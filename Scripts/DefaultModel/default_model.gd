extends _TL_Model
class_name TL_DefaultModel

class CameraData:
	var view_matrix : Projection
	var projection_matrix : Projection

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
	var model_matrix : Projection
	var surfaces_data : Array[SurfaceData]

class SurfaceData:
	var mesh_data : MeshData

	var index_count : int
	var index_buffer : RID

	var vertex_count : int
	var position_buffer : RID
	var normal_buffer : RID
	var tangent_buffer : RID
	var uv_buffer : RID

	var material_data : MaterialData

class MaterialData:
	var albedo_tex : RID
	var normal_tex : RID
	var orm_tex : RID
