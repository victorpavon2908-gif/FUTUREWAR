extends "res://scripts/weapon_v2.gd"

# FUTUREWAR VA-9 ARC RIFLE
# Original first-person viewmodel inspired by classic military sci-fi proportions:
# olive armor panels, a visible blue energy chamber, armored gauntlets and black gloves.

var plasma_core: MeshInstance3D
var core_ring_front: MeshInstance3D
var core_ring_back: MeshInstance3D
var visual_time: float = 0.0


func _ready() -> void:
	base_position = Vector3(0.345, -0.305, -0.705)
	ads_position = Vector3(0.010, -0.185, -0.515)
	damage = 37
	fire_interval = 0.105
	reload_time = 1.38
	super._ready()
	scale = Vector3(0.84, 0.84, 0.84)
	position = base_position


func _process(delta: float) -> void:
	super._process(delta)
	visual_time += delta
	var pulse: float = 1.0 + sin(visual_time * 5.5) * 0.045
	if plasma_core != null:
		plasma_core.scale = Vector3(pulse, 1.0, pulse)
	if core_ring_front != null:
		core_ring_front.rotation.z += delta * 0.55
	if core_ring_back != null:
		core_ring_back.rotation.z -= delta * 0.42


func _build_visuals() -> void:
	var olive_dark: StandardMaterial3D = _make_material(Color(0.185, 0.205, 0.155), 0.46, 0.42)
	var olive: StandardMaterial3D = _make_material(Color(0.285, 0.315, 0.235), 0.54, 0.35)
	var olive_light: StandardMaterial3D = _make_material(Color(0.39, 0.415, 0.315), 0.48, 0.34)
	var gunmetal: StandardMaterial3D = _make_material(Color(0.075, 0.085, 0.092), 0.82, 0.24)
	var steel: StandardMaterial3D = _make_material(Color(0.20, 0.22, 0.225), 0.76, 0.28)
	var polymer: StandardMaterial3D = _make_material(Color(0.025, 0.030, 0.032), 0.10, 0.86)
	var glove: StandardMaterial3D = _make_material(Color(0.025, 0.030, 0.028), 0.04, 0.92)
	var undersuit: StandardMaterial3D = _make_material(Color(0.055, 0.065, 0.060), 0.10, 0.80)
	var plasma: StandardMaterial3D = _make_emissive_material(Color(0.025, 0.48, 1.0), 5.8)
	var plasma_hot: StandardMaterial3D = _make_emissive_material(Color(0.20, 0.78, 1.0), 7.2)

	# --- REAR / STOCK -------------------------------------------------------
	_add_box(Vector3(0.21, 0.145, 0.34), Vector3(0.0, 0.005, 0.275), olive_dark, Vector3(-3.0, 0.0, 0.0))
	_add_box(Vector3(0.165, 0.085, 0.27), Vector3(0.0, 0.085, 0.375), olive, Vector3(-7.0, 0.0, 0.0))
	_add_box(Vector3(0.18, 0.050, 0.115), Vector3(0.0, -0.075, 0.425), polymer)
	_add_box(Vector3(0.135, 0.075, 0.12), Vector3(0.0, 0.015, 0.505), gunmetal)

	# --- MAIN RECEIVER ------------------------------------------------------
	_add_box(Vector3(0.255, 0.205, 0.67), Vector3(0.0, 0.0, -0.12), gunmetal)
	_add_box(Vector3(0.275, 0.095, 0.53), Vector3(0.0, 0.125, -0.17), olive, Vector3(-2.0, 0.0, 0.0))
	_add_box(Vector3(0.235, 0.075, 0.47), Vector3(0.0, -0.125, -0.12), polymer, Vector3(2.0, 0.0, 0.0))
	_add_box(Vector3(0.035, 0.115, 0.48), Vector3(-0.145, 0.035, -0.15), olive_light)
	_add_box(Vector3(0.035, 0.115, 0.48), Vector3(0.145, 0.035, -0.15), olive_dark)

	# Layered receiver armor gives the gun a manufactured, high-end military shape.
	_add_box(Vector3(0.295, 0.045, 0.30), Vector3(0.0, 0.205, -0.08), steel)
	_add_box(Vector3(0.20, 0.038, 0.25), Vector3(0.0, 0.235, -0.28), gunmetal)
	_add_box(Vector3(0.09, 0.05, 0.20), Vector3(-0.105, 0.17, -0.25), olive_light, Vector3(0.0, 0.0, -8.0))

	# --- GRIP / MAGAZINE ---------------------------------------------------
	_add_box(Vector3(0.105, 0.26, 0.15), Vector3(0.0, -0.235, 0.12), polymer, Vector3(14.0, 0.0, 0.0))
	_add_box(Vector3(0.13, 0.29, 0.18), Vector3(0.0, -0.26, -0.17), gunmetal, Vector3(-9.0, 0.0, 0.0))
	_add_box(Vector3(0.115, 0.085, 0.18), Vector3(0.0, -0.405, -0.12), olive_dark, Vector3(-12.0, 0.0, 0.0))

	# --- PLASMA CHAMBER ----------------------------------------------------
	# The chamber is the visual signature: a protected blue energy cylinder in the front half.
	_add_box(Vector3(0.24, 0.185, 0.44), Vector3(0.0, -0.005, -0.63), olive_dark)
	_add_box(Vector3(0.275, 0.055, 0.47), Vector3(0.0, 0.13, -0.63), olive_light)
	_add_box(Vector3(0.275, 0.050, 0.47), Vector3(0.0, -0.13, -0.63), gunmetal)
	for side: float in [-1.0, 1.0]:
		_add_box(Vector3(0.045, 0.20, 0.44), Vector3(0.145 * side, 0.0, -0.63), steel)
		_add_box(Vector3(0.026, 0.115, 0.30), Vector3(0.169 * side, 0.0, -0.63), plasma)

	plasma_core = _add_cylinder_node(0.072, 0.39, Vector3(0.0, 0.0, -0.63), plasma_hot, Vector3(90.0, 0.0, 0.0))
	_add_cylinder(0.098, 0.055, Vector3(0.0, 0.0, -0.855), gunmetal, Vector3(90.0, 0.0, 0.0))
	_add_cylinder(0.098, 0.055, Vector3(0.0, 0.0, -0.405), gunmetal, Vector3(90.0, 0.0, 0.0))
	core_ring_front = _add_torus_node(Vector3(0.0, 0.0, -0.84), 0.084, 0.108, steel)
	core_ring_back = _add_torus_node(Vector3(0.0, 0.0, -0.42), 0.084, 0.108, steel)

	# --- FRONT FRAME / MULTI-BARREL MUZZLE --------------------------------
	_add_box(Vector3(0.20, 0.15, 0.28), Vector3(0.0, 0.0, -0.99), gunmetal)
	_add_box(Vector3(0.225, 0.055, 0.30), Vector3(0.0, 0.11, -0.99), olive)
	_add_cylinder(0.032, 0.48, Vector3(0.0, 0.005, -1.31), steel, Vector3(90.0, 0.0, 0.0))
	_add_cylinder(0.022, 0.34, Vector3(-0.070, -0.035, -1.28), gunmetal, Vector3(90.0, 0.0, 0.0))
	_add_cylinder(0.022, 0.34, Vector3(0.070, -0.035, -1.28), gunmetal, Vector3(90.0, 0.0, 0.0))
	_add_cylinder(0.045, 0.10, Vector3(0.0, 0.005, -1.58), polymer, Vector3(90.0, 0.0, 0.0))

	# --- RAIL / OPTIC ------------------------------------------------------
	_add_box(Vector3(0.15, 0.035, 0.60), Vector3(0.0, 0.245, -0.27), polymer)
	_add_box(Vector3(0.125, 0.105, 0.19), Vector3(0.0, 0.305, -0.22), gunmetal)
	_add_box(Vector3(0.085, 0.048, 0.018), Vector3(0.0, 0.307, -0.325), plasma)
	_add_box(Vector3(0.065, 0.045, 0.14), Vector3(0.0, 0.285, -0.48), olive_dark)

	# --- LEFT SUPPORT HAND -------------------------------------------------
	_add_box(Vector3(0.145, 0.075, 0.17), Vector3(-0.115, -0.16, -0.68), glove, Vector3(7.0, -8.0, -15.0))
	_add_capsule(0.078, 0.36, Vector3(-0.19, -0.235, -0.56), undersuit, Vector3(77.0, -9.0, -18.0))
	for i: int in range(4):
		_add_capsule(0.019, 0.12, Vector3(-0.103 + float(i) * 0.033, -0.115, -0.715), glove, Vector3(83.0, 0.0, 1.5 * float(i)))
	_add_capsule(0.024, 0.14, Vector3(-0.175, -0.125, -0.64), glove, Vector3(58.0, -22.0, 34.0))
	for i: int in range(3):
		_add_box(Vector3(0.032, 0.020, 0.050), Vector3(-0.105 + float(i) * 0.038, -0.083, -0.718), olive_dark)

	# --- RIGHT FIRING HAND -------------------------------------------------
	_add_box(Vector3(0.145, 0.075, 0.17), Vector3(0.115, -0.17, 0.04), glove, Vector3(-5.0, 12.0, 14.0))
	_add_capsule(0.080, 0.36, Vector3(0.19, -0.245, -0.05), undersuit, Vector3(72.0, 14.0, 18.0))
	for i: int in range(4):
		_add_capsule(0.018, 0.112, Vector3(0.083 + float(i) * 0.033, -0.20, 0.10), glove, Vector3(76.0, 8.0, 8.0))
	_add_capsule(0.023, 0.14, Vector3(0.18, -0.135, 0.035), glove, Vector3(50.0, 14.0, -30.0))
	for i: int in range(3):
		_add_box(Vector3(0.032, 0.020, 0.050), Vector3(0.085 + float(i) * 0.038, -0.158, 0.10), olive_dark)

	# --- ARMORED FOREARMS --------------------------------------------------
	# Thick articulated gauntlets follow the supplied visual direction while remaining original.
	_add_capsule(0.10, 0.52, Vector3(-0.275, -0.305, -0.25), undersuit, Vector3(70.0, -12.0, -18.0))
	_add_capsule(0.10, 0.52, Vector3(0.285, -0.305, -0.16), undersuit, Vector3(70.0, 12.0, 16.0))

	_add_box(Vector3(0.205, 0.095, 0.285), Vector3(-0.285, -0.205, -0.31), olive, Vector3(7.0, -13.0, -17.0))
	_add_box(Vector3(0.205, 0.095, 0.285), Vector3(0.295, -0.205, -0.22), olive, Vector3(-5.0, 13.0, 15.0))
	_add_box(Vector3(0.165, 0.060, 0.20), Vector3(-0.285, -0.145, -0.34), olive_light, Vector3(7.0, -13.0, -17.0))
	_add_box(Vector3(0.165, 0.060, 0.20), Vector3(0.295, -0.145, -0.25), olive_light, Vector3(-5.0, 13.0, 15.0))
	_add_box(Vector3(0.17, 0.055, 0.12), Vector3(-0.285, -0.29, -0.18), gunmetal, Vector3(7.0, -13.0, -17.0))
	_add_box(Vector3(0.17, 0.055, 0.12), Vector3(0.295, -0.29, -0.09), gunmetal, Vector3(-5.0, 13.0, 15.0))

	# Elbow/joint housings sell the supersoldier armor construction.
	_add_sphere(Vector3(0.13, 0.13, 0.13), Vector3(-0.32, -0.34, -0.05), gunmetal)
	_add_sphere(Vector3(0.13, 0.13, 0.13), Vector3(0.33, -0.34, 0.02), gunmetal)
	_add_cylinder(0.080, 0.045, Vector3(-0.325, -0.34, -0.05), steel, Vector3(0.0, 0.0, 90.0))
	_add_cylinder(0.080, 0.045, Vector3(0.335, -0.34, 0.02), steel, Vector3(0.0, 0.0, 90.0))

	# Muzzle feedback.
	muzzle_light = OmniLight3D.new()
	muzzle_light.position = Vector3(0.0, 0.005, -1.66)
	muzzle_light.light_color = Color(0.08, 0.58, 1.0)
	muzzle_light.light_energy = 8.0
	muzzle_light.omni_range = 3.0
	muzzle_light.shadow_enabled = false
	muzzle_light.visible = false
	add_child(muzzle_light)

	muzzle_mesh = MeshInstance3D.new()
	var flash_mesh: SphereMesh = SphereMesh.new()
	flash_mesh.radius = 0.052
	flash_mesh.height = 0.19
	muzzle_mesh.mesh = flash_mesh
	muzzle_mesh.position = Vector3(0.0, 0.005, -1.66)
	muzzle_mesh.scale = Vector3(0.8, 0.8, 2.8)
	muzzle_mesh.material_override = plasma_hot
	muzzle_mesh.visible = false
	add_child(muzzle_mesh)


func _add_cylinder_node(radius: float, height: float, local_position: Vector3, material: Material, rotation_value: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var node: MeshInstance3D = MeshInstance3D.new()
	var mesh: CylinderMesh = CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 16
	node.mesh = mesh
	node.position = local_position
	node.rotation_degrees = rotation_value
	node.material_override = material
	add_child(node)
	return node


func _add_sphere(size_value: Vector3, local_position: Vector3, material: Material) -> void:
	var node: MeshInstance3D = MeshInstance3D.new()
	var mesh: SphereMesh = SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	mesh.radial_segments = 12
	mesh.rings = 6
	node.mesh = mesh
	node.scale = size_value
	node.position = local_position
	node.material_override = material
	add_child(node)


func _add_torus_node(local_position: Vector3, inner_radius_value: float, outer_radius_value: float, material: Material) -> MeshInstance3D:
	var node: MeshInstance3D = MeshInstance3D.new()
	var mesh: TorusMesh = TorusMesh.new()
	mesh.inner_radius = inner_radius_value
	mesh.outer_radius = outer_radius_value
	mesh.rings = 20
	mesh.ring_segments = 8
	node.mesh = mesh
	node.position = local_position
	node.rotation_degrees.x = 90.0
	node.material_override = material
	add_child(node)
	return node
