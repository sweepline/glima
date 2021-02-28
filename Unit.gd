extends KinematicBody

class_name Unit

var current_target_location: Vector3
var path = []
var path_ind = 0
const move_speed = 12
export var turn_speed = 20

var id: int
var dead = false

onready var nav: Navigation = get_parent()
onready var shape: CollisionShape = $CollisionShape
onready var body: MeshInstance = $Body
onready var slash_area = preload("res://SlashArea.tscn")
onready var dagger = preload("res://Dagger.tscn")

var colors = {
	"blue": preload("res://BlueUnit.tres"),
	"red": preload("res://RedUnit.tres"),
	"grey": preload("res://GreyUnit.tres")
}
var normal_color = "blue"

# Spell things
var cooldowns: Array = [0, 0, 0, 0, 0]
var shield_active = false
var stone_active = false
var attack_moving = false
var attacking_unit: KinematicBody = null


func _ready() -> void:
	if is_in_group("enemy"):
		body.material_override = colors.red
		normal_color = "red"


func _process(delta: float):
	for i in range(0, cooldowns.size()):
		var cooldown = cooldowns[i]
		if cooldown > 0:
			cooldowns[i] = max(cooldown - delta, 0)


func _physics_process(delta):
	if path_ind < path.size():
		var move_vec = path[path_ind] - global_transform.origin
		if move_vec.length() < 0.1:
			path_ind += 1
		else:
			face_direction(move_vec, delta)
			var _vel = move_and_slide(move_vec.normalized() * move_speed, Vector3(0, 1, 0))


func face_direction(_dir: Vector3, delta: float):
	var dir = -_dir  # Front is -Z
	var angle_diff = global_transform.basis.z.angle_to(dir)
	var turn_right = sign(global_transform.basis.x.dot(dir))  # Turn right or left
	if abs(angle_diff) < turn_speed * delta:  # snap because we would overshoot
		rotation.y = atan2(dir.x, dir.z)  # angle, x and z because y is up
	else:
		rotation.y += turn_speed * delta * turn_right


func move_to(target_pos: Vector3):
	attack_moving = false
	if not $StoneTimer.is_stopped():
		$StoneTimer.stop()
		end_stone()
	current_target_location = target_pos
	path = nav.get_simple_path(global_transform.origin, target_pos)
	path_ind = 0


func is_moving() -> bool:
	return path_ind < path.size()


# The spells to cast (mostly for animations when server comes i guess?)


# Shield
func cast_shield() -> void:
	var spell_id = 0
	var COOLDOWN = 2
	var DURATION = 0.7

	if stone_active:
		return
	if cooldowns[spell_id] > 0:
		return

	$Shield.visible = true
	$ShieldTimer.wait_time = DURATION
	$ShieldTimer.start()
	shield_active = true

	cooldowns[spell_id] = DURATION + COOLDOWN


func end_shield() -> void:
	$Shield.visible = false
	shield_active = false


# Blink
func cast_blink(pos: Vector3) -> void:
	var spell_id = 1
	var COOLDOWN = 4
	var RANGE = 30

	if stone_active:
		return
	if cooldowns[spell_id] > 0:
		return

	stop()
	look_at(pos, Vector3.UP)
	disjoint_dagger()

	var save_y = global_transform.origin.y
	var blink_point
	if pos.distance_to(global_transform.origin) < RANGE:
		blink_point = pos
	else:
		blink_point = global_transform.origin.move_toward(pos, RANGE)

	global_transform.origin = nav.get_closest_point(blink_point)

	global_transform.origin.y = save_y

	cooldowns[spell_id] = COOLDOWN


func disjoint_dagger():
	get_tree().call_group("dagger", "blink_disjoint", self, global_transform.origin)


# Slash
func cast_slash(cast_point: Vector3) -> void:
	var spell_id = 2
	var COOLDOWN = 2

	if stone_active:
		return
	if cooldowns[spell_id] > 0:
		return

	stop()
	look_at(cast_point, Vector3.UP)
	var slash_area_inst = slash_area.instance()
	get_tree().get_root().add_child(slash_area_inst)
	slash_area_inst.start(global_transform.origin, cast_point, self)

	cooldowns[spell_id] = COOLDOWN


# Stone
func cast_stone() -> void:
	var spell_id = 3
	var COOLDOWN = 12
	var DURATION = 6

	if stone_active:
		return
	if cooldowns[spell_id] > 0:
		return

	body.material_override = colors.grey
	stop()
	$StoneTimer.wait_time = DURATION
	$StoneTimer.start()
	stone_active = true

	cooldowns[spell_id] = DURATION + COOLDOWN


func end_stone() -> void:
	stone_active = false
	body.material_override = colors[normal_color]


# Dagger
func cast_dagger(target: KinematicBody) -> void:
	var spell_id = 4
	var COOLDOWN = 5
	var RANGE = 40

	if stone_active:
		return
	if target == null:
		return
	if global_transform.origin.distance_to(target.global_transform.origin) > RANGE:
		return
	if cooldowns[spell_id] > 0:
		return

	look_at(target.global_transform.origin, Vector3.UP)
	var dagger_inst = dagger.instance()
	get_tree().get_root().add_child(dagger_inst)
	dagger_inst.start(global_transform.origin, target, self)

	cooldowns[spell_id] = COOLDOWN


func refresh_spells():
	cooldowns = [0, 0, 0, 0, 0]


# Find closests enemy and attack it, if it dies do it again
func attack_move(target_pos: Vector3):
	move_to(target_pos)
	attacking_unit = null
	attack_moving = true


# Run to specific unit and attack it.
func attack_unit(target_unit: KinematicBody) -> void:
	move_to(target_unit.global_transform.origin)
	attack_moving = false
	attacking_unit = target_unit


# Stop all actions
func stop() -> void:
	attack_moving = false
	attacking_unit = null
	path = []


# Self got hit with a spell
func hit(spell: String, caster) -> void:
	if dead:
		return
	if spell == "dagger":
		if shield_active and not caster.dead:
			cast_dagger(caster)

	if spell == "slash":
		pass

	if not shield_active and not stone_active:
		caster.refresh_spells()
		die()


func die():
	disjoint_dagger()
	stop()
	global_transform.origin.y = -8
	visible = false
	dead = true
