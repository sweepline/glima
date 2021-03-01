extends Node

var network: NetworkedMultiplayerENet
var gateway_api: MultiplayerAPI
var ip = "127.0.0.1"
var port = 1910

var username
var password


func _ready():
	pass


func _process(_delta):
	if get_custom_multiplayer() == null:
		return
	if not custom_multiplayer.has_network_peer():
		return
	custom_multiplayer.poll()


func connect_to_server(_username, _password):
	network = NetworkedMultiplayerENet.new()
	gateway_api = MultiplayerAPI.new()
	username = _username
	password = _password
	network.create_client(ip, port)
	set_custom_multiplayer(gateway_api)
	custom_multiplayer.set_root_node(self)
	custom_multiplayer.set_network_peer(network)

	network.connect("connection_succeeded", self, "_on_connection_succeeded")
	network.connect("connection_failed", self, "_on_connection_failed")


func _on_connection_succeeded():
	request_login()


func _on_connection_failed():
	print("Failed to connect to login server")
	# TODO: Tell user
	get_node("../World/LoginScreen").login_button.disabled = false


func request_login():
	print("Connecting to login gateway")
	rpc_id(1, "login_request", username, password)
	username = ""
	password = ""

remote func return_login_request(result, token):
	print("Login request result recieved")
	if result == true:
		Server.token = token
		Server.connect_to_server()
	else:
		print("Username or password is incorrect")
		get_node("../World/LoginScreen").login_button.disabled = false
	
	network.disconnect("connection_succeeded", self, "_on_connection_succeeded")
	network.disconnect("connection_failed", self, "_on_connection_failed")
