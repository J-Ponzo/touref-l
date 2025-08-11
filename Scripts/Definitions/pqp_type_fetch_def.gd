extends TL_ProxyQueueProcessorDef
class_name TL_PQPTypeFetchDef

@export var type : StringName

func _process(proxy_model : _TL_ProxyModel, data : Array[_TL_ProxyData]) -> Array[_TL_ProxyData]:
	return proxy_model.renderer.scene_proxy.get_data_from_type(type)
