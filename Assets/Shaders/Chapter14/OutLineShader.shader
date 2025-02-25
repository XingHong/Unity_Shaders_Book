//基于观察角度和表面法线的轮廓线渲染
Shader "Custom/OutLine/Simple"
{
    Properties
    {
        _Outline("Outline", Range(0, 1)) = 0.1
    }
        SubShader
    {
        Tags { "RenderType" = "Opaque" }
        LOD 100

        Pass
        {
            Cull Back

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            float _Outline;

            struct v2f
            {
                float4 pos : SV_POSITION;
                fixed4 color : COLOR;
            };

            v2f vert(appdata_base v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                float3 ObjViewDir = normalize(ObjSpaceViewDir(v.vertex));
                float3 normal = normalize(v.normal);
                float factor = step(_Outline, dot(normal, ObjViewDir));
                o.color = float4(1, 1, 1, 1) * factor;
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                return i.color;
            }
            ENDCG
        }
    }
        FallBack "Diffuse"
}
