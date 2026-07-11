class_name ToolBoundaries
extends EditorTool

enum Handle { NONE, TOP, BOTTOM, LEFT, RIGHT, TOP_LEFT, TOP_RIGHT, BOTTOM_LEFT, BOTTOM_RIGHT, BODY }

var _state_dragging: bool = false
var _active_handle: Handle = Handle.NONE
var _hover_handle: Handle = Handle.NONE

var _drag_start_mouse: Vector2 = Vector2.ZERO
var _drag_start_rect: Rect2 = Rect2()
var _preview_rect: Rect2 = Rect2()

var _original_boundary: Rect2i = Rect2i()

const HANDLE_HIT_RADIUS: float = 6.0
const HANDLE_DRAW_RADIUS: float = 4.0
const MIN_SIZE: float = 8.0

const HANDLE_COLOR        := Color(1.0, 0.3, 0.3, 0.9)
const HANDLE_HOVER_COLOR  := Color(1.0, 0.9, 0.2, 1.0)
const RECT_COLOR          := Color(1.0, 0.2, 0.2, 0.9)
const RECT_FILL_COLOR     := Color(1.0, 0.2, 0.2, 0.08)

signal boundaries_changed(new_boundaries: Rect2i)

# ---------------------------------------------

func activate() -> void:
	_reset_to_idle()

func deactivate() -> void:
	_cancel_drag()

# ---------------------------------------------

func handle_input(event: InputEvent) -> bool:
	if editor_level == null:
		return false
	
	if event is InputEventMouseMotion:
		var pos := _world_pos()
		
		if _state_dragging:
			_update_drag(pos, Input.is_key_pressed(KEY_SHIFT))
			return true
		
		var new_hover := _handle_at(pos, editor_level.level_info.boundaries)
		if new_hover != _hover_handle:
			_hover_handle = new_hover
		return false
	
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				var pos := _world_pos()
				var handle := _handle_at(pos, editor_level.level_info.boundaries)
				if handle == Handle.NONE:
					return false
				
				_begin_drag(handle, pos)
				return true
			else:
				if _state_dragging:
					_commit_drag()
					return true
		
		if mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed and _state_dragging:
			_cancel_drag()
			return true
	
	return false

func draw(canvas: CanvasItem) -> void:
	if editor_level == null:
		return
	
	var rect: Rect2
	if _state_dragging:
		rect = _preview_rect
	else:
		rect = Rect2(editor_level.level_info.boundaries)
	
	canvas.draw_rect(rect, RECT_FILL_COLOR)
	canvas.draw_rect(rect, RECT_COLOR, false, 1.5)
	
	for h in _all_handles():
		var p := _handle_position(rect, h)
		var is_active := h == (_active_handle if _state_dragging else _hover_handle)
		var color := HANDLE_HOVER_COLOR if is_active else HANDLE_COLOR
		var r := HANDLE_DRAW_RADIUS * (1.4 if is_active else 1.0)
		canvas.draw_rect(Rect2(p - Vector2(r, r), Vector2(r, r) * 2.0), color)

# --------------------------------------------- Начало / завершение драга

func _begin_drag(handle: Handle, mouse_pos: Vector2) -> void:
	_state_dragging = true
	_active_handle = handle
	_drag_start_mouse = mouse_pos
	_drag_start_rect = Rect2(editor_level.level_info.boundaries)
	_preview_rect = _drag_start_rect
	_original_boundary = editor_level.level_info.boundaries

func _update_drag(mouse_pos: Vector2, snap: bool) -> void:
	var delta := mouse_pos - _drag_start_mouse
	var step := float(View.grid_value.x) if snap else 1.0
	
	if snap and step > 0.0:
		delta = (delta / step).round() * step
	
	_preview_rect = _apply_handle_delta(_drag_start_rect, _active_handle, delta)

func _commit_drag() -> void:
	_state_dragging = false
	
	var new_boundary := Rect2i(_preview_rect)
	var old_boundary := _original_boundary
	
	if new_boundary == old_boundary:
		_reset_to_idle()
		return
	
	editor_level.update_boundary(new_boundary)
	
	UndoRedoManager.commit(
		"EDR_BORDER_EDIT",
		func():
			if is_instance_valid(editor_level):
				editor_level.update_boundary(new_boundary)
				boundaries_changed.emit(new_boundary),
		func():
			if is_instance_valid(editor_level):
				editor_level.update_boundary(old_boundary)
				boundaries_changed.emit(old_boundary)
	)
	
	_reset_to_idle()

func _cancel_drag() -> void:
	_state_dragging = false
	_active_handle = Handle.NONE
	_preview_rect = Rect2()

func _reset_to_idle() -> void:
	_state_dragging = false
	_active_handle = Handle.NONE
	_hover_handle = Handle.NONE
	_preview_rect = Rect2()

# ---------------------------------------------

func _apply_handle_delta(base: Rect2, handle: Handle, delta: Vector2) -> Rect2:
	var r := base
	
	match handle:
		Handle.BODY:
			r.position += delta
		Handle.LEFT:
			r = _resize_left(r, delta.x)
		Handle.RIGHT:
			r = _resize_right(r, delta.x)
		Handle.TOP:
			r = _resize_top(r, delta.y)
		Handle.BOTTOM:
			r = _resize_bottom(r, delta.y)
		Handle.TOP_LEFT:
			r = _resize_left(r, delta.x)
			r = _resize_top(r, delta.y)
		Handle.TOP_RIGHT:
			r = _resize_right(r, delta.x)
			r = _resize_top(r, delta.y)
		Handle.BOTTOM_LEFT:
			r = _resize_left(r, delta.x)
			r = _resize_bottom(r, delta.y)
		Handle.BOTTOM_RIGHT:
			r = _resize_right(r, delta.x)
			r = _resize_bottom(r, delta.y)
	
	return r

func _resize_left(r: Rect2, dx: float) -> Rect2:
	var new_x := r.position.x + dx
	var right := r.position.x + r.size.x
	new_x = min(new_x, right - MIN_SIZE)
	r.size.x = right - new_x
	r.position.x = new_x
	return r

func _resize_right(r: Rect2, dx: float) -> Rect2:
	var new_w := r.size.x + dx
	r.size.x = max(new_w, MIN_SIZE)
	return r

func _resize_top(r: Rect2, dy: float) -> Rect2:
	var new_y := r.position.y + dy
	var bottom := r.position.y + r.size.y
	new_y = min(new_y, bottom - MIN_SIZE)
	r.size.y = bottom - new_y
	r.position.y = new_y
	return r

func _resize_bottom(r: Rect2, dy: float) -> Rect2:
	var new_h := r.size.y + dy
	r.size.y = max(new_h, MIN_SIZE)
	return r

# ---------------------------------------------

func _all_handles() -> Array[Handle]:
	return [
		Handle.TOP_LEFT, Handle.TOP, Handle.TOP_RIGHT,
		Handle.LEFT, Handle.RIGHT,
		Handle.BOTTOM_LEFT, Handle.BOTTOM, Handle.BOTTOM_RIGHT,
	]

func _handle_position(rect: Rect2, handle: Handle) -> Vector2:
	var l := rect.position.x
	var t := rect.position.y
	var r := rect.position.x + rect.size.x
	var b := rect.position.y + rect.size.y
	var cx := (l + r) / 2.0
	var cy := (t + b) / 2.0

	match handle:
		Handle.TOP_LEFT:     return Vector2(l, t)
		Handle.TOP:          return Vector2(cx, t)
		Handle.TOP_RIGHT:    return Vector2(r, t)
		Handle.LEFT:         return Vector2(l, cy)
		Handle.RIGHT:        return Vector2(r, cy)
		Handle.BOTTOM_LEFT:  return Vector2(l, b)
		Handle.BOTTOM:       return Vector2(cx, b)
		Handle.BOTTOM_RIGHT: return Vector2(r, b)
	
	return Vector2.ZERO

func _handle_at(world_pos: Vector2, boundary: Rect2i) -> Handle:
	var rect := Rect2(boundary)
	var zoom_scale := _camera_zoom_scale()
	var hit_radius := HANDLE_HIT_RADIUS / zoom_scale
	
	for h in _all_handles():
		if world_pos.distance_to(_handle_position(rect, h)) <= hit_radius:
			return h
	
	if rect.has_point(world_pos):
		return Handle.BODY
	
	return Handle.NONE

func _camera_zoom_scale() -> float:
	var cam = Engine.get_main_loop().get_root().get_viewport().get_camera_2d()
	return cam.zoom.x if cam else 1.0
