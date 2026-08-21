extends "res://scripts/weapon_arsenal_primary.gd"

# JEFE first-person presentation layer.
# Keeps the existing arsenal and weapon logic intact while replacing the visible
# arms with the same olive/black armored language used by JEFE in third person.

var jefe_armor: StandardMaterial3D
var jefe_armor_dark: StandardMaterial3D
var jefe_edge: StandardMaterial3D
var jefe_glove: StandardMaterial3D
var jefe_joint: StandardMaterial3D
var jefe_metal: StandardMaterial3D


func _build_materials() -> void:
	super._build_materials()
	jefe_armor = _mat(Color(0.235, 0.255, 0.145), 0.54, 0.43)
	jefe_armor_dark = _mat(Color(0.105, 0.125, 0.075), 0.48, 0.50)
	jefe_edge = _mat(Color(0.34, 0.35, 0.25), 0.72, 0.30)
	jefe_glove = _mat(Color(0.020, 0.023, 0.022), 0.04, 0.96)
	jefe_joint = _mat(Color(0.030, 0.034, 0.032), 0.08, 0.92)
	jefe_metal = _mat(Color(0.075, 0.080, 0.075), 0.82, 0.26)


func _build_arms() -> void:
	_build_jefe_arm(
		1.0,
		Vector3(0.165, -0.255, -0.125),
		Vector3(67.0, 10.0, 10.0),
		true
	)
	_build_jefe_arm(
		-1.0,
		Vector3(0.015, -0.265, -0.255),
		Vector3(72.0, -11.0, -6.0),
		false
	)


func _build_jefe_arm(side: float, base_pos: Vector3, rot: Vector3, trigger_hand: bool) -> void:
	var root: Node3D = Node3D.new()
	root.name = "JEFE_FP_RIGHT_ARM" if side > 0.0 else "JEFE_FP_LEFT_ARM"
	root.position = base_pos
	root.rotation_degrees = rot
	arms_root.add_child(root)

	# Technical undersuit volume.
	_add_capsule(root, 0.066, 0.40, Vector3(0.0, 0.012, 0.080), jefe_joint)

	# Forearm shell: layered plates instead of a single cylinder/block.
	_add_capsule(root, 0.073, 0.30, Vector3(0.0, 0.016, -0.005), jefe_joint)
	_add_box(root, Vector3(0.128, 0.180, 0.118), Vector3(0.0, 0.038, 0.006), jefe_armor, Vector3(-5.0, 0.0, 0.0))
	_add_box(root, Vector3(0.112, 0.118, 0.042), Vector3(0.0, 0.062, -0.066), jefe_armor_dark, Vector3(-7.0, 0.0, 0.0))
	_add_box(root, Vector3(0.026, 0.155, 0.050), Vector3(0.068 * side, 0.040, -0.010), jefe_edge, Vector3(0.0, 0.0, 4.0 * side))
	_add_box(root, Vector3(0.090, 0.028, 0.100), Vector3(0.0, 0.093, -0.078), jefe_metal)

	# Armored wrist transition.
	_add_capsule(root, 0.052, 0.120, Vector3(0.0, -0.004, -0.128), jefe_glove, Vector3(88.0, 0.0, 0.0))
	_add_box(root, Vector3(0.112, 0.050, 0.105), Vector3(0.0, 0.015, -0.132), jefe_armor_dark, Vector3(-2.0, 0.0, 0.0))

	# Palm and armored glove mass.
	_add_sphere(root, Vector3(0.090, 0.056, 0.108), Vector3(0.0, -0.020, -0.205), jefe_glove)
	_add_sphere(root, Vector3(0.074, 0.028, 0.072), Vector3(0.0, 0.031, -0.205), jefe_armor_dark)
	_add_sphere(root, Vector3(0.046, 0.037, 0.055), Vector3(0.050 * side, -0.016, -0.220), jefe_glove)

	# Raised knuckle armor.
	for knuckle: int in range(4):
		var kx: float = (float(knuckle) - 1.5) * 0.024
		_add_sphere(root, Vector3(0.017, 0.011, 0.019), Vector3(kx, 0.040, -0.242), jefe_edge)

	# Four articulated fingers. Trigger index remains less curled.
	for finger: int in range(4):
		var x_value: float = (float(finger) - 1.5) * 0.024
		var finger_z: float = -0.270 - absf(float(finger) - 1.5) * 0.004
		var bend_1: float = 70.0
		var bend_2: float = 84.0
		if trigger_hand and finger == 3:
			bend_1 = 48.0
			bend_2 = 70.0
		_add_capsule(root, 0.0120, 0.060, Vector3(x_value, -0.032, finger_z), jefe_glove, Vector3(bend_1, 0.0, 0.0))
		_add_capsule(root, 0.0110, 0.052, Vector3(x_value, -0.046, finger_z - 0.038), jefe_glove, Vector3(bend_2, 0.0, 0.0))

	# Thumb and side armor.
	_add_capsule(root, 0.0130, 0.070, Vector3(0.062 * side, -0.012, -0.214), jefe_glove, Vector3(58.0, 0.0, 30.0 * side))
	_add_capsule(root, 0.0110, 0.054, Vector3(0.082 * side, -0.026, -0.254), jefe_glove, Vector3(78.0, 0.0, 35.0 * side))
	_add_box(root, Vector3(0.030, 0.065, 0.052), Vector3(0.073 * side, 0.010, -0.203), jefe_armor_dark, Vector3(0.0, 0.0, 8.0 * side))
