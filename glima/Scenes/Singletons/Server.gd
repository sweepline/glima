extends Node

var network = NetworkedMultiplayerENet.new()
var ip = "127.0.0.1"
var connected = false
var port = 1909

var token


func _ready():
	pass


func connect_to_server():
	network.create_client(ip, port)
	get_tree().set_network_peer(network)

	network.connect("connection_succeeded", self, "_on_connection_succeeded")
	network.connect("connection_failed", self, "_on_connection_failed")

func fetch_player_stats():
	rpc_id(1, "fetch_player_stats")

remote func return_player_stats(stats):
	get_node("/root/World/PlayerController").test_print_player_stats(stats)
	

func _on_connection_succeeded():
	connected = true
	print("Succesfully connected")


func _on_connection_failed():
	print("Connection failed")
	
remote func fetch_token():
	rpc_id(1, "return_token", token)
	
remote func return_token_verification_results(result):
	if result == true:
		get_node("../World/LoginScreen").queue_free()
		print("Succesfull token verification")
	else:
		print("Token verification failed")		
		get_node("../World/LoginScreen").login_button.disabled = false
