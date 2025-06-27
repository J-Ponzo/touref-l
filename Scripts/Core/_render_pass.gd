class_name _TL_RenderPass

# TODO test those msg
const  ERR_UNDEFINED_VERTEX_FORMAT = "TourefL : Invalid vertex pass %s. Undefined vertex format (you have to override define_vertex_format())"
const  ERR_UNDEFINED_DEPTH_ATTACHMENT = "TourefL : Invalid vertex pass %s. Undefined depth attachment (you have to override define_depth_attachment())"
const  ERR_UNDEFINED_COLOR_ATTACHMENT = "TourefL : Invalid vertex pass %s. Undefined color attachments (you have to override define_color_attachments())"

var pso_defs : Dictionary[StringName, TL_PSODef]
var pso_instances : Dictionary[StringName, _TL_PSO]

var renderer : _TL_Renderer

var framebuffer : RID

var depth_attachment : RID
var color_attachments : Array[RID]

func _setup() -> void:
	depth_attachment = define_depth_attachment()
	color_attachments = define_color_attachments()
	framebuffer = create_framebuffer()
	pso_instances = create_piplines_from_defs(pso_defs)
	
func create_piplines_from_defs(pso_defs : Dictionary[StringName, TL_PSODef]) -> Dictionary[StringName, _TL_PSO]:
	var pso_instances : Dictionary[StringName, _TL_PSO] 
	for key in pso_defs.keys():
		pso_instances[key] = _TL_Renderer_Factory.create_pso(pso_defs[key], framebuffer, color_attachments.size())
	return pso_instances
	
func _cleanup() -> void:
	renderer.rd.free_rid(framebuffer)
	for pso_inst in pso_instances.values():
		renderer.rd.free_rid(pso_inst.pipeline)
		renderer.rd.free_rid(pso_inst.shader_program)

func _render() -> void:
	pass

func define_depth_attachment() -> RID:
	push_error(ERR_UNDEFINED_DEPTH_ATTACHMENT % self.get_script())
	return RID()

func define_color_attachments() -> Array[RID]:
	push_error(ERR_UNDEFINED_COLOR_ATTACHMENT % self.get_script())
	return []

func create_framebuffer() -> RID:
	var all_attachments : Array[RID]
	if depth_attachment != RID():
		all_attachments.append(depth_attachment)
	all_attachments.append_array(color_attachments)
	return renderer.rd.framebuffer_create(all_attachments)
