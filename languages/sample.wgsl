// WGSL: a vertex/fragment pair and a compute kernel.
struct Uniforms {
    mvp: mat4x4<f32>,
    time: f32,
};
@group(0) @binding(0) var<uniform> u: Uniforms;
@group(0) @binding(1) var albedo: texture_2d<f32>;
@group(0) @binding(2) var albedo_sampler: sampler;

struct VSOut {
    @builtin(position) pos: vec4<f32>,
    @location(0) uv: vec2<f32>,
};

@vertex
fn vs_main(@location(0) position: vec3<f32>, @location(1) uv: vec2<f32>) -> VSOut {
    var out: VSOut;
    out.pos = u.mvp * vec4<f32>(position, 1.0);
    out.uv = uv + vec2<f32>(0.0, sin(u.time) * 0.01);
    return out;
}

@fragment
fn fs_main(in: VSOut) -> @location(0) vec4<f32> {
    let base = textureSample(albedo, albedo_sampler, in.uv).rgb;
    let shade = mix(0.6, 1.0, in.uv.y);
    return vec4<f32>(base * shade, 1.0);
}

@group(1) @binding(0) var<storage, read_write> data: array<f32>;

@compute @workgroup_size(64)
fn scale(@builtin(global_invocation_id) id: vec3<u32>) {
    if (id.x < arrayLength(&data)) { data[id.x] = data[id.x] * 2.0; }
}
