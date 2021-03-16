extends Spatial

var target_circle = preload("res://Scenes/Instances/ClickCircle.tscn")
onready var click_circle: MeshInstance = $ClickCircle

onready var camera_controller: Spatial = $CameraController
const floor_plane = Plane(0, 1, 0, 0)

# Player node, assume only one for now
var player: KinematicBody = null

# Target when hovering
var target_unit: KinematicBody
var target_reticle: MeshInstance

# Unit things
# Spell things
var cooldowns: Array = [0, 0, 0, 0, 0, 0]
var event_queue: Array = []
var casting = false

var state_buffer = []


func set_player(_player: KinematicBody):
	player = _player


func activate():
	set_process(true)
	set_process_input(true)
	set_physics_process(true)


func deactivate():
	set_process_input(false)
	set_physics_process(false)
	set_process(false)


func _ready() -> void:
	deactivate()
	click_circle.visible = false
	#for enemy in get_tree().get_nodes_in_group("enemy"):
	#	enemy.connect("mouse_entered", self, "set_target", [enemy])
	#	enemy.connect("mouse_exited", self, "unset_target", [enemy])


func _process(delta):
	for i in range(0, cooldowns.size()):
		var cooldown = cooldowns[i]
		if cooldown > 0:
			cooldowns[i] = max(cooldown - delta, 0)


func _physics_process(_delta):
	var rot_quat = player.global_transform.basis.get_rotation_quat()
	var state = {"t": GameServer.client_clock, "p": player.global_transform.origin, "r": rot_quat}
	state_buffer.append(state)


func test_print_player_stats(stats):
	print("Player stats: ", stats)


func _input(event: InputEvent) -> void:
	if player.dead:
		return
	var m_pos = get_viewport().get_mouse_position()

	if Input.is_key_pressed(KEY_SHIFT):
		pass
		# queue event
	if event.is_action_pressed("main_move"):
		if not player.get_node("StoneTimer").is_stopped():
			player.get_node("StoneTimer").stop()
			player.end_stone()
		move_player(m_pos)
	# abilities
	if event.is_action_pressed("spell_1"):
		try_cast("shield")
	if event.is_action_pressed("spell_2"):
		try_cast("blink", raycast_from_mouse(m_pos))
	if event.is_action_pressed("spell_3"):
		try_cast("slash", raycast_from_mouse(m_pos))
	if event.is_action_pressed("spell_4"):
		try_cast("stone")
	if event.is_action_pressed("spell_5"):
		try_cast("dagger", target_unit)
	if event.is_action_pressed("spell_6"):
		try_cast("spin")
	if event.is_action_pressed("stop_move"):
		stop_player()


func stop_player():
	player.path = []
	GameServer.move_command({"type": "stop"})
	if target_reticle != null:
		target_reticle.green()


func move_player(m_pos: Vector2):
	var result = raycast_from_mouse(m_pos)
	if casting:
		# TODO: queue the move
		return
	if result:
		player.move_to(result)
		GameServer.move_command({"type": "move", "pos": result})

		# Make an effect on the point clicked
		click_circle.global_transform.origin = Vector3(result.x, 0.01, result.z)
		click_circle.rotation = Vector3(-PI / 2, 0, 0)
		click_circle.green()

		var anim_player = click_circle.get_node("AnimationPlayer")
		if anim_player.is_playing():
			anim_player.stop()
		anim_player.play("scale_down")


func raycast_from_mouse(m_pos: Vector2) -> Vector3:
	var ray_start = camera_controller.cam.project_ray_origin(m_pos)
	var ray_dir = camera_controller.cam.project_ray_normal(m_pos)
	return floor_plane.intersects_ray(ray_start, ray_dir)


func set_target(enemy) -> void:
	target_unit = enemy
	if target_reticle != null:
		target_reticle.queue_free()
	target_reticle = target_circle.instance()
	enemy.add_child(target_reticle)
	target_reticle.translate(Vector3(0, 0, 0.01))
	target_reticle.scale = Vector3(2, 2, 2)


func unset_target(enemy) -> void:
	if target_unit == enemy:
		target_unit = null
		if target_reticle != null:
			target_reticle.queue_free()


func _on_CastDurationTimer_timeout() -> void:
	casting = false


func try_cast(spell: String, options = null):
	var data = GameData.spell_data[spell]

	if player.stone_active:
		# HUD should update
		return
	if cooldowns[data.id] > 0:
		# HUD should update
		return
	if casting:
		# Maybe queue it
		return

	var success = self.call("cast_" + spell, options)

	if not success:
		# The spell should handle this
		return

	$CastDurationTimer.wait_time = data.cast_duration
	$CastDurationTimer.start()
	casting = true
	cooldowns[data.id] = data.cooldown


# Shield
func cast_shield(_opt) -> bool:
	var data = GameData.spell_data["shield"]
	GameServer.cast_spell({"id": data.id})
	return true


# Blink
func cast_blink(pos: Vector3) -> bool:
	var data = GameData.spell_data["blink"]

	stop_player()
	player.face_towards(pos)

	# All movement is instant client side and so happens only in playercontroller
	var save_y = player.global_transform.origin.y
	var blink_point
	if pos.distance_to(player.global_transform.origin) < data.range:
		blink_point = pos
	else:
		blink_point = player.global_transform.origin.move_toward(pos, data.range)

	player.global_transform.origin = get_node("/root/Main/World/Map").get_closest_point(blink_point)

	player.global_transform.origin.y = save_y

	GameServer.cast_spell({"id": data.id, "p": pos})
	return true


func disjoint_dagger():
	get_tree().call_group("dagger", "blink_disjoint", self, global_transform.origin)


# Slash
func cast_slash(cast_pos: Vector3) -> bool:
	var data = GameData.spell_data["slash"]

	stop_player()
	player.face_towards(cast_pos)

	GameServer.cast_spell({"id": data.id, "p": cast_pos})
	return true


# Stone
func cast_stone(_opt) -> bool:
	var data = GameData.spell_data["stone"]

	stop_player()
	GameServer.cast_spell({"id": data.id})
	return true


# Dagger
func cast_dagger(target: KinematicBody) -> bool:
	var data = GameData.spell_data["dagger"]

	if target == null:
		return false

	if player.global_transform.origin.distance_to(target.global_transform.origin) > data.range:
		# move towards target and cast when in range
		return false

	stop_player()
	player.face_towards(target.global_transform.origin)
	GameServer.cast_spell({"id": data.id, "u": target_unit.name})
	# player.cast_dagger(target)

	return true


func cast_spin(_opt) -> bool:
	var data = GameData.spell_data["spin"]

	stop_player()
	GameServer.cast_spell({"id": data.id})

	return true


func refresh_cooldowns():
	cooldowns = [0, 0, 0, 0, 0, 0]
