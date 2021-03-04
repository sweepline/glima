extends Spatial

var map: Navigation
var unit_res = preload("res://Scenes/Instances/Player.tscn")
onready var playerController = $PlayerController

var last_world_state = 0
# Should be kept as
# [past_past_state, most_recent_past_state, nearest_future_state, any_other_future_state]
var world_state_buffer: Array = []
const INTERPOLATION_OFFSET = 50


func _ready():
	# Make into some map load on demand thing
	var map_res = load("res://Scenes/World/Maps/RedMap.tscn")
	map = map_res.instance()
	add_child(map)


func spawn_new_player(player_id: int, spawn_position: Vector2, spawn_rotation = Vector2(0, 1)):
	if map.has_node(str(player_id)):
		return
	print("spawn ", player_id)
	var new_player = unit_res.instance()
	new_player.name = str(player_id)
	if player_id == get_tree().get_network_unique_id():
		print("WE SPAWNED OURSELF")
		new_player.add_to_group("player")
		playerController.set_player(new_player)
	else:
		new_player.add_to_group("enemy")  # TODO: TEAM SETUP
		new_player.connect("mouse_entered", playerController, "set_target", [new_player])
		new_player.connect("mouse_exited", playerController, "unset_target", [new_player])
	map.add_child(new_player)
	new_player.move_player(
		Vector3(spawn_position.x, 0.4, spawn_position.y),
		Quat(0, spawn_rotation.x, 0, spawn_rotation.y)
	)


func despawn_player(player_id):
	yield(get_tree().create_timer(0.2), "timeout")
	map.get_node(str(player_id)).queue_free()


func update_world_state(world_state):
	if world_state["t"] > last_world_state:
		last_world_state = world_state["t"]
		world_state_buffer.append(world_state)


func _physics_process(_delta):
	var render_time = GameServer.client_clock - INTERPOLATION_OFFSET
	if world_state_buffer.size() > 1:
		# Make sure most_recent_past is actually that
		while world_state_buffer.size() > 2 and render_time > world_state_buffer[2]["t"]:
			world_state_buffer.remove(0)
		if world_state_buffer.size() > 2:
			# Interpolate
			var interpolation_factor = (
				float(render_time - world_state_buffer[1]["t"])
				/ float(world_state_buffer[2]["t"] - world_state_buffer[1]["t"])
			)
			for player_id in world_state_buffer[2].keys():
				if str(player_id) == "t":
					continue
				if player_id == get_tree().get_network_unique_id():
					continue
				if not world_state_buffer[1].has(player_id):
					continue
				if map.has_node(str(player_id)):
					var tmp_pos: Vector2 = lerp(
						world_state_buffer[1][player_id]["p"],
						world_state_buffer[2][player_id]["p"],
						interpolation_factor
					)
					var new_position: Vector3 = Vector3(tmp_pos.x, 0.4, tmp_pos.y)
					var old_rot: Vector2 = world_state_buffer[1][player_id]["r"]
					var new_rot: Vector2 = world_state_buffer[2][player_id]["r"]
					var new_basis = Quat(0, old_rot.x, 0, old_rot.y).slerp(
						Quat(0, new_rot.x, 0, new_rot.y), interpolation_factor
					)
					map.get_node(str(player_id)).move_player(new_position, new_basis)
				else:
					spawn_new_player(
						player_id,
						world_state_buffer[2][player_id]["p"],
						world_state_buffer[2][player_id]["r"]
					)
		elif render_time > world_state_buffer[1]["t"]:
			# Extrapolate
			var extrapolation_factor = (
				(
					float(render_time - world_state_buffer[0]["t"])
					/ float(world_state_buffer[1]["t"] - world_state_buffer[0]["t"])
				)
				- 1.00
			)
			for player_id in world_state_buffer[1].keys():
				if str(player_id) == "t":
					continue
				if player_id == get_tree().get_network_unique_id():
					continue
				if not world_state_buffer[0].has(player_id):
					continue
				if map.has_node(str(player_id)):
					var position_delta = (
						world_state_buffer[1][player_id]["p"]
						- world_state_buffer[0][player_id]["p"]
					)
					var new_position: Vector2 = (
						world_state_buffer[1][player_id]["p"]
						+ (position_delta * extrapolation_factor)
					)
					map.get_node(str(player_id)).global_transform.origin = Vector3(
						new_position.x, 0.4, new_position.y
					)
