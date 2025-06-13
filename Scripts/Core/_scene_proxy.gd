class_name _TL_SceneProxy

var _scene_root : Node

func _setup(scene_root : Node) -> void:
	_scene_root = scene_root

	var all_nodes : Array = _find_all_in_tree(_scene_root, func(node : Node): return true)
	for node in all_nodes:
		on_node_enter_tree(node)

	_scene_root.get_tree().node_added.connect(on_node_enter_tree)
	_scene_root.get_tree().node_removed.connect(on_node_exit_tree)

func on_node_enter_tree(node: Node) -> void:
	pass

func _cleanup() -> void:
	_scene_root.get_tree().node_added.disconnect(on_node_enter_tree)
	_scene_root.get_tree().node_removed.disconnect(on_node_exit_tree)

	var all_nodes : Array = _find_all_in_tree(_scene_root, func(node : Node): return true)
	for node in all_nodes:
		on_node_exit_tree(node)

func on_node_exit_tree(node : Node) -> void:
	pass

func _find_first_in_tree(root : Node, selector : Callable) -> Variant:
	if selector.call(root):
		return root
		
	for child in root.get_children():
		var selected =  _find_first_in_tree(child, selector)
		if selected != null:
			return selected
	
	return null
	
func _find_all_in_tree(root : Node, selector : Callable) -> Array[Variant]:
	var all_selected : Array[Variant]
	
	if selector.call(root):
		all_selected.append(root)
		
	for child in root.get_children():
		all_selected.append_array(_find_all_in_tree(child, selector))
	
	return all_selected

class ProxyDataProcessor:
	var proxy_data : ProxyData

	func process():
		pass
	

class ProxyData:
	var initializer : ProxyDataProcessor = ProxyDataProcessor.new()
	var updater : ProxyDataProcessor = ProxyDataProcessor.new()

	func init_data() -> void:
		initializer.proxy_data = self
		updater.proxy_data = self
		initializer.process()

	func update_data() -> void:
		updater.process()

	func free_rids() -> void:
		pass

class ProxyObject extends ProxyData:
	var node : Node
	
class MeshProxy extends ProxyObject:
	var model_matrix : Projection
	var surface_proxies : Array[SurfaceProxy]

	func free_rids() -> void:
		for surface_proxy in surface_proxies:
			surface_proxy.free_rids()

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
	pass

class DirectionalLightProxy extends  _LightProxy:	
	var direction : Vector3

class SpotLightProxy extends  _LocalizedLight:	
	var direction : Vector3
	var angle : float
	var angle_attenuation : float

class CameraProxy extends ProxyObject:
	var view_matrix : Projection
	var projection_matrix : Projection

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
