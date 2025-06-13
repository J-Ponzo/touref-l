class_name _TL_RenderPass

# TODO test those msg
const  ERR_UNDEFINED_VERTEX_FORMAT = "TourefL : Invalid vertex pass %s. Undefined vertex format (you have to override define_vertex_format())"
const  ERR_UNDEFINED_DEPTH_ATTACHMENT = "TourefL : Invalid vertex pass %s. Undefined depth attachment (you have to override define_depth_attachment())"
const  ERR_UNDEFINED_COLOR_ATTACHMENT = "TourefL : Invalid vertex pass %s. Undefined color attachments (you have to override define_color_attachments())"

var vertex_shader_src : String
var fragment_shader_src : String
var renderer : _TL_Renderer

var shader_program : RID
var vertex_format : int
var pipeline : RID
var framebuffer : RID

var depth_attachment : RID
var color_attachments : Array[RID]

func _setup() -> void:
	shader_program = compile_shader(vertex_shader_src, fragment_shader_src)
	vertex_format = define_vertex_format()
	depth_attachment = define_depth_attachment()
	color_attachments = define_color_attachments()
	framebuffer = create_framebuffer()
	pipeline = create_pipeline()
	
func _cleanup() -> void:
	renderer.rd.free_rid(framebuffer)
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

func create_pipeline() -> RID :
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

	return renderer.rd.render_pipeline_create(shader_program, framebuffer_format, vertex_format, RenderingDevice.RENDER_PRIMITIVE_TRIANGLES, rasterizationState, multisampleState, depthStencilState, colorBlendState)

# Utils
func _proj_to_bytes(proj: Projection) -> PackedByteArray:
	var floats = PackedFloat32Array([
		proj.x.x, proj.x.y, proj.x.z, proj.x.w,
		proj.y.x, proj.y.y, proj.y.z, proj.y.w,
		proj.z.x, proj.z.y, proj.z.z, proj.z.w,
		proj.w.x, proj.w.y, proj.w.z, proj.w.w
	])
	return floats.to_byte_array()

func create_texture_sampler_uniform(texture_rid : RID, binding : int) -> RDUniform:
	var sampler_state := RDSamplerState.new()
	sampler_state.mag_filter = RenderingDevice.SAMPLER_FILTER_LINEAR
	sampler_state.min_filter = RenderingDevice.SAMPLER_FILTER_LINEAR
	sampler_state.repeat_u = RenderingDevice.SAMPLER_REPEAT_MODE_REPEAT
	sampler_state.repeat_v = RenderingDevice.SAMPLER_REPEAT_MODE_REPEAT
	var sampler_rid := renderer.rd.sampler_create(sampler_state)

	var uniform := RDUniform.new()
	uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_SAMPLER_WITH_TEXTURE
	uniform.binding = binding
	uniform.add_id(sampler_rid)
	uniform.add_id(texture_rid)

	return uniform
