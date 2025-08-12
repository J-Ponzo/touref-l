class_name _TL_ProxyQueueManager

class Name_Key_Pair:
	var sort_queue_name : StringName
	var key : int

class Data_NameKey_Pair:
	var data : _TL_ProxyData
	var name_key : Name_Key_Pair

var proxy_queue_manager_def : TL_ProxyQueueManagerDef
var renderer : _TL_Renderer

var keygens : Dictionary[StringName, _TL_KeyGen]
var proxy_data_lookup : Dictionary[_TL_ProxyObject, DataBucket]
var data_key_lookup : Dictionary[_TL_ProxyData, Name_Key_Pair]
var sort_queues : Dictionary[StringName, DataBucket]

func _setup() -> void:
	pass

func _register(proxy_object : _TL_ProxyObject) -> void:
	if proxy_data_lookup.has(proxy_object):
		return

	var keyed_items : Array[Data_NameKey_Pair] = _extract_keyed_data(proxy_object)
	var items_bucket : DataBucket = DataBucket.new()
	for keyed_item in keyed_items:
		var data : _TL_ProxyData = keyed_item.data
		var sort_queue_name : StringName = keyed_item.name_key.sort_queue_name
		var key : int = keyed_item.name_key.key
		items_bucket.data.append(data)
		data_key_lookup[keyed_item.data] = keyed_item.name_key
		if !sort_queues.has(sort_queue_name):
			sort_queues[sort_queue_name] = DataBucket.new()
		sort_queues[sort_queue_name].data.append(data)

	proxy_data_lookup[proxy_object] = items_bucket

func _unregister(proxy_object : _TL_ProxyObject) -> void:
	if !proxy_data_lookup.has(proxy_object):
		return
	
	for data in proxy_data_lookup[proxy_object].data:
		var name_key : Name_Key_Pair = data_key_lookup[data]
		var sort_queue_name : StringName = name_key.sort_queue_name
		data_key_lookup.erase(data)
		var idx = sort_queues[sort_queue_name].data.find(data)
		sort_queues[sort_queue_name].data.remove_at(idx)

	proxy_data_lookup.erase(proxy_object)

func _extract_keyed_data(proxy_object : _TL_ProxyObject)  -> Array[Data_NameKey_Pair]:
	return []
