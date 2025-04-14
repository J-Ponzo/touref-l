extends Node
class_name _TL_Renderer

var vertex_shader_src : String
var fragment_shader_src : String

var rd = RenderingServer.get_rendering_device()

func _setup() -> void:
	pass
	
func _cleanup() -> void:
	pass

func _render(root : Node) -> void:
	pass
