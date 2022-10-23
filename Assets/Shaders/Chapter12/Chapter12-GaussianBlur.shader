Shader "Unlit/Chapter12-GaussianBlur"
{
    Properties {
		_MainTex ("Base (RGB)", 2D) = "white" {}
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
		    float _BlurSize;
        CBUFFER_END

        TEXTURE2D(_MainTex);       SAMPLER(sampler_MainTex);

        struct appdata{
            float4 vertex : POSITION;
            float2 texcoord : TEXCOORD0;
        };

        struct v2f {
			float4 pos : SV_POSITION;
			half2 uv[5] : TEXCOORD0;
        };

		v2f vertBlurVertical(appdata v) {
			v2f o;
			o.pos = TransformObjectToHClip(v.vertex);
			
			half2 uv = v.texcoord;
			
			o.uv[0] = uv;
			o.uv[1] = uv + float2(0.0, _MainTex_TexelSize.y * 1.0) * _BlurSize;
			o.uv[2] = uv - float2(0.0, _MainTex_TexelSize.y * 1.0) * _BlurSize;
			o.uv[3] = uv + float2(0.0, _MainTex_TexelSize.y * 2.0) * _BlurSize;
			o.uv[4] = uv - float2(0.0, _MainTex_TexelSize.y * 2.0) * _BlurSize;
            //和属性_BlurSize相乘来控制采样距离。在高斯核维数不变的情况下，_BlurSize越大，模糊程度越高
					 
			return o;
		}
		
		v2f vertBlurHorizontal(appdata v) {
			v2f o;
			o.pos = TransformObjectToHClip(v.vertex);
			
			half2 uv = v.texcoord;
			
			o.uv[0] = uv;
			o.uv[1] = uv + float2(_MainTex_TexelSize.x * 1.0, 0.0) * _BlurSize;
			o.uv[2] = uv - float2(_MainTex_TexelSize.x * 1.0, 0.0) * _BlurSize;
			o.uv[3] = uv + float2(_MainTex_TexelSize.x * 2.0, 0.0) * _BlurSize;
			o.uv[4] = uv - float2(_MainTex_TexelSize.x * 2.0, 0.0) * _BlurSize;
					 
			return o;
		}
		
		half4 fragBlur(v2f i) : SV_Target {
			float weight[3] = {0.4026, 0.2442, 0.0545};
            //高斯权重
			
			half3 sum = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv[0]).rgb * weight[0];
			
			for (int it = 1; it < 3; it++) {
				sum += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv[it*2-1]).rgb * weight[it];
				sum += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv[it*2]).rgb * weight[it];
			}
			
			return half4(sum, 1.0);
		}
		    
		ENDHLSL
		
		ZTest Always Cull Off ZWrite Off
		
		Pass {
			NAME "GAUSSIAN_BLUR_VERTICAL"
			
			HLSLPROGRAM
			  
			#pragma vertex vertBlurVertical  
			#pragma fragment fragBlur
			  
			ENDHLSL  
		}
		
		Pass {  
			NAME "GAUSSIAN_BLUR_HORIZONTAL"
			
			HLSLPROGRAM  
			
			#pragma vertex vertBlurHorizontal  
			#pragma fragment fragBlur
			
			ENDHLSL
		}
	} 
	FallBack "Packages/com.unity.render-pipelines.universal/FallbackError"
}