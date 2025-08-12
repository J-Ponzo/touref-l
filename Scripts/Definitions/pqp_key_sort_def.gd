extends TL_ProxyQueueProcessorDef
class_name TL_PQPKeySortDef

@export var sort_queue_name : StringName
@export var reverse_order : bool = false

var proxy_queue_manager : _TL_ProxyQueueManager

# TODO find more direct init
func _setup(proxy_model : _TL_ProxyModel) -> void:
	proxy_queue_manager = proxy_model.renderer.proxy_queue_manager

func is_before(data_1 : _TL_ProxyData, data_2 : _TL_ProxyData) -> bool:
	return proxy_queue_manager.data_key_lookup[data_1].key < proxy_queue_manager.data_key_lookup[data_2].key

func is_after(data_1 : _TL_ProxyData, data_2 : _TL_ProxyData) -> bool:
	return proxy_queue_manager.data_key_lookup[data_1].key > proxy_queue_manager.data_key_lookup[data_2].key

func _process(proxy_model : _TL_ProxyModel, data : Array[_TL_ProxyData]) -> Array[_TL_ProxyData]:
	var callable : Callable = is_before
	if reverse_order:
		callable = is_after
	proxy_queue_manager.sort_queues[sort_queue_name].data.sort_custom(callable)
	return proxy_queue_manager.sort_queues[sort_queue_name].data
