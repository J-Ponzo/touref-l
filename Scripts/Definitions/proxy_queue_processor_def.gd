extends Resource
class_name TL_ProxyQueueProcessorDef

const ERR_BASE_PROCESSOR_INVOKED = "TourefL : TL_ProxyQueueProcessorDef is intended to be subclassed to specify processing behaviours. Invoking the base classe as is does nothing"

@export var active : bool = true

func _setup(proxy_model : _TL_ProxyModel) -> void:
    pass

func _process(proxy_model : _TL_ProxyModel, data : Array[_TL_ProxyData]) -> Array[_TL_ProxyData]:
    return data