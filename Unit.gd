extends KinematicBody

class_name Unit

var path = []
var path_ind = 0
const move_speed = 12
export var turn_speed = 20

var id: int

onready var nav: Navigation = get_parent()
onready var shape: CollisionShape = $CollisionShape
onready var body: MeshInstance = $Body


func _ready() -> void:
	if is_in_group("enemy"):
		var red_mat = load("res://RedUnit.tres")
		body.material_override = red_mat


func move_to(target_pos):
	path = nav.get_simple_path(global_transform.origin, target_pos)
	path_ind = 0


func _process(_delta: float):
	pass


func _physics_process(delta):
	if path_ind < path.size():
		var move_vec = path[path_ind] - global_transform.origin
		if move_vec.length() < 0.1:
			path_ind += 1
		else:
			var _vel = move_and_slide(move_vec.normalized() * move_speed, Vector3(0, 1, 0))
			face_direction(move_vec, delta)


func face_direction(dir: Vector3, delta: float):
	var angle_diff = global_transform.basis.z.angle_to(dir)
	var turn_right = sign(global_transform.basis.x.dot(dir))  # Turn right or left
	if abs(angle_diff) < turn_speed * delta:  # snap because we would overshoot
		rotation.y = atan2(dir.x, dir.z)  # angle, x and z because y is up
	else:
		rotation.y += turn_speed * delta * turn_right


# The spells to cast (mostly for animations when server comes i guess?)


func cast_spell_1() -> void:
	pass


func cast_spell_2() -> void:
	pass


func cast_spell_3() -> void:
	pass


func cast_spell_4() -> void:
	pass


func cast_spell_5() -> void:
	pass


func cast_spell_6() -> void:
	pass
