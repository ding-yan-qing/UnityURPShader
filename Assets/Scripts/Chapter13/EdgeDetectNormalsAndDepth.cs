using System;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class EdgeDetectNormalsAndDepth : ScriptableRendererFeature
{
    [Serializable, VolumeComponentMenu("Ding Post-processing/13.4 EdgeDetectNormalsAndDepth")]
    public class CustomVolumeComponent : DingVolumeComponentBase 
    {
        public ClampedFloatParameter EdgeOnly = new ClampedFloatParameter(0.0f, 0, 1.0f);
        public MinFloatParameter SampleDistance = new MinFloatParameter(1.0f, 0f);
        public MinFloatParameter SensitivityDepth = new MinFloatParameter(1.0f, 0f);
        public MinFloatParameter SensitivityNormals = new MinFloatParameter(1.0f, 0f);

        public ColorParameter EdgeColor = new ColorParameter(Color.black, false, false, true);
        public ColorParameter BackgroundColor = new ColorParameter(Color.white);
    
        public override bool IsActive() => isRender.value;
        public override bool IsTileCompatible() => false;

    }

    class CustomRenderPass : ScriptableRenderPass
    {
        
        public Material material;
        //RT的滤波模式
        public FilterMode filterMode {get; set;}
        //当前渲染阶段的colorRT
        //RenderTargetIdentifier、RenderTargetHandle都可以理解为RT，Identifier为camera提供的需要被应用的texture，Handle为被shader处理渲染过的RT
        private RenderTargetIdentifier source {get; set;}
        //private RenderTargetHandle destination {get; set;}
        //辅助RT
        private RenderTargetHandle tempTexture;
        string m_ProfilerTag;
        //Profiling上显示
        public CustomVolumeComponent volume;
        ProfilingSampler m_ProfilingSampler = new ProfilingSampler("URPDing");

        public CustomRenderPass(RenderPassEvent renderPassEvent, Shader shader, CustomVolumeComponent volume, string tag){
            //确定在哪个阶段插入渲染
            this.renderPassEvent = renderPassEvent;
            this.volume = volume;
            if(shader == null){return;}
            this.material = CoreUtils.CreateEngineMaterial(shader);
            m_ProfilerTag = tag;
            //初始化辅助RT的名字
            tempTexture.Init("_TempRTexture");
        }

        public void Setup(RenderTargetIdentifier source){
            this.source = source;
            //this.destination = destination;
        }
        
        
        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            if (!volume.IsActive()) { 
                return;
            }
            CommandBuffer cmd = CommandBufferPool.Get("m_ProfilerTag");
            //using 方法可以实现在FrameDebug上查看渲染过程
            using(new ProfilingScope(cmd, m_ProfilingSampler)){

                Vector4 Sensitivity = new Vector4(volume.SensitivityNormals.value, volume.SensitivityDepth.value, 0, 0);

                material.SetFloat("_EdgeOnly", volume.EdgeOnly.value);
                material.SetFloat("_SampleDistance", volume.SampleDistance.value);
                material.SetVector("_Sensitivity", Sensitivity);
                
                material.SetColor("_EdgeColor", volume.EdgeColor.value);
                material.SetColor("_BackgroundColor", volume.BackgroundColor.value);
                //创建一张RT
                RenderTextureDescriptor cameraTextureDesc = renderingData.cameraData.cameraTargetDescriptor;
                cameraTextureDesc.depthBufferBits = 0;
                cameraTextureDesc.msaaSamples = 1;
                //取消抗锯齿处理,抗锯齿会影响unity自动在DX与OpenGL间的坐标转换
                cmd.GetTemporaryRT(tempTexture.id, cameraTextureDesc, filterMode);
                
                //将当前帧的colorRT用着色器（shader in material）渲染后输出到之前创建的贴图（辅助RT）上
                Blit(cmd, source, tempTexture.Identifier(), material, 0);
                    //将处理后的辅助RT重新渲染到当前帧的colorRT上
                Blit(cmd, tempTexture.Identifier(), source);

            }
            //执行渲染
            context.ExecuteCommandBuffer(cmd);
            //释放回收
            CommandBufferPool.Release(cmd);
        }


        public override void FrameCleanup(CommandBuffer cmd){
            base.FrameCleanup(cmd);
            cmd.ReleaseTemporaryRT(tempTexture.id);
        }
    }

    [System.Serializable]
    public class Settings{
        public RenderPassEvent Event = RenderPassEvent.AfterRenderingTransparents;
        public Shader shader;
    }

    public Settings settings = new Settings();
    CustomVolumeComponent volume;
    CustomRenderPass m_ScriptablePass;

    

    /// <inheritdoc/>
    //feature被创建时调用
    public override void Create()
    {
        var stack = VolumeManager.instance.stack;
        volume = stack.GetComponent<CustomVolumeComponent>();
        if (volume == null) { 
            CoreUtils.Destroy(m_ScriptablePass.material);
            return; 
        }
        m_ScriptablePass = new CustomRenderPass(settings.Event, settings.shader, volume, name);
    }

    //每一帧都会调用
    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        var src = renderer.cameraColorTarget;
        //var dest = RenderTargetHandle.CameraTarget;

        if(settings.shader == null){
            Debug.LogWarningFormat("shader丢失",GetType().Name);
            return;
        }

        //将当前渲染的colorRT传到Pass中

        m_ScriptablePass.Setup(src);

        //将Pass添加到渲染队列中
        renderer.EnqueuePass(m_ScriptablePass);
    }

    protected override void Dispose(bool disposing)
    {
        base.Dispose(disposing);
    
    }
}


