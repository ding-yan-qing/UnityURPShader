Shader "Custom/Chapter9-ForwardRendering"
{
    Properties {
		_Diffuse ("Diffuse", Color) = (1, 1, 1, 1)
		_Specular ("Specular", Color) = (1, 1, 1, 1)
		_Gloss ("Gloss", Range(8.0, 256)) = 20
		[Toggle(_AdditionalLights)] _AddLights ("AddLights", Float) = 1
		//多光源计算开关
	}
	SubShader {
		Tags { 
            "RenderPipeline" = "UniversalPipeline"
			//设置URP渲染
            "RenderType"="Opaque" 
			//渲染类型与之前相同
			}
		//用一个Pass可以完成ForwardRendering多个光照的渲染
		Pass {
			
			Tags { "LightMode"="UniversalForward" }
		//前向渲染光照类型改用"UniversalForward"
			HLSLPROGRAM
			
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			//URP引用标配
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			//光照渲染标配引用

			#pragma shader_feature _AdditionalLights
			//多光源计算的开关变量	
			
			#pragma vertex vert
			#pragma fragment frag
			
			CBUFFER_START(UnityPerMaterial)
            half4 _Diffuse;
			half4 _Specular;
			float _Gloss;
            CBUFFER_END
			
			struct a2v {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
			};
			
			struct v2f {
				float4 pos : SV_POSITION;
				float3 worldNormal : TEXCOORD0;
				float3 worldPos : TEXCOORD1;
			};
			
			v2f vert(a2v v) {
				v2f o;
				o.pos = TransformObjectToHClip(v.vertex);
				
				o.worldNormal = TransformObjectToWorldNormal(v.normal);
				
				o.worldPos = TransformObjectToWorld(v.vertex.xyz);
				
				return o;
			}
			//以上主要的变换矩阵有对应的修改
			
			half4 frag(v2f i) : SV_Target {
				
                Light mainLight = GetMainLight();
				//获取光源信息的函数
                half3 worldLightDir = normalize(TransformObjectToWorldDir(mainLight.direction));
                half3 diffuse = mainLight.color*_Diffuse.rgb * max(0, dot(i.worldNormal, worldLightDir));
                half3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos);
                half3 halfDir = normalize(worldLightDir + viewDir);
                half3 specular = mainLight.color * _Specular.rgb * pow(max(0, dot(i.worldNormal, halfDir)), _Gloss);
                half3 ambient = half3(unity_SHAr.w, unity_SHAg.w, unity_SHAb.w);
				//计算ambient
                half atten = mainLight.distanceAttenuation;

				half3 color = ambient + (diffuse + specular) * atten;
				//计算主光源光照

				#ifdef _AdditionalLights
				int lightCount = GetAdditionalLightsCount();
				//获取AddLight的数量和ID
				for(int index = 0; index < lightCount; index++){
                Light light = GetAdditionalLight(index, i.worldPos);     
				//获取其它的副光源世界位置
				
                half3 diffuseAdd = light.color*_Diffuse.rgb * max(0, dot(i.worldNormal, light.direction));
				half3 halfDir = normalize(light.direction + viewDir);
                half3 specularAdd = light.color * _Specular.rgb * pow(max(0, dot(i.worldNormal, halfDir)), _Gloss);
				//计算副光源的高光颜色
				color += (diffuseAdd + specularAdd)*light.distanceAttenuation;
                //上面单颜色增加新计算的颜色
				}
				#endif
				
				return half4(color, 1.0);
			}
			
			ENDHLSL
		}
	
		
	}
	FallBack "Packages/com.unity.render-pipelines.universal/FallbackError"
}
