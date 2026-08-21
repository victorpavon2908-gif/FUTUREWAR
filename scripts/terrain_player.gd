extends CharacterBody3D

const BODY_SCRIPT: Script = preload("res://scripts/jefe_body.gd")
const ARSENAL_SCRIPT: Script = preload("res://scripts/jefe_weapon_arsenal.gd")
const COMBAT_SCRIPT: Script = preload("res://scripts/jefe_combat_overlay.gd")

var gravity: float = 9.8
var pitch: float = 0.0
var walk_speed: float = 6.0
var sprint_speed: float = 10.0
var acceleration: float = 22.0

var look_pivot: Node3D
var first_camera: Camera3D
var third_camera: Camera3D
var weapon_rig: Node3D
var body_model: Node3D
var combat_overlay: Node
var third_person: bool = false


func _ready() -> void:
	gravity = float(ProjectSettings.get_setting("physics/3d/default_gravity", 9.8))
	_configure_actions()
	_build_collision()
	_build_view_system()
	_build_jefe_body()
	_build_weapon_rig()
	_build_combat_overlay()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _physics_process(delta: float) -> void:
	var input_vector: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction: Vector3 = global_transform.basis * Vector3(input_vector.x, 0.0, input_vector.y)
	direction.y = 0.0
	direction = direction.normalized()
	var sprinting: bool = Input.is_action_pressed("sprint") and input_vector.y < -0.10
	var speed: float = sprint_speed if sprinting else walk_speed
	velocity.x = move_toward(velocity.x, direction.x * speed, acceleration * delta)
	velocity.z = move_toward(velocity.z, direction.z * speed, acceleration * delta)

	if not is_on_floor():
		velocity.y -= gravity * delta
	elif Input.is_action_just_pressed("jump"):
		velocity.y = 5.3

	move_and_slide()

	var planar_speed: float = Vector2(velocity.x, velocity.z).length()
	var speed_ratio: float = clampf(planar_speed / sprint_speed, 0.0, 1.0)
	if body_model != null and body_model.has_method("update_pose"):
		body_model.call("update_pose", delta, speed_ratio, sprinting)

	# Apply the armed upper-body stance after locomotion so the legs can walk/run
	# while JEFE keeps both hands committed to the weapon.
	if combat_overlay != null and combat_overlay.has_method("apply_combat_pose"):
		combat_overlay.call(
			"apply_combat_pose",
			delta,
			speed_ratio,
			sprinting,
			not is_on_floor(),
			Input.is_action_pressed("aim")
		)

	if weapon_rig != null:
		weapon_rig.call("update_motion", speed_ratio, sprinting)
		weapon_rig.call("set_trigger", Input.is_action_pressed("shoot"))
		weapon_rig.call("set_aim", Input.is_action_pressed("aim"))
		if Input.is_action_just_pressed("reload"):
			weapon_rig.call("request_reload")


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * 0.0022)
		pitch = clampf(pitch - event.relative.y * 0.0022, deg_to_rad(-78.0), deg_to_rad(78.0))
		look_pivot.rotation.x = pitch
		return

	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and weapon_rig != null:
			weapon_rig.call("cycle_weapon", 1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and weapon_rig != null:
			weapon_rig.call("cycle_weapon", -1)
		return

	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_ESCAPE:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED
			KEY_V:
				_toggle_view()
			KEY_1:
				_equip(0)
			KEY_2:
				_equip(1)
			KEY_3:
				_equip(2)
			KEY_4:
				_equip(3)
			KEY_5:
				_equip(4)
			KEY_6:
				_equip(5)


func _equip(index: int) -> void:
	if weapon_rig != null:
		weapon_rig.call("equip_weapon", index)
	if combat_overlay != null and combat_overlay.has_method("set_weapon_index"):
		combat_overlay.call("set_weapon_index", index)


func _toggle_view() -> void:
	third_person = not third_person
	first_camera.current = not third_person
	third_camera.current = third_person
	body_model.visible = third_person
	weapon_rig.visible = not third_person


func _build_collision() -> void:
	var collision: CollisionShape3D = CollisionShape3D.new()
	var capsule: CapsuleShape3D = CapsuleShape3D.new()
	capsule.radius = 0.38
	capsule.height = 1.82
	collision.shape = capsule
	add_child(collision)


func _build_view_system() -> void:
	look_pivot = Node3D.new()
	look_pivot.name = "JEFE_LOOK_PIVOT"
	look_pivot.position = Vector3(0.0, 0.70, 0.0)
	add_child(look_pivot)

	first_camera = Camera3D.new()
	first_camera.name = "JEFE_FPS_CAMERA"
	first_camera.fov = 74.0
	first_camera.near = 0.035
	first_camera.current = true
	look_pivot.add_child(first_camera)

	third_camera = Camera3D.new()
	third_camera.name = "JEFE_CHARACTER_CAMERA"
	third_camera.position = Vector3(0.0, 1.08, 4.25)
	third_camera.fov = 64.0
	third_camera.near = 0.08
	third_camera.current = false
	look_pivot.add_child(third_camera)


func _build_jefe_body() -> void:
	body_model = Node3D.new()
	body_model.name = "JEFE_BODY"
	body_model.position = Vector3(0.0, 0.18, 0.0)
	body_model.set_script(BODY_SCRIPT)
	body_model.visible = false
	add_child(body_model)
	call_deferred("_postprocess_jefe_external_model")


func _postprocess_jefe_external_model() -> void:
	if body_model == null:
		return
	var production: Node = body_model.find_child("JEFE_PRODUCTION_MODEL", true, false)
	if production == null or not production is Node3D:
		return

	var production_3d: Node3D = production as Node3D
	# The AccuRIG FBX already faces FUTUREWAR's -Z gameplay direction. The old
	# unrigged GLB required a 180-degree correction. Detect the skeleton so the
	# third-person camera sees JEFE's back instead of his chest.
	if _contains_skeleton(production_3d):
		production_3d.rotation_degrees.y = 0.0
	else:
		production_3d.rotation_degrees.y = 180.0
	_fix_imported_materials(production_3d)


func _contains_skeleton(node: Node) -> bool:
	if node is Skeleton3D:
		return true
	for child: Node in node.get_children():
		if _contains_skeleton(child):
			return true
	return false


func _fix_imported_materials(node: Node) -> void:
	if node is MeshInstance3D:
		var mesh_instance: MeshInstance3D = node as MeshInstance3D
		if mesh_instance.mesh != null:
			for surface: int in range(mesh_instance.mesh.get_surface_count()):
				var source_material: Material = mesh_instance.mesh.surface_get_material(surface)
				if source_material is StandardMaterial3D:
					var fixed_material: StandardMaterial3D = (source_material as StandardMaterial3D).duplicate() as StandardMaterial3D
					fixed_material.emission_enabled = false

					var material_name: String = String(fixed_material.resource_name).to_lower()
					if material_name.contains("pants") or material_name == "material":
						fixed_material.albedo_color = Color(0.48, 0.52, 0.43, 1.0)
						fixed_material.metallic = 0.08
						fixed_material.roughness = 0.78
					else:
						fixed_material.albedo_color = Color(0.55, 0.62, 0.34, 1.0)
						fixed_material.metallic = 0.30
						fixed_material.roughness = 0.50
					mesh_instance.set_surface_override_material(surface, fixed_material)

	for child: Node in node.get_children():
		_fix_imported_materials(child)


func _build_weapon_rig() -> void:
	weapon_rig = Node3D.new()
	weapon_rig.name = "JEFE_WEAPON_ARSENAL"
	weapon_rig.set_script(ARSENAL_SCRIPT)
	first_camera.add_child(weapon_rig)


func _build_combat_overlay() -> void:
	combat_overlay = Node.new()
	combat_overlay.name = "JEFE_COMBAT_OVERLAY"
	combat_overlay.set_script(COMBAT_SCRIPT)
	add_child(combat_overlay)
	combat_overlay.call("setup", body_model)


func _configure_actions() -> void:
	_ensure_key_action("move_forward", KEY_W)
	_ensure_key_action("move_back", KEY_S)
	_ensure_key_action("move_left", KEY_A)
	_ensure_key_action("move_right", KEY_D)
	_ensure_key_action("sprint", KEY_SHIFT)
	_ensure_key_action("jump", KEY_SPACE)
	_ensure_key_action("reload", KEY_R)
	_ensure_mouse_action("shoot", MOUSE_BUTTON_LEFT)
	_ensure_mouse_action("aim", MOUSE_BUTTON_RIGHT)


func _ensure_key_action(action_name: StringName, keycode: Key) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	if InputMap.action_get_events(action_name).is_empty():
		var event: InputEventKey = InputEventKey.new()
		event.physical_keycode = keycode
		InputMap.action_add_event(action_name, event)


func _ensure_mouse_action(action_name: StringName, button_index: int) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	if InputMap.action_get_events(action_name).is_empty():
		var event: InputEventMouseButton = InputEventMouseButton.new()
		event.button_index = button_index
		InputMap.action_add_event(action_name, event)
