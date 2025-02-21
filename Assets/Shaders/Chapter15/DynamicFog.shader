Shader "Custom/DynamicFog" {
	Properties {
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_FogDensity ("Fog Density", Float) = 1.0
		_FogColor ("Fog Color", Color) = (1, 1, 1, 1)
		_FogStart ("Fog Start", Float) = 0.0
		_FogEnd ("Fog End", Float) = 1.0
		_NoiseTex ("Noise Texture", 2D) = "white" {}
		_FogSpeed ("Fog Speed", Float) = 0.1	

		_Persistance("Perlin Persistance", Range(0, 1)) = 0.4
		_Roughness("Perlin Roughness", Range(1, 8)) = 3
	}
	SubShader {
		CGINCLUDE

		//#pragma target 3.0 
		#include "Random.cginc"
		#include "UnityCG.cginc"

	    #define OCTAVES 4 
		
		float4x4 _FrustumCornersRay;
		
		sampler2D _MainTex;
		half4 _MainTex_TexelSize;
		sampler2D _CameraDepthTexture;
		half _FogDensity;
		fixed4 _FogColor;
		float _FogStart;
		float _FogEnd;
		sampler2D _NoiseTex;
		half _FogSpeed;
		float _Roughness, _Persistance;
		
		struct v2f {
			float4 pos : SV_POSITION;
			float2 uv : TEXCOORD0;
			float2 uv_depth : TEXCOORD1;
			//float4 screenPos : TEXCOORD2;
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

		float easeIn(float interpolator) {
			return interpolator * interpolator;
		}

		float easeOut(float interpolator) {
			return 1 - easeIn(1 - interpolator);
		}

		float easeInOut(float interpolator) {
			float easeInValue = easeIn(interpolator);
			float easeOutValue = easeOut(interpolator);
			return lerp(easeInValue, easeOutValue, interpolator);
		}

		float perlinNoise(float3 value) {
			float3 fraction = frac(value);

			float interpolatorX = easeInOut(fraction.x);
			float interpolatorY = easeInOut(fraction.y);
			float interpolatorZ = easeInOut(fraction.z);

			float cellNoiseZ[2];
			[unroll]
			for (int z = 0; z <= 1; z++) {
				float cellNoiseY[2];
				[unroll]
				for (int y = 0; y <= 1; y++) {
					float cellNoiseX[2];
					[unroll]
					for (int x = 0; x <= 1; x++) {
						float3 cell = floor(value) + float3(x, y, z);
						float3 cellDirection = rand3dTo3d(cell) * 2 - 1;
						float3 compareVector = fraction - float3(x, y, z);
						cellNoiseX[x] = dot(cellDirection, compareVector);
					}
					cellNoiseY[y] = lerp(cellNoiseX[0], cellNoiseX[1], interpolatorX);
				}
				cellNoiseZ[z] = lerp(cellNoiseY[0], cellNoiseY[1], interpolatorY);
			}
			float noise = lerp(cellNoiseZ[0], cellNoiseZ[1], interpolatorZ);
			return noise;
		}

		float sampleLayeredNoise(float3 value, float persistance, float roughness) {
			float noise = 0;
			float frequency = 1;
			float factor = 1;

			[unroll]
			for (int i = 0; i < OCTAVES; i++) {
				noise = noise + perlinNoise(value * frequency + i * 0.72354) * factor;
				factor *= persistance;
				frequency *= roughness;
			}

			return noise;
		}
		
		fixed4 frag(v2f i) : SV_Target {

			float linearDepth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv_depth));
			float3 worldPos = _WorldSpaceCameraPos + linearDepth * i.interpolatedRay.xyz;

			float speed = _Time.y * _FogSpeed;
			float noise = sampleLayeredNoise(worldPos + speed, _Persistance, _Roughness);
					
			float fogDensity = (_FogEnd - worldPos.y) / (_FogEnd - _FogStart);
			fogDensity = saturate(fogDensity * _FogDensity * (1 + noise));
			
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
