class_name ToolObjPlace
extends EditorTool

signal frame_changed(new_frame: int)

var _object_id: int
var _sprite_id: int
var _mode:      int

var _preview: ObjectSprite = null
var _preview_rotation: float = 0.0
var _preview_frame: int = 0
var _preview_coord_cache: Vector2 = Vector2.ZERO

var _move_dragging:  bool  = false
var _move_origin:    Vector2
var _move_snapshot:  Array
var _move_target:    ObjectSprite
var _move_snap_grid: bool = false

var _erase_dragging: bool  = false
var _erase_batch:    Array

# ---------------------------------------------

func init(object_id: int, sprite_id: int, mode: int, frame: int = 0) -> void:
	_object_id = object_id
	_sprite_id = sprite_id
	_mode      = mode
	_preview_frame = frame
	
	_create_preview()

func activate() -> void:
	_create_preview()

func deactivate() -> void:
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	_destroy_preview()
	_move_dragging  = false
	_erase_dragging = false
	_preview_rotation = 0.0
	_preview_frame = 0
	_erase_batch.clear()

# ---------------------------------------------

func _create_preview() -> void:
	_destroy_preview()
	if _object_id == 0:
		return
	var obj := _make_hlm_object()
	
	_preview = _instantiate_sprite(obj, float(_preview_frame), _mode)
	_preview.set_meta("preview", true)
	
	_preview.global_position = _preview_coord_cache
	_preview.rotation_degrees = _preview_rotation
	_preview.modulate.a = 0.5
	_preview.z_index    = 1000
	var floor_node := editor_level.get_active_floor()
	if floor_node:
		floor_node.add_child(_preview)

func _destroy_preview() -> void:
	if is_instance_valid(_preview):
		_preview_coord_cache = _preview.global_position
		_preview.queue_free()
	_preview = null

func _set_preview_visible(v: bool) -> void:
	if is_instance_valid(_preview):
		_preview.visible = v

func _update_preview_pos() -> void:
	if not is_instance_valid(_preview):
		return
	var pos := _world_pos()
	if Input.is_key_pressed(KEY_SHIFT):
		var grid := Vector2(View.grid_value)
		pos = (pos / grid).round() * grid
	else:
		pos = pos.round()
	_preview.global_position = pos

# ---------------------------------------------

func handle_input(event: InputEvent) -> bool:
	if event is InputEventMouseMotion:
		if _move_dragging:
			_update_move_drag()
			return true
		if _erase_dragging:
			_erase_at(_world_pos())
			return true
		_update_preview_pos()
		return false
	
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		
		# Смена фрейма
		if mb.pressed and mb.alt_pressed:
			if mb.button_index == MOUSE_BUTTON_WHEEL_UP:
				_change_preview_frame(1)
				return true
			elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				_change_preview_frame(-1)
				return true
		
		# Размещение и Перемещение
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				if mb.ctrl_pressed:
					var hit := _sprite_at(_world_pos())
					if hit:
						_start_move_drag(hit, mb.shift_pressed)
						return true
				else:
					var pos := _world_pos()
					if mb.shift_pressed: 
						var grid := Vector2(View.grid_value)
						pos = (pos / grid).round() * grid
					else:
						pos = pos.round()
						
					_place_object(pos) 
					return true
			else:
				if _move_dragging:
					_finish_move_drag()
					return true
		
		# Удаление и Поворот
		if mb.button_index == MOUSE_BUTTON_RIGHT:
			if mb.pressed:
				if mb.shift_pressed:
					# Поворот
					if _move_target:
						_rotate_target_snap90(_move_target, false)
						return true
					else:
						_rotate_preview_snap90(false)
						return true
				else:
					# Удаление
					_set_preview_visible(false)
					_erase_dragging = true
					_erase_batch.clear()
					_erase_at(_world_pos())
					return true
			else:
				if _erase_dragging:
					_finish_erase_batch()
					return true
		
		# Поворот
		if mb.pressed and not mb.alt_pressed and (mb.ctrl_pressed or mb.shift_pressed):
			if mb.button_index == MOUSE_BUTTON_WHEEL_DOWN or mb.button_index == MOUSE_BUTTON_WHEEL_UP:
				var dir := 1 if mb.button_index == MOUSE_BUTTON_WHEEL_DOWN else -1
				var step := 5.0 if mb.shift_pressed else 1.0
				if _move_target:
					_rotate_target(_move_target, dir, step)
					return true
				else:
					_rotate_preview(dir, step)
					return true
	
	return false

# --------------------------------------------- Размещение

func _place_object(pos: Vector2) -> void:
	var floor_node := editor_level.get_active_floor()
	if floor_node == null:
		return
	var obj := _make_hlm_object()
	
	var spr := _instantiate_sprite(obj, float(_preview_frame), _mode)
	
	spr.global_position = pos
	spr.rotation_degrees = _preview_rotation
	spr.level = floor_node.index
	UndoRedoManager.commit(
		"EDR_OBJ_PLACE",
		func():
			if is_instance_valid(spr) and is_instance_valid(floor_node):
				floor_node.add_child(spr),
		func():
			if is_instance_valid(spr) and spr.get_parent() != null:
				spr.get_parent().remove_child(spr)
	)

func _instantiate_sprite(obj: HLMObject, frame: float, sprite_mode: int) -> ObjectSprite:
	if obj.object_id == NPCObjectSprite.NPCobjectID:
		return NPCObjectSprite.new(obj, 0.0, sprite_mode)
	else:
		return ObjectSprite.new(obj, frame, sprite_mode)

# --------------------------------------------- Смена фрейма

func _change_preview_frame(direction: int) -> void:
	var def := Defs.get_sprite_def(_sprite_id)
	_preview_frame = wrapi(_preview_frame + direction, 0, def.frames.size())
	
	if is_instance_valid(_preview):
		_preview.object_frame = float(_preview_frame)
	
	_create_preview()
	frame_changed.emit(_preview_frame)

func set_frame_from_ui(frame_index: int) -> void:
	var def := Defs.get_sprite_def(_sprite_id)
	if not def or def.frames.is_empty(): return
	
	_preview_frame = clampi(frame_index, 0, def.frames.size() - 1)
	
	if is_instance_valid(_preview):
		_preview.object_frame = float(_preview_frame)
	
	_create_preview()

# --------------------------------------------- Перемещение

func _start_move_drag(target: ObjectSprite, snap_to_grid: bool) -> void:
	_move_dragging  = true
	_move_snap_grid = snap_to_grid
	_move_origin    = _world_pos()
	_move_target    = target
	_move_snapshot  = [{ "ref": target, "pos": target.global_position }]
	_set_preview_visible(false)
	Input.set_default_cursor_shape(Input.CURSOR_MOVE)

func _update_move_drag() -> void:
	var snap := Input.is_key_pressed(KEY_SHIFT)
	var delta := _world_pos() - _move_origin
	for d in _move_snapshot:
		var s := d["ref"] as BaseSprite
		if not is_instance_valid(s):
			continue
		var new_pos: Vector2 = d["pos"] + delta
		if snap:
			var grid := Vector2(View.grid_value)
			new_pos = (new_pos / grid).round() * grid
		else:
			new_pos = new_pos.round()
		s.global_position = new_pos

func _finish_move_drag() -> void:
	_move_dragging = false
	Input.set_default_cursor_shape(Input.CURSOR_CROSS)
	_set_preview_visible(true)
	
	var final_state := []
	for s in _move_snapshot:
		final_state.append({ "ref": s["ref"], "pos": s["ref"].global_position })
	
	var snapshot := _move_snapshot.duplicate(true)
	
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
	
	_move_snapshot = []
	_move_target   = null

# --------------------------------------------- Удаление

func _erase_at(pos: Vector2) -> void:
	var hit := _sprite_at(pos)
	if hit == null:
		return
	for d in _erase_batch:
		if d["ref"] == hit:
			return
	_erase_batch.append({
		"ref":    hit,
		"parent": hit.get_parent(),
		"index":  hit.get_index(),
	})
	hit.visible = false

func _finish_erase_batch() -> void:
	_set_preview_visible(true)
	_erase_dragging = false
	if _erase_batch.is_empty():
		return
	
	var batch := _erase_batch.duplicate(true)
	for d in batch:
		var s := d["ref"] as Node
		if is_instance_valid(s):
			s.visible = true
	
	UndoRedoManager.commit(
		"EDR_OBJ_ERASE",
		func():
			for d in batch:
				var s: Node = d["ref"]
				if is_instance_valid(s) and s.get_parent() != null:
					s.get_parent().remove_child(s),
		func():
			for d in batch:
				var s = d["ref"]
				var p = d["parent"]
				if is_instance_valid(s) and is_instance_valid(p):
					p.add_child(s)
					p.move_child(s, d["index"])
	)
	
	_erase_batch.clear()

# --------------------------------------------- Поворот

func _rotate_target(target: ObjectSprite, direction: int, step: float) -> void:
	var delta_deg := step * direction
	var snapshot  := { "ref": target, "pos": target.global_position, "rot": target.rotation_degrees }
	
	UndoRedoManager.commit(
		"EDR_SPR_ROTATE",
		func():
			var s = snapshot["ref"]
			if not is_instance_valid(s): return
			s.rotation_degrees = roundf(snapshot["rot"] + delta_deg)
			if s.has_method("set_angle"): s.set_angle(s.rotation_degrees),
		func():
			var s = snapshot["ref"]
			if not is_instance_valid(s): return
			s.rotation_degrees = snapshot["rot"]
			if s.has_method("set_angle"): s.set_angle(snapshot["rot"])
	)

func _rotate_target_snap90(target: ObjectSprite, counter_clockwise: bool) -> void:
	var snapshot := { "ref": target, "pos": target.global_position, "rot": target.rotation_degrees }
	
	UndoRedoManager.commit(
		"EDR_SPR_ROTATE",
		func():
			var s = snapshot["ref"]
			if not is_instance_valid(s): return
			var current: float = snapshot["rot"]
			var snapped  := roundf(current / 90.0) * 90.0
			var dir      := -1.0 if counter_clockwise else 1.0
			var new_rot  := snapped + 90.0 * dir
			s.rotation_degrees = roundf(fposmod(new_rot, 360.0))
			if s.has_method("set_angle"): s.set_angle(s.rotation_degrees),
		func():
			var s = snapshot["ref"]
			if not is_instance_valid(s): return
			s.rotation_degrees = snapshot["rot"]
			if s.has_method("set_angle"): s.set_angle(snapshot["rot"])
	)

func _rotate_preview(direction: int, step: float) -> void:
	_preview_rotation = roundf(_preview_rotation + step * direction)
	if is_instance_valid(_preview):
		_preview.rotation_degrees = _preview_rotation

func _rotate_preview_snap90(counter_clockwise: bool) -> void:
	var snapped  := roundf(_preview_rotation / 90.0) * 90.0
	var dir      := -1.0 if counter_clockwise else 1.0
	_preview_rotation = roundf(fposmod(snapped + 90.0 * dir, 360.0))
	if is_instance_valid(_preview):
		_preview.rotation_degrees = _preview_rotation

# --------------------------------------------- Вспомогательное

func _sprite_at(pos: Vector2) -> ObjectSprite:
	var current_mode: LevelTab.Modes = level_tab.current_mode
	var valid_sprites: Array[ObjectSprite] = []
	
	for node in (Engine.get_main_loop() as SceneTree).get_nodes_in_group("sprites"):
		if node == _preview or not (node is ObjectSprite) or not node.visible:
			continue
		if node.mode != current_mode:
			continue
		valid_sprites.append(node as ObjectSprite)
	
	valid_sprites.sort_custom(func(a: ObjectSprite, b: ObjectSprite):
		if a.z_index == b.z_index:
			return a.get_index() > b.get_index()
		return a.z_index > b.z_index
	)
	
	for spr in valid_sprites:
		if spr._hit_test(pos):
			return spr
	
	return null

func _make_hlm_object() -> HLMObject:
	var obj        := HLMObject.new()
	obj.object_id  = _object_id
	obj.sprite_id  = _sprite_id
	return obj
