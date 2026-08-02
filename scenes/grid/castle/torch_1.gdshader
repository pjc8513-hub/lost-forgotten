shader_type spatial;

render_mode unshaded,
			cull_disabled,
			depth_draw_opaque;

uniform sampler2D flame_texture : source_color, filter_nearest;

uniform vec4 hot_color : source_color = vec4(1.0, 0.85, 0.25, 1.0);
uniform vec4 middle_color : source_color = vec4(1.0, 0.25, 0.02, 1.0);
uniform vec4 outer_color : source_color = vec4(0.35, 0.0, 0.0, 1.0);

uniform float sway_amount : hint_range(0.0, 0.2) = 0.035;
uniform float sway_speed : hint_range(0.0, 20.0) = 5.0;
uniform float flutter_strength : hint_range(0.0, 0.1) = 0.018;
uniform float pulse_speed : hint_range(0.0, 20.0) = 8.0;
uniform float alpha_cutoff : hint_range(0.0, 1.0) = 0.1;
uniform float emission_strength : hint_range(0.0, 8.0) = 2.5;

float random(vec2 position) {
	return fract(
		sin(dot(position, vec2(12.9898, 78.233))) * 43758.5453
	);
}

void vertex() {
	// UV.y is normally 0 at the top and 1 at the bottom.
	// This makes the upper part of the flame move more than the base.
	float upper_flame = 1.0 - UV.y;

	float slow_sway =
		sin(TIME * sway_speed + UV.y * 7.0)
		* sway_amount
		* upper_flame;

	float quick_flutter =
		sin(TIME * 13.0 + UV.y * 19.0)
		* flutter_strength
		* upper_flame;

	VERTEX.x += slow_sway + quick_flutter;

	// Tiny vertical pulse.
	VERTEX.y +=
		sin(TIME * pulse_speed + UV.x * 4.0)
		* 0.008
		* upper_flame;
}

void fragment() {
	vec4 texture_color = texture(flame_texture, UV);
	// NoiseTexture2D provides the useful flame shape in its grayscale
	// channels; its alpha channel is not a reliable mask for this material.
	float flame_alpha = texture_color.r;

	if (flame_alpha < alpha_cutoff) {
		discard;
	}

	// Brighter near the center and base.
	float center =
		1.0 - clamp(abs(UV.x - 0.5) * 2.0, 0.0, 1.0);

	float height_gradient = 1.0 - UV.y;

	vec3 flame_color = mix(
		outer_color.rgb,
		middle_color.rgb,
		center
	);

	flame_color = mix(
		flame_color,
		hot_color.rgb,
		center * height_gradient
	);

	float pulse =
		0.88
		+ sin(TIME * pulse_speed) * 0.07
		+ sin(TIME * 17.0) * 0.03;

	ALBEDO = flame_color * pulse;
	EMISSION = flame_color * emission_strength * pulse;
	// Keep this as an opaque cutout. Writing ALPHA would move the material
	// into the transparent pipeline and can sort incorrectly against the sky.
}
