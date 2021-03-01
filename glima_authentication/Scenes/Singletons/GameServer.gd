extends Node

var network = NetworkedMultiplayerENet.new()
var gateway_api = MultiplayerAPI.new()
var port = 1912
var max_servers = 1000

var gameserverlist = {}

func _ready():
	start_server()


func _process(_delta):
	if not custom_multiplayer.has_network_peer():
		return
	custom_multiplayer.poll()


func start_server():
	network.create_server(port, max_servers)
	set_custom_multiplayer(gateway_api)
	custom_multiplayer.set_root_node(self)
	custom_multiplayer.set_network_peer(network)
	print("Game server hub started on port: ", port)

	network.connect("peer_connected", self, "_on_peer_connected")
	network.connect("peer_disconnected", self, "_on_peer_disconnected")


func _on_peer_connected(gameserver_id):
	print("Gameserver " + str(gameserver_id) + " connected")
	gameserverlist["gameserver1"] = gameserver_id
	print(gameserverlist)

func _on_peer_disconnected(gateway_id):
	print("Gameserver " + str(gateway_id) + " disconnected")

func distribute_login_token(token, gameserver):
	var gameserver_peer_id = gameserverlist[gameserver]
	rpc_id(gameserver_peer_id, "recieve_login_token", token)
