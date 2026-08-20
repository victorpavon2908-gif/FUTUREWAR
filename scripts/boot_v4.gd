extends Control

const WORLDS: Array[Dictionary] = [
	{
		"chapter": "01",
		"title": "COASTLINE FORTRESS",
		"subtitle": "BROKEN TIDE",
		"location": "PACIFIC CLIFF NETWORK",
		"description": "Primary production world. Ocean cliffs, a flooded command lagoon, radial bridges, batteries and a monumental HELIX core.",
		"scene": "res://scenes/coastline_fortress.tscn",
		"available": true,
		"accent": Color(0.06, 0.72, 1.0)
	},
	{
		"chapter": "02",
		"title": "ASTER VALLEY",
		"subtitle": "FIRST CONTACT",
		"location": "ALPINE FRONTIER",
		"description": "Legacy alpine combat prototype retained for gameplay comparison while its final art pass is rebuilt later.",
		"scene": "res://scenes/aster_valley.tscn",
		"available": true,
		"accent": Color(0.18, 0.88, 0.72)
	},
	{
		"chapter": "03",
		"title": "RIFT CANYON",
		"subtitle": "THREE LEVELS",
		"location": "TECTONIC DEFENSE CORRIDOR",
		"description": "Stacked canyon routes: floor, bridge and ridge combat.",
		"scene": "",
		"available": false,
		"accent": Color(0.92, 0.42, 0.12)
	},
	{
		"chapter": "04",
		"title": "FROST RANGE",
		"subtitle": "WHITE SIGNAL",
		"location": "POLAR MEGASTRUCTURE BELT",
		"description": "Frozen valleys, giant bridges and repeated vertical landmarks.",
		"scene": "",
		"available": false,
		"accent": Color(0.68, 0.92, 1.0)
	},
	{
		"chapter": "05",
		"title": "NOVA CITY",
		"subtitle": "NEON SIEGE",
		"location": "METROPOLITAN ARC",
		"description": "Dense futuristic city combat with skyways and vertical districts.",
		"scene": "",
		"available": false,
		"accent": Color(0.56, 0.48, 1.0)
	},
	{
		"chapter": "06",
		"title": "HELIX ASCENT",
		"subtitle": "LAST DIRECTIVE",
		"location": "CLASSIFIED MEGASTRUCTURE",
		"description": "Final assault above the clouds.",
		"scene": "",
		"available": false,
		"accent": Color(1.0, 0.14, 0.20)
	}
]

var selected_world: int = 0
var title_label: Label
var subtitle_label: Label
var location_label: Label
var description_label: Label
var deploy_button: Button
var status_label: Label
var world_buttons: Array[Button] = []
var cyan: Color = Color(0.07, 0.78, 1.0)
var pale: Color = Color(0.90, 0.97, 1.0)


func _ready() -> void:
	Engine.max_fps = 30
	_build_background()
	_build_ui()
	_select_world(0)


func _build_background() -> void:
	var sky: ColorRect = ColorRect.new()
	sky.set_anchors_preset(Control.PRESET_FULL_RECT)
	sky.color = Color(0.055, 0.15, 0.26)
	sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sky)

	var sea: ColorRect = ColorRect.new()
	sea.anchor_top = 0.55
	sea.anchor_right = 1.0
	sea.anchor_bottom = 1.0
	sea.color = Color(0.018, 0.08, 0.12)
	sea.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sea)

	var glow: ColorRect = ColorRect.new()
	glow.anchor_left = 0.50
	glow.anchor_top = 0.0
	glow.anchor_right = 0.50
	glow.anchor_bottom = 1.0
	glow.offset_left = -2.0
	glow.offset_right = 2.0
	glow.color = Color(cyan.r, cyan.g, cyan.b, 0.16)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(glow)


func _build_ui() -> void:
	var brand: Label = Label.new()
	brand.text = "FUTUREWAR"
	brand.position = Vector2(42.0, 28.0)
	brand.add_theme_font_size_override("font_size", 46)
	brand.add_theme_color_override("font_color", pale)
	add_child(brand)

	var sub: Label = Label.new()
	sub.text = "2089 // VANGUARD EXPEDITIONARY COMMAND"
	sub.position = Vector2(46.0, 78.0)
	sub.add_theme_font_size_override("font_size", 13)
	sub.add_theme_color_override("font_color", cyan)
	add_child(sub)

	var left: Panel = Panel.new()
	left.position = Vector2(36.0, 120.0)
	left.size = Vector2(390.0, 540.0)
	left.add_theme_stylebox_override("panel", _panel_style(Color(0.008, 0.025, 0.035, 0.94), Color(0.08, 0.42, 0.55, 0.72), 1))
	add_child(left)

	var stack: VBoxContainer = VBoxContainer.new()
	stack.position = Vector2(16.0, 18.0)
	stack.size = Vector2(358.0, 500.0)
	stack.add_theme_constant_override("separation", 8)
	left.add_child(stack)

	for i: int in range(WORLDS.size()):
		var world: Dictionary = WORLDS[i]
		var button: Button = Button.new()
		button.text = "%s  //  %s\n%s" % [world["chapter"], world["title"], world["subtitle"]]
		button.custom_minimum_size = Vector2(358.0, 68.0)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.add_theme_font_size_override("font_size", 13)
		button.add_theme_color_override("font_color", pale if bool(world["available"]) else Color(0.42, 0.50, 0.53))
		button.add_theme_stylebox_override("normal", _panel_style(Color(0.018, 0.050, 0.062, 0.94), Color(0.10, 0.22, 0.27, 0.92), 1))
		button.add_theme_stylebox_override("hover", _panel_style(Color(0.025, 0.10, 0.13, 0.96), world["accent"] as Color, 2))
		button.add_theme_stylebox_override("pressed", _panel_style(Color(0.04, 0.15, 0.18, 1.0), world["accent"] as Color, 2))
		button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		button.pressed.connect(_select_world.bind(i))
		stack.add_child(button)
		world_buttons.append(button)

	var right: Panel = Panel.new()
	right.position = Vector2(458.0, 120.0)
	right.size = Vector2(786.0, 540.0)
	right.add_theme_stylebox_override("panel", _panel_style(Color(0.007, 0.020, 0.030, 0.94), Color(0.12, 0.32, 0.40, 0.80), 1))
	add_child(right)

	var kicker: Label = Label.new()
	kicker.text = "ACTIVE PRODUCTION WORLD"
	kicker.position = Vector2(30.0, 28.0)
	kicker.add_theme_font_size_override("font_size", 12)
	kicker.add_theme_color_override("font_color", cyan)
	right.add_child(kicker)

	title_label = Label.new()
	title_label.position = Vector2(30.0, 60.0)
	title_label.size = Vector2(720.0, 52.0)
	title_label.add_theme_font_size_override("font_size", 36)
	title_label.add_theme_color_override("font_color", pale)
	right.add_child(title_label)

	subtitle_label = Label.new()
	subtitle_label.position = Vector2(32.0, 112.0)
	subtitle_label.size = Vector2(710.0, 30.0)
	subtitle_label.add_theme_font_size_override("font_size", 17)
	subtitle_label.add_theme_color_override("font_color", cyan)
	right.add_child(subtitle_label)

	location_label = Label.new()
	location_label.position = Vector2(32.0, 153.0)
	location_label.size = Vector2(710.0, 24.0)
	location_label.add_theme_font_size_override("font_size", 12)
	location_label.add_theme_color_override("font_color", Color(0.62, 0.76, 0.81))
	right.add_child(location_label)

	description_label = Label.new()
	description_label.position = Vector2(32.0, 205.0)
	description_label.size = Vector2(710.0, 120.0)
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description_label.add_theme_font_size_override("font_size", 17)
	description_label.add_theme_color_override("font_color", Color(0.80, 0.88, 0.91))
	right.add_child(description_label)

	var production: Label = Label.new()
	production.text = "PRODUCTION PASS\n• procedural cliff geology\n• animated ocean shader\n• panelized HELIX architecture\n• compact HUD\n• slimmer VX-7 first-person model\n• mobile target: cinematic 30 FPS"
	production.position = Vector2(32.0, 340.0)
	production.add_theme_font_size_override("font_size", 14)
	production.add_theme_color_override("font_color", Color(0.54, 0.72, 0.74))
	right.add_child(production)

	deploy_button = Button.new()
	deploy_button.position = Vector2(32.0, 455.0)
	deploy_button.size = Vector2(505.0, 60.0)
	deploy_button.add_theme_font_size_override("font_size", 18)
	deploy_button.add_theme_color_override("font_color", Color.WHITE)
	deploy_button.add_theme_stylebox_override("normal", _panel_style(Color(0.015, 0.30, 0.39, 0.98), cyan, 2))
	deploy_button.add_theme_stylebox_override("hover", _panel_style(Color(0.025, 0.43, 0.51, 1.0), Color(0.45, 0.96, 1.0), 2))
	deploy_button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	deploy_button.pressed.connect(_deploy)
	right.add_child(deploy_button)

	var fps_button: Button = Button.new()
	fps_button.position = Vector2(555.0, 455.0)
	fps_button.size = Vector2(185.0, 60.0)
	fps_button.text = "30 / 60 FPS"
	fps_button.add_theme_font_size_override("font_size", 14)
	fps_button.add_theme_stylebox_override("normal", _panel_style(Color(0.025, 0.07, 0.085, 0.96), Color(0.24, 0.42, 0.48), 1))
	fps_button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	fps_button.pressed.connect(_toggle_fps)
	right.add_child(fps_button)

	status_label = Label.new()
	status_label.anchor_left = 0.5
	status_label.anchor_top = 1.0
	status_label.anchor_right = 0.5
	status_label.anchor_bottom = 1.0
	status_label.offset_left = -390.0
	status_label.offset_top = -34.0
	status_label.offset_right = 390.0
	status_label.offset_bottom = -8.0
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 12)
	status_label.add_theme_color_override("font_color", Color(0.70, 0.86, 0.90))
	add_child(status_label)


func _select_world(index: int) -> void:
	selected_world = clampi(index, 0, WORLDS.size() - 1)
	var world: Dictionary = WORLDS[selected_world]
	title_label.text = world["title"]
	subtitle_label.text = "%s // CHAPTER %s" % [world["subtitle"], world["chapter"]]
	location_label.text = world["location"]
	description_label.text = world["description"]
	deploy_button.disabled = not bool(world["available"])
	deploy_button.text = "DEPLOY TO %s" % world["title"] if bool(world["available"]) else "WORLD LOCKED // IN PRODUCTION"
	status_label.text = "COASTLINE FORTRESS IS THE CURRENT VISUAL PRODUCTION TARGET" if selected_world == 0 else "%s SELECTED" % world["title"]
	for i: int in range(world_buttons.size()):
		world_buttons[i].modulate = Color.WHITE if i == selected_world else Color(0.78, 0.83, 0.85)


func _deploy() -> void:
	var world: Dictionary = WORLDS[selected_world]
	if not bool(world["available"]):
		return
	var scene_path: String = String(world["scene"])
	if scene_path.is_empty():
		return
	status_label.text = "DEPLOYMENT AUTHORIZED // %s" % world["title"]
	get_tree().change_scene_to_file(scene_path)


func _toggle_fps() -> void:
	Engine.max_fps = 60 if Engine.max_fps == 30 else 30
	status_label.text = "%d FPS PROFILE ACTIVE" % Engine.max_fps


func _panel_style(bg: Color, border: Color, width: int) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(width)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 12.0
	style.content_margin_right = 12.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0
	return style
