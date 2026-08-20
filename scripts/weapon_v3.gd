extends "res://scripts/weapon_v2.gd"


func _ready() -> void:
	base_position = Vector3(0.38, -0.31, -0.66)
	ads_position = Vector3(0.018, -0.19, -0.48)
	super._ready()
	scale = Vector3(0.78, 0.78, 0.78)
	position = base_position


func _build_visuals() -> void:
	var graphite: StandardMaterial3D = _make_material(Color(0.075, 0.085, 0.092), 0.82, 0.24)
	var tungsten: StandardMaterial3D = _make_material(Color(0.18, 0.20, 0.205), 0.70, 0.28)
	var armor: StandardMaterial3D = _make_material(Color(0.235, 0.25, 0.245), 0.56, 0.33)
	var dark: StandardMaterial3D = _make_material(Color(0.025, 0.030, 0.034), 0.44, 0.48)
	var grip: StandardMaterial3D = _make_material(Color(0.045, 0.050, 0.052), 0.12, 0.84)
	var cyan_mat: StandardMaterial3D = _make_emissive_material(Color(0.025, 0.46, 0.72), 2.7)
	var suit: StandardMaterial3D = _make_material(Color(0.105, 0.125, 0.12), 0.38, 0.48)

	# Leaner VX-7 receiver. The silhouette now reads as a rifle instead of a block.
	_add_box(Vector3(0.19, 0.16, 0.58), Vector3(0.0, 0.00, -0.19), graphite)
	_add_box(Vector3(0.205, 0.075, 0.40), Vector3(0.0, 0.115, -0.25), tungsten, Vector3(-2.0, 0.0, 0.0))
	_add_box(Vector3(0.17, 0.09, 0.30), Vector3(0.0, -0.105, -0.12), dark, Vector3(3.0, 0.0, 0.0))

	# Rear stock / cheek line.
	_add_box(Vector3(0.18, 0.12, 0.30), Vector3(0.0, 0.015, 0.23), armor, Vector3(0.0, 0.0, 0.0))
	_add_box(Vector3(0.13, 0.08, 0.22), Vector3(0.0, 0.08, 0.34), graphite, Vector3(-6.0, 0.0, 0.0))

	# Magazine and pistol grip.
	_add_box(Vector3(0.115, 0.27, 0.17), Vector3(0.0, -0.225, -0.13), dark, Vector3(-8.0, 0.0, 0.0))
	_add_box(Vector3(0.095, 0.23, 0.145), Vector3(0.0, -0.205, 0.12), grip, Vector3(13.0, 0.0, 0.0))

	# Handguard and barrel are narrower and longer for a believable firearm profile.
	_add_box(Vector3(0.165, 0.125, 0.42), Vector3(0.0, -0.005, -0.63), tungsten)
	_add_box(Vector3(0.14, 0.095, 0.25), Vector3(0.0, 0.055, -0.80), graphite, Vector3(-2.0, 0.0, 0.0))
	_add_cylinder(0.026, 0.48, Vector3(0.0, -0.003, -1.02), graphite, Vector3(90.0, 0.0, 0.0))
	_add_cylinder(0.043, 0.12, Vector3(0.0, -0.003, -1.31), dark, Vector3(90.0, 0.0, 0.0))

	# Low-profile optic and compact energy/status accents.
	_add_box(Vector3(0.105, 0.035, 0.31), Vector3(0.0, 0.165, -0.31), dark)
	_add_box(Vector3(0.115, 0.095, 0.16), Vector3(0.0, 0.215, -0.30), graphite)
	_add_box(Vector3(0.070, 0.040, 0.018), Vector3(0.0, 0.218, -0.395), cyan_mat)
	_add_box(Vector3(0.018, 0.045, 0.22), Vector3(-0.102, 0.025, -0.31), cyan_mat)
	_add_box(Vector3(0.018, 0.045, 0.15), Vector3(0.102, 0.025, -0.52), cyan_mat)

	# Hands/forearms sit lower and no longer cover half the screen.
	_add_capsule(0.085, 0.42, Vector3(-0.18, -0.245, -0.08), grip, Vector3(76.0, -12.0, -19.0))
	_add_capsule(0.085, 0.42, Vector3(0.20, -0.22, -0.29), grip, Vector3(76.0, 14.0, 17.0))
	_add_box(Vector3(0.19, 0.085, 0.25), Vector3(-0.18, -0.15, -0.18), suit, Vector3(8.0, -12.0, -18.0))
	_add_box(Vector3(0.19, 0.085, 0.25), Vector3(0.20, -0.13, -0.37), suit, Vector3(-6.0, 14.0, 16.0))

	muzzle_light = OmniLight3D.new()
	muzzle_light.position = Vector3(0.0, -0.003, -1.38)
	muzzle_light.light_color = Color(1.0, 0.40, 0.08)
	muzzle_light.light_energy = 7.0
	muzzle_light.omni_range = 2.6
	muzzle_light.shadow_enabled = false
	muzzle_light.visible = false
	add_child(muzzle_light)

	muzzle_mesh = MeshInstance3D.new()
	var flash_mesh: SphereMesh = SphereMesh.new()
	flash_mesh.radius = 0.052
	flash_mesh.height = 0.15
	muzzle_mesh.mesh = flash_mesh
	muzzle_mesh.position = Vector3(0.0, -0.003, -1.38)
	muzzle_mesh.scale = Vector3(1.0, 1.0, 2.2)
	muzzle_mesh.material_override = _make_emissive_material(Color(1.0, 0.28, 0.035), 7.0)
	muzzle_mesh.visible = false
	add_child(muzzle_mesh)
