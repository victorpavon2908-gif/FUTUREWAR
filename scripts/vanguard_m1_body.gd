extends Node3D

var armor_primary: StandardMaterial3D
var armor_secondary: StandardMaterial3D
var armor_dark: StandardMaterial3D
var undersuit: StandardMaterial3D
var visor: StandardMaterial3D
var energy: StandardMaterial3D

var left_arm: Node3D
var right_arm: Node3D
var left_leg: Node3D
var right_leg: Node3D
var elapsed: float = 0.0


func _ready() -> void:
	_build_materials()
	_build_character()


func update_pose(delta: float, speed_ratio: float, sprinting: bool) -> void:
	elapsed += delta * (7.0 + speed_ratio * 4.0)
	var amount: float = clampf(speed_ratio, 0.0, 1.0)
	var swing: float = sin(elapsed) * deg_to_rad(24.0) * amount
	if sprinting:
		swing *= 1.25
	if left_arm != null:
		left_arm.rotation.x = -swing * 0.72
	if right_arm != null:
		right_arm.rotation.x = swing * 0.72
	if left_leg != null:
		left_leg.rotation.x = swing
	if right_leg != null:
		right_leg.rotation.x = -swing
	position.y = sin(elapsed * 2.0) * 0.018 * amount


func _build_materials() -> void:
	armor_primary = _mat(Color(0.25, 0.285, 0.22), 0.62, 0.36)
	armor_secondary = _mat(Color(0.12, 0.145, 0.14), 0.72, 0.29)
	armor_dark = _mat(Color(0.035, 0.043, 0.045), 0.54, 0.48)
	undersuit = _mat(Color(0.025, 0.03, 0.032), 0.10, 0.88)
	visor = _emissive(Color(0.08, 0.72, 0.95), 4.6)
	energy = _emissive(Color(0.035, 0.45, 0.82), 3.0)


func _build_character() -> void:
	# Core armored torso.
	_add_capsule(self, 0.30, 0.92, Vector3(0.0, 0.34, 0.02), undersuit)
	_add_box(self, Vector3(0.74, 0.46, 0.36), Vector3(0.0, 0.48, -0.01), armor_primary, Vector3(-4.0, 0.0, 0.0))
	_add_box(self, Vector3(0.58, 0.18, 0.40), Vector3(0.0, 0.67, -0.02), armor_secondary)
	_add_box(self, Vector3(0.48, 0.22, 0.30), Vector3(0.0, 0.18, 0.02), armor_secondary, Vector3(5.0, 0.0, 0.0))
	_add_box(self, Vector3(0.36, 0.14, 0.22), Vector3(0.0, -0.02, 0.02), armor_dark)
	_add_box(self, Vector3(0.12, 0.30, 0.04), Vector3(0.0, 0.46, -0.205), energy)

	# Helmet with angular visor and jaw armor.
	_add_sphere(self, Vector3(0.33, 0.31, 0.32), Vector3(0.0, 1.08, 0.0), armor_secondary)
	_add_box(self, Vector3(0.44, 0.10, 0.055), Vector3(0.0, 1.11, -0.285), visor, Vector3(-4.0, 0.0, 0.0))
	_add_box(self, Vector3(0.30, 0.14, 0.12), Vector3(0.0, 0.93, -0.22), armor_dark, Vector3(8.0, 0.0, 0.0))
	_add_box(self, Vector3(0.18, 0.09, 0.25), Vector3(-0.23, 1.04, 0.02), armor_primary, Vector3(0.0, 0.0, 12.0))
	_add_box(self, Vector3(0.18, 0.09, 0.25), Vector3(0.23, 1.04, 0.02), armor_primary, Vector3(0.0, 0.0, -12.0))

	left_arm = _build_arm(-1.0)
	right_arm = _build_arm(1.0)
	left_leg = _build_leg(-1.0)
	right_leg = _build_leg(1.0)

	# Belt / utility armor.
	for x_value: float in [-0.30, -0.15, 0.15, 0.30]:
		_add_box(self, Vector3(0.12, 0.15, 0.18), Vector3(x_value, -0.08, 0.08), armor_dark)


func _build_arm(side: float) -> Node3D:
	var root: Node3D = Node3D.new()
	root.position = Vector3(0.45 * side, 0.50, 0.0)
	add_child(root)
	_add_sphere(root, Vector3(0.28, 0.22, 0.30), Vector3(0.08 * side, 0.0, 0.0), armor_primary)
	_add_box(root, Vector3(0.24, 0.34, 0.26), Vector3(0.10 * side, -0.23, 0.0), armor_secondary, Vector3(0.0, 0.0, 4.0 * side))
	_add_capsule(root, 0.105, 0.48, Vector3(0.08 * side, -0.46, 0.01), undersuit, Vector3(0.0, 0.0, 4.0 * side))
	_add_box(root, Vector3(0.22, 0.31, 0.24), Vector3(0.07 * side, -0.59, -0.01), armor_primary, Vector3(0.0, 0.0, 5.0 * side))
	_add_box(root, Vector3(0.14, 0.12, 0.20), Vector3(0.07 * side, -0.80, -0.02), armor_dark)
	return root


func _build_leg(side: float) -> Node3D:
	var root: Node3D = Node3D.new()
	root.position = Vector3(0.20 * side, -0.18, 0.0)
	add_child(root)
	_add_capsule(root, 0.145, 0.60, Vector3(0.0, -0.28, 0.02), undersuit)
	_add_box(root, Vector3(0.30, 0.40, 0.32), Vector3(0.0, -0.27, -0.01), armor_primary)
	_add_sphere(root, Vector3(0.23, 0.18, 0.22), Vector3(0.0, -0.53, -0.12), armor_secondary)
	_add_capsule(root, 0.125, 0.54, Vector3(0.0, -0.74, 0.02), undersuit)
	_add_box(root, Vector3(0.27, 0.38, 0.30), Vector3(0.0, -0.76, -0.02), armor_secondary)
	_add_box(root, Vector3(0.31, 0.16, 0.48), Vector3(0.0, -1.04, -0.10), armor_dark, Vector3(-4.0, 0.0, 0.0))
	return root


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
	mesh.radial_segments = 16
	mesh.rings = 8
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
	mesh.radial_segments = 12
	mesh.rings = 5
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
	var material: StandardMaterial3D = _mat(color, 0.25, 0.18)
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = power
	return material
