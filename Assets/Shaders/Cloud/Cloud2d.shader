Shader "Custom/Cloud" {
        Properties{

            _MainTex("Texture", 2D) = "white" {}
            _MaskTex("MaskTexture", 2D) = "white" {}
            _MinMaxPowValue("边缘渐变范围(x,y),精度系数(z)", vector) = (1,1,1,1)
            _NoiseOffsetMultValue("扰动边缘偏移(x,y),扰动幅度(z)", vector) = (0,0,1,1)
            _CloudSpeed("uv走向,xy是第一个，zw是第二个", Vector) = (1,1,1,1)
            _TillingFactor("TillingFactor", float) = 0.5
        }

        SubShader{
            Tags{ "Queue" = "Transparent" "DisableBatching" = "True" }
            Pass
            {
                Tags
                {
                    "LightMode" = "ForwardBase"
                }
                ZWrite Off
                Blend SrcAlpha OneMinusSrcAlpha
                Cull Off

                CGPROGRAM
                #pragma vertex vert
                #pragma fragment frag
                #pragma multi_compile_fwdbase

                #include "UnityCG.cginc"
                #include "Lighting.cginc"
                #include "AutoLight.cginc"

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
                    SHADOW_COORDS(2)
                };

                sampler2D _MainTex;
                float4 _MainTex_ST;
                sampler2D _MaskTex;
                float4 _MinMaxPowValue;
                float4 _NoiseOffsetMultValue;
                float4 _CloudSpeed;
                float _TillingFactor;

                v2f vert(appdata v)
                {
                    v2f o;
                    o.pos = UnityObjectToClipPos(v.vertex);
                    o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                    o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                    TRANSFER_SHADOW(o)
                    return o;
                }

                //常见算法
                float clampAndPowValue(float val, float3 minMaxPow) {
                    float mValue;
                    mValue = saturate((val - minMaxPow.x) / (minMaxPow.y - minMaxPow.x)); //边缘数值约束在(Min,Max)范围归一化[0,1] (加快或减缓边缘渐变)
                    mValue = saturate(pow(mValue, minMaxPow.z));//提高边缘精度
                    return mValue;
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
                    float r = mask.r;
                    ////裁剪边缘精度、边缘渐变幅度控制
                    r = clampAndPowValue(r, _MinMaxPowValue.xyz);                    

                    float a = col.a * r;
                    col = fixed4(col.rgb, a);
                    return col;
                }
                ENDCG
            }
        }
}