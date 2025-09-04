class_name _TL_Renderer_Factory

const ERR_RENDERER_WRONG_PARENT = "TourefL : Cannot instantiate the renderer from class %s. It must inherit from _TL_Renderer."
const ERR_SCNPROXY_WRONG_PARENT = "TourefL : Cannot instantiate the scene proxy from class %s. It must inherit from _TL_SceneProxy."
const ERR_RENDERPASS_WRONG_PARENT = "TourefL : Cannot instantiate the render pass from class %s. It must inherit from _TL_RenderPass."
const ERR_FEATUREFLAG_WRONG_PARENT = "TourefL : Cannot instantiate the feature flag manager from class %s. It must inherit from _TL_FeatureFlagManager."
const ERR_PROXYQUEUEMANAGER_WRONG_PARENT = "TourefL : Cannot instantiate the proxy queue manager from class %s. It must inherit from _TL_ProxyQueueManager."
const ERR_SORTKEYMANAGER_WRONG_PARENT = "TourefL : Cannot instantiate the sort key manager from class %s. It must inherit from _TL_SortKeyManager."
const ERR_PROXYMODEL_WRONG_PARENT = "TourefL : Cannot instantiate the feature flag manager from class %s. It must inherit from _TL_ProxyModel."

const SIZEOF_FLOAT = 4
const SIZEOF_INT = 4
const POSITION_2D_NB_FLOATS = 2
const POSITION_3D_NB_FLOATS = 3
const NORMAL_NB_FLOATS = 3
const TAGENT_NB_FLOATS = 4
const COLOR_NB_FLOATS = 4
const UV_NB_FLOATS = 2
const UV2_NB_FLOATS = 2
const BONES_NB_INTS = 4
const WEIGHT_NB_FLOATS = 4

static var rd = RenderingServer.get_rendering_device()

# TODO Handle more definition errors
# TODO Refact make generic managers
static func create_renderer(renderer_def : TL_RendererDef) -> _TL_Renderer:
	var renderer_inst = renderer_def.renderer_script.new()
	if renderer_inst is _TL_Renderer:
		var renderer : _TL_Renderer = renderer_inst
		renderer.renderer_def = renderer_def
		var scn_proxy_inst = renderer_def.scene_proxy_script.new()
		if scn_proxy_inst is _TL_SceneProxy:
			var scene_proxy : _TL_SceneProxy = scn_proxy_inst
			scene_proxy.render = renderer
			renderer.scene_proxy = scene_proxy
			for key : StringName in renderer_def.renderer_pass_defs.keys():
				create_render_pass(renderer, key, renderer_def.renderer_pass_defs[key])
		else :
			push_error(ERR_SCNPROXY_WRONG_PARENT % renderer_def.scene_proxy_script)
			
		if renderer_def.feature_flag_manager_def != null:	# TODO check if feature flag manager is mandatory
			var feature_flag_manager_inst = renderer_def.feature_flag_manager_def.manager_script.new()
			if feature_flag_manager_inst is _TL_FeatureFlagManager:
				var feature_flag_manager : _TL_FeatureFlagManager = feature_flag_manager_inst
				feature_flag_manager.feature_flag_manager_def = renderer_def.feature_flag_manager_def
				renderer_inst.feature_flag_manager = feature_flag_manager
			else:
				push_error(ERR_FEATUREFLAG_WRONG_PARENT % renderer_def.feature_flag_manager_def.manager_script)

		var proxy_model_inst = renderer_def.proxy_model_script.new()
		if proxy_model_inst is _TL_ProxyModel:
			var proxy_model : _TL_ProxyModel = proxy_model_inst
			renderer.proxy_model = proxy_model
			proxy_model.renderer = renderer
			for key : StringName in renderer_def.renderer_pass_defs.keys():
				create_render_pass(renderer, key, renderer_def.renderer_pass_defs[key])
		else:
			push_error(ERR_PROXYMODEL_WRONG_PARENT % renderer_def.scene_proxy_script)
		
		var proxy_queue_manager_inst = renderer_def.proxy_queues_manager_def.manager_script.new()
		if proxy_queue_manager_inst is _TL_ProxyQueueManager:
			var proxy_queue_manager : _TL_ProxyQueueManager = proxy_queue_manager_inst
			proxy_queue_manager.renderer = renderer
			proxy_queue_manager.proxy_queue_manager_def = renderer_def.proxy_queues_manager_def
			renderer.proxy_queue_manager = proxy_queue_manager
		else:
			push_error(ERR_PROXYQUEUEMANAGER_WRONG_PARENT % renderer_def.proxy_queues_manager_def.manager_script)

		if renderer_def.sort_key_manager_def != null:	# TODO check ifsort key manager is mandatory
			var sort_key_manager_inst = renderer_def.sort_key_manager_def.manager_script.new()
			if sort_key_manager_inst is _TL_SortKeyManager:
				var sort_key_manager : _TL_SortKeyManager = sort_key_manager_inst
				sort_key_manager.sort_key_manager_def = renderer_def.sort_key_manager_def
				sort_key_manager.renderer = renderer
				renderer.sort_key_manager = sort_key_manager
			else:
				push_error(ERR_SORTKEYMANAGER_WRONG_PARENT % renderer_def.sort_key_manager_def.manager_script)

		return renderer
	else :
		push_error(ERR_RENDERER_WRONG_PARENT % renderer_def.renderer_script)
	
	return null

static func create_render_pass(renderer_inst : _TL_Renderer, render_pass_key : StringName, render_pass_def : TL_RenderPassDef) -> _TL_RenderPass:
	var render_pass_inst = render_pass_def.pass_script.new()
	if render_pass_inst is _TL_RenderPass:
		var render_pass : _TL_RenderPass = render_pass_inst
		render_pass.render_pass_def = render_pass_def
		render_pass.renderer = renderer_inst
		renderer_inst.render_passes[render_pass_key] = render_pass

		return render_pass
	else:
		push_error(ERR_RENDERPASS_WRONG_PARENT % render_pass_def.pass_script)
	
	return null

static func get_mask_from_bool_array(bools : Array[bool]) -> int:
	if bools.size() > 32:
		return -1
	var mask : int = 0
	for i in bools.size():
		mask |= 1 << i if bools[i] else 0
	return mask

static func get_vertex_format_def_from_material_data(material : BaseMaterial3D, is_skeletal : bool) -> TL_VertexFormatDef:
	var vf_def : TL_VertexFormatDef = TL_VertexFormatDef.new()

	vf_def.is_2d = false
	vf_def.has_normal = material.shading_mode != BaseMaterial3D.ShadingMode.SHADING_MODE_UNSHADED
	vf_def.has_tangent = material.shading_mode != BaseMaterial3D.ShadingMode.SHADING_MODE_UNSHADED
	vf_def.has_color = false
	vf_def.has_uv = material.albedo_texture != null or material.normal_texture != null or try_extract_orm_from_material(material) != null
	vf_def.has_uv2 = false
	vf_def.has_bones = is_skeletal
	vf_def.has_weights = is_skeletal

	return vf_def

static func try_extract_orm_from_material(material : BaseMaterial3D) -> Texture2D:
	if material.orm_texture != null:
		return material.orm_texture
	
	var textures : Array[Texture2D]
	if material.ao_texture != null and material.ao_texture_channel == BaseMaterial3D.TextureChannel.TEXTURE_CHANNEL_RED:
		textures.append(material.ao_texture)
	if material.roughness_texture != null and material.roughness_texture_channel == BaseMaterial3D.TextureChannel.TEXTURE_CHANNEL_GREEN:
		textures.append(material.roughness_texture)
	if material.metallic_texture != null and material.metallic_texture_channel == BaseMaterial3D.TextureChannel.TEXTURE_CHANNEL_BLUE:
		textures.append(material.roughness_texture)

	if textures.size() == 0:
		return null
	var texture = textures[0]
	for i in range(1, textures.size()):
		if texture != textures[i]:
			return null

	return texture

static func get_vertex_format_def_from_mask(mask : int) -> TL_VertexFormatDef:
	if mask < 0:
		return null;
	var vf_def : TL_VertexFormatDef = TL_VertexFormatDef.new()
	vf_def.is_2d = 			(mask & 1 << 0) > 0
	vf_def.has_normal = 	(mask & 1 << 1) > 0
	vf_def.has_tangent = 	(mask & 1 << 2) > 0
	vf_def.has_color = 		(mask & 1 << 3) > 0
	vf_def.has_uv = 		(mask & 1 << 4) > 0
	vf_def.has_uv2 = 		(mask & 1 << 5) > 0
	vf_def.has_bones = 		(mask & 1 << 6) > 0
	vf_def.has_weights = 	(mask & 1 << 7) > 0

	return vf_def

static func get_mask_from_vertex_format_def(vf_def : TL_VertexFormatDef) -> int:
	return get_mask_from_bool_array([vf_def.is_2d, vf_def.has_normal, vf_def.has_tangent, vf_def.has_color, vf_def.has_uv, vf_def.has_uv2, vf_def.has_bones, vf_def.has_weights])

static var vertex_formats_cache : Dictionary[int, int]

static func get_or_create_vertex_format(vertex_format_def : TL_VertexFormatDef) -> int:
	var mask : int = get_mask_from_vertex_format_def(vertex_format_def) 
	if !vertex_formats_cache.has(mask):
		vertex_formats_cache[mask] = create_vertex_format(vertex_format_def)
	return vertex_formats_cache[mask]

static func create_vertex_format(vertex_format_def : TL_VertexFormatDef) -> int:
	var attrs : Array[RDVertexAttribute]
	
	if vertex_format_def.is_2d:
		var positionAttr = RDVertexAttribute.new()
		positionAttr.format = RenderingDevice.DATA_FORMAT_R32G32_SFLOAT;
		positionAttr.stride = POSITION_2D_NB_FLOATS * SIZEOF_FLOAT
		positionAttr.offset = 0
		positionAttr.location = 0
		attrs.append(positionAttr)
	else:
		var positionAttr = RDVertexAttribute.new()
		positionAttr.format = RenderingDevice.DATA_FORMAT_R32G32B32_SFLOAT;
		positionAttr.stride = POSITION_3D_NB_FLOATS * SIZEOF_FLOAT
		positionAttr.offset = 0
		positionAttr.location = 0
		attrs.append(positionAttr)

	if vertex_format_def.has_normal:
		var normalAttr = RDVertexAttribute.new()
		normalAttr.format = RenderingDevice.DATA_FORMAT_R32G32B32_SFLOAT;
		normalAttr.stride = NORMAL_NB_FLOATS * SIZEOF_FLOAT
		normalAttr.offset = 0
		normalAttr.location = 1
		attrs.append(normalAttr)

	if vertex_format_def.has_tangent:
		var tangentAttr = RDVertexAttribute.new()
		tangentAttr.format = RenderingDevice.DATA_FORMAT_R32G32B32A32_SFLOAT ;
		tangentAttr.stride = TAGENT_NB_FLOATS * SIZEOF_FLOAT
		tangentAttr.offset = 0
		tangentAttr.location = 2
		attrs.append(tangentAttr)

	if vertex_format_def.has_color:
		var colorAttr = RDVertexAttribute.new()
		colorAttr.format = RenderingDevice.DATA_FORMAT_R32G32B32A32_SFLOAT ;
		colorAttr.stride = COLOR_NB_FLOATS * SIZEOF_FLOAT
		colorAttr.offset = 0
		colorAttr.location = 3
		attrs.append(colorAttr)

	if vertex_format_def.has_uv:
		var uvAttr = RDVertexAttribute.new()
		uvAttr.format = RenderingDevice.DATA_FORMAT_R32G32_SFLOAT;
		uvAttr.stride = UV_NB_FLOATS * SIZEOF_FLOAT
		uvAttr.offset = 0
		uvAttr.location = 4
		attrs.append(uvAttr)

	if vertex_format_def.has_uv2:
		var uv2Attr = RDVertexAttribute.new()
		uv2Attr.format = RenderingDevice.DATA_FORMAT_R32G32_SFLOAT;
		uv2Attr.stride = UV_NB_FLOATS * SIZEOF_FLOAT
		uv2Attr.offset = 0
		uv2Attr.location = 5
		attrs.append(uv2Attr)

	if vertex_format_def.has_bones:
		var bonesAttr = RDVertexAttribute.new()
		bonesAttr.format = RenderingDevice.DATA_FORMAT_R32G32B32A32_SINT;
		bonesAttr.stride = BONES_NB_INTS * SIZEOF_INT
		bonesAttr.offset = 0
		bonesAttr.location = 6
		attrs.append(bonesAttr)

	if vertex_format_def.has_weights:
		var weightsAttr = RDVertexAttribute.new()
		weightsAttr.format = RenderingDevice.DATA_FORMAT_R32G32B32A32_SFLOAT;
		weightsAttr.stride = WEIGHT_NB_FLOATS * SIZEOF_FLOAT
		weightsAttr.offset = 0
		weightsAttr.location = 7
		attrs.append(weightsAttr)

	return rd.vertex_format_create(attrs)

# TODO remove nb_color_attachments and depth_test
static func create_pso(pso_def : TL_ExpicitPSODef, framebuffer_format : int) -> _TL_PSO:
	var instance = _TL_PSO.new()

	var path : String = pso_def.vertex_shader.resource_path
	var raw_source : String = pso_def.vertex_shader.source_code
	var preprocessed_source : String = TL_Shader_Preprocessor.preprocess(path, raw_source, pso_def.defines)
	var vertex_shader_src : String = preprocessed_source
	
	path = pso_def.fragment_shader.resource_path
	raw_source = pso_def.fragment_shader.source_code
	preprocessed_source = TL_Shader_Preprocessor.preprocess(path, raw_source, pso_def.defines)
	var fragment_shader_src : String = preprocessed_source

	instance.shader_program = TL_RendererUtils.compile_shader(vertex_shader_src, fragment_shader_src)

	var vf_def : TL_VertexFormatDef = pso_def.vertex_format_def
	instance.vertex_format = _TL_Renderer_Factory.get_or_create_vertex_format(vf_def)

	var rasterizationState = RDPipelineRasterizationState.new()
	rasterizationState.cull_mode = pso_def.rasterization_state.cull_mode
	rasterizationState.depth_bias_clamp = pso_def.rasterization_state.depth_bias_clamp
	rasterizationState.depth_bias_constant_factor = pso_def.rasterization_state.depth_bias_constant_factor
	rasterizationState.depth_bias_enabled = pso_def.rasterization_state.depth_bias_enabled
	rasterizationState.depth_bias_slope_factor = pso_def.rasterization_state.depth_bias_slope_factor
	rasterizationState.discard_primitives = pso_def.rasterization_state.discard_primitives
	rasterizationState.enable_depth_clamp = pso_def.rasterization_state.enable_depth_clamp
	rasterizationState.front_face = pso_def.rasterization_state.front_face
	rasterizationState.line_width = pso_def.rasterization_state.line_width
	rasterizationState.patch_control_points = pso_def.rasterization_state.patch_control_points
	rasterizationState.wireframe = pso_def.rasterization_state.wireframe

	var multisampleState = RDPipelineMultisampleState.new()
	multisampleState.enable_alpha_to_coverage = pso_def.multisample_state.enable_alpha_to_coverage
	multisampleState.enable_alpha_to_one = pso_def.multisample_state.enable_alpha_to_one
	multisampleState.enable_sample_shading = pso_def.multisample_state.enable_sample_shading
	multisampleState.min_sample_shading = pso_def.multisample_state.min_sample_shading
	multisampleState.sample_count = pso_def.multisample_state.sample_count
	multisampleState.sample_masks = pso_def.multisample_state.sample_masks

	var depthStencilState = RDPipelineDepthStencilState.new()
	depthStencilState.back_op_compare = pso_def.depth_stencil_state.back_op_compare
	depthStencilState.back_op_compare_mask = pso_def.depth_stencil_state.back_op_compare_mask
	depthStencilState.back_op_depth_fail = pso_def.depth_stencil_state.back_op_depth_fail
	depthStencilState.back_op_fail = pso_def.depth_stencil_state.back_op_fail
	depthStencilState.back_op_pass = pso_def.depth_stencil_state.back_op_pass
	depthStencilState.back_op_reference = pso_def.depth_stencil_state.back_op_reference
	depthStencilState.back_op_write_mask = pso_def.depth_stencil_state.back_op_write_mask
	depthStencilState.depth_compare_operator = pso_def.depth_stencil_state.depth_compare_operator
	depthStencilState.depth_range_max = pso_def.depth_stencil_state.depth_range_max
	depthStencilState.depth_range_min = pso_def.depth_stencil_state.depth_range_min
	depthStencilState.enable_depth_range = pso_def.depth_stencil_state.enable_depth_range
	depthStencilState.enable_depth_test = pso_def.depth_stencil_state.enable_depth_test
	depthStencilState.enable_depth_write = pso_def.depth_stencil_state.enable_depth_write
	depthStencilState.enable_stencil = pso_def.depth_stencil_state.enable_stencil
	depthStencilState.front_op_compare = pso_def.depth_stencil_state.front_op_compare
	depthStencilState.front_op_compare_mask = pso_def.depth_stencil_state.front_op_compare_mask
	depthStencilState.front_op_depth_fail = pso_def.depth_stencil_state.front_op_depth_fail
	depthStencilState.front_op_fail = pso_def.depth_stencil_state.front_op_fail
	depthStencilState.front_op_pass = pso_def.depth_stencil_state.front_op_pass
	depthStencilState.front_op_reference = pso_def.depth_stencil_state.front_op_reference
	depthStencilState.front_op_write_mask = pso_def.depth_stencil_state.front_op_write_mask

	var colorBlendState = RDPipelineColorBlendState.new()
	for color_blend_attachment_def : TL_PSOColorBlendAttachmentDef in pso_def.blend_attachments:
		var colorBlendStateAttachment : RDPipelineColorBlendStateAttachment = RDPipelineColorBlendStateAttachment.new()
		colorBlendStateAttachment.alpha_blend_op = color_blend_attachment_def.alpha_blend_op
		colorBlendStateAttachment.color_blend_op = color_blend_attachment_def.color_blend_op
		colorBlendStateAttachment.dst_alpha_blend_factor = color_blend_attachment_def.dst_alpha_blend_factor
		colorBlendStateAttachment.dst_color_blend_factor = color_blend_attachment_def.dst_color_blend_factor
		colorBlendStateAttachment.enable_blend = color_blend_attachment_def.enable_blend
		colorBlendStateAttachment.src_alpha_blend_factor = color_blend_attachment_def.src_alpha_blend_factor
		colorBlendStateAttachment.src_color_blend_factor = color_blend_attachment_def.src_color_blend_factor
		colorBlendStateAttachment.write_a = color_blend_attachment_def.write_a
		colorBlendStateAttachment.write_b = color_blend_attachment_def.write_b
		colorBlendStateAttachment.write_g = color_blend_attachment_def.write_g
		colorBlendStateAttachment.write_r = color_blend_attachment_def.write_r
		colorBlendState.attachments.append(colorBlendStateAttachment)

	colorBlendState.blend_constant = pso_def.blend_constant
	colorBlendState.enable_logic_op = pso_def.enable_logic_op
	colorBlendState.logic_op = pso_def.logic_op

	instance.pipeline = rd.render_pipeline_create(instance.shader_program, framebuffer_format, instance.vertex_format, RenderingDevice.RENDER_PRIMITIVE_TRIANGLES, rasterizationState, multisampleState, depthStencilState, colorBlendState)

	return instance
	
static func create_texture_attachment(tex_attach_def : TL_AttachmentFormat_Def, width : int = -1, height : int = -1) -> RID:
	if width == -1:
		width = ProjectSettings.get_setting("display/window/size/viewport_width")
	if height == -1:
		height = ProjectSettings.get_setting("display/window/size/viewport_height")
	
	var tf = RDTextureFormat.new();
	tf.usage_bits = 0
	for bit in tex_attach_def.usage_flags:
		tf.usage_bits |= bit
	tf.width = width
	tf.height = height
	tf.format = tex_attach_def.format
	var view = RDTextureView.new();

	return rd.texture_create(tf, view)
