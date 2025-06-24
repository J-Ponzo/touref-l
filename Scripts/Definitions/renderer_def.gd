extends Resource
class_name TL_RendererDef

const ERR_RENDERER_WRONG_PARENT = "TourefL : Cannot instantiate the renderer from class %s. It must inherit from _TL_Renderer."
const ERR_SCNPROXY_WRONG_PARENT = "TourefL : Cannot instantiate the scene proxy from class %s. It must inherit from _TL_SceneProxy."
const ERR_RENDERPASS_WRONG_PARENT = "TourefL : Cannot instantiate the render pass from class %s. It must inherit from _TL_RenderPass."

@export var renderer_script : GDScript
@export var scene_proxy_script : GDScript
@export var renderer_pass_defs : Array[TL_RenderPassDef]

func instanciate() -> _TL_Renderer:
	var renderer_inst = renderer_script.new()
	if renderer_inst is _TL_Renderer:
		var scn_proxy_inst = scene_proxy_script.new()
		if scn_proxy_inst is _TL_SceneProxy:
			var scene_proxy : _TL_SceneProxy = scn_proxy_inst
			var renderer : _TL_Renderer = renderer_inst
			renderer.scene_proxy = scene_proxy
			for render_pass_def : TL_RenderPassDef in renderer_pass_defs:
				var render_pass_inst = render_pass_def.pass_script.new()
				if render_pass_inst is _TL_RenderPass:
					var render_pass : _TL_RenderPass = render_pass_inst
					render_pass.pso_defs = render_pass_def.pso_defs

					render_pass.renderer = renderer
					renderer.render_passes.append(render_pass)
				else:
					push_error(ERR_RENDERPASS_WRONG_PARENT % render_pass_def.pass_script)

			return renderer
		else :
			push_error(ERR_SCNPROXY_WRONG_PARENT % scene_proxy_script)
	else :
		push_error(ERR_RENDERER_WRONG_PARENT % renderer_script)
	
	return null