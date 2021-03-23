extends Node


var player_data: Dictionary = {}
var dead_players = []

func player_dead(player_id: int):
	var player_collection = get_parent().player_collection
	dead_players.push_back(player_id)
	print(dead_players.size(), player_collection.size())
	if dead_players.size() > 0 and player_collection.size() - 1 == dead_players.size():
		print("SOMEONE WON (figure out who)")
		yield(get_tree().create_timer(2), "timeout")
		dead_players.clear()
		for player_id in player_collection.keys():
			var spawn_pos = player_data[player_id].spawn_pos
			get_parent().resurrect_player(player_id, spawn_pos)
			player_collection[player_id].resurrect(spawn_pos)


func pause_game():
	pass

func start_game():
	pass
