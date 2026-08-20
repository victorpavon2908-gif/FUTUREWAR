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
var visor_material: StandardMaterial3D
var muzzle: Marker3D


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
	mat.albedo_color = Color(1.0, 0.10, 0.035)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.08, 0.02)
	mat.emission_energy_multiplier = 5.0
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
	armor_material.emission_energy_multiplier = 3.0
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
	tween.tween_property(self, "rotation:z", deg_to_rad(82.0), 0.26)
	tween.tween_property(self, "position:y", position.y - 0.42, 0.26)
	tween.tween_property(self, "scale", scale * Vector3(1.05, 0.18, 1.05), 0.28)
	tween.chain().tween_callback(queue_free)


func _build_collision() -> void:
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	var radius := 0.48 if unit_type == "heavy" else 0.40
	var height := 2.04 if unit_type == "heavy" else 1.82
	capsule.radius = radius
	capsule.height = height
	collision.shape = capsule
	collision.position.y = 0.05
	add_child(collision)


func _build_visuals() -> void:
	var accent := Color(0.90, 0.08, 0.025)
	var shell := Color(0.075, 0.085, 0.095)
	var plate := Color(0.15, 0.16, 0.17)
	var size_factor := 1.0

	match unit_type:
		"scout":
			accent = Color(1.0, 0.22, 0.05)
			shell = Color(0.045, 0.052, 0.060)
			size_factor = 0.92
		"heavy":
			accent = Color(1.0, 0.35, 0.03)
			plate = Color(0.20, 0.16, 0.12)
			size_factor = 1.18
		"commander":
			accent = Color(1.0, 0.04, 0.18)
			plate = Color(0.17, 0.10, 0.14)
			size_factor = 1.08

	body_material = _make_material(shell, 0.72, 0.36)
	armor_material = _make_material(plate, 0.78, 0.28)
	visor_material = _make_emissive(accent, 4.8)

	# Original bulky military sci-fi silhouette: broad chest, separated plates and luminous visor.
	_add_box(Vector3(0.68, 0.82, 0.40) * size_factor, Vector3(0.0, 0.18, 0.0), body_material)
	_add_box(Vector3(0.78, 0.34, 0.46) * size_factor, Vector3(0.0, 0.42, -0.01), armor_material)
	_add_box(Vector3(0.50, 0.38, 0.44) * size_factor, Vector3(0.0, 0.86, 0.0), armor_material)
	_add_box(Vector3(0.37, 0.075, 0.035) * size_factor, Vector3(0.0, 0.90, -0.235 * size_factor), visor_material)
	_add_box(Vector3(0.20, 0.16, 0.08) * size_factor, Vector3(0.0, 0.65, -0.22 * size_factor), visor_material)

	for side in [-1.0, 1.0]:
		_add_box(Vector3(0.30, 0.22, 0.48) * size_factor, Vector3(0.45 * side * size_factor, 0.42, 0.0), armor_material, Vector3(0.0, 0.0, 12.0 * side))
		_add_box(Vector3(0.20, 0.63, 0.22) * size_factor, Vector3(0.49 * side * size_factor, 0.08, 0.0), body_material, Vector3(0.0, 0.0, -6.0 * side))
		_add_box(Vector3(0.27, 0.56, 0.30) * size_factor, Vector3(0.20 * side * size_factor, -0.56, 0.0), armor_material)
		_add_box(Vector3(0.29, 0.20, 0.34) * size_factor, Vector3(0.20 * side * size_factor, -0.87, -0.01), body_material)

	if unit_type == "heavy":
		_add_box(Vector3(0.92, 0.24, 0.52) * size_factor, Vector3(0.0, 0.31, 0.05), armor_material)
		_add_box(Vector3(0.20, 0.52, 0.16) * size_factor, Vector3(0.0, 0.14, 0.29), armor_material)

	# Distinct rifle silhouette.
	_add_box(Vector3(0.14, 0.15, 0.78) * size_factor, Vector3(0.20, 0.10, -0.42), body_material, Vector3(0.0, 0.0, -10.0))
	_add_box(Vector3(0.19, 0.08, 0.33) * size_factor, Vector3(0.20, 0.17, -0.46), armor_material, Vector3(0.0, 0.0, -10.0))
	_add_box(Vector3(0.055, 0.055, 0.28) * size_factor, Vector3(0.20, 0.10, -0.95), body_material, Vector3(0.0, 0.0, -10.0))

	muzzle = Marker3D.new()
	muzzle.position = Vector3(0.20, 0.10, -1.10 * size_factor)
	add_child(muzzle)


func _add_box(size: Vector3, local_position: Vector3, material: Material, rotation_value: Vector3 = Vector3.ZERO) -> void:
	var instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	instance.mesh = mesh
	instance.position = local_position
	instance.rotation_degrees = rotation_value
	instance.material_override = material
	add_child(instance)


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
	material.metallic = 0.2
	material.roughness = 0.16
	return material
