shader_type spatial;
render_mode blend_add, cull_disabled, unshaded;

uniform sampler2D noise_tex : repeat_enable;
uniform vec4 fire_color : source_color = vec4(1.0, 0.4, 0.0, 1.0);
uniform vec4 core_color : source_color = vec4(1.0, 1.0, 0.8, 1.0);

uniform float speed = 2.0;
uniform vec2 noise_scale = vec2(1.0, 2.0);
uniform float distortion_strength = 0.1;

// Controls the spell animation lifecycle
uniform float pillar_growth : hint_range(0.0, 1.0) = 1.0; 
uniform float edge_softness = 1.5;

void fragment() {
    // 1. Setup scrolling UVs
    vec2 shifting_uv = UV * noise_scale;
    shifting_uv.y -= TIME * speed;
    
    // 2. Intentional distortion (wobble)
    float distortion = texture(noise_tex, shifting_uv * 0.5).r;
    shifting_uv.x += (distortion - 0.5) * distortion_strength;
    
    // 3. Sample main fire noise
    float noise_base = texture(noise_tex, shifting_uv).r;
    
    // 4. Shape the pillar shape (fade out at top, bottom, and edges)
    // Vertically fade out based on growth parameter
    float vertical_fade = smoothstep(0.0, 0.3, UV.y) * smoothstep(pillar_growth, pillar_growth - 0.2, UV.y);
    
    // Fresnel-like effect for cylinder edges (softens the profile)
    float edge_fade = pow(1.0 - abs(dot(NORMAL, VIEW)), edge_softness);
    
    // Combine masks
    float intensity = noise_base * vertical_fade * edge_fade;
    
    // 5. Color grading (Hot core vs cool outer edges)
    vec3 final_color = mix(fire_color.rgb, core_color.rgb, pow(intensity, 2.5));
    
    // 6. Outputs
    ALBEDO = final_color * intensity * 2.0; // Overdrive for bloom/glow
    ALPHA = intensity;
}