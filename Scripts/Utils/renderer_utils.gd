extends Object
class_name TL_RendererUtils

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