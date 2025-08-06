extends Resource
class_name _TL_PSODef

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
