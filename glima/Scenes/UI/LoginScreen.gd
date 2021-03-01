extends Control

onready var username_input: LineEdit = get_node("Background/LoginContainer/Username")
onready var password_input: LineEdit = get_node("Background/LoginContainer/Password")
onready var login_button: TextureButton = get_node("Background/LoginContainer/LoginButton")


func _on_login_button_pressed():
	if username_input.text == "" or password_input.text == "":
		print("Please privide a valid username and password")
	else:
		login_button.disabled = true
		var username = username_input.get_text()
		var password = password_input.get_text()
		print("Attempting login")
		Gateway.connect_to_server(username, password)
