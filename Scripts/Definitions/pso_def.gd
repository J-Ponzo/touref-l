extends Resource
class_name TL_PSODef

enum ERenderMode {
    Opaque,
    Transparent_Mix,
    Transparent_Add,
    Transparent_Subtract,
    Transparent_Multiply,
    Transparent_PremultAlpha,
    AlphaScissor,
    AlphaHash
}

@export var vertex_shader : TL_GLSLShader
@export var fragment_shader : TL_GLSLShader
@export var vertex_format_def : TL_VertexFormatDef
@export var cull_mode : RenderingDevice.PolygonCullMode
@export var render_mode : ERenderMode
@export var defines : Array[StringName]

# @export var material_features_def : TL_MaterialFeatureFlags_Def
