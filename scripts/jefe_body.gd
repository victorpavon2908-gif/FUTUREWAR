extends Node3D

# JEFE — original heavy sci-fi supersoldier for FUTUREWAR.
# The procedural body is the in-game fallback. If a production GLB is later
# placed at EXTERNAL_MODEL_PATH, it will be used automatically instead.
const EXTERNAL_MODEL_PATH: String = "res://assets/characters/jefe/jefe.glb"

var armor_olive: StandardMaterial3D
var armor_olive_dark: StandardMaterial3D
var armor_edge: StandardMaterial3D
var armor_shadow: StandardMaterial3D
var undersuit: StandardMaterial3D
var rubber: StandardMaterial3D
var visor_gold: StandardMaterial3D
var metal_dark: StandardMaterial3D
var amber_light: StandardMaterial3D

var left_arm: Node3D
var right_arm: Node3D
var left_leg: Node3D
var right_leg: Node3D
var torso_root: Node3D
var head_root: Node3D
var elapsed: float = 0.0
var using_external_model: bool = false


func _ready() -> void:
	_build_materials()
	if ResourceLoader.exists(EXTERNAL_MODEL_PATH):
		using_external_model = _load_external_model()
	if not using_external_model:
		_build_character()


func update_pose(delta: float, speed_ratio: float, sprinting: bool) -> void:
	elapsed += delta * (6.2 + speed_ratio * 5.2)
	var amount: float = clampf(speed_ratio, 0.0, 1.0)
	var stride: float = sin(elapsed) * deg_to_rad(22.0) * amount
	var sprint_multiplier: float = 1.28 if sprinting else 1.0
	stride *= sprint_multiplier

	if not using_external_model:
		if left_arm != null:
			left_arm.rotation.x = lerpf(left_arm.rotation.x, -stride * 0.66, minf(delta * 13.0, 1.0))
		if right_arm != null:
			right_arm.rotation.x = lerpf(right_arm.rotation.x, stride * 0.66, minf(delta * 13.0, 1.0))
		if left_leg != null:
			left_leg.rotation.x = lerpf(left_leg.rotation.x, stride, minf(delta * 14.0, 1.0))
		if right_leg != null:
			right_leg.rotation.x = lerpf(right_leg.rotation.x, -stride, minf(delta * 14.0, 1.0))
		if torso_root != null:
			torso_root.rotation.z = sin(elapsed) * deg_to_rad(1.3) * amount
		if head_root != null:
			head_root.rotation.y = sin(elapsed * 0.5) * deg_to_rad(1.5) * amount

	position.y = sin(elapsed * 2.0) * 0.016 * amount


func _load_external_model() -> bool:
	var resource: Resource = load(EXTERNAL_MODEL_PATH)
	if not resource is PackedScene:
		return false
	var model: Node = (resource as PackedScene).instantiate()
	if not model is Node3D:
		model.queue_free()
		return false
	model.name = "JEFE_PRODUCTION_MODEL"
	(model as Node3D).position = Vector3(0.0, -1.05, 0.0)
	add_child(model)
	return true


func _build_materials() -> void:
	armor_olive = _mat(Color(0.235, 0.255, 0.145), 0.54, 0.43)
	armor_olive_dark = _mat(Color(0.105, 0.125, 0.075), 0.48, 0.50)
	armor_edge = _mat(Color(0.34, 0.35, 0.25), 0.72, 0.30)
	armor_shadow = _mat(Color(0.048, 0.055, 0.044), 0.38, 0.58)
	undersuit = _mat(Color(0.018, 0.021, 0.022), 0.08, 0.92)
	rubber = _mat(Color(0.025, 0.027, 0.026), 0.02, 0.98)
	metal_dark = _mat(Color(0.075, 0.080, 0.075), 0.82, 0.26)
	visor_gold = _emissive(Color(1.0, 0.48, 0.055), 2.0, 0.76, 0.18)
	amber_light = _emissive(Color(1.0, 0.28, 0.025), 3.2, 0.42, 0.22)


func _build_character() -> void:
	# Overall proportions: ~2.18 m armored supersoldier.
	torso_root = Node3D.new()
	torso_root.name = "JEFE_TORSO"
	add_child(torso_root)

	# Black technical pressure suit / body mass.
	_add_capsule(torso_root, 0.30, 0.94, Vector3(0.0, 0.34, 0.02), undersuit)
	_add_capsule(torso_root, 0.255, 0.55, Vector3(0.0, -0.02, 0.03), undersuit)

	# Layered chest armor: broad upper plate, split pectorals, sternum and ribs.
	_add_box(torso_root, Vector3(0.76, 0.34, 0.31), Vector3(0.0, 0.52, -0.005), armor_olive, Vector3(-5.0, 0.0, 0.0))
	_add_box(torso_root, Vector3(0.34, 0.24, 0.075), Vector3(-0.205, 0.55, -0.185), armor_olive_dark, Vector3(-4.0, -4.0, -2.0))
	_add_box(torso_root, Vector3(0.34, 0.24, 0.075), Vector3(0.205, 0.55, -0.185), armor_olive_dark, Vector3(-4.0, 4.0, 2.0))
	_add_box(torso_root, Vector3(0.16, 0.36, 0.085), Vector3(0.0, 0.47, -0.205), armor_edge, Vector3(-3.0, 0.0, 0.0))
	_add_box(torso_root, Vector3(0.58, 0.16, 0.35), Vector3(0.0, 0.72, 0.015), armor_olive_dark)
	_add_box(torso_root, Vector3(0.62, 0.13, 0.29), Vector3(0.0, 0.27, 0.005), armor_shadow, Vector3(6.0, 0.0, 0.0))

	# Segmented abdomen, each plate slightly offset for a more manufactured look.
	for i: int in range(3):
		var y: float = 0.13 - float(i) * 0.10
		var width: float = 0.48 - float(i) * 0.035
		_add_box(torso_root, Vector3(width, 0.075, 0.095), Vector3(0.0, y, -0.17), armor_olive_dark, Vector3(2.0 + float(i), 0.0, 0.0))

	# Collar / neck protection.
	_add_cylinder(torso_root, 0.20, 0.17, Vector3(0.0, 0.82, 0.0), armor_shadow)
	_add_box(torso_root, Vector3(0.18, 0.17, 0.20), Vector3(-0.23, 0.80, 0.02), armor_olive_dark, Vector3(0.0, 0.0, 11.0))
	_add_box(torso_root, Vector3(0.18, 0.17, 0.20), Vector3(0.23, 0.80, 0.02), armor_olive_dark, Vector3(0.0, 0.0, -11.0))

	# Rear power pack / spine armor.
	_add_box(torso_root, Vector3(0.40, 0.48, 0.16), Vector3(0.0, 0.44, 0.245), armor_shadow)
	_add_box(torso_root, Vector3(0.14, 0.34, 0.10), Vector3(-0.13, 0.44, 0.34), metal_dark)
	_add_box(torso_root, Vector3(0.14, 0.34, 0.10), Vector3(0.13, 0.44, 0.34), metal_dark)

	_build_helmet()
	_build_waist()

	left_arm = _build_arm(-1.0)
	right_arm = _build_arm(1.0)
	left_leg = _build_leg(-1.0)
	right_leg = _build_leg(1.0)


func _build_helmet() -> void:
	head_root = Node3D.new()
	head_root.name = "JEFE_HELMET"
	head_root.position = Vector3(0.0, 1.03, 0.0)
	add_child(head_root)

	# Inner helmet shell.
	_add_sphere(head_root, Vector3(0.35, 0.34, 0.34), Vector3.ZERO, armor_shadow, 24, 12)

	# Crown and brow plates.
	_add_box(head_root, Vector3(0.44, 0.16, 0.31), Vector3(0.0, 0.17, 0.005), armor_olive, Vector3(-5.0, 0.0, 0.0))
	_add_box(head_root, Vector3(0.50, 0.095, 0.16), Vector3(0.0, 0.075, -0.20), armor_olive_dark, Vector3(-10.0, 0.0, 0.0))

	# Distinctive wide gold visor — original shape, classic military sci-fi language.
	_add_box(head_root, Vector3(0.43, 0.13, 0.045), Vector3(0.0, 0.02, -0.318), visor_gold, Vector3(-3.5, 0.0, 0.0))
	_add_box(head_root, Vector3(0.30, 0.055, 0.035), Vector3(0.0, -0.055, -0.327), visor_gold, Vector3(4.0, 0.0, 0.0))

	# Jaw, cheek and side armor break up the silhouette.
	_add_box(head_root, Vector3(0.30, 0.14, 0.12), Vector3(0.0, -0.19, -0.235), armor_olive_dark, Vector3(9.0, 0.0, 0.0))
	_add_box(head_root, Vector3(0.12, 0.23, 0.24), Vector3(-0.25, -0.055, -0.015), armor_olive, Vector3(0.0, 0.0, 9.0))
	_add_box(head_root, Vector3(0.12, 0.23, 0.24), Vector3(0.25, -0.055, -0.015), armor_olive, Vector3(0.0, 0.0, -9.0))
	_add_box(head_root, Vector3(0.075, 0.11, 0.09), Vector3(-0.29, 0.01, -0.205), metal_dark)
	_add_box(head_root, Vector3(0.075, 0.11, 0.09), Vector3(0.29, 0.01, -0.205), metal_dark)

	# Small amber status light, not a franchise marking.
	_add_sphere(head_root, Vector3(0.035, 0.035, 0.02), Vector3(-0.20, 0.205, -0.19), amber_light, 12, 6)


func _build_waist() -> void:
	# Armored pelvis and utility belt.
	_add_box(torso_root, Vector3(0.52, 0.17, 0.34), Vector3(0.0, -0.16, 0.02), armor_shadow, Vector3(4.0, 0.0, 0.0))
	_add_box(torso_root, Vector3(0.24, 0.16, 0.08), Vector3(0.0, -0.16, -0.185), armor_olive_dark, Vector3(3.0, 0.0, 0.0))
	for side: float in [-1.0, 1.0]:
		_add_box(torso_root, Vector3(0.16, 0.18, 0.18), Vector3(0.31 * side, -0.14, 0.05), armor_olive_dark, Vector3(0.0, 0.0, 5.0 * side))
		_add_box(torso_root, Vector3(0.10, 0.14, 0.13), Vector3(0.38 * side, -0.11, 0.05), metal_dark)


func _build_arm(side: float) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "JEFE_LEFT_ARM" if side < 0.0 else "JEFE_RIGHT_ARM"
	root.position = Vector3(0.46 * side, 0.56, 0.0)
	add_child(root)

	# Shoulder joint + broad pauldron.
	_add_sphere(root, Vector3(0.24, 0.24, 0.25), Vector3(0.06 * side, -0.02, 0.0), undersuit, 18, 8)
	_add_sphere(root, Vector3(0.34, 0.24, 0.34), Vector3(0.10 * side, 0.01, 0.0), armor_olive, 20, 9)
	_add_box(root, Vector3(0.23, 0.12, 0.28), Vector3(0.19 * side, 0.12, 0.0), armor_edge, Vector3(0.0, 0.0, -9.0 * side))

	# Upper arm and bicep plates.
	_add_capsule(root, 0.11, 0.43, Vector3(0.08 * side, -0.27, 0.01), undersuit, Vector3(0.0, 0.0, 4.0 * side))
	_add_box(root, Vector3(0.22, 0.28, 0.24), Vector3(0.09 * side, -0.26, -0.025), armor_olive_dark, Vector3(0.0, 0.0, 5.0 * side))
	_add_box(root, Vector3(0.075, 0.22, 0.06), Vector3(0.19 * side, -0.25, -0.14), armor_edge)

	# Elbow and armored forearm.
	_add_sphere(root, Vector3(0.17, 0.14, 0.18), Vector3(0.07 * side, -0.49, -0.03), armor_shadow, 16, 7)
	_add_capsule(root, 0.10, 0.41, Vector3(0.06 * side, -0.66, 0.01), undersuit, Vector3(0.0, 0.0, 3.0 * side))
	_add_box(root, Vector3(0.23, 0.31, 0.25), Vector3(0.06 * side, -0.66, -0.02), armor_olive, Vector3(0.0, 0.0, 3.0 * side))
	_add_box(root, Vector3(0.14, 0.20, 0.055), Vector3(0.06 * side, -0.65, -0.16), armor_edge)

	# Glove / knuckle guard.
	_add_box(root, Vector3(0.18, 0.15, 0.23), Vector3(0.05 * side, -0.88, -0.02), rubber)
	_add_box(root, Vector3(0.18, 0.07, 0.15), Vector3(0.05 * side, -0.92, -0.10), armor_shadow)
	for knuckle: int in range(3):
		var kx: float = (-0.045 + float(knuckle) * 0.045) * side
		_add_box(root, Vector3(0.032, 0.035, 0.045), Vector3(0.05 * side + kx, -0.965, -0.17), metal_dark)
	return root


func _build_leg(side: float) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "JEFE_LEFT_LEG" if side < 0.0 else "JEFE_RIGHT_LEG"
	root.position = Vector3(0.20 * side, -0.18, 0.01)
	add_child(root)

	# Hip joint and thigh mass.
	_add_sphere(root, Vector3(0.19, 0.18, 0.20), Vector3(0.0, -0.02, 0.0), undersuit, 16, 8)
	_add_capsule(root, 0.145, 0.58, Vector3(0.0, -0.28, 0.02), undersuit)
	_add_box(root, Vector3(0.31, 0.39, 0.32), Vector3(0.0, -0.29, -0.005), armor_olive)
	_add_box(root, Vector3(0.17, 0.30, 0.055), Vector3(0.0, -0.28, -0.185), armor_olive_dark, Vector3(2.0, 0.0, 0.0))
	_add_box(root, Vector3(0.08, 0.28, 0.22), Vector3(0.17 * side, -0.29, 0.015), armor_edge)

	# Knee joint + pronounced knee guard.
	_add_sphere(root, Vector3(0.20, 0.17, 0.21), Vector3(0.0, -0.55, -0.06), armor_shadow, 18, 8)
	_add_box(root, Vector3(0.22, 0.17, 0.11), Vector3(0.0, -0.56, -0.20), armor_olive_dark, Vector3(-8.0, 0.0, 0.0))

	# Shin armor and calf rails.
	_add_capsule(root, 0.12, 0.52, Vector3(0.0, -0.78, 0.02), undersuit)
	_add_box(root, Vector3(0.29, 0.39, 0.28), Vector3(0.0, -0.79, 0.0), armor_olive_dark)
	_add_box(root, Vector3(0.16, 0.31, 0.07), Vector3(0.0, -0.79, -0.17), armor_olive)
	_add_box(root, Vector3(0.055, 0.30, 0.18), Vector3(0.15 * side, -0.79, 0.0), armor_edge)

	# Heavy boot with heel and toe cap.
	_add_box(root, Vector3(0.31, 0.16, 0.43), Vector3(0.0, -1.05, -0.08), rubber, Vector3(-3.0, 0.0, 0.0))
	_add_box(root, Vector3(0.30, 0.11, 0.22), Vector3(0.0, -1.08, -0.26), armor_olive_dark, Vector3(-5.0, 0.0, 0.0))
	_add_box(root, Vector3(0.28, 0.10, 0.12), Vector3(0.0, -1.03, 0.17), metal_dark)
	return root


func _add_box(parent_node: Node3D, size_value: Vector3, pos: Vector3, mat: Material, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var node: MeshInstance3D = MeshInstance3D.new()
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = size_value
	node.mesh = mesh
	node.position = pos
	node.rotation_degrees = rot
	node.material_override = mat
	parent_node.add_child(node)
	return node


func _add_sphere(parent_node: Node3D, scale_value: Vector3, pos: Vector3, mat: Material, segments: int = 20, rings: int = 10) -> MeshInstance3D:
	var node: MeshInstance3D = MeshInstance3D.new()
	var mesh: SphereMesh = SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	mesh.radial_segments = segments
	mesh.rings = rings
	node.mesh = mesh
	node.scale = scale_value
	node.position = pos
	node.material_override = mat
	parent_node.add_child(node)
	return node


func _add_capsule(parent_node: Node3D, radius: float, height: float, pos: Vector3, mat: Material, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var node: MeshInstance3D = MeshInstance3D.new()
	var mesh: CapsuleMesh = CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = maxf(height, radius * 2.05)
	mesh.radial_segments = 18
	mesh.rings = 7
	node.mesh = mesh
	node.position = pos
	node.rotation_degrees = rot
	node.material_override = mat
	parent_node.add_child(node)
	return node


func _add_cylinder(parent_node: Node3D, radius: float, height: float, pos: Vector3, mat: Material, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var node: MeshInstance3D = MeshInstance3D.new()
	var mesh: CylinderMesh = CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 18
	node.mesh = mesh
	node.position = pos
	node.rotation_degrees = rot
	node.material_override = mat
	parent_node.add_child(node)
	return node


func _mat(color: Color, metallic_value: float, roughness_value: float) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metallic_value
	material.roughness = roughness_value
	return material


func _emissive(color: Color, power: float, metallic_value: float, roughness_value: float) -> StandardMaterial3D:
	var material: StandardMaterial3D = _mat(color, metallic_value, roughness_value)
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = power
	return material
