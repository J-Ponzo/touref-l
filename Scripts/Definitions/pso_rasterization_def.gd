extends Resource
class_name _TL_PSORasterisationDef

@export var cull_mode : RenderingDevice.PolygonCullMode = RenderingDevice.PolygonCullMode.POLYGON_CULL_DISABLED
@export var depth_bias_clamp : float = 0.0
@export var depth_bias_constant_factor : float = 0.0
@export var depth_bias_enabled : bool = false
@export var depth_bias_slope_factor : float = 0.0
@export var discard_primitives : bool = false
@export var enable_depth_clamp : bool = false
@export var front_face : RenderingDevice.PolygonFrontFace = RenderingDevice.PolygonFrontFace.POLYGON_FRONT_FACE_CLOCKWISE
@export var line_width : float = 0.0
@export var patch_control_points : int = 1
@export var wireframe : bool = false