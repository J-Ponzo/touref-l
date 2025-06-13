class_name _TL_SceneProxy

class ProxyData:
	func init_data() -> void:
		pass

	func update_data() -> void:
		init_data()

	func free_rids() -> void:
		pass

class ProxyObject extends ProxyData:
	var node : Node
	
class MeshProxy extends ProxyObject:
	var model_matrix : Projection
	var surface_proxies : Array[SurfaceProxy]

	func init_data() -> void:
		var mesh : MeshInstance3D = node
		
		model_matrix = Projection(mesh.global_transform)
		surface_proxies.clear()
		for i in range(0, mesh.mesh.get_surface_count()):
			var surface_proxy : SurfaceProxy = SurfaceProxy.new()
			surface_proxy.slot = i
			surface_proxy.mesh_proxy = self
			surface_proxies.append(surface_proxy)
			surface_proxy.init_data()

	func free_rids() -> void:
		for surface_proxy in surface_proxies:
			surface_proxy.free_rids()

	func update_data() -> void:
		var mesh : MeshInstance3D = node
		model_matrix = Projection(mesh.global_transform)
		for surface_proxy in surface_proxies:
			surface_proxy.update_data()

class SurfaceProxy extends ProxyData:
	var rd = RenderingServer.get_rendering_device()

	var mesh_proxy : MeshProxy
	var slot : int

	var index_count : int
	var index_buffer : RID

	var vertex_count : int
	var position_buffer : RID
	var normal_buffer : RID
	var tangent_buffer : RID
	var uv_buffer : RID

	var material_proxy : MaterialProxy

	func init_data() -> void:
		var mesh : MeshInstance3D = mesh_proxy.node

		var arrays = mesh.mesh.surface_get_arrays(slot)
		
		index_count = arrays[Mesh.ARRAY_INDEX].size()
		var byte_array = arrays[Mesh.ARRAY_INDEX].to_byte_array()
		index_buffer = rd.index_buffer_create(arrays[Mesh.ARRAY_INDEX].size(), RenderingDevice.INDEX_BUFFER_FORMAT_UINT32, byte_array)

		vertex_count = arrays[Mesh.ARRAY_VERTEX].size()
		byte_array = arrays[Mesh.ARRAY_VERTEX].to_byte_array()
		position_buffer = rd.vertex_buffer_create(byte_array.size(), byte_array)

		byte_array = arrays[Mesh.ARRAY_NORMAL].to_byte_array()
		normal_buffer = rd.vertex_buffer_create(byte_array.size(), byte_array)

		byte_array = arrays[Mesh.ARRAY_TANGENT].to_byte_array()
		tangent_buffer = rd.vertex_buffer_create(byte_array.size(), byte_array)

		byte_array = arrays[Mesh.ARRAY_TEX_UV].to_byte_array()
		uv_buffer = rd.vertex_buffer_create(byte_array.size(), byte_array)

		material_proxy = mat_proxy_from_mat(mesh.get_active_material(slot))

	func update_data() -> void:
		pass

	func mat_proxy_from_mat(material : BaseMaterial3D) -> MaterialProxy:
		var mat_proxy : MaterialProxy = MaterialProxy.new()

		mat_proxy.albedo_tex = RenderingServer.texture_get_rd_texture(material.albedo_texture)
		mat_proxy.normal_tex = RenderingServer.texture_get_rd_texture(material.normal_texture)
		mat_proxy.orm_tex =  RenderingServer.texture_get_rd_texture(material.orm_texture)

		return mat_proxy

	func free_rids() -> void:
		if index_buffer != RID():
			rd.free_rid(index_buffer)
		if position_buffer != RID():
			rd.free_rid(position_buffer)
		if normal_buffer != RID():
			rd.free_rid(normal_buffer)
		if tangent_buffer != RID():
			rd.free_rid(tangent_buffer)
		if uv_buffer != RID():
			rd.free_rid(uv_buffer)

	func _notification(what):
		if what == NOTIFICATION_PREDELETE:	# We can't invoke free_rids because funcs are not available on NOTIFICATION_PREDELETE
			if index_buffer != RID():
				rd.free_rid(index_buffer)
			if position_buffer != RID():
				rd.free_rid(position_buffer)
			if normal_buffer != RID():
				rd.free_rid(normal_buffer)
			if tangent_buffer != RID():
				rd.free_rid(tangent_buffer)
			if uv_buffer != RID():
				rd.free_rid(uv_buffer)

class MaterialProxy extends ProxyData:
	var albedo_tex : RID
	var normal_tex : RID
	var orm_tex : RID

class _LightProxy extends ProxyObject:
	var color : Color
	var intensity : float

class _LocalizedLight extends _LightProxy:
	var location : Vector3
	var range : float
	var attenuation : float

class OmniLightProxy extends _LocalizedLight:
	func init_data() -> void:
		var omni : OmniLight3D = node
		color = omni.light_color
		intensity = omni.light_energy
		location = omni.global_position
		range = omni.omni_range
		attenuation = omni.omni_attenuation

class DirectionalLightProxy extends  _LightProxy:	
	var direction : Vector3

	func init_data() -> void:
		var directional : DirectionalLight3D = node
		color = directional.light_color
		intensity = directional.light_energy
		direction = -directional.global_basis.z

class SpotLightProxy extends  _LocalizedLight:	
	var direction : Vector3
	var angle : float
	var angle_attenuation : float

	func init_data() -> void:
		var spot : SpotLight3D = node
		color = spot.light_color
		intensity = spot.light_energy
		location = spot.global_position
		direction = -spot.global_basis.z
		angle = deg_to_rad(spot.spot_angle)
		angle_attenuation = spot.spot_angle_attenuation
		range = spot.spot_range
		attenuation = spot.spot_attenuation

class CameraProxy extends ProxyObject:
	var view_matrix : Projection
	var projection_matrix : Projection

	func init_data() -> void:
		var cam : Camera3D = node
		view_matrix = Projection(cam.get_camera_transform().affine_inverse())
		projection_matrix = cam.get_camera_projection().flipped_y()

func _setup(scene_root : Node) -> void:
	pass

func _update() -> void:
	pass

func get_current_camera() -> CameraProxy:
	return null
	
func get_surfaces() -> Array[SurfaceProxy]:
	return []
	
func get_omni_lights() -> Array[OmniLightProxy]:
	return []

func get_spot_lights() -> Array[SpotLightProxy]:
	return []
	
func get_directional_lights() -> Array[DirectionalLightProxy]:
	return []
	
func _cleanup() -> void:
	pass
