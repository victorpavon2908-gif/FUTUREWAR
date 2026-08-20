extends Node3D

const PLAYER_SCRIPT := preload("res://scripts/player_v2.gd")
const ENEMY_SCRIPT := preload("res://scripts/enemy_v2.gd")
const DRONE_SCRIPT := preload("res://scripts/drone.gd")
const COMMAND_SCENE := "res://scenes/boot.tscn"

var player: CharacterBody3D
var shield_bar: ProgressBar
var health_bar: ProgressBar
var shield_label: Label
var health_label: Label
var ammo_label: Label
var reserve_label: Label
var objective_label: Label
var status_label: Label
var hostiles_label: Label
var crosshair: Label
var damage_overlay: ColorRect
var extraction_beacon: Node3D
var extraction_active: bool = false
var game_finished: bool = false
var total_enemies: int = 0
var mission_time: float = 0.0

var cyan := Color(0.07, 0.73, 1.0)
var orange := Color(1.0, 0.28, 0.06)
var pale := Color(0.84, 0.94, 1.0)
var muted := Color(0.43, 0.56, 0.64)


func _ready() -> void:
	_configure_input()
	_build_environment()
	_build_city_zero()
	_spawn_player()
	_spawn_enemies()
	_build_extraction_beacon()
	_build_hud()
	_show_mission_intro()


func _process(delta: float) -> void:
	mission_time += delta
	if game_finished or player == null:
		return

	var enemies_left := get_tree().get_nodes_in_group("enemies").size()
	if hostiles_label != null:
		hostiles_label.text = "HOSTILES  %02d / %02d" % [enemies_left, total_enemies]

	if enemies_left == 0 and not extraction_active:
		_activate_extraction()

	if extraction_active and is_instance_valid(player):
		var extraction_distance := player.global_position.distance_to(Vector3(0.0, 1.0, 29.0))
		if objective_label != null:
			objective_label.text = "REACH EXTRACTION  //  %02d M" % int(extraction_distance)
		if extraction_distance <= 3.4:
			_complete_mission()

	if extraction_active and extraction_beacon != null:
		extraction_beacon.rotation.y += delta * 0.75
		var pulse := 1.0 + sin(mission_time * 4.0) * 0.08
		extraction_beacon.scale = Vector3(pulse, 1.0, pulse)


func _configure_input() -> void:
	_add_key_action("move_forward", KEY_W)
	_add_key_action("move_back", KEY_S)
	_add_key_action("move_left", KEY_A)
	_add_key_action("move_right", KEY_D)
	_add_key_action("jump", KEY_SPACE)
	_add_key_action("sprint", KEY_SHIFT)
	_add_key_action("reload", KEY_R)
	_add_mouse_action("shoot", MOUSE_BUTTON_LEFT)
	_add_mouse_action("aim", MOUSE_BUTTON_RIGHT)


func _add_key_action(action_name: StringName, physical_keycode: Key) -> void:
	if InputMap.has_action(action_name):
		return
	InputMap.add_action(action_name)
	var key_event := InputEventKey.new()
	key_event.physical_keycode = physical_keycode
	InputMap.action_add_event(action_name, key_event)


func _add_mouse_action(action_name: StringName, button_index: MouseButton) -> void:
	if InputMap.has_action(action_name):
		return
	InputMap.add_action(action_name)
	var mouse_event := InputEventMouseButton.new()
	mouse_event.button_index = button_index
	InputMap.action_add_event(action_name, mouse_event)


func _build_environment() -> void:
	var world_environment := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.012, 0.020, 0.032)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.19, 0.27, 0.36)
	environment.ambient_light_energy = 0.80
	environment.fog_enabled = true
	environment.fog_light_color = Color(0.10, 0.15, 0.20)
	environment.fog_density = 0.009
	environment.fog_sky_affect = 0.62
	world_environment.environment = environment
	add_child(world_environment)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-54.0, -28.0, 0.0)
	sun.light_color = Color(0.72, 0.84, 1.0)
	sun.light_energy = 1.22
	sun.shadow_enabled = true
	add_child(sun)

	_create_omni(Vector3(-14.0, 4.0, -14.0), Color(1.0, 0.08, 0.02), 8.0, 10.0)
	_create_omni(Vector3(15.0, 4.0, -8.0), Color(0.0, 0.38, 1.0), 7.0, 10.0)
	_create_omni(Vector3(0.0, 4.0, 18.0), Color(0.0, 0.56, 1.0), 5.0, 9.0)


func _build_city_zero() -> void:
	var concrete := Color(0.065, 0.075, 0.086)
	var metal := Color(0.09, 0.105, 0.12)
	var road := Color(0.035, 0.043, 0.052)
	_create_static_box("Ground", Vector3(0.0, -0.35, 0.0), Vector3(64.0, 0.70, 78.0), concrete, 0.04, 0.94)
	_create_static_box("CentralBoulevard", Vector3(0.0, 0.02, -2.0), Vector3(13.0, 0.08, 70.0), road, 0.12, 0.70)
	_create_static_box("Median", Vector3(0.0, 0.25, -7.0), Vector3(0.75, 0.50, 35.0), metal, 0.42, 0.50)

	_create_static_box("WallNorth", Vector3(0.0, 3.0, -38.5), Vector3(64.0, 6.0, 1.0), metal, 0.38, 0.68)
	_create_static_box("WallSouth", Vector3(0.0, 3.0, 38.5), Vector3(64.0, 6.0, 1.0), metal, 0.38, 0.68)
	_create_static_box("WallWest", Vector3(-31.5, 3.0, 0.0), Vector3(1.0, 6.0, 78.0), metal, 0.38, 0.68)
	_create_static_box("WallEast", Vector3(31.5, 3.0, 0.0), Vector3(1.0, 6.0, 78.0), metal, 0.38, 0.68)

	var buildings := [
		[Vector3(-21.0, 5.8, -27.0), Vector3(9.0, 11.6, 8.0)],
		[Vector3(21.5, 7.4, -28.0), Vector3(8.0, 14.8, 9.0)],
		[Vector3(-23.0, 4.6, -5.0), Vector3(8.0, 9.2, 12.0)],
		[Vector3(23.0, 5.3, -4.0), Vector3(8.0, 10.6, 11.0)],
		[Vector3(-21.0, 3.9, 21.0), Vector3(10.0, 7.8, 9.0)],
		[Vector3(21.0, 4.5, 23.0), Vector3(9.0, 9.0, 9.0)]
	]
	for index in range(buildings.size()):
		var building_position: Vector3 = buildings[index][0]
		var building_size: Vector3 = buildings[index][1]
		var shade := 0.078 + float(index % 3) * 0.012
		_create_static_box("Ruin_%02d" % index, building_position, building_size, Color(shade, shade + 0.012, shade + 0.026), 0.52, 0.68)
		_create_building_light(building_position + Vector3(0.0, minf(2.7, building_size.y * 0.2), -building_size.z * 0.505), building_size.x * 0.62, cyan if index % 2 == 0 else orange)

	# Original sci-fi architecture: broad gate silhouettes and overhead transit beam.
	_create_static_box("GateLeft", Vector3(-5.3, 2.5, -18.0), Vector3(1.6, 5.0, 1.8), metal, 0.70, 0.32)
	_create_static_box("GateRight", Vector3(5.3, 2.5, -18.0), Vector3(1.6, 5.0, 1.8), metal, 0.70, 0.32)
	_create_static_box("GateTop", Vector3(0.0, 5.1, -18.0), Vector3(12.2, 1.0, 1.8), metal, 0.70, 0.32)
	_create_neon_strip(Vector3(0.0, 4.62, -17.04), Vector3(8.2, 0.10, 0.06), cyan)
	_create_static_box("TransitBridge", Vector3(0.0, 6.7, 4.0), Vector3(26.0, 0.65, 3.2), Color(0.07, 0.08, 0.095), 0.58, 0.46)
	_create_neon_strip(Vector3(0.0, 6.35, 2.36), Vector3(18.0, 0.10, 0.06), Color(0.18, 0.50, 1.0))

	var covers := [
		Vector3(-5.5, 0.65, 13.0), Vector3(6.0, 0.65, 9.0),
		Vector3(-7.0, 0.65, 2.0), Vector3(7.8, 0.65, -1.0),
		Vector3(-5.5, 0.65, -11.0), Vector3(5.5, 0.65, -13.0),
		Vector3(-8.5, 0.65, -25.0), Vector3(8.5, 0.65, -27.0)
	]
	for index in range(covers.size()):
		_create_static_box("Barricade_%02d" % index, covers[index], Vector3(2.9, 1.30, 1.05), Color(0.12, 0.135, 0.15), 0.62, 0.42)
		if index % 2 == 0:
			_create_neon_strip(covers[index] + Vector3(0.0, 0.18, -0.54), Vector3(1.7, 0.06, 0.03), orange)

	for pylon_position in [Vector3(-12.0, 1.8, 17.0), Vector3(12.0, 1.8, 14.0), Vector3(-12.0, 1.8, -9.0), Vector3(12.0, 1.8, -12.0), Vector3(-12.0, 1.8, -30.0), Vector3(12.0, 1.8, -31.0)]:
		_create_neon_pylon(pylon_position, cyan if int(abs(pylon_position.z)) % 2 == 0 else orange)

	# Distant skyline is visual-only to keep collision cost low on mobile.
	for index in range(18):
		var side := -1.0 if index % 2 == 0 else 1.0
		var x := side * (36.0 + float((index * 7) % 18))
		var z := -44.0 + float((index * 13) % 86)
		var height := 10.0 + float((index * 17) % 24)
		_create_visual_box(Vector3(x, height * 0.5 - 0.2, z), Vector3(6.0 + float(index % 4), height, 6.0), Color(0.025, 0.038, 0.055), 0.48, 0.74)

	# Small visual debris pieces give depth without dozens of physics bodies.
	for index in range(28):
		var debris_x := -14.0 + float((index * 11) % 28)
		var debris_z := -31.0 + float((index * 19) % 64)
		var debris_size := Vector3(0.28 + float(index % 3) * 0.12, 0.12 + float(index % 2) * 0.08, 0.45 + float(index % 4) * 0.12)
		_create_visual_box(Vector3(debris_x, debris_size.y * 0.5, debris_z), debris_size, Color(0.10, 0.105, 0.11), 0.18, 0.82, Vector3(float((index * 7) % 18), float((index * 31) % 90), float((index * 5) % 14)))


func _spawn_player() -> void:
	player = CharacterBody3D.new()
	player.name = "Vanguard_01"
	player.set_script(PLAYER_SCRIPT)
	player.position = Vector3(0.0, 1.05, 29.0)
	add_child(player)


func _spawn_enemies() -> void:
	var soldier_data := [
		[Vector3(-5.0, 1.05, 12.0), "rifleman"],
		[Vector3(6.5, 1.05, 7.0), "scout"],
		[Vector3(-7.5, 1.05, -3.0), "rifleman"],
		[Vector3(6.5, 1.05, -11.0), "scout"],
		[Vector3(-4.5, 1.05, -21.0), "heavy"],
		[Vector3(7.5, 1.05, -29.0), "commander"]
	]

	for index in range(soldier_data.size()):
		var enemy := CharacterBody3D.new()
		enemy.name = "HELIX_%02d" % (index + 1)
		enemy.set_script(ENEMY_SCRIPT)
		enemy.set("unit_type", str(soldier_data[index][1]))
		enemy.set("target", player)
		enemy.position = soldier_data[index][0]
		add_child(enemy)

	var drone_positions := [Vector3(-9.0, 4.0, -15.0), Vector3(10.0, 4.6, -24.0)]
	for index in range(drone_positions.size()):
		var drone := CharacterBody3D.new()
		drone.name = "HELIX_Drone_%02d" % (index + 1)
		drone.set_script(DRONE_SCRIPT)
		drone.set("target", player)
		drone.position = drone_positions[index]
		add_child(drone)

	total_enemies = get_tree().get_nodes_in_group("enemies").size()


func _build_extraction_beacon() -> void:
	extraction_beacon = Node3D.new()
	extraction_beacon.name = "ExtractionBeacon"
	extraction_beacon.position = Vector3(0.0, 0.08, 29.0)
	extraction_beacon.visible = false
	add_child(extraction_beacon)

	var ring := MeshInstance3D.new()
	var ring_mesh := TorusMesh.new()
	ring_mesh.inner_radius = 1.8
	ring_mesh.outer_radius = 2.05
	ring.mesh = ring_mesh
	ring.material_override = _emissive_material(cyan, 4.2)
	extraction_beacon.add_child(ring)

	var beam := MeshInstance3D.new()
	var beam_mesh := CylinderMesh.new()
	beam_mesh.top_radius = 0.16
	beam_mesh.bottom_radius = 0.60
	beam_mesh.height = 5.5
	beam.mesh = beam_mesh
	beam.position.y = 2.75
	var beam_material := _emissive_material(Color(0.04, 0.55, 1.0, 0.35), 2.2)
	beam_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	beam.material_override = beam_material
	extraction_beacon.add_child(beam)


func _build_hud() -> void:
	var canvas := CanvasLayer.new()
	canvas.layer = 20
	add_child(canvas)

	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(root)

	_build_left_status(root)
	_build_right_weapon(root)
	_build_mission_header(root)
	_build_crosshair(root)
	_build_mobile_controls(root)

	damage_overlay = ColorRect.new()
	damage_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	damage_overlay.color = Color(0.70, 0.02, 0.015, 0.0)
	damage_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(damage_overlay)

	player.connect("health_changed", Callable(self, "_on_player_health_changed"))
	player.connect("shield_changed", Callable(self, "_on_player_shield_changed"))
	player.connect("ammo_changed", Callable(self, "_on_player_ammo_changed"))
	player.connect("damaged", Callable(self, "_on_player_damaged"))
	player.connect("died", Callable(self, "_on_player_died"))

	var weapon_node: Node = player.get("weapon") as Node
	if weapon_node != null:
		weapon_node.connect("hit_confirmed", Callable(self, "_show_hitmarker"))
		_on_player_ammo_changed(int(weapon_node.get("current_mag")), int(weapon_node.get("reserve_ammo")))
	_on_player_health_changed(int(player.get("health")), int(player.get("max_health")))
	_on_player_shield_changed(float(player.get("shield")), float(player.get("max_shield")))


func _build_left_status(root: Control) -> void:
	var panel := Panel.new()
	panel.position = Vector2(24.0, 24.0)
	panel.size = Vector2(300.0, 126.0)
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.015, 0.037, 0.055, 0.87), Color(cyan.r, cyan.g, cyan.b, 0.40), 1))
	root.add_child(panel)

	var id_label := Label.new()
	id_label.text = "VANGUARD // ARMOR SYSTEM"
	id_label.position = Vector2(18.0, 12.0)
	id_label.add_theme_font_size_override("font_size", 12)
	id_label.add_theme_color_override("font_color", cyan)
	panel.add_child(id_label)

	shield_label = Label.new()
	shield_label.text = "SHIELD 100"
	shield_label.position = Vector2(18.0, 38.0)
	shield_label.add_theme_font_size_override("font_size", 12)
	shield_label.add_theme_color_override("font_color", pale)
	panel.add_child(shield_label)

	shield_bar = ProgressBar.new()
	shield_bar.position = Vector2(95.0, 40.0)
	shield_bar.size = Vector2(184.0, 10.0)
	shield_bar.max_value = 100.0
	shield_bar.value = 100.0
	shield_bar.show_percentage = false
	shield_bar.add_theme_stylebox_override("background", _bar_style(Color(0.04, 0.09, 0.12), Color(0.08, 0.18, 0.23)))
	shield_bar.add_theme_stylebox_override("fill", _bar_style(Color(0.04, 0.62, 1.0), cyan))
	panel.add_child(shield_bar)

	health_label = Label.new()
	health_label.text = "CORE 100"
	health_label.position = Vector2(18.0, 70.0)
	health_label.add_theme_font_size_override("font_size", 12)
	health_label.add_theme_color_override("font_color", pale)
	panel.add_child(health_label)

	health_bar = ProgressBar.new()
	health_bar.position = Vector2(95.0, 72.0)
	health_bar.size = Vector2(184.0, 10.0)
	health_bar.max_value = 100.0
	health_bar.value = 100.0
	health_bar.show_percentage = false
	health_bar.add_theme_stylebox_override("background", _bar_style(Color(0.09, 0.04, 0.035), Color(0.18, 0.08, 0.06)))
	health_bar.add_theme_stylebox_override("fill", _bar_style(Color(1.0, 0.24, 0.08), Color(1.0, 0.42, 0.12)))
	panel.add_child(health_bar)

	var nexus := Label.new()
	nexus.text = "NEXUS LINK  ●  STABLE"
	nexus.position = Vector2(18.0, 99.0)
	nexus.add_theme_font_size_override("font_size", 11)
	nexus.add_theme_color_override("font_color", Color(0.42, 0.85, 0.72))
	panel.add_child(nexus)


func _build_right_weapon(root: Control) -> void:
	var panel := Panel.new()
	panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	panel.offset_left = -282.0
	panel.offset_top = 24.0
	panel.offset_right = -24.0
	panel.offset_bottom = 138.0
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.015, 0.037, 0.055, 0.87), Color(cyan.r, cyan.g, cyan.b, 0.40), 1))
	root.add_child(panel)

	var weapon_name := Label.new()
	weapon_name.text = "VX-7 // KINETIC RIFLE"
	weapon_name.position = Vector2(18.0, 12.0)
	weapon_name.add_theme_font_size_override("font_size", 12)
	weapon_name.add_theme_color_override("font_color", cyan)
	panel.add_child(weapon_name)

	ammo_label = Label.new()
	ammo_label.text = "30"
	ammo_label.position = Vector2(16.0, 31.0)
	ammo_label.size = Vector2(110.0, 58.0)
	ammo_label.add_theme_font_size_override("font_size", 44)
	ammo_label.add_theme_color_override("font_color", pale)
	panel.add_child(ammo_label)

	reserve_label = Label.new()
	reserve_label.text = "/ 150"
	reserve_label.position = Vector2(115.0, 52.0)
	reserve_label.add_theme_font_size_override("font_size", 19)
	reserve_label.add_theme_color_override("font_color", muted)
	panel.add_child(reserve_label)

	var mode := Label.new()
	mode.text = "AUTO  •  34 DMG"
	mode.position = Vector2(18.0, 91.0)
	mode.add_theme_font_size_override("font_size", 11)
	mode.add_theme_color_override("font_color", Color(0.55, 0.68, 0.75))
	panel.add_child(mode)


func _build_mission_header(root: Control) -> void:
	var header := Panel.new()
	header.anchor_left = 0.5
	header.anchor_right = 0.5
	header.offset_left = -290.0
	header.offset_top = 24.0
	header.offset_right = 290.0
	header.offset_bottom = 116.0
	header.add_theme_stylebox_override("panel", _panel_style(Color(0.012, 0.028, 0.042, 0.83), Color(cyan.r, cyan.g, cyan.b, 0.25), 1))
	root.add_child(header)

	var chapter := Label.new()
	chapter.text = "OPERATION 01 // CITY ZERO"
	chapter.position = Vector2(20.0, 10.0)
	chapter.size = Vector2(540.0, 22.0)
	chapter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chapter.add_theme_font_size_override("font_size", 12)
	chapter.add_theme_color_override("font_color", cyan)
	header.add_child(chapter)

	objective_label = Label.new()
	objective_label.text = "ELIMINATE HELIX PATROL"
	objective_label.position = Vector2(20.0, 34.0)
	objective_label.size = Vector2(540.0, 27.0)
	objective_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	objective_label.add_theme_font_size_override("font_size", 18)
	objective_label.add_theme_color_override("font_color", pale)
	header.add_child(objective_label)

	hostiles_label = Label.new()
	hostiles_label.text = "HOSTILES  00 / 00"
	hostiles_label.position = Vector2(20.0, 64.0)
	hostiles_label.size = Vector2(540.0, 18.0)
	hostiles_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hostiles_label.add_theme_font_size_override("font_size", 11)
	hostiles_label.add_theme_color_override("font_color", orange)
	header.add_child(hostiles_label)

	status_label = Label.new()
	status_label.anchor_left = 0.5
	status_label.anchor_top = 1.0
	status_label.anchor_right = 0.5
	status_label.anchor_bottom = 1.0
	status_label.offset_left = -330.0
	status_label.offset_top = -80.0
	status_label.offset_right = 330.0
	status_label.offset_bottom = -44.0
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 15)
	status_label.add_theme_color_override("font_color", Color(0.70, 0.84, 0.92))
	status_label.text = "NEXUS: ENTER THE COMBAT ZONE"
	root.add_child(status_label)


func _build_crosshair(root: Control) -> void:
	crosshair = Label.new()
	crosshair.text = "⌁"
	crosshair.anchor_left = 0.5
	crosshair.anchor_top = 0.5
	crosshair.anchor_right = 0.5
	crosshair.anchor_bottom = 0.5
	crosshair.offset_left = -24.0
	crosshair.offset_top = -25.0
	crosshair.offset_right = 24.0
	crosshair.offset_bottom = 25.0
	crosshair.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	crosshair.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	crosshair.add_theme_font_size_override("font_size", 32)
	crosshair.add_theme_color_override("font_color", Color(0.76, 0.94, 1.0))
	root.add_child(crosshair)


func _build_mobile_controls(root: Control) -> void:
	var mobile_visible := _is_mobile()
	var move_pad := Panel.new()
	move_pad.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	move_pad.offset_left = 34.0
	move_pad.offset_top = -205.0
	move_pad.offset_right = 196.0
	move_pad.offset_bottom = -43.0
	move_pad.visible = mobile_visible
	move_pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	move_pad.add_theme_stylebox_override("panel", _panel_style(Color(0.03, 0.10, 0.14, 0.24), Color(cyan.r, cyan.g, cyan.b, 0.30), 2))
	root.add_child(move_pad)

	var move_text := Label.new()
	move_text.text = "MOVE\n   ◉"
	move_text.set_anchors_preset(Control.PRESET_FULL_RECT)
	move_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	move_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	move_text.add_theme_font_size_override("font_size", 17)
	move_text.add_theme_color_override("font_color", Color(cyan.r, cyan.g, cyan.b, 0.62))
	move_pad.add_child(move_text)

	var fire := _mobile_button("FIRE", Vector2(-172.0, -190.0), Vector2(-30.0, -48.0), orange)
	fire.button_down.connect(func() -> void: player.call("set_mobile_fire", true))
	fire.button_up.connect(func() -> void: player.call("set_mobile_fire", false))
	fire.visible = mobile_visible
	root.add_child(fire)

	var jump := _mobile_button("JUMP", Vector2(-318.0, -128.0), Vector2(-203.0, -48.0), cyan)
	jump.pressed.connect(func() -> void: player.call("request_mobile_jump"))
	jump.visible = mobile_visible
	root.add_child(jump)

	var reload := _mobile_button("RLD", Vector2(-302.0, -218.0), Vector2(-207.0, -148.0), Color(0.50, 0.72, 0.84))
	reload.pressed.connect(func() -> void: player.call("request_mobile_reload"))
	reload.visible = mobile_visible
	root.add_child(reload)

	var aim := _mobile_button("ADS", Vector2(-430.0, -185.0), Vector2(-332.0, -105.0), Color(0.38, 0.70, 1.0))
	aim.button_down.connect(func() -> void: Input.action_press("aim"))
	aim.button_up.connect(func() -> void: Input.action_release("aim"))
	aim.visible = mobile_visible
	root.add_child(aim)

	var pc_hint := Label.new()
	pc_hint.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	pc_hint.offset_left = 24.0
	pc_hint.offset_top = -36.0
	pc_hint.offset_right = 760.0
	pc_hint.offset_bottom = -10.0
	pc_hint.text = "WASD MOVE  •  SHIFT SPRINT  •  SPACE JUMP  •  LMB FIRE  •  RMB ADS  •  R RELOAD"
	pc_hint.add_theme_font_size_override("font_size", 11)
	pc_hint.add_theme_color_override("font_color", Color(0.38, 0.50, 0.58))
	pc_hint.visible = not mobile_visible
	root.add_child(pc_hint)


func _mobile_button(text_value: String, top_left: Vector2, bottom_right: Vector2, accent: Color) -> Button:
	var button := Button.new()
	button.text = text_value
	button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	button.offset_left = top_left.x
	button.offset_top = top_left.y
	button.offset_right = bottom_right.x
	button.offset_bottom = bottom_right.y
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_stylebox_override("normal", _panel_style(Color(accent.r * 0.15, accent.g * 0.15, accent.b * 0.15, 0.50), Color(accent.r, accent.g, accent.b, 0.58), 2))
	button.add_theme_stylebox_override("pressed", _panel_style(Color(accent.r * 0.35, accent.g * 0.35, accent.b * 0.35, 0.70), accent, 2))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	return button


func _show_mission_intro() -> void:
	status_label.text = "NEXUS: HELIX SIGNATURES DETECTED // CLEAR THE BOULEVARD"
	var timer := get_tree().create_timer(3.0)
	timer.timeout.connect(func() -> void: if not game_finished and status_label != null: status_label.text = "NEXUS: SHIELD RECHARGES AFTER 3 SECONDS WITHOUT DAMAGE")


func _activate_extraction() -> void:
	extraction_active = true
	extraction_beacon.visible = true
	objective_label.text = "REACH EXTRACTION"
	status_label.text = "NEXUS: SECTOR CLEAR // EXTRACTION BEACON ONLINE"
	status_label.add_theme_color_override("font_color", Color(0.32, 1.0, 0.72))


func _complete_mission() -> void:
	if game_finished:
		return
	game_finished = true
	status_label.text = "MISSION COMPLETE // CITY ZERO SECURED"
	status_label.add_theme_color_override("font_color", Color(0.34, 1.0, 0.70))
	objective_label.text = "VANGUARD EXTRACTED"
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var timer := get_tree().create_timer(4.0)
	timer.timeout.connect(_return_to_command)


func _return_to_command() -> void:
	get_tree().change_scene_to_file(COMMAND_SCENE)


func _on_player_health_changed(current_health: int, maximum_health: int) -> void:
	if health_bar == null:
		return
	health_bar.max_value = maximum_health
	health_bar.value = current_health
	health_label.text = "CORE %03d" % current_health


func _on_player_shield_changed(current_shield: float, maximum_shield: float) -> void:
	if shield_bar == null:
		return
	shield_bar.max_value = maximum_shield
	shield_bar.value = current_shield
	shield_label.text = "SHIELD %03d" % int(current_shield)
	shield_label.add_theme_color_override("font_color", orange if current_shield <= 20.0 else pale)


func _on_player_ammo_changed(current_mag: int, reserve_ammo: int) -> void:
	if ammo_label == null:
		return
	ammo_label.text = "%02d" % current_mag
	reserve_label.text = "/ %03d" % reserve_ammo
	ammo_label.add_theme_color_override("font_color", orange if current_mag <= 5 else pale)


func _on_player_damaged() -> void:
	if damage_overlay == null:
		return
	damage_overlay.color = Color(0.76, 0.02, 0.01, 0.23)
	var tween := create_tween()
	tween.tween_property(damage_overlay, "color", Color(0.76, 0.02, 0.01, 0.0), 0.34)


func _on_player_died() -> void:
	if game_finished:
		return
	game_finished = true
	status_label.text = "VANGUARD DOWN // REBOOTING COMBAT SIMULATION"
	status_label.add_theme_color_override("font_color", Color(1.0, 0.16, 0.08))
	var timer := get_tree().create_timer(2.6)
	timer.timeout.connect(_restart_level)


func _restart_level() -> void:
	get_tree().reload_current_scene()


func _show_hitmarker() -> void:
	if crosshair == null:
		return
	crosshair.text = "×"
	crosshair.add_theme_color_override("font_color", Color(1.0, 0.30, 0.10))
	var timer := get_tree().create_timer(0.085)
	timer.timeout.connect(_clear_hitmarker)


func _clear_hitmarker() -> void:
	if crosshair != null:
		crosshair.text = "⌁"
		crosshair.add_theme_color_override("font_color", Color(0.76, 0.94, 1.0))


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
	mesh_instance.material_override = _material(color, metallic, roughness)
	body.add_child(mesh_instance)
	add_child(body)
	return body


func _create_visual_box(box_position: Vector3, box_size: Vector3, color: Color, metallic: float, roughness: float, rotation_value: Vector3 = Vector3.ZERO) -> void:
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = box_size
	mesh_instance.mesh = mesh
	mesh_instance.position = box_position
	mesh_instance.rotation_degrees = rotation_value
	mesh_instance.material_override = _material(color, metallic, roughness)
	add_child(mesh_instance)


func _create_neon_pylon(pylon_position: Vector3, glow_color: Color) -> void:
	_create_static_box("NeonPylon", pylon_position, Vector3(0.40, 3.6, 0.40), Color(0.055, 0.065, 0.075), 0.72, 0.26)
	_create_neon_strip(pylon_position + Vector3(0.0, 0.0, -0.215), Vector3(0.12, 2.7, 0.025), glow_color)


func _create_neon_strip(strip_position: Vector3, strip_size: Vector3, glow_color: Color) -> void:
	var instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = strip_size
	instance.mesh = mesh
	instance.position = strip_position
	instance.material_override = _emissive_material(glow_color, 3.4)
	add_child(instance)


func _create_building_light(light_position: Vector3, width: float, glow_color: Color) -> void:
	_create_neon_strip(light_position, Vector3(width, 0.10, 0.04), glow_color)


func _create_omni(light_position: Vector3, light_color: Color, energy: float, light_range: float) -> void:
	var light := OmniLight3D.new()
	light.position = light_position
	light.light_color = light_color
	light.light_energy = energy
	light.omni_range = light_range
	light.shadow_enabled = false
	add_child(light)


func _material(color: Color, metallic: float, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metallic
	material.roughness = roughness
	return material


func _emissive_material(color: Color, energy: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = energy
	material.metallic = 0.20
	material.roughness = 0.16
	return material


func _panel_style(background: Color, border: Color, width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(width)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	return style


func _bar_style(background: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(1)
	style.corner_radius_top_left = 2
	style.corner_radius_top_right = 2
	style.corner_radius_bottom_left = 2
	style.corner_radius_bottom_right = 2
	return style


func _is_mobile() -> bool:
	return OS.has_feature("mobile") or DisplayServer.is_touchscreen_available()
