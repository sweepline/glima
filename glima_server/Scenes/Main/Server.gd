extends Node

var network = NetworkedMultiplayerENet.new()
var port = 1909
var max_players = 20

onready var player_verification_process = get_node("PlayerVerification")
onready var combat_functions = get_node("Combat")

var expected_tokens: Array = []

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
	player_verification_process.start(player_id)


func _on_peer_disconnected(player_id):
	print(str(player_id), " disconnected")
	if has_node(str(player_id)):
		get_node(str(player_id)).queue_free()
		
func _on_timer_expiration_timeout():
	## THIS MIGHT HAVE TIMING ISSUES
	# Actually we need to set up the server such that x players can connect
	# Then when the players are connected we dont accept ANY more connections
	# we are starting rounds and stuff, this assumes people logging in and out
	var current_time = OS.get_unix_time()
	var token_time
	if expected_tokens.size() == 0:
		pass
	else:
		for i in range(expected_tokens.size() -1, -1, -1):
			token_time = int(expected_tokens[i].right(64))
			if current_time - token_time >= 30:
				expected_tokens.remove(i)

func fetch_token(player_id):
	rpc_id(player_id, "fetch_token")

remote func return_token(token):
	var player_id = get_tree().get_rpc_sender_id()
	player_verification_process.verify(player_id, token)
	
func return_token_verification_results(player_id, result):
	rpc_id(player_id, "return_token_verification_results", result)

remote func fetch_player_stats():
	var player_id = get_tree().get_rpc_sender_id()
	var player_stats = get_node(str(player_id)).player_stats
	rpc_id(player_id, "return_player_stats", player_stats)
