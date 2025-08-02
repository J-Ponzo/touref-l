extends Resource
class_name TL_FramebufferFormat_Def

@export var depth_key : StringName
# @export var attachment_format_defs : Dictionary[StringName, TL_AttachmentFormat_Def]
@export var color_keys : Array[StringName]

func get_all_attachment_keys() -> Array[StringName]:
	var keys : Array[StringName] = []
	if !depth_key.is_empty():
		keys.append(depth_key)
	keys.append_array(color_keys)
	return keys
