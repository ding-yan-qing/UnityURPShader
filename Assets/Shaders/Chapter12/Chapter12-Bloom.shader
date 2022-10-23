Shader "Unlit/Chapter12-Bloom"
{
    Properties {
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_BloomNew ("Bloom",2D) = "Black" {}
		//"Black"如果写成小写“black”,renderFeature 中的高亮渲染贴图会传不过来，也不知道什么原因，各种改bug最后问题在这里，有知道原理的请不吝赐教~
		_LuminanceThreshold ("Luminance Threshold", Float) = 0.5
		_BlurSize ("Blur Size", Float) = 1.0
	}
    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" }
        
        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
		#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

        CBUFFER_START(UnityPerMaterial)
            half4 _MainTex_TexelSize;
		    float _LuminanceThreshold;
		    float _BlurSize;
        CBUFFER_END

        TEXTURE2D(_MainTex);       SAMPLER(sampler_MainTex);
        TEXTURE2D(_BloomNew);       SAMPLER(sampler_BloomNew);

        struct appdata{
            float4 vertex : POSITION;
            float2 texcoord : TEXCOORD0;
        };

        struct v2f {
			float4 pos : SV_POSITION;
			half2 uv : TEXCOORD0;
        };
        v2f vertExtractBright(appdata v) {
			v2f o;
			
			o.pos = TransformObjectToHClip(v.vertex);
			
			o.uv = v.texcoord;
					 
			return o;
		}
		
		half luminance(half4 color) {
			return  0.2125 * color.r + 0.7154 * color.g + 0.0721 * color.b; 
		}
		
		half4 fragExtractBright(v2f i) : SV_Target {
			half4 c = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv); 
			half val = clamp(luminance(c) - _LuminanceThreshold, 0.0, 1.0);
			//亮度值减去阈值_LuminanceThreshold，并把结果截取到0～1范围内。
			return c * val;
            //只保留val值大于0的部分
		}
		
		struct v2fBloom {
			float4 pos : SV_POSITION; 
			half4 uv : TEXCOORD0;
		};
		
		v2fBloom vertBloom(appdata v) {
			v2fBloom o;
			
			o.pos = TransformObjectToHClip (v.vertex);
			o.uv.xy = v.texcoord;		
			o.uv.zw = v.texcoord;
			
			#if UNITY_UV_STARTS_AT_TOP			
			if (_MainTex_TexelSize.y < 0.0)
				o.uv.w = 1.0 - o.uv.w;
			#endif
				        	
			return o; 
		}
		
		half4 fragBloom(v2fBloom i) : SV_Target {
			return SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv.xy) + SAMPLE_TEXTURE2D(_BloomNew, sampler_BloomNew, i.uv.zw);
		} 
		
		ENDHLSL
		
		ZTest Always Cull Off ZWrite Off
		
		Pass {  
			HLSLPROGRAM  
			#pragma vertex vertExtractBright  
			#pragma fragment fragExtractBright  
			
			ENDHLSL  
		}
        //第一步提取高亮度的范围
		
		UsePass "Unlit/Chapter12-GaussianBlur/GAUSSIAN_BLUR_VERTICAL"
		
		UsePass "Unlit/Chapter12-GaussianBlur/GAUSSIAN_BLUR_HORIZONTAL"

        //第二步对高亮范围进行模糊
		
		Pass {  
			HLSLPROGRAM  
			#pragma vertex vertBloom  
			#pragma fragment fragBloom  
			
			ENDHLSL  
		}
        //第三步把模糊后的高亮位置与原图相加
	}
	FallBack "Packages/com.unity.render-pipelines.universal/FallbackError"
}
