Shader "Custom/Chapter9-Shadow"
{
    Properties {
		_Diffuse ("Diffuse", Color) = (1, 1, 1, 1)
		_Specular ("Specular", Color) = (1, 1, 1, 1)
		_Gloss ("Gloss", Range(8.0, 256)) = 20
        [Toggle(_AdditionalLights)] 
        _AddLights ("AddLights", Float) = 1
	}
	SubShader {
		Tags { 
            "RenderPipeline" = "UniversalPipeline"
            "RenderType"="Opaque" }

            HLSLINCLUDE
            //SubShader下用HLSLINCLUDE而不是HLSLPROGRAM
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            CBUFFER_START(UnityPerMaterial)
            half4 _Diffuse;
			half4 _Specular;
			float _Gloss;
            CBUFFER_END

            struct a2v {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
                float4 tangent : TANGENT;
			};
			
			struct v2f {
				float4 pos : SV_POSITION;
				float3 worldNormal : TEXCOORD0;
				float3 worldPos : TEXCOORD1;

                //SHADOW_COORDS(2)
			};
            //把引用和变量放到了SubShader下，避免两个Pass重复写两遍
            ENDHLSL

		Pass {
			
			Tags { "LightMode"="UniversalForward" }
		
			HLSLPROGRAM

            #pragma shader_feature _AdditionalLights

			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS
			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
			#pragma multi_compile _ _SHADOWS_SOFT
            //接收阴影的变体关键字
			
			#pragma vertex vert
			#pragma fragment frag
			
			
			v2f vert(a2v v) {
				v2f o;

                VertexPositionInputs positionInputs = GetVertexPositionInputs(v.vertex.xyz);
                //获取不同空间下顶点位置信息的函数
				//o.pos = UnityObjectToClipPos(v.vertex);
                o.pos = positionInputs.positionCS;
                //CS = Clip Space 齐次坐标空间
                o.worldPos = positionInputs.positionWS;
                //WS = World Space
				VertexNormalInputs normalInputs = GetVertexNormalInputs(v.normal, v.tangent);
                //这个函数输入对象空间下发现与切线信息，可获得世界空间下法线、切线、副切的信息
				o.worldNormal = NormalizeNormalPerVertex(normalInputs.normalWS);
				
				//o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

                //TRANSFER_SHADOW(o);
				
				return o;
			}
			
			half4 frag(v2f i) : SV_Target {
				
                float4 shadowCoord = TransformWorldToShadowCoord(i.worldPos.xyz);
                //获取阴影坐标

                Light mainLight = GetMainLight(shadowCoord);
                
                half3 worldLightDir = normalize(TransformObjectToWorldDir(mainLight.direction));
                half3 diffuse = mainLight.color*_Diffuse.rgb * max(0, dot(i.worldNormal, worldLightDir));
                half3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos);
                half3 halfDir = normalize(worldLightDir + viewDir);
                half3 specular = mainLight.color * _Specular.rgb * pow(max(0, dot(i.worldNormal, halfDir)), _Gloss);
                half3 ambient = SampleSH(i.worldNormal);
                //另一种计算环境光的函数
                
                half atten = mainLight.distanceAttenuation;

                half3 color = ambient + (diffuse + specular) * atten;

                #ifdef _AdditionalLights
                int lightCount = GetAdditionalLightsCount();
                for(int index = 0; index < lightCount; index++){
                Light light = GetAdditionalLight(index, i.worldPos);     
                
                half3 diffuseAdd = light.color*_Diffuse.rgb * max(0, dot(i.worldNormal, light.direction));
                half3 halfDir = normalize(light.direction + viewDir);
                half3 specularAdd = light.color * _Specular.rgb * pow(max(0, dot(i.worldNormal, halfDir)), _Gloss);
                
                color += (diffuseAdd + specularAdd)*light.distanceAttenuation;
                }
                #endif
                
                return half4(color, 1.0);
                //以上参照《Unity Shader 入门精要》从Bulit-in 到URP （HLSL）Chapter9-ForwardRendering

			}
			
			ENDHLSL
		}
	
		Pass {
            Tags { "LightMode" = "ShadowCaster" }
            //ShadowCaster阴影光照模式

            Cull Off
            ZWrite On
            ZTest LEqual
            
            HLSLPROGRAM

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
            
            #pragma shader_feature _ALPHATEST_ON
            
            #pragma vertex vert
            #pragma fragment frag

            half3 _LightDirection;

			v2f vert(a2v i){
                v2f o;
                float3 worldPos = TransformObjectToWorld(i.vertex.xyz);
                float3 worldNormal = TransformObjectToWorldNormal(i.normal);
                o.pos = TransformWorldToHClip(ApplyShadowBias(worldPos, worldNormal, _LightDirection));
                //阴影专用裁剪空间坐标

                #if UNITY_REVERSED_Z
                    o.pos.z = min(o.pos.z, o.pos.w * UNITY_NEAR_CLIP_VALUE);
                #else
                    o.pos.z = max(o.pos.z, o.pos.w * UNITY_NEAR_CLIP_VALUE);
                #endif
                //判断是否在DirectX平台，决定是否反转坐标

                return o;
            
            }

            half4 frag(v2f i): SV_Target{

                return 0;
            }
            
            ENDHLSL

		}
	}
	FallBack "Packages/com.unity.render-pipelines.universal/FallbackError"
}
