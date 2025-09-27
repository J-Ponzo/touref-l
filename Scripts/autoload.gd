extends Node
class_name autoload

const ERR_RENDERER_IDX_UNDEFINED = "TourefL: Cannot switch the active renderer to %d. No renderers are registered at this index. Check your renderers_registry.tres file."

const NATIVE_RENDERER_IDX = -1
const INVALID_RENDERER_IDX = -2

var registry : TL_RenderersRegistry_Def = preload("res://renderers_registry.tres")

var renderers : Array[_TL_Renderer]
var active_renderer_idx : int = NATIVE_RENDERER_IDX

var custom_canvas_layer : CanvasLayer
var texture_rect : TextureRect
var root_vp_rid : RID

func _enter_tree() -> void:
	for renderer_def : TL_RendererDef in registry.rederer_defs:
		var renderer_inst = _TL_Renderer_Factory.create_renderer(renderer_def)
		renderers.append(renderer_inst)
	
	root_vp_rid = get_viewport().get_viewport_rid()

	custom_canvas_layer = CanvasLayer.new()
	custom_canvas_layer.layer = RenderingServer.CANVAS_LAYER_MIN
	add_child(custom_canvas_layer)

	texture_rect = TextureRect.new()
	texture_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	custom_canvas_layer.add_child(texture_rect)

var scene 

func _ready() -> void:
	scene = get_tree().current_scene
	switch_active_renderer(0)

func switch_active_renderer(new_renderer_idx : int) -> bool:
	if new_renderer_idx < NATIVE_RENDERER_IDX or new_renderer_idx >= renderers.size():
		push_error(ERR_RENDERER_IDX_UNDEFINED % new_renderer_idx)
		return false
	
	_put_renderer_offline(active_renderer_idx)
	_put_renderer_online(new_renderer_idx)
	
	return true

func _put_renderer_offline(renderer_idx : int) -> void:
	if renderer_idx == NATIVE_RENDERER_IDX:
		_put_native_renderer_offline()
	else:
		_put_custom_renderer_offline(renderer_idx)

func _put_native_renderer_offline() -> void:
	RenderingServer.viewport_set_disable_3d(root_vp_rid, true)
	
func _put_custom_renderer_offline(renderer_idx : int) -> void:
	texture_rect.texture = null
	active_renderer_idx = INVALID_RENDERER_IDX
	renderers[renderer_idx]._cleanup()
	renderers[renderer_idx].scene_proxy._cleanup()

	custom_canvas_layer.visible = false

func _put_renderer_online(renderer_idx : int) -> void:
	if renderer_idx == NATIVE_RENDERER_IDX:
		_put_native_renderer_online()
	else :
		_put_custom_renderer_online(renderer_idx)
	active_renderer_idx = renderer_idx

func _put_native_renderer_online() -> void:
	RenderingServer.viewport_set_disable_3d(root_vp_rid, false)

func _put_custom_renderer_online(renderer_idx : int) -> void:
	renderers[renderer_idx]._setup()
	renderers[renderer_idx].scene_proxy._setup(scene)
	
	var render_target_from_rd : Texture2DRD = Texture2DRD.new()
	render_target_from_rd.texture_rd_rid = renderers[renderer_idx].get_render_target()
	texture_rect.texture = render_target_from_rd

	custom_canvas_layer.visible = true
	
func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		pass
	else:
		if active_renderer_idx != INVALID_RENDERER_IDX and active_renderer_idx != NATIVE_RENDERER_IDX:
			if scene != null:
				renderers[active_renderer_idx].scene_proxy._on_pre_render()
				renderers[active_renderer_idx]._pre_renderer()
				renderers[active_renderer_idx]._render()
				renderers[active_renderer_idx].scene_proxy._on_post_render()
			
func _unhandled_input(event):
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_F1:
			switch_active_renderer(0)
		elif event.pressed and event.keycode == KEY_F2:
			switch_active_renderer(1)
		elif event.pressed and event.keycode == KEY_F3:
			switch_active_renderer(2)
		elif event.pressed and event.keycode == KEY_F4:
			switch_active_renderer(3)
		elif event.pressed and event.keycode == KEY_F5:
			switch_active_renderer(4)
		elif event.pressed and event.keycode == KEY_F6:
			switch_active_renderer(5)
		elif event.pressed and event.keycode == KEY_F7:
			switch_active_renderer(6)
		elif event.pressed and event.keycode == KEY_F8:
			switch_active_renderer(7)
		elif event.pressed and event.keycode == KEY_F9:
			switch_active_renderer(8)
		elif event.pressed and event.keycode == KEY_F10:
			switch_active_renderer(9)
		elif event.pressed and event.keycode == KEY_F11:
			switch_active_renderer(10)
		elif event.pressed and event.keycode == KEY_F12:
			switch_active_renderer(NATIVE_RENDERER_IDX)
			
