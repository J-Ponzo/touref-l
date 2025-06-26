class_name TL_DefaultModel

const LOG_WARNS = false
const WARN_NOT_SUPPORTED_MATERIAL = "TourefL : Unable to generate proxy data from %s material. It may have unsupported features."
const WARN_SURFACE_SKIPPED_MAT = "TourefL : The material data for %dth surface of the mesh %s could not be generated. This surface will be skipped."
const WARN_SURFACE_SKIPPED_VF = "TourefL : The vertex format for %dth surface of the mesh %s could not be generated. This surface will be skipped."

static var rd = RenderingServer.get_rendering_device()

class CameraData:
	var view_matrix_bytes : PackedByteArray
	var projection_matrix_bytes : PackedByteArray

	var matrices_uniform_buffer : RID

class LightData:
	var light_buffer_float : PackedFloat32Array
	var light_buffer_bytes : PackedByteArray

class OmniLightData extends LightData:
	var color : Color
	var intensity : float
	var location : Vector3
	var range : float
	var attenuation : float
	
class SpotLightData extends LightData:
	var color : Color
	var intensity : float
	var location : Vector3
	var range : float
	var attenuation : float
	var direction : Vector3
	var angle : float
	var angle_attenuation : float
	
class DirectionalLightData extends LightData:
	var color : Color
	var intensity : float
	var direction : Vector3

class MeshData:
	var is_skeletal : bool
	var pose_array : Array[Projection]
	var pose_array_buffer : RID
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
	var color_buffer : RID
	var bones_buffer : RID
	var weights_buffer : RID
	var vertex_array : RID

	var material_data : MaterialData

class MaterialData:
	var albedo_tex : RID 
	var albedo_sampler : RID 
	var normal_tex : RID
	var normal_sampler : RID
	var orm_tex : RID
	var orm_sampler : RID 

class ParticlesData:
	var multi_mesh_rid : RID
	var nb_particles : int
	var instance_storage_buffer : RID
	var mesh_data : MeshData

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
	elif obj is CPUParticles3D:
		return create_from_cpu_particles(obj)

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
	elif data is ParticlesData:
		return free_particles(data)

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

static func _create_orphan_surfaces_from_mesh_resource(mesh_resource : Mesh, ignore_mat : bool = false) -> Array[SurfaceData]:
	var orphan_surfaces : Array[SurfaceData]

	for i in range(0, mesh_resource.get_surface_count()):
		var surface_data : TL_DefaultModel.SurfaceData = TL_DefaultModel.SurfaceData.new()

		if ignore_mat:
			surface_data.material_data = MaterialData.new()
			orphan_surfaces.append(surface_data)
		else:
			surface_data.material_data = create_from_material(mesh_resource.surface_get_material(i))
			if surface_data.material_data != null:
				orphan_surfaces.append(surface_data)
			elif LOG_WARNS :
				push_warning(WARN_SURFACE_SKIPPED_MAT % [i, mesh_resource.resource_name])

		var arrays = mesh_resource.surface_get_arrays(i)
		surface_data.index_count = arrays[Mesh.ARRAY_INDEX].size()
		var byte_array = arrays[Mesh.ARRAY_INDEX].to_byte_array()
		surface_data.index_buffer = rd.index_buffer_create(arrays[Mesh.ARRAY_INDEX].size(), RenderingDevice.INDEX_BUFFER_FORMAT_UINT32, byte_array)
		
		surface_data.index_array = rd.index_array_create(surface_data.index_buffer, 0, surface_data.index_count)

		surface_data.vertex_count = arrays[Mesh.ARRAY_VERTEX].size()
		byte_array = arrays[Mesh.ARRAY_VERTEX].to_byte_array()
		surface_data.position_buffer = rd.vertex_buffer_create(byte_array.size(), byte_array)

		var has_normal : bool = false
		var has_tangent : bool = false
		var has_uv : bool = false
		var has_color : bool = false
		var has_bones : bool = false
		var has_weights : bool = false

		if arrays.size() > Mesh.ARRAY_NORMAL and arrays[Mesh.ARRAY_NORMAL] != null:
			has_normal = true
			byte_array = arrays[Mesh.ARRAY_NORMAL].to_byte_array()
			surface_data.normal_buffer = rd.vertex_buffer_create(byte_array.size(), byte_array)

		if arrays.size() > Mesh.ARRAY_TANGENT and arrays[Mesh.ARRAY_TANGENT] != null:
			has_tangent = true
			byte_array = arrays[Mesh.ARRAY_TANGENT].to_byte_array()
			surface_data.tangent_buffer = rd.vertex_buffer_create(byte_array.size(), byte_array)

		if arrays.size() > Mesh.ARRAY_TEX_UV and arrays[Mesh.ARRAY_TEX_UV] != null:
			has_uv = true
			byte_array = arrays[Mesh.ARRAY_TEX_UV].to_byte_array()
			surface_data.uv_buffer = rd.vertex_buffer_create(byte_array.size(), byte_array)

		if arrays.size() > Mesh.ARRAY_COLOR and arrays[Mesh.ARRAY_COLOR] != null:
			has_color = true
			byte_array = arrays[Mesh.ARRAY_COLOR].to_byte_array()
			surface_data.color_buffer = rd.vertex_buffer_create(byte_array.size(), byte_array)

		if arrays.size() > Mesh.ARRAY_BONES and arrays[Mesh.ARRAY_BONES] != null:
			has_bones = true
			byte_array = arrays[Mesh.ARRAY_BONES].to_byte_array()
			surface_data.bones_buffer = rd.vertex_buffer_create(byte_array.size(), byte_array)

		if arrays.size() > Mesh.ARRAY_WEIGHTS and arrays[Mesh.ARRAY_WEIGHTS] != null:
			has_weights = true
			byte_array = arrays[Mesh.ARRAY_WEIGHTS].to_byte_array()
			surface_data.weights_buffer = rd.vertex_buffer_create(byte_array.size(), byte_array)

		var vertex_format = -1
		if has_normal and has_tangent and has_uv and has_bones and has_weights:
			vertex_format = _TL_Renderer_Factory.get_or_create_vertex_format(false, true, true, false, true, false, true, true)
			surface_data.vertex_array = rd.vertex_array_create(surface_data.vertex_count, vertex_format, [surface_data.position_buffer, surface_data.normal_buffer, surface_data.tangent_buffer, surface_data.uv_buffer, surface_data.bones_buffer, surface_data.weights_buffer])
		elif has_normal and has_tangent and has_uv:
			vertex_format = _TL_Renderer_Factory.get_or_create_vertex_format(false, true, true, false, true, false, false, false)
			surface_data.vertex_array = rd.vertex_array_create(surface_data.vertex_count, vertex_format, [surface_data.position_buffer, surface_data.normal_buffer, surface_data.tangent_buffer, surface_data.uv_buffer])
		# elif has_color:
		# 	vertex_format = get_or_create_particles_vertex_format()
		# 	surface_data.vertex_array = rd.vertex_array_create(surface_data.vertex_count, vertex_format, [surface_data.position_buffer, surface_data.color_buffer])
		elif LOG_WARNS :
			push_warning(WARN_SURFACE_SKIPPED_VF % [i, mesh_resource.resource_name])

	return orphan_surfaces

static func create_from_mesh(mesh : MeshInstance3D) -> MeshData:
	var mesh_data = MeshData.new()

	var skin : Skin = mesh.skin
	var skeleton : Skeleton3D = mesh.get_node_or_null(mesh.skeleton)
	mesh_data.is_skeletal = skeleton != null && skin != null
	if mesh_data.is_skeletal:
		for bone_idx in range(skeleton.get_bone_count()):
			var global_bone_transform : Transform3D = skeleton.get_bone_global_pose(bone_idx)
			var inverse_bind : Transform3D = skin.get_bind_pose(bone_idx)
			mesh_data.pose_array.append(Projection(global_bone_transform * inverse_bind))
		mesh_data.pose_array_buffer = TL_RendererUtils.create_mat4_array_uniform_buffer(mesh_data.pose_array)

	mesh_data.model_matrix_bytes = TL_RendererUtils.proj_to_bytes(Projection(mesh.global_transform))

	var orphan_surfaces : Array[SurfaceData] = _create_orphan_surfaces_from_mesh_resource(mesh.mesh)
	for surface_data in orphan_surfaces:
		surface_data.mesh_data = mesh_data
		mesh_data.surfaces_data.append(surface_data)

	return mesh_data

static func free_mesh(mesh_data : MeshData):
	if mesh_data.pose_array_buffer != RID():
		rd.free_rid(mesh_data.pose_array_buffer)

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
	if surface_data.color_buffer != RID():
		rd.free_rid(surface_data.color_buffer)
		surface_data.color_buffer = RID()

	if surface_data.bones_buffer != RID():
		rd.free_rid(surface_data.bones_buffer)
		surface_data.bones_buffer = RID()
	if surface_data.weights_buffer != RID():
		rd.free_rid(surface_data.weights_buffer)
		surface_data.weights_buffer = RID()

	free_material(surface_data.material_data)

static func create_from_omni_light(omni : OmniLight3D) -> OmniLightData:
	var omni_data = OmniLightData.new()
	omni_data.color = omni.light_color
	omni_data.intensity = omni.light_energy
	omni_data.location = omni.global_position
	omni_data.range = omni.omni_range
	omni_data.attenuation = omni.omni_attenuation

	omni_data.light_buffer_float.append(omni_data.location.x)
	omni_data.light_buffer_float.append(omni_data.location.y)
	omni_data.light_buffer_float.append(omni_data.location.z)
	omni_data.light_buffer_float.append(omni_data.intensity)
	omni_data.light_buffer_float.append(omni_data.color.r)
	omni_data.light_buffer_float.append(omni_data.color.g)
	omni_data.light_buffer_float.append(omni_data.color.b)
	omni_data.light_buffer_float.append(omni_data.range)
	omni_data.light_buffer_float.append(0.0)
	omni_data.light_buffer_float.append(0.0)
	omni_data.light_buffer_float.append(0.0)
	omni_data.light_buffer_float.append(omni_data.attenuation)

	omni_data.light_buffer_bytes = omni_data.light_buffer_float.to_byte_array()

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

	spot_data.light_buffer_float.append(spot_data.location.x)
	spot_data.light_buffer_float.append(spot_data.location.y)
	spot_data.light_buffer_float.append(spot_data.location.z)
	spot_data.light_buffer_float.append(spot_data.angle)
	spot_data.light_buffer_float.append(spot_data.direction.x)
	spot_data.light_buffer_float.append(spot_data.direction.y)
	spot_data.light_buffer_float.append(spot_data.direction.z)
	spot_data.light_buffer_float.append(spot_data.intensity)
	spot_data.light_buffer_float.append(spot_data.color.r)
	spot_data.light_buffer_float.append(spot_data.color.g)
	spot_data.light_buffer_float.append(spot_data.color.b)
	spot_data.light_buffer_float.append(spot_data.angle_attenuation)
	spot_data.light_buffer_float.append(0.0)
	spot_data.light_buffer_float.append(0.0)
	spot_data.light_buffer_float.append(spot_data.range)
	spot_data.light_buffer_float.append(spot_data.attenuation)

	spot_data.light_buffer_bytes = spot_data.light_buffer_float.to_byte_array()

	return spot_data
	
static func free_spot_light(spot_light_data : SpotLightData):
	pass

static func create_from_directional_light(directional : DirectionalLight3D) -> DirectionalLightData:
	var directional_data = DirectionalLightData.new()
	directional_data.color = directional.light_color
	directional_data.intensity = directional.light_energy
	directional_data.direction = -directional.global_basis.z

	directional_data.light_buffer_float.append(directional_data.direction.x)
	directional_data.light_buffer_float.append(directional_data.direction.y)
	directional_data.light_buffer_float.append(directional_data.direction.z)
	directional_data.light_buffer_float.append(directional_data.intensity)
	directional_data.light_buffer_float.append(directional_data.color.r)
	directional_data.light_buffer_float.append(directional_data.color.g)
	directional_data.light_buffer_float.append(directional_data.color.b)
	directional_data.light_buffer_float.append(0.0)

	directional_data.light_buffer_bytes = directional_data.light_buffer_float.to_byte_array()

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

static func create_from_cpu_particles(cpu_particles : CPUParticles3D) -> ParticlesData:
	var particles_data = ParticlesData.new()
	particles_data.multi_mesh_rid = cpu_particles.get_multimesh_rid()

	particles_data.nb_particles = RenderingServer.multimesh_get_instance_count(particles_data.multi_mesh_rid)
	var instance_transforms : Array[Transform3D]
	var instance_colors : Array[Color]
	for idx : int in range(particles_data.nb_particles):
		var transform : Transform3D = RenderingServer.multimesh_instance_get_transform(particles_data.multi_mesh_rid, idx)
		instance_transforms.append(transform)
		var color : Color = RenderingServer.multimesh_instance_get_color(particles_data.multi_mesh_rid, idx)
		instance_colors.append(color)
	particles_data.instance_storage_buffer = TL_RendererUtils.create_particles_instance_storage_buffer(instance_transforms, instance_colors)

	var mesh_data = MeshData.new()
	mesh_data.model_matrix_bytes = TL_RendererUtils.proj_to_bytes(Projection(cpu_particles.global_transform))
	particles_data.mesh_data = mesh_data

	var orphan_surfaces : Array[SurfaceData] = _create_orphan_surfaces_from_mesh_resource(cpu_particles.mesh, true)
	for surface_data in orphan_surfaces:
		surface_data.mesh_data = mesh_data
		mesh_data.surfaces_data.append(surface_data)

	return particles_data

static func free_particles(particles_data : ParticlesData):
	free_mesh(particles_data.mesh_data)
	if particles_data.instance_storage_buffer != RID() :
		rd.free_rid(particles_data.instance_storage_buffer)
