class_name _TL_SceneProxy

class ProxyObject:
	var scene_proxy : _TL_SceneProxy	# TODO Remove
	var node : Node
	var data
	var _is_active : bool

	func update_data() -> void:
		var visible_in_tree = node.is_visible_in_tree()
		if _is_active != visible_in_tree:
			set_active(visible_in_tree)
	
	func set_active(active : bool) -> void:
		_is_active = active

var proxy_objects_cache : Dictionary[Node, ProxyObject]
# var type_buckets_cache : Dictionary[StringName, DataBucket]	# TODO implement type search later

var render : _TL_Renderer
var _scene_root : Node

func _setup(scene_root : Node) -> void:
	_scene_root = scene_root

	var all_nodes : Array = _find_all_in_tree(_scene_root, func(node : Node): return true)
	for node in all_nodes:
		on_node_enter_tree(node)

	_scene_root.get_tree().node_added.connect(on_node_enter_tree)
	_scene_root.get_tree().node_removed.connect(on_node_exit_tree)

func on_node_enter_tree(node: Node) -> void:
	var proxy_object : ProxyObject = _create_proxy_object(node)

	if proxy_object != null:
		proxy_object._is_active = node.is_visible_in_tree()
		proxy_objects_cache[node] = proxy_object
		proxy_object.node = node
		proxy_object.scene_proxy = self

		# TODO implement type search later
		# var data_class = proxy_object.data.get_class()
		# if !type_buckets_cache.has(data_class):
		# 	type_buckets_cache[data_class] = DataBucket.new()
		# type_buckets_cache[data_class].data.append(data)

		if render.feature_flag_manager != null:
			render.feature_flag_manager._register(proxy_object)


func _create_proxy_object(node : Node) -> ProxyObject:
	return null

func _cleanup() -> void:
	_scene_root.get_tree().node_added.disconnect(on_node_enter_tree)
	_scene_root.get_tree().node_removed.disconnect(on_node_exit_tree)

	var all_nodes : Array = _find_all_in_tree(_scene_root, func(node : Node): return true)
	for node in all_nodes:
		on_node_exit_tree(node)

func on_node_exit_tree(node : Node) -> void:
	if !proxy_objects_cache.has(node):
		return

	var proxy_object : ProxyObject = proxy_objects_cache[node]
	proxy_objects_cache.erase(node)

	if render.feature_flag_manager != null:
		render.feature_flag_manager._unregister(proxy_object)

	_free_proxy_object(proxy_object)

func _free_proxy_object(proxy_object : ProxyObject) -> void:
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

func _on_pre_render() -> void:
	pass

func _on_post_render() -> void:
	pass

# TODO implement type search later
# func get_data_from_type(type : StringName) -> Array[Object]: 
# 	return []

func get_data_from_query(query : _TL_FeatureFlagManager.FeatureFlagQuery) -> Array[Object]:
	if render.feature_flag_manager != null:
		return render.feature_flag_manager.query_objects(query)
	return []

func get_current_camera() -> TL_DefaultModel.CameraData:
	return null
	
func get_static_surfaces() -> Array[TL_DefaultModel.SurfaceData]:
	return []

func get_skeletal_surfaces() -> Array[TL_DefaultModel.SurfaceData]:
	return []

func get_instanced_surfaces() -> Array[TL_DefaultModel.SurfaceData]:
	return []

func get_omni_lights() -> Array[TL_DefaultModel.OmniLightData]:
	return []

func get_spot_lights() -> Array[TL_DefaultModel.SpotLightData]:
	return []
	
func get_directional_lights() -> Array[TL_DefaultModel.DirectionalLightData]:
	return []
