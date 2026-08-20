extends "res://scripts/main_v2.gd"

const EXTRACTION_POINT := Vector3(7.0, 0.0, 104.0)
const TERRAIN_SIZE_X := 260.0
const TERRAIN_SIZE_Z := 320.0
const TERRAIN_RESOLUTION := 129

var terrain_noise: FastNoiseLite
var detail_noise: FastNoiseLite
var terrain_heights := PackedFloat32Array()
var terrain_min_height: float = 0.0
var terrain_max_height: float = 0.0


func _ready() -> void:
	_configure_input()
	_setup_noise()
	_build_environment()
	_build_aster_valley()
	_spawn_player()
	_spawn_enemies()
	_build_extraction_beacon()
	_build_hud()
	_show_mission_intro()


func _process(delta: float) -> void:
	mission_time += delta
	if game_finished or player == null:
		return

	var enemies_left := get_tree().get_nodes_in_group("enemies").size()
	if hostiles_label != null:
		hostiles_label.text = "HOSTILES  %02d / %02d" % [enemies_left, total_enemies]

	if enemies_left == 0 and not extraction_active:
		_activate_extraction()

	if extraction_active and is_instance_valid(player):
		var target := Vector3(EXTRACTION_POINT.x, _terrain_height_at(EXTRACTION_POINT.x, EXTRACTION_POINT.z) + 1.0, EXTRACTION_POINT.z)
		var extraction_distance := player.global_position.distance_to(target)
		if objective_label != null:
			objective_label.text = "RETURN TO VANGUARD LZ  //  %03d M" % int(extraction_distance)
		if extraction_distance <= 5.0:
			_complete_mission()

	if extraction_active and extraction_beacon != null:
		extraction_beacon.rotation.y += delta * 0.72
		var pulse := 1.0 + sin(mission_time * 3.6) * 0.07
		extraction_beacon.scale = Vector3(pulse, 1.0, pulse)


func _setup_noise() -> void:
	terrain_noise = FastNoiseLite.new()
	terrain_noise.seed = 2089
	terrain_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	terrain_noise.frequency = 0.010
	terrain_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	terrain_noise.fractal_octaves = 5
	terrain_noise.fractal_lacunarity = 2.05
	terrain_noise.fractal_gain = 0.48

	detail_noise = FastNoiseLite.new()
	detail_noise.seed = 9917
	detail_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	detail_noise.frequency = 0.035
	detail_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	detail_noise.fractal_octaves = 3
	detail_noise.fractal_gain = 0.45


func _build_environment() -> void:
	var world_environment := WorldEnvironment.new()
	world_environment.name = "AsterAtmosphere"
	var environment := Environment.new()

	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color(0.08, 0.30, 0.61)
	sky_material.sky_horizon_color = Color(0.58, 0.78, 0.92)
	sky_material.ground_bottom_color = Color(0.035, 0.055, 0.065)
	sky_material.ground_horizon_color = Color(0.33, 0.43, 0.43)
	sky_material.sun_angle_max = 18.0
	sky_material.sun_curve = 0.08

	var sky := Sky.new()
	sky.sky_material = sky_material
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.ambient_light_color = Color(0.65, 0.75, 0.83)
	environment.ambient_light_energy = 0.72
	environment.fog_enabled = true
	environment.fog_light_color = Color(0.60, 0.72, 0.78)
	environment.fog_density = 0.0022
	environment.fog_sky_affect = 0.26
	world_environment.environment = environment
	add_child(world_environment)

	var sun := DirectionalLight3D.new()
	sun.name = "PrimarySun"
	sun.rotation_degrees = Vector3(-46.0, -31.0, 0.0)
	sun.light_color = Color(1.0, 0.91, 0.76)
	sun.light_energy = 1.55
	sun.shadow_enabled = true
	add_child(sun)

	var cool_fill := DirectionalLight3D.new()
	cool_fill.name = "SkyFill"
	cool_fill.rotation_degrees = Vector3(-22.0, 146.0, 0.0)
	cool_fill.light_color = Color(0.36, 0.55, 0.82)
	cool_fill.light_energy = 0.24
	cool_fill.shadow_enabled = false
	add_child(cool_fill)


func _build_aster_valley() -> void:
	_build_terrain()
	_build_river()
	_build_forest()
	_build_boulder_field()
	_build_distant_mountain_mass()
	_build_vanguard_landing_zone()
	_build_helix_outpost()
	_build_valley_bridge()
	_build_landmarks()


func _terrain_height_at(x: float, z: float) -> float:
	if terrain_noise == null:
		return 0.0

	var normalized_side := abs(x) / (TERRAIN_SIZE_X * 0.5)
	var side_rise := pow(clampf(normalized_side, 0.0, 1.15), 1.75) * 52.0
	var broad := terrain_noise.get_noise_2d(x, z) * 7.4
	var detail := detail_noise.get_noise_2d(x, z) * 2.1
	var north_rise := maxf(0.0, (-z - 88.0) / 72.0) * 10.0
	var river_channel := exp(-pow((x + 23.0) / 9.5, 2.0)) * 4.8
	var central_floor := exp(-pow(x / 34.0, 2.0)) * 2.3
	var h := side_rise + broad + detail + north_rise - river_channel - central_floor
	return clampf(h, -2.8, 58.0)


func _build_terrain() -> void:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	terrain_heights.clear()
	terrain_min_height = 99999.0
	terrain_max_height = -99999.0

	var cells := TERRAIN_RESOLUTION - 1
	var step_x := TERRAIN_SIZE_X / float(cells)
	var step_z := TERRAIN_SIZE_Z / float(cells)
	var half_x := TERRAIN_SIZE_X * 0.5
	var half_z := TERRAIN_SIZE_Z * 0.5

	for zi in range(TERRAIN_RESOLUTION):
		var z := -half_z + float(zi) * step_z
		for xi in range(TERRAIN_RESOLUTION):
			var x := -half_x + float(xi) * step_x
			var h := _terrain_height_at(x, z)
			terrain_heights.append(h)
			terrain_min_height = minf(terrain_min_height, h)
			terrain_max_height = maxf(terrain_max_height, h)
			vertices.append(Vector3(x, h, z))

			var hx0 := _terrain_height_at(x - step_x, z)
			var hx1 := _terrain_height_at(x + step_x, z)
			var hz0 := _terrain_height_at(x, z - step_z)
			var hz1 := _terrain_height_at(x, z + step_z)
			var normal := Vector3(hx0 - hx1, step_x + step_z, hz0 - hz1).normalized()
			normals.append(normal)

			var slope := 1.0 - normal.y
			var base_color := Color(0.18, 0.30, 0.11)
			if h > 35.0:
				base_color = Color(0.46, 0.47, 0.44)
			elif slope > 0.16 or h > 19.0:
				base_color = Color(0.31, 0.32, 0.29)
			elif h < 1.0:
				base_color = Color(0.14, 0.25, 0.10)
			var color_variation := detail_noise.get_noise_2d(x * 2.0, z * 2.0) * 0.035
			colors.append(base_color.lightened(maxf(0.0, color_variation)).darkened(maxf(0.0, -color_variation)))
			uvs.append(Vector2(float(xi) / float(cells) * 12.0, float(zi) / float(cells) * 14.0))

	for zi in range(cells):
		for xi in range(cells):
			var a := zi * TERRAIN_RESOLUTION + xi
			var b := a + 1
			var c := a + TERRAIN_RESOLUTION
			var d := c + 1
			indices.append(a)
			indices.append(c)
			indices.append(b)
			indices.append(b)
			indices.append(c)
			indices.append(d)

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices

	var terrain_mesh := ArrayMesh.new()
	terrain_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var terrain_material := StandardMaterial3D.new()
	terrain_material.vertex_color_use_as_albedo = true
	terrain_material.roughness = 0.92
	terrain_material.metallic = 0.02
	terrain_mesh.surface_set_material(0, terrain_material)

	var terrain := MeshInstance3D.new()
	terrain.name = "AsterTerrain"
	terrain.mesh = terrain_mesh
	add_child(terrain)

	var ground_body := StaticBody3D.new()
	ground_body.name = "AsterTerrainCollision"
	var collision := CollisionShape3D.new()
	var height_shape := HeightMapShape3D.new()
	height_shape.map_width = TERRAIN_RESOLUTION
	height_shape.map_depth = TERRAIN_RESOLUTION
	height_shape.map_data = terrain_heights
	collision.shape = height_shape
	ground_body.add_child(collision)
	add_child(ground_body)


func _build_river() -> void:
	var river := MeshInstance3D.new()
	river.name = "AsterRiver"
	var plane := PlaneMesh.new()
	plane.size = Vector2(19.0, 286.0)
	river.mesh = plane
	river.position = Vector3(-23.0, -0.52, 0.0)
	var water := StandardMaterial3D.new()
	water.albedo_color = Color(0.055, 0.20, 0.31)
	water.metallic = 0.35
	water.roughness = 0.16
	river.material_override = water
	add_child(river)

	for z in [-112.0, -54.0, 8.0, 72.0, 124.0]:
		var bank_y := _terrain_height_at(-23.0, z) - 0.2
		_create_visual_box(Vector3(-33.5, bank_y + 0.3, z), Vector3(2.2, 0.8, 18.0), Color(0.24, 0.25, 0.22), 0.02, 0.95, Vector3(0.0, float(int(abs(z)) % 21) - 10.0, 8.0))


func _build_forest() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 88201
	var positions: Array[Vector3] = []
	var scales: Array[float] = []

	for _i in range(220):
		var x := rng.randf_range(-118.0, 118.0)
		var z := rng.randf_range(-150.0, 150.0)
		if abs(x) < 17.0:
			continue
		if abs(x + 23.0) < 10.0:
			continue
		if z > 82.0 and abs(x) < 40.0:
			continue
		if z < -70.0 and abs(x) < 48.0:
			continue
		var y := _terrain_height_at(x, z)
		if y > 31.0:
			continue
		positions.append(Vector3(x, y, z))
		scales.append(rng.randf_range(0.72, 1.48))

	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.top_radius = 0.16
	trunk_mesh.bottom_radius = 0.28
	trunk_mesh.height = 3.4
	var trunk_mat := StandardMaterial3D.new()
	trunk_mat.albedo_color = Color(0.18, 0.105, 0.055)
	trunk_mat.roughness = 1.0
	trunk_mesh.material = trunk_mat

	var canopy_mesh := CylinderMesh.new()
	canopy_mesh.top_radius = 0.05
	canopy_mesh.bottom_radius = 1.45
	canopy_mesh.height = 4.6
	var canopy_mat := StandardMaterial3D.new()
	canopy_mat.albedo_color = Color(0.055, 0.17, 0.075)
	canopy_mat.roughness = 0.94
	canopy_mesh.material = canopy_mat

	var trunk_mm := MultiMesh.new()
	trunk_mm.transform_format = MultiMesh.TRANSFORM_3D
	trunk_mm.mesh = trunk_mesh
	trunk_mm.instance_count = positions.size()
	var canopy_mm := MultiMesh.new()
	canopy_mm.transform_format = MultiMesh.TRANSFORM_3D
	canopy_mm.mesh = canopy_mesh
	canopy_mm.instance_count = positions.size()

	for i in range(positions.size()):
		var s := scales[i]
		var trunk_basis := Basis().scaled(Vector3(s, s, s))
		var canopy_basis := Basis().rotated(Vector3.UP, rng.randf_range(-PI, PI)).scaled(Vector3(s, s, s))
		trunk_mm.set_instance_transform(i, Transform3D(trunk_basis, positions[i] + Vector3.UP * (1.7 * s)))
		canopy_mm.set_instance_transform(i, Transform3D(canopy_basis, positions[i] + Vector3.UP * (4.15 * s)))

	var trunks := MultiMeshInstance3D.new()
	trunks.name = "PineTrunks"
	trunks.multimesh = trunk_mm
	add_child(trunks)

	var canopies := MultiMeshInstance3D.new()
	canopies.name = "PineCanopies"
	canopies.multimesh = canopy_mm
	add_child(canopies)


func _build_boulder_field() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42081
	var rock_mesh := SphereMesh.new()
	var rock_mat := StandardMaterial3D.new()
	rock_mat.albedo_color = Color(0.29, 0.30, 0.28)
	rock_mat.roughness = 0.96
	rock_mesh.material = rock_mat

	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = rock_mesh
	multimesh.instance_count = 92

	for i in range(multimesh.instance_count):
		var x := rng.randf_range(-122.0, 122.0)
		var z := rng.randf_range(-152.0, 152.0)
		var y := _terrain_height_at(x, z)
		var sx := rng.randf_range(0.5, 2.7)
		var sy := rng.randf_range(0.38, 1.65)
		var sz := rng.randf_range(0.55, 2.4)
		var basis := Basis().rotated(Vector3.UP, rng.randf_range(-PI, PI)).scaled(Vector3(sx, sy, sz))
		multimesh.set_instance_transform(i, Transform3D(basis, Vector3(x, y + sy * 0.45, z)))

	var rocks := MultiMeshInstance3D.new()
	rocks.name = "BoulderField"
	rocks.multimesh = multimesh
	add_child(rocks)


func _build_distant_mountain_mass() -> void:
	var mountain_mat := StandardMaterial3D.new()
	mountain_mat.albedo_color = Color(0.28, 0.33, 0.34)
	mountain_mat.roughness = 1.0

	var positions := [
		[Vector3(-145.0, 30.0, -122.0), Vector3(34.0, 42.0, 27.0)],
		[Vector3(-151.0, 37.0, -50.0), Vector3(42.0, 53.0, 32.0)],
		[Vector3(-148.0, 28.0, 37.0), Vector3(36.0, 40.0, 31.0)],
		[Vector3(-144.0, 24.0, 122.0), Vector3(31.0, 35.0, 25.0)],
		[Vector3(146.0, 34.0, -132.0), Vector3(39.0, 49.0, 29.0)],
		[Vector3(150.0, 41.0, -58.0), Vector3(44.0, 60.0, 34.0)],
		[Vector3(147.0, 29.0, 35.0), Vector3(36.0, 43.0, 31.0)],
		[Vector3(144.0, 26.0, 122.0), Vector3(33.0, 37.0, 27.0)],
		[Vector3(-62.0, 45.0, -181.0), Vector3(46.0, 65.0, 40.0)],
		[Vector3(30.0, 52.0, -188.0), Vector3(55.0, 75.0, 46.0)],
		[Vector3(103.0, 41.0, -177.0), Vector3(42.0, 59.0, 39.0)]
	]

	for data in positions:
		var mesh_instance := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.material = mountain_mat
		mesh_instance.mesh = sphere
		mesh_instance.position = data[0]
		mesh_instance.scale = data[1]
		mesh_instance.rotation_degrees = Vector3(0.0, float(int(abs(data[0].x)) % 37), 0.0)
		add_child(mesh_instance)


func _build_vanguard_landing_zone() -> void:
	var z := 102.0
	var base_y := _terrain_height_at(7.0, z)
	var dark_metal := Color(0.085, 0.105, 0.115)
	var alloy := Color(0.15, 0.18, 0.19)
	_create_static_box("VanguardPad", Vector3(7.0, base_y + 0.28, z), Vector3(25.0, 0.55, 20.0), dark_metal, 0.72, 0.30)
	_create_static_box("VanguardPadInset", Vector3(7.0, base_y + 0.58, z), Vector3(15.5, 0.08, 12.0), alloy, 0.62, 0.34)
	_create_neon_strip(Vector3(7.0, base_y + 0.65, z - 6.1), Vector3(11.0, 0.08, 0.08), cyan)
	_create_neon_strip(Vector3(7.0, base_y + 0.65, z + 6.1), Vector3(11.0, 0.08, 0.08), cyan)

	for side in [-1.0, 1.0]:
		_create_static_box("LZPylon", Vector3(7.0 + side * 10.5, base_y + 3.2, z), Vector3(1.2, 6.4, 1.2), alloy, 0.76, 0.28)
		_create_neon_strip(Vector3(7.0 + side * 10.5, base_y + 3.3, z - 0.62), Vector3(0.16, 3.6, 0.05), cyan)

	_create_static_box("LZCommand", Vector3(28.0, base_y + 2.1, 107.0), Vector3(12.0, 4.2, 9.0), Color(0.11, 0.13, 0.14), 0.56, 0.38)
	_create_neon_strip(Vector3(28.0, base_y + 2.35, 102.45), Vector3(7.0, 0.20, 0.05), cyan)


func _build_valley_bridge() -> void:
	var z := 18.0
	var y := maxf(_terrain_height_at(-6.0, z), _terrain_height_at(-38.0, z)) + 1.2
	_create_static_box("AsterBridge", Vector3(-22.0, y, z), Vector3(39.0, 1.1, 7.5), Color(0.10, 0.12, 0.13), 0.70, 0.34)
	_create_static_box("BridgeRailA", Vector3(-22.0, y + 1.25, z - 3.5), Vector3(39.0, 1.6, 0.35), Color(0.15, 0.18, 0.19), 0.65, 0.32)
	_create_static_box("BridgeRailB", Vector3(-22.0, y + 1.25, z + 3.5), Vector3(39.0, 1.6, 0.35), Color(0.15, 0.18, 0.19), 0.65, 0.32)
	_create_neon_strip(Vector3(-22.0, y + 0.62, z - 3.72), Vector3(31.0, 0.10, 0.05), cyan)


func _build_helix_outpost() -> void:
	var center := Vector3(8.0, 0.0, -73.0)
	var base_y := _terrain_height_at(center.x, center.z)
	var helix_dark := Color(0.055, 0.06, 0.065)
	var helix_alloy := Color(0.12, 0.13, 0.14)
	var red := Color(1.0, 0.10, 0.035)

	_create_static_box("HelixPlateau", Vector3(center.x, base_y + 0.35, center.z), Vector3(54.0, 0.70, 36.0), Color(0.09, 0.10, 0.095), 0.10, 0.88)
	_create_static_box("HelixBunker", Vector3(center.x, base_y + 3.0, center.z - 5.0), Vector3(19.0, 6.0, 15.0), helix_dark, 0.72, 0.28)
	_create_static_box("HelixBunkerCap", Vector3(center.x, base_y + 6.4, center.z - 5.0), Vector3(23.0, 1.0, 18.0), helix_alloy, 0.76, 0.24)

	for side in [-1.0, 1.0]:
		_create_static_box("HelixTower", Vector3(center.x + side * 18.0, base_y + 6.2, center.z - 3.0), Vector3(4.2, 12.4, 4.2), helix_dark, 0.74, 0.25)
		_create_neon_strip(Vector3(center.x + side * 18.0, base_y + 7.0, center.z - 5.14), Vector3(0.42, 6.5, 0.06), red)
		_create_static_box("HelixButtress", Vector3(center.x + side * 12.8, base_y + 2.6, center.z + 8.0), Vector3(2.2, 5.2, 12.0), helix_alloy, 0.64, 0.31)

	_create_static_box("HelixGateLeft", Vector3(center.x - 7.2, base_y + 3.2, center.z + 13.0), Vector3(2.5, 6.4, 2.8), helix_alloy, 0.70, 0.27)
	_create_static_box("HelixGateRight", Vector3(center.x + 7.2, base_y + 3.2, center.z + 13.0), Vector3(2.5, 6.4, 2.8), helix_alloy, 0.70, 0.27)
	_create_static_box("HelixGateTop", Vector3(center.x, base_y + 6.6, center.z + 13.0), Vector3(16.8, 1.2, 2.8), helix_alloy, 0.70, 0.27)
	_create_neon_strip(Vector3(center.x, base_y + 6.0, center.z + 14.44), Vector3(9.0, 0.12, 0.06), red)

	for p in [Vector3(-13.0, 0.0, -59.0), Vector3(25.0, 0.0, -57.0), Vector3(-14.0, 0.0, -84.0), Vector3(28.0, 0.0, -88.0)]:
		var py := _terrain_height_at(p.x, p.z)
		_create_static_box("HelixBarricade", Vector3(p.x, py + 0.7, p.z), Vector3(6.0, 1.4, 1.1), helix_alloy, 0.55, 0.40)


func _build_landmarks() -> void:
	# Original monumental sci-fi silhouette visible from most of the valley.
	var z := -132.0
	var y := _terrain_height_at(7.0, z)
	var alloy := Color(0.11, 0.13, 0.14)
	_create_static_box("AsterSpireLeft", Vector3(-15.0, y + 15.0, z), Vector3(4.0, 30.0, 6.0), alloy, 0.68, 0.30)
	_create_static_box("AsterSpireRight", Vector3(29.0, y + 15.0, z), Vector3(4.0, 30.0, 6.0), alloy, 0.68, 0.30)
	_create_static_box("AsterSpireCrown", Vector3(7.0, y + 29.0, z), Vector3(48.0, 3.0, 6.0), alloy, 0.68, 0.30)
	_create_neon_strip(Vector3(7.0, y + 27.2, z + 3.05), Vector3(30.0, 0.18, 0.08), Color(0.10, 0.72, 1.0))

	# Distant city/outpost silhouette nestled into the mountain pass.
	for i in range(10):
		var x := -26.0 + float(i) * 7.0
		var h := 8.0 + float((i * 7) % 15)
		var py := _terrain_height_at(x, -149.0)
		_create_visual_box(Vector3(x, py + h * 0.5, -149.0), Vector3(5.0, h, 6.0), Color(0.075, 0.09, 0.095), 0.52, 0.46)
		if i % 2 == 0:
			_create_neon_strip(Vector3(x, py + h * 0.55, -145.95), Vector3(1.5, 0.10, 0.05), cyan)


func _spawn_player() -> void:
	player = CharacterBody3D.new()
	player.name = "Vanguard_01"
	player.set_script(PLAYER_SCRIPT)
	var x := 7.0
	var z := 96.0
	player.position = Vector3(x, _terrain_height_at(x, z) + 1.20, z)
	add_child(player)


func _spawn_enemies() -> void:
	var soldier_data := [
		[Vector3(7.0, 0.0, 60.0), "scout"],
		[Vector3(-7.0, 0.0, 43.0), "rifleman"],
		[Vector3(19.0, 0.0, 31.0), "rifleman"],
		[Vector3(-7.0, 0.0, 3.0), "scout"],
		[Vector3(12.0, 0.0, -23.0), "rifleman"],
		[Vector3(-12.0, 0.0, -49.0), "heavy"],
		[Vector3(20.0, 0.0, -66.0), "rifleman"],
		[Vector3(5.0, 0.0, -78.0), "commander"]
	]

	for index in range(soldier_data.size()):
		var spawn: Vector3 = soldier_data[index][0]
		var enemy := CharacterBody3D.new()
		enemy.name = "HELIX_ASTER_%02d" % (index + 1)
		enemy.set_script(ENEMY_SCRIPT)
		enemy.set("unit_type", str(soldier_data[index][1]))
		enemy.set("target", player)
		enemy.position = Vector3(spawn.x, _terrain_height_at(spawn.x, spawn.z) + 1.15, spawn.z)
		add_child(enemy)

	var drone_positions := [Vector3(-17.0, 0.0, 23.0), Vector3(22.0, 0.0, -36.0), Vector3(-4.0, 0.0, -71.0)]
	for index in range(drone_positions.size()):
		var spawn: Vector3 = drone_positions[index]
		var drone := CharacterBody3D.new()
		drone.name = "HELIX_ASTER_DRONE_%02d" % (index + 1)
		drone.set_script(DRONE_SCRIPT)
		drone.set("target", player)
		drone.position = Vector3(spawn.x, _terrain_height_at(spawn.x, spawn.z) + 7.0 + float(index), spawn.z)
		add_child(drone)

	total_enemies = get_tree().get_nodes_in_group("enemies").size()


func _build_extraction_beacon() -> void:
	extraction_beacon = Node3D.new()
	extraction_beacon.name = "AsterExtractionBeacon"
	var y := _terrain_height_at(EXTRACTION_POINT.x, EXTRACTION_POINT.z)
	extraction_beacon.position = Vector3(EXTRACTION_POINT.x, y + 0.9, EXTRACTION_POINT.z)
	extraction_beacon.visible = false
	add_child(extraction_beacon)

	var base := MeshInstance3D.new()
	var base_mesh := CylinderMesh.new()
	base_mesh.top_radius = 2.8
	base_mesh.bottom_radius = 3.2
	base_mesh.height = 0.24
	base.mesh = base_mesh
	base.material_override = _make_material(Color(0.10, 0.13, 0.14), 0.72, 0.28)
	extraction_beacon.add_child(base)

	for side in [-1.0, 1.0]:
		var wing := MeshInstance3D.new()
		var wing_mesh := BoxMesh.new()
		wing_mesh.size = Vector3(0.32, 4.5, 0.32)
		wing.mesh = wing_mesh
		wing.position = Vector3(side * 1.75, 2.35, 0.0)
		wing.rotation_degrees.z = -10.0 * side
		wing.material_override = _emissive_material(Color(0.04, 0.58, 1.0), 2.8)
		extraction_beacon.add_child(wing)

	var beam := MeshInstance3D.new()
	var beam_mesh := CylinderMesh.new()
	beam_mesh.top_radius = 0.34
	beam_mesh.bottom_radius = 0.58
	beam_mesh.height = 11.0
	beam.mesh = beam_mesh
	beam.position.y = 5.6
	var beam_material := _emissive_material(Color(0.06, 0.62, 1.0, 0.32), 2.7)
	beam_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	beam.material_override = beam_material
	extraction_beacon.add_child(beam)


func _build_mission_header(root: Control) -> void:
	var header := Panel.new()
	header.anchor_left = 0.5
	header.anchor_right = 0.5
	header.offset_left = -310.0
	header.offset_top = 24.0
	header.offset_right = 310.0
	header.offset_bottom = 116.0
	header.add_theme_stylebox_override("panel", _panel_style(Color(0.012, 0.028, 0.042, 0.80), Color(cyan.r, cyan.g, cyan.b, 0.28), 1))
	root.add_child(header)

	var chapter := Label.new()
	chapter.text = "OPERATION 01 // ASTER VALLEY"
	chapter.position = Vector2(20.0, 10.0)
	chapter.size = Vector2(580.0, 22.0)
	chapter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chapter.add_theme_font_size_override("font_size", 12)
	chapter.add_theme_color_override("font_color", cyan)
	header.add_child(chapter)

	objective_label = Label.new()
	objective_label.text = "BREACH THE HELIX OUTPOST"
	objective_label.position = Vector2(20.0, 34.0)
	objective_label.size = Vector2(580.0, 27.0)
	objective_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	objective_label.add_theme_font_size_override("font_size", 18)
	objective_label.add_theme_color_override("font_color", pale)
	header.add_child(objective_label)

	hostiles_label = Label.new()
	hostiles_label.text = "HOSTILES  00 / 00"
	hostiles_label.position = Vector2(20.0, 64.0)
	hostiles_label.size = Vector2(580.0, 18.0)
	hostiles_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hostiles_label.add_theme_font_size_override("font_size", 11)
	hostiles_label.add_theme_color_override("font_color", orange)
	header.add_child(hostiles_label)

	status_label = Label.new()
	status_label.anchor_left = 0.5
	status_label.anchor_top = 1.0
	status_label.anchor_right = 0.5
	status_label.anchor_bottom = 1.0
	status_label.offset_left = -390.0
	status_label.offset_top = -80.0
	status_label.offset_right = 390.0
	status_label.offset_bottom = -44.0
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 15)
	status_label.add_theme_color_override("font_color", Color(0.70, 0.90, 0.92))
	status_label.text = "NEXUS: ASTER VALLEY LINK ESTABLISHED"
	root.add_child(status_label)


func _show_mission_intro() -> void:
	status_label.text = "NEXUS: ADVANCE THROUGH THE VALLEY // DESTROY HELIX OCCUPATION FORCE"
	var timer := get_tree().create_timer(4.0)
	timer.timeout.connect(func() -> void: if not game_finished and status_label != null: status_label.text = "NEXUS: NATURAL COVER + VANGUARD SHIELD RECHARGE AVAILABLE")


func _complete_mission() -> void:
	if game_finished:
		return
	game_finished = true
	status_label.text = "MISSION COMPLETE // ASTER VALLEY SECURED"
	status_label.add_theme_color_override("font_color", Color(0.34, 1.0, 0.70))
	objective_label.text = "VANGUARD EXTRACTION CONFIRMED"
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var timer := get_tree().create_timer(4.0)
	timer.timeout.connect(_return_to_command)
