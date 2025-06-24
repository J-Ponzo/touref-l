class_name _TL_Renderer_Factory

const ERR_RENDERER_WRONG_PARENT = "TourefL : Cannot instantiate the renderer from class %s. It must inherit from _TL_Renderer."
const ERR_SCNPROXY_WRONG_PARENT = "TourefL : Cannot instantiate the scene proxy from class %s. It must inherit from _TL_SceneProxy."
const ERR_RENDERPASS_WRONG_PARENT = "TourefL : Cannot instantiate the render pass from class %s. It must inherit from _TL_RenderPass."

const SIZEOF_FLOAT = 4
const SIZEOF_INT = 4
const POSITION_NB_FLOATS = 3
const NORMAL_NB_FLOATS = 3
const TAGENT_NB_FLOATS = 4
const COLOR_NB_FLOATS = 4
const UV_NB_FLOATS = 2
const UV2_NB_FLOATS = 2
const BONES_NB_INTS = 4
const WEIGHT_NB_FLOATS = 4

static var rd = RenderingServer.get_rendering_device()

static func create_renderer(renderer_def : TL_RendererDef) -> _TL_Renderer:
	var renderer_inst = renderer_def.renderer_script.new()
	if renderer_inst is _TL_Renderer:
		var scn_proxy_inst = renderer_def.scene_proxy_script.new()
		if scn_proxy_inst is _TL_SceneProxy:
			var scene_proxy : _TL_SceneProxy = scn_proxy_inst
			var renderer : _TL_Renderer = renderer_inst
			renderer.scene_proxy = scene_proxy
			for render_pass_def : TL_RenderPassDef in renderer_def.renderer_pass_defs:
				var render_pass_inst = create_render_pass(renderer, render_pass_def)
			return renderer
		else :
			push_error(ERR_SCNPROXY_WRONG_PARENT % renderer_def.scene_proxy_script)
	else :
		push_error(ERR_RENDERER_WRONG_PARENT % renderer_def.renderer_script)
	
	return null

static func create_render_pass(renderer_inst : _TL_Renderer, render_pass_def : TL_RenderPassDef) -> _TL_RenderPass:
	var render_pass_inst = render_pass_def.pass_script.new()
	if render_pass_inst is _TL_RenderPass:
		var render_pass : _TL_RenderPass = render_pass_inst
		render_pass.pso_defs = render_pass_def.pso_defs
		render_pass.renderer = renderer_inst
		renderer_inst.render_passes.append(render_pass)
		return render_pass
	else:
		push_error(ERR_RENDERPASS_WRONG_PARENT % render_pass_def.pass_script)
	
	return null

static func get_mask_from_vertex_attrs(has_normal : bool, has_tangent : bool, has_color : bool, has_uv : bool, has_uv2 : bool, has_bones : bool, has_weights : bool) -> int:
	var mask : int = 0
	mask |= 1 << 0 if has_normal else 0
	mask |= 1 << 1 if has_tangent else 0
	mask |= 1 << 2 if has_color else 0
	mask |= 1 << 3 if has_uv else 0
	mask |= 1 << 4 if has_uv2 else 0
	mask |= 1 << 5 if has_bones else 0
	mask |= 1 << 6 if has_weights else 0
	return mask

static var vertex_formats_cache : Dictionary[int, int]

static func get_or_create_vertex_format(has_normal : bool, has_tangent : bool, has_color : bool, has_uv : bool, has_uv2 : bool, has_bones : bool, has_weights : bool) -> int:
	var mask : int = get_mask_from_vertex_attrs(has_normal, has_tangent, has_color, has_uv, has_uv2, has_bones, has_weights) 
	if !vertex_formats_cache.has(mask):
		vertex_formats_cache[mask] = create_vertex_format(has_normal, has_tangent, has_color, has_uv, has_uv2, has_bones, has_weights)
	return vertex_formats_cache[mask]

static func create_vertex_format(has_normal : bool, has_tangent : bool, has_color : bool, has_uv : bool, has_uv2 : bool, has_bones : bool, has_weights : bool) -> int:
	var attrs : Array[RDVertexAttribute]

	var positionAttr = RDVertexAttribute.new()
	positionAttr.format = RenderingDevice.DATA_FORMAT_R32G32B32_SFLOAT;
	positionAttr.stride = POSITION_NB_FLOATS * SIZEOF_FLOAT
	positionAttr.offset = 0
	attrs.append(positionAttr)

	if has_normal:
		var normalAttr = RDVertexAttribute.new()
		normalAttr.format = RenderingDevice.DATA_FORMAT_R32G32B32_SFLOAT;
		normalAttr.stride = NORMAL_NB_FLOATS * SIZEOF_FLOAT
		normalAttr.offset = 0
		attrs.append(normalAttr)

	if has_tangent:
		var tangentAttr = RDVertexAttribute.new()
		tangentAttr.format = RenderingDevice.DATA_FORMAT_R32G32B32A32_SFLOAT ;
		tangentAttr.stride = TAGENT_NB_FLOATS * SIZEOF_FLOAT
		tangentAttr.offset = 0
		attrs.append(tangentAttr)

	if has_color:
		var colorAttr = RDVertexAttribute.new()
		colorAttr.format = RenderingDevice.DATA_FORMAT_R32G32B32A32_SFLOAT ;
		colorAttr.stride = COLOR_NB_FLOATS * SIZEOF_FLOAT
		colorAttr.offset = 0
		attrs.append(colorAttr)

	if has_uv:
		var uvAttr = RDVertexAttribute.new()
		uvAttr.format = RenderingDevice.DATA_FORMAT_R32G32_SFLOAT;
		uvAttr.stride = UV_NB_FLOATS * SIZEOF_FLOAT
		uvAttr.offset = 0
		attrs.append(uvAttr)

	if has_uv2:
		var uv2Attr = RDVertexAttribute.new()
		uv2Attr.format = RenderingDevice.DATA_FORMAT_R32G32_SFLOAT;
		uv2Attr.stride = UV_NB_FLOATS * SIZEOF_FLOAT
		uv2Attr.offset = 0
		attrs.append(uv2Attr)

	if has_bones:
		var bonesAttr = RDVertexAttribute.new()
		bonesAttr.format = RenderingDevice.DATA_FORMAT_R32G32B32A32_SINT;
		bonesAttr.stride = BONES_NB_INTS * SIZEOF_INT
		bonesAttr.offset = 0
		attrs.append(bonesAttr)

	if has_weights:
		var weightsAttr = RDVertexAttribute.new()
		weightsAttr.format = RenderingDevice.DATA_FORMAT_R32G32B32A32_SFLOAT;
		weightsAttr.stride = WEIGHT_NB_FLOATS * SIZEOF_FLOAT
		weightsAttr.offset = 0
		attrs.append(weightsAttr)

	for i in range(attrs.size()):
		attrs[i].location = i

	return rd.vertex_format_create(attrs)