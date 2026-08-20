extends "res://scripts/main_v2.gd"

const PLAYER_CF: Script = preload("res://scripts/player_v2.gd")
const ENEMY_CF: Script = preload("res://scripts/enemy_v2.gd")
const DRONE_CF: Script = preload("res://scripts/drone.gd")

const ISLAND_SIZE: float = 230.0
const TERRAIN_RESOLUTION: int = 97
const OCEAN_LEVEL: float = 0.15
const PLATFORM_Y: float = 12.0
const EXTRACTION_POINT: Vector3 = Vector3(0.0, 0.0, 78.0)

var coast_noise: FastNoiseLite
var detail_noise_cf: FastNoiseLite


func _ready() -> void:
	_configure_input()
	_setup_noise_cf()
	_build_environment()
	_build_coastline_fortress()
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
			objective_label.text = "RETURN TO SOUTHERN LZ  //  %03d M" % int(extraction_distance)
		if extraction_distance <= 5.5:
			_complete_mission()

	if extraction_active and extraction_beacon != null:
		extraction_beacon.rotation.y += delta * 0.8
		var pulse: float = 1.0 + sin(mission_time * 4.0) * 0.075
		extraction_beacon.scale = Vector3(pulse, 1.0, pulse)


func _setup_noise_cf() -> void:
	coast_noise = FastNoiseLite.new()
	coast_noise.seed = 31877
	coast_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	coast_noise.frequency = 0.012
	coast_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	coast_noise.fractal_octaves = 5
	coast_noise.fractal_gain = 0.46

	detail_noise_cf = FastNoiseLite.new()
	detail_noise_cf.seed = 9031
	detail_noise_cf.noise_type = FastNoiseLite.TYPE_PERLIN
	detail_noise_cf.frequency = 0.045
	detail_noise_cf.fractal_type = FastNoiseLite.FRACTAL_FBM
	detail_noise_cf.fractal_octaves = 3
	detail_noise_cf.fractal_gain = 0.42


func _build_environment() -> void:
	var world_environment: WorldEnvironment = WorldEnvironment.new()
	world_environment.name = "CoastAtmosphere"
	var environment: Environment = Environment.new()
	var sky_material: ProceduralSkyMaterial = ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color(0.055, 0.28, 0.62)
	sky_material.sky_horizon_color = Color(0.62, 0.82, 0.96)
	sky_material.ground_bottom_color = Color(0.025, 0.09, 0.13)
	sky_material.ground_horizon_color = Color(0.34, 0.57, 0.62)
	var sky: Sky = Sky.new()
	sky.sky_material = sky_material
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.ambient_light_energy = 0.92
	environment.fog_enabled = true
	environment.fog_light_color = Color(0.58, 0.76, 0.83)
	environment.fog_density = 0.0011
	environment.fog_sky_affect = 0.16
	world_environment.environment = environment
	add_child(world_environment)

	var sun: DirectionalLight3D = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48.0, 32.0, 0.0)
	sun.light_color = Color(1.0, 0.94, 0.82)
	sun.light_energy = 1.85
	sun.shadow_enabled = true
	add_child(sun)

	var fill: DirectionalLight3D = DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-20.0, -145.0, 0.0)
	fill.light_color = Color(0.30, 0.50, 0.78)
	fill.light_energy = 0.22
	fill.shadow_enabled = false
	add_child(fill)


func _terrain_height_at(x: float, z: float) -> float:
	if coast_noise == null or detail_noise_cf == null:
		return 0.0

	var nx: float = x / 106.0
	var nz: float = z / 112.0
	var radial: float = sqrt(nx * nx + nz * nz)
	var coast_band: float = clampf((1.02 - radial) * 7.6, 0.0, 1.0)
	var core_height: float = -6.5 + coast_band * 15.5
	var broad: float = coast_noise.get_noise_2d(x, z) * 3.8 * coast_band
	var detail: float = detail_noise_cf.get_noise_2d(x, z) * 1.15 * coast_band

	# Natural shoulders make the island read as a rocky bowl from the ocean.
	var west_mass: float = exp(-(pow((x + 58.0) / 30.0, 2.0) + pow((z + 2.0) / 54.0, 2.0))) * 10.0
	var east_mass: float = exp(-(pow((x - 57.0) / 32.0, 2.0) + pow((z - 10.0) / 48.0, 2.0))) * 9.0
	var north_mass: float = exp(-(pow(x / 48.0, 2.0) + pow((z + 74.0) / 34.0, 2.0))) * 7.5

	# The command fortress spans a lagoon carved into the middle of the island.
	var lagoon: float = exp(-(pow(x / 31.0, 2.0) + pow((z + 9.0) / 28.0, 2.0))) * 13.0
	var south_route: float = exp(-(pow(x / 18.0, 2.0) + pow((z - 57.0) / 42.0, 2.0))) * 1.8

	var height_value: float = core_height + broad + detail + west_mass + east_mass + north_mass - lagoon - south_route
	return clampf(height_value, -7.0, 27.0)


func _build_coastline_fortress() -> void:
	_build_ocean()
	_build_island_terrain()
	_build_cliff_language()
	_build_tree_clusters()
	_build_command_platforms()
	_build_radial_bridges()
	_build_side_batteries()
	_build_northern_monolith()
	_build_southern_landing_zone()
	_build_horizon_structures()


func _build_ocean() -> void:
	var ocean: MeshInstance3D = MeshInstance3D.new()
	var mesh: PlaneMesh = PlaneMesh.new()
	mesh.size = Vector2(760.0, 760.0)
	ocean.mesh = mesh
	ocean.position = Vector3(0.0, OCEAN_LEVEL, 0.0)
	var water: StandardMaterial3D = StandardMaterial3D.new()
	water.albedo_color = Color(0.025, 0.20, 0.33, 0.93)
	water.metallic = 0.18
	water.roughness = 0.12
	water.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	water.emission_enabled = true
	water.emission = Color(0.012, 0.055, 0.085)
	water.emission_energy_multiplier = 0.35
	ocean.material_override = water
	add_child(ocean)


func _build_island_terrain() -> void:
	var vertices: PackedVector3Array = PackedVector3Array()
	var normals: PackedVector3Array = PackedVector3Array()
	var colors: PackedColorArray = PackedColorArray()
	var indices: PackedInt32Array = PackedInt32Array()
	var cells: int = TERRAIN_RESOLUTION - 1
	var step: float = ISLAND_SIZE / float(cells)
	var half: float = ISLAND_SIZE * 0.5

	for zi: int in range(TERRAIN_RESOLUTION):
		var z: float = -half + float(zi) * step
		for xi: int in range(TERRAIN_RESOLUTION):
			var x: float = -half + float(xi) * step
			var h: float = _terrain_height_at(x, z)
			vertices.append(Vector3(x, h, z))
			var hx0: float = _terrain_height_at(x - step, z)
			var hx1: float = _terrain_height_at(x + step, z)
			var hz0: float = _terrain_height_at(x, z - step)
			var hz1: float = _terrain_height_at(x, z + step)
			var normal: Vector3 = Vector3(hx0 - hx1, step * 2.0, hz0 - hz1).normalized()
			normals.append(normal)

			var slope: float = 1.0 - clampf(normal.y, 0.0, 1.0)
			var beach_factor: float = 1.0 - clampf((h - 0.8) / 4.0, 0.0, 1.0)
			var grass: Color = Color(0.17, 0.31, 0.12)
			var rock: Color = Color(0.32, 0.33, 0.31)
			var sand: Color = Color(0.48, 0.43, 0.30)
			var c: Color = grass.lerp(rock, clampf(slope * 2.1, 0.0, 1.0))
			c = c.lerp(sand, beach_factor * 0.72)
			colors.append(c)

	for zi: int in range(cells):
		for xi: int in range(cells):
			var a: int = zi * TERRAIN_RESOLUTION + xi
			var b: int = a + 1
			var c: int = a + TERRAIN_RESOLUTION
			var d: int = c + 1
			indices.append(a); indices.append(c); indices.append(b)
			indices.append(b); indices.append(c); indices.append(d)

	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	var island_mesh: ArrayMesh = ArrayMesh.new()
	island_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.95
	island_mesh.surface_set_material(0, mat)

	var instance: MeshInstance3D = MeshInstance3D.new()
	instance.name = "CoastlineIsland"
	instance.mesh = island_mesh
	add_child(instance)

	var body: StaticBody3D = StaticBody3D.new()
	body.name = "CoastlineIslandCollision"
	var collision: CollisionShape3D = CollisionShape3D.new()
	var shape: ConcavePolygonShape3D = ConcavePolygonShape3D.new()
	shape.set_faces(island_mesh.get_faces())
	collision.shape = shape
	body.add_child(collision)
	add_child(body)


func _build_cliff_language() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 4402
	for i: int in range(44):
		var angle: float = TAU * float(i) / 44.0 + rng.randf_range(-0.045, 0.045)
		var radius: float = rng.randf_range(88.0, 105.0)
		var x: float = cos(angle) * radius
		var z: float = sin(angle) * radius
		var ground: float = _terrain_height_at(x, z)
		var height: float = rng.randf_range(5.0, 15.0)
		var width: float = rng.randf_range(5.5, 12.0)
		_create_visual_box(Vector3(x, ground + height * 0.25, z), Vector3(width, height, rng.randf_range(4.0, 9.0)), Color(0.29, 0.30, 0.29), 0.0, 0.96, Vector3(rng.randf_range(-8.0, 8.0), rad_to_deg(-angle), rng.randf_range(-7.0, 7.0)))

	# A few large angular cliff masses replace the previous spherical mountain blobs.
	var masses: Array = [
		[Vector3(-76.0, 18.0, -18.0), Vector3(32.0, 31.0, 42.0), Vector3(-5.0, 18.0, 8.0)],
		[Vector3(78.0, 17.0, 5.0), Vector3(36.0, 29.0, 39.0), Vector3(7.0, -21.0, -7.0)],
		[Vector3(-57.0, 18.0, -74.0), Vector3(27.0, 28.0, 35.0), Vector3(4.0, 34.0, 6.0)],
		[Vector3(58.0, 19.0, -73.0), Vector3(29.0, 30.0, 33.0), Vector3(-6.0, -30.0, -5.0)]
	]
	for item: Array in masses:
		_create_visual_box(item[0] as Vector3, item[1] as Vector3, Color(0.30, 0.31, 0.30), 0.0, 0.97, item[2] as Vector3)


func _build_tree_clusters() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 99741
	for i: int in range(76):
		var angle: float = rng.randf_range(0.0, TAU)
		var radius: float = rng.randf_range(55.0, 92.0)
		var x: float = cos(angle) * radius
		var z: float = sin(angle) * radius
		if z > 52.0 and absf(x) < 25.0:
			continue
		var y: float = _terrain_height_at(x, z)
		if y < 2.5:
			continue
		_create_pine(Vector3(x, y, z), rng.randf_range(0.8, 1.45))


func _create_pine(world_position: Vector3, scale_value: float) -> void:
	var trunk: MeshInstance3D = MeshInstance3D.new()
	var trunk_mesh: CylinderMesh = CylinderMesh.new()
	trunk_mesh.top_radius = 0.10 * scale_value
	trunk_mesh.bottom_radius = 0.16 * scale_value
	trunk_mesh.height = 2.5 * scale_value
	trunk.mesh = trunk_mesh
	trunk.position = world_position + Vector3(0.0, 1.25 * scale_value, 0.0)
	trunk.material_override = _material(Color(0.17, 0.10, 0.05), 0.0, 0.95)
	add_child(trunk)

	for layer: int in range(3):
		var canopy: MeshInstance3D = MeshInstance3D.new()
		var canopy_mesh: CylinderMesh = CylinderMesh.new()
		canopy_mesh.top_radius = 0.0
		canopy_mesh.bottom_radius = (1.25 - float(layer) * 0.18) * scale_value
		canopy_mesh.height = 2.4 * scale_value
		canopy.mesh = canopy_mesh
		canopy.position = world_position + Vector3(0.0, (3.0 + float(layer) * 1.15) * scale_value, 0.0)
		canopy.material_override = _material(Color(0.065, 0.19 + float(layer) * 0.01, 0.09), 0.0, 0.94)
		add_child(canopy)


func _build_command_platforms() -> void:
	_create_round_platform("CommandCore", Vector3(0.0, PLATFORM_Y, -10.0), 17.5, 1.4, Color(0.13, 0.15, 0.16), orange)
	_create_round_platform("WestPad", Vector3(-39.0, PLATFORM_Y - 0.8, -12.0), 10.5, 1.2, Color(0.13, 0.15, 0.16), orange)
	_create_round_platform("EastPad", Vector3(39.0, PLATFORM_Y - 0.8, -12.0), 10.5, 1.2, Color(0.13, 0.15, 0.16), orange)
	_create_round_platform("NorthPad", Vector3(0.0, PLATFORM_Y + 0.8, -50.0), 11.5, 1.3, Color(0.12, 0.14, 0.15), orange)

	# Central command drum and surrounding ribs.
	var drum: StaticBody3D = StaticBody3D.new()
	drum.position = Vector3(0.0, PLATFORM_Y + 4.0, -10.0)
	var drum_collision: CollisionShape3D = CollisionShape3D.new()
	var drum_shape: CylinderShape3D = CylinderShape3D.new()
	drum_shape.radius = 6.0
	drum_shape.height = 7.0
	drum_collision.shape = drum_shape
	drum.add_child(drum_collision)
	var drum_mesh_instance: MeshInstance3D = MeshInstance3D.new()
	var drum_mesh: CylinderMesh = CylinderMesh.new()
	drum_mesh.top_radius = 6.0
	drum_mesh.bottom_radius = 6.0
	drum_mesh.height = 7.0
	drum_mesh_instance.mesh = drum_mesh
	drum_mesh_instance.material_override = _material(Color(0.085, 0.095, 0.105), 0.82, 0.24)
	drum.add_child(drum_mesh_instance)
	add_child(drum)

	var crown: MeshInstance3D = MeshInstance3D.new()
	var crown_mesh: CylinderMesh = CylinderMesh.new()
	crown_mesh.top_radius = 8.5
	crown_mesh.bottom_radius = 6.4
	crown_mesh.height = 1.0
	crown.mesh = crown_mesh
	crown.position = Vector3(0.0, PLATFORM_Y + 7.8, -10.0)
	crown.material_override = _material(Color(0.15, 0.17, 0.18), 0.78, 0.27)
	add_child(crown)

	for i: int in range(12):
		var angle: float = TAU * float(i) / 12.0
		var light_pos: Vector3 = Vector3(cos(angle) * 7.0, PLATFORM_Y + 4.0, -10.0 + sin(angle) * 7.0)
		var p: MeshInstance3D = MeshInstance3D.new()
		var pm: SphereMesh = SphereMesh.new()
		pm.radius = 0.18
		pm.height = 0.36
		p.mesh = pm
		p.position = light_pos
		p.material_override = _emissive_material(orange, 4.0)
		add_child(p)


func _create_round_platform(node_name: String, center: Vector3, radius: float, thickness: float, color: Color, glow: Color) -> void:
	var body: StaticBody3D = StaticBody3D.new()
	body.name = node_name
	body.position = center
	var collision: CollisionShape3D = CollisionShape3D.new()
	var shape: CylinderShape3D = CylinderShape3D.new()
	shape.radius = radius
	shape.height = thickness
	collision.shape = shape
	body.add_child(collision)
	var mesh_instance: MeshInstance3D = MeshInstance3D.new()
	var mesh: CylinderMesh = CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = thickness
	mesh.radial_segments = 32
	mesh_instance.mesh = mesh
	mesh_instance.material_override = _material(color, 0.72, 0.30)
	body.add_child(mesh_instance)
	add_child(body)

	var ring: MeshInstance3D = MeshInstance3D.new()
	var ring_mesh: TorusMesh = TorusMesh.new()
	ring_mesh.inner_radius = radius - 0.32
	ring_mesh.outer_radius = radius
	ring.mesh = ring_mesh
	ring.position = center + Vector3(0.0, thickness * 0.53, 0.0)
	ring.material_override = _emissive_material(glow, 2.7)
	add_child(ring)


func _build_radial_bridges() -> void:
	_create_bridge(Vector3(-27.0, PLATFORM_Y - 0.35, -11.0), Vector3(19.0, 0.8, 6.0), 0.0)
	_create_bridge(Vector3(27.0, PLATFORM_Y - 0.35, -11.0), Vector3(19.0, 0.8, 6.0), 0.0)
	_create_bridge(Vector3(0.0, PLATFORM_Y + 0.05, -31.0), Vector3(6.0, 0.8, 24.0), 0.0)
	_create_bridge(Vector3(0.0, PLATFORM_Y - 0.9, 18.0), Vector3(7.0, 0.8, 43.0), 0.0)

	# Sloped assault ramp from the natural south shelf to the elevated bridge system.
	_create_static_box_rotated("SouthAssaultRamp", Vector3(0.0, 9.0, 45.0), Vector3(9.0, 1.0, 26.0), Color(0.14, 0.16, 0.17), 0.70, 0.31, Vector3(-9.0, 0.0, 0.0))


func _create_bridge(center: Vector3, size: Vector3, yaw: float) -> void:
	_create_static_box_rotated("FortressBridge", center, size, Color(0.14, 0.16, 0.17), 0.72, 0.29, Vector3(0.0, yaw, 0.0))
	var long_axis_z: bool = size.z > size.x
	if long_axis_z:
		_create_neon_strip(center + Vector3(-size.x * 0.48, size.y * 0.56, 0.0), Vector3(0.08, 0.07, size.z * 0.93), orange)
		_create_neon_strip(center + Vector3(size.x * 0.48, size.y * 0.56, 0.0), Vector3(0.08, 0.07, size.z * 0.93), orange)
	else:
		_create_neon_strip(center + Vector3(0.0, size.y * 0.56, -size.z * 0.48), Vector3(size.x * 0.93, 0.07, 0.08), orange)
		_create_neon_strip(center + Vector3(0.0, size.y * 0.56, size.z * 0.48), Vector3(size.x * 0.93, 0.07, 0.08), orange)


func _create_static_box_rotated(node_name: String, center: Vector3, size: Vector3, color: Color, metallic: float, roughness: float, rotation_value: Vector3) -> void:
	var body: StaticBody3D = StaticBody3D.new()
	body.name = node_name
	body.position = center
	body.rotation_degrees = rotation_value
	var collision: CollisionShape3D = CollisionShape3D.new()
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	var mesh_instance: MeshInstance3D = MeshInstance3D.new()
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.material_override = _material(color, metallic, roughness)
	body.add_child(mesh_instance)
	add_child(body)


func _build_side_batteries() -> void:
	for side: float in [-1.0, 1.0]:
		var x: float = 39.0 * side
		_create_static_box("BatterySpine", Vector3(x, PLATFORM_Y + 3.1, -12.0), Vector3(3.4, 6.0, 3.4), Color(0.09, 0.10, 0.11), 0.80, 0.24)
		_create_static_box_rotated("BatteryWing", Vector3(x + 5.8 * side, PLATFORM_Y + 2.2, -12.0), Vector3(10.0, 1.8, 4.0), Color(0.12, 0.14, 0.15), 0.76, 0.27, Vector3(0.0, 0.0, 12.0 * side))
		_create_neon_strip(Vector3(x, PLATFORM_Y + 3.2, -13.76), Vector3(0.22, 3.7, 0.06), orange)


func _build_northern_monolith() -> void:
	var base_z: float = -75.0
	var base_y: float = maxf(_terrain_height_at(-14.0, base_z), _terrain_height_at(14.0, base_z))
	for side: float in [-1.0, 1.0]:
		_create_static_box_rotated("NorthMonolith", Vector3(14.0 * side, base_y + 18.0, base_z), Vector3(7.0, 36.0, 9.0), Color(0.11, 0.12, 0.13), 0.82, 0.23, Vector3(0.0, 0.0, 7.0 * side))
		_create_neon_strip(Vector3(14.0 * side, base_y + 18.0, base_z + 4.55), Vector3(0.30, 22.0, 0.06), orange)
	_create_static_box("NorthCrown", Vector3(0.0, base_y + 32.0, base_z), Vector3(35.0, 4.0, 9.0), Color(0.13, 0.15, 0.16), 0.78, 0.26)


func _build_southern_landing_zone() -> void:
	var p: Vector3 = _extraction_world_position()
	_create_round_platform("VanguardLZ", p + Vector3(0.0, -0.25, 0.0), 9.0, 0.7, Color(0.14, 0.17, 0.18), cyan)
	for side: float in [-1.0, 1.0]:
		_create_static_box("LZBeacon", p + Vector3(7.0 * side, 3.2, -2.0), Vector3(1.1, 6.0, 1.1), Color(0.11, 0.14, 0.15), 0.70, 0.31)
		_create_neon_strip(p + Vector3(7.0 * side, 3.2, -2.56), Vector3(0.18, 4.0, 0.05), cyan)


func _build_horizon_structures() -> void:
	# Distant non-colliding silhouettes sell a larger military complex beyond the playable island.
	for i: int in range(10):
		var angle: float = -0.9 + float(i) * 0.18
		var radius: float = 185.0 + float((i * 11) % 30)
		var x: float = cos(angle) * radius
		var z: float = -absf(sin(angle) * radius) - 70.0
		var height: float = 18.0 + float((i * 13) % 42)
		_create_visual_box(Vector3(x, height * 0.45, z), Vector3(7.0 + float(i % 3) * 3.0, height, 9.0), Color(0.12, 0.16, 0.18), 0.48, 0.48, Vector3(0.0, float(i * 17), 0.0))


func _spawn_player() -> void:
	player = CharacterBody3D.new()
	player.name = "Vanguard_01"
	player.set_script(PLAYER_CF)
	player.position = _extraction_world_position() + Vector3(0.0, 1.15, -2.0)
	add_child(player)


func _spawn_enemies() -> void:
	var terrain_units: Array = [
		[Vector3(-18.0, 0.0, 52.0), "scout"],
		[Vector3(18.0, 0.0, 47.0), "rifleman"],
		[Vector3(-28.0, 0.0, 24.0), "rifleman"]
	]
	for i: int in range(terrain_units.size()):
		var raw: Vector3 = terrain_units[i][0] as Vector3
		_spawn_soldier(Vector3(raw.x, _terrain_height_at(raw.x, raw.z) + 1.15, raw.z), String(terrain_units[i][1]), i)

	var platform_units: Array = [
		[Vector3(0.0, PLATFORM_Y + 1.15, 15.0), "rifleman"],
		[Vector3(-34.0, PLATFORM_Y + 0.35, -12.0), "scout"],
		[Vector3(34.0, PLATFORM_Y + 0.35, -12.0), "rifleman"],
		[Vector3(-7.0, PLATFORM_Y + 1.15, -10.0), "heavy"],
		[Vector3(7.0, PLATFORM_Y + 1.15, -10.0), "rifleman"],
		[Vector3(0.0, PLATFORM_Y + 1.95, -49.0), "commander"]
	]
	for j: int in range(platform_units.size()):
		_spawn_soldier(platform_units[j][0] as Vector3, String(platform_units[j][1]), j + terrain_units.size())

	var drone_positions: Array[Vector3] = [
		Vector3(-28.0, PLATFORM_Y + 10.0, -10.0),
		Vector3(28.0, PLATFORM_Y + 11.0, -18.0),
		Vector3(0.0, PLATFORM_Y + 13.0, -58.0)
	]
	for k: int in range(drone_positions.size()):
		var drone: CharacterBody3D = CharacterBody3D.new()
		drone.name = "HELIX_Drone_%02d" % (k + 1)
		drone.set_script(DRONE_CF)
		drone.set("target", player)
		drone.position = drone_positions[k]
		add_child(drone)

	total_enemies = terrain_units.size() + platform_units.size() + drone_positions.size()


func _spawn_soldier(world_position: Vector3, unit_type: String, index: int) -> void:
	var enemy: CharacterBody3D = CharacterBody3D.new()
	enemy.name = "HELIX_CF_%02d" % (index + 1)
	enemy.set_script(ENEMY_CF)
	enemy.set("unit_type", unit_type)
	enemy.set("target", player)
	enemy.position = world_position
	add_child(enemy)


func _build_extraction_beacon() -> void:
	extraction_beacon = Node3D.new()
	extraction_beacon.name = "CoastExtraction"
	extraction_beacon.position = _extraction_world_position()
	var ring: MeshInstance3D = MeshInstance3D.new()
	var rm: TorusMesh = TorusMesh.new()
	rm.inner_radius = 3.2
	rm.outer_radius = 3.7
	ring.mesh = rm
	ring.material_override = _emissive_material(cyan, 3.3)
	extraction_beacon.add_child(ring)
	var beam: MeshInstance3D = MeshInstance3D.new()
	var bm: CylinderMesh = CylinderMesh.new()
	bm.top_radius = 0.25
	bm.bottom_radius = 0.45
	bm.height = 8.0
	beam.mesh = bm
	beam.position.y = 4.0
	beam.material_override = _emissive_material(Color(0.05, 0.62, 1.0, 0.42), 2.1)
	extraction_beacon.add_child(beam)
	extraction_beacon.visible = false
	add_child(extraction_beacon)


func _extraction_world_position() -> Vector3:
	return Vector3(EXTRACTION_POINT.x, _terrain_height_at(EXTRACTION_POINT.x, EXTRACTION_POINT.z) + 0.55, EXTRACTION_POINT.z)


func _build_mission_header(root: Control) -> void:
	super._build_mission_header(root)
	var header: Panel = objective_label.get_parent() as Panel
	if header != null:
		var labels: Array[Node] = header.get_children()
		for child: Node in labels:
			if child is Label and (child as Label).text.begins_with("OPERATION"):
				(child as Label).text = "OPERATION 02 // COASTLINE FORTRESS"
	objective_label.text = "BREACH THE HELIX COMMAND PLATFORM"


func _show_mission_intro() -> void:
	status_label.text = "NEXUS: OCEAN PERIMETER SECURE // ASSAULT BRIDGE 70 METERS NORTH"
	var timer: SceneTreeTimer = get_tree().create_timer(3.4)
	timer.timeout.connect(func() -> void:
		if not game_finished and status_label != null:
			status_label.text = "NEXUS: USE CLIFF SHELVES AND RADIAL BRIDGES TO BREAK THE FORTRESS"
	)


func _activate_extraction() -> void:
	extraction_active = true
	extraction_beacon.visible = true
	objective_label.text = "RETURN TO SOUTHERN LZ"
	status_label.text = "NEXUS: FORTRESS NETWORK OFFLINE // EXTRACTION ACTIVE"
	status_label.add_theme_color_override("font_color", Color(0.32, 1.0, 0.72))


func _complete_mission() -> void:
	if game_finished:
		return
	game_finished = true
	status_label.text = "MISSION COMPLETE // COASTLINE FORTRESS SILENCED"
	status_label.add_theme_color_override("font_color", Color(0.34, 1.0, 0.70))
	objective_label.text = "VANGUARD EXTRACTED"
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var timer: SceneTreeTimer = get_tree().create_timer(4.0)
	timer.timeout.connect(_return_to_command)
