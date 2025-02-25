Shader "Custom/DynamicFogWithMask" {
	Properties {
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_FogDensity ("Fog Density", Float) = 1.0
		_FogColor ("Fog Color", Color) = (1, 1, 1, 1)
		_FogStart ("Fog Start", Float) = 0.0
		_FogEnd ("Fog End", Float) = 1.0
		_NoiseTex("Noise Texture", 2D) = "white" {}
		_FogSpeed ("Fog Speed", Float) = 0.1	
		_NoiseAmount("Noise Amount", Float) = 25

		//遮罩测试
		_MaskCenter("遮罩中心", Vector) = (0,0,0,0)
		_MaskRadius("遮罩半径", Float) = 5
		_Feather("羽化范围", Range(0,5)) = 1
	}

	SubShader {
		CGINCLUDE

		#include "UnityCG.cginc"	    
		
		float4x4 _FrustumCornersRay;
		
		sampler2D _MainTex;
		half4 _MainTex_TexelSize;
		sampler2D _CameraDepthTexture;
		half _FogDensity;
		fixed4 _FogColor;
		float _FogStart;
		float _FogEnd;
		sampler2D _NoiseTex;
		half _NoiseAmount;
		half _FogSpeed;
		float _Roughness, _Persistance;

		float3 _MaskCenter;
		float _MaskRadius, _Feather;
		
		struct v2f {
			float4 pos : SV_POSITION;
			float2 uv : TEXCOORD0;
			float2 uv_depth : TEXCOORD1;
			float4 interpolatedRay : TEXCOORD2;
		};
		
		v2f vert(appdata_img v) {
			v2f o;
			o.pos = UnityObjectToClipPos(v.vertex);
			
			o.uv = v.texcoord;
			o.uv_depth = v.texcoord;
			
			#if UNITY_UV_STARTS_AT_TOP
			if (_MainTex_TexelSize.y < 0)
				o.uv_depth.y = 1 - o.uv_depth.y;
			#endif
			
			int index = 0;
			if (v.texcoord.x < 0.5 && v.texcoord.y < 0.5) {
				index = 0;
			} else if (v.texcoord.x > 0.5 && v.texcoord.y < 0.5) {
				index = 1;
			} else if (v.texcoord.x > 0.5 && v.texcoord.y > 0.5) {
				index = 2;
			} else {
				index = 3;
			}
			#if UNITY_UV_STARTS_AT_TOP
			if (_MainTex_TexelSize.y < 0)
				index = 3 - index;
			#endif
			
			o.interpolatedRay = _FrustumCornersRay[index];
				 	 
			return o;
		}	
	

		// 在雾效计算前添加遮罩计算
		float CalculateFogMask(float3 worldPos)
		{
			float distanceToCenter = distance(worldPos, _MaskCenter);
			float mask = smoothstep(_MaskRadius, _MaskRadius + _Feather, distanceToCenter);
			return mask;
		}
		
		fixed4 frag(v2f i) : SV_Target {

			float linearDepth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv_depth));
			float3 worldPos = _WorldSpaceCameraPos + linearDepth * i.interpolatedRay.xyz;

			float speed = _Time.y * _FogSpeed;
			float noise = (tex2D(_NoiseTex, worldPos.xz / _NoiseAmount + speed).r - 0.5);		//根据位置采样噪声图
					
			float fogDensity = (_FogEnd - worldPos.y) / (_FogEnd - _FogStart);
			fogDensity = saturate(fogDensity * _FogDensity);
			//fogDensity = saturate(fogDensity * _FogDensity * (1 + noise));
			
			
			/*float fogMask = CalculateFogMask(worldPos);
			fogDensity *= fogMask;*/
			fixed4 finalColor = tex2D(_MainTex, i.uv);
			finalColor.rgb = lerp(finalColor.rgb, _FogColor.rgb, fogDensity);
			
			return finalColor;
		}
		
		ENDCG
		
		Pass {          	
			CGPROGRAM  
			
			#pragma vertex vert  
			#pragma fragment frag  
			  
			ENDCG
		}
	} 
	FallBack Off
}
