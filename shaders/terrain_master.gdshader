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
	float macro_n = noise2(world_pos.xz * 0.025);
	float mid_n = noise2(world_pos.xz * 0.10);
	float fine_n = noise2(world_pos.xz * 0.46);
	float slope = 1.0 - clamp(NORMAL.y, 0.0, 1.0);

	vec3 base = vertex_tint.rgb;
	base *= mix(0.78, 1.17, macro_n);
	base *= mix(0.91, 1.08, mid_n);

	vec3 rock_dust = vec3(0.28, 0.29, 0.27) * mix(0.78, 1.12, fine_n);
	base = mix(base, rock_dust, smoothstep(0.30, 0.72, slope) * 0.34);

	float strata = sin(world_pos.y * 1.65 + world_pos.x * 0.035 + mid_n * 4.0) * 0.5 + 0.5;
	base *= mix(0.94, 1.05, strata * smoothstep(0.38, 0.80, slope));

	ALBEDO = base;
	ROUGHNESS = mix(0.86, 0.98, fine_n);
	METALLIC = 0.0;
}
