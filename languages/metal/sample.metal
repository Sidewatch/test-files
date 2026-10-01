// Metal Shading Language 4.0 — syntax showcase: stock-map rendering and a compute pass for reorder levels.
/* A block comment
   spanning two lines. */
/// Documentation comment for the shader library.
// TODO: tune the threadgroup size
// FIXME: handle zero-sized grids

#include <metal_stdlib>
#include <metal_compute>
#include <metal_atomic>
#include "ShaderTypes.h"
#import <simd/simd.h>

using namespace metal;

#define MAX_LIGHTS 4
#define SQUARE(x) ((x) * (x))
#define PI 3.14159265358979323846f
#ifndef REORDER_POINT
#define REORDER_POINT 25u
#endif
#if defined(DEBUG) && !defined(NDEBUG)
#define DEBUG_COLOR float4(1.0, 0.0, 1.0, 1.0)
#elif MAX_LIGHTS > 2
#pragma clang diagnostic ignored "-Wunused-variable"
#else
#error "unsupported configuration"
#endif

// ── Constants and function constants ──
constant float kGamma = 2.2f;
constant uint kTileSize [[function_constant(0)]];
constant bool kUseFog [[function_constant(1)]];
constant bool kNoFog = !kUseFog;
constant half3 kTint = half3(0.9h, 0.8h, 0.7h);
constexpr sampler kLinear(coord::normalized, address::clamp_to_edge, filter::linear, mip_filter::linear);
constexpr constant int kLayers = 3;

// ── Numbers ──
constant int   kDec = 42;
constant uint  kHex = 0xFFu;
constant uint  kOct = 0755u;
constant uint  kBin = 0b1010u;
constant long  kLong = 123456789l;
constant float kExp = 1.5e-3f;
constant float kBare = .5f;
constant half  kHalf = 0.25h;
constant bool  kYes = true;
constant bool  kNo = false;

// ── Structs with attributes ──
struct VertexIn {
    float3 position [[attribute(0)]];
    float2 uv       [[attribute(1)]];
    float3 normal   [[attribute(2)]];
    uchar4 color    [[attribute(3)]];
};

struct VertexOut {
    float4 position [[position]];
    float2 uv;
    float3 normal;
    float pointSize [[point_size]];
    uint layer [[render_target_array_index]];
};

struct Uniforms {
    float4x4 mvp;
    float3x3 normalMatrix;
    float    time;
    packed_float3 lightDir;
    uint     lightCount;
};

struct Material {
    float4 albedo;
    float  roughness;
    float  metallic;
    texture2d<float> map [[id(0)]];
    sampler smp [[id(1)]];
};

struct Stock {
    atomic_uint count;
    uint        reorder;
    float       price;
};

enum class Zone : uchar { Cold, Dry, Hazard = 5 };
typedef float4 Color;
using Index = ushort;

template <typename T, int N>
struct Ring {
    T items[N];
    T at(uint i) const { return items[i % N]; }
};

template <typename T>
inline T saturate_sq(T v) { return SQUARE(clamp(v, T(0), T(1))); }

// ── Helper functions ──
inline float3 tonemap(float3 c) {
    c = c / (c + 1.0f);
    return pow(c, 1.0f / kGamma);
}

[[maybe_unused]] static float luminance(float3 c) { return dot(c, float3(0.2126f, 0.7152f, 0.0722f)); }

// ── Vertex stage ──
vertex VertexOut vertex_main(VertexIn in [[stage_in]],
                             uint vid [[vertex_id]],
                             uint iid [[instance_id]],
                             constant Uniforms& u [[buffer(1)]],
                             const device float4x4* models [[buffer(2)]]) {
    VertexOut out;
    out.position = u.mvp * models[iid] * float4(in.position, 1.0);
    out.uv = in.uv + float2(0.0, sin(u.time) * 0.01);
    out.normal = normalize(u.normalMatrix * in.normal);
    out.pointSize = 4.0;
    out.layer = iid % kLayers;
    return out;
}

// ── Fragment stage ──
fragment float4 fragment_main(VertexOut in [[stage_in]],
                              texture2d<float, access::sample> albedo [[texture(0)]],
                              depth2d<float> shadow [[texture(1)]],
                              sampler s [[sampler(0)]],
                              constant Uniforms& u [[buffer(1)]],
                              bool front [[front_facing]],
                              uint sampleId [[sample_id]]) {
    float3 base = albedo.sample(s, in.uv).rgb;
    float shade = mix(0.6, 1.0, in.uv.y);
    float ndl = max(dot(in.normal, -float3(u.lightDir)), 0.0f);
    float3 lit = base * shade * (0.2 + ndl);
    if (kUseFog) {
        lit = mix(lit, float3(0.5), 0.25);
    } else if (!front) {
        lit *= 0.5;
    }
    float4 result = float4(tonemap(lit), 1.0);
#if defined(DEBUG)
    result = DEBUG_COLOR;
#endif
    return result;
}

fragment half4 tint_main(VertexOut in [[stage_in]],
                         texture2d<half> tex [[texture(0)]]) {
    half4 c = tex.sample(kLinear, in.uv);
    return c * half4(kTint, 1.0h);
}

// ── Kernel stage ──
kernel void reorder_levels(device Stock* stocks [[buffer(0)]],
                           constant uint& count [[buffer(1)]],
                           threadgroup uint* shared [[threadgroup(0)]],
                           uint tid [[thread_position_in_grid]],
                           uint lid [[thread_position_in_threadgroup]],
                           uint gid [[threadgroup_position_in_grid]],
                           uint tgSize [[threads_per_threadgroup]],
                           uint simdLane [[thread_index_in_simdgroup]]) {
    if (tid >= count) { return; }
    device Stock& s = stocks[tid];
    uint have = atomic_load_explicit(&s.count, memory_order_relaxed);
    shared[lid] = have < s.reorder ? 1u : 0u;
    threadgroup_barrier(mem_flags::mem_threadgroup);
    for (uint stride = tgSize / 2; stride > 0; stride >>= 1) {
        if (lid < stride) { shared[lid] += shared[lid + stride]; }
        threadgroup_barrier(mem_flags::mem_threadgroup);
    }
    while (have < REORDER_POINT) {
        have = atomic_fetch_add_explicit(&s.count, 5u, memory_order_relaxed) + 5u;
        if (have > 1000u) break;
        continue;
    }
    do { have ^= 0x1u; } while (false);
    switch (tid & 3u) {
        case 0: s.price *= 1.01f; break;
        case 1: s.price -= 0.5f; break;
        default: break;
    }
    float sum = simd_sum(float(have));
    uint bits = (have << 2) | (have >> 30) & 0xFu;
    bool ok = (have != 0u && sum >= 0.0f) || !kNo;
    int sel = ok ? 1 : -1;
    s.price = clamp(s.price + float(sel), 0.0f, 9999.99f);
}

// ── Tile (imageblock-free) compute with 2D grid ──
kernel void blur(texture2d<float, access::read> src [[texture(0)]],
                 texture2d<float, access::write> dst [[texture(1)]],
                 uint2 gid [[thread_position_in_grid]]) {
    float4 acc = float4(0);
    for (int dy = -1; dy <= 1; ++dy) {
        for (int dx = -1; dx <= 1; ++dx) {
            acc += src.read(uint2(int2(gid) + int2(dx, dy)));
        }
    }
    dst.write(acc / 9.0f, gid);
}

// ── Mesh-style and ray-tracing attributes ──
[[kernel]] void attr_style(device uint* out [[buffer(0)]], uint tid [[thread_position_in_grid]]) {
    out[tid] = as_type<uint>(1.0f);
}

[[visible]] float helper(float x) { return x * x; }

// ── Tile, imageblock and raster-order attributes ──
struct FragmentOut {
    float4 color [[color(0)]];
    float4 normal [[color(1), raster_order_group(0)]];
    float depth [[depth(any)]];
    uint mask [[sample_mask]];
};

struct TileData {
    half4 accum [[raster_order_group(1)]];
};

fragment FragmentOut gbuffer_main(VertexOut in [[stage_in]],
                                  float4 prev [[color(0)]],
                                  uint prim [[primitive_id]],
                                  float2 pc [[point_coord]],
                                  float3 bary [[barycentric_coord]],
                                  ushort viewport [[viewport_array_index]],
                                  uint amp [[amplification_id]]) {
    FragmentOut out;
    out.color = prev;
    out.normal = float4(in.normal * 0.5 + 0.5, 1.0);
    out.depth = in.position.z;
    out.mask = 0xFFFFFFFFu;
    return out;
}

// ── Compute: simdgroup matrices and threadgroup memory ──
kernel void matmul(device const half* a [[buffer(0)]],
                   device const half* b [[buffer(1)]],
                   device float* c [[buffer(2)]],
                   uint3 tgid [[threadgroup_position_in_grid]],
                   ushort sid [[simdgroup_index_in_threadgroup]],
                   uint3 grid [[threads_per_grid]],
                   uint3 tpg [[threadgroups_per_grid]],
                   uint3 gsize [[grid_size]],
                   uint tcount [[thread_index_in_threadgroup]]) {
    simdgroup_float8x8 acc = simdgroup_float8x8(0);
    simdgroup_half8x8 ma, mb;
    simdgroup_load(ma, a, 8);
    simdgroup_load(mb, b, 8);
    simdgroup_multiply_accumulate(acc, ma, mb, acc);
    simdgroup_store(acc, c, 8);
    threadgroup float tile[16][16];
    tile[tcount % 16][0] = simd_prefix_exclusive_sum(1.0f);
    simdgroup_barrier(mem_flags::mem_none);
}

// ── Indirect command buffers, argument buffers and function tables ──
struct ArgBuffer {
    device float* data [[id(0)]];
    constant uint& count [[id(1)]];
    array<texture2d<float>, 4> textures [[id(2)]];
};

kernel void use_args(constant ArgBuffer& args [[buffer(0)]], uint tid [[thread_position_in_grid]]) {
    if (tid < args.count) args.data[tid] = args.textures[0].read(uint2(tid, 0)).x;
}

[[stitchable]] float stitched(float x) { return x + 1.0f; }

// ── Object, mesh and tessellation stage qualifiers (declarations only) ──
struct PatchIn { float4 pos [[attribute(0)]]; };
[[patch(triangle, 3)]] vertex VertexOut tess_vertex(PatchIn p [[stage_in]], uint pid [[patch_id]], float3 loc [[position_in_patch]]) { VertexOut o; o.position = p.pos; o.uv = loc.xy; o.normal = loc; o.pointSize = 1.0; o.layer = pid; return o; }
[[max_total_threads_per_threadgroup(256)]] kernel void limited(uint t [[thread_position_in_grid]]) {}
[[early_fragment_tests]] fragment float4 early_main(VertexOut in [[stage_in]]) { return float4(1); }

// ── Casts, address spaces and misc ──
kernel void misc(device uint* out [[buffer(0)]], const device packed_float3* v [[buffer(1)]],
                 device float* r [[buffer(2)]], constant float4x4* mats [[buffer(3)]]) {
    uint a = as_type<uint>(1.0f);
    float b = static_cast<float>(a);
    half c = half(b);
    float4 d = float4(float3(v[0]), 1.0f);
    int e = int(c) + (int)b;
    ulong f = (ulong)a << 32;
    short2 g = short2(1, 2);
    uchar h = 255;
    bool4 i = bool4(true, false, true, false);
    out[0] = select(a, 0u, any(i)) + (all(i) ? 1u : 0u) + popcount(a) + clz(a) + ctz(a) + extract_bits(a, 0, 4) + reverse_bits(a);
    out[1] = uint(abs(e)) + min(a, 3u) + max(a, 3u) + uint(fma(b, 2.0f, 1.0f)) + uint(f) + uint(g.x) + uint(h) + uint(d.x);
}

// ── Mesh shading (object + mesh stages) ──
#include <metal_mesh>
struct MeshVertex { float4 position [[position]]; float3 color; };
struct MeshPrim { float3 tint [[flat]]; };
struct ObjectPayload { uint indices[16]; };
using TriMesh = metal::mesh<MeshVertex, MeshPrim, 3, 1, topology::triangle>;

[[object, max_total_threads_per_threadgroup(32)]]
void object_main(object_data ObjectPayload& payload [[payload]],
                 mesh_grid_properties grid,
                 uint tid [[thread_index_in_threadgroup]]) {
    payload.indices[tid % 16] = tid;
    grid.set_threadgroups_per_grid(uint3(1, 1, 1));
}

[[mesh, max_total_threads_per_threadgroup(3)]]
void mesh_main(TriMesh output,
               const object_data ObjectPayload& payload [[payload]],
               uint tid [[thread_index_in_threadgroup]]) {
    output.set_primitive_count(1);
    MeshVertex v;
    v.position = float4(float(tid), 0.0, 0.0, 1.0);
    v.color = float3(1.0);
    output.set_vertex(tid, v);
    output.set_index(tid, tid);
    if (tid == 0) { MeshPrim p; p.tint = float3(0.5); output.set_primitive(0, p); }
}

// ── Ray tracing ──
#include <metal_raytracing>
using namespace metal::raytracing;

[[intersection(triangle, triangle_data, instancing)]]
bool tri_filter(uint prim [[primitive_id]], float2 bc [[barycentric_coord]]) { return bc.x > 0.1; }

struct BBoxResult { bool accept [[accept_intersection]]; float distance [[distance]]; };
[[intersection(bounding_box)]]
BBoxResult bbox_main(float3 origin [[origin]], float3 dir [[direction]],
                                           float tmin [[min_distance]], float tmax [[max_distance]]) {
    BBoxResult r;
    r.accept = true;
    r.distance = tmin;
    return r;
}

kernel void trace(instance_acceleration_structure scene [[buffer(0)]],
                  intersection_function_table<triangle_data, instancing> table [[buffer(1)]],
                  visible_function_table<float(float)> vft [[buffer(2)]],
                  texture2d<float, access::write> img [[texture(0)]],
                  uint2 tid [[thread_position_in_grid]]) {
    ray r(float3(0, 0, -1), float3(0, 0, 1), 0.001f, 100.0f);
    intersector<triangle_data, instancing> i;
    i.assume_geometry_type(geometry_type::triangle);
    i.force_opacity(forced_opacity::opaque);
    intersection_result<triangle_data, instancing> hit = i.intersect(r, scene, table);
    float v = hit.type == intersection_type::triangle ? hit.distance : 0.0f;
    img.write(float4(v), tid);
}

// ── Compiler extensions, attributes and qualifiers ──
#pragma METAL internals : enable
[[clang::always_inline]] inline float fast_sq(float x) { return x * x; }
[[clang::optnone]] void no_opt() {}
[[deprecated("use fast_sq")]] float old_sq(float x) { return x * x; }
[[nodiscard]] static inline int must_use() { return 1; }
static_assert(sizeof(float4) == 16, "float4 is 16 bytes");
constant constexpr int kCount = 4;
template <typename T> T twice(T v) { return v + v; }
template <typename T> struct Box { T value; constexpr Box() : value() {} };
namespace stock { namespace detail { inline float scale(float x) { return x * 2.0f; } } }
union Bits { uint u; float f; };
struct Packed { packed_float3 p; packed_uint2 q; packed_half4 h; };
struct Aligned { alignas(16) float x; };
float use_lambda(float v) {
    auto lambda_demo = [](float x) { return x + 1.0f; };
#pragma clang loop unroll(full)
    for (int i = 0; i < 4; ++i) { v = lambda_demo(v); }
    return v;
}

// ── Metal 4 tensors (MSL 4.0) ──
#include <metal_tensor>
kernel void tensor_demo(tensor<device float, dextents<int, 2>> t [[buffer(0)]],
                        uint2 tid [[thread_position_in_grid]]) {
    int rows = t.get_extent(0);
    if (int(tid.x) < rows) { t[tid.y, tid.x] = 1.0f; }
}
