extends ResourceFormatLoader
class_name TL_GLSLShaderLoader

const  ERR_CANNOT_OPEN_FILE = "TourefL : Cannot load glsl shader (failed to open %s file)"

func _get_recognized_extensions() -> PackedStringArray:
	TL_Plugin.debug_print("TL_GLSLShaderLoader._get_recognized_extensions() invoked")
	return ["frag", "vert"]

func  _recognize_path(path: String, type: StringName) -> bool:
	TL_Plugin.debug_print("TL_GLSLShaderLoader._recognize_path(path: String = %s, type: StringName = %s) invoked" % [path, type])
	return path.get_extension() in _get_recognized_extensions()

func _load(path: String, original_path: String, use_sub_threads: bool, cache_mode: int) -> Resource:
	TL_Plugin.debug_print("TL_GLSLShaderLoader._load(path: String = %s, original_path: String = %s, use_sub_threads: bool = %s, cache_mode: int = %s) invoked" % [path, original_path, use_sub_threads, cache_mode])
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error(ERR_CANNOT_OPEN_FILE % path)
		return null
	var shader = TL_GLSLShader.new()
	shader.source_code = file.get_as_text()
	return shader
