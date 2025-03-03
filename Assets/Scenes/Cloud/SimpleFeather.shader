Shader "Custom/SimpleFeather" {
    Properties{
        _MainTex("Mask Texture", 2D) = "white" {}
        _SDFTex("SDF Texture", 2D) = "white" {}
        _Feather("Feather Range", Range(0, 0.5)) = 0.1 // Óð»¯·¶Î§
        _EdgeWidth("Edge Width", Range(0.01, 0.1)) = 0.01 // »ù´¡¿í¶È(0.01-0.1)
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
            sampler2D _SDFTex;
            float _Feather;
            float _EdgeWidth;

            v2f vert(appdata v) {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target{
                fixed4 color = tex2D(_MainTex, i.uv);
                float sdf = tex2D(_SDFTex, i.uv).g;
                float alpha = smoothstep(_EdgeWidth, _EdgeWidth + _Feather, sdf);
                color.a = alpha;
                return color;
            }
            ENDCG
        }
    }
}