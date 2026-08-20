shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

varying vec3 world_pos;
varying vec4 vertex_tint;
varying vec3 world_normal;

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

float fbm(vec2 p) {
	float value = 0.0;
	float amp = 0.52;
	for (int i = 0; i < 4; i++) {
		value += noise2(p) * amp;
		p = p * 2.03 + vec2(13.7, 7.1);
		amp *= 0.48;
	}
	return value;
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize(mat3(MODEL_MATRIX) * NORMAL);
	vertex_tint = COLOR;
}

void fragment() {
	float macro = fbm(world_pos.xz * 0.028);
	float medium = fbm(world_pos.xz * 0.11 + vec2(4.2, 8.9));
	float fine = noise2(world_pos.xz * 0.72);
	float slope = 1.0 - clamp(world_normal.y, 0.0, 1.0);
	float altitude = smoothstep(8.0, 25.0, world_pos.y);
	float beach = 1.0 - smoothstep(0.6, 4.7, world_pos.y);

	vec3 grass = vec3(0.105, 0.205, 0.070);
	vec3 dry_grass = vec3(0.205, 0.245, 0.105);
	vec3 rock = vec3(0.275, 0.285, 0.275);
	vec3 dark_rock = vec3(0.165, 0.175, 0.170);
	vec3 sand = vec3(0.43, 0.37, 0.235);

	vec3 natural = mix(grass, dry_grass, macro * 0.55);
	natural = mix(natural, mix(rock, dark_rock, medium * 0.55), smoothstep(0.18, 0.58, slope));
	natural = mix(natural, sand, beach * 0.80);
	natural = mix(natural, dark_rock, altitude * smoothstep(0.12, 0.45, slope) * 0.42);

	vec3 authored = vertex_tint.rgb;
	vec3 base = mix(authored, natural, 0.68);
	float micro = mix(0.88, 1.10, fine);
	float strata = 0.94 + 0.06 * sin(world_pos.y * 2.1 + medium * 8.0);
	base *= micro * mix(1.0, strata, smoothstep(0.20, 0.60, slope));

	ALBEDO = base;
	ROUGHNESS = mix(0.78, 0.98, 0.45 + medium * 0.55);
	METALLIC = 0.0;
	AO = mix(0.82, 1.0, macro);
}
