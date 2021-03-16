extends Spatial

var map: Navigation
var unit_res = preload("res://Scenes/Instances/PlayerUnit.tscn")
onready var player_controller = $PlayerController

var last_world_state = 0
# Should be kept as
# [past_past_state, most_recent_past_state, nearest_future_state, any_other_future_state]
var world_state_buffer: Array = []
const INTERPOLATION_OFFSET = 50  # Basically the lag compensation
var event_buffer: Array = []


func _ready():
	# Make into some map load on demand thing
	var map_res = load("res://Scenes/World/Maps/RedMap.tscn")
	map = map_res.instance()
	map.name = "Map"
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
		player_controller.set_player(new_player)
		player_controller.activate()
	else:
		new_player.add_to_group("enemy")  # TODO: TEAM SETUP
		new_player.connect("mouse_entered", player_controller, "set_target", [new_player])
		new_player.connect("mouse_exited", player_controller, "unset_target", [new_player])
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
				if not world_state_buffer[1].has(player_id):
					continue

				# If were interpolating check player against newest world
				if player_id == get_tree().get_network_unique_id() and map.has_node(str(player_id)):
					var state_buffer = player_controller.state_buffer
					# The client might aswell look at the most recent world
					var newest_world = world_state_buffer.back()
					while state_buffer.size() > 1 and newest_world["t"] > state_buffer[0]["t"]:
						state_buffer.remove(0)
					var pos: Vector3 = state_buffer[0]["p"]
					var rot: Quat = state_buffer[0]["r"]
					var world_pos = Vector3(
						newest_world[player_id]["p"].x, 0.4, newest_world[player_id]["p"].y
					)
					var world_rot = Quat(
						0, newest_world[player_id]["r"].x, 0, newest_world[player_id]["r"].y
					)
					if (
						pos.distance_to(world_pos) > 1
						and (
							player_controller.cooldowns[1]
							< GameData.spell_data["blink"].cooldown - 0.15
						)
					):
						# TODO: Lerp this for rubber-banding
						print("PLAYER REPOSITIONED, pos: ", pos, " world_pos ", world_pos)
						map.get_node(str(player_id)).move_player(world_pos, world_rot)
						#map.get_node(str(player_id)).move_player(pos.linear_interpolate(world_pos, delta * 2), rot.slerp(world_rot, delta))
						map.get_node(str(player_id)).recalculate_nav()
					continue
				if map.has_node(str(player_id)):
					var new_position: Vector3
					# If we moved a lot, just let the player teleport
					if (
						world_state_buffer[1][player_id]["p"].distance_squared_to(
							world_state_buffer[2][player_id]["p"]
						)
						> 1
					):
						new_position = Vector3(
							world_state_buffer[2][player_id]["p"].x,
							0.4,
							world_state_buffer[2][player_id]["p"].y
						)
					else:
						var tmp_pos: Vector2 = lerp(
							world_state_buffer[1][player_id]["p"],
							world_state_buffer[2][player_id]["p"],
							interpolation_factor
						)
						new_position = Vector3(tmp_pos.x, 0.4, tmp_pos.y)
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

	# For other global events
	# It might be better to go through it forwards and stop, depending on size in real world applications
	for i in range(event_buffer.size() - 1, -1, -1):
		var event = event_buffer[i]
		if event.t <= render_time:
			consume_event(event)
			event_buffer.remove(i)


func insert_event(options, event_time):
	if options.has("player") and options.player == str(get_tree().get_network_unique_id()):
		consume_event(options)
	elif event_time > GameServer.client_clock - INTERPOLATION_OFFSET:
		options["t"] = event_time
		event_buffer.append(options)
	else:
		consume_event(options)


func consume_event(event):
	if event.has("player"):
		get_node("/root/Main/World/Map/" + event.player).call(event.function, event)
	if event.has("group"):
		get_tree().call_group(event.group, event.function, event)
