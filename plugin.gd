@tool
extends EditorPlugin

const AUTOLOAD_NAME = "TourefL"
const AUTOLOAD_PATH = "res://addons/touref-l/Scripts/autoload.gd"
const SHADER_EDITOR_DOCK_NAME = "Touref-L Shader Editor"

const  MSG_PLUGIN_ENABLED = "TourefL : Plugin enabled"
const  MSG_PLUGIN_DISABLED = "TourefL : Plugin disabled"

var shader_editor_dock : TL_ShaderEditorDock

func _enter_tree() -> void:
	print(MSG_PLUGIN_ENABLED)
	add_autoload_singleton(AUTOLOAD_NAME, AUTOLOAD_PATH)
	
	shader_editor_dock = preload("res://addons/touref-l/Scenes/TLShaderEditorDock.tscn").instantiate()
	add_control_to_bottom_panel(shader_editor_dock, SHADER_EDITOR_DOCK_NAME)

func _exit_tree() -> void:
	print(MSG_PLUGIN_DISABLED)
	remove_autoload_singleton(AUTOLOAD_NAME)
	remove_control_from_bottom_panel(shader_editor_dock)
