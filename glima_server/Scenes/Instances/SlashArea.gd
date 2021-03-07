extends Area

export var speed = 30
var distance_traveled = 0
var caster: KinematicBody
export var TRAVEL_DISTANCE = 20


func start(position: Vector3, cast_point: Vector3, _caster: KinematicBody):
	caster = _caster
	look_at_from_position(position, cast_point, Vector3.UP)
	global_transform.origin.y = 0
	rotation.x = 0


func _physics_process(delta):
	distance_traveled += speed * delta
	var move_vec = global_transform.basis.z * speed * delta
	move_vec.y = 0
	global_transform.origin -= move_vec

	if distance_traveled > TRAVEL_DISTANCE:
		queue_free()


func _on_unit_entered(body):
	if body.name != caster.name:
		body.hit("slash", caster)
