extends Resource
class_name TL_GLSLTokenizer

enum ETokenType {
	BlockComment,
	LineComment,
	Preprocessor,
	Operator,
	Float,
	Identifier,
	BuiltIn,
	EOF,
	Integer,
	Whitespace,
	Keyword,
	Malformed,
	Other
}

class Token:
	var type : ETokenType
	var data : String
	var pos : int
	var line : int
	var col : int

class TokensData:
	var tokens : Array[Token] = []
	var idx_by_line : Dictionary[int, Array] = {}	# 'values' are indicies of token at line 'key' from the 'tokens' array
	func extract_line_token_no_check(line : int) -> Array[Token]:
		var tokens_line : Array[Token] = []
		for i in idx_by_line[line]:
			tokens_line.append(tokens[i])
		return tokens_line
	func get_first_token_before_line(line : int) -> Token:
		line -= 1
		if line < 0:
			return null
		while not idx_by_line.has(line):
			line -= 1
			if line < 0:
				return null
		var last_idx_of_line = idx_by_line[line][idx_by_line[line].size() - 1]
		return tokens[last_idx_of_line]
		# var first_idx_of_line = idx_by_line[line][0]
		# return tokens[first_idx_of_line - 1] if first_idx_of_line != 0 else null
	# TODO replace with _to_string()
	func debug_tokens_to_str() -> String:
		var str : String = "DEBUG TOKENS (%d)\n" % tokens.size()
		for token in tokens:
			str += str(token.type) + " " + token.data + " " + str(token.pos) + " " + str(token.line) + " " + str(token.col) + "\n"
		return str

class TextIterator:
	var text_lines : PackedStringArray
	var text_size : int
	var p : int
	var l : int
	var c : int

	var marked_p : int
	var marked_l : int
	var marked_c : int

	var last_ticked : int
	var line_break_last_tick : bool
	var line_start_last_tick : bool
	var tick_count : int

	func reset(text : String) -> void:
		self.text_lines = text.split('\n', true)
		for i in range(self.text_lines.size()):
			self.text_lines[i] += '\n'
		self.text_size = text.length()
		self.p = 0
		self.l = 0
		self.c = 0
		self.marked_p = -1
		self.marked_l = -1
		self.marked_c = -1
		self.last_ticked = -2	# create const for that
		self.line_break_last_tick = false
		self.line_start_last_tick = false
		self.tick_count = 0

	func mark_last_ticked() -> void:
		# print("mark_last_ticked start %d %d %d" % [p, l, c])
		if last_ticked == -2:
			return
		marked_c = c - 1
		marked_p = p - 1
		marked_l = l
		# print("mark_last_ticked marked %d %d %d" % [marked_p, marked_l, marked_c])
		if marked_c == -1:
			marked_l = l - 1
			marked_c = text_lines[marked_l].length() - 1
			# print("mark_last_ticked fixed marked %d %d %d" % [marked_p, marked_l, marked_c])

	func rest_of_line() -> String:
		if p == text_size:
			return ""
		return text_lines[l].substr(c)

	func skip_rest_of_line() -> void:
		var rest_of_line = rest_of_line()
		var rest_of_line_size = rest_of_line.length()
		tick_count += rest_of_line_size
		p += rest_of_line_size #+ 1	# '\n' must be counted
		l += 1
		line_break_last_tick = true
		c = 0
		last_ticked = rest_of_line.unicode_at(rest_of_line_size - 1)

	func tick() -> int:
		line_start_last_tick = false
		line_break_last_tick = false
		if p == text_size:
			last_ticked = -1
			return -1

		line_start_last_tick = c == 0

		# if l >= text_lines.size():
		# 	push_error("TL_GLSLTokenizer.TextIterator.tick() reashed eof but p(%d) != text_size(%d). It should not happen !" % [p, text_size])
		# 	return -1

		last_ticked = text_lines[l].unicode_at(c)
		c += 1
		p += 1
		tick_count += 1
		var line_length : int = text_lines[l].length()
		if c >= line_length:
			l += 1
			line_break_last_tick = true
			#p += 1	# '\n' must be counted
			c = 0
		return last_ticked
		

	func multi_tick(ticks : int) -> Array[int]:
		var unicodes : Array[int]
		for i in range(0, ticks):
			unicodes.append(tick())
		return unicodes

var ti : TextIterator = TextIterator.new()
var tokens_data : TokensData

func tokenize_all(source : String) -> void:
	reset(source)
	if ti.last_ticked != -1:
		batch_tokenize(source.length())

func reset(source : String) -> void:
	tokens_data = TokensData.new()
	ti.reset(source)
	ti.tick()

func batch_tokenize(nb_ticks : int) -> bool:
	ti.tick_count = 0

	for i in range(0, nb_ticks):
		var unicode : int = ti.last_ticked
		if unicode == -1:
			# print("unicode == -1")
			return true
		
		if ti.tick_count > nb_ticks:
			# print("ti.tick_count > nb_ticks")
			return false

		if TL_CharUtils.is_whitespace(unicode):
			_parse_whitespace_token()
		elif unicode == TL_CharUtils.CHAR_TO_UNICODE['/'] && ti.rest_of_line().unicode_at(0) == TL_CharUtils.CHAR_TO_UNICODE['/']:
			_parse_linecomment_token()
		elif unicode == TL_CharUtils.CHAR_TO_UNICODE['/'] && ti.rest_of_line().unicode_at(0) == TL_CharUtils.CHAR_TO_UNICODE['*']:
			_parse_blockcomment_token()
		elif unicode == TL_CharUtils.CHAR_TO_UNICODE['#']:
			_parse_preprocessor_token()
		elif TL_CharUtils.is_digit(unicode):
			_parse_numeric_token()
		elif TL_CharUtils.is_identifier_head(unicode):
			_parse_identifier_token()
		elif TL_CharUtils.is_symbol(unicode):	# Check Operators after comments so that starting '/' is not considered as Operator
			_parse_operator_token()
		else:
			_parse_malformed_token()
	# print("exit on end of function")
	return false

func _store_token(token : Token):
	if tokens_data.idx_by_line.has(token.line):
		tokens_data.idx_by_line[token.line].append(tokens_data.tokens.size())
	else :
		tokens_data.idx_by_line[token.line] = [tokens_data.tokens.size()]
	tokens_data.tokens.append(token)

func _parse_whitespace_token() -> void:
	ti.mark_last_ticked()
	var data : String = char(ti.last_ticked)
	var unicode = ti.tick()
	while unicode != -1 && TL_CharUtils.is_whitespace(unicode):
		data += char(unicode)
		unicode = ti.tick()

	var token : Token = _create_token(ETokenType.Whitespace, data, ti.marked_p, ti.marked_l, ti.marked_c)

	_store_token(token)

func _parse_preprocessor_token() -> void:
	ti.mark_last_ticked()
	var data : String = char(ti.last_ticked) + ti.rest_of_line()
	ti.skip_rest_of_line()
	ti.tick()

	var token : Token = _create_token(ETokenType.Preprocessor, data, ti.marked_p, ti.marked_l, ti.marked_c)
	_store_token(token)

func _parse_numeric_token() -> void:
	ti.mark_last_ticked()
	var data : String = char(ti.last_ticked)

	var unicode = ti.tick()
	var dot_count = 0
	while !ti.line_start_last_tick && unicode != -1 && TL_CharUtils.is_digit(unicode) || unicode == TL_CharUtils.CHAR_TO_UNICODE["."]:
		if unicode == TL_CharUtils.CHAR_TO_UNICODE["."]:
			dot_count += 1
		data += char(unicode)
		unicode = ti.tick()

	var type = ETokenType.Integer
	if dot_count == 1:
		type = ETokenType.Float
	elif dot_count > 1:
		type = ETokenType.Malformed
	var token : Token = _create_token(type, data, ti.marked_p, ti.marked_l, ti.marked_c)
	_store_token(token)

func _parse_identifier_token() -> void:
	ti.mark_last_ticked()
	var data : String = char(ti.last_ticked)
	var unicode = ti.tick()
	
	while !ti.line_start_last_tick && unicode != -1 && TL_CharUtils.is_identifier_tail(unicode):
		data += char(unicode)
		unicode = ti.tick()

	var type : ETokenType = ETokenType.Identifier
	if TL_GLSLSyntax.GLSL_FUNC_QUALIFIERS.has(data) || TL_GLSLSyntax.GLSL_CONTROL_FLOW.has(data) || TL_GLSLSyntax.GLSL_TYPE_QUALIFIERS.has(data) || TL_GLSLSyntax.GLSL_DEFINITION.has(data):
		type = ETokenType.Keyword
	elif TL_GLSLSyntax.GLSL_BASE_TYPES.has(data) || TL_GLSLSyntax.GLSL_STD_FUNCS.has(data):
		type = ETokenType.BuiltIn
	var token : Token = _create_token(type, data, ti.marked_p, ti.marked_l, ti.marked_c)
	_store_token(token)

func _parse_linecomment_token() -> void:
	ti.mark_last_ticked()
	var data : String = char(ti.last_ticked) + ti.rest_of_line()
	ti.skip_rest_of_line()
	ti.tick()

	var token : Token = _create_token(ETokenType.LineComment, data, ti.marked_p, ti.marked_l, ti.marked_c)
	_store_token(token)

func _parse_blockcomment_token() -> void:
	ti.mark_last_ticked()
	var data : String = "/*"
	var unicode = ti.multi_tick(2)[1]

	while unicode != -1 && (unicode != TL_CharUtils.CHAR_TO_UNICODE['*'] || ti.rest_of_line().unicode_at(0) != TL_CharUtils.CHAR_TO_UNICODE['/']):
		data += char(unicode)
		# if ti.line_break_last_tick:
		# 	data += '\n'
		unicode = ti.tick()

	if unicode != -1:
		data += "*/"
		ti.multi_tick(2)

	var token : Token = _create_token(ETokenType.BlockComment, data, ti.marked_p, ti.marked_l, ti.marked_c)
	_store_token(token)

func _parse_operator_token() -> void:
	ti.mark_last_ticked()
	var data : String = char(ti.last_ticked)
	var token : Token = _create_token(ETokenType.Operator, data, ti.marked_p, ti.marked_l, ti.marked_c)
	_store_token(token)
	ti.tick()

func _parse_malformed_token() -> void:
	ti.mark_last_ticked()
	var data : String = char(ti.last_ticked)
	var token : Token = _create_token(ETokenType.Malformed, data, ti.marked_p, ti.marked_l, ti.marked_c)
	_store_token(token)
	ti.tick()

func _create_token(type , data : String, pos : int, line : int, col : int) -> Token:
	var token : Token = Token.new()
	token.type = type
	token.data = data
	token.pos = pos
	token.line = line
	token.col = col
	return token
