shader_type spatial;
render_mode blend_mix, depth_draw_alpha_prepass, cull_back, diffuse_burley, specular_schlick_ggx;

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float wave_a = sin(world_pos.x * 0.085 + TIME * 0.75);
	float wave_b = sin(world_pos.z * 0.11 - TIME * 0.58);
	float wave_c = sin((world_pos.x + world_pos.z) * 0.045 + TIME * 0.36);
	float waves = (wave_a + wave_b + wave_c) / 3.0;
	float fresnel = pow(1.0 - max(dot(normalize(NORMAL), normalize(VIEW)), 0.0), 3.0);

	vec3 deep = vec3(0.018, 0.095, 0.145);
	vec3 mid = vec3(0.025, 0.25, 0.34);
	vec3 sky = vec3(0.16, 0.47, 0.62);
	vec3 color = mix(deep, mid, 0.48 + waves * 0.10);
	color = mix(color, sky, fresnel * 0.52);

	ALBEDO = color;
	ROUGHNESS = mix(0.06, 0.20, abs(waves));
	METALLIC = 0.08;
	SPECULAR = 0.85;
	ALPHA = 0.90;
	EMISSION = color * 0.035;
}
