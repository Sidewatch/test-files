#version 330 core
// Fragment shader: a Phong-lit surface with a subtle rim light.

in vec3 vNormal;
in vec3 vWorldPos;
out vec4 fragColor;

uniform vec3 uLightPos = vec3(4.0, 6.0, 3.0);
uniform vec3 uCameraPos;
uniform vec3 uBaseColor = vec3(0.8, 0.35, 0.2);
uniform float uShininess = 32.0;

float rim(vec3 n, vec3 v) {
    return pow(1.0 - max(dot(n, v), 0.0), 3.0);
}

void main() {
    vec3 n = normalize(vNormal);
    vec3 l = normalize(uLightPos - vWorldPos);
    vec3 v = normalize(uCameraPos - vWorldPos);
    vec3 h = normalize(l + v);

    float diffuse  = max(dot(n, l), 0.0);
    float specular = pow(max(dot(n, h), 0.0), uShininess);
    vec3 color = uBaseColor * (0.15 + diffuse) + vec3(specular) * 0.4 + rim(n, v) * vec3(0.2, 0.3, 0.5);

    fragColor = vec4(color, 1.0);
}
