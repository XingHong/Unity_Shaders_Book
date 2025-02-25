Shader "Custom/ToonShader/ToonShader1" {
    Properties{
        _MainColor("Main Color", Color) = (1,1,1,1)
        _RampTex("Ramp Texture", 2D) = "white" {} // 色阶渐变纹理
        _Specular("Specular", Range(0,1)) = 0.5
        _SpecularSize("Specular Size", Range(0,1)) = 0.1
        _OutlineWidth("Outline Width", Range(0,1)) = 0.1
    }
        SubShader{
            Tags { "RenderType" = "Opaque" }

            // --- 第一个Pass：正常着色 ---
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
                };

                v2f vert(appdata v) {
                    v2f o;
                    o.pos = UnityObjectToClipPos(v.vertex);
                    o.worldNormal = UnityObjectToWorldNormal(v.normal);
                    o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                    return o;
                }

                fixed4 _MainColor;
                sampler2D _RampTex;
                float _Specular;
                float _SpecularSize;

                fixed4 frag(v2f i) : SV_Target {
                    // 计算光照方向
                    float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
                    // 计算法线
                    float3 normal = normalize(i.worldNormal);
                    // 兰伯特光照
                    float diff = dot(normal, lightDir) * 0.5 + 0.5;
                    // 离散化光照（或使用Ramp纹理）
                    float ramp = tex2D(_RampTex, float2(diff, 0.5)).r;
                    // 高光计算
                    float3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos);
                    float3 halfDir = normalize(lightDir + viewDir);
                    float spec = pow(max(0, dot(normal, halfDir)), _Specular * 128) * step(_SpecularSize, diff);
                    // 合成颜色
                    fixed4 col = _MainColor * ramp + spec;
                    return col;
                }
                ENDCG
            }

            // --- 第二个Pass：边缘描边 ---
            Pass {
                Cull Front // 渲染背面

                CGPROGRAM
                #pragma vertex vert
                #pragma fragment frag
                #include "UnityCG.cginc"

                struct appdata {
                    float4 vertex : POSITION;
                    float3 normal : NORMAL;
                };

                struct v2f {
                    float4 pos : SV_POSITION;
                };

                float _OutlineWidth;
                fixed4 _OutlineColor;

                v2f vert(appdata v) {
                    v2f o;
                    // 挤出顶点（沿法线方向）
                    float3 outlineOffset = normalize(v.normal) * _OutlineWidth;
                    float3 pos = v.vertex + outlineOffset;
                    o.pos = UnityObjectToClipPos(pos);
                    return o;
                }

                fixed4 frag(v2f i) : SV_Target {
                    return _OutlineColor;
                }
                ENDCG
            }
        }
}