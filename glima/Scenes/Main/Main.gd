extends Node

var in_menu:bool

func _ready():
	set_in_menu(true)
	OS.window_maximized = true

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("menu"):
		set_in_menu(not in_menu)
	if event.is_action_pressed("scoreboard"):
		if GameServer.connected:
			GameServer.fetch_player_stats()

func set_in_menu(_in_menu: bool):
	in_menu = _in_menu
	if in_menu:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		get_node("World/PlayerController/CameraController").disable()
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED)
		get_node("World/PlayerController/CameraController").enable()
