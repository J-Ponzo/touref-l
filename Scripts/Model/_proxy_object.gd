class_name _TL_ProxyObject 

var scene_proxy : _TL_SceneProxy	# TODO Remove
var node : Node
var _primary_data : _TL_PrimaryData
var _is_active : bool

func bind_primary_data(primary_data : _TL_PrimaryData) -> void:
	_primary_data = primary_data
	_primary_data.proxy_object = self

func get_primary_data() -> _TL_PrimaryData:
	return _primary_data

func update_data() -> void:
	var visible_in_tree = node.is_visible_in_tree()
	if _is_active != visible_in_tree:
		set_active(visible_in_tree)

func set_active(active : bool) -> void:
	_is_active = active
