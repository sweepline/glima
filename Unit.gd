extends KinematicBody

class_name Unit

var current_target_location: Vector3
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


func move_to(target_pos: Vector3):
	current_target_location = target_pos
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
			face_direction(move_vec, delta)
			var _vel = move_and_slide(move_vec.normalized() * move_speed, Vector3(0, 1, 0))


func face_direction(dir: Vector3, delta: float):
	var angle_diff = global_transform.basis.z.angle_to(dir)
	var turn_right = sign(global_transform.basis.x.dot(dir))  # Turn right or left
	if abs(angle_diff) < turn_speed * delta:  # snap because we would overshoot
		rotation.y = atan2(dir.x, dir.z)  # angle, x and z because y is up
	else:
		rotation.y += turn_speed * delta * turn_right


# The spells to cast (mostly for animations when server comes i guess?)


# Shield
func cast_shield() -> void:
	print(self, " casted shield")
	pass


# Blink
func cast_blink(pos: Vector3) -> void:
	print(self, " casted blink")
	global_transform.origin = pos
	move_to(current_target_location)


# Slash
func cast_slash(pos: Vector3) -> void:
	print(self, " casted slash")
	pass


# Stone
func cast_stone() -> void:
	print(self, " casted stone")
	pass


# Dagger
func cast_dagger(target: KinematicBody) -> void:
	print(self, " casted dagger")
	pass


func attack() -> void:
	pass


func stop() -> void:
	path = []


func die() -> void:
	print("dead")
