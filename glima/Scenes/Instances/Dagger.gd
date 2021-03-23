extends Area

export var speed = 30

var target: KinematicBody = null
var caster: KinematicBody = null
var start_distance: float
var disjointed = false
var saved_target_position: Vector3 = Vector3.ZERO


func start(position: Vector3, _target: KinematicBody, _caster: KinematicBody):
	target = _target
	caster = _caster
	look_at_from_position(position, target.global_transform.origin, Vector3.UP)
	rotation.x = PI / 6  # Range lerp, we need to throw further up if we are further away
	global_transform.origin.y = 0.4
	start_distance = global_transform.origin.distance_to(target.global_transform.origin)


func _physics_process(delta):
	var target_center = Vector3(
		target.global_transform.origin.x, 0.5, target.global_transform.origin.z
	)
	if disjointed:
		target_center = saved_target_position

	var towards_target = global_transform.looking_at(target_center, Vector3.UP)

	var distance = global_transform.origin.distance_to(target_center)

	if disjointed and distance < 1:
		queue_free()

	var steer_force = range_lerp(distance, start_distance, 0, 0, 30)

	global_transform.basis = global_transform.basis.slerp(
		towards_target.basis.get_rotation_quat(), delta * steer_force
	)

	var move_vec = global_transform.basis.z * speed * delta
	global_transform.origin -= move_vec


func _on_unit_entered(body):
	if body == target:
		body.hit("dagger", caster.name)
		visible = false
		queue_free()


func blink_disjoint(options):
	if options.blink_caster == target:
		disjointed = true
		saved_target_position = options.caster_position
		saved_target_position.y = 0
