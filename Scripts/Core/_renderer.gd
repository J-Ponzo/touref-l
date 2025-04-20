class_name _TL_Renderer

var vertex_shader_src : String
var fragment_shader_src : String
var scene_proxy : _TL_SceneProxy

var rd = RenderingServer.get_rendering_device()

func get_render_target() -> RID:
	return RID()

func _setup() -> void:
	pass
	
func _cleanup() -> void:
	pass

func _render(root : Node) -> void:
	pass
