extends "res://scripts/coastline_fortress_production.gd"

const PLAYER_FINAL: Script = preload("res://scripts/player_v3.gd")


func _spawn_player() -> void:
	player = CharacterBody3D.new()
	player.name = "Vanguard_01_Production"
	player.set_script(PLAYER_FINAL)
	player.position = _extraction_world_position() + Vector3(0.0, 1.15, -2.0)
	add_child(player)
