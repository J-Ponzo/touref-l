class_name _TL_SceneProxy

var proxy_objects_cache : Dictionary[Node, _TL_ProxyObject]

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
	var proxy_object : _TL_ProxyObject = _create_proxy_object(node)

	if proxy_object != null:
		proxy_object._is_active = node.is_visible_in_tree()
		proxy_objects_cache[node] = proxy_object
		proxy_object.node = node
		proxy_object.scene_proxy = self
		if render.feature_flag_manager != null:		# TODO check if mandatory
			render.feature_flag_manager._register(proxy_object)
		if render.proxy_queue_manager != null:		# TODO is mandatory, remove whene setup
			render.proxy_queue_manager._register(proxy_object)


func _create_proxy_object(node : Node) -> _TL_ProxyObject:
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

	var proxy_object : _TL_ProxyObject = proxy_objects_cache[node]
	proxy_objects_cache.erase(node)

	if render.feature_flag_manager != null:			# TODO chack if mandatory
		render.feature_flag_manager._unregister(proxy_object)
	if render.proxy_queue_manager != null:		# TODO is mandatory, remove whene setup
		render.proxy_queue_manager._unregister(proxy_object)

	_free_proxy_object(proxy_object)

func _free_proxy_object(proxy_object : _TL_ProxyObject) -> void:
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
	for proxy_object in proxy_objects_cache.values():
		proxy_object.update_data()

func _on_post_render() -> void:
	pass

func get_data_from_type(type : StringName) -> Array[_TL_ProxyData]: 
	return render.proxy_model._get_data_from_type(type)

func get_data_from_query(query : _TL_FeatureFlagManager.FeatureFlagQuery) -> Array[_TL_ProxyData]:
	if render.feature_flag_manager != null:
		return render.feature_flag_manager.query_objects(query)
	return []
