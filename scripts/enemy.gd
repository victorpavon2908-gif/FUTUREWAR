extends CharacterBody3D

@export var max_health: int = 100
@export var move_speed: float = 2.7
@export var attack_range: float = 16.0
@export var preferred_range: float = 9.0
@export var fire_interval: float = 0.85
@export var damage: int = 8
@export var turn_speed: float = 5.0

var health: int = 100
var target: CharacterBody3D
var gravity: float = 9.8
var fire_cooldown: float = 0.0
var dead: bool = false
var body_material: StandardMaterial3D
var visor_material: StandardMaterial3D


func _ready() -> void:
	add_to_group("enemies")
	health = max_health
	gravity = float(ProjectSettings.get_setting("physics/3d/default_gravity", 9.8))
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
		velocity.y = -0.2

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


func _fire_at_player() -> void:
	if not is_instance_valid(target):
		return
	if target.has_method("take_damage"):
		target.take_damage(damage)


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


func _flash_hit() -> void:
	if body_material == null:
		return
	body_material.emission_enabled = true
	body_material.emission = Color(0.75, 0.05, 0.02)
	body_material.emission_energy_multiplier = 2.4
	var timer := get_tree().create_timer(0.08)
	timer.timeout.connect(_clear_hit_flash)


func _clear_hit_flash() -> void:
	if body_material != null:
		body_material.emission_enabled = false


func _die() -> void:
	dead = true
	remove_from_group("enemies")
	collision_layer = 0
	collision_mask = 0
	velocity = Vector3.ZERO

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector3(1.12, 0.08, 1.12), 0.22)
	tween.tween_property(self, "rotation:z", deg_to_rad(78.0), 0.22)
	tween.chain().tween_callback(queue_free)


func _build_collision() -> void:
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.40
	capsule.height = 1.78
	collision.shape = capsule
	add_child(collision)


func _build_visuals() -> void:
	body_material = StandardMaterial3D.new()
	body_material.albedo_color = Color(0.055, 0.065, 0.075)
	body_material.metallic = 0.72
	body_material.roughness = 0.34

	visor_material = StandardMaterial3D.new()
	visor_material.albedo_color = Color(0.02, 0.28, 0.44)
	visor_material.emission_enabled = true
	visor_material.emission = Color(0.0, 0.42, 0.76)
	visor_material.emission_energy_multiplier = 4.5
	visor_material.metallic = 0.2
	visor_material.roughness = 0.15

	var torso := MeshInstance3D.new()
	var torso_mesh := BoxMesh.new()
	torso_mesh.size = Vector3(0.72, 0.92, 0.42)
	torso.mesh = torso_mesh
	torso.position = Vector3(0.0, 0.20, 0.0)
	torso.material_override = body_material
	add_child(torso)

	var head := MeshInstance3D.new()
	var head_mesh := BoxMesh.new()
	head_mesh.size = Vector3(0.48, 0.38, 0.42)
	head.mesh = head_mesh
	head.position = Vector3(0.0, 0.87, 0.0)
	head.material_override = body_material
	add_child(head)

	var visor := MeshInstance3D.new()
	var visor_mesh := BoxMesh.new()
	visor_mesh.size = Vector3(0.34, 0.08, 0.03)
	visor.mesh = visor_mesh
	visor.position = Vector3(0.0, 0.91, -0.225)
	visor.material_override = visor_material
	add_child(visor)

	var chest_light := MeshInstance3D.new()
	var chest_mesh := BoxMesh.new()
	chest_mesh.size = Vector3(0.10, 0.22, 0.025)
	chest_light.mesh = chest_mesh
	chest_light.position = Vector3(0.0, 0.27, -0.225)
	chest_light.material_override = visor_material
	add_child(chest_light)

	for side in [-1.0, 1.0]:
		var leg := MeshInstance3D.new()
		var leg_mesh := BoxMesh.new()
		leg_mesh.size = Vector3(0.25, 0.76, 0.28)
		leg.mesh = leg_mesh
		leg.position = Vector3(0.19 * side, -0.60, 0.0)
		leg.material_override = body_material
		add_child(leg)

		var arm := MeshInstance3D.new()
		var arm_mesh := BoxMesh.new()
		arm_mesh.size = Vector3(0.20, 0.74, 0.22)
		arm.mesh = arm_mesh
		arm.position = Vector3(0.47 * side, 0.18, 0.0)
		arm.rotation_degrees.z = -8.0 * side
		arm.material_override = body_material
		add_child(arm)

	var rifle := MeshInstance3D.new()
	var rifle_mesh := BoxMesh.new()
	rifle_mesh.size = Vector3(0.12, 0.12, 0.72)
	rifle.mesh = rifle_mesh
	rifle.position = Vector3(0.20, 0.12, -0.38)
	rifle.rotation_degrees.z = -14.0
	rifle.material_override = body_material
	add_child(rifle)
