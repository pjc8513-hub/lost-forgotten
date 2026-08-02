shader_type spatial;

group_uniforms Textures;
uniform sampler2D noise : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D normalmap : hint_normal, filter_linear_mipmap, repeat_enable;

group_uniforms Settings;
uniform float triplanar_scale = 0.5;
uniform float height_scale = 0.22;
uniform float normal_strength : hint_range(0.0, 1.0) = 0.35;
uniform vec3 albedo_color : source_color = vec3(0.605, 0.556, 0.537);
uniform float roughness : hint_range(0.0, 1.0) = 0.88;

varying vec3 world_position;
varying vec3 base_world_normal;

vec3 triplanar_weights(vec3 normal) {
	vec3 weights = pow(abs(normal), vec3(4.0));
	return weights / max(weights.x + weights.y + weights.z, 0.0001);
}

vec4 triplanar_texture(sampler2D source, vec3 weights, vec3 position) {
	return texture(source, position.zy) * weights.x
		+ texture(source, position.xz) * weights.y
		+ texture(source, position.xy) * weights.z;
}

// Convert each tangent-space normal into the world-space basis of its
// projection before blending. Directly blending the three texture samples
// makes lighting rotate incorrectly as a wall turns around a corner.
vec3 triplanar_world_normal(sampler2D source, vec3 weights, vec3 position, vec3 surface_normal) {
	vec3 x_sample = texture(source, position.zy).xyz * 2.0 - 1.0;
	vec3 y_sample = texture(source, position.xz).xyz * 2.0 - 1.0;
	vec3 z_sample = texture(source, position.xy).xyz * 2.0 - 1.0;

	vec3 direction = sign(surface_normal);
	direction += vec3(1.0) - abs(direction); // Avoid a zero sign at blend boundaries.

	vec3 x_normal = vec3(x_sample.z * direction.x, x_sample.y, -x_sample.x * direction.x);
	vec3 y_normal = vec3(y_sample.x, y_sample.z * direction.y, -y_sample.y * direction.y);
	vec3 z_normal = vec3(z_sample.x * direction.z, z_sample.y, z_sample.z * direction.z);

	return normalize(x_normal * weights.x + y_normal * weights.y + z_normal * weights.z);
}

void vertex() {
	vec3 original_world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	base_world_normal = normalize(mat3(MODEL_MATRIX) * NORMAL);
	vec3 weights = triplanar_weights(base_world_normal);
	float height = triplanar_texture(noise, weights, original_world_position * triplanar_scale).r;

	// Centering the displacement around zero prevents every wall from swelling
	// outward and reduces intersections at grid-cell boundaries.
	VERTEX += NORMAL * ((height - 0.5) * 2.0 * height_scale);
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec3 base_normal = normalize(base_world_normal);
	vec3 weights = triplanar_weights(base_normal);

	// Vertex displacement does not update mesh normals automatically. Derive a
	// geometric normal from the displaced world position so torch lighting
	// follows the visible rocky silhouette instead of the original flat box.
	vec3 displaced_normal = normalize(cross(dFdx(world_position), dFdy(world_position)));
	if (dot(displaced_normal, base_normal) < 0.0) {
		displaced_normal = -displaced_normal;
	}

	vec3 detail_normal = triplanar_world_normal(
		normalmap,
		weights,
		world_position * triplanar_scale,
		base_normal
	);
	vec3 detail_offset = detail_normal - base_normal * dot(detail_normal, base_normal);
	vec3 final_world_normal = normalize(displaced_normal + detail_offset * normal_strength);

	NORMAL = normalize((VIEW_MATRIX * vec4(final_world_normal, 0.0)).xyz);
	ALBEDO = albedo_color;
	ROUGHNESS = roughness;
}
