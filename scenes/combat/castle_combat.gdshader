shader_type canvas_item;
render_mode unshaded;

uniform float effect_progress : hint_range(0.0, 1.0) = 1.0;
uniform float effect_strength : hint_range(0.0, 1.0) = 0.0;
uniform float critical_strength : hint_range(0.0, 1.0) = 0.0;
uniform vec4 damage_color : source_color = vec4(0.75, 0.015, 0.025, 1.0);
uniform vec4 critical_color : source_color = vec4(1.0, 0.62, 0.18, 1.0);

void fragment() {
	float progress = clamp(effect_progress, 0.0, 1.0);
	float pulse = sin(progress * 3.14159265);
	float distance_from_center = distance(UV, vec2(0.5));
	float vignette = smoothstep(0.18, 0.78, distance_from_center);
	float ring_position = progress * 0.72;
	float ring = 1.0 - smoothstep(0.0, 0.055, abs(distance_from_center - ring_position));
	float critical_flicker = 0.65 + 0.35 * sin(progress * 56.0);
	float normal_alpha = pulse * (0.08 + vignette * 0.34);
	float critical_alpha = pulse * (0.14 + vignette * 0.42 + ring * critical_flicker * 0.32);
	float alpha = mix(normal_alpha, critical_alpha, critical_strength) * effect_strength;
	vec3 color = mix(damage_color.rgb, critical_color.rgb, critical_strength * (0.35 + ring * 0.65));
	COLOR = vec4(color, clamp(alpha, 0.0, 0.82));
}
