class_name _TL_Renderer

var scene_proxy : _TL_SceneProxy
var render_passes : Dictionary[StringName, _TL_RenderPass]

var rd = RenderingServer.get_rendering_device()

func get_render_target() -> RID:
	return RID()

func _setup() -> void:
	for key : StringName in render_passes.keys():
		render_passes[key]._setup()
	
func _cleanup() -> void:
	for key : StringName in render_passes.keys():
		render_passes[key]._cleanup()

func _render() -> void:
	for key : StringName in render_passes.keys():
		render_passes[key]._render()
