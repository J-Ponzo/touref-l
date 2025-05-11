extends SyntaxHighlighter
class_name TL_GLSLSyntaxHighlighter

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
		if TL_CharUtils.is_symbol(unicode):
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
		if !TL_CharUtils.is_digit(unicode):
			return false
	return true

func build_color_map(words : Dictionary) -> Dictionary:
	var color_map : Dictionary
	for word in words.values():
		if word["is_symb_streak"] == true:
			color_map[word["start"]] = {"color": SYMBOL_COLOR}
			var word_content = word["word"]
			for i in word_content.length():
				if word_content.unicode_at(i) == TL_CharUtils.CHAR_TO_UNICODE['#']:
					color_map[word["start"] + i] = {"color": PREPROC_COLOR}
					return color_map
				if i + 1 < word_content.length() && word_content.unicode_at(i) == TL_CharUtils.CHAR_TO_UNICODE['/'] && word_content.unicode_at(i + 1) == TL_CharUtils.CHAR_TO_UNICODE['/']:
					color_map[word["start"] + i] = {"color": COMMENT_COLOR}
					return color_map

		elif TL_GLSLSyntax.GLSL_CONTROL_FLOW.has(word["word"]):
			color_map[word["start"]] = {"color": GLSL_CONTROL_FLOW_COLOR}
		elif TL_GLSLSyntax.GLSL_BASE_TYPES.has(word["word"]):
			color_map[word["start"]] = {"color": GLSL_BASE_TYPES_COLOR}
		elif TL_GLSLSyntax.GLSL_TYPE_QUALIFIERS.has(word["word"]):
			color_map[word["start"]] = {"color": GLSL_QUALIFIERS_COLOR}
		elif TL_GLSLSyntax.GLSL_STD_FUNCS.has(word["word"]):
			color_map[word["start"]] = {"color": GLSL_STD_FUNCNAME_COLOR}
		elif are_digits(word["word"]):
			color_map[word["start"]] = {"color": NUMERIC_COLOR}
		else:
			color_map[word["start"]] = {"color": TEXT_COLOR}
	return color_map
