extends CharacterBody3D

var gravity: float = 9.8
var pitch: float = 0.0
var camera: Camera3D

func _ready() -> void:
	gravity = float(ProjectSettings.get_setting("physics/3d/default_gravity", 9.8))
	var collision: CollisionShape3D = CollisionShape3D.new()
	var capsule: CapsuleShape3D = CapsuleShape3D.new()
	capsule.radius = 0.38
	capsule.height = 1.82
	collision.shape = capsule
	add_child(collision)
	camera = Camera3D.new()
	camera.position = Vector3(0.0, 0.70, 0.0)
	camera.fov = 78.0
	camera.current = true
	add_child(camera)
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
	move_and_slide()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * 0.0022)
		pitch = clampf(pitch - event.relative.y * 0.0022, deg_to_rad(-82.0), deg_to_rad(82.0))
		camera.rotation.x = pitch
	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED
