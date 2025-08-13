extends Resource
class_name TL_RendererDef

@export var renderer_script : GDScript
@export var scene_proxy_script : GDScript
@export var renderer_pass_defs : Dictionary[StringName, TL_RenderPassDef]
@export var attachment_format_defs : Dictionary[StringName, TL_AttachmentFormat_Def]
@export var feature_flag_manager_def : TL_FeatureFlagManager_Def
@export var proxy_model_script : GDScript
@export var proxy_queues_manager_def : TL_ProxyQueueManagerDef
@export var sort_key_manager_def : TL_SortKeyManagerDef
