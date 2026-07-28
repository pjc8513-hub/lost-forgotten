shader_type spatial;

render_mode diffuse_burley, specular_schlick_ggx;

// ---------------------------------------------------------
// COLORS
// ---------------------------------------------------------

uniform vec4 mud_dark : source_color = vec4(0.075, 0.085, 0.045, 1.0);
uniform vec4 mud_light : source_color = vec4(0.20, 0.22, 0.10, 1.0);

uniform vec4 moss_dark : source_color = vec4(0.11, 0.18, 0.07, 1.0);
uniform vec4 moss_light : source_color = vec4(0.30, 0.38, 0.12, 1.0);

uniform vec4 water_dark : source_color = vec4(0.025, 0.075, 0.065, 1.0);
uniform vec4 water_highlight : source_color = vec4(0.15, 0.27, 0.20, 1.0);

// ---------------------------------------------------------
// SHAPE CONTROLS
// ---------------------------------------------------------

uniform float pattern_scale : hint_range(0.25, 12.0) = 3.0;

uniform float puddle_amount : hint_range(0.0, 1.0) = 0.42;
uniform float puddle_softness : hint_range(0.01, 0.3) = 0.10;

uniform float moss_amount : hint_range(0.0, 1.0) = 0.38;
uniform float moss_detail : hint_range(1.0, 30.0) = 9.0;

uniform float roughness_mud : hint_range(0.0, 1.0) = 0.88;
uniform float roughness_water : hint_range(0.0, 1.0) = 0.18;

uniform float ripple_strength : hint_range(0.0, 0.2) = 0.035;
uniform float ripple_speed : hint_range(0.0, 2.0) = 0.22;

uniform float normal_strength : hint_range(0.0, 2.0) = 0.55;


// ---------------------------------------------------------
// PROCEDURAL NOISE
// ---------------------------------------------------------

float random_2d(vec2 position) {
	return fract(
		sin(dot(position, vec2(127.1, 311.7))) * 43758.5453123
	);
}


float value_noise(vec2 position) {
	vec2 cell = floor(position);
	vec2 local_position = fract(position);

	// Smooth interpolation curve.
	vec2 smooth_position =
		local_position * local_position *
		(3.0 - 2.0 * local_position);

	float bottom_left = random_2d(cell);
	float bottom_right = random_2d(cell + vec2(1.0, 0.0));
	float top_left = random_2d(cell + vec2(0.0, 1.0));
	float top_right = random_2d(cell + vec2(1.0, 1.0));

	float bottom = mix(
		bottom_left,
		bottom_right,
		smooth_position.x
	);

	float top = mix(
		top_left,
		top_right,
		smooth_position.x
	);

	return mix(bottom, top, smooth_position.y);
}


float fractal_noise(vec2 position) {
	float result = 0.0;
	float amplitude = 0.5;

	for (int octave = 0; octave < 5; octave++) {
		result += value_noise(position) * amplitude;
		position = position * 2.03 + vec2(19.1, 7.7);
		amplitude *= 0.5;
	}

	return result;
}


// Approximate a procedural normal from the noise height.
vec3 noise_normal(
	vec2 position,
	float strength
) {
	float offset = 0.015;

	float center = fractal_noise(position);
	float right = fractal_noise(position + vec2(offset, 0.0));
	float up = fractal_noise(position + vec2(0.0, offset));

	vec3 normal_value = normalize(vec3(
		(center - right) * strength,
		(center - up) * strength,
		1.0
	));

	return normal_value;
}


// ---------------------------------------------------------
// FRAGMENT SHADER
// ---------------------------------------------------------

void fragment() {
	vec2 coordinates = UV * pattern_scale;

	// Large-scale uneven mud pattern.
	float terrain_noise = fractal_noise(coordinates);

	// Smaller broken-up details.
	float detail_noise = fractal_noise(
		coordinates * moss_detail + vec2(12.4, 3.8)
	);

	// -----------------------------------------------------
	// MUD
	// -----------------------------------------------------

	float mud_mix = smoothstep(
		0.25,
		0.78,
		terrain_noise + detail_noise * 0.18
	);

	vec3 final_color = mix(
		mud_dark.rgb,
		mud_light.rgb,
		mud_mix
	);


	// -----------------------------------------------------
	// PUDDLES
	// -----------------------------------------------------

	float puddle_threshold = 1.0 - puddle_amount;

	float puddle_mask = smoothstep(
		puddle_threshold + puddle_softness,
		puddle_threshold - puddle_softness,
		terrain_noise
	);

	// Break up the puddle edges.
	puddle_mask *= smoothstep(
		0.18,
		0.52,
		fractal_noise(coordinates * 0.72 + vec2(8.0, 14.0))
	);


	// -----------------------------------------------------
	// SUBTLE WATER MOVEMENT
	// -----------------------------------------------------

	float ripple_one = sin(
		coordinates.x * 9.0 +
		coordinates.y * 4.0 +
		TIME * ripple_speed * 6.0
	);

	float ripple_two = sin(
		coordinates.y * 11.0 -
		coordinates.x * 3.0 -
		TIME * ripple_speed * 4.5
	);

	float ripple = (ripple_one + ripple_two) * 0.5;
	ripple *= ripple_strength;

	float water_pattern = clamp(
		terrain_noise * 0.6 + ripple,
		0.0,
		1.0
	);

	vec3 water_color = mix(
		water_dark.rgb,
		water_highlight.rgb,
		water_pattern
	);

	final_color = mix(
		final_color,
		water_color,
		puddle_mask
	);


	// -----------------------------------------------------
	// MOSS
	// -----------------------------------------------------

	float moss_noise = fractal_noise(
		coordinates * 1.7 + vec2(31.0, 8.0)
	);

	float moss_threshold = 1.0 - moss_amount;

	float moss_mask = smoothstep(
		moss_threshold,
		moss_threshold + 0.18,
		moss_noise + detail_noise * 0.22
	);

	// Keep moss mostly out of the water.
	moss_mask *= 1.0 - puddle_mask * 0.85;

	vec3 moss_color = mix(
		moss_dark.rgb,
		moss_light.rgb,
		detail_noise
	);

	final_color = mix(
		final_color,
		moss_color,
		moss_mask
	);


	// -----------------------------------------------------
	// MATERIAL OUTPUT
	// -----------------------------------------------------

	ALBEDO = final_color;

	ROUGHNESS = mix(
		roughness_mud,
		roughness_water,
		puddle_mask
	);

	SPECULAR = mix(
		0.15,
		0.75,
		puddle_mask
	);

	METALLIC = 0.0;

	// Procedural muddy surface normal.
	vec3 muddy_normal = noise_normal(
		coordinates * 2.0,
		normal_strength
	);

	// Water is smoother than mud.
	NORMAL_MAP = mix(
		muddy_normal * 0.5 + 0.5,
		vec3(0.5, 0.5, 1.0),
		puddle_mask * 0.8
	);

	NORMAL_MAP_DEPTH = normal_strength;
}