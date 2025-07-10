class_name TL_DefaultModel

const LOG_WARNS = false
const WARN_NOT_SUPPORTED_MATERIAL = "TourefL : Unable to generate proxy data from %s material. It may have unsupported features."
const WARN_SURFACE_SKIPPED_MAT = "TourefL : The material data for %dth surface of the mesh %s could not be generated. This surface will be skipped."
const WARN_SURFACE_SKIPPED_VF = "TourefL : The vertex format for %dth surface of the mesh %s could not be generated. This surface will be skipped."

static var rd = RenderingServer.get_rendering_device()

class CameraData:
	var view_transform : Transform3D
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
	var skeleton_data : SkeletonData
	var invert_bind_pose_array_buffer : RID

	var is_instanced : bool
	var nb_instances : int
	var instance_storage_buffer : RID

	var bounding_box : AABB
	var model_matrix_bytes : PackedByteArray
	var surfaces_data : Array[SurfaceData]

static var existing_skeletons_data : Array[SkeletonData]

class SkeletonData:
	var instance_id : int

	var global_bone_pose_array : Array[Projection]
	var global_bone_pose_array_bytes_id : int
	var global_bone_pose_array_buffer : RID

class SurfaceData:
	var sort_key : int
	var mesh_data : MeshData
	var topology_data : TopologyData
	var vertex_array : RID
	var material_data : MaterialData

static var existing_topologies_data : Array[TopologyData]
static var existing_topologies_ref_count : Array[int]

class TopologyData:
	var instance_id : int
	var surface_id : int

	var index_count : int
	var index_buffer : RID
	var index_array : RID

	var vertex_count : int
	var position_buffer : RID
	var normal_buffer : RID
	var tangent_buffer : RID
	var color_buffer : RID
	var uv_buffer : RID
	var uv2_buffer : RID
	var bones_buffer : RID
	var weights_buffer : RID

	var vertex_format_mask : int = -1

class MaterialData:
	var albedo : Color
	var albedo_tex : RID 
	var albedo_sampler : RID 
	var normal_tex : RID
	var normal_sampler : RID
	var orm_tex : RID
	var orm_sampler : RID 
	var mat_feat_flags_mask : int = -1

class ParticlesData:
	var multi_mesh_rid : RID
	var mesh_data : MeshData

static  func hash_int_to_bits(src_int : int, trg_nb_bits : int) -> int:
	var h = hash(src_int)
	var mask = (1 << trg_nb_bits) - 1
	return h & mask

static func generate_opaque_sort_key(surface_data : SurfaceData) -> int:
	var pso_id = surface_data.material_data.mat_feat_flags_mask
	
	var color_hash : int = hash_int_to_bits(surface_data.material_data.albedo.to_rgba64(), 8)
	var albedo_hash : int = hash_int_to_bits(surface_data.material_data.albedo_sampler.get_id(), 8)
	var normal_hash : int = hash_int_to_bits(surface_data.material_data.normal_sampler.get_id(), 8)
	var orm_hash : int = hash_int_to_bits(surface_data.material_data.orm_sampler.get_id(), 8)
	var material_id : int = color_hash
	material_id |= albedo_hash << 8
	material_id |= normal_hash << 16
	material_id |= orm_hash << 24


	var index_array_hash : int = hash_int_to_bits(surface_data.topology_data.index_array.get_id(), 16)
	var vertex_array_hash : int = hash_int_to_bits(surface_data.vertex_array.get_id(), 16)
	var mesh_id : int = index_array_hash
	mesh_id |= vertex_array_hash << 16

	var custom_id : int = 0

	var sort_key : int = 0
	sort_key |= pso_id << 48		# PSO_ID
	sort_key |= material_id << 32	# Material_ID
	sort_key |= mesh_id << 16		# Mesh_ID
	sort_key |= custom_id			# Custom_ID

	return sort_key

# TODO optimize : compute this on mesh level
static func generate_transparent_sort_key(surface_data : SurfaceData, camera_data : CameraData) -> int:
	var view_pos : Vector3 = camera_data.view_transform * surface_data.mesh_data.bounding_box.get_center()
	var distance : float = -view_pos.z
	var sort_key : int = distance * 9223372036854775807

	return sort_key


static func create_from(obj : Object):
	if obj is MeshInstance3D :
		return create_from_mesh(obj)
	elif obj is Skeleton3D:
		return get_or_create_from_skeleton(obj)
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
	elif data is SkeletonData:
		return free_skeleton(data)
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

static func create_from_material(material : BaseMaterial3D, mat_feat_flags : TL_MaterialFeatureFlags_Def) -> MaterialData:
	var material_data : TL_DefaultModel.MaterialData = TL_DefaultModel.MaterialData.new()

	material_data.mat_feat_flags_mask = _TL_Renderer_Factory.get_mask_from_material_feature_flags_def(mat_feat_flags)

	material_data.albedo = material.albedo_color
	if mat_feat_flags.has_albedo_map:
		material_data.albedo_tex = RenderingServer.texture_get_rd_texture(material.albedo_texture)
		material_data.albedo_sampler = rd.sampler_create(TL_RendererUtils.create_sampler_state())
	if mat_feat_flags.has_normal_map and mat_feat_flags.is_lit:
		material_data.normal_tex = RenderingServer.texture_get_rd_texture(material.normal_texture)
		material_data.normal_sampler = rd.sampler_create(TL_RendererUtils.create_sampler_state())
	if mat_feat_flags.has_orm_map and mat_feat_flags.is_lit:
		material_data.orm_tex = RenderingServer.texture_get_rd_texture(_TL_Renderer_Factory.try_extract_orm_from_material(material))
		material_data.orm_sampler = rd.sampler_create(TL_RendererUtils.create_sampler_state())

	return material_data

static func free_material(material_data : MaterialData):
	if material_data == null:
		return
	
	if material_data.albedo_sampler != RID():
		rd.free_rid(material_data.albedo_sampler)
		material_data.albedo_sampler = RID() 
	if material_data.normal_sampler != RID():
		rd.free_rid(material_data.normal_sampler)
		material_data.normal_sampler = RID() 
	if material_data.orm_sampler != RID():
		rd.free_rid(material_data.orm_sampler)
		material_data.orm_sampler = RID() 

const HAS_NORMAL = 		1 << 1
const HAS_TANGEANT = 	1 << 2
const HAS_COLOR = 		1 << 3
const HAS_UV = 			1 << 4
const HAS_UV2 = 		1 << 5
const HAS_BONES = 		1 << 6
const HAS_WEIGHTS = 	1 << 7

static func _create_orphan_surface(mesh_resource : Mesh, surface_idx : int, mat_feat_flags : TL_MaterialFeatureFlags_Def) -> SurfaceData:
	var surface_data : TL_DefaultModel.SurfaceData = TL_DefaultModel.SurfaceData.new()
	surface_data.topology_data = _get_or_create_topology_data(mesh_resource, surface_idx)

	var vf_def : TL_VertexFormatDef = _TL_Renderer_Factory.get_vertex_format_def_from_material_feature_flags(mat_feat_flags)
	var buffers : Array[RID]
	buffers.append(surface_data.topology_data.position_buffer)
	var vf_mask : int = surface_data.topology_data.vertex_format_mask
	if vf_def.has_normal:
		if (vf_mask & HAS_NORMAL) == 0:
			_free_or_decr_topology(surface_data.topology_data)
			return null
		buffers.append(surface_data.topology_data.normal_buffer)
	if vf_def.has_tangent:
		if (vf_mask & HAS_TANGEANT) == 0:
			_free_or_decr_topology(surface_data.topology_data)
			return null
		buffers.append(surface_data.topology_data.tangent_buffer)
	if vf_def.has_color:
		if (vf_mask & HAS_COLOR) == 0:
			_free_or_decr_topology(surface_data.topology_data)
			return null
		buffers.append(surface_data.topology_data.color_buffer)
	if vf_def.has_uv:
		if (vf_mask & HAS_UV) == 0:
			_free_or_decr_topology(surface_data.topology_data)
			return null
		buffers.append(surface_data.topology_data.uv_buffer)
	if vf_def.has_uv2:
		if (vf_mask & HAS_UV2) == 0:
			_free_or_decr_topology(surface_data.topology_data)
			return null
		buffers.append(surface_data.topology_data.uv2_buffer)
	if vf_def.has_bones:
		if (vf_mask & HAS_BONES) == 0:
			_free_or_decr_topology(surface_data.topology_data)
			return null
		buffers.append(surface_data.topology_data.bones_buffer)
	if vf_def.has_weights:
		if (vf_mask & HAS_WEIGHTS) == 0:
			_free_or_decr_topology(surface_data.topology_data)
			return null
		buffers.append(surface_data.topology_data.weights_buffer)
	var vertex_format : int = _TL_Renderer_Factory.get_or_create_vertex_format(vf_def)

	surface_data.vertex_array = rd.vertex_array_create(surface_data.topology_data.vertex_count, vertex_format, buffers)

	return surface_data

static func free_surface(surface_data : SurfaceData):
	surface_data.mesh_data = null

	if surface_data.vertex_array != RID():
		rd.free_rid(surface_data.vertex_array)
		surface_data.vertex_array = RID()

	_free_or_decr_topology(surface_data.topology_data)
	free_material(surface_data.material_data)

static func _get_or_create_topology_data(mesh_resource : Mesh, surface_idx : int) -> TopologyData:
	for i in range(existing_topologies_data.size()):
		var existing_topology_data : TopologyData = existing_topologies_data[i]
		if existing_topology_data.surface_id == surface_idx and existing_topology_data.instance_id == mesh_resource.get_instance_id():
			existing_topologies_ref_count[i] += 1
			return existing_topology_data

	var topology_data : TopologyData = TopologyData.new()
	topology_data.instance_id = mesh_resource.get_instance_id()
	topology_data.surface_id = surface_idx

	var arrays = mesh_resource.surface_get_arrays(surface_idx)
	topology_data.index_count = arrays[Mesh.ARRAY_INDEX].size()
	var byte_array = arrays[Mesh.ARRAY_INDEX].to_byte_array()
	topology_data.index_buffer = rd.index_buffer_create(arrays[Mesh.ARRAY_INDEX].size(), RenderingDevice.INDEX_BUFFER_FORMAT_UINT32, byte_array)
	
	topology_data.index_array = rd.index_array_create(topology_data.index_buffer, 0, topology_data.index_count)

	topology_data.vertex_count = arrays[Mesh.ARRAY_VERTEX].size()
	byte_array = arrays[Mesh.ARRAY_VERTEX].to_byte_array()
	topology_data.position_buffer = rd.vertex_buffer_create(byte_array.size(), byte_array)

	var has_normal : bool = false
	var has_tangent : bool = false
	var has_color : bool = false
	var has_uv : bool = false
	var has_uv2 : bool = false
	var has_bones : bool = false
	var has_weights : bool = false

	if arrays.size() > Mesh.ARRAY_NORMAL and arrays[Mesh.ARRAY_NORMAL] != null:
		has_normal = true
		byte_array = arrays[Mesh.ARRAY_NORMAL].to_byte_array()
		topology_data.normal_buffer = rd.vertex_buffer_create(byte_array.size(), byte_array)

	if arrays.size() > Mesh.ARRAY_TANGENT and arrays[Mesh.ARRAY_TANGENT] != null:
		has_tangent = true
		byte_array = arrays[Mesh.ARRAY_TANGENT].to_byte_array()
		topology_data.tangent_buffer = rd.vertex_buffer_create(byte_array.size(), byte_array)

	if arrays.size() > Mesh.ARRAY_COLOR and arrays[Mesh.ARRAY_COLOR] != null:
		has_color = true
		byte_array = arrays[Mesh.ARRAY_COLOR].to_byte_array()
		topology_data.color_buffer = rd.vertex_buffer_create(byte_array.size(), byte_array)

	if arrays.size() > Mesh.ARRAY_TEX_UV and arrays[Mesh.ARRAY_TEX_UV] != null:
		has_uv = true
		byte_array = arrays[Mesh.ARRAY_TEX_UV].to_byte_array()
		topology_data.uv_buffer = rd.vertex_buffer_create(byte_array.size(), byte_array)

	if arrays.size() > Mesh.ARRAY_TEX_UV2 and arrays[Mesh.ARRAY_TEX_UV2] != null:
		has_uv2 = true
		byte_array = arrays[Mesh.ARRAY_TEX_UV].to_byte_array()
		topology_data.uv2_buffer = rd.vertex_buffer_create(byte_array.size(), byte_array)

	if arrays.size() > Mesh.ARRAY_BONES and arrays[Mesh.ARRAY_BONES] != null:
		has_bones = true
		byte_array = arrays[Mesh.ARRAY_BONES].to_byte_array()
		topology_data.bones_buffer = rd.vertex_buffer_create(byte_array.size(), byte_array)

	if arrays.size() > Mesh.ARRAY_WEIGHTS and arrays[Mesh.ARRAY_WEIGHTS] != null:
		has_weights = true
		byte_array = arrays[Mesh.ARRAY_WEIGHTS].to_byte_array()
		topology_data.weights_buffer = rd.vertex_buffer_create(byte_array.size(), byte_array)

	topology_data.vertex_format_mask = _TL_Renderer_Factory.get_mask_from_bool_array([false, has_normal, has_tangent, has_color, has_uv, has_uv2, has_bones, has_weights])

	existing_topologies_data.append(topology_data)
	existing_topologies_ref_count.append(1)

	return topology_data

static func _free_or_decr_topology(topology_data : TopologyData):
	for i in range(existing_topologies_data.size()):
		var existing_topology_data : TopologyData = existing_topologies_data[i]
		if existing_topology_data == topology_data:
			existing_topologies_ref_count[i] -= 1
			if existing_topologies_ref_count[i] > 0:
				return
			else:
				existing_topologies_data.remove_at(i)
				existing_topologies_ref_count.remove_at(i)
				break

	if topology_data.index_array != RID():
		rd.free_rid(topology_data.index_array)
		topology_data.index_array = RID()
	
	if topology_data.index_buffer != RID():
		rd.free_rid(topology_data.index_buffer)
		topology_data.index_buffer = RID()
	if topology_data.position_buffer != RID():
		rd.free_rid(topology_data.position_buffer)
		topology_data.position_buffer = RID()
	if topology_data.normal_buffer != RID():
		rd.free_rid(topology_data.normal_buffer)
		topology_data.normal_buffer = RID()
	if topology_data.tangent_buffer != RID():
		rd.free_rid(topology_data.tangent_buffer)
		topology_data.tangent_buffer = RID()
	if topology_data.color_buffer != RID():
		rd.free_rid(topology_data.color_buffer)
		topology_data.color_buffer = RID()
	if topology_data.uv_buffer != RID():
		rd.free_rid(topology_data.uv_buffer)
		topology_data.uv_buffer = RID()
	if topology_data.uv2_buffer != RID():
		rd.free_rid(topology_data.uv2_buffer)
		topology_data.uv2_buffer = RID()

	if topology_data.bones_buffer != RID():
		rd.free_rid(topology_data.bones_buffer)
		topology_data.bones_buffer = RID()
	if topology_data.weights_buffer != RID():
		rd.free_rid(topology_data.weights_buffer)
		topology_data.weights_buffer = RID()

# TODO centralize this
const SIZEOF_FLOAT = 4
const SIZEOF_MAT4 = SIZEOF_FLOAT * 16
const MAX_BONES = 128

static func create_from_mesh(mesh : MeshInstance3D) -> MeshData:
	var mesh_data : MeshData = MeshData.new()
	mesh_data.bounding_box = mesh.get_aabb()

	var skin : Skin = mesh.skin
	var node_at_skeleton_path = mesh.get_node_or_null(mesh.skeleton)
	var skeleton : Skeleton3D = null
	if node_at_skeleton_path != null and node_at_skeleton_path is Skeleton3D:
		skeleton = node_at_skeleton_path
	if skeleton != null && skin != null:
		mesh_data.skeleton_data = get_or_create_from_skeleton(skeleton)
		var nb_bones : int = skeleton.get_bone_count()
		var invert_bind_pose_array : PackedByteArray
		for bone_idx in range(nb_bones):
			var inverse_bind : Transform3D = skin.get_bind_pose(bone_idx)
			invert_bind_pose_array.append_array(TL_RendererUtils.proj_to_bytes(Projection(inverse_bind)))
		for i in range(nb_bones, MAX_BONES):
			for j in range(SIZEOF_MAT4):
				invert_bind_pose_array.append(0)

		mesh_data.invert_bind_pose_array_buffer = rd.uniform_buffer_create(MAX_BONES * SIZEOF_MAT4, invert_bind_pose_array)

	mesh_data.model_matrix_bytes = TL_RendererUtils.proj_to_bytes(Projection(mesh.global_transform))

	for i in range(0, mesh.mesh.get_surface_count()):
		var material : BaseMaterial3D =  mesh.mesh.surface_get_material(i)
		var mat_feat_flags : TL_MaterialFeatureFlags_Def = _TL_Renderer_Factory.create_material_feature_flags(material, mesh_data.skeleton_data != null, false)

		var material_data : MaterialData = create_from_material(material, mat_feat_flags)

		var surface_data : SurfaceData = _create_orphan_surface(mesh.mesh, i, mat_feat_flags)
		surface_data.material_data = material_data
		surface_data.mesh_data = mesh_data
		mesh_data.surfaces_data.append(surface_data)

		if mat_feat_flags.is_transparent():
			surface_data.sort_key = generate_opaque_sort_key(surface_data)

	return mesh_data

static func free_mesh(mesh_data : MeshData):
	if mesh_data.invert_bind_pose_array_buffer != RID():
		rd.free_rid(mesh_data.invert_bind_pose_array_buffer)
		mesh_data.invert_bind_pose_array_buffer = RID()

	if mesh_data.instance_storage_buffer != RID() :
		rd.free_rid(mesh_data.instance_storage_buffer)
		mesh_data.instance_storage_buffer = RID()

	for surface_data in mesh_data.surfaces_data:
		free_surface(surface_data)

static func get_or_create_from_skeleton(skeleton : Skeleton3D) -> SkeletonData:
	for existing_skeleton_data in existing_skeletons_data:
		if existing_skeleton_data.instance_id == skeleton.get_instance_id():
			return existing_skeleton_data

	var skeleton_data : SkeletonData = SkeletonData.new()
	skeleton_data.instance_id = skeleton.get_instance_id()

	var nb_bones : int = skeleton.get_bone_count()
	skeleton_data.global_bone_pose_array.resize(nb_bones)
	for bone_idx in range(nb_bones):
		var global_bone_transform : Transform3D = skeleton.get_bone_global_pose(bone_idx)
		skeleton_data.global_bone_pose_array[bone_idx] = Projection(global_bone_transform)

	skeleton_data.global_bone_pose_array_bytes_id = TL_NativeMemory.ManagerInst.create_packed_byte_array(MAX_BONES * SIZEOF_MAT4)
	TL_NativeMemory.ManagerInst.fill_packed_byte_array_with_projections(skeleton_data.global_bone_pose_array_bytes_id, 0, skeleton_data.global_bone_pose_array)
	skeleton_data.global_bone_pose_array_buffer = TL_NativeMemory.RenderingDeviceInst.uniform_buffer_create(MAX_BONES * SIZEOF_MAT4, skeleton_data.global_bone_pose_array_bytes_id, 0)

	existing_skeletons_data.append(skeleton_data)

	return skeleton_data

static func free_skeleton(skeleton_data : SkeletonData):
	if skeleton_data.global_bone_pose_array_buffer != RID():
		rd.free_rid(skeleton_data.global_bone_pose_array_buffer)
		skeleton_data.global_bone_pose_array_buffer = RID()

	var idx : int = existing_skeletons_data.find(skeleton_data)
	existing_skeletons_data.remove_at(idx)

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
	var linear_color : Color = omni_data.color#.srgb_to_linear()
	omni_data.light_buffer_float.append(linear_color.r)
	omni_data.light_buffer_float.append(linear_color.g)
	omni_data.light_buffer_float.append(linear_color.b)
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
	var linear_color : Color = spot_data.color.srgb_to_linear()
	spot_data.light_buffer_float.append(linear_color.r)
	spot_data.light_buffer_float.append(linear_color.g)
	spot_data.light_buffer_float.append(linear_color.b)
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
	var linear_color : Color = directional_data.color.srgb_to_linear()
	directional_data.light_buffer_float.append(linear_color.r)
	directional_data.light_buffer_float.append(linear_color.g)
	directional_data.light_buffer_float.append(linear_color.b)
	directional_data.light_buffer_float.append(0.0)

	directional_data.light_buffer_bytes = directional_data.light_buffer_float.to_byte_array()

	return directional_data

static func free_directional_light(directional_light_data : DirectionalLightData):
	pass

static func create_from_camera(cam : Camera3D) -> CameraData:
	var cam_data = CameraData.new()
	cam_data.view_transform = cam.get_camera_transform().affine_inverse()
	cam_data.view_matrix_bytes = TL_RendererUtils.proj_to_bytes(Projection(cam_data.view_transform))
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

	var mesh_data = MeshData.new()
	mesh_data.is_instanced = true
	mesh_data.nb_instances = RenderingServer.multimesh_get_instance_count(particles_data.multi_mesh_rid)
	var instance_transforms : Array[Transform3D]
	var instance_colors : Array[Color]
	for idx : int in range(mesh_data.nb_instances):
		var transform : Transform3D = RenderingServer.multimesh_instance_get_transform(particles_data.multi_mesh_rid, idx)
		instance_transforms.append(transform)
		var color : Color = RenderingServer.multimesh_instance_get_color(particles_data.multi_mesh_rid, idx)
		instance_colors.append(color)
	mesh_data.instance_storage_buffer = TL_RendererUtils.create_particles_instance_storage_buffer(instance_transforms, instance_colors)

	mesh_data.model_matrix_bytes = TL_RendererUtils.proj_to_bytes(Projection(cpu_particles.global_transform))
	particles_data.mesh_data = mesh_data

	for i in range(0, cpu_particles.mesh.get_surface_count()):
		var material : BaseMaterial3D =  cpu_particles.mesh.surface_get_material(i)
		var mat_feat_flags : TL_MaterialFeatureFlags_Def = _TL_Renderer_Factory.create_material_feature_flags(material, mesh_data.skeleton_data != null, true)

		var material_data : MaterialData = create_from_material(material, mat_feat_flags)

		var surface_data : SurfaceData = _create_orphan_surface(cpu_particles.mesh, i, mat_feat_flags)
		surface_data.mesh_data = mesh_data
		surface_data.material_data = material_data
		mesh_data.surfaces_data.append(surface_data)

		if mat_feat_flags.is_transparent():
			surface_data.sort_key = generate_opaque_sort_key(surface_data)

	return particles_data

static func free_particles(particles_data : ParticlesData):
	free_mesh(particles_data.mesh_data)
