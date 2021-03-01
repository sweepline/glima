extends Node

var network = NetworkedMultiplayerENet.new()
var port = 1909
var max_players = 20


func _ready():
	start_server()


func start_server():
	network.create_server(port, max_players)
	get_tree().set_network_peer(network)
	print("Server Started on port: ", port)

	network.connect("peer_connected", self, "_on_peer_connected")
	network.connect("peer_disconnected", self, "_on_peer_disconnected")


func _on_peer_connected(player_id):
	print(str(player_id), " connected")


func _on_peer_disconnected(player_id):
	print(str(player_id), " disconnected")
