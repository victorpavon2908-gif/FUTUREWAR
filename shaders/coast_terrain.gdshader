shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

varying vec3 world_pos;
varying vec4 vertex_tint;

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
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
	vertex_tint = COLOR;
}

void fragment() {
	float large_noise = noise2(world_pos.xz * 0.055);
	float fine_noise = noise2(world_pos.xz * 0.36);
	float streak = noise2(vec2(world_pos.x * 0.12, world_pos.y * 0.28));
	float variation = mix(0.84, 1.14, large_noise) * mix(0.93, 1.06, fine_noise);

	vec3 base = vertex_tint.rgb * variation;
	float rocky = smoothstep(0.31, 0.46, max(base.r, max(base.g, base.b)));
	vec3 moss = vec3(0.10, 0.18, 0.075) * (0.75 + large_noise * 0.35);
	base = mix(base, moss, (1.0 - rocky) * 0.12);
	base *= mix(0.92, 1.08, streak * 0.35);

	ALBEDO = base;
	ROUGHNESS = mix(0.88, 0.98, fine_noise);
	METALLIC = 0.0;
}
