// Unity ShaderLab: an unlit textured shader with a tint and a scroll.
Shader "Custom/UnlitScroll"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Tint ("Tint", Color) = (1, 1, 1, 1)
        _Speed ("Scroll speed", Range(0, 2)) = 0.5
    }
    SubShader
    {
        Tags { "RenderType" = "Opaque" "Queue" = "Geometry" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed4 _Tint;
            float _Speed;

            struct appdata { float4 vertex : POSITION; float2 uv : TEXCOORD0; };
            struct v2f { float2 uv : TEXCOORD0; float4 vertex : SV_POSITION; };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex) + float2(0, _Time.y * _Speed);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target { return tex2D(_MainTex, i.uv) * _Tint; }
            ENDCG
        }
    }
    FallBack "Unlit/Texture"
}
