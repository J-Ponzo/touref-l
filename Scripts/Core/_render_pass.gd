class_name _TL_RenderPass

# TODO test those msg
const  ERR_UNDEFINED_VERTEX_FORMAT = "TourefL : Invalid vertex pass %s. Undefined vertex format (you have to override define_vertex_format())"
const  ERR_UNDEFINED_DEPTH_ATTACHMENT = "TourefL : Invalid vertex pass %s. Undefined depth attachment (you have to override define_depth_attachment())"
const  ERR_UNDEFINED_COLOR_ATTACHMENT = "TourefL : Invalid vertex pass %s. Undefined color attachments (you have to override define_color_attachments())"

var pso_defs : Dictionary[String, TL_PSODef]
var pso_instances : Dictionary[String, RID]		# TODO String search could be ineficient.
var shader_programs : Dictionary[String, RID]

var renderer : _TL_Renderer

var vertex_format : int
var framebuffer : RID

var depth_attachment : RID
var color_attachments : Array[RID]

func _setup() -> void:
	vertex_format = define_vertex_format()
	depth_attachment = define_depth_attachment()
	color_attachments = define_color_attachments()
	framebuffer = create_framebuffer()
	pso_instances = create_piplines_from_defs(pso_defs)
	
func create_piplines_from_defs(pso_defs : Dictionary[String, TL_PSODef]) -> Dictionary[String, RID]:
	var pso_instances : Dictionary[String, RID] 
	for key in pso_defs.keys():
		shader_programs[key] = compile_shader_program(pso_defs[key])
		pso_instances[key] = create_pipline_from_def(key, pso_defs[key], shader_programs[key])
	return pso_instances

func compile_shader_program(pso_def : TL_PSODef) -> RID:
	var path : String = pso_def.vertex_shader.resource_path
	var raw_source : String = pso_def.vertex_shader.source_code
	var preprocessed_source : String = TL_Shader_Preprocessor.preprocess(path, raw_source)
	var vertex_shader_src : String = preprocessed_source
	
	path = pso_def.fragment_shader.resource_path
	raw_source = pso_def.fragment_shader.source_code
	preprocessed_source = TL_Shader_Preprocessor.preprocess(path, raw_source)
	var fragment_shader_src : String = preprocessed_source

	return compile_shader(vertex_shader_src, fragment_shader_src)

func create_pipline_from_def(pso_key : String, pso_def : TL_PSODef, shader_program : RID) -> RID:
	var has_depth_attachment : bool = depth_attachment != RID()

	var framebuffer_format = renderer.rd.framebuffer_get_format(framebuffer)
	var rasterizationState = RDPipelineRasterizationState.new()
	rasterizationState.cull_mode = RenderingDevice.POLYGON_CULL_DISABLED
	var multisampleState = RDPipelineMultisampleState.new()

	var depthStencilState = RDPipelineDepthStencilState.new()
	if has_depth_attachment:
		depthStencilState.enable_depth_test = true
		depthStencilState.enable_depth_write = true
		depthStencilState.depth_compare_operator = RenderingDevice.COMPARE_OP_LESS
	else:
		depthStencilState.enable_depth_test = false
		depthStencilState.enable_depth_write = false
		depthStencilState.depth_compare_operator = RenderingDevice.COMPARE_OP_ALWAYS
	
	var colorBlendState = RDPipelineColorBlendState.new()
	
	for i in range(define_color_attachments().size()):
		colorBlendState.attachments.append(RDPipelineColorBlendStateAttachment.new())
	var specific_vertex_format = vertex_format		# TODO remove this hard coded patch
	if pso_key == "draw_skeletal":
		specific_vertex_format = TL_DefaultModel.get_or_create_skeletal_mesh_vertex_format()
	return renderer.rd.render_pipeline_create(shader_program, framebuffer_format, specific_vertex_format, RenderingDevice.RENDER_PRIMITIVE_TRIANGLES, rasterizationState, multisampleState, depthStencilState, colorBlendState)

func _cleanup() -> void:
	renderer.rd.free_rid(framebuffer)
	for pipeline in pso_instances.values():
		renderer.rd.free_rid(pipeline)

func _render() -> void:
	pass

func define_vertex_format() -> int:
	push_error(ERR_UNDEFINED_VERTEX_FORMAT % self.get_script())
	return -1

func define_depth_attachment() -> RID:
	push_error(ERR_UNDEFINED_DEPTH_ATTACHMENT % self.get_script())
	return RID()

func define_color_attachments() -> Array[RID]:
	push_error(ERR_UNDEFINED_COLOR_ATTACHMENT % self.get_script())
	return []

func compile_shader(vertex_src : String, fragment_src : String) -> RID:
	var shader_source = RDShaderSource.new()
	shader_source.language = RenderingDevice.SHADER_LANGUAGE_GLSL;
	shader_source.source_vertex = vertex_src;
	shader_source.source_fragment = fragment_src;
	
	return renderer.rd.shader_create_from_spirv(renderer.rd.shader_compile_spirv_from_source(shader_source))

func create_framebuffer() -> RID:
	var all_attachments : Array[RID]
	if depth_attachment != RID():
		all_attachments.append(depth_attachment)
	all_attachments.append_array(color_attachments)
	return renderer.rd.framebuffer_create(all_attachments)
