extends KinematicBody

class_name Unit

var current_target_location: Vector3
var path = []
var path_ind = 0
const move_speed = 12
export var turn_speed = 20

var dead = false

onready var nav: Navigation = get_parent()
onready var shape: CollisionShape = $CollisionShape
onready var slash_area = preload("res://Scenes/Instances/SlashArea.tscn")
onready var dagger = preload("res://Scenes/Instances/Dagger.tscn")
onready var cast_point_timer: Timer = $CastPointTimer

var normal_color = "blue"

# Spell things
var cooldowns: Array = [0, 0, 0, 0, 0, 0]
var shield_active = false
var stone_active = false
var casting = false


func _physics_process(delta):
	if path_ind < path.size():
		var move_vec = path[path_ind] - global_transform.origin
		if move_vec.length() < 0.1:
			path_ind += 1
		else:
			face_direction(move_vec, delta)
			var _vel = move_and_slide(move_vec.normalized() * move_speed, Vector3(0, 1, 0))
	for i in range(0, cooldowns.size()):
		var cooldown = cooldowns[i]
		if cooldown > 0:
			cooldowns[i] = max(cooldown - delta, 0)


func face_direction(_dir: Vector3, delta: float):
	var dir = -_dir  # Front is -Z
	var angle_diff = global_transform.basis.z.angle_to(dir)
	var turn_right = sign(global_transform.basis.x.dot(dir))  # Turn right or left
	if abs(angle_diff) < turn_speed * delta:  # snap because we would overshoot
		rotation.y = atan2(dir.x, dir.z)  # angle, x and z because y is up
	else:
		rotation.y += turn_speed * delta * turn_right


func face_towards(point: Vector3):
	look_at(point, Vector3.UP)
	rotation.x = 0
	rotation.z = 0


func move_to(target_pos: Vector3):
	if casting:
		# TODO: queue the move
		return
	if not $StoneTimer.is_stopped():
		$StoneTimer.stop()
		end_stone()
	current_target_location = target_pos
	path = nav.get_simple_path(global_transform.origin, target_pos)
	path_ind = 0


func is_moving() -> bool:
	return path_ind < path.size()


# Stop all actions
func stop() -> void:
	path = []


# SPELL THINGS


func try_cast_spell(options) -> Dictionary:
	var data = GameData.spell_by_id[options.id]

	if stone_active:
		return {"r": "stone_active", "id": data.id}
	if cooldowns[data.id] > 0:
		return {"r": "cooldown", "t": cooldowns[data.id], "id": data.id}
	if casting:
		# Maybe queue it
		return {"r": "already_casting", "id": data.id}

	var success = call("cast_" + data.name, options)

	if not success:
		# The spell should handle this
		return {"r": "spell_failed", "id": data.id}

	$CastDurationTimer.wait_time = data.cast_duration
	$CastDurationTimer.start()
	casting = true
	cooldowns[data.id] = data.cooldown
	return {"r": "success"}


func _on_cast_end():
	casting = false


func cast_from_cast_point(cast_point, spell, options):
	if cast_point == 0:
		call(spell, options)
		return
	cast_point_timer.wait_time = cast_point
	cast_point_timer.connect("timeout", self, spell, [options])
	cast_point_timer.start()


func cast_shield(_options) -> bool:
	var data = GameData.spell_data["shield"]
	cast_from_cast_point(data.cast_point, "main_cast_shield", _options)
	return true


# Shield
func main_cast_shield(_options) -> void:
	var data = GameData.spell_data["shield"]
	$Shield.visible = true
	$ShieldTimer.wait_time = data.duration
	$ShieldTimer.start()
	shield_active = true
	if cast_point_timer.is_connected("timeout", self, "main_cast_shield"):
		cast_point_timer.disconnect("timeout", self, "main_cast_shield")


func end_shield() -> void:
	get_node("/root/GameServer").end_buff(GameData.spell_data["shield"].id, int(name))
	$Shield.visible = false
	shield_active = false


func cast_blink(options) -> bool:
	var data = GameData.spell_data["blink"]
	stop()
	face_towards(options.p)

	cast_from_cast_point(data.cast_point, "main_cast_blink", options)
	return true


# Blink
func main_cast_blink(options) -> void:
	var pos: Vector3 = options.p
	var data = GameData.spell_data["blink"]

	disjoint_dagger()

	var save_y = global_transform.origin.y
	var blink_point
	if pos.distance_to(global_transform.origin) < data.range:
		blink_point = pos
	else:
		blink_point = global_transform.origin.move_toward(pos, data.range)

	global_transform.origin = nav.get_closest_point(blink_point)

	global_transform.origin.y = save_y
	if cast_point_timer.is_connected("timeout", self, "main_cast_blink"):
		cast_point_timer.disconnect("timeout", self, "main_cast_blink")


func cast_slash(options) -> bool:
	var data = GameData.spell_data["slash"]
	stop()
	face_towards(options.p)

	cast_from_cast_point(data.cast_point, "main_cast_slash", options)
	return true


# Slash
func main_cast_slash(options) -> void:
	var cast_point: Vector3 = options.p
	var data = GameData.spell_data["slash"]

	var slash_area_inst = slash_area.instance()
	get_tree().get_root().add_child(slash_area_inst)
	slash_area_inst.start(global_transform.origin, cast_point, self)
	if cast_point_timer.is_connected("timeout", self, "main_cast_slash"):
		cast_point_timer.disconnect("timeout", self, "main_cast_slash")


func cast_stone(_options) -> bool:
	var data = GameData.spell_data["stone"]
	stop()

	cast_from_cast_point(data.cast_point, "main_cast_stone", _options)
	return true


# Stone
func main_cast_stone(_options) -> void:
	var data = GameData.spell_data["stone"]

	$StoneTimer.wait_time = data.duration
	$StoneTimer.start()
	stone_active = true
	if cast_point_timer.is_connected("timeout", self, "main_cast_stone"):
		cast_point_timer.disconnect("timeout", self, "main_cast_stone")


func end_stone() -> void:
	get_node("/root/GameServer").end_buff(GameData.spell_data["stone"].id, int(name))
	stone_active = false


func cast_dagger(options) -> bool:
	var target: KinematicBody = get_node("/root/GameServer").player_collection[int(options.u)]
	var reflect = false
	if options.has("r"):
		reflect = options.r

	var data = GameData.spell_data["dagger"]

	if target.dead:
		return false
	if target == null:
		return false
	if (
		not reflect
		&& global_transform.origin.distance_to(target.global_transform.origin) > data.range
	):
		# move towards target and cast when in range
		return false

	stop()
	face_towards(target.global_transform.origin)

	cast_from_cast_point(data.cast_point, "main_cast_dagger", options)
	return true


# Dagger
func main_cast_dagger(options) -> void:
	var target: KinematicBody = get_node("/root/GameServer").player_collection[int(options.u)]

	var dagger_inst = dagger.instance()
	get_tree().get_root().add_child(dagger_inst)
	dagger_inst.start(global_transform.origin, target, self)
	if cast_point_timer.is_connected("timeout", self, "main_cast_dagger"):
		cast_point_timer.disconnect("timeout", self, "main_cast_dagger")


func disjoint_dagger():
	get_tree().call_group("dagger", "blink_disjoint", self, global_transform.origin)
	get_node("/root/GameServer").disjoint(int(self.name), global_transform.origin)


func cast_spin(options) -> bool:
	var data = GameData.spell_data["stone"]
	stop()

	cast_from_cast_point(data.cast_point, "main_cast_spin", options)
	return true


func main_cast_spin(_options) -> void:
	var data = GameData.spell_data["spin"]
	$SpinArea.start(data.range, self)
	if cast_point_timer.is_connected("timeout", self, "main_cast_spin"):
		cast_point_timer.disconnect("timeout", self, "main_cast_spin")


func refresh_spells():
	cooldowns = [0, 0, 0, 0, 0, 0]


# Self got hit with a spell
func hit(spell: String, caster) -> void:
	if dead:
		return
	if spell == "dagger":
		if shield_active and not caster.dead:
			var caster_t = {"id": GameData.spell_data["dagger"].id, "u": caster.name, "r": true}
			var _debug_r = cast_dagger(caster_t)
			get_node("/root/GameServer").cast_spell_server(caster_t, int(name))

	if spell == "slash":
		pass

	if spell == "spin":
		pass

	if not shield_active and not stone_active:
		caster.refresh_spells()
		get_node("/root/GameServer").kill_player(int(name), int(caster.name))
		die()


func die():
	disjoint_dagger()
	stop()
	global_transform.origin.y = -10
	visible = false
	dead = true
	$SpinArea.stop()
	get_node("/root/GameServer/GameControl").player_dead(int(name))
	#DEBUG THING
	# yield(get_tree().create_timer(2), "timeout")
	# get_node("/root/GameServer").resurrect_player(int(name), Vector3(0, 0.4, 0))
	# resurrect(Vector3(0, 0.4, 0))


func resurrect(pos):
	global_transform.origin = pos
	current_target_location = pos
	face_towards(Vector3.ZERO)
	visible = true
	dead = false
