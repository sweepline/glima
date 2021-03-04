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
	
func return_login_request(result, player_id, token):
	rpc_id(player_id, "return_login_request", result, token)
	network.disconnect_peer(player_id)
