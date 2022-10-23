Shader "Unlit/Chapter11-VertexAnimationWIthShadow"
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
		
        HLSLINCLUDE
            
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

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
            float3 normal : NORMAL;
            float4 tangent : TANGENT;
		};
			
		struct v2f {
			float4 pos : SV_POSITION;
            //float3 worldNormal : TEXCOORD0;
			//float3 worldPos : TEXCOORD1;
			float2 uv : TEXCOORD0;
		};
        ENDHLSL

		Pass {
			Tags { "LightMode"="UniversalForward" }
			
			ZWrite Off
			Blend SrcAlpha OneMinusSrcAlpha
			Cull Off
			
			HLSLPROGRAM

			#pragma vertex vert 
			#pragma fragment frag
			
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

        Pass{
            Tags { "LightMode" = "ShadowCaster" }

            Cull Off
            ZWrite On
            ZTest LEqual
            
            HLSLPROGRAM

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
            
            #pragma shader_feature _ALPHATEST_ON
            
            #pragma vertex vert
            #pragma fragment frag

            half3 _LightDirection;

			v2f vert(a2v v){
                v2f o;
                float4 offset;
				offset.yzw = float3(0.0, 0.0, 0.0);
				offset.x = sin(_Frequency * _Time.y + v.vertex.x * _InvWaveLength + v.vertex.y * _InvWaveLength + v.vertex.z * _InvWaveLength) * _Magnitude;
                float3 worldPos = TransformObjectToWorld(v.vertex.xyz + offset.xyz);

                float3 worldNormal = TransformObjectToWorldNormal(v.normal);
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
