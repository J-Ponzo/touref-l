extends Resource
class_name TL_PSODef

static var rd = RenderingServer.get_rendering_device()

class TL_PSOInst:
	var shader_program : RID
	var pipeline : RID
	var vertex_format : int

@export var vertex_shader : TL_GLSLShader
@export var fragment_shader : TL_GLSLShader
@export var is_skeletal : bool

func instanciate(framebuffer : RID, nb_color_attachment : int, depth_test : bool = true) -> TL_PSOInst:
	var instance = TL_PSOInst.new()

	var path : String = vertex_shader.resource_path
	var raw_source : String = vertex_shader.source_code
	var preprocessed_source : String = TL_Shader_Preprocessor.preprocess(path, raw_source)
	var vertex_shader_src : String = preprocessed_source
	
	path = fragment_shader.resource_path
	raw_source = fragment_shader.source_code
	preprocessed_source = TL_Shader_Preprocessor.preprocess(path, raw_source)
	var fragment_shader_src : String = preprocessed_source

	instance.shader_program = TL_RendererUtils.compile_shader(vertex_shader_src, fragment_shader_src)

	if is_skeletal:
		instance.vertex_format = TL_DefaultModel.get_or_create_skeletal_mesh_vertex_format()
	else :
		instance.vertex_format = TL_DefaultModel.get_or_create_static_mesh_vertex_format()

	instance.pipeline = TL_RendererUtils.create_pipline(nb_color_attachment, instance.shader_program, framebuffer, instance.vertex_format, depth_test)

	return instance
