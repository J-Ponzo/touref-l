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

class LineBreakEvent:
	var origin_line : int
	var nb_line_breaks : int
	func revert(line : int):
		if nb_line_breaks > 0 && line > origin_line && line < origin_line + nb_line_breaks:
			return -1
		elif line < origin_line && line > origin_line + nb_line_breaks:
			return -1
		
		if line < origin_line:
			return line
		else:
			return line - nb_line_breaks

var line_break_history_stack : Array[LineBreakEvent]
var color_map_cache : Dictionary[int, Dictionary] = {}
var original_color_maps : Array[Dictionary] = []

# TODO check if both original_text & original_text_lines are used
var original_text : String
var original_text_lines : PackedStringArray
var tokens : Array[TL_GLSLParser.Token]

# TODO remove this debug things
var differential_color_map = {0 : {"color" : Color.MAGENTA}}

func _setup(original_text : String, tokens : Array[TL_GLSLParser.Token]) -> void:
	self.original_text
	self.tokens = tokens
	# fill caches
	original_text_lines = original_text.split('\n', true);
	for l in range(0, original_text_lines.size()):
		var color_map : Dictionary = _build_color_map(l, original_text_lines[l])
		original_color_maps.append(color_map)
	
	print(original_text_lines)
	print(color_map_cache)
	print(original_color_maps)

func register_line_break_event(origin_line : int, nb_line_breaks : int) -> void:
	var line_break_event = LineBreakEvent.new()
	line_break_event.origin_line = origin_line
	line_break_event.nb_line_breaks = nb_line_breaks
	line_break_history_stack.insert(0, line_break_event)

func _get_line_syntax_highlighting(line_number: int) -> Dictionary:
	var line : String = get_text_edit().get_line(line_number)
	return _build_color_map(line_number, line)

func _build_color_map(line_number: int, line: String) -> Dictionary:
	var key = line.hash()
	if color_map_cache.has(key):
		return color_map_cache[key]

	var color_map : Dictionary

	# TODO optimize, we don't need prefix/sufix content, just their size
	var original_line : int = _lookup_original_line(line_number)
	print(original_line)
	if original_line == -1:
		color_map = _build_default_color_map(line)
	else:
		var original_text_line : String = original_text_lines[original_line]
		var untouched_prefix : String = _find_common_prefix(original_text_line, line)
		if original_text_line.length() == untouched_prefix.length():
			color_map = _build_default_color_map(line)
		else:
			var untouched_suffix : String = _find_common_suffix(original_text_line, line)
			var altered_part_length : int = line.length() - untouched_prefix.length() - untouched_suffix.length()
			var altered_part : String = line.substr(untouched_prefix.length(), altered_part_length)
			print("altered_part_length:%s" % altered_part_length)
			print("original_text_line:%s" % original_text_line)
			print("untouched_prefix:%s" % untouched_prefix)
			print("altered_part:%s" % altered_part)
			print("untouched_suffix:%s" % untouched_suffix)
			color_map = _build_mixed_color_map(original_color_maps[original_line], untouched_prefix.length(), altered_part, line.length() - untouched_suffix.length())

	color_map_cache[key] = color_map

	return color_map

func _build_mixed_color_map(original_color_map : Dictionary, last_prefix_pos : int, altered_part : String, first_suffix_pos : int) -> Dictionary:
	var mixed_color_map : Dictionary = {}
	for pos in original_color_map.keys():
		if pos < last_prefix_pos:
			mixed_color_map[pos] = original_color_map[pos]
		elif pos >= first_suffix_pos:
			mixed_color_map[pos + altered_part.length()] = original_color_map[pos]

	var alterd_part_color_map : Dictionary = _build_default_color_map(altered_part)
	for pos in alterd_part_color_map.keys():
		mixed_color_map[pos + last_prefix_pos] = alterd_part_color_map[pos]

	return alterd_part_color_map

func _find_common_suffix(str1 : String, str2 : String) -> String:
	var result : String
	for i in range(0, min(str1.length(), str2.length())):
		if str1[str1.length() - 1 - i] == str2[str2.length() -1 - i]:
			result += str1[str1.length() - 1 - i]
		else:
			break
	return result.reverse()

func _find_common_prefix(str1 : String, str2 : String) -> String:
	var result : String
	for i in range(0, min(str1.length(), str2.length())):
		if str1[i] == str2[i]:
			result += str1[i]
		else:
			break
	return result

func _lookup_original_line(actual_line : int) -> int:
	var line = actual_line
	for event : LineBreakEvent in line_break_history_stack:
		line = event.revert(line)
		if line == -1:
			break
	return line

func _are_digits(word : String) -> bool:
	for i in word.length():
		var unicode : int = word.unicode_at(i)
		if !TL_CharUtils.is_digit(unicode):
			return false
	return true

func _build_default_color_map(line : String) -> Dictionary:
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

	var color_map : Dictionary = _build_color_map_from_words(words)
	return color_map

func _build_color_map_from_words(words : Dictionary) -> Dictionary:
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
		elif _are_digits(word["word"]):
			color_map[word["start"]] = {"color": NUMERIC_COLOR}
		else:
			color_map[word["start"]] = {"color": TEXT_COLOR}
	return color_map
