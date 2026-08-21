extends Node3D

# JEFE runtime body driver.
# The production GLB currently has no skeleton, so this script adds a polished
# rigless locomotion layer (idle breathing, footsteps, run lean, jump and landing)
# while keeping a fallback body if the external asset is unavailable.
const EXTERNAL_MODEL_PATH: String = "res://assets/characters/jefe/jefe.glb"

var elapsed: float = 0.0
var using_external_model: bool = false
var base_position: Vector3
var external_root: Node3D

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

# Fallback materials.
var armor: StandardMaterial3D
var armor_dark: StandardMaterial3D
var undersuit: StandardMaterial3D
var visor: StandardMaterial3D


func _ready() -> void:
	base_position = position
	_build_fallback_materials()
	if ResourceLoader.exists(EXTERNAL_MODEL_PATH):
		using_external_model = _load_external_model()
	if not using_external_model:
		_build_simple_fallback()


func update_pose(delta: float, speed_ratio: float, sprinting: bool) -> void:
	var amount: float = clampf(speed_ratio, 0.0, 1.0)
	var cadence: float = 6.2 + amount * 5.4
	if sprinting:
		cadence += 2.2
	elapsed += delta * cadence

	var player: CharacterBody3D = get_parent() as CharacterBody3D
	var airborne: bool = player != null and not player.is_on_floor()
	if was_airborne and not airborne:
		landing_pulse = 1.0
	was_airborne = airborne
	landing_pulse = move_toward(landing_pulse, 0.0, delta * 5.5)

	# Vertical motion: subtle breathing when idle, heavier step compression while moving.
	var idle_breath: float = sin(elapsed * 0.42) * 0.010 * (1.0 - amount)
	var step_bob: float = absf(sin(elapsed)) * 0.034 * amount
	var sprint_bob: float = 0.012 * amount if sprinting else 0.0
	var landing_drop: float = 0.075 * landing_pulse
	var jump_lift: float = 0.025 if airborne else 0.0
	position = base_position + Vector3(0.0, idle_breath + step_bob + sprint_bob + jump_lift - landing_drop, 0.0)

	if not using_external_model or external_root == null:
		return

	_animate_external_model(delta, amount, sprinting, airborne)


func _animate_external_model(delta: float, amount: float, sprinting: bool, airborne: bool) -> void:
	# Restore imported mesh transforms each frame so procedural offsets never accumulate.
	_restore_mesh_transforms()

	# Whole-body locomotion. Keep Y rotation untouched because terrain_player aligns
	# the imported model to FUTUREWAR's -Z forward direction.
	var target_pitch: float = deg_to_rad(-2.0) * amount
	if sprinting:
		target_pitch = deg_to_rad(-7.0) * amount
	if airborne:
		target_pitch = deg_to_rad(-3.0)
	var side_sway: float = sin(elapsed * 0.5) * deg_to_rad(1.6) * amount
	external_root.rotation.x = lerp_angle(external_root.rotation.x, target_pitch, minf(delta * 10.0, 1.0))
	external_root.rotation.z = lerp_angle(external_root.rotation.z, side_sway, minf(delta * 9.0, 1.0))

	# The downloaded model is separated by material groups rather than bones.
	# We animate those groups conservatively so the silhouette feels alive without
	# distorting the mesh or requiring a Skeleton3D.
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
		# Head stabilization keeps the helmet from feeling welded to the torso.
		helmet_mesh.rotation.z += step_wave * deg_to_rad(0.55) * amount
		helmet_mesh.rotation.x += sin(elapsed * 0.5) * deg_to_rad(0.35) * (1.0 - amount)

	if airborne:
		# Compact the pose slightly in the air. This is deliberately subtle because
		# the current GLB is unskinned and large offsets would expose that limitation.
		if pants_mesh != null:
			pants_mesh.rotation.x += deg_to_rad(-3.0)
		if arms_mesh != null:
			arms_mesh.rotation.x += deg_to_rad(2.0)

	if landing_pulse > 0.0:
		var impact: float = sin(landing_pulse * PI) * 0.035
		if torso_mesh != null:
			torso_mesh.position.y -= impact
		if gear_mesh != null:
			gear_mesh.position.y -= impact * 0.75


func _load_external_model() -> bool:
	var resource: Resource = load(EXTERNAL_MODEL_PATH)
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
	_cache_external_meshes(external_root)
	return true


func _cache_external_meshes(node: Node) -> void:
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
		_cache_external_meshes(child)


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
	# Lightweight emergency fallback only. The production GLB is the intended body.
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
