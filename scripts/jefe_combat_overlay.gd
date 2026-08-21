extends Node

# JEFE third-person combat layer.
# Uses Godot 4.7 TwoBoneIK3D instead of guessing AccuRIG local bone axes.
# The weapon is placed in character/skeleton space and each hand is solved to a
# dedicated grip target. This keeps the arms in a believable combat stance even
# when locomotion changes the lower body.

var body_model: Node3D
var skeleton: Skeleton3D
var equipped_index: int = 0
var bind_attempts: int = 0
var ready_for_combat: bool = false

var chest_bone: int = -1
var head_bone: int = -1

var weapon_mount: Node3D
var weapon_root: Node3D
var right_hand_target: Node3D
var left_hand_target: Node3D
var right_elbow_pole: Node3D
var left_elbow_pole: Node3D
var right_ik: TwoBoneIK3D
var left_ik: TwoBoneIK3D

var weapon_dark: StandardMaterial3D
var weapon_metal: StandardMaterial3D
var weapon_olive: StandardMaterial3D
var weapon_tan: StandardMaterial3D
var weapon_rubber: StandardMaterial3D
var sight_glow: StandardMaterial3D


func setup(target_body: Node3D) -> void:
	body_model = target_body
	_build_materials()
	call_deferred("_try_bind")


func _try_bind() -> void:
	if body_model == null:
		return

	skeleton = _find_skeleton(body_model)
	if skeleton == null:
		bind_attempts += 1
		if bind_attempts < 180:
			await get_tree().process_frame
			call_deferred("_try_bind")
		return

	chest_bone = skeleton.find_bone("CC_Base_Spine02")
	head_bone = skeleton.find_bone("CC_Base_Head")
	if chest_bone < 0:
		chest_bone = skeleton.find_bone("CC_Base_Spine01")

	if not _required_arm_bones_exist():
		return

	_create_combat_nodes()
	_create_arm_ik()
	_rebuild_weapon()
	ready_for_combat = true


func _find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node as Skeleton3D
	for child: Node in node.get_children():
		var found: Skeleton3D = _find_skeleton(child)
		if found != null:
			return found
	return null


func _required_arm_bones_exist() -> bool:
	var required: Array[String] = [
		"CC_Base_R_Upperarm", "CC_Base_R_Forearm", "CC_Base_R_Hand",
		"CC_Base_L_Upperarm", "CC_Base_L_Forearm", "CC_Base_L_Hand"
	]
	for bone_name: String in required:
		if skeleton.find_bone(bone_name) < 0:
			return false
	return true


func _create_combat_nodes() -> void:
	weapon_mount = Node3D.new()
	weapon_mount.name = "JEFE_COMBAT_WEAPON_MOUNT"
	skeleton.add_child(weapon_mount)

	weapon_root = Node3D.new()
	weapon_root.name = "JEFE_THIRD_PERSON_WEAPON"
	weapon_mount.add_child(weapon_root)

	right_hand_target = Node3D.new()
	right_hand_target.name = "JEFE_RIGHT_HAND_TARGET"
	weapon_mount.add_child(right_hand_target)

	left_hand_target = Node3D.new()
	left_hand_target.name = "JEFE_LEFT_HAND_TARGET"
	weapon_mount.add_child(left_hand_target)

	right_elbow_pole = Node3D.new()
	right_elbow_pole.name = "JEFE_RIGHT_ELBOW_POLE"
	skeleton.add_child(right_elbow_pole)

	left_elbow_pole = Node3D.new()
	left_elbow_pole.name = "JEFE_LEFT_ELBOW_POLE"
	skeleton.add_child(left_elbow_pole)


func _create_arm_ik() -> void:
	right_ik = TwoBoneIK3D.new()
	right_ik.name = "JEFE_RIGHT_ARM_IK"
	skeleton.add_child(right_ik)
	right_ik.setting_count = 1
	right_ik.set_root_bone_name(0, "CC_Base_R_Upperarm")
	right_ik.set_middle_bone_name(0, "CC_Base_R_Forearm")
	right_ik.set_end_bone_name(0, "CC_Base_R_Hand")
	right_ik.set_target_node(0, right_ik.get_path_to(right_hand_target))
	right_ik.set_pole_node(0, right_ik.get_path_to(right_elbow_pole))
	right_ik.influence = 0.98
	right_ik.active = true

	left_ik = TwoBoneIK3D.new()
	left_ik.name = "JEFE_LEFT_ARM_IK"
	skeleton.add_child(left_ik)
	left_ik.setting_count = 1
	left_ik.set_root_bone_name(0, "CC_Base_L_Upperarm")
	left_ik.set_middle_bone_name(0, "CC_Base_L_Forearm")
	left_ik.set_end_bone_name(0, "CC_Base_L_Hand")
	left_ik.set_target_node(0, left_ik.get_path_to(left_hand_target))
	left_ik.set_pole_node(0, left_ik.get_path_to(left_elbow_pole))
	left_ik.influence = 0.98
	left_ik.active = true


func apply_combat_pose(delta: float, speed_ratio: float, sprinting: bool, airborne: bool, aiming: bool) -> void:
	if not ready_for_combat or skeleton == null or chest_bone < 0:
		return

	var chest_pose: Transform3D = skeleton.get_bone_global_pose(chest_bone)
	var chest_pos: Vector3 = chest_pose.origin
	var move_amount: float = clampf(speed_ratio, 0.0, 1.0)

	# Weapon mount is expressed in skeleton/model coordinates instead of bone-local
	# coordinates. This avoids the AccuRIG axis mismatch that previously raised the
	# arms above JEFE's head.
	var mount_offset: Vector3
	if equipped_index == 0:
		mount_offset = Vector3(0.035, -0.105, -0.385)
	else:
		mount_offset = Vector3(0.075, -0.105, -0.315)

	if sprinting:
		mount_offset += Vector3(0.035, -0.105, 0.055)
	elif airborne:
		mount_offset += Vector3(0.0, -0.045, 0.020)

	# Tiny breathing/movement response; never large enough to break hand contact.
	var breathe: float = sin(Time.get_ticks_msec() * 0.0022) * 0.006
	var step: float = absf(sin(Time.get_ticks_msec() * 0.0065)) * 0.010 * move_amount
	mount_offset.y += breathe + step

	weapon_mount.position = chest_pos + mount_offset
	weapon_mount.rotation = Vector3.ZERO

	_configure_grip_targets(aiming, sprinting)

	# Pole targets force elbows down and away from the torso, producing a compact
	# tactical stance instead of allowing the solver to flip the arms upward.
	right_elbow_pole.position = chest_pos + Vector3(0.46, -0.20, -0.02)
	left_elbow_pole.position = chest_pos + Vector3(-0.46, -0.18, -0.08)

	# Weapon recoil is visual only. The IK targets remain on the same mount, so both
	# hands continue to follow the weapon while firing.
	var recoil_z: float = 0.025 if Input.is_action_pressed("shoot") else 0.0
	weapon_root.position.z = lerpf(weapon_root.position.z, recoil_z, minf(delta * 22.0, 1.0))


func _configure_grip_targets(aiming: bool, sprinting: bool) -> void:
	var aim_raise: float = 0.025 if aiming else 0.0
	if equipped_index == 0:
		# Two-hand pistol stance: hands close together and weapon farther forward.
		right_hand_target.position = Vector3(0.075, -0.075 + aim_raise, 0.075)
		left_hand_target.position = Vector3(-0.065, -0.055 + aim_raise, 0.030)
	else:
		# Rifle stance: trigger hand at the pistol grip, support hand farther forward
		# on the handguard. This naturally bends both elbows through IK.
		right_hand_target.position = Vector3(0.115, -0.105 + aim_raise, 0.115)
		left_hand_target.position = Vector3(-0.135, -0.025 + aim_raise, -0.315)

	if sprinting:
		right_hand_target.position.y -= 0.035
		left_hand_target.position.y -= 0.045


func set_weapon_index(index: int) -> void:
	equipped_index = clampi(index, 0, 5)
	if weapon_root != null:
		_rebuild_weapon()


func _rebuild_weapon() -> void:
	if weapon_root == null:
		return

	for child: Node in weapon_root.get_children():
		child.queue_free()

	weapon_root.position = Vector3.ZERO
	weapon_root.rotation = Vector3.ZERO
	weapon_root.scale = Vector3.ONE

	if equipped_index == 0:
		_build_tactical_pistol()
	else:
		_build_combat_rifle(equipped_index)


func _build_tactical_pistol() -> void:
	# Compact sidearm, barrel along -Z.
	_add_box(weapon_root, Vector3(0.105, 0.090, 0.325), Vector3(0.0, 0.025, -0.105), weapon_dark)
	_add_box(weapon_root, Vector3(0.098, 0.165, 0.090), Vector3(0.0, -0.090, 0.025), weapon_tan, Vector3(12.0, 0.0, 0.0))
	_add_box(weapon_root, Vector3(0.082, 0.024, 0.250), Vector3(0.0, 0.078, -0.110), weapon_metal)
	_add_cylinder(weapon_root, 0.016, 0.185, Vector3(0.0, 0.020, -0.315), weapon_metal, Vector3(90.0, 0.0, 0.0))
	_add_box(weapon_root, Vector3(0.030, 0.025, 0.022), Vector3(0.0, 0.095, -0.205), sight_glow)


func _build_combat_rifle(index: int) -> void:
	var length_extra: float = 0.035 * float(index - 1)

	# Buttstock behind the trigger hand.
	_add_box(weapon_root, Vector3(0.155, 0.185, 0.245), Vector3(0.0, 0.020, 0.300), weapon_olive, Vector3(-4.0, 0.0, 0.0))
	_add_box(weapon_root, Vector3(0.132, 0.155, 0.095), Vector3(0.0, 0.015, 0.455), weapon_rubber)

	# Receiver with narrower profile than the previous blocky placeholder.
	_add_box(weapon_root, Vector3(0.150, 0.170, 0.390), Vector3(0.0, 0.020, 0.020), weapon_dark)
	_add_box(weapon_root, Vector3(0.132, 0.060, 0.405), Vector3(0.0, 0.132, 0.015), weapon_metal)
	_add_box(weapon_root, Vector3(0.128, 0.082, 0.250), Vector3(0.0, -0.095, -0.035), weapon_olive)

	# Pistol grip and magazine.
	_add_box(weapon_root, Vector3(0.105, 0.235, 0.100), Vector3(0.015, -0.170, 0.105), weapon_rubber, Vector3(14.0, 0.0, 0.0))
	_add_box(weapon_root, Vector3(0.118, 0.260, 0.115), Vector3(-0.015, -0.185, -0.085), weapon_dark, Vector3(-8.0, 0.0, 0.0))

	# Long handguard where the left hand target sits.
	_add_box(weapon_root, Vector3(0.135, 0.135, 0.410 + length_extra), Vector3(0.0, 0.015, -0.365 - length_extra * 0.5), weapon_olive)
	_add_box(weapon_root, Vector3(0.115, 0.040, 0.390 + length_extra), Vector3(0.0, 0.095, -0.365 - length_extra * 0.5), weapon_metal)

	# Barrel and muzzle.
	_add_cylinder(weapon_root, 0.020, 0.410 + length_extra, Vector3(0.0, 0.015, -0.765 - length_extra * 0.5), weapon_metal, Vector3(90.0, 0.0, 0.0))
	_add_cylinder(weapon_root, 0.032, 0.095, Vector3(0.0, 0.015, -0.990 - length_extra), weapon_dark, Vector3(90.0, 0.0, 0.0))

	# Compact optic.
	_add_box(weapon_root, Vector3(0.090, 0.080, 0.145), Vector3(0.0, 0.170, -0.055), weapon_dark)
	_add_box(weapon_root, Vector3(0.032, 0.028, 0.032), Vector3(0.0, 0.217, -0.085), sight_glow)


func _build_materials() -> void:
	weapon_dark = _mat(Color(0.024, 0.029, 0.032), 0.78, 0.25)
	weapon_metal = _mat(Color(0.20, 0.22, 0.23), 0.88, 0.18)
	weapon_olive = _mat(Color(0.17, 0.21, 0.10), 0.34, 0.50)
	weapon_tan = _mat(Color(0.48, 0.33, 0.19), 0.08, 0.64)
	weapon_rubber = _mat(Color(0.035, 0.040, 0.038), 0.05, 0.88)
	sight_glow = _mat(Color(0.20, 0.85, 0.30), 0.15, 0.30)
	sight_glow.emission_enabled = true
	sight_glow.emission = Color(0.20, 0.85, 0.30)
	sight_glow.emission_energy_multiplier = 2.2


func _mat(color: Color, metallic_value: float, roughness_value: float) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metallic_value
	material.roughness = roughness_value
	return material


func _add_box(parent: Node3D, size: Vector3, pos: Vector3, material: Material, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var node: MeshInstance3D = MeshInstance3D.new()
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.position = pos
	node.rotation_degrees = rot
	node.material_override = material
	parent.add_child(node)
	return node


func _add_cylinder(parent: Node3D, radius: float, height: float, pos: Vector3, material: Material, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var node: MeshInstance3D = MeshInstance3D.new()
	var mesh: CylinderMesh = CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 14
	node.mesh = mesh
	node.position = pos
	node.rotation_degrees = rot
	node.material_override = material
	parent.add_child(node)
	return node
