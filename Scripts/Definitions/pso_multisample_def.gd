extends Resource
class_name TL_PSOMultisampleDef

@export var enable_alpha_to_coverage : bool = false
@export var enable_alpha_to_one : bool = false
@export var enable_sample_shading : bool = false
@export var min_sample_shading : float = 0.0
@export var sample_count : RenderingDevice.TextureSamples = RenderingDevice.TextureSamples.TEXTURE_SAMPLES_1
@export var sample_masks : Array[int] = []