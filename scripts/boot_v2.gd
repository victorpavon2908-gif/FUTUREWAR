extends Control

const GAME_SCENE := "res://scenes/main.tscn"

const WORLDS := [
	{
		"chapter": "01",
		"title": "ASTER VALLEY",
		"subtitle": "FIRST CONTACT",
		"location": "MOUNTAIN FRONTIER // EARTH",
		"description": "A vast alpine valley where VANGUARD defenses, rivers and forested cliffs collide with a new HELIX occupation fortress. Breach the outpost and reopen the mountain corridor.",
		"accent": Color(0.12, 0.78, 0.92),
		"available": true
	},
	{
		"chapter": "02",
		"title": "COASTLINE FORTRESS",
		"subtitle": "BROKEN TIDE",
		"location": "PACIFIC CLIFF NETWORK",
		"description": "Ocean cliffs, suspended bridges and military platforms form a vertical battlefield above a violent sea.",
		"accent": Color(0.10, 0.56, 0.92),
		"available": false
	},
	{
		"chapter": "03",
		"title": "NOVA CITY",
		"subtitle": "NEON SIEGE",
		"location": "METROPOLITAN ARC",
		"description": "A living future city under occupation: towers, skyways, monorails and plazas become the largest urban front of the war.",
		"accent": Color(0.42, 0.48, 1.0),
		"available": false
	},
	{
		"chapter": "04",
		"title": "FROST RANGE",
		"subtitle": "WHITE SIGNAL",
		"location": "POLAR RESEARCH BELT",
		"description": "Frozen valleys and buried laboratories hide the archive that explains the origin of the HELIX directive.",
		"accent": Color(0.62, 0.91, 1.0),
		"available": false
	},
	{
		"chapter": "05",
		"title": "RED DESERT FRONT",
		"subtitle": "COLONY WAR",
		"location": "MARS TERRAFORMING ZONE",
		"description": "Red canyons, dust storms and industrial colonies surround the reactor feeding the NEXUS war network.",
		"accent": Color(1.0, 0.35, 0.12),
		"available": false
	},
	{
		"chapter": "06",
		"title": "HELIX ASCENT",
		"subtitle": "LAST DIRECTIVE",
		"location": "CLASSIFIED MEGASTRUCTURE",
		"description": "The final assault climbs a machine citadel suspended above the clouds. Every surviving faction converges on the HELIX core.",
		"accent": Color(1.0, 0.12, 0.20),
		"available": false
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

var cyan: Color = Color(0.09, 0.78, 0.96)
var pale: Color = Color(0.88, 0.96, 1.0)
var muted: Color = Color(0.48, 0.61, 0.67)


func _ready() -> void:
	Engine.max_fps = 30
	_build_background()
	_build_command_ui()
	_select_world(0)


func _build_background() -> void:
	var sky: ColorRect = ColorRect.new()
	sky.set_anchors_preset(Control.PRESET_FULL_RECT)
	sky.color = Color(0.20, 0.48, 0.72)
	sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sky)

	var horizon: ColorRect = ColorRect.new()
	horizon.anchor_top = 0.48
	horizon.anchor_right = 1.0
	horizon.anchor_bottom = 1.0
	horizon.color = Color(0.19, 0.30, 0.29)
	horizon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(horizon)

	_add_mountain(
		[Vector2(0, 430), Vector2(145, 155), Vector2(255, 340), Vector2(390, 105), Vector2(555, 370), Vector2(690, 195), Vector2(860, 370), Vector2(1045, 130), Vector2(1280, 390), Vector2(1280, 720), Vector2(0, 720)],
		Color(0.25, 0.34, 0.36)
	)
	_add_mountain(
		[Vector2(0, 505), Vector2(180, 335), Vector2(320, 480), Vector2(520, 292), Vector2(720, 475), Vector2(935, 315), Vector2(1125, 485), Vector2(1280, 335), Vector2(1280, 720), Vector2(0, 720)],
		Color(0.14, 0.23, 0.22)
	)
	_add_mountain(
		[Vector2(0, 590), Vector2(180, 520), Vector2(370, 572), Vector2(565, 500), Vector2(760, 575), Vector2(960, 505), Vector2(1150, 565), Vector2(1280, 510), Vector2(1280, 720), Vector2(0, 720)],
		Color(0.07, 0.14, 0.13)
	)

	var mist: ColorRect = ColorRect.new()
	mist.anchor_top = 0.37
	mist.anchor_right = 1.0
	mist.anchor_bottom = 0.62
	mist.color = Color(0.67, 0.82, 0.86, 0.13)
	mist.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(mist)

	var overlay: ColorRect = ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.006, 0.018, 0.025, 0.34)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)

	var top_bar: ColorRect = ColorRect.new()
	top_bar.anchor_right = 1.0
	top_bar.offset_bottom = 3.0
	top_bar.color = Color(cyan.r, cyan.g, cyan.b, 0.72)
	top_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(top_bar)


func _add_mountain(points: Array[Vector2], color: Color) -> void:
	var poly: Polygon2D = Polygon2D.new()
	poly.polygon = PackedVector2Array(points)
	poly.color = color
	# Polygon2D is a CanvasItem, not a Control. It has no mouse_filter property.
	add_child(poly)


func _build_command_ui() -> void:
	var brand: Label = Label.new()
	brand.text = "FUTUREWAR"
	brand.position = Vector2(44.0, 30.0)
	brand.add_theme_font_size_override("font_size", 48)
	brand.add_theme_color_override("font_color", pale)
	add_child(brand)

	var edition: Label = Label.new()
	edition.text = "2089 // VANGUARD EXPEDITIONARY COMMAND"
	edition.position = Vector2(48.0, 82.0)
	edition.add_theme_font_size_override("font_size", 13)
	edition.add_theme_color_override("font_color", cyan)
	add_child(edition)

	var fps: Label = Label.new()
	fps.text = "CINEMATIC MOBILE PROFILE // 30 FPS"
	fps.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	fps.offset_left = -345.0
	fps.offset_top = 42.0
	fps.offset_right = -36.0
	fps.offset_bottom = 72.0
	fps.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	fps.add_theme_font_size_override("font_size", 12)
	fps.add_theme_color_override("font_color", Color(0.68, 0.82, 0.84))
	add_child(fps)

	var left: Panel = Panel.new()
	left.position = Vector2(38.0, 125.0)
	left.size = Vector2(420.0, 548.0)
	left.add_theme_stylebox_override("panel", _panel_style(Color(0.015, 0.038, 0.043, 0.90), Color(cyan.r, cyan.g, cyan.b, 0.42), 2))
	add_child(left)

	var campaign_label: Label = Label.new()
	campaign_label.text = "CAMPAIGN WORLDS"
	campaign_label.position = Vector2(22.0, 18.0)
	campaign_label.add_theme_font_size_override("font_size", 15)
	campaign_label.add_theme_color_override("font_color", cyan)
	left.add_child(campaign_label)

	var stack: VBoxContainer = VBoxContainer.new()
	stack.position = Vector2(18.0, 55.0)
	stack.size = Vector2(384.0, 420.0)
	stack.add_theme_constant_override("separation", 8)
	left.add_child(stack)

	for i: int in range(WORLDS.size()):
		var world: Dictionary = WORLDS[i]
		var button: Button = Button.new()
		button.text = "%s  //  %s\n%s" % [world["chapter"], world["title"], world["subtitle"]]
		button.custom_minimum_size = Vector2(384.0, 62.0)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.add_theme_font_size_override("font_size", 13)
		button.add_theme_color_override("font_color", pale if bool(world["available"]) else Color(0.48, 0.57, 0.59))
		button.add_theme_stylebox_override("normal", _panel_style(Color(0.025, 0.065, 0.066, 0.80), Color(0.16, 0.28, 0.29, 0.72), 1))
		button.add_theme_stylebox_override("hover", _panel_style(Color(0.035, 0.11, 0.12, 0.90), world["accent"] as Color, 1))
		button.add_theme_stylebox_override("pressed", _panel_style(Color(0.05, 0.14, 0.15, 0.96), world["accent"] as Color, 2))
		button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		button.pressed.connect(_select_world.bind(i))
		stack.add_child(button)
		world_buttons.append(button)

	var right: Panel = Panel.new()
	right.position = Vector2(490.0, 125.0)
	right.size = Vector2(752.0, 548.0)
	right.add_theme_stylebox_override("panel", _panel_style(Color(0.012, 0.031, 0.038, 0.88), Color(0.20, 0.42, 0.44, 0.62), 2))
	add_child(right)

	var chapter_label: Label = Label.new()
	chapter_label.text = "SELECTED OPERATION"
	chapter_label.position = Vector2(28.0, 24.0)
	chapter_label.add_theme_font_size_override("font_size", 12)
	chapter_label.add_theme_color_override("font_color", cyan)
	right.add_child(chapter_label)

	title_label = Label.new()
	title_label.position = Vector2(28.0, 52.0)
	title_label.size = Vector2(690.0, 54.0)
	title_label.add_theme_font_size_override("font_size", 38)
	title_label.add_theme_color_override("font_color", pale)
	right.add_child(title_label)

	subtitle_label = Label.new()
	subtitle_label.position = Vector2(31.0, 104.0)
	subtitle_label.size = Vector2(680.0, 30.0)
	subtitle_label.add_theme_font_size_override("font_size", 17)
	subtitle_label.add_theme_color_override("font_color", cyan)
	right.add_child(subtitle_label)

	location_label = Label.new()
	location_label.position = Vector2(31.0, 151.0)
	location_label.size = Vector2(680.0, 25.0)
	location_label.add_theme_font_size_override("font_size", 12)
	location_label.add_theme_color_override("font_color", Color(0.64, 0.77, 0.78))
	right.add_child(location_label)

	var separator: ColorRect = ColorRect.new()
	separator.position = Vector2(30.0, 190.0)
	separator.size = Vector2(690.0, 2.0)
	separator.color = Color(cyan.r, cyan.g, cyan.b, 0.32)
	separator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	right.add_child(separator)

	description_label = Label.new()
	description_label.position = Vector2(31.0, 215.0)
	description_label.size = Vector2(670.0, 120.0)
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description_label.add_theme_font_size_override("font_size", 16)
	description_label.add_theme_color_override("font_color", Color(0.77, 0.87, 0.88))
	right.add_child(description_label)

	var intel: Label = Label.new()
	intel.text = "ASTER VALLEY BUILD PROFILE\n• 260 x 320 m procedural terrain\n• forests + river + cliffs + outpost\n• dynamic combat AI + drones\n• energy shields + ADS + extraction\n• high-detail mobile-first lighting"
	intel.position = Vector2(31.0, 344.0)
	intel.add_theme_font_size_override("font_size", 13)
	intel.add_theme_color_override("font_color", Color(0.56, 0.74, 0.71))
	right.add_child(intel)

	deploy_button = Button.new()
	deploy_button.position = Vector2(31.0, 457.0)
	deploy_button.size = Vector2(465.0, 64.0)
	deploy_button.text = "DEPLOY TO ASTER VALLEY"
	deploy_button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	deploy_button.add_theme_font_size_override("font_size", 17)
	deploy_button.add_theme_color_override("font_color", Color.WHITE)
	deploy_button.add_theme_stylebox_override("normal", _panel_style(Color(0.02, 0.31, 0.38, 0.95), cyan, 2))
	deploy_button.add_theme_stylebox_override("hover", _panel_style(Color(0.04, 0.45, 0.52, 1.0), Color(0.42, 0.96, 1.0), 2))
	deploy_button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	deploy_button.pressed.connect(_deploy)
	right.add_child(deploy_button)

	var quality: Button = Button.new()
	quality.position = Vector2(515.0, 457.0)
	quality.size = Vector2(205.0, 64.0)
	quality.text = "FPS PROFILE\n30 ↔ 60"
	quality.add_theme_font_size_override("font_size", 13)
	quality.add_theme_stylebox_override("normal", _panel_style(Color(0.04, 0.09, 0.10, 0.92), Color(0.31, 0.50, 0.51), 1))
	quality.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	quality.pressed.connect(_toggle_fps)
	right.add_child(quality)

	status_label = Label.new()
	status_label.anchor_left = 0.5
	status_label.anchor_top = 1.0
	status_label.anchor_right = 0.5
	status_label.anchor_bottom = 1.0
	status_label.offset_left = -360.0
	status_label.offset_top = -35.0
	status_label.offset_right = 360.0
	status_label.offset_bottom = -10.0
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 12)
	status_label.add_theme_color_override("font_color", Color(0.72, 0.88, 0.86))
	status_label.text = "VANGUARD COMMAND ONLINE // SELECT A DEPLOYMENT ZONE"
	add_child(status_label)


func _select_world(index: int) -> void:
	selected_world = clampi(index, 0, WORLDS.size() - 1)
	var world: Dictionary = WORLDS[selected_world]
	title_label.text = str(world["title"])
	subtitle_label.text = "%s // CHAPTER %s" % [world["subtitle"], world["chapter"]]
	location_label.text = str(world["location"])
	description_label.text = str(world["description"])
	var available: bool = bool(world["available"])
	deploy_button.disabled = not available
	deploy_button.text = "DEPLOY TO %s" % world["title"] if available else "WORLD LOCKED // IN PRODUCTION"
	status_label.text = "ASTER VALLEY IS THE ACTIVE REALISTIC VERTICAL SLICE" if available else "%s IS DEFINED FOR FUTURE PRODUCTION" % world["title"]

	for i: int in range(world_buttons.size()):
		var button: Button = world_buttons[i]
		button.modulate = Color.WHITE if i == selected_world else Color(0.86, 0.90, 0.90)


func _deploy() -> void:
	if not bool(WORLDS[selected_world]["available"]):
		return
	status_label.text = "DEPLOYMENT AUTHORIZED // ASTER VALLEY"
	get_tree().change_scene_to_file(GAME_SCENE)


func _toggle_fps() -> void:
	Engine.max_fps = 60 if Engine.max_fps == 30 else 30
	status_label.text = "%d FPS PROFILE ACTIVE // REALISM COST VARIES BY DEVICE" % Engine.max_fps


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
