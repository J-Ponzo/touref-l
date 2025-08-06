class_name _TL_PSOFactory

var mask_lookup : Dictionary[Object, int]
var pso_lookup : Dictionary[int, _TL_PSO]

func get_or_create_pso_from_object(object : Object, generated_pso_def : TL_GeneratedPSODef) -> _TL_PSO:
    if !mask_lookup.has(object):
        _create_pso_from_object(object, generated_pso_def)
    var mask = mask_lookup[object]
    return pso_lookup[mask]

func _create_pso_from_object(object : Object, generated_pso_def : TL_GeneratedPSODef) -> void:
    pass