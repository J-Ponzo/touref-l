class_name _TL_SortKeyManager

class Name_Key_Pair:
	var sort_queue_name : StringName
	var key : int

class Data_NameKey_Pair:
	var data : _TL_ProxyData
	var name_key : Name_Key_Pair

class SortQueueInfo:
	var is_dirty : bool
	var keygen : _TL_KeyGen
	var keysort : TL_DefaultKeySort

var sort_key_manager_def : TL_SortKeyManagerDef
var renderer : _TL_Renderer

var proxy_data_lookup : Dictionary[_TL_ProxyObject, DataBucket]
var data_key_lookup : Dictionary[_TL_ProxyData, Name_Key_Pair]
var sort_queues : Dictionary[StringName, DataBucket]
var sort_queues_info : Dictionary[StringName, SortQueueInfo]

# TODO more type checks
func _setup() -> void:
	for queue_name : StringName in sort_key_manager_def.sort_keys_def.keys():
		var key_def : TL_SortKeyDef = sort_key_manager_def.sort_keys_def[queue_name]
		sort_queues[queue_name] = DataBucket.new()
		var queue_info : SortQueueInfo = SortQueueInfo.new()
		queue_info.is_dirty = true
		queue_info.keygen = key_def.keygen_script.new()
		if key_def.keysort_script != null:
			queue_info.keysort = key_def.keysort_script.new()
		else:
			queue_info.keysort = TL_DefaultKeySort.new()
		sort_queues_info[queue_name] = queue_info

func _update() -> void:
	for queue_name : StringName in sort_queues.keys():
		if sort_queues_info[queue_name].is_dirty:
			sort_queue(queue_name)

func sort_queue(queue_name : StringName, clear_dirty : bool = true) -> void:
	# sort
	sort_queues_info[queue_name].is_dirty = false

func _register(proxy_object : _TL_ProxyObject) -> void:
	if proxy_data_lookup.has(proxy_object):
		return

	var keyed_items : Array[Data_NameKey_Pair] = _extract_keyed_data(proxy_object)
	var items_bucket : DataBucket = DataBucket.new()
	for keyed_item in keyed_items:
		var data : _TL_ProxyData = keyed_item.data
		var queue_name : StringName = keyed_item.name_key.sort_queue_name
		keyed_item.name_key.key = sort_queues_info[queue_name].keygen._generate(data)
		items_bucket.data.append(data)
		data_key_lookup[keyed_item.data] = keyed_item.name_key
		sort_queues[queue_name].data.append(data)

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
