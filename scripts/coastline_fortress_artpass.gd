extends "res://scripts/coastline_fortress.gd"

const TERRAIN_SHADER = preload("res://shaders/coast_terrain.gdshader")
const WATER_SHADER = preload("res://shaders/coast_water.gdshader")

var steel_dark: Color = Color(0.055, 0.072, 0.082)
var steel_mid: Color = Color(0.11, 0.135, 0.145)
var steel_light: Color = Color(0.20, 0.23, 0.235)
var cliff_dark: Color = Color(0.18, 0.19, 0.18)
var cliff_mid: Color = Color(0.29, 0.30, 0.285)
var foliage_dark: Color = Color(0.055, 0.115, 0.07)
var foliage_mid: Color = Color(0.075, 0.165, 0.095)


func _build_environment() -> void:
	var world_environment: WorldEnvironment = WorldEnvironment.new()
	world_environment.name = "CoastProductionAtmosphere"
	var environment: Environment = Environment.new()
	var sky_material: ProceduralSkyMaterial = ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color(0.045, 0.205, 0.46)
	sky_material.sky_horizon_color = Color(0.55, 0.77, 0.91)
	sky_material.ground_bottom_color = Color(0.018, 0.052, 0.07)
	sky_material.ground_horizon_color = Color(0.29, 0.43, 0.43)
	sky_material.sun_angle_max = 18.0
	sky_material.sun_curve = 0.09
	var sky: Sky = Sky.new()
	sky.sky_material = sky_material
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.ambient_light_color = Color(0.70, 0.79, 0.84)
	environment.ambient_light_energy = 0.82
	environment.fog_enabled = true
	environment.fog_light_color = Color(0.58, 0.72, 0.78)
	environment.fog_density = 0.0017
	environment.fog_sky_affect = 0.14
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.adjustment_enabled = true
	environment.adjustment_brightness = 1.03
	environment.adjustment_contrast = 1.08
	environment.adjustment_saturation = 0.94
	world_environment.environment = environment
	add_child(world_environment)

	var sun: DirectionalLight3D = DirectionalLight3D.new()
	sun.name = "CoastalSun"
	sun.rotation_degrees = Vector3(-49.0, 28.0, 0.0)
	sun.light_color = Color(1.0, 0.91, 0.76)
	sun.light_energy = 1.58
	sun.shadow_enabled = true
	add_child(sun)

	var fill: DirectionalLight3D = DirectionalLight3D.new()
	fill.name = "OceanFill"
	fill.rotation_degrees = Vector3(-18.0, -150.0, 0.0)
	fill.light_color = Color(0.26, 0.47, 0.73)
	fill.light_energy = 0.29
	fill.shadow_enabled = false
	add_child(fill)


func _build_ocean() -> void:
	var ocean: MeshInstance3D = MeshInstance3D.new()
	ocean.name = "ProductionOcean"
	var mesh: PlaneMesh = PlaneMesh.new()
	mesh.size = Vector2(900.0, 900.0)
	mesh.subdivide_width = 10
	mesh.subdivide_depth = 10
	ocean.mesh = mesh
	ocean.position = Vector3(0.0, OCEAN_LEVEL, 0.0)
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = WATER_SHADER
	ocean.material_override = material
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
			var height_value: float = _terrain_height_at(x, z)
			vertices.append(Vector3(x, height_value, z))
			var hx0: float = _terrain_height_at(x - step, z)
			var hx1: float = _terrain_height_at(x + step, z)
			var hz0: float = _terrain_height_at(x, z - step)
			var hz1: float = _terrain_height_at(x, z + step)
			var normal: Vector3 = Vector3(hx0 - hx1, step * 2.0, hz0 - hz1).normalized()
			normals.append(normal)

			var slope: float = 1.0 - clampf(normal.y, 0.0, 1.0)
			var beach_factor: float = 1.0 - clampf((height_value - 1.2) / 4.2, 0.0, 1.0)
			var high_factor: float = clampf((height_value - 11.0) / 15.0, 0.0, 1.0)
			var grass: Color = Color(0.15, 0.255, 0.105)
			var rock: Color = Color(0.31, 0.315, 0.30)
			var sand: Color = Color(0.43, 0.38, 0.27)
			var high_rock: Color = Color(0.26, 0.27, 0.265)
			var tint: Color = grass.lerp(rock, clampf(slope * 2.25, 0.0, 1.0))
			tint = tint.lerp(sand, beach_factor * 0.62)
			tint = tint.lerp(high_rock, high_factor * 0.42)
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
	var island_mesh: ArrayMesh = ArrayMesh.new()
	island_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var terrain_material: ShaderMaterial = ShaderMaterial.new()
	terrain_material.shader = TERRAIN_SHADER
	island_mesh.surface_set_material(0, terrain_material)

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
	rng.seed = 912001
	for i: int in range(34):
		var angle: float = TAU * float(i) / 34.0 + rng.randf_range(-0.075, 0.075)
		var radius: float = rng.randf_range(88.0, 107.0)
		var x: float = cos(angle) * radius
		var z: float = sin(angle) * radius
		var ground: float = _terrain_height_at(x, z)
		var scale_value: Vector3 = Vector3(rng.randf_range(6.0, 13.0), rng.randf_range(8.0, 20.0), rng.randf_range(6.0, 15.0))
		_create_rock_chunk(Vector3(x, ground + scale_value.y * 0.20, z), scale_value, i * 197 + 31)

	var hero_rocks: Array = [
		[Vector3(-73.0, 18.0, -20.0), Vector3(30.0, 34.0, 36.0), 401],
		[Vector3(76.0, 18.0, 3.0), Vector3(34.0, 31.0, 40.0), 402],
		[Vector3(-57.0, 19.0, -77.0), Vector3(26.0, 31.0, 33.0), 403],
		[Vector3(60.0, 20.0, -72.0), Vector3(29.0, 34.0, 31.0), 404],
		[Vector3(-90.0, 13.0, 47.0), Vector3(25.0, 23.0, 29.0), 405],
		[Vector3(93.0, 14.0, 50.0), Vector3(28.0, 25.0, 30.0), 406]
	]
	for item: Array in hero_rocks:
		_create_rock_chunk(item[0] as Vector3, item[1] as Vector3, int(item[2]))


func _create_rock_chunk(center: Vector3, size_value: Vector3, seed_value: int) -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value
	var top_scale: float = rng.randf_range(0.56, 0.82)
	var skew_x: float = rng.randf_range(-0.18, 0.18) * size_value.x
	var skew_z: float = rng.randf_range(-0.18, 0.18) * size_value.z
	var hx: float = size_value.x * 0.5
	var hz: float = size_value.z * 0.5
	var y0: float = -size_value.y * 0.5
	var y1: float = size_value.y * 0.5

	var points: Array[Vector3] = [
		Vector3(-hx, y0, -hz), Vector3(hx, y0, -hz), Vector3(hx, y0, hz), Vector3(-hx, y0, hz),
		Vector3(-hx * top_scale + skew_x, y1, -hz * top_scale + skew_z),
		Vector3(hx * top_scale + skew_x, y1, -hz * top_scale + skew_z),
		Vector3(hx * top_scale + skew_x, y1, hz * top_scale + skew_z),
		Vector3(-hx * top_scale + skew_x, y1, hz * top_scale + skew_z)
	]
	var triangles: Array[PackedInt32Array] = [
		PackedInt32Array([0, 2, 1]), PackedInt32Array([0, 3, 2]),
		PackedInt32Array([4, 5, 6]), PackedInt32Array([4, 6, 7]),
		PackedInt32Array([0, 1, 5]), PackedInt32Array([0, 5, 4]),
		PackedInt32Array([1, 2, 6]), PackedInt32Array([1, 6, 5]),
		PackedInt32Array([2, 3, 7]), PackedInt32Array([2, 7, 6]),
		PackedInt32Array([3, 0, 4]), PackedInt32Array([3, 4, 7])
	]
	var surface: SurfaceTool = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for face: PackedInt32Array in triangles:
		for point_index: int in face:
			surface.add_vertex(points[point_index])
	surface.generate_normals()
	var mesh: ArrayMesh = surface.commit()
	var rock: MeshInstance3D = MeshInstance3D.new()
	rock.mesh = mesh
	rock.position = center
	rock.rotation_degrees = Vector3(rng.randf_range(-7.0, 7.0), rng.randf_range(0.0, 180.0), rng.randf_range(-6.0, 6.0))
	var shade: float = rng.randf_range(-0.035, 0.035)
	rock.material_override = _material(cliff_mid + Color(shade, shade, shade), 0.0, 0.97)
	add_child(rock)


func _build_tree_clusters() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 99741
	for i: int in range(56):
		var angle: float = rng.randf_range(0.0, TAU)
		var radius: float = rng.randf_range(54.0, 90.0)
		var x: float = cos(angle) * radius
		var z: float = sin(angle) * radius
		if z > 50.0 and absf(x) < 26.0:
			continue
		var y: float = _terrain_height_at(x, z)
		if y < 3.0:
			continue
		_create_pine_art(Vector3(x, y, z), rng.randf_range(0.80, 1.50), i)


func _create_pine_art(world_position: Vector3, scale_value: float, index: int) -> void:
	var trunk: MeshInstance3D = MeshInstance3D.new()
	var trunk_mesh: CylinderMesh = CylinderMesh.new()
	trunk_mesh.top_radius = 0.075 * scale_value
	trunk_mesh.bottom_radius = 0.18 * scale_value
	trunk_mesh.height = 3.2 * scale_value
	trunk_mesh.radial_segments = 7
	trunk.mesh = trunk_mesh
	trunk.position = world_position + Vector3(0.0, 1.6 * scale_value, 0.0)
	trunk.material_override = _material(Color(0.15, 0.085, 0.045), 0.0, 0.98)
	add_child(trunk)

	for layer: int in range(5):
		var canopy: MeshInstance3D = MeshInstance3D.new()
		var canopy_mesh: CylinderMesh = CylinderMesh.new()
		var layer_radius: float = (1.42 - float(layer) * 0.19) * scale_value
		canopy_mesh.top_radius = layer_radius * 0.12
		canopy_mesh.bottom_radius = layer_radius
		canopy_mesh.height = 1.65 * scale_value
		canopy_mesh.radial_segments = 8
		canopy.mesh = canopy_mesh
		canopy.position = world_position + Vector3(0.0, (3.35 + float(layer) * 0.93) * scale_value, 0.0)
		canopy.rotation_degrees.y = float((index * 37 + layer * 19) % 120)
		var layer_color: Color = foliage_dark.lerp(foliage_mid, float(layer) / 5.0)
		canopy.material_override = _material(layer_color, 0.0, 0.96)
		add_child(canopy)


func _build_command_platforms() -> void:
	_create_round_platform("CommandCore", Vector3(0.0, PLATFORM_Y, -10.0), 18.8, 1.5, steel_mid, orange)
	_create_round_platform("WestPad", Vector3(-39.0, PLATFORM_Y - 0.8, -12.0), 11.0, 1.2, steel_mid, orange)
	_create_round_platform("EastPad", Vector3(39.0, PLATFORM_Y - 0.8, -12.0), 11.0, 1.2, steel_mid, orange)
	_create_round_platform("NorthPad", Vector3(0.0, PLATFORM_Y + 0.8, -50.0), 12.0, 1.3, steel_mid, orange)

	# Layered command hub: broad pedestal, tapered command drum, roof ring, reactor core.
	_create_cylinder_static("CorePedestal", Vector3(0.0, PLATFORM_Y + 1.2, -10.0), 11.8, 2.2, steel_dark, 0.78, 0.26, 16)
	_create_cylinder_static("CoreDrum", Vector3(0.0, PLATFORM_Y + 5.4, -10.0), 7.2, 6.2, Color(0.075, 0.085, 0.095), 0.84, 0.22, 16)
	_create_cylinder_visual(Vector3(0.0, PLATFORM_Y + 9.2, -10.0), 9.6, 1.2, steel_light, 0.72, 0.27, 16)
	_create_cylinder_visual(Vector3(0.0, PLATFORM_Y + 10.2, -10.0), 5.3, 0.9, steel_dark, 0.80, 0.23, 14)

	var reactor: MeshInstance3D = MeshInstance3D.new()
	var reactor_mesh: CylinderMesh = CylinderMesh.new()
	reactor_mesh.top_radius = 1.15
	reactor_mesh.bottom_radius = 1.55
	reactor_mesh.height = 7.4
	reactor_mesh.radial_segments = 12
	reactor.mesh = reactor_mesh
	reactor.position = Vector3(0.0, PLATFORM_Y + 6.0, -10.0)
	reactor.material_override = _emissive_material(Color(1.0, 0.16, 0.035), 3.8)
	add_child(reactor)

	var roof_ring: MeshInstance3D = MeshInstance3D.new()
	var ring_mesh: TorusMesh = TorusMesh.new()
	ring_mesh.inner_radius = 8.5
	ring_mesh.outer_radius = 9.3
	ring_mesh.rings = 32
	ring_mesh.ring_segments = 10
	roof_ring.mesh = ring_mesh
	roof_ring.position = Vector3(0.0, PLATFORM_Y + 9.7, -10.0)
	roof_ring.material_override = _material(steel_light, 0.77, 0.25)
	add_child(roof_ring)

	for i: int in range(8):
		var angle: float = TAU * float(i) / 8.0
		var side_pos: Vector3 = Vector3(cos(angle) * 12.8, PLATFORM_Y + 4.0, -10.0 + sin(angle) * 12.8)
		var yaw: float = -rad_to_deg(angle) + 90.0
		_create_static_box_rotated("CoreButtress", side_pos, Vector3(2.0, 7.0, 7.5), steel_dark, 0.78, 0.25, Vector3(-7.0, yaw, 0.0))
		var strip_pos: Vector3 = side_pos + Vector3(0.0, 1.2, 0.0)
		_create_neon_strip(strip_pos, Vector3(0.22, 3.4, 0.08), orange)

	for i: int in range(16):
		var angle: float = TAU * float(i) / 16.0
		var p: MeshInstance3D = MeshInstance3D.new()
		var pm: BoxMesh = BoxMesh.new()
		pm.size = Vector3(0.22, 0.22, 0.55)
		p.mesh = pm
		p.position = Vector3(cos(angle) * 17.0, PLATFORM_Y + 1.0, -10.0 + sin(angle) * 17.0)
		p.rotation_degrees.y = -rad_to_deg(angle)
		p.material_override = _emissive_material(orange, 3.5)
		add_child(p)


func _build_radial_bridges() -> void:
	_create_bridge_art(Vector3(-28.0, PLATFORM_Y - 0.30, -11.0), Vector3(20.0, 1.0, 6.5), false)
	_create_bridge_art(Vector3(28.0, PLATFORM_Y - 0.30, -11.0), Vector3(20.0, 1.0, 6.5), false)
	_create_bridge_art(Vector3(0.0, PLATFORM_Y + 0.05, -31.0), Vector3(6.5, 1.0, 24.0), true)
	_create_bridge_art(Vector3(0.0, PLATFORM_Y - 0.75, 18.0), Vector3(7.5, 1.0, 43.0), true)
	_create_static_box_rotated("SouthAssaultRamp", Vector3(0.0, 8.9, 45.0), Vector3(10.0, 1.1, 27.0), steel_mid, 0.72, 0.30, Vector3(-9.0, 0.0, 0.0))
	for side: float in [-1.0, 1.0]:
		_create_visual_box(Vector3(4.4 * side, 10.5, 45.0), Vector3(0.38, 2.2, 26.0), steel_light, 0.65, 0.32, Vector3(-9.0, 0.0, 0.0))


func _create_bridge_art(center: Vector3, size_value: Vector3, long_axis_z: bool) -> void:
	_create_static_box("FortressBridge", center, size_value, steel_mid, 0.72, 0.29)
	var length_value: float = size_value.z if long_axis_z else size_value.x
	var post_count: int = maxi(4, int(length_value / 4.0))
	for i: int in range(post_count + 1):
		var t: float = float(i) / float(post_count)
		if long_axis_z:
			var z: float = center.z - size_value.z * 0.46 + t * size_value.z * 0.92
			for side: float in [-1.0, 1.0]:
				_create_visual_box(Vector3(center.x + side * size_value.x * 0.47, center.y + 1.05, z), Vector3(0.16, 1.8, 0.16), steel_light, 0.64, 0.36)
			_create_neon_strip(Vector3(center.x - size_value.x * 0.49, center.y + 0.60, z), Vector3(0.08, 0.06, 0.50), orange)
		else:
			var x: float = center.x - size_value.x * 0.46 + t * size_value.x * 0.92
			for side: float in [-1.0, 1.0]:
				_create_visual_box(Vector3(x, center.y + 1.05, center.z + side * size_value.z * 0.47), Vector3(0.16, 1.8, 0.16), steel_light, 0.64, 0.36)
			_create_neon_strip(Vector3(x, center.y + 0.60, center.z - size_value.z * 0.49), Vector3(0.50, 0.06, 0.08), orange)


func _build_side_batteries() -> void:
	for side: float in [-1.0, 1.0]:
		var x: float = 39.0 * side
		_create_cylinder_static("BatteryBase", Vector3(x, PLATFORM_Y + 1.2, -12.0), 4.5, 2.4, steel_dark, 0.79, 0.25, 12)
		_create_static_box("BatterySpine", Vector3(x, PLATFORM_Y + 5.0, -12.0), Vector3(3.6, 7.2, 3.6), steel_dark, 0.82, 0.23)
		_create_static_box_rotated("BatteryWing", Vector3(x + 5.6 * side, PLATFORM_Y + 3.0, -12.0), Vector3(9.5, 1.7, 4.2), steel_mid, 0.77, 0.27, Vector3(0.0, 0.0, 11.0 * side))
		_create_static_box_rotated("BatteryBarrel", Vector3(x + 7.0 * side, PLATFORM_Y + 6.1, -12.0), Vector3(8.0, 0.85, 0.85), steel_light, 0.78, 0.22, Vector3(0.0, 0.0, -4.0 * side))
		_create_neon_strip(Vector3(x, PLATFORM_Y + 5.0, -13.84), Vector3(0.20, 4.4, 0.06), orange)


func _build_northern_monolith() -> void:
	var base_z: float = -75.0
	var base_y: float = maxf(_terrain_height_at(-14.0, base_z), _terrain_height_at(14.0, base_z))
	for side: float in [-1.0, 1.0]:
		_create_static_box_rotated("NorthMonolith", Vector3(13.0 * side, base_y + 18.0, base_z), Vector3(7.0, 37.0, 9.0), steel_dark, 0.83, 0.22, Vector3(0.0, 0.0, 8.0 * side))
		_create_static_box_rotated("NorthBlade", Vector3(17.0 * side, base_y + 31.0, base_z), Vector3(3.0, 20.0, 6.0), steel_light, 0.76, 0.28, Vector3(0.0, 0.0, 18.0 * side))
		_create_neon_strip(Vector3(13.0 * side, base_y + 19.0, base_z + 4.60), Vector3(0.30, 23.0, 0.06), orange)
	_create_static_box("NorthCrown", Vector3(0.0, base_y + 33.0, base_z), Vector3(34.0, 4.0, 9.0), steel_mid, 0.79, 0.25)
	_create_cylinder_visual(Vector3(0.0, base_y + 25.0, base_z + 4.8), 1.5, 18.0, Color(0.14, 0.05, 0.035), 0.35, 0.28, 10)
	_create_neon_strip(Vector3(0.0, base_y + 25.0, base_z + 6.38), Vector3(0.55, 12.0, 0.08), orange)


func _build_southern_landing_zone() -> void:
	var point: Vector3 = _extraction_world_position()
	_create_round_platform("VanguardLZ", point + Vector3(0.0, -0.25, 0.0), 9.4, 0.75, steel_mid, cyan)
	_create_cylinder_visual(point + Vector3(0.0, 0.10, 0.0), 6.3, 0.18, Color(0.075, 0.105, 0.12), 0.48, 0.35, 24)
	for side: float in [-1.0, 1.0]:
		_create_static_box_rotated("LZBeacon", point + Vector3(7.2 * side, 3.4, -2.4), Vector3(1.1, 6.4, 1.2), steel_dark, 0.72, 0.30, Vector3(0.0, 0.0, 5.0 * side))
		_create_neon_strip(point + Vector3(7.2 * side, 3.4, -3.02), Vector3(0.17, 4.4, 0.05), cyan)
	for i: int in range(8):
		var angle: float = TAU * float(i) / 8.0
		var light_pos: Vector3 = point + Vector3(cos(angle) * 7.8, 0.25, sin(angle) * 7.8)
		var light_mesh: MeshInstance3D = MeshInstance3D.new()
		var box_mesh: BoxMesh = BoxMesh.new()
		box_mesh.size = Vector3(0.45, 0.10, 0.45)
		light_mesh.mesh = box_mesh
		light_mesh.position = light_pos
		light_mesh.material_override = _emissive_material(cyan, 3.4)
		add_child(light_mesh)


func _build_horizon_structures() -> void:
	for i: int in range(11):
		var angle: float = -1.05 + float(i) * 0.19
		var radius: float = 188.0 + float((i * 17) % 38)
		var x: float = cos(angle) * radius
		var z: float = -absf(sin(angle) * radius) - 78.0
		var height_value: float = 18.0 + float((i * 13) % 46)
		_create_visual_box(Vector3(x, height_value * 0.45, z), Vector3(8.0 + float(i % 3) * 2.5, height_value, 9.0), Color(0.09, 0.13, 0.15), 0.42, 0.52, Vector3(0.0, float(i * 17), 0.0))

	# Distant sea stacks add depth and give the fortress a believable archipelago context.
	for i: int in range(8):
		var angle: float = TAU * float(i) / 8.0 + 0.3
		var x: float = cos(angle) * 150.0
		var z: float = sin(angle) * 150.0
		_create_rock_chunk(Vector3(x, 8.0 + float(i % 3) * 3.0, z), Vector3(16.0, 24.0 + float(i % 4) * 6.0, 18.0), 810 + i)


func _build_hud() -> void:
	var canvas: CanvasLayer = CanvasLayer.new()
	canvas.layer = 20
	add_child(canvas)
	var root: Control = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(root)

	_build_compact_vitals(root)
	_build_compact_weapon(root)
	_build_compact_objective(root)
	_build_compact_crosshair(root)
	_build_mobile_controls(root)

	damage_overlay = ColorRect.new()
	damage_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	damage_overlay.color = Color(0.70, 0.02, 0.015, 0.0)
	damage_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(damage_overlay)

	player.connect("health_changed", Callable(self, "_on_player_health_changed"))
	player.connect("shield_changed", Callable(self, "_on_player_shield_changed"))
	player.connect("ammo_changed", Callable(self, "_on_player_ammo_changed"))
	player.connect("damaged", Callable(self, "_on_player_damaged"))
	player.connect("died", Callable(self, "_on_player_died"))
	var weapon_node: Node = player.get("weapon") as Node
	if weapon_node != null:
		weapon_node.connect("hit_confirmed", Callable(self, "_show_hitmarker"))
		_on_player_ammo_changed(int(weapon_node.get("current_mag")), int(weapon_node.get("reserve_ammo")))
	_on_player_health_changed(int(player.get("health")), int(player.get("max_health")))
	_on_player_shield_changed(float(player.get("shield")), float(player.get("max_shield")))


func _build_compact_vitals(root: Control) -> void:
	var panel: Panel = Panel.new()
	panel.position = Vector2(22.0, 20.0)
	panel.size = Vector2(238.0, 74.0)
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.008, 0.024, 0.032, 0.76), Color(cyan.r, cyan.g, cyan.b, 0.28), 1))
	root.add_child(panel)
	var id_label: Label = Label.new()
	id_label.text = "VANGUARD // M41"
	id_label.position = Vector2(14.0, 7.0)
	id_label.add_theme_font_size_override("font_size", 10)
	id_label.add_theme_color_override("font_color", Color(0.56, 0.86, 0.94))
	panel.add_child(id_label)

	shield_label = Label.new()
	shield_label.text = "S 100"
	shield_label.position = Vector2(14.0, 28.0)
	shield_label.size = Vector2(48.0, 16.0)
	shield_label.add_theme_font_size_override("font_size", 10)
	shield_label.add_theme_color_override("font_color", pale)
	panel.add_child(shield_label)
	shield_bar = ProgressBar.new()
	shield_bar.position = Vector2(62.0, 30.0)
	shield_bar.size = Vector2(160.0, 7.0)
	shield_bar.show_percentage = false
	shield_bar.max_value = 100.0
	shield_bar.value = 100.0
	shield_bar.add_theme_stylebox_override("background", _bar_style(Color(0.025, 0.055, 0.07), Color(0.05, 0.12, 0.15)))
	shield_bar.add_theme_stylebox_override("fill", _bar_style(Color(0.02, 0.54, 0.90), Color(0.06, 0.78, 1.0)))
	panel.add_child(shield_bar)

	health_label = Label.new()
	health_label.text = "C 100"
	health_label.position = Vector2(14.0, 49.0)
	health_label.size = Vector2(48.0, 16.0)
	health_label.add_theme_font_size_override("font_size", 10)
	health_label.add_theme_color_override("font_color", pale)
	panel.add_child(health_label)
	health_bar = ProgressBar.new()
	health_bar.position = Vector2(62.0, 51.0)
	health_bar.size = Vector2(160.0, 7.0)
	health_bar.show_percentage = false
	health_bar.max_value = 100.0
	health_bar.value = 100.0
	health_bar.add_theme_stylebox_override("background", _bar_style(Color(0.07, 0.025, 0.02), Color(0.13, 0.05, 0.04)))
	health_bar.add_theme_stylebox_override("fill", _bar_style(Color(0.82, 0.14, 0.035), Color(1.0, 0.29, 0.08)))
	panel.add_child(health_bar)


func _build_compact_weapon(root: Control) -> void:
	var panel: Panel = Panel.new()
	panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	panel.offset_left = -196.0
	panel.offset_top = 20.0
	panel.offset_right = -22.0
	panel.offset_bottom = 94.0
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.008, 0.024, 0.032, 0.76), Color(cyan.r, cyan.g, cyan.b, 0.24), 1))
	root.add_child(panel)
	var name_label: Label = Label.new()
	name_label.text = "VX-7 // AUTO"
	name_label.position = Vector2(13.0, 8.0)
	name_label.add_theme_font_size_override("font_size", 10)
	name_label.add_theme_color_override("font_color", Color(0.56, 0.86, 0.94))
	panel.add_child(name_label)
	ammo_label = Label.new()
	ammo_label.text = "30"
	ammo_label.position = Vector2(12.0, 24.0)
	ammo_label.size = Vector2(72.0, 40.0)
	ammo_label.add_theme_font_size_override("font_size", 30)
	ammo_label.add_theme_color_override("font_color", pale)
	panel.add_child(ammo_label)
	reserve_label = Label.new()
	reserve_label.text = "/ 150"
	reserve_label.position = Vector2(82.0, 40.0)
	reserve_label.add_theme_font_size_override("font_size", 13)
	reserve_label.add_theme_color_override("font_color", Color(0.55, 0.68, 0.73))
	panel.add_child(reserve_label)


func _build_compact_objective(root: Control) -> void:
	var panel: Panel = Panel.new()
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.offset_left = -260.0
	panel.offset_top = 18.0
	panel.offset_right = 260.0
	panel.offset_bottom = 82.0
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.008, 0.024, 0.032, 0.68), Color(cyan.r, cyan.g, cyan.b, 0.20), 1))
	root.add_child(panel)
	var chapter: Label = Label.new()
	chapter.text = "OP 02 // COASTLINE FORTRESS"
	chapter.position = Vector2(10.0, 6.0)
	chapter.size = Vector2(500.0, 16.0)
	chapter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chapter.add_theme_font_size_override("font_size", 10)
	chapter.add_theme_color_override("font_color", Color(0.55, 0.84, 0.93))
	panel.add_child(chapter)
	objective_label = Label.new()
	objective_label.text = "BREACH HELIX COMMAND CORE"
	objective_label.position = Vector2(10.0, 25.0)
	objective_label.size = Vector2(500.0, 22.0)
	objective_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	objective_label.add_theme_font_size_override("font_size", 15)
	objective_label.add_theme_color_override("font_color", pale)
	panel.add_child(objective_label)
	hostiles_label = Label.new()
	hostiles_label.text = "HOSTILES 00 / 00"
	hostiles_label.position = Vector2(10.0, 47.0)
	hostiles_label.size = Vector2(500.0, 14.0)
	hostiles_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hostiles_label.add_theme_font_size_override("font_size", 9)
	hostiles_label.add_theme_color_override("font_color", orange)
	panel.add_child(hostiles_label)

	status_label = Label.new()
	status_label.anchor_left = 0.5
	status_label.anchor_top = 1.0
	status_label.anchor_right = 0.5
	status_label.anchor_bottom = 1.0
	status_label.offset_left = -360.0
	status_label.offset_top = -46.0
	status_label.offset_right = 360.0
	status_label.offset_bottom = -19.0
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 11)
	status_label.add_theme_color_override("font_color", Color(0.72, 0.86, 0.88))
	status_label.text = "NEXUS // COASTAL INSERTION"
	root.add_child(status_label)


func _build_compact_crosshair(root: Control) -> void:
	crosshair = Label.new()
	crosshair.text = "+"
	crosshair.anchor_left = 0.5
	crosshair.anchor_top = 0.5
	crosshair.anchor_right = 0.5
	crosshair.anchor_bottom = 0.5
	crosshair.offset_left = -18.0
	crosshair.offset_top = -18.0
	crosshair.offset_right = 18.0
	crosshair.offset_bottom = 18.0
	crosshair.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	crosshair.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	crosshair.add_theme_font_size_override("font_size", 20)
	crosshair.add_theme_color_override("font_color", Color(0.84, 0.96, 1.0, 0.88))
	root.add_child(crosshair)


func _create_cylinder_static(node_name: String, center: Vector3, radius: float, height_value: float, color: Color, metallic: float, roughness: float, segments: int) -> void:
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
	mesh_instance.material_override = _material(color, metallic, roughness)
	body.add_child(mesh_instance)
	add_child(body)


func _create_cylinder_visual(center: Vector3, radius: float, height_value: float, color: Color, metallic: float, roughness: float, segments: int) -> void:
	var mesh_instance: MeshInstance3D = MeshInstance3D.new()
	var mesh: CylinderMesh = CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height_value
	mesh.radial_segments = segments
	mesh_instance.mesh = mesh
	mesh_instance.position = center
	mesh_instance.material_override = _material(color, metallic, roughness)
	add_child(mesh_instance)
