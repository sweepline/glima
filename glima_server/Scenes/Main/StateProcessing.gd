extends Node

var world_state

var counter: float = 0.0
var target_tickrate: float = 1 / 40.0


func _physics_process(delta):
	counter += delta
	print(counter, ", ", delta, ", ", target_tickrate)
	if counter >= target_tickrate:
		counter -= target_tickrate
		var player_collection = get_parent().player_collection
		if not player_collection.empty():
			world_state = {}
			# ext_world_state = {}
			for player_id in player_collection.keys():
				var player = player_collection[player_id]
				var rot_quat = player.global_transform.basis.get_rotation_quat()
				var player_state = {"p": player.global_transform.origin, "r": rot_quat}
				world_state[player_id] = player_state
				# var ext_player_state = {"p": player.global_transform.origin, "r": rot_quat, "d": player.dead, }
				# ext_world_state[player_id] = ext_player_state
			world_state["t"] = OS.get_system_time_msecs()

			get_parent().send_world_state(world_state)
