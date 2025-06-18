extends Object
class_name TL_RendererUtils

static var rd = RenderingServer.get_rendering_device()

static func proj_to_bytes(proj: Projection) -> PackedByteArray:
	var floats = PackedFloat32Array([
		proj.x.x, proj.x.y, proj.x.z, proj.x.w,
		proj.y.x, proj.y.y, proj.y.z, proj.y.w,
		proj.z.x, proj.z.y, proj.z.z, proj.z.w,
		proj.w.x, proj.w.y, proj.w.z, proj.w.w
	])
	return floats.to_byte_array()

static func create_sampler_state(mag_filter = RenderingDevice.SAMPLER_FILTER_LINEAR, min_filter = RenderingDevice.SAMPLER_FILTER_LINEAR, repeat_u = RenderingDevice.SAMPLER_REPEAT_MODE_REPEAT, repeat_v = RenderingDevice.SAMPLER_REPEAT_MODE_REPEAT) -> RDSamplerState:
	var sampler_state := RDSamplerState.new()
	sampler_state.mag_filter = mag_filter
	sampler_state.min_filter = min_filter
	sampler_state.repeat_u = repeat_u
	sampler_state.repeat_v = repeat_v
	return sampler_state

static func create_texture_sampler_uniform(texture_rid : RID, sampler_rid : RID, binding : int) -> RDUniform:
	var uniform := RDUniform.new()
	uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_SAMPLER_WITH_TEXTURE
	uniform.binding = binding
	uniform.add_id(sampler_rid)
	uniform.add_id(texture_rid)

	return uniform

static func compile_shader(vertex_src : String, fragment_src : String) -> RID:
	var shader_source = RDShaderSource.new()
	shader_source.language = RenderingDevice.SHADER_LANGUAGE_GLSL;
	shader_source.source_vertex = vertex_src;
	shader_source.source_fragment = fragment_src;
	
	return rd.shader_create_from_spirv(rd.shader_compile_spirv_from_source(shader_source))

static func create_pipline(nb_color_attachments : int, shader_program : RID, framebuffer : RID, vertex_format : int, depth_test : bool = true) -> RID:
	var framebuffer_format = rd.framebuffer_get_format(framebuffer)
	var rasterizationState = RDPipelineRasterizationState.new()
	rasterizationState.cull_mode = RenderingDevice.POLYGON_CULL_DISABLED
	var multisampleState = RDPipelineMultisampleState.new()

	var depthStencilState = RDPipelineDepthStencilState.new()
	if depth_test:
		depthStencilState.enable_depth_test = true
		depthStencilState.enable_depth_write = true
		depthStencilState.depth_compare_operator = RenderingDevice.COMPARE_OP_LESS
	else:
		depthStencilState.enable_depth_test = false
		depthStencilState.enable_depth_write = false
		depthStencilState.depth_compare_operator = RenderingDevice.COMPARE_OP_ALWAYS
	
	var colorBlendState = RDPipelineColorBlendState.new()
	
	for i in range(nb_color_attachments):
		colorBlendState.attachments.append(RDPipelineColorBlendStateAttachment.new())
	return rd.render_pipeline_create(shader_program, framebuffer_format, vertex_format, RenderingDevice.RENDER_PRIMITIVE_TRIANGLES, rasterizationState, multisampleState, depthStencilState, colorBlendState)

static func create_pose_array_buffer(pose_array : Array[Projection]) -> RID:
	var bytes : PackedByteArray
	for pose_matrix in pose_array:
		bytes.append_array(TL_RendererUtils.proj_to_bytes(pose_matrix))

	return rd.uniform_buffer_create(bytes.size(), bytes)
		
