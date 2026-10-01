#version 450 core
#extension GL_ARB_separate_shader_objects : enable
#extension GL_EXT_scalar_block_layout : require
#pragma optimize(on)
#pragma debug(off)

// ── Comments ──
// Fragment shader: a Phong-lit, normal-mapped surface with shadows and rim light.
/* Block comment
   spanning lines. TODO: add clustered lighting. FIXME: banding in the rim term. */

// ── Preprocessor ──
#define PI 3.14159265358979
#define TWO_PI (2.0 * PI)
#define MAX_LIGHTS 8
#define SQR(x) ((x) * (x))
#define SATURATE(x) clamp((x), 0.0, 1.0)
#define USE_SHADOWS
#define STR(x) #x
#define CAT(a, b) a##b
#ifndef EPSILON
#define EPSILON 1e-5
#endif
#if defined(USE_SHADOWS) && MAX_LIGHTS > 4
#define SHADOW_SAMPLES 16
#elif defined(LOW_QUALITY)
#define SHADOW_SAMPLES 4
#else
#define SHADOW_SAMPLES 8
#endif
#ifdef GL_ES
precision highp float;
precision mediump int;
precision lowp sampler2D;
#endif
#line 100
#undef LOW_QUALITY

// ── Layout qualifiers, in/out/uniform/buffer ──
layout(location = 0) in vec3 vNormal;
layout(location = 1) in vec3 vWorldPos;
layout(location = 2) in vec2 vUV;
layout(location = 3) in vec4 vTangent;
layout(location = 4) flat in int vMaterialId;
layout(location = 5) smooth in float vDepth;
layout(location = 6) noperspective in vec2 vScreen;
layout(location = 0) out vec4 fragColor;
layout(location = 1) out vec4 fragNormal;
layout(early_fragment_tests) in;
layout(depth_less) out float gl_FragDepth;

layout(std140, binding = 0) uniform Camera {
    mat4 view;
    mat4 projection;
    vec3 position;
    float exposure;
} camera;

layout(std430, binding = 1) readonly buffer Lights {
    int count;
    vec4 positions[MAX_LIGHTS];
    vec4 colors[];
} lights;

layout(binding = 2) uniform sampler2D uAlbedo;
layout(binding = 3) uniform sampler2D uNormalMap;
layout(binding = 4) uniform samplerCube uEnvironment;
layout(binding = 5) uniform sampler2DShadow uShadowMap;
layout(binding = 6) uniform sampler2DArray uAtlas;
layout(binding = 7) uniform isampler2D uIds;
layout(binding = 8) uniform usampler3D uVolume;
layout(rgba32f, binding = 0) uniform restrict writeonly image2D uOutput;
layout(binding = 0, offset = 0) uniform atomic_uint uCounter;
layout(push_constant) uniform Push { mat4 model; } push;
layout(constant_id = 0) const int kQuality = 2;
layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

uniform vec3 uLightPos = vec3(4.0, 6.0, 3.0);
uniform vec3 uBaseColor = vec3(0.8, 0.35, 0.2);
uniform float uShininess = 32.0;
uniform bool uUseNormalMap;
uniform highp mat3 uNormalMatrix;
uniform vec4 uTint[3];

// ── Constants and literals ──
const float kGamma = 2.2;
const int kSteps = 0x10;
const uint kMask = 0xFFu;
const uint kOctal = 0755u;
const int kNegative = -42;
const float kExp = 1.5e-3;
const double kDouble = 3.14159265358979lf;
const float kFloatSuffix = 2.5f;
const float kLeadingDot = .5;
const float kTrailingDot = 5.;
const bool kEnabled = true;
const bool kDisabled = false;

// ── Structs ──
struct Material {
    vec3 albedo;
    float roughness;
    float metallic;
    bool emissive;
};

struct Light {
    vec3 position;
    vec3 color;
    float intensity;
};

// ── Interface blocks ──
in VertexData {
    vec3 normal;
    vec2 uv;
} fromVertex;

// ── Functions: parameter qualifiers, overloads, recursion-free helpers ──
float rim(vec3 n, vec3 v) {
    return pow(1.0 - max(dot(n, v), 0.0), 3.0);
}

float rim(in vec3 n, in vec3 v, const in float power) {
    return pow(1.0 - max(dot(n, v), 0.0), power);
}

void swapValues(inout float a, inout float b) {
    float t = a;
    a = b;
    b = t;
}

void split(in vec4 v, out vec3 xyz, out float w) {
    xyz = v.xyz;
    w = v.w;
}

vec3 fresnelSchlick(float cosTheta, vec3 f0) {
    return f0 + (1.0 - f0) * pow(clamp(1.0 - cosTheta, 0.0, 1.0), 5.0);
}

float distributionGGX(vec3 n, vec3 h, float roughness) {
    float a = roughness * roughness;
    float a2 = a * a;
    float nh = max(dot(n, h), 0.0);
    float denom = nh * nh * (a2 - 1.0) + 1.0;
    return a2 / (PI * denom * denom);
}

float shadowFactor(vec4 lightSpacePos) {
    vec3 proj = lightSpacePos.xyz / lightSpacePos.w * 0.5 + 0.5;
    float shadow = 0.0;
    for (int i = 0; i < SHADOW_SAMPLES; ++i) {
        vec2 offset = vec2(float(i % 4), float(i / 4)) * 0.001;
        shadow += texture(uShadowMap, vec3(proj.xy + offset, proj.z));
    }
    return shadow / float(SHADOW_SAMPLES);
}

subroutine vec3 ColorMode(vec3 c);
subroutine(ColorMode) vec3 identity(vec3 c) { return c; }
subroutine uniform ColorMode uMode;

invariant precise float stable(float x) { return x; }

// ── Main ──
void main() {
    // Vectors, swizzles, constructors
    vec3 n = normalize(vNormal);
    vec3 l = normalize(uLightPos - vWorldPos);
    vec3 v = normalize(camera.position - vWorldPos);
    vec3 h = normalize(l + v);
    vec4 sample4 = texture(uAlbedo, vUV);
    vec3 rgb = sample4.rgb;
    vec2 xy = sample4.xy;
    float alpha = sample4.a;
    vec4 swizzled = sample4.wzyx;
    vec4 stpq = vec4(vUV.st, vUV.pq);
    ivec2 size = textureSize(uAlbedo, 0);
    uvec3 ids = uvec3(1u, 2u, 3u);
    bvec3 flags = bvec3(true, false, true);
    dvec2 wide = dvec2(1.0lf, 2.0lf);
    mat3 tbn = mat3(vTangent.xyz, cross(n, vTangent.xyz), n);
    mat4 identityMat = mat4(1.0);
    float arr[3] = float[3](1.0, 2.0, 3.0);
    float arr2[] = float[](1.0, 2.0);
    vec3 palette[2] = vec3[2](vec3(1.0, 0.0, 0.0), vec3(0.0, 0.0, 1.0));

    // Normal mapping
    if (uUseNormalMap) {
        vec3 tn = texture(uNormalMap, vUV).xyz * 2.0 - 1.0;
        n = normalize(tbn * tn);
    } else if (vMaterialId == 0) {
        n = normalize(n);
    } else {
        n = -n;
    }

    // Lighting
    float diffuse  = max(dot(n, l), 0.0);
    float specular = pow(max(dot(n, h), 0.0), uShininess);
    vec3 color = uBaseColor * (0.15 + diffuse) + vec3(specular) * 0.4 + rim(n, v) * vec3(0.2, 0.3, 0.5);

    // Operators
    int i = 5;
    i += 2; i -= 1; i *= 3; i /= 2; i %= 4;
    i <<= 1; i >>= 1; i &= 0xF; i |= 0x1; i ^= 0x3;
    i++; --i;
    int bits = (i & 3) | (i ^ 5) | ~i | (i << 2) | (i >> 1);
    bool logic = (diffuse > 0.5 && specular < 0.5) || !(alpha >= 1.0) ^^ (alpha <= 0.0) || diffuse != 1.0 || diffuse == 0.0;
    float tern = logic ? 1.0 : 0.0;
    color = mix(color, rgb, 0.5) * SATURATE(tern) + EPSILON;
    color = pow(color, vec3(1.0 / kGamma));

    // Loops and control flow
    for (int k = 0; k < min(lights.count, MAX_LIGHTS); k++) {
        if (lights.positions[k].w < 0.0) continue;
        if (k > 6) break;
        color += lights.colors[k].rgb * 0.01;
    }
    int w = 0;
    while (w < 3) { w++; }
    do { w--; } while (w > 0);
    switch (vMaterialId) {
        case 0:
            color *= 1.0;
            break;
        case 1:
        case 2:
            color *= 0.5;
            break;
        default:
            color = vec3(1.0, 0.0, 1.0);
    }

    // Builtins
    float len = length(color) + distance(l, v) + dot(n, l) + abs(-1.0) + sign(1.0) + floor(1.5) + ceil(1.5) + fract(1.5);
    float stepped = step(0.5, diffuse) + smoothstep(0.0, 1.0, diffuse) + clamp(diffuse, 0.0, 1.0) + mod(5.0, 3.0);
    vec3 refl = reflect(-l, n) + refract(-l, n, 1.0 / 1.5) + faceforward(n, v, n);
    float sc = sin(PI) + cos(TWO_PI) + tan(0.5) + atan(1.0, 2.0) + exp(1.0) + log(2.0) + sqrt(4.0) + inversesqrt(4.0);
    vec4 env = textureLod(uEnvironment, refl, 2.0) + texelFetch(uAlbedo, ivec2(0, 0), 0) + textureGrad(uAlbedo, vUV, dFdx(vUV), dFdy(vUV));
    float dd = dFdx(len) + dFdy(len) + fwidth(len);
    imageStore(uOutput, ivec2(gl_FragCoord.xy), vec4(color, 1.0));
    uint c = atomicCounterIncrement(uCounter);
    memoryBarrier();
    barrier();

    if (alpha < 0.01) {
        discard;
    }

    // Builtin variables
    float depth = gl_FragCoord.z;
    bool front = gl_FrontFacing;
    vec2 pc = gl_PointCoord;
    int prim = gl_PrimitiveID;
    int layer = gl_Layer;
    gl_FragDepth = depth;
    uvec3 gid = gl_GlobalInvocationID;
    uvec3 lid = gl_LocalInvocationID;
    uint idx = gl_LocalInvocationIndex;
    int vid = gl_VertexID + gl_InstanceID;
    gl_Position = camera.projection * camera.view * push.model * vec4(vWorldPos, 1.0);
    gl_PointSize = 1.0;
    gl_ClipDistance[0] = 1.0;
    gl_SampleMask[0] = ~0;

    fragColor = vec4(color, 1.0);
    fragNormal = vec4(n * 0.5 + 0.5, 1.0);
    return;
}

// ── Extra layout, storage and memory qualifiers ──
layout(row_major, std140, binding = 9) uniform Matrices { mat4 modelA; layout(column_major) mat4 modelB; };
layout(location = 7, component = 2) in float vComponent;
layout(location = 8, index = 1) out vec4 fragSecondary;
layout(xfb_buffer = 0, xfb_stride = 32) out;
layout(r32f, binding = 1) coherent volatile restrict uniform image2D uCoherent;
layout(rgba8ui, binding = 2) readonly uniform uimage2D uReadOnly;
layout(r32i, binding = 3) writeonly uniform iimage3D uWriteOnly;
layout(binding = 4) uniform samplerBuffer uTexelBuffer;
layout(binding = 5) uniform sampler2DMS uMultisample;
layout(binding = 6) uniform sampler1D uLine;
layout(binding = 7) uniform sampler3D uVolumeTex;
layout(binding = 8) uniform samplerCubeArray uCubeArray;
layout(binding = 9) uniform sampler2DRect uRect;
layout(binding = 10) uniform sampler1DArrayShadow uShadowArray;
layout(binding = 11) uniform usamplerCube uUCube;
layout(binding = 12) uniform isampler2DArray uIArray;
shared float sharedScratch[64];
patch out vec4 tessPatchData;
centroid in vec2 vCentroidUV;
sample in vec2 vSampleUV;
lowp float lowFloat;
mediump vec3 medVec;
highp mat4 highMat;
precise vec3 preciseVec;
const float constArray[3] = float[](1.0, 2.0, 3.0);
const ivec2 offsets[2] = ivec2[2](ivec2(0, 1), ivec2(1, 0));

// ── Legacy GLSL 1.x names (inside a disabled block) ──
#if 0
attribute vec3 aPosition;
varying vec2 vTexCoord;
uniform sampler2D uTex;
void legacy() {
    vec4 c = texture2D(uTex, vTexCoord);
    gl_FragColor = c * gl_Color;
    gl_FragData[0] = c;
    gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
    gl_TexCoord[0] = gl_MultiTexCoord0;
}
#endif

// ── Matrix and vector type zoo ──
mat2 m2; mat3 m3; mat4 m4;
mat2x3 m23; mat2x4 m24; mat3x2 m32; mat3x4 m34; mat4x2 m42; mat4x3 m43;
dmat2 dm2; dmat3 dm3; dmat4 dm4; dmat2x3 dm23;
dvec2 dv2; dvec3 dv3; dvec4 dv4;
bvec2 bv2; bvec4 bv4;
ivec3 iv3; ivec4 iv4;
uvec2 uv2; uvec4 uv4;
double dbl;
uint unsignedValue = 1u;
atomic_uint atomicCounterVar;

// ── Geometry-shader style declarations ──
layout(triangles) in;
layout(triangle_strip, max_vertices = 3) out;
layout(points) in;
layout(line_strip, max_vertices = 2) out;
layout(lines_adjacency) in;
layout(triangles_adjacency) in;
layout(invocations = 4) in;
layout(stream = 1) out vec3 streamOut;
layout(vertices = 4) out;
layout(quads, equal_spacing, ccw) in;
layout(isolines, fractional_even_spacing, cw) in;
layout(point_mode) in;
layout(pixel_center_integer, origin_upper_left) in vec4 gl_FragCoord;
layout(depth_any) out float gl_FragDepth;
layout(depth_greater) out float gl_FragDepth;
layout(depth_unchanged) out float gl_FragDepth;

void geometryStage() {
    for (int i = 0; i < gl_in.length(); ++i) {
        gl_Position = gl_in[i].gl_Position;
        gl_PrimitiveID = gl_PrimitiveIDIn;
        EmitVertex();
    }
    EndPrimitive();
    EmitStreamVertex(1);
    EndStreamPrimitive(1);
}

void tessellationStage() {
    gl_TessLevelOuter[0] = 4.0;
    gl_TessLevelInner[0] = 4.0;
    gl_out[gl_InvocationID].gl_Position = gl_in[gl_InvocationID].gl_Position;
    vec3 tc = gl_TessCoord;
    int patchVerts = gl_PatchVerticesIn;
}

// ── More builtins ──
void builtins() {
    vec4 v = vec4(1.0);
    float r = radians(90.0) + degrees(1.0) + sinh(1.0) + cosh(1.0) + tanh(1.0) + asin(0.5) + acos(0.5) + asinh(1.0) + acosh(2.0) + atanh(0.5);
    float s = pow(2.0, 3.0) + exp2(3.0) + log2(8.0) + trunc(1.5) + round(1.5) + roundEven(1.5) + min(1.0, 2.0) + max(1.0, 2.0) + mod(5.0, 3.0) + modf(1.5, r);
    float t = clamp(0.5, 0.0, 1.0) + mix(0.0, 1.0, 0.5) + step(0.5, 0.2) + smoothstep(0.0, 1.0, 0.5) + fma(1.0, 2.0, 3.0) + sign(-1.0) + isnan(1.0 / 0.0 == 0.0 ? 1.0 : 0.0);
    bool b = isinf(1.0) || any(bvec3(true)) || all(bvec3(true)) || any(lessThan(v, v)) || any(equal(v, v)) || any(notEqual(v, v)) || any(greaterThanEqual(v, v));
    int i = floatBitsToInt(1.0) + packUnorm4x8(v) > 0 ? bitCount(7) + findLSB(8) + findMSB(8) + bitfieldExtract(255, 0, 4) + bitfieldInsert(0, 15, 0, 4) + bitfieldReverse(1) : 0;
    uint u = packHalf2x16(v.xy) + packSnorm2x16(v.xy) + uaddCarry(1u, 2u, u) + usubBorrow(1u, 2u, u);
    umulExtended(1u, 2u, u, u);
    mat3 inv = inverse(mat3(1.0)) * transpose(mat3(1.0)) * outerProduct(vec3(1.0), vec3(1.0));
    float det = determinant(mat3(1.0)) + dot(v, v) + length(v) + distance(v, v);
    vec4 tex = texture(uLine, 0.5) + textureProj(uAlbedo, vec3(0.0)) + textureOffset(uAlbedo, vUV, ivec2(1)) + textureGather(uAlbedo, vUV) + textureQueryLod(uAlbedo, vUV).x + textureSamples(uMultisample) + texelFetch(uMultisample, ivec2(0), 0);
    int levels = textureQueryLevels(uAlbedo);
    vec4 img = imageLoad(uCoherent, ivec2(0));
    imageAtomicAdd(uWriteOnly, ivec3(0), 1);
    memoryBarrierShared(); memoryBarrierImage(); memoryBarrierBuffer(); memoryBarrierAtomicCounter(); groupMemoryBarrier();
    uint old = atomicAdd(unsignedValue, 1u);
    atomicMin(unsignedValue, 1u); atomicMax(unsignedValue, 1u); atomicAnd(unsignedValue, 1u); atomicOr(unsignedValue, 1u);
    atomicXor(unsignedValue, 1u); atomicExchange(unsignedValue, 1u); atomicCompSwap(unsignedValue, 1u, 2u);
    float interp = interpolateAtCentroid(vSampleUV.x) + interpolateAtSample(vSampleUV.x, 0) + interpolateAtOffset(vSampleUV.x, vec2(0.0));
    bool helper = gl_HelperInvocation;
    int sampleId = gl_SampleID;
    vec2 samplePos = gl_SamplePosition;
    int ssampleMask = gl_SampleMaskIn[0];
    float dd2 = dFdxFine(r) + dFdyFine(r) + dFdxCoarse(r) + dFdyCoarse(r) + fwidthFine(r) + fwidthCoarse(r);
    int viewport = gl_ViewportIndex;
    int layerOut = gl_Layer;
    int baseVertex = gl_BaseVertex + gl_BaseInstance + gl_DrawID;
    uvec3 wg = gl_NumWorkGroups + gl_WorkGroupSize + gl_WorkGroupID;
}
