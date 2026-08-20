extends Node3D

signal ammo_changed(current_mag: int, reserve_ammo: int)
signal hit_confirmed

@export var damage: int = 34
@export var magazine_size: int = 30
@export var starting_reserve: int = 150
@export var fire_interval: float = 0.095
@export var reload_time: float = 1.30
@export var weapon_range: float = 220.0

var current_mag: int = 30
var reserve_ammo: int = 150
var cooldown: float = 0.0
var reloading: bool = false
var camera: Camera3D
var owner_body: CharacterBody3D
var muzzle_light: OmniLight3D
var muzzle_mesh: MeshInstance3D
var muzzle_timer: Timer
var reload_timer: Timer
var base_position := Vector3(0.31, -0.23, -0.54)
var ads_position := Vector3(0.025, -0.155, -0.44)


func _ready() -> void:
	camera = get_parent() as Camera3D
	owner_body = camera.get_parent() as CharacterBody3D
	current_mag = magazine_size
	reserve_ammo = starting_reserve
	position = base_position
	_build_visuals()
	_build_timers()
	ammo_changed.emit(current_mag, reserve_ammo)


func _process(delta: float) -> void:
	cooldown = maxf(0.0, cooldown - delta)
	var aiming := InputMap.has_action("aim") and Input.is_action_pressed("aim") and not reloading
	var target_pos := ads_position if aiming else base_position
	position = position.lerp(target_pos, minf(1.0, delta * 12.0))
	if camera != null:
		var target_fov := 61.0 if aiming else 76.0
		camera.fov = lerpf(camera.fov, target_fov, minf(1.0, delta * 10.0))


func try_fire() -> void:
	if reloading or cooldown > 0.0:
		return
	if current_mag <= 0:
		request_reload()
		return

	current_mag -= 1
	cooldown = fire_interval
	ammo_changed.emit(current_mag, reserve_ammo)
	_show_muzzle_flash()
	_fire_hitscan()

	if owner_body != null and owner_body.has_method("apply_recoil"):
		owner_body.call("apply_recoil", 0.0105)


func request_reload() -> void:
	if reloading:
		return
	if current_mag >= magazine_size or reserve_ammo <= 0:
		return
	reloading = true
	reload_timer.start(reload_time)
	var tween := create_tween()
	tween.tween_property(self, "rotation_degrees:x", 15.0, 0.18)
	tween.parallel().tween_property(self, "position:y", base_position.y - 0.08, 0.18)
	tween.tween_property(self, "rotation_degrees:x", -6.0, 0.38)
	tween.tween_property(self, "rotation_degrees:x", 0.0, 0.30)


func _finish_reload() -> void:
	if not reloading:
		return
	var needed := magazine_size - current_mag
	var loaded := mini(needed, reserve_ammo)
	current_mag += loaded
	reserve_ammo -= loaded
	reloading = false
	ammo_changed.emit(current_mag, reserve_ammo)


func _fire_hitscan() -> void:
	if camera == null or owner_body == null:
		return

	var ray_from := camera.global_position
	var ray_to := ray_from + (-camera.global_transform.basis.z * weapon_range)
	var query := PhysicsRayQueryParameters3D.create(ray_from, ray_to)
	query.exclude = [owner_body.get_rid()]
	query.collide_with_areas = true
	query.collide_with_bodies = true

	var result := get_world_3d().direct_space_state.intersect_ray(query)
	if result.is_empty():
		return

	var impact_position: Vector3 = result.get("position", ray_to)
	_spawn_impact(impact_position)
	var collider: Object = result.get("collider")
	if collider != null and collider.has_method("take_damage"):
		collider.call("take_damage", damage)
		hit_confirmed.emit()


func _build_timers() -> void:
	muzzle_timer = Timer.new()
	muzzle_timer.one_shot = true
	muzzle_timer.wait_time = 0.045
	muzzle_timer.timeout.connect(_hide_muzzle_flash)
	add_child(muzzle_timer)

	reload_timer = Timer.new()
	reload_timer.one_shot = true
	reload_timer.timeout.connect(_finish_reload)
	add_child(reload_timer)


func _show_muzzle_flash() -> void:
	if muzzle_light != null:
		muzzle_light.visible = true
	if muzzle_mesh != null:
		muzzle_mesh.visible = true
	muzzle_timer.start()


func _hide_muzzle_flash() -> void:
	if muzzle_light != null:
		muzzle_light.visible = false
	if muzzle_mesh != null:
		muzzle_mesh.visible = false


func _spawn_impact(world_position: Vector3) -> void:
	var spark := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.06
	sphere.height = 0.12
	spark.mesh = sphere
	spark.material_override = _make_emissive_material(Color(1.0, 0.38, 0.08), 6.0)
	get_tree().current_scene.add_child(spark)
	spark.global_position = world_position
	var tween := spark.create_tween()
	tween.tween_property(spark, "scale", Vector3(2.8, 2.8, 2.8), 0.075)
	tween.tween_property(spark, "scale", Vector3.ZERO, 0.11)
	tween.tween_callback(spark.queue_free)


func _build_visuals() -> void:
	var graphite := _make_material(Color(0.12, 0.135, 0.145), 0.80, 0.25)
	var armor := _make_material(Color(0.23, 0.26, 0.27), 0.58, 0.31)
	var dark := _make_material(Color(0.045, 0.052, 0.055), 0.46, 0.48)
	var cyan_mat := _make_emissive_material(Color(0.03, 0.58, 0.88), 4.0)
	var glove := _make_material(Color(0.07, 0.075, 0.075), 0.16, 0.76)
	var vanguard_armor := _make_material(Color(0.18, 0.21, 0.20), 0.48, 0.36)

	# Main receiver with layered plates.
	_add_box(Vector3(0.22, 0.20, 0.66), Vector3(0.0, 0.0, -0.15), graphite)
	_add_box(Vector3(0.25, 0.12, 0.42), Vector3(0.0, 0.105, -0.24), armor)
	_add_box(Vector3(0.18, 0.12, 0.30), Vector3(0.0, -0.115, -0.13), dark)
	_add_box(Vector3(0.12, 0.20, 0.22), Vector3(0.0, -0.09, 0.25), armor, Vector3(12.0, 0.0, 0.0))

	# Magazine and grip.
	_add_box(Vector3(0.13, 0.30, 0.18), Vector3(0.0, -0.24, -0.18), dark, Vector3(-8.0, 0.0, 0.0))
	_add_box(Vector3(0.11, 0.25, 0.16), Vector3(0.0, -0.23, 0.15), glove, Vector3(12.0, 0.0, 0.0))

	# Handguard and barrel assembly.
	_add_box(Vector3(0.20, 0.16, 0.36), Vector3(0.0, 0.01, -0.61), armor)
	_add_cylinder(0.035, 0.50, Vector3(0.0, 0.01, -0.96), graphite, Vector3(90.0, 0.0, 0.0))
	_add_cylinder(0.055, 0.14, Vector3(0.0, 0.01, -1.26), dark, Vector3(90.0, 0.0, 0.0))

	# Upper rail and optic.
	_add_box(Vector3(0.13, 0.06, 0.40), Vector3(0.0, 0.18, -0.25), dark)
	_add_box(Vector3(0.14, 0.12, 0.19), Vector3(0.0, 0.25, -0.23), armor)
	_add_box(Vector3(0.088, 0.058, 0.018), Vector3(0.0, 0.255, -0.335), cyan_mat)
	_add_box(Vector3(0.07, 0.028, 0.26), Vector3(0.0, 0.205, -0.52), cyan_mat)

	# Side energy status strips improve visibility in dark or bright scenes.
	_add_box(Vector3(0.022, 0.08, 0.34), Vector3(-0.118, 0.05, -0.20), cyan_mat)
	_add_box(Vector3(0.022, 0.08, 0.22), Vector3(0.118, 0.05, -0.38), cyan_mat)

	# Armored VANGUARD forearms; rounded undersuit + plates.
	_add_capsule(0.105, 0.48, Vector3(-0.19, -0.20, -0.12), glove, Vector3(74.0, -12.0, -19.0))
	_add_capsule(0.105, 0.48, Vector3(0.22, -0.17, -0.28), glove, Vector3(74.0, 14.0, 17.0))
	_add_box(Vector3(0.24, 0.12, 0.30), Vector3(-0.19, -0.10, -0.22), vanguard_armor, Vector3(8.0, -12.0, -18.0))
	_add_box(Vector3(0.24, 0.12, 0.30), Vector3(0.22, -0.07, -0.37), vanguard_armor, Vector3(-6.0, 14.0, 16.0))
	_add_box(Vector3(0.12, 0.035, 0.20), Vector3(-0.19, -0.045, -0.25), cyan_mat, Vector3(8.0, -12.0, -18.0))

	muzzle_light = OmniLight3D.new()
	muzzle_light.position = Vector3(0.0, 0.01, -1.35)
	muzzle_light.light_color = Color(1.0, 0.42, 0.09)
	muzzle_light.light_energy = 8.0
	muzzle_light.omni_range = 2.8
	muzzle_light.shadow_enabled = false
	muzzle_light.visible = false
	add_child(muzzle_light)

	muzzle_mesh = MeshInstance3D.new()
	var flash_mesh := SphereMesh.new()
	flash_mesh.radius = 0.065
	flash_mesh.height = 0.18
	muzzle_mesh.mesh = flash_mesh
	muzzle_mesh.position = Vector3(0.0, 0.01, -1.35)
	muzzle_mesh.scale = Vector3(1.0, 1.0, 2.4)
	muzzle_mesh.material_override = _make_emissive_material(Color(1.0, 0.31, 0.04), 8.0)
	muzzle_mesh.visible = false
	add_child(muzzle_mesh)


func _add_box(size: Vector3, local_position: Vector3, material: Material, rotation_value: Vector3 = Vector3.ZERO) -> void:
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.position = local_position
	mesh_instance.rotation_degrees = rotation_value
	mesh_instance.material_override = material
	add_child(mesh_instance)


func _add_cylinder(radius: float, height: float, local_position: Vector3, material: Material, rotation_value: Vector3 = Vector3.ZERO) -> void:
	var mesh_instance := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius * 1.08
	mesh.height = height
	mesh_instance.mesh = mesh
	mesh_instance.position = local_position
	mesh_instance.rotation_degrees = rotation_value
	mesh_instance.material_override = material
	add_child(mesh_instance)


func _add_capsule(radius: float, height: float, local_position: Vector3, material: Material, rotation_value: Vector3 = Vector3.ZERO) -> void:
	var mesh_instance := MeshInstance3D.new()
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = maxf(height, radius * 2.05)
	mesh_instance.mesh = mesh
	mesh_instance.position = local_position
	mesh_instance.rotation_degrees = rotation_value
	mesh_instance.material_override = material
	add_child(mesh_instance)


func _make_material(color: Color, metallic: float, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metallic
	material.roughness = roughness
	return material


func _make_emissive_material(color: Color, energy: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = energy
	material.metallic = 0.25
	material.roughness = 0.16
	return material
