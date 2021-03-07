extends Spatial

const MOVE_MARGIN = 20
const MOVE_SPEED = 60
const DRAG_SPEED = 40
const MAX_ZOOM = 40
const MIN_ZOOM = 15

const ray_length = 1000
onready var cam: Camera = $Camera

const floor_plane = Plane(0, 1, 0, 0)
var mouse_pos = null
var dragging = false
var drag_m_start: Vector3
var drag_m_prev: Vector2
var drag_c_start: Vector3

func enable():
	set_process_input(true)
	set_process(true)
	set_physics_process(true)

func disable():
	set_process_input(true)
	set_process(false)
	set_physics_process(false)


func _process(delta: float):
	if Input.is_action_just_pressed("drag_cam"):
		var m_pos = get_viewport().get_mouse_position()
		drag_m_start = raycast_from_mouse(m_pos)
		drag_m_prev = m_pos
		drag_c_start = global_transform.origin
		dragging = true
	elif Input.is_action_just_released("drag_cam"):
		dragging = false

	if Input.is_action_just_released("zoom_in"):
		cam.translation.z = max(cam.translation.z - 2, MIN_ZOOM)
	if Input.is_action_just_released("zoom_out"):
		cam.translation.z = min(cam.translation.z + 2, MAX_ZOOM)

	if Input.is_action_pressed("center_cam"):
		if get_parent().player == null:
			return
		# Assuming just one player controlled character
		var player_loc = get_parent().player.global_transform.origin
		# Basically when were close we dont want to interpolate the camera position anymore
		if global_transform.origin.distance_squared_to(player_loc) < 0.25:
			global_transform.origin = player_loc
		else:
			global_transform.origin = global_transform.origin.linear_interpolate(
				player_loc, delta * MOVE_SPEED
			)


func _physics_process(delta: float):
	var m_pos: Vector2 = get_viewport().get_mouse_position()
	if dragging:
		drag_camera(m_pos, delta)
	if ! dragging:
		move_camera(m_pos, delta)


func drag_camera(m_current: Vector2, delta: float) -> void:
	var drag_m_current = raycast_from_mouse(m_current)
	var m_diff = drag_m_current - drag_m_start
	var new_pos = global_transform.origin - m_diff
	global_transform.origin = global_transform.origin.linear_interpolate(
		new_pos, delta * DRAG_SPEED
	)


func move_camera(m_pos: Vector2, delta: float) -> void:
	var v_size = get_viewport().size
	var move_vec = Vector3()
	if m_pos.x < MOVE_MARGIN:
		move_vec.x -= 1
	if m_pos.y < MOVE_MARGIN:
		move_vec.z -= 1
	if m_pos.x > v_size.x - MOVE_MARGIN:
		move_vec.x += 1
	if m_pos.y > v_size.y - MOVE_MARGIN:
		move_vec.z += 1
	move_vec = move_vec.rotated(Vector3.UP, rotation_degrees.y)
	global_translate(move_vec * delta * MOVE_SPEED)


func raycast_from_mouse(m_pos: Vector2) -> Vector3:
	var ray_start = cam.project_ray_origin(m_pos)
	var ray_dir = cam.project_ray_normal(m_pos)
	return floor_plane.intersects_ray(ray_start, ray_dir)
