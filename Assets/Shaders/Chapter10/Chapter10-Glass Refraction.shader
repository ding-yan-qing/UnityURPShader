Shader "Custom/Chapter10-Glass Refraction"
{
    Properties {
		_MainTex ("Main Tex", 2D) = "white" {}
		_BumpMap ("Normal Map", 2D) = "bump" {}
		_Cubemap ("Environment Cubemap", Cube) = "_Skybox" {}
		_RefractionTex("Refraction Tex",2D) = "white"{}
		_Distortion ("Distortion", Range(0, 100)) = 10
		_RefractAmount ("Refract Amount", Range(0.0, 1.0)) = 1.0
	}
	SubShader {

		Tags { 
            "RenderPipeline"="UniversalPipeline"
            "Queue"="Transparent" 
            "RenderType"="Opaque" 
        }

		//GrabPass { "_RefractionTex" }被废除，可以直接用Mirror中的render texture实现此功能，这一方法《入门精要》中有分析与GrabPass之间的区别
		
		Pass {		
			HLSLPROGRAM
 
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			
			#pragma vertex vert
			#pragma fragment frag

            CBUFFER_START(UnityPerMaterial)
			float4 _MainTex_ST;
            float4 _BumpMap_ST;
			float _Distortion;
			half _RefractAmount;
			float4 _RefractionTex_TexelSize;
            CBUFFER_END

			sampler2D _MainTex;
			sampler2D _BumpMap;
			samplerCUBE _Cubemap;
			sampler2D _RefractionTex;
			
			struct a2v {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 tangent : TANGENT; 
				float2 texcoord: TEXCOORD0;
			};
			
			struct v2f {
				float4 pos : SV_POSITION;
				float4 scrPos : TEXCOORD0;
				float4 uv : TEXCOORD1;
				float4 TtoW0 : TEXCOORD2;  
			    float4 TtoW1 : TEXCOORD3;  
			    float4 TtoW2 : TEXCOORD4; 
			};
			
			v2f vert (a2v v) {
				v2f o;
				VertexPositionInputs posInputs = GetVertexPositionInputs(v.vertex.xyz);
                o.pos = posInputs.positionCS;

				
				o.scrPos = ComputeScreenPos(posInputs.positionCS);

                //URP中被移除，没有完全对应的：ComputeGrabScreenPos(o.pos)
				
				o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
				o.uv.zw = TRANSFORM_TEX(v.texcoord, _BumpMap);
				
				float3 worldPos = posInputs.positionWS;  

                VertexNormalInputs normalInputs = GetVertexNormalInputs(v.normal, v.tangent);
                //可以一次性获得下面三个参数
				half3 worldNormal = normalInputs.normalWS;  
				half3 worldTangent = normalInputs.tangentWS;  
				half3 worldBinormal = normalInputs.bitangentWS; 
				//bitangent与binormal是一个意思的两种叫法

				o.TtoW0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);  
				o.TtoW1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);  
				o.TtoW2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);  
				
				return o;
			}
			
			half4 frag (v2f i) : SV_Target {		
				float3 worldPos = float3(i.TtoW0.w, i.TtoW1.w, i.TtoW2.w);
				half3 worldViewDir = normalize(_WorldSpaceCameraPos.xyz - worldPos);

				half3 bump = UnpackNormal(tex2D(_BumpMap, i.uv.zw));	

				float2 offset = bump.xy * _Distortion * _RefractionTex_TexelSize.xy;
				i.scrPos.xy = offset * i.scrPos.z + i.scrPos.xy;
				half3 refrCol = tex2D(_RefractionTex, i.scrPos.xy/i.scrPos.w).rgb;

				bump = normalize(half3(dot(i.TtoW0.xyz, bump), dot(i.TtoW1.xyz, bump), dot(i.TtoW2.xyz, bump)));
				half3 reflDir = reflect(-worldViewDir, bump);
				half4 texColor = tex2D(_MainTex, i.uv.xy);
				half3 reflCol = texCUBE(_Cubemap, reflDir).rgb * texColor.rgb;
				
				half3 finalColor = reflCol * (1 - _RefractAmount) + refrCol * _RefractAmount;
				
				return half4(finalColor, 1);
			}
			
			ENDHLSL
		}
	} 
 	FallBack "Packages/com.unity.render-pipelines.universal/FallbackError"
}
