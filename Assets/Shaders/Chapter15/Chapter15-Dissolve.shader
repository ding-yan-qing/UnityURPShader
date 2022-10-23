Shader "Unlit/Chapter15-Dissolve"
{
    Properties {
		_BurnAmount ("Burn Amount", Range(0.0, 1.0)) = 0.0
		_LineWidth("Burn Line Width", Range(0.0, 0.2)) = 0.1
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_BumpMap ("Normal Map", 2D) = "bump" {}
		_BurnFirstColor("Burn First Color", Color) = (1, 0, 0, 1)
		_BurnSecondColor("Burn Second Color", Color) = (1, 0, 0, 1)
		_BurnMap("Burn Map", 2D) = "white"{}
	}

    SubShader {
		Tags {"RenderPipeline" = "UniversalPipeline" "RenderType"="Opaque" "Queue"="Geometry"}

        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
		#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

        CBUFFER_START(UnityPerMaterial)
            half _BurnAmount;
			half _LineWidth;
			half4 _BurnFirstColor;
			half4 _BurnSecondColor;
			
			float4 _MainTex_ST;
			float4 _BumpMap_ST;
			float4 _BurnMap_ST;
        CBUFFER_END
			
			TEXTURE2D(_MainTex);       SAMPLER(sampler_MainTex);
            TEXTURE2D(_BumpMap);       SAMPLER(sampler_BumpMap);
            TEXTURE2D(_BurnMap);       SAMPLER(sampler_BurnMap);

            struct a2v {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 tangent : TANGENT;
				float4 texcoord : TEXCOORD0;
			};
			
			struct v2f {
				float4 pos : SV_POSITION;
				float2 uvMainTex : TEXCOORD0;
				float2 uvBumpMap : TEXCOORD1;
				float2 uvBurnMap : TEXCOORD2;
				//float3 lightDir : TEXCOORD3;
				float3 worldPos : TEXCOORD3;
                half3 normalWS : TEXCOORD4;
                half3 tangentWS : TEXCOORD5;
                half3 bitangentWS : TEXCOORD6;
			};
            
        ENDHLSL
		
		Pass {
			Tags { "LightMode"="UniversalForward" }

			Cull Off
			
			HLSLPROGRAM
			
			#pragma vertex vert
			#pragma fragment frag
			
			v2f vert(a2v v) {
				v2f o;
                VertexPositionInputs positionInputs = GetVertexPositionInputs(v.vertex.xyz);
                o.pos = positionInputs.positionCS;
				o.worldPos = positionInputs.positionWS;
                VertexNormalInputs normalInput = GetVertexNormalInputs(v.normal, v.tangent);
                o.normalWS = normalInput.normalWS;
                o.tangentWS = normalInput.tangentWS;
                o.bitangentWS = normalInput.bitangentWS;
				
				o.uvMainTex = TRANSFORM_TEX(v.texcoord, _MainTex);
				o.uvBumpMap = TRANSFORM_TEX(v.texcoord, _BumpMap);
				o.uvBurnMap = TRANSFORM_TEX(v.texcoord, _BurnMap);
				
				//TANGENT_SPACE_ROTATION;
                //URP中已经去除，我们选择把法线通过TBN矩阵转换到世界空间，和书中把光线转换到TBN空间的结果是相同的
				
				return o;
			}
			
			half4 frag(v2f i) : SV_Target {
				half3 burn = SAMPLE_TEXTURE2D(_BurnMap, sampler_BurnMap, i.uvBurnMap).rgb;
				
				clip(burn.r - _BurnAmount);
				
				//float3 tangentLightDir = normalize(i.lightDir);
				half3 tangentNormal = UnpackNormal(SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap, i.uvBumpMap));
				half3 normalWS = TransformTangentToWorld(tangentNormal, half3x3(i.tangentWS, i.bitangentWS, i.normalWS));
                //把切线空间的法线转换到世界空间
				half3 albedo = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uvMainTex).rgb;
				
				half3 ambient = half3(unity_SHAr.w, unity_SHAg.w, unity_SHAb.w) * albedo;

                Light mainLight = GetMainLight();
                half3 worldLightDir = normalize(TransformObjectToWorldDir(mainLight.direction));
				
				half3 diffuse = mainLight.color * albedo * max(0, dot(normalWS, worldLightDir));

				half t = 1 - smoothstep(0.0, _LineWidth, burn.r - _BurnAmount);
				half3 burnColor = lerp(_BurnFirstColor, _BurnSecondColor, t);
				burnColor = pow(burnColor, 5);
				
				half3 finalColor = lerp(ambient + diffuse * mainLight.distanceAttenuation, burnColor, t * step(0.0001, _BurnAmount));
				
				return half4(finalColor, 1);
			}
			
			ENDHLSL
		}
		
		// Pass to render object as a shadow caster
		Pass {
			Tags { "LightMode" = "ShadowCaster" }
			
			HLSLPROGRAM
			
			#pragma vertex vert
			#pragma fragment frag

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
			
            half3 _LightDirection;
			
			v2f vert(a2v v) {
				v2f o;
				
				float3 worldPos = TransformObjectToWorld(v.vertex.xyz);
                float3 worldNormal = TransformObjectToWorldNormal(v.normal);
                o.pos = TransformWorldToHClip(ApplyShadowBias(worldPos, worldNormal, _LightDirection));
                //阴影专用裁剪空间坐标

                #if UNITY_REVERSED_Z
                    o.pos.z = min(o.pos.z, o.pos.w * UNITY_NEAR_CLIP_VALUE);
                #else
                    o.pos.z = max(o.pos.z, o.pos.w * UNITY_NEAR_CLIP_VALUE);
                #endif
                //判断是否在DirectX平台，决定是否反转坐标
				
				o.uvBurnMap = TRANSFORM_TEX(v.texcoord, _BurnMap);
				
				return o;
			}
			
			half4 frag(v2f i) : SV_Target {
				half3 burn = SAMPLE_TEXTURE2D(_BurnMap, sampler_BurnMap, i.uvBurnMap).rgb;
				
				clip(burn.r - _BurnAmount);
				return 0;
			}
			ENDHLSL
		}
	}
	FallBack "Packages/com.unity.render-pipelines.universal/FallbackError"
}
