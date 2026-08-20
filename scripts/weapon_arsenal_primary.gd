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


func _ready() -> void:
	super._ready()
	# Keep the sidearm compact in first person so it reads like a real pistol,
	# not a rifle-sized block directly in front of the camera.
	scale = Vector3(0.72, 0.72, 0.72)
	base_position = Vector3(0.31, -0.36, -0.60)
	ads_position = Vector3(0.008, -0.245, -0.47)
	position = base_position
	weapon_root.rotation_degrees = Vector3(-2.0, -5.5, 0.0)


func _build_materials() -> void:
	super._build_materials()
	pistol_tan = _mat(Color(0.58, 0.405, 0.245), 0.08, 0.62)
	pistol_tan_dark = _mat(Color(0.39, 0.255, 0.145), 0.06, 0.72)
	slide_black = _mat(Color(0.028, 0.033, 0.036), 0.76, 0.25)
	steel = _mat(Color(0.24, 0.26, 0.265), 0.82, 0.18)
	sight_green = _emissive(Color(0.34, 0.95, 0.42), 2.7)
	glove_black = _mat(Color(0.022, 0.027, 0.025), 0.04, 0.92)
	glove_olive = _mat(Color(0.115, 0.165, 0.09), 0.06, 0.86)
	skin_shadow = _mat(Color(0.20, 0.145, 0.105), 0.02, 0.93)


func _build_arms() -> void:
	# Compact modern two-hand stance. Trigger hand owns the grip; support hand wraps the front.
	_build_human_tactical_arm(
		1.0,
		Vector3(0.165, -0.255, -0.125),
		Vector3(67.0, 10.0, 10.0),
		true
	)
	_build_human_tactical_arm(
		-1.0,
		Vector3(0.015, -0.265, -0.255),
		Vector3(72.0, -11.0, -6.0),
		false
	)


func _build_human_tactical_arm(side: float, base_pos: Vector3, rot: Vector3, trigger_hand: bool) -> void:
	var root: Node3D = Node3D.new()
	root.position = base_pos
	root.rotation_degrees = rot
	arms_root.add_child(root)

	# Human forearm volume under a fitted olive/black tactical sleeve.
	_add_capsule(root, 0.064, 0.38, Vector3(0.0, 0.012, 0.080), suit)
	_add_capsule(root, 0.070, 0.28, Vector3(0.0, 0.016, -0.010), glove_olive)
	_add_box(root, Vector3(0.124, 0.034, 0.158), Vector3(0.0, 0.070, -0.020), glove_black, Vector3(-5.0, 0.0, 0.0))
	_add_box(root, Vector3(0.100, 0.028, 0.092), Vector3(0.0, 0.093, -0.082), glove_olive)

	# Narrow wrist transition keeps the hand from looking like a block attached to the forearm.
	_add_capsule(root, 0.050, 0.120, Vector3(0.0, -0.004, -0.126), glove_black, Vector3(88.0, 0.0, 0.0))

	# Rounded palm and thenar pad.
	_add_sphere(root, Vector3(0.088, 0.054, 0.105), Vector3(0.0, -0.020, -0.205), glove_black)
	_add_sphere(root, Vector3(0.071, 0.027, 0.070), Vector3(0.0, 0.031, -0.205), glove_olive)
	_add_sphere(root, Vector3(0.046, 0.037, 0.055), Vector3(0.050 * side, -0.016, -0.220), glove_black)

	# Four fingers, each with proximal and distal segments. The index finger on the
	# trigger hand is straighter so it reads as resting on the trigger.
	for finger: int in range(4):
		var x_value: float = (float(finger) - 1.5) * 0.024
		var finger_z: float = -0.270 - absf(float(finger) - 1.5) * 0.004
		var bend_1: float = 70.0
		var bend_2: float = 84.0
		if trigger_hand and finger == 3:
			bend_1 = 48.0
			bend_2 = 70.0
		_add_capsule(root, 0.0120, 0.060, Vector3(x_value, -0.032, finger_z), glove_black, Vector3(bend_1, 0.0, 0.0))
		_add_capsule(root, 0.0110, 0.052, Vector3(x_value, -0.046, finger_z - 0.038), glove_black, Vector3(bend_2, 0.0, 0.0))

	# Two-piece thumb wraps around the pistol/support hand.
	_add_capsule(root, 0.0130, 0.070, Vector3(0.062 * side, -0.012, -0.214), glove_black, Vector3(58.0, 0.0, 30.0 * side))
	_add_capsule(root, 0.0110, 0.054, Vector3(0.082 * side, -0.026, -0.254), glove_black, Vector3(78.0, 0.0, 35.0 * side))

	# Low-profile knuckle protectors following the actual finger line.
	for knuckle: int in range(4):
		var kx: float = (float(knuckle) - 1.5) * 0.024
		_add_sphere(root, Vector3(0.016, 0.010, 0.018), Vector3(kx, 0.038, -0.242), glove_olive)


func _process(delta: float) -> void:
	if current_index != 0:
		super._process(delta)
		return

	fire_cooldown = maxf(0.0, fire_cooldown - delta)
	if reload_timer > 0.0:
		reload_timer -= delta
		if reload_timer <= 0.0:
			_finish_reload()

	var can_fire: bool = trigger_pressed and not trigger_was_pressed
	if can_fire and fire_cooldown <= 0.0 and reload_timer <= 0.0:
		_fire()
	trigger_was_pressed = trigger_pressed

	motion_time += delta * (8.0 if sprinting else 5.6)
	var bob_scale: float = 0.008 * motion_amount * (1.45 if sprinting else 1.0)
	if aiming:
		bob_scale *= 0.18
	var bob: Vector3 = Vector3(
		sin(motion_time) * bob_scale,
		absf(cos(motion_time * 2.0)) * bob_scale * 0.54,
		0.0
	)
	var target_position: Vector3 = (ads_position if aiming else base_position) + bob
	position = position.lerp(target_position, clampf(delta * 14.0, 0.0, 1.0))
	rotation.z = lerpf(rotation.z, sin(motion_time) * 0.006 * motion_amount, clampf(delta * 10.0, 0.0, 1.0))
	var target_weapon_yaw: float = 0.0 if aiming else -5.5
	var target_weapon_pitch: float = 0.0 if aiming else -2.0
	weapon_root.rotation_degrees.y = lerpf(weapon_root.rotation_degrees.y, target_weapon_yaw, clampf(delta * 12.0, 0.0, 1.0))
	weapon_root.rotation_degrees.x = lerpf(weapon_root.rotation_degrees.x, target_weapon_pitch, clampf(delta * 12.0, 0.0, 1.0))


func equip_weapon(index: int) -> void:
	if index != 0:
		scale = Vector3.ONE
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
	base_position = Vector3(0.31, -0.36, -0.60)
	ads_position = Vector3(0.008, -0.245, -0.47)
	position = base_position
	scale = Vector3(0.72, 0.72, 0.72)
	weapon_root.rotation_degrees = Vector3(-2.0, -5.5, 0.0)
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
	tween.tween_property(self, "rotation_degrees", Vector3(8.0, 0.0, 11.0), 0.22)
	tween.tween_property(self, "position", base_position + Vector3(-0.055, -0.075, 0.04), 0.27)
	tween.tween_property(self, "rotation_degrees", Vector3.ZERO, 0.38)
	tween.parallel().tween_property(self, "position", base_position, 0.38)


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
	position.z += 0.012
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "rotation:x", 0.0, 0.09)
	tween.tween_property(self, "position:z", base_position.z, 0.08)


func _build_primary_tactical_pistol() -> void:
	# TAN POLYMER FRAME -------------------------------------------------------
	# Wider lower frame and angled grip keep the tan polymer visible from FPS view.
	_add_box(weapon_root, Vector3(0.140, 0.255, 0.125), Vector3(0.0, -0.160, 0.035), pistol_tan, Vector3(12.0, 0.0, 0.0))
	_add_box(weapon_root, Vector3(0.150, 0.052, 0.145), Vector3(0.0, -0.293, 0.050), pistol_tan_dark, Vector3(7.0, 0.0, 0.0))
	_add_box(weapon_root, Vector3(0.166, 0.082, 0.285), Vector3(0.0, -0.060, -0.150), pistol_tan)
	_add_box(weapon_root, Vector3(0.154, 0.052, 0.210), Vector3(0.0, -0.108, -0.275), pistol_tan_dark)

	# Stippling hints on both visible sides of the grip.
	for row: int in range(4):
		for column: int in range(3):
			var x_value: float = (float(column) - 1.0) * 0.031
			var y_value: float = -0.112 - float(row) * 0.040
			_add_box(weapon_root, Vector3(0.010, 0.010, 0.004), Vector3(x_value, y_value, 0.096), pistol_tan_dark)

	# Open trigger guard and trigger.
	_add_cylinder(weapon_root, 0.012, 0.145, Vector3(-0.061, -0.087, -0.200), pistol_tan_dark, Vector3(90.0, 0.0, 0.0))
	_add_cylinder(weapon_root, 0.012, 0.145, Vector3(0.061, -0.087, -0.200), pistol_tan_dark, Vector3(90.0, 0.0, 0.0))
	_add_cylinder(weapon_root, 0.012, 0.122, Vector3(0.0, -0.137, -0.200), pistol_tan_dark, Vector3(0.0, 0.0, 90.0))
	_add_capsule(weapon_root, 0.009, 0.068, Vector3(0.0, -0.086, -0.205), slide_black, Vector3(12.0, 0.0, 0.0))

	# BLACK SLIDE -------------------------------------------------------------
	# Lower, slimmer slide with a subtly tapered nose so it no longer reads as a black cuboid.
	_add_box(weapon_root, Vector3(0.164, 0.112, 0.430), Vector3(0.0, 0.055, -0.165), slide_black)
	_add_box(weapon_root, Vector3(0.148, 0.026, 0.360), Vector3(0.0, 0.125, -0.160), steel)
	_add_box(weapon_root, Vector3(0.142, 0.022, 0.225), Vector3(0.0, 0.134, -0.245), slide_black)
	_add_box(weapon_root, Vector3(0.145, 0.094, 0.085), Vector3(0.0, 0.045, -0.405), slide_black, Vector3(0.0, 0.0, 0.0))

	# Ejection port and side controls.
	_add_box(weapon_root, Vector3(0.068, 0.036, 0.084), Vector3(0.083, 0.078, -0.195), steel)
	_add_box(weapon_root, Vector3(0.010, 0.030, 0.065), Vector3(0.086, 0.010, -0.050), steel)
	_add_box(weapon_root, Vector3(0.008, 0.018, 0.048), Vector3(0.086, -0.024, -0.090), slide_black)

	# Rear serrations on both slide faces.
	for serration: int in range(6):
		var z_value: float = 0.008 - float(serration) * 0.016
		_add_box(weapon_root, Vector3(0.005, 0.068, 0.007), Vector3(0.084, 0.054, z_value), steel, Vector3(0.0, 0.0, -8.0))
		_add_box(weapon_root, Vector3(0.005, 0.068, 0.007), Vector3(-0.084, 0.054, z_value), steel, Vector3(0.0, 0.0, 8.0))

	# Barrel and visible muzzle opening.
	_add_cylinder(weapon_root, 0.030, 0.102, Vector3(0.0, 0.047, -0.420), steel, Vector3(90.0, 0.0, 0.0))
	_add_cylinder(weapon_root, 0.017, 0.112, Vector3(0.0, 0.047, -0.442), dark, Vector3(90.0, 0.0, 0.0))

	# Three-dot tactical sights.
	_add_box(weapon_root, Vector3(0.064, 0.026, 0.032), Vector3(0.0, 0.132, 0.014), slide_black)
	_add_box(weapon_root, Vector3(0.016, 0.016, 0.022), Vector3(-0.022, 0.147, 0.012), sight_green)
	_add_box(weapon_root, Vector3(0.016, 0.016, 0.022), Vector3(0.022, 0.147, 0.012), sight_green)
	_add_box(weapon_root, Vector3(0.026, 0.030, 0.028), Vector3(0.0, 0.135, -0.365), slide_black)
	_add_box(weapon_root, Vector3(0.010, 0.016, 0.018), Vector3(0.0, 0.151, -0.371), sight_green)

	# Accessory rail below dust cover.
	for rail: int in range(4):
		_add_box(weapon_root, Vector3(0.088, 0.010, 0.012), Vector3(0.0, -0.118, -0.226 - float(rail) * 0.030), slide_black)

	# Compact tactical light mounted under the barrel.
	_add_box(weapon_root, Vector3(0.112, 0.070, 0.145), Vector3(0.0, -0.155, -0.277), slide_black)
	_add_cylinder(weapon_root, 0.038, 0.135, Vector3(0.0, -0.155, -0.372), slide_black, Vector3(90.0, 0.0, 0.0))
	_add_cylinder(weapon_root, 0.031, 0.038, Vector3(0.0, -0.155, -0.455), steel, Vector3(90.0, 0.0, 0.0))
	_add_sphere(weapon_root, Vector3(0.026, 0.026, 0.012), Vector3(0.0, -0.155, -0.480), _emissive(Color(0.84, 0.92, 0.88), 1.2))

	# Magazine is mostly contained inside the grip with only the base plate visible.
	_add_box(weapon_root, Vector3(0.100, 0.205, 0.078), Vector3(0.0, -0.225, 0.055), dark, Vector3(10.0, 0.0, 0.0))
	_add_box(weapon_root, Vector3(0.120, 0.028, 0.097), Vector3(0.0, -0.329, 0.075), slide_black, Vector3(7.0, 0.0, 0.0))

	_set_muzzle(Vector3(0.0, 0.047, -0.500))


func _build_muzzle_fx() -> void:
	if current_index != 0:
		super._build_muzzle_fx()
		return
	if muzzle == null:
		return
	muzzle_flash = MeshInstance3D.new()
	var flash_mesh: SphereMesh = SphereMesh.new()
	flash_mesh.radius = 0.030
	flash_mesh.height = 0.085
	flash_mesh.radial_segments = 8
	flash_mesh.rings = 4
	muzzle_flash.mesh = flash_mesh
	muzzle_flash.position = muzzle.position
	muzzle_flash.scale = Vector3(1.0, 1.0, 1.85)
	muzzle_flash.material_override = _emissive(Color(1.0, 0.78, 0.33), 6.5)
	muzzle_flash.visible = false
	weapon_root.add_child(muzzle_flash)

	muzzle_light = OmniLight3D.new()
	muzzle_light.position = muzzle.position
	muzzle_light.light_color = Color(1.0, 0.78, 0.36)
	muzzle_light.light_energy = 4.2
	muzzle_light.omni_range = 1.7
	muzzle_light.visible = false
	muzzle_light.shadow_enabled = false
	weapon_root.add_child(muzzle_light)
