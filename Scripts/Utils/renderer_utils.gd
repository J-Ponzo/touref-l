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

static func create_mat4_array_uniform_buffer(proj_array : Array[Projection]) -> RID:
	var bytes : PackedByteArray
	for proj_matrix in proj_array:
		bytes.append_array(TL_RendererUtils.proj_to_bytes(proj_matrix))

	return rd.uniform_buffer_create(bytes.size(), bytes)

static func create_particles_instance_storage_buffer(transform_array : Array[Transform3D], color_array : Array[Color]) -> RID:
	var bytes : PackedByteArray
	for idx : int in transform_array.size():
		bytes.append_array(TL_RendererUtils.proj_to_bytes(Projection(transform_array[idx])))
		var color : PackedColorArray = [color_array[idx]]
		bytes.append_array(color.to_byte_array())

	return rd.storage_buffer_create(bytes.size(), bytes)

static func update_particles_instance_storage_buffer(instance_storage_buffer : RID, transform_array : Array[Transform3D], color_array : Array[Color]) -> void:
	var bytes : PackedByteArray
	for idx : int in transform_array.size():
		bytes.append_array(TL_RendererUtils.proj_to_bytes(Projection(transform_array[idx])))
		var color : PackedColorArray = [color_array[idx]]
		bytes.append_array(color.to_byte_array())

	rd.buffer_update(instance_storage_buffer, 0, bytes.size(), bytes)
