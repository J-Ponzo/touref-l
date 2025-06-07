class_name _TL_Renderer

var scene_proxy : _TL_SceneProxy
var render_passes : Array[_TL_RenderPass]

var rd = RenderingServer.get_rendering_device()

func get_render_target() -> RID:
	return RID()

func _setup() -> void:
	for render_pass : _TL_RenderPass in render_passes:
		render_pass._setup()
	
func _cleanup() -> void:
	for render_pass : _TL_RenderPass in render_passes:
		render_pass._cleanup()

func _render() -> void:
	for render_pass : _TL_RenderPass in render_passes:
		render_pass._render()

# Utils
func create_color_attach() -> RID:
	var tf = RDTextureFormat.new();
	tf.usage_bits = RenderingDevice.TEXTURE_USAGE_COLOR_ATTACHMENT_BIT | RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT
	tf.width = ProjectSettings.get_setting("display/window/size/viewport_width")
	tf.height = ProjectSettings.get_setting("display/window/size/viewport_height")
	tf.format = RenderingDevice.DATA_FORMAT_R8G8B8A8_UNORM
	var view = RDTextureView.new();
	return rd.texture_create(tf, view)
	
func create_depth_attach() -> RID:
	var tf = RDTextureFormat.new();
	tf.usage_bits = RenderingDevice.TEXTURE_USAGE_DEPTH_STENCIL_ATTACHMENT_BIT
	tf.width = ProjectSettings.get_setting("display/window/size/viewport_width")
	tf.height = ProjectSettings.get_setting("display/window/size/viewport_height")
	tf.format = RenderingDevice.DATA_FORMAT_D32_SFLOAT
	var view = RDTextureView.new();
	return rd.texture_create(tf, view)
