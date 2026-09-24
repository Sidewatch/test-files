// CUDA: SAXPY on the device, checked on the host.
#include <cstdio>
#include <cuda_runtime.h>

__global__ void saxpy(int n, float a, const float* __restrict__ x, float* __restrict__ y) {
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i < n) y[i] = a * x[i] + y[i];
}

int main() {
    const int n = 1 << 20;
    float *x, *y;
    cudaMallocManaged(&x, n * sizeof(float));
    cudaMallocManaged(&y, n * sizeof(float));
    for (int i = 0; i < n; ++i) { x[i] = 1.0f; y[i] = 2.0f; }

    dim3 block(256), grid((n + block.x - 1) / block.x);
    saxpy<<<grid, block>>>(n, 2.0f, x, y);
    cudaDeviceSynchronize();

    float maxError = 0.0f;
    for (int i = 0; i < n; ++i) maxError = fmaxf(maxError, fabsf(y[i] - 4.0f));
    printf("max error: %f\n", maxError);
    cudaFree(x); cudaFree(y);
    return 0;
}
