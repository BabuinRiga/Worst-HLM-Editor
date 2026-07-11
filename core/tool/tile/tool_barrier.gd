class_name ToolBarrierPlace
extends EditorTool

enum State { IDLE, DRAGGING }

var _state: State = State.IDLE
var _pixel_mode: bool = false
var _shift_mode: bool = false

var _drag_start: Vector2 = Vector2.ZERO
var _drag_current: Vector2 = Vector2.ZERO

var _erase_dragging: bool    = false
var _erase_rect:     bool    = false
var _erase_start:    Vector2 = Vector2.ZERO
var _erase_current:  Vector2 = Vector2.ZERO
var _erase_batch:    Array   = []

const MIN_LENGTH: float = 2.0

# ---------------------------------------------

func init(_arg = null) -> void:
	_reset_to_idle()

func activate() -> void:
	_reset_to_idle()

func deactivate() -> void:
	_reset_to_idle()
	
	if _erase_dragging:
		_finish_erase_batch()
	
	_erase_dragging = false

# ---------------------------------------------

func handle_input(event: InputEvent) -> bool:
	if event is InputEventMouseMotion:
		_pixel_mode = Input.is_key_pressed(KEY_CTRL)
		_shift_mode = Input.is_key_pressed(KEY_SHIFT)
		
		if _erase_dragging:
			_erase_current = _world_pos()
			if not _erase_rect:
				_erase_at(_erase_current)
			return true
		
		if _state == State.DRAGGING:
			_drag_current = _world_pos()
			return true
		
		if _state == State.IDLE:
			_drag_current = _world_pos()
		
		return false
	
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		
		_pixel_mode = mb.ctrl_pressed
		_shift_mode = mb.shift_pressed
		
		# Рисование
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_drag_start = _get_snapped_pos(_world_pos())
				_drag_current = _world_pos()
				_state = State.DRAGGING
				return true
			else:
				if _state == State.DRAGGING:
					_confirm_barrier()
				return true
		
		# Удаление
		if mb.button_index == MOUSE_BUTTON_RIGHT and _state == State.IDLE:
			if mb.pressed:
				_erase_dragging = true
				_erase_rect     = mb.ctrl_pressed
				_erase_start    = _world_pos()
				_erase_current  = _erase_start
				_erase_batch.clear()
				
				if not _erase_rect:
					_erase_at(_erase_start)
				return true
			else:
				if _erase_dragging:
					if _erase_rect:
						_erase_rect_region(_erase_start, _erase_current)
					_finish_erase_batch()
					return true
	
	return false

func draw(canvas: CanvasItem) -> void:
	if _state == State.IDLE and not _erase_dragging:
		var hover_pos = _get_snapped_pos(_drag_current)
		canvas.draw_rect(Rect2(hover_pos - Vector2(2, 2), Vector2(4, 4)), BarrierSprite.COLOR)
		
	elif _state == State.DRAGGING:
		var start = _drag_start
		var current = _get_snapped_pos(_drag_current)
		var end = _get_constrained_end(start, current, _shift_mode)
		
		canvas.draw_line(start, end, BarrierSprite.COLOR, 4.0)
		
	if _erase_dragging and _erase_rect:
		var rect := _get_snapped_rect(_erase_start, _erase_current)
		canvas.draw_rect(rect, Color(1.0, 0.2, 0.2, 0.2))
		canvas.draw_rect(rect, Color(1.0, 0.2, 0.2, 0.8), false, 1.5)

# --------------------------------------------- Размещение

func _confirm_barrier() -> void:
	var floor_node := editor_level.get_active_floor()
	if floor_node == null:
		_reset_to_idle()
		return
	
	var start = _drag_start
	var current = _get_snapped_pos(_drag_current)
	var end = _get_constrained_end(start, current, _shift_mode)
	
	var delta = end - start
	
	if delta.length() < MIN_LENGTH:
		_reset_to_idle()
		return
	
	var len_units = delta.length() / 16.0
	var rot_angle = delta.angle()
	
	var spr := BarrierSprite.new(len_units)
	
	floor_node.add_child(spr)
	spr.global_position = start
	spr.rotation = rot_angle
	
	UndoRedoManager.commit(
		"EDR_BARRIER_PLACE",
		func():
			if is_instance_valid(spr) and spr.get_parent() == null:
				floor_node.add_child(spr),
		func():
			if is_instance_valid(spr) and spr.get_parent() != null:
				spr.get_parent().remove_child(spr)
	)
	
	_reset_to_idle()

func _reset_to_idle() -> void:
	_state = State.IDLE
	_drag_start = Vector2.ZERO
	_drag_current = _world_pos()

# --------------------------------------------- Вспомогательное

func _get_snapped_pos(pos: Vector2) -> Vector2:
	var step := 1.0 if _pixel_mode else float(View.grid_value.x)
	return (pos / step).floor() * step

func _get_constrained_end(start: Vector2, current: Vector2, use_shift: bool) -> Vector2:
	if not use_shift:
		return current
	
	var d = current - start
	var abs_x = abs(d.x)
	var abs_y = abs(d.y)
	
	if abs_x > abs_y * 2.0:
		return start + Vector2(d.x, 0)
	elif abs_y > abs_x * 2.0:
		return start + Vector2(0, d.y)
	else:
		var m = max(abs_x, abs_y)
		return start + Vector2(m * sign(d.x), m * sign(d.y))

func _get_snapped_rect(start: Vector2, end: Vector2) -> Rect2:
	var step := 1.0 if _pixel_mode else float(View.grid_value.x)
	var s := (start / step).floor() * step
	var e := (end / step).floor() * step

	var min_p := Vector2(min(s.x, e.x), min(s.y, e.y))
	var max_p := Vector2(max(s.x, e.x), max(s.y, e.y)) + Vector2(step, step)
	
	return Rect2(min_p, max_p - min_p)

# --------------------------------------------- Удаление

func _erase_at(pos: Vector2) -> void:
	var floor_node := editor_level.get_active_floor()
	if floor_node == null:
		return
	
	for child in floor_node.get_children():
		if not (child is BarrierSprite) or not child.visible:
			continue
		
		var local_pos = child.to_local(pos)
		var hit_rect = child.custom_rect.grow(6.0)
		
		if hit_rect.has_point(local_pos):
			_mark_erased(child)

func _erase_rect_region(start: Vector2, end: Vector2) -> void:
	var floor_node := editor_level.get_active_floor()
	if floor_node == null:
		return
	
	var region := _get_snapped_rect(start, end)
	
	for child in floor_node.get_children():
		if not (child is BarrierSprite) or not child.visible:
			continue
		
		var c_start = child.global_position
		var c_end = child.to_global(Vector2(child.lenght * 16.0, 0))
		
		if region.has_point(c_start) or region.has_point(c_end):
			_mark_erased(child)

func _mark_erased(node: BarrierSprite) -> void:
	for d in _erase_batch:
		if d["node"] == node:
			return
	
	_erase_batch.append({
		"node":   node,
		"parent": node.get_parent(),
		"index":  node.get_index(),
	})
	node.visible = false

func _finish_erase_batch() -> void:
	_erase_dragging = false
	
	if _erase_batch.is_empty():
		return
	
	for d in _erase_batch:
		var s = d["node"]
		if is_instance_valid(s):
			s.visible = true
	
	var batch := _erase_batch
	_erase_batch = []
	
	UndoRedoManager.commit(
		"EDR_BARRIER_ERASE",
		func():
			for d in batch:
				var s = d["node"]
				if is_instance_valid(s) and s.get_parent() != null:
					s.get_parent().remove_child(s),
		func():
			var rev_batch := batch.duplicate()
			rev_batch.reverse()
			
			for d in rev_batch:
				var s = d["node"]
				var p = d["parent"]
				if is_instance_valid(s) and is_instance_valid(p):
					if s.get_parent() == null:
						p.add_child(s)
					
					var safe_idx: int = clampi(d["index"], 0, p.get_child_count() - 1)
					p.move_child(s, safe_idx)
					s.visible = true
	)
