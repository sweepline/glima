extends MeshInstance

var colors = {
	"green": preload("res://Materials/GreenClickCircle.tres"),
	"red": preload("res://Materials/RedClickCircle.tres"),
}


func green():
	self.material_override = colors.green


func red():
	self.material_override = colors.red
