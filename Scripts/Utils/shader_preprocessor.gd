extends Object
class_name TL_Shader_Preprocessor

static func preprocess(path : String, raw_source: String) -> String:
	var already_included_paths = {}
	var preprocessed_source : String = _expand_includes_rec(path, raw_source, already_included_paths)
	return preprocessed_source

static func _expand_includes_rec(path : String, raw_source: String, already_included_paths : Dictionary) -> String:
	if already_included_paths.has(path):
		push_error("Include cycle detected with : %s" % path)
		return ""
	already_included_paths[path] = true
	
	var output = ""
	
	for line in raw_source.split("\n"):
		output += line + "\n"

	return output
