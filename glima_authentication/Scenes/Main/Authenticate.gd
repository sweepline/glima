extends Node

var network = NetworkedMultiplayerENet.new()
var port = 1911
var max_servers = 5


func _ready():
	start_server()


func start_server():
	network.create_server(port, max_servers)
	get_tree().set_network_peer(network)
	print("Authentication server started on port: ", port)

	network.connect("peer_connected", self, "_on_peer_connected")
	network.connect("peer_disconnected", self, "_on_peer_disconnected")


func _on_peer_connected(gateway_id):
	print("Gateway " + str(gateway_id) + " connected")


func _on_peer_disconnected(gateway_id):
	print("Gateway " + str(gateway_id) + " disconnected")


remote func authenticate_player(username, password, player_id):
	print("authentication request recieved for user: ", username)
	var token
	var gateway_id = get_tree().get_rpc_sender_id()
	var result
	print("Starting authentication")
	if not PlayerData.player_data.has(username):
		print("No user named: ", username)
		result = false
	elif not PlayerData.player_data[username].password == password:
		print("Incorrect password for user: ", username)
		result = false
	else:
		print("Succesful login for user: ", username)
		result = true
		
		randomize()
		token = str(randi()).sha256_text() + str(OS.get_unix_time())
		var gameserver = "gameserver1"
		GameServer.distribute_login_token(token, gameserver)

	print("Authentication result sent to gateway server")
	rpc_id(gateway_id, "authentication_result", result, player_id, token)
