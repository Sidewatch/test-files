// Metal: a vertex/fragment pair drawing a gradient-lit quad.
#include <metal_stdlib>
using namespace metal;

struct VertexIn {
    float3 position [[attribute(0)]];
    float2 uv       [[attribute(1)]];
};

struct VertexOut {
    float4 position [[position]];
    float2 uv;
};

struct Uniforms {
    float4x4 mvp;
    float    time;
};

vertex VertexOut vertex_main(VertexIn in [[stage_in]],
                             constant Uniforms& u [[buffer(1)]]) {
    VertexOut out;
    out.position = u.mvp * float4(in.position, 1.0);
    out.uv = in.uv + float2(0.0, sin(u.time) * 0.01);
    return out;
}

fragment float4 fragment_main(VertexOut in [[stage_in]],
                              texture2d<float> albedo [[texture(0)]],
                              sampler s [[sampler(0)]]) {
    float3 base = albedo.sample(s, in.uv).rgb;
    float shade = mix(0.6, 1.0, in.uv.y);
    return float4(base * shade, 1.0);
}
