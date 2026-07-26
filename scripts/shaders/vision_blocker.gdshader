shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_nearest;
uniform float darkness : hint_range(0.0, 1.0) = 0.92;
uniform float reveal_radius : hint_range(0.05, 0.8) = 0.22;
uniform float edge_softness : hint_range(0.01, 0.4) = 0.08;
uniform vec4 darkness_color : source_color = vec4(0.005, 0.004, 0.008, 1.0);

void fragment() {
	vec2 centered_uv = SCREEN_UV - vec2(0.5);
	// Compensate for the viewport's aspect ratio so the reveal stays circular.
	centered_uv.x *= SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
	float distance_from_center = length(centered_uv);
	float outside_reveal = smoothstep(reveal_radius - edge_softness, reveal_radius, distance_from_center);

	vec3 scene_color = texture(SCREEN_TEXTURE, SCREEN_UV).rgb;
	vec3 darkened_color = mix(scene_color, darkness_color.rgb, darkness);
	COLOR = vec4(mix(scene_color, darkened_color, outside_reveal), 1.0);
}
