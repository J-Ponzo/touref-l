extends Resource
class_name TL_ProxyQueueDef

@export var queue_processors : Array[TL_ProxyQueueProcessorDef]

func _setup(proxy_model : _TL_ProxyModel) -> void:
    for processor : TL_ProxyQueueProcessorDef in queue_processors:
        processor._setup(proxy_model)