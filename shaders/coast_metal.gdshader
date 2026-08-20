shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec3 base_color : source_color = vec3(0.10, 0.12, 0.13);
uniform vec3 accent_color : source_color = vec3(1.0, 0.18, 0.04);
uniform float metalness : hint_range(0.0, 1.0) = 0.78;
uniform float roughness_base : hint_range(0.0, 1.0) = 0.28;
uniform float panel_scale = 1.35;
uniform float accent_strength : hint_range(0.0, 2.0) = 0.32;

varying vec3 world_pos;
varying vec3 object_pos;

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	object_pos = VERTEX;
}

void fragment() {
	vec2 grid_uv = abs(object_pos.xz) * panel_scale;
	vec2 cell = abs(fract(grid_uv) - 0.5);
	float seam = 1.0 - smoothstep(0.455, 0.495, max(cell.x, cell.y));
	float grain = hash21(floor(world_pos.xz * 4.0)) * 0.06;
	float scratch = smoothstep(0.985, 1.0, fract(world_pos.y * 7.0 + hash21(world_pos.xz * 0.7) * 4.0));

	vec3 color = base_color * (0.88 + grain);
	color = mix(color, base_color * 0.52, seam * 0.45);
	color = mix(color, vec3(0.42), scratch * 0.10);

	ALBEDO = color;
	METALLIC = metalness;
	ROUGHNESS = clamp(roughness_base + seam * 0.16 + grain * 0.8, 0.12, 0.68);
	EMISSION = accent_color * seam * accent_strength * 0.11;
}
