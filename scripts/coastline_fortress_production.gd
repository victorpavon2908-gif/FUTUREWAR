extends "res://scripts/coastline_fortress_artpass.gd"

const METAL_SHADER: Shader = preload("res://shaders/coast_metal.gdshader")
const ROCK_SHADER: Shader = preload("res://shaders/coast_rock.gdshader")


func _terrain_height_at(x: float, z: float) -> float:
	if coast_noise == null or detail_noise_cf == null:
		return 0.0

	var nx: float = x / 108.0
	var nz: float = z / 112.0
	var radial: float = sqrt(nx * nx + nz * nz)
	var edge: float = clampf((1.035 - radial) * 5.6, 0.0, 1.0)
	edge = edge * edge * (3.0 - 2.0 * edge)

	var base: float = -7.4 + edge * 17.8
	var broad: float = coast_noise.get_noise_2d(x, z) * 4.4 * edge
	var detail: float = detail_noise_cf.get_noise_2d(x, z) * 1.15 * edge

	var west_ridge: float = exp(-(pow((x + 60.0) / 27.0, 2.0) + pow((z + 4.0) / 48.0, 2.0))) * 12.0
	var east_ridge: float = exp(-(pow((x - 58.0) / 29.0, 2.0) + pow((z - 8.0) / 46.0, 2.0))) * 11.0
	var north_ridge: float = exp(-(pow(x / 48.0, 2.0) + pow((z + 76.0) / 30.0, 2.0))) * 9.0
	var lagoon: float = exp(-(pow(x / 30.0, 2.0) + pow((z + 10.0) / 26.0, 2.0))) * 14.5
	var south_lz: float = exp(-(pow(x / 24.0, 2.0) + pow((z - 78.0) / 22.0, 2.0))) * 4.2
	var approach: float = exp(-(pow(x / 18.0, 2.0) + pow((z - 49.0) / 35.0, 2.0))) * 2.4

	var value: float = base + broad + detail + west_ridge + east_ridge + north_ridge - lagoon - approach + south_lz
	return clampf(value, -8.0, 30.0)


func _build_environment() -> void:
	var world_environment: WorldEnvironment = WorldEnvironment.new()
	world_environment.name = "CoastlineProductionEnvironment"
	var environment: Environment = Environment.new()
	var sky_material: ProceduralSkyMaterial = ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color(0.035, 0.16, 0.36)
	sky_material.sky_horizon_color = Color(0.48, 0.72, 0.88)
	sky_material.ground_bottom_color = Color(0.012, 0.035, 0.052)
	sky_material.ground_horizon_color = Color(0.24, 0.38, 0.40)
	sky_material.sun_angle_max = 13.0
	sky_material.sun_curve = 0.075
	var sky: Sky = Sky.new()
	sky.sky_material = sky_material
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.ambient_light_color = Color(0.66, 0.74, 0.79)
	environment.ambient_light_energy = 0.72
	environment.fog_enabled = true
	environment.fog_light_color = Color(0.50, 0.66, 0.73)
	environment.fog_density = 0.00135
	environment.fog_sky_affect = 0.12
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.adjustment_enabled = true
	environment.adjustment_brightness = 1.02
	environment.adjustment_contrast = 1.10
	environment.adjustment_saturation = 0.96
	world_environment.environment = environment
	add_child(world_environment)

	var sun: DirectionalLight3D = DirectionalLight3D.new()
	sun.name = "CoastlineSun"
	sun.rotation_degrees = Vector3(-47.0, 30.0, 0.0)
	sun.light_color = Color(1.0, 0.90, 0.74)
	sun.light_energy = 1.72
	sun.shadow_enabled = true
	add_child(sun)

	var sky_fill: DirectionalLight3D = DirectionalLight3D.new()
	sky_fill.name = "BlueSkyFill"
	sky_fill.rotation_degrees = Vector3(-20.0, -145.0, 0.0)
	sky_fill.light_color = Color(0.26, 0.48, 0.78)
	sky_fill.light_energy = 0.24
	sky_fill.shadow_enabled = false
	add_child(sky_fill)

	var rim: DirectionalLight3D = DirectionalLight3D.new()
	rim.name = "WarmRim"
	rim.rotation_degrees = Vector3(-14.0, 112.0, 0.0)
	rim.light_color = Color(1.0, 0.56, 0.29)
	rim.light_energy = 0.10
	rim.shadow_enabled = false
	add_child(rim)


func _create_rock_chunk(center: Vector3, size_value: Vector3, seed_value: int) -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value
	var sectors: int = 7
	var lower: PackedVector3Array = PackedVector3Array()
	var middle: PackedVector3Array = PackedVector3Array()
	var upper: PackedVector3Array = PackedVector3Array()
	var hx: float = size_value.x * 0.5
	var hz: float = size_value.z * 0.5
	var y0: float = -size_value.y * 0.5
	var y1: float = size_value.y * 0.02
	var y2: float = size_value.y * 0.5
	var mid_shift: Vector2 = Vector2(rng.randf_range(-0.11, 0.11) * size_value.x, rng.randf_range(-0.11, 0.11) * size_value.z)
	var top_shift: Vector2 = Vector2(rng.randf_range(-0.18, 0.18) * size_value.x, rng.randf_range(-0.18, 0.18) * size_value.z)

	for i: int in range(sectors):
		var a: float = TAU * float(i) / float(sectors)
		var jitter: float = rng.randf_range(0.82, 1.16)
		lower.append(Vector3(cos(a) * hx * jitter, y0 + rng.randf_range(-0.05, 0.04) * size_value.y, sin(a) * hz * jitter))
		var mid_scale: float = rng.randf_range(0.70, 0.98)
		middle.append(Vector3(cos(a) * hx * mid_scale + mid_shift.x, y1 + rng.randf_range(-0.08, 0.08) * size_value.y, sin(a) * hz * mid_scale + mid_shift.y))
		var top_scale: float = rng.randf_range(0.38, 0.68)
		upper.append(Vector3(cos(a) * hx * top_scale + top_shift.x, y2 + rng.randf_range(-0.05, 0.05) * size_value.y, sin(a) * hz * top_scale + top_shift.y))

	var surface: SurfaceTool = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i: int in range(sectors):
		var next_i: int = (i + 1) % sectors
		_add_surface_quad(surface, lower[i], lower[next_i], middle[next_i], middle[i])
		_add_surface_quad(surface, middle[i], middle[next_i], upper[next_i], upper[i])

	var top_center: Vector3 = Vector3(top_shift.x, y2 + size_value.y * 0.05, top_shift.y)
	var bottom_center: Vector3 = Vector3.ZERO + Vector3(0.0, y0, 0.0)
	for i: int in range(sectors):
		var next_i: int = (i + 1) % sectors
		_add_surface_triangle(surface, upper[i], upper[next_i], top_center)
		_add_surface_triangle(surface, lower[next_i], lower[i], bottom_center)

	surface.generate_normals()
	var rock_mesh: ArrayMesh = surface.commit()
	var body: StaticBody3D = StaticBody3D.new()
	body.name = "CliffRock"
	body.position = center
	body.rotation_degrees = Vector3(rng.randf_range(-5.0, 5.0), rng.randf_range(0.0, 180.0), rng.randf_range(-4.0, 4.0))

	var mesh_instance: MeshInstance3D = MeshInstance3D.new()
	mesh_instance.mesh = rock_mesh
	var rock_material: ShaderMaterial = ShaderMaterial.new()
	rock_material.shader = ROCK_SHADER
	var shade: float = rng.randf_range(-0.025, 0.035)
	rock_material.set_shader_parameter("rock_color", Vector3(0.27 + shade, 0.28 + shade, 0.27 + shade))
	rock_material.set_shader_parameter("moss_color", Vector3(0.07, 0.12, 0.06))
	rock_material.set_shader_parameter("moss_amount", rng.randf_range(0.20, 0.48))
	mesh_instance.material_override = rock_material
	body.add_child(mesh_instance)

	if Vector2(center.x, center.z).length() < 124.0:
		var collision: CollisionShape3D = CollisionShape3D.new()
		var shape: BoxShape3D = BoxShape3D.new()
		shape.size = Vector3(size_value.x * 0.72, size_value.y * 0.80, size_value.z * 0.72)
		collision.shape = shape
		body.add_child(collision)
	add_child(body)


func _add_surface_triangle(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	surface.add_vertex(a)
	surface.add_vertex(b)
	surface.add_vertex(c)


func _add_surface_quad(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	_add_surface_triangle(surface, a, b, c)
	_add_surface_triangle(surface, a, c, d)


func _metal_material(base: Color, accent: Color, metallic: float = 0.80, roughness: float = 0.28, scale_value: float = 1.25) -> ShaderMaterial:
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = METAL_SHADER
	material.set_shader_parameter("base_color", Vector3(base.r, base.g, base.b))
	material.set_shader_parameter("accent_color", Vector3(accent.r, accent.g, accent.b))
	material.set_shader_parameter("metalness", metallic)
	material.set_shader_parameter("roughness_base", roughness)
	material.set_shader_parameter("panel_scale", scale_value)
	material.set_shader_parameter("accent_strength", 0.34)
	return material


func _panel_box(node_name: String, center: Vector3, size_value: Vector3, base: Color, accent: Color, rotation_value: Vector3 = Vector3.ZERO) -> StaticBody3D:
	var body: StaticBody3D = StaticBody3D.new()
	body.name = node_name
	body.position = center
	body.rotation_degrees = rotation_value
	var collision: CollisionShape3D = CollisionShape3D.new()
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = size_value
	collision.shape = shape
	body.add_child(collision)
	var mesh_instance: MeshInstance3D = MeshInstance3D.new()
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = size_value
	mesh_instance.mesh = mesh
	mesh_instance.material_override = _metal_material(base, accent)
	body.add_child(mesh_instance)
	add_child(body)
	return body


func _panel_visual_box(center: Vector3, size_value: Vector3, base: Color, accent: Color, rotation_value: Vector3 = Vector3.ZERO) -> void:
	var mesh_instance: MeshInstance3D = MeshInstance3D.new()
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = size_value
	mesh_instance.mesh = mesh
	mesh_instance.position = center
	mesh_instance.rotation_degrees = rotation_value
	mesh_instance.material_override = _metal_material(base, accent)
	add_child(mesh_instance)


func _panel_cylinder(node_name: String, center: Vector3, radius: float, height_value: float, base: Color, accent: Color, segments: int = 20) -> StaticBody3D:
	var body: StaticBody3D = StaticBody3D.new()
	body.name = node_name
	body.position = center
	var collision: CollisionShape3D = CollisionShape3D.new()
	var shape: CylinderShape3D = CylinderShape3D.new()
	shape.radius = radius
	shape.height = height_value
	collision.shape = shape
	body.add_child(collision)
	var mesh_instance: MeshInstance3D = MeshInstance3D.new()
	var mesh: CylinderMesh = CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height_value
	mesh.radial_segments = segments
	mesh_instance.mesh = mesh
	mesh_instance.material_override = _metal_material(base, accent, 0.82, 0.25, 1.5)
	body.add_child(mesh_instance)
	add_child(body)
	return body


func _build_command_platforms() -> void:
	var core: Vector3 = Vector3(0.0, PLATFORM_Y, -10.0)
	_panel_cylinder("CommandDeck", core, 19.5, 1.55, steel_mid, orange, 28)
	_panel_cylinder("CommandLowerRing", core + Vector3(0.0, -1.35, 0.0), 15.2, 1.25, steel_dark, orange, 24)
	_panel_cylinder("CommandTower", core + Vector3(0.0, 5.4, 0.0), 7.3, 7.2, Color(0.06, 0.075, 0.085), orange, 18)
	_panel_cylinder("CommandCrown", core + Vector3(0.0, 9.4, 0.0), 10.2, 1.0, steel_light, orange, 24)
	_panel_cylinder("CommandCap", core + Vector3(0.0, 10.5, 0.0), 5.4, 0.8, steel_dark, orange, 18)

	var reactor: MeshInstance3D = MeshInstance3D.new()
	var reactor_mesh: CylinderMesh = CylinderMesh.new()
	reactor_mesh.top_radius = 1.15
	reactor_mesh.bottom_radius = 1.55
	reactor_mesh.height = 8.2
	reactor_mesh.radial_segments = 14
	reactor.mesh = reactor_mesh
	reactor.position = core + Vector3(0.0, 5.8, 0.0)
	reactor.material_override = _emissive_material(Color(1.0, 0.12, 0.02), 4.5)
	add_child(reactor)

	var ring: MeshInstance3D = MeshInstance3D.new()
	var ring_mesh: TorusMesh = TorusMesh.new()
	ring_mesh.inner_radius = 8.8
	ring_mesh.outer_radius = 9.6
	ring_mesh.rings = 36
	ring_mesh.ring_segments = 12
	ring.mesh = ring_mesh
	ring.position = core + Vector3(0.0, 10.0, 0.0)
	ring.material_override = _metal_material(steel_light, orange, 0.75, 0.25, 1.7)
	add_child(ring)

	for i: int in range(8):
		var angle: float = TAU * float(i) / 8.0
		var radial_pos: Vector3 = core + Vector3(cos(angle) * 13.0, 4.1, sin(angle) * 13.0)
		var yaw: float = -rad_to_deg(angle) + 90.0
		_panel_box("CoreButtress", radial_pos, Vector3(2.2, 7.2, 8.2), steel_dark, orange, Vector3(-8.0, yaw, 0.0))
		_create_neon_strip(radial_pos + Vector3(0.0, 1.3, 0.0), Vector3(0.22, 3.7, 0.08), orange)

	for wing: Vector3 in [Vector3(-39.0, PLATFORM_Y - 0.7, -12.0), Vector3(39.0, PLATFORM_Y - 0.7, -12.0), Vector3(0.0, PLATFORM_Y + 0.8, -50.0)]:
		_panel_cylinder("FortressAuxDeck", wing, 11.2, 1.25, steel_mid, orange, 22)

	for side: float in [-1.0, 1.0]:
		_panel_box("CommandWing", core + Vector3(10.5 * side, 2.1, 0.0), Vector3(10.5, 1.2, 7.0), steel_mid, orange, Vector3(0.0, 0.0, 5.0 * side))


func _build_radial_bridges() -> void:
	_bridge_v2(Vector3(-28.0, PLATFORM_Y - 0.25, -11.0), Vector3(20.0, 1.0, 6.5), false)
	_bridge_v2(Vector3(28.0, PLATFORM_Y - 0.25, -11.0), Vector3(20.0, 1.0, 6.5), false)
	_bridge_v2(Vector3(0.0, PLATFORM_Y + 0.08, -31.0), Vector3(6.5, 1.0, 24.0), true)
	_bridge_v2(Vector3(0.0, PLATFORM_Y - 0.68, 18.0), Vector3(7.5, 1.0, 43.0), true)
	_panel_box("SouthAssaultRamp", Vector3(0.0, 8.9, 45.0), Vector3(10.5, 1.05, 27.0), steel_mid, cyan, Vector3(-9.0, 0.0, 0.0))
	for side: float in [-1.0, 1.0]:
		_panel_visual_box(Vector3(4.7 * side, 10.35, 45.0), Vector3(0.28, 1.8, 26.0), steel_light, cyan, Vector3(-9.0, 0.0, 0.0))


func _bridge_v2(center: Vector3, size_value: Vector3, long_axis_z: bool) -> void:
	_panel_box("FortressBridge", center, size_value, steel_mid, orange)
	if long_axis_z:
		for side: float in [-1.0, 1.0]:
			_panel_visual_box(center + Vector3(side * size_value.x * 0.49, 1.0, 0.0), Vector3(0.18, 1.55, size_value.z * 0.94), steel_light, orange)
			_create_neon_strip(center + Vector3(side * size_value.x * 0.46, 0.62, 0.0), Vector3(0.08, 0.07, size_value.z * 0.88), orange)
		var post_count: int = maxi(4, int(size_value.z / 5.0))
		for i: int in range(post_count + 1):
			var z: float = center.z - size_value.z * 0.44 + float(i) / float(post_count) * size_value.z * 0.88
			for side: float in [-1.0, 1.0]:
				_panel_visual_box(Vector3(center.x + side * size_value.x * 0.49, center.y + 1.8, z), Vector3(0.22, 2.0, 0.22), steel_dark, orange)
	else:
		for side: float in [-1.0, 1.0]:
			_panel_visual_box(center + Vector3(0.0, 1.0, side * size_value.z * 0.49), Vector3(size_value.x * 0.94, 1.55, 0.18), steel_light, orange)
			_create_neon_strip(center + Vector3(0.0, 0.62, side * size_value.z * 0.46), Vector3(size_value.x * 0.88, 0.07, 0.08), orange)


func _build_side_batteries() -> void:
	for side: float in [-1.0, 1.0]:
		var x: float = 39.0 * side
		_panel_cylinder("BatteryBase", Vector3(x, PLATFORM_Y + 1.1, -12.0), 4.8, 2.5, steel_dark, orange, 16)
		_panel_box("BatterySpine", Vector3(x, PLATFORM_Y + 5.1, -12.0), Vector3(3.8, 7.4, 3.8), steel_dark, orange)
		_panel_box("BatteryWing", Vector3(x + 5.8 * side, PLATFORM_Y + 3.2, -12.0), Vector3(9.8, 1.9, 4.4), steel_mid, orange, Vector3(0.0, 0.0, 12.0 * side))
		for barrel_index: int in range(2):
			_panel_box("BatteryBarrel", Vector3(x + 7.1 * side, PLATFORM_Y + 6.0 + float(barrel_index) * 0.75, -12.0), Vector3(8.5, 0.55, 0.55), steel_light, orange, Vector3(0.0, 0.0, -4.0 * side))
		_create_neon_strip(Vector3(x, PLATFORM_Y + 5.1, -13.95), Vector3(0.22, 4.6, 0.06), orange)


func _build_northern_monolith() -> void:
	var base_z: float = -75.0
	var base_y: float = maxf(_terrain_height_at(-14.0, base_z), _terrain_height_at(14.0, base_z))
	for side: float in [-1.0, 1.0]:
		_panel_box("NorthSpire", Vector3(13.0 * side, base_y + 19.0, base_z), Vector3(7.2, 39.0, 9.2), steel_dark, orange, Vector3(0.0, 0.0, 9.0 * side))
		_panel_box("NorthBlade", Vector3(18.0 * side, base_y + 32.0, base_z), Vector3(3.2, 22.0, 6.2), steel_light, orange, Vector3(0.0, 0.0, 19.0 * side))
		_create_neon_strip(Vector3(13.0 * side, base_y + 20.0, base_z + 4.65), Vector3(0.32, 24.0, 0.06), orange)
	_panel_box("NorthCrown", Vector3(0.0, base_y + 34.0, base_z), Vector3(35.0, 4.2, 9.2), steel_mid, orange)
	_panel_cylinder("NorthEnergyCore", Vector3(0.0, base_y + 25.0, base_z + 5.0), 1.6, 18.5, Color(0.12, 0.045, 0.03), orange, 12)
	_create_neon_strip(Vector3(0.0, base_y + 25.0, base_z + 6.7), Vector3(0.60, 13.0, 0.08), orange)


func _build_southern_landing_zone() -> void:
	var point: Vector3 = _extraction_world_position()
	_panel_cylinder("VanguardLZ", point + Vector3(0.0, -0.30, 0.0), 9.8, 0.8, steel_mid, cyan, 28)
	_panel_cylinder("VanguardLZInner", point + Vector3(0.0, 0.10, 0.0), 6.4, 0.16, Color(0.065, 0.095, 0.11), cyan, 24)
	for side: float in [-1.0, 1.0]:
		_panel_box("LZBeacon", point + Vector3(7.4 * side, 3.4, -2.4), Vector3(1.15, 6.5, 1.25), steel_dark, cyan, Vector3(0.0, 0.0, 6.0 * side))
		_create_neon_strip(point + Vector3(7.4 * side, 3.4, -3.04), Vector3(0.18, 4.6, 0.05), cyan)
	for i: int in range(8):
		var angle: float = TAU * float(i) / 8.0
		var light_pos: Vector3 = point + Vector3(cos(angle) * 8.0, 0.22, sin(angle) * 8.0)
		var light_mesh: MeshInstance3D = MeshInstance3D.new()
		var box_mesh: BoxMesh = BoxMesh.new()
		box_mesh.size = Vector3(0.50, 0.10, 0.50)
		light_mesh.mesh = box_mesh
		light_mesh.position = light_pos
		light_mesh.material_override = _emissive_material(cyan, 3.8)
		add_child(light_mesh)


func _build_horizon_structures() -> void:
	for i: int in range(7):
		var angle: float = TAU * float(i) / 7.0 + 0.25
		var x: float = cos(angle) * 160.0
		var z: float = sin(angle) * 160.0
		_create_rock_chunk(Vector3(x, 9.0 + float(i % 3) * 3.5, z), Vector3(18.0, 28.0 + float(i % 4) * 7.0, 20.0), 1200 + i)

	for i: int in range(3):
		var center_x: float = -135.0 + float(i) * 135.0
		var center_z: float = -205.0 - float(i % 2) * 20.0
		_panel_visual_box(Vector3(center_x - 12.0, 25.0, center_z), Vector3(6.0, 50.0, 8.0), Color(0.08, 0.11, 0.13), orange, Vector3(0.0, 0.0, -8.0))
		_panel_visual_box(Vector3(center_x + 12.0, 25.0, center_z), Vector3(6.0, 50.0, 8.0), Color(0.08, 0.11, 0.13), orange, Vector3(0.0, 0.0, 8.0))
		_panel_visual_box(Vector3(center_x, 48.0, center_z), Vector3(30.0, 4.0, 8.0), steel_mid, orange)


func _show_mission_intro() -> void:
	status_label.text = "NEXUS: COASTLINE FORTRESS // SOUTHERN LZ SECURE"
	var timer: SceneTreeTimer = get_tree().create_timer(3.2)
	timer.timeout.connect(func() -> void:
		if not game_finished and status_label != null:
			status_label.text = "NEXUS: CROSS THE ASSAULT RAMP // BREAK THE COMMAND CORE"
	)
