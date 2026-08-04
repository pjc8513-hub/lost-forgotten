shader_type spatial;

render_mode unshaded, cull_disabled, depth_draw_opaque;

// ----------------------------------------------------
// FOREST CANOPY SHADER
// Stylized moving foliage + gaps + dappled light
// Godot 4.x
// ----------------------------------------------------

uniform vec3 canopy_dark : source_color = vec3(0.045, 0.085, 0.045);
uniform vec3 canopy_mid : source_color = vec3(0.10, 0.18, 0.08);
uniform vec3 canopy_light : source_color = vec3(0.24, 0.34, 0.14);

uniform float canopy_scale : hint_range(0.1, 10.0) = 1.4;
uniform float detail_scale : hint_range(0.1, 20.0) = 4.5;

uniform float leaf_threshold : hint_range(0.0, 1.0) = 0.47;
uniform float edge_softness : hint_range(0.001, 0.3) = 0.07;

uniform float wind_speed : hint_range(0.0, 2.0) = 0.08;
uniform float wind_strength : hint_range(0.0, 1.0) = 0.12;

uniform float gap_amount : hint_range(0.0, 1.0) = 0.30;

uniform float light_strength : hint_range(0.0, 2.0) = 0.55;

uniform float pixel_size : hint_range(1.0, 32.0) = 5.0;

uniform sampler2D noise_texture;


// ----------------------------------------------------
// Cheap hash/noise helpers
// ----------------------------------------------------

float hash(vec2 p)
{
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}


float value_noise(vec2 p)
{
	vec2 i = floor(p);
	vec2 f = fract(p);

	f = f * f * (3.0 - 2.0 * f);

	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));

	return mix(
		mix(a, b, f.x),
		mix(c, d, f.x),
		f.y
	);
}


float fbm(vec2 p)
{
	float value = 0.0;
	float amplitude = 0.5;

	for(int i = 0; i < 4; i++)
	{
		value += value_noise(p) * amplitude;
		p *= 2.02;
		amplitude *= 0.5;
	}

	return value;
}


// ----------------------------------------------------
// Fragment
// ----------------------------------------------------

void fragment()
{
	// Pixelate the canopy pattern slightly
	vec2 uv = UV;

	vec2 pixel_uv = floor(uv * pixel_size * 32.0)
		/ (pixel_size * 32.0);

	// Wind direction
	vec2 wind =
		vec2(
			TIME * wind_speed,
			TIME * wind_speed * 0.37
		);

	// Large canopy masses
	float large_noise = fbm(
		pixel_uv * canopy_scale * 5.0
		+ wind
	);

	// Smaller leaf clusters moving differently
	float small_noise = fbm(
		pixel_uv * detail_scale * 6.0
		- wind * 1.7
	);

	// Slight irregular movement
	float sway =
		sin(
			pixel_uv.x * 18.0
			+ TIME * wind_speed * 8.0
		)
		* wind_strength;

	float canopy =
		large_noise * 0.72
		+ small_noise * 0.28
		+ sway;

	// ------------------------------------------------
	// Leaf silhouette
	// ------------------------------------------------

	float leaf_mask =
		smoothstep(
			leaf_threshold - edge_softness,
			leaf_threshold + edge_softness,
			canopy
		);


	// ------------------------------------------------
	// Openings in canopy
	// Creates occasional sky/light holes
	// ------------------------------------------------

	float gap_noise =
		fbm(
			pixel_uv * canopy_scale * 2.2
			+ vec2(18.0, 42.0)
			- wind * 0.4
		);

	float gap =
		smoothstep(
			1.0 - gap_amount,
			1.0,
			gap_noise
		);

	leaf_mask *= 1.0 - gap;


	// ------------------------------------------------
	// Canopy color bands
	// ------------------------------------------------

	vec3 color = canopy_dark;

	float mid_mask =
		smoothstep(
			0.42,
			0.65,
			canopy
		);

	color =
		mix(
			canopy_dark,
			canopy_mid,
			mid_mask
		);

	float highlight_mask =
		smoothstep(
			0.62,
			0.82,
			small_noise
		);

	color =
		mix(
			color,
			canopy_light,
			highlight_mask * 0.45
		);


	// ------------------------------------------------
	// Fake shafts / dapple light
	// ------------------------------------------------

	float dapple =
		fbm(
			pixel_uv * 12.0
			+ wind * 2.5
		);

	dapple =
		smoothstep(
			0.60,
			0.82,
			dapple
		);

	color +=
		canopy_light
		* dapple
		* light_strength
		* 0.18;


	// ------------------------------------------------
	// Output
	// ------------------------------------------------

	ALBEDO = color;

	// Small emission helps stop canopy becoming
	// completely black in dark scenes.
	EMISSION = color * 0.08;

	ALPHA = leaf_mask;
}