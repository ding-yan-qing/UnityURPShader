Shader "Unlit/Chapter13-EdgeDetectNormalAndDepth"
{
    Properties {
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_EdgeOnly ("Edge Only", Float) = 1.0
		_EdgeColor ("Edge Color", Color) = (0, 0, 0, 1)
		_BackgroundColor ("Background Color", Color) = (1, 1, 1, 1)
		_SampleDistance ("Sample Distance", Float) = 1.0
		_Sensitivity ("Sensitivity", Vector) = (1, 1, 1, 1)
	}
    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" }
        
        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
		#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

        CBUFFER_START(UnityPerMaterial)
            half4 _MainTex_TexelSize;
            half _EdgeOnly;
            half4 _EdgeColor;
            half4 _BackgroundColor;
            float _SampleDistance;
            half4 _Sensitivity;
        CBUFFER_END

        TEXTURE2D(_MainTex);       SAMPLER(sampler_MainTex);
        TEXTURE2D(_CameraDepthTexture);       SAMPLER(sampler_CameraDepthTexture);
        TEXTURE2D(_CameraNormalsTexture);       SAMPLER(sampler_CameraNormalsTexture);
        //TEXTURE2D(_CameraNormalsTexture);       SAMPLER(sampler_CameraNormalsTexture);
        //如果在URP Asset设置下勾选 depth texture选项系统会自动生成一张以_CameraDepthTexture为名的深度图，抽时间会写一篇相关文章并把链接补充到本篇中。

        struct appdata{
            float4 vertex : POSITION;
            float2 texcoord : TEXCOORD0;
        };

        struct v2f {
			float4 pos : SV_POSITION;
			half2 uv[5] : TEXCOORD0;
        };

        v2f vert(appdata v) {
			v2f o;
			
			o.pos = TransformObjectToHClip(v.vertex);
			
			half2 uv = v.texcoord;
            o.uv[0] = uv;

            #if UNITY_UV_STARTS_AT_TOP
			if (_MainTex_TexelSize.y < 0)
				uv.y = 1 - uv.y;
			#endif

            o.uv[1] = uv + _MainTex_TexelSize.xy * half2(1,1) * _SampleDistance;
            o.uv[2] = uv + _MainTex_TexelSize.xy * half2(-1,-1) * _SampleDistance;
            o.uv[3] = uv + _MainTex_TexelSize.xy * half2(-1,1) * _SampleDistance;
            o.uv[4] = uv + _MainTex_TexelSize.xy * half2(1,-1) * _SampleDistance;

            return o;
        }

        half CheckSame(half2 centerN, half2 sampleN, half centerD, half sampleD) {
			half2 centerNormal = centerN;
			float centerDepth = centerD;
			half2 sampleNormal = sampleN;
			float sampleDepth = sampleD;
			
			// difference in normals
			// do not bother decoding normals - there's no need here
			half2 diffNormal = abs(centerNormal - sampleNormal) * _Sensitivity.x;
			int isSameNormal = (diffNormal.x + diffNormal.y) < 0.1;
			// difference in depth
			float diffDepth = abs(centerDepth - sampleDepth) * _Sensitivity.y;
			// scale the required threshold by the distance
			int isSameDepth = diffDepth < 0.1 * centerDepth;
			
			// return:
			// 1 - if normals and depth are similar enough
			// 0 - otherwise
			return isSameNormal * isSameDepth ? 1.0 : 0.0;
		}
		
		half4 fragRobertsCrossDepthAndNormal(v2f i) : SV_Target {
			half2 sample1Normal = SAMPLE_TEXTURE2D(_CameraNormalsTexture, sampler_CameraNormalsTexture, i.uv[1]);
			half2 sample2Normal = SAMPLE_TEXTURE2D(_CameraNormalsTexture, sampler_CameraNormalsTexture, i.uv[2]);
			half2 sample3Normal = SAMPLE_TEXTURE2D(_CameraNormalsTexture, sampler_CameraNormalsTexture, i.uv[3]);
			half2 sample4Normal = SAMPLE_TEXTURE2D(_CameraNormalsTexture, sampler_CameraNormalsTexture, i.uv[4]);
			//法线贴图只存储x与y两个值，z值默认是1，在解码之后会补上z值，并把x,y由（0,1）转换到（-1,1）

			half sample1Depth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture,i.uv[1]), _ZBufferParams);
			half sample2Depth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture,i.uv[2]), _ZBufferParams);
			half sample3Depth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture,i.uv[3]), _ZBufferParams);
			half sample4Depth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture,i.uv[4]), _ZBufferParams);
			//得到view空间的线性深度值

			half edge = 1.0;
			
			edge *= CheckSame(sample1Normal, sample2Normal, sample1Depth, sample2Depth);
			edge *= CheckSame(sample3Normal, sample4Normal, sample3Depth, sample4Depth);
			
			half4 withEdgeColor = lerp(_EdgeColor, SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv[0]), edge);
			half4 onlyEdgeColor = lerp(_EdgeColor, _BackgroundColor, edge);
			
			return lerp(withEdgeColor, onlyEdgeColor, _EdgeOnly);
		}
		
		ENDHLSL
		
		Pass { 
			ZTest Always Cull Off ZWrite Off
			
			HLSLPROGRAM      
			
			#pragma vertex vert  
			#pragma fragment fragRobertsCrossDepthAndNormal
			
			ENDHLSL  
		}
	} 
	FallBack "Packages/com.unity.render-pipelines.universal/FallbackError"
}
