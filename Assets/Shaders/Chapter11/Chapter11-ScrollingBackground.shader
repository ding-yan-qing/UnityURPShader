Shader "Unlit/Chapter11-ScrollingBackground"
{
    Properties{
        _MainTex ("Base Layer (RGB)", 2D) = "white"{}
        _DetailTex ("2nd Layer (RGB)", 2D) = "white"{}
        _ScrollX ("Base layer Scroll Speed", Float) = 1.0
        _Scroll2X ("2nd layer Scroll Speed", Float) = 1.0
        _Multiplier ("Layer Multiplier", Float) = 1
    }

    SubShader{
        Tags{"RenderPipeline" = "UniversalPipeline" "Queue" = "Geometry" "RenderType" = "Opaque"}

        Pass{

            Tags{
                "LightMode" = "UniversalForward"
            }

            HLSLPROGRAM

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            #pragma vertex vert
            #pragma fragment frag

            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
			float4 _DetailTex_ST;
			float _ScrollX;
			float _Scroll2X;
			float _Multiplier;
            CBUFFER_END

            TEXTURE2D(_MainTex);       SAMPLER(sampler_MainTex);
            TEXTURE2D(_DetailTex);       SAMPLER(sampler_DetailTex);

            struct a2v {
				float4 vertex : POSITION;
				float4 texcoord : TEXCOORD0;
                //用一个四维的TEXCOORD 采样两个二维的纹理，以减少占用的插值寄存器空间。
			};
			
			struct v2f {
				float4 pos : SV_POSITION;
				float4 uv : TEXCOORD0;
                //float2 uv2 : TEXCOORD3;
			};

            v2f vert (a2v v) {
				v2f o;
				o.pos = TransformObjectToHClip(v.vertex);
				o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex) + frac(float2(_ScrollX, 0.0) * _Time.y);
				o.uv.zw = TRANSFORM_TEX(v.texcoord, _DetailTex) + frac(float2(_Scroll2X, 0.0) * _Time.y);
                //frac函数用于返回变量的小数部分，以上两段代码整体实现纹理延X轴方向循环移动
				//纹理贴图wrap mode 需要设置为repeat
				return o;
			}
			
			float4 frag (v2f i) : SV_Target {
				float4 firstLayer = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv.xy);
				float4 secondLayer = SAMPLE_TEXTURE2D(_DetailTex, sampler_DetailTex, i.uv.zw);
				
				float4 c = lerp(firstLayer, secondLayer, secondLayer.a);
                //secondLayer.a值为1则完全显示第二张图，为0则完全显示第一张图
				c.rgb *= _Multiplier;
				
				return c;
			}

            ENDHLSL
        }
    }
    FallBack "Packages/com.unity.render-pipelines.universal/FallbackError"

}
