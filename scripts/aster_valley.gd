extends "res://scripts/main_v2.gd"

const PLAYER_AST: Script = preload("res://scripts/player_v2.gd")
const ENEMY_AST: Script = preload("res://scripts/enemy_v2.gd")
const DRONE_AST: Script = preload("res://scripts/drone.gd")

const EXTRACTION_POINT: Vector3 = Vector3(7.0, 0.0, 104.0)
const TERRAIN_SIZE_X: float = 260.0
const TERRAIN_SIZE_Z: float = 320.0
const TERRAIN_RESOLUTION: int = 97

var terrain_noise: FastNoiseLite
var detail_noise: FastNoiseLite
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

	var enemies_left: int = get_tree().get_nodes_in_group("enemies").size()
	if hostiles_label != null:
		hostiles_label.text = "HOSTILES  %02d / %02d" % [enemies_left, total_enemies]

	if enemies_left == 0 and not extraction_active:
		_activate_extraction()

	if extraction_active and is_instance_valid(player):
		var target: Vector3 = _extraction_world_position()
		var extraction_distance: float = player.global_position.distance_to(target)
		if objective_label != null:
			objective_label.text = "RETURN TO VANGUARD LZ  //  %03d M" % int(extraction_distance)
		if extraction_distance <= 5.0:
			_complete_mission()

	if extraction_active and extraction_beacon != null:
		extraction_beacon.rotation.y += delta * 0.72
		var pulse: float = 1.0 + sin(mission_time * 3.6) * 0.07
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
	var world_environment: WorldEnvironment = WorldEnvironment.new()
	world_environment.name = "AsterAtmosphere"
	var environment: Environment = Environment.new()
	var sky_material: ProceduralSkyMaterial = ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color(0.07, 0.27, 0.58)
	sky_material.sky_horizon_color = Color(0.59, 0.79, 0.94)
	sky_material.ground_bottom_color = Color(0.035, 0.055, 0.065)
	sky_material.ground_horizon_color = Color(0.34, 0.45, 0.44)
	var sky: Sky = Sky.new()
	sky.sky_material = sky_material
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.ambient_light_color = Color(0.70, 0.78, 0.84)
	environment.ambient_light_energy = 0.86
	environment.fog_enabled = true
	environment.fog_light_color = Color(0.62, 0.74, 0.80)
	environment.fog_density = 0.0017
	environment.fog_sky_affect = 0.20
	world_environment.environment = environment
	add_child(world_environment)

	var sun: DirectionalLight3D = DirectionalLight3D.new()
	sun.name = "PrimarySun"
	sun.rotation_degrees = Vector3(-46.0, -31.0, 0.0)
	sun.light_color = Color(1.0, 0.92, 0.78)
	sun.light_energy = 1.72
	sun.shadow_enabled = true
	add_child(sun)

	var fill: DirectionalLight3D = DirectionalLight3D.new()
	fill.name = "SkyFill"
	fill.rotation_degrees = Vector3(-23.0, 148.0, 0.0)
	fill.light_color = Color(0.34, 0.53, 0.82)
	fill.light_energy = 0.27
	fill.shadow_enabled = false
	add_child(fill)


func _terrain_height_at(x: float, z: float) -> float:
	if terrain_noise == null or detail_noise == null:
		return 0.0

	var normalized_side: float = absf(x) / (TERRAIN_SIZE_X * 0.5)
	var side_rise: float = pow(clampf(normalized_side, 0.0, 1.10), 1.82) * 50.0
	var broad: float = terrain_noise.get_noise_2d(x, z) * 6.6
	var detail: float = detail_noise.get_noise_2d(x, z) * 1.6
	var north_rise: float = maxf(0.0, (-z - 94.0) / 74.0) * 9.0
	var river_channel: float = exp(-pow((x + 24.0) / 10.5, 2.0)) * 4.5
	var central_floor: float = exp(-pow(x / 38.0, 2.0)) * 2.0
	var spawn_flatten: float = exp(-((pow((x - 7.0) / 22.0, 2.0)) + pow((z - 104.0) / 22.0, 2.0))) * 3.0
	var outpost_flatten: float = exp(-((pow(x / 28.0, 2.0)) + pow((z + 108.0) / 24.0, 2.0))) * 4.0
	var height_value: float = side_rise + broad + detail + north_rise - river_channel - central_floor
	height_value -= spawn_flatten
	height_value -= outpost_flatten
	return clampf(height_value, -3.2, 58.0)


func _build_aster_valley() -> void:
	_build_terrain()
	_build_river()
	_build_forest()
	_build_boulder_field()
	_build_distant_mountains()
	_build_vanguard_landing_zone()
	_build_helix_outpost()
	_build_valley_bridge()
	_build_landmarks()


func _build_terrain() -> void:
	var vertices: PackedVector3Array = PackedVector3Array()
	var normals: PackedVector3Array = PackedVector3Array()
	var colors: PackedColorArray = PackedColorArray()
	var uvs: PackedVector2Array = PackedVector2Array()
	var indices: PackedInt32Array = PackedInt32Array()

	terrain_min_height = 99999.0
	terrain_max_height = -99999.0
	var cells: int = TERRAIN_RESOLUTION - 1
	var step_x: float = TERRAIN_SIZE_X / float(cells)
	var step_z: float = TERRAIN_SIZE_Z / float(cells)
	var half_x: float = TERRAIN_SIZE_X * 0.5
	var half_z: float = TERRAIN_SIZE_Z * 0.5

	for zi: int in range(TERRAIN_RESOLUTION):
		var z: float = -half_z + float(zi) * step_z
		for xi: int in range(TERRAIN_RESOLUTION):
			var x: float = -half_x + float(xi) * step_x
			var h: float = _terrain_height_at(x, z)
			terrain_min_height = minf(terrain_min_height, h)
			terrain_max_height = maxf(terrain_max_height, h)
			vertices.append(Vector3(x, h, z))

			var hx0: float = _terrain_height_at(x - step_x, z)
			var hx1: float = _terrain_height_at(x + step_x, z)
			var hz0: float = _terrain_height_at(x, z - step_z)
			var hz1: float = _terrain_height_at(x, z + step_z)
			var normal: Vector3 = Vector3(hx0 - hx1, step_x + step_z, hz0 - hz1).normalized()
			normals.append(normal)
			uvs.append(Vector2(float(xi) / float(cells), float(zi) / float(cells)) * 18.0)

			var slope: float = 1.0 - clampf(normal.y, 0.0, 1.0)
			var grass: Color = Color(0.20, 0.30, 0.14)
			var stone: Color = Color(0.34, 0.35, 0.32)
			var alpine: Color = Color(0.44, 0.43, 0.38)
			var terrain_color: Color = grass.lerp(stone, clampf(slope * 2.3, 0.0, 1.0))
			terrain_color = terrain_color.lerp(alpine, clampf((h - 24.0) / 28.0, 0.0, 0.75))
			colors.append(terrain_color)

	for zi: int in range(cells):
		for xi: int in range(cells):
			var a: int = zi * TERRAIN_RESOLUTION + xi
			var b: int = a + 1
			var c: int = a + TERRAIN_RESOLUTION
			var d: int = c + 1
			indices.append(a)
			indices.append(c)
			indices.append(b)
			indices.append(b)
			indices.append(c)
			indices.append(d)

	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices

	var terrain_mesh: ArrayMesh = ArrayMesh.new()
	terrain_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var terrain_material: StandardMaterial3D = StandardMaterial3D.new()
	terrain_material.vertex_color_use_as_albedo = true
	terrain_material.roughness = 0.94
	terrain_material.metallic = 0.0
	terrain_mesh.surface_set_material(0, terrain_material)

	var terrain_instance: MeshInstance3D = MeshInstance3D.new()
	terrain_instance.name = "AsterTerrain"
	terrain_instance.mesh = terrain_mesh
	add_child(terrain_instance)

	var terrain_body: StaticBody3D = StaticBody3D.new()
	terrain_body.name = "AsterTerrainCollision"
	var collision: CollisionShape3D = CollisionShape3D.new()
	var terrain_shape: ConcavePolygonShape3D = ConcavePolygonShape3D.new()
	terrain_shape.set_faces(terrain_mesh.get_faces())
	collision.shape = terrain_shape
	terrain_body.add_child(collision)
	add_child(terrain_body)


func _build_river() -> void:
	var river: MeshInstance3D = MeshInstance3D.new()
	var river_mesh: BoxMesh = BoxMesh.new()
	river_mesh.size = Vector3(17.0, 0.22, 270.0)
	river.mesh = river_mesh
	river.position = Vector3(-24.0, -2.4, -2.0)
	var water: StandardMaterial3D = StandardMaterial3D.new()
	water.albedo_color = Color(0.055, 0.28, 0.42, 0.82)
	water.metallic = 0.15
	water.roughness = 0.16
	water.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	water.emission_enabled = true
	water.emission = Color(0.025, 0.11, 0.16)
	water.emission_energy_multiplier = 0.55
	river.material_override = water
	add_child(river)


func _build_forest() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 20890419
	for i: int in range(105):
		var side: float = -1.0 if i % 2 == 0 else 1.0
		var x: float = side * rng.randf_range(34.0, 116.0)
		var z: float = rng.randf_range(-145.0, 135.0)
		if absf(z + 108.0) < 30.0 and absf(x) < 48.0:
			continue
		var y: float = _terrain_height_at(x, z)
		var scale_value: float = rng.randf_range(0.75, 1.65)
		_create_pine(Vector3(x, y, z), scale_value)


func _create_pine(world_position: Vector3, scale_value: float) -> void:
	var trunk: MeshInstance3D = MeshInstance3D.new()
	var trunk_mesh: CylinderMesh = CylinderMesh.new()
	trunk_mesh.top_radius = 0.12 * scale_value
	trunk_mesh.bottom_radius = 0.18 * scale_value
	trunk_mesh.height = 2.9 * scale_value
	trunk.mesh = trunk_mesh
	trunk.position = world_position + Vector3(0.0, 1.45 * scale_value, 0.0)
	trunk.material_override = _material(Color(0.20, 0.12, 0.065), 0.0, 0.95)
	add_child(trunk)

	var canopy: MeshInstance3D = MeshInstance3D.new()
	var canopy_mesh: CylinderMesh = CylinderMesh.new()
	canopy_mesh.top_radius = 0.0
	canopy_mesh.bottom_radius = 1.35 * scale_value
	canopy_mesh.height = 4.8 * scale_value
	canopy.mesh = canopy_mesh
	canopy.position = world_position + Vector3(0.0, 4.6 * scale_value, 0.0)
	canopy.material_override = _material(Color(0.08, 0.21, 0.11), 0.0, 0.92)
	add_child(canopy)


func _build_boulder_field() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 771190
	for i: int in range(58):
		var x: float = rng.randf_range(-118.0, 118.0)
		var z: float = rng.randf_range(-148.0, 145.0)
		if absf(x) < 16.0 and z > 65.0:
			continue
		var y: float = _terrain_height_at(x, z)
		var size_value: float = rng.randf_range(0.7, 2.8)
		_create_boulder(Vector3(x, y + size_value * 0.38, z), size_value, rng.randf_range(0.65, 1.35))


func _create_boulder(world_position: Vector3, size_value: float, squash: float) -> void:
	var rock: MeshInstance3D = MeshInstance3D.new()
	var mesh: SphereMesh = SphereMesh.new()
	mesh.radius = size_value
	mesh.height = size_value * 2.0
	mesh.radial_segments = 10
	mesh.rings = 6
	rock.mesh = mesh
	rock.position = world_position
	rock.scale = Vector3(1.0, 0.55 * squash, 0.78 + squash * 0.15)
	rock.rotation_degrees = Vector3(0.0, fmod(world_position.x * 7.0 + world_position.z * 3.0, 180.0), 0.0)
	rock.material_override = _material(Color(0.31, 0.31, 0.29), 0.0, 0.93)
	add_child(rock)


func _build_distant_mountains() -> void:
	for i: int in range(15):
		var side: float = -1.0 if i % 2 == 0 else 1.0
		var x: float = side * (132.0 + float((i * 13) % 55))
		var z: float = -150.0 + float((i * 29) % 310)
		var height: float = 42.0 + float((i * 17) % 44)
		var mountain: MeshInstance3D = MeshInstance3D.new()
		var mesh: SphereMesh = SphereMesh.new()
		mesh.radius = 18.0
		mesh.height = 36.0
		mesh.radial_segments = 12
		mesh.rings = 8
		mountain.mesh = mesh
		mountain.position = Vector3(x, height * 0.42, z)
		mountain.scale = Vector3(1.45, height / 36.0, 1.05)
		mountain.material_override = _material(Color(0.26, 0.28, 0.27), 0.0, 0.96)
		add_child(mountain)


func _build_vanguard_landing_zone() -> void:
	var center: Vector3 = _extraction_world_position()
	_create_static_box("LZ_Platform", center + Vector3(0.0, -0.45, 0.0), Vector3(22.0, 0.9, 18.0), Color(0.16, 0.19, 0.20), 0.58, 0.32)
	_create_neon_strip(center + Vector3(0.0, 0.03, -8.7), Vector3(17.0, 0.08, 0.08), cyan)
	_create_neon_strip(center + Vector3(0.0, 0.03, 8.7), Vector3(17.0, 0.08, 0.08), cyan)
	_create_neon_strip(center + Vector3(-10.7, 0.03, 0.0), Vector3(0.08, 0.08, 13.5), cyan)
	_create_neon_strip(center + Vector3(10.7, 0.03, 0.0), Vector3(0.08, 0.08, 13.5), cyan)

	for side: float in [-1.0, 1.0]:
		var tower_pos: Vector3 = center + Vector3(8.0 * side, 4.1, -5.0)
		_create_static_box("LZ_Tower", tower_pos, Vector3(1.5, 8.0, 1.5), Color(0.13, 0.16, 0.17), 0.72, 0.28)
		_create_neon_strip(tower_pos + Vector3(0.0, 0.0, -0.78), Vector3(0.25, 5.2, 0.05), cyan)


func _build_helix_outpost() -> void:
	var base_z: float = -108.0
	var ground_y: float = _terrain_height_at(0.0, base_z)
	_create_static_box("HELIX_Base", Vector3(0.0, ground_y + 0.65, base_z), Vector3(42.0, 1.3, 30.0), Color(0.11, 0.115, 0.12), 0.72, 0.28)
	_create_static_box("HELIX_Bunker", Vector3(0.0, ground_y + 5.2, base_z - 6.0), Vector3(18.0, 9.0, 12.0), Color(0.13, 0.135, 0.14), 0.78, 0.24)
	_create_neon_strip(Vector3(0.0, ground_y + 5.4, base_z + 0.05), Vector3(11.0, 0.22, 0.08), orange)

	for side: float in [-1.0, 1.0]:
		var tower_x: float = 15.0 * side
		var tower_ground: float = _terrain_height_at(tower_x, base_z - 6.0)
		_create_static_box("HELIX_Tower", Vector3(tower_x, tower_ground + 7.0, base_z - 6.0), Vector3(4.2, 14.0, 4.2), Color(0.09, 0.095, 0.105), 0.76, 0.25)
		_create_neon_strip(Vector3(tower_x, tower_ground + 7.0, base_z - 8.15), Vector3(0.34, 8.0, 0.07), orange)

	_create_static_box("HELIX_GateLeft", Vector3(-8.0, ground_y + 3.0, base_z + 14.0), Vector3(3.0, 6.0, 2.2), Color(0.10, 0.105, 0.11), 0.78, 0.22)
	_create_static_box("HELIX_GateRight", Vector3(8.0, ground_y + 3.0, base_z + 14.0), Vector3(3.0, 6.0, 2.2), Color(0.10, 0.105, 0.11), 0.78, 0.22)
	_create_static_box("HELIX_GateTop", Vector3(0.0, ground_y + 6.4, base_z + 14.0), Vector3(19.0, 1.3, 2.2), Color(0.10, 0.105, 0.11), 0.78, 0.22)
	_create_neon_strip(Vector3(0.0, ground_y + 5.75, base_z + 12.85), Vector3(12.0, 0.16, 0.06), orange)

	for i: int in range(8):
		var side: float = -1.0 if i % 2 == 0 else 1.0
		var x: float = side * (5.0 + float((i * 3) % 9))
		var z: float = base_z + 28.0 + float((i % 4) * 8)
		var y: float = _terrain_height_at(x, z)
		_create_static_box("HELIX_Barricade", Vector3(x, y + 0.65, z), Vector3(4.0, 1.3, 1.0), Color(0.17, 0.15, 0.13), 0.66, 0.36)


func _build_valley_bridge() -> void:
	var bridge_z: float = -12.0
	var bridge_y: float = maxf(_terrain_height_at(-34.0, bridge_z), _terrain_height_at(-12.0, bridge_z)) + 2.8
	_create_static_box("RiverBridge", Vector3(-24.0, bridge_y, bridge_z), Vector3(28.0, 1.2, 8.0), Color(0.15, 0.17, 0.18), 0.70, 0.30)
	_create_neon_strip(Vector3(-24.0, bridge_y + 0.63, bridge_z - 3.95), Vector3(23.0, 0.08, 0.08), cyan)
	_create_neon_strip(Vector3(-24.0, bridge_y + 0.63, bridge_z + 3.95), Vector3(23.0, 0.08, 0.08), cyan)


func _build_landmarks() -> void:
	var landmark_z: float = -150.0
	var landmark_y: float = _terrain_height_at(0.0, landmark_z)
	_create_visual_box(Vector3(-13.0, landmark_y + 23.0, landmark_z), Vector3(6.0, 46.0, 7.0), Color(0.20, 0.23, 0.24), 0.68, 0.30, Vector3(0.0, 0.0, -7.0))
	_create_visual_box(Vector3(13.0, landmark_y + 23.0, landmark_z), Vector3(6.0, 46.0, 7.0), Color(0.20, 0.23, 0.24), 0.68, 0.30, Vector3(0.0, 0.0, 7.0))
	_create_visual_box(Vector3(0.0, landmark_y + 43.0, landmark_z), Vector3(32.0, 5.0, 7.0), Color(0.18, 0.21, 0.23), 0.70, 0.27)
	_create_neon_strip(Vector3(0.0, landmark_y + 40.1, landmark_z + 3.55), Vector3(18.0, 0.20, 0.06), orange)

	for i: int in range(9):
		var x: float = -62.0 + float(i) * 14.0
		var z: float = -185.0 - float((i * 7) % 22)
		var height: float = 10.0 + float((i * 11) % 24)
		_create_visual_box(Vector3(x, height * 0.5, z), Vector3(7.0, height, 7.0), Color(0.15, 0.18, 0.20), 0.52, 0.46)


func _spawn_player() -> void:
	player = CharacterBody3D.new()
	player.name = "Vanguard_01"
	player.set_script(PLAYER_AST)
	var start: Vector3 = _extraction_world_position()
	player.position = start + Vector3(0.0, 1.10, -2.0)
	add_child(player)


func _spawn_enemies() -> void:
	var soldier_data: Array = [
		[Vector3(-7.0, 0.0, 56.0), "scout"],
		[Vector3(10.0, 0.0, 35.0), "rifleman"],
		[Vector3(-13.0, 0.0, 14.0), "rifleman"],
		[Vector3(13.0, 0.0, -24.0), "scout"],
		[Vector3(-10.0, 0.0, -58.0), "rifleman"],
		[Vector3(8.0, 0.0, -84.0), "heavy"],
		[Vector3(-8.0, 0.0, -106.0), "rifleman"],
		[Vector3(7.0, 0.0, -118.0), "commander"]
	]

	for i: int in range(soldier_data.size()):
		var raw_position: Vector3 = soldier_data[i][0] as Vector3
		var enemy_type: String = String(soldier_data[i][1])
		var enemy: CharacterBody3D = CharacterBody3D.new()
		enemy.name = "HELIX_%02d" % (i + 1)
		enemy.set_script(ENEMY_AST)
		enemy.set("unit_type", enemy_type)
		enemy.set("target", player)
		enemy.position = Vector3(raw_position.x, _terrain_height_at(raw_position.x, raw_position.z) + 1.15, raw_position.z)
		add_child(enemy)

	var drone_positions: Array[Vector3] = [
		Vector3(-18.0, 0.0, -42.0),
		Vector3(18.0, 0.0, -92.0),
		Vector3(0.0, 0.0, -126.0)
	]
	for i: int in range(drone_positions.size()):
		var p: Vector3 = drone_positions[i]
		var drone: CharacterBody3D = CharacterBody3D.new()
		drone.name = "HELIX_Drone_%02d" % (i + 1)
		drone.set_script(DRONE_AST)
		drone.set("target", player)
		drone.position = Vector3(p.x, _terrain_height_at(p.x, p.z) + 6.0, p.z)
		add_child(drone)

	total_enemies = soldier_data.size() + drone_positions.size()


func _build_extraction_beacon() -> void:
	extraction_beacon = Node3D.new()
	extraction_beacon.name = "AsterExtractionBeacon"
	extraction_beacon.position = _extraction_world_position()

	var ring: MeshInstance3D = MeshInstance3D.new()
	var ring_mesh: CylinderMesh = CylinderMesh.new()
	ring_mesh.top_radius = 3.4
	ring_mesh.bottom_radius = 3.4
	ring_mesh.height = 0.08
	ring.mesh = ring_mesh
	ring.position.y = 0.10
	ring.material_override = _emissive_material(Color(0.03, 0.70, 1.0), 3.0)
	extraction_beacon.add_child(ring)

	var beam: MeshInstance3D = MeshInstance3D.new()
	var beam_mesh: CylinderMesh = CylinderMesh.new()
	beam_mesh.top_radius = 0.28
	beam_mesh.bottom_radius = 0.28
	beam_mesh.height = 8.0
	beam.mesh = beam_mesh
	beam.position.y = 4.0
	var beam_material: StandardMaterial3D = _emissive_material(Color(0.04, 0.58, 1.0, 0.34), 2.2)
	beam_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	beam.material_override = beam_material
	extraction_beacon.add_child(beam)

	extraction_beacon.visible = false
	add_child(extraction_beacon)


func _build_mission_header(root: Control) -> void:
	var header: Panel = Panel.new()
	header.anchor_left = 0.5
	header.anchor_right = 0.5
	header.offset_left = -290.0
	header.offset_top = 24.0
	header.offset_right = 290.0
	header.offset_bottom = 116.0
	header.add_theme_stylebox_override("panel", _panel_style(Color(0.012, 0.028, 0.042, 0.80), Color(cyan.r, cyan.g, cyan.b, 0.25), 1))
	root.add_child(header)

	var chapter: Label = Label.new()
	chapter.text = "OPERATION 01 // ASTER VALLEY"
	chapter.position = Vector2(20.0, 10.0)
	chapter.size = Vector2(540.0, 22.0)
	chapter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chapter.add_theme_font_size_override("font_size", 12)
	chapter.add_theme_color_override("font_color", cyan)
	header.add_child(chapter)

	objective_label = Label.new()
	objective_label.text = "BREACH HELIX OCCUPATION ZONE"
	objective_label.position = Vector2(20.0, 34.0)
	objective_label.size = Vector2(540.0, 27.0)
	objective_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	objective_label.add_theme_font_size_override("font_size", 18)
	objective_label.add_theme_color_override("font_color", pale)
	header.add_child(objective_label)

	hostiles_label = Label.new()
	hostiles_label.text = "HOSTILES  00 / 00"
	hostiles_label.position = Vector2(20.0, 64.0)
	hostiles_label.size = Vector2(540.0, 18.0)
	hostiles_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hostiles_label.add_theme_font_size_override("font_size", 11)
	hostiles_label.add_theme_color_override("font_color", orange)
	header.add_child(hostiles_label)

	status_label = Label.new()
	status_label.anchor_left = 0.5
	status_label.anchor_top = 1.0
	status_label.anchor_right = 0.5
	status_label.anchor_bottom = 1.0
	status_label.offset_left = -360.0
	status_label.offset_top = -80.0
	status_label.offset_right = 360.0
	status_label.offset_bottom = -44.0
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 15)
	status_label.add_theme_color_override("font_color", Color(0.70, 0.84, 0.92))
	status_label.text = "NEXUS: VANGUARD LZ SECURE // ADVANCE NORTH"
	root.add_child(status_label)


func _show_mission_intro() -> void:
	if status_label == null:
		return
	status_label.text = "NEXUS: ASTER VALLEY // HELIX FORTRESS 200 METERS NORTH"
	var timer: SceneTreeTimer = get_tree().create_timer(3.3)
	timer.timeout.connect(func() -> void:
		if not game_finished and status_label != null:
			status_label.text = "NEXUS: USE ROCK, FOREST AND ELEVATION FOR COVER"
	)


func _activate_extraction() -> void:
	extraction_active = true
	if extraction_beacon != null:
		extraction_beacon.visible = true
	if objective_label != null:
		objective_label.text = "RETURN TO VANGUARD LZ"
	if status_label != null:
		status_label.text = "NEXUS: HELIX FORCE COLLAPSED // EXTRACTION ONLINE"
		status_label.add_theme_color_override("font_color", Color(0.32, 1.0, 0.72))


func _complete_mission() -> void:
	if game_finished:
		return
	game_finished = true
	if status_label != null:
		status_label.text = "MISSION COMPLETE // ASTER VALLEY SECURED"
		status_label.add_theme_color_override("font_color", Color(0.34, 1.0, 0.70))
	if objective_label != null:
		objective_label.text = "VANGUARD EXTRACTED"
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var timer: SceneTreeTimer = get_tree().create_timer(4.0)
	timer.timeout.connect(_return_to_command)


func _extraction_world_position() -> Vector3:
	return Vector3(EXTRACTION_POINT.x, _terrain_height_at(EXTRACTION_POINT.x, EXTRACTION_POINT.z) + 0.45, EXTRACTION_POINT.z)
