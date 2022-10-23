Shader "Unlit/Chapter12-BrightnessSaturationAndContrast"
{
    Properties {
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_Brightness ("Brightness", Float) = 1.5
		_Saturation("Saturation", Float) = 1.5
		_Contrast("Contrast", Float) = 1.5
	}
    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" }
        ZTest Always Cull Off ZWrite Off
        //基本是后处理shader的必备设置，放置场景中的透明物体渲染错误
		//注意进行该设置后，shader将在完成透明物体的渲染后起作用，即RenderPassEvent.AfterRenderingTransparents后

        Pass
        {
			HLSLPROGRAM 
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			
			#pragma vertex vert
			#pragma fragment frag

            CBUFFER_START(UnityPerMaterial)
            half _Brightness;
			half _Saturation;
			half _Contrast;
            CBUFFER_END

            TEXTURE2D(_MainTex);       SAMPLER(sampler_MainTex);

            struct a2v{
                float4 vertex : POSITION;
				float4 texcoord : TEXCOORD0;
            };

            struct v2f {
				float4 pos : SV_POSITION;
				half2 uv: TEXCOORD0;
			};
			  
			v2f vert(a2v v) {
                //appdata_img在URP下不能使用，保险起见自己定义输入结构体
                v2f o;
				
				o.pos = TransformObjectToHClip(v.vertex);
				
				o.uv = v.texcoord;
						 
				return o;
			}
		
			half4 frag(v2f i) : SV_Target {
				half4 renderTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv); 
				  
				// Apply brightness
				half3 finalColor = renderTex.rgb * _Brightness;
                //亮度的调整非常简单，只需要把原颜色乘以亮度系数_Brightness即可
				
				// Apply saturation
				half luminance = 0.2125 * renderTex.r + 0.7154 * renderTex.g + 0.0721 * renderTex.b;
				half3 luminanceColor = half3(luminance, luminance, luminance);
                //通过对每个颜色分量乘以一个特定的系数再相加得到一个饱和度为0的颜色值
				finalColor = lerp(luminanceColor, finalColor, _Saturation);
                //用_Saturation属性和上一步得到的颜色之间进行插值
				
				// Apply contrast
				half3 avgColor = half3(0.5, 0.5, 0.5);
                //创建一个对比度为0的颜色值（各分量均为0.5）
				finalColor = lerp(avgColor, finalColor, _Contrast);
                //使用_Contrast属性和上一步得到的颜色之间进行插值
				
				return half4(finalColor, renderTex.a);  
			}  
			  
			ENDHLSL
		}  
	}
    FallBack "Packages/com.unity.render-pipelines.universal/FallbackError"
}
