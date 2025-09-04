class_name _TL_RenderPass

const ERR_PSOFACTORY_WRONG_PARENT = "TourefL : Cannot instantiate the pso factory from class %s. It must inherit from _TL_PSOFactory."

var render_pass_def : TL_RenderPassDef

var pso_factories : Dictionary[StringName, _TL_PSOFactory]

var explicits_pso : Dictionary[StringName, _TL_PSO]

var renderer : _TL_Renderer

var framebuffer_format : int
var framebuffer : RID

func _setup() -> void:
	framebuffer_format = create_framebuffer_format_from_def(render_pass_def.fb_format_def)

	var attachments : Array[RID] = renderer.get_attachments(render_pass_def.fb_format_def.get_all_attachment_keys())
	framebuffer = renderer.rd.framebuffer_create(attachments, framebuffer_format)
	explicits_pso = create_explicits_pso_from_defs(render_pass_def.explicite_pso_defs)
	pso_factories = create_pso_factories_from_defs(render_pass_def.generated_pso_defs, framebuffer_format, get_nb_color_attachments(render_pass_def.fb_format_def))

func create_pso_factories_from_defs(generated_pso_defs : Dictionary[StringName, TL_GeneratedPSODef], framebuffer_format : int, nb_color_attachment : int) -> Dictionary[StringName, _TL_PSOFactory]:
	var factories : Dictionary[StringName, _TL_PSOFactory]
	for key in generated_pso_defs.keys():
		var generated_pso_def : TL_GeneratedPSODef = generated_pso_defs[key]
		var pso_factory_inst = generated_pso_def.factory_script.new()
		if pso_factory_inst is _TL_PSOFactory:
			pso_factory_inst.render_pass = self
			pso_factory_inst.generated_pso_def = generated_pso_def
			pso_factory_inst.framebuffer_format = framebuffer_format
			pso_factory_inst.nb_color_attachments = nb_color_attachment
			factories[key] = pso_factory_inst
		else :
			push_error(ERR_PSOFACTORY_WRONG_PARENT % generated_pso_def.factory_script)
	return factories

func create_explicits_pso_from_defs(explicit_pso_defs : Dictionary[StringName, TL_ExpicitPSODef]) -> Dictionary[StringName, _TL_PSO]:
	var pso_instances : Dictionary[StringName, _TL_PSO] 
	for key in explicit_pso_defs.keys():
		pso_instances[key] = _TL_Renderer_Factory.create_pso(explicit_pso_defs[key], framebuffer_format)
	return pso_instances

func create_piplines_from_defs(pso_defs : Dictionary[StringName, TL_ExpicitPSODef], pso_name_to_mask : Dictionary[StringName, int]) -> Dictionary[int, _TL_PSO]:
	var pso_instances : Dictionary[int, _TL_PSO] 
	for key in pso_defs.keys():
		var mask : int = pso_name_to_mask[key]
		pso_instances[mask] = _TL_Renderer_Factory.create_pso(pso_defs[key], framebuffer_format)
	return pso_instances

func create_framebuffer_format_from_def(fb_format_def : TL_FramebufferFormat_Def) -> int:
	var attachment_formats : Array[RDAttachmentFormat]

	for attach_key : StringName in fb_format_def.get_all_attachment_keys():
		var attachment_format : RDAttachmentFormat = RDAttachmentFormat.new()
		attachment_format.format = renderer.renderer_def.attachment_format_defs[attach_key].format
		attachment_format.usage_flags = 0
		for bit in renderer.renderer_def.attachment_format_defs[attach_key].usage_flags:
			attachment_format.usage_flags |= bit
		attachment_formats.append(attachment_format)

	return renderer.rd.framebuffer_format_create(attachment_formats)
	
func get_nb_color_attachments(fb_format_def : TL_FramebufferFormat_Def) -> int :
	return fb_format_def.color_keys.size()
	
func _cleanup() -> void:
	renderer.rd.free_rid(framebuffer)
	for pso_factorie in pso_factories.values():
		pso_factorie._cleanup()
	explicits_pso.clear()
	pso_factories.clear()
	

func _render() -> void:
	pass
