extends "res://scripts/weapon_v3.gd"


func _ready() -> void:
	base_position = Vector3(0.34, -0.34, -0.70)
	ads_position = Vector3(0.012, -0.205, -0.50)
	super._ready()
	scale = Vector3(0.72, 0.72, 0.72)
	position = base_position


func _build_visuals() -> void:
	var gunmetal: StandardMaterial3D = _make_material(Color(0.055, 0.065, 0.072), 0.86, 0.22)
	var titanium: StandardMaterial3D = _make_material(Color(0.19, 0.205, 0.21), 0.72, 0.26)
	var armor: StandardMaterial3D = _make_material(Color(0.26, 0.285, 0.29), 0.52, 0.34)
	var polymer: StandardMaterial3D = _make_material(Color(0.027, 0.032, 0.035), 0.12, 0.82)
	var rubber: StandardMaterial3D = _make_material(Color(0.018, 0.022, 0.024), 0.02, 0.94)
	var cyan_mat: StandardMaterial3D = _make_emissive_material(Color(0.015, 0.48, 0.78), 2.25)
	var visor_mat: StandardMaterial3D = _make_emissive_material(Color(0.05, 0.72, 1.0), 3.0)
	var glove: StandardMaterial3D = _make_material(Color(0.04, 0.048, 0.045), 0.08, 0.88)
	var forearm: StandardMaterial3D = _make_material(Color(0.15, 0.175, 0.17), 0.48, 0.43)
	var forearm_plate: StandardMaterial3D = _make_material(Color(0.23, 0.255, 0.25), 0.58, 0.34)

	# VX-7 receiver: layered, tapered military silhouette.
	_add_box(Vector3(0.18, 0.145, 0.58), Vector3(0.0, -0.005, -0.20), gunmetal)
	_add_box(Vector3(0.205, 0.060, 0.46), Vector3(0.0, 0.105, -0.25), titanium, Vector3(-2.0, 0.0, 0.0))
	_add_box(Vector3(0.155, 0.075, 0.37), Vector3(0.0, -0.095, -0.22), polymer, Vector3(2.0, 0.0, 0.0))
	_add_box(Vector3(0.145, 0.035, 0.44), Vector3(0.0, 0.155, -0.26), gunmetal)

	# Rear assembly and cheek support.
	_add_box(Vector3(0.17, 0.105, 0.31), Vector3(0.0, 0.01, 0.23), armor)
	_add_box(Vector3(0.125, 0.07, 0.23), Vector3(0.0, 0.07, 0.37), gunmetal, Vector3(-5.0, 0.0, 0.0))
	_add_box(Vector3(0.15, 0.045, 0.075), Vector3(0.0, -0.055, 0.40), rubber)

	# Pistol grip and curved-looking magazine cluster.
	_add_box(Vector3(0.09, 0.225, 0.14), Vector3(0.0, -0.195, 0.11), rubber, Vector3(14.0, 0.0, 0.0))
	_add_box(Vector3(0.11, 0.255, 0.15), Vector3(0.0, -0.215, -0.14), polymer, Vector3(-10.0, 0.0, 0.0))
	_add_box(Vector3(0.10, 0.08, 0.16), Vector3(0.0, -0.355, -0.10), gunmetal, Vector3(-13.0, 0.0, 0.0))

	# Long slim handguard and barrel.
	_add_box(Vector3(0.155, 0.115, 0.44), Vector3(0.0, -0.005, -0.67), titanium)
	_add_box(Vector3(0.13, 0.050, 0.40), Vector3(0.0, 0.085, -0.69), gunmetal)
	_add_box(Vector3(0.12, 0.035, 0.36), Vector3(0.0, -0.085, -0.67), polymer)
	_add_cylinder(0.024, 0.50, Vector3(0.0, -0.005, -1.06), gunmetal, Vector3(90.0, 0.0, 0.0))
	_add_cylinder(0.039, 0.15, Vector3(0.0, -0.005, -1.385), polymer, Vector3(90.0, 0.0, 0.0))

	# Holographic optic with guarded window.
	_add_box(Vector3(0.095, 0.030, 0.27), Vector3(0.0, 0.165, -0.32), polymer)
	_add_box(Vector3(0.12, 0.09, 0.14), Vector3(0.0, 0.215, -0.31), gunmetal)
	_add_box(Vector3(0.072, 0.047, 0.015), Vector3(0.0, 0.221, -0.392), visor_mat)
	_add_box(Vector3(0.010, 0.038, 0.18), Vector3(-0.092, 0.02, -0.34), cyan_mat)
	_add_box(Vector3(0.010, 0.038, 0.13), Vector3(0.092, 0.02, -0.53), cyan_mat)

	# Left support hand: palm, thumb and fingers wrapped around the handguard.
	_add_capsule(0.078, 0.34, Vector3(-0.145, -0.205, -0.50), glove, Vector3(78.0, -8.0, -18.0))
	_add_box(Vector3(0.13, 0.065, 0.16), Vector3(-0.105, -0.145, -0.57), glove, Vector3(8.0, -10.0, -18.0))
	for i: int in range(4):
		_add_capsule(0.018, 0.11, Vector3(-0.098 + float(i) * 0.032, -0.112, -0.64), glove, Vector3(82.0, 0.0, 0.0))
	_add_capsule(0.022, 0.13, Vector3(-0.165, -0.13, -0.58), glove, Vector3(58.0, -20.0, 35.0))

	# Right firing hand around pistol grip.
	_add_capsule(0.080, 0.34, Vector3(0.16, -0.225, -0.08), glove, Vector3(72.0, 14.0, 18.0))
	_add_box(Vector3(0.13, 0.07, 0.16), Vector3(0.105, -0.155, 0.015), glove, Vector3(-6.0, 13.0, 16.0))
	for i: int in range(4):
		_add_capsule(0.017, 0.105, Vector3(0.085 + float(i) * 0.031, -0.185, 0.075), glove, Vector3(76.0, 8.0, 8.0))
	_add_capsule(0.021, 0.13, Vector3(0.17, -0.13, 0.01), glove, Vector3(48.0, 14.0, -30.0))

	# Armored forearms: rounded undersuit + segmented shell plates.
	_add_capsule(0.088, 0.46, Vector3(-0.22, -0.28, -0.19), forearm, Vector3(72.0, -10.0, -17.0))
	_add_capsule(0.088, 0.46, Vector3(0.24, -0.275, -0.10), forearm, Vector3(72.0, 12.0, 16.0))
	_add_box(Vector3(0.17, 0.075, 0.23), Vector3(-0.23, -0.19, -0.25), forearm_plate, Vector3(8.0, -12.0, -17.0))
	_add_box(Vector3(0.17, 0.075, 0.23), Vector3(0.245, -0.19, -0.17), forearm_plate, Vector3(-5.0, 12.0, 15.0))
	_add_box(Vector3(0.115, 0.025, 0.16), Vector3(-0.225, -0.145, -0.27), cyan_mat, Vector3(8.0, -12.0, -17.0))

	muzzle_light = OmniLight3D.new()
	muzzle_light.position = Vector3(0.0, -0.005, -1.46)
	muzzle_light.light_color = Color(1.0, 0.42, 0.08)
	muzzle_light.light_energy = 7.0
	muzzle_light.omni_range = 2.7
	muzzle_light.shadow_enabled = false
	muzzle_light.visible = false
	add_child(muzzle_light)

	muzzle_mesh = MeshInstance3D.new()
	var flash_mesh: SphereMesh = SphereMesh.new()
	flash_mesh.radius = 0.048
	flash_mesh.height = 0.16
	muzzle_mesh.mesh = flash_mesh
	muzzle_mesh.position = Vector3(0.0, -0.005, -1.46)
	muzzle_mesh.scale = Vector3(1.0, 1.0, 2.4)
	muzzle_mesh.material_override = _make_emissive_material(Color(1.0, 0.28, 0.03), 7.2)
	muzzle_mesh.visible = false
	add_child(muzzle_mesh)
