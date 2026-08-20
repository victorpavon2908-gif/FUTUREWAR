extends Node3D

const TERRAIN_SHADER: Shader = preload("res://shaders/terrain_master.gdshader")
const RIVER_SHADER: Shader = preload("res://shaders/terrain_river.gdshader")
const TERRAIN_PLAYER: Script = preload("res://scripts/terrain_player.gd")

const MAP_SIZE: float = 340.0
const TERRAIN_RESOLUTION: int = 145
const HALF_MAP: float = MAP_SIZE * 0.5
const RIVER_LEVEL: float = 2.75

var broad_noise: FastNoiseLite
var detail_noise: FastNoiseLite
var ridge_noise: FastNoiseLite
var player: CharacterBody3D
var last_safe_position: Vector3 = Vector3.ZERO
var rescue_timer: float = 0.0


func _ready() -> void:
	_configure_input()
	_setup_noise()
	_build_environment()
	_build_master_terrain()
	_build_river()
	_build_rock_fields()
	_build_pine_groves()
	_build_perimeter_safety()
	_spawn_player()


func _process(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	rescue_timer += delta
	if rescue_timer > 0.35:
		rescue_timer = 0.0
		if player.is_on_floor() and player.global_position.y > 0.5:
			last_safe_position = player.global_position
	if player.global_position.y < -3.0:
		player.global_position = last_safe_position + Vector3(0.0, 1.0, 0.0)
		player.velocity = Vector3.ZERO


func _configure_input() -> void:
	_ensure_key_action("move_forward", KEY_W)
	_ensure_key_action("move_back", KEY_S)
	_ensure_key_action("move_left", KEY_A)
	_ensure_key_action("move_right", KEY_D)
	_ensure_key_action("sprint", KEY_SHIFT)
	_ensure_key_action("jump", KEY_SPACE)


func _ensure_key_action(action_name: StringName, keycode: Key) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	if InputMap.action_get_events(action_name).is_empty():
		var event: InputEventKey = InputEventKey.new()
		event.physical_keycode = keycode
		InputMap.action_add_event(action_name, event)


func _setup_noise() -> void:
	broad_noise = FastNoiseLite.new()
	broad_noise.seed = 721104
	broad_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	broad_noise.frequency = 0.0085
	broad_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	broad_noise.fractal_octaves = 5
	broad_noise.fractal_gain = 0.48

	detail_noise = FastNoiseLite.new()
	detail_noise.seed = 19827
	detail_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	detail_noise.frequency = 0.032
	detail_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	detail_noise.fractal_octaves = 3
	detail_noise.fractal_gain = 0.42

	ridge_noise = FastNoiseLite.new()
	ridge_noise.seed = 550991
	ridge_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	ridge_noise.frequency = 0.017


func _build_environment() -> void:
	var world_environment: WorldEnvironment = WorldEnvironment.new()
	world_environment.name = "TerrainMasterAtmosphere"
	var environment: Environment = Environment.new()
	var sky_material: ProceduralSkyMaterial = ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color(0.055, 0.25, 0.52)
	sky_material.sky_horizon_color = Color(0.62, 0.82, 0.95)
	sky_material.ground_bottom_color = Color(0.025, 0.055, 0.065)
	sky_material.ground_horizon_color = Color(0.32, 0.48, 0.42)
	sky_material.sun_angle_max = 10.0
	sky_material.sun_curve = 0.08
	var sky: Sky = Sky.new()
	sky.sky_material = sky_material
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.ambient_light_color = Color(0.72, 0.80, 0.82)
	environment.ambient_light_energy = 0.80
	environment.fog_enabled = true
	environment.fog_light_color = Color(0.62, 0.76, 0.78)
	environment.fog_density = 0.00115
	environment.fog_sky_affect = 0.12
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.adjustment_enabled = true
	environment.adjustment_brightness = 1.03
	environment.adjustment_contrast = 1.08
	environment.adjustment_saturation = 0.96
	world_environment.environment = environment
	add_child(world_environment)

	var sun: DirectionalLight3D = DirectionalLight3D.new()
	sun.name = "TerrainSun"
	sun.rotation_degrees = Vector3(-46.0, 30.0, 0.0)
	sun.light_color = Color(1.0, 0.92, 0.77)
	sun.light_energy = 1.62
	sun.shadow_enabled = true
	add_child(sun)

	var fill: DirectionalLight3D = DirectionalLight3D.new()
	fill.name = "TerrainSkyFill"
	fill.rotation_degrees = Vector3(-20.0, -145.0, 0.0)
	fill.light_color = Color(0.27, 0.48, 0.72)
	fill.light_energy = 0.22
	fill.shadow_enabled = false
	add_child(fill)


func _terrain_height_at(x: float, z: float) -> float:
	if broad_noise == null or detail_noise == null or ridge_noise == null:
		return 5.0

	var edge_norm: float = maxf(absf(x), absf(z)) / HALF_MAP
	var edge_t: float = clampf((edge_norm - 0.64) / 0.36, 0.0, 1.0)
	edge_t = edge_t * edge_t * (3.0 - 2.0 * edge_t)

	var broad: float = broad_noise.get_noise_2d(x, z) * 4.8
	var detail: float = detail_noise.get_noise_2d(x, z) * 0.95
	var rugged: float = absf(ridge_noise.get_noise_2d(x, z)) * 2.4

	var west_wall: float = exp(-(pow((x + 112.0) / 39.0, 2.0) + pow((z + 4.0) / 118.0, 2.0))) * 15.0
	var east_wall: float = exp(-(pow((x - 114.0) / 42.0, 2.0) + pow((z - 8.0) / 120.0, 2.0))) * 14.5
	var north_wall: float = exp(-(pow(x / 105.0, 2.0) + pow((z + 132.0) / 34.0, 2.0))) * 16.0

	var hero_west: float = exp(-(pow((x + 82.0) / 24.0, 2.0) + pow((z + 72.0) / 28.0, 2.0))) * 17.0
	var hero_east: float = exp(-(pow((x - 78.0) / 25.0, 2.0) + pow((z + 60.0) / 31.0, 2.0))) * 15.0
	var shelf_west: float = exp(-(pow((x + 72.0) / 34.0, 2.0) + pow((z - 48.0) / 42.0, 2.0))) * 7.0
	var shelf_east: float = exp(-(pow((x - 76.0) / 36.0, 2.0) + pow((z - 36.0) / 44.0, 2.0))) * 6.5

	var valley: float = exp(-pow(x / 70.0, 2.0)) * 3.4
	var base_height: float = 7.2 + broad + detail + rugged + edge_t * 26.0
	var height_value: float = base_height + west_wall + east_wall + north_wall + hero_west + hero_east + shelf_west + shelf_east - valley

	var river_center: float = sin(z * 0.021) * 13.0 + sin(z * 0.049) * 4.5
	var river_distance: float = absf(x - river_center)
	var river_mask: float = exp(-pow(river_distance / 9.5, 2.0)) * clampf(1.0 - absf(z) / 165.0, 0.0, 1.0)
	var river_bed: float = 2.15 + detail_noise.get_noise_2d(x * 1.7, z * 1.7) * 0.22
	height_value = lerpf(height_value, river_bed, river_mask * 0.92)

	var south_spawn_mask: float = exp(-(pow(x / 34.0, 2.0) + pow((z - 132.0) / 24.0, 2.0)))
	var spawn_height: float = 6.4 + detail_noise.get_noise_2d(x, z) * 0.28
	height_value = lerpf(height_value, spawn_height, south_spawn_mask * 0.88)

	var center_basin: float = exp(-(pow(x / 50.0, 2.0) + pow((z + 10.0) / 52.0, 2.0)))
	height_value = lerpf(height_value, 5.2 + broad * 0.22, center_basin * 0.28)

	return clampf(height_value, 2.05, 52.0)


func _build_master_terrain() -> void:
	var vertices: PackedVector3Array = PackedVector3Array()
	var normals: PackedVector3Array = PackedVector3Array()
	var colors: PackedColorArray = PackedColorArray()
	var indices: PackedInt32Array = PackedInt32Array()
	var cells: int = TERRAIN_RESOLUTION - 1
	var step: float = MAP_SIZE / float(cells)

	for zi: int in range(TERRAIN_RESOLUTION):
		var z: float = -HALF_MAP + float(zi) * step
		for xi: int in range(TERRAIN_RESOLUTION):
			var x: float = -HALF_MAP + float(xi) * step
			var height_value: float = _terrain_height_at(x, z)
			vertices.append(Vector3(x, height_value, z))

			var hx0: float = _terrain_height_at(x - step, z)
			var hx1: float = _terrain_height_at(x + step, z)
			var hz0: float = _terrain_height_at(x, z - step)
			var hz1: float = _terrain_height_at(x, z + step)
			var normal: Vector3 = Vector3(hx0 - hx1, step * 2.0, hz0 - hz1).normalized()
			normals.append(normal)

			var slope: float = 1.0 - clampf(normal.y, 0.0, 1.0)
			var low_factor: float = 1.0 - clampf((height_value - 3.0) / 4.5, 0.0, 1.0)
			var high_factor: float = clampf((height_value - 20.0) / 22.0, 0.0, 1.0)
			var grass: Color = Color(0.16, 0.29, 0.105)
			var meadow: Color = Color(0.22, 0.36, 0.13)
			var rock: Color = Color(0.31, 0.32, 0.30)
			var dark_rock: Color = Color(0.20, 0.22, 0.21)
			var river_bank: Color = Color(0.36, 0.34, 0.23)
			var tint: Color = grass.lerp(meadow, clampf(1.0 - slope * 1.7, 0.0, 1.0) * 0.45)
			tint = tint.lerp(rock, clampf(slope * 2.35, 0.0, 1.0))
			tint = tint.lerp(dark_rock, high_factor * 0.70)
			tint = tint.lerp(river_bank, low_factor * 0.72)
			colors.append(tint)

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
	arrays[Mesh.ARRAY_INDEX] = indices

	var mesh: ArrayMesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = TERRAIN_SHADER
	mesh.surface_set_material(0, material)

	var terrain: MeshInstance3D = MeshInstance3D.new()
	terrain.name = "MASTER_CONTINUOUS_TERRAIN"
	terrain.mesh = mesh
	add_child(terrain)

	var body: StaticBody3D = StaticBody3D.new()
	body.name = "MASTER_CONTINUOUS_TERRAIN_COLLISION"
	var collision: CollisionShape3D = CollisionShape3D.new()
	var shape: ConcavePolygonShape3D = ConcavePolygonShape3D.new()
	shape.set_faces(mesh.get_faces())
	collision.shape = shape
	body.add_child(collision)
	add_child(body)


func _river_center_at(z: float) -> float:
	return sin(z * 0.021) * 13.0 + sin(z * 0.049) * 4.5


func _build_river() -> void:
	var water_material: ShaderMaterial = ShaderMaterial.new()
	water_material.shader = RIVER_SHADER
	var segment_length: float = 34.0
	var z: float = -136.0
	while z < 136.0:
		var z_next: float = minf(z + segment_length, 136.0)
		var x0: float = _river_center_at(z)
		var x1: float = _river_center_at(z_next)
		var center: Vector3 = Vector3((x0 + x1) * 0.5, RIVER_LEVEL, (z + z_next) * 0.5)
		var dx: float = x1 - x0
		var dz: float = z_next - z
		var yaw: float = atan2(dx, dz)
		var plane: MeshInstance3D = MeshInstance3D.new()
		var mesh: PlaneMesh = PlaneMesh.new()
		mesh.size = Vector2(15.5, Vector2(dx, dz).length() + 2.0)
		mesh.subdivide_width = 6
		mesh.subdivide_depth = 10
		plane.mesh = mesh
		plane.position = center
		plane.rotation.y = yaw
		plane.material_override = water_material
		add_child(plane)
		z = z_next


func _build_rock_fields() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 445102
	for i: int in range(46):
		var x: float = rng.randf_range(-145.0, 145.0)
		var z: float = rng.randf_range(-145.0, 145.0)
		var river_distance: float = absf(x - _river_center_at(z))
		if river_distance < 14.0:
			continue
		var y: float = _terrain_height_at(x, z)
		if y < 5.0 or y > 37.0:
			continue
		var size_value: Vector3 = Vector3(rng.randf_range(2.5, 7.0), rng.randf_range(2.2, 6.5), rng.randf_range(2.5, 7.0))
		_create_rock(Vector3(x, y + size_value.y * 0.22, z), size_value, 900 + i)


func _create_rock(center: Vector3, size_value: Vector3, seed_value: int) -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value
	var mesh: SphereMesh = SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	mesh.radial_segments = 7
	mesh.rings = 4
	var rock: MeshInstance3D = MeshInstance3D.new()
	rock.mesh = mesh
	rock.position = center
	rock.scale = size_value
	rock.rotation_degrees = Vector3(rng.randf_range(-18.0, 18.0), rng.randf_range(0.0, 180.0), rng.randf_range(-16.0, 16.0))
	var material: StandardMaterial3D = StandardMaterial3D.new()
	var shade: float = rng.randf_range(-0.04, 0.04)
	material.albedo_color = Color(0.26 + shade, 0.27 + shade, 0.25 + shade)
	material.roughness = 0.98
	rock.material_override = material
	add_child(rock)


func _build_pine_groves() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 87113
	for i: int in range(58):
		var x: float = rng.randf_range(-150.0, 150.0)
		var z: float = rng.randf_range(-150.0, 150.0)
		var y: float = _terrain_height_at(x, z)
		if y < 7.0 or y > 31.0:
			continue
		if absf(x - _river_center_at(z)) < 18.0:
			continue
		_create_pine(Vector3(x, y, z), rng.randf_range(0.85, 1.55), i)


func _create_pine(position_value: Vector3, scale_value: float, index: int) -> void:
	var trunk_material: StandardMaterial3D = StandardMaterial3D.new()
	trunk_material.albedo_color = Color(0.15, 0.085, 0.045)
	trunk_material.roughness = 0.98
	var leaf_material: StandardMaterial3D = StandardMaterial3D.new()
	var shade: float = float(index % 5) * 0.008
	leaf_material.albedo_color = Color(0.055 + shade, 0.13 + shade, 0.07 + shade)
	leaf_material.roughness = 0.96

	var trunk: MeshInstance3D = MeshInstance3D.new()
	var trunk_mesh: CylinderMesh = CylinderMesh.new()
	trunk_mesh.top_radius = 0.08 * scale_value
	trunk_mesh.bottom_radius = 0.17 * scale_value
	trunk_mesh.height = 3.0 * scale_value
	trunk_mesh.radial_segments = 7
	trunk.mesh = trunk_mesh
	trunk.position = position_value + Vector3(0.0, 1.5 * scale_value, 0.0)
	trunk.material_override = trunk_material
	add_child(trunk)

	for layer: int in range(4):
		var canopy: MeshInstance3D = MeshInstance3D.new()
		var canopy_mesh: CylinderMesh = CylinderMesh.new()
		var radius: float = (1.38 - float(layer) * 0.20) * scale_value
		canopy_mesh.top_radius = radius * 0.10
		canopy_mesh.bottom_radius = radius
		canopy_mesh.height = 1.75 * scale_value
		canopy_mesh.radial_segments = 9
		canopy.mesh = canopy_mesh
		canopy.position = position_value + Vector3(0.0, (3.0 + float(layer) * 0.92) * scale_value, 0.0)
		canopy.rotation_degrees.y = float((index * 31 + layer * 17) % 120)
		canopy.material_override = leaf_material
		add_child(canopy)


func _build_perimeter_safety() -> void:
	var wall_height: float = 70.0
	var wall_thickness: float = 2.0
	var wall_length: float = MAP_SIZE + 8.0
	_create_invisible_wall(Vector3(-HALF_MAP - 1.0, wall_height * 0.5, 0.0), Vector3(wall_thickness, wall_height, wall_length))
	_create_invisible_wall(Vector3(HALF_MAP + 1.0, wall_height * 0.5, 0.0), Vector3(wall_thickness, wall_height, wall_length))
	_create_invisible_wall(Vector3(0.0, wall_height * 0.5, -HALF_MAP - 1.0), Vector3(wall_length, wall_height, wall_thickness))
	_create_invisible_wall(Vector3(0.0, wall_height * 0.5, HALF_MAP + 1.0), Vector3(wall_length, wall_height, wall_thickness))

	var catch_body: StaticBody3D = StaticBody3D.new()
	catch_body.name = "TerrainEmergencyCatch"
	catch_body.position = Vector3(0.0, -2.5, 0.0)
	var catch_collision: CollisionShape3D = CollisionShape3D.new()
	var catch_shape: BoxShape3D = BoxShape3D.new()
	catch_shape.size = Vector3(MAP_SIZE + 20.0, 0.8, MAP_SIZE + 20.0)
	catch_collision.shape = catch_shape
	catch_body.add_child(catch_collision)
	add_child(catch_body)


func _create_invisible_wall(position_value: Vector3, size_value: Vector3) -> void:
	var body: StaticBody3D = StaticBody3D.new()
	body.position = position_value
	var collision: CollisionShape3D = CollisionShape3D.new()
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = size_value
	collision.shape = shape
	body.add_child(collision)
	add_child(body)


func _spawn_player() -> void:
	player = CharacterBody3D.new()
	player.name = "TerrainSurveyPlayer"
	player.set_script(TERRAIN_PLAYER)
	var spawn: Vector3 = Vector3(0.0, 0.0, 132.0)
	spawn.y = _terrain_height_at(spawn.x, spawn.z) + 1.2
	player.position = spawn
	last_safe_position = spawn
	add_child(player)
