extends Resource
class_name TL_ProxyQueueManagerDef

@export var queues_def : Dictionary[StringName, TL_ProxyQueueDef]
@export var sort_queues_def : Dictionary[StringName, GDScript]
@export var manager_script : GDScript

func _setup(proxy_model : _TL_ProxyModel) -> void:
    for queue : TL_ProxyQueueDef in queues_def.values():
        queue._setup(proxy_model)