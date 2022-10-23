Shader "Unlit/Chapter12-EdgeDetection"
{
    Properties {
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_EdgeOnly ("Edge Only", Float) = 1.0
		_EdgeColor ("Edge Color", Color) = (0, 0, 0, 1)
		_BackgroundColor ("Background Color", Color) = (1, 1, 1, 1)
	}
	SubShader {
        Tags { "RenderPipeline" = "UniversalPipeline" }
        ZTest Always Cull Off ZWrite Off
        //基本是后处理shader的必备设置，放置场景中的透明物体渲染错误
		//注意进行该设置后，shader将在完成透明物体的渲染后起作用，即RenderPassEvent.AfterRenderingTransparents后
		Pass {  
			
			HLSLPROGRAM 
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			
			#pragma vertex vert  
			#pragma fragment fragSobel

            CBUFFER_START(UnityPerMaterial)
            uniform half4 _MainTex_TexelSize;
            //_TexelSize对应每个纹素的大小（纹素是纹理的组成单位），卷积采样需要依据纹素的大小
			half _EdgeOnly;
			half4 _EdgeColor;
			half4 _BackgroundColor;
            CBUFFER_END

            TEXTURE2D(_MainTex);       SAMPLER(sampler_MainTex);

            struct appdata
            {
                float4 vertex : POSITION;
                float2 texcoord : TEXCOORD0;
            };

            struct v2f {
				float4 pos : SV_POSITION;
				half2 uv[9] : TEXCOORD0;
                //存储边缘监测时需要的纹理坐标
			};

            v2f vert(appdata v) {
				v2f o;
				o.pos = TransformObjectToHClip(v.vertex);
				
				half2 uv = v.texcoord;
				
				o.uv[0] = uv + _MainTex_TexelSize.xy * half2(-1, -1);
				o.uv[1] = uv + _MainTex_TexelSize.xy * half2(0, -1);
				o.uv[2] = uv + _MainTex_TexelSize.xy * half2(1, -1);
				o.uv[3] = uv + _MainTex_TexelSize.xy * half2(-1, 0);
				o.uv[4] = uv + _MainTex_TexelSize.xy * half2(0, 0);
				o.uv[5] = uv + _MainTex_TexelSize.xy * half2(1, 0);
				o.uv[6] = uv + _MainTex_TexelSize.xy * half2(-1, 1);
				o.uv[7] = uv + _MainTex_TexelSize.xy * half2(0, 1);
				o.uv[8] = uv + _MainTex_TexelSize.xy * half2(1, 1);
                //九个数组元素对应了3*3卷积核相对于被作用的纹理坐标的相对位置，在顶点着色器中完成该步骤可以减少运算量。
						 
				return o;
			}
			
			half luminance(half4 color) {
				return  0.2125 * color.r + 0.7154 * color.g + 0.0721 * color.b; 
                //返回色彩饱和度为0的亮度值
			}
			//Sobel()主要用于计算梯度值，梯度值是边缘监测实现的核心
			half Sobel(v2f i) {
				const half Gx[9] = {-1,  0,  1,
									-2,  0,  2,
									-1,  0,  1};
				const half Gy[9] = {-1, -2, -1,
									0,  0,  0,
									1,  2,  1};		
                //X轴方向与Y轴方向的一对卷积核
				
				half texColor;
				half edgeX = 0;
				half edgeY = 0;
				for (int it = 0; it < 9; it++) {
					texColor = luminance(SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv[it]));
                    //得到亮度值
					edgeX += texColor * Gx[it];
					edgeY += texColor * Gy[it];
                    //与卷积核的运算公式是相乘求和
				}
				
				half edge = 1 - abs(edgeX) - abs(edgeY);
                //得到梯度值，公式讲解见《入门精要》
				
				return edge;
			}
			
			half4 fragSobel(v2f i) : SV_Target {
				half edge = Sobel(i);
				
				half4 withEdgeColor = lerp(_EdgeColor, SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv[4]), edge);
				half4 onlyEdgeColor = lerp(_EdgeColor, _BackgroundColor, edge);
				return lerp(withEdgeColor, onlyEdgeColor, _EdgeOnly);
 			}
			
			ENDHLSL
		}  
	}
    FallBack "Packages/com.unity.render-pipelines.universal/FallbackError"
}
