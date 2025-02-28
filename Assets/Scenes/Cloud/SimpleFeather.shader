Shader "Custom/SimpleFeather" {
    Properties{
        _MainTex("Mask Texture", 2D) = "white" {}
        _Feather("Feather Range", Range(0, 0.5)) = 0.1 // 羽化范围
    }

        SubShader{
            Tags{ "Queue" = "Transparent" "DisableBatching" = "True" }
            Pass {
                ZWrite Off
                Blend SrcAlpha OneMinusSrcAlpha
                Cull Off
                CGPROGRAM
                #pragma vertex vert
                #pragma fragment frag
                #include "UnityCG.cginc"

                struct appdata {
                    float4 vertex : POSITION;
                    float2 uv : TEXCOORD0;
                };

                struct v2f {
                    float2 uv : TEXCOORD0;
                    float4 vertex : SV_POSITION;
                };

                sampler2D _MainTex;
                float4 _MainTex_ST;
                float _Feather;

                v2f vert(appdata v) {
                    v2f o;
                    o.vertex = UnityObjectToClipPos(v.vertex);
                    o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                    return o;
                }

                fixed4 frag(v2f i) : SV_Target {
                    // 5x5模糊采样（优化版）
                    float2 texelSize = _MainTex_ST.xy * 1;
                    float3x3 kernel = float3x3(
                        1, 2, 1,
                        2, 4, 2,
                        1, 2, 1
                    ) / 16.0;

                    float mask = 0;
                    [unroll]
                    for (int y = -1; y <= 1; y++) {
                        [unroll]
                        for (int x = -1; x <= 1; x++) {
                            float2 offset = float2(x,y) * texelSize;
                            mask += tex2D(_MainTex, i.uv + offset).r * kernel[y + 1][x + 1];
                        }
                    }
                    float3 col = tex2D(_MainTex, i.uv);
                    float alpha = smoothstep(0.5 - _Feather, 0.5 + _Feather, mask);
                    return fixed4(col.rgb, alpha);
                }
                ENDCG
            }
        }
}