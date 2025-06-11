class_name _TL_SceneProxy

class MeshProxy:
	var rd = RenderingServer.get_rendering_device()

	var model_matrix : Projection

	var index_count : int
	var index_buffer : RID

	var vertex_count : int
	var position_buffer : RID
	var normal_buffer : RID
	var tangent_buffer : RID
	var uv_buffer : RID

	var material_proxy : MaterialProxy

	func _notification(what):
		if what == NOTIFICATION_PREDELETE:
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


class MaterialProxy:
	var albedo_tex : RID
	var normal_tex : RID
	var orm_tex : RID

class _LightProxy:
	var color : Color
	var intensity : float

class _LocalizedLight extends _LightProxy:
	var location : Vector3
	var range : float
	var attenuation : float

class OmniLightProxy extends _LocalizedLight:
	pass

class DirectionalLightProxy extends  _LightProxy:	
	var direction : Vector3

class SpotLightProxy extends  _LocalizedLight:	
	var direction : Vector3
	var angle : float
	var angle_attenuation : float

class CameraProxy:
	var view_matrix : Projection
	var projection_matrix : Projection

func _setup(scene_root : Node) -> void:
	pass

func get_current_camera() -> CameraProxy:
	return null
	
func get_meshes() -> Array[MeshProxy]:
	return []
	
func get_omni_lights() -> Array[OmniLightProxy]:
	return []

func get_spot_lights() -> Array[SpotLightProxy]:
	return []
	
func get_directional_lights() -> Array[DirectionalLightProxy]:
	return []
	
func _cleanup() -> void:
	pass
