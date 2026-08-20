extends Node3D

signal ammo_changed(current_mag: int, reserve_ammo: int)
signal hit_confirmed

@export var damage: int = 34
@export var magazine_size: int = 30
@export var starting_reserve: int = 120
@export var fire_interval: float = 0.095
@export var reload_time: float = 1.35
@export var weapon_range: float = 180.0

var current_mag: int = 30
var reserve_ammo: int = 120
var cooldown: float = 0.0
var reloading: bool = false

var camera: Camera3D
var owner_body: CharacterBody3D
var muzzle_flash: OmniLight3D
var muzzle_timer: Timer
var reload_timer: Timer


func _ready() -> void:
	camera = get_parent() as Camera3D
	owner_body = camera.get_parent() as CharacterBody3D
	current_mag = magazine_size
	reserve_ammo = starting_reserve
	_build_visuals()
	_build_timers()
	ammo_changed.emit(current_mag, reserve_ammo)


func _process(delta: float) -> void:
	cooldown = maxf(0.0, cooldown - delta)


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
		owner_body.apply_recoil(0.012)


func request_reload() -> void:
	if reloading:
		return
	if current_mag >= magazine_size or reserve_ammo <= 0:
		return
	reloading = true
	reload_timer.start(reload_time)


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

	var collider: Object = result.get("collider")
	if collider != null and collider.has_method("take_damage"):
		collider.take_damage(damage)
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
	if muzzle_flash == null:
		return
	muzzle_flash.visible = true
	muzzle_timer.start()


func _hide_muzzle_flash() -> void:
	if muzzle_flash != null:
		muzzle_flash.visible = false


func _build_visuals() -> void:
	position = Vector3(0.27, -0.23, -0.48)

	var body_mesh := MeshInstance3D.new()
	var body_box := BoxMesh.new()
	body_box.size = Vector3(0.18, 0.16, 0.62)
	body_mesh.mesh = body_box
	body_mesh.position = Vector3(0.0, 0.0, -0.12)
	body_mesh.material_override = _make_material(Color(0.055, 0.065, 0.075), 0.65, 0.32)
	add_child(body_mesh)

	var top_mesh := MeshInstance3D.new()
	var top_box := BoxMesh.new()
	top_box.size = Vector3(0.12, 0.07, 0.30)
	top_mesh.mesh = top_box
	top_mesh.position = Vector3(0.0, 0.105, -0.20)
	top_mesh.material_override = _make_emissive_material(Color(0.02, 0.30, 0.48))
	add_child(top_mesh)

	var barrel := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.025
	cylinder.bottom_radius = 0.025
	cylinder.height = 0.44
	barrel.mesh = cylinder
	barrel.rotation_degrees.x = 90.0
	barrel.position = Vector3(0.0, 0.0, -0.55)
	barrel.material_override = _make_material(Color(0.025, 0.03, 0.035), 0.85, 0.25)
	add_child(barrel)

	muzzle_flash = OmniLight3D.new()
	muzzle_flash.position = Vector3(0.0, 0.0, -0.80)
	muzzle_flash.light_color = Color(1.0, 0.34, 0.08)
	muzzle_flash.light_energy = 7.0
	muzzle_flash.omni_range = 2.4
	muzzle_flash.shadow_enabled = false
	muzzle_flash.visible = false
	add_child(muzzle_flash)


func _make_material(color: Color, metallic: float, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metallic
	material.roughness = roughness
	return material


func _make_emissive_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 3.5
	material.metallic = 0.25
	material.roughness = 0.2
	return material
