extends Control

onready var login_username: LineEdit = get_node("Background/LoginContainer/Username")
onready var login_password: LineEdit = get_node("Background/LoginContainer/Password")
onready var login_button: TextureButton = get_node("Background/LoginContainer/LoginButton")
onready var goto_create_button: TextureButton = get_node(
	"Background/LoginContainer/CreateAccountButton"
)

onready var create_username: LineEdit = get_node("Background/CreateAccountContainer/Username")
onready var create_password: LineEdit = get_node("Background/CreateAccountContainer/Password")
onready var create_rpassword: LineEdit = get_node("Background/CreateAccountContainer/RPassword")
onready var create_button: TextureButton = get_node(
	"Background/CreateAccountContainer/ConfirmCreateButton"
)
onready var back_button: TextureButton = get_node("Background/CreateAccountContainer/BackButton")

func buttons_disable(disabled):
	login_button.disabled = disabled
	goto_create_button.disabled = disabled
	create_button.disabled = disabled
	back_button.disabled = disabled


func _on_login_button_pressed():
	if login_username.text == "" or login_password.text == "":
		print("Please provide a valid username and password")
	else:
		buttons_disable(true)
		var username = login_username.get_text()
		var password = login_password.get_text()
		print("Attempting login")
		Gateway.connect_to_server(username, password, false)


func _on_create_account():
	if create_username.get_text() == "":
		print("Please provide a valid username")
	elif create_username.get_text().length() <= 3:
		print("Please provide a username longer than 3 characters")
	elif create_password.get_text() == "":
		print("Please provide a valid password")
	elif create_password.get_text().length() <= 6:
		print("Please provide a password longer than 6 characters")
	elif create_password.get_text() != create_rpassword.get_text():
		print("Passwords must match")
	else:
		buttons_disable(true)
		var username = create_username.get_text()
		var password = create_password.get_text()
		print("Attempting create and login")
		Gateway.connect_to_server(username, password, true)


func _on_goto_create_pressed():
	get_node("Background/LoginContainer").visible = false
	get_node("Background/CreateAccountContainer").visible = true


func _on_create_back_pressed():
	get_node("Background/LoginContainer").visible = true
	get_node("Background/CreateAccountContainer").visible = false


func _on_password_done(_x):
	_on_login_button_pressed()

func _on_gateway_ip_changed(new_text):
	Gateway.ip = new_text.strip_edges()
