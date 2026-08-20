shader_type spatial;
render_mode blend_mix, depth_draw_alpha_prepass, cull_back, diffuse_burley, specular_schlick_ggx;

varying vec3 world_pos;
varying float crest;

float wave(vec2 p, vec2 dir, float freq, float speed, float amp) {
	return sin(dot(p, normalize(dir)) * freq + TIME * speed) * amp;
}

void vertex() {
	vec2 p = VERTEX.xz;
	float w1 = wave(p, vec2(1.0, 0.35), 0.095, 0.78, 0.20);
	float w2 = wave(p, vec2(-0.35, 1.0), 0.14, -0.62, 0.12);
	float w3 = wave(p, vec2(0.72, 0.68), 0.052, 0.39, 0.10);
	float w = w1 + w2 + w3;
	VERTEX.y += w;
	crest = clamp(abs(w) * 2.0, 0.0, 1.0);
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float chop_a = sin(world_pos.x * 0.18 + TIME * 1.0);
	float chop_b = sin(world_pos.z * 0.23 - TIME * 0.74);
	float chop = (chop_a + chop_b) * 0.5;
	float fresnel = pow(1.0 - max(dot(normalize(NORMAL), normalize(VIEW)), 0.0), 3.3);

	vec3 deep = vec3(0.012, 0.070, 0.115);
	vec3 mid = vec3(0.020, 0.205, 0.300);
	vec3 sky = vec3(0.18, 0.46, 0.64);
	vec3 foam = vec3(0.72, 0.88, 0.91);

	vec3 color = mix(deep, mid, 0.55 + chop * 0.06);
	color = mix(color, sky, fresnel * 0.62);
	float foam_factor = smoothstep(0.58, 0.95, crest) * 0.25;
	color = mix(color, foam, foam_factor);

	ALBEDO = color;
	ROUGHNESS = mix(0.05, 0.18, crest);
	METALLIC = 0.03;
	SPECULAR = 0.92;
	ALPHA = 0.93;
	EMISSION = color * (0.018 + fresnel * 0.020);
}
