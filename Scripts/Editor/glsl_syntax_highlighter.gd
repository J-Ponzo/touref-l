extends SyntaxHighlighter
class_name TL_GLSLSyntaxHighlighter

const CHAR_TO_UNICODE = {
	'\t': 9,
	' ': 32,
	'!': 33,
	'"': 34,
	'#': 35,
	'/': 47,
	'0': 48,
	'9': 57,
	':': 58,
	'@': 64,
	'[': 91,
	'_': 95,
	'`': 96,
	'{': 123,
	'~': 126,
}

const GLSL_CONTROL_FLOW = [
	"if", 
	"else",
	"for",
	"while", 
	"do",
	"break", 
	"continue",
	"return", 
	"discard"
]

const GLSL_BASE_TYPES = [
	"void", 
	"bool",
	"int", 
	"uint", 
	"float", 
	"double",
	"vec2", 
	"vec3", 
	"vec4",
	"ivec2", 
	"ivec3", 
	"ivec4",
	"uvec2", 
	"uvec3", 
	"uvec4",
	"bvec2", 
	"bvec3", 
	"bvec4",
	"mat2", 
	"mat3", 
	"mat4",
	"mat2x2", 
	"mat2x3", 
	"mat2x4", 
	"mat3x2", 
	"mat3x3", 
	"mat3x4", 
	"mat4x2", 
	"mat4x3", 
	"mat4x4",
	"sampler1D", 
	"sampler2D", 
	"sampler3D", 
	"samplerCube",
	"isampler1D", 
	"isampler2D", 
	"isampler3D", 
	"isamplerCube",
	"usampler1D", 
	"usampler2D", 
	"usampler3D", 
	"usamplerCube",
	"sampler1DShadow", 
	"sampler2DShadow", 
	"samplerCubeShadow",
	"sampler1DArray", 
	"sampler2DArray", 
	"samplerCubeArray",
	"isampler1DArray", 
	"isampler2DArray",
	"usampler1DArray", 
	"usampler2DArray",
	"sampler2DMS", 
	"isampler2DMS",
	"usampler2DMS",
	"sampler2DRect", 
	"sampler2DRectShadow",
	"samplerBuffer", 
	"isamplerBuffer", 
	"usamplerBuffer",
	"image1D", 
	"image2D", 
	"image3D", 
	"imageCube",
	"iimage1D", 
	"iimage2D", 
	"iimage3D", 
	"iimageCube",
	"uimage1D", 
	"uimage2D", 
	"uimage3D", 
	"uimageCube",
	"image1DArray", 
	"image2DArray",
	"iimage1DArray", 
	"iimage2DArray",
	"uimage1DArray", 
	"uimage2DArray",
	"imageBuffer", 
	"iimageBuffer", 
	"uimageBuffer",
	"atomic_uint"
]

const GLSL_TYPE_QUALIFIERS = [
	"const", 
	"in", 
	"out", 
	"inout",
	"uniform", 
	"buffer", 
	"shared",
	"layout", 
	"set", 
	"binding", 
	"location",
	"centroid", 
	"sample", 
	"patch", 
	"smooth", 
	"flat", 
	"noperspective",
	"struct"
]

const GLSL_STD_FUNCS = [
	"abs", 
	"sign",
	"floor", 
	"trunc", 
	"round", 
	"roundEven", 
	"ceil", 
	"fract", 
	"mod", 
	"modf", 
	"min", 
	"max", 
	"clamp", 
	"mix", 
	"step",
	"smoothstep", 
	"isnan", 
	"isinf", 
	"floatBitsToInt", 
	"floatBitsToUint", 
	"intBitsToFloat", 
	"uintBitsToFloat", 
	"fma", 
	"frexp", 
	"ldexp",
	"pow", 
	"exp", 
	"log", 
	"exp2", 
	"log2", 
	"sqrt", 
	"inversesqrt",
	"sin", 
	"cos", 
	"tan", 
	"asin", 
	"acos", 
	"atan", 
	"sinh", 
	"cosh", 
	"tanh", 
	"asinh", 
	"acosh", 
	"atanh", 
	"atan2",
	"length", 
	"distance", 
	"dot", 
	"cross", 
	"normalize", 
	"faceforward", 
	"reflect", 
	"refract",
	"texture", 
	"textureSize", 
	"textureQueryLevels", 
	"textureQueryLod", 
	"texelFetch", 
	"texelFetchOffset", 
	"textureProj", 
	"textureLod", 
	"textureOffset", 
	"textureProjOffset", 
	"textureLodOffset", 
	"textureProjLod", 
	"textureProjLodOffset", 
	"textureGrad", 
	"textureGradOffset", 
	"textureProjGrad", 
	"textureProjGradOffset",
	"dfdx", 
	"dfdy", 
	"fwidth"
]

const GLSL_STD_FUNCNAME_COLOR = Color(0.9, 0.6, 0.2)
const GLSL_CONTROL_FLOW_COLOR = Color(0.9, 0.2, 0.6)
const GLSL_BASE_TYPES_COLOR = Color(0.2, 0.6, 0.9)
const GLSL_QUALIFIERS_COLOR = Color(0.9, 0.3, 0.3)
const TEXT_COLOR = Color(0.9, 0.9, 0.9)
const PREPROC_COLOR = Color(0.1, 0.5, 0.1)
const SYMBOL_COLOR = Color(0.6, 0.8, 0.9)
const COMMENT_COLOR = Color(0.6, 0.6, 0.6)
const NUMERIC_COLOR = Color(0.7, 0.9, 0.7)
const CUSTOM_FUNCNAME_COLOR = Color(0.2, 0.6, 0.9)

func _get_line_syntax_highlighting(line_number: int) -> Dictionary:
	var line : String = get_text_edit().get_line(line_number)

	var words : Dictionary = {}
	var cur_word = ""
	var cur_symb_streak = ""
	for col in line.length():
		var unicode : int = line.unicode_at(col)
		if is_symbol(unicode):
			if cur_word.is_empty():
				cur_symb_streak += line[col]
			else:
				words[words.size()] = {
					"word" = cur_word,
					"start" = col - cur_word.length(),
					"is_symb_streak" = false
				}
				cur_word = ""
				cur_symb_streak = line[col]
		else:
			if cur_symb_streak.is_empty():
				cur_word += line[col]
			else:
				words[words.size()] = {
					"word" = cur_symb_streak,
					"start" = col - cur_symb_streak.length(),
					"is_symb_streak" = true
				}
				cur_symb_streak = ""
				cur_word = line[col]
	if !cur_word.is_empty():
		words[words.size()] = {
			"word" = cur_word,
			"start" = line.length() - cur_word.length(),
			"is_symb_streak" = false
		}
	elif !cur_symb_streak.is_empty():
		words[words.size()] = {
			"word" = cur_symb_streak,
			"start" = line.length() - cur_symb_streak.length(),
			"is_symb_streak" = true
		}

	return build_color_map(words)



func are_digits(word : String) -> bool:
	for i in word.length():
		var unicode : int = word.unicode_at(i)
		if !is_digit(unicode):
			return false
	return true

func is_digit(unicode : int) -> bool:
	return (unicode >= CHAR_TO_UNICODE['0'] && unicode <= CHAR_TO_UNICODE['9']);;

func is_symbol(unicode : int) -> bool:
	return unicode != CHAR_TO_UNICODE['_'] && ((unicode >= CHAR_TO_UNICODE['!'] && unicode <= CHAR_TO_UNICODE['/']) || (unicode >= CHAR_TO_UNICODE[':'] && unicode <= CHAR_TO_UNICODE['@']) || (unicode >= CHAR_TO_UNICODE['['] && unicode <= CHAR_TO_UNICODE['`']) || (unicode >= CHAR_TO_UNICODE['{'] && unicode <= CHAR_TO_UNICODE['~']) || unicode == CHAR_TO_UNICODE['\t'] || unicode == CHAR_TO_UNICODE[' ']);

func build_color_map(words : Dictionary) -> Dictionary:
	var color_map : Dictionary
	for word in words.values():
		if word["is_symb_streak"] == true:
			color_map[word["start"]] = {"color": SYMBOL_COLOR}
			var word_content = word["word"]
			for i in word_content.length():
				if word_content.unicode_at(i) == CHAR_TO_UNICODE['#']:
					color_map[word["start"] + i] = {"color": PREPROC_COLOR}
					return color_map
				if i + 1 < word_content.length() && word_content.unicode_at(i) == CHAR_TO_UNICODE['/'] && word_content.unicode_at(i + 1) == CHAR_TO_UNICODE['/']:
					color_map[word["start"] + i] = {"color": COMMENT_COLOR}
					return color_map

		elif GLSL_CONTROL_FLOW.has(word["word"]):
			color_map[word["start"]] = {"color": GLSL_CONTROL_FLOW_COLOR}
		elif GLSL_BASE_TYPES.has(word["word"]):
			color_map[word["start"]] = {"color": GLSL_BASE_TYPES_COLOR}
		elif GLSL_TYPE_QUALIFIERS.has(word["word"]):
			color_map[word["start"]] = {"color": GLSL_QUALIFIERS_COLOR}
		elif GLSL_STD_FUNCS.has(word["word"]):
			color_map[word["start"]] = {"color": GLSL_STD_FUNCNAME_COLOR}
		elif are_digits(word["word"]):
			color_map[word["start"]] = {"color": NUMERIC_COLOR}
		else:
			color_map[word["start"]] = {"color": TEXT_COLOR}
	return color_map
