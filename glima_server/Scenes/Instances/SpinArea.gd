extends Area

var caster: KinematicBody
onready var spin_time = (2 * PI) / GameData.spell_data["spin"].duration


func _ready():
	visible = false
	$CollisionShape.disabled = true
	set_physics_process(false)


func _physics_process(delta):
	rotate_y(spin_time * delta)


func start(_range: float, _caster: KinematicBody):
	visible = true
	$CollisionShape.disabled = false
	$CollisionShape.shape.extents = Vector3(0.2, 2, _range)
	$CollisionShape.translation.z = -_range
	caster = _caster
	rotation.y = 0
	set_physics_process(true)

	yield(get_tree().create_timer(GameData.spell_data["spin"].duration), "timeout")
	stop()


func stop():
	print("STOP")
	set_physics_process(false)
	visible = false
	$CollisionShape.disabled = true


func _on_unit_entered(body):
	if body.name != caster.name:
		body.hit("spin", caster)
