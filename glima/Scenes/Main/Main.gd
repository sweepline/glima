extends Node

var inMenu = false

func _ready():
	pass # Replace with function body.

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("menu"):
		if inMenu:
			inMenu = false
			Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED)
			get_node("World/PlayerController/CameraController").enable()
		else:
			inMenu = true
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			get_node("World/PlayerController/CameraController").disable()
	if event.is_action_pressed("scoreboard"):
		if GameServer.connected:
			GameServer.fetch_player_stats()
