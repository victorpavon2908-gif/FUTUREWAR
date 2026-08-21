extends Node

# Third-person combat layer for JEFE.
# Runs after jefe_body.gd updates locomotion, then locks the upper body into an
# armed stance and attaches a visible weapon to the AccuRIG right-hand bone.

var body_model: Node3D
var skeleton: Skeleton3D
var weapon_attachment: BoneAttachment3D
var weapon_root: Node3D
var equipped_index: int = 0
var bind_attempts: int = 0
var ready_for_combat: bool = false

var base_rotations: Dictionary = {}

var weapon_dark: StandardMaterial3D
var weapon_metal: StandardMaterial3D
var weapon_olive: StandardMaterial3D
var weapon_tan: StandardMaterial3D
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
		if bind_attempts < 120:
			await get_tree().process_frame
			call_deferred("_try_bind")
		return

	_cache_bones()
	_create_weapon_attachment()
	ready_for_combat = true


func _find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node as Skeleton3D
	for child: Node in node.get_children():
		var found: Skeleton3D = _find_skeleton(child)
		if found != null:
			return found
	return null


func _cache_bones() -> void:
	var names: Array[String] = [
		"CC_Base_Spine01", "CC_Base_Spine02", "CC_Base_Head",
		"CC_Base_L_Clavicle", "CC_Base_R_Clavicle",
		"CC_Base_L_Upperarm", "CC_Base_R_Upperarm",
		"CC_Base_L_Forearm", "CC_Base_R_Forearm",
		"CC_Base_L_Hand", "CC_Base_R_Hand"
	]
	for bone_name: String in names:
		var index: int = skeleton.find_bone(bone_name)
		if index >= 0:
			base_rotations[bone_name] = skeleton.get_bone_pose_rotation(index)


func apply_combat_pose(delta: float, speed_ratio: float, sprinting: bool, airborne: bool, aiming: bool) -> void:
	if not ready_for_combat or skeleton == null:
		return

	var move_amount: float = clampf(speed_ratio, 0.0, 1.0)
	var aim_boost: float = 1.0 if aiming else 0.0

	# Keep the rifle/pistol shouldered while walking. Sprint lowers it slightly but
	# JEFE remains visibly ready for combat instead of returning to a mannequin gait.
	if equipped_index == 0:
		_apply_pistol_stance(sprinting, airborne, aim_boost)
	else:
		_apply_rifle_stance(sprinting, airborne, aim_boost)

	# A little upper-body life so the pose does not look frozen on top of moving legs.
	var sway: float = sin(Time.get_ticks_msec() * 0.0065) * deg_to_rad(0.55) * move_amount
	_add_current_rotation("CC_Base_Spine02", deg_to_rad(-2.5) - deg_to_rad(1.2) * aim_boost, 0.0, sway)
	_add_current_rotation("CC_Base_Head", deg_to_rad(1.7) + deg_to_rad(0.8) * aim_boost, 0.0, -sway * 0.35)

	if weapon_root != null:
		var recoil_target: float = -0.018 if Input.is_action_pressed("shoot") else 0.0
		weapon_root.position.z = lerpf(weapon_root.position.z, _weapon_base_position().z + recoil_target, minf(delta * 18.0, 1.0))


func _apply_pistol_stance(sprinting: bool, airborne: bool, aim_boost: float) -> void:
	var lower: float = 12.0 if sprinting else 0.0
	if airborne:
		lower = 7.0

	_set_from_base("CC_Base_R_Clavicle", -2.0, -3.0, 6.0)
	_set_from_base("CC_Base_L_Clavicle", -2.0, 3.0, -6.0)
	_set_from_base("CC_Base_R_Upperarm", -43.0 + lower, -7.0, 29.0)
	_set_from_base("CC_Base_L_Upperarm", -47.0 + lower, 10.0, -31.0)
	_set_from_base("CC_Base_R_Forearm", -76.0 + lower * 0.35, -2.0, -4.0)
	_set_from_base("CC_Base_L_Forearm", -82.0 + lower * 0.35, 3.0, 5.0)
	_set_from_base("CC_Base_R_Hand", -4.0 - aim_boost * 2.0, 1.0, 2.0)
	_set_from_base("CC_Base_L_Hand", -7.0 - aim_boost * 2.0, -1.0, -3.0)


func _apply_rifle_stance(sprinting: bool, airborne: bool, aim_boost: float) -> void:
	var lower: float = 14.0 if sprinting else 0.0
	if airborne:
		lower = 8.0

	_set_from_base("CC_Base_R_Clavicle", -3.0, -4.0, 8.0)
	_set_from_base("CC_Base_L_Clavicle", -4.0, 5.0, -10.0)
	_set_from_base("CC_Base_R_Upperarm", -38.0 + lower, -8.0, 24.0)
	_set_from_base("CC_Base_L_Upperarm", -52.0 + lower, 13.0, -36.0)
	_set_from_base("CC_Base_R_Forearm", -69.0 + lower * 0.30, -3.0, -4.0)
	_set_from_base("CC_Base_L_Forearm", -88.0 + lower * 0.30, 4.0, 7.0)
	_set_from_base("CC_Base_R_Hand", -3.0 - aim_boost * 2.0, 0.0, 3.0)
	_set_from_base("CC_Base_L_Hand", -9.0 - aim_boost * 2.0, 0.0, -5.0)


func _set_from_base(bone_name: String, pitch_deg: float, yaw_deg: float, roll_deg: float) -> void:
	if not base_rotations.has(bone_name):
		return
	var index: int = skeleton.find_bone(bone_name)
	if index < 0:
		return
	var base: Quaternion = base_rotations[bone_name]
	var offset: Quaternion = Quaternion(Vector3.RIGHT, deg_to_rad(pitch_deg)) * Quaternion(Vector3.UP, deg_to_rad(yaw_deg)) * Quaternion(Vector3.BACK, deg_to_rad(roll_deg))
	skeleton.set_bone_pose_rotation(index, base * offset)


func _add_current_rotation(bone_name: String, pitch: float, yaw: float, roll: float) -> void:
	var index: int = skeleton.find_bone(bone_name)
	if index < 0:
		return
	var current: Quaternion = skeleton.get_bone_pose_rotation(index)
	var offset: Quaternion = Quaternion(Vector3.RIGHT, pitch) * Quaternion(Vector3.UP, yaw) * Quaternion(Vector3.BACK, roll)
	skeleton.set_bone_pose_rotation(index, current * offset)


func set_weapon_index(index: int) -> void:
	equipped_index = clampi(index, 0, 5)
	if weapon_root != null:
		_rebuild_weapon()


func _create_weapon_attachment() -> void:
	var hand_index: int = skeleton.find_bone("CC_Base_R_Hand")
	if hand_index < 0:
		return

	weapon_attachment = BoneAttachment3D.new()
	weapon_attachment.name = "JEFE_RIGHT_HAND_WEAPON"
	weapon_attachment.bone_name = "CC_Base_R_Hand"
	skeleton.add_child(weapon_attachment)

	weapon_root = Node3D.new()
	weapon_root.name = "JEFE_THIRD_PERSON_WEAPON"
	weapon_attachment.add_child(weapon_root)
	_rebuild_weapon()


func _rebuild_weapon() -> void:
	for child: Node in weapon_root.get_children():
		child.queue_free()

	weapon_root.position = _weapon_base_position()
	# AccuRIG hand basis differs from Godot weapon forward; this rotates barrel toward JEFE's -Z.
	weapon_root.rotation_degrees = Vector3(2.0, 92.0, -88.0)

	if equipped_index == 0:
		_build_tactical_pistol()
	else:
		_build_combat_rifle(equipped_index)


func _weapon_base_position() -> Vector3:
	if equipped_index == 0:
		return Vector3(0.015, -0.035, -0.145)
	return Vector3(0.020, -0.050, -0.205)


func _build_tactical_pistol() -> void:
	_add_box(weapon_root, Vector3(0.115, 0.105, 0.390), Vector3(0.0, 0.030, -0.185), weapon_dark)
	_add_box(weapon_root, Vector3(0.105, 0.185, 0.105), Vector3(0.0, -0.105, -0.025), weapon_tan, Vector3(11.0, 0.0, 0.0))
	_add_box(weapon_root, Vector3(0.092, 0.030, 0.310), Vector3(0.0, 0.091, -0.180), weapon_metal)
	_add_cylinder(weapon_root, 0.021, 0.255, Vector3(0.0, 0.025, -0.405), weapon_dark, Vector3(90.0, 0.0, 0.0))
	_add_box(weapon_root, Vector3(0.042, 0.032, 0.030), Vector3(0.0, 0.125, -0.285), sight_glow)


func _build_combat_rifle(index: int) -> void:
	var long_variant: float = 0.10 * float(index - 1)
	_add_box(weapon_root, Vector3(0.145, 0.180, 0.520 + long_variant), Vector3(0.0, 0.010, -0.245), weapon_dark)
	_add_box(weapon_root, Vector3(0.125, 0.095, 0.370), Vector3(0.0, -0.105, -0.215), weapon_olive, Vector3(8.0, 0.0, 0.0))
	_add_box(weapon_root, Vector3(0.120, 0.120, 0.330), Vector3(0.0, 0.015, 0.190), weapon_olive, Vector3(-7.0, 0.0, 0.0))
	_add_box(weapon_root, Vector3(0.095, 0.245, 0.120), Vector3(0.0, -0.155, -0.105), weapon_dark, Vector3(13.0, 0.0, 0.0))
	_add_cylinder(weapon_root, 0.023, 0.510 + long_variant, Vector3(0.0, 0.010, -0.660 - long_variant * 0.5), weapon_metal, Vector3(90.0, 0.0, 0.0))
	_add_box(weapon_root, Vector3(0.080, 0.070, 0.175), Vector3(0.0, 0.145, -0.180), weapon_dark)
	_add_box(weapon_root, Vector3(0.035, 0.030, 0.045), Vector3(0.0, 0.190, -0.230), sight_glow)


func _build_materials() -> void:
	weapon_dark = _mat(Color(0.025, 0.030, 0.032), 0.78, 0.24)
	weapon_metal = _mat(Color(0.19, 0.21, 0.22), 0.88, 0.18)
	weapon_olive = _mat(Color(0.18, 0.22, 0.105), 0.32, 0.48)
	weapon_tan = _mat(Color(0.49, 0.34, 0.20), 0.08, 0.62)
	sight_glow = _mat(Color(0.20, 0.85, 0.30), 0.15, 0.30)
	sight_glow.emission_enabled = true
	sight_glow.emission = Color(0.20, 0.85, 0.30)
	sight_glow.emission_energy_multiplier = 2.0


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
	mesh.radial_segments = 12
	node.mesh = mesh
	node.position = pos
	node.rotation_degrees = rot
	node.material_override = material
	parent.add_child(node)
	return node
