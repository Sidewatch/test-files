// CUDA C++ 13.0 (C++20 device code, sm_75 through sm_120) — syntax showcase
// ── Comments ──
// Line comment. TODO: tune the block size. FIXME: handle n not divisible by 4.
/* Block comment
   across lines */
/**
 * @brief  Warehouse stock kernels.
 * @param  n   element count
 * @return nothing
 */

// ── Preprocessor ──
#pragma once
#include <cstdio>
#include <cstdlib>
#include <cmath>
#include <cuda_runtime.h>
#include <cuda_fp16.h>
#include <cooperative_groups.h>
#include <cub/cub.cuh>
#include <thrust/device_vector.h>
#include <thrust/reduce.h>

#define CHECK(call)                                                      \
    do {                                                                 \
        cudaError_t err__ = (call);                                      \
        if (err__ != cudaSuccess) {                                      \
            fprintf(stderr, "CUDA error %s at %s:%d\n",                  \
                    cudaGetErrorString(err__), __FILE__, __LINE__);      \
            exit(EXIT_FAILURE);                                          \
        }                                                                \
    } while (0)

#ifdef __CUDACC__
#define HD __host__ __device__
#else
#define HD
#endif
#if defined(__CUDA_ARCH__) && __CUDA_ARCH__ >= 800
#define HAS_AMPERE 1
#endif

namespace cg = cooperative_groups;

// ── Constants and literals ──
constexpr int kBlock = 256;
constexpr int kWarp = 32;
constexpr unsigned kMask = 0xFFFFFFFFu;
constexpr float kScale = 1.5f;
constexpr double kEps = 1e-6;
constexpr long long kBig = 1'000'000LL;
constexpr int kBinary = 0b1010;
const char* kName = "warehouse \"north\"\t\n";
const char* kRaw = R"(raw \n string)";
const char kChar = '\n';

// ── Memory spaces ──
__constant__ float c_weights[16];
__device__ int d_counter = 0;
__managed__ float m_total;
__device__ __managed__ int dm_flag;
// The texture<> reference API was removed in CUDA 12; texture objects (cudaTextureObject_t) replace it.
cudaTextureObject_t tex_stock;

// ── Structs and templates ──
struct __align__(16) Item {
    float price;
    int qty;
    int sku;
    int flags;
};

struct alignas(8) Pair { int a, b; };

template <typename T>
HD inline T clampv(T v, T lo, T hi) {
    return v < lo ? lo : (v > hi ? hi : v);
}

__host__ __device__ float lerp(float a, float b, float t) { return a + t * (b - a); }
__forceinline__ __device__ float sq(float x) { return x * x; }
__noinline__ __device__ float cube(float x) { return x * x * x; }

// ── Kernels ──
__global__ void saxpy(int n, float a, const float* __restrict__ x, float* __restrict__ y) {
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i < n) y[i] = a * x[i] + y[i];
}

__global__ void __launch_bounds__(256, 4) reduce_sum(const float* in, float* out, int n) {
    extern __shared__ float sdata[];
    __shared__ int block_flag;
    unsigned tid = threadIdx.x;
    unsigned idx = blockIdx.x * (blockDim.x * 2) + tid;
    float v = (idx < n) ? in[idx] : 0.0f;
    if (idx + blockDim.x < n) v += in[idx + blockDim.x];
    sdata[tid] = v;
    __syncthreads();

    for (unsigned s = blockDim.x / 2; s > 32; s >>= 1) {
        if (tid < s) sdata[tid] += sdata[tid + s];
        __syncthreads();
    }
    if (tid < 32) {
        v = sdata[tid] + sdata[tid + 32];
        for (int off = 16; off > 0; off >>= 1)
            v += __shfl_down_sync(kMask, v, off);
    }
    if (tid == 0) {
        out[blockIdx.x] = v;
        atomicAdd(&d_counter, 1);
    }
}

__global__ void warp_ops(int* out, const int* in) {
    int lane = threadIdx.x % warpSize;
    int v = in[threadIdx.x];
    int b = __ballot_sync(kMask, v > 0);
    int a = __any_sync(kMask, v > 0);
    int all = __all_sync(kMask, v > 0);
    int s = __shfl_sync(kMask, v, 0);
    int x = __shfl_xor_sync(kMask, v, 1);
    int p = __popc(b) + __clz(b) + __ffs(b);
    float f = __fmaf_rn(1.0f, 2.0f, 3.0f) + __expf(1.0f) + __sinf(0.5f) + rsqrtf(4.0f);
    atomicMax(&out[0], v);
    atomicCAS(&out[1], 0, 1);
    __threadfence();
    __syncwarp();
    out[lane] = b + a + all + s + x + p + (int)f;
}

__global__ void grid_sync_kernel(float* data) {
    cg::grid_group grid = cg::this_grid();
    cg::thread_block block = cg::this_thread_block();
    cg::thread_block_tile<32> tile = cg::tiled_partition<32>(block);
    data[grid.thread_rank()] = tile.shfl(data[0], 0);
    grid.sync();
}

__global__ void matmul(const float* A, const float* B, float* C, int N) {
    __shared__ float As[16][16];
    __shared__ float Bs[16][16];
    int row = blockIdx.y * 16 + threadIdx.y;
    int col = blockIdx.x * 16 + threadIdx.x;
    float acc = 0.0f;
    for (int t = 0; t < N / 16; ++t) {
        As[threadIdx.y][threadIdx.x] = A[row * N + t * 16 + threadIdx.x];
        Bs[threadIdx.y][threadIdx.x] = B[(t * 16 + threadIdx.y) * N + col];
        __syncthreads();
        #pragma unroll
        for (int k = 0; k < 16; ++k) acc += As[threadIdx.y][k] * Bs[k][threadIdx.x];
        __syncthreads();
    }
    C[row * N + col] = acc;
}

// ── Host code ──
int main(int argc, char** argv) {
    const int n = 1 << 20;
    size_t bytes = n * sizeof(float);
    float *x, *y, *d_x, *d_y;
    cudaStream_t stream;
    cudaEvent_t start, stop;

    CHECK(cudaMallocManaged(&x, bytes));
    CHECK(cudaMallocHost(&y, bytes));
    CHECK(cudaMalloc(&d_x, bytes));
    CHECK(cudaMalloc((void**)&d_y, bytes));
    CHECK(cudaStreamCreate(&stream));
    CHECK(cudaEventCreate(&start));
    CHECK(cudaEventCreate(&stop));
    for (int i = 0; i < n; ++i) { x[i] = 1.0f; y[i] = 2.0f; }

    CHECK(cudaMemcpy(d_x, x, bytes, cudaMemcpyHostToDevice));
    CHECK(cudaMemcpyAsync(d_y, y, bytes, cudaMemcpyHostToDevice, stream));
    CHECK(cudaMemcpyToSymbol(c_weights, x, 16 * sizeof(float)));

    dim3 block(kBlock), grid((n + block.x - 1) / block.x);
    dim3 block2d(16, 16, 1);
    cudaEventRecord(start, stream);
    saxpy<<<grid, block>>>(n, 2.0f, d_x, d_y);
    saxpy<<<grid, block, 0, stream>>>(n, 2.0f, d_x, d_y);
    reduce_sum<<<grid, block, kBlock * sizeof(float), stream>>>(d_x, d_y, n);
    void* args[] = {&d_x};
    cudaLaunchCooperativeKernel((void*)grid_sync_kernel, grid, block, args);
    cudaEventRecord(stop, stream);
    CHECK(cudaGetLastError());
    CHECK(cudaDeviceSynchronize());

    float ms = 0.0f;
    cudaEventElapsedTime(&ms, start, stop);
    CHECK(cudaMemcpy(y, d_y, bytes, cudaMemcpyDeviceToHost));

    thrust::device_vector<int> dv(100, 1);
    int total = thrust::reduce(dv.begin(), dv.end(), 0, thrust::plus<int>());

    cudaDeviceProp prop;
    cudaGetDeviceProperties(&prop, 0);
    printf("%s: %d SMs, %.2f ms, total %d\n", prop.name, prop.multiProcessorCount, ms, total);

    float maxError = 0.0f;
    for (int i = 0; i < n; ++i) maxError = fmaxf(maxError, fabsf(y[i] - 4.0f));
    printf("max error: %f\n", maxError);

    cudaFree(x); cudaFreeHost(y); cudaFree(d_x); cudaFree(d_y);
    cudaStreamDestroy(stream);
    return maxError > kEps ? EXIT_FAILURE : EXIT_SUCCESS;
}

// ── Further constructs ──
#if defined(__CUDA_ARCH__)
#  if __CUDA_ARCH__ >= 900
#    define ARCH_NAME "hopper"
#  elif __CUDA_ARCH__ >= 800
#    define ARCH_NAME "ampere"
#  else
#    define ARCH_NAME "legacy"
#  endif
#endif
#pragma unroll 4
#pragma nv_diag_suppress 177

#include <cuda_pipeline.h>
#include <mma.h>
#include <curand_kernel.h>
#include <cublas_v2.h>
#include <cuda/std/atomic>
#include <cuda/barrier>
#include <cuda_bf16.h>
#include <cuda_fp8.h>
using namespace nvcuda;

__device__ __constant__ unsigned char lut[256];
__device__ __managed__ float managed_buffer[1024];
__device__ __grid_constant__ const int grid_const = 3;
__device__ void device_only() {}
__host__ void host_only() {}
__global__ void __cluster_dims__(2, 1, 1) clustered() {}
__global__ void __maxnreg__(64) regs() {}
__global__ void __launch_bounds__(512, 2, 4) bounded() {}

__global__ void random_fill(curandState* states, float* out, unsigned long long seed) {
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    curand_init(seed, i, 0, &states[i]);
    out[i] = curand_uniform(&states[i]) + curand_normal(&states[i]);
}

__global__ void tensor_core(const half* a, const half* b, float* c) {
    wmma::fragment<wmma::matrix_a, 16, 16, 16, half, wmma::row_major> fa;
    wmma::fragment<wmma::matrix_b, 16, 16, 16, half, wmma::col_major> fb;
    wmma::fragment<wmma::accumulator, 16, 16, 16, float> acc;
    wmma::fill_fragment(acc, 0.0f);
    wmma::load_matrix_sync(fa, a, 16);
    wmma::load_matrix_sync(fb, b, 16);
    wmma::mma_sync(acc, fa, fb, acc);
    wmma::store_matrix_sync(c, acc, 16, wmma::mem_row_major);
}

__global__ void half_ops(__half* h, __nv_bfloat16* bf, float* out) {
    __half two = __float2half(2.0f);
    h[threadIdx.x] = __hadd(h[threadIdx.x], two);
    h[threadIdx.x] = __hmul(__ldg(&h[threadIdx.x]), two);
    __half2 pair = __halves2half2(two, two);
    out[0] = __half2float(__low2half(pair)) + __bfloat162float(bf[0]);
    float v = __int_as_float(0x3f800000) + __uint_as_float(1u) + __float_as_int(1.0f);
    out[1] = __fdividef(v, 3.0f) + __saturatef(v) + fmaf(v, v, v) + __powf(v, 2.0f) + __logf(v) + __cosf(v);
    out[2] = __ldg(out) + __ldcs(out) + __ldlu(out);
    __stcs(out, v); __stwb(out, v);
    long long t = clock64(); long long t2 = clock();
    unsigned lane = 0; asm volatile("mov.u32 %0, %%laneid;" : "=r"(lane));
    unsigned smid; asm("mov.u32 %0, %%smid;" : "=r"(smid));
    printf("lane %u sm %u t %lld %lld\n", lane, smid, t, t2);
    assert(lane < 32);
    __trap();
    __brkpt();
    __prof_trigger(0);
}

__global__ void dyn_parallel(int depth) {
    if (depth > 0) {
        dyn_parallel<<<1, 1, 0, cudaStreamTailLaunch>>>(depth - 1);
        cudaDeviceSynchronize();
    }
}

__global__ void async_copy(const float* __restrict__ src, float* dst) {
    extern __shared__ __align__(16) char smem[];
    float* tile = reinterpret_cast<float*>(smem);
    __pipeline_memcpy_async(&tile[threadIdx.x], &src[threadIdx.x], sizeof(float));
    __pipeline_commit();
    __pipeline_wait_prior(0);
    cuda::barrier<cuda::thread_scope_block> bar;
    cuda::memcpy_async(tile, src, sizeof(float), bar);
    dst[threadIdx.x] = tile[threadIdx.x];
}

template <typename T>
__global__ void templated_kernel(T* data, int n) {
    for (int i = blockIdx.x * blockDim.x + threadIdx.x; i < n; i += blockDim.x * gridDim.x)
        data[i] = static_cast<T>(i);
}

void host_extras() {
    cudaGraph_t graph; cudaGraphExec_t exec; cudaStream_t s;
    cudaStreamBeginCapture(s, cudaStreamCaptureModeGlobal);
    templated_kernel<float><<<dim3(4, 2, 1), dim3(128), 0, s>>>(nullptr, 0);
    cudaStreamEndCapture(s, &graph);
    cudaGraphInstantiate(&exec, graph, nullptr, nullptr, 0);
    cudaGraphLaunch(exec, s);
    cudaFuncSetAttribute(async_copy, cudaFuncAttributeMaxDynamicSharedMemorySize, 49152);
    cudaMemLocation loc{};
    loc.type = cudaMemLocationTypeDevice;
    loc.id = 0;
    cudaMemPrefetchAsync(managed_buffer, 4096, loc, 0, s);
    cudaMemAdvise(managed_buffer, 4096, cudaMemAdviseSetReadMostly, loc);
    cublasHandle_t handle; cublasCreate(&handle);
    const float alpha = 1.0f, beta = 0.0f;
    cublasSgemm(handle, CUBLAS_OP_N, CUBLAS_OP_T, 4, 4, 4, &alpha, nullptr, 4, nullptr, 4, &beta, nullptr, 4);
    cudaError_t e = cudaPeekAtLastError();
    if (e != cudaSuccess) fprintf(stderr, "%s\n", cudaGetErrorName(e));
    int dev; cudaGetDevice(&dev); cudaSetDevice(dev);
    int attr; cudaDeviceGetAttribute(&attr, cudaDevAttrMultiProcessorCount, dev);
    cudaOccupancyMaxPotentialBlockSize(&attr, &attr, templated_kernel<float>, 0, 0);
    cudaHostRegister(nullptr, 0, cudaHostRegisterDefault);
    cudaMemset(nullptr, 0, 0); cudaMemsetAsync(nullptr, 0, 0, s);
    cudaMallocAsync(nullptr, 0, s); cudaFreeAsync(nullptr, s);
    cudaDeviceReset();
}

// ── CUDA 12 / 13 additions ──
#include <cuda/std/span>
#include <cuda/std/array>
#include <cuda/std/cstdint>
#include <cuda/pipeline>
#include <cuda/atomic>
#include <thrust/transform.h>
#include <thrust/sort.h>
#include <thrust/functional.h>
#include <thrust/execution_policy.h>

// Kernel parameters passed by const reference through constant memory
struct Params { float scale; int count; };
__global__ void grid_const_param(const __grid_constant__ Params p, float* out) {
    out[threadIdx.x] = p.scale * static_cast<float>(p.count);
}

// Thread block clusters (sm_90+)
namespace cgc = cooperative_groups;
__global__ void __cluster_dims__(2, 1, 1) cluster_kernel(float* data) {
    cgc::cluster_group cluster = cgc::this_cluster();
    __shared__ float local[128];
    local[threadIdx.x] = static_cast<float>(cluster.block_rank());
    cluster.sync();
    float* remote = cluster.map_shared_rank(local, (cluster.block_rank() + 1) % cluster.num_blocks());
    data[threadIdx.x] = remote[threadIdx.x];
    cluster.sync();
}

// Warp-level reductions and misc intrinsics (sm_80+)
__global__ void warp_intrinsics(unsigned* out, const unsigned* in) {
    unsigned v = in[threadIdx.x];
    unsigned active = __activemask();
    unsigned sum = __reduce_add_sync(active, v);
    unsigned mn = __reduce_min_sync(active, v);
    unsigned any_match = __match_any_sync(active, v);
    unsigned packed = __byte_perm(v, v, 0x3210) + __funnelshift_l(v, v, 3) + __brev(v) + __popc(v);
    int dot = __dp4a(static_cast<int>(v), static_cast<int>(v), 0);
    __nanosleep(100);
    atomicAdd_block(&out[1], 1u);
    atomicOr(&out[2], v); atomicAnd(&out[3], v); atomicXor(&out[4], v); atomicExch(&out[5], v);
    atomicMin(&out[6], v); atomicInc(&out[7], 16u); atomicDec(&out[8], 16u);
    out[0] = sum + mn + any_match + packed + dot;
}

// C++20 in device code: concepts, constexpr, templates, structured bindings
template <typename T>
concept Numeric = requires(T a, T b) { a + b; a * b; };

template <Numeric T>
__host__ __device__ constexpr T fused(T a, T b, T c) { return a * b + c; }

__device__ constexpr int kDeviceConst = 42;
__host__ __device__ constexpr float half_of(float x) noexcept { return x * 0.5f; }

template <typename T, int N>
struct alignas(16) Vec {
    T v[N];
    __host__ __device__ T& operator[](int i) { return v[i]; }
    __host__ __device__ const T& operator[](int i) const { return v[i]; }
    __host__ __device__ auto operator<=>(const Vec&) const = default;
};

__global__ void structured(float* out, Vec<float, 4> vec) {
    auto [a, b] = cuda::std::pair<float, float>{vec[0], vec[1]};
    if constexpr (sizeof(float) == 4) out[threadIdx.x] = a + b;
    else out[threadIdx.x] = 0.0f;
}

// Low-precision types (FP8 / BF16 / FP16, sm_89+)
__global__ void fp8_ops(__nv_fp8_e4m3* in, __nv_fp8_e5m2* in2, __nv_bfloat162* pairs, float* out) {
    __nv_fp8_e4m3 q = __nv_fp8_e4m3(1.5f);
    out[0] = static_cast<float>(q) + static_cast<float>(in[threadIdx.x]) + static_cast<float>(in2[0]);
    __nv_bfloat162 two = __floats2bfloat162_rn(1.0f, 2.0f);
    pairs[threadIdx.x] = __hadd2(two, pairs[threadIdx.x]);
}

// Extended lambdas (nvcc --extended-lambda) and Thrust
void thrust_lambdas() {
    thrust::device_vector<float> d(1024, 1.0f);
    thrust::transform(thrust::device, d.begin(), d.end(), d.begin(),
                      [] __device__ (float x) { return x * 2.0f; });
    thrust::sort(thrust::device, d.begin(), d.end(), thrust::greater<float>());
    auto doubler = [=] __host__ __device__ (int i) mutable { return i * 2; };
    (void)doubler;
}

template <typename F>
__global__ void apply_kernel(F f, int n) {
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i < n) f(i);
}

// Launch with attributes (cudaLaunchKernelEx) and stream-ordered allocation
void launch_ex(cudaStream_t stream) {
    cudaLaunchConfig_t cfg = {};
    cfg.gridDim = dim3(8, 1, 1);
    cfg.blockDim = dim3(128, 1, 1);
    cfg.dynamicSmemBytes = 0;
    cfg.stream = stream;
    cudaLaunchAttribute attrs[1];
    attrs[0].id = cudaLaunchAttributeClusterDimension;
    attrs[0].val.clusterDim.x = 2;
    attrs[0].val.clusterDim.y = 1;
    attrs[0].val.clusterDim.z = 1;
    cfg.attrs = attrs;
    cfg.numAttrs = 1;
    float* buf = nullptr;
    cudaMallocAsync(reinterpret_cast<void**>(&buf), 1024 * sizeof(float), stream);
    cudaLaunchKernelEx(&cfg, cluster_kernel, buf);
    cudaFreeAsync(buf, stream);
    cudaMemPool_t pool;
    cudaDeviceGetDefaultMemPool(&pool, 0);
    uint64_t threshold = UINT64_MAX;
    cudaMemPoolSetAttribute(pool, cudaMemPoolAttrReleaseThreshold, &threshold);
}

// libcu++ atomics and span
__global__ void libcudacxx(cuda::std::span<int> items, cuda::atomic<int, cuda::thread_scope_device>* counter) {
    if (threadIdx.x < items.size()) {
        items[threadIdx.x] += 1;
        counter->fetch_add(1, cuda::std::memory_order_relaxed);
    }
}

// Unrolling / pragma forms and inline PTX
__global__ void pragmas(float* a) {
    #pragma unroll
    for (int i = 0; i < 4; ++i) a[i] += 1.0f;
    #pragma unroll 2
    for (int i = 0; i < 4; ++i) a[i] += 1.0f;
    #pragma nounroll
    for (int i = 0; i < 4; ++i) a[i] += 1.0f;
    unsigned r;
    asm volatile("{ .reg .u32 t; mov.u32 t, %%tid.x; add.u32 %0, t, 1; }" : "=r"(r) :: "memory");
    a[0] = static_cast<float>(r);
}
