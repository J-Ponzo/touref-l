class_name _TL_PSOFactory

var render_pass : _TL_RenderPass

var generated_pso_def : TL_GeneratedPSODef
var framebuffer_format : int
var nb_color_attachments : int

var mask_lookup : Dictionary[Object, int]
var pso_lookup : Dictionary[int, _TL_PSO]

func get_or_create_pso_from_object(object : Object, forced_defines : Array[StringName] = []) -> _TL_PSO:
	object.get_instance_id()
	if !mask_lookup.has(object):
		_create_pso_from_object(object, forced_defines)
	var mask = mask_lookup[object]
	return pso_lookup[mask]

func _create_pso_from_object(object : Object, forced_defines : Array[StringName]) -> void:
	pass

func _cleanup() -> void:
	for pso_inst in pso_lookup.values():
		_TL_Renderer_Factory.rd.free_rid(pso_inst.pipeline)
		_TL_Renderer_Factory.rd.free_rid(pso_inst.shader_program)
