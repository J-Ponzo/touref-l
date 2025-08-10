class_name _TL_ProxyModel

var renderer : _TL_Renderer

var data_registry : Dictionary[StringName, DataBucket]

func create_from(obj : Object) -> Object:
	return null

func free_data(data : Object):
	pass

func _register(proxy_data : _TL_ProxyData) -> void:
	var type : StringName = proxy_data.get_class_name()
	if !data_registry.has(type):
		data_registry[type] = DataBucket.new()
	data_registry[type].data.append(proxy_data)

func _unregister(proxy_data : _TL_ProxyData) -> void:
	var type : StringName = proxy_data.get_class_name()
	var idx : int = data_registry[type].data.find(proxy_data)
	data_registry[type].data.remove_at(idx)

func _get_data_from_type(type : StringName) -> Array[Object]:
	if !data_registry.has(type):
		return []
	return data_registry[type].data
