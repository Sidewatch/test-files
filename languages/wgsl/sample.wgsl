// WGSL (W3C Candidate Recommendation, 2025) — syntax showcase
// ── Comments ───────────────────────────────────────────────
// WGSL: warehouse heat-map rendering and a stock compute kernel.
// TODO: add shadow maps. FIXME: premultiplied alpha.
/* Block comment
   /* nested block comments are allowed in WGSL */
   still inside */

// ── Directives ─────────────────────────────────────────────
enable f16;
enable subgroups;
enable primitive_index;
enable clip_distances;
enable dual_source_blending;
requires readonly_and_readwrite_storage_textures;
diagnostic(off, derivative_uniformity);

// ── Constants and overrides ────────────────────────────────
const PI: f32 = 3.14159265;
const TAU = PI * 2.0;
const WORKGROUP: u32 = 64u;
const MASK: u32 = 0xFFu;
const BIG: i32 = 1000000;
const HEX_FLOAT = 0x1.8p3;
const SMALL = 1e-3;
const SHORT: f16 = 1.5h;
const FLOAT_SUFFIX = 2.5f;
const NEG = -42i;
const TRUTH: bool = true;
const FALSEHOOD = false;
const ZERO = vec3<f32>(0.0);
const LIMITS = array<u32, 3>(1u, 2u, 3u);
override reorder_point: u32 = 25u;
@id(1) override gain: f32 = 1.0;
alias Color = vec4<f32>;
alias Index = u32;

// ── Structs ────────────────────────────────────────────────
struct Uniforms {
    mvp: mat4x4<f32>,
    time: f32,
    @align(16) tint: vec3<f32>,
    @size(16) pad: f32,
};

struct Light {
    position: vec3<f32>,
    @location(0) color: vec3<f32>,
    intensity: f32,
}

struct VSOut {
    @builtin(position) pos: vec4<f32>,
    @location(0) uv: vec2<f32>,
    @location(1) @interpolate(flat) bin: u32,
    @location(2) @interpolate(linear, centroid) heat: f32,
    @location(3) @invariant normal: vec3<f32>,
};

struct Item {
    qty: atomic<u32>,
    price: f32,
    tags: array<u32, 4>,
}

// ── Bindings ───────────────────────────────────────────────
@group(0) @binding(0) var<uniform> u: Uniforms;
@group(0) @binding(1) var albedo: texture_2d<f32>;
@group(0) @binding(2) var albedo_sampler: sampler;
@group(0) @binding(3) var shadow: texture_depth_2d;
@group(0) @binding(4) var shadow_sampler: sampler_comparison;
@group(0) @binding(5) var cube: texture_cube<f32>;
@group(0) @binding(6) var multisampled: texture_multisampled_2d<f32>;
@group(0) @binding(7) var storage_tex: texture_storage_2d<rgba8unorm, write>;
@group(0) @binding(8) var arr_tex: texture_2d_array<f32>;
@group(0) @binding(9) var vol: texture_3d<f32>;
@group(1) @binding(0) var<storage, read_write> data: array<f32>;
@group(1) @binding(1) var<storage, read> items: array<Item>;
@group(1) @binding(2) var<storage> counts: array<atomic<u32>, 8>;
var<private> seed: u32 = 12345u;
var<workgroup> tile: array<f32, 64>;
var<workgroup> shared_count: atomic<u32>;

// ── Functions ──────────────────────────────────────────────
fn hash(x: u32) -> u32 {
    var h = x;
    h ^= h >> 16u;
    h *= 0x7feb352du;
    h ^= h >> 15u;
    h *= 0x846ca68bu;
    h ^= h >> 16u;
    return h;
}

fn saturate_color(c: vec3<f32>) -> vec3<f32> {
    return clamp(c, vec3<f32>(0.0), vec3<f32>(1.0));
}

fn heat_ramp(t: f32) -> vec3<f32> {
    let cold = vec3(0.0, 0.2, 1.0);
    let hot = vec3f(1.0, 0.1, 0.0);
    return mix(cold, hot, smoothstep(0.0, 1.0, t));
}

fn lerp_all(a: f32, b: f32, t: f32) -> f32 {
    return a + (b - a) * t;
}

fn ops_demo(a: i32, b: i32) -> i32 {
    var r = a + b - a * b / 2 % 7;
    r += 1; r -= 1; r *= 2; r /= 2; r %= 5;
    r <<= 1u; r >>= 1u; r &= 0xF; r |= 1; r ^= 2;
    r++;
    r--;
    let bits = ~a & b | a ^ b << 1u >> 1u;
    let logic = !(a > b) && (a < b) || (a >= b) || (a <= b) || (a == b) || (a != b);
    let short_and = (a > 0) & (b > 0);
    let short_or = (a > 0) | (b > 0);
    let casted = f32(a) + f32(b) + bitcast<f32>(1u);
    let sw = select(0, 1, logic);
    _ = bits;
    _ = short_and;
    _ = short_or;
    _ = casted;
    return r + sw;
}

fn vectors_demo(v: vec4<f32>) -> f32 {
    let xy = v.xy;
    let swizzled = v.wzyx;
    let rgb = v.rgb;
    let m = mat3x3<f32>(1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0);
    let mv = m * v.xyz;
    let c = cross(v.xyz, vec3f(0.0, 1.0, 0.0));
    let d = dot(v, v) + length(v) + distance(v, v) + determinant(m);
    let n = normalize(v.xyz) + reflect(v.xyz, c) + refract(v.xyz, c, 1.5);
    let t = transpose(m) * mv;
    let s = sin(d) + cos(d) + tan(d) + atan2(d, 1.0) + sqrt(d) + pow(d, 2.0) + exp(d) + log(d) + abs(d) + floor(d) + ceil(d) + fract(d) + sign(d) + step(0.5, d) + min(d, 1.0) + max(d, 0.0);
    let pk = pack4x8unorm(v) + pack2x16float(xy);
    let uv = unpack4x8unorm(pk);
    let b = countOneBits(pk) + reverseBits(pk) + firstLeadingBit(pk) + extractBits(pk, 0u, 8u);
    let bb = any(vec3<bool>(true, false, true)) && all(vec2<bool>(true, true));
    let idx = v[0] + m[1][2];
    return s + f32(b) + select(0.0, 1.0, bb) + idx + n.x + t.x + uv.x;
}

// ── Stages ─────────────────────────────────────────────────
@vertex
fn vs_main(
    @location(0) position: vec3<f32>,
    @location(1) uv: vec2<f32>,
    @builtin(vertex_index) vi: u32,
    @builtin(instance_index) ii: u32,
) -> VSOut {
    var out: VSOut;
    out.pos = u.mvp * vec4<f32>(position, 1.0);
    out.uv = uv + vec2<f32>(0.0, sin(u.time) * 0.01);
    out.bin = hash(vi + ii) % 8u;
    out.heat = f32(out.bin) / 8.0;
    out.normal = vec3(0.0, 0.0, 1.0);
    return out;
}

@fragment
fn fs_main(
    in: VSOut,
    @builtin(front_facing) front: bool,
    @builtin(sample_index) si: u32,
    @builtin(position) frag: vec4<f32>,
) -> @location(0) vec4<f32> {
    let base = textureSample(albedo, albedo_sampler, in.uv).rgb;
    let dims = textureDimensions(albedo);
    let texel = textureLoad(albedo, vec2<i32>(in.uv * vec2<f32>(dims)), 0);
    let depth = textureSampleCompare(shadow, shadow_sampler, in.uv, 0.5);
    let lod = textureSampleLevel(albedo, albedo_sampler, in.uv, 0.0);
    let shade = mix(0.6, 1.0, in.uv.y);
    var color = vec3<f32>(base * shade) * heat_ramp(in.heat);
    if (!front) {
        discard;
    } else if (depth < 0.1) {
        color *= 0.5;
    } else {
        color += texel.rgb * 0.0 + lod.rgb * 0.0;
    }
    let dx = dpdx(in.uv.x) + dpdy(in.uv.y) + fwidth(in.uv.x);
    return vec4<f32>(color + dx * 0.0, 1.0);
}

@fragment
fn fs_depth(@builtin(position) pos: vec4<f32>) -> @builtin(frag_depth) f32 {
    return pos.z;
}

@compute @workgroup_size(64)
fn scale(@builtin(global_invocation_id) id: vec3<u32>) {
    if (id.x < arrayLength(&data)) { data[id.x] = data[id.x] * 2.0; }
}

@compute @workgroup_size(8, 8, 1)
fn reduce(
    @builtin(local_invocation_id) lid: vec3<u32>,
    @builtin(local_invocation_index) li: u32,
    @builtin(workgroup_id) wid: vec3<u32>,
    @builtin(num_workgroups) nwg: vec3<u32>,
) {
    tile[li] = data[wid.x * 64u + li];
    workgroupBarrier();
    var stride = 32u;
    loop {
        if (stride == 0u) { break; }
        if (li < stride) { tile[li] += tile[li + stride]; }
        workgroupBarrier();
        continuing {
            stride = stride >> 1u;
            break if stride == 0u;
        }
    }
    if (li == 0u) {
        atomicAdd(&shared_count, 1u);
        atomicStore(&counts[0], 1u);
        let old = atomicLoad(&counts[0]);
        let swapped = atomicCompareExchangeWeak(&counts[0], old, 2u);
        _ = swapped.exchanged;
    }
    storageBarrier();
    textureStore(storage_tex, vec2<i32>(lid.xy), vec4<f32>(tile[0]));
}

// ── Control flow ───────────────────────────────────────────
fn flow(n: u32) -> u32 {
    var total = 0u;
    for (var i = 0u; i < n; i++) {
        if (i == 3u) { continue; }
        total += i;
    }
    var j = 0u;
    while (j < n) { j += 1u; }
    switch (n) {
        case 0u, 1u: { total = 1u; }
        case 2u: { total = 2u; }
        case default: { total = 3u; }
    }
    switch n {
        default { total += 1u; }
    }
    return total;
}

// ── Pointers, atomics, const assertions ────────────────────
const_assert WORKGROUP > 0u;
const_assert (PI > 3.0) && (TAU < 7.0);

fn increment(p: ptr<function, i32>) {
    *p = *p + 1;
    (*p) += 2;
}

fn ptr_params(a: ptr<private, u32>, b: ptr<workgroup, f32>, c: ptr<storage, array<f32>, read_write>, d: ptr<uniform, Uniforms>) {
    let v = *a;
    let first = (*c)[0];
    let t = (*d).time;
    _ = v;
    _ = first;
    _ = t;
}

@must_use
fn pure_value(x: f32) -> f32 { return x * 2.0; }

@diagnostic(warning, derivative_uniformity)
fn with_diagnostic() {}

fn local_vars() {
    var counter: i32 = 0;
    var<function> explicit_function: f32 = 1.0;
    let immutable = 5;
    const constant_local = 10u;
    increment(&counter);
    let copy = counter;
    var arr = array<vec2<f32>, 4>(vec2(0.0), vec2(1.0), vec2(2.0), vec2(3.0));
    arr[2].x = 5.0;
    let len = arrayLength(&data);
    _ = explicit_function;
    _ = immutable;
    _ = constant_local;
    _ = copy;
    _ = len;
}

// ── Scalar, vector and matrix type spellings ───────────────
struct AllTypes {
    a: bool,
    b: i32,
    c: u32,
    d: f32,
    e: f16,
    v2: vec2<f32>, v3: vec3<i32>, v4: vec4<u32>, vb: vec2<bool>, vh: vec3<f16>,
    v2f: vec2f, v3i: vec3i, v4u: vec4u, v2h: vec2h,
    m22: mat2x2<f32>, m23: mat2x3<f32>, m24: mat2x4<f32>,
    m32: mat3x2<f32>, m33: mat3x3<f32>, m34: mat3x4<f32>,
    m42: mat4x2<f32>, m43: mat4x3<f32>, m44: mat4x4<f32>,
    m22f: mat2x2f, m44f: mat4x4f, m33h: mat3x3h,
    arr: array<f32, 8>,
    nested: array<array<vec3<f32>, 2>, 2>,
    at: atomic<i32>,
}

// ── Texture and sampler types ──────────────────────────────
@group(2) @binding(0) var t1d: texture_1d<f32>;
@group(2) @binding(1) var t2d_array: texture_2d_array<i32>;
@group(2) @binding(2) var t3d: texture_3d<u32>;
@group(2) @binding(3) var tcube_array: texture_cube_array<f32>;
@group(2) @binding(4) var tms: texture_multisampled_2d<f32>;
@group(2) @binding(5) var tdms: texture_depth_multisampled_2d;
@group(2) @binding(6) var tdepth_arr: texture_depth_2d_array;
@group(2) @binding(7) var tdepth_cube: texture_depth_cube;
@group(2) @binding(8) var tdepth_cube_arr: texture_depth_cube_array;
@group(2) @binding(9) var text: texture_external;
@group(2) @binding(10) var st1: texture_storage_1d<r32float, read_write>;
@group(2) @binding(11) var st2: texture_storage_2d<rgba16float, read>;
@group(2) @binding(12) var st2a: texture_storage_2d_array<bgra8unorm, write>;
@group(2) @binding(13) var st3: texture_storage_3d<rgba32uint, write>;
@group(2) @binding(14) var smp: sampler;
@group(2) @binding(15) var smp_cmp: sampler_comparison;

fn texture_funcs(uv: vec2<f32>) -> vec4<f32> {
    let a = textureSampleBias(albedo, albedo_sampler, uv, 0.5);
    let b = textureSampleGrad(albedo, albedo_sampler, uv, vec2(0.1), vec2(0.1));
    let c = textureSampleBaseClampToEdge(text, smp, uv);
    let d = textureGather(0, albedo, albedo_sampler, uv);
    let e = textureGatherCompare(shadow, shadow_sampler, uv, 0.5);
    let f = textureSampleCompareLevel(shadow, shadow_sampler, uv, 0.5);
    let g = textureNumLayers(arr_tex) + textureNumLevels(albedo) + textureNumSamples(multisampled);
    let h = textureLoad(multisampled, vec2<i32>(0), 0);
    let i = textureSampleLevel(arr_tex, albedo_sampler, uv, 1, 0.0);
    textureStore(storage_tex, vec2<i32>(0), vec4<f32>(1.0));
    return a + b + c + d + f32(g) + h + i + vec4(e);
}

// ── Remaining builtins and attributes ──────────────────────
struct FragIn {
    @builtin(position) frag_pos: vec4<f32>,
    @builtin(front_facing) front: bool,
    @builtin(sample_index) sample_idx: u32,
    @builtin(sample_mask) mask: u32,
    @location(0) @interpolate(perspective) p: f32,
    @location(1) @interpolate(perspective, sample) ps: f32,
    @location(2) @interpolate(linear, center) lc: f32,
    @location(3) @interpolate(flat, first) ff: u32,
}

struct FragOut {
    @location(0) @blend_src(0) color: vec4<f32>,
    @location(0) @blend_src(1) blend: vec4<f32>,
    @builtin(frag_depth) depth: f32,
    @builtin(sample_mask) mask: u32,
}

override block_size: u32 = 8u;

@compute @workgroup_size(block_size, 4, 1)
fn overridden(
    @builtin(subgroup_invocation_id) sg_id: u32,
    @builtin(subgroup_size) sg_size: u32,
) {
    let s = subgroupAdd(1u) + subgroupMax(1u) + subgroupBallot(true).x + subgroupBroadcast(1u, 0u);
    let q = quadSwapX(1.0) + quadBroadcast(1.0, 0u);
    workgroupUniformLoad(&tile[0]);
    _ = s;
    _ = q;
}

fn math_builtins(x: f32, v: vec3<f32>, i: i32, u: u32) {
    let a = abs(x) + acos(0.5) + acosh(2.0) + asin(0.5) + asinh(1.0) + atan(x) + atanh(0.5) + atan2(x, 1.0);
    let b = ceil(x) + clamp(x, 0.0, 1.0) + cos(x) + cosh(x) + degrees(x) + exp(x) + exp2(x) + floor(x) + fma(x, x, x) + fract(x);
    let c = inverseSqrt(x) + log(x) + log2(x) + max(x, 1.0) + min(x, 1.0) + mix(x, 1.0, 0.5) + pow(x, 2.0) + radians(x) + round(x);
    let d = saturate(x) + sign(x) + sin(x) + sinh(x) + smoothstep(0.0, 1.0, x) + sqrt(x) + step(0.5, x) + tan(x) + tanh(x) + trunc(x);
    let e = faceForward(v, v, v) + normalize(v) + reflect(v, v) + refract(v, v, 1.0) + cross(v, v);
    let f = length(v) + distance(v, v) + dot(v, v);
    let g = countLeadingZeros(u) + countTrailingZeros(u) + countOneBits(u) + firstLeadingBit(u) + firstTrailingBit(u) + insertBits(u, u, 0u, 4u) + extractBits(u, 0u, 4u) + reverseBits(u);
    let h = dot4I8Packed(u, u) + dot4U8Packed(u, u);
    let j = pack4x8snorm(vec4(0.0)) + pack4xI8(vec4(0)) + pack2x16snorm(vec2(0.0)) + pack4xU8Clamp(vec4(0u));
    let k = unpack2x16unorm(u) + unpack4x8snorm(u).xy + unpack2x16snorm(u);
    let l = modf(x).fract + frexp(x).exp + ldexp(x, 2) + dpdxCoarse(x) + dpdxFine(x) + dpdyCoarse(x) + dpdyFine(x);
    let m = transpose(mat2x2<f32>(1.0, 0.0, 0.0, 1.0));
    let n = all(vec2<bool>(true)) && any(vec2<bool>(false)) && select(true, false, x > 0.0);
    let o = arrayLength(&data) + u;
    let p = bitcast<i32>(u) + bitcast<i32>(f32(i));
}

// ── Additions: literals, extensions and remaining forms ────
const L_INT = 0x1Fi + 07 * 1i;
const L_UINT = 0xFFu + 10u;
const L_FLOAT = 1.0e5 + .5 + 5. + 1f + 0x1p-2 + 0x.8p1 + 1e2f;
const L_HALF = 1h + 2.5h + 0x1p3h;
const L_ABSTRACT = 1 + 0x10 + 1.5 + 2e3;

struct ClipOut {
    @builtin(position) pos: vec4<f32>,
    @builtin(clip_distances) clip: array<f32, 2>,
}

@fragment
fn fs_prim(@builtin(primitive_index) prim: u32, @builtin(position) p: vec4<f32>) -> @location(0) vec4<f32> {
    return vec4<f32>(f32(prim), p.xyz);
}

fn loops_forms() {
    var i = 0;
    for (;;) { break; }
    for (var k = 0; k < 4; k += 1) { }
    for (; i < 2; ) { i++; }
    loop { i += 1; if i > 3 { break; } }
    if i > 0 { i = 1; } else if i < 0 { i = -1; } else { i = 0; }
    switch i {
        case 1, 2, default { i = 3; }
    }
    let t = (i > 0) && !(i < 0);
    _ = t;
    {
        let inner = 1;
        _ = inner;
    }
    return;
}

fn ref_forms(p: ptr<function, array<i32, 4>>) -> i32 {
    (*p)[0] = 1;
    let q = &(*p)[1];
    *q = 2;
    return (*p)[0] + *q;
}
