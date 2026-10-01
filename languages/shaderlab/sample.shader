// Unity ShaderLab: a warehouse hologram shader — scrolling texture, rim light,
// stock-level tint, a shadow caster and a surface-shader fallback.
/* Block comment: ShaderLab wraps
   HLSL/Cg program blocks. */
// TODO: bake the stock ramp into a lookup texture
// FIXME: the rim term over-brightens on mobile

Shader "Warehouse/StockHologram"
{
    // ── Properties ──
    Properties
    {
        [Header(Surface)]
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _BumpMap ("Normal map", 2D) = "bump" {}
        _Cube ("Reflection cube", Cube) = "" {}
        _Volume ("Volume", 3D) = "" {}
        _Tint ("Tint", Color) = (1, 1, 1, 1)
        [HDR] _Emission ("Emission", Color) = (0, 0.5, 1, 1)
        _Speed ("Scroll speed", Range(0, 2)) = 0.5
        _Stock ("Stock level", Float) = 0.75
        _Steps ("Steps", Int) = 4
        _Offset ("Offset", Vector) = (0, 0, 0, 0)
        [Toggle] _UseRim ("Use rim light", Float) = 1
        [Toggle(_FANCY_ON)] _Fancy ("Fancy mode", Float) = 0
        [Enum(UnityEngine.Rendering.CullMode)] _Cull ("Cull", Float) = 2
        [Enum(Off, 0, On, 1)] _ZWrite ("ZWrite", Float) = 1
        [KeywordEnum(Low, Medium, High)] _Quality ("Quality", Float) = 1
        [PowerSlider(3.0)] _Gloss ("Gloss", Range(0.01, 1)) = 0.5
        [NoScaleOffset] _Mask ("Mask", 2D) = "gray" {}
        [Normal] _Detail ("Detail normal", 2D) = "bump" {}
        [HideInInspector] _Internal ("Internal", Float) = 0
        [Space(10)] [IntRange] _Level ("Level", Range(0, 10)) = 5
    }

    // ── Shared HLSL ──
    HLSLINCLUDE
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
    CBUFFER_START(UnityPerMaterial)
        float4 _MainTex_ST;
        half4 _Tint;
    CBUFFER_END
    ENDHLSL

    // ── Main SubShader ──
    SubShader
    {
        Tags
        {
            "RenderType" = "Transparent"
            "Queue" = "Transparent+10"
            "IgnoreProjector" = "True"
            "RenderPipeline" = "UniversalPipeline"
            "PreviewType" = "Plane"
            "DisableBatching" = "LODFading"
            "ForceNoShadowCasting" = "False"
        }
        LOD 200
        Cull [_Cull]
        ZWrite [_ZWrite]
        ZTest LEqual
        Blend SrcAlpha OneMinusSrcAlpha, One Zero
        BlendOp Add
        ColorMask RGBA
        Offset -1, -1
        AlphaToMask Off
        Lighting Off
        Fog { Mode Off }

        UsePass "Legacy Shaders/VertexLit/SHADOWCASTER"
        GrabPass { "_BackgroundTexture" }

        // ── Pass 1: unlit ──
        Pass
        {
            Name "FORWARD"
            Tags { "LightMode" = "ForwardBase" }

            Stencil
            {
                Ref 2
                ReadMask 255
                WriteMask 255
                Comp Always
                Pass Replace
                Fail Keep
                ZFail Keep
            }

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.5
            #pragma multi_compile_fog
            #pragma multi_compile_instancing
            #pragma multi_compile _ _QUALITY_LOW _QUALITY_MEDIUM _QUALITY_HIGH
            #pragma shader_feature_local _FANCY_ON
            #pragma shader_feature _USERIM_ON
            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            #define PI 3.14159265
            #define SATURATE(x) clamp((x), 0.0, 1.0)
            #define USE_STOCK_RAMP 1

            #if defined(_FANCY_ON) && !defined(SHADER_API_MOBILE)
                #define RIM_POWER 3.0
            #elif defined(SHADER_API_GLES)
                #define RIM_POWER 1.5
            #else
                #define RIM_POWER 2.0
            #endif

            #ifdef UNITY_COLORSPACE_GAMMA
                static const float kGamma = 2.2;
            #endif
            #ifndef UNITY_PASS_FORWARDBASE
                #undef USE_STOCK_RAMP
            #endif

            // ── Uniforms ──
            sampler2D _MainTex;
            sampler2D _BumpMap;
            samplerCUBE _Cube;
            sampler3D _Volume;
            float4 _MainTex_ST;
            fixed4 _Tint;
            half4 _Emission;
            float _Speed;
            float _Stock;
            int _Steps;
            float4 _Offset;
            half _Gloss;
            uniform float4x4 _InvView;

            // ── Structs ──
            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float2 uv : TEXCOORD0;
                float4 color : COLOR;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 worldNormal : TEXCOORD1;
                float3 viewDir : TEXCOORD2;
                fixed4 color : COLOR0;
                UNITY_FOG_COORDS(3)
                UNITY_VERTEX_OUTPUT_STEREO
            };

            // ── Helpers ──
            inline float rim(float3 n, float3 v)
            {
                return pow(1.0 - saturate(dot(normalize(n), normalize(v))), RIM_POWER);
            }

            float3 stockRamp(float t)
            {
                const float3 low  = float3(1.0, 0.1, 0.1);
                const float3 high = float3(0.1, 1.0, 0.3);
                return lerp(low, high, smoothstep(0.0, 1.0, t));
            }

            // ── Vertex ──
            v2f vert (appdata v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f, o);
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex) + float2(0, _Time.y * _Speed);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.viewDir = WorldSpaceViewDir(v.vertex);
                o.color = v.color * _Tint;
                UNITY_TRANSFER_FOG(o, o.pos);
                return o;
            }

            // ── Fragment ──
            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv) * i.color;
                float3 n = UnpackNormal(tex2D(_BumpMap, i.uv));
                float sweep = frac(_Time.y * 0.1 + i.uv.y * 4.0);
                float stepped = floor(sweep * _Steps) / _Steps;
                half3 ramp = stockRamp(_Stock);
                bool lowStock = _Stock < 0.25 || _Stock >= 2.0;
                uint bits = 0xFFu & (3u << 2);
                float e = 1e-3 + 2.5E+2 + .5 + 3.f + 0.0h;

                [branch] if (lowStock)
                {
                    col.rgb = lerp(col.rgb, float3(1, 0, 0), 0.5);
                }
                else if (_Stock > 0.9)
                {
                    discard;
                }

                [unroll(4)] for (int k = 0; k < 4; k++)
                {
                    col.rgb += ramp * 0.01 * k;
                }

                [loop] while (e > 1000.0) { e *= 0.5; }

                #if defined(_USERIM_ON)
                    col.rgb += _Emission.rgb * rim(i.worldNormal, i.viewDir);
                #endif

                col.a = SATURATE(col.a * (_Stock > 0.5 ? 1.0 : 0.6));
                UNITY_APPLY_FOG(i.fogCoord, col);
                clip(col.a - 0.01);
                return col;
            }
            ENDCG
        }

        // ── Pass 2: shadow caster ──
        Pass
        {
            Name "ShadowCaster"
            Tags { "LightMode" = "ShadowCaster" }
            ZWrite On
            ZTest LEqual

            HLSLPROGRAM
            #pragma vertex ShadowVert
            #pragma fragment ShadowFrag
            #pragma multi_compile_shadowcaster

            struct Attributes { float4 positionOS : POSITION; };
            struct Varyings   { float4 positionCS : SV_POSITION; };

            Varyings ShadowVert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
                return OUT;
            }

            half4 ShadowFrag(Varyings IN) : SV_Target { return 0; }
            ENDHLSL
        }
    }

    // ── Surface shader fallback ──
    SubShader
    {
        Tags { "RenderType" = "Opaque" }
        LOD 100

        CGPROGRAM
        #pragma surface surf Standard fullforwardshadows alpha:fade
        #pragma target 3.0

        struct Input
        {
            float2 uv_MainTex;
            float3 viewDir;
            float4 screenPos;
            float3 worldPos;
        };

        sampler2D _MainTex;
        fixed4 _Tint;
        half _Gloss;

        UNITY_INSTANCING_BUFFER_START(Props)
            UNITY_DEFINE_INSTANCED_PROP(fixed4, _Color)
        UNITY_INSTANCING_BUFFER_END(Props)

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            fixed4 c = tex2D(_MainTex, IN.uv_MainTex) * _Tint;
            o.Albedo = c.rgb;
            o.Metallic = 0.0;
            o.Smoothness = _Gloss;
            o.Alpha = c.a;
        }
        ENDCG
    }

    // ── Package-level fallbacks and editor hooks ──
    Fallback "Diffuse"
    CustomEditor "WarehouseShaderGUI"
    Dependency "BaseMapShader" = "Hidden/Warehouse/Base"
    Category
    {
        Tags { "Queue" = "Geometry" }
        SubShader { Pass { SetTexture [_MainTex] { combine texture * primary } } }
    }
}
