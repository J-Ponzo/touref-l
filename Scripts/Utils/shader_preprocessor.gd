extends Object
class_name TL_Shader_Preprocessor

const use_filenames_in_line_directives : bool = true

# TODO find something more reliable for persistant debug reatures
static var _is_debug = true

static func preprocess(path : String, raw_source: String, defines : Array[StringName]) -> String:
	var already_included_paths = {}
	var preprocessed_source : String = _expand_includes_rec(path, raw_source, already_included_paths)
	preprocessed_source  = _inject_defines(preprocessed_source, defines)

	if _is_debug:
		print(preprocessed_source)
	return preprocessed_source

static func _inject_defines(raw_source: String, defines : Array[StringName]) -> String:
	var lines = raw_source.split("\n")


	var output = lines[0] + "\n\n"

	for define in defines:
		output += "#define " + define + "\n"
	output += "\n"

	for i in range(1, lines.size()):
		output += lines[i] + "\n"

	return output

static func _expand_includes_rec(path : String, raw_source: String, already_included_paths : Dictionary) -> String:
	if already_included_paths.has(path):
		push_error("Include cycle detected with : %s" % path)
		return ""
	already_included_paths[path] = true
	
	var output = ""
	
	var lines : PackedStringArray = raw_source.split("\n")
	for l in range(0, lines.size()) :
		var line : String = lines[l]
		
		var versionRegex = RegEx.new()
		versionRegex.compile("^#version\\s+([0-9]+)")
		
		var includeRegex = RegEx.new()
		includeRegex.compile("^#include\\s+\"(.*)\"")
		
		var match : RegExMatch = includeRegex.search(line)
		if match:
			var include_path : String = match.get_string(1)
			var include_raw_source : String = FileAccess.get_file_as_string(include_path)
			output += "#line %d \"%s\" \n" % [1, include_path if use_filenames_in_line_directives else ""]
			output += _expand_includes_rec(include_path, include_raw_source, already_included_paths)
			output += "#line %d \"%s\" \n" % [l + 1, path if use_filenames_in_line_directives else ""]
		else:
			output += line + "\n"
			if use_filenames_in_line_directives and versionRegex.search(line):
				output += "#extension GL_GOOGLE_cpp_style_line_directive : require\n"

	return output

static func generate_dummy_shader_for_partial_source(partial_source_path: String, raw_partial_source: String) -> String:
	var dummy_shader = ""
	dummy_shader += "#version 450\n"
	if use_filenames_in_line_directives:
		dummy_shader += "#extension GL_GOOGLE_cpp_style_line_directive : require\n"
	
	dummy_shader += "#line %d \"%s\" \n" % [1, partial_source_path if use_filenames_in_line_directives else ""]
	dummy_shader += _expand_includes_rec(partial_source_path, raw_partial_source, {})
	dummy_shader += "#line %d \"%s\" \n" % [-1, "<dummy_shader>" if use_filenames_in_line_directives else ""]

	dummy_shader += "void main() { }"

	return dummy_shader
