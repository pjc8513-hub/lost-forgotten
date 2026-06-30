shader_type canvas_item;

uniform vec4 line_color : source_color = vec4(0.0, 0.5, 1.0, 1.0);
uniform float line_count : hint_range(1.0, 50.0) = 15.0;
uniform float line_thickness : hint_range(0.0, 1.0) = 0.3;
uniform float speed : hint_range(-10.0, 10.0) = 1.0;

void fragment() {
	float diagonal = UV.x + UV.y + (TIME * speed * 0.1);
	float pattern = sin(diagonal * line_count * 3.14159);
	float edge = smoothstep(1.0 - line_thickness, 1.0, pattern);
	COLOR = vec4(line_color.rgb, edge * line_color.a);
}
