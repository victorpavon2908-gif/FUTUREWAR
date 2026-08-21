extends "res://scripts/terrain_master.gd"


func _build_master_terrain() -> void:
	var vertices: PackedVector3Array = PackedVector3Array()
	var normals: PackedVector3Array = PackedVector3Array()
	var colors: PackedColorArray = PackedColorArray()
	var indices: PackedInt32Array = PackedInt32Array()
	var collision_faces: PackedVector3Array = PackedVector3Array()
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
			var grass: Color = Color(0.14, 0.27, 0.085)
			var meadow: Color = Color(0.24, 0.39, 0.13)
			var rock: Color = Color(0.30, 0.31, 0.29)
			var dark_rock: Color = Color(0.18, 0.20, 0.19)
			var river_bank: Color = Color(0.34, 0.31, 0.21)
			var tint: Color = grass.lerp(meadow, clampf(1.0 - slope * 1.7, 0.0, 1.0) * 0.46)
			tint = tint.lerp(rock, clampf(slope * 2.35, 0.0, 1.0))
			tint = tint.lerp(dark_rock, high_factor * 0.72)
			tint = tint.lerp(river_bank, low_factor * 0.70)
			colors.append(tint)

	for zi: int in range(cells):
		for xi: int in range(cells):
			var a: int = zi * TERRAIN_RESOLUTION + xi
			var b: int = a + 1
			var c: int = a + TERRAIN_RESOLUTION
			var d: int = c + 1

			# IMPORTANT: these triangles face UP. The previous pass faced downward,
			# which is why the player fell through the terrain and saw it as a ceiling.
			indices.append(a)
			indices.append(b)
			indices.append(c)
			indices.append(b)
			indices.append(d)
			indices.append(c)

			# Physics uses double-sided triangles so no seam can swallow the player.
			_append_double_sided_triangle(collision_faces, vertices[a], vertices[b], vertices[c])
			_append_double_sided_triangle(collision_faces, vertices[b], vertices[d], vertices[c])

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
	terrain.name = "MASTER_CONTINUOUS_TERRAIN_FIXED"
	terrain.mesh = mesh
	add_child(terrain)

	var body: StaticBody3D = StaticBody3D.new()
	body.name = "MASTER_CONTINUOUS_TERRAIN_COLLISION_FIXED"
	var collision: CollisionShape3D = CollisionShape3D.new()
	var shape: ConcavePolygonShape3D = ConcavePolygonShape3D.new()
	shape.set_faces(collision_faces)
	collision.shape = shape
	body.add_child(collision)
	add_child(body)


func _append_double_sided_triangle(target_faces: PackedVector3Array, a: Vector3, b: Vector3, c: Vector3) -> void:
	target_faces.append(a)
	target_faces.append(b)
	target_faces.append(c)
	target_faces.append(a)
	target_faces.append(c)
	target_faces.append(b)


func _spawn_player() -> void:
	player = CharacterBody3D.new()
	player.name = "Jefe"
	player.set_script(TERRAIN_PLAYER)
	var spawn: Vector3 = Vector3(0.0, 0.0, 132.0)
	spawn.y = _terrain_height_at(spawn.x, spawn.z) + 2.4
	player.position = spawn
	player.rotation.y = 0.0
	last_safe_position = spawn
	add_child(player)


func _process(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return

	rescue_timer += delta
	var px: float = clampf(player.global_position.x, -HALF_MAP + 2.0, HALF_MAP - 2.0)
	var pz: float = clampf(player.global_position.z, -HALF_MAP + 2.0, HALF_MAP - 2.0)
	var expected_ground: float = _terrain_height_at(px, pz)

	# Terrain-relative failsafe: if physics ever puts the player below the visible ground,
	# correct it immediately instead of allowing the camera to end up underneath the map.
	if player.global_position.y < expected_ground - 0.75:
		player.global_position = Vector3(px, expected_ground + 1.35, pz)
		player.velocity = Vector3.ZERO
		last_safe_position = player.global_position
		return

	if rescue_timer >= 0.30:
		rescue_timer = 0.0
		if player.is_on_floor() and absf(player.global_position.y - expected_ground) < 2.5:
			last_safe_position = player.global_position

	# Last-resort catch. This should never be reached now, but it keeps the survey safe.
	if player.global_position.y < -1.0:
		player.global_position = Vector3(last_safe_position.x, _terrain_height_at(last_safe_position.x, last_safe_position.z) + 1.35, last_safe_position.z)
		player.velocity = Vector3.ZERO
