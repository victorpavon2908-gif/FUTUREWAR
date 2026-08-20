shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec3 rock_color : source_color = vec3(0.28, 0.29, 0.28);
uniform vec3 moss_color : source_color = vec3(0.075, 0.13, 0.065);
uniform float moss_amount : hint_range(0.0, 1.0) = 0.36;

varying vec3 world_pos;
varying vec3 world_normal;

float hash21(vec2 p) {
	p = fract(p * vec2(127.1, 311.7));
	p += dot(p, p + 34.5);
	return fract(p.x * p.y);
}

float noise2(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash21(i);
	float b = hash21(i + vec2(1.0, 0.0));
	float c = hash21(i + vec2(0.0, 1.0));
	float d = hash21(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize(mat3(MODEL_MATRIX) * NORMAL);
}

void fragment() {
	float macro = noise2(world_pos.xz * 0.055);
	float grain = noise2(world_pos.xy * 0.46 + world_pos.zy * 0.18);
	float strata = 0.88 + 0.12 * sin(world_pos.y * 1.7 + macro * 8.0);
	float top_face = smoothstep(0.45, 0.86, world_normal.y);
	float moss_noise = noise2(world_pos.xz * 0.12 + vec2(8.0, 2.0));
	float moss_mask = top_face * smoothstep(0.34, 0.72, moss_noise) * moss_amount;

	vec3 color = rock_color * mix(0.74, 1.12, macro) * mix(0.90, 1.07, grain);
	color *= strata;
	color = mix(color, moss_color * (0.80 + moss_noise * 0.35), moss_mask);

	ALBEDO = color;
	ROUGHNESS = mix(0.82, 0.98, grain);
	METALLIC = 0.0;
	AO = mix(0.80, 1.0, macro);
}
