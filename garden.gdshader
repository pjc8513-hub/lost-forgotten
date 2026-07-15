shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

// Uniforms (expose parameters to the editor)
uniform vec4 garden_bounds = vec4(-10.0, -10.0, 10.0, 10.0); // MIN_X, MIN_Z, MAX_X, MAX_Z
uniform float flora_density : hint_range(0.01, 10.0) = 4.0;
uniform sampler2D noise_texture; // A noise texture for clumping (A_NOISE, R_CLUMP)
uniform vec3 ground_color : source_color = vec3(0.08, 0.05, 0.03); // Rich soil
uniform vec3 leaf_color : source_color = vec3(0.1, 0.5, 0.1);
uniform vec3 leaf_color_2 : source_color = vec3(0.2, 0.6, 0.2); // Subtle leaf variation

// Wind / sway controls
uniform float wind_strength : hint_range(0.0, 0.5) = 0.03; // how far plants move (world units)
uniform float wind_speed : hint_range(0.0, 5.0) = 0.8;     // how fast the sway oscillates
uniform float wind_scale : hint_range(0.01, 2.0) = 0.35;   // spatial frequency (higher = more, tighter ripples)
uniform float wind_variation : hint_range(0.0, 1.0) = 0.8; // per-plant randomness (0 = uniform wave, 1 = very individual)

// Pseudo-random functions for color and petal shape
float hash12(vec2 p) {
	vec3 p3  = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

vec3 random_flower_color(vec2 id) {
	float h = hash12(id);
	// Generate colors in the purple/pink/yellow range
	return vec3(
		mix(0.6, 1.0, fract(h * 1.3)), // Red (often high)
		mix(0.1, 0.9, fract(h * 2.7)), // Green (variable)
		mix(0.3, 0.9, fract(h * 4.1))  // Blue (variable)
	);
}

// Function to generate a varied flower shape
float flower_shape(vec2 uv, float id, float t) {
	float r = length(uv);
	float a = atan(uv.y, uv.x);
	
	// Number of petals, varying slightly
	float num_petals = 5.0 + 3.0 * floor(hash12(vec2(id, 13.0)) * 2.0); 
	
	// Petal shape based on sine and cosine, with random variation
	float shape = 0.5 + 0.5 * sin(a * num_petals + t + hash12(vec2(id, 7.0)) * 6.28);
	float edge = 0.5 + 0.1 * cos(a * 2.0 + hash12(vec2(id, 11.0)) * 6.28);
	
	// Create the center and the petals
	float f = smoothstep(shape, shape - 0.05, r);
	f *= smoothstep(edge, edge - 0.05, r); // Outer boundary
	float center = 1.0 - smoothstep(0.1, 0.15, r); // Bright center
	
	return clamp(f + center, 0.0, 1.0);
}

void vertex() {
	// Gentle, localized wind sway — each plant nods a bit independently
	// instead of the whole mesh rolling like a wave.
	float plant_id = hash12(floor(VERTEX.xz * 4.0));
	float phase_offset = plant_id * 6.28 * wind_variation;
	float local_speed = mix(1.0, 1.4, plant_id * wind_variation);

	float sway = sin(TIME * wind_speed * local_speed
					+ VERTEX.x * wind_scale
					+ VERTEX.z * wind_scale
					+ phase_offset) * wind_strength;

	VERTEX.y += sway;
}

void fragment() {
	// Normalize the input UVs (0 to 1) to world coordinates within the garden bounds
	vec2 grid_uv = mix(garden_bounds.xy, garden_bounds.zw, UV);
	
	// Apply flora density
	grid_uv *= flora_density;
	
	// Create a grid for individual flora IDs
	vec2 id = floor(grid_uv);
	vec2 flora_uv = fract(grid_uv) - 0.5; // UV relative to the center of each cell
	
	// 1. Generate Ground/Soil (base color)
	vec3 final_color = ground_color;
	float final_alpha = 1.0;
	
	// Use Noise for organic clumping (e.g., green channel determines growth)
	float growth_factor = texture(noise_texture, grid_uv * 0.05).g;
	
	// Threshold for whether ANY flora grows here
	if (growth_factor > 0.3) {
		// Calculate subtle sway per-cell based on time and location
		float t = TIME * 2.0 + (id.x * 13.0 + id.y * 17.0);
		
		// 2. Generate Flowers vs. Leaves based on noise (e.g., blue channel)
		float plant_type_noise = texture(noise_texture, grid_uv * 0.1).b;
		
		if (plant_type_noise > 0.45) {
			// **It's a Flower**
			float f = flower_shape(flora_uv, hash12(id), t);
			
			// If we generated a pixel inside a flower, color it
			if (f > 0.05) {
				vec3 flower_col = random_flower_color(id);
				
				// Standard flower center (yellow/bright)
				float center_dist = length(flora_uv);
				if (center_dist < 0.15) {
					flower_col = vec3(1.0, 0.9, 0.1); 
				}
				
				final_color = flower_col;
			} else {
				// Base color for the edges/gaps between plants
				final_color = mix(leaf_color, leaf_color_2, hash12(id + vec2(1.1)));
			}
			
		} else {
			// **It's Foliage/Leaves**
			// Simple organic leaf clump shape
			float leaves = smoothstep(0.4, 0.45, hash12(id + flora_uv * 3.0));
			final_color = mix(leaf_color, leaf_color_2, leaves);
		}
		
		// Add subtle variation to growth strength (alpha) based on noise
		final_alpha = mix(0.1, 1.0, smoothstep(0.3, 0.7, growth_factor));
	}
	
	// Apply standard spatial shader lighting
	ALBEDO = final_color;
	ALPHA = final_alpha;
	
	// Add some natural variation to roughness
	ROUGHNESS = mix(0.6, 0.9, hash12(id + vec2(5.1)));
}
