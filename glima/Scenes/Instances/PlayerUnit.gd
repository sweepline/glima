extends KinematicBody

# THIS CLASS SHOULD HAVE NO GAMEPLAY FUNCTIONALITY
# IF CLIENT_SIDE NEEDS FUNCTIONALITY, PUT IT IN THE PlayerController
# THIS IS JUST A VISUAL REPRESENTATION

class_name PlayerUnit

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
onready var slash_area = preload("res://Scenes/Instances/SlashArea.tscn")
onready var dagger = preload("res://Scenes/Instances/Dagger.tscn")

var colors = {
	"blue": preload("res://Materials/BlueUnit.tres"),
	"red": preload("res://Materials/RedUnit.tres"),
	"grey": preload("res://Materials/GreyUnit.tres")
}
var normal_color = "blue"


func _ready() -> void:
	if is_in_group("enemy"):
		body.material_override = colors.red
		normal_color = "red"


func _physics_process(delta):
	if path_ind < path.size():
		var move_vec = path[path_ind] - global_transform.origin
		if move_vec.length() < 0.1:
			path_ind += 1
		else:
			face_direction(move_vec, delta)
			var _vel = move_and_slide(move_vec.normalized() * move_speed, Vector3(0, 1, 0))


func move_player(pos: Vector3, basis: Quat):
	global_transform.origin = pos
	global_transform.basis = basis


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
	current_target_location = target_pos
	path = nav.get_simple_path(global_transform.origin, target_pos)
	path_ind = 0


func is_moving() -> bool:
	return path_ind < path.size()


# The spells to cast (mostly for animations when server comes i guess?)


func cast_spell(spell, options, cast_time):
	print(spell)
	if spell == GameData.spells.SHIELD:
		cast_shield()


# Shield
func cast_shield() -> void:
	$Shield.visible = true


func end_shield() -> void:
	$Shield.visible = false


# Blink
func cast_blink(pos: Vector3) -> void:
	stop()
	face_towards(pos)
	disjoint_dagger()

	var save_y = global_transform.origin.y

	global_transform.origin = pos

	global_transform.origin.y = save_y


func disjoint_dagger():
	get_tree().call_group("dagger", "blink_disjoint", self, global_transform.origin)


# Slash
func cast_slash(cast_point: Vector3) -> void:
	stop()
	face_towards(cast_point)
	var slash_area_inst = slash_area.instance()
	get_tree().get_root().add_child(slash_area_inst)
	slash_area_inst.start(global_transform.origin, cast_point, self)


# Stone
func cast_stone() -> void:
	body.material_override = colors.grey
	stop()


func end_stone() -> void:
	body.material_override = colors[normal_color]


# Dagger
func cast_dagger(target: KinematicBody) -> void:
	face_towards(target.global_transform.origin)

	var dagger_inst = dagger.instance()
	get_tree().get_root().add_child(dagger_inst)
	dagger_inst.start(global_transform.origin, target, self)


# Find closests enemy and attack it, if it dies do it again
func attack_move(target_pos: Vector3):
	move_to(target_pos)
	# attacking_unit = null
	# attack_moving = true


# Run to specific unit and attack it.
func attack_unit(target_unit: KinematicBody) -> void:
	move_to(target_unit.global_transform.origin)
	# attack_moving = false
	# attacking_unit = target_unit


# Stop all actions
func stop() -> void:
	# attack_moving = false
	# attacking_unit = null
	path = []


# Self got hit with a spell
func hit(spell: String, caster) -> void:
	pass
	# if dead:
	# 	return
	# if spell == "dagger":
	# 	if shield_active and not caster.dead:
	# 		cast_dagger(caster)

	# if spell == "slash":
	# 	pass

	# if not shield_active and not stone_active:
	# 	caster.refresh_spells()
	# 	die()


func die():
	disjoint_dagger()
	stop()
	global_transform.origin.y = -10
	visible = false
	dead = true
