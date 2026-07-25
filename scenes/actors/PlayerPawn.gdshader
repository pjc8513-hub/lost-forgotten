shader_type spatial;
render_mode unshaded, cull_disabled;

// Texture Uniforms for Post-Processing
uniform sampler2D screen_texture : source_color, hint_screen_texture, filter_nearest;
uniform sampler2D depth_texture : hint_depth_texture, filter_nearest;
uniform sampler2D normal_texture : hint_normal_roughness_texture, filter_nearest;

group_uniforms Outlines;
uniform float depth_threshold : hint_range(0.0, 1.0) = 0.3;
uniform float normal_threshold : hint_range(0.0, 1.0) = 0.4;
uniform float normal_edge_bias : hint_range(0.0, 5.0) = 1.0;

group_uniforms Styling;
uniform vec4 dark_outline_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform vec4 bright_outline_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float dark_line_intensity : hint_range(0.0, 1.0) = 1.0;
uniform float bright_line_intensity : hint_range(0.0, 1.0) = 0.5;

// Vertex shader forces the QuadMesh to span the exact screen boundaries
void vertex() {
	POSITION = vec4(VERTEX.xy * 2.0, 0.0, 1.0);
}

// Helper function to linearize depth buffer data
float get_linear_depth(vec2 uv, mat4 inv_proj_matrix) {
	float depth = texture(depth_texture, uv).r;
	vec3 ndc = vec3(uv * 2.0 - 1.0, depth);
	vec4 view = inv_proj_matrix * vec4(ndc, 1.0);
	view.xyz /= view.w;
	return -view.z;
}

// Helper function to retrieve and normalize screen normals (-1.0 to 1.0)
vec3 get_normal(vec2 uv) {
	vec3 normal_raw = texture(normal_texture, uv).rgb;
	return normal_raw * 2.0 - 1.0;
}

// Logic courtesy of Cody King via Eduardo's video to clean normal-based edges
float normal_edge_indicator(float bias, vec3 normal_center, vec3 normal_neighbor, float depth_diff) {
	float threshold = 1.0 - normal_threshold;
	float indicator = dot(normal_center, normal_neighbor);
	indicator = 1.0 - smoothstep(threshold, 1.0, indicator);
	indicator *= smoothstep(0.0, 0.1, depth_diff * bias);
	return indicator;
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 texel_size = 1.0 / VIEWPORT_SIZE;
	
	// Sample base properties of the current pixel
	vec3 original_albedo = texture(screen_texture, uv).rgb;
	float center_depth = get_linear_depth(uv, INV_PROJECTION_MATRIX);
	vec3 center_normal = get_normal(uv);
	
	// Define neighborhood UV offsets (Left, Right, Up, Down)
	vec2 offsets[4];
	offsets[0] = uv + vec2(-1.0, 0.0) * texel_size; // Left
	offsets[1] = uv + vec2(1.0, 0.0) * texel_size;  // Right
	offsets[2] = uv + vec2(0.0, 1.0) * texel_size;  // Up
	offsets[3] = uv + vec2(0.0, -1.0) * texel_size; // Down
	
	float depth_diff_sum = 0.0;
	float normal_diff_sum = 0.0;
	float outer_edge_mask = 0.5; // Starts at 0.5 for inverse calculations
	
	// Loop through neighbors to process structural shifts
	for(int i = 0; i < 4; i++) {
		float neighbor_depth = get_linear_depth(offsets[i], INV_PROJECTION_MATRIX);
		vec3 neighbor_normal = get_normal(offsets[i]);
		
		// 1. Depth Outlines (Outer edges)
		float d_diff = neighbor_depth - center_depth;
		depth_diff_sum += clamp(d_diff, 0.0, 1.0);
		
		// 2. Normal Outlines (Inner creases)
		normal_diff_sum += normal_edge_indicator(normal_edge_bias, center_normal, neighbor_normal, abs(d_diff));
		
		// 3. Mask creation to prevent double thick outlines on silhouettes
		outer_edge_mask += (center_depth - neighbor_depth);
	}
	
	// Apply thresholds using smoothstep
	float depth_edge = smoothstep(depth_threshold, depth_threshold + 0.05, depth_diff_sum);
	float normal_edge = smoothstep(0.1, 0.3, normal_diff_sum);
	
	// Finalize mask logic to scrub duplicate lines out
	float edge_mask = smoothstep(0.5, 0.55, outer_edge_mask);
	edge_mask = clamp(edge_mask * 10.0, 0.0, 1.0);
	normal_edge = clamp(normal_edge - edge_mask, 0.0, 1.0);
	
	// Isolate clean inner lines from outer lines
	float inner_lines = clamp(normal_edge - depth_edge, 0.0, 1.0);
	float outer_lines = clamp(depth_edge, 0.0, 1.0);
	
	// Composite colors together onto final screen output
	vec3 final_color = original_albedo;
	
	// Apply bright inner contours
	final_color = mix(final_color, bright_outline_color.rgb, inner_lines * bright_line_intensity);
	
	// Apply dark outer shadows/borders
	final_color = mix(final_color, dark_outline_color.rgb, outer_lines * dark_line_intensity);
	
	ALBEDO = final_color;
}