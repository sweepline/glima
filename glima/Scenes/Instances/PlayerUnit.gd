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

onready var nav: Navigation = get_parent()
onready var shape: CollisionShape = $CollisionShape
onready var body: MeshInstance = $PlayerModel/Armature/Skeleton/Knight
onready var slash_area = preload("res://Scenes/Instances/SlashArea.tscn")
onready var dagger = preload("res://Scenes/Instances/Dagger.tscn")
onready var anim_tree = $PlayerModel/AnimationTree

var colors = {
	"blue": preload("res://Assets/Knight/knight_blue.material"),
	"red": preload("res://Assets/Knight/knight_red.material"),
	"grey": preload("res://Assets/Knight/knight_stone.material")
}
var normal_color = "blue"

var dead = false
var shield_active = false
var stone_active = false

onready var cast_point_timer: Timer = $CastPointTimer


func _ready() -> void:
	anim_tree.active = true
	if is_in_group("enemy"):
		normal_color = "red"
	body.material_override = colors[normal_color]
	if name != str(get_tree().get_network_unique_id()):
		set_physics_process(false)


func _physics_process(delta):
	if path_ind < path.size():
		anim_tree.set("parameters/walk_state/current", 1)
		var move_vec = path[path_ind] - global_transform.origin
		if move_vec.length() < 0.1:
			path_ind += 1
		else:
			face_direction(move_vec, delta)
			var _vel = move_and_slide(move_vec.normalized() * move_speed, Vector3(0, 1, 0))
	else:
		anim_tree.set("parameters/walk_state/current", 0)


func move_player(pos: Vector3, basis: Quat):
	if pos != global_transform.origin:
		anim_tree.set("parameters/walk_state/current", 1)
	else:
		anim_tree.set("parameters/walk_state/current", 0)
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


func recalculate_nav():
	if current_target_location == null:
		return
	if global_transform.origin.distance_to(current_target_location) < 1:
		path = []
		global_transform.origin = current_target_location
	else:
		path = nav.get_simple_path(global_transform.origin, current_target_location)
		path_ind = 0


func move_to(target_pos: Vector3):
	current_target_location = target_pos
	path = nav.get_simple_path(global_transform.origin, target_pos)
	path_ind = 0


func is_moving() -> bool:
	return path_ind < path.size()


# The spells to cast (mostly for animations when server comes i guess?)


func cast_shield(_options) -> void:
	var data = GameData.spell_data["shield"]
	anim_tree.set("parameters/spell_slot/blend_position", 0)
	anim_tree.set("parameters/cast_spell/active", true)

	cast_point_timer.wait_time = data.cast_point
	cast_point_timer.connect("timeout", self, "main_cast_shield", [_options])
	cast_point_timer.start()


# Shield
func main_cast_shield(_options) -> void:
	var data = GameData.spell_data["shield"]

	$Shield.visible = true
	shield_active = true

	cast_point_timer.disconnect("timeout", self, "main_cast_shield")


func end_shield(_options) -> void:
	$Shield.visible = false
	shield_active = false


func cast_blink(options) -> void:
	var data = GameData.spell_data["blink"]
	anim_tree.set("parameters/spell_slot/blend_position", 1)
	anim_tree.set("parameters/cast_spell/active", true)

	cast_point_timer.wait_time = data.cast_point
	cast_point_timer.connect("timeout", self, "main_cast_blink", [options])
	cast_point_timer.start()


# Blink
func main_cast_blink(_options) -> void:
	var data = GameData.spell_data["blink"]
	cast_point_timer.disconnect("timeout", self, "main_cast_blink")


func cast_slash(options) -> void:
	var data = GameData.spell_data["slash"]
	anim_tree.set("parameters/spell_slot/blend_position", 2)
	anim_tree.set("parameters/cast_spell/active", true)
	cast_point_timer.wait_time = data.cast_point
	cast_point_timer.connect("timeout", self, "main_cast_slash", [options])
	cast_point_timer.start()


# Slash
func main_cast_slash(options) -> void:
	var data = GameData.spell_data["slash"]
	var cast_pos: Vector3 = options.p
	var slash_area_inst = slash_area.instance()
	get_tree().get_root().add_child(slash_area_inst)
	slash_area_inst.start(global_transform.origin, cast_pos, self)
	cast_point_timer.disconnect("timeout", self, "main_cast_slash")


func cast_stone(_opt) -> void:
	var data = GameData.spell_data["stone"]
	anim_tree.set("parameters/stone_timescale/scale", 0)
	cast_point_timer.wait_time = data.cast_point
	cast_point_timer.connect("timeout", self, "main_cast_stone", [_opt])
	cast_point_timer.start()


# Stone
func main_cast_stone(_options) -> void:
	var data = GameData.spell_data["stone"]
	stone_active = true
	body.material_override = colors.grey
	cast_point_timer.disconnect("timeout", self, "main_cast_stone")


func end_stone(_options) -> void:
	anim_tree.set("parameters/stone_timescale/scale", 1)
	body.material_override = colors[normal_color]
	stone_active = false


func cast_dagger(options) -> void:
	var data = GameData.spell_data["dagger"]

	if options.has("server") and options.server:
		# This is the rebound when shielded, different animation and no cast_point
		self.call("main_cast_dagger", [options])
		return

	anim_tree.set("parameters/spell_slot/blend_position", 4)
	anim_tree.set("parameters/cast_spell/active", true)
	cast_point_timer.wait_time = data.cast_point
	cast_point_timer.connect("timeout", self, "main_cast_dagger", [options])
	cast_point_timer.start()


# Dagger
func main_cast_dagger(options) -> void:
	var target: KinematicBody = get_node("/root/Main/World/Map/" + str(options.u))
	var dagger_inst = dagger.instance()
	get_tree().get_root().add_child(dagger_inst)
	dagger_inst.start(global_transform.origin, target, self)
	cast_point_timer.disconnect("timeout", self, "main_cast_dagger")


func cast_spin(_opt) -> void:
	var data = GameData.spell_data["spin"]
	anim_tree.set("parameters/spell_slot/blend_position", 5)
	anim_tree.set("parameters/cast_spell/active", true)
	cast_point_timer.wait_time = data.cast_point
	cast_point_timer.connect("timeout", self, "main_cast_spin", [_opt])
	cast_point_timer.start()


func main_cast_spin(_options) -> void:
	var data = GameData.spell_data["spin"]
	$SpinArea.start(data.range, self)
	cast_point_timer.disconnect("timeout", self, "main_cast_spin")


func hit(_type: String, _caster: String):
	pass


func die(_options):
	$SpinArea.stop()
	global_transform.origin.y = -10
	visible = false
	dead = true


func resurrect(options):
	global_transform.origin = options.position
	current_target_location = options.position
	visible = true
	dead = false
