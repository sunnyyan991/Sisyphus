class_name CachedLayer
extends Control
## A layer that renders its drawing into a texture once and then shows that texture,
## so a static picture costs one draw call per frame instead of hundreds.
## Connect to `paint` to draw; call refresh() when the picture changes.

signal paint(cv: CanvasItem)

var _vp: SubViewport
var _canvas: Node2D
var _rect: TextureRect


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_vp = SubViewport.new()
	_vp.transparent_bg = true
	_vp.disable_3d = true
	_vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(_vp)
	_canvas = Node2D.new()
	_vp.add_child(_canvas)
	_canvas.draw.connect(func(): paint.emit(_canvas))
	_rect = TextureRect.new()
	_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_rect.stretch_mode = TextureRect.STRETCH_SCALE
	_rect.texture = _vp.get_texture()
	add_child(_rect)
	resized.connect(refresh)


## Re-render the picture into the texture (at screen resolution, so it stays sharp).
func refresh() -> void:
	if not is_inside_tree() or size.x < 1.0 or size.y < 1.0:
		return
	var k := get_viewport().get_final_transform().get_scale().x if get_viewport() else 1.0
	k = clampf(k, 1.0, 3.0)
	_vp.size = Vector2i(ceili(size.x * k), ceili(size.y * k))
	_canvas.scale = Vector2(k, k)
	_canvas.queue_redraw()
	_vp.render_target_update_mode = SubViewport.UPDATE_ONCE


func _notification(what: int) -> void:
	if what == NOTIFICATION_ENTER_TREE:
		refresh.call_deferred()
