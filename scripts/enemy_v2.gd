extends CharacterBody3D

@export var unit_type: String = "rifleman"
@export var max_health: int = 100
@export var move_speed: float = 2.7
@export var attack_range: float = 17.0
@export var preferred_range: float = 9.0
@export var fire_interval: float = 0.85
@export var damage: int = 8
@export var turn_speed: float = 5.5

var health: int = 100
var target: CharacterBody3D
var gravity: float = 9.8
var fire_cooldown: float = 0.0
var dead: bool = false
var body_material: StandardMaterial3D
var armor_material: StandardMaterial3D
var undersuit_material: StandardMaterial3D
var visor_material: StandardMaterial3D
var muzzle: Marker3D
var visual_root: Node3D


func _ready() -> void:
	_configure_unit()
	add_to_group("enemies")
	health = max_health
	gravity = float(ProjectSettings.get_setting("physics/3d/default_gravity", 9.8))
	if target == null:
		target = get_tree().get_first_node_in_group("player") as CharacterBody3D
	_build_collision()
	_build_visuals()


func _physics_process(delta: float) -> void:
	if dead or not is_instance_valid(target):
		return

	fire_cooldown = maxf(0.0, fire_cooldown - delta)
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = -0.18

	var offset := target.global_position - global_position
	var flat_offset := Vector3(offset.x, 0.0, offset.z)
	var distance := flat_offset.length()

	if distance > 0.05:
		var desired_yaw := atan2(-flat_offset.x, -flat_offset.z)
		rotation.y = lerp_angle(rotation.y, desired_yaw, minf(1.0, turn_speed * delta))

	if distance > preferred_range:
		var move_dir := flat_offset.normalized()
		velocity.x = move_dir.x * move_speed
		velocity.z = move_dir.z * move_speed
	elif unit_type == "scout" and distance < preferred_range * 0.65:
		var retreat_dir := -flat_offset.normalized()
		velocity.x = retreat_dir.x * move_speed * 0.7
		velocity.z = retreat_dir.z * move_speed * 0.7
	else:
		velocity.x = move_toward(velocity.x, 0.0, move_speed * 6.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, move_speed * 6.0 * delta)

	if visual_root != null:
		var movement_amount := Vector2(velocity.x, velocity.z).length()
		visual_root.rotation.z = sin(Time.get_ticks_msec() * 0.008) * 0.018 * clampf(movement_amount, 0.0, 1.0)

	if distance <= attack_range and fire_cooldown <= 0.0 and _has_line_of_sight():
		fire_cooldown = fire_interval
		_fire_at_player()

	move_and_slide()


func take_damage(amount: int) -> void:
	if dead or amount <= 0:
		return
	health = maxi(0, health - amount)
	_flash_hit()
	if health <= 0:
		_die()


func _configure_unit() -> void:
	match unit_type:
		"scout":
			max_health = 65
			move_speed = 4.1
			attack_range = 18.0
			preferred_range = 10.5
			fire_interval = 0.62
			damage = 6
		"heavy":
			max_health = 240
			move_speed = 1.65
			attack_range = 18.5
			preferred_range = 8.0
			fire_interval = 0.48
			damage = 9
		"commander":
			max_health = 180
			move_speed = 2.4
			attack_range = 22.0
			preferred_range = 12.0
			fire_interval = 0.58
			damage = 11
		_:
			unit_type = "rifleman"


func _fire_at_player() -> void:
	if not is_instance_valid(target):
		return
	var from := global_position + Vector3.UP * 0.55
	if muzzle != null:
		from = muzzle.global_position
	var to := target.global_position + Vector3.UP * 0.48
	_spawn_tracer(from, to)
	if target.has_method("take_damage"):
		target.call("take_damage", damage)


func _has_line_of_sight() -> bool:
	if not is_instance_valid(target):
		return false
	var ray_from := global_position + Vector3.UP * 0.65
	var ray_to := target.global_position + Vector3.UP * 0.55
	var query := PhysicsRayQueryParameters3D.create(ray_from, ray_to)
	query.exclude = [get_rid()]
	query.collide_with_areas = false
	query.collide_with_bodies = true
	var result := get_world_3d().direct_space_state.intersect_ray(query)
	if result.is_empty():
		return false
	return result.get("collider") == target


func _spawn_tracer(from: Vector3, to: Vector3) -> void:
	var tracer := MeshInstance3D.new()
	var line_mesh := ImmediateMesh.new()
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1.0, 0.12, 0.035)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.08, 0.02)
	mat.emission_energy_multiplier = 5.5
	line_mesh.surface_begin(Mesh.PRIMITIVE_LINES, mat)
	line_mesh.surface_add_vertex(Vector3.ZERO)
	line_mesh.surface_add_vertex(to - from)
	line_mesh.surface_end()
	tracer.mesh = line_mesh
	get_tree().current_scene.add_child(tracer)
	tracer.global_position = from
	var timer := get_tree().create_timer(0.055)
	timer.timeout.connect(tracer.queue_free)


func _flash_hit() -> void:
	if armor_material == null:
		return
	armor_material.emission_enabled = true
	armor_material.emission = Color(1.0, 0.13, 0.035)
	armor_material.emission_energy_multiplier = 3.4
	var timer := get_tree().create_timer(0.075)
	timer.timeout.connect(_clear_hit_flash)


func _clear_hit_flash() -> void:
	if armor_material != null:
		armor_material.emission_enabled = false


func _die() -> void:
	dead = true
	remove_from_group("enemies")
	collision_layer = 0
	collision_mask = 0
	velocity = Vector3.ZERO
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "rotation:z", deg_to_rad(84.0), 0.34)
	tween.tween_property(self, "position:y", position.y - 0.48, 0.34)
	tween.tween_property(self, "scale", scale * Vector3(1.02, 0.82, 1.02), 0.34)
	tween.chain().tween_callback(queue_free)


func _build_collision() -> void:
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	var radius := 0.50 if unit_type == "heavy" else 0.40
	var height := 2.08 if unit_type == "heavy" else 1.84
	capsule.radius = radius
	capsule.height = height
	collision.shape = capsule
	collision.position.y = 0.05
	add_child(collision)


func _build_visuals() -> void:
	var accent := Color(0.92, 0.09, 0.025)
	var shell := Color(0.11, 0.12, 0.13)
	var plate := Color(0.21, 0.22, 0.22)
	var suit := Color(0.035, 0.042, 0.045)
	var size_factor := 1.0

	match unit_type:
		"scout":
			accent = Color(1.0, 0.26, 0.055)
			shell = Color(0.075, 0.085, 0.09)
			plate = Color(0.16, 0.17, 0.18)
			size_factor = 0.94
		"heavy":
			accent = Color(1.0, 0.42, 0.035)
			plate = Color(0.26, 0.21, 0.14)
			shell = Color(0.12, 0.10, 0.075)
			size_factor = 1.20
		"commander":
			accent = Color(1.0, 0.055, 0.22)
			plate = Color(0.24, 0.12, 0.18)
			shell = Color(0.10, 0.065, 0.085)
			size_factor = 1.08

	body_material = _make_material(shell, 0.70, 0.34)
	armor_material = _make_material(plate, 0.79, 0.25)
	undersuit_material = _make_material(suit, 0.15, 0.82)
	visor_material = _make_emissive(accent, 4.8)

	visual_root = Node3D.new()
	visual_root.name = "HELIX_ArmorRig"
	add_child(visual_root)

	# Undersuit core and abdomen.
	_add_capsule(0.24 * size_factor, 0.76 * size_factor, Vector3(0.0, 0.18, 0.02), undersuit_material)
	_add_cylinder(0.27 * size_factor, 0.34 * size_factor, Vector3(0.0, -0.18, 0.02), undersuit_material)

	# Broad but rounded chest armor.
	_add_box(Vector3(0.76, 0.42, 0.42) * size_factor, Vector3(0.0, 0.38, 0.0), armor_material)
	_add_box(Vector3(0.58, 0.26, 0.48) * size_factor, Vector3(0.0, 0.13, 0.0), body_material)
	_add_box(Vector3(0.16, 0.30, 0.06) * size_factor, Vector3(0.0, 0.32, -0.235 * size_factor), visor_material)

	# Helmet shell: rounded dome with a strong glowing visor slit.
	_add_sphere(Vector3(0.34, 0.29, 0.33) * size_factor, Vector3(0.0, 0.91, 0.0), armor_material)
	_add_box(Vector3(0.43, 0.10, 0.055) * size_factor, Vector3(0.0, 0.92, -0.315 * size_factor), visor_material)
	_add_box(Vector3(0.21, 0.12, 0.09) * size_factor, Vector3(0.0, 0.76, -0.255 * size_factor), body_material)

	for side in [-1.0, 1.0]:
		# Shoulder shells.
		_add_sphere(Vector3(0.24, 0.18, 0.28) * size_factor, Vector3(0.46 * side * size_factor, 0.43, 0.0), armor_material)
		# Upper/lower arms.
		_add_capsule(0.115 * size_factor, 0.54 * size_factor, Vector3(0.48 * side * size_factor, 0.12, 0.0), undersuit_material, Vector3(0.0, 0.0, -6.0 * side))
		_add_box(Vector3(0.22, 0.32, 0.22) * size_factor, Vector3(0.49 * side * size_factor, 0.06, -0.015), body_material, Vector3(0.0, 0.0, -6.0 * side))
		_add_capsule(0.105 * size_factor, 0.48 * size_factor, Vector3(0.44 * side * size_factor, -0.20, -0.05), undersuit_material, Vector3(0.0, 0.0, 9.0 * side))

		# Thigh and shin armor.
		_add_capsule(0.145 * size_factor, 0.58 * size_factor, Vector3(0.20 * side * size_factor, -0.55, 0.0), undersuit_material)
		_add_box(Vector3(0.30, 0.40, 0.34) * size_factor, Vector3(0.20 * side * size_factor, -0.49, -0.02), armor_material)
		_add_capsule(0.125 * size_factor, 0.48 * size_factor, Vector3(0.20 * side * size_factor, -0.89, 0.01), undersuit_material)
		_add_box(Vector3(0.27, 0.34, 0.31) * size_factor, Vector3(0.20 * side * size_factor, -0.84, -0.03), body_material)
		_add_box(Vector3(0.30, 0.16, 0.46) * size_factor, Vector3(0.20 * side * size_factor, -1.12, -0.10), body_material)

	if unit_type == "heavy":
		_add_box(Vector3(1.00, 0.26, 0.56) * size_factor, Vector3(0.0, 0.42, 0.04), armor_material)
		_add_box(Vector3(0.28, 0.60, 0.18) * size_factor, Vector3(0.0, 0.08, 0.33), armor_material)
		for side in [-1.0, 1.0]:
			_add_box(Vector3(0.28, 0.34, 0.38) * size_factor, Vector3(0.57 * side * size_factor, 0.40, 0.0), armor_material)

	if unit_type == "commander":
		_add_box(Vector3(0.62, 0.08, 0.08) * size_factor, Vector3(0.0, 1.10, 0.0), visor_material)

	# Rifle with thicker receiver and cylindrical barrel.
	_add_box(Vector3(0.17, 0.18, 0.72) * size_factor, Vector3(0.20, 0.11, -0.43), body_material, Vector3(0.0, 0.0, -10.0))
	_add_box(Vector3(0.23, 0.10, 0.34) * size_factor, Vector3(0.20, 0.18, -0.48), armor_material, Vector3(0.0, 0.0, -10.0))
	_add_cylinder(0.035 * size_factor, 0.40 * size_factor, Vector3(0.20, 0.11, -0.93), body_material, Vector3(90.0, 0.0, 0.0))
	_add_box(Vector3(0.09, 0.06, 0.18) * size_factor, Vector3(0.20, 0.25, -0.47), visor_material)

	muzzle = Marker3D.new()
	muzzle.position = Vector3(0.20, 0.11, -1.16 * size_factor)
	add_child(muzzle)


func _parent_visual(node: Node3D) -> void:
	if visual_root != null:
		visual_root.add_child(node)
	else:
		add_child(node)


func _add_box(size: Vector3, local_position: Vector3, material: Material, rotation_value: Vector3 = Vector3.ZERO) -> void:
	var instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	instance.mesh = mesh
	instance.position = local_position
	instance.rotation_degrees = rotation_value
	instance.material_override = material
	_parent_visual(instance)


func _add_capsule(radius: float, height: float, local_position: Vector3, material: Material, rotation_value: Vector3 = Vector3.ZERO) -> void:
	var instance := MeshInstance3D.new()
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = maxf(height, radius * 2.05)
	instance.mesh = mesh
	instance.position = local_position
	instance.rotation_degrees = rotation_value
	instance.material_override = material
	_parent_visual(instance)


func _add_sphere(scale_value: Vector3, local_position: Vector3, material: Material) -> void:
	var instance := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	instance.mesh = mesh
	instance.scale = scale_value
	instance.position = local_position
	instance.material_override = material
	_parent_visual(instance)


func _add_cylinder(radius: float, height: float, local_position: Vector3, material: Material, rotation_value: Vector3 = Vector3.ZERO) -> void:
	var instance := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius * 1.08
	mesh.height = height
	instance.mesh = mesh
	instance.position = local_position
	instance.rotation_degrees = rotation_value
	instance.material_override = material
	_parent_visual(instance)


func _make_material(color: Color, metallic: float, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metallic
	material.roughness = roughness
	return material


func _make_emissive(color: Color, energy: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = energy
	material.metallic = 0.25
	material.roughness = 0.14
	return material
