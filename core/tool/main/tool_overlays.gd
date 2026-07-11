class_name ToolOverlays
extends EditorTool

enum SubTool { DARKNESS, RAIN }

var current_subtool: SubTool = SubTool.DARKNESS

const DARKNESS_TEXTURE = preload("uid://chwap2hcoxllk")
const RAIN_TEXTURE = preload("uid://dhqijjqfcsoxl")

const DEFAULT_GRID: float = 8.0
const MIN_DRAG_CELLS: float = 1.0

var _dragging: bool = false
var _drag_start: Vector2 = Vector2.ZERO
var _drag_current: Vector2 = Vector2.ZERO

var _erase_dragging: bool = false
var _erase_rect: bool = false
var _erase_start: Vector2 = Vector2.ZERO
var _erase_current: Vector2 = Vector2.ZERO
var _erase_batch: Array = []

# ---------------------------------------------

func init(mode: SubTool = SubTool.DARKNESS) -> void:
	current_subtool = mode

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
		if _erase_dragging:
			_erase_current = _world_pos()
			if not _erase_rect:
				_erase_at(_erase_current)
			return true
		
		if _dragging:
			_drag_current = _world_pos()
			return true
		
		return false
	
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		
		if mb.button_index == MOUSE_BUTTON_LEFT:
			return _handle_lmb(mb)
		
		if mb.button_index == MOUSE_BUTTON_RIGHT and not mb.shift_pressed:
			if mb.pressed:
				if _dragging:
					_cancel_pending()
					return true
				
				_erase_dragging = true
				_erase_rect = mb.ctrl_pressed
				_erase_start = _world_pos()
				_erase_current = _erase_start
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

func _handle_lmb(mb: InputEventMouseButton) -> bool:
	if mb.pressed:
		if not _dragging:
			_drag_start = _world_pos()
			_drag_current = _drag_start
			_dragging = true
	else:
		if _dragging:
			_try_confirm()
	return true

# ---------------------------------------------

func draw(canvas: CanvasItem) -> void:
	if _dragging:
		var rect := _get_snapped_rect(_drag_start, _drag_current)
		var tex := DARKNESS_TEXTURE if current_subtool == SubTool.DARKNESS else RAIN_TEXTURE
		var outline := Color(1.0, 1.0, 1.0, 0.9) if current_subtool == SubTool.DARKNESS else Color(0.2, 0.6, 1.0, 0.9)
		
		canvas.draw_texture_rect(tex, rect, true, Color(1, 1, 1, 1))
		canvas.draw_rect(rect, outline, false, 1.5)
	
	if _erase_dragging and _erase_rect:
		var rect := _get_snapped_rect(_erase_start, _erase_current)
		canvas.draw_rect(rect, Color(1.0, 0.2, 0.2, 0.2))
		canvas.draw_rect(rect, Color(1.0, 0.2, 0.2, 0.8), false, 1.5)

# --------------------------------------------- Подтверждение / отмена

func _try_confirm() -> void:
	var rect := _get_snapped_rect(_drag_start, _drag_current)
	var step := _current_step()
	
	if rect.size.x < step * MIN_DRAG_CELLS or rect.size.y < step * MIN_DRAG_CELLS:
		_reset_to_idle()
		return
	
	var floor_node := editor_level.get_active_floor()
	if floor_node == null:
		_reset_to_idle()
		return
	
	var spr: BaseSprite
	var action_name: String
	
	if current_subtool == SubTool.DARKNESS:
		spr = DarknessSprite.new(Rect2i(rect))
		action_name = "EDR_DARKNESS_PLACE"
	else:
		spr = RainSprite.new(rect)
		action_name = "EDR_RAIN_PLACE"
	
	spr.level = floor_node.index
	_commit_creation(floor_node, spr, action_name)

func _cancel_pending() -> void:
	_reset_to_idle()

func _reset_to_idle() -> void:
	_dragging = false
	_drag_start = Vector2.ZERO
	_drag_current = Vector2.ZERO

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

# --------------------------------------------- Сетка

func _current_step() -> float:
	if Input.is_key_pressed(KEY_SHIFT):
		return float(View.grid_value.x)
	if Input.is_key_pressed(KEY_CTRL):
		return 1.0
	return DEFAULT_GRID

func _get_snapped_rect(start: Vector2, end: Vector2) -> Rect2:
	var step := _current_step()
	var s := (start / step).floor() * step
	var e := (end / step).floor() * step
	
	var min_p := Vector2(min(s.x, e.x), min(s.y, e.y))
	var max_p := Vector2(max(s.x, e.x), max(s.y, e.y)) + Vector2(step, step)
	
	return Rect2(min_p, max_p - min_p)

# --------------------------------------------- Удаление

func _erase_at(pos: Vector2) -> void:
	var floor_node := editor_level.get_active_floor()
	if floor_node == null: return
	
	for child in floor_node.get_children():
		if not _matches_subtool(child) or not child.visible:
			continue
		
		var rect: Rect2 = child.darkness_rect if child is DarknessSprite else child.rain_rect
		if rect.has_point(pos):
			_mark_erased(child)

func _erase_rect_region(start: Vector2, end: Vector2) -> void:
	var floor_node := editor_level.get_active_floor()
	if floor_node == null: return
	var region := _get_snapped_rect(start, end)
	
	for child in floor_node.get_children():
		if not _matches_subtool(child) or not child.visible:
			continue
		
		var rect: Rect2 = child.darkness_rect if child is DarknessSprite else child.rain_rect
		if region.intersects(rect):
			_mark_erased(child)

func _matches_subtool(node: Node) -> bool:
	if current_subtool == SubTool.DARKNESS:
		return node is DarknessSprite
	return node is RainSprite

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
	if _erase_batch.is_empty(): return
	
	for d in _erase_batch:
		var s = d["node"]
		if is_instance_valid(s): s.visible = true
	
	var batch := _erase_batch
	_erase_batch = []
	
	var action_name := "EDR_DARKNESS_ERASE" if current_subtool == SubTool.DARKNESS else "EDR_RAIN_ERASE"
	
	UndoRedoManager.commit(
		action_name,
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
