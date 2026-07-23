shader_type spatial;

uniform sampler2D screen_tex: hint_screen_texture;
uniform float color_crush: hint_range(0.0, 100.0, 1.0) = 1.;
uniform vec2 gamma;

void vertex() {
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

void fragment() {
	vec2 uv = vec2(UV.x, UV.y * -1.);
	vec4 screen = texture(screen_tex, uv);
	//Dithering
	screen.rgb = pow(screen.rgb, vec3(gamma.x));
	float greyscale = max(screen.r, max(screen.g, screen.b));
	float lower = floor(greyscale * color_crush) / color_crush;
	float higher = ceil(greyscale * color_crush) / color_crush;
	float lower_dif = abs(lower - greyscale);
	float higher_dif = abs(higher - greyscale);
	float color_level = lower_dif < higher_dif ? lower : higher;
	float final_crush = color_level / greyscale;
	screen.rgb *= final_crush;
	screen.rgb = pow(screen.rgb, vec3(gamma.y));
	//application
	vec4 color = screen;
	ALBEDO = color.rgb;
}

void light() {
	DIFFUSE_LIGHT = vec3(1.);
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
}
	