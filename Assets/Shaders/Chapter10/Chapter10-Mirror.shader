Shader "Custom/Chapter10-Mirror"
{
    //基本和built-in版无差别
    Properties {
		_MainTex ("Main Tex", 2D) = "white" {}
	}
	SubShader {
		Tags { 
            "RenderPipeline"="UniversalPipeline"
            "RenderType"="Opaque" 
            "Queue"="Geometry"}
		
		Pass {
			Tags {"Lighting"="UniversalForward"}

            HLSLPROGRAM
 
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			
			#pragma vertex vert
			#pragma fragment frag
			
			sampler2D _MainTex;
			
			struct a2v {
				float4 vertex : POSITION;
				float3 texcoord : TEXCOORD0;
			};
			
			struct v2f {
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
			};
			
			v2f vert(a2v v) {
				v2f o;
				o.pos = TransformObjectToHClip(v.vertex.xyz);
				o.uv = v.texcoord;
				o.uv.x = 1 - o.uv.x;
				
				return o;
			}
			
			half4 frag(v2f i) : SV_Target {
				return tex2D(_MainTex, i.uv);
			}
			
			ENDHLSL
		}
	} 
 	FallBack "Packages/com.unity.render-pipelines.universal/FallbackError"
}
