class_name ToolTilePaint
extends EditorTool

var _tile:  HLMTile         = null
var _cells: Array[Vector2i] = []
var _base_cell: Vector2i = Vector2i.ZERO

var _preview_root: Node2D = null
var _last_preview_rect: Rect2 = Rect2()
var _preview_is_rect: bool = false

var _paint_dragging: bool  = false
var _paint_rect:     bool  = false
var _paint_start:    Vector2 = Vector2.ZERO
var _paint_current:  Vector2 = Vector2.ZERO
var _pixel_mode:     bool  = false
var _alt_mode:       bool  = false
var _paint_batch:    Array = []

var _erase_dragging: bool    = false
var _erase_rect:     bool    = false
var _erase_start:    Vector2 = Vector2.ZERO
var _erase_current:  Vector2 = Vector2.ZERO
var _erase_batch:    Array   = []

# ---------------------------------------------


func init(tile: HLMTile, cells: Array[Vector2i]) -> void:
	_tile  = tile
	_cells = cells
	if _cells.size() > 0:
		var min_x = _cells[0].x
		var min_y = _cells[0].y
		for c in _cells:
			min_x = min(min_x, c.x)
			min_y = min(min_y, c.y)
		_base_cell = Vector2i(min_x, min_y)
	else:
		_base_cell = Vector2i.ZERO
	
	if is_instance_valid(_preview_root):
		_create_preview()

func activate() -> void:
	_create_preview()

func deactivate() -> void:
	_destroy_preview()
	
	if _paint_dragging: 
		_finish_paint_batch()
	if _erase_dragging: 
		_finish_erase_batch()
		
	_paint_dragging = false
	_erase_dragging = false
	_erase_rect     = false
	
	var tiles_tab = level_tab.tiles as TilesTab
	if tiles_tab:
		tiles_tab.tile_picker.clear_selection()
		tiles_tab.c_picker.clear_selection()

# ---------------------------------------------

func _create_preview() -> void:
	_destroy_preview()
	
	if _tile == null or _cells.is_empty():
		return
		
	var floor_node := editor_level.get_active_floor()
	if floor_node == null:
		return

	_preview_root = Node2D.new()
	_preview_root.set_meta("preview", true)
	_preview_root.modulate.a = 0.5
	_preview_root.z_index    = 1000
	
	floor_node.add_child(_preview_root)
	
	_preview_is_rect = false
	_rebuild_preview(false)
	_update_preview_pos()

func _rebuild_preview(is_rect: bool, rect: Rect2 = Rect2()) -> void:
	if not is_instance_valid(_preview_root) or _tile == null or _cells.is_empty():
		return
		
	var floor_node := editor_level.get_active_floor()
	if floor_node == null:
		return
	
	for child in _preview_root.get_children():
		child.queue_free()
	
	var t_size := _get_tile_size()
	var step := float(t_size)
	var step_base := 1.0 if _pixel_mode else step
	
	if not is_rect:
		for cell in _cells:
			var current_depth = _get_current_depth()
			var spr := TileSprite.new(_tile.id, cell.x * t_size, cell.y * t_size, current_depth)
			spr.position = Vector2(cell - _base_cell) * step
			_preview_root.add_child(spr)
	else:
		var min_x = _cells[0].x
		var max_x = _cells[0].x
		var min_y = _cells[0].y
		var max_y = _cells[0].y
		
		for c in _cells:
			min_x = min(min_x, c.x); max_x = max(max_x, c.x)
			min_y = min(min_y, c.y); max_y = max(max_y, c.y)
			
		var pattern_w = (max_x - min_x + 1) * step_base
		var pattern_h = (max_y - min_y + 1) * step_base
		
		var pos_x = rect.position.x
		while pos_x < rect.end.x:
			var pos_y = rect.position.y
			while pos_y < rect.end.y:
				var current_pos = Vector2(pos_x, pos_y)
				var snapped = (current_pos / step_base).floor() * step_base
				
				for cell in _cells:
					var offset = Vector2(cell - _base_cell) * step
					var current_depth = _get_current_depth()
					var spr := TileSprite.new(_tile.id, cell.x * t_size, cell.y * t_size, current_depth)
					spr.position = snapped + offset
					_preview_root.add_child(spr)
					
				pos_y += pattern_h
			pos_x += pattern_w

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
	var step := 1.0 if _pixel_mode else float(_get_tile_size())
	var pos  := _world_pos()
	
	if _paint_dragging and _paint_rect:
		var rect := _get_snapped_rect(_paint_start, _paint_current)
		if rect != _last_preview_rect or not _preview_is_rect:
			_last_preview_rect = rect
			_preview_is_rect = true
			_rebuild_preview(true, rect)
		
		_preview_root.global_position = Vector2.ZERO
	else:
		var snapped := (pos / step).floor() * step
		
		if _preview_is_rect:
			_preview_is_rect = false
			_rebuild_preview(false)
			
		_preview_root.global_position = snapped

# ---------------------------------------------

func _update_alt_mode() -> void:
	var physical_alt := Input.is_key_pressed(KEY_ALT)
	var manual_toggle := false
	
	var tiles_tab = level_tab.tiles as TilesTab
	if tiles_tab:
		manual_toggle = tiles_tab.manual_place_layer
		
	_alt_mode = manual_toggle != physical_alt


func _pick_tile(hit: TileSprite) -> void:
	var found_tile: HLMTile = Defs.get_tile(hit.tile_id)
	if found_tile == null:
		return
	
	var tiles_tab = level_tab.tiles as TilesTab
	if tiles_tab == null:
		return
		
	var protected_id = Defs._tiles[-1].id if Defs._tiles.size() > 0 else -1
	
	if found_tile.id == protected_id:
		tiles_tab.c_picker.set_tile(found_tile)
	else:
		tiles_tab.select_tile_by_id(found_tile.id)
	
	if hit.depth != found_tile.depth:
		tiles_tab.tile_prop_check.button_pressed = true
		tiles_tab.tile_prop_check.toggled.emit(true)
		
		tiles_tab.depth_spin_box.value = hit.depth
		tiles_tab.depth_spin_box.value_changed.emit(hit.depth)
	else:
		tiles_tab.tile_prop_check.button_pressed = false
		tiles_tab.tile_prop_check.toggled.emit(false)
		
		tiles_tab.depth_spin_box.value = found_tile.depth
		tiles_tab.depth_spin_box.value_changed.emit(found_tile.depth)
	
	var cell := Vector2i(hit.tile_x, hit.tile_y) / _get_tile_size(found_tile)
	
	init(found_tile, [cell])
	
	if found_tile.id == protected_id:
		tiles_tab.c_picker.select_cell(cell)
		tiles_tab.tile_picker.clear_selection()
	else:
		tiles_tab.tile_picker.select_cell(cell)
		tiles_tab.c_picker.clear_selection()

# ---------------------------------------------

func handle_input(event: InputEvent) -> bool:
	if event is InputEventMouseMotion:
		_update_alt_mode()
		
		if _paint_dragging:
			_paint_current = _world_pos()
			if not _paint_rect:
				_paint_at(_paint_current)
			else:
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
		
		# Рисование
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_paint_dragging = true
				_pixel_mode     = mb.ctrl_pressed
				_update_alt_mode()
				_paint_rect     = mb.shift_pressed 
				
				_paint_start    = _world_pos()
				_paint_current  = _paint_start
				_paint_batch.clear()
				
				if _paint_rect:
					_update_preview_pos()
				else:
					_paint_at(_paint_start)
				return true
			else:
				if _paint_dragging:
					if _paint_rect:
						_paint_rect_region(_paint_start, _paint_current)
						_preview_is_rect = false
						_rebuild_preview(false)
						_update_preview_pos()
					_finish_paint_batch()
					return true
		
		# Удаление и Пипетка
		if mb.button_index == MOUSE_BUTTON_RIGHT:
			if mb.pressed:
				if Input.is_key_pressed(KEY_ALT):
					var hit := _tile_at(_world_pos())
					if hit:
						_pick_tile(hit)
						return true
				
				_update_alt_mode()
				_erase_dragging = true
				_erase_rect     = mb.shift_pressed 
				_erase_start    = _world_pos()
				_erase_current  = _erase_start
				_erase_batch.clear()
				_set_preview_visible(false)
				
				if not _erase_rect:
					_erase_at(_world_pos())
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


# --------------------------------------------- Рисование

func _paint_at(pos: Vector2) -> void:
	if _tile == null or _cells.is_empty():
		return
	var floor_node := editor_level.get_active_floor()
	if floor_node == null:
		return
	
	var t_size := _get_tile_size()
	var step := 1.0 if _pixel_mode else float(t_size)
	var snapped := (pos / step).floor() * step
	
	var protected_id = Defs._tiles[-1].id if Defs._tiles.size() > 0 else -1
	var current_id = _tile.id
	
	for cell in _cells:
		var offset := Vector2(cell - _base_cell) * float(t_size)
		var tile_pos := snapped + offset
		
		var existing_tiles = _get_tiles_at(floor_node, tile_pos)
		var replaced_data = []
		var can_paint = true
		
		for ext_tile in existing_tiles:
			var ext_id = ext_tile.tile_id
			
			if current_id == protected_id:
				if ext_id == protected_id:
					replaced_data.append({
						"node": ext_tile,
						"parent": ext_tile.get_parent(),
						"index": ext_tile.get_index()
					})
				continue
			
			if ext_id == protected_id:
				continue
			
			if !_alt_mode:
				continue
				
			replaced_data.append({
				"node": ext_tile,
				"parent": ext_tile.get_parent(),
				"index": ext_tile.get_index()
			})
			
		if not can_paint:
			continue
			
		for r in replaced_data:
			var r_node = r["node"]
			r_node.get_parent().remove_child(r_node)
		
		var current_depth = _get_current_depth()
		var spr := TileSprite.new(_tile.id, cell.x * t_size, cell.y * t_size, current_depth)
		spr.global_position = tile_pos
		floor_node.add_child(spr)
		
		_paint_batch.append({ 
			"node": spr, 
			"parent": floor_node,
			"replaced": replaced_data
		})

func _paint_rect_region(start: Vector2, end: Vector2) -> void:
	if _tile == null or _cells.is_empty():
		return
		
	var rect = _get_snapped_rect(start, end)
	var step_base = 1.0 if _pixel_mode else float(_get_tile_size())
	
	var min_x = _cells[0].x
	var max_x = _cells[0].x
	var min_y = _cells[0].y
	var max_y = _cells[0].y
	
	for c in _cells:
		min_x = min(min_x, c.x)
		max_x = max(max_x, c.x)
		min_y = min(min_y, c.y)
		max_y = max(max_y, c.y)
		
	var pattern_w = (max_x - min_x + 1) * step_base
	var pattern_h = (max_y - min_y + 1) * step_base
	
	var pos_x = rect.position.x
	while pos_x < rect.end.x:
		var pos_y = rect.position.y
		while pos_y < rect.end.y:
			_paint_at(Vector2(pos_x, pos_y))
			pos_y += pattern_h
		pos_x += pattern_w

func _get_tiles_at(floor_node: Node, pos: Vector2) -> Array[TileSprite]:
	var found: Array[TileSprite] = []
	for child in floor_node.get_children():
		if child is TileSprite and child.visible:
			if child.global_position.distance_squared_to(pos) < 1.0:
				found.append(child as TileSprite)
	return found

func _finish_paint_batch() -> void:
	_paint_dragging = false
	if _paint_batch.is_empty():
		return
		
	var batch = _paint_batch
	_paint_batch = []
	
	UndoRedoManager.commit(
		"EDR_TILE_PAINT",
		func(): # DO
			for d in batch:
				var s = d["node"]
				var p = d["parent"]
				
				for r in d["replaced"]:
					var r_node   = r["node"]
					var r_parent = r["parent"]
					if is_instance_valid(r_node) and r_node.get_parent() != null:
						r_parent.remove_child(r_node)
						
				if is_instance_valid(s) and is_instance_valid(p):
					if s.get_parent() == null:
						p.add_child(s),
		func():
			var rev_batch = batch.duplicate()
			rev_batch.reverse()
			
			for d in rev_batch:
				var s = d["node"]
				var p = d["parent"]
				
				if is_instance_valid(s) and s.get_parent() != null:
					s.get_parent().remove_child(s)
					
				for r in d["replaced"]:
					var r_node   = r["node"]
					var r_parent = r["parent"]
					if is_instance_valid(r_node) and is_instance_valid(r_parent):
						if r_node.get_parent() == null:
							r_parent.add_child(r_node)
						
						var safe_idx = clampi(r["index"], 0, r_parent.get_child_count() - 1)
						r_parent.move_child(r_node, safe_idx)
	)


# --------------------------------------------- Удаление

func _can_erase_tile(target_node: TileSprite) -> bool:
	var target_id    = target_node.tile_id
	var current_id   = _tile.id if _tile != null else -1
	var protected_id = Defs._tiles[-1].id if Defs._tiles.size() > 0 else -1
	
	if target_id != current_id:
		if target_id == protected_id or current_id == protected_id:
			return false
		
	if !_alt_mode and target_id != current_id:
		return false
		
	return true

func _erase_at(pos: Vector2) -> void:
	var hit := _tile_at(pos)
	if hit and _can_erase_tile(hit):
		_mark_erased(hit)

func _erase_rect_region(start: Vector2, end: Vector2) -> void:
	var floor_node := editor_level.get_active_floor()
	if floor_node == null or _tile == null:
		return
		
	var region := _get_snapped_rect(start, end)
	
	for child in floor_node.get_children():
		if not (child is TileSprite) or not child.visible:
			continue
			
		if region.has_point(child.global_position):
			if _can_erase_tile(child as TileSprite):
				_mark_erased(child)

func _tile_at(pos: Vector2) -> TileSprite:
	var floor_node := editor_level.get_active_floor()
	if floor_node == null:
		return null
		
	var valid_children: Array[TileSprite] = []
	
	for child in floor_node.get_children():
		if child is TileSprite and child.visible:
			valid_children.append(child as TileSprite)
			
	valid_children.sort_custom(func(a: TileSprite, b: TileSprite):
		if a.z_index == b.z_index:
			return a.get_index() > b.get_index()
		return a.z_index > b.z_index
	)
	
	for child in valid_children:
		if child._hit_test(pos):
			return child
				
	return null

func _mark_erased(node: TileSprite) -> void:
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
	_erase_rect     = false
	
	if _erase_batch.is_empty():
		return
	
	for d in _erase_batch:
		var s = d["node"]
		if is_instance_valid(s):
			s.visible = true
	
	var batch = _erase_batch
	_erase_batch = []
	
	UndoRedoManager.commit(
		"EDR_TILE_ERASE",
		func(): # DO
			for d in batch:
				var s = d["node"]
				if is_instance_valid(s) and s.get_parent() != null:
					s.get_parent().remove_child(s),
		func():
			var rev_batch = batch.duplicate()
			rev_batch.reverse()
			
			for d in rev_batch:
				var s = d["node"]
				var p = d["parent"]
				if is_instance_valid(s) and is_instance_valid(p):
					if s.get_parent() == null:
						p.add_child(s)
					
					var safe_idx = clampi(d["index"], 0, p.get_child_count() - 1)
					p.move_child(s, safe_idx)
					s.visible = true
	)

# --------------------------------------------- Вспомогательное

func _get_snapped_rect(start: Vector2, end: Vector2) -> Rect2:
	if _tile == null: return Rect2()
	var step := 1.0 if _pixel_mode else float(_get_tile_size())
	
	var s = (start / step).floor() * step
	var e = (end / step).floor() * step
	
	var min_p = Vector2(min(s.x, e.x), min(s.y, e.y))
	var max_p = Vector2(max(s.x, e.x), max(s.y, e.y)) + Vector2(step, step)
	
	return Rect2(min_p, max_p - min_p)

func _get_current_depth(t: HLMTile = null) -> int:
	var target = t if t != null else _tile
	if target == null: return 0
	
	var tiles_tab = level_tab.tiles as TilesTab
	if tiles_tab and tiles_tab.tile_prop_check.button_pressed and target != Defs._tiles[-1]:
		return int(tiles_tab.depth_spin_box.value)
	
	return target.depth

func _get_tile_size(t: HLMTile = null) -> int:
	var d = _get_current_depth(t)
	return 16 if d > -99 else 8
