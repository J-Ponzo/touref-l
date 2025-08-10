class_name _TL_ProxyObject 

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
