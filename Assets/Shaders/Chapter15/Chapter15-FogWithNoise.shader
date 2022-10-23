Shader "Unlit/Chapter15-FogWithNoise"
{
    Properties {
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_FogDensity ("Fog Density", Float) = 1.0
		_FogColor ("Fog Color", Color) = (1, 1, 1, 1)
		_FogStart ("Fog Start", Float) = 0.0
		_FogEnd ("Fog End", Float) = 1.0
		_NoiseTex ("Noise Texture", 2D) = "white" {}
		_FogXSpeed ("Fog Horizontal Speed", Float) = 0.1
		_FogYSpeed ("Fog Vertical Speed", Float) = 0.1
		_NoiseAmount ("Noise Amount", Float) = 1
	}
    SubShader {
        Tags {"RenderPipeline" = "UniversalPipeline"}
		HLSLINCLUDE
		
		#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
		#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

        CBUFFER_START(UnityPerMaterial)
            half4 _MainTex_TexelSize;
            half _FogDensity;
            half4 _FogColor;
            float _FogStart;
            float _FogEnd;
            half _FogXSpeed;
            half _FogYSpeed;
            half _NoiseAmount;
            float4x4 _FrustumCornersRay;
        CBUFFER_END
			
			TEXTURE2D(_MainTex);                           SAMPLER(sampler_MainTex);
            TEXTURE2D(_CameraDepthTexture);                SAMPLER(sampler_CameraDepthTexture);
            TEXTURE2D(_NoiseTex);                          SAMPLER(sampler_NoiseTex);
		
        struct appdata{
            float4 vertex : POSITION;
            float2 texcoord : TEXCOORD0;
        };

		struct v2f {
			float4 pos : SV_POSITION;
			float2 uv : TEXCOORD0;
			float2 uv_depth : TEXCOORD1;
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
				 	 
			return o;
		}
		
		half4 frag(v2f i) : SV_Target {
			float linearDepth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, i.uv_depth), _ZBufferParams);
			float3 worldPos = _WorldSpaceCameraPos + linearDepth * i.interpolatedRay.xyz;
			
			float2 speed = _Time.y * float2(_FogXSpeed, _FogYSpeed);
			float noise = (SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, i.uv + speed).r - 0.5) * _NoiseAmount;
					
			float fogDensity = (_FogEnd - worldPos.y) / (_FogEnd - _FogStart); 
			fogDensity = saturate(fogDensity * _FogDensity * (1 + noise));
			
			half4 finalColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);
			finalColor.rgb = lerp(finalColor.rgb, _FogColor.rgb, fogDensity);
			
			return finalColor;
		}
		
		ENDHLSL
		
		Pass {          	
			HLSLPROGRAM  
			
			#pragma vertex vert  
			#pragma fragment frag  
			  
			ENDHLSL
		}
	} 
	FallBack "Packages/com.unity.render-pipelines.universal/FallbackError"
}
