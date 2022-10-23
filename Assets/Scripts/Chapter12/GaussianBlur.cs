using System;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class GaussianBlur : ScriptableRendererFeature
{
    [Serializable, VolumeComponentMenu("Ding Post-processing/12.4 GaussianBlur")]
    public class CustomVolumeComponent : DingVolumeComponentBase 
    {
        public ClampedFloatParameter BlurSpread = new ClampedFloatParameter(0.5f, 0.1f, 3f);
        public ClampedIntParameter Iterations = new ClampedIntParameter(3, 1, 4);
        public ClampedIntParameter DownSample = new ClampedIntParameter(2, 1, 8);
        
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
        private RenderTargetHandle tempTexture0;
        private RenderTargetHandle tempTexture1;
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
            tempTexture0.Init("_TempRTexture0");
            tempTexture1.Init("_TempRTexture1");
        }

        public void Setup(RenderTargetIdentifier source, RenderTargetHandle destination){
            this.source = source;
            this.destination = destination;
        }
        
        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            if (!volume.IsActive()) { 
                return;
            }
            CommandBuffer cmd = CommandBufferPool.Get("m_ProfilerTag");
            //using 方法可以实现在FrameDebug上查看渲染过程
            using(new ProfilingScope(cmd, m_ProfilingSampler)){

                ref var cameraData = ref renderingData.cameraData;
                int w = cameraData.camera.scaledPixelWidth / volume.DownSample.value;
                int h = cameraData.camera.scaledPixelHeight / volume.DownSample.value;

                cmd.GetTemporaryRT(tempTexture0.id, w, h, 0, filterMode);
                Blit(cmd, source, tempTexture0.Identifier());

                for(int i = 0; i < volume.Iterations.value; i++){
                    material.SetFloat("_BlurSize", 1.0f + i * volume.BlurSpread.value);
                    cmd.GetTemporaryRT(tempTexture1.id, w, h, 0, filterMode);
                    Blit(cmd, tempTexture0.Identifier(), tempTexture1.Identifier(), material, 0);
                    cmd.ReleaseTemporaryRT(tempTexture0.id);
                    tempTexture0 = tempTexture1;
                    cmd.GetTemporaryRT(tempTexture1.id, w, h, 0, filterMode);
                    Blit(cmd, tempTexture0.Identifier(), tempTexture1.Identifier(), material, 1);
                    cmd.ReleaseTemporaryRT(tempTexture0.id);
                    tempTexture0 = tempTexture1;
                }

                Blit(cmd, tempTexture0.Identifier(), source);

            }
            //执行渲染
            context.ExecuteCommandBuffer(cmd);
            //释放回收
            CommandBufferPool.Release(cmd);
        }

        public override void FrameCleanup(CommandBuffer cmd){
            base.FrameCleanup(cmd);
            cmd.ReleaseTemporaryRT(tempTexture0.id);
            cmd.ReleaseTemporaryRT(tempTexture1.id);
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



