// MobileBloom.shader
Shader "Custom/Cloud/MobileBloom" {
    Properties{
        _MainTex("Texture", 2D) = "white" {}
        _Threshold("Threshold", Range(0,1)) = 0.7
        _Intensity("Intensity", Range(0,5)) = 1.0
    }

        SubShader{
            CGINCLUDE
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
            float4 _MainTex_TexelSize;
            float _Threshold;
            float _Intensity;

            v2f vert(appdata v) {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }
            ENDCG

                // Pass 1: 亮度提取 + Kawase模糊 (合并操作)
                Pass {
                    CGPROGRAM
                    #pragma vertex vert
                    #pragma fragment frag

                    fixed4 frag(v2f i) : SV_Target {
                        // 亮度阈值提取
                        fixed4 col = tex2D(_MainTex, i.uv);
                        float brightness = max(col.r, max(col.g, col.b));
                        float bloom = smoothstep(_Threshold, _Threshold + 0.1, brightness);

                        // Kawase模糊（单Pass双方向）
                        float2 offset = _MainTex_TexelSize.xy * 2.0; // 2x2降采样
                        fixed4 sum = 0;
                        sum += tex2D(_MainTex, i.uv + offset * float2(1,1)) * bloom;
                        sum += tex2D(_MainTex, i.uv + offset * float2(-1,1)) * bloom;
                        sum += tex2D(_MainTex, i.uv + offset * float2(1,-1)) * bloom;
                        sum += tex2D(_MainTex, i.uv + offset * float2(-1,-1)) * bloom;
                        return sum / 4.0;
                    }
                    ENDCG
                }

                // Pass 2: 上采样 + 合成
                Pass {
                    CGPROGRAM
                    #pragma vertex vert
                    #pragma fragment frag
                    sampler2D _BloomTex;

                    fixed4 frag(v2f i) : SV_Target {
                        // 双线性上采样
                        fixed4 bloom = tex2D(_BloomTex, i.uv);

                        // 合成原始图像
                        fixed4 original = tex2D(_MainTex, i.uv);
                        return original + bloom * _Intensity;
                    }
                    ENDCG
                }
        }
}