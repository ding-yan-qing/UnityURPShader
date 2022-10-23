Shader "Unlit/Chapter11-Billboard"
{
    Properties {
		_MainTex ("Main Tex", 2D) = "white" {}
		_Color ("Color Tint", Color) = (1, 1, 1, 1)
		_VerticalBillboarding ("Vertical Restraints", Range(0, 1)) = 1 
	}
	SubShader {
		Tags {"RenderPipeline" = "UniversalPipeline" "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" "DisableBatching"="True"}
        //取消批处理会带来一定的性能下降
		
		Pass { 
			Tags { "LightMode"="UniversalForward" }
			
			ZWrite Off
			Blend SrcAlpha OneMinusSrcAlpha
			Cull Off
            //以上设置在顶点动画1中，及之前文章中做了讲解
		
			HLSLPROGRAM

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			
			#pragma vertex vert
			#pragma fragment frag

            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
			half4 _Color;
			float _VerticalBillboarding;
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
			
			v2f vert (a2v v) {
				v2f o;
				
				// 主要效果在模型空间实现，下面代码用来固定模型空间中的锚点（即原点）
				float3 center = float3(0, 0, 0);
                //把观察方向变换到模型空间
				float3 viewer = mul(unity_WorldToObject,float4(_WorldSpaceCameraPos, 1));
				
				float3 normalDir = viewer - center;

				normalDir.y =normalDir.y * _VerticalBillboarding;
                //此处公式理解比较抽象，建议自己画示意图理解。本人的理解是如果_VerticalBillboarding为1，法线方向永远等于观察方向，观察方向改编法线则进行相等改编，即永远正面观察模型。而_VerticalBillboarding为0，法线方向（0，0,1）则与UP方向（0，1,0）垂直，进而由法线和right叉积得到的up'永远指向（0,1，0）。
				normalDir = normalize(normalDir);
				float3 upDir = abs(normalDir.y) > 0.999 ? float3(0, 0, 1) : float3(0, 1, 0);
                //防止法线方向和向上方向平行（如果平行，那么叉积得到的结果将是错误的）
				float3 rightDir = normalize(cross(upDir, normalDir));
				upDir = normalize(cross(normalDir, rightDir));
				
				float3 centerOffs = v.vertex.xyz - center;
				float3 localPos = center + rightDir * centerOffs.x + upDir * centerOffs.y + normalDir * centerOffs.z;
                //本质是把模型空间下的顶点向量与上面得到的正交基矢量进行矩阵运算，得到新的空间位置
              
				o.pos = TransformObjectToHClip(float4(localPos, 1));
				o.uv = TRANSFORM_TEX(v.texcoord,_MainTex);

				return o;
			}
			
			half4 frag (v2f i) : SV_Target {
				half4 c = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);
				c.rgb *= _Color.rgb;
				
				return c;
			}
			
			ENDHLSL
		}
	} 
    FallBack "Packages/com.unity.render-pipelines.universal/FallbackError"
}
