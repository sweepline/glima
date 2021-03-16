extends Node

var network = NetworkedMultiplayerENet.new()
var gateway_api = MultiplayerAPI.new()
var port = 1910
var max_servers = 100
var cert = load("res://Data/certificates/gateway.crt")
var key = load("res://Data/certificates/gateway.key")


func _ready():
	start_server()


func _process(_delta):
	if not custom_multiplayer.has_network_peer():
		return
	custom_multiplayer.poll()


func start_server():
	network.use_dtls = true
	network.set_dtls_key(key)
	network.set_dtls_certificate(cert)
	network.create_server(port, max_servers)
	set_custom_multiplayer(gateway_api)
	custom_multiplayer.set_root_node(self)
	custom_multiplayer.set_network_peer(network)
	print("Gateway server started on port: ", port)

	network.connect("peer_connected", self, "_on_peer_connected")
	network.connect("peer_disconnected", self, "_on_peer_disconnected")


func _on_peer_connected(gateway_id):
	print("Peer " + str(gateway_id) + " connected")


func _on_peer_disconnected(gateway_id):
	print("Peer " + str(gateway_id) + " disconnected")


remote func login_request(username, password):
	print("Login request recieved")
	var player_id = custom_multiplayer.get_rpc_sender_id()
	Authenticate.authenticate_player(username, password, player_id)

remote func create_account_request(username, password):
	var player_id = custom_multiplayer.get_rpc_sender_id()
	var valid_request = true
	if username == "":
		valid_request = false
	if username.length() <= 3:
		valid_request = false
	if password == "":
		valid_request = false
	if password.length() <= 6:
		valid_request = false

	if not valid_request:
		return_create_account_request(valid_request, player_id, 1)
	else:
		Authenticate.create_account(username.to_lower(), password, player_id)


func return_create_account_request(result: bool, player_id: int, message):
	rpc_id(player_id, "return_create_account_request", result, message)
	# 1 = fail, 2 = existing username, 3 = success
	network.disconnect_peer(player_id)


func return_login_request(result, player_id, token):
	rpc_id(player_id, "return_login_request", result, token)
	network.disconnect_peer(player_id)
