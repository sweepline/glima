extends Node

var world_state

var counter: float = 0.0
var target_tickrate: float = 1 / 40.0


func _physics_process(delta):
	counter += delta
	if counter >= target_tickrate:
		counter -= target_tickrate
		var player_collection = get_parent().player_collection
		if not player_collection.empty():
			world_state = {}
			for player_id in player_collection.keys():
				var player = player_collection[player_id]
				var rot_quat = player.global_transform.basis.get_rotation_quat()
				var player_state = {
					"p":
					Vector2(player.global_transform.origin.x, player.global_transform.origin.z),
					"r": Vector2(rot_quat.y, rot_quat.w)
				}
				world_state[player_id] = player_state
			world_state["t"] = OS.get_system_time_msecs()

			get_parent().send_world_state(world_state)
