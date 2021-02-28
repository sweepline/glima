extends MeshInstance

var colors = {
	"green": preload("res://GreenClickCircle.tres"),
	"red": preload("res://RedClickCircle.tres"),
}


func green():
	self.material_override = colors.green


func red():
	self.material_override = colors.red
