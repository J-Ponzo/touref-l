class_name _TL_ProxyQueueManager

var proxy_queue_manager_def : TL_ProxyQueueManagerDef
var renderer : _TL_Renderer

var proxy_queues : Dictionary[StringName, TL_ProxyQueue]

func _setup() -> void:
	for queue_name : StringName in proxy_queue_manager_def.queues_def.keys():
		proxy_queues[queue_name] = TL_ProxyQueue.new()
		proxy_queues[queue_name].proxy_queue_def = proxy_queue_manager_def.queues_def[queue_name]
		proxy_queues[queue_name]._setup(renderer.proxy_model)

func _update() -> void:
	for proxy_queue : TL_ProxyQueue in proxy_queues.values():
		proxy_queue._process(renderer.proxy_model)
