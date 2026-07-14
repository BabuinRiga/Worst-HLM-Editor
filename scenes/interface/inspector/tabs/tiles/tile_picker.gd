class_name TilePicker
extends Control

signal tile_selected(tile: HLMTile, tx: int, ty: int)
signal selection_changed(tile: HLMTile, cells: Array[Vector2i])

@onready var level_tab = get_tree().get_first_node_in_group("LevelTab") as LevelTab

@export var zoom: float = 2.0:
	set(value):
		zoom = max(0.1, value)
		update_minimum_size()
		queue_redraw()

var _tile: HLMTile = null
var _hovered: Vector2i = Vector2i(-1, -1)

var _selection: Array[Vector2i] = []
var _drag_start: Vector2i = Vector2i(-1, -1)
var _is_dragging: bool = false

func set_tile(tile: HLMTile) -> void:
	_tile = tile
	_selection.clear()
	_hovered = Vector2i(-1, -1)
	update_minimum_size()
	queue_redraw()

func get_selected_cells() -> Array[Vector2i]:
	return _selection.duplicate()

func _update_tool() -> void:
	if _tile == null: return
	var tool := ToolManager._tools[ToolManager.Tool.TILE_PAINT] as ToolTilePaint
	tool.init(_tile, get_selected_cells())


# ----------------------------------------------------------------


func _draw() -> void:
	if _tile == null or _tile.tilemap == null:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.1, 0.1, 0.1))
		return
	
	var img_size := _tile.tilemap.get_size()
	draw_texture_rect(_tile.tilemap, Rect2(Vector2.ZERO, img_size * zoom), false)
	
	for cell in _selection:
		var r := _tile_to_rect(cell)
		draw_rect(r, Color(0.2, 0.6, 1.0, 0.4))
		draw_rect(r, Color(0.4, 0.8, 1.0), false, 1.5)
	
	if _hovered.x >= 0:
		var r := _tile_to_rect(_hovered)
		draw_rect(r, Color(1.0, 1.0, 1.0, 0.15))
		draw_rect(r, Color(1.0, 1.0, 1.0, 0.6), false, 1.0)
	
	if _is_dragging and _drag_start.x >= 0:
		var drag_rect := _get_drag_rect()
		draw_rect(drag_rect, Color(0.2, 0.6, 1.0, 0.2))
		draw_rect(drag_rect, Color(0.4, 0.8, 1.0, 0.8), false, 1.0)

func _gui_input(event: InputEvent) -> void:
	if _tile == null:
		return
	
	if event is InputEventMouseMotion:
		var tc := _px_to_tile(event.position)
		if tc != _hovered:
			_hovered = tc
			queue_redraw()

	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			var tc := _px_to_tile(event.position)
			if tc.x >= 0:
				_drag_start = tc
				_is_dragging = true
				if not event.ctrl_pressed and not event.shift_pressed:
					_selection.clear()
				queue_redraw()
		else:
			if _is_dragging:
				_is_dragging = false
				
				var tc := _clamp_tc(event.position) 
				
				if _drag_start == tc:
					_toggle_cell(tc)
					var t_size = _get_tile_size()
					tile_selected.emit(_tile, tc.x * t_size, tc.y * t_size)
				else:
					_select_rect(_drag_start, tc, event.ctrl_pressed or event.shift_pressed)
					selection_changed.emit(_tile, _selection.duplicate())
				
				_drag_start = Vector2i(-1, -1)
				queue_redraw()
				
				_update_tool()
				if ToolManager.current() != ToolManager._tools[ToolManager.Tool.TILE_PAINT]:
					ToolManager.set_tool(ToolManager.Tool.TILE_PAINT)

func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_EXIT:
		_hovered = Vector2i(-1, -1)
		queue_redraw()

func _get_minimum_size() -> Vector2:
	if _tile == null or _tile.tilemap == null:
		return Vector2(128, 128)
	var img_size := _tile.tilemap.get_size()
	return img_size * zoom


# ----------------------------------------------------------------


func _px_to_tile(pos: Vector2) -> Vector2i:
	if _tile == null or _tile.tilemap == null:
		return Vector2i(-1, -1)
	
	var img_size := _tile.tilemap.get_size() * zoom
	if pos.x < 0 or pos.y < 0 or pos.x >= img_size.x or pos.y >= img_size.y:
		return Vector2i(-1, -1)
	
	var s := _get_tile_size() * zoom
	var tx := int(pos.x / s)
	var ty := int(pos.y / s)
	return Vector2i(tx, ty)

func _clamp_tc(pos: Vector2) -> Vector2i:
	if _tile == null or _tile.tilemap == null:
		return Vector2i(-1, -1)
	var s := _get_tile_size() * zoom
	var max_x := int((_tile.tilemap.get_width() * zoom - 1) / s)
	var max_y := int((_tile.tilemap.get_height() * zoom - 1) / s)
	var tx := clampi(int(pos.x / s), 0, max_x)
	var ty := clampi(int(pos.y / s), 0, max_y)
	return Vector2i(tx, ty)

func _tile_to_rect(tc: Vector2i) -> Rect2:
	if _tile == null:
		return Rect2()
	var s := _get_tile_size()
	return Rect2(Vector2(tc) * s * zoom, Vector2(s, s) * zoom)

func _toggle_cell(tc: Vector2i) -> void:
	var i := _selection.find(tc)
	if i >= 0:
		_selection.remove_at(i)
	else:
		_selection.append(tc)

func _select_rect(a: Vector2i, b: Vector2i, additive: bool) -> void:
	var r := _get_normalized_tile_rect(a, b)
	if not additive:
		_selection.clear()
	for x in range(r.position.x, r.end.x):
		for y in range(r.position.y, r.end.y):
			var cell := Vector2i(x, y)
			if not _selection.has(cell):
				_selection.append(cell)

func select_cell(cell: Vector2i) -> void:
	_selection = [cell]
	_hovered = Vector2i(-1, -1)
	queue_redraw()

func clear_selection() -> void:
	_selection.clear()
	_hovered = Vector2i(-1, -1)
	queue_redraw()

func _get_normalized_tile_rect(a: Vector2i, b: Vector2i) -> Rect2i:
	var mn := Vector2i(min(a.x, b.x), min(a.y, b.y))
	var mx := Vector2i(max(a.x, b.x) + 1, max(a.y, b.y) + 1)
	return Rect2i(mn, mx - mn)

func _get_drag_rect() -> Rect2:
	var current_drag_end = _clamp_tc(get_local_mouse_position())
	var normalized_tiles = _get_normalized_tile_rect(_drag_start, current_drag_end)
	
	var s := _get_tile_size() * zoom
	var visual_pos = Vector2(normalized_tiles.position) * s
	var visual_size = Vector2(normalized_tiles.size) * s
	
	return Rect2(visual_pos, visual_size)

# -------------------------------------------------------------

func _get_current_depth(t: HLMTile = null) -> int:
	var target = t if t != null else _tile
	if target == null: return 0
	
	if level_tab and level_tab.tiles.tile_prop_check.button_pressed and target != Defs._tiles[-1]:
		return int(level_tab.tiles.depth_spin_box.value)
	
	return target.depth

func _get_tile_size(t: HLMTile = null) -> int:
	var d = _get_current_depth(t)
	return 16 if d > -99 else 8
