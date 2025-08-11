extends Resource
class_name TL_ProxyQueueManagerDef

@export var queues_def : Dictionary[StringName, TL_ProxyQueueDef]

func _setup(proxy_model : _TL_ProxyModel) -> void:
    for queue : TL_ProxyQueueDef in queues_def.values():
        queue._setup(proxy_model)