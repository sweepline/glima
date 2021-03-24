extends Node

var network = NetworkedMultiplayerENet.new()
var port = 1909
var max_players = 8

var player_collection = {}

onready var player_verification_process = get_node("PlayerVerification")
onready var combat_functions = get_node("Combat")
onready var game_control = get_node("GameControl")
onready var player_res = preload("res://Scenes/Instances/ServerPlayer.tscn")

var expected_tokens: Array = []


func _ready():
	start_server()


func start_server():
	network.create_server(port, max_players)
	get_tree().set_network_peer(network)
	print("Server Started on port: ", port)
	print("IP: ", IP.get_local_addresses()[0])

	network.connect("peer_connected", self, "_on_peer_connected")
	network.connect("peer_disconnected", self, "_on_peer_disconnected")


func _on_peer_connected(player_id):
	print(str(player_id), " connected")
	player_verification_process.start(player_id)


func _on_peer_disconnected(player_id):
	print(str(player_id), " disconnected")
	if has_node(str(player_id)):
		get_node(str(player_id)).queue_free()
		rpc_id(0, "despawn_player", player_id)
		get_node("World/Map/" + str(player_id)).queue_free()
		player_collection.erase(player_id)


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
		for i in range(expected_tokens.size() - 1, -1, -1):
			token_time = int(expected_tokens[i].right(64))
			# We don't need to check for tokens in the future as we trust the auth server
			if current_time - token_time >= 30:
				expected_tokens.remove(i)


remote func fetch_server_time(client_time):
	var player_id = get_tree().get_rpc_sender_id()
	rpc_id(player_id, "return_server_time", OS.get_system_time_msecs(), client_time)

remote func determine_latency(client_time):
	var player_id = get_tree().get_rpc_sender_id()
	rpc_id(player_id, "return_latency", client_time)


func fetch_token(player_id):
	rpc_id(player_id, "fetch_token")


remote func return_token(token):
	var player_id = get_tree().get_rpc_sender_id()
	player_verification_process.verify(player_id, token)


func return_token_verification_results(player_id, result):
	rpc_id(player_id, "return_token_verification_results", result)
	if result == true:
		var spawn_pos = get_node(
			"World/Map/SpawnPoints/FFA/SpawnPoint" + str(player_collection.size())
		).global_transform.origin
		game_control.player_data[player_id] = {"spawn_pos": spawn_pos}
		spawn_player(player_id, spawn_pos)
		var player_inst = player_res.instance()
		get_node("World/Map").add_child(player_inst)
		player_inst.name = str(player_id)
		player_inst.global_transform.origin = spawn_pos
		player_collection[player_id] = player_inst


remote func move_command(options, _client_clock):
	var player_id = get_tree().get_rpc_sender_id()
	if options.type == "move":
		get_node("/root/GameServer/World/Map/" + str(player_id)).move_to(options.pos)
	elif options.type == "attack":
		get_node("/root/GameServer/World/Map/" + str(player_id)).move_to(options.pos)
	elif options.type == "stop":
		get_node("/root/GameServer/World/Map/" + str(player_id)).stop()


func send_world_state(world_state):
	rpc_unreliable_id(0, "receive_world_state", world_state)


remote func cast_spell(options, _cast_time):
	var player_id = get_tree().get_rpc_sender_id()
	# We need to verify it can be done and do it
	var result = get_node("/root/GameServer/World/Map/" + str(player_id)).try_cast_spell(options)
	if result["r"] == "success":
		rpc_id(0, "receive_spell", options, result, player_id, OS.get_system_time_msecs())
	else:
		rpc_id(player_id, "cast_failed", result)


func cast_spell_server(options, player_id: int):
	rpc_id(0, "receive_spell", options, {"r": "server"}, player_id, OS.get_system_time_msecs())


func end_buff(buff_id, player_id: int):
	rpc_id(0, "end_buff", buff_id, player_id, OS.get_system_time_msecs())


func disjoint(player_id: int, pos):
	rpc_id(0, "disjoint", pos, player_id, OS.get_system_time_msecs())


func kill_player(player_id: int, killer_id):
	rpc_id(0, "kill_player", player_id, killer_id, OS.get_system_time_msecs())


func resurrect_player(player_id: int, position):
	rpc_id(0, "resurrect_player", player_id, position, OS.get_system_time_msecs())


func spawn_player(player_id: int, position):
	rpc_id(0, "spawn_new_player", player_id, position)


remote func fetch_player_stats():
	var player_id = get_tree().get_rpc_sender_id()
	var player_stats = get_node(str(player_id)).player_stats
	rpc_id(player_id, "return_player_stats", player_stats)
