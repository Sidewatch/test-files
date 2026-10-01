// OpenCL C 3.0 — syntax showcase: vector kernels, reductions, images, atomics and vector types.
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

// ── OpenCL C 3.0: feature-test macros, optional features and attributes ──
#if __OPENCL_C_VERSION__ >= 300
#define CL3 1
#endif
#ifdef __opencl_c_fp64
#define HAS_DOUBLE 1
#endif
#if defined(__opencl_c_images) && defined(__opencl_c_3d_image_writes)
#define HAS_IMAGES_3D 1
#elif defined(__opencl_c_read_write_images)
#define HAS_RW_IMAGES 1
#elifdef __opencl_c_pipes
#define HAS_PIPES 1
#elifndef __opencl_c_device_enqueue
#define NO_DEVICE_ENQUEUE 1
#endif
#if defined(__opencl_c_generic_address_space) && defined(__opencl_c_program_scope_global_variables)
global int g_counter = 0;
#endif
#if defined(__opencl_c_work_group_collective_functions) && defined(__opencl_c_subgroups)
#define HAS_COLLECTIVES 1
#endif
#pragma OPENCL EXTENSION cl_khr_subgroups : enable
#pragma OPENCL EXTENSION cl_khr_3d_image_writes : enable
#pragma OPENCL EXTENSION cl_khr_byte_addressable_store : enable
#pragma OPENCL EXTENSION cl_khr_local_int32_extended_atomics : enable

typedef float float4_ext __attribute__((ext_vector_type(4)));
typedef struct __attribute__((packed, aligned(4))) { uchar a; uint b; } PackedAligned;
typedef int int_endian __attribute__((endian(host)));

__attribute__((intel_reqd_sub_group_size(16)))
__attribute__((reqd_work_group_size(64, 1, 1)))
__attribute__((work_group_size_hint(64, 1, 1)))
__attribute__((vec_type_hint(float)))
__attribute__((nosvm))
kernel void attributes_demo(global float* restrict out, global const float* restrict in, const int n) {
    size_t i = get_global_id(0);
    if (i < n) out[i] = in[i];
}

atomic_flag g_flag = ATOMIC_FLAG_INIT;

kernel void memory_model(global atomic_int* counter, global atomic_uint* flags, local atomic_int* lcl) {
    atomic_flag_test_and_set_explicit(&g_flag, memory_order_acquire, memory_scope_work_group);
    atomic_flag_clear(&g_flag);
    int old = atomic_exchange_explicit(counter, 1, memory_order_acq_rel, memory_scope_device);
    atomic_store(counter, old);
    int loaded = atomic_load_explicit(counter, memory_order_acquire, memory_scope_all_svm_devices);
    atomic_fetch_or(flags, 1u);
    atomic_fetch_and(flags, 3u);
    atomic_fetch_xor(flags, 2u);
    atomic_fetch_min(counter, loaded);
    atomic_fetch_max(counter, loaded);
    atomic_work_item_fence(CLK_LOCAL_MEM_FENCE | CLK_GLOBAL_MEM_FENCE, memory_order_release, memory_scope_work_item);
    (void)lcl;
}

kernel void query_builtins(global ulong* out, global void* svm_ptr) {
    size_t lsz = get_enqueued_local_size(0);
    size_t gid_lin = get_global_linear_id();
    size_t lid_lin = get_local_linear_id();
    size_t ngroups = get_enqueued_num_sub_groups();
    out[0] = lsz + gid_lin + lid_lin + ngroups + vec_step(float4) + sizeof(long);
    size_t gws2[2] = {8, 8};
    ndrange_t nd2 = ndrange_2D(gws2);
    ndrange_t nd3 = ndrange_1D(8, 2);
    (void)nd2; (void)nd3;
    uint wgsz = get_kernel_work_group_size(^{});
    uint pref = get_kernel_preferred_work_group_size_multiple(^{});
    (void)wgsz; (void)pref;
    float f = as_float((uint)0x3F800000);
    float g = __builtin_astype((uint)0x3F800000, float);
    out[1] = (ulong)(f + g);
    out[2] = work_group_scan_exclusive_add(1) + work_group_scan_inclusive_max(2) + work_group_any(1) + work_group_all(1);
    ulong8 big = (ulong8)(1, 2, 3, 4, 5, 6, 7, 8);
    long2 l2 = (long2)(1L, 2L);
    char16 c16 = (char16)(1);
    short3 s3 = (short3)(1, 2, 3);
    (void)big; (void)l2; (void)c16; (void)s3;
}

// Cast and literal forms
kernel void literals(global float* out) {
    const float a = 1.0f, b = 1.0, c = 1e3f, d = 0x1p-2f, e = 0.f;
    const half h = (half)1.5f;
    const double dd = 1.0L;
    const uint u = 4294967295u;
    const ulong ul = 0xFFFFFFFFFFFFFFFFul;
    const char ch = '\0';
    const char oct = '\101';
    const char hex = '\x41';
    const float4 v = (float4)(1.0f);
    const float4 w = (float4)(1.0f, 2.0f, 3.0f, 4.0f);
    const float4 z = (float4){1.0f, 2.0f, 3.0f, 4.0f};
    const float4 lit = {1, 2, 3, 4};
    constant char* s = "string literal";
    out[0] = a + b + c + d + e + (float)h + (float)dd + (float)u + (float)ul + (float)ch + (float)oct + (float)hex + v.x + w.y + z.z + lit.w + (float)s[0];
}

#pragma OPENCL EXTENSION cl_khr_fp64 : disable
#pragma OPENCL EXTENSION all : disable
