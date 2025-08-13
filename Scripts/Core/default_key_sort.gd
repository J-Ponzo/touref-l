class_name TL_DefaultKeySort

var manager : _TL_SortKeyManager

func is_before(data_1 : _TL_ProxyData, data_2 : _TL_ProxyData) -> bool:
	return manager.data_key_lookup[data_1].key < manager.data_key_lookup[data_2].key

func is_after(data_1 : _TL_ProxyData, data_2 : _TL_ProxyData) -> bool:
	return manager.data_key_lookup[data_1].key > manager.data_key_lookup[data_2].key

func _sort(data : Array[_TL_ProxyData], reverse : bool = false) -> void:
	var callable : Callable = is_before
	if reverse:
		callable = is_after
	data.sort_custom(callable)
