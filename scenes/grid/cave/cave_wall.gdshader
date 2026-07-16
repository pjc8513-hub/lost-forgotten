shader_type spatial;

group_uniforms Textures;
uniform sampler2D noise : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D normalmap : hint_normal, filter_linear_mipmap, repeat_enable;

group_uniforms Settings;
uniform float triplanar_scale = 0.2; // Lower values make the rock details larger
uniform float height_scale = 0.25;
uniform vec3 albedo_color : source_color = vec3(0.15, 0.13, 0.12);
uniform float roughness : hint_range(0.0, 1.0) = 0.8;

varying vec3 triplanar_pos;
varying vec3 world_normal;

vec4 triplanar_texture(sampler2D p_sampler, vec3 p_weights, vec3 p_triplanar_pos) {
	vec4 samp = vec4(0.0);
	samp += texture(p_sampler, p_triplanar_pos.xy) * p_weights.z;
	samp += texture(p_sampler, p_triplanar_pos.xz) * p_weights.y;
	samp += texture(p_sampler, p_triplanar_pos.zy) * p_weights.x;
	return samp;
}

void vertex() {
	// 1. Get the vertex position and normal in World Space
	vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = abs((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	
	// 2. Use World Space coordinates for the triplanar mapping
	triplanar_pos = world_pos * triplanar_scale;
	
	// Calculate weights using the world-space normal direction
	vec3 power_normal = pow(world_normal, vec3(4.0));
	power_normal /= (power_normal.x + power_normal.y + power_normal.z);
	
	// 3. Sample the noise in World Space
	float height = triplanar_texture(noise, power_normal, triplanar_pos).x;
	
	// 4. Displace the vertex along its local normal
	// Because the noise is sampled in world space, adjacent vertices on separate meshes
	// will read the exact same height value, creating a seamless transition!
	VERTEX += NORMAL * (height * height_scale);
}

void fragment() {
	// Re-calculate weights using the world normal passed from vertex
	vec3 w = pow(world_normal, vec3(4.0));
	w /= (w.x + w.y + w.z);
	
	// Apply Triplanar Normal Map using world-space positions
	vec3 n_local = triplanar_texture(normalmap, w, triplanar_pos).xyz * 2.0 - 1.0;
	NORMAL_MAP = n_local; 
	
	ALBEDO = albedo_color;
	ROUGHNESS = roughness;
}