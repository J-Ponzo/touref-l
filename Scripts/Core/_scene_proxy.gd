class_name _TL_SceneProxy

class MeshProxy:
	var model_matrix : Projection
	var index_data : PackedInt32Array
	var position_data : PackedVector3Array
	var normal_data : PackedVector3Array
	var uv_data : PackedVector2Array

class _LightProxy:
	var color : Color
	var intensity : float

class OmniLightProxy extends _LightProxy:
	var location : Vector3

class DirectionalLightProxy extends  _LightProxy:	
	var direction : Vector3

class SpotLightProxy extends  _LightProxy:	
	var location : Vector3
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
