extends _TL_ProxyData
class_name _TL_SecondaryData
func get_class_name() -> StringName:
	push_warning(ERR_GETCLASSNAME_NOT_OVERRIDEN % "_TL_SecondaryData")
	return "_TL_SecondaryData"

static func construct(type : GDScript, proxy_model : _TL_ProxyModel, primary_data : _TL_PrimaryData) -> _TL_SecondaryData:
	var instance : _TL_SecondaryData = type.new()
	primary_data.secondary_data.append(instance)
	instance.primary_data = primary_data
	proxy_model._register(instance)
	return instance

var primary_data : _TL_PrimaryData

func get_proxy_object() -> _TL_ProxyObject:
	return primary_data.proxy_object
