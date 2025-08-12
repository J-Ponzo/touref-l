class_name _TL_ProxyQueueManager

var proxy_queue_manager_def : TL_ProxyQueueManagerDef
var renderer : _TL_Renderer

var keygens : Dictionary[StringName, _TL_KeyGen]
var sort_queues : Dictionary[StringName, DataBucket]

func _register(proxy_object : _TL_ProxyObject) -> void:
	pass

func _unregister(proxy_object : _TL_ProxyObject) -> void:
	pass
