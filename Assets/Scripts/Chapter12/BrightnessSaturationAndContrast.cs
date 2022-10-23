using System;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;


public class BrightnessSaturationAndContrast : ScriptableRendererFeature
{
    [Serializable, VolumeComponentMenu("Ding Post-processing/12.2BrightnessSaturationAndContrast")]
    public class CustomVolumeComponent : DingVolumeComponentBase 
    {
        public MinFloatParameter Brightness = new MinFloatParameter(1f, 0);
        public ClampedFloatParameter Saturation = new ClampedFloatParameter(1f, 0, 1f);
        public ClampedFloatParameter Contrast = new ClampedFloatParameter(1f, 0, 1f);
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
        private RenderTargetHandle destination {get; set;}
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

        public void Setup(RenderTargetIdentifier source, RenderTargetHandle destination){
            this.source = source;
            this.destination = destination;
        }
        
        // This method is called before executing the render pass.
        // It can be used to configure render targets and their clear state. Also to create temporary render target textures.
        // When empty this render pass will render to the active camera render target.
        // You should never call CommandBuffer.SetRenderTarget. Instead call <c>ConfigureTarget</c> and <c>ConfigureClear</c>.
        // The render pipeline will ensure target setup and clearing happens in a performant manner.
        public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
        {
        }

        // Here you can implement the rendering logic.
        // Use <c>ScriptableRenderContext</c> to issue drawing commands or execute command buffers
        // https://docs.unity3d.com/ScriptReference/Rendering.ScriptableRenderContext.html
        // You don't have to call ScriptableRenderContext.submit, the render pipeline will call it at specific points in the pipeline.
        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            if (!volume.IsActive()) { 
                return;
            }
            CommandBuffer cmd = CommandBufferPool.Get("m_ProfilerTag");
            //using 方法可以实现在FrameDebug上查看渲染过程
            using(new ProfilingScope(cmd, m_ProfilingSampler)){
                material.SetFloat("_Brightness", volume.Brightness.value);
                material.SetFloat("_Saturation", volume.Saturation.value);
                material.SetFloat("_Contrast", volume.Contrast.value);

                //创建一张RT
                RenderTextureDescriptor cameraTextureDesc = renderingData.cameraData.cameraTargetDescriptor;
                cameraTextureDesc.depthBufferBits = 0;
                cameraTextureDesc.msaaSamples = 1;
                //取消抗锯齿处理
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

        // Cleanup any allocated resources that were created during the execution of this render pass.
        public override void OnCameraCleanup(CommandBuffer cmd)
        {
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

    // Here you can inject one or multiple render passes in the renderer.
    // This method is called when setting up the renderer once per-camera.
    //每一帧都会调用
    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        var src = renderer.cameraColorTarget;
        var dest = RenderTargetHandle.CameraTarget;

        if(settings.shader == null){
            Debug.LogWarningFormat("shader丢失",GetType().Name);
            return;
        }

        //将当前渲染的colorRT传到Pass中

        m_ScriptablePass.Setup(src, dest);

        //将Pass添加到渲染队列中
        renderer.EnqueuePass(m_ScriptablePass);
    }

    protected override void Dispose(bool disposing)
    {
        base.Dispose(disposing);
    
    }
}