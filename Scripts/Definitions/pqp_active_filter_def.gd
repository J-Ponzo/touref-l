extends TL_ProxyQueueProcessorDef
class_name TL_PQPActiveFilterDef

func _process(proxy_model : _TL_ProxyModel, data : Array[_TL_ProxyData]) -> Array[_TL_ProxyData]:
	var processed_array : Array[_TL_ProxyData]= []
	for item : _TL_ProxyData in data:
		if item.get_proxy_object()._is_active:
			processed_array.append(item)
	return processed_array
