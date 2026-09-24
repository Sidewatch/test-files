// OpenCL: a vector add and a reduction kernel.
#pragma OPENCL EXTENSION cl_khr_fp64 : enable

__constant float SCALE = 2.0f;

__kernel void vadd(__global const float* a,
                   __global const float* b,
                   __global float* out,
                   const unsigned int n)
{
    size_t i = get_global_id(0);
    if (i < n) out[i] = SCALE * a[i] + b[i];
}

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
