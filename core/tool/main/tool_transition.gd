class_name ToolTransition
extends EditorTool

enum SubTool { TRANSITION, ELEVATOR }
enum State { IDLE, DRAGGING_RECT, AIMING_DIR, SETTING_OFFSET }

var current_subtool: SubTool = SubTool.TRANSITION
var target_floor_cache: int = 0

var _state: State = State.IDLE
var _pixel_mode: bool = false

var _drag_start: Vector2 = Vector2.ZERO
var _drag_current: Vector2 = Vector2.ZERO
var _pending_rect: Rect2 = Rect2()
var _aim_direction: int = 0

var _elevator_pos: Vector2 = Vector2.ZERO
var _elevator_rot: float = 0.0

var _erase_dragging: bool = false
var _erase_rect: bool = false
var _erase_start: Vector2 = Vector2.ZERO
var _erase_current: Vector2 = Vector2.ZERO
var _erase_batch: Array = []

const MIN_DRAG_CELLS: float = 1.0

# ---------------------------------------------

var _elevator_preview: ElevatorSprite = null

func _create_elevator_preview() -> void:
	_destroy_elevator_preview()
	var floor_node := editor_level.get_active_floor()
	if floor_node == null:
		return
	_elevator_preview = ElevatorSprite.new(target_floor_cache, Vector2i.ZERO)
	_elevator_preview.set_meta("preview", true)
	_elevator_preview.modulate.a = 0.5
	_elevator_preview.z_index = 1000
	floor_node.add_child(_elevator_preview)

func _destroy_elevator_preview() -> void:
	if is_instance_valid(_elevator_preview):
		_elevator_preview.queue_free()
	_elevator_preview = null

func _set_elevator_preview_visible(v: bool) -> void:
	if is_instance_valid(_elevator_preview):
		_elevator_preview.visible = v

func _update_elevator_preview_pos() -> void:
	if not is_instance_valid(_elevator_preview):
		return
	_elevator_preview.global_position = _get_offset_placement_pos(_world_pos())
	_elevator_preview.rotation = deg_to_rad(-_elevator_rot)

# ---------------------------------------------

func init(mode: SubTool = SubTool.TRANSITION) -> void:
	current_subtool = mode

func activate() -> void:
	_reset_to_idle()
	if current_subtool == SubTool.ELEVATOR:
		_create_elevator_preview()
		_update_elevator_preview_pos()

func deactivate() -> void:
	_cancel_pending()
	if _erase_dragging:
		_finish_erase_batch()
	_erase_dragging = false
	_destroy_elevator_preview()

# ---------------------------------------------

func handle_input(event: InputEvent) -> bool:
	if event is InputEventMouseMotion:
		_pixel_mode = Input.is_key_pressed(KEY_CTRL)
		
		if _erase_dragging:
			_erase_current = _world_pos()
			if not _erase_rect:
				_erase_at(_erase_current)
			return true
		
		if current_subtool == SubTool.ELEVATOR and _state != State.SETTING_OFFSET:
			_update_elevator_preview_pos()
		
		match _state:
			State.DRAGGING_RECT:
				_drag_current = _world_pos()
				return true
			State.AIMING_DIR:
				_aim_direction = _direction_to_cursor(_world_pos())
				return false
			State.SETTING_OFFSET:
				if not Input.is_key_pressed(KEY_CTRL):
					_drag_current = _get_offset_placement_pos(_world_pos())
				return false
		
		return false
	
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		
		if mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
			# Поворот
			if _state == State.IDLE and current_subtool == SubTool.ELEVATOR and mb.shift_pressed:
				_elevator_rot = wrapf(_elevator_rot + 90.0, 0.0, 360.0)
				_update_elevator_preview_pos()
				return true
				
			if _state != State.IDLE:
				_cancel_pending()
				return true
		
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if current_subtool == SubTool.TRANSITION:
				return _handle_transition_lmb(mb)
			else:
				return _handle_elevator_lmb(mb)
		
		# Удаление
		if mb.button_index == MOUSE_BUTTON_RIGHT and _state == State.IDLE and not mb.shift_pressed:
			if mb.pressed:
				_erase_dragging = true
				_erase_rect = mb.ctrl_pressed
				_erase_start = _world_pos()
				_erase_current = _erase_start
				_erase_batch.clear()
				_set_elevator_preview_visible(false)
				
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

func _handle_transition_lmb(mb: InputEventMouseButton) -> bool:
	if mb.pressed:
		match _state:
			State.IDLE:
				_pixel_mode = mb.ctrl_pressed
				_drag_start = _world_pos()
				_drag_current = _drag_start
				_state = State.DRAGGING_RECT
			State.AIMING_DIR:
				_drag_current = _get_offset_placement_pos(_world_pos())
				_state = State.SETTING_OFFSET
			State.SETTING_OFFSET:
				_confirm_transition()
	else:
		if _state == State.DRAGGING_RECT:
			_try_start_aiming()
	return true

func _handle_elevator_lmb(mb: InputEventMouseButton) -> bool:
	if mb.pressed:
		match _state:
			State.IDLE:
				_elevator_pos = _get_offset_placement_pos(_world_pos())
				_drag_current = _get_offset_placement_pos(_world_pos())
				_state = State.SETTING_OFFSET
				_set_elevator_preview_visible(true)
				_update_elevator_preview_pos()
			State.SETTING_OFFSET:
				_confirm_elevator()
	return true

# ---------------------------------------------

func draw(canvas: CanvasItem) -> void:
	if _state == State.DRAGGING_RECT:
		var rect := _get_snapped_rect(_drag_start, _drag_current)
		canvas.draw_rect(rect, Color(0.2, 0.6, 1.0, 0.2))
		canvas.draw_rect(rect, Color(0.2, 0.6, 1.0, 0.8), false, 1.5)
	
	elif _state == State.AIMING_DIR:
		canvas.draw_rect(_pending_rect, Color(0.2, 1.0, 0.4, 0.2))
		canvas.draw_rect(_pending_rect, Color(0.2, 1.0, 0.4, 0.8), false, 1.5)
		_draw_direction_arrow(canvas)
	
	elif _state == State.SETTING_OFFSET:
		var node_rot = deg_to_rad(-_elevator_rot)
		
		if current_subtool == SubTool.TRANSITION:
			canvas.draw_rect(_pending_rect, Color(0.8, 0.8, 0.2, 0.3))
			canvas.draw_rect(_pending_rect, Color(0.8, 0.8, 0.2, 0.8), false, 1.0)
		
		if Input.is_key_pressed(KEY_CTRL):
			_draw_offset_arrow_hint(canvas, node_rot)
		else:
			_draw_offset_player_hint(canvas, node_rot)
	
	if _erase_dragging and _erase_rect:
		var rect := _get_snapped_rect(_erase_start, _erase_current)
		canvas.draw_rect(rect, Color(1.0, 0.2, 0.2, 0.2))
		canvas.draw_rect(rect, Color(1.0, 0.2, 0.2, 0.8), false, 1.5)

func _draw_offset_player_hint(canvas: CanvasItem, node_rot: float) -> void:
	var player_def = Defs.get_sprite_def(TransitionSprite.PLAYER_SPRITE_ID)
	if not player_def or player_def.frames.is_empty():
		return
	var p_tex = player_def.frames[0]
	var p_size = p_tex.get_size()
	var p_offset = p_size / 2.0
	
	if current_subtool == SubTool.TRANSITION:
		var center = _pending_rect.position + _pending_rect.size / 2.0
		var offset_vec = _drag_current - center
		var exact_angle = (-offset_vec).angle() if offset_vec != Vector2.ZERO else 0.0
		var look_angle = snapped(exact_angle, PI / 2.0)
		
		canvas.draw_set_transform(_drag_current, look_angle, Vector2.ONE)
		canvas.draw_texture(p_tex, -p_offset, Color(0.0, 0.8, 1.0, 0.7))
		canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		
	elif current_subtool == SubTool.ELEVATOR:
		var world_delta = _drag_current - _elevator_pos
		var local_offset = world_delta.rotated(-node_rot)
		var exact_angle = (-local_offset).angle() if local_offset != Vector2.ZERO else 0.0
		var look_angle = snapped(exact_angle, PI / 2.0)
		
		canvas.draw_set_transform(_drag_current, node_rot + look_angle, Vector2.ONE)
		canvas.draw_texture(p_tex, -p_offset, Color(0.0, 0.8, 1.0, 0.7))
		canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_offset_arrow_hint(canvas: CanvasItem, node_rot: float) -> void:
	var def := Defs.get_sprite_def(TransitionSprite.ARROW_SPRITE_ID)
	
	if current_subtool == SubTool.TRANSITION:
		var center = _pending_rect.position + _pending_rect.size / 2.0
		var dir := _aim_direction
		
		if def and def.frames.size() > dir:
			canvas.draw_texture(def.frames[dir], center - Vector2(6, 6))
		else:
			var dir_vec := _direction_vector(dir)
			canvas.draw_line(center, center + dir_vec * 16.0, Color.WHITE, 2.0)
		
	elif current_subtool == SubTool.ELEVATOR:
		var local_shift := (_elevator_preview.texture.get_size() / 2.0) - (ElevatorSprite.HM_OFFSET * -1.0)
		var arrow_pos := _elevator_pos + local_shift.rotated(node_rot)
		var look_angle := node_rot - (PI / 2.0)
		
		if def and not def.frames.is_empty():
			canvas.draw_set_transform(arrow_pos, look_angle, Vector2.ONE)
			canvas.draw_texture(def.frames[0], -Vector2(6, 6))
			canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		else:
			var dir_vec := Vector2.RIGHT.rotated(look_angle)
			canvas.draw_line(arrow_pos, arrow_pos + dir_vec * (ElevatorSprite.HM_OFFSET.x * -1.0), Color.WHITE, 2.0)

func _draw_direction_arrow(canvas: CanvasItem) -> void:
	var def := Defs.get_sprite_def(TransitionSprite.ARROW_SPRITE_ID)
	var center := _pending_rect.position + _pending_rect.size / 2.0
	
	if def and def.frames.size() > _aim_direction:
		canvas.draw_texture(def.frames[_aim_direction], center - Vector2(6, 6))
	else:
		var dir_vec := _direction_vector(_aim_direction)
		canvas.draw_line(center, center + dir_vec * (ElevatorSprite.HM_OFFSET.x * -1.0), Color.WHITE, 2.0)

# --------------------------------------------- Вспомогательные 1

func _try_start_aiming() -> void:
	var rect := _get_snapped_rect(_drag_start, _drag_current)
	var step := 1.0 if _pixel_mode else float(View.grid_value.x)
	
	if rect.size.x < step * MIN_DRAG_CELLS or rect.size.y < step * MIN_DRAG_CELLS:
		_reset_to_idle()
		return
	
	_pending_rect = rect
	_aim_direction = _direction_to_cursor(_world_pos())
	_state = State.AIMING_DIR

func _confirm_transition() -> void:
	var floor_node := editor_level.get_active_floor()
	if floor_node == null: return
	
	var rect := _pending_rect
	var direction := _aim_direction
	
	var final_offset: Vector2i
	if Input.is_key_pressed(KEY_CTRL):
		final_offset = Vector2i.ZERO
	else:
		var center = rect.position + rect.size / 2.0
		final_offset = Vector2i(_drag_current - center)
	
	var spr = TransitionSprite.new(rect, direction, target_floor_cache, final_offset)
	
	_commit_creation(floor_node, spr, "EDR_TRANSITION_PLACE")
	ToolManager.set_tool(ToolManager.Tool.SELECT)
	Selection.add_to_selection(spr)

func _confirm_elevator() -> void:
	var floor_node := editor_level.get_active_floor()
	if floor_node == null: return
	
	var node_rot = deg_to_rad(-_elevator_rot)
	
	var final_offset_vec: Vector2
	if Input.is_key_pressed(KEY_CTRL):
		final_offset_vec = Vector2.ZERO
	else:
		var world_delta = _drag_current - _elevator_pos
		final_offset_vec = world_delta.rotated(-node_rot)
	
	var spr = ElevatorSprite.new(target_floor_cache, Vector2i(final_offset_vec))
	
	spr.position = floor_node.to_local(_elevator_pos)
	spr.rotation = node_rot
	
	_commit_creation(floor_node, spr, "EDR_ELEVATOR_PLACE")
	_create_elevator_preview()
	_update_elevator_preview_pos()
	ToolManager.set_tool(ToolManager.Tool.SELECT)
	Selection.add_to_selection(spr)

func _commit_creation(floor_node: Node2D, spr: Node, action_name: String) -> void:
	floor_node.add_child(spr)
	
	UndoRedoManager.commit(
		action_name,
		func():
			if is_instance_valid(spr) and spr.get_parent() == null:
				floor_node.add_child(spr),
		func():
			if is_instance_valid(spr) and spr.get_parent() != null:
				spr.get_parent().remove_child(spr)
	)
	_reset_to_idle()

func _cancel_pending() -> void:
	_reset_to_idle()

func _reset_to_idle() -> void:
	_state = State.IDLE
	_pending_rect = Rect2()
	_drag_start = Vector2.ZERO
	_drag_current = Vector2.ZERO
	_set_elevator_preview_visible(true)
	_update_elevator_preview_pos()

# --------------------------------------------- Вспомогательные 2

func _direction_to_cursor(cursor_pos: Vector2) -> int:
	var center := _pending_rect.position + _pending_rect.size / 2.0
	var delta := cursor_pos - center
	if delta == Vector2.ZERO: return _aim_direction
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

func _get_snapped_rect(start: Vector2, end: Vector2) -> Rect2:
	var step := 1.0 if _pixel_mode else float(View.grid_value.x)
	var s := (start / step).floor() * step
	var e := (end / step).floor() * step
	
	var min_p := Vector2(min(s.x, e.x), min(s.y, e.y))
	var max_p := Vector2(max(s.x, e.x), max(s.y, e.y)) + Vector2(step, step)
	
	return Rect2(min_p, max_p - min_p)

func _get_offset_placement_pos(pos: Vector2) -> Vector2:
	if Input.is_key_pressed(KEY_SHIFT):
		var step := float(View.grid_value.x)
		return (pos / step).floor() * step
	return pos.round()

# --------------------------------------------- Удаление

func _erase_at(pos: Vector2) -> void:
	var floor_node := editor_level.get_active_floor()
	if floor_node == null: return
	
	for child in floor_node.get_children():
		if not (child is TransitionSprite or child is ElevatorSprite) or not child.visible:
			continue
		if child == _elevator_preview:
			continue
		
		if child.has_method("_hit_test") and child._hit_test(pos):
			_mark_erased(child)
		elif "trigger_rect" in child and child.trigger_rect.has_point(pos):
			_mark_erased(child)
		elif child is ElevatorSprite and child.global_position.distance_to(pos) < (ElevatorSprite.HM_OFFSET.x * -1.0):
			_mark_erased(child)

func _erase_rect_region(start: Vector2, end: Vector2) -> void:
	var floor_node := editor_level.get_active_floor()
	if floor_node == null: return
	var region := _get_snapped_rect(start, end)
	
	for child in floor_node.get_children():
		if not (child is TransitionSprite or child is ElevatorSprite) or not child.visible:
			continue
		if child == _elevator_preview:
			continue
		
		if child is TransitionSprite and region.intersects(child.trigger_rect):
			_mark_erased(child)
		elif child is ElevatorSprite and region.has_point(child.global_position):
			_mark_erased(child)

func _mark_erased(node: Node) -> void:
	for d in _erase_batch:
		if d["node"] == node: return
	
	_erase_batch.append({
		"node":   node,
		"parent": node.get_parent(),
		"index":  node.get_index(),
	})
	node.visible = false

func _finish_erase_batch() -> void:
	_erase_dragging = false
	_set_elevator_preview_visible(true)
	if _erase_batch.is_empty(): return
	
	for d in _erase_batch:
		var s = d["node"]
		if is_instance_valid(s): s.visible = true
	
	var batch := _erase_batch
	_erase_batch = []
	var floor_node := editor_level.get_active_floor()
	
	UndoRedoManager.commit(
		"EDR_TRANSITION_ERASE",
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
