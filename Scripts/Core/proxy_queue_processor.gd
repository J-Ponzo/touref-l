class_name TL_ProxyQueueProcessor

var proxy_queue_processor_def : TL_ProxyQueueProcessorDef

func _setup(proxy_model : _TL_ProxyModel) -> void:
	proxy_queue_processor_def._setup(proxy_model)

func _process(proxy_model : _TL_ProxyModel, data : Array[_TL_ProxyData]) -> Array[_TL_ProxyData]:
	if !proxy_queue_processor_def.active:
		return data
	return proxy_queue_processor_def._process(proxy_model, data)
