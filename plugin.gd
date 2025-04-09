@tool
extends EditorPlugin

const AUTOLOAD_NAME = "TourefL"
const AUTOLOAD_PATH = "res://addons/touref-l/Scripts/autoload.gd"

const  MSG_PLUGIN_ENABLED = "TourefL : Plugin enabled"
const  MSG_PLUGIN_DISABLED = "TourefL : Plugin disabled"

func _enter_tree() -> void:
	print(MSG_PLUGIN_ENABLED)
	add_autoload_singleton(AUTOLOAD_NAME, AUTOLOAD_PATH)

func _exit_tree() -> void:
	print(MSG_PLUGIN_DISABLED)
	remove_autoload_singleton(AUTOLOAD_NAME)
