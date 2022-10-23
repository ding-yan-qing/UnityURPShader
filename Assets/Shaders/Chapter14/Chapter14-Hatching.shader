Shader "Unlit/Chapter14-Hatching"
{
    Properties {
		_Color ("Color Tint", Color) = (1, 1, 1, 1)
        _OutlineColor ("Outline Color", Color) = (0, 0, 0, 1)
		_TileFactor ("Tile Factor", Float) = 1
		_Outline ("Outline", Range(0, 1)) = 0.1
		_Hatch0 ("Hatch 0", 2D) = "white" {}
		_Hatch1 ("Hatch 1", 2D) = "white" {}
		_Hatch2 ("Hatch 2", 2D) = "white" {}
		_Hatch3 ("Hatch 3", 2D) = "white" {}
		_Hatch4 ("Hatch 4", 2D) = "white" {}
		_Hatch5 ("Hatch 5", 2D) = "white" {}
	}
    SubShader
    {
        Tags {"RenderPipeline" = "UniversalPipeline" "RenderType"="Opaque" "Queue"="Geometry"}
        UsePass "Unlit/Chapter14-ToonShading/OUTLINE"
        UsePass "Universal Render Pipeline/Lit/ShadowCaster"

        Pass {
			Tags { "LightMode"="UniversalForward" }
			
			HLSLPROGRAM
			
			#pragma vertex vert
			#pragma fragment frag 
			
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
		    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            CBUFFER_START(UnityPerMaterial)
                half4 _Color;
			    float _TileFactor;
            CBUFFER_END

			TEXTURE2D(_Hatch0);       SAMPLER(sampler_Hatch0);
            TEXTURE2D(_Hatch1);       SAMPLER(sampler_Hatch1);
            TEXTURE2D(_Hatch2);       SAMPLER(sampler_Hatch2);
            TEXTURE2D(_Hatch3);       SAMPLER(sampler_Hatch3);
            TEXTURE2D(_Hatch4);       SAMPLER(sampler_Hatch4);
            TEXTURE2D(_Hatch5);       SAMPLER(sampler_Hatch5);
			
			struct a2v {
				float4 vertex : POSITION;
				float4 tangent : TANGENT; 
				float3 normal : NORMAL; 
				float2 texcoord : TEXCOORD0; 
			};
			
			struct v2f {
				float4 pos : SV_POSITION;
				float3 uv : TEXCOORD0;
				half3 hatchWeights0 : TEXCOORD1;
				half3 hatchWeights1 : TEXCOORD2;
				float3 worldPos : TEXCOORD3;
			};
			
			v2f vert(a2v v) {
				v2f o;
				
				VertexPositionInputs positionInputs = GetVertexPositionInputs(v.vertex.xyz);
                o.pos = positionInputs.positionCS;
				
				o.uv.xy = v.texcoord.xy * _TileFactor;
				
                Light mainLight = GetMainLight();
				//获取光源信息的函数
                o.uv.z = mainLight.distanceAttenuation;
                //即atten
                half3 worldLightDir = normalize(TransformObjectToWorldDir(mainLight.direction));
                half3 worldNormal = TransformObjectToWorldNormal(v.normal);
				half diff = max(0, dot(worldLightDir, worldNormal));
				
				o.hatchWeights0 = half3(0, 0, 0);
				o.hatchWeights1 = half3(0, 0, 0);
				
				float hatchFactor = diff * 7.0;
				
				if (hatchFactor > 6.0) {
					// Pure white, do nothing
				} else if (hatchFactor > 5.0) {
					o.hatchWeights0.x = hatchFactor - 5.0;
				} else if (hatchFactor > 4.0) {
					o.hatchWeights0.x = hatchFactor - 4.0;
					o.hatchWeights0.y = 1.0 - o.hatchWeights0.x;
				} else if (hatchFactor > 3.0) {
					o.hatchWeights0.y = hatchFactor - 3.0;
					o.hatchWeights0.z = 1.0 - o.hatchWeights0.y;
				} else if (hatchFactor > 2.0) {
					o.hatchWeights0.z = hatchFactor - 2.0;
					o.hatchWeights1.x = 1.0 - o.hatchWeights0.z;
				} else if (hatchFactor > 1.0) {
					o.hatchWeights1.x = hatchFactor - 1.0;
					o.hatchWeights1.y = 1.0 - o.hatchWeights1.x;
				} else {
					o.hatchWeights1.y = hatchFactor;
					o.hatchWeights1.z = 1.0 - o.hatchWeights1.y;
				}

                o.worldPos = positionInputs.positionWS;
				
				return o; 
			}
			
			half4 frag(v2f i) : SV_Target {			
				half4 hatchTex0 = SAMPLE_TEXTURE2D(_Hatch0, sampler_Hatch0, i.uv) * i.hatchWeights0.x;
				half4 hatchTex1 = SAMPLE_TEXTURE2D(_Hatch1, sampler_Hatch1, i.uv) * i.hatchWeights0.y;
				half4 hatchTex2 = SAMPLE_TEXTURE2D(_Hatch2, sampler_Hatch2, i.uv) * i.hatchWeights0.z;
				half4 hatchTex3 = SAMPLE_TEXTURE2D(_Hatch3, sampler_Hatch3, i.uv) * i.hatchWeights1.x;
				half4 hatchTex4 = SAMPLE_TEXTURE2D(_Hatch4, sampler_Hatch4, i.uv) * i.hatchWeights1.y;
				half4 hatchTex5 = SAMPLE_TEXTURE2D(_Hatch5, sampler_Hatch5, i.uv) * i.hatchWeights1.z;
				half4 whiteColor = half4(1, 1, 1, 1) * (1 - i.hatchWeights0.x - i.hatchWeights0.y - i.hatchWeights0.z - 
							i.hatchWeights1.x - i.hatchWeights1.y - i.hatchWeights1.z);
				
				half4 hatchColor = hatchTex0 + hatchTex1 + hatchTex2 + hatchTex3 + hatchTex4 + hatchTex5 + whiteColor;
								
				return half4(hatchColor.rgb * _Color.rgb * i.uv.z, 1.0);
			}
			
			ENDHLSL
		}
	}
	FallBack "Packages/com.unity.render-pipelines.universal/FallbackError"
}
