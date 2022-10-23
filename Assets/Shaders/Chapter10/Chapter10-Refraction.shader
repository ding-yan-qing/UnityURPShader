Shader "Custom/Chapter10-Refraction"
{
    Properties{
        _Color("Color Tint",Color)=(1,1,1,1)
        _RefractColor("Refraction Color",Color)=(1,1,1,1)
        _RefractAmount("Refraction Amount",Range(0,1))=1
        _RefractRatio("Refraction Ratio",Range(0.1,1))=0.5
        _Cubemap("Refraction Cubemap",Cube)="_Skybox"{}
    }
    SubShader {
		Tags { 
            "RenderPipeline" = "UniversalPipeline"
            "RenderType"="Opaque" 
            "Queue"="Geometry"}
		
		Pass { 
			Tags { "LightMode"="UniversalForward" }
		
			HLSLPROGRAM

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            CBUFFER_START(UnityPerMaterial)
            half4 _Color;
			half4 _RefractColor;
			float _RefractAmount;
			float _RefractRatio;
            CBUFFER_END
				
			TEXTURECUBE(_Cubemap);
			SAMPLER(sampler_Cubemap);
            //材质相关不用放在UnityPerMaterial里

			#pragma vertex vert
			#pragma fragment frag
			
			struct a2v {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
			};
			
			struct v2f {
				float4 pos : SV_POSITION;
				float3 worldPos : TEXCOORD0;
				half3 worldNormal : TEXCOORD1;
				half3 worldViewDir : TEXCOORD2;
				half3 worldRefr : TEXCOORD3;
				//SHADOW_COORDS(4)
			};

            v2f vert(a2v v){
                v2f o;
                o.pos = TransformObjectToHClip(v.vertex);
                o.worldNormal = TransformObjectToWorldNormal(v.normal);
                o.worldPos = TransformObjectToWorld(v.vertex.xyz);
                o.worldViewDir = GetCameraPositionWS() - o.worldPos;
                o.worldRefr = refract(-normalize(o.worldViewDir),normalize(o.worldNormal),_RefractRatio);
                //TRANSFER_SHADOW(o);
                return o;
            }

            half4 frag(v2f i) : SV_Target{
				float4 shadowCoord = TransformWorldToShadowCoord(i.worldPos);
				Light mainLight = GetMainLight(shadowCoord);
				half3 lightDir = normalize(mainLight.direction);
				half3 ambient = SampleSH(i.worldNormal);
				half3 refraction = SAMPLE_TEXTURECUBE(_Cubemap, sampler_Cubemap, i.worldRefr).rgb * _RefractColor.rgb;
                //此处函数有变化，整体变化不大
				half3 diffuse = mainLight.color.rgb * _Color.rgb * saturate(dot(i.worldNormal, lightDir));
                half atten = mainLight.distanceAttenuation;
				half3 color = ambient + lerp(diffuse, refraction, _RefractAmount)*atten; 
				return half4(color, 1.0);

            }

            ENDHLSL
        }

        UsePass "Universal Render Pipeline/Lit/ShadowCaster"
        //阴影可以URP内置Pass计算
    }
    FallBack "Packages/com.unity.render-pipelines.universal/FallbackError"
}
