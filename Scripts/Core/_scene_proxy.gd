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

func _on_pre_render() -> void:
	pass

func _on_post_render() -> void:
	pass

func get_current_camera() -> TL_DefaultModel.CameraData:
	return null
	
func get_static_surfaces() -> Array[TL_DefaultModel.SurfaceData]:
	return []

func get_skeletal_surfaces() -> Array[TL_DefaultModel.SurfaceData]:
	return []

func get_omni_lights() -> Array[TL_DefaultModel.OmniLightData]:
	return []

func get_spot_lights() -> Array[TL_DefaultModel.SpotLightData]:
	return []
	
func get_directional_lights() -> Array[TL_DefaultModel.DirectionalLightData]:
	return []
