extends Control

const WORLDS: Array[Dictionary] = [
	{
		"chapter": "01",
		"title": "ASTER VALLEY",
		"subtitle": "FIRST CONTACT",
		"location": "ALPINE FRONTIER // EARTH",
		"description": "A broad mountain basin built around long sightlines, forested walls and sparse monumental technology. The redesign studies classic open-valley pacing while keeping FUTUREWAR geometry original.",
		"scene": "res://scenes/main.tscn",
		"available": true,
		"accent": Color(0.10, 0.80, 0.95)
	},
	{
		"chapter": "02",
		"title": "COASTLINE FORTRESS",
		"subtitle": "BROKEN TIDE",
		"location": "PACIFIC CLIFF NETWORK",
		"description": "A cliff island surrounded by open ocean. A HELIX command core spans a flooded lagoon with radial bridges, elevated batteries and a northern monolith. Built as an original level from the uploaded coastal-map design lessons.",
		"scene": "res://scenes/coastline_fortress.tscn",
		"available": true,
		"accent": Color(0.10, 0.62, 1.0)
	},
	{
		"chapter": "03",
		"title": "RIFT CANYON",
		"subtitle": "THREE LEVELS",
		"location": "TECTONIC DEFENSE CORRIDOR",
		"description": "A stacked canyon front with floor, bridge and ridge combat routes. Navigation uses strong faction beacons and distant city silhouettes.",
		"scene": "",
		"available": false,
		"accent": Color(0.82, 0.42, 0.16)
	},
	{
		"chapter": "04",
		"title": "FROST RANGE",
		"subtitle": "WHITE SIGNAL",
		"location": "POLAR MEGASTRUCTURE BELT",
		"description": "Snow fields, ravines and colossal bridge structures repeatedly reveal the same HELIX tower from new angles.",
		"scene": "",
		"available": false,
		"accent": Color(0.66, 0.92, 1.0)
	},
	{
		"chapter": "05",
		"title": "NOVA CITY",
		"subtitle": "NEON SIEGE",
		"location": "METROPOLITAN ARC",
		"description": "A dense futuristic capital with skyways, monorails and vertical combat districts.",
		"scene": "",
		"available": false,
		"accent": Color(0.54, 0.48, 1.0)
	},
	{
		"chapter": "06",
		"title": "HELIX ASCENT",
		"subtitle": "LAST DIRECTIVE",
		"location": "CLASSIFIED MEGASTRUCTURE",
		"description": "The final assault climbs a machine citadel above the clouds.",
		"scene": "",
		"available": false,
		"accent": Color(1.0, 0.13, 0.20)
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

var cyan: Color = Color(0.08, 0.79, 0.98)
var pale: Color = Color(0.90, 0.97, 1.0)
var muted: Color = Color(0.53, 0.66, 0.70)


func _ready() -> void:
	Engine.max_fps = 30
	_build_background()
	_build_ui()
	_select_world(0)


func _build_background() -> void:
	var sky: ColorRect = ColorRect.new()
	sky.set_anchors_preset(Control.PRESET_FULL_RECT)
	sky.color = Color(0.16, 0.42, 0.67)
	sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sky)

	var horizon: ColorRect = ColorRect.new()
	horizon.anchor_top = 0.47
	horizon.anchor_right = 1.0
	horizon.anchor_bottom = 1.0
	horizon.color = Color(0.12, 0.24, 0.23)
	horizon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(horizon)

	_add_mountain(PackedVector2Array([Vector2(0, 430), Vector2(130, 210), Vector2(235, 355), Vector2(390, 120), Vector2(515, 365), Vector2(705, 175), Vector2(850, 360), Vector2(1030, 110), Vector2(1280, 390), Vector2(1280, 720), Vector2(0, 720)]), Color(0.26, 0.35, 0.37))
	_add_mountain(PackedVector2Array([Vector2(0, 520), Vector2(180, 350), Vector2(330, 490), Vector2(500, 305), Vector2(680, 480), Vector2(905, 330), Vector2(1090, 485), Vector2(1280, 350), Vector2(1280, 720), Vector2(0, 720)]), Color(0.12, 0.23, 0.23))
	_add_mountain(PackedVector2Array([Vector2(0, 600), Vector2(170, 530), Vector2(370, 582), Vector2(570, 510), Vector2(760, 582), Vector2(970, 510), Vector2(1160, 575), Vector2(1280, 525), Vector2(1280, 720), Vector2(0, 720)]), Color(0.055, 0.12, 0.13))

	var sea_band: ColorRect = ColorRect.new()
	sea_band.anchor_top = 0.66
	sea_band.anchor_right = 1.0
	sea_band.anchor_bottom = 1.0
	sea_band.color = Color(0.025, 0.15, 0.22, 0.45)
	sea_band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sea_band)

	var overlay: ColorRect = ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.006, 0.018, 0.026, 0.38)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)

	var top_line: ColorRect = ColorRect.new()
	top_line.anchor_right = 1.0
	top_line.offset_bottom = 3.0
	top_line.color = Color(cyan.r, cyan.g, cyan.b, 0.78)
	top_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(top_line)


func _add_mountain(points: PackedVector2Array, color: Color) -> void:
	var poly: Polygon2D = Polygon2D.new()
	poly.polygon = points
	poly.color = color
	add_child(poly)


func _build_ui() -> void:
	var brand: Label = Label.new()
	brand.text = "FUTUREWAR"
	brand.position = Vector2(42.0, 26.0)
	brand.add_theme_font_size_override("font_size", 48)
	brand.add_theme_color_override("font_color", pale)
	add_child(brand)

	var subbrand: Label = Label.new()
	subbrand.text = "2089 // VANGUARD EXPEDITIONARY COMMAND"
	subbrand.position = Vector2(46.0, 78.0)
	subbrand.add_theme_font_size_override("font_size", 13)
	subbrand.add_theme_color_override("font_color", cyan)
	add_child(subbrand)

	var profile: Label = Label.new()
	profile.text = "REFERENCE-DRIVEN WORLD PASS // CINEMATIC 30 FPS"
	profile.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	profile.offset_left = -430.0
	profile.offset_top = 38.0
	profile.offset_right = -36.0
	profile.offset_bottom = 65.0
	profile.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	profile.add_theme_font_size_override("font_size", 12)
	profile.add_theme_color_override("font_color", Color(0.70, 0.84, 0.87))
	add_child(profile)

	var left: Panel = Panel.new()
	left.position = Vector2(34.0, 116.0)
	left.size = Vector2(420.0, 558.0)
	left.add_theme_stylebox_override("panel", _panel_style(Color(0.012, 0.035, 0.042, 0.92), Color(cyan.r, cyan.g, cyan.b, 0.40), 2))
	add_child(left)

	var campaign: Label = Label.new()
	campaign.text = "CAMPAIGN WORLDS"
	campaign.position = Vector2(20.0, 16.0)
	campaign.add_theme_font_size_override("font_size", 15)
	campaign.add_theme_color_override("font_color", cyan)
	left.add_child(campaign)

	var stack: VBoxContainer = VBoxContainer.new()
	stack.position = Vector2(17.0, 51.0)
	stack.size = Vector2(386.0, 455.0)
	stack.add_theme_constant_override("separation", 8)
	left.add_child(stack)

	for i: int in range(WORLDS.size()):
		var world: Dictionary = WORLDS[i]
		var button: Button = Button.new()
		button.text = "%s  //  %s\n%s" % [world["chapter"], world["title"], world["subtitle"]]
		button.custom_minimum_size = Vector2(386.0, 65.0)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.add_theme_font_size_override("font_size", 13)
		button.add_theme_color_override("font_color", pale if bool(world["available"]) else Color(0.46, 0.55, 0.58))
		button.add_theme_stylebox_override("normal", _panel_style(Color(0.024, 0.061, 0.067, 0.82), Color(0.14, 0.27, 0.29, 0.72), 1))
		button.add_theme_stylebox_override("hover", _panel_style(Color(0.035, 0.11, 0.12, 0.92), world["accent"] as Color, 1))
		button.add_theme_stylebox_override("pressed", _panel_style(Color(0.05, 0.14, 0.15, 0.97), world["accent"] as Color, 2))
		button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		button.pressed.connect(_select_world.bind(i))
		stack.add_child(button)
		world_buttons.append(button)

	var right: Panel = Panel.new()
	right.position = Vector2(486.0, 116.0)
	right.size = Vector2(758.0, 558.0)
	right.add_theme_stylebox_override("panel", _panel_style(Color(0.010, 0.027, 0.036, 0.90), Color(0.18, 0.40, 0.44, 0.62), 2))
	add_child(right)

	var selected: Label = Label.new()
	selected.text = "SELECTED OPERATION"
	selected.position = Vector2(28.0, 24.0)
	selected.add_theme_font_size_override("font_size", 12)
	selected.add_theme_color_override("font_color", cyan)
	right.add_child(selected)

	title_label = Label.new()
	title_label.position = Vector2(28.0, 53.0)
	title_label.size = Vector2(700.0, 52.0)
	title_label.add_theme_font_size_override("font_size", 38)
	title_label.add_theme_color_override("font_color", pale)
	right.add_child(title_label)

	subtitle_label = Label.new()
	subtitle_label.position = Vector2(31.0, 105.0)
	subtitle_label.size = Vector2(690.0, 30.0)
	subtitle_label.add_theme_font_size_override("font_size", 17)
	subtitle_label.add_theme_color_override("font_color", cyan)
	right.add_child(subtitle_label)

	location_label = Label.new()
	location_label.position = Vector2(31.0, 150.0)
	location_label.size = Vector2(690.0, 24.0)
	location_label.add_theme_font_size_override("font_size", 12)
	location_label.add_theme_color_override("font_color", Color(0.64, 0.77, 0.80))
	right.add_child(location_label)

	var separator: ColorRect = ColorRect.new()
	separator.position = Vector2(30.0, 188.0)
	separator.size = Vector2(698.0, 2.0)
	separator.color = Color(cyan.r, cyan.g, cyan.b, 0.32)
	right.add_child(separator)

	description_label = Label.new()
	description_label.position = Vector2(31.0, 214.0)
	description_label.size = Vector2(680.0, 122.0)
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description_label.add_theme_font_size_override("font_size", 16)
	description_label.add_theme_color_override("font_color", Color(0.79, 0.88, 0.90))
	right.add_child(description_label)

	var study: Label = Label.new()
	study.text = "LEVEL-DESIGN STUDY APPLIED\n• open-valley sightline discipline\n• water / cliff world boundaries\n• monumental bridge + tower silhouettes\n• two-endpoint readability\n• stacked floor / bridge / ridge routes\n• shipping geometry remains original FUTUREWAR work"
	study.position = Vector2(31.0, 350.0)
	study.add_theme_font_size_override("font_size", 13)
	study.add_theme_color_override("font_color", Color(0.57, 0.74, 0.72))
	right.add_child(study)

	deploy_button = Button.new()
	deploy_button.position = Vector2(31.0, 470.0)
	deploy_button.size = Vector2(478.0, 62.0)
	deploy_button.add_theme_font_size_override("font_size", 17)
	deploy_button.add_theme_color_override("font_color", Color.WHITE)
	deploy_button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	deploy_button.pressed.connect(_deploy)
	right.add_child(deploy_button)

	var quality: Button = Button.new()
	quality.position = Vector2(526.0, 470.0)
	quality.size = Vector2(202.0, 62.0)
	quality.text = "FPS PROFILE\n30 ↔ 60"
	quality.add_theme_font_size_override("font_size", 13)
	quality.add_theme_stylebox_override("normal", _panel_style(Color(0.04, 0.09, 0.10, 0.94), Color(0.31, 0.50, 0.52), 1))
	quality.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	quality.pressed.connect(_toggle_fps)
	right.add_child(quality)

	status_label = Label.new()
	status_label.anchor_left = 0.5
	status_label.anchor_top = 1.0
	status_label.anchor_right = 0.5
	status_label.anchor_bottom = 1.0
	status_label.offset_left = -390.0
	status_label.offset_top = -35.0
	status_label.offset_right = 390.0
	status_label.offset_bottom = -10.0
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 12)
	status_label.add_theme_color_override("font_color", Color(0.72, 0.88, 0.86))
	add_child(status_label)


func _select_world(index: int) -> void:
	selected_world = clampi(index, 0, WORLDS.size() - 1)
	var world: Dictionary = WORLDS[selected_world]
	title_label.text = String(world["title"])
	subtitle_label.text = "%s // CHAPTER %s" % [world["subtitle"], world["chapter"]]
	location_label.text = String(world["location"])
	description_label.text = String(world["description"])
	var available: bool = bool(world["available"])
	deploy_button.disabled = not available
	deploy_button.text = "DEPLOY TO %s" % world["title"] if available else "WORLD LOCKED // IN PRODUCTION"
	var accent: Color = world["accent"] as Color
	deploy_button.add_theme_stylebox_override("normal", _panel_style(Color(accent.r * 0.18, accent.g * 0.18, accent.b * 0.18, 0.96), accent, 2))
	deploy_button.add_theme_stylebox_override("hover", _panel_style(Color(accent.r * 0.28, accent.g * 0.28, accent.b * 0.28, 1.0), accent.lightened(0.18), 2))
	status_label.text = "%s READY FOR FIELD TEST" % world["title"] if available else "%s IS DEFINED FOR FUTURE PRODUCTION" % world["title"]

	for i: int in range(world_buttons.size()):
		world_buttons[i].modulate = Color.WHITE if i == selected_world else Color(0.84, 0.89, 0.90)


func _deploy() -> void:
	var world: Dictionary = WORLDS[selected_world]
	if not bool(world["available"]):
		return
	status_label.text = "DEPLOYMENT AUTHORIZED // %s" % world["title"]
	get_tree().change_scene_to_file(String(world["scene"]))


func _toggle_fps() -> void:
	Engine.max_fps = 60 if Engine.max_fps == 30 else 30
	status_label.text = "%d FPS PROFILE ACTIVE // PROFILE ON PHYSICAL ANDROID HARDWARE" % Engine.max_fps


func _panel_style(bg: Color, border: Color, width: int) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(width)
	style.corner_radius_top_left = 3
	style.corner_radius_top_right = 3
	style.corner_radius_bottom_left = 3
	style.corner_radius_bottom_right = 3
	style.content_margin_left = 12.0
	style.content_margin_right = 12.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0
	return style
