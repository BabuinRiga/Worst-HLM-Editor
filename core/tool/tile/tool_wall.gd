class_name ToolWallPlace
extends EditorTool

var _object_id: int
var _sprite_id: int
var _is_vertical: bool = false

var _preview_root: Node2D = null
var _last_preview_count: int = -1
var _preview_is_line: bool = false

var _place_dragging: bool    = false
var _place_line:     bool    = false
var _place_start:    Vector2 = Vector2.ZERO
var _place_current:  Vector2 = Vector2.ZERO
var _pixel_mode:     bool    = false
var _place_batch:    Array   = []

var _erase_dragging: bool    = false
var _erase_rect:     bool    = false
var _erase_start:    Vector2 = Vector2.ZERO
var _erase_current:  Vector2 = Vector2.ZERO
var _erase_batch:    Array   = []

const WALL_SIZE: float = 32.0

# ---------------------------------------------

func init(wall: WallSprite) -> void:
	_object_id = wall.object_id
	_sprite_id = wall.sprite_id
	_is_vertical = _find_orientation(_object_id, _sprite_id)
	
	if is_instance_valid(_preview_root):
		_create_preview()

func activate() -> void:
	_create_preview()

func deactivate() -> void:
	_destroy_preview()
	
	if _place_dragging:
		_finish_place_batch()
	if _erase_dragging:
		_finish_erase_batch()
	
	_place_dragging = false
	_erase_dragging = false
	
	var tiles_tab = level_tab.tiles as TilesTab
	if tiles_tab:
		tiles_tab.wall_list.deselect_all()

# ---------------------------------------------

func _create_preview() -> void:
	_destroy_preview()
	
	if !_object_id or !_sprite_id:
		return
	
	var floor_node := editor_level.get_active_floor()
	if floor_node == null:
		return
	
	_preview_root = Node2D.new()
	_preview_root.set_meta("preview", true)
	_preview_root.modulate.a = 0.5
	_preview_root.z_index    = 1000
	
	floor_node.add_child(_preview_root)
	
	_preview_is_line = false
	var step := 1.0 if _pixel_mode else WALL_SIZE
	var default_offset := Vector2(0, step) if _is_vertical else Vector2(step, 0)
	_rebuild_preview(0, default_offset)
	_update_preview_pos()

func _rebuild_preview(count: int, offset: Vector2) -> void:
	if not is_instance_valid(_preview_root) or !_object_id or !_sprite_id:
		return
	
	for child in _preview_root.get_children():
		child.queue_free()
	
	for i in range(count + 1):
		var spr := WallSprite.new(_object_id, _sprite_id)
		spr.position = offset * i
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
	var step := 1.0 if _pixel_mode else WALL_SIZE
	var pos  := _world_pos()
	
	if _place_dragging and _place_line:
		var snapped_start := _snap_wall_pos(_place_start)
		var count := _line_step_count(_place_start, _place_current)
		
		var dir_y = sign(_place_current.y - _place_start.y) if _place_current.y != _place_start.y else 1
		var dir_x = sign(_place_current.x - _place_start.x) if _place_current.x != _place_start.x else 1
		var current_offset := Vector2(0, step * dir_y) if _is_vertical else Vector2(step * dir_x, 0)
		
		if count != _last_preview_count or not _preview_is_line:
			_last_preview_count = count
			_preview_is_line = true
			_rebuild_preview(count, current_offset)
		
		_preview_root.global_position = snapped_start - _wall_offset()
	else:
		var snapped := (pos / step).floor() * step
		
		if _preview_is_line:
			_preview_is_line = false
			var default_offset := Vector2(0, step) if _is_vertical else Vector2(step, 0)
			_rebuild_preview(0, default_offset)
		
		_preview_root.global_position = snapped - _wall_offset()

# ---------------------------------------------

func handle_input(event: InputEvent) -> bool:
	if event is InputEventMouseMotion:
		if _place_dragging:
			_place_current = _world_pos()
			if _place_current.distance_squared_to(_place_start) > 4.0:
				_place_line = true
			_update_preview_pos()
			return true
		
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
				_place_dragging = true
				_pixel_mode     = mb.ctrl_pressed
				_place_line     = false
				
				_place_start    = _world_pos()
				_place_current  = _place_start
				_place_batch.clear()
				
				_update_preview_pos()
				return true
			else:
				if _place_dragging:
					if _place_line:
						_place_line_region(_place_start, _place_current)
					else:
						_place_at(_place_start)
					
					_preview_is_line = false
					_rebuild_preview(0, Vector2.ZERO)
					_update_preview_pos()
					_finish_place_batch()
					return true
		
		# Поворот
		if mb.button_index == MOUSE_BUTTON_RIGHT and mb.shift_pressed and not mb.ctrl_pressed:
			if mb.pressed:
				_rotate_wall()
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
	if _place_dragging and _place_line:
		pass
	if _erase_dragging and _erase_rect:
		var rect := _get_snapped_rect(_erase_start, _erase_current)
		canvas.draw_rect(rect, Color(1.0, 0.2, 0.2, 0.2))
		canvas.draw_rect(rect, Color(1.0, 0.2, 0.2, 0.8), false, 1.5)

# --------------------------------------------- Размещение

func _place_at(pos: Vector2) -> void:
	if !_object_id or !_sprite_id:
		return
	
	var floor_node := editor_level.get_active_floor()
	if floor_node == null:
		return
	
	var step      := 1.0 if _pixel_mode else WALL_SIZE
	var snapped   := (pos / step).floor() * step
	var final_pos := snapped - _wall_offset()
	
	var replaced_walls = []
	
	for child in floor_node.get_children():
		if child is WallSprite and child.visible:
			if child.global_position.distance_squared_to(final_pos) < 1.0:
				var child_is_vertical = _find_orientation(child.object_id, child.sprite_id)
				if child_is_vertical == _is_vertical:
					replaced_walls.append(child)
					child.visible = false
	
	var spr := WallSprite.new(_object_id, _sprite_id)
	spr.global_position = final_pos
	floor_node.add_child(spr)
	
	_place_batch.append({
		"node":     spr,
		"parent":   floor_node,
		"replaced": replaced_walls
	})

func _place_line_region(start: Vector2, end: Vector2) -> void:
	if !_object_id or !_sprite_id:
		return
	
	var snapped_start := _snap_wall_pos(start)
	var count := _line_step_count(start, end)
	var step := 1.0 if _pixel_mode else WALL_SIZE
	
	var dir_y = sign(end.y - start.y) if end.y != start.y else 1
	var dir_x = sign(end.x - start.x) if end.x != start.x else 1
	
	var offset := Vector2(0, step * dir_y) if _is_vertical else Vector2(step * dir_x, 0)
	
	for i in range(abs(count) + 1):
		_place_at(snapped_start + offset * i)

func _line_step_count(start: Vector2, end: Vector2) -> int:
	var step := 1.0 if _pixel_mode else WALL_SIZE
	var s := _snap_wall_pos(start)
	var e := _snap_wall_pos(end)
	
	if _is_vertical:
		return int(round(abs(e.y - s.y) / step))
	else:
		return int(round(abs(e.x - s.x) / step))

func _snap_wall_pos(pos: Vector2) -> Vector2:
	var step := 1.0 if _pixel_mode else WALL_SIZE
	return (pos / step).floor() * step

func _wall_at(floor_node: Node, pos: Vector2) -> WallSprite:
	for child in floor_node.get_children():
		if child is WallSprite and child.visible:
			if child.global_position.distance_squared_to(pos) < 1.0:
				return child as WallSprite
	return null

func _finish_place_batch() -> void:
	_place_dragging = false
	if _place_batch.is_empty():
		return
	
	var batch := _place_batch
	_place_batch = []
	
	UndoRedoManager.commit(
		"EDR_WALL_PLACE",
		func(): # DO
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

func _rotate_wall() -> void:
	var walls: Array = level_tab.tiles.walls if level_tab and level_tab.tiles else []
	if walls.is_empty():
		return
	
	var idx := -1
	for i in range(walls.size()):
		if walls[i]["object_id"] == _object_id and walls[i]["sprite_id"] == _sprite_id:
			idx = i
			break
	
	if idx == -1:
		return
	
	var next_idx: int = walls[idx]["next"]
	if next_idx < 0 or next_idx >= walls.size():
		return
	
	_object_id   = walls[next_idx]["object_id"]
	_sprite_id   = walls[next_idx]["sprite_id"]
	_is_vertical = (next_idx % 2) == 1
	
	_preview_is_line = false
	_rebuild_preview(0, Vector2.ZERO)
	_update_preview_pos()
	
	var tiles_tab = level_tab.tiles as TilesTab
	if tiles_tab:
		tiles_tab.wall_list.select(next_idx)

func _find_orientation(object_id: int, sprite_id: int) -> bool:
	var walls: Array = level_tab.tiles.walls if level_tab and level_tab.tiles else []
	for i in range(walls.size()):
		if walls[i]["object_id"] == object_id and walls[i]["sprite_id"] == sprite_id:
			return (i % 2) == 1
	return false

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
		if not (child is WallSprite) or not child.visible:
			continue
		
		if region.has_point(child.global_position):
			_mark_erased(child)

func _mark_erased(node: WallSprite) -> void:
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
		"EDR_WALL_ERASE",
		func(): # DO
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

func _sprite_at(pos: Vector2) -> WallSprite:
	var current_mode: LevelTab.Modes = level_tab.current_mode
	var valid_sprites: Array[WallSprite] = []
	
	for node in (Engine.get_main_loop() as SceneTree).get_nodes_in_group("sprites"):
		if node == _preview_root or not (node is WallSprite) or not node.visible:
			continue
		
		if is_instance_valid(_preview_root) and node.get_parent() == _preview_root:
			continue
		
		if node.mode != current_mode:
			continue
		
		valid_sprites.append(node as WallSprite)
	
	valid_sprites.sort_custom(func(a: WallSprite, b: WallSprite):
		if a.z_index == b.z_index:
			return a.get_index() > b.get_index()
		return a.z_index > b.z_index
	)
	
	for spr in valid_sprites:
		if spr._hit_test(pos):
			return spr
	
	return null

func _wall_offset() -> Vector2:
	if !_object_id or !_sprite_id:
		return Vector2.ZERO
	var def := Defs.get_sprite_def(_sprite_id)
	return -Vector2(def.center)

func _get_snapped_rect(start: Vector2, end: Vector2) -> Rect2:
	var step := 1.0 if _pixel_mode else WALL_SIZE
	
	var s := (start / step).floor() * step
	var e := (end / step).floor() * step

	var min_p := Vector2(min(s.x, e.x), min(s.y, e.y))
	var max_p := Vector2(max(s.x, e.x), max(s.y, e.y)) + Vector2(step, step)
	
	return Rect2(min_p, max_p - min_p)
