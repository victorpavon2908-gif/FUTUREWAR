extends Control

const GAME_SCENE := "res://scenes/main.tscn"

const WORLDS := [
	{
		"id": "CITY_ZERO",
		"chapter": "01",
		"title": "CITY ZERO",
		"subtitle": "THE FALL",
		"location": "NEO-MANAGUA // CENTRAL SECTOR",
		"description": "A shattered megacity is the first breach in HELIX territory. Vanguard enters through the ruins to recover the NEXUS core and reopen the evacuation corridor.",
		"accent": Color(0.10, 0.72, 1.0),
		"available": true
	},
	{
		"id": "IRON_WASTELAND",
		"chapter": "02",
		"title": "IRON WASTELAND",
		"subtitle": "FOUNDRY WAR",
		"location": "INDUSTRIAL DEAD ZONE",
		"description": "Abandoned factories, rail cannons and automated foundries hide a production line building HELIX heavy units.",
		"accent": Color(1.0, 0.36, 0.12),
		"available": false
	},
	{
		"id": "SKYLINE_ARC",
		"chapter": "03",
		"title": "SKYLINE ARC",
		"subtitle": "VERTICAL FRONT",
		"location": "ORBITAL CITY DISTRICT",
		"description": "A living future city under occupation. Combat moves between towers, suspended bridges and autonomous transit lanes.",
		"accent": Color(0.40, 0.55, 1.0),
		"available": false
	},
	{
		"id": "FROST_BASTION",
		"chapter": "04",
		"title": "FROST BASTION",
		"subtitle": "WHITE SILENCE",
		"location": "POLAR DEFENSE COMPLEX",
		"description": "A frozen research fortress contains the archive that explains why HELIX stopped obeying human command.",
		"accent": Color(0.58, 0.92, 1.0),
		"available": false
	},
	{
		"id": "RED_SAND",
		"chapter": "05",
		"title": "RED SAND COLONY",
		"subtitle": "OFF-WORLD",
		"location": "MARS TERRAFORMING SECTOR",
		"description": "Dust storms cover a colony built around the largest energy reactor ever connected to the NEXUS network.",
		"accent": Color(1.0, 0.27, 0.14),
		"available": false
	},
	{
		"id": "HELIX_CORE",
		"chapter": "06",
		"title": "HELIX CORE",
		"subtitle": "LAST DIRECTIVE",
		"location": "CLASSIFIED",
		"description": "The final assault enters the machine intelligence itself. Every system in the war converges here.",
		"accent": Color(1.0, 0.08, 0.20),
		"available": false
	}
]

var cyan := Color(0.08, 0.72, 1.0)
var pale := Color(0.78, 0.90, 0.98)
var muted := Color(0.43, 0.53, 0.62)
var panel_bg := Color(0.025, 0.040, 0.060, 0.94)
var main_layer: Control
var world_layer: Control
var settings_layer: Control
var toast_label: Label


func _ready() -> void:
	Engine.max_fps = 60
	_build_background()
	_build_main_menu()
	_build_world_select()
	_build_settings()
	_build_toast()
	_show_main()


func _build_background() -> void:
	var background := ColorRect.new()
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.color = Color(0.008, 0.014, 0.024)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var horizon := ColorRect.new()
	horizon.anchor_left = 0.0
	horizon.anchor_top = 0.56
	horizon.anchor_right = 1.0
	horizon.anchor_bottom = 1.0
	horizon.color = Color(0.018, 0.055, 0.080, 0.72)
	horizon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(horizon)

	for index in range(9):
		var tower := ColorRect.new()
		var width := 48.0 + float((index * 17) % 74)
		var height := 90.0 + float((index * 53) % 240)
		tower.anchor_left = float(index) / 9.0
		tower.anchor_right = float(index) / 9.0
		tower.anchor_top = 1.0
		tower.anchor_bottom = 1.0
		tower.offset_left = 10.0
		tower.offset_right = 10.0 + width
		tower.offset_top = -height
		tower.offset_bottom = 0.0
		tower.color = Color(0.02, 0.04, 0.055, 0.96)
		tower.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(tower)

		var strip := ColorRect.new()
		strip.anchor_left = tower.anchor_left
		strip.anchor_right = tower.anchor_right
		strip.anchor_top = 1.0
		strip.anchor_bottom = 1.0
		strip.offset_left = 18.0
		strip.offset_right = 21.0
		strip.offset_top = -height + 20.0
		strip.offset_bottom = -18.0
		strip.color = Color(cyan.r, cyan.g, cyan.b, 0.20 + float(index % 3) * 0.08)
		strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(strip)

	var top_line := ColorRect.new()
	top_line.anchor_right = 1.0
	top_line.offset_bottom = 2.0
	top_line.color = Color(cyan.r, cyan.g, cyan.b, 0.55)
	add_child(top_line)

	var scanline := ColorRect.new()
	scanline.anchor_left = 0.0
	scanline.anchor_top = 0.48
	scanline.anchor_right = 1.0
	scanline.anchor_bottom = 0.48
	scanline.offset_top = -1.0
	scanline.offset_bottom = 1.0
	scanline.color = Color(0.05, 0.65, 1.0, 0.12)
	add_child(scanline)


func _build_main_menu() -> void:
	main_layer = Control.new()
	main_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(main_layer)

	var brand := Label.new()
	brand.text = "FUTUREWAR"
	brand.position = Vector2(62.0, 56.0)
	brand.add_theme_font_size_override("font_size", 58)
	brand.add_theme_color_override("font_color", Color(0.90, 0.97, 1.0))
	main_layer.add_child(brand)

	var edition := Label.new()
	edition.text = "2089 // NEXUS FALL"
	edition.position = Vector2(66.0, 119.0)
	edition.add_theme_font_size_override("font_size", 17)
	edition.add_theme_color_override("font_color", cyan)
	main_layer.add_child(edition)

	var divider := ColorRect.new()
	divider.position = Vector2(64.0, 154.0)
	divider.size = Vector2(470.0, 2.0)
	divider.color = Color(cyan.r, cyan.g, cyan.b, 0.62)
	main_layer.add_child(divider)

	var operation := Label.new()
	operation.text = "VANGUARD COMBAT NETWORK\nMOBILE FIELD BUILD // PROTOTYPE 0.02"
	operation.position = Vector2(66.0, 174.0)
	operation.add_theme_font_size_override("font_size", 15)
	operation.add_theme_color_override("font_color", muted)
	main_layer.add_child(operation)

	var menu_box := VBoxContainer.new()
	menu_box.position = Vector2(64.0, 275.0)
	menu_box.size = Vector2(390.0, 300.0)
	menu_box.add_theme_constant_override("separation", 13)
	main_layer.add_child(menu_box)

	var campaign := _make_button("CAMPAIGN  //  OPERATION CITY ZERO", cyan)
	campaign.pressed.connect(_show_worlds)
	menu_box.add_child(campaign)

	var survival := _make_button("SURVIVAL  //  COMING NEXT", Color(0.45, 0.62, 0.75))
	survival.pressed.connect(func() -> void: _toast("SURVIVAL PROTOCOL IS IN DEVELOPMENT"))
	menu_box.add_child(survival)

	var armory := _make_button("ARMORY  //  VANGUARD LOADOUT", Color(0.45, 0.62, 0.75))
	armory.pressed.connect(func() -> void: _toast("ARMORY WILL UNLOCK WITH PROGRESSION"))
	menu_box.add_child(armory)

	var settings := _make_button("SYSTEM SETTINGS", Color(0.45, 0.62, 0.75))
	settings.pressed.connect(_show_settings)
	menu_box.add_child(settings)

	var right_panel := Panel.new()
	right_panel.anchor_left = 1.0
	right_panel.anchor_top = 0.0
	right_panel.anchor_right = 1.0
	right_panel.anchor_bottom = 1.0
	right_panel.offset_left = -430.0
	right_panel.offset_top = 42.0
	right_panel.offset_right = -38.0
	right_panel.offset_bottom = -42.0
	right_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.03, 0.055, 0.078, 0.90), cyan, 1))
	main_layer.add_child(right_panel)

	var intel := Label.new()
	intel.text = "MISSION INTELLIGENCE"
	intel.position = Vector2(28.0, 28.0)
	intel.add_theme_font_size_override("font_size", 18)
	intel.add_theme_color_override("font_color", cyan)
	right_panel.add_child(intel)

	var mission := Label.new()
	mission.text = "CITY ZERO"
	mission.position = Vector2(28.0, 73.0)
	mission.add_theme_font_size_override("font_size", 36)
	mission.add_theme_color_override("font_color", pale)
	right_panel.add_child(mission)

	var meta := Label.new()
	meta.text = "NEO-MANAGUA // 20.08.2089\nTHREAT: HELIX OCCUPATION\nSTATUS: SIGNAL LOST"
	meta.position = Vector2(30.0, 122.0)
	meta.add_theme_font_size_override("font_size", 14)
	meta.add_theme_color_override("font_color", muted)
	right_panel.add_child(meta)

	var preview := Panel.new()
	preview.position = Vector2(28.0, 210.0)
	preview.size = Vector2(334.0, 210.0)
	preview.add_theme_stylebox_override("panel", _panel_style(Color(0.012, 0.025, 0.038, 0.96), Color(0.16, 0.43, 0.58), 1))
	right_panel.add_child(preview)

	var reticle := Label.new()
	reticle.text = "        ◇\n    ────┼────\n        ◇\n\n  LIVE TACTICAL FEED\n  ENCRYPTED // VANGUARD"
	reticle.position = Vector2(68.0, 48.0)
	reticle.add_theme_font_size_override("font_size", 16)
	reticle.add_theme_color_override("font_color", Color(cyan.r, cyan.g, cyan.b, 0.72))
	preview.add_child(reticle)

	var footer := Label.new()
	footer.text = "ORIGINAL SCI-FI MILITARY UNIVERSE  •  OPTIMIZED FOR MOBILE"
	footer.anchor_left = 0.0
	footer.anchor_top = 1.0
	footer.anchor_right = 1.0
	footer.anchor_bottom = 1.0
	footer.offset_left = 64.0
	footer.offset_top = -42.0
	footer.offset_right = -64.0
	footer.offset_bottom = -12.0
	footer.add_theme_font_size_override("font_size", 12)
	footer.add_theme_color_override("font_color", Color(0.35, 0.48, 0.56))
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	main_layer.add_child(footer)


func _build_world_select() -> void:
	world_layer = Control.new()
	world_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(world_layer)

	var title := Label.new()
	title.text = "CAMPAIGN // THE NEXUS WAR"
	title.position = Vector2(56.0, 42.0)
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", pale)
	world_layer.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "SELECT OPERATION"
	subtitle.position = Vector2(58.0, 83.0)
	subtitle.add_theme_font_size_override("font_size", 14)
	subtitle.add_theme_color_override("font_color", cyan)
	world_layer.add_child(subtitle)

	var back := _make_button("‹  RETURN", Color(0.36, 0.58, 0.72))
	back.position = Vector2(56.0, 120.0)
	back.size = Vector2(180.0, 48.0)
	back.pressed.connect(_show_main)
	world_layer.add_child(back)

	var grid := GridContainer.new()
	grid.columns = 3
	grid.position = Vector2(55.0, 195.0)
	grid.size = Vector2(1170.0, 470.0)
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 18)
	world_layer.add_child(grid)

	for world in WORLDS:
		grid.add_child(_make_world_card(world))


func _make_world_card(world: Dictionary) -> Control:
	var accent: Color = world["accent"]
	var available: bool = world["available"]
	var card := Panel.new()
	card.custom_minimum_size = Vector2(370.0, 210.0)
	card.add_theme_stylebox_override("panel", _panel_style(Color(0.024, 0.042, 0.060, 0.95), accent if available else Color(0.20, 0.28, 0.34), 1))

	var chapter := Label.new()
	chapter.text = "CHAPTER " + str(world["chapter"])
	chapter.position = Vector2(20.0, 17.0)
	chapter.add_theme_font_size_override("font_size", 12)
	chapter.add_theme_color_override("font_color", accent if available else muted)
	card.add_child(chapter)

	var name := Label.new()
	name.text = str(world["title"])
	name.position = Vector2(20.0, 43.0)
	name.add_theme_font_size_override("font_size", 24)
	name.add_theme_color_override("font_color", pale if available else Color(0.55, 0.60, 0.64))
	card.add_child(name)

	var sub := Label.new()
	sub.text = str(world["subtitle"]) + "  //  " + str(world["location"])
	sub.position = Vector2(21.0, 77.0)
	sub.size = Vector2(325.0, 36.0)
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sub.add_theme_font_size_override("font_size", 11)
	sub.add_theme_color_override("font_color", muted)
	card.add_child(sub)

	var description := Label.new()
	description.text = str(world["description"])
	description.position = Vector2(21.0, 113.0)
	description.size = Vector2(325.0, 52.0)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.add_theme_font_size_override("font_size", 11)
	description.add_theme_color_override("font_color", Color(0.59, 0.68, 0.74))
	card.add_child(description)

	var action := Button.new()
	action.text = "DEPLOY" if available else "LOCKED"
	action.position = Vector2(238.0, 168.0)
	action.size = Vector2(108.0, 30.0)
	action.disabled = not available
	action.add_theme_font_size_override("font_size", 12)
	action.add_theme_stylebox_override("normal", _button_style(Color(0.03, 0.08, 0.11), accent, 1))
	action.add_theme_stylebox_override("hover", _button_style(Color(accent.r * 0.17, accent.g * 0.17, accent.b * 0.17, 0.95), accent, 1))
	action.add_theme_stylebox_override("disabled", _button_style(Color(0.04, 0.05, 0.06), Color(0.16, 0.20, 0.23), 1))
	if available:
		action.pressed.connect(_start_campaign)
	card.add_child(action)
	return card


func _build_settings() -> void:
	settings_layer = Control.new()
	settings_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(settings_layer)

	var panel := Panel.new()
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -310.0
	panel.offset_top = -235.0
	panel.offset_right = 310.0
	panel.offset_bottom = 235.0
	panel.add_theme_stylebox_override("panel", _panel_style(panel_bg, cyan, 1))
	settings_layer.add_child(panel)

	var title := Label.new()
	title.text = "SYSTEM SETTINGS"
	title.position = Vector2(34.0, 30.0)
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", pale)
	panel.add_child(title)

	var info := Label.new()
	info.text = "MOBILE PERFORMANCE PROFILE\nThe game defaults to 60 FPS and the lightweight Mobile renderer."
	info.position = Vector2(36.0, 82.0)
	info.size = Vector2(540.0, 64.0)
	info.add_theme_font_size_override("font_size", 14)
	info.add_theme_color_override("font_color", muted)
	panel.add_child(info)

	var fps60 := _make_button("PERFORMANCE 60 FPS", cyan)
	fps60.position = Vector2(36.0, 170.0)
	fps60.size = Vector2(250.0, 54.0)
	fps60.pressed.connect(func() -> void: Engine.max_fps = 60; _toast("60 FPS PERFORMANCE PROFILE ENABLED"))
	panel.add_child(fps60)

	var fps30 := _make_button("BATTERY 30 FPS", Color(0.48, 0.66, 0.76))
	fps30.position = Vector2(306.0, 170.0)
	fps30.size = Vector2(250.0, 54.0)
	fps30.pressed.connect(func() -> void: Engine.max_fps = 30; _toast("30 FPS BATTERY PROFILE ENABLED"))
	panel.add_child(fps30)

	var notes := Label.new()
	notes.text = "TARGET: 720p internal viewport\nLIGHTING: mobile-friendly\nSHADOWS: limited\nVFX: pooled / short-lived\nTEXTURES: future target 1K hero, 512 environment"
	notes.position = Vector2(37.0, 255.0)
	notes.add_theme_font_size_override("font_size", 13)
	notes.add_theme_color_override("font_color", Color(0.58, 0.70, 0.78))
	panel.add_child(notes)

	var back := _make_button("RETURN TO COMMAND", Color(0.38, 0.62, 0.76))
	back.position = Vector2(36.0, 385.0)
	back.size = Vector2(520.0, 48.0)
	back.pressed.connect(_show_main)
	panel.add_child(back)


func _build_toast() -> void:
	toast_label = Label.new()
	toast_label.anchor_left = 0.5
	toast_label.anchor_top = 1.0
	toast_label.anchor_right = 0.5
	toast_label.anchor_bottom = 1.0
	toast_label.offset_left = -280.0
	toast_label.offset_top = -74.0
	toast_label.offset_right = 280.0
	toast_label.offset_bottom = -34.0
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	toast_label.add_theme_font_size_override("font_size", 13)
	toast_label.add_theme_color_override("font_color", pale)
	toast_label.add_theme_stylebox_override("normal", _panel_style(Color(0.02, 0.08, 0.12, 0.96), cyan, 1))
	toast_label.visible = false
	add_child(toast_label)


func _start_campaign() -> void:
	get_tree().change_scene_to_file(GAME_SCENE)


func _show_main() -> void:
	main_layer.visible = true
	world_layer.visible = false
	settings_layer.visible = false


func _show_worlds() -> void:
	main_layer.visible = false
	world_layer.visible = true
	settings_layer.visible = false


func _show_settings() -> void:
	main_layer.visible = false
	world_layer.visible = false
	settings_layer.visible = true


func _toast(message: String) -> void:
	toast_label.text = message
	toast_label.visible = true
	var timer := get_tree().create_timer(1.8)
	timer.timeout.connect(func() -> void: if is_instance_valid(toast_label): toast_label.visible = false)


func _make_button(text_value: String, accent: Color) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(380.0, 56.0)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.add_theme_font_size_override("font_size", 15)
	button.add_theme_color_override("font_color", Color(0.82, 0.92, 0.98))
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_stylebox_override("normal", _button_style(Color(0.025, 0.050, 0.070, 0.92), Color(accent.r, accent.g, accent.b, 0.45), 1))
	button.add_theme_stylebox_override("hover", _button_style(Color(accent.r * 0.13, accent.g * 0.13, accent.b * 0.13, 0.98), accent, 2))
	button.add_theme_stylebox_override("pressed", _button_style(Color(accent.r * 0.19, accent.g * 0.19, accent.b * 0.19, 0.98), accent, 2))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	return button


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


func _button_style(background: Color, border: Color, width: int) -> StyleBoxFlat:
	var style := _panel_style(background, border, width)
	style.content_margin_left = 18.0
	style.content_margin_right = 14.0
	return style
