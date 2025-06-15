class_name TL_DefaultModel

const LOG_WARNS = false
const WARN_NOT_SUPPORTED_MATERIAL = "TourefL : Unable to generate proxy data from %s material. It may have unsupported features."
const WARN_SURAFACE_SKIPPED = "TourefL : The material data for %dth surface of the mesh %s could not be generated. This surface will be skipped."

static var rd = RenderingServer.get_rendering_device()

static var _static_mesh_vertex_format : int = -1
static func get_or_create_static_mesh_vertex_format() -> int:
	if _static_mesh_vertex_format == -1:
		var sizeof_float = 4
		var position_nb_floats = 3
		var normal_nb_floats = 3
		var tangent_nb_floats = 4
		var uv_nb_floats = 2
		
		var positionAttr = RDVertexAttribute.new()
		positionAttr.format = RenderingDevice.DATA_FORMAT_R32G32B32_SFLOAT;
		positionAttr.stride = position_nb_floats * sizeof_float
		positionAttr.offset = 0
		positionAttr.location = 0
		
		var normalAttr = RDVertexAttribute.new()
		normalAttr.format = RenderingDevice.DATA_FORMAT_R32G32B32_SFLOAT;
		normalAttr.stride = normal_nb_floats * sizeof_float
		normalAttr.offset = 0
		normalAttr.location = 1

		var tangentAttr = RDVertexAttribute.new()
		tangentAttr.format = RenderingDevice.DATA_FORMAT_R32G32B32A32_SFLOAT ;
		tangentAttr.stride = tangent_nb_floats * sizeof_float
		tangentAttr.offset = 0
		tangentAttr.location = 2
		
		var uvAttr = RDVertexAttribute.new()
		uvAttr.format = RenderingDevice.DATA_FORMAT_R32G32_SFLOAT;
		uvAttr.stride = uv_nb_floats * sizeof_float
		uvAttr.offset = 0
		uvAttr.location = 3

		_static_mesh_vertex_format = rd.vertex_format_create([positionAttr, normalAttr, tangentAttr, uvAttr])

	return _static_mesh_vertex_format

class CameraData:
	var view_matrix_bytes : PackedByteArray
	var projection_matrix_bytes : PackedByteArray

	var matrices_uniform_buffer : RID

class OmniLightData:
	var color : Color
	var intensity : float
	var location : Vector3
	var range : float
	var attenuation : float
	
class SpotLightData:
	var color : Color
	var intensity : float
	var location : Vector3
	var range : float
	var attenuation : float
	var direction : Vector3
	var angle : float
	var angle_attenuation : float
	
class DirectionalLightData:
	var color : Color
	var intensity : float
	var direction : Vector3

class MeshData:
	var model_matrix_bytes : PackedByteArray
	var surfaces_data : Array[SurfaceData]

class SurfaceData :
	var mesh_data : MeshData

	var index_count : int
	var index_buffer : RID
	var index_array : RID

	var vertex_count : int
	var position_buffer : RID
	var normal_buffer : RID
	var tangent_buffer : RID
	var uv_buffer : RID
	var vertex_array : RID

	var material_data : MaterialData

class MaterialData:
	var albedo_tex : RID 
	var albedo_sampler : RID 
	var normal_tex : RID
	var normal_sampler : RID
	var orm_tex : RID
	var orm_sampler : RID 

static func create_from(obj : Object):
	if obj is BaseMaterial3D:
		return create_from_material(obj)
	elif obj is MeshInstance3D :
		return create_from_mesh(obj)
	elif obj is OmniLight3D:
		return create_from_omni_light(obj)
	elif obj is SpotLight3D:
		return create_from_spot_light(obj)
	elif obj is DirectionalLight3D:
		return create_from_directional_light(obj)
	elif obj is Camera3D:
		return create_from_camera(obj)

static func free_data(data : Object):
	if data is MaterialData:
		return free_material(data)
	elif data is SurfaceData:
		return free_surface(data)
	elif data is MeshData :
		return free_mesh(data)
	elif data is OmniLightData:
		return free_omni_light(data)
	elif data is SpotLightData:
		return free_spot_light(data)
	elif data is DirectionalLightData:
		return free_directional_light(data)
	elif data is CameraData:
		return free_camera(data)

static func create_from_material(material : BaseMaterial3D) -> MaterialData:
	var material_data : TL_DefaultModel.MaterialData = TL_DefaultModel.MaterialData.new()

	material_data.albedo_tex = RenderingServer.texture_get_rd_texture(material.albedo_texture)
	if material_data.albedo_tex == RID():
		if LOG_WARNS:
			push_warning(WARN_NOT_SUPPORTED_MATERIAL % material.resource_name)
		return null

	material_data.normal_tex = RenderingServer.texture_get_rd_texture(material.normal_texture)
	if material_data.normal_tex == RID():
		if LOG_WARNS:
			push_warning(WARN_NOT_SUPPORTED_MATERIAL % material.resource_name)
		return null

	material_data.orm_tex =  RenderingServer.texture_get_rd_texture(material.orm_texture)

	material_data.albedo_sampler = rd.sampler_create(TL_RendererUtils.create_sampler_state())
	material_data.normal_sampler = rd.sampler_create(TL_RendererUtils.create_sampler_state())
	material_data.orm_sampler = rd.sampler_create(TL_RendererUtils.create_sampler_state())

	return material_data

static func free_material(material_data : MaterialData):
	if material_data.albedo_sampler != RID():
		rd.free_rid(material_data.albedo_sampler)
		material_data.albedo_sampler = RID() 
	if material_data.normal_sampler != RID():
		rd.free_rid(material_data.normal_sampler)
		material_data.normal_sampler = RID() 
	if material_data.orm_sampler != RID():
		rd.free_rid(material_data.orm_sampler)
		material_data.orm_sampler = RID() 

static func create_from_mesh(mesh : MeshInstance3D) -> MeshData:
	var mesh_data = MeshData.new()
	mesh_data.model_matrix_bytes = TL_RendererUtils.proj_to_bytes(Projection(mesh.global_transform))
	for i in range(0, mesh.mesh.get_surface_count()):
		var surface_data : TL_DefaultModel.SurfaceData = TL_DefaultModel.SurfaceData.new()
		
		surface_data.material_data = create_from_material(mesh.get_active_material(i))
		if surface_data.material_data != null:
			mesh_data.surfaces_data.append(surface_data)
		elif LOG_WARNS :
			push_warning(WARN_SURAFACE_SKIPPED % [i, mesh.name])

		surface_data.mesh_data = mesh_data

		var arrays = mesh.mesh.surface_get_arrays(i)
		surface_data.index_count = arrays[Mesh.ARRAY_INDEX].size()
		var byte_array = arrays[Mesh.ARRAY_INDEX].to_byte_array()
		surface_data.index_buffer = rd.index_buffer_create(arrays[Mesh.ARRAY_INDEX].size(), RenderingDevice.INDEX_BUFFER_FORMAT_UINT32, byte_array)
		
		surface_data.index_array = rd.index_array_create(surface_data.index_buffer, 0, surface_data.index_count)

		surface_data.vertex_count = arrays[Mesh.ARRAY_VERTEX].size()
		byte_array = arrays[Mesh.ARRAY_VERTEX].to_byte_array()
		surface_data.position_buffer = rd.vertex_buffer_create(byte_array.size(), byte_array)

		byte_array = arrays[Mesh.ARRAY_NORMAL].to_byte_array()
		surface_data.normal_buffer = rd.vertex_buffer_create(byte_array.size(), byte_array)

		byte_array = arrays[Mesh.ARRAY_TANGENT].to_byte_array()
		surface_data.tangent_buffer = rd.vertex_buffer_create(byte_array.size(), byte_array)

		byte_array = arrays[Mesh.ARRAY_TEX_UV].to_byte_array()
		surface_data.uv_buffer = rd.vertex_buffer_create(byte_array.size(), byte_array)

		var vertex_format = get_or_create_static_mesh_vertex_format()
		surface_data.vertex_array = rd.vertex_array_create(surface_data.vertex_count, vertex_format, [surface_data.position_buffer, surface_data.normal_buffer, surface_data.tangent_buffer, surface_data.uv_buffer])

	return mesh_data

static func free_mesh(mesh_data : MeshData):
	for surface_data in mesh_data.surfaces_data:
		free_surface(surface_data)

static func free_surface(surface_data : SurfaceData):
	if surface_data.index_array != RID():
		rd.free_rid(surface_data.index_array)
		surface_data.index_array = RID()
	if surface_data.vertex_array != RID():
		rd.free_rid(surface_data.vertex_array)
		surface_data.vertex_array = RID()
	
	if surface_data.index_buffer != RID():
		rd.free_rid(surface_data.index_buffer)
		surface_data.index_buffer = RID()
	if surface_data.position_buffer != RID():
		rd.free_rid(surface_data.position_buffer)
		surface_data.position_buffer = RID()
	if surface_data.normal_buffer != RID():
		rd.free_rid(surface_data.normal_buffer)
		surface_data.normal_buffer = RID()
	if surface_data.tangent_buffer != RID():
		rd.free_rid(surface_data.tangent_buffer)
		surface_data.tangent_buffer = RID()
	if surface_data.uv_buffer != RID():
		rd.free_rid(surface_data.uv_buffer)
		surface_data.uv_buffer = RID()
	free_material(surface_data.material_data)

static func create_from_omni_light(omni : OmniLight3D) -> OmniLightData:
	var omni_data = OmniLightData.new()
	omni_data.color = omni.light_color
	omni_data.intensity = omni.light_energy
	omni_data.location = omni.global_position
	omni_data.range = omni.omni_range
	omni_data.attenuation = omni.omni_attenuation
	return omni_data

static func free_omni_light(omni_light_data : OmniLightData):
	pass

static func create_from_spot_light(spot : SpotLight3D) -> SpotLightData:
	var spot_data : TL_DefaultModel.SpotLightData = TL_DefaultModel.SpotLightData.new()
	spot_data.color = spot.light_color
	spot_data.intensity = spot.light_energy
	spot_data.location = spot.global_position
	spot_data.direction = -spot.global_basis.z
	spot_data.angle = deg_to_rad(spot.spot_angle)
	spot_data.angle_attenuation = spot.spot_angle_attenuation
	spot_data.range = spot.spot_range
	spot_data.attenuation = spot.spot_attenuation
	return spot_data
	
static func free_spot_light(spot_light_data : SpotLightData):
	pass

static func create_from_directional_light(directional : DirectionalLight3D) -> DirectionalLightData:
	var directional_data = DirectionalLightData.new()
	directional_data.color = directional.light_color
	directional_data.intensity = directional.light_energy
	directional_data.direction = -directional.global_basis.z
	return directional_data

static func free_directional_light(directional_light_data : DirectionalLightData):
	pass

static func create_from_camera(cam : Camera3D) -> CameraData:
	var cam_data = CameraData.new()
	cam_data.view_matrix_bytes = TL_RendererUtils.proj_to_bytes(Projection(cam.get_camera_transform().affine_inverse()))
	cam_data.projection_matrix_bytes = TL_RendererUtils.proj_to_bytes(cam.get_camera_projection().flipped_y())

	var bytes = cam_data.view_matrix_bytes
	bytes.append_array(cam_data.projection_matrix_bytes)
	
	cam_data.matrices_uniform_buffer = rd.uniform_buffer_create(bytes.size(), bytes)

	return cam_data;

static func free_camera(camera_data : CameraData):
	if camera_data.matrices_uniform_buffer != RID():
		rd.free_rid(camera_data.matrices_uniform_buffer)
		camera_data.matrices_uniform_buffer = RID()
