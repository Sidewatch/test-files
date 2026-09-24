// HLSL: a vertex/pixel pair for a lit, textured mesh.
cbuffer PerFrame : register(b0) {
    float4x4 viewProj;
    float3   lightDir;
    float    time;
};

Texture2D    albedo   : register(t0);
SamplerState linear_s : register(s0);

struct VSIn  { float3 pos : POSITION; float3 nrm : NORMAL; float2 uv : TEXCOORD0; };
struct VSOut { float4 pos : SV_Position; float3 nrm : NORMAL; float2 uv : TEXCOORD0; };

VSOut VSMain(VSIn i) {
    VSOut o;
    o.pos = mul(viewProj, float4(i.pos, 1.0));
    o.nrm = normalize(i.nrm);
    o.uv  = i.uv + float2(0.0, sin(time) * 0.01);
    return o;
}

float4 PSMain(VSOut i) : SV_Target {
    float ndl = saturate(dot(i.nrm, -lightDir));
    float3 base = albedo.Sample(linear_s, i.uv).rgb;
    return float4(base * (0.2 + 0.8 * ndl), 1.0);
}
