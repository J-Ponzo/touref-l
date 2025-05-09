extends ResourceFormatSaver
class_name TL_GLSLShaderSaver

const  ERR_CANNOT_OPEN_FILE = "TourefL : Cannot save glsl shader (failed to open %s file)"

func _get_recognized_extensions(resource: Resource) -> PackedStringArray:
	TL_Plugin.debug_print("TL_GLSLShaderSaver._get_recognized_extensions(resource: Resource = %s) invoked" % resource)
	if resource is TL_GLSLShader:
		return ["frag", "vert", "glslinc"]
	return []

func _recognize(resource: Resource) -> bool:
	TL_Plugin.debug_print("TL_GLSLShaderSaver._recognize(resource: Resource = %s) invoked" % resource)
	return resource is TL_GLSLShader

func _save(resource: Resource, path: String, flags: int) -> Error:
	TL_Plugin.debug_print("TL_GLSLShaderSaver._save(resource: Resource = %s, path: String = %s, flags: int = %s) invoked" % [resource, path, flags])
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error(ERR_CANNOT_OPEN_FILE % path)
		return ERR_CANT_OPEN

	file.store_string(resource.source_code)
	file.close()
	return OK
