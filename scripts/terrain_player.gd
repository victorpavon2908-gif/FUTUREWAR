extends CharacterBody3D

const WEAPON_V5: Script = preload("res://scripts/weapon_v5.gd")

var gravity: float = 9.8
var pitch: float = 0.0
var camera: Camera3D
var weapon: Node3D


func _ready() -> void:
	gravity = float(ProjectSettings.get_setting("physics/3d/default_gravity", 9.8))
	_ensure_combat_input()
	_build_collision()
	_build_camera_and_weapon()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _physics_process(delta: float) -> void:
	var input_vector: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction: Vector3 = global_transform.basis * Vector3(input_vector.x, 0.0, input_vector.y)
	direction.y = 0.0
	direction = direction.normalized()
	var speed: float = 10.0 if Input.is_action_pressed("sprint") else 6.0
	velocity.x = move_toward(velocity.x, direction.x * speed, 22.0 * delta)
	velocity.z = move_toward(velocity.z, direction.z * speed, 22.0 * delta)

	if not is_on_floor():
		velocity.y -= gravity * delta
	elif Input.is_action_just_pressed("jump"):
		velocity.y = 5.3

	if weapon != null:
		if Input.is_action_pressed("shoot"):
			weapon.call("try_fire")
		if Input.is_action_just_pressed("reload"):
			weapon.call("request_reload")

	move_and_slide()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * 0.0022)
		pitch = clampf(pitch - event.relative.y * 0.0022, deg_to_rad(-82.0), deg_to_rad(82.0))
		camera.rotation.x = pitch
	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func apply_recoil(amount: float) -> void:
	pitch = clampf(pitch - amount, deg_to_rad(-82.0), deg_to_rad(82.0))
	if camera != null:
		camera.rotation.x = pitch


func _build_collision() -> void:
	var collision: CollisionShape3D = CollisionShape3D.new()
	var capsule: CapsuleShape3D = CapsuleShape3D.new()
	capsule.radius = 0.38
	capsule.height = 1.82
	collision.shape = capsule
	add_child(collision)


func _build_camera_and_weapon() -> void:
	camera = Camera3D.new()
	camera.name = "VanguardHelmetCam"
	camera.position = Vector3(0.0, 0.70, 0.0)
	camera.fov = 76.0
	camera.near = 0.025
	camera.current = true
	add_child(camera)

	weapon = Node3D.new()
	weapon.name = "VA9_ArcRifle_Viewmodel"
	weapon.set_script(WEAPON_V5)
	camera.add_child(weapon)

	_build_crosshair()


func _build_crosshair() -> void:
	var layer: CanvasLayer = CanvasLayer.new()
	layer.layer = 15
	add_child(layer)
	var center: Control = Control.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(center)

	var dot: ColorRect = ColorRect.new()
	dot.color = Color(0.72, 0.92, 1.0, 0.86)
	dot.size = Vector2(3.0, 3.0)
	dot.position = Vector2(-1.5, -1.5)
	dot.set_anchors_preset(Control.PRESET_CENTER)
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(dot)

	for data: Array in [
		[Vector2(-11.0, -1.0), Vector2(6.0, 2.0)],
		[Vector2(5.0, -1.0), Vector2(6.0, 2.0)],
		[Vector2(-1.0, -11.0), Vector2(2.0, 6.0)],
		[Vector2(-1.0, 5.0), Vector2(2.0, 6.0)]
	]:
		var line: ColorRect = ColorRect.new()
		line.color = Color(0.64, 0.88, 1.0, 0.56)
		line.size = data[1] as Vector2
		line.position = data[0] as Vector2
		line.set_anchors_preset(Control.PRESET_CENTER)
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		center.add_child(line)


func _ensure_combat_input() -> void:
	_ensure_mouse_action("shoot", MOUSE_BUTTON_LEFT)
	_ensure_mouse_action("aim", MOUSE_BUTTON_RIGHT)
	_ensure_key_action("reload", KEY_R)


func _ensure_mouse_action(action_name: StringName, button_index: int) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	if InputMap.action_get_events(action_name).is_empty():
		var event: InputEventMouseButton = InputEventMouseButton.new()
		event.button_index = button_index
		InputMap.action_add_event(action_name, event)


func _ensure_key_action(action_name: StringName, keycode: Key) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	if InputMap.action_get_events(action_name).is_empty():
		var event: InputEventKey = InputEventKey.new()
		event.physical_keycode = keycode
		InputMap.action_add_event(action_name, event)
