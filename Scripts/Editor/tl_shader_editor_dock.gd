@tool
extends Control
class_name TL_ShaderEditorDock

const EXTENSIONS = {"Vertex": "vert", "Fragment": "frag", "Include": "glslinc"}		# We use glslinc extention because glsl rise conflict with Godot native RDShaderFile resource type
const DIRTY_SUFFIX = " (*)"

const ERR_FAILED_SAVE_SHADER = "Touref-L: Failed to save shader : %s"
const ERR_FAILED_LOAD_SHADER = "Touref-L: Failed to load shader : %s"
const ERR_UNKOWN_SHADER = "Touref-L: Cannot set %s as current edited shader (nothing loaded with this name)"
const WARN_SHADER_ALREADY_LOADED = "Touref-L: The shader %s is already loaded"
const MSG_CONFIRM_RELOAD_EDITED = "Touref-L: The shader %s has been modified by another program.\nThose changes conflicts with your local version. Do you want to reload it anyway ?"

class EditedShader:
	# TODO find something more reliable for persistant debug reatures
	var _is_debug = false

	var shader : TL_GLSLShader
	var idx : int
	var is_dirty : bool
	var content : String
	var sha_256 : PackedByteArray
	var last_compile_output : String
	var syntax_highlighter : TL_GLSLSyntaxHighlighter
		
	func load_from_shader_resource():
		content = shader.source_code
		sha_256 = content.sha256_buffer()
		is_dirty = false
		syntax_highlighter = TL_GLSLSyntaxHighlighter.new() 
		syntax_highlighter._setup(content, null)
		ast_update()
	
	func save_to_shader_resource():
		shader.source_code = content
		var err = ResourceSaver.save(shader, shader.resource_path)
		if err != OK:
			push_error(ERR_FAILED_SAVE_SHADER % shader.resource_path)
			return
		sha_256 = content.sha256_buffer()
		is_dirty = false

	func update_dirty_flag():
		is_dirty = content.sha256_buffer() != sha_256

	var ast_update_thread : Thread
	var want_cancel_ast_update = false
	var parser : TL_GLSLTokenizer= TL_GLSLTokenizer.new() 
	var tokenize_batch_size : int = 4096

	signal tokenize_finished()

	func ast_update() -> void:
		if ast_update_thread != null and ast_update_thread.is_alive():
			want_cancel_ast_update = true
			ast_update_thread.wait_to_finish()

		parser.reset(content)

		want_cancel_ast_update = false
		ast_update_thread = Thread.new()
		ast_update_thread.start(_asyn_ast_update)

	func _asyn_ast_update() -> void:
		while not want_cancel_ast_update:
			if parser.batch_tokenize(tokenize_batch_size):
				break
		if not want_cancel_ast_update:
			syntax_highlighter = TL_GLSLSyntaxHighlighter.new() 
			syntax_highlighter._setup(content, parser.tokens_data)
			call_deferred("_emit_tokenize_finished")
	
	func _emit_tokenize_finished() -> void:
		tokenize_finished.emit()

# TODO find something more reliable for persistant debug reatures
var _is_debug = false

var current_shader_key : String = ""
var edited_shaders : Dictionary[String, EditedShader]

var save_shortcut := Shortcut.new()
var create_shader_dialog : TLShaderCreateDialog = preload("res://addons/touref-l/Scenes/TLShaderCreateDialog.tscn").instantiate()
var load_shader_dialog : FileDialog
var confirm_reload_edited_dialog : ConfirmationDialog
var confirm_reload_edited_dialog_path_param : String = ""

var _editor_interface : EditorInterface

func set_editor_interface(editor_interface_inst : EditorInterface):
	_editor_interface = editor_interface_inst
	_editor_interface.get_resource_filesystem().connect("resources_reload", _on_resources_reload)
	_editor_interface.get_file_system_dock().connect("file_removed", _on_file_removed)
	_editor_interface.get_file_system_dock().connect("folder_removed", _on_dir_removed)
	_editor_interface.get_file_system_dock().connect("files_moved", _on_file_moved)
	_editor_interface.get_file_system_dock().connect("folder_moved", _on_dir_moved)

func _ready() -> void:
	var key_event := InputEventKey.new()
	key_event.keycode = KEY_S
	key_event.ctrl_pressed = true
	save_shortcut.events = [key_event]
	
	create_shader_dialog.shader_editor_dock = self
	create_shader_dialog.hide()
	create_shader_dialog.shader_created.connect(_create_shader)
	add_child(create_shader_dialog)
	
	var filter : String
	for ext in EXTENSIONS.values():
		filter += "*." + ext + ", "
	filter.trim_suffix(", ")
	load_shader_dialog = FileDialog.new()
	load_shader_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	load_shader_dialog.mode_overrides_title = false
	load_shader_dialog.title = "Load Touref-L Shader"
	load_shader_dialog.ok_button_text = "Load"
	load_shader_dialog.clear_filters()
	load_shader_dialog.add_filter(filter, "Tourf-L shader files")
	load_shader_dialog.hide()
	load_shader_dialog.file_selected.connect(_load_shader)
	add_child(load_shader_dialog)
	
	confirm_reload_edited_dialog = ConfirmationDialog.new()
	confirm_reload_edited_dialog.title = "Confirm External Modification"
	confirm_reload_edited_dialog.get_ok_button().connect("pressed", _on_confirm_reload_edited)
	confirm_reload_edited_dialog.hide()
	add_child(confirm_reload_edited_dialog)
	
	%NewButton.connect("pressed", new_shader_action)
	%LoadButton.connect("pressed", load_shader_action)
	%CloseButton.connect("pressed", close_shader_action)
	
	%SaveButton.connect("pressed", save_shader_action)
	%CompileButton.connect("pressed", compile_shader_action)
	
	%ShaderCodeEdit.connect("text_changed", _on_shader_code_changed)
	%ShaderFilesList.connect("item_selected", _on_shader_selected)

func new_shader_action() -> void:
	create_shader_dialog.init(_editor_interface.get_current_path())
	create_shader_dialog.popup_centered()

func _create_shader(path : String) -> void:
	var shader := TL_GLSLShader.new()

	var err = ResourceSaver.save(shader, path)
	if err != OK:
		push_error(ERR_FAILED_SAVE_SHADER % path)
		return

	_load_shader(path)

func load_shader_action() -> void:
	load_shader_dialog.current_dir = _editor_interface.get_current_path().get_base_dir()
	load_shader_dialog.popup_centered()

func _load_shader(path : String) -> void:
	if edited_shaders.has(path):
		push_warning(WARN_SHADER_ALREADY_LOADED % path)
		set_current_shader(path)
		return
	
	var shader : TL_GLSLShader = ResourceLoader.load(path)
	if shader == null:
		push_error(ERR_FAILED_LOAD_SHADER % path)
		return

	edited_shaders[path] = EditedShader.new()
	edited_shaders[path].idx = %ShaderFilesList.item_count
	edited_shaders[path].shader = shader
	edited_shaders[path].load_from_shader_resource()
	
	%ShaderFilesList.add_item(path.get_file())
	
	set_current_shader(path)

func _on_edited_shader_tokenize_finished() -> void:
	%ShaderCodeEdit.syntax_highlighter = edited_shaders[current_shader_key].syntax_highlighter
	if _is_debug:
		print(%ShaderCodeEdit.syntax_highlighter._tokens_data.debug_tokens_to_str())

func set_current_shader(new_shader_key : String) -> bool:
	if edited_shaders.has(current_shader_key):
		edited_shaders[current_shader_key].disconnect("tokenize_finished", _on_edited_shader_tokenize_finished)

	current_shader_key = new_shader_key
	
	if current_shader_key.is_empty():
		%FileNameLabel.text = "[Empty]"
		%ShaderCodeEdit.editable = false
		%ShaderCodeEdit.visible = false
		%ShaderCodeEdit.text = ""
		%SaveButton.disabled = true
		%CloseButton.disabled = true
		%CompileButton.disabled = true
		%ConsoleTextEdit.text = ""
		return true
	
	if not edited_shaders.has(current_shader_key):
		push_error(ERR_UNKOWN_SHADER % current_shader_key)
		return false
	
	var new_edited_shader = edited_shaders[current_shader_key]
	new_edited_shader.connect("tokenize_finished", _on_edited_shader_tokenize_finished)
	if not %ShaderFilesList.is_selected(new_edited_shader.idx):
		%ShaderFilesList.select(new_edited_shader.idx)
	%FileNameLabel.text = current_shader_key
	%ShaderCodeEdit.editable = true
	%ShaderCodeEdit.visible = true
	%ShaderCodeEdit.text = new_edited_shader.content
	%ConsoleTextEdit.text = new_edited_shader.last_compile_output
	%CloseButton.disabled = false
	%CompileButton.disabled = false
	
	_set_shader_dirty(current_shader_key, new_edited_shader.is_dirty)

	%ShaderCodeEdit.syntax_highlighter = new_edited_shader.syntax_highlighter

	return true

func save_shader_action() -> void:
	edited_shaders[current_shader_key].save_to_shader_resource()
	_set_shader_dirty(current_shader_key, false)
	
func close_shader_action() -> void:
	close_shader(current_shader_key)
	
func close_shader(shader_key : String) -> void:
	var idx : int = edited_shaders[shader_key].idx
	edited_shaders.erase(shader_key)
	%ShaderFilesList.remove_item(idx)
	for value in edited_shaders.values():
		if value.idx > idx:
			value.idx -= 1
	
	if shader_key == current_shader_key:
		set_current_shader("")

func compile_shader_action() -> void:
	var current_edited_shader : EditedShader = edited_shaders[current_shader_key]
	
	var shader_source = RDShaderSource.new()
	shader_source.language = RenderingDevice.SHADER_LANGUAGE_GLSL
	var raw_source = edited_shaders[current_shader_key].content
	var path = current_shader_key
	var preprocessed_source = TL_Shader_Preprocessor.preprocess(path, raw_source)
	if current_shader_key.get_extension() == EXTENSIONS["Vertex"]:
		shader_source.source_vertex = preprocessed_source
	elif current_shader_key.get_extension() == EXTENSIONS["Fragment"]:
		shader_source.source_fragment = preprocessed_source
	elif current_shader_key.get_extension() == EXTENSIONS["Include"]:
		var dummy_shader_preprocessed_source = TL_Shader_Preprocessor.generate_dummy_shader_for_partial_source(path, raw_source)
		shader_source.source_vertex = dummy_shader_preprocessed_source

	var rd = RenderingServer.get_rendering_device()
	var result = rd.shader_compile_spirv_from_source(shader_source)
	
	var err_text = result.compile_error_vertex + result.compile_error_fragment
	current_edited_shader.last_compile_output = "Compile SUCCESS" if err_text.is_empty() else err_text
	%ConsoleTextEdit.text = current_edited_shader.last_compile_output

# The "dirty" detection strategy could be heavy on big files but until 5000 lines it's
# still not noticable. So we keep with this until it's a problem.
func _on_shader_code_changed():
	var current_shader : EditedShader = edited_shaders[current_shader_key]
	current_shader.content = %ShaderCodeEdit.text
	current_shader.ast_update()
	var was_dirty = current_shader.is_dirty
	current_shader.update_dirty_flag()
	if was_dirty != current_shader.is_dirty:
		_set_shader_dirty(current_shader_key, current_shader.is_dirty)
	
func _set_shader_dirty(shader_key : String, dirty : bool) -> void:	
	var edited_shader : EditedShader = edited_shaders[shader_key]
	edited_shader.is_dirty = dirty
	
	var suffix = DIRTY_SUFFIX if dirty else ""
	var decorated_name = shader_key.get_file() + suffix
	%ShaderFilesList.set_item_text(edited_shader.idx, decorated_name)
	
	if shader_key == current_shader_key:
		var decorated_path = shader_key + suffix
		%FileNameLabel.text = decorated_path
		%SaveButton.disabled = !dirty
	
func _on_shader_selected(idx : int):
	for edited_shader_key in edited_shaders.keys():
		if edited_shaders[edited_shader_key].idx == idx:
			set_current_shader(edited_shader_key)

func _on_resources_reload(resources: PackedStringArray):
	for resource in resources:
		for key in edited_shaders.keys():
			if key == resource:
				_try_reload_edited_from_shader_resouce(key)

func _try_reload_edited_from_shader_resouce(path : String) -> void:
	if edited_shaders[path].is_dirty:
		confirm_reload_edited_dialog_path_param = path
		confirm_reload_edited_dialog.dialog_text = MSG_CONFIRM_RELOAD_EDITED % path
		confirm_reload_edited_dialog.popup_centered()
	else:
		_reload_edited_from_shader_resouce(path)

func _on_confirm_reload_edited() -> void:
	_reload_edited_from_shader_resouce(confirm_reload_edited_dialog_path_param)
	
func _reload_edited_from_shader_resouce(path : String) -> void:
	edited_shaders[path].load_from_shader_resource()
	_set_shader_dirty(path, false)
	if path == current_shader_key:
		set_current_shader(current_shader_key)		# Reload the ShaderCodeEdit

func _unhandled_key_input(event):
	if save_shortcut.matches_event(event):
		_on_save_shortcut_invoked()

func _on_save_shortcut_invoked():
	if current_shader_key.is_empty():
		return
		
	var current_edited_shader : EditedShader = edited_shaders[current_shader_key]
	if current_edited_shader.is_dirty:
		save_shader_action()

func _on_file_removed(path: String):
	if edited_shaders.has(path):
		close_shader(path)
	
func _on_dir_removed(path: String):
	for key : String in edited_shaders.keys():
		if key.begins_with(path):
			close_shader(key)

func _on_file_moved(old_path: String, new_path: String):
	if edited_shaders.has(old_path):
		_move_shader(old_path, new_path)
		
func _on_dir_moved(old_path: String, new_path: String):
	for key : String in edited_shaders.keys():
		if key.begins_with(old_path):
			_move_shader(old_path, new_path)
			
func _move_shader(old_key: String, new_key: String):
	var moved_shader : EditedShader = edited_shaders[old_key]
	edited_shaders.erase(old_key)
	edited_shaders[new_key] = moved_shader
	%ShaderFilesList.set_item_text(moved_shader.idx, new_key.get_file())
	
	if old_key == current_shader_key:
		set_current_shader(new_key)
	
	_set_shader_dirty(new_key, moved_shader.is_dirty)
