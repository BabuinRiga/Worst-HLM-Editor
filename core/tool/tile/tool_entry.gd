class_name ToolEntryPlace
extends EditorTool

enum State { IDLE, DRAGGING, AIMING }

var _state: State = State.IDLE
var _pixel_mode: bool = false

var _drag_start: Vector2 = Vector2.ZERO
var _drag_current: Vector2 = Vector2.ZERO
var _pending_rect: Rect2 = Rect2()

var _aim_direction: int = 0

var _erase_dragging: bool = false
var _erase_rect:     bool = false
var _erase_start:    Vector2 = Vector2.ZERO
var _erase_current:  Vector2 = Vector2.ZERO
var _erase_batch:    Array   = []

const MIN_DRAG_CELLS: float = 1.0

# ---------------------------------------------

func activate() -> void:
	_reset_to_idle()

func deactivate() -> void:
	_cancel_pending()
	
	if _erase_dragging:
		_finish_erase_batch()
	
	_erase_dragging = false

# ---------------------------------------------

func handle_input(event: InputEvent) -> bool:
	if event is InputEventMouseMotion:
		_pixel_mode = Input.is_key_pressed(KEY_CTRL)
		
		if _erase_dragging:
			_erase_current = _world_pos()
			if not _erase_rect:
				_erase_at(_erase_current)
			return true
		
		if _state == State.DRAGGING:
			_drag_current = _world_pos()
			return true
		
		if _state == State.AIMING:
			_aim_direction = _direction_to_cursor(_world_pos())
			return false
		
		return false
	
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		
		if _state == State.AIMING:
			if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
				_confirm_entry()
				return true
			
			if mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
				_cancel_pending()
				return true
			
			return false
		
		# Рисование
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_pixel_mode = mb.ctrl_pressed
				_drag_start = _world_pos()
				_drag_current = _drag_start
				_state = State.DRAGGING
				return true
			else:
				if _state == State.DRAGGING:
					_try_start_aiming()
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
	if _state == State.DRAGGING:
		var rect := _get_snapped_rect(_drag_start, _drag_current)
		canvas.draw_rect(rect, Color(0.2, 0.6, 1.0, 0.2))
		canvas.draw_rect(rect, Color(0.2, 0.6, 1.0, 0.8), false, 1.5)
	
	elif _state == State.AIMING:
		canvas.draw_rect(_pending_rect, Color(0.2, 1.0, 0.4, 0.2))
		canvas.draw_rect(_pending_rect, Color(0.2, 1.0, 0.4, 0.8), false, 1.5)
		_draw_direction_arrow(canvas)
	
	if _erase_dragging and _erase_rect:
		var rect := _get_snapped_rect(_erase_start, _erase_current)
		canvas.draw_rect(rect, Color(1.0, 0.2, 0.2, 0.2))
		canvas.draw_rect(rect, Color(1.0, 0.2, 0.2, 0.8), false, 1.5)

func _draw_direction_arrow(canvas: CanvasItem) -> void:
	var def := Defs.get_sprite_def(EntrySprite.ARROW_SPRITE_ID)
	var center := _pending_rect.position + _pending_rect.size / 2.0
	
	if def and def.frames.size() > _aim_direction:
		canvas.draw_texture(def.frames[_aim_direction], center - Vector2(6, 6))
	else:
		var dir_vec := _direction_vector(_aim_direction)
		canvas.draw_line(center, center + dir_vec * 16.0, Color.WHITE, 2.0)

# --------------------------------------------- Шаг 1: рисование квадрата

func _try_start_aiming() -> void:
	var rect := _get_snapped_rect(_drag_start, _drag_current)
	var step := 1.0 if _pixel_mode else float(View.grid_value.x)
	
	if rect.size.x < step * MIN_DRAG_CELLS or rect.size.y < step * MIN_DRAG_CELLS:
		_reset_to_idle()
		return
	
	_pending_rect = rect
	_aim_direction = _direction_to_cursor(_world_pos())
	_state = State.AIMING

func _cancel_pending() -> void:
	_reset_to_idle()

func _reset_to_idle() -> void:
	_state = State.IDLE
	_pending_rect = Rect2()
	_drag_start = Vector2.ZERO
	_drag_current = Vector2.ZERO

# ---------------------------------------------

func _direction_to_cursor(cursor_pos: Vector2) -> int:
	var center := _pending_rect.position + _pending_rect.size / 2.0
	var delta := cursor_pos - center
	
	if delta == Vector2.ZERO:
		return _aim_direction
	
	if abs(delta.x) >= abs(delta.y):
		return 0 if delta.x >= 0.0 else 2
	else:
		return 1 if delta.y < 0.0 else 3

func _direction_vector(dir: int) -> Vector2:
	match dir:
		0: return Vector2.RIGHT
		1: return Vector2.UP
		2: return Vector2.LEFT
		3: return Vector2.DOWN
	return Vector2.ZERO

func _confirm_entry() -> void:
	var floor_node := editor_level.get_active_floor()
	if floor_node == null:
		_reset_to_idle()
		return
	
	var rect := _pending_rect
	var direction := _aim_direction
	
	var spr := EntrySprite.new(rect, direction)
	
	floor_node.add_child(spr)
	
	UndoRedoManager.commit(
		"EDR_ENTRY_PLACE",
		func():
			if is_instance_valid(spr) and spr.get_parent() == null:
				floor_node.add_child(spr),
		func():
			if is_instance_valid(spr) and spr.get_parent() != null:
				spr.get_parent().remove_child(spr)
	)
	
	_reset_to_idle()

# --------------------------------------------- Удаление

func _erase_at(pos: Vector2) -> void:
	var floor_node := editor_level.get_active_floor()
	if floor_node == null:
		return
	
	for child in floor_node.get_children():
		if not (child is EntrySprite) or not child.visible:
			continue
		
		if child._hit_test(pos):
			_mark_erased(child)

func _erase_rect_region(start: Vector2, end: Vector2) -> void:
	var floor_node := editor_level.get_active_floor()
	if floor_node == null:
		return
	
	var region := _get_snapped_rect(start, end)
	
	for child in floor_node.get_children():
		if not (child is EntrySprite) or not child.visible:
			continue
		
		if region.has_point(child.global_position):
			_mark_erased(child)

func _mark_erased(node: EntrySprite) -> void:
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
		"EDR_ENTRY_ERASE",
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

# --------------------------------------------- Вспомогательное

func _get_snapped_rect(start: Vector2, end: Vector2) -> Rect2:
	var step := 1.0 if _pixel_mode else float(View.grid_value.x)
	var s := (start / step).floor() * step
	var e := (end / step).floor() * step
	
	var min_p := Vector2(min(s.x, e.x), min(s.y, e.y))
	var max_p := Vector2(max(s.x, e.x), max(s.y, e.y)) + Vector2(step, step)
	
	return Rect2(min_p, max_p - min_p)
