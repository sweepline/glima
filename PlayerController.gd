extends Spatial

var click_effect = preload("res://ClickCircle.tscn")
onready var camera_controller: Spatial = $CameraController
const floor_plane = Plane(0, 1, 0, 0)

# Player node, assume only one for now
onready var player = get_tree().get_nodes_in_group("player").pop_back()

# Target when hovering
var target_unit: KinematicBody
var target_reticle: MeshInstance


func _ready() -> void:
	for enemy in get_tree().get_nodes_in_group("enemy"):
		enemy.connect("mouse_entered", self, "set_target", [enemy])
		enemy.connect("mouse_exited", self, "unset_target", [enemy])


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("menu"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	if Input.is_action_just_pressed("main_move"):
		var m_pos = get_viewport().get_mouse_position()
		move_player(m_pos)


func move_player(m_pos: Vector2):
	var result = raycast_from_mouse(m_pos)
	if result:
		player.move_to(result)

		# Make an effect on the point clicked
		var click_effect_inst = click_effect.instance()
		get_tree().get_root().add_child(click_effect_inst)
		click_effect_inst.global_transform.origin = Vector3(result.x, 0.01, result.z)
		var anim_player = click_effect_inst.get_node("AnimationPlayer")
		anim_player.play("scale_down")


func raycast_from_mouse(m_pos: Vector2) -> Vector3:
	var ray_start = camera_controller.cam.project_ray_origin(m_pos)
	var ray_dir = camera_controller.cam.project_ray_normal(m_pos)
	return floor_plane.intersects_ray(ray_start, ray_dir)


func set_target(enemy) -> void:
	target_unit = enemy
	if target_reticle != null:
		target_reticle.queue_free()
	target_reticle = click_effect.instance()
	enemy.add_child(target_reticle)
	target_reticle.translate(Vector3(0, 0, 0.01))


func unset_target(enemy) -> void:
	if target_unit == enemy:
		target_unit = null
		if target_reticle != null:
			target_reticle.queue_free()
