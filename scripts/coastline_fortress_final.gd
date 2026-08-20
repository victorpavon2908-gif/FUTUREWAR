extends "res://scripts/coastline_fortress_production.gd"

const PLAYER_FINAL: Script = preload("res://scripts/player_v3.gd")

var last_safe_player_position: Vector3 = Vector3.ZERO
var safe_position_timer: float = 0.0


func _build_coastline_fortress() -> void:
	super._build_coastline_fortress()
	_build_full_traversal_network()
	_build_world_safety_floor()


func _spawn_player() -> void:
	player = CharacterBody3D.new()
	player.name = "Vanguard_01_Production"
	player.set_script(PLAYER_FINAL)
	player.position = _extraction_world_position() + Vector3(0.0, 1.15, -2.0)
	last_safe_player_position = player.position
	add_child(player)


func _process(delta: float) -> void:
	super._process(delta)
	if player == null or not is_instance_valid(player):
		return

	safe_position_timer += delta
	if safe_position_timer >= 0.35:
		safe_position_timer = 0.0
		if player.global_position.y > -1.2 and player.is_on_floor():
			last_safe_player_position = player.global_position

	# Never let the player disappear into an accidental terrain gap.
	if player.global_position.y < -5.2:
		var rescue: Vector3 = last_safe_player_position
		if rescue == Vector3.ZERO:
			rescue = _extraction_world_position() + Vector3(0.0, 1.4, -2.0)
		player.global_position = rescue + Vector3(0.0, 1.0, 0.0)
		player.velocity = Vector3.ZERO


func _build_full_traversal_network() -> void:
	# Southern approach: uninterrupted route from landing pad to the fortress bridge.
	var lz: Vector3 = _extraction_world_position()
	var south_ground: Vector3 = Vector3(0.0, _terrain_height_at(0.0, 61.0) + 0.45, 61.0)
	_create_walkable_link(lz + Vector3(0.0, 0.15, -5.5), south_ground, 10.0, Color(0.16, 0.19, 0.20))

	var ramp_entry: Vector3 = Vector3(0.0, _terrain_height_at(0.0, 38.0) + 0.55, 38.0)
	_create_walkable_link(south_ground, ramp_entry, 10.0, Color(0.14, 0.17, 0.18))
	_create_walkable_link(ramp_entry, Vector3(0.0, PLATFORM_Y - 0.35, 28.0), 9.0, Color(0.12, 0.15, 0.16))

	# Four fortress exits connect the elevated military structure back to natural terrain.
	var west_ground: Vector3 = Vector3(-58.0, _terrain_height_at(-58.0, -12.0) + 0.55, -12.0)
	var east_ground: Vector3 = Vector3(58.0, _terrain_height_at(58.0, -12.0) + 0.55, -12.0)
	var north_ground: Vector3 = Vector3(0.0, _terrain_height_at(0.0, -68.0) + 0.55, -68.0)
	_create_walkable_link(Vector3(-49.0, PLATFORM_Y - 0.25, -12.0), west_ground, 7.5, Color(0.13, 0.16, 0.17))
	_create_walkable_link(Vector3(49.0, PLATFORM_Y - 0.25, -12.0), east_ground, 7.5, Color(0.13, 0.16, 0.17))
	_create_walkable_link(Vector3(0.0, PLATFORM_Y + 0.35, -59.0), north_ground, 7.5, Color(0.13, 0.16, 0.17))

	# Side terraces let the player leave the main bridges and explore both cliff shelves.
	var west_shelf_a: Vector3 = Vector3(-38.0, _terrain_height_at(-38.0, 24.0) + 0.55, 24.0)
	var west_shelf_b: Vector3 = Vector3(-58.0, _terrain_height_at(-58.0, 38.0) + 0.55, 38.0)
	var east_shelf_a: Vector3 = Vector3(38.0, _terrain_height_at(38.0, 24.0) + 0.55, 24.0)
	var east_shelf_b: Vector3 = Vector3(58.0, _terrain_height_at(58.0, 38.0) + 0.55, 38.0)
	_create_walkable_link(Vector3(-29.0, PLATFORM_Y - 0.55, 6.0), west_shelf_a, 6.5, Color(0.12, 0.15, 0.16))
	_create_walkable_link(west_shelf_a, west_shelf_b, 6.0, Color(0.11, 0.14, 0.15))
	_create_walkable_link(Vector3(29.0, PLATFORM_Y - 0.55, 6.0), east_shelf_a, 6.5, Color(0.12, 0.15, 0.16))
	_create_walkable_link(east_shelf_a, east_shelf_b, 6.0, Color(0.11, 0.14, 0.15))

	# Low-profile guidance lights make every usable route readable at a glance.
	for p: Vector3 in [south_ground, ramp_entry, west_ground, east_ground, north_ground, west_shelf_a, east_shelf_a]:
		_create_route_marker(p + Vector3(0.0, 0.22, 0.0))


func _create_walkable_link(from_point: Vector3, to_point: Vector3, width: float, color: Color) -> void:
	var direction: Vector3 = to_point - from_point
	var length_value: float = direction.length()
	if length_value < 0.5:
		return

	var body: StaticBody3D = StaticBody3D.new()
	body.name = "TraversalDeck"
	body.position = (from_point + to_point) * 0.5
	body.basis = Basis.looking_at(direction.normalized(), Vector3.UP)

	var collision: CollisionShape3D = CollisionShape3D.new()
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = Vector3(width, 0.65, length_value)
	collision.shape = shape
	body.add_child(collision)

	var mesh_instance: MeshInstance3D = MeshInstance3D.new()
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = Vector3(width, 0.65, length_value)
	mesh_instance.mesh = mesh
	mesh_instance.material_override = _material(color, 0.72, 0.31)
	body.add_child(mesh_instance)
	add_child(body)

	# Narrow emissive edge strips make the route look intentionally built, not like a debug slab.
	for side: float in [-1.0, 1.0]:
		var rail: MeshInstance3D = MeshInstance3D.new()
		var rail_mesh: BoxMesh = BoxMesh.new()
		rail_mesh.size = Vector3(0.08, 0.06, length_value * 0.94)
		rail.mesh = rail_mesh
		rail.position = Vector3(side * (width * 0.46), 0.37, 0.0)
		rail.material_override = _emissive_material(cyan, 1.45)
		body.add_child(rail)


func _create_route_marker(world_position: Vector3) -> void:
	var marker: MeshInstance3D = MeshInstance3D.new()
	var mesh: CylinderMesh = CylinderMesh.new()
	mesh.top_radius = 0.12
	mesh.bottom_radius = 0.18
	mesh.height = 0.42
	mesh.radial_segments = 8
	marker.mesh = mesh
	marker.position = world_position
	marker.material_override = _emissive_material(cyan, 2.0)
	add_child(marker)


func _build_world_safety_floor() -> void:
	# A hidden catch floor sits below the visible island. It prevents endless falls through
	# unavoidable procedural seams while preserving all visible terrain height changes.
	var body: StaticBody3D = StaticBody3D.new()
	body.name = "WorldSafetyCatch"
	body.position = Vector3(0.0, -4.6, 0.0)
	var collision: CollisionShape3D = CollisionShape3D.new()
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = Vector3(ISLAND_SIZE + 24.0, 0.7, ISLAND_SIZE + 24.0)
	collision.shape = shape
	body.add_child(collision)
	add_child(body)
