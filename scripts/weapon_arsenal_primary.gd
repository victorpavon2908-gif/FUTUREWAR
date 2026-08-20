extends "res://scripts/weapon_arsenal.gd"

# FUTUREWAR PRIMARY SIDEARM PASS
# Original game-ready model inspired by the supplied tan/black tactical-pistol reference.
# No manufacturer logos or copied texture assets are used.

const PISTOL_MAG: int = 15
const PISTOL_RESERVE: int = 90
const PISTOL_RPM: float = 390.0
const PISTOL_RELOAD: float = 1.55
const PISTOL_RECOIL: float = 0.020

var pistol_tan: StandardMaterial3D
var pistol_tan_dark: StandardMaterial3D
var slide_black: StandardMaterial3D
var steel: StandardMaterial3D
var sight_green: StandardMaterial3D
var glove_black: StandardMaterial3D
var glove_olive: StandardMaterial3D
var skin_shadow: StandardMaterial3D


func _build_materials() -> void:
	super._build_materials()
	pistol_tan = _mat(Color(0.56, 0.39, 0.23), 0.10, 0.58)
	pistol_tan_dark = _mat(Color(0.40, 0.27, 0.16), 0.08, 0.68)
	slide_black = _mat(Color(0.035, 0.041, 0.045), 0.72, 0.23)
	steel = _mat(Color(0.22, 0.24, 0.24), 0.78, 0.20)
	sight_green = _emissive(Color(0.34, 0.95, 0.42), 2.7)
	glove_black = _mat(Color(0.025, 0.030, 0.028), 0.06, 0.90)
	glove_olive = _mat(Color(0.13, 0.18, 0.105), 0.08, 0.82)
	skin_shadow = _mat(Color(0.20, 0.145, 0.105), 0.02, 0.93)


func _build_arms() -> void:
	# Two-handed modern pistol stance. Geometry uses rounded anatomy first, armor second.
	_build_human_tactical_arm(
		1.0,
		Vector3(0.205, -0.205, -0.235),
		Vector3(70.0, 8.0, 12.0),
		true
	)
	_build_human_tactical_arm(
		-1.0,
		Vector3(-0.095, -0.205, -0.335),
		Vector3(73.0, -7.0, -9.0),
		false
	)


func _build_human_tactical_arm(side: float, base_pos: Vector3, rot: Vector3, trigger_hand: bool) -> void:
	var root: Node3D = Node3D.new()
	root.position = base_pos
	root.rotation_degrees = rot
	arms_root.add_child(root)

	# Forearm: rounded human volume beneath a fitted black/olive tactical sleeve.
	_add_capsule(root, 0.075, 0.44, Vector3(0.0, 0.015, 0.10), suit)
	_add_capsule(root, 0.081, 0.35, Vector3(0.0, 0.020, -0.015), glove_olive)
	_add_box(root, Vector3(0.145, 0.045, 0.19), Vector3(0.0, 0.083, -0.01), glove_black, Vector3(-5.0, 0.0, 0.0))
	_add_box(root, Vector3(0.118, 0.035, 0.125), Vector3(0.0, 0.108, -0.085), glove_olive)

	# Wrist transition.
	_add_capsule(root, 0.060, 0.17, Vector3(0.0, -0.005, -0.135), glove_black, Vector3(88.0, 0.0, 0.0))

	# Palm is an ellipsoid instead of a rectangular block.
	_add_sphere(root, Vector3(0.105, 0.070, 0.125), Vector3(0.0, -0.018, -0.215), glove_black)
	_add_sphere(root, Vector3(0.086, 0.036, 0.085), Vector3(0.0, 0.045, -0.218), glove_olive)

	# Four fingers with two anatomical segments each.
	for finger: int in range(4):
		var x_value: float = (float(finger) - 1.5) * 0.030
		var finger_z: float = -0.294 - absf(float(finger) - 1.5) * 0.004
		var bend: float = 62.0 if trigger_hand and finger == 3 else 76.0
		_add_capsule(root, 0.0145, 0.075, Vector3(x_value, -0.037, finger_z), glove_black, Vector3(bend, 0.0, 0.0))
		_add_capsule(root, 0.0135, 0.066, Vector3(x_value, -0.052, finger_z - 0.047), glove_black, Vector3(86.0, 0.0, 0.0))

	# Thumb wraps naturally around the grip/support hand.
	_add_capsule(
		root,
		0.017,
		0.105,
		Vector3(0.082 * side, -0.020, -0.245),
		glove_black,
		Vector3(63.0, 0.0, 38.0 * side)
	)
	_add_sphere(root, Vector3(0.030, 0.020, 0.042), Vector3(0.070 * side, 0.015, -0.235), glove_olive)

	# Knuckle guards are thin and follow the human hand shape.
	for knuckle: int in range(4):
		var kx: float = (float(knuckle) - 1.5) * 0.030
		_add_sphere(root, Vector3(0.019, 0.012, 0.020), Vector3(kx, 0.050, -0.252), glove_olive)


func _process(delta: float) -> void:
	if current_index != 0:
		super._process(delta)
		return

	fire_cooldown = maxf(0.0, fire_cooldown - delta)
	if reload_timer > 0.0:
		reload_timer -= delta
		if reload_timer <= 0.0:
			_finish_reload()

	# The pistol is semi-automatic: one shot per click.
	var can_fire: bool = trigger_pressed and not trigger_was_pressed
	if can_fire and fire_cooldown <= 0.0 and reload_timer <= 0.0:
		_fire()
	trigger_was_pressed = trigger_pressed

	motion_time += delta * (8.0 if sprinting else 5.6)
	var bob_scale: float = 0.010 * motion_amount * (1.55 if sprinting else 1.0)
	if aiming:
		bob_scale *= 0.22
	var bob: Vector3 = Vector3(
		sin(motion_time) * bob_scale,
		absf(cos(motion_time * 2.0)) * bob_scale * 0.58,
		0.0
	)
	var target_position: Vector3 = (ads_position if aiming else base_position) + bob
	position = position.lerp(target_position, clampf(delta * 14.0, 0.0, 1.0))
	rotation.z = lerpf(rotation.z, sin(motion_time) * 0.008 * motion_amount, clampf(delta * 10.0, 0.0, 1.0))


func equip_weapon(index: int) -> void:
	if index != 0:
		super.equip_weapon(index)
		return

	current_index = 0
	for child: Node in weapon_root.get_children():
		child.queue_free()
	muzzle = null
	muzzle_flash = null
	muzzle_light = null
	current_mag = PISTOL_MAG
	reserve_ammo = PISTOL_RESERVE
	_build_primary_tactical_pistol()
	base_position = Vector3(0.255, -0.285, -0.505)
	ads_position = Vector3(0.006, -0.205, -0.405)
	position = base_position
	_build_muzzle_fx()
	weapon_changed.emit("VANGUARD P-15 // TACTICAL")
	ammo_changed.emit(current_mag, reserve_ammo)


func get_weapon_name() -> String:
	if current_index == 0:
		return "VANGUARD P-15 // TACTICAL"
	return super.get_weapon_name()


func request_reload() -> void:
	if current_index != 0:
		super.request_reload()
		return
	if reload_timer > 0.0 or current_mag >= PISTOL_MAG or reserve_ammo <= 0:
		return
	reload_timer = PISTOL_RELOAD
	var tween: Tween = create_tween()
	tween.tween_property(self, "rotation_degrees", Vector3(10.0, 0.0, 14.0), 0.24)
	tween.tween_property(self, "position", base_position + Vector3(-0.08, -0.10, 0.05), 0.30)
	tween.tween_property(self, "rotation_degrees", Vector3.ZERO, 0.40)
	tween.parallel().tween_property(self, "position", base_position, 0.40)


func _finish_reload() -> void:
	if current_index != 0:
		super._finish_reload()
		return
	var needed: int = PISTOL_MAG - current_mag
	var taken: int = mini(needed, reserve_ammo)
	current_mag += taken
	reserve_ammo -= taken
	ammo_changed.emit(current_mag, reserve_ammo)


func _fire() -> void:
	if current_index != 0:
		super._fire()
		return
	if current_mag <= 0:
		request_reload()
		return
	current_mag -= 1
	fire_cooldown = 60.0 / PISTOL_RPM
	ammo_changed.emit(current_mag, reserve_ammo)
	_flash_muzzle()
	_spawn_hit_spark()
	rotation.x -= PISTOL_RECOIL
	position.z += 0.018
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "rotation:x", 0.0, 0.10)
	tween.tween_property(self, "position:z", base_position.z, 0.09)


func _build_primary_tactical_pistol() -> void:
	# TAN POLYMER FRAME -------------------------------------------------------
	# Grip has a rearward rake like the supplied reference.
	_add_box(weapon_root, Vector3(0.145, 0.285, 0.135), Vector3(0.0, -0.170, 0.030), pistol_tan, Vector3(10.0, 0.0, 0.0))
	_add_box(weapon_root, Vector3(0.155, 0.060, 0.155), Vector3(0.0, -0.315, 0.046), pistol_tan_dark, Vector3(5.0, 0.0, 0.0))
	_add_box(weapon_root, Vector3(0.175, 0.090, 0.295), Vector3(0.0, -0.065, -0.155), pistol_tan)
	_add_box(weapon_root, Vector3(0.165, 0.060, 0.215), Vector3(0.0, -0.115, -0.285), pistol_tan_dark)

	# Grip texture blocks suggest stippling without a heavy texture asset.
	for row: int in range(4):
		for column: int in range(3):
			var x_value: float = (float(column) - 1.0) * 0.034
			var y_value: float = -0.115 - float(row) * 0.045
			_add_box(weapon_root, Vector3(0.012, 0.012, 0.004), Vector3(x_value, y_value, 0.104), pistol_tan_dark)

	# Trigger guard: three rounded-looking structural pieces around an open center.
	_add_cylinder(weapon_root, 0.014, 0.155, Vector3(-0.066, -0.090, -0.205), pistol_tan_dark, Vector3(90.0, 0.0, 0.0))
	_add_cylinder(weapon_root, 0.014, 0.155, Vector3(0.066, -0.090, -0.205), pistol_tan_dark, Vector3(90.0, 0.0, 0.0))
	_add_cylinder(weapon_root, 0.014, 0.132, Vector3(0.0, -0.145, -0.205), pistol_tan_dark, Vector3(0.0, 0.0, 90.0))
	_add_capsule(weapon_root, 0.010, 0.075, Vector3(0.0, -0.090, -0.205), slide_black, Vector3(12.0, 0.0, 0.0))

	# BLACK STEEL SLIDE -------------------------------------------------------
	_add_box(weapon_root, Vector3(0.178, 0.135, 0.480), Vector3(0.0, 0.060, -0.170), slide_black)
	_add_box(weapon_root, Vector3(0.160, 0.040, 0.405), Vector3(0.0, 0.143, -0.165), steel)
	_add_box(weapon_root, Vector3(0.152, 0.030, 0.245), Vector3(0.0, 0.152, -0.245), slide_black)

	# Ejection port / extractor side detailing.
	_add_box(weapon_root, Vector3(0.078, 0.045, 0.095), Vector3(0.091, 0.090, -0.195), steel)
	_add_box(weapon_root, Vector3(0.012, 0.035, 0.075), Vector3(0.096, 0.015, -0.050), steel)
	_add_box(weapon_root, Vector3(0.010, 0.022, 0.055), Vector3(0.096, -0.025, -0.090), slide_black)

	# Rear slide serrations.
	for serration: int in range(7):
		var z_value: float = 0.015 - float(serration) * 0.017
		_add_box(weapon_root, Vector3(0.006, 0.080, 0.008), Vector3(0.093, 0.060, z_value), steel, Vector3(0.0, 0.0, -8.0))
		_add_box(weapon_root, Vector3(0.006, 0.080, 0.008), Vector3(-0.093, 0.060, z_value), steel, Vector3(0.0, 0.0, 8.0))

	# Barrel and muzzle visible at the front of the slide.
	_add_cylinder(weapon_root, 0.033, 0.115, Vector3(0.0, 0.050, -0.452), steel, Vector3(90.0, 0.0, 0.0))
	_add_cylinder(weapon_root, 0.019, 0.125, Vector3(0.0, 0.050, -0.472), dark, Vector3(90.0, 0.0, 0.0))

	# Tactical sights with subtle green inserts.
	_add_box(weapon_root, Vector3(0.070, 0.030, 0.035), Vector3(0.0, 0.150, 0.025), slide_black)
	_add_box(weapon_root, Vector3(0.020, 0.020, 0.030), Vector3(-0.026, 0.167, 0.020), sight_green)
	_add_box(weapon_root, Vector3(0.020, 0.020, 0.030), Vector3(0.026, 0.167, 0.020), sight_green)
	_add_box(weapon_root, Vector3(0.030, 0.034, 0.030), Vector3(0.0, 0.153, -0.398), slide_black)
	_add_box(weapon_root, Vector3(0.012, 0.020, 0.020), Vector3(0.0, 0.171, -0.405), sight_green)

	# Accessory rail underneath the dust cover.
	for rail: int in range(4):
		_add_box(weapon_root, Vector3(0.100, 0.012, 0.014), Vector3(0.0, -0.125, -0.238 - float(rail) * 0.035), slide_black)

	# Tactical weapon light: black clamp + cylindrical lamp head, matching the reference layout.
	_add_box(weapon_root, Vector3(0.125, 0.085, 0.170), Vector3(0.0, -0.170, -0.290), slide_black)
	_add_cylinder(weapon_root, 0.047, 0.160, Vector3(0.0, -0.170, -0.405), slide_black, Vector3(90.0, 0.0, 0.0))
	_add_cylinder(weapon_root, 0.038, 0.045, Vector3(0.0, -0.170, -0.505), steel, Vector3(90.0, 0.0, 0.0))
	_add_sphere(weapon_root, Vector3(0.032, 0.032, 0.015), Vector3(0.0, -0.170, -0.535), _emissive(Color(0.84, 0.92, 0.88), 1.2))

	# Magazine body and base plate.
	_add_box(weapon_root, Vector3(0.112, 0.250, 0.090), Vector3(0.0, -0.245, 0.055), dark, Vector3(8.0, 0.0, 0.0))
	_add_box(weapon_root, Vector3(0.132, 0.035, 0.110), Vector3(0.0, -0.372, 0.073), slide_black, Vector3(5.0, 0.0, 0.0))

	_set_muzzle(Vector3(0.0, 0.050, -0.548))


func _build_muzzle_fx() -> void:
	if current_index != 0:
		super._build_muzzle_fx()
		return
	if muzzle == null:
		return
	muzzle_flash = MeshInstance3D.new()
	var flash_mesh: SphereMesh = SphereMesh.new()
	flash_mesh.radius = 0.035
	flash_mesh.height = 0.100
	flash_mesh.radial_segments = 8
	flash_mesh.rings = 4
	muzzle_flash.mesh = flash_mesh
	muzzle_flash.position = muzzle.position
	muzzle_flash.scale = Vector3(1.0, 1.0, 2.0)
	muzzle_flash.material_override = _emissive(Color(1.0, 0.66, 0.22), 8.0)
	muzzle_flash.visible = false
	weapon_root.add_child(muzzle_flash)

	muzzle_light = OmniLight3D.new()
	muzzle_light.position = muzzle.position
	muzzle_light.light_color = Color(1.0, 0.58, 0.24)
	muzzle_light.light_energy = 4.8
	muzzle_light.omni_range = 2.0
	muzzle_light.visible = false
	muzzle_light.shadow_enabled = false
	weapon_root.add_child(muzzle_light)
