shader_type canvas_item;
render_mode blend_add;

uniform float scroll_speed : hint_range(0.0, 1.0) = 0.06;
uniform float scale : hint_range(1.0, 40.0) = 12.0;
uniform float intensity : hint_range(0.0, 1.0) = 0.15;
uniform vec4 caustic_color : source_color = vec4(0.6, 0.9, 0.85, 1.0);

// cheap value noise
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

void fragment() {
    vec2 uv = UV * scale;
    float t = TIME * scroll_speed;

    // two overlapping noise layers drifting in different directions
    float n1 = noise(uv + vec2(t, t * 0.6));
    float n2 = noise(uv * 1.4 - vec2(t * 0.7, t * 0.3));

    // multiply + sharpen into thin bright veins
    float caustic = pow(n1 * n2, 3.0) * 6.0;
    caustic = clamp(caustic, 0.0, 1.0);

    COLOR = caustic_color * caustic * intensity;
}