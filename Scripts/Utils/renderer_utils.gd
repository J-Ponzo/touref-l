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