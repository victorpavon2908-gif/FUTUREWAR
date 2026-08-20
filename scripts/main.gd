extends Node3D

const PLAYER_SCRIPT := preload("res://scripts/player.gd")
const ENEMY_SCRIPT := preload("res://scripts/enemy.gd")

var player: CharacterBody3D
var health_label: Label
var ammo_label: Label
var objective_label: Label
var status_label: Label
var crosshair: Label
var game_finished: bool = false
var total_enemies: int = 0


func _ready() -> void:
	_configure_input()
	_build_environment()
	_build_city_zero()
	_spawn_player()
	_spawn_enemies()
	_build_hud()


func _process(_delta: float) -> void:
	if game_finished:
		return

	var enemies_left := get_tree().get_nodes_in_group("enemies").size()
	if objective_label != null:
		objective_label.text = "OPERATION CITY ZERO  •  HOSTILES %d / %d" % [enemies_left, total_enemies]

	if total_enemies > 0 and enemies_left == 0:
		game_finished = true
		status_label.text = "SECTOR CLEARED  //  EXTRACTION COMPLETE"
		status_label.modulate = Color(0.35, 1.0, 0.72)
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _configure_input() -> void:
	_add_key_action("move_forward", KEY_W)
	_add_key_action("move_back", KEY_S)
	_add_key_action("move_left", KEY_A)
	_add_key_action("move_right", KEY_D)
	_add_key_action("jump", KEY_SPACE)
	_add_key_action("sprint", KEY_SHIFT)
	_add_key_action("reload", KEY_R)

	if not InputMap.has_action("shoot"):
		InputMap.add_action("shoot")
	var mouse_event := InputEventMouseButton.new()
	mouse_event.button_index = MOUSE_BUTTON_LEFT
	InputMap.action_add_event("shoot", mouse_event)


func _add_key_action(action_name: StringName, physical_keycode: Key) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	var key_event := InputEventKey.new()
	key_event.physical_keycode = physical_keycode
	InputMap.action_add_event(action_name, key_event)


func _build_environment() -> void:
	var world_environment := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.025, 0.035, 0.05)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.20, 0.30, 0.42)
	environment.ambient_light_energy = 0.82
	environment.fog_enabled = true
	environment.fog_light_color = Color(0.16, 0.20, 0.25)
	environment.fog_density = 0.008
	environment.fog_sky_affect = 0.5
	world_environment.environment = environment
	add_child(world_environment)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-56.0, -32.0, 0.0)
	sun.light_color = Color(0.78, 0.87, 1.0)
	sun.light_energy = 1.25
	sun.shadow_enabled = true
	add_child(sun)

	var red_light := OmniLight3D.new()
	red_light.position = Vector3(-11.0, 3.5, -15.0)
	red_light.light_color = Color(1.0, 0.08, 0.025)
	red_light.light_energy = 12.0
	red_light.omni_range = 11.0
	red_light.shadow_enabled = false
	add_child(red_light)

	var blue_light := OmniLight3D.new()
	blue_light.position = Vector3(12.0, 4.0, -8.0)
	blue_light.light_color = Color(0.0, 0.28, 1.0)
	blue_light.light_energy = 10.0
	blue_light.omni_range = 10.0
	blue_light.shadow_enabled = false
	add_child(blue_light)


func _build_city_zero() -> void:
	_create_static_box("Ground", Vector3(0.0, -0.30, 0.0), Vector3(62.0, 0.60, 72.0), Color(0.075, 0.082, 0.09), 0.05, 0.95)

	# Perimeter walls keep the prototype combat area contained.
	_create_static_box("WallNorth", Vector3(0.0, 3.0, -35.5), Vector3(62.0, 6.0, 1.0), Color(0.09, 0.10, 0.12), 0.35, 0.72)
	_create_static_box("WallSouth", Vector3(0.0, 3.0, 35.5), Vector3(62.0, 6.0, 1.0), Color(0.09, 0.10, 0.12), 0.35, 0.72)
	_create_static_box("WallWest", Vector3(-30.5, 3.0, 0.0), Vector3(1.0, 6.0, 72.0), Color(0.09, 0.10, 0.12), 0.35, 0.72)
	_create_static_box("WallEast", Vector3(30.5, 3.0, 0.0), Vector3(1.0, 6.0, 72.0), Color(0.09, 0.10, 0.12), 0.35, 0.72)

	# Ruined towers and cover. All geometry uses primitives so the game opens without external assets.
	var ruins := [
		[Vector3(-20.0, 5.0, -22.0), Vector3(8.0, 10.0, 7.0)],
		[Vector3(20.5, 6.5, -24.0), Vector3(7.5, 13.0, 8.0)],
		[Vector3(-22.0, 4.0, 2.0), Vector3(7.0, 8.0, 10.0)],
		[Vector3(22.0, 4.8, 5.0), Vector3(7.0, 9.6, 9.0)],
		[Vector3(-18.0, 3.2, 23.0), Vector3(10.0, 6.4, 6.0)],
		[Vector3(19.0, 3.6, 24.0), Vector3(9.0, 7.2, 7.0)]
	]
	for index in range(ruins.size()):
		var ruin_position: Vector3 = ruins[index][0]
		var ruin_size: Vector3 = ruins[index][1]
		var shade := 0.105 + float(index % 3) * 0.018
		_create_static_box("Ruin_%02d" % index, ruin_position, ruin_size, Color(shade, shade + 0.01, shade + 0.025), 0.48, 0.70)

	var covers := [
		Vector3(-6.5, 0.65, 7.0), Vector3(5.8, 0.65, 1.0),
		Vector3(-8.0, 0.65, -5.0), Vector3(8.0, 0.65, -8.0),
		Vector3(-4.0, 0.65, -16.0), Vector3(4.5, 0.65, -19.0),
		Vector3(-9.5, 0.65, 19.0), Vector3(10.0, 0.65, 17.0)
	]
	for index in range(covers.size()):
		_create_static_box("Cover_%02d" % index, covers[index], Vector3(2.7, 1.3, 1.0), Color(0.12, 0.14, 0.16), 0.62, 0.48)

	# Futuristic emissive pylons make the greybox readable and establish the art direction.
	_create_neon_pylon(Vector3(-13.5, 1.9, -10.0), Color(0.0, 0.42, 1.0))
	_create_neon_pylon(Vector3(14.5, 1.9, -13.0), Color(1.0, 0.10, 0.025))
	_create_neon_pylon(Vector3(-13.0, 1.9, 15.0), Color(0.0, 0.42, 1.0))
	_create_neon_pylon(Vector3(15.0, 1.9, 13.0), Color(1.0, 0.10, 0.025))


func _spawn_player() -> void:
	player = CharacterBody3D.new()
	player.name = "VanguardPlayer"
	player.set_script(PLAYER_SCRIPT)
	player.position = Vector3(0.0, 1.05, 25.0)
	add_child(player)

func _spawn_enemies() -> void:
	var spawn_points := [
		Vector3(-4.0, 1.05, 8.0),
		Vector3(7.0, 1.05, 1.0),
		Vector3(-8.0, 1.05, -7.0),
		Vector3(5.0, 1.05, -14.0),
		Vector3(-2.0, 1.05, -25.0),
		Vector3(12.0, 1.05, -22.0)
	]
	total_enemies = spawn_points.size()

	for index in range(spawn_points.size()):
		var enemy := CharacterBody3D.new()
		enemy.name = "HelixSoldier_%02d" % (index + 1)
		enemy.set_script(ENEMY_SCRIPT)
		enemy.position = spawn_points[index]
		add_child(enemy)
		enemy.set("target", player)


func _build_hud() -> void:
	var canvas := CanvasLayer.new()
	canvas.layer = 10
	add_child(canvas)

	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(root)

	health_label = Label.new()
	health_label.text = "ARMOR 100 / 100"
	health_label.position = Vector2(28.0, 24.0)
	health_label.add_theme_font_size_override("font_size", 22)
	root.add_child(health_label)

	ammo_label = Label.new()
	ammo_label.text = "VX-7   30 / 120"
	ammo_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	ammo_label.offset_left = -250.0
	ammo_label.offset_top = 24.0
	ammo_label.offset_right = -28.0
	ammo_label.offset_bottom = 62.0
	ammo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ammo_label.add_theme_font_size_override("font_size", 22)
	root.add_child(ammo_label)

	objective_label = Label.new()
	objective_label.text = "OPERATION CITY ZERO"
	objective_label.anchor_left = 0.5
	objective_label.anchor_right = 0.5
	objective_label.offset_left = -260.0
	objective_label.offset_right = 260.0
	objective_label.offset_top = 24.0
	objective_label.offset_bottom = 58.0
	objective_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	objective_label.add_theme_font_size_override("font_size", 18)
	objective_label.modulate = Color(0.70, 0.86, 1.0)
	root.add_child(objective_label)

	status_label = Label.new()
	status_label.text = "OBJECTIVE: ELIMINATE HELIX PATROL"
	status_label.anchor_left = 0.5
	status_label.anchor_right = 0.5
	status_label.offset_left = -320.0
	status_label.offset_right = 320.0
	status_label.offset_top = 58.0
	status_label.offset_bottom = 90.0
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 16)
	status_label.modulate = Color(1.0, 0.54, 0.18)
	root.add_child(status_label)

	crosshair = Label.new()
	crosshair.text = "+"
	crosshair.anchor_left = 0.5
	crosshair.anchor_top = 0.5
	crosshair.anchor_right = 0.5
	crosshair.anchor_bottom = 0.5
	crosshair.offset_left = -18.0
	crosshair.offset_top = -23.0
	crosshair.offset_right = 18.0
	crosshair.offset_bottom = 23.0
	crosshair.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	crosshair.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	crosshair.add_theme_font_size_override("font_size", 30)
	crosshair.modulate = Color(0.76, 0.94, 1.0)
	root.add_child(crosshair)

	var controls_hint := Label.new()
	controls_hint.text = "WASD MOVE   •   SHIFT SPRINT   •   SPACE JUMP   •   LMB FIRE   •   R RELOAD"
	controls_hint.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	controls_hint.offset_left = 24.0
	controls_hint.offset_top = -48.0
	controls_hint.offset_right = 820.0
	controls_hint.offset_bottom = -18.0
	controls_hint.add_theme_font_size_override("font_size", 14)
	controls_hint.modulate = Color(0.62, 0.67, 0.74)
	controls_hint.visible = not _is_mobile()
	root.add_child(controls_hint)

	_build_mobile_controls(root)

	player.health_changed.connect(_on_player_health_changed)
	player.ammo_changed.connect(_on_player_ammo_changed)
	player.died.connect(_on_player_died)
	if player.weapon != null:
		player.weapon.hit_confirmed.connect(_show_hitmarker)
		var ammo: Vector2i = player.get_weapon_ammo()
		_on_player_ammo_changed(ammo.x, ammo.y)
	_on_player_health_changed(player.health, player.max_health)


func _build_mobile_controls(root: Control) -> void:
	var mobile_visible := _is_mobile()

	var move_hint := Label.new()
	move_hint.text = "MOVE\n◉"
	move_hint.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	move_hint.offset_left = 45.0
	move_hint.offset_top = -175.0
	move_hint.offset_right = 180.0
	move_hint.offset_bottom = -40.0
	move_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	move_hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	move_hint.add_theme_font_size_override("font_size", 20)
	move_hint.modulate = Color(0.56, 0.75, 1.0, 0.62)
	move_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	move_hint.visible = mobile_visible
	root.add_child(move_hint)

	var fire_button := Button.new()
	fire_button.text = "FIRE"
	fire_button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	fire_button.offset_left = -170.0
	fire_button.offset_top = -175.0
	fire_button.offset_right = -30.0
	fire_button.offset_bottom = -35.0
	fire_button.add_theme_font_size_override("font_size", 22)
	fire_button.modulate = Color(1.0, 0.48, 0.30, 0.84)
	fire_button.visible = mobile_visible
	fire_button.button_down.connect(func() -> void: player.set_mobile_fire(true))
	fire_button.button_up.connect(func() -> void: player.set_mobile_fire(false))
	root.add_child(fire_button)

	var jump_button := Button.new()
	jump_button.text = "JUMP"
	jump_button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	jump_button.offset_left = -310.0
	jump_button.offset_top = -120.0
	jump_button.offset_right = -195.0
	jump_button.offset_bottom = -35.0
	jump_button.add_theme_font_size_override("font_size", 17)
	jump_button.modulate = Color(0.52, 0.76, 1.0, 0.84)
	jump_button.visible = mobile_visible
	jump_button.pressed.connect(func() -> void: player.request_mobile_jump())
	root.add_child(jump_button)

	var reload_button := Button.new()
	reload_button.text = "RELOAD"
	reload_button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	reload_button.offset_left = -295.0
	reload_button.offset_top = -220.0
	reload_button.offset_right = -180.0
	reload_button.offset_bottom = -145.0
	reload_button.add_theme_font_size_override("font_size", 15)
	reload_button.modulate = Color(0.70, 0.82, 0.94, 0.78)
	reload_button.visible = mobile_visible
	reload_button.pressed.connect(func() -> void: player.request_mobile_reload())
	root.add_child(reload_button)


func _on_player_health_changed(current_health: int, maximum_health: int) -> void:
	if health_label == null:
		return
	health_label.text = "ARMOR %d / %d" % [current_health, maximum_health]
	health_label.modulate = Color(1.0, 0.25, 0.18) if current_health <= 30 else Color.WHITE


func _on_player_ammo_changed(current_mag: int, reserve_ammo: int) -> void:
	if ammo_label == null:
		return
	ammo_label.text = "VX-7   %02d / %03d" % [current_mag, reserve_ammo]
	ammo_label.modulate = Color(1.0, 0.38, 0.18) if current_mag <= 5 else Color.WHITE


func _on_player_died() -> void:
	if game_finished:
		return
	game_finished = true
	status_label.text = "VANGUARD DOWN  //  REBOOTING SIMULATION..."
	status_label.modulate = Color(1.0, 0.18, 0.12)
	var timer := get_tree().create_timer(2.2)
	timer.timeout.connect(_restart_level)


func _restart_level() -> void:
	get_tree().reload_current_scene()


func _show_hitmarker() -> void:
	if crosshair == null:
		return
	crosshair.text = "×"
	crosshair.modulate = Color(1.0, 0.32, 0.18)
	var timer := get_tree().create_timer(0.085)
	timer.timeout.connect(_clear_hitmarker)


func _clear_hitmarker() -> void:
	if crosshair != null:
		crosshair.text = "+"
		crosshair.modulate = Color(0.76, 0.94, 1.0)


func _create_static_box(node_name: String, box_position: Vector3, box_size: Vector3, color: Color, metallic: float, roughness: float) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = box_position

	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = box_size
	collision.shape = shape
	body.add_child(collision)

	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = box_size
	mesh_instance.mesh = mesh
	mesh_instance.material_override = _make_material(color, metallic, roughness)
	body.add_child(mesh_instance)

	add_child(body)
	return body


func _create_neon_pylon(pylon_position: Vector3, glow_color: Color) -> void:
	var pylon := StaticBody3D.new()
	pylon.position = pylon_position

	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.42, 3.8, 0.42)
	collision.shape = shape
	pylon.add_child(collision)

	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.42, 3.8, 0.42)
	mesh_instance.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = glow_color * 0.25
	material.emission_enabled = true
	material.emission = glow_color
	material.emission_energy_multiplier = 3.2
	material.metallic = 0.35
	material.roughness = 0.20
	mesh_instance.material_override = material
	pylon.add_child(mesh_instance)

	add_child(pylon)


func _make_material(color: Color, metallic: float, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metallic
	material.roughness = roughness
	return material


func _is_mobile() -> bool:
	return OS.has_feature("mobile") or DisplayServer.is_touchscreen_available()
