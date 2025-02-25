Shader "Custom/ToonShader/ToonSinglePass" {
    Properties{
        _MainColor("Main Color", Color) = (1,1,1,1)
        _RampTex("Ramp Texture", 2D) = "white" {}
        _OutlineColor("Outline Color", Color) = (0,0,0,1)
        _OutlineWidth("Outline Width", Range(0, 0.1)) = 0.02
        _FresnelPower("Edge Fresnel Power", Range(0, 10)) = 5.0
        _Specular("Specular", Range(0,1)) = 0.5
    }
        SubShader{
            Tags { "RenderType" = "Opaque" }

            Pass {
                CGPROGRAM
                #pragma vertex vert
                #pragma fragment frag
                #include "UnityCG.cginc"
                #include "Lighting.cginc"

                struct appdata {
                    float4 vertex : POSITION;
                    float3 normal : NORMAL;
                };

                struct v2f {
                    float4 pos : SV_POSITION;
                    float3 worldNormal : TEXCOORD0;
                    float3 worldPos : TEXCOORD1;
                    float3 viewDir : TEXCOORD2;
                    float fresnel : TEXCOORD3;
                };

                fixed4 _MainColor;
                sampler2D _RampTex;
                fixed4 _OutlineColor;
                float _OutlineWidth;
                float _FresnelPower;
                float _Specular;

                v2f vert(appdata v) {
                    v2f o;

                    // 法线扩展描边（模型空间）
                    float3 outlineOffset = v.normal * _OutlineWidth;
                    float4 outlinePos = v.vertex + float4(outlineOffset, 0);
                    o.pos = UnityObjectToClipPos(outlinePos);

                    // 传递数据到片段着色器
                    o.worldNormal = UnityObjectToWorldNormal(v.normal);
                    o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                    o.viewDir = WorldSpaceViewDir(v.vertex);

                    // 提前计算菲涅尔因子
                    float3 viewDir = normalize(ObjSpaceViewDir(v.vertex));
                    o.fresnel = pow(1.0 - saturate(dot(v.normal, viewDir)), _FresnelPower);

                    return o;
                }

                fixed4 frag(v2f i) : SV_Target {
                    // --- 边缘检测 ---
                    if (i.fresnel > 0.2) { // 阈值控制描边粗细
                        return _OutlineColor;
                    }

                // --- 色块化光照 ---
                float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
                float3 normal = normalize(i.worldNormal);
                float diff = dot(normal, lightDir) * 0.5 + 0.5;
                float ramp = tex2D(_RampTex, float2(diff, 0.5)).r;

                // --- 高光计算 ---
                float3 viewDir = normalize(i.viewDir);
                float3 halfDir = normalize(lightDir + viewDir);
                float spec = pow(max(0, dot(normal, halfDir)), _Specular * 128) * step(0.2, diff);

                return _MainColor * ramp + spec;
            }
            ENDCG
        }
        }
}