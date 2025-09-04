extends _TL_PSODef
class_name TL_ExpicitPSODef

@export var vertex_format_def : TL_VertexFormatDef
@export var cull_mode : RenderingDevice.PolygonCullMode
@export var render_mode : ERenderMode
@export var defines : Array[StringName]
@export var rasterization_state : TL_PSORasterisationDef
@export var multisample_state : TL_PSOMultisampleDef
@export var depth_stencil_state : TL_PSODepthStencilDef
@export var blend_attachments : Array[TL_PSOColorBlendAttachmentDef] = []
@export var blend_constant : Color = Color(0, 0, 0, 1)
@export var enable_logic_op : bool = false
@export var logic_op : RenderingDevice.LogicOperation = RenderingDevice.LogicOperation.LOGIC_OP_CLEAR 
