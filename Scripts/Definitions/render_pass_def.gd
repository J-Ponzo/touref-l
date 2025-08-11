extends Resource
class_name TL_RenderPassDef

@export var pass_script : GDScript
@export var fb_format_def : TL_FramebufferFormat_Def
@export var explicite_pso_defs : Dictionary[StringName, TL_ExpicitPSODef]
@export var generated_pso_defs : Dictionary[StringName, TL_GeneratedPSODef]