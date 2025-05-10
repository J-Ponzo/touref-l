@tool
extends CodeEdit
class_name TL_GLSLCodeEdit

@export var code_conpletion_on_typing = true

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

func _on_text_changed():
	var is_shrinking = last_size > text.length()
	last_size = text.length()
	
	if !code_conpletion_on_typing:
		return
	
	if is_shrinking:
		return
	
	var unicode_before = find_unicode_before_caret()
	if unicode_before == -1 || TL_GLSLSyntax.is_symbol(unicode_before):
		cancel_code_completion()
		return
	
	add_static_code_completion_options()
	update_code_completion_options(true)

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
