extends Node3D

signal weapon_changed(display_name: String)
signal ammo_changed(current_mag: int, reserve_ammo: int)

const WEAPONS: Array[Dictionary] = [
	{"name":"VX-7 AEGIS","mag":30,"reserve":150,"rpm":620.0,"reload":1.85,"semi":false,"recoil":0.010,"builder":"vx7"},
	{"name":"ARC-9 WRAITH","mag":42,"reserve":210,"rpm":880.0,"reload":1.55,"semi":false,"recoil":0.007,"builder":"arc9"},
	{"name":"MANTIS-LR","mag":8,"reserve":40,"rpm":115.0,"reload":2.35,"semi":true,"recoil":0.026,"builder":"mantis"},
	{"name":"NOVA-12","mag":10,"reserve":50,"rpm":95.0,"reload":2.10,"semi":true,"recoil":0.032,"builder":"nova"},
	{"name":"HELION-HMG","mag":64,"reserve":256,"rpm":720.0,"reload":2.85,"semi":false,"recoil":0.014,"builder":"helion"},
	{"name":"PULSE-CARBINE","mag":24,"reserve":120,"rpm":520.0,"reload":1.70,"semi":false,"recoil":0.009,"builder":"pulse"}
]

var current_index: int = 0
var current_mag: int = 30
var reserve_ammo: int = 150
var fire_cooldown: float = 0.0
var reload_timer: float = 0.0
var trigger_pressed: bool = false
var trigger_was_pressed: bool = false
var aiming: bool = false
var motion_time: float = 0.0
var motion_amount: float = 0.0
var sprinting: bool = false

var weapon_root: Node3D
var arms_root: Node3D
var muzzle: Marker3D
var muzzle_flash: MeshInstance3D
var muzzle_light: OmniLight3D

var base_position: Vector3 = Vector3(0.38, -0.34, -0.78)
var ads_position: Vector3 = Vector3(0.02, -0.24, -0.57)
var camera_ref: Camera3D

var graphite: StandardMaterial3D
var gunmetal: StandardMaterial3D
var olive: StandardMaterial3D
var dark: StandardMaterial3D
var glove: StandardMaterial3D
var suit: StandardMaterial3D
var blue: StandardMaterial3D
var cyan: StandardMaterial3D


func _ready() -> void:
	camera_ref = get_parent() as Camera3D
	_build_materials()
	arms_root = Node3D.new()
	arms_root.name = "VANGUARD_M1_ARMS"
	add_child(arms_root)
	weapon_root = Node3D.new()
	weapon_root.name = "WEAPON_ROOT"
	add_child(weapon_root)
	_build_arms()
	equip_weapon(0)


func _process(delta: float) -> void:
	fire_cooldown = maxf(0.0, fire_cooldown - delta)
	if reload_timer > 0.0:
		reload_timer -= delta
		if reload_timer <= 0.0:
			_finish_reload()

	var config: Dictionary = WEAPONS[current_index]
	var semi_auto: bool = bool(config["semi"])
	var can_fire: bool = trigger_pressed and (not semi_auto or not trigger_was_pressed)
	if can_fire and fire_cooldown <= 0.0 and reload_timer <= 0.0:
		_fire()
	trigger_was_pressed = trigger_pressed

	motion_time += delta * (8.0 if sprinting else 5.6)
	var bob_scale: float = 0.014 * motion_amount * (1.65 if sprinting else 1.0)
	if aiming:
		bob_scale *= 0.28
	var bob: Vector3 = Vector3(sin(motion_time) * bob_scale, absf(cos(motion_time * 2.0)) * bob_scale * 0.65, 0.0)
	var target: Vector3 = (ads_position if aiming else base_position) + bob
	position = position.lerp(target, clampf(delta * 12.0, 0.0, 1.0))
	rotation.z = lerpf(rotation.z, sin(motion_time) * 0.012 * motion_amount, clampf(delta * 9.0, 0.0, 1.0))


func set_trigger(value: bool) -> void:
	trigger_pressed = value


func set_aim(value: bool) -> void:
	aiming = value


func update_motion(speed_ratio: float, is_sprinting: bool) -> void:
	motion_amount = clampf(speed_ratio, 0.0, 1.0)
	sprinting = is_sprinting


func request_reload() -> void:
	if reload_timer > 0.0:
		return
	var config: Dictionary = WEAPONS[current_index]
	var capacity: int = int(config["mag"])
	if current_mag >= capacity or reserve_ammo <= 0:
		return
	reload_timer = float(config["reload"])
	var tween: Tween = create_tween()
	tween.tween_property(self, "rotation_degrees:x", 8.0, reload_timer * 0.35)
	tween.tween_property(self, "rotation_degrees:x", 0.0, reload_timer * 0.65)


func equip_weapon(index: int) -> void:
	current_index = wrapi(index, 0, WEAPONS.size())
	for child: Node in weapon_root.get_children():
		child.queue_free()
	muzzle = null
	muzzle_flash = null
	muzzle_light = null

	var config: Dictionary = WEAPONS[current_index]
	current_mag = int(config["mag"])
	reserve_ammo = int(config["reserve"])
	var builder: String = String(config["builder"])
	match builder:
		"arc9": _build_arc9()
		"mantis": _build_mantis()
		"nova": _build_nova()
		"helion": _build_helion()
		"pulse": _build_pulse()
		_: _build_vx7()
	_configure_view_position(builder)
	_build_muzzle_fx()
	weapon_changed.emit(String(config["name"]))
	ammo_changed.emit(current_mag, reserve_ammo)


func cycle_weapon(direction: int) -> void:
	equip_weapon(current_index + direction)


func get_weapon_name() -> String:
	return String(WEAPONS[current_index]["name"])


func _configure_view_position(builder: String) -> void:
	match builder:
		"arc9":
			base_position = Vector3(0.33, -0.35, -0.68)
			ads_position = Vector3(0.015, -0.235, -0.48)
		"mantis":
			base_position = Vector3(0.39, -0.36, -0.86)
			ads_position = Vector3(0.005, -0.225, -0.66)
		"nova":
			base_position = Vector3(0.40, -0.39, -0.78)
			ads_position = Vector3(0.015, -0.26, -0.59)
		"helion":
			base_position = Vector3(0.44, -0.42, -0.86)
			ads_position = Vector3(0.035, -0.29, -0.66)
		"pulse":
			base_position = Vector3(0.36, -0.35, -0.75)
			ads_position = Vector3(0.012, -0.235, -0.55)
		_:
			base_position = Vector3(0.38, -0.34, -0.78)
			ads_position = Vector3(0.02, -0.24, -0.57)
	position = base_position


func _fire() -> void:
	if current_mag <= 0:
		request_reload()
		return
	current_mag -= 1
	var config: Dictionary = WEAPONS[current_index]
	fire_cooldown = 60.0 / float(config["rpm"])
	ammo_changed.emit(current_mag, reserve_ammo)
	_flash_muzzle()
	_spawn_hit_spark()
	var recoil_value: float = float(config["recoil"])
	rotation.x -= recoil_value
	var tween: Tween = create_tween()
	tween.tween_property(self, "rotation:x", 0.0, 0.09)


func _finish_reload() -> void:
	var config: Dictionary = WEAPONS[current_index]
	var capacity: int = int(config["mag"])
	var needed: int = capacity - current_mag
	var taken: int = mini(needed, reserve_ammo)
	current_mag += taken
	reserve_ammo -= taken
	ammo_changed.emit(current_mag, reserve_ammo)


func _flash_muzzle() -> void:
	if muzzle_flash == null or muzzle_light == null:
		return
	muzzle_flash.visible = true
	muzzle_light.visible = true
	get_tree().create_timer(0.045).timeout.connect(_hide_muzzle)


func _hide_muzzle() -> void:
	if muzzle_flash != null:
		muzzle_flash.visible = false
	if muzzle_light != null:
		muzzle_light.visible = false


func _spawn_hit_spark() -> void:
	if camera_ref == null:
		return
	var from: Vector3 = camera_ref.global_position
	var to: Vector3 = from + (-camera_ref.global_transform.basis.z * 240.0)
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(from, to)
	query.collide_with_areas = false
	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return
	var spark: MeshInstance3D = MeshInstance3D.new()
	var mesh: SphereMesh = SphereMesh.new()
	mesh.radius = 0.045
	mesh.height = 0.09
	mesh.radial_segments = 8
	mesh.rings = 4
	spark.mesh = mesh
	spark.material_override = _emissive(Color(0.10, 0.72, 1.0), 5.5)
	get_tree().current_scene.add_child(spark)
	spark.global_position = hit["position"] + hit["normal"] * 0.025
	var tween: Tween = spark.create_tween()
	tween.tween_property(spark, "scale", Vector3(2.2, 2.2, 2.2), 0.06)
	tween.tween_property(spark, "scale", Vector3.ZERO, 0.08)
	tween.tween_callback(spark.queue_free)


func _build_materials() -> void:
	graphite = _mat(Color(0.055, 0.064, 0.068), 0.82, 0.24)
	gunmetal = _mat(Color(0.17, 0.19, 0.19), 0.74, 0.27)
	olive = _mat(Color(0.255, 0.285, 0.22), 0.58, 0.37)
	dark = _mat(Color(0.018, 0.024, 0.026), 0.42, 0.52)
	glove = _mat(Color(0.032, 0.038, 0.039), 0.10, 0.88)
	suit = _mat(Color(0.08, 0.095, 0.085), 0.24, 0.62)
	blue = _emissive(Color(0.03, 0.38, 0.96), 4.8)
	cyan = _emissive(Color(0.05, 0.78, 1.0), 3.4)


func _build_arms() -> void:
	_build_arm(-1.0, Vector3(-0.22, -0.19, -0.25), Vector3(72.0, -10.0, -18.0))
	_build_arm(1.0, Vector3(0.22, -0.17, -0.36), Vector3(72.0, 12.0, 18.0))


func _build_arm(side: float, base_pos: Vector3, rot: Vector3) -> void:
	var root: Node3D = Node3D.new()
	root.position = base_pos
	root.rotation_degrees = rot
	arms_root.add_child(root)
	_add_capsule(root, 0.085, 0.46, Vector3(0.0, 0.0, 0.10), suit)
	_add_box(root, Vector3(0.20, 0.10, 0.31), Vector3(0.0, 0.02, 0.03), olive, Vector3(-4.0, 0.0, 0.0))
	_add_box(root, Vector3(0.18, 0.07, 0.24), Vector3(0.0, 0.09, -0.02), gunmetal)
	_add_sphere(root, Vector3(0.10, 0.095, 0.10), Vector3(0.0, -0.02, -0.16), dark)

	# Palm and articulated armored fingers.
	_add_box(root, Vector3(0.18, 0.075, 0.17), Vector3(0.0, -0.02, -0.22), glove, Vector3(-8.0, 0.0, 0.0))
	for finger: int in range(4):
		var x_value: float = (float(finger) - 1.5) * 0.035
		_add_capsule(root, 0.017, 0.105, Vector3(x_value, -0.045, -0.31), glove, Vector3(72.0, 0.0, 0.0))
	_add_capsule(root, 0.020, 0.105, Vector3(0.095 * side, -0.03, -0.255), glove, Vector3(62.0, 0.0, 38.0 * side))
	_add_box(root, Vector3(0.16, 0.035, 0.10), Vector3(0.0, 0.035, -0.22), olive)


func _build_vx7() -> void:
	# Reference direction: armored military plasma rifle with a visible energy chamber.
	_add_box(weapon_root, Vector3(0.22, 0.19, 0.62), Vector3(0.0, 0.0, -0.20), graphite)
	_add_box(weapon_root, Vector3(0.24, 0.10, 0.46), Vector3(0.0, 0.12, -0.25), olive, Vector3(-3.0, 0.0, 0.0))
	_add_box(weapon_root, Vector3(0.18, 0.14, 0.36), Vector3(0.0, -0.12, -0.12), dark)
	_add_box(weapon_root, Vector3(0.20, 0.14, 0.32), Vector3(0.0, 0.02, 0.27), gunmetal)
	_add_box(weapon_root, Vector3(0.15, 0.09, 0.28), Vector3(0.0, 0.10, 0.39), graphite, Vector3(-7.0, 0.0, 0.0))
	_add_box(weapon_root, Vector3(0.12, 0.28, 0.16), Vector3(0.0, -0.22, -0.11), dark, Vector3(-7.0, 0.0, 0.0))
	_add_box(weapon_root, Vector3(0.18, 0.14, 0.36), Vector3(0.0, 0.0, -0.65), gunmetal)
	_add_energy_chamber(Vector3(0.0, 0.015, -0.55), 0.078, 0.34)
	_add_box(weapon_root, Vector3(0.13, 0.045, 0.36), Vector3(0.0, 0.175, -0.34), dark)
	_add_box(weapon_root, Vector3(0.13, 0.09, 0.18), Vector3(0.0, 0.22, -0.31), graphite)
	_add_box(weapon_root, Vector3(0.07, 0.035, 0.02), Vector3(0.0, 0.23, -0.415), cyan)
	_add_cylinder(weapon_root, 0.032, 0.54, Vector3(0.0, 0.0, -1.02), graphite, Vector3(90.0, 0.0, 0.0))
	_add_cylinder(weapon_root, 0.050, 0.15, Vector3(0.0, 0.0, -1.36), dark, Vector3(90.0, 0.0, 0.0))
	_set_muzzle(Vector3(0.0, 0.0, -1.45))


func _build_arc9() -> void:
	_add_box(weapon_root, Vector3(0.20, 0.18, 0.48), Vector3(0.0, 0.0, -0.22), graphite)
	_add_box(weapon_root, Vector3(0.22, 0.09, 0.30), Vector3(0.0, 0.12, -0.26), olive)
	_add_box(weapon_root, Vector3(0.13, 0.24, 0.14), Vector3(0.0, -0.20, -0.04), dark, Vector3(10.0, 0.0, 0.0))
	_add_box(weapon_root, Vector3(0.14, 0.11, 0.22), Vector3(0.0, 0.0, 0.20), gunmetal)
	_add_energy_chamber(Vector3(-0.075, 0.015, -0.50), 0.050, 0.28)
	_add_energy_chamber(Vector3(0.075, 0.015, -0.50), 0.050, 0.28)
	_add_cylinder(weapon_root, 0.025, 0.34, Vector3(0.0, 0.0, -0.79), graphite, Vector3(90.0, 0.0, 0.0))
	_add_box(weapon_root, Vector3(0.11, 0.05, 0.25), Vector3(0.0, 0.16, -0.26), dark)
	_set_muzzle(Vector3(0.0, 0.0, -0.99))


func _build_mantis() -> void:
	_add_box(weapon_root, Vector3(0.18, 0.16, 0.72), Vector3(0.0, 0.0, -0.25), graphite)
	_add_box(weapon_root, Vector3(0.20, 0.08, 0.55), Vector3(0.0, 0.12, -0.30), olive)
	_add_box(weapon_root, Vector3(0.16, 0.11, 0.42), Vector3(0.0, 0.00, -0.82), gunmetal)
	_add_energy_chamber(Vector3(0.0, 0.02, -0.61), 0.060, 0.42)
	_add_box(weapon_root, Vector3(0.13, 0.13, 0.40), Vector3(0.0, 0.02, 0.34), gunmetal)
	_add_box(weapon_root, Vector3(0.14, 0.065, 0.45), Vector3(0.0, 0.19, -0.29), dark)
	_add_cylinder(weapon_root, 0.060, 0.24, Vector3(0.0, 0.22, -0.30), graphite, Vector3(90.0, 0.0, 0.0))
	_add_cylinder(weapon_root, 0.028, 0.92, Vector3(0.0, 0.0, -1.37), graphite, Vector3(90.0, 0.0, 0.0))
	_add_cylinder(weapon_root, 0.044, 0.24, Vector3(0.0, 0.0, -1.95), dark, Vector3(90.0, 0.0, 0.0))
	_set_muzzle(Vector3(0.0, 0.0, -2.08))


func _build_nova() -> void:
	_add_box(weapon_root, Vector3(0.25, 0.22, 0.58), Vector3(0.0, 0.0, -0.18), graphite)
	_add_box(weapon_root, Vector3(0.27, 0.10, 0.42), Vector3(0.0, 0.14, -0.24), olive)
	_add_box(weapon_root, Vector3(0.17, 0.31, 0.16), Vector3(0.0, -0.22, -0.08), dark, Vector3(-8.0, 0.0, 0.0))
	_add_box(weapon_root, Vector3(0.23, 0.18, 0.40), Vector3(0.0, 0.0, -0.65), gunmetal)
	_add_box(weapon_root, Vector3(0.26, 0.16, 0.26), Vector3(0.0, -0.03, -0.82), olive)
	_add_energy_chamber(Vector3(0.0, 0.09, -0.52), 0.067, 0.30)
	_add_cylinder(weapon_root, 0.050, 0.58, Vector3(0.0, 0.0, -1.16), graphite, Vector3(90.0, 0.0, 0.0))
	_add_cylinder(weapon_root, 0.067, 0.15, Vector3(0.0, 0.0, -1.51), dark, Vector3(90.0, 0.0, 0.0))
	_set_muzzle(Vector3(0.0, 0.0, -1.61))


func _build_helion() -> void:
	_add_box(weapon_root, Vector3(0.31, 0.28, 0.76), Vector3(0.0, -0.02, -0.24), graphite)
	_add_box(weapon_root, Vector3(0.34, 0.11, 0.58), Vector3(0.0, 0.14, -0.28), olive)
	_add_box(weapon_root, Vector3(0.20, 0.36, 0.18), Vector3(0.0, -0.28, -0.06), dark)
	_add_energy_chamber(Vector3(0.0, 0.03, -0.61), 0.085, 0.44)
	_add_box(weapon_root, Vector3(0.28, 0.20, 0.44), Vector3(0.0, 0.0, -0.86), gunmetal)
	for side: float in [-1.0, 0.0, 1.0]:
		_add_cylinder(weapon_root, 0.027, 0.62, Vector3(side * 0.055, 0.01, -1.32), graphite, Vector3(90.0, 0.0, 0.0))
	_add_box(weapon_root, Vector3(0.18, 0.075, 0.34), Vector3(0.0, 0.22, -0.33), dark)
	_set_muzzle(Vector3(0.0, 0.01, -1.66))


func _build_pulse() -> void:
	_add_box(weapon_root, Vector3(0.19, 0.17, 0.62), Vector3(0.0, 0.0, -0.22), graphite)
	_add_box(weapon_root, Vector3(0.21, 0.08, 0.45), Vector3(0.0, 0.13, -0.28), olive)
	_add_box(weapon_root, Vector3(0.18, 0.15, 0.35), Vector3(0.0, 0.01, 0.25), gunmetal)
	_add_box(weapon_root, Vector3(0.14, 0.25, 0.14), Vector3(0.0, -0.20, -0.03), dark, Vector3(8.0, 0.0, 0.0))
	_add_energy_chamber(Vector3(0.0, 0.02, -0.52), 0.055, 0.34)
	_add_box(weapon_root, Vector3(0.12, 0.05, 0.34), Vector3(0.0, 0.17, -0.31), dark)
	_add_cylinder(weapon_root, 0.028, 0.50, Vector3(0.0, 0.0, -1.02), graphite, Vector3(90.0, 0.0, 0.0))
	_set_muzzle(Vector3(0.0, 0.0, -1.30))


func _add_energy_chamber(pos: Vector3, radius: float, length: float) -> void:
	_add_cylinder(weapon_root, radius * 1.28, length + 0.08, pos, dark, Vector3(90.0, 0.0, 0.0))
	_add_cylinder(weapon_root, radius, length, pos, blue, Vector3(90.0, 0.0, 0.0))
	_add_cylinder(weapon_root, radius * 0.42, length * 0.88, pos, cyan, Vector3(90.0, 0.0, 0.0))


func _set_muzzle(pos: Vector3) -> void:
	muzzle = Marker3D.new()
	muzzle.position = pos
	weapon_root.add_child(muzzle)


func _build_muzzle_fx() -> void:
	if muzzle == null:
		return
	muzzle_flash = MeshInstance3D.new()
	var flash_mesh: SphereMesh = SphereMesh.new()
	flash_mesh.radius = 0.055
	flash_mesh.height = 0.16
	flash_mesh.radial_segments = 8
	flash_mesh.rings = 4
	muzzle_flash.mesh = flash_mesh
	muzzle_flash.position = muzzle.position
	muzzle_flash.scale = Vector3(1.0, 1.0, 2.6)
	muzzle_flash.material_override = _emissive(Color(0.08, 0.64, 1.0), 7.0)
	muzzle_flash.visible = false
	weapon_root.add_child(muzzle_flash)
	muzzle_light = OmniLight3D.new()
	muzzle_light.position = muzzle.position
	muzzle_light.light_color = Color(0.10, 0.58, 1.0)
	muzzle_light.light_energy = 5.5
	muzzle_light.omni_range = 2.3
	muzzle_light.visible = false
	muzzle_light.shadow_enabled = false
	weapon_root.add_child(muzzle_light)


func _add_box(parent_node: Node3D, size_value: Vector3, pos: Vector3, mat: Material, rot: Vector3 = Vector3.ZERO) -> void:
	var node: MeshInstance3D = MeshInstance3D.new()
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = size_value
	node.mesh = mesh
	node.position = pos
	node.rotation_degrees = rot
	node.material_override = mat
	parent_node.add_child(node)


func _add_sphere(parent_node: Node3D, scale_value: Vector3, pos: Vector3, mat: Material) -> void:
	var node: MeshInstance3D = MeshInstance3D.new()
	var mesh: SphereMesh = SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	mesh.radial_segments = 14
	mesh.rings = 7
	node.mesh = mesh
	node.scale = scale_value
	node.position = pos
	node.material_override = mat
	parent_node.add_child(node)


func _add_capsule(parent_node: Node3D, radius: float, height: float, pos: Vector3, mat: Material, rot: Vector3 = Vector3.ZERO) -> void:
	var node: MeshInstance3D = MeshInstance3D.new()
	var mesh: CapsuleMesh = CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = maxf(height, radius * 2.05)
	mesh.radial_segments = 10
	mesh.rings = 4
	node.mesh = mesh
	node.position = pos
	node.rotation_degrees = rot
	node.material_override = mat
	parent_node.add_child(node)


func _add_cylinder(parent_node: Node3D, radius: float, height: float, pos: Vector3, mat: Material, rot: Vector3 = Vector3.ZERO) -> void:
	var node: MeshInstance3D = MeshInstance3D.new()
	var mesh: CylinderMesh = CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius * 1.04
	mesh.height = height
	mesh.radial_segments = 12
	node.mesh = mesh
	node.position = pos
	node.rotation_degrees = rot
	node.material_override = mat
	parent_node.add_child(node)


func _mat(color: Color, metallic_value: float, roughness_value: float) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metallic_value
	material.roughness = roughness_value
	return material


func _emissive(color: Color, power: float) -> StandardMaterial3D:
	var material: StandardMaterial3D = _mat(color, 0.30, 0.16)
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = power
	return material
