class_name TL_ProxyQueue

var proxy_queue_def : TL_ProxyQueueDef

var queue_processors : Array[TL_ProxyQueueProcessor]
var data : Array[_TL_ProxyData]

func _setup(proxy_model : _TL_ProxyModel) -> void:
	for queue_processor_def : TL_ProxyQueueProcessorDef in proxy_queue_def.queue_processors:
		var queue_processor : TL_ProxyQueueProcessor = TL_ProxyQueueProcessor.new()
		queue_processor.proxy_queue_processor_def = queue_processor_def
		queue_processors.append(queue_processor)
		queue_processor._setup(proxy_model)

func _process(proxy_model : _TL_ProxyModel) -> void:
	var processed_data : Array[_TL_ProxyData]
	for queue_processor : TL_ProxyQueueProcessor in queue_processors:
		processed_data = queue_processor._process(proxy_model, processed_data)
	data = processed_data
