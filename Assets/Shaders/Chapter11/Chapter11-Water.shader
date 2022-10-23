Shader "Unlit/Chapter11-Water"
{
    Properties {
		_MainTex ("Main Tex", 2D) = "white" {}
		_Color ("Color Tint", Color) = (1, 1, 1, 1)
		_Magnitude ("Distortion Magnitude", Float) = 1
 		_Frequency ("Distortion Frequency", Float) = 1
 		_InvWaveLength ("Distortion Inverse Wave Length", Float) = 10
 		_Speed ("Speed", Float) = 0.5
	}
	SubShader {

		Tags {"RenderPipeline" = "UniversalPipeline" "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" "DisableBatching"="True"}
        //DisableBatching关闭批处理，因为批处理会合并所有相关的模型，而这些模型各自的模型空间就会丢失，而本shader需要在模型空间操作顶点位置实现顶点动画
		
		Pass {
			Tags { "LightMode"="UniversalForward" }
			
			ZWrite Off
			Blend SrcAlpha OneMinusSrcAlpha
			Cull Off
            //关闭剔除功能，可以同时显示前面与后面
			
			HLSLPROGRAM

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

			#pragma vertex vert 
			#pragma fragment frag

            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
			half4 _Color;
			float _Magnitude;
			float _Frequency;
			float _InvWaveLength;
			float _Speed;
            CBUFFER_END

            TEXTURE2D(_MainTex);       SAMPLER(sampler_MainTex);

            struct a2v {
				float4 vertex : POSITION;
				float4 texcoord : TEXCOORD0;
			};
			
			struct v2f {
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
			};
			
			v2f vert(a2v v) {
				v2f o;
				
				float4 offset;
				offset.yzw = float3(0.0, 0.0, 0.0);
				offset.x = sin(_Frequency * _Time.y + v.vertex.x * _InvWaveLength + v.vertex.y * _InvWaveLength + v.vertex.z * _InvWaveLength) * _Magnitude;
				o.pos = TransformObjectToHClip(v.vertex + offset);
				
				o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
				o.uv +=  float2(0.0, _Time.y * _Speed);
				
				return o;
			}
			
			half4 frag(v2f i) : SV_Target {
				half4 c = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);
				c.rgb *= _Color.rgb;
				
				return c;
			} 
			
			ENDHLSL
		}
	}
    FallBack "Packages/com.unity.render-pipelines.universal/FallbackError"
}
