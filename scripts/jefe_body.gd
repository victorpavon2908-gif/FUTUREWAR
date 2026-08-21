extends Node3D

# JEFE runtime body driver.
# Prefer the AccuRIG FBX when it exists. It contains a real skinned skeleton and
# can be animated directly from gameplay without requiring paid motion clips.
const RIGGED_MODEL_PATH: String = "res://assets/characters/jefe/jefe_rigged.fbx"
const LEGACY_MODEL_PATH: String = "res://assets/characters/jefe/jefe.glb"

var elapsed: float = 0.0
var using_external_model: bool = false
var using_skeleton: bool = false
var base_position: Vector3
var external_root: Node3D
var skeleton: Skeleton3D

# AccuRIG / Character Creator bone cache.
var bone_ids: Dictionary = {}
var bone_base_rotations: Dictionary = {}

# Legacy unrigged GLB mesh groups. These remain as a fallback until the rigged
# FBX is present in the project.
var helmet_mesh: MeshInstance3D
var arms_mesh: MeshInstance3D
var gear_mesh: MeshInstance3D
var jumpjet_mesh: MeshInstance3D
var pants_mesh: MeshInstance3D
var torso_mesh: MeshInstance3D

var helmet_rest: Transform3D
var arms_rest: Transform3D
var gear_rest: Transform3D
var jumpjet_rest: Transform3D
var pants_rest: Transform3D
var torso_rest: Transform3D

var was_airborne: bool = false
var landing_pulse: float = 0.0

# Emergency fallback materials.
var armor: StandardMaterial3D
var armor_dark: StandardMaterial3D
var undersuit: StandardMaterial3D
var visor: StandardMaterial3D


func _ready() -> void:
	base_position = position
	_build_fallback_materials()
	using_external_model = _load_best_external_model()
	if not using_external_model:
		_build_simple_fallback()


func update_pose(delta: float, speed_ratio: float, sprinting: bool) -> void:
	var amount: float = clampf(speed_ratio, 0.0, 1.0)
	var cadence: float = lerpf(5.7, 9.4, amount)
	if sprinting:
		cadence = 12.2
	elapsed += delta * cadence

	var player: CharacterBody3D = get_parent() as CharacterBody3D
	var airborne: bool = player != null and not player.is_on_floor()
	var vertical_velocity: float = player.velocity.y if player != null else 0.0

	if was_airborne and not airborne:
		landing_pulse = 1.0
	was_airborne = airborne
	landing_pulse = move_toward(landing_pulse, 0.0, delta * 5.2)

	# Root motion is visual only; gameplay remains controlled by terrain_player.gd.
	var idle_breath: float = sin(elapsed * 0.38) * 0.008 * (1.0 - amount)
	var step_bob: float = absf(sin(elapsed)) * 0.024 * amount
	var sprint_bob: float = absf(sin(elapsed * 2.0)) * 0.010 if sprinting else 0.0
	var landing_drop: float = 0.060 * landing_pulse
	var jump_lift: float = 0.020 if airborne else 0.0
	position = base_position + Vector3(0.0, idle_breath + step_bob + sprint_bob + jump_lift - landing_drop, 0.0)

	if not using_external_model or external_root == null:
		return

	if using_skeleton and skeleton != null:
		_animate_skeleton(amount, sprinting, airborne, vertical_velocity)
	else:
		_animate_legacy_unrigged(delta, amount, sprinting, airborne)


func _animate_skeleton(amount: float, sprinting: bool, airborne: bool, vertical_velocity: float) -> void:
	# Restore the bones we own to their imported bind pose before applying offsets.
	_reset_driven_bones()

	var phase: float = sin(elapsed)
	var phase_cos: float = cos(elapsed)
	var double_phase: float = sin(elapsed * 2.0)
	var idle_amount: float = 1.0 - amount

	# Idle: tiny breathing and helmet stabilization so JEFE never feels frozen.
	var breath: float = sin(elapsed * 0.42) * deg_to_rad(0.75) * idle_amount
	_apply_bone_rotation("CC_Base_Spine02", breath, 0.0, 0.0)
	_apply_bone_rotation("CC_Base_Head", -breath * 0.45, 0.0, sin(elapsed * 0.25) * deg_to_rad(0.35) * idle_amount)

	if airborne:
		_animate_jump_pose(vertical_velocity)
		return

	if amount <= 0.025:
		return

	# Walk / run gait. Sprint increases stride and arm drive without changing the
	# actual CharacterBody3D speed or collision capsule.
	var stride_deg: float = lerpf(19.0, 29.0, amount)
	var knee_deg: float = lerpf(17.0, 31.0, amount)
	var arm_deg: float = lerpf(13.0, 25.0, amount)
	var torso_lean_deg: float = lerpf(1.5, 4.5, amount)
	if sprinting:
		stride_deg = 38.0
		knee_deg = 42.0
		arm_deg = 33.0
		torso_lean_deg = 8.0

	var stride: float = deg_to_rad(stride_deg) * phase
	var knee_left: float = deg_to_rad(knee_deg) * maxf(0.0, phase_cos)
	var knee_right: float = deg_to_rad(knee_deg) * maxf(0.0, -phase_cos)
	var arm_swing: float = deg_to_rad(arm_deg) * phase

	# Legs.
	_apply_bone_rotation("CC_Base_L_Thigh", stride, 0.0, 0.0)
	_apply_bone_rotation("CC_Base_R_Thigh", -stride, 0.0, 0.0)
	_apply_bone_rotation("CC_Base_L_Calf", -knee_left, 0.0, 0.0)
	_apply_bone_rotation("CC_Base_R_Calf", -knee_right, 0.0, 0.0)
	_apply_bone_rotation("CC_Base_L_Foot", -stride * 0.16 + knee_left * 0.20, 0.0, 0.0)
	_apply_bone_rotation("CC_Base_R_Foot", stride * 0.16 + knee_right * 0.20, 0.0, 0.0)

	# Arms move opposite the legs. A small permanent elbow bend keeps the armored
	# silhouette from looking like a mannequin while running.
	_apply_bone_rotation("CC_Base_L_Upperarm", -arm_swing, 0.0, deg_to_rad(-1.5) * amount)
	_apply_bone_rotation("CC_Base_R_Upperarm", arm_swing, 0.0, deg_to_rad(1.5) * amount)
	_apply_bone_rotation("CC_Base_L_Forearm", deg_to_rad(-7.0) - absf(arm_swing) * 0.22, 0.0, 0.0)
	_apply_bone_rotation("CC_Base_R_Forearm", deg_to_rad(-7.0) - absf(arm_swing) * 0.22, 0.0, 0.0)

	# Torso counter-rotation gives weight to the armor and prevents robotic motion.
	var torso_roll: float = double_phase * deg_to_rad(1.4) * amount
	var torso_yaw: float = -phase * deg_to_rad(2.0) * amount
	_apply_bone_rotation("CC_Base_Waist", deg_to_rad(-torso_lean_deg) * 0.35, torso_yaw * 0.35, -torso_roll * 0.35)
	_apply_bone_rotation("CC_Base_Spine01", deg_to_rad(-torso_lean_deg) * 0.35, torso_yaw * 0.35, -torso_roll * 0.35)
	_apply_bone_rotation("CC_Base_Spine02", deg_to_rad(-torso_lean_deg) * 0.30 + breath, torso_yaw * 0.30, -torso_roll * 0.30)
	_apply_bone_rotation("CC_Base_Head", deg_to_rad(torso_lean_deg) * 0.18 - breath * 0.45, -torso_yaw * 0.20, torso_roll * 0.20)

	# Landing compression blends out automatically through landing_pulse.
	if landing_pulse > 0.0:
		var impact: float = sin(landing_pulse * PI)
		_apply_bone_rotation("CC_Base_L_Thigh", stride + deg_to_rad(7.0) * impact, 0.0, 0.0)
		_apply_bone_rotation("CC_Base_R_Thigh", -stride + deg_to_rad(7.0) * impact, 0.0, 0.0)
		_apply_bone_rotation("CC_Base_L_Calf", -knee_left - deg_to_rad(12.0) * impact, 0.0, 0.0)
		_apply_bone_rotation("CC_Base_R_Calf", -knee_right - deg_to_rad(12.0) * impact, 0.0, 0.0)


func _animate_jump_pose(vertical_velocity: float) -> void:
	var rising: bool = vertical_velocity > 0.25
	var thigh_angle: float = deg_to_rad(13.0 if rising else 8.0)
	var knee_angle: float = deg_to_rad(21.0 if rising else 13.0)
	var arm_angle: float = deg_to_rad(-9.0 if rising else -4.0)

	_apply_bone_rotation("CC_Base_L_Thigh", thigh_angle, 0.0, deg_to_rad(-3.0))
	_apply_bone_rotation("CC_Base_R_Thigh", thigh_angle, 0.0, deg_to_rad(3.0))
	_apply_bone_rotation("CC_Base_L_Calf", -knee_angle, 0.0, 0.0)
	_apply_bone_rotation("CC_Base_R_Calf", -knee_angle, 0.0, 0.0)
	_apply_bone_rotation("CC_Base_L_Upperarm", arm_angle, 0.0, deg_to_rad(-4.0))
	_apply_bone_rotation("CC_Base_R_Upperarm", arm_angle, 0.0, deg_to_rad(4.0))
	_apply_bone_rotation("CC_Base_Spine01", deg_to_rad(-3.0), 0.0, 0.0)
	_apply_bone_rotation("CC_Base_Spine02", deg_to_rad(-2.0), 0.0, 0.0)


func _apply_bone_rotation(bone_name: String, pitch: float, yaw: float, roll: float) -> void:
	if skeleton == null or not bone_ids.has(bone_name):
		return
	var index: int = int(bone_ids[bone_name])
	var base_rotation: Quaternion = bone_base_rotations[bone_name]
	var offset: Quaternion = Quaternion(Vector3.RIGHT, pitch) * Quaternion(Vector3.UP, yaw) * Quaternion(Vector3.BACK, roll)
	skeleton.set_bone_pose_rotation(index, base_rotation * offset)


func _reset_driven_bones() -> void:
	if skeleton == null:
		return
	for bone_name: Variant in bone_ids.keys():
		var name_string: String = String(bone_name)
		var index: int = int(bone_ids[name_string])
		var base_rotation: Quaternion = bone_base_rotations[name_string]
		skeleton.set_bone_pose_rotation(index, base_rotation)


func _load_best_external_model() -> bool:
	var selected_path: String = ""
	if ResourceLoader.exists(RIGGED_MODEL_PATH):
		selected_path = RIGGED_MODEL_PATH
	elif ResourceLoader.exists(LEGACY_MODEL_PATH):
		selected_path = LEGACY_MODEL_PATH
	else:
		return false

	var resource: Resource = load(selected_path)
	if not resource is PackedScene:
		return false

	var model: Node = (resource as PackedScene).instantiate()
	if not model is Node3D:
		model.queue_free()
		return false

	external_root = model as Node3D
	external_root.name = "JEFE_PRODUCTION_MODEL"
	external_root.position = Vector3(0.0, -1.05, 0.0)
	add_child(external_root)
	_cache_external_nodes(external_root)

	using_skeleton = skeleton != null
	if using_skeleton:
		_cache_accu_rig_bones()
	return true


func _cache_external_nodes(node: Node) -> void:
	if node is Skeleton3D and skeleton == null:
		skeleton = node as Skeleton3D

	if node is AnimationPlayer:
		# Character-only AccuRIG exports can contain a bind/reference animation stack.
		# Do not let it override the gameplay-driven skeleton.
		(node as AnimationPlayer).stop()

	if node is MeshInstance3D:
		var mesh_instance: MeshInstance3D = node as MeshInstance3D
		var material_name: String = ""
		if mesh_instance.mesh != null and mesh_instance.mesh.get_surface_count() > 0:
			var material: Material = mesh_instance.mesh.surface_get_material(0)
			if material != null:
				material_name = String(material.resource_name).to_lower()

		if material_name.contains("helmet"):
			helmet_mesh = mesh_instance
			helmet_rest = mesh_instance.transform
		elif material_name == "material":
			arms_mesh = mesh_instance
			arms_rest = mesh_instance.transform
		elif material_name.contains("gear"):
			gear_mesh = mesh_instance
			gear_rest = mesh_instance.transform
		elif material_name.contains("jumpjet"):
			jumpjet_mesh = mesh_instance
			jumpjet_rest = mesh_instance.transform
		elif material_name.contains("pants"):
			pants_mesh = mesh_instance
			pants_rest = mesh_instance.transform
		elif material_name.contains("torso"):
			torso_mesh = mesh_instance
			torso_rest = mesh_instance.transform

	for child: Node in node.get_children():
		_cache_external_nodes(child)


func _cache_accu_rig_bones() -> void:
	if skeleton == null:
		return

	var driven_bones: Array[String] = [
		"CC_Base_Hip",
		"CC_Base_Pelvis",
		"CC_Base_Waist",
		"CC_Base_Spine01",
		"CC_Base_Spine02",
		"CC_Base_Head",
		"CC_Base_L_Clavicle",
		"CC_Base_R_Clavicle",
		"CC_Base_L_Upperarm",
		"CC_Base_R_Upperarm",
		"CC_Base_L_Forearm",
		"CC_Base_R_Forearm",
		"CC_Base_L_Hand",
		"CC_Base_R_Hand",
		"CC_Base_L_Thigh",
		"CC_Base_R_Thigh",
		"CC_Base_L_Calf",
		"CC_Base_R_Calf",
		"CC_Base_L_Foot",
		"CC_Base_R_Foot",
		"CC_Base_L_ToeBase",
		"CC_Base_R_ToeBase"
	]

	for bone_name: String in driven_bones:
		var index: int = skeleton.find_bone(bone_name)
		if index >= 0:
			bone_ids[bone_name] = index
			bone_base_rotations[bone_name] = skeleton.get_bone_pose_rotation(index)


func _animate_legacy_unrigged(delta: float, amount: float, sprinting: bool, airborne: bool) -> void:
	_restore_mesh_transforms()

	var target_pitch: float = deg_to_rad(-2.0) * amount
	if sprinting:
		target_pitch = deg_to_rad(-7.0) * amount
	if airborne:
		target_pitch = deg_to_rad(-3.0)
	var side_sway: float = sin(elapsed * 0.5) * deg_to_rad(1.6) * amount
	external_root.rotation.x = lerp_angle(external_root.rotation.x, target_pitch, minf(delta * 10.0, 1.0))
	external_root.rotation.z = lerp_angle(external_root.rotation.z, side_sway, minf(delta * 9.0, 1.0))

	var step_wave: float = sin(elapsed)
	var double_wave: float = sin(elapsed * 2.0)
	var run_mult: float = 1.45 if sprinting else 1.0

	if pants_mesh != null:
		pants_mesh.rotation.x += step_wave * deg_to_rad(2.6) * amount * run_mult
		pants_mesh.position.y += absf(double_wave) * 0.010 * amount
	if arms_mesh != null:
		arms_mesh.rotation.x += -step_wave * deg_to_rad(2.2) * amount * run_mult
		arms_mesh.rotation.z += double_wave * deg_to_rad(0.8) * amount
	if torso_mesh != null:
		torso_mesh.rotation.z += -step_wave * deg_to_rad(1.25) * amount
		torso_mesh.position.y += sin(elapsed * 0.5) * 0.005 * (1.0 - amount)
	if gear_mesh != null:
		gear_mesh.rotation.z += -step_wave * deg_to_rad(1.0) * amount
		gear_mesh.position.y += absf(double_wave) * 0.004 * amount
	if jumpjet_mesh != null:
		jumpjet_mesh.rotation.z += -step_wave * deg_to_rad(0.65) * amount
	if helmet_mesh != null:
		helmet_mesh.rotation.z += step_wave * deg_to_rad(0.55) * amount
		helmet_mesh.rotation.x += sin(elapsed * 0.5) * deg_to_rad(0.35) * (1.0 - amount)


func _restore_mesh_transforms() -> void:
	if helmet_mesh != null:
		helmet_mesh.transform = helmet_rest
	if arms_mesh != null:
		arms_mesh.transform = arms_rest
	if gear_mesh != null:
		gear_mesh.transform = gear_rest
	if jumpjet_mesh != null:
		jumpjet_mesh.transform = jumpjet_rest
	if pants_mesh != null:
		pants_mesh.transform = pants_rest
	if torso_mesh != null:
		torso_mesh.transform = torso_rest


func _build_fallback_materials() -> void:
	armor = _material(Color(0.22, 0.27, 0.12), 0.48, 0.48)
	armor_dark = _material(Color(0.07, 0.09, 0.055), 0.38, 0.58)
	undersuit = _material(Color(0.018, 0.021, 0.022), 0.05, 0.92)
	visor = _material(Color(0.92, 0.45, 0.05), 0.70, 0.20)
	visor.emission_enabled = true
	visor.emission = Color(0.92, 0.35, 0.03)
	visor.emission_energy_multiplier = 1.8


func _build_simple_fallback() -> void:
	var torso: MeshInstance3D = MeshInstance3D.new()
	var torso_mesh_data: CapsuleMesh = CapsuleMesh.new()
	torso_mesh_data.radius = 0.32
	torso_mesh_data.height = 1.05
	torso.mesh = torso_mesh_data
	torso.position = Vector3(0.0, 0.35, 0.0)
	torso.material_override = armor
	add_child(torso)

	var head: MeshInstance3D = MeshInstance3D.new()
	var head_mesh_data: SphereMesh = SphereMesh.new()
	head_mesh_data.radius = 0.25
	head_mesh_data.height = 0.50
	head.mesh = head_mesh_data
	head.position = Vector3(0.0, 1.10, 0.0)
	head.material_override = armor_dark
	add_child(head)

	var visor_node: MeshInstance3D = MeshInstance3D.new()
	var visor_mesh_data: BoxMesh = BoxMesh.new()
	visor_mesh_data.size = Vector3(0.36, 0.11, 0.035)
	visor_node.mesh = visor_mesh_data
	visor_node.position = Vector3(0.0, 1.12, -0.235)
	visor_node.material_override = visor
	add_child(visor_node)


func _material(color: Color, metallic_value: float, roughness_value: float) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metallic_value
	material.roughness = roughness_value
	return material