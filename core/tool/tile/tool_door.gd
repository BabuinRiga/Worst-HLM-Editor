class_name ToolDoorPlace
extends EditorTool

var _current_direction: int = 0
var _is_vertical: bool = false

var _preview_root: Node2D = null

var _pixel_mode:     bool    = false
var _place_batch:    Array   = []

var _erase_dragging: bool    = false
var _erase_rect:     bool    = false
var _erase_start:    Vector2 = Vector2.ZERO
var _erase_current:  Vector2 = Vector2.ZERO
var _erase_batch:    Array   = []

const DOOR_SIZE: float = 32.0

# ---------------------------------------------

func init(dir_index: int = 0) -> void:
	set_direction(dir_index)

func activate() -> void:
	_create_preview()

func deactivate() -> void:
	_destroy_preview()
	
	if _erase_dragging:
		_finish_erase_batch()
	
	_erase_dragging = false

func set_direction(idx: int) -> void:
	_current_direction = clampi(idx, 0, 3)
	_is_vertical = _current_direction in [0, 2]
	
	if is_instance_valid(_preview_root):
		_create_preview()

func _get_locked() -> int:
	var tiles = level_tab.tiles as TilesTab
	return 1 if (tiles and tiles.check_locked.button_pressed) else 0

func _get_cutscene() -> int:
	var tiles = level_tab.tiles as TilesTab
	return 1 if (tiles and tiles.check_cutscene.button_pressed) else 0

# --------------------------------------------- Превью

func _create_preview() -> void:
	_destroy_preview()
	
	var floor_node := editor_level.get_active_floor()
	if floor_node == null:
		return
	
	_preview_root = Node2D.new()
	_preview_root.set_meta("preview", true)
	_preview_root.modulate.a = 0.5
	_preview_root.z_index    = 1000
	
	floor_node.add_child(_preview_root)
	
	_rebuild_preview()
	_update_preview_pos()

func _rebuild_preview() -> void:
	if not is_instance_valid(_preview_root):
		return
	
	for child in _preview_root.get_children():
		child.queue_free()
		
	var obj_id = DoorSprite.object_ids[_current_direction]
	var locked = _get_locked()
	var cutscene = _get_cutscene()
	
	var spr := DoorSprite.new(obj_id, locked, cutscene)
	_preview_root.add_child(spr)

func _destroy_preview() -> void:
	if is_instance_valid(_preview_root):
		_preview_root.queue_free()
	_preview_root = null

func _set_preview_visible(v: bool) -> void:
	if is_instance_valid(_preview_root):
		_preview_root.visible = v

func _update_preview_pos() -> void:
	if not is_instance_valid(_preview_root):
		return
	
	_pixel_mode = Input.is_key_pressed(KEY_CTRL)
	var step := 1.0 if _pixel_mode else DOOR_SIZE
	var pos  := _world_pos()
	var snapped := (pos / step).floor() * step
		
	_preview_root.global_position = snapped

# --------------------------------------------- Input & Draw

func handle_input(event: InputEvent) -> bool:
	if event is InputEventMouseMotion:
		if _erase_dragging:
			_erase_current = _world_pos()
			if not _erase_rect:
				_erase_at(_erase_current)
			return true
		
		_update_preview_pos()
		return false
	
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		
		# Размещение
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_pixel_mode = mb.ctrl_pressed
				_place_batch.clear()
				_place_at(_world_pos())
				_finish_place_batch()
				_update_preview_pos()
				return true
		
		# Поворот
		if mb.button_index == MOUSE_BUTTON_RIGHT and mb.shift_pressed and not mb.ctrl_pressed:
			if mb.pressed:
				_rotate_door()
			return true
		
		# Удаление
		if mb.button_index == MOUSE_BUTTON_RIGHT and not mb.shift_pressed:
			if mb.pressed:
				_erase_dragging = true
				_erase_rect     = mb.ctrl_pressed
				_erase_start    = _world_pos()
				_erase_current  = _erase_start
				_erase_batch.clear()
				
				_set_preview_visible(false)
				
				if not _erase_rect:
					_erase_at(_erase_start)
				return true
			else:
				if _erase_dragging:
					if _erase_rect:
						_erase_rect_region(_erase_start, _erase_current)
					_finish_erase_batch()
					_set_preview_visible(true)
					return true
	
	return false

func draw(canvas: CanvasItem) -> void:
	if _erase_dragging and _erase_rect:
		var rect := _get_snapped_rect(_erase_start, _erase_current)
		canvas.draw_rect(rect, Color(1.0, 0.2, 0.2, 0.2))
		canvas.draw_rect(rect, Color(1.0, 0.2, 0.2, 0.8), false, 1.5)

# --------------------------------------------- Размещение

func _place_at(pos: Vector2) -> void:
	var floor_node := editor_level.get_active_floor()
	if floor_node == null:
		return
	
	var step     := 1.0 if _pixel_mode else DOOR_SIZE
	var snapped  := (pos / step).floor() * step
	
	var replaced_doors = []
	for child in floor_node.get_children():
		if child is DoorSprite and child.visible:
			if child.global_position.distance_squared_to(snapped) < 1.0:
				var child_is_vertical = child.direction in [0, 2]
				if child_is_vertical == _is_vertical:
					replaced_doors.append(child)
					child.visible = false
	
	var obj_id = DoorSprite.object_ids[_current_direction]
	var spr := DoorSprite.new(obj_id, _get_locked(), _get_cutscene())
	
	floor_node.add_child(spr)
	spr.global_position = snapped
	
	_place_batch.append({
		"node":     spr,
		"parent":   floor_node,
		"replaced": replaced_doors
	})

func _finish_place_batch() -> void:
	if _place_batch.is_empty():
		return
	
	var batch := _place_batch
	_place_batch = []
	
	UndoRedoManager.commit(
		"EDR_DOOR_PLACE",
		func():
			for d in batch:
				var s = d["node"]
				var p = d["parent"]
				if is_instance_valid(s) and is_instance_valid(p):
					if s.get_parent() == null:
						p.add_child(s)
				
				for r in d.get("replaced", []):
					if is_instance_valid(r) and r.get_parent() != null:
						r.get_parent().remove_child(r),
		func():
			var rev_batch := batch.duplicate()
			rev_batch.reverse()
			
			for d in rev_batch:
				var s = d["node"]
				var p = d["parent"]
				if is_instance_valid(s) and s.get_parent() != null:
					s.get_parent().remove_child(s)
				
				for r in d.get("replaced", []):
					if is_instance_valid(r) and is_instance_valid(p):
						if r.get_parent() == null:
							p.add_child(r)
						r.visible = true
	)

# --------------------------------------------- Поворот

func _rotate_door() -> void:
	var next_dir = (_current_direction + 1) % 4
	set_direction(next_dir)
	
	var tiles_tab = level_tab.tiles as TilesTab
	if tiles_tab and tiles_tab.option_dalign:
		tiles_tab.option_dalign.select(next_dir)
		tiles_tab._on_option_dalign_selected(next_dir)

# --------------------------------------------- Удаление

func _erase_at(pos: Vector2) -> void:
	var floor_node := editor_level.get_active_floor()
	if floor_node == null:
		return
	
	var hit := _sprite_at(pos)
	if hit == null:
		return
	_mark_erased(hit)

func _erase_rect_region(start: Vector2, end: Vector2) -> void:
	var floor_node := editor_level.get_active_floor()
	if floor_node == null:
		return
	
	var region := _get_snapped_rect(start, end)
	
	for child in floor_node.get_children():
		if not (child is DoorSprite) or not child.visible:
			continue
		
		if region.has_point(child.global_position):
			_mark_erased(child)

func _mark_erased(node: DoorSprite) -> void:
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
		"EDR_DOOR_ERASE",
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

func _sprite_at(pos: Vector2) -> DoorSprite:
	var current_mode: LevelTab.Modes = level_tab.current_mode
	var valid_sprites: Array[DoorSprite] = []
	
	for node in (Engine.get_main_loop() as SceneTree).get_nodes_in_group("sprites"):
		if node == _preview_root or not (node is DoorSprite) or not node.visible:
			continue
		
		if is_instance_valid(_preview_root) and node.get_parent() == _preview_root:
			continue
		
		if node.mode != current_mode:
			continue
		
		valid_sprites.append(node as DoorSprite)
	
	valid_sprites.sort_custom(func(a: DoorSprite, b: DoorSprite):
		if a.z_index == b.z_index:
			return a.get_index() > b.get_index()
		return a.z_index > b.z_index
	)
	
	for spr in valid_sprites:
		if spr._hit_test(pos):
			return spr
	
	return null

func _get_snapped_rect(start: Vector2, end: Vector2) -> Rect2:
	var step := 1.0 if _pixel_mode else DOOR_SIZE
	var s := (start / step).floor() * step
	var e := (end / step).floor() * step

	var min_p := Vector2(min(s.x, e.x), min(s.y, e.y))
	var max_p := Vector2(max(s.x, e.x), max(s.y, e.y)) + Vector2(step, step)
	
	return Rect2(min_p, max_p - min_p)
