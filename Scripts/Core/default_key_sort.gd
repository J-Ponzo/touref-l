class_name TL_DefaultKeySort

func is_before(sort_key_manager : _TL_SortKeyManager, data_1 : _TL_ProxyData, data_2 : _TL_ProxyData) -> bool:
	return sort_key_manager.data_key_lookup[data_1].key < sort_key_manager.data_key_lookup[data_2].key

func is_after(sort_key_manager : _TL_SortKeyManager, data_1 : _TL_ProxyData, data_2 : _TL_ProxyData) -> bool:
	return sort_key_manager.data_key_lookup[data_1].key > sort_key_manager.data_key_lookup[data_2].key

func _sort(sort_key_manager : _TL_SortKeyManager, data : Array[_TL_ProxyData], reverse : bool = false) -> void:
	var callable : Callable = is_before
	if reverse:
		callable = is_after
	data.sort_custom(callable)
