@tool
extends Window
class_name TLShaderCreateDialog

const ERR_EMPTY_PATH = "Path cannot be empty"
const ERR_PATH_ALRADY_EXISTS = "File already exists"
const ERR_DIR_NOT_EXISTS = "The directory %s do not exists"
const ERR_WRONG_PATH_PREFFIX = "Path must start with 'res://'"
const ERR_PARENT_SYMBOL = "Path cannot contain '..'"
const ERR_INVALID_CHARACTERS = "Path contains invalid characters"
const ERR_WRONG_EXT = "Wrong file extension (%s expected)"
const ERR_SPACES_FORBIDEN = "Spaces are not allowed"
const MSG_VALID_PATH = "Path is valid"

const DEFAULT_NAME = "my_shader"

signal shader_created(path: String)

var shader_editor_dock : TL_ShaderEditorDock

func _ready() -> void:
	connect("close_requested", close_dialog)
	
	%ShaderTypeOption.clear()
	for key in shader_editor_dock.EXTENSIONS.keys():
		%ShaderTypeOption.add_item(key)
	%ShaderTypeOption.item_selected.connect(_on_shader_type_selected)
	
	%ShaderPath.text_changed.connect(_validate_path)
	
	%CreateButton.pressed.connect(_on_create_pressed)
	%CancelButton.pressed.connect(close_dialog)

func init(filesystem_path : String) -> void:
	%ShaderPath.text = filesystem_path.get_base_dir() + "/" 
	%ShaderPath.text += DEFAULT_NAME + "." + shader_editor_dock.EXTENSIONS[get_selected_ext_key()]
	_validate_path(%ShaderPath.text)

func get_selected_ext_key() -> String:
	return %ShaderTypeOption.get_item_text(%ShaderTypeOption.selected) 

func _on_shader_type_selected(idx : int):
	var new_ext_key = shader_editor_dock.EXTENSIONS.keys()[idx]
	%ShaderPath.text = %ShaderPath.text.get_basename() + "." + shader_editor_dock.EXTENSIONS[new_ext_key]
	_validate_path(%ShaderPath.text)

func _validate_path(path : String) -> void:
	var errors : Array[String] = _check_path(path)
	%CreateButton.disabled = !errors.is_empty()
	
	%Error_TextEdit.text = ""
	for error in errors:
		%Error_TextEdit.text += error + "\n"
	
	if errors.is_empty():
		%Error_TextEdit.text = MSG_VALID_PATH
		

func _check_path(path : String) -> Array[String]:
	var errors : Array[String]
	if path == "":
		errors.append(ERR_EMPTY_PATH)
	if FileAccess.file_exists(path):
		errors.append(ERR_PATH_ALRADY_EXISTS)
	if not path.begins_with("res://"):
		errors.append(ERR_WRONG_PATH_PREFFIX)
	if path.find("..") != -1:
		errors.append(ERR_PARENT_SYMBOL)
	if path.find(" ") != -1:
		errors.append(ERR_SPACES_FORBIDEN)
	
	var base_dir = path.get_base_dir()
	if not DirAccess.dir_exists_absolute(base_dir):
		errors.append(ERR_DIR_NOT_EXISTS % base_dir)
	
	var expected_ext = shader_editor_dock.EXTENSIONS[get_selected_ext_key()]
	if path.get_extension() != expected_ext:
		errors.append(ERR_WRONG_EXT % expected_ext)
	
	var regex = RegEx.new()
	regex.compile(r"^[a-zA-Z0-9_\-.\/]+$")
	if regex.search(path.trim_prefix("res://")) == null:
		errors.append(ERR_INVALID_CHARACTERS)
	
	return errors

func _on_create_pressed():
	emit_signal("shader_created", %ShaderPath.text)
	hide()

func close_dialog() -> void:
	hide()
