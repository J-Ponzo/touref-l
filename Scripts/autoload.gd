extends Node
class_name autoload

const  ERR_RENDERER_WRONG_PARENT = "TourefL : Cannot instantiate the renderer from class %s. It must inherit from _TL_Renderer."
const  ERR_RENDERER_IDX_UNDEFINED = "TourefL: Cannot switch the active renderer to %d. No renderers are registered at this index. Check your renderers_registry.tres file."

const NATIVE_RENDERER_IDX = -1
const INVALID_RENDERER_IDX = -2

var registry : TL_RenderersRegistry_Def = preload("res://renderers_registry.tres")

var renderers : Array[_TL_Renderer]
var active_renderer_idx : int = NATIVE_RENDERER_IDX

var sub_viewport_container : SubViewportContainer
var sub_viewport : SubViewport
var texture_rect : TextureRect

var native_sub_viewport_container : SubViewportContainer
var native_sub_viewport : SubViewport

func _enter_tree() -> void:
	for renderer_def : TL_RendererDef in registry.rederer_defs:
		var instance = renderer_def.renderer_script.new()
		if instance is _TL_Renderer:
			renderers.append(instance)
		else :
			push_error(ERR_RENDERER_WRONG_PARENT % renderer_def.renderer_script)
	
	native_sub_viewport_container = SubViewportContainer.new()
	native_sub_viewport_container.stretch = true;
	native_sub_viewport_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	native_sub_viewport = SubViewport.new()
	native_sub_viewport_container.add_child(native_sub_viewport)
	
	sub_viewport_container = SubViewportContainer.new()
	sub_viewport_container.stretch = true;
	sub_viewport_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	#todo check drawcalls with default clear mode / update mode
	sub_viewport = SubViewport.new()
	sub_viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_NEVER
	sub_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	sub_viewport.disable_3d = true;
	sub_viewport_container.add_child(sub_viewport)
	
	texture_rect = TextureRect.new()
	texture_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	sub_viewport.add_child(texture_rect)

func _ready() -> void:
	var scene = get_tree().current_scene
	scene.get_parent().add_child.call_deferred(native_sub_viewport_container)
	scene.reparent.call_deferred(native_sub_viewport)
	
	add_child(sub_viewport_container)
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
	sub_viewport_container.visible = true
	native_sub_viewport_container.visible = false
	
func _put_custom_renderer_offline(renderer_idx : int) -> void:
	texture_rect.texture = null
	active_renderer_idx = INVALID_RENDERER_IDX
	renderers[renderer_idx]._cleanup()

func _put_renderer_online(renderer_idx : int) -> void:
	if renderer_idx == NATIVE_RENDERER_IDX:
		_put_native_renderer_online()
	else :
		_put_custom_renderer_online(renderer_idx)
	active_renderer_idx = renderer_idx

func _put_native_renderer_online() -> void:
	sub_viewport_container.visible = false
	native_sub_viewport_container.visible = true

func _put_custom_renderer_online(renderer_idx : int) -> void:
	renderers[renderer_idx]._setup()
	
	var render_target_from_rd : Texture2DRD = Texture2DRD.new()
	render_target_from_rd.texture_rd_rid = renderers[renderer_idx].render_target
	texture_rect.texture = render_target_from_rd
	
func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		pass
	else:
		if active_renderer_idx != INVALID_RENDERER_IDX and active_renderer_idx != NATIVE_RENDERER_IDX:
			renderers[active_renderer_idx]._render()
			
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
			
