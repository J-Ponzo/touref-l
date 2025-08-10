extends _TL_ClassNameType
class_name _TL_ProxyData
func get_class_name() -> StringName:
	push_warning(ERR_GETCLASSNAME_NOT_OVERRIDEN % "_TL_ProxyData")
	return "_TL_ProxyData"
