extends Resource
class_name _TL_PSODepthStencilDef

@export var back_op_compare : RenderingDevice.CompareOperator = RenderingDevice.CompareOperator.COMPARE_OP_ALWAYS
@export var back_op_compare_mask : int = 0
@export var back_op_depth_fail : RenderingDevice.StencilOperation = RenderingDevice.StencilOperation.STENCIL_OP_ZERO
@export var back_op_fail : RenderingDevice.StencilOperation = RenderingDevice.StencilOperation.STENCIL_OP_ZERO
@export var back_op_pass : RenderingDevice.StencilOperation = RenderingDevice.StencilOperation.STENCIL_OP_ZERO
@export var back_op_reference : int = 0
@export var back_op_write_mask : int = 0
@export var depth_compare_operator : RenderingDevice.CompareOperator = RenderingDevice.CompareOperator.COMPARE_OP_ALWAYS
@export var depth_range_max : float = 0.0
@export var depth_range_min : float = 0.0
@export var enable_depth_range : bool = false
@export var enable_depth_test : bool = false
@export var enable_depth_write : bool = false
@export var enable_stencil : bool = false
@export var front_op_compare : RenderingDevice.CompareOperator = RenderingDevice.CompareOperator.COMPARE_OP_ALWAYS
@export var front_op_compare_mask : int = 0
@export var front_op_depth_fail : RenderingDevice.StencilOperation = RenderingDevice.StencilOperation.STENCIL_OP_ZERO
@export var front_op_fail : RenderingDevice.StencilOperation = RenderingDevice.StencilOperation.STENCIL_OP_ZERO
@export var front_op_pass : RenderingDevice.StencilOperation = RenderingDevice.StencilOperation.STENCIL_OP_ZERO
@export var front_op_reference : int = 0
@export var front_op_write_mask : int = 0