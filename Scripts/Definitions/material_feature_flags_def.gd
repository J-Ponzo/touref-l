extends Resource
class_name TL_MaterialFeatureFlags_Def

@export var is_skeletal : bool
@export var is_lit : bool
@export var is_instanced : bool
@export var has_albedo_map : bool
@export var has_normal_map : bool
@export var has_orm_map : bool

@export var cull_mode : RenderingDevice.PolygonCullMode
@export var render_mode : TL_PSODef.ERenderMode

func is_transparent() -> bool:
    return render_mode == TL_PSODef.ERenderMode.Transparent_Mix or render_mode == TL_PSODef.ERenderMode.Transparent_Add or render_mode == TL_PSODef.ERenderMode.Transparent_Subtract or render_mode == TL_PSODef.ERenderMode.Transparent_Multiply or render_mode == TL_PSODef.ERenderMode.Transparent_PremultAlpha
