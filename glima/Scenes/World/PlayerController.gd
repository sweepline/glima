extends Spatial

var target_circle = preload("res://Scenes/Instances/ClickCircle.tscn")
onready var click_circle: MeshInstance = $ClickCircle

onready var camera_controller: Spatial = $CameraController
const floor_plane = Plane(0, 1, 0, 0)

# Player node, assume only one for now
onready var player = get_tree().get_nodes_in_group("player").pop_back()

# Target when hovering
var target_unit: KinematicBody
var target_reticle: MeshInstance

enum { NORMAL_MOVE, ATTACK_MOVE }


func _ready() -> void:
	click_circle.visible = false
	for enemy in get_tree().get_nodes_in_group("enemy"):
		enemy.connect("mouse_entered", self, "set_target", [enemy])
		enemy.connect("mouse_exited", self, "unset_target", [enemy])


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("menu"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	if player.dead:
		return
	var m_pos = get_viewport().get_mouse_position()

	if event.is_action_pressed("main_move"):
		if target_unit != null:
			player.attack_unit(target_unit)
			target_reticle.red()
		else:
			move_player(m_pos, NORMAL_MOVE)
	if event.is_action_pressed("attack_move"):
		if target_unit != null:
			player.attack_unit(target_unit)
			target_reticle.red()
		else:
			move_player(m_pos, ATTACK_MOVE)
	# abilities
	if event.is_action_pressed("spell_1"):
		player.cast_shield()
	if event.is_action_pressed("spell_2"):
		player.cast_blink(raycast_from_mouse(m_pos))
	if event.is_action_pressed("spell_3"):
		player.cast_slash(raycast_from_mouse(m_pos))
	if event.is_action_pressed("spell_4"):
		player.cast_stone()
	if event.is_action_pressed("spell_5"):
		player.cast_dagger(target_unit)
	if event.is_action_pressed("stop_move"):
		player.stop()
		if target_reticle != null:
			target_reticle.green()


func _process(_delta: float) -> void:
	pass


func move_player(m_pos: Vector2, type):
	var result = raycast_from_mouse(m_pos)
	if result:
		# Make an effect on the point clicked
		click_circle.global_transform.origin = Vector3(result.x, 0.01, result.z)
		click_circle.rotation = Vector3(-PI / 2, 0, 0)
		match type:
			NORMAL_MOVE:
				player.move_to(result)
				click_circle.green()
			ATTACK_MOVE:
				player.attack_move(result)
				click_circle.red()
		var anim_player = click_circle.get_node("AnimationPlayer")
		if anim_player.is_playing():
			anim_player.stop()
		anim_player.play("scale_down")


func raycast_from_mouse(m_pos: Vector2) -> Vector3:
	var ray_start = camera_controller.cam.project_ray_origin(m_pos)
	var ray_dir = camera_controller.cam.project_ray_normal(m_pos)
	return floor_plane.intersects_ray(ray_start, ray_dir)


func set_target(enemy) -> void:
	target_unit = enemy
	if target_reticle != null:
		target_reticle.queue_free()
	target_reticle = target_circle.instance()
	enemy.add_child(target_reticle)
	target_reticle.translate(Vector3(0, 0, 0.01))
	target_reticle.scale = Vector3(3, 3, 3)


func unset_target(enemy) -> void:
	if target_unit == enemy:
		target_unit = null
		if target_reticle != null:
			target_reticle.queue_free()
