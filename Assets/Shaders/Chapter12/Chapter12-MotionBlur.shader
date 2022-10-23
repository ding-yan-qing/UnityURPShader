Shader "Unlit/Chapter12-MotionBlur"
{
    Properties {
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_BlurAmount ("Blur Amount", Float) = 1.0
	}
    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" }
        
        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
		#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

        CBUFFER_START(UnityPerMaterial)
            half _BlurAmount;
        CBUFFER_END

        TEXTURE2D(_MainTex);       SAMPLER(sampler_MainTex);

        struct appdata{
            float4 vertex : POSITION;
            float2 texcoord : TEXCOORD0;
        };

        struct v2f {
			float4 pos : SV_POSITION;
			half2 uv : TEXCOORD0;
        };
        v2f vert(appdata v) {
			v2f o;
			
			o.pos = TransformObjectToHClip(v.vertex);
			
			o.uv = v.texcoord;
					 
			return o;
		}

        half4 fragRGB (v2f i) : SV_Target {
			return half4(SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv).rgb, _BlurAmount);
		}
		
		half4 fragA (v2f i) : SV_Target {
			return SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);
		}
        //这个片元着色器为了维护渲染纹理的透明通道值，不让其受到混合时使用的透明度值的影响。
		
		ENDHLSL
		
		ZTest Always Cull Off ZWrite Off
		
		Pass {
			Blend SrcAlpha OneMinusSrcAlpha
			ColorMask RGB
            //颜色遮罩，即保留RGB通道,屏蔽alpha，即src的alpha = 0，这样可以得到上一帧单纯的虚化图，而不是颜色混合图。ColorMask 0 即只保留深度信息
            //DstColornew=SrcAlpha(=0) ×SrcColor+(1-SrcAlpha (= _BlurAmount))×DstColorold
			
			HLSLPROGRAM
			
			#pragma vertex vert  
			#pragma fragment fragRGB  
			
			ENDHLSL
		}
		
		Pass {   
			Blend One Zero
            // Csrc * 1+Cdst * 0，也就是说完全使用当前新绘制的Color,即src的A等于原始值，rgb都为0，而dst则相反。所以无论有没有上面一行代码效果呈现是一样的。
			ColorMask A
			   	
			HLSLPROGRAM  
			
			#pragma vertex vert  
			#pragma fragment fragA
			  
			ENDHLSL
		}
	}
    FallBack "Packages/com.unity.render-pipelines.universal/FallbackError"
}