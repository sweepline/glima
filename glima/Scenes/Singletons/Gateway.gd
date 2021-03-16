extends Node

var network: NetworkedMultiplayerENet
var gateway_api: MultiplayerAPI
var ip = "127.0.0.1"
var port = 1910
var cert = load("res://Data/certificates/gateway.crt")

var username
var password
var new_account


func _ready():
	pass


func _process(_delta):
	if get_custom_multiplayer() == null:
		return
	if not custom_multiplayer.has_network_peer():
		return
	custom_multiplayer.poll()


func connect_to_server(_username, _password, _new_account):
	network = NetworkedMultiplayerENet.new()
	gateway_api = MultiplayerAPI.new()
	network.use_dtls = true
	network.dtls_verify = false
	network.set_dtls_certificate(cert)
	username = _username
	password = _password
	new_account = _new_account
	network.create_client(ip, port)
	set_custom_multiplayer(gateway_api)
	custom_multiplayer.set_root_node(self)
	custom_multiplayer.set_network_peer(network)

	network.connect("connection_succeeded", self, "_on_connection_succeeded")
	network.connect("connection_failed", self, "_on_connection_failed")


func _on_connection_succeeded():
	if new_account:
		request_account_create()
	else:
		request_login()


func _on_connection_failed():
	print("Failed to connect to login server")
	# TODO: Tell user
	get_node("/root/Main/LoginScreen").buttons_disable(false)


func request_login():
	print("Connecting to login gateway")
	rpc_id(1, "login_request", username, password)
	username = ""
	password = ""


func request_account_create():
	print("Creating new account")
	rpc_id(1, "create_account_request", username, password)
	username = ""
	password = ""


remote func return_login_request(result, token):
	if gateway_api.get_rpc_sender_id() != 1:
		return
	print("Login request result received")
	if result == true:
		GameServer.token = token
		GameServer.connect_to_server()
	else:
		print("Username or password is incorrect")
		get_node("/root/Main/LoginScreen").buttons_disable(false)

	network.disconnect("connection_succeeded", self, "_on_connection_succeeded")
	network.disconnect("connection_failed", self, "_on_connection_failed")

remote func return_create_account_request(result, message):
	if result:
		print("Account created, please log in")
		get_node("/root/Main/LoginScreen").buttons_disable(false)
		get_node("/root/Main/LoginScreen")._on_create_back_pressed()
	else:
		if message == 1:
			print("Could not create account, please try again")
		elif message == 2:
			print("Username exists, please use a different username")
		get_node("/root/Main/LoginScreen").buttons_disable(false)
	network.disconnect("connection_succeeded", self, "_on_connection_succeeded")
	network.disconnect("connection_failed", self, "_on_connection_failed")
