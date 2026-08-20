extends CharacterBody3D

@export var unit_type: String = "glyph_crawler"

var target: CharacterBody3D
var max_health: int = 100
var health: int = 100
var move_speed: float = 2.8
var attack_range: float = 18.0
var preferred_range: float = 10.0
var fire_interval: float = 0.75
var damage: int = 7
var turn_speed: float = 6.0
var gravity: float = 9.8
var fire_cooldown: float = 0.0
var ability_cooldown: float = 0.0
var melee_cooldown: float = 0.0
var dead: bool = false
var strafe_sign: float = 1.0
var visual_root: Node3D
var armor_material: StandardMaterial3D
var energy_material: StandardMaterial3D
var muzzle: Marker3D
var accent: Color = Color(0.18, 0.82, 1.0)
var body_height: float = 1.8
var elapsed: float = 0.0


func _ready() -> void:
	_configure_unit()
	add_to_group("enemies")
	health = max_health
	gravity = float(ProjectSettings.get_setting("physics/3d/default_gravity", 9.8))
	strafe_sign = -1.0 if (get_instance_id() % 2 == 0) else 1.0
	if target == null:
		target = get_tree().get_first_node_in_group("player") as CharacterBody3D
	_build_collision()
	_build_visuals()


func _physics_process(delta: float) -> void:
	if dead or not is_instance_valid(target):
		return

	elapsed += delta
	fire_cooldown = maxf(0.0, fire_cooldown - delta)
	ability_cooldown = maxf(0.0, ability_cooldown - delta)
	melee_cooldown = maxf(0.0, melee_cooldown - delta)

	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = -0.14

	var offset: Vector3 = target.global_position - global_position
	var flat: Vector3 = Vector3(offset.x, 0.0, offset.z)
	var distance: float = flat.length()
	if distance > 0.05:
		var desired_yaw: float = atan2(-flat.x, -flat.z)
		rotation.y = lerp_angle(rotation.y, desired_yaw, minf(1.0, turn_speed * delta))

	match unit_type:
		"phase_lancer":
			_update_phase_lancer(flat, distance, delta)
		"threshborn":
			_update_threshborn(flat, distance, delta)
		"carapace_crawler":
			_update_carapace(flat, distance, delta)
		_:
			_update_glyph(flat, distance, delta)

	_animate_visual(delta)
	move_and_slide()


func _update_glyph(flat: Vector3, distance: float, delta: float) -> void:
	var direction: Vector3 = flat.normalized() if distance > 0.05 else Vector3.ZERO
	var side: Vector3 = Vector3(-direction.z, 0.0, direction.x)
	if distance > preferred_range:
		_set_horizontal_velocity((direction + side * sin(elapsed * 1.7) * 0.18).normalized() * move_speed, delta)
	elif distance < preferred_range * 0.65:
		_set_horizontal_velocity((-direction + side * 0.30 * strafe_sign).normalized() * move_speed * 0.75, delta)
	else:
		_set_horizontal_velocity(side * move_speed * 0.42 * strafe_sign, delta)

	if distance <= attack_range and fire_cooldown <= 0.0 and _has_line_of_sight():
		fire_cooldown = fire_interval
		_fire_projectile(accent, damage)


func _update_phase_lancer(flat: Vector3, distance: float, delta: float) -> void:
	var direction: Vector3 = flat.normalized() if distance > 0.05 else Vector3.ZERO
	var side: Vector3 = Vector3(-direction.z, 0.0, direction.x) * strafe_sign
	var desired: Vector3
	if distance > preferred_range * 1.15:
		desired = (direction * 0.75 + side * 0.66).normalized() * move_speed
	elif distance < preferred_range * 0.72:
		desired = (-direction * 0.55 + side).normalized() * move_speed
	else:
		desired = side * move_speed

	if ability_cooldown <= 0.0 and distance < 17.0 and distance > 4.0:
		ability_cooldown = 2.4
		strafe_sign *= -1.0
		desired = side * move_speed * 2.25
		_spawn_dash_echo()

	_set_horizontal_velocity(desired, delta, 22.0)
	if distance <= attack_range and fire_cooldown <= 0.0 and _has_line_of_sight():
		fire_cooldown = fire_interval
		_fire_projectile(accent, damage)


func _update_threshborn(flat: Vector3, distance: float, delta: float) -> void:
	var direction: Vector3 = flat.normalized() if distance > 0.05 else Vector3.ZERO
	if distance > preferred_range:
		_set_horizontal_velocity(direction * move_speed, delta, 9.0)
	else:
		_set_horizontal_velocity(Vector3.ZERO, delta, 12.0)

	if distance <= 3.4 and melee_cooldown <= 0.0:
		melee_cooldown = 1.35
		_heavy_slam()
	elif distance <= attack_range and fire_cooldown <= 0.0 and _has_line_of_sight():
		fire_cooldown = fire_interval
		_fire_projectile(accent, damage)


func _update_carapace(flat: Vector3, distance: float, delta: float) -> void:
	var direction: Vector3 = flat.normalized() if distance > 0.05 else Vector3.ZERO
	var speed_scale: float = 1.0
	if ability_cooldown <= 0.0 and distance < 15.0 and distance > 5.0:
		ability_cooldown = 2.7
		speed_scale = 2.15
		_spawn_dash_echo()
	_set_horizontal_velocity(direction * move_speed * speed_scale, delta, 28.0)

	if distance <= 2.1 and melee_cooldown <= 0.0:
		melee_cooldown = 0.95
		_carapace_bite()


func _set_horizontal_velocity(target_velocity: Vector3, delta: float, acceleration_value: float = 16.0) -> void:
	velocity.x = move_toward(velocity.x, target_velocity.x, acceleration_value * delta)
	velocity.z = move_toward(velocity.z, target_velocity.z, acceleration_value * delta)


func _configure_unit() -> void:
	match unit_type:
		"phase_lancer":
			max_health = 82
			move_speed = 4.5
			attack_range = 24.0
			preferred_range = 13.0
			fire_interval = 0.52
			damage = 8
			turn_speed = 8.5
			body_height = 2.15
			accent = Color(0.62, 0.18, 1.0)
		"threshborn":
			max_health = 340
			move_speed = 1.72
			attack_range = 20.0
			preferred_range = 7.2
			fire_interval = 0.78
			damage = 15
			turn_speed = 4.1
			body_height = 2.45
			accent = Color(0.04, 0.78, 1.0)
		"carapace_crawler":
			max_health = 185
			move_speed = 5.0
			attack_range = 2.2
			preferred_range = 1.5
			fire_interval = 99.0
			damage = 17
			turn_speed = 9.5
			body_height = 1.15
			accent = Color(1.0, 0.10, 0.035)
		_:
			unit_type = "glyph_crawler"
			max_health = 105
			move_speed = 2.9
			attack_range = 18.5
			preferred_range = 9.5
			fire_interval = 0.72
			damage = 7
			turn_speed = 6.2
			body_height = 1.55
			accent = Color(1.0, 0.48, 0.05)


func take_damage(amount: int) -> void:
	if dead or amount <= 0:
		return
	health = maxi(0, health - amount)
	_flash_hit()
	if health <= 0:
		_die()


func _has_line_of_sight() -> bool:
	if not is_instance_valid(target):
		return false
	var ray_from: Vector3 = global_position + Vector3.UP * maxf(0.45, body_height * 0.48)
	var ray_to: Vector3 = target.global_position + Vector3.UP * 0.55
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(ray_from, ray_to)
	query.exclude = [get_rid()]
	query.collide_with_areas = false
	query.collide_with_bodies = true
	var result: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	return not result.is_empty() and result.get("collider") == target


func _fire_projectile(color: Color, hit_damage: int) -> void:
	if not is_instance_valid(target):
		return
	var from: Vector3 = global_position + Vector3.UP * maxf(0.55, body_height * 0.52)
	if muzzle != null:
		from = muzzle.global_position
	var to: Vector3 = target.global_position + Vector3.UP * 0.48
	_spawn_tracer(from, to, color)
	if target.has_method("take_damage"):
		target.call("take_damage", hit_damage)


func _heavy_slam() -> void:
	if not is_instance_valid(target):
		return
	_spawn_ground_pulse(Color(0.05, 0.75, 1.0), 2.6)
	if global_position.distance_to(target.global_position) <= 3.8 and target.has_method("take_damage"):
		target.call("take_damage", 23)


func _carapace_bite() -> void:
	if not is_instance_valid(target):
		return
	_spawn_ground_pulse(Color(1.0, 0.08, 0.025), 1.35)
	if global_position.distance_to(target.global_position) <= 2.35 and target.has_method("take_damage"):
		target.call("take_damage", 20)


func _spawn_tracer(from: Vector3, to: Vector3, color: Color) -> void:
	var tracer: MeshInstance3D = MeshInstance3D.new()
	var line_mesh: ImmediateMesh = ImmediateMesh.new()
	var material: StandardMaterial3D = _make_emissive(color, 7.0)
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	line_mesh.surface_begin(Mesh.PRIMITIVE_LINES, material)
	line_mesh.surface_add_vertex(Vector3.ZERO)
	line_mesh.surface_add_vertex(to - from)
	line_mesh.surface_end()
	tracer.mesh = line_mesh
	get_tree().current_scene.add_child(tracer)
	tracer.global_position = from
	get_tree().create_timer(0.06).timeout.connect(tracer.queue_free)


func _spawn_ground_pulse(color: Color, radius_value: float) -> void:
	var pulse: MeshInstance3D = MeshInstance3D.new()
	var torus: TorusMesh = TorusMesh.new()
	torus.inner_radius = 0.35
	torus.outer_radius = 0.55
	torus.rings = 20
	torus.ring_segments = 8
	pulse.mesh = torus
	pulse.material_override = _make_emissive(color, 5.0)
	get_tree().current_scene.add_child(pulse)
	pulse.global_position = global_position + Vector3.UP * 0.06
	pulse.scale = Vector3(0.2, 0.2, 0.2)
	var tween: Tween = pulse.create_tween()
	tween.tween_property(pulse, "scale", Vector3(radius_value, 0.12, radius_value), 0.20)
	tween.parallel().tween_property(pulse, "transparency", 1.0, 0.20)
	tween.tween_callback(pulse.queue_free)


func _spawn_dash_echo() -> void:
	if visual_root == null:
		return
	var ring: MeshInstance3D = MeshInstance3D.new()
	var torus: TorusMesh = TorusMesh.new()
	torus.inner_radius = 0.50
	torus.outer_radius = 0.62
	torus.rings = 16
	torus.ring_segments = 8
	ring.mesh = torus
	ring.material_override = _make_emissive(accent, 4.0)
	get_tree().current_scene.add_child(ring)
	ring.global_position = global_position + Vector3.UP * maxf(0.6, body_height * 0.45)
	ring.rotation_degrees.x = 90.0
	var tween: Tween = ring.create_tween()
	tween.tween_property(ring, "scale", Vector3(2.1, 2.1, 2.1), 0.16)
	tween.tween_callback(ring.queue_free)


func _flash_hit() -> void:
	if armor_material == null:
		return
	armor_material.emission_enabled = true
	armor_material.emission = Color(1.0, 0.08, 0.025)
	armor_material.emission_energy_multiplier = 3.5
	get_tree().create_timer(0.07).timeout.connect(_clear_hit_flash)


func _clear_hit_flash() -> void:
	if armor_material != null:
		armor_material.emission_enabled = false


func _die() -> void:
	dead = true
	remove_from_group("enemies")
	collision_layer = 0
	collision_mask = 0
	velocity = Vector3.ZERO
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "rotation:z", deg_to_rad(78.0 if unit_type != "carapace_crawler" else 22.0), 0.32)
	tween.tween_property(self, "position:y", position.y - 0.35, 0.32)
	tween.tween_property(self, "scale", scale * Vector3(1.06, 0.55, 1.06), 0.32)
	tween.chain().tween_callback(queue_free)


func _build_collision() -> void:
	var collision: CollisionShape3D = CollisionShape3D.new()
	if unit_type == "carapace_crawler":
		var box: BoxShape3D = BoxShape3D.new()
		box.size = Vector3(1.25, 0.85, 2.25)
		collision.shape = box
		collision.position = Vector3(0.0, -0.16, 0.0)
	else:
		var capsule: CapsuleShape3D = CapsuleShape3D.new()
		capsule.radius = 0.58 if unit_type == "threshborn" else 0.40
		capsule.height = body_height
		collision.shape = capsule
		collision.position = Vector3(0.0, 0.02, 0.0)
	add_child(collision)


func _build_visuals() -> void:
	visual_root = Node3D.new()
	visual_root.name = "HELIX_BioforgeRig"
	add_child(visual_root)

	match unit_type:
		"phase_lancer":
			_build_phase_lancer()
		"threshborn":
			_build_threshborn()
		"carapace_crawler":
			_build_carapace_crawler()
		_:
			_build_glyph_crawler()


func _build_glyph_crawler() -> void:
	var shell: StandardMaterial3D = _make_material(Color(0.095, 0.105, 0.11), 0.76, 0.30)
	armor_material = _make_material(Color(0.23, 0.19, 0.13), 0.72, 0.29)
	var hide: StandardMaterial3D = _make_material(Color(0.045, 0.05, 0.052), 0.05, 0.90)
	energy_material = _make_emissive(accent, 4.3)

	_add_capsule(0.31, 0.86, Vector3(0.0, 0.03, 0.08), hide, Vector3(10.0, 0.0, 0.0))
	_add_sphere(Vector3(0.72, 0.62, 0.58), Vector3(0.0, 0.34, 0.10), armor_material)
	_add_sphere(Vector3(0.47, 0.42, 0.44), Vector3(0.0, 0.73, -0.02), shell)
	_add_box(Vector3(0.30, 0.11, 0.055), Vector3(0.0, 0.76, -0.23), energy_material)
	_add_sphere(Vector3(0.18, 0.18, 0.18), Vector3(0.0, 0.28, 0.38), energy_material)
	for side: float in [-1.0, 1.0]:
		_add_capsule(0.12, 0.48, Vector3(0.34 * side, -0.10, 0.02), hide, Vector3(0.0, 0.0, 10.0 * side))
		_add_capsule(0.13, 0.48, Vector3(0.21 * side, -0.54, 0.02), hide, Vector3(0.0, 0.0, 5.0 * side))
		_add_box(Vector3(0.24, 0.30, 0.28), Vector3(0.21 * side, -0.50, -0.03), shell)
		_add_spike(Vector3(0.25 * side, 0.87, 0.02), 0.08, 0.36, armor_material, Vector3(0.0, 0.0, -18.0 * side))

	_add_box(Vector3(0.19, 0.16, 0.64), Vector3(0.22, 0.02, -0.42), shell, Vector3(0.0, 0.0, -12.0))
	_add_box(Vector3(0.26, 0.12, 0.30), Vector3(0.22, 0.10, -0.44), armor_material, Vector3(0.0, 0.0, -12.0))
	_add_cylinder(0.035, 0.34, Vector3(0.22, 0.02, -0.87), shell, Vector3(90.0, 0.0, 0.0))
	_add_box(Vector3(0.09, 0.06, 0.18), Vector3(0.22, 0.17, -0.46), energy_material)
	_set_muzzle(Vector3(0.22, 0.02, -1.08))


func _build_phase_lancer() -> void:
	var shell: StandardMaterial3D = _make_material(Color(0.055, 0.06, 0.075), 0.80, 0.22)
	armor_material = _make_material(Color(0.16, 0.13, 0.21), 0.74, 0.25)
	var hide: StandardMaterial3D = _make_material(Color(0.025, 0.028, 0.035), 0.08, 0.82)
	energy_material = _make_emissive(accent, 5.3)

	_add_capsule(0.22, 1.12, Vector3(0.0, 0.08, 0.02), hide)
	_add_box(Vector3(0.64, 0.34, 0.38), Vector3(0.0, 0.42, 0.0), armor_material, Vector3(-6.0, 0.0, 0.0))
	_add_sphere(Vector3(0.34, 0.38, 0.36), Vector3(0.0, 0.98, -0.02), shell)
	_add_box(Vector3(0.22, 0.075, 0.045), Vector3(0.0, 1.0, -0.205), energy_material)
	for side: float in [-1.0, 1.0]:
		_add_capsule(0.095, 0.70, Vector3(0.38 * side, 0.12, -0.01), hide, Vector3(0.0, 0.0, 7.0 * side))
		_add_capsule(0.11, 0.72, Vector3(0.18 * side, -0.62, 0.02), hide)
		_add_box(Vector3(0.19, 0.38, 0.20), Vector3(0.18 * side, -0.57, -0.03), shell)
		_add_spike(Vector3(0.24 * side, 1.15, 0.06), 0.06, 0.58, armor_material, Vector3(18.0, 0.0, -24.0 * side))
		_add_spike(Vector3(0.40 * side, 0.48, 0.08), 0.055, 0.46, armor_material, Vector3(5.0, 0.0, -55.0 * side))

	_add_box(Vector3(0.12, 0.11, 1.05), Vector3(0.24, 0.13, -0.58), shell, Vector3(0.0, 0.0, -8.0))
	_add_box(Vector3(0.18, 0.06, 0.64), Vector3(0.24, 0.20, -0.63), energy_material, Vector3(0.0, 0.0, -8.0))
	_add_cylinder(0.026, 0.54, Vector3(0.24, 0.13, -1.31), shell, Vector3(90.0, 0.0, 0.0))
	_set_muzzle(Vector3(0.24, 0.13, -1.58))


func _build_threshborn() -> void:
	var shell: StandardMaterial3D = _make_material(Color(0.09, 0.105, 0.11), 0.82, 0.25)
	armor_material = _make_material(Color(0.27, 0.25, 0.22), 0.64, 0.34)
	var hide: StandardMaterial3D = _make_material(Color(0.055, 0.058, 0.055), 0.05, 0.88)
	energy_material = _make_emissive(accent, 4.8)

	_add_capsule(0.43, 1.30, Vector3(0.0, 0.04, 0.12), hide, Vector3(12.0, 0.0, 0.0))
	_add_sphere(Vector3(1.24, 0.94, 0.82), Vector3(0.0, 0.48, 0.07), armor_material)
	_add_box(Vector3(1.16, 0.32, 0.60), Vector3(0.0, 0.53, -0.08), shell, Vector3(-6.0, 0.0, 0.0))
	_add_sphere(Vector3(0.48, 0.44, 0.48), Vector3(0.0, 1.12, -0.10), shell)
	_add_box(Vector3(0.31, 0.09, 0.06), Vector3(0.0, 1.12, -0.36), energy_material)
	_add_sphere(Vector3(0.27, 0.27, 0.27), Vector3(0.0, 0.42, -0.46), energy_material)
	for side: float in [-1.0, 1.0]:
		_add_sphere(Vector3(0.48, 0.48, 0.48), Vector3(0.66 * side, 0.48, 0.02), armor_material)
		_add_capsule(0.19, 0.76, Vector3(0.67 * side, 0.05, 0.02), hide, Vector3(0.0, 0.0, 8.0 * side))
		_add_capsule(0.20, 0.78, Vector3(0.31 * side, -0.78, 0.03), hide)
		_add_box(Vector3(0.42, 0.46, 0.42), Vector3(0.31 * side, -0.70, -0.05), shell)

	# Integrated bio-cannon on the right arm.
	_add_cylinder(0.25, 0.66, Vector3(0.74, 0.02, -0.32), shell, Vector3(90.0, 0.0, 0.0))
	_add_cylinder(0.15, 0.62, Vector3(0.74, 0.02, -0.88), armor_material, Vector3(90.0, 0.0, 0.0))
	_add_sphere(Vector3(0.22, 0.22, 0.22), Vector3(0.74, 0.02, -1.19), energy_material)
	_set_muzzle(Vector3(0.74, 0.02, -1.29))


func _build_carapace_crawler() -> void:
	var shell: StandardMaterial3D = _make_material(Color(0.07, 0.075, 0.075), 0.64, 0.42)
	armor_material = _make_material(Color(0.18, 0.14, 0.13), 0.68, 0.36)
	var hide: StandardMaterial3D = _make_material(Color(0.035, 0.027, 0.026), 0.02, 0.92)
	energy_material = _make_emissive(accent, 5.6)

	_add_capsule(0.40, 1.75, Vector3(0.0, -0.03, 0.10), hide, Vector3(90.0, 0.0, 0.0))
	_add_sphere(Vector3(0.92, 0.62, 1.40), Vector3(0.0, 0.02, 0.08), armor_material)
	_add_sphere(Vector3(0.66, 0.52, 0.72), Vector3(0.0, -0.04, -0.82), shell)
	_add_box(Vector3(0.42, 0.08, 0.06), Vector3(0.0, 0.02, -1.18), energy_material)
	_add_box(Vector3(0.44, 0.12, 0.28), Vector3(0.0, -0.21, -1.18), shell, Vector3(-9.0, 0.0, 0.0))
	for side: float in [-1.0, 1.0]:
		for z_index: int in range(2):
			var z_pos: float = -0.40 + float(z_index) * 0.82
			_add_capsule(0.11, 0.72, Vector3(0.52 * side, -0.34, z_pos), hide, Vector3(0.0, 0.0, 48.0 * side))
			_add_capsule(0.10, 0.58, Vector3(0.76 * side, -0.62, z_pos), shell, Vector3(0.0, 0.0, 18.0 * side))
	for i: int in range(6):
		var z_spine: float = 0.65 - float(i) * 0.28
		_add_spike(Vector3(0.0, 0.46, z_spine), 0.09 - float(i) * 0.006, 0.54, armor_material, Vector3(-14.0 + float(i) * 4.0, 0.0, 0.0))
	_add_sphere(Vector3(0.16, 0.16, 0.16), Vector3(-0.18, 0.05, -1.13), energy_material)
	_add_sphere(Vector3(0.16, 0.16, 0.16), Vector3(0.18, 0.05, -1.13), energy_material)


func _animate_visual(_delta: float) -> void:
	if visual_root == null:
		return
	var speed: float = Vector2(velocity.x, velocity.z).length()
	var movement: float = clampf(speed / maxf(move_speed, 0.1), 0.0, 2.2)
	if unit_type == "carapace_crawler":
		visual_root.position.y = sin(elapsed * 8.0) * 0.025 * movement
		visual_root.rotation.z = sin(elapsed * 6.0) * 0.025 * movement
	else:
		visual_root.position.y = sin(elapsed * 6.5) * 0.018 * movement
		visual_root.rotation.z = sin(elapsed * 5.0) * 0.018 * movement


func _set_muzzle(local_position: Vector3) -> void:
	muzzle = Marker3D.new()
	muzzle.position = local_position
	visual_root.add_child(muzzle)


func _parent_visual(node: Node3D) -> void:
	if visual_root != null:
		visual_root.add_child(node)
	else:
		add_child(node)


func _add_box(size: Vector3, local_position: Vector3, material: Material, rotation_value: Vector3 = Vector3.ZERO) -> void:
	var node: MeshInstance3D = MeshInstance3D.new()
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.position = local_position
	node.rotation_degrees = rotation_value
	node.material_override = material
	_parent_visual(node)


func _add_sphere(size: Vector3, local_position: Vector3, material: Material) -> void:
	var node: MeshInstance3D = MeshInstance3D.new()
	var mesh: SphereMesh = SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	mesh.radial_segments = 12
	mesh.rings = 6
	node.mesh = mesh
	node.scale = size
	node.position = local_position
	node.material_override = material
	_parent_visual(node)


func _add_capsule(radius: float, height: float, local_position: Vector3, material: Material, rotation_value: Vector3 = Vector3.ZERO) -> void:
	var node: MeshInstance3D = MeshInstance3D.new()
	var mesh: CapsuleMesh = CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = maxf(height, radius * 2.05)
	mesh.radial_segments = 10
	mesh.rings = 4
	node.mesh = mesh
	node.position = local_position
	node.rotation_degrees = rotation_value
	node.material_override = material
	_parent_visual(node)


func _add_cylinder(radius: float, height: float, local_position: Vector3, material: Material, rotation_value: Vector3 = Vector3.ZERO) -> void:
	var node: MeshInstance3D = MeshInstance3D.new()
	var mesh: CylinderMesh = CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius * 1.08
	mesh.height = height
	mesh.radial_segments = 10
	node.mesh = mesh
	node.position = local_position
	node.rotation_degrees = rotation_value
	node.material_override = material
	_parent_visual(node)


func _add_spike(local_position: Vector3, radius: float, height: float, material: Material, rotation_value: Vector3 = Vector3.ZERO) -> void:
	var node: MeshInstance3D = MeshInstance3D.new()
	var mesh: CylinderMesh = CylinderMesh.new()
	mesh.top_radius = 0.0
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 7
	node.mesh = mesh
	node.position = local_position
	node.rotation_degrees = rotation_value
	node.material_override = material
	_parent_visual(node)


func _make_material(color: Color, metallic: float, roughness: float) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metallic
	material.roughness = roughness
	return material


func _make_emissive(color: Color, energy: float) -> StandardMaterial3D:
	var material: StandardMaterial3D = _make_material(color, 0.25, 0.18)
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = energy
	return material
