Shader "Custom/Cloud/SDFCloud2d" {
        Properties{

            _MainTex("Texture", 2D) = "white" {}
            _MaskTex("MaskTexture(SDF)", 2D) = "white" {}
            _CloudSpeed("uv走向,xy是第一个，zw是第二个", Vector) = (1,1,1,1)
            _TillingFactor("TillingFactor", float) = 0.5
            _CloudColor("Cloud Color", Color) = (0,1,0,1)
            _Feather("Feather Range", Range(0, 0.5)) = 0.1 // 羽化范围
            _EdgeWidth("Edge Width", Range(0.01, 0.1)) = 0.01 // 基础宽度(0.01-0.1)
        }

        SubShader{
            Tags{ "Queue" = "Transparent" "DisableBatching" = "True" }
            Pass
            {
                ZWrite Off
                Blend SrcAlpha OneMinusSrcAlpha
                Cull Off

                CGPROGRAM
                #pragma vertex vert
                #pragma fragment frag

                #include "UnityCG.cginc"                

                struct appdata
                {
                    float4 vertex : POSITION;
                    float2 uv : TEXCOORD0;
                };

                struct v2f
                {
                    float2 uv : TEXCOORD0;
                    float4 pos : SV_POSITION;
                    float3 worldPos : TEXCOORD1;
                };

                sampler2D _MainTex;
                float4 _MainTex_ST;
                sampler2D _MaskTex;
                sampler2D _NoiseTex;
                float4 _CloudSpeed;
                float _TillingFactor;
                float4 _CloudColor;
                float _Feather;
                float _EdgeWidth;

                v2f vert(appdata v)
                {
                    v2f o;
                    o.pos = UnityObjectToClipPos(v.vertex);
                    o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                    o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                    return o;
                }

                float4 blendTwoCloud(float2 uv)
                {
                    float4 col = tex2D(_MainTex, uv * _TillingFactor + _Time.x * _CloudSpeed.xy);
                    float4 col2 = tex2D(_MainTex, uv + _Time.x * _CloudSpeed.zw);
                    col.rgb = (col.rgb + col2.rgb) / 2;
                    return col;
                }

                fixed4 frag(v2f i) : SV_Target
                {
                    float4 col = blendTwoCloud(i.uv);
                    float4 mask = tex2D(_MaskTex, i.uv);
                    float r = 1 - mask.g;             

                    r = smoothstep(_EdgeWidth, _EdgeWidth + _Feather, r);
                    float a = col.a * r;
                    float3 finalColor = col.rgb * _CloudColor.rgb;
                    col = float4(finalColor.rgb, a);
                    return col;
                }
                ENDCG
            }
        }
}