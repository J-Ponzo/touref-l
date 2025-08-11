class_name _TL_ClassNameType
func get_class_name() -> StringName:
	push_warning(ERR_GETCLASSNAME_NOT_OVERRIDEN % "_TL_ClassNameType")
	return "_TL_ClassNameType"

const ERR_GETCLASSNAME_NOT_OVERRIDEN = "TourefL: A user defined class name type do not to overrides 'func get_class_name() -> StringName:' while extending '%s'. Touref-L relie on this to identify types since get_class() do not return the expected results for user defined scripts."

static var CLASS_NAME : StringName = "_TL_ClassNameType"
