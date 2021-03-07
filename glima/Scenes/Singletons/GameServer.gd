extends Node

var network = NetworkedMultiplayerENet.new()
var ip = "127.0.0.1"
var connected = false
var port = 1909

var token

var client_clock = 0
var decimal_collector: float = 0.00
var latency_array = []
var latency = 0
var delta_latency = 0


func _ready():
	pass


func _physics_process(delta):
	client_clock += int(delta * 1000) + delta_latency
	delta_latency = 0
	decimal_collector += (delta * 1000) - int(delta * 1000)
	if decimal_collector >= 1.00:
		client_clock += 1
		decimal_collector -= 1.00


func connect_to_server():
	network.create_client(ip, port)
	get_tree().set_network_peer(network)

	network.connect("connection_succeeded", self, "_on_connection_succeeded")
	network.connect("connection_failed", self, "_on_connection_failed")


remote func spawn_new_player(player_id: int, position: Vector3):
	if get_tree().get_rpc_sender_id() != 1:
		return
	get_node("/root/Main/World").spawn_new_player(player_id, Vector2(position.x, position.z))

remote func despawn_player(player_id: int):
	if get_tree().get_rpc_sender_id() != 1:
		return
	get_node("/root/Main/World").despawn_player(player_id)


func fetch_player_stats():
	rpc_id(1, "fetch_player_stats")


remote func return_player_stats(stats):
	if get_tree().get_rpc_sender_id() != 1:
		return
	get_node("/root/Main/World/PlayerController").test_print_player_stats(stats)

remote func receive_world_state(world_state):
	if get_tree().get_rpc_sender_id() != 1:
		return
	get_node("/root/Main/World").update_world_state(world_state)


func move_command(options):
	rpc_id(1, "move_command", options, client_clock)


func cast_spell(options):
	rpc_id(1, "cast_spell", options, client_clock)


remote func cast_failed(reason):
	if get_tree().get_rpc_sender_id() != 1:
		return
	# Update cd if spells cast failed
	print("Could not cast spell: ", reason.r)
	reason.erase("r")
	print("Other information: ", reason)

remote func receive_spell(options, result, player_id: int, cast_time):
	if get_tree().get_rpc_sender_id() != 1:
		return

	options["function"] = "cast_" + GameData.spell_by_id[options.id].name
	options["target"] = "player"
	options["player"] = str(player_id)
	get_node("/root/Main/World").insert_event(options, cast_time)
	if result.r == "server":
		# Server says this was casted without user input
		pass
	elif player_id == get_tree().get_network_unique_id():
		# Correct client side predictions
		pass
	else:
		pass
		#get_node("/root/Main/World")

remote func end_buff(buff_id, player_id: int, time):
	if get_tree().get_rpc_sender_id() != 1:
		return

	var options = {
		"function": "end_" + GameData.spell_by_id[buff_id].name, "player": str(player_id)
	}
	get_node("/root/Main/World").insert_event(options, time)

remote func disjoint(pos, player_id, time):
	if get_tree().get_rpc_sender_id() != 1:
		return
	var player = get_node("/root/Main/World/Map/" + str(player_id))
	var options = {
		"function": "blink_disjoint",
		"group": "dagger",
		"blink_caster": player,
		"caster_position": pos
	}
	get_node("/root/Main/World").insert_event(options, time)

remote func kill_player(player_id: int, killer_id, time):
	if get_tree().get_rpc_sender_id() != 1:
		return
	var options = {"function": "die", "player": str(player_id)}
	get_node("/root/Main/World").insert_event(options, time)
	# TODO: DO THIS AT CORRECT TIME
	if player_id == get_tree().get_network_unique_id():
		get_node("/root/Main/World/PlayerController").deactivate()
	if killer_id == get_tree().get_network_unique_id():
		get_node("/root/Main/World/PlayerController").refresh_cooldowns()

remote func resurrect_player(player_id: int, position, time):
	if get_tree().get_rpc_sender_id() != 1:
		return
	var options = {"function": "resurrect", "player": str(player_id), "position": position}
	get_node("/root/Main/World").insert_event(options, time)
	# TODO: AT CORRECT TIME
	if player_id == get_tree().get_network_unique_id():
		get_node("/root/Main/World/PlayerController").activate()


func _on_connection_succeeded():
	print("Succesfully connected")
	connected = true
	rpc_id(1, "fetch_server_time", OS.get_system_time_msecs())
	var timer = Timer.new()
	timer.wait_time = 0.5
	timer.autostart = true
	timer.connect("timeout", self, "determine_latency")
	self.add_child(timer)


remote func return_server_time(server_time, client_time):
	if get_tree().get_rpc_sender_id() != 1:
		return
	# Actually there might be a difference between to and from server, but eh...
	latency = (OS.get_system_time_msecs() - client_time) / 2
	print(server_time)
	client_clock = server_time + latency


func determine_latency():
	rpc_id(1, "determine_latency", OS.get_system_time_msecs())


remote func return_latency(client_time):
	if get_tree().get_rpc_sender_id() != 1:
		return
	latency_array.append((OS.get_system_time_msecs() - client_time) / 2)
	if latency_array.size() == 9:
		var total_latency = 0
		latency_array.sort()
		var mid_point = latency_array[4]
		for i in range(latency_array.size() - 1, -1, -1):
			if latency_array[i] > (2 * mid_point) and latency_array[i] > 25:
				latency_array.remove(i)
			else:
				total_latency += latency_array[i]
		delta_latency = (total_latency / latency_array.size()) - latency
		latency = total_latency / latency_array.size()
		# print("new latency ", latency)
		# print("Delta latency ", delta_latency)
		latency_array.clear()


func _on_connection_failed():
	print("Connection failed")


remote func fetch_token():
	if get_tree().get_rpc_sender_id() != 1:
		return
	rpc_id(1, "return_token", token)

remote func return_token_verification_results(result):
	print("TOKEN VERIFY, ", result)
	if get_tree().get_rpc_sender_id() != 1:
		return
	if result == true:
		get_node("/root/Main/LoginScreen").queue_free()
		print("Succesfull token verification")
	else:
		print("Token verification failed")
		get_node("/root/Main/LoginScreen").login_button.disabled = false
