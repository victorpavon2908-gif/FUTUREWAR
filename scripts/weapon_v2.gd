extends Node3D

signal ammo_changed(current_mag: int, reserve_ammo: int)
signal hit_confirmed

@export var damage: int = 34
@export var magazine_size: int = 30
@export var starting_reserve: int = 150
@export var fire_interval: float = 0.095
@export var reload_time: float = 1.30
@export var weapon_range: float = 170.0

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
var base_position := Vector3(0.29, -0.25, -0.50)
var ads_position := Vector3(0.03, -0.18, -0.43)


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
		var target_fov := 64.0 if aiming else 76.0
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
	tween.tween_property(self, "rotation_degrees:x", 14.0, 0.18)
	tween.tween_property(self, "rotation_degrees:x", -6.0, 0.42)
	tween.tween_property(self, "rotation_degrees:x", 0.0, 0.32)


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
	sphere.radius = 0.055
	sphere.height = 0.11
	spark.mesh = sphere
	spark.material_override = _make_emissive_material(Color(1.0, 0.34, 0.08), 5.0)
	get_tree().current_scene.add_child(spark)
	spark.global_position = world_position
	var tween := spark.create_tween()
	tween.tween_property(spark, "scale", Vector3(2.4, 2.4, 2.4), 0.08)
	tween.tween_property(spark, "scale", Vector3.ZERO, 0.10)
	tween.tween_callback(spark.queue_free)


func _build_visuals() -> void:
	var graphite := _make_material(Color(0.035, 0.045, 0.055), 0.78, 0.28)
	var armor := _make_material(Color(0.10, 0.13, 0.15), 0.55, 0.34)
	var cyan_mat := _make_emissive_material(Color(0.02, 0.48, 0.78), 3.7)
	var glove := _make_material(Color(0.045, 0.055, 0.060), 0.18, 0.70)

	_add_box(Vector3(0.19, 0.17, 0.62), Vector3(0.0, 0.0, -0.12), graphite)
	_add_box(Vector3(0.23, 0.13, 0.34), Vector3(0.0, 0.02, -0.49), armor)
	_add_box(Vector3(0.17, 0.22, 0.18), Vector3(0.0, -0.06, 0.18), armor)
	_add_box(Vector3(0.13, 0.08, 0.33), Vector3(0.0, 0.13, -0.21), graphite)
	_add_box(Vector3(0.08, 0.035, 0.19), Vector3(0.0, 0.185, -0.23), cyan_mat)

	var barrel := MeshInstance3D.new()
	var barrel_mesh := CylinderMesh.new()
	barrel_mesh.top_radius = 0.027
	barrel_mesh.bottom_radius = 0.033
	barrel_mesh.height = 0.48
	barrel.mesh = barrel_mesh
	barrel.rotation_degrees.x = 90.0
	barrel.position = Vector3(0.0, 0.01, -0.76)
	barrel.material_override = graphite
	add_child(barrel)

	var optic := MeshInstance3D.new()
	var optic_mesh := BoxMesh.new()
	optic_mesh.size = Vector3(0.12, 0.10, 0.17)
	optic.mesh = optic_mesh
	optic.position = Vector3(0.0, 0.18, -0.18)
	optic.material_override = armor
	add_child(optic)

	var lens := MeshInstance3D.new()
	var lens_mesh := BoxMesh.new()
	lens_mesh.size = Vector3(0.072, 0.047, 0.012)
	lens.mesh = lens_mesh
	lens.position = Vector3(0.0, 0.185, -0.271)
	lens.material_override = cyan_mat
	add_child(lens)

	# Low-poly armored forearms keep the first-person silhouette readable on small screens.
	_add_box(Vector3(0.20, 0.20, 0.42), Vector3(-0.18, -0.19, -0.10), glove, Vector3(8.0, -12.0, -18.0))
	_add_box(Vector3(0.20, 0.20, 0.42), Vector3(0.22, -0.16, -0.24), glove, Vector3(-6.0, 14.0, 16.0))
	_add_box(Vector3(0.23, 0.10, 0.25), Vector3(-0.18, -0.09, -0.19), armor, Vector3(8.0, -12.0, -18.0))
	_add_box(Vector3(0.23, 0.10, 0.25), Vector3(0.22, -0.06, -0.33), armor, Vector3(-6.0, 14.0, 16.0))

	muzzle_light = OmniLight3D.new()
	muzzle_light.position = Vector3(0.0, 0.01, -1.02)
	muzzle_light.light_color = Color(1.0, 0.38, 0.08)
	muzzle_light.light_energy = 6.0
	muzzle_light.omni_range = 2.1
	muzzle_light.shadow_enabled = false
	muzzle_light.visible = false
	add_child(muzzle_light)

	muzzle_mesh = MeshInstance3D.new()
	var flash_mesh := SphereMesh.new()
	flash_mesh.radius = 0.055
	flash_mesh.height = 0.16
	muzzle_mesh.mesh = flash_mesh
	muzzle_mesh.position = Vector3(0.0, 0.01, -1.02)
	muzzle_mesh.scale = Vector3(0.8, 0.8, 2.0)
	muzzle_mesh.material_override = _make_emissive_material(Color(1.0, 0.27, 0.04), 7.0)
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
	material.roughness = 0.18
	return material
