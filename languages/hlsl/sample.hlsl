// HLSL (DXC, HLSL 2021, Shader Model 6.8) — syntax showcase
// ── Comments ──
// HLSL: vertex, pixel, geometry, hull, domain and compute stages for a lit, textured mesh.
/* Block comment. TODO: add cascaded shadows. FIXME: banding on low-end GPUs. */

// ── Preprocessor ──
#pragma pack_matrix(row_major)
#pragma warning(disable : 3557)
#include "common.hlsli"
#define PI 3.14159265358979
#define MAX_LIGHTS 8
#define SATURATE(x) clamp((x), 0.0, 1.0)
#define CAT(a, b) a##b
#define STR(x) #x
#ifndef USE_NORMAL_MAP
#define USE_NORMAL_MAP 1
#endif
#if USE_NORMAL_MAP && defined(MAX_LIGHTS)
#define NORMAL_STEP 1
#elif defined(LOW_QUALITY)
#define NORMAL_STEP 0
#else
#define NORMAL_STEP 2
#endif
#undef LOW_QUALITY

// ── Constant buffers, registers, packoffset ──
cbuffer PerFrame : register(b0) {
    float4x4 viewProj;
    float3   lightDir;
    float    time;
    row_major float4x4 world;
    column_major float3x3 normalMatrix;
};

cbuffer Packed : register(b1, space1) {
    float4 colorA : packoffset(c0);
    float  scalar : packoffset(c1.x);
    float2 pair   : packoffset(c1.y);
};

tbuffer Table : register(t4) { float4 tableData[16]; };

ConstantBuffer<PerFrame> frameBuffer : register(b2);

// ── Resources ──
Texture2D    albedo     : register(t0);
Texture2D<float4> normalMap : register(t1);
Texture2DArray<float> shadowMap : register(t2);
TextureCube  environment : register(t3);
Texture3D<float> volume : register(t5);
SamplerState linear_s : register(s0);
SamplerComparisonState shadow_s : register(s1);
StructuredBuffer<float4> lightsIn : register(t6);
RWStructuredBuffer<float4> lightsOut : register(u0);
RWTexture2D<float4> outputImage : register(u1);
ByteAddressBuffer rawIn : register(t7);
RWByteAddressBuffer rawOut : register(u2);
Buffer<uint> counters : register(t8);
AppendStructuredBuffer<uint> appendBuf : register(u3);
ConsumeStructuredBuffer<uint> consumeBuf : register(u4);

static const float kGamma = 2.2;
static const int kSteps = 16;
static const uint kMask = 0xFFu;
static const float3 kUp = float3(0, 1, 0);
groupshared float4 gCache[64];
static float gScratch = 0.0;
extern float gExtern;
uniform float uScale;
volatile float gVolatile;
precise float gPrecise;

// ── Literals ──
static const int    kInt    = 42;
static const int    kHex    = 0xFF;
static const uint   kUint   = 7u;
static const uint   kOctal  = 0755;
static const float  kFloat  = 3.14f;
static const float  kExp    = 1.5e-3f;
static const half   kHalf   = 0.5h;
static const double kDouble = 3.14159265358979L;
static const float  kDot    = .5;
static const bool   kTrue   = true;
static const bool   kFalse  = false;
static const string kName   = "hlsl string literal with \"escape\"";

// ── Structs, semantics, interpolation modifiers ──
struct VSIn {
    float3 pos : POSITION;
    float3 nrm : NORMAL;
    float4 tan : TANGENT;
    float2 uv  : TEXCOORD0;
    uint   id  : SV_VertexID;
    uint   inst : SV_InstanceID;
    float4 col : COLOR0;
};

struct VSOut {
    float4 pos : SV_Position;
    float3 nrm : NORMAL;
    float2 uv  : TEXCOORD0;
    nointerpolation uint material : TEXCOORD1;
    noperspective float depth : TEXCOORD2;
    centroid float3 world : TEXCOORD3;
    linear float4 col : COLOR0;
    sample float rim : TEXCOORD4;
};

struct Light {
    float3 position;
    float  range;
    float3 color;
    float  intensity;
};

interface ILightModel {
    float3 Shade(float3 n, float3 l);
};

class Lambert : ILightModel {
    float3 tint;
    float3 Shade(float3 n, float3 l) { return tint * saturate(dot(n, l)); }
};

namespace Lighting {
    float3 fresnel(float cosTheta, float3 f0) {
        return f0 + (1.0 - f0) * pow(1.0 - cosTheta, 5.0);
    }
}

template<typename T>
T Square(T x) { return x * x; }

typedef float4 Color;
typedef uint2 Pair;
enum Mode { Off, On = 5, Auto };
enum class Channel : uint { R, G, B, A };

SamplerState s_with_state {
    Filter = MIN_MAG_MIP_LINEAR;
    AddressU = Wrap;
    AddressV = Clamp;
};

// ── Functions ──
float4 Tint(in float4 c, out float4 result, inout float t, const float k = 1.0) {
    result = c * k;
    t += 1.0;
    return result;
}

inline float rim(float3 n, float3 v) {
    return pow(1.0 - max(dot(n, v), 0.0), 3.0);
}

[branch] float Pick(float a, float b) { return a > b ? a : b; }

// ── Vertex shader ──
VSOut VSMain(VSIn i) {
    VSOut o;
    o.pos = mul(viewProj, float4(i.pos, 1.0));
    o.nrm = normalize(mul((float3x3)world, i.nrm));
    o.uv  = i.uv + float2(0.0, sin(time) * 0.01);
    o.material = i.id & 3;
    o.depth = o.pos.z / o.pos.w;
    o.world = mul(world, float4(i.pos, 1.0)).xyz;
    o.col = i.col;
    o.rim = 0;
    return o;
}

// ── Pixel shader ──
[earlydepthstencil]
float4 PSMain(VSOut i, bool front : SV_IsFrontFace, uint prim : SV_PrimitiveID) : SV_Target {
    float3 n = normalize(i.nrm);
    float ndl = saturate(dot(n, -lightDir));
    float3 base = albedo.Sample(linear_s, i.uv).rgb;
    float4 swizzled = float4(base, 1).bgra;
    float2 xy = swizzled.xy;
    float shadow = shadowMap.SampleCmpLevelZero(shadow_s, float3(i.uv, 0), i.depth);
    float4 env = environment.SampleLevel(linear_s, n, 2.0);
    float4 tex = albedo.SampleGrad(linear_s, i.uv, ddx(i.uv), ddy(i.uv));
    float4 loaded = normalMap.Load(int3(0, 0, 0));
    float3x3 tbn = float3x3(1, 0, 0, 0, 1, 0, 0, 0, 1);
    float4x4 identity = float4x4(1,0,0,0, 0,1,0,0, 0,0,1,0, 0,0,0,1);
    int2 ipos = int2(i.pos.xy);
    uint3 uv3 = uint3(1u, 2u, 3u);
    bool3 flags = bool3(true, false, true);
    half3 h = half3(0.5h, 0.5h, 0.5h);
    float arr[3] = { 1.0, 2.0, 3.0 };
    float3 lit = base * (0.2 + 0.8 * ndl) * shadow + env.rgb * 0.05;

    // Operators
    int k = 5;
    k += 2; k -= 1; k *= 3; k /= 2; k %= 4;
    k <<= 1; k >>= 1; k &= 0xF; k |= 0x1; k ^= 0x3;
    k++; --k;
    int bits = (k & 3) | (k ^ 5) | ~k | (k << 2) | (k >> 1);
    bool logic = (ndl > 0.5 && shadow < 0.5) || !(ndl >= 1.0) || ndl != 1.0 || ndl == 0.0;
    float tern = logic ? 1.0 : 0.0;
    lit = lerp(lit, base, 0.5) * SATURATE(tern);
    lit = pow(lit, 1.0 / kGamma);

    // Control flow with attributes
    [unroll(4)] for (int s = 0; s < 4; s++) { lit += 0.01; }
    [loop] for (int t = 0; t < kSteps; ++t) {
        if (t > 8) break;
        if (t == 3) continue;
    }
    [fastopt] while (k > 0) { k--; }
    do { k++; } while (k < 3);
    [flatten] if (front) { lit *= 1.0; } else { lit *= 0.5; }
    [branch] switch (i.material) {
        case 0: lit *= 1.0; break;
        case 1:
        case 2: lit *= 0.5; break;
        default: lit = float3(1, 0, 1);
    }
    [forcecase] switch (k) { default: break; }

    // Intrinsics
    float m = mad(ndl, 2.0, 1.0) + rcp(2.0) + rsqrt(4.0) + frac(1.5) + fmod(5.0, 3.0) + sign(-1.0) + step(0.5, ndl) + smoothstep(0.0, 1.0, ndl);
    float3 rf = reflect(-lightDir, n) + refract(-lightDir, n, 0.66) + cross(n, kUp);
    float l = length(lit) + distance(lit, base) + dot(n, n) + abs(-1.0) + floor(1.5) + ceil(1.5) + round(1.5) + trunc(1.5) + exp2(2.0) + log2(4.0);
    uint c = countbits(kMask) + firstbithigh(8u) + reversebits(1u) + asuint(1.0);
    float f = asfloat(0x3f800000) + f16tof32(0x3c00) + (float)k + (uint)l;
    clip(ndl - 0.01);
    if (ndl < 0.0) discard;
    GroupMemoryBarrierWithGroupSync();
    InterlockedAdd(gCounter, 1);
    float4 dbg = mul(identity, float4(lit, 1)) + mul(float4(lit, 1), identity);
    return float4(lit, 1.0) + dbg * 0.0 + float4(m, l, f, c) * 0.0;
}

// ── Geometry, hull and domain shaders ──
[maxvertexcount(3)]
void GSMain(triangle VSOut input[3], inout TriangleStream<VSOut> stream) {
    [unroll] for (int i = 0; i < 3; i++) { stream.Append(input[i]); }
    stream.RestartStrip();
}

struct HSConst { float edges[3] : SV_TessFactor; float inside : SV_InsideTessFactor; };

HSConst PatchConstants(InputPatch<VSOut, 3> patch, uint id : SV_PrimitiveID) {
    HSConst c;
    c.edges[0] = c.edges[1] = c.edges[2] = 4;
    c.inside = 4;
    return c;
}

[domain("tri")]
[partitioning("fractional_odd")]
[outputtopology("triangle_cw")]
[outputcontrolpoints(3)]
[patchconstantfunc("PatchConstants")]
VSOut HSMain(InputPatch<VSOut, 3> patch, uint i : SV_OutputControlPointID) { return patch[i]; }

[domain("tri")]
VSOut DSMain(HSConst c, float3 bary : SV_DomainLocation, const OutputPatch<VSOut, 3> patch) {
    return patch[0];
}

// ── Compute shader ──
[numthreads(8, 8, 1)]
void CSMain(uint3 gid : SV_GroupID, uint3 tid : SV_GroupThreadID, uint3 dtid : SV_DispatchThreadID, uint gi : SV_GroupIndex) {
    gCache[gi] = lightsIn[gi];
    GroupMemoryBarrierWithGroupSync();
    outputImage[dtid.xy] = float4(gCache[gi].rgb, 1.0);
    lightsOut[gi] = gCache[(gi + 1) & 63];
    uint original;
    InterlockedExchange(counters[0], 1, original);
}

// ── Techniques (effects framework) ──
technique11 Main {
    pass P0 {
        SetVertexShader(CompileShader(vs_5_0, VSMain()));
        SetPixelShader(CompileShader(ps_5_0, PSMain()));
    }
}
// ── Scalar, vector and matrix type zoo ──
bool b1; int i1; uint u1; dword dw1; half h1; float f1; double d1;
min16float mf16; min10float mf10; min16int mi16; min12int mi12; min16uint mu16;
int16_t i16; uint16_t u16; int64_t i64; uint64_t u64; float16_t f16;
float1 v1; float2 v2; float3 v3; float4 v4;
int2 iv2; int3 iv3; int4 iv4; uint2 uv2; uint3 uv3; uint4 uv4;
bool2 bv2; bool3 bv3; bool4 bv4; half2 hv2; half3 hv3; half4 hv4; double2 dv2; double3 dv3; double4 dv4;
float2x2 m22; float2x3 m23; float3x3 m33; float3x4 m34; float4x3 m43; float4x4 m44;
int2x2 im22; uint3x3 um33; half4x4 hm44; double2x2 dm22;
vector<float, 3> templVec;
matrix<float, 4, 4> templMat;
snorm float snormVal;
unorm float unormVal;
string strVar;
texture oldTexture;
sampler oldSampler;
sampler1D smp1; sampler2D smp2; sampler3D smp3; samplerCUBE smpC;
sampler_state oldState;

// ── Resource zoo ──
Texture1D<float4> tex1D : register(t10);
Texture1DArray<float4> tex1DArray : register(t11);
Texture2DMS<float4, 4> texMS : register(t12);
Texture2DMSArray<float4, 4> texMSArray : register(t13);
TextureCubeArray<float4> texCubeArray : register(t14);
RWTexture1D<float4> rwTex1D : register(u10);
RWTexture1DArray<float4> rwTex1DArray : register(u11);
RWTexture2DArray<float4> rwTex2DArray : register(u12);
RWTexture3D<float4> rwTex3D : register(u13);
RasterizerOrderedTexture2D<float4> rovTex : register(u14);
RasterizerOrderedBuffer<uint> rovBuffer : register(u15);
RasterizerOrderedStructuredBuffer<float4> rovStructured : register(u16);
RWBuffer<float4> rwBuffer : register(u17);
FeedbackTexture2D<SAMPLER_FEEDBACK_MIN_MIP> feedback : register(u18);
RaytracingAccelerationStructure scene : register(t20);
SamplerState pointClamp : register(s2, space2);
SamplerComparisonState cmpState : register(s3);
globallycoherent RWByteAddressBuffer coherentBuf : register(u19);
Texture2D<float4> bindless[] : register(t0, space3);
ConstantBuffer<float4x4> cbArray[4] : register(b4, space4);
static const SamplerState staticSampler = SamplerState(0);

// ── Attributes of every kind ──
[RootSignature("RootFlags(ALLOW_INPUT_ASSEMBLER_INPUT_LAYOUT), CBV(b0), DescriptorTable(SRV(t0, numDescriptors = 4))")]
[numthreads(64, 1, 1)]
[WaveSize(32)]
void CSAttributes(uint3 id : SV_DispatchThreadID) {
    [allow_uav_condition] while (id.x < 4) { id.x++; }
    [loop] for (uint i = 0; i < 4; i++) {}
    [unroll] for (uint j = 0; j < 4; j++) {}
    [branch] if (id.x > 0) {}
    [flatten] if (id.x > 1) {}
    [call] switch (id.x) { case 0: break; }
    [fastopt] for (uint k = 0; k < 4; k++) {}
}

[instance(4)]
[maxvertexcount(6)]
void GSInstanced(triangle VSOut input[3], inout TriangleStream<VSOut> stream, uint instanceId : SV_GSInstanceID) {}

[maxtessfactor(16.0)]
[clipplanes(clipPlane0, clipPlane1)]
[noinline] float NoInline(float x) { return x; }
[experimental] float Experimental(float x) { return x; }

// ── Mesh and amplification shaders ──
struct MeshPayload { uint indices[32]; };
groupshared MeshPayload sharedPayload;

[numthreads(32, 1, 1)]
void ASMain(uint gtid : SV_GroupThreadID) {
    sharedPayload.indices[gtid] = gtid;
    DispatchMesh(1, 1, 1, sharedPayload);
}

[numthreads(32, 1, 1)]
[outputtopology("triangle")]
void MSMain(
    uint gtid : SV_GroupThreadID,
    in payload MeshPayload payload,
    out vertices VSOut verts[64],
    out indices uint3 tris[126],
    out primitives PrimAttr prims[126]) {
    SetMeshOutputCounts(64, 126);
    verts[gtid] = (VSOut)0;
    tris[gtid] = uint3(0, 1, 2);
}
struct PrimAttr { uint id : SV_PrimitiveID; bool cull : SV_CullPrimitive; };

// ── DirectX Raytracing ──
struct [raypayload] RayPayload {
    float4 color : write(caller, closesthit, miss) : read(caller);
};
struct Attributes { float2 bary; };

[shader("raygeneration")]
void RayGen() {
    uint2 index = DispatchRaysIndex().xy;
    uint2 dims = DispatchRaysDimensions().xy;
    RayDesc ray;
    ray.Origin = float3(0, 0, -5);
    ray.Direction = normalize(float3(0, 0, 1));
    ray.TMin = 0.001;
    ray.TMax = 10000.0;
    RayPayload payload = { float4(0, 0, 0, 0) };
    TraceRay(scene, RAY_FLAG_NONE, 0xFF, 0, 1, 0, ray, payload);
    rwTex2DArray[uint3(index, 0)] = payload.color;
}

[shader("closesthit")]
void ClosestHit(inout RayPayload payload, in Attributes attr) {
    payload.color = float4(attr.bary, 0, 1) * RayTCurrent() * InstanceID() * PrimitiveIndex() * HitKind();
    float3 hitPos = WorldRayOrigin() + WorldRayDirection() * RayTCurrent();
}

[shader("anyhit")]
void AnyHit(inout RayPayload payload, in Attributes attr) { IgnoreHit(); AcceptHitAndEndSearch(); }

[shader("miss")]
void Miss(inout RayPayload payload) { payload.color = float4(0, 0, 0, 1); }

[shader("intersection")]
void Intersection() { ReportHit(1.0, 0, (Attributes)0); }

[shader("callable")]
void Callable(inout RayPayload payload) { CallShader(0, payload); }

// ── Wave intrinsics and SM6 features ──
[numthreads(64, 1, 1)]
void CSWave(uint3 id : SV_DispatchThreadID) {
    uint lane = WaveGetLaneIndex();
    uint count = WaveGetLaneCount();
    bool first = WaveIsFirstLane();
    float sum = WaveActiveSum(1.0) + WaveActiveProduct(1.0) + WaveActiveMin(1.0) + WaveActiveMax(1.0);
    uint bits = WaveActiveBitAnd(1u) | WaveActiveBitOr(1u) | WaveActiveBitXor(1u) | WaveActiveCountBits(true);
    bool any = WaveActiveAnyTrue(true) || WaveActiveAllTrue(true) || WaveActiveAllEqual(1);
    uint4 ballot = WaveActiveBallot(true);
    float read = WaveReadLaneAt(1.0, 0) + WaveReadLaneFirst(1.0);
    float prefix = WavePrefixSum(1.0) + WavePrefixProduct(1.0) + WavePrefixCountBits(true);
    float quad = QuadReadAcrossX(1.0) + QuadReadAcrossY(1.0) + QuadReadAcrossDiagonal(1.0) + QuadReadLaneAt(1.0, 0);
    float matched = WaveMatch(1.0).x;
    uint packed = dot4add_u8packed(1u, 2u, 3u) + dot4add_i8packed(1u, 2u, 3u);
    uint64_t wide = 0xFFFFFFFFFFFFFFFFull;
    NonUniformResourceIndex(lane);
    uint idx = NonUniformResourceIndex(id.x);
    float4 c = bindless[NonUniformResourceIndex(id.x)].Load(int3(0, 0, 0));
}

// ── HLSL 2021: templates, operators, enums, bitfields ──
struct Vec2 {
    float x, y;
    uint flags : 4;
    uint other : 28;
    Vec2 operator+(Vec2 rhs) { Vec2 r; r.x = x + rhs.x; r.y = y + rhs.y; return r; }
    Vec2 operator*(float s) { Vec2 r = { x * s, y * s }; return r; }
    bool operator==(Vec2 rhs) { return x == rhs.x && y == rhs.y; }
    float operator[](int i) { return i == 0 ? x : y; }
    float Length() { return sqrt(this.x * this.x + this.y * this.y); }
};

template<typename T, int N>
struct Array { T data[N]; T get(int i) { return data[i]; } };

template<typename T>
T Lerp(T a, T b, float t) { return a + (b - a) * t; }

enum class Flags : uint { None = 0, A = 1, B = 2, AB = A | B };

float UseTemplates() {
    Array<float, 4> arr;
    Vec2 a = { 1, 2 }, b = { 3, 4 };
    Vec2 c = a + b * 2.0;
    return Lerp<float>(0, 1, 0.5) + arr.get(0) + c.Length() + (float)sizeof(Vec2);
}

// ── Legacy D3D9 and effects syntax ──
float4 LegacyPS(float2 uv : TEXCOORD0) : COLOR0 {
    float4 c = tex2D(smp2, uv) + tex2Dlod(smp2, float4(uv, 0, 0)) + tex2Dgrad(smp2, uv, ddx(uv), ddy(uv)) + tex2Dbias(smp2, float4(uv, 0, 0)) + tex2Dproj(smp2, float4(uv, 0, 1)) + texCUBE(smpC, float3(uv, 0));
    return c;
}

BlendState AlphaBlend {
    AlphaToCoverageEnable = FALSE;
    BlendEnable[0] = TRUE;
    SrcBlend = SRC_ALPHA;
    DestBlend = INV_SRC_ALPHA;
    BlendOp = ADD;
    RenderTargetWriteMask[0] = 0x0F;
};
RasterizerState NoCull { CullMode = NONE; FillMode = SOLID; };
DepthStencilState DepthOff { DepthEnable = FALSE; DepthWriteMask = ZERO; };

technique10 Legacy {
    pass P0 {
        SetVertexShader(CompileShader(vs_4_0, VSMain()));
        SetGeometryShader(NULL);
        SetPixelShader(CompileShader(ps_4_0, PSMain()));
        SetBlendState(AlphaBlend, float4(0, 0, 0, 0), 0xFFFFFFFF);
        SetRasterizerState(NoCull);
        SetDepthStencilState(DepthOff, 0);
    }
}

fxgroup Group { technique11 T { pass P { } } }

// ── More operators and literals ──
float MoreOperators(float a, int b, uint c) {
    float r = a++ + ++a - a-- - --a;
    r = -a + +a;
    r += 1; r -= 1; r *= 2; r /= 2;
    int ib = b % 3;
    ib %= 2; ib <<= 1; ib >>= 1; ib &= 3; ib |= 1; ib ^= 2;
    uint uc = (c << 3) | (c >> 2) & 0xFu ^ ~c;
    bool cmp = a < 1 && a <= 2 || a > 3 && a >= 4 || a == 5 || a != 6;
    float3 v = float3(1, 2, 3).zyx + float3(1, 2, 3).rgb.bgr + float4(1, 2, 3, 4).xxyy.xyz;
    float2 comma = (1, 2).xy;
    float lit = 1.f + 1.0f + 1.0h + 1.0F + 1e3f + 1.5E-3 + .25 + 3. + 0x1F + 0x1Fu + 0XAB + 010 + 1u + 1U + 1l + 1ul;
    float4x4 mat = {
        1, 0, 0, 0,
        0, 1, 0, 0,
        0, 0, 1, 0,
        0, 0, 0, 1
    };
    float mm = mat._m00 + mat._11 + mat[1][2] + mat._m33;
    float2 swz = mat._m00_m11;
    return r + lit + mm + cmp + ib + uc;
}


// ── Shader Model 6.5–6.8: inline ray queries, work graphs, typed loads, logical intrinsics ──
[shader("compute")]
[numthreads(8, 8, 1)]
void CSRayQuery(uint3 id : SV_DispatchThreadID) {
    RayDesc ray = { float3(0, 0, 0), 0.001, float3(0, 0, 1), 100.0 };
    RayQuery<RAY_FLAG_CULL_NON_OPAQUE | RAY_FLAG_SKIP_PROCEDURAL_PRIMITIVES> q;
    q.TraceRayInline(scene, RAY_FLAG_NONE, 0xFF, ray);
    while (q.Proceed()) {
        if (q.CandidateType() == CANDIDATE_NON_OPAQUE_TRIANGLE) {
            q.CommitNonOpaqueTriangleHit();
        }
    }
    if (q.CommittedStatus() == COMMITTED_TRIANGLE_HIT) {
        float t = q.CommittedRayT();
        uint inst = q.CommittedInstanceID();
        float2 bary = q.CommittedTriangleBarycentrics();
        outputImage[id.xy] = float4(bary, t, inst);
    }
}

struct EntryRecord {
    uint3 gridSize : SV_DispatchGrid;
    uint  id;
};
struct ChildRecord { uint value; };

[Shader("node")]
[NodeLaunch("broadcasting")]
[NodeDispatchGrid(8, 1, 1)]
[NumThreads(64, 1, 1)]
[NodeIsProgramEntry]
void EntryNode(
    DispatchNodeInputRecord<EntryRecord> input,
    [MaxRecords(4)] NodeOutput<ChildRecord> Child,
    uint gtid : SV_GroupThreadID) {
    ThreadNodeOutputRecords<ChildRecord> rec = Child.GetThreadNodeOutputRecords(1);
    rec.Get().value = gtid + input.Get().id;
    rec.OutputComplete();
}

[Shader("node")]
[NodeLaunch("thread")]
void LeafNode(ThreadNodeInputRecord<ChildRecord> input) {
    uint v = input.Get().value;
}

[Shader("node")]
[NodeLaunch("coalescing")]
[NumThreads(32, 1, 1)]
void CoalescedNode([MaxRecords(32)] GroupNodeInputRecords<ChildRecord> inputs, uint gi : SV_GroupIndex) {
    if (gi < inputs.Count()) { uint v = inputs[gi].value; }
}

[WaveSize(16, 64)]
[numthreads(64, 1, 1)]
void CSWaveRange() {}

[numthreads(64, 1, 1)]
void CSTypedLoads(uint3 id : SV_DispatchThreadID) {
    float4 a = rawIn.Load<float4>(id.x * 16);
    uint2  b = rawIn.Load<uint2>(id.x * 8);
    rawOut.Store<float4>(id.x * 16, a);
    bool both = and(a.x > 0, b.x > 0);
    bool either = or(a.x > 0, b.x > 0);
    float picked = select(both, 1.0, 0.0);
    float3 sel3 = select(bool3(true, false, true), float3(1, 2, 3), float3(4, 5, 6));
}

// ── C++11 attributes (HLSL 2021) and SPIR-V (DXC -spirv) attributes ──
[[vk::binding(0, 1)]] Texture2D<float4> vkTexture;
[[vk::binding(1, 1)]] SamplerState vkSampler;
[[vk::push_constant]] struct PushConstants { float4x4 mvp; uint flags; } pushConstants;
[[vk::constant_id(0)]] const int kSpecialization = 4;
[[vk::input_attachment_index(0)]] SubpassInput<float4> vkSubpass;
struct VkVertexOut {
    [[vk::location(0)]] float3 normal : NORMAL;
    [[vk::builtin("PointSize")]] float pointSize : PSIZE;
};
float4 VkFragment(VkVertexOut i) : SV_Target {
    [[likely]] if (i.normal.x > 0) { return vkSubpass.SubpassLoad(); }
    [[unlikely]] if (i.normal.y > 0) { return float4(0, 0, 0, 0); }
    switch (kSpecialization) {
        case 0: [[fallthrough]];
        case 1: return float4(1, 1, 1, 1);
        default: break;
    }
    return vkTexture.Sample(vkSampler, i.normal.xy);
}

// ── Exports and libraries ──
export float LibraryFunction(float x) { return x * 2.0; }
[shader("vertex")] float4 VertexInLibrary(float3 p : POSITION) : SV_Position { return float4(p, 1); }
[shader("pixel")] float4 PixelInLibrary() : SV_Target { return 1; }
[shader("hull")] [domain("quad")] [partitioning("integer")] [outputtopology("triangle_ccw")] [outputcontrolpoints(4)] [patchconstantfunc("PatchConstants")]
VSOut HullInLibrary(InputPatch<VSOut, 4> p, uint i : SV_OutputControlPointID) { return p[i]; }

// Non-ASCII: café 日本語 ☕
