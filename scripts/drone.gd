extends CharacterBody3D

@export var max_health: int = 55
@export var move_speed: float = 4.4
@export var orbit_range: float = 10.0
@export var attack_range: float = 21.0
@export var fire_interval: float = 0.72
@export var damage: int = 6

var health: int = 55
var target: CharacterBody3D
var dead: bool = false
var fire_cooldown: float = 0.0
var phase: float = 0.0
var core_material: StandardMaterial3D


func _ready() -> void:
	add_to_group("enemies")
	health = max_health
	phase = randf() * TAU
	if target == null:
		target = get_tree().get_first_node_in_group("player") as CharacterBody3D
	_build_collision()
	_build_visuals()


func _physics_process(delta: float) -> void:
	if dead or not is_instance_valid(target):
		return

	fire_cooldown = maxf(0.0, fire_cooldown - delta)
	phase += delta * 1.45
	var target_point := target.global_position + Vector3(cos(phase) * orbit_range, 3.0 + sin(phase * 1.8) * 0.55, sin(phase) * orbit_range)
	var to_target_point := target_point - global_position
	velocity = to_target_point.limit_length(move_speed)
	move_and_slide()

	var look_point := target.global_position + Vector3.UP * 0.55
	look_at(look_point, Vector3.UP, true)
	var distance := global_position.distance_to(target.global_position)
	if distance <= attack_range and fire_cooldown <= 0.0 and _has_line_of_sight():
		fire_cooldown = fire_interval
		_fire()


func take_damage(amount: int) -> void:
	if dead or amount <= 0:
		return
	health = maxi(0, health - amount)
	_flash()
	if health <= 0:
		_die()


func _fire() -> void:
	if not is_instance_valid(target):
		return
	var from := global_position + (-global_transform.basis.z * 0.52)
	var to := target.global_position + Vector3.UP * 0.55
	_spawn_tracer(from, to)
	if target.has_method("take_damage"):
		target.call("take_damage", damage)


func _has_line_of_sight() -> bool:
	var query := PhysicsRayQueryParameters3D.create(global_position, target.global_position + Vector3.UP * 0.55)
	query.exclude = [get_rid()]
	query.collide_with_bodies = true
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return not hit.is_empty() and hit.get("collider") == target


func _spawn_tracer(from: Vector3, to: Vector3) -> void:
	var tracer := MeshInstance3D.new()
	var line_mesh := ImmediateMesh.new()
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1.0, 0.18, 0.02)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.10, 0.01)
	mat.emission_energy_multiplier = 5.5
	line_mesh.surface_begin(Mesh.PRIMITIVE_LINES, mat)
	line_mesh.surface_add_vertex(Vector3.ZERO)
	line_mesh.surface_add_vertex(to - from)
	line_mesh.surface_end()
	tracer.mesh = line_mesh
	get_tree().current_scene.add_child(tracer)
	tracer.global_position = from
	var timer := get_tree().create_timer(0.07)
	timer.timeout.connect(tracer.queue_free)


func _flash() -> void:
	if core_material == null:
		return
	core_material.emission_energy_multiplier = 8.0
	var timer := get_tree().create_timer(0.08)
	timer.timeout.connect(func() -> void: core_material.emission_energy_multiplier = 4.5)


func _die() -> void:
	dead = true
	remove_from_group("enemies")
	collision_layer = 0
	collision_mask = 0
	velocity = Vector3.ZERO
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "rotation", Vector3(2.0, 4.0, 1.2), 0.36)
	tween.tween_property(self, "scale", Vector3.ZERO, 0.36)
	tween.chain().tween_callback(queue_free)


func _build_collision() -> void:
	var collision := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.62
	collision.shape = shape
	add_child(collision)


func _build_visuals() -> void:
	var dark := _make_material(Color(0.045, 0.055, 0.065), 0.82, 0.24)
	var plate := _make_material(Color(0.13, 0.14, 0.15), 0.70, 0.30)
	core_material = _make_emissive(Color(1.0, 0.08, 0.02), 4.5)

	var core := MeshInstance3D.new()
	var core_mesh := SphereMesh.new()
	core_mesh.radius = 0.30
	core_mesh.height = 0.60
	core.mesh = core_mesh
	core.material_override = core_material
	add_child(core)

	_add_box(Vector3(1.15, 0.18, 0.34), Vector3.ZERO, dark)
	_add_box(Vector3(0.46, 0.26, 0.68), Vector3(0.0, 0.0, 0.05), plate)
	_add_box(Vector3(0.20, 0.11, 0.32), Vector3(-0.70, 0.0, 0.0), plate)
	_add_box(Vector3(0.20, 0.11, 0.32), Vector3(0.70, 0.0, 0.0), plate)
	_add_box(Vector3(0.16, 0.12, 0.42), Vector3(0.0, -0.17, -0.36), dark)

	for side in [-1.0, 1.0]:
		var rotor := MeshInstance3D.new()
		var rotor_mesh := CylinderMesh.new()
		rotor_mesh.top_radius = 0.18
		rotor_mesh.bottom_radius = 0.18
		rotor_mesh.height = 0.08
		rotor.mesh = rotor_mesh
		rotor.position = Vector3(0.72 * side, 0.08, 0.0)
		rotor.material_override = core_material
		add_child(rotor)


func _add_box(size: Vector3, local_position: Vector3, material: Material) -> void:
	var instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	instance.mesh = mesh
	instance.position = local_position
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
	material.metallic = 0.15
	material.roughness = 0.14
	return material
