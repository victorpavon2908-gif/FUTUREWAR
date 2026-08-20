shader_type spatial;
render_mode blend_mix, depth_draw_alpha_prepass, cull_back, diffuse_burley, specular_schlick_ggx;

varying vec3 world_pos;

void vertex() {
	vec4 wp = MODEL_MATRIX * vec4(VERTEX, 1.0);
	float wave = sin(wp.x * 0.42 + TIME * 0.85) * 0.045;
	wave += sin(wp.z * 0.31 - TIME * 0.64) * 0.035;
	VERTEX.y += wave;
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float fresnel = pow(1.0 - max(dot(normalize(NORMAL), normalize(VIEW)), 0.0), 3.0);
	float wave = sin(world_pos.x * 0.55 + world_pos.z * 0.26 + TIME * 0.7) * 0.5 + 0.5;
	vec3 deep = vec3(0.018, 0.12, 0.17);
	vec3 shallow = vec3(0.07, 0.35, 0.42);
	vec3 sky = vec3(0.30, 0.61, 0.77);
	vec3 color = mix(deep, shallow, 0.38 + wave * 0.12);
	color = mix(color, sky, fresnel * 0.48);
	ALBEDO = color;
	ROUGHNESS = mix(0.08, 0.20, wave);
	SPECULAR = 0.88;
	ALPHA = 0.84;
	EMISSION = color * 0.025;
}
