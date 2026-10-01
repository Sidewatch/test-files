// OpenCL C showcase: vector kernels, reductions, images, atomics and vector types.
/* A block comment
   over several lines. */
/// Documentation comment.
// TODO: tune the work-group size per device
// FIXME: reduce_sum assumes a power-of-two group

#pragma OPENCL EXTENSION cl_khr_fp64 : enable
#pragma OPENCL EXTENSION cl_khr_global_int32_base_atomics : enable
#pragma OPENCL EXTENSION cl_khr_fp16 : enable

#define WORK_GROUP 64
#define SQUARE(x) ((x) * (x))
#define CLAMP01(x) clamp((x), 0.0f, 1.0f)
#ifndef REORDER_POINT
#define REORDER_POINT 25
#endif
#if __OPENCL_VERSION__ >= 200 && defined(__OPENCL_C_VERSION__)
#define HAS_CL2 1
#elif defined(cl_khr_fp64)
#define HAS_FP64 1
#else
#define HAS_BASE 1
#endif

// ── Constants and numbers ──
__constant float SCALE = 2.0f;
__constant int TABLE[4] = { 1, 2, 3, 4 };
__constant sampler_t SMP = CLK_NORMALIZED_COORDS_FALSE | CLK_ADDRESS_CLAMP_TO_EDGE | CLK_FILTER_NEAREST;
constant float kPi = M_PI_F;
constant uint kHex = 0xFFu;
constant uint kOct = 0755u;
constant ulong kBig = 18446744073709551615UL;
constant long kLong = 123456789L;
constant float kExp = 1.5e-3f;
constant float kBare = .5f;
constant double kDouble = 1.0e10;
constant float kHexF = 0x1.8p3f;
constant float kInf = INFINITY;
constant char kCh = 'x';
constant char kEsc = '\n';
constant bool kYes = true;

// ── Types ──
typedef struct {
    float x, y;
} Vec2;

typedef struct __attribute__((packed)) {
    uchar flags;
    uint  qty;
    float price;
} Stock;

typedef union { float f; uint u; } Bits;
typedef enum { COLD, DRY = 5, HAZARD } Zone;
typedef float4 Color;

struct __attribute__((aligned(16))) Item {
    int sku;
    int qty;
    float price;
};

// ── Helper functions ──
inline float lum(float3 c) { return dot(c, (float3)(0.2126f, 0.7152f, 0.0722f)); }
static float2 rotate2d(float2 v, float a) {
    float s = sin(a), c = cos(a);
    return (float2)(c * v.x - s * v.y, s * v.x + c * v.y);
}
float lerp3(float a, float b, float t) { return mad(t, b - a, a); }

// ── Kernels ──
__kernel void vadd(__global const float* a,
                   __global const float* b,
                   __global float* out,
                   const unsigned int n)
{
    size_t i = get_global_id(0);
    if (i < n) out[i] = SCALE * a[i] + b[i];
}

__attribute__((reqd_work_group_size(64, 1, 1)))
__kernel void reduce_sum(__global const float* in,
                         __global float* partial,
                         __local float* scratch,
                         const unsigned int n)
{
    size_t gid = get_global_id(0), lid = get_local_id(0), size = get_local_size(0);
    scratch[lid] = gid < n ? in[gid] : 0.0f;
    barrier(CLK_LOCAL_MEM_FENCE);

    for (size_t stride = size / 2; stride > 0; stride >>= 1) {
        if (lid < stride) scratch[lid] += scratch[lid + stride];
        barrier(CLK_LOCAL_MEM_FENCE);
    }
    if (lid == 0) partial[get_group_id(0)] = scratch[0];
}

kernel void count_low(global const int* qty, global volatile int* counter, private int limit) {
    int i = get_global_id(0);
    if (qty[i] < limit) atomic_inc(counter);
    atom_add(counter, 0);
    atomic_fetch_add_explicit((volatile global atomic_int*)counter, 0, memory_order_relaxed, memory_scope_device);
}

__kernel void invert(__read_only image2d_t src, __write_only image2d_t dst) {
    int2 pos = (int2)(get_global_id(0), get_global_id(1));
    float4 px = read_imagef(src, SMP, pos);
    px.xyz = 1.0f - px.xyz;
    px.w = CLAMP01(px.w);
    write_imagef(dst, pos, px);
}

__kernel void vectors(__global float4* data, __constant int* table) {
    size_t i = get_global_id(0);
    half h = 0.25h;
    float4 v = data[i] + (float)h;
    float4 w = (float4)(1.0f, 2.0f, 3.0f, 4.0f);
    float2 xy = v.xy;
    float3 rgb = v.rgb;
    float4 swz = v.wzyx;
    float x = v.s0 + v.s1 + v.s3;
    uchar4 bytes = convert_uchar4_sat(v * 255.0f);
    int4 mask = v > w;
    float4 sel = select(v, w, mask);
    float4 mixed = mix(v, w, 0.5f);
    float4 cross4 = (float4)(cross(v.xyz, w.xyz), 0.0f);
    uint bits = as_uint(x);
    float len = length(v) + distance(v, w) + dot(v, w);
    data[i] = normalize(sel) * len + mixed + cross4 + (float4)(swz.x, xy, (float)bits) + (float4)(rgb, (float)bytes.x);
}

__kernel void control(__global int* out, int n) {
    int gid = get_global_id(0);
    int acc = 0;
    if (gid >= n) { return; } else if (gid == 0) { acc = 1; } else { acc = 2; }
    #pragma unroll 4
    for (int i = 0; i < 4; ++i) { if (i == 1) continue; if (i == 3) break; acc += TABLE[i]; }
    while (acc < 100) acc <<= 1;
    do { acc--; } while (acc > 50);
    switch (gid & 3) {
        case 0: acc += 1; break;
        case 1:
        case 2: acc ^= 0xF; break;
        default: acc = ~acc; break;
    }
    int t = (acc > 5 && gid != 0) || !(acc <= 5) ? acc % 7 : -acc / 3;
    acc = (acc & 0xFF) | ((acc >> 3) ^ (t << 2));
    acc += 1; acc -= 1; acc *= 2; acc /= 2; acc %= 9; acc &= 7; acc |= 8; acc ^= 1; acc <<= 1; acc >>= 1;
    out[gid] = acc;
    work_group_barrier(CLK_GLOBAL_MEM_FENCE);
    mem_fence(CLK_LOCAL_MEM_FENCE | CLK_GLOBAL_MEM_FENCE);
}

__kernel void stock_update(__global struct Item* items, __global Stock* stock, ulong count) {
    size_t i = get_global_id(0);
    if (i >= count) return;
    __private struct Item it = items[i];
    __local int shared_count;
    if (get_local_id(0) == 0) shared_count = 0;
    barrier(CLK_LOCAL_MEM_FENCE);
    if (it.qty < REORDER_POINT) atomic_inc(&shared_count);
    items[i].price = it.price * (1.0f + 0.01f * shared_count);
    stock[i].qty = it.qty;
}

// ── More OpenCL C: address spaces, images, pipes, blocks and builtins ──
#pragma OPENCL EXTENSION cl_khr_int64_base_atomics : enable
#pragma OPENCL FP_CONTRACT ON
#pragma OPENCL SELECT_ROUNDING_MODE rtz

typedef struct { int a; float b; } Pair;
typedef int2 Index2;
typedef event_t Evt;

__kernel __attribute__((vec_type_hint(float4))) __attribute__((work_group_size_hint(64, 1, 1)))
void hints(__global float4* in, __global float4* out, __local float4* tmp, __constant float* coeffs, __private int n) {
    size_t g = get_global_id(0), l = get_local_id(0), grp = get_group_id(0);
    size_t gs = get_global_size(0), ls = get_local_size(0), ng = get_num_groups(0), off = get_global_offset(0);
    uint dim = get_work_dim();
    event_t e = async_work_group_copy(tmp, in + grp * ls, ls, 0);
    wait_group_events(1, &e);
    barrier(CLK_LOCAL_MEM_FENCE | CLK_GLOBAL_MEM_FENCE);
    float4 v = vload4(g, (__global float*)in);
    vstore4(v * coeffs[0], g, (__global float*)out);
    float8 wide = (float8)(v, v);
    float4 lo = wide.lo, hi = wide.hi, odd = wide.odd, even = wide.even;
    int4 ibits = as_int4(v);
    uchar16 u16 = convert_uchar16((float16)(wide, wide));
    float r = native_sqrt(v.x) + half_rsqrt(v.y) + fast_length(v) + fma(v.x, v.y, v.z) + rootn(v.x, 3) + hypot(v.x, v.y) + atan2pi(v.x, v.y) + (float)hadd(1, 3);
    float m = fmax(v.x, v.y) + fmin(v.x, v.y) + mix(v.x, v.y, 0.5f) + step(0.5f, v.x) + smoothstep(0.0f, 1.0f, v.x) + sign(v.x) + degrees(v.x) + radians(v.y);
    int c = clz(ibits.x) + popcount(ibits.y) + rotate(ibits.z, ibits.w) + mul_hi(ibits.w, ibits.x) + mad24(ibits.x, ibits.y, ibits.z) + (int)abs_diff(ibits.x, ibits.y) + add_sat(ibits.x, ibits.y);
    int cmpv = isnan(v.x) + isinf(v.y) + isfinite(v.z) + isnormal(v.w) + signbit(v.x) + isequal(v.x, v.y) + isgreater(v.x, v.y) + any(ibits) + all(ibits) + bitselect(1, 2, 3);
    printf("g=%zu r=%f c=%d %v4f\n", g, r, c, v);
    out[g] = (float4)(r, m, (float)c, (float)cmpv + (float)u16.s0 + lo.x + hi.y + odd.x + even.y + (float)dim + (float)gs + (float)off + (float)ng);
}

__kernel void images(read_only image3d_t vol, write_only image2d_array_t layers, read_write image2d_t rw, sampler_t smp,
                     __global int* out) {
    int4 c = (int4)(get_global_id(0), get_global_id(1), get_global_id(2), 0);
    float4 px = read_imagef(vol, smp, c);
    uint4 up = read_imageui(rw, c.xy);
    int4 ip = read_imagei(vol, smp, (float4)(0.5f, 0.5f, 0.5f, 0.0f));
    write_imagef(layers, (int4)(c.xy, 0, 0), px);
    out[0] = get_image_width(rw) + get_image_height(rw) + get_image_depth(vol) + get_image_channel_data_type(rw) + get_image_channel_order(rw) + get_image_array_size(layers) + (int)up.x + ip.x;
    out[1] = get_image_dim(rw).x;
}

__kernel void pipes(read_only pipe int src, write_only pipe int dst) {
    int v;
    if (read_pipe(src, &v) == 0) write_pipe(dst, &v);
    reserve_id_t rid = reserve_read_pipe(src, 1);
    commit_read_pipe(src, rid);
    work_group_reserve_write_pipe(dst, 1);
}

__kernel void device_enqueue(__global int* data) {
    queue_t q = get_default_queue();
    ndrange_t nd = ndrange_1D(64);
    enqueue_kernel(q, CLK_ENQUEUE_FLAGS_NO_WAIT, nd, ^{ data[get_global_id(0)] += 1; });
    clk_event_t ev;
    enqueue_kernel(q, CLK_ENQUEUE_FLAGS_WAIT_KERNEL, nd, 0, NULL, &ev, ^(local void* p) { }, 128);
    release_event(ev);
    int (^blk)(int) = ^(int x) { return x * 2; };
    data[0] = blk(2);
    atomic_int counter;
    atomic_init(&counter, 0);
    atomic_work_item_fence(CLK_GLOBAL_MEM_FENCE, memory_order_seq_cst, memory_scope_work_group);
    int expected = 0;
    atomic_compare_exchange_strong(&counter, &expected, 1);
    global int* gp = to_global(data);
    generic int* gen = (generic int*)data;
    (void)gp; (void)gen;
}

__kernel void subgroups(__global int* out) {
    uint sg = get_sub_group_id();
    uint lane = get_sub_group_local_id();
    uint sz = get_sub_group_size();
    out[get_global_id(0)] = sub_group_reduce_add((int)lane) + sub_group_scan_inclusive_add(1) + sub_group_broadcast(1, 0) + (int)(sg + sz) + sub_group_all(1);
    sub_group_barrier(CLK_LOCAL_MEM_FENCE);
    work_group_broadcast(1, 0);
    work_group_reduce_max(1);
}

kernel void ternary_and_goto(global uint* x) {
    uint v = x[0] ? x[1] : x[2];
    if (v == 0) goto out;
    x[0] = ~v;
out:
    x[1] = v;
}
