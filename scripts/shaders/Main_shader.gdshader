shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_nearest;
// The LoSpec palette texture passed from our MapTheme resource
uniform sampler2D palette_texture : filter_nearest;

uniform float pixel_size : hint_range(1.0, 16.0) = 8.0;
uniform float dither_strength : hint_range(0.0, 1.0) = 0.15;
uniform float contrast : hint_range(0.5, 3.0) = 0.8;

const mat4 bayer_matrix = mat4(
    vec4(0.0/16.0, 8.0/16.0, 2.0/16.0, 10.0/16.0),
    vec4(12.0/16.0, 4.0/16.0, 14.0/16.0, 6.0/16.0),
    vec4(3.0/16.0, 11.0/16.0, 1.0/16.0, 9.0/16.0),
    vec4(15.0/16.0, 7.0/16.0, 13.0/16.0, 5.0/16.0)
);

float luminance(vec3 c) {
    return dot(c, vec3(0.299, 0.587, 0.114));
}

vec3 find_closest_color(vec3 color) {
    // Dynamically fetch the width of our palette texture (e.g., 16, 20, 46)
    int palette_size = textureSize(palette_texture, 0).x;
    
    vec3 closest = vec3(0.0);
    float best_score = 99999.0;
    float color_luma = luminance(color);

    for (int i = 0; i < palette_size; i++) {
        // Sample from the center of each pixel along the 1D line of the texture
        vec2 uv = vec2((float(i) + 0.5) / float(palette_size), 0.5);
        vec3 pal = texture(palette_texture, uv).rgb;

        float rgb_dist = distance(color, pal);
        float lum_dist = abs(color_luma - luminance(pal));

        // Weight brightness more heavily than raw RGB distance
        float score = rgb_dist + lum_dist * 1.5;

        if (score < best_score) {
            best_score = score;
            closest = pal;
        }
    }

    return closest;
}

void fragment() {
    // Pixelation
    vec2 size = vec2(textureSize(SCREEN_TEXTURE, 0)) / pixel_size;
    vec2 pixelated_uv = floor(SCREEN_UV * size) / size;

    vec3 color = texture(SCREEN_TEXTURE, pixelated_uv).rgb;
	color = pow(color, vec3(0.9));    
    // Contrast boost (using our uniform)
    color = (color - 0.5) * contrast + 0.5;
    
    // Slight saturation boost
    float lum = luminance(color);
    color = mix(vec3(lum), color, 1.25);
    
    // Optional brightness quantization
     color = floor(color * 12.0) / 12.0;
	// color = max(color, vec3(0.08));    
    // Bayer dithering
    ivec2 pixel_coord = ivec2(mod(FRAGCOORD.xy / pixel_size, 4.0));
    float threshold = bayer_matrix[pixel_coord.x][pixel_coord.y];
    
    vec3 dithered_color = color + (threshold - 0.5) * dither_strength;
    dithered_color = clamp(dithered_color, 0.0, 1.0);

    COLOR.rgb = find_closest_color(dithered_color);
    COLOR.a = 1.0;
}