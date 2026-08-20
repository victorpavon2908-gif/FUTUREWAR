extends CharacterBody3D

signal health_changed(current_health: int, max_health: int)
signal shield_changed(current_shield: float, max_shield: float)
signal ammo_changed(current_mag: int, reserve_ammo: int)
signal damaged
signal died

const WEAPON_SCRIPT := preload("res://scripts/weapon_v2.gd")

@export var walk_speed: float = 5.5
@export var sprint_speed: float = 8.0
@export var acceleration: float = 19.0
@export var air_acceleration: float = 7.0
@export var jump_velocity: float = 5.1
@export var mouse_sensitivity: float = 0.0022
@export var touch_sensitivity: float = 0.0031
@export var max_health: int = 100
@export var max_shield: float = 100.0
@export var shield_recharge_delay: float = 3.0
@export var shield_recharge_rate: float = 24.0

var health: int = 100
var shield: float = 100.0
var dead: bool = false
var pitch: float = 0.0
var gravity: float = 9.8
var time_since_damage: float = 99.0

var camera: Camera3D
var weapon: Node3D
var mobile_move := Vector2.ZERO
var move_touch_index: int = -1
var look_touch_index: int = -1
var move_touch_start := Vector2.ZERO
var mobile_fire_pressed: bool = false
var mobile_jump_requested: bool = false


func _ready() -> void:
	add_to_group("player")
	health = max_health
	shield = max_shield
	gravity = float(ProjectSettings.get_setting("physics/3d/default_gravity", 9.8))
	_build_collision()
	_build_camera_and_weapon()
	health_changed.emit(health, max_health)
	shield_changed.emit(shield, max_shield)
	if not _is_mobile():
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _physics_process(delta: float) -> void:
	if dead:
		return

	time_since_damage += delta
	_recharge_shield(delta)

	var input_vector := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if mobile_move.length() > input_vector.length():
		input_vector = mobile_move

	var local_direction := Vector3(input_vector.x, 0.0, input_vector.y)
	var world_direction := global_transform.basis * local_direction
	world_direction.y = 0.0
	world_direction = world_direction.normalized()

	var wants_sprint := Input.is_action_pressed("sprint") and input_vector.y < -0.15
	var target_speed := sprint_speed if wants_sprint else walk_speed
	var target_velocity := world_direction * target_speed
	var accel := acceleration if is_on_floor() else air_acceleration
	velocity.x = move_toward(velocity.x, target_velocity.x, accel * delta)
	velocity.z = move_toward(velocity.z, target_velocity.z, accel * delta)

	if not is_on_floor():
		velocity.y -= gravity * delta
	elif Input.is_action_just_pressed("jump") or mobile_jump_requested:
		velocity.y = jump_velocity
	mobile_jump_requested = false

	if weapon != null:
		if Input.is_action_pressed("shoot") or mobile_fire_pressed:
			weapon.call("try_fire")
		if Input.is_action_just_pressed("reload"):
			weapon.call("request_reload")

	move_and_slide()


func _unhandled_input(event: InputEvent) -> void:
	if dead:
		return

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_apply_look(event.relative, mouse_sensitivity)
		return

	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED
		return

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED and not _is_mobile():
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		return

	if event is InputEventScreenTouch:
		_handle_touch_press(event)
		return

	if event is InputEventScreenDrag:
		_handle_touch_drag(event)


func _handle_touch_press(event: InputEventScreenTouch) -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	if event.pressed:
		if event.position.x < viewport_size.x * 0.45 and move_touch_index == -1:
			move_touch_index = event.index
			move_touch_start = event.position
			mobile_move = Vector2.ZERO
		elif look_touch_index == -1:
			look_touch_index = event.index
	else:
		if event.index == move_touch_index:
			move_touch_index = -1
			mobile_move = Vector2.ZERO
		if event.index == look_touch_index:
			look_touch_index = -1


func _handle_touch_drag(event: InputEventScreenDrag) -> void:
	if event.index == move_touch_index:
		var drag := (event.position - move_touch_start) / 100.0
		mobile_move = drag.limit_length(1.0)
	elif event.index == look_touch_index:
		_apply_look(event.relative, touch_sensitivity)


func _apply_look(relative_motion: Vector2, sensitivity: float) -> void:
	rotate_y(-relative_motion.x * sensitivity)
	pitch = clampf(pitch - relative_motion.y * sensitivity, deg_to_rad(-82.0), deg_to_rad(82.0))
	if camera != null:
		camera.rotation.x = pitch


func apply_recoil(amount: float) -> void:
	pitch = clampf(pitch - amount, deg_to_rad(-82.0), deg_to_rad(82.0))
	if camera != null:
		camera.rotation.x = pitch


func take_damage(amount: int) -> void:
	if dead or amount <= 0:
		return

	time_since_damage = 0.0
	var remaining := float(amount)
	if shield > 0.0:
		var absorbed := minf(shield, remaining)
		shield -= absorbed
		remaining -= absorbed
		shield_changed.emit(shield, max_shield)

	if remaining > 0.0:
		health = maxi(0, health - int(ceil(remaining)))
		health_changed.emit(health, max_health)

	damaged.emit()
	if health <= 0:
		_die()


func heal(amount: int) -> void:
	if dead or amount <= 0:
		return
	health = mini(max_health, health + amount)
	health_changed.emit(health, max_health)


func restore_shield(amount: float) -> void:
	if dead or amount <= 0.0:
		return
	shield = minf(max_shield, shield + amount)
	shield_changed.emit(shield, max_shield)


func _recharge_shield(delta: float) -> void:
	if time_since_damage < shield_recharge_delay or shield >= max_shield:
		return
	shield = minf(max_shield, shield + shield_recharge_rate * delta)
	shield_changed.emit(shield, max_shield)


func set_mobile_fire(pressed: bool) -> void:
	mobile_fire_pressed = pressed


func request_mobile_jump() -> void:
	mobile_jump_requested = true


func request_mobile_reload() -> void:
	if weapon != null:
		weapon.call("request_reload")


func get_weapon_ammo() -> Vector2i:
	if weapon == null:
		return Vector2i.ZERO
	return Vector2i(int(weapon.get("current_mag")), int(weapon.get("reserve_ammo")))


func _die() -> void:
	dead = true
	velocity = Vector3.ZERO
	mobile_fire_pressed = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	died.emit()


func _build_collision() -> void:
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.38
	capsule.height = 1.82
	collision.shape = capsule
	collision.position.y = 0.02
	add_child(collision)


func _build_camera_and_weapon() -> void:
	camera = Camera3D.new()
	camera.name = "VanguardHelmetCam"
	camera.position = Vector3(0.0, 0.67, 0.0)
	camera.current = true
	camera.fov = 76.0
	camera.near = 0.04
	add_child(camera)

	weapon = Node3D.new()
	weapon.name = "VX7_Rifle"
	weapon.set_script(WEAPON_SCRIPT)
	weapon.connect("ammo_changed", Callable(self, "_on_weapon_ammo_changed"))
	camera.add_child(weapon)


func _on_weapon_ammo_changed(current_mag: int, reserve_ammo: int) -> void:
	ammo_changed.emit(current_mag, reserve_ammo)


func _is_mobile() -> bool:
	return OS.has_feature("mobile") or DisplayServer.is_touchscreen_available()
