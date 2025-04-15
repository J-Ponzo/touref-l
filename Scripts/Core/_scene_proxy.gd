class_name _TL_SceneProxy

class MeshProxy:
	var model_matrix : Projection
	var index_data : PackedInt32Array
	var vertex_data : PackedVector3Array

class CameraProxy:
	var view_matrix : Projection
	var projection_matrix : Projection

func _setup(scene_root : Node) -> void:
	pass

func get_current_camera() -> CameraProxy:
	return null
	
func get_meshes() -> Array[MeshProxy]:
	return []
	
func _cleanup() -> void:
	pass
