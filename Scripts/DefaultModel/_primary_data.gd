extends _TL_ProxyData
class_name _TL_PrimaryData
func get_class_name() -> StringName:
	push_warning(ERR_GETCLASSNAME_NOT_OVERRIDEN % "_TL_PrimaryData")
	return "_TL_PrimaryData"

static func construct(type : GDScript, proxy_model : _TL_ProxyModel) -> _TL_PrimaryData:
	var instance : _TL_PrimaryData = type.new()
	proxy_model._register(instance)
	return instance

var proxy_object : _TL_ProxyObject
var secondary_data : Array[_TL_SecondaryData]
