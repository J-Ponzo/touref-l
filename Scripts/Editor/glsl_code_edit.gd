@tool
extends CodeEdit
class_name TL_GLSLCodeEdit

var parser : TL_GLSLParser = TL_GLSLParser.new()
@export var completion_on_typing : bool = true
@export var completion_delay : float = 0.3

var nb_completion_delay_running = 0

func _ready():
	code_completion_enabled = true
	connect("text_changed", _on_text_changed)
	connect("code_completion_requested", _on_code_completion_requested)

func _confirm_code_completion(replace: bool) -> void:
	var completion_base_size = find_completion_base().length()
	var line = get_caret_line()
	var to_col = get_caret_column()
	var from_col = to_col - completion_base_size
	remove_text(line, from_col, line, to_col)
	
	var index : int = get_code_completion_selected_index()
	var option : Dictionary = get_code_completion_option(index)
	insert_text_at_caret(option["insert_text"])
	if option["kind"] == CodeEdit.KIND_FUNCTION:
		insert_text_at_caret("()")
		set_caret_column(get_caret_column() - 1)
	
	cancel_code_completion()

func find_completion_base() -> String:
	var col := get_caret_column()
	var text := get_line(get_caret_line())

	var start : int = col
	while start > 0 and text[start - 1].is_valid_ascii_identifier():
		start -= 1

	return text.substr(start, col - start)

func _on_code_completion_requested():
	add_static_code_completion_options()
	update_code_completion_options(true)

# TODO find a way to speedup that
func get_caret_position() -> int:
	var position := 0
	var caret_line := get_caret_line()
	var caret_column := get_caret_column()

	for i in range(caret_line):
		position += get_line(i).length() + 1  # +1 for implicit '\n'

	position += caret_column
	return position

var prev_text : String
func _on_text_changed():
	var size_delta = text.length() - last_size
	last_size = text.length()

	var caret_pos : int = get_caret_position()
	var delta_chunk : String
	if size_delta > 0:	# insertion
		delta_chunk = text.substr(caret_pos - size_delta, size_delta)
	else :				# suppression
		delta_chunk = prev_text.substr(caret_pos, -size_delta)
	
	prev_text = text

	var casted : TL_GLSLSyntaxHighlighter = syntax_highlighter
	var origin_line = caret_pos - size_delta
	var nb_line_breaks = sign(size_delta) * delta_chunk.countn('\n')
	if nb_line_breaks != 0:
		casted.register_line_break_event(origin_line, nb_line_breaks)
	
	if !completion_on_typing:
		return
	
	if size_delta < 0:
		return
	
	var unicode_before = find_unicode_before_caret()
	if unicode_before == -1 || TL_CharUtils.is_symbol(unicode_before):
		cancel_code_completion()
		return

	start_completion_delay(completion_delay)

func start_completion_delay(delay : float) -> void:
	nb_completion_delay_running += 1
	await get_tree().create_timer(delay).timeout
	_on_completion_delay_over()


func _on_completion_delay_over() -> void:
	nb_completion_delay_running -= 1
	if nb_completion_delay_running == 0 :
		
		add_static_code_completion_options()
		update_code_completion_options(true)

		# print("start parsing")
		# var start_time = Time.get_ticks_usec()
		# parser.tokenize_all(text)
		# var tokens = parser.tokens
		# var end_time = Time.get_ticks_usec()
		# var elapsed = end_time - start_time
		# print("parsing over : %sms" % (elapsed / 1000.0))
		# print(parser.debug_tokens_to_str(tokens))

func find_unicode_before_caret() -> int:
	var caret_col : int = get_caret_column()
	if caret_col == 0:
		return -1
		
	var current_line = get_line(get_caret_line())
	return current_line.unicode_at(caret_col - 1)

var last_size : int = 0

func add_static_code_completion_options() -> void:
	for word in TL_GLSLSyntax.GLSL_BASE_TYPES:
		add_code_completion_option(CodeEdit.KIND_PLAIN_TEXT, word, word)
	
	for word in TL_GLSLSyntax.GLSL_TYPE_QUALIFIERS:
		add_code_completion_option(CodeEdit.KIND_PLAIN_TEXT, word, word)
		
	for word in TL_GLSLSyntax.GLSL_CONTROL_FLOW:
		add_code_completion_option(CodeEdit.KIND_PLAIN_TEXT, word, word)
		
	for word in TL_GLSLSyntax.GLSL_STD_FUNCS:
		add_code_completion_option(CodeEdit.KIND_FUNCTION, word, word)
