extends "res://scripts/player_v2.gd"

const WEAPON_V4: Script = preload("res://scripts/weapon_v4.gd")


func _build_camera_and_weapon() -> void:
	camera = Camera3D.new()
	camera.name = "VanguardHelmetCam"
	camera.position = Vector3(0.0, 0.67, 0.0)
	camera.current = true
	camera.fov = 74.0
	camera.near = 0.035
	add_child(camera)

	weapon = Node3D.new()
	weapon.name = "VX7_Rifle_Production_V4"
	weapon.set_script(WEAPON_V4)
	weapon.connect("ammo_changed", Callable(self, "_on_weapon_ammo_changed"))
	camera.add_child(weapon)
