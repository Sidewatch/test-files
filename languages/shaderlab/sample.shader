// ShaderLab — Unity 6.2 (6000.2) syntax showcase, with HLSL program blocks
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
        [MainTexture] _BaseMap ("Base map", 2D) = "white" {}
        [MainColor] _BaseColor ("Base colour", Color) = (1, 1, 1, 1)
        [PerRendererData] _RendererTint ("Renderer tint", Color) = (1, 1, 1, 1)
        [ToggleUI] _ShowOutline ("Outline", Float) = 0
        [Gamma] _GammaTint ("Gamma tint", Color) = (1, 1, 1, 1)
        [NoScaleOffset] [Normal] _NormalMap ("Normal", 2D) = "bump" {}
        [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend ("Src blend", Float) = 5
        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlend ("Dst blend", Float) = 10
        [Enum(UnityEngine.Rendering.CompareFunction)] _ZTest ("ZTest", Float) = 4
        [HDR] [Gamma] _HdrGamma ("HDR gamma", Color) = (1, 1, 1, 1)
        [Header(Stencil)] [Space] _StencilRef ("Ref", Range(0, 255)) = 0
        _Smoothness ("Smoothness", Range(0.0, 1.0)) = 0.5
        _Tiling ("Tiling", Vector) = (1, 1, 0, 0)
        _Array ("Texture array", 2DArray) = "" {}
        _Cutoff ("Alpha cutoff", Range(0, 1)) = 0.5
        _Neg ("Negative", Float) = -1.5e-2
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

    // ── SubShader: modern HLSL pass (URP-style) with per-target state ──
    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" "Queue" = "Geometry" "UniversalMaterialType" = "Lit" }
        LOD 300

        Pass
        {
            Name "UniversalForward"
            Tags { "LightMode" = "UniversalForward" }

            Blend [_SrcBlend] [_DstBlend]
            Blend 1 One One
            Blend 2 Off
            BlendOp 0 Add
            BlendOp Max, Min
            Cull Back
            ZClip True
            ZTest [_ZTest]
            ZWrite On
            ColorMask 0
            ColorMask RGB 1
            Conservative True
            Offset [_OffsetFactor], [_OffsetUnits]
            AlphaToMask On
            Stencil
            {
                Ref [_StencilRef]
                Comp [_StencilComp]
                Pass IncrSat
                Fail DecrWrap
                ZFail Invert
                CompFront Equal
                PassFront Zero
                FailFront IncrWrap
                ZFailFront DecrSat
                CompBack NotEqual
                PassBack Keep
                FailBack Replace
                ZFailBack Zero
            }

            HLSLPROGRAM
            #pragma target 4.5
            #pragma use_dxc
            #pragma vertex Vert
            #pragma fragment Frag
            #pragma hull Hull
            #pragma domain Domain
            #pragma geometry Geom
            #pragma require geometry tessellation
            #pragma only_renderers d3d11 vulkan metal
            #pragma exclude_renderers gles
            #pragma multi_compile_instancing
            #pragma multi_compile_local _ _ALPHATEST_ON
            #pragma multi_compile_local_fragment _ _SHADOWS_SOFT
            #pragma shader_feature_local_fragment _NORMALMAP
            #pragma shader_feature_local_vertex _WIND
            #pragma instancing_options renderinglayer
            #pragma skip_variants FOG_EXP FOG_EXP2
            #pragma editor_sync_compilation
            #pragma enable_d3d11_debug_symbols
            #pragma warning disable 3557
            #pragma once
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            #line 1 "WarehouseForward"
            #if SHADER_API_D3D11 || SHADER_API_VULKAN
                #define HAS_COMPUTE 1
            #elif !defined(SHADER_API_METAL)
                #error "Unsupported platform"
            #else
                #warning "Metal path"
            #endif

            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);
            Texture2D<float4> _Tex2;
            SamplerState sampler_Tex2;
            Texture2DArray _Array;
            StructuredBuffer<float4> _Points;
            RWStructuredBuffer<uint> _Counters;

            cbuffer Params : register(b0)
            {
                float4 _Params;
                row_major float4x4 _World;
                column_major float3x3 _Basis;
            }

            typedef float3 Colour;
            static const float kEpsilon = 1e-5;
            static uint s_counter = 0u;
            groupshared float g_shared[64];

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS   : NORMAL;
                float2 uv         : TEXCOORD0;
                uint   vertexID   : SV_VertexID;
                uint   instanceID : SV_InstanceID;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                nointerpolation float3 flat : TEXCOORD0;
                noperspective float2 uv : TEXCOORD1;
                linear float3 smooth : TEXCOORD2;
                centroid float3 cen : TEXCOORD3;
                bool front : SV_IsFrontFace;
            };

            Varyings Vert(Attributes IN)
            {
                Varyings OUT = (Varyings)0;
                OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = IN.uv;
                OUT.flat = float3(1, 0, 0);
                return OUT;
            }

            [maxvertexcount(3)]
            void Geom(triangle Varyings input[3], inout TriangleStream<Varyings> stream)
            {
                [unroll] for (int i = 0; i < 3; ++i) { stream.Append(input[i]); }
                stream.RestartStrip();
            }

            half4 Frag(Varyings IN, bool isFront : SV_IsFrontFace, out float depth : SV_Depth) : SV_Target0
            {
                half4 c = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.uv);
                float3x3 m = float3x3(1, 0, 0, 0, 1, 0, 0, 0, 1);
                half2x2 h = half2x2(1, 0, 0, 1);
                matrix<float, 4, 4> mm = (matrix<float, 4, 4>)0;
                vector<float, 3> v3 = float3(1, 2, 3);
                int4 iv = int4(1, 2, 3, 4);
                uint2 uv2 = uint2(1u, 2u);
                min16float mf = 1.0;
                double dd = 1.0;
                float swz = v3.zyx.x + c.rgba.a + c.xyzw.w;
                int sel = (int)floor(IN.uv.x * 3.0) % 3;
                switch (sel)
                {
                    case 0: c.r = 1.0; break;
                    case 1: { c.g = 1.0; break; }
                    default: c.b = 1.0; break;
                }
                [flatten] if (isFront) { c.a *= 0.5; }
                [fastopt] do { s_counter++; } while (s_counter < 4u);
                for (uint k = 0u; k < 2u; k += 1u) { c.rgb *= 0.9; }
                float t = isFront ? 1.0 : -1.0;
                t = (t > 0 && t < 2) || !(t == 3) ? t : -t;
                t += 1; t -= 1; t *= 2; t /= 2; t %= 5;
                uint bits = (1u << 3) | (2u >> 1) ^ 0xFu & ~0u;
                depth = IN.positionCS.z;
                #if defined(_ALPHATEST_ON)
                    clip(c.a - _Cutoff);
                #endif
                return c;
            }
            ENDHLSL
        }
    }

    // ── Deprecated fixed-function SubShader (still parsed by Unity) ──
    SubShader
    {
        Pass
        {
            Material { Diffuse [_Tint] Ambient (0.2, 0.2, 0.2, 1) Shininess [_Gloss] Specular (1, 1, 1, 1) Emission [_Emission] }
            Lighting On
            SeparateSpecular On
            ColorMaterial AmbientAndDiffuse
            Fog { Color (0, 0, 0, 0) }
            AlphaTest Greater 0.5
            SetTexture [_MainTex] { constantColor (1, 1, 1, 0.5) combine texture * primary DOUBLE, texture * constant }
            SetTexture [_BumpMap] { combine previous + texture }
        }
    }

    // ── Package-level fallbacks and editor hooks ──
    Fallback "Diffuse"
    // Fallback Off  (alternative: disable the fallback)
    CustomEditor "WarehouseShaderGUI"
    CustomEditorForRenderPipeline "WarehouseURPGUI" "UnityEngine.Rendering.Universal.UniversalRenderPipelineAsset"
    Dependency "BaseMapShader" = "Hidden/Warehouse/Base"
    Category
    {
        Tags { "Queue" = "Geometry" }
        SubShader { Pass { SetTexture [_MainTex] { combine texture * primary } } }
    }
}
