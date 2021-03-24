extends ImmediateGeometry

export var resolution = 16


func _ready():
	draw_circle(Vector3(0, 1, 0), 2)


func draw_circle(_circle_center, circle_radius, elevation = 0):
	var UP = Vector3(0, 1, 0)
	var circle_center = Vector3(_circle_center.x, _circle_center.y + elevation, _circle_center.z)
	clear()
	begin(Mesh.PRIMITIVE_LINE_LOOP)
	for i in range(int(resolution)):
		var rotation = float(i) / resolution * TAU
		add_vertex(Vector3(circle_radius, 0, 0).rotated(UP, rotation) + circle_center)
	end()
