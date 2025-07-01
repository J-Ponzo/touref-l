class_name _TL_RenderPass

# TODO test those msg
const  ERR_UNDEFINED_VERTEX_FORMAT = "TourefL : Invalid vertex pass %s. Undefined vertex format (you have to override define_vertex_format())"
const  ERR_UNDEFINED_DEPTH_ATTACHMENT = "TourefL : Invalid vertex pass %s. Undefined depth attachment (you have to override define_depth_attachment())"
const  ERR_UNDEFINED_COLOR_ATTACHMENT = "TourefL : Invalid vertex pass %s. Undefined color attachments (you have to override define_color_attachments())"

var render_pass_def : TL_RenderPassDef
var pso_defs : Dictionary[StringName, TL_PSODef]

var pso_name_to_mask : Dictionary[StringName, int]
var pso_instances : Dictionary[int, _TL_PSO]
var attachments : Dictionary[StringName, RID]

var renderer : _TL_Renderer

var framebuffer_format : int
var framebuffer : RID

func _setup() -> void:
	attachments = create_attachments_from_def(render_pass_def.fb_format_def.attachment_format_defs)
	framebuffer_format = create_framebuffer_format_from_def(render_pass_def.fb_format_def)
	framebuffer = renderer.rd.framebuffer_create(attachments.values())
	pso_name_to_mask = create_pso_name_to_mask(pso_defs)
	pso_instances = create_piplines_from_defs(pso_defs, pso_name_to_mask)

func get_or_create_pso_instance(mat_feature_flags_mask : int) -> _TL_PSO:
	if !pso_instances.has(mat_feature_flags_mask):
		var pso_def = _TL_Renderer_Factory.get_pso_def_from_mask_and_shaders(mat_feature_flags_mask, render_pass_def.uber_vertex_shader, render_pass_def.uber_fragment_shader)
		pso_instances[mat_feature_flags_mask] = _TL_Renderer_Factory.create_pso(pso_def, framebuffer_format, get_nb_color_attachments(render_pass_def.fb_format_def))
	return pso_instances[mat_feature_flags_mask]
	

func create_pso_name_to_mask(pso_defs : Dictionary[StringName, TL_PSODef]) -> Dictionary[StringName, int]:
	var pso_name_to_mask : Dictionary[StringName, int]
	for key in pso_defs.keys(): 
		pso_name_to_mask[key] = _TL_Renderer_Factory.get_mask_from_material_feature_flags_def(pso_defs[key].material_features_def)
	return pso_name_to_mask

func create_piplines_from_defs(pso_defs : Dictionary[StringName, TL_PSODef], pso_name_to_mask : Dictionary[StringName, int]) -> Dictionary[int, _TL_PSO]:
	var pso_instances : Dictionary[int, _TL_PSO] 
	for key in pso_defs.keys():
		var mask : int = pso_name_to_mask[key]
		pso_instances[mask] = _TL_Renderer_Factory.create_pso(pso_defs[key], framebuffer_format, get_nb_color_attachments(render_pass_def.fb_format_def))
	return pso_instances

func create_framebuffer_format_from_def(fb_format_def : TL_FramebufferFormat_Def) -> int:
	var attachment_formats : Array[RDAttachmentFormat]

	for attach_key : StringName in fb_format_def.attachment_format_defs.keys():
		var attachment_format : RDAttachmentFormat = RDAttachmentFormat.new()
		attachment_format.format = fb_format_def.attachment_format_defs[attach_key].format
		attachment_format.usage_flags = 0
		for bit in fb_format_def.attachment_format_defs[attach_key].usage_flags:
			attachment_format.usage_flags |= bit
		attachment_formats.append(attachment_format)

	return renderer.rd.framebuffer_format_create(attachment_formats)

func create_attachments_from_def(attachment_format_defs : Dictionary[StringName, TL_AttachmentFormat_Def]) -> Dictionary[StringName, RID]:
	var attachments : Dictionary[StringName, RID]

	for attach_key : StringName in attachment_format_defs.keys():
		var attachment : RID = _TL_Renderer_Factory.create_texture_attachment(attachment_format_defs[attach_key])
		attachments[attach_key] = attachment

	return attachments
	
func get_nb_color_attachments(fb_format_def : TL_FramebufferFormat_Def) -> int :
	if fb_format_def.attachment_format_defs.has(fb_format_def.depth_key):
		return fb_format_def.attachment_format_defs.size() - 1;
	return fb_format_def.attachment_format_defs.size();
	
func _cleanup() -> void:


	renderer.rd.free_rid(framebuffer)
	for pso_inst in pso_instances.values():
		renderer.rd.free_rid(pso_inst.pipeline)
		renderer.rd.free_rid(pso_inst.shader_program)
	pso_instances.clear()

	for attachment in attachments.values():
		renderer.rd.free_rid(attachment)
	attachments.clear()
	

func _render() -> void:
	pass
