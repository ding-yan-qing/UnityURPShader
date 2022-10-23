Shader "Unlit/Chapter11-ImageSequenceAnimation"
{
    Properties{
        _Color ("Color Tint", Color) = (1,1,1,1)
        _MainTex ("Image Sequence", 2D) = "white"{}
        _HorizontalAmount ("Horizontal Amount", Float) = 4
        _VerticalAmount ("Vertical Amount", Float) = 4
        //序列帧纹理的行列数
        _Speed ("Speed", Range(1,100)) = 30
        //动画速度
    }

    SubShader{
        Tags{
            "RenderPipeline" = "UniversalPipeline" "Queue" = "Transparent" "IgnoreProjector" = "True" "RenderType" = "Transparent"
            //序列帧图像通常是透明纹理
            //如果提供了 IgnoreProjector 标签并且值为“True”，则使用此着色器的对象不会受到投影器的影响。这对半透明对象非常有用，因为投影器无法影响它们。
        }

        Pass{
            Tags{
                "LightMode" = "UniversalForward"
            }

            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha
            //透明物体基本设置，关闭深度写入，开启混合模式

            HLSLPROGRAM

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            #pragma vertex vert
            #pragma fragment frag

            CBUFFER_START(UnityPerMaterial)
            half4 _Color;
            float4 _MainTex_ST;
			float _HorizontalAmount;
			float _VerticalAmount;
            float _Speed;
            CBUFFER_END

            TEXTURE2D(_MainTex);       SAMPLER(sampler_MainTex);

            struct a2v {  
			    float4 vertex : POSITION; 
			    float2 texcoord : TEXCOORD0;
			};  
			
			struct v2f {  
			    float4 pos : SV_POSITION;
			    float2 uv : TEXCOORD0;
			};  

            v2f vert (a2v v){
                v2f o;
                o.pos = TransformObjectToHClip(v.vertex);
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                //TRANSFORM_TEX方法比较简单，就是将模型顶点的uv和Tiling、Offset两个变量进行运算，计算出实际显示用的定点uv。
                return o;
            }

            half4 frag (v2f i) : SV_Target{
				float time = floor(_Time.y * _Speed);  
                //_Time（float4） 是自该场景加载开始所经过的时间，四个分量的值分别是（t/20,t,2t,3t）
                //函数floor 为向下取整
				float row = floor(time / _HorizontalAmount);
				float column = time - row * _HorizontalAmount;
                //该算法不能实现特效的循环，而且在shader中调用时间参数似乎开销很大，效果一般

                //half2 uv = float2(i.uv.x /_HorizontalAmount, i.uv.y / _VerticalAmount);
  				//uv.x += column / _HorizontalAmount;
  				//uv.y -= row / _VerticalAmount;

                half2 uv = i.uv + half2(column, row);
                //大概是因为URP底层使用的是DX，所以row取负会出现问题
                uv.x /= _HorizontalAmount;
                uv.y /= _VerticalAmount;

                half4 c = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv);
                // 贴图采样方法有变化，由tex2D(Tex, texcoords)变为SAMPLE_TEXTURE2D(textureName, samplerName, texcoord)
                c.rgb *= _Color;
                
                return c;
            }
            ENDHLSL

        }

    }
    FallBack "Packages/com.unity.render-pipelines.universal/FallbackError"
}
