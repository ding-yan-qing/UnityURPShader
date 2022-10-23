Shader "Custom/Chapter10-Reflection"
{
    Properties{
        _Color("Color Tint",Color)=(1,1,1,1)
        _ReflectColor("Reflection Color",Color)=(1,1,1,1)
        _ReflectAmount("Reflection Amount",Range(0,1))=1
        _Cubemap("Reflection Cubemap",cube)="_Skybox"{}
    }
    SubShader {
		Tags {
			"RenderPipeline"="UniversalPipeline"
			"Queue"="Geometry" 
            "RenderType"="Opaque"
		}
		Pass {
			Tags {"LightMode"="UniversalForward"}
 
			HLSLPROGRAM
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
 
			#pragma vertex vert
			#pragma fragment frag
 
 
            CBUFFER_START(UnityPerMaterial)
			half4 _Color;
			half4 _ReflectColor;
			half _ReflectAmount;
            CBUFFER_END
 
			TEXTURECUBE(_Cubemap);
			SAMPLER(sampler_Cubemap);

			struct a2v {
				float4 vertex : POSITION;
				half3 normal : NORMAL;
			};
 
			struct v2f {
				float4 pos : SV_POSITION;
				half3 worldPos : TEXCOORD0;
				half3 worldNormal : TEXCOORD1;
				half3 worldViewDir : TEXCOORD2;
				half3 worldRefl : TEXCOORD3;
			};
 
			v2f vert(a2v v) {
				v2f o;
				o.pos = TransformObjectToHClip(v.vertex.xyz);
				o.worldPos = TransformObjectToWorld(v.vertex.xyz);
				o.worldNormal = TransformObjectToWorldNormal(v.normal);
				o.worldViewDir = GetCameraPositionWS() - o.worldPos;
				o.worldRefl = reflect(-o.worldViewDir, o.worldNormal);

				return o;
			}
 
			half4 frag(v2f i): SV_Target {
				half3 worldNormal = normalize(i.worldNormal);
				float4 shadowCoord = TransformWorldToShadowCoord(i.worldPos);
				Light mainLight = GetMainLight(shadowCoord);
				half3 lightDir = normalize(mainLight.direction);
				half3 ambient = SampleSH(i.worldNormal);
				half3 diffuse = mainLight.color.rgb * _Color.rgb * saturate(dot(i.worldNormal, lightDir));
				half3 reflection = SAMPLE_TEXTURECUBE(_Cubemap, sampler_Cubemap, i.worldRefl).rgb * _ReflectColor.rgb;
                half atten = mainLight.distanceAttenuation;
				half3 color = ambient + lerp(diffuse, reflection, _ReflectAmount)*atten;

				return half4(color, 1.0);
			}
 
			ENDHLSL
		}

        UsePass "Universal Render Pipeline/Lit/ShadowCaster"
	}
    FallBack "Packages/com.unity.render-pipelines.universal/FallbackError"
}
