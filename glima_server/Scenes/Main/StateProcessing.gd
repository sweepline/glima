extends Node

var world_state

func _physics_process(_delta):
	if not get_parent().player_state_collection.empty():
		world_state = get_parent().player_state_collection.duplicate(true)
		for player in world_state.keys():
			world_state[player].erase("t")
		world_state["t"] = OS.get_system_time_msecs()
		
		#Verification
		#Anti-Cheat
		# Lag Compensation
		#   For that Roll back to world state depending on how far we run clients
		#   In the past (e.g. we might be running 100ms in the past at all times)
		#Chunking data
		#Physics Check
		#Other
		get_parent().send_world_state(world_state)
