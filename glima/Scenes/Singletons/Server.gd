extends Node

var network = NetworkedMultiplayerENet.new()
var ip = "127.0.0.1"

var port = 1909


func _ready():
	connect_to_server()


func connect_to_server():
	network.create_client(ip, port)
	get_tree().set_network_peer(network)

	network.connect("connection_succeeded", self, "_on_connection_succeeded")
	network.connect("connection_failed", self, "_on_connection_failed")


func _on_connection_succeeded():
	print("Succesfully connected")


func _on_connection_failed():
	print("Connection failed")
