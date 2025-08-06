extends Resource
class_name TL_RenderPassDef

@export var pass_script : GDScript
@export var fb_format_def : TL_FramebufferFormat_Def
@export var pso_defs : Dictionary[StringName, TL_ExpicitPSODef]     # TODO rename to explicite_pso_def
@export var uber_vertex_shader : TL_GLSLShader
@export var uber_fragment_shader : TL_GLSLShader
@export var defines : Array[StringName]
@export var generated_pso_defs : Dictionary[StringName, TL_GeneratedPSODef]