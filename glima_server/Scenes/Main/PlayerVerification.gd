extends Node

onready var main_interface = get_parent()
onready var player_container_scene = preload("res://Scenes/Instances/PlayerContainer.tscn")

var awaiting_verification = {}

func start(player_id):
	awaiting_verification[player_id] = {"timestamp": OS.get_unix_time()}
	main_interface.fetch_token(player_id)
	#create_player_container(player_id)

func verify(player_id, token):
	var token_verification = false
	# While token is less than 30 seconds in the past and no more than 5 seconds in the future
	while OS.get_unix_time() - int(token.right(64)) <= 30 and OS.get_unix_time() - int(token.right(64)) > -5:
		if main_interface.expected_tokens.has(token):
			token_verification = true
			create_player_container(player_id)
			awaiting_verification.erase(player_id)
			main_interface.expected_tokens.erase(token)
			break
		else:
			yield(get_tree().create_timer(2), "timeout")
	main_interface.return_token_verification_results(player_id, token_verification)
	if token_verification == false:
		awaiting_verification.erase(player_id)
		var connected_peers = Array(get_tree().get_network_connected_peers())
		if connected_peers.has(player_id):
			main_interface.network.disconnect_peer(player_id)

func create_player_container(player_id):
	var new_player_container = player_container_scene.instance()
	new_player_container.name = str(player_id)
	get_parent().add_child(new_player_container, true)
	var player_container = get_node("../" + str(player_id))
	fill_player_container(player_container)

func fill_player_container(player_container):
	player_container.player_stats = GameData.test_data.stats
