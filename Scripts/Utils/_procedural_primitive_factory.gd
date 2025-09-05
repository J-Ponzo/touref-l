class_name TL_Procedural_Primitive_Factory

static func create_screen_quad() -> TL_Procedural_Primitive:
	var primitive : TL_Procedural_Primitive = TL_Procedural_Primitive.new()

	var position_data : PackedVector2Array = [Vector2(-1.0, -1.0), Vector2(1.0, -1.0), Vector2(1.0, 1.0), Vector2(-1.0, 1.0)]
	var byte_array : PackedByteArray = position_data.to_byte_array()
	primitive.position_buffer = _TL_Renderer_Factory.rd.vertex_buffer_create(byte_array.size(), byte_array)

	var uv_data : PackedVector2Array = [Vector2(0.0, 0.0), Vector2(1.0, 0.0), Vector2(1.0, 1.0), Vector2(0.0, 1.0)]
	byte_array = uv_data.to_byte_array()
	primitive.uv_buffer = _TL_Renderer_Factory.rd.vertex_buffer_create(byte_array.size(), byte_array)

	var index_data : PackedInt32Array = [0, 1, 2, 0, 2, 3]
	byte_array = index_data.to_byte_array()
	primitive.index_buffer = _TL_Renderer_Factory.rd.index_buffer_create(index_data.size(), RenderingDevice.INDEX_BUFFER_FORMAT_UINT32, byte_array)
	primitive.index_array = _TL_Renderer_Factory.rd.index_array_create(primitive.index_buffer, 0, index_data.size())

	_generate_vertex_array_from_data(primitive, 4, true)

	return primitive

static func _generate_vertex_array_from_data(primitive : TL_Procedural_Primitive, vertex_count : int, is_2d : bool = false) -> void:
	var vf_def : TL_VertexFormatDef = TL_VertexFormatDef.new()

	vf_def.is_2d = is_2d
	vf_def.has_normal = primitive.normal_buffer != RID()
	vf_def.has_tangent = primitive.tangent_buffer != RID()
	vf_def.has_color = primitive.color_buffer != RID()
	vf_def.has_uv = primitive.uv_buffer != RID()
	vf_def.has_uv2 = primitive.uv2_buffer != RID()
	vf_def.has_bones = primitive.bones_buffer != RID()
	vf_def.has_weights = primitive.weights_buffer != RID()

	var src_buffers : Array[RID]
	src_buffers.append(primitive.position_buffer)
	if vf_def.has_normal:
		src_buffers.append(primitive.normal_buffer)
	if vf_def.has_tangent:
		src_buffers.append(primitive.tangent_buffer)
	if vf_def.has_color:
		src_buffers.append(primitive.color_buffer)
	if vf_def.has_uv:
		src_buffers.append(primitive.uv_buffer)
	if vf_def.has_uv2:
		src_buffers.append(primitive.uv2_buffer)
	if vf_def.has_bones:
		src_buffers.append(primitive.bones_buffer)
	if vf_def.has_weights:
		src_buffers.append(primitive.weights_buffer)

	var vertex_format : int = _TL_Renderer_Factory.get_or_create_vertex_format(vf_def)

	primitive.vertex_array = _TL_Renderer_Factory.rd.vertex_array_create(vertex_count, vertex_format, src_buffers)

static func free_rids(primitive : TL_Procedural_Primitive) -> void:
	if primitive.index_array != RID():
		_TL_Renderer_Factory.rd.free_rid(primitive.index_array)
	if primitive.index_buffer != RID():
		_TL_Renderer_Factory.rd.free_rid(primitive.index_buffer)

	if primitive.vertex_array != RID():
		_TL_Renderer_Factory.rd.free_rid(primitive.vertex_array)
	if primitive.position_buffer != RID():
		_TL_Renderer_Factory.rd.free_rid(primitive.position_buffer)
	if primitive.normal_buffer != RID():
		_TL_Renderer_Factory.rd.free_rid(primitive.normal_buffer)
	if primitive.tangent_buffer != RID():
		_TL_Renderer_Factory.rd.free_rid(primitive.tangent_buffer)
	if primitive.color_buffer != RID():
		_TL_Renderer_Factory.rd.free_rid(primitive.color_buffer)
	if primitive.uv_buffer != RID():
		_TL_Renderer_Factory.rd.free_rid(primitive.uv_buffer)
	if primitive.uv2_buffer != RID():
		_TL_Renderer_Factory.rd.free_rid(primitive.uv2_buffer)
	if primitive.bones_buffer != RID():
		_TL_Renderer_Factory.rd.free_rid(primitive.weights_buffer)
