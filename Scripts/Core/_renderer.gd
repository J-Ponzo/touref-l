class_name _TL_Renderer

var renderer_def : TL_RendererDef

var scene_proxy : _TL_SceneProxy
var render_passes : Dictionary[StringName, _TL_RenderPass]
var attachments : Dictionary[StringName, RID]
var feature_flag_manager : _TL_FeatureFlagManager
var proxy_model : _TL_ProxyModel
var proxy_queues : Dictionary[StringName, DataBucket]
var proxy_queue_manager : _TL_ProxyQueueManager
var sort_key_manager : _TL_SortKeyManager

var rd = RenderingServer.get_rendering_device()

func get_render_target() -> RID:
	return RID()

# TODO harmonize this and autoload singleton setups
func _setup() -> void:
	attachments = create_attachments_from_def(renderer_def.attachment_format_defs)
	for key : StringName in render_passes.keys():
		render_passes[key]._setup()
	
	if sort_key_manager != null:
		sort_key_manager._setup()
	proxy_queue_manager._setup()
	
func create_attachments_from_def(attachment_format_defs : Dictionary[StringName, TL_AttachmentFormat_Def]) -> Dictionary[StringName, RID]:
	var attachments : Dictionary[StringName, RID]

	for attach_key : StringName in attachment_format_defs.keys():
		var attachment : RID = _TL_Renderer_Factory.create_texture_attachment(attachment_format_defs[attach_key])
		attachments[attach_key] = attachment

	return attachments

func get_attachments(names : Array[StringName]) -> Array[RID]:
	var named_attachments : Array[RID]
	for name in names:
		named_attachments.append(attachments[name])
	return named_attachments

func _pre_renderer() -> void:
	if sort_key_manager != null:
		sort_key_manager._update()
	proxy_queue_manager._update()

func _render() -> void:
	for key : StringName in render_passes.keys():
		render_passes[key]._render()

func _cleanup() -> void:
	for key : StringName in render_passes.keys():
		render_passes[key]._cleanup()
	
	for attachment in attachments.values():
		rd.free_rid(attachment)
	attachments.clear()
