extends Node

# Third-person combat layer for JEFE.
# Runs after locomotion so the legs keep moving while the upper body stays in a
# believable armed-ready pose. The visible third-person weapon is attached to
# the AccuRIG right-hand bone.

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
		"CC_Base_Waist", "CC_Base_Spine01", "CC_Base_Spine02", "CC_Base_Head",
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

	# Own the upper torso after the locomotion pass. This keeps the shoulders
	# squared and prevents the old walk arm-swing from fighting the weapon pose.
	var sprint_lean: float = 3.0 if sprinting else 0.0
	var air_lean: float = 2.0 if airborne else 0.0
	_set_from_base("CC_Base_Waist", -1.5 - sprint_lean * 0.25, 1.0, 0.0)
	_set_from_base("CC_Base_Spine01", -3.0 - sprint_lean * 0.45 - air_lean, 2.5, 0.0)
	_set_from_base("CC_Base_Spine02", -5.0 - sprint_lean * 0.30, 4.0, 0.0)
	_set_from_base("CC_Base_Head", 4.0 + aim_boost * 1.5, -3.0, 0.0)

	if equipped_index == 0:
		_apply_pistol_stance(sprinting, airborne, aim_boost)
	else:
		_apply_rifle_stance(sprinting, airborne, aim_boost)

	# Small breathing/sway only. Keep it subtle so the weapon reads as controlled.
	var sway: float = sin(Time.get_ticks_msec() * 0.0055) * deg_to_rad(0.32) * (0.35 + move_amount * 0.65)
	_add_current_rotation("CC_Base_Spine02", 0.0, 0.0, sway)
	_add_current_rotation("CC_Base_Head", 0.0, 0.0, -sway * 0.25)

	if weapon_root != null:
		var base_pos: Vector3 = _weapon_base_position()
		var recoil: float = 0.014 if Input.is_action_pressed("shoot") else 0.0
		weapon_root.position = weapon_root.position.lerp(base_pos + Vector3(0.0, 0.0, recoil), minf(delta * 22.0, 1.0))


func _apply_pistol_stance(sprinting: bool, airborne: bool, aim_boost: float) -> void:
	# Compact two-hand pistol stance: elbows slightly bent and below shoulder line.
	var lower: float = 8.0 if sprinting else 0.0
	if airborne:
		lower = 5.0

	_set_from_base("CC_Base_R_Clavicle", -2.0, -6.0, 4.0)
	_set_from_base("CC_Base_L_Clavicle", -2.0, 7.0, -4.0)
	_set_from_base("CC_Base_R_Upperarm", -35.0 + lower, -15.0, 17.0)
	_set_from_base("CC_Base_L_Upperarm", -38.0 + lower, 17.0, -16.0)
	_set_from_base("CC_Base_R_Forearm", -68.0 + lower * 0.35, 7.0, 3.0)
	_set_from_base("CC_Base_L_Forearm", -72.0 + lower * 0.35, -7.0, -3.0)
	_set_from_base("CC_Base_R_Hand", 5.0 - aim_boost * 2.0, 0.0, 6.0)
	_set_from_base("CC_Base_L_Hand", 5.0 - aim_boost * 2.0, 0.0, -6.0)


func _apply_rifle_stance(sprinting: bool, airborne: bool, aim_boost: float) -> void:
	# High-ready carbine stance. The trigger elbow stays tucked; the support arm
	# reaches forward under the handguard instead of crossing the chest.
	var lower: float = 10.0 if sprinting else 0.0
	if airborne:
		lower = 6.0

	_set_from_base("CC_Base_R_Clavicle", -3.0, -8.0, 5.0)
	_set_from_base("CC_Base_L_Clavicle", -2.0, 11.0, -4.0)
	_set_from_base("CC_Base_R_Upperarm", -32.0 + lower, -18.0, 18.0)
	_set_from_base("CC_Base_L_Upperarm", -46.0 + lower * 0.70, 29.0, -12.0)
	_set_from_base("CC_Base_R_Forearm", -73.0 + lower * 0.30, 9.0, 4.0)
	_set_from_base("CC_Base_L_Forearm", -78.0 + lower * 0.25, -11.0, -5.0)
	_set_from_base("CC_Base_R_Hand", 7.0 - aim_boost * 2.0, 1.0, 8.0)
	_set_from_base("CC_Base_L_Hand", 9.0 - aim_boost * 2.0, -2.0, -9.0)


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
	if weapon_root == null:
		return
	for child: Node in weapon_root.get_children():
		child.queue_free()

	weapon_root.position = _weapon_base_position()
	# AccuRIG right-hand local axes: rotate the weapon so the grip sits in the palm
	# and the barrel points forward, not sideways across the chest.
	if equipped_index == 0:
		weapon_root.rotation_degrees = Vector3(-91.0, 5.0, 91.0)
		weapon_root.scale = Vector3(0.88, 0.88, 0.88)
		_build_tactical_pistol()
	else:
		weapon_root.rotation_degrees = Vector3(-92.0, 8.0, 92.0)
		weapon_root.scale = Vector3(0.90, 0.90, 0.90)
		_build_combat_rifle(equipped_index)


func _weapon_base_position() -> Vector3:
	if equipped_index == 0:
		return Vector3(0.070, -0.015, -0.110)
	return Vector3(0.105, -0.020, -0.155)


func _build_tactical_pistol() -> void:
	# Compact sidearm with a distinct slide, polymer grip, trigger guard and sights.
	_add_box(weapon_root, Vector3(0.090, 0.075, 0.245), Vector3(0.0, 0.028, -0.118), weapon_dark)
	_add_box(weapon_root, Vector3(0.082, 0.022, 0.210), Vector3(0.0, 0.080, -0.115), weapon_metal)
	_add_box(weapon_root, Vector3(0.082, 0.155, 0.075), Vector3(0.0, -0.090, -0.020), weapon_tan, Vector3(12.0, 0.0, 0.0))
	_add_box(weapon_root, Vector3(0.075, 0.034, 0.100), Vector3(0.0, -0.040, -0.082), weapon_tan)
	_add_cylinder(weapon_root, 0.012, 0.120, Vector3(0.0, -0.050, -0.085), weapon_dark, Vector3(0.0, 0.0, 90.0))
	_add_cylinder(weapon_root, 0.013, 0.165, Vector3(0.0, 0.024, -0.262), weapon_metal, Vector3(90.0, 0.0, 0.0))
	_add_box(weapon_root, Vector3(0.025, 0.022, 0.022), Vector3(0.0, 0.105, -0.205), sight_glow)


func _build_combat_rifle(index: int) -> void:
	# Slim original sci-fi carbine sized for a 2.12 m armored soldier.
	var variant: float = float(index - 1)
	var barrel_extra: float = minf(variant * 0.025, 0.10)

	# Central receiver and upper rail.
	_add_box(weapon_root, Vector3(0.115, 0.135, 0.330), Vector3(0.0, 0.010, -0.145), weapon_dark)
	_add_box(weapon_root, Vector3(0.090, 0.026, 0.320), Vector3(0.0, 0.094, -0.150), weapon_metal)
	_add_box(weapon_root, Vector3(0.102, 0.090, 0.250), Vector3(0.0, 0.005, -0.420), weapon_olive)

	# Rear stock sits against the shoulder instead of forming a huge block.
	_add_box(weapon_root, Vector3(0.105, 0.105, 0.230), Vector3(0.0, 0.012, 0.150), weapon_olive, Vector3(-4.0, 0.0, 0.0))
	_add_box(weapon_root, Vector3(0.120, 0.145, 0.075), Vector3(0.0, 0.005, 0.275), weapon_rubber, Vector3(-7.0, 0.0, 0.0))

	# Pistol grip and magazine give the silhouette a believable center of mass.
	_add_box(weapon_root, Vector3(0.075, 0.170, 0.075), Vector3(0.0, -0.125, -0.040), weapon_rubber, Vector3(14.0, 0.0, 0.0))
	_add_box(weapon_root, Vector3(0.082, 0.210, 0.085), Vector3(0.0, -0.145, -0.185), weapon_dark, Vector3(9.0, 0.0, 0.0))

	# Handguard and barrel.
	_add_box(weapon_root, Vector3(0.105, 0.095, 0.280), Vector3(0.0, 0.000, -0.445), weapon_olive)
	_add_cylinder(weapon_root, 0.015, 0.300 + barrel_extra, Vector3(0.0, 0.000, -0.730 - barrel_extra * 0.5), weapon_metal, Vector3(90.0, 0.0, 0.0))
	_add_cylinder(weapon_root, 0.024, 0.080, Vector3(0.0, 0.000, -0.920 - barrel_extra), weapon_dark, Vector3(90.0, 0.0, 0.0))

	# Compact optic and luminous front element.
	_add_box(weapon_root, Vector3(0.075, 0.070, 0.105), Vector3(0.0, 0.145, -0.170), weapon_dark)
	_add_box(weapon_root, Vector3(0.038, 0.025, 0.030), Vector3(0.0, 0.185, -0.205), sight_glow)


func _build_materials() -> void:
	weapon_dark = _mat(Color(0.025, 0.030, 0.032), 0.78, 0.24)
	weapon_metal = _mat(Color(0.18, 0.20, 0.21), 0.88, 0.18)
	weapon_olive = _mat(Color(0.17, 0.21, 0.095), 0.30, 0.52)
	weapon_tan = _mat(Color(0.48, 0.33, 0.19), 0.08, 0.62)
	weapon_rubber = _mat(Color(0.035, 0.040, 0.038), 0.05, 0.88)
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
	mesh.radial_segments = 14
	node.mesh = mesh
	node.position = pos
	node.rotation_degrees = rot
	node.material_override = material
	parent.add_child(node)
	return node
