Shader "Unlit/Chapter13-FogWithDepthTexture"
{
    Properties {
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_FogDensity ("Fog Density", Float) = 1.0
		_FogColor ("Fog Color", Color) = (1, 1, 1, 1)
		_FogStart ("Fog Start", Float) = 0.0
		_FogEnd ("Fog End", Float) = 1.0
	}
    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" }
        
        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
		#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

        CBUFFER_START(UnityPerMaterial)
            float4x4 _FrustumCornersRay;
		
            half4 _MainTex_TexelSize;
            half _FogDensity;
            half4 _FogColor;
            float _FogStart;
            float _FogEnd;
        CBUFFER_END

        TEXTURE2D(_MainTex);       SAMPLER(sampler_MainTex);
        TEXTURE2D(_CameraDepthTexture);       SAMPLER(sampler_CameraDepthTexture);
        //如果在URP Asset设置下勾选 depth texture选项系统会自动生成一张以_CameraDepthTexture为名的深度图，抽时间会写一篇相关文章并把链接补充到本篇中。

        struct appdata{
            float4 vertex : POSITION;
            float2 texcoord : TEXCOORD0;
        };

        struct v2f {
			float4 pos : SV_POSITION;
			half2 uv : TEXCOORD0;
			half2 uv_depth : TEXCOORD1;
			float4 interpolatedRay : TEXCOORD2;
        };
        v2f vert(appdata v) {
			v2f o;
			
			o.pos = TransformObjectToHClip(v.vertex);
			
			o.uv = v.texcoord;
            o.uv_depth = v.texcoord;
            #if UNITY_UV_STARTS_AT_TOP
			if (_MainTex_TexelSize.y < 0)
				o.uv_depth.y = 1 - o.uv_depth.y;
			#endif

            int index = 0;
			if (v.texcoord.x < 0.5 && v.texcoord.y < 0.5) {
				index = 0;
			} else if (v.texcoord.x > 0.5 && v.texcoord.y < 0.5) {
				index = 1;
			} else if (v.texcoord.x > 0.5 && v.texcoord.y > 0.5) {
				index = 2;
			} else {
				index = 3;
			}

			#if UNITY_UV_STARTS_AT_TOP
			if (_MainTex_TexelSize.y < 0)
				index = 3 - index;
			#endif
			
			o.interpolatedRay = _FrustumCornersRay[index];
            //尽管我们这里使用了很多判断语句，但由于屏幕后处理所用的模型是一个四边形网格，只包含4个顶点，因此这些操作不会对性能造成很大影响。
					 
			return o;
		}

        half4 frag(v2f i) : SV_Target {
			float linearDepth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture,i.uv_depth), _ZBufferParams);
            //使用LinearEyeDepth得到视角空间下的线性深度值
			float3 worldPos = _WorldSpaceCameraPos + linearDepth * i.interpolatedRay.xyz;
						
			float fogDensity = (_FogEnd - worldPos.y) / (_FogEnd - _FogStart); 
			fogDensity = saturate(fogDensity * _FogDensity);
			
			half4 finalColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);
			finalColor.rgb = lerp(finalColor.rgb, _FogColor.rgb, fogDensity);
			
			return finalColor;
		}
		
		ENDHLSL
		
		Pass {
			ZTest Always Cull Off ZWrite Off
			     	
			HLSLPROGRAM  
			
			#pragma vertex vert  
			#pragma fragment frag  
			  
			ENDHLSL  
		}
	} 
	FallBack "Packages/com.unity.render-pipelines.universal/FallbackError"
}