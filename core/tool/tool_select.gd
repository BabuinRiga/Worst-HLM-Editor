class_name ToolSelect
extends EditorTool

var _drag_start:    Vector2
var _dragging:      bool = false
var _drag_additive: bool = false

var _move_dragging: bool = false
var _move_origin: Vector2
var _move_snapshot: Array
var _move_targets: Array[BaseSprite]
var _move_anchor_initial_pos: Vector2

func activate() -> void:
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)

func deactivate() -> void:
	Selection.clear()

func handle_input(event: InputEvent) -> bool:
	if event is InputEventKey:
		var key := event as InputEventKey
		# Удаление
		if key.pressed and key.keycode == KEY_DELETE:
			_delete_selection()
			return true

	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		# Перемещение и выделение
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				if mb.ctrl_pressed:
					_start_move_drag()
					return true
				_drag_start    = _world_pos()
				_dragging      = true
				_drag_additive = mb.shift_pressed
				if not mb.shift_pressed:
					Selection.clear()
				return true
			else:
				if _move_dragging:
					_finish_move_drag()
					return true
				if _dragging:
					_finish_rubber_band()
					_dragging = false
				return true
		# Поворот на 90 градусов
		if mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
			if _all_selected_are_object_sprites():
				_rotate_snap90(mb.shift_pressed)
				return true
		# Поворот
		if mb.ctrl_pressed and _all_selected_are_object_sprites():
			var step := 5.0 if mb.shift_pressed else 1.0
			if mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
				_rotate_by_wheel(1, step)
				return true
			if mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
				_rotate_by_wheel(-1, step)
				return true
	
	elif event is InputEventMouseMotion:
		if _move_dragging:
			_update_move_drag()
			return true
		if _dragging:
			return true
	
	return false

func draw(canvas: CanvasItem) -> void:
	if not _dragging:
		return
	var rect := _get_rubber_rect()
	canvas.draw_rect(rect, Color(0.2, 0.5, 1.0, 0.2))
	canvas.draw_rect(rect, Color(0.2, 0.5, 1.0, 0.8), false)


# --------------------------------------------- Перетаскивание


func _all_selected_are_object_sprites() -> bool:
	var sel := Selection.selected
	if sel.is_empty():
		return false
	for s in sel:
		if not (s is ObjectSprite):
			return false
	return true

func _start_move_drag() -> void:
	if Selection.selected.is_empty(): return
	_move_dragging   = true
	_move_origin     = _world_pos()
	_move_targets    = []
	_move_snapshot   = []
	
	var anchor := Selection.selected.back() as BaseSprite
	if is_instance_valid(anchor):
		_move_anchor_initial_pos = anchor.global_position
	else:
		_move_anchor_initial_pos = _move_origin
	for s in Selection.selected:
		_move_targets.append(s as BaseSprite)
		_move_snapshot.append({ "ref": s, "pos": s.global_position })
		
	Input.set_default_cursor_shape(Input.CURSOR_MOVE)

func _update_move_drag() -> void:
	var raw_delta := _world_pos() - _move_origin
	var snap := Input.is_key_pressed(KEY_SHIFT)
	
	var actual_delta := raw_delta
	
	if snap:
		var grid := Vector2(View.grid_value)
		var anchor_target_pos = _move_anchor_initial_pos + raw_delta
		var anchor_snapped_pos = (anchor_target_pos / grid).round() * grid
		actual_delta = anchor_snapped_pos - _move_anchor_initial_pos
	else:
		actual_delta = actual_delta.round()
	
	for d in _move_snapshot:
		var s := d["ref"] as BaseSprite
		if is_instance_valid(s):
			s.global_position = d["pos"] + actual_delta

func _finish_move_drag() -> void:
	_move_dragging = false
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	
	var final_state := []
	for s in _move_targets:
		final_state.append({ "ref": s, "pos": s.global_position })
	
	var snapshot  := _move_snapshot.duplicate(true)
	var targets   := _move_targets.duplicate()
	
	UndoRedoManager.commit(
		"EDR_SPR_MOVE",
		func():
			for d in final_state:
				if is_instance_valid(d["ref"]):
					d["ref"].global_position = d["pos"]
					if d["ref"].has_method("set_coords"):
						d["ref"].set_coords(d["pos"]),
		func():
			for d in snapshot:
				if is_instance_valid(d["ref"]):
					d["ref"].global_position = d["pos"]
					if d["ref"].has_method("set_coords"):
						d["ref"].set_coords(d["pos"])
	)
	
	_move_targets  = []
	_move_snapshot = []


# --------------------------------------------- Поворот


func _get_selection_center() -> Vector2:
	var sum := Vector2.ZERO
	for s in Selection.selected:
		sum += s.global_position
	return sum / Selection.selected.size()


func _rotate_by_wheel(direction: int, step: float) -> void:
	var delta_deg := step * direction
	var center    := _get_selection_center()
	var targets   := Selection.selected.duplicate()
	var snapshot  := targets.map(func(s): return {
		"ref": s,
		"pos": s.global_position,
		"rot": s.rotation_degrees
	})
	var delta_rad := deg_to_rad(delta_deg)
	
	UndoRedoManager.commit(
		"EDR_SPR_ROTATE",
		func():
			for d in snapshot:
				var s = d["ref"]
				if not is_instance_valid(s): continue
				s.global_position  = (center + (d["pos"] - center).rotated(delta_rad)).round()
				s.rotation_degrees = roundf(d["rot"] + delta_deg)
				if s.has_method("set_coords"): s.set_coords(s.global_position)
				if s.has_method("set_angle"):  s.set_angle(s.rotation_degrees),
		func():
			for d in snapshot:
				if not is_instance_valid(d["ref"]): continue
				d["ref"].global_position  = d["pos"]
				d["ref"].rotation_degrees = d["rot"]
				if d["ref"].has_method("set_coords"): d["ref"].set_coords(d["pos"])
				if d["ref"].has_method("set_angle"):  d["ref"].set_angle(d["rot"])
	)


func _rotate_snap90(counter_clockwise: bool) -> void:
	var center   := _get_selection_center()
	var targets  := Selection.selected.duplicate()
	var snapshot := targets.map(func(s): return {
		"ref": s,
		"pos": s.global_position,
		"rot": s.rotation_degrees
	})
	
	UndoRedoManager.commit(
		"EDR_SPR_ROTATE",
		func():
			for d in snapshot:
				var s = d["ref"]
				if not is_instance_valid(s): continue
				var current: float = d["rot"]
				var snapped := roundf(current / 90.0) * 90.0
				var direction := -1.0 if counter_clockwise else 1.0
				var new_rot := snapped + 90.0 * direction
				var delta_rad := deg_to_rad(new_rot - current)
				s.global_position  = center + (d["pos"] - center).rotated(delta_rad)
				s.rotation_degrees = roundf(fposmod(new_rot, 360.0))
				if s.has_method("set_coords"): s.set_coords(s.global_position)
				if s.has_method("set_angle"):  s.set_angle(s.rotation_degrees),
		func():
			for d in snapshot:
				if not is_instance_valid(d["ref"]): continue
				d["ref"].global_position  = d["pos"]
				d["ref"].rotation_degrees = d["rot"]
				if d["ref"].has_method("set_coords"): d["ref"].set_coords(d["pos"])
				if d["ref"].has_method("set_angle"):  d["ref"].set_angle(d["rot"])
	)


# --------------------------------------------- Выделение


func _finish_rubber_band() -> void:
	var rect := _get_rubber_rect()
	
	if rect.size.length() < 2.0:
		var hit := _sprite_at(_world_pos())
		if hit:
			if _drag_additive:
				Selection.add_to_selection(hit)
			else:
				Selection.select_many([hit])
		return
	
	var found: Array[BaseSprite] = []
	var valid_sprites: Array[BaseSprite] = []
	
	for node in (Engine.get_main_loop() as SceneTree).get_nodes_in_group("sprites"):
		if node is BaseSprite and node.visible:
			if level_tab.current_mode == node.mode:
				valid_sprites.append(node)
	
	valid_sprites.sort_custom(func(a: BaseSprite, b: BaseSprite):
		if a.z_index == b.z_index:
			return a.get_index() > b.get_index()
		return a.z_index > b.z_index
	)
	
	for node in valid_sprites:
		var global_rect = node.get_global_transform() * node.get_rect()
		if rect.intersects(global_rect):
			found.append(node)
	
	if found.is_empty():
		return
	
	if _drag_additive:
		for s in found:
			Selection.add_to_selection(s)
	else:
		Selection.select_many(found)

func _get_rubber_rect() -> Rect2:
	var cur := _world_pos()
	return Rect2(
		Vector2(min(_drag_start.x, cur.x), min(_drag_start.y, cur.y)),
		Vector2(abs(cur.x - _drag_start.x), abs(cur.y - _drag_start.y))
	)

# --------------------------------------------- Удаление

func _delete_selection() -> void:
	var snapshot := []
	for s in Selection.selected:
		snapshot.append({
			"ref":    s,
			"parent": s.get_parent(),
			"index":  s.get_index(),
		})
	Selection.clear()
	
	UndoRedoManager.commit(
		"EDR_SPR_DELETE",
		func():
			for d in snapshot:
				var s: Node = d["ref"]
				if is_instance_valid(s) and s.get_parent() != null:
					s.get_parent().remove_child(s),
		func():
			for d in snapshot:
				var s: Node = d["ref"]
				var parent: Node = d["parent"]
				if is_instance_valid(s) and is_instance_valid(parent):
					parent.add_child(s)
					parent.move_child(s, d["index"])
	)

# --------------------------------------------- Вспомогательное

func _sprite_at(pos: Vector2) -> BaseSprite:
	var current_mode = level_tab.current_mode
	var valid_sprites: Array[BaseSprite] = []
	
	for node in (Engine.get_main_loop() as SceneTree).get_nodes_in_group("sprites"):
		if node is BaseSprite and node.visible:
			if node.mode == current_mode:
				valid_sprites.append(node)
				
	valid_sprites.sort_custom(func(a: BaseSprite, b: BaseSprite):
		if a.z_index == b.z_index:
			return a.get_index() > b.get_index()
		return a.z_index > b.z_index
	)
	
	for spr in valid_sprites:
		if spr._hit_test(pos):
			return spr
	
	return null
