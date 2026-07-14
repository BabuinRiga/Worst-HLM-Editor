class_name Floor
extends Node2D

@onready var top_bar = get_tree().get_first_node_in_group("TopBar") as TopBar
@onready var editor_level = get_tree().get_first_node_in_group("EditorLevel") as EditorLevel

var index: int  = 0
var light_overlays: Array[int] = []
var static_objects: Array[int] = []
var previous_floor: Floor = null

var cutscene_files: Dictionary = {}

const SUNSET_OVERLAY: int = 0
const DAYLIGHT_OVERLAY: int = 1
const WALL_HINT_COLOR: Color = Color(0, 1, 0, 0.4)
const TRANSITION_HINT_COLOR: Color = Color(1, 0, 0, 0.2)

const CUTSCENE_EXTENSIONS: Array[String] = ["npc", "itm", "csf"]

# -------------------------------------------------------

func _init(_index: int = 0) -> void:
	index = _index
	name = "Floor%d" % index
	z_index = 99

func _ready() -> void:
	editor_level.floor_switched.connect(_on_floor_switched)
	top_bar.view.view_updated.connect(queue_redraw)

# ------------------------------------------------------- Загрузка

func load_level_from_info(level_info: LevelInfo) -> bool:
	return load_floor(level_info.hlm_path, level_info.type)

func load_floor(floor_path: String, level_type: LevelInfo.Type) -> bool:
	var ext := floor_path.get_extension()
	
	if ext in CUTSCENE_EXTENSIONS:
		return _load_cutscene_file(floor_path, ext)
	
	var file := FileAccess.open(floor_path, FileAccess.READ)
	if file == null or file.get_length() == 0:
		return false
	
	match ext:
		"obj":  _load_obj(file)
		"tls":  _load_tls(file)
		"wll":  _load_wll(file)
		"play": _load_play(file, level_type)
	
	file.close()
	return true

func _load_cutscene_file(file_path: String, ext: String) -> bool:
	var file := FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		return false
	
	cutscene_files[ext] = file.get_buffer(file.get_length())
	file.close()
	return true

# ------------------------------------------------------- Парсеры

func _load_tls(file: FileAccess) -> void:
	while not file.eof_reached():
		var row := _read_lines(file, 6)
		if row.is_empty():
			break
		
		var tile_id := int(row[0])
		var tile_x := int(row[1])
		var tile_y := int(row[2])
		var x := int(row[3])
		var y := int(row[4])
		var depth := int(row[5])
		
		var spr := TileSprite.new(tile_id, tile_x, tile_y, depth)
		spr.global_position = Vector2(x, y)
		spr.level = index
		add_child(spr)

func _load_wll(file: FileAccess) -> void:
	while not file.eof_reached():
		var row := _read_lines(file, 5)
		if row.is_empty():
			break
		
		var object_id := int(row[0])
		var x := float(row[1])
		var y := float(row[2])
		var sprite_id := int(row[3])
		
		var spr = WallSprite.new(object_id, sprite_id)
		spr.global_position = Vector2(x, y) - spr.wall_offset
		add_child(spr)

func _load_obj(file: FileAccess) -> void:
	while not file.eof_reached():
		var parent_id_line := file.get_line().strip_edges()
		if parent_id_line.is_empty():
			break
		
		var parent_id := int(parent_id_line.split("\t")[0])
		var count := _get_obj_param_count(parent_id, file)
		var row := _read_lines(file, count)
		
		if row.is_empty() and count > 0:
			break
		
		_parse_obj_entry(parent_id, row)

func _load_play(file: FileAccess, level_type: LevelInfo.Type) -> void:
	file.get_line()
	file.get_line()
	
	while not file.eof_reached():
		var id_line := file.get_line().strip_edges()
		if id_line.is_empty():
			break
	
		var object_id := int(id_line.split("\t")[0])
		var count := _get_play_param_count(object_id, file)
		var row := _read_lines(file, count)
		
		if row.is_empty() and count > 0:
			break
		
		if level_type == LevelInfo.Type.CAMPAIGN_LEVEL:
			_parse_play_entry_campaign(object_id, row)

# ------------------------------------------------------- Спавн объектов

func _spawn_object_sprite(
	obj: HLMObject,
	sprite_id: int,
	frame: float,
	pos: Vector2,
	angle_deg: float,
	parent_id: int
) -> ObjectSprite:
	var dup := obj.duplicate() as HLMObject
	dup.sprite_id = sprite_id
	var spr: ObjectSprite
	if obj.object_id == NPCObjectSprite.NPCobjectID:
		spr = NPCObjectSprite.new(dup, frame, _get_mode_for_object(obj.object_id, parent_id))
	else:
		spr = ObjectSprite.new(dup, frame, _get_mode_for_object(obj.object_id, parent_id))
	spr.global_position = pos
	spr.rotation_degrees = angle_deg
	spr.level = index
	add_child(spr)
	return spr

func _get_mode_for_object(object_id: int, parent_id: int) -> int:
	if parent_id == 10 or object_id in EnemyTab.enemy_ids:
		return LevelTab.Modes.ENEMY
	if object_id in MiscTab.weapon_ids:
		return LevelTab.Modes.MISC
	if parent_id == 1582 or parent_id == 1583 or object_id in MainTab.player_ids or object_id in MainTab.car_ids:
		return LevelTab.Modes.MAIN
	return LevelTab.Modes.OBJECTS

func _get_transition_markers() -> Array:
	return get_children().filter(func(c): return c is TransitionSprite)

func _get_elevator_markers() -> Array:
	return get_children().filter(func(c): return c is ElevatorSprite)

# ------------------------------------------------------- Вспомогательные

func _read_lines(file: FileAccess, count: int) -> Array[String]:
	var result: Array[String] = []
	for _i in range(count):
		if file.eof_reached():
			return []
		var line := file.get_line()
		if line.is_empty():
			return []
		result.append(line)
	return result

func _get_obj_param_count(parent_id: int, _file: FileAccess) -> int:
	match parent_id:
		2297: return 9  # Transition
		2410: return 6  # Elevator
		2411: return 4  # Barrier
		2412: return 7  # Entry
		1417: return 4  # Darkness
		1770: return 1  # Light overlay
		663:
			var n := int(_file.get_line())
			return n * 4
		_:    return 6  # Default object

func _get_play_param_count(object_id: int, file: FileAccess) -> int:
	match object_id:
		124:  return 9  # Transition
		810:  return 6  # Elevator
		2411: return 4  # Barrier
		1417: return 4  # Darkness
		302, 303: return 5  # Entry
		663:  # Rain
			var n := int(file.get_line())
			return n * 4
		1770: return 1  # Light overlay
		_:
			if object_id in DoorSprite.object_ids:
				return 6
			if object_id in TilesTab.wall_ids:
				return 5
			return 5

func _parse_obj_entry(parent_id: int, row: Array[String]) -> void:
	match parent_id:
		2297: _create_transition_obj(row)
		2410: _create_elevator_obj(row)
		2411: _create_barrier_obj(row)
		2412: _create_entry_obj(row)
		1417: _create_darkness_obj(row)
		1770: _add_light_overlay(int(row[0]))
		663:  _create_rain_obj(row)
		_:
			if parent_id in DoorSprite.object_ids:
				_create_door_obj(parent_id, row)
			else:
				_create_generic_object(parent_id, row)

func _parse_play_entry_campaign(object_id: int, row: Array[String]) -> void:
	match object_id:
		-1, 0, 1:
			pass
		124:
			_create_transition_obj(row)
		810:
			_create_elevator_obj(row)
		2411:
			_create_barrier_obj(row)
		1417:
			_create_darkness_obj(row)
		663:
			_create_rain_obj(row)
		1770:
			if row.size() > 0:
				_add_light_overlay(int(row[0]))
		302, 303:
			var trigger_rect = Rect2(int(row[0]), int(row[1]), int(float(row[2]) * 16), int(float(row[3]) * 16))
			var mul_direction = max(min(int(row[4]), 1), -1)
			
			var direction = 0
			if object_id == 302:
				direction = 0 if mul_direction == 1 else 2
			else:
				direction = 3 if mul_direction == 1 else 1
			
			var spr = EntrySprite.new(trigger_rect, direction)
			spr.level = index
			add_child(spr)
		_:
			if object_id in DoorSprite.object_ids:
				if row.size() >= 6:
					var spr := DoorSprite.new(object_id, int(row[4]), int(row[5]))
					spr.level = index
					spr.position = Vector2(float(row[0]), float(row[1]))
					add_child(spr)
				return
			
			if object_id in TilesTab.wall_ids:
				if row.size() >= 3:
					var x = float(row[0])
					var y = float(row[1])
					var sprite_id = int(row[2])
					
					var spr = WallSprite.new(object_id, sprite_id)
					spr.global_position = Vector2(x, y) - spr.wall_offset
					spr.level = index
					add_child(spr)
				return
			
			if row.size() >= 5:
				var x = float(row[0])
				var y = float(row[1])
				var sprite_id = int(row[2])
				var angle = -int(row[3])
				var frame = float(row[4])
				
				var obj = Defs.get_object(object_id)
				if obj != null:
					_spawn_object_sprite(obj, sprite_id, frame, Vector2(x, y), angle, 11)

# ------------------------------------------------------- Создание объектов

func _create_transition_obj(row: Array[String]) -> void:
	var trigger_rect = Rect2(int(row[0]), int(row[1]), int(float(row[2]) * 16), int(float(row[3]) * 16))
	trigger_rect.position -= trigger_rect.size / 2
	var hor = max(min(int(row[4]), 1), -1)
	var ver = max(min(int(row[5]), 1), -1)
	var direction = _calc_direction(hor, ver)
	var target_floor = int(row[6])
	var transition_offset = Vector2(int(row[7]), int(row[8]))
	
	var spr = TransitionSprite.new(trigger_rect, direction, target_floor, transition_offset)
	spr.level = index
	add_child(spr)

func _create_elevator_obj(row: Array[String]) -> void:
	var target_floor = int(row[3])
	var transition_offset = Vector2(int(row[4]), int(row[5])).rotated(deg_to_rad(-int(row[2])))
	var spr = ElevatorSprite.new(target_floor, transition_offset)
	spr.level = index
	spr.global_position = Vector2(float(row[0]), float(row[1]))
	spr.global_rotation_degrees = -int(row[2])
	add_child(spr)

func _create_barrier_obj(row: Array[String]) -> void:
	var spr = BarrierSprite.new(float(row[2]))
	spr.level = index
	spr.global_position = Vector2(float(row[0]), float(row[1]))
	spr.global_rotation_degrees = -int(row[3])
	add_child(spr)

func _create_entry_obj(row: Array[String]) -> void:
	var trigger_rect = Rect2(int(row[0]), int(row[1]), int(float(row[2]) * 16), int(float(row[3]) * 16))
	var hor = max(min(int(row[5]), 1), -1)
	var ver = max(min(int(row[6]), 1), -1)
	var direction = _calc_direction(hor, ver)
	
	var spr = EntrySprite.new(trigger_rect, direction)
	spr.level = index
	add_child(spr)

func _create_darkness_obj(row: Array[String]) -> void:
	var spr = DarknessSprite.new(Rect2i(int(row[0]), int(row[2]), int(row[1]) - int(row[0]), int(row[3]) - int(row[2])))
	spr.level = index
	add_child(spr)

func _create_rain_obj(row: Array[String]) -> void:
	for i in range(0, row.size(), 4):
		if i + 3 >= row.size():
			break
		
		var x1 = int(row[i])
		var x2 = int(row[i+1])
		var y1 = int(row[i+2])
		var y2 = int(row[i+3])
		
		var rect = Rect2(x1, y1, x2 - x1, y2 - y1)
		
		var spr = RainSprite.new(rect)
		spr.level = index
		add_child(spr)

func _create_door_obj(parent_id: int, row: Array[String]) -> void:
	var spr = DoorSprite.new(parent_id, int(row[4]), int(row[5]))
	spr.level = index
	spr.position = Vector2(float(row[0]), float(row[1]))
	add_child(spr)

func _create_generic_object(parent_id: int, row: Array[String]) -> void:
	var x = float(row[0])
	var y = float(row[1])
	var sprite_id = int(row[2])
	var angle = -int(row[3])
	var object_id = int(row[4])
	var frame = float(row[5])
	
	var obj = Defs.get_object(object_id)
	if obj == null:
		return
	
	_spawn_object_sprite(obj, sprite_id, frame, Vector2(x, y), angle, parent_id)

func _add_light_overlay(id: int) -> void:
	light_overlays.append(id)

func _calc_direction(hor: int, ver: int) -> int:
	if hor == 0 and ver == -1: return 1
	if hor == -1 and ver == 0: return 2
	if hor == 0 and ver == 1:  return 3
	return 0

# ------------------------------------------------------- Дождь

func _update_rain() -> void:
	if not is_inside_tree():
		return
	var rain_zones = get_rain_rects()
	if editor_level:
		editor_level.rain.no_rain_zone = rain_zones
		editor_level.rain.toggle_rain(not rain_zones.is_empty())

func get_rain_rects() -> Array[Rect2]:
	var rects: Array[Rect2] = []
	for child in get_children():
		if child is RainSprite:
			rects.append(child.rain_rect)
	return rects

func has_rain() -> bool:
	return get_children().any(func(c): return c is RainSprite)

func _on_floor_switched(new_floor: Floor) -> void:
	editor_level.rain.no_rain_zone = new_floor.get_rain_rects()
	editor_level.rain.toggle_rain(not new_floor.get_rain_rects().is_empty())

# ------------------------------------------------------- Сохранение

func save_floor(base_path: String, level_info: LevelInfo) -> void:
	var tiles_list: Array[Node] = []
	var walls_list: Array[Node] = []
	var general_objects: Array[Node] = []
	
	for child in get_children():
		if child.get_meta("preview", false) == true:
			continue
		if child is TileSprite:
			tiles_list.append(child)
		elif child is WallSprite:
			walls_list.append(child)
		else:
			general_objects.append(child)
	
	#walls_list.sort_custom(func(a: WallSprite, b: WallSprite) -> bool:
		#if not is_equal_approx(a.global_position.y, b.global_position.y):
			#return a.global_position.y < b.global_position.y
		#return a.global_position.x < b.global_position.x
	#)
	
	var fmt = func(v: float) -> String:
		return str(int(v)) if is_equal_approx(fmod(v, 1.0), 0.0) else str(v)
	
	# ------------------------------------------------------- ТАЙЛЫ
	
	var tls_file := FileAccess.open(base_path + ".tls", FileAccess.WRITE)
	if tls_file:
		for tile: TileSprite in tiles_list:
			tls_file.store_line(str(tile.tile_id))
			tls_file.store_line(str(tile.tile_x))
			tls_file.store_line(str(tile.tile_y))
			tls_file.store_line(fmt.call(int(tile.global_position.x)))
			tls_file.store_line(fmt.call(int(tile.global_position.y)))
			tls_file.store_line(str(tile.depth))
		tls_file.close()
	
	# ------------------------------------------------------- СТЕНЫ
	
	if level_info.type == LevelInfo.Type.SINGLE:
		var wll_file := FileAccess.open(base_path + ".wll", FileAccess.WRITE)
		if wll_file:
			for wall: WallSprite in walls_list:
				var offset: Vector2 = wall.wall_offset
				var orig_pos := wall.global_position + offset
				
				wll_file.store_line(str(wall.object_id))
				wll_file.store_line(fmt.call(orig_pos.x))
				wll_file.store_line(fmt.call(orig_pos.y))
				wll_file.store_line(str(wall.sprite_id))
				wll_file.store_line("0")
			wll_file.close()
	
	# ------------------------------------------------------- ОБЪЕКТЫ
	
	if level_info.type == LevelInfo.Type.SINGLE:
		var obj_file := FileAccess.open(base_path + ".obj", FileAccess.WRITE)
		if obj_file:
			for overlay_id in light_overlays:
				obj_file.store_line("1770")
				obj_file.store_line(str(overlay_id))
			
			var rain_sprites := general_objects.filter(func(c): return c is RainSprite)
			if not rain_sprites.is_empty():
				obj_file.store_line("663")
				obj_file.store_line(str(rain_sprites.size()))
				for rain_node in rain_sprites:
					var r: Rect2 = rain_node.rain_rect
					obj_file.store_line(fmt.call(int(r.position.x)))
					obj_file.store_line(fmt.call(int(r.position.x + r.size.x)))
					obj_file.store_line(fmt.call(int(r.position.y)))
					obj_file.store_line(fmt.call(int(r.position.y + r.size.y)))
			
			for obj in general_objects:
				if obj is RainSprite: 
					continue
				
				if obj is TransitionSprite:
					obj_file.store_line("2297")
					var center_pos: Vector2 = obj.trigger_rect.position + (obj.trigger_rect.size / 2.0)
					obj_file.store_line(fmt.call(int(center_pos.x)))
					obj_file.store_line(fmt.call(int(center_pos.y)))
					obj_file.store_line(fmt.call(obj.trigger_rect.size.x / 16.0))
					obj_file.store_line(fmt.call(obj.trigger_rect.size.y / 16.0))
					
					var hor := 0; var ver := 0
					match obj.direction:
						0: hor = 1; ver = 0
						1: hor = 0; ver = -1
						2: hor = -1; ver = 0
						3: hor = 0; ver = 1
					obj_file.store_line(str(hor))
					obj_file.store_line(str(ver))
					obj_file.store_line(str(obj.target_floor))
					obj_file.store_line(fmt.call(int(obj.transition_offset.x)))
					obj_file.store_line(fmt.call(int(obj.transition_offset.y)))
				
				elif obj is ElevatorSprite:
					obj_file.store_line("2410")
					obj_file.store_line(fmt.call(obj.global_position.x))
					obj_file.store_line(fmt.call(obj.global_position.y))
					obj_file.store_line(fmt.call(-int(obj.global_rotation_degrees)))
					obj_file.store_line(str(obj.target_floor))
					var orig_offset := Vector2(obj.transition_offset).rotated(deg_to_rad(obj.global_rotation_degrees))
					obj_file.store_line(fmt.call(int(orig_offset.x)))
					obj_file.store_line(fmt.call(int(orig_offset.y)))
				
				elif obj is BarrierSprite:
					obj_file.store_line("2411")
					obj_file.store_line(fmt.call(obj.global_position.x))
					obj_file.store_line(fmt.call(obj.global_position.y))
					obj_file.store_line(fmt.call(obj.lenght))
					obj_file.store_line(fmt.call(-int(obj.global_rotation_degrees)))
				
				elif obj is EntrySprite:
					obj_file.store_line("2412")
					obj_file.store_line(fmt.call(int(obj.trigger_rect.position.x)))
					obj_file.store_line(fmt.call(int(obj.trigger_rect.position.y)))
					obj_file.store_line(fmt.call(obj.trigger_rect.size.x / 16.0))
					obj_file.store_line(fmt.call(obj.trigger_rect.size.y / 16.0))
					obj_file.store_line("0")
					var hor := 0; var ver := 0
					match obj.direction:
						0: hor = 1; ver = 0
						1: hor = 0; ver = -1
						2: hor = -1; ver = 0
						3: hor = 0; ver = 1
					obj_file.store_line(str(hor))
					obj_file.store_line(str(ver))
				
				elif obj is DarknessSprite:
					obj_file.store_line("1417")
					obj_file.store_line(fmt.call(obj.region_rect.position.x))
					obj_file.store_line(fmt.call(obj.region_rect.position.x + obj.region_rect.size.x))
					obj_file.store_line(fmt.call(obj.region_rect.position.y))
					obj_file.store_line(fmt.call(obj.region_rect.position.y + obj.region_rect.size.y))
				
				elif obj is DoorSprite:
					obj_file.store_line(str(obj.object_id))
					obj_file.store_line(fmt.call(obj.position.x))
					obj_file.store_line(fmt.call(obj.position.y))
					obj_file.store_line(str(obj.sprite_id))
					obj_file.store_line(str(0))
					obj_file.store_line(str(obj.locked))
					obj_file.store_line(str(obj.cutscene))
				
				elif obj is ObjectSprite:
					var parent_id = _get_parent_id_by_object_id(obj.object.object_id)
					
					obj_file.store_line(str(parent_id))
					obj_file.store_line(fmt.call(obj.global_position.x))
					obj_file.store_line(fmt.call(obj.global_position.y))
					obj_file.store_line(str(obj.object.sprite_id))
					obj_file.store_line(fmt.call(-int(obj.rotation_degrees)))
					obj_file.store_line(str(obj.object.object_id))
					if obj is NPCObjectSprite:
						obj_file.store_line(str(float(obj.object_frame)))
					else:
						obj_file.store_line(str(int(obj.object_frame)))
			
			obj_file.close()
	
	# ------------------------------------------------------- PLAY
	
	var play_file := FileAccess.open(base_path + ".play", FileAccess.WRITE)
	if play_file:
		play_file.store_line(str(level_info.character_id))
		play_file.store_line(str(level_info.mask_id))
		
		for overlay_id in light_overlays:
			play_file.store_line("1770")
			play_file.store_line(str(overlay_id))
		
		var rain_sprites := general_objects.filter(func(c): return c is RainSprite)
		if not rain_sprites.is_empty():
			play_file.store_line("663")
			play_file.store_line(str(rain_sprites.size()))
			for rain_node in rain_sprites:
				var r: Rect2 = rain_node.rain_rect
				play_file.store_line(fmt.call(int(r.position.x)))
				play_file.store_line(fmt.call(int(r.position.x + r.size.x)))
				play_file.store_line(fmt.call(int(r.position.y)))
				play_file.store_line(fmt.call(int(r.position.y + r.size.y)))
		
		for wall: WallSprite in walls_list:
			var offset: Vector2 = wall.wall_offset
			var orig_pos := wall.global_position + offset
			
			play_file.store_line(str(wall.object_id))
			play_file.store_line(fmt.call(orig_pos.x))
			play_file.store_line(fmt.call(orig_pos.y))
			play_file.store_line(str(wall.sprite_id))
			play_file.store_line("0")
			play_file.store_line("0")
		
		for obj in general_objects:
			if obj is RainSprite: 
				continue
			
			if obj is TransitionSprite:
				play_file.store_line("124")
				var center_pos: Vector2 = obj.trigger_rect.position + (obj.trigger_rect.size / 2.0)
				play_file.store_line(fmt.call(int(center_pos.x)))
				play_file.store_line(fmt.call(int(center_pos.y)))
				play_file.store_line(fmt.call(obj.trigger_rect.size.x / 16.0))
				play_file.store_line(fmt.call(obj.trigger_rect.size.y / 16.0))
				var hor := 0; var ver := 0
				match obj.direction:
					0: hor = 1; ver = 0
					1: hor = 0; ver = -1
					2: hor = -1; ver = 0
					3: hor = 0; ver = 1
				play_file.store_line(str(hor))
				play_file.store_line(str(ver))
				play_file.store_line(str(obj.target_floor))
				play_file.store_line(fmt.call(int(obj.transition_offset.x)))
				play_file.store_line(fmt.call(int(obj.transition_offset.y)))
			
			elif obj is ElevatorSprite:
				play_file.store_line("810")
				play_file.store_line(fmt.call(obj.global_position.x))
				play_file.store_line(fmt.call(obj.global_position.y))
				play_file.store_line(fmt.call(-int(obj.global_rotation_degrees)))
				play_file.store_line(str(obj.target_floor))
				var orig_offset := Vector2(obj.transition_offset).rotated(deg_to_rad(obj.global_rotation_degrees))
				play_file.store_line(fmt.call(int(orig_offset.x)))
				play_file.store_line(fmt.call(int(orig_offset.y)))
			
			elif obj is BarrierSprite:
				play_file.store_line("2411")
				play_file.store_line(fmt.call(obj.global_position.x))
				play_file.store_line(fmt.call(obj.global_position.y))
				var length_val = obj.lenght
				play_file.store_line(str(length_val))
				play_file.store_line(fmt.call(-int(obj.global_rotation_degrees)))
			
			elif obj is EntrySprite:
				var object_id = 302 if (obj.direction == 0 or obj.direction == 2) else 303
				play_file.store_line(str(object_id))
				play_file.store_line(fmt.call(int(obj.trigger_rect.position.x)))
				play_file.store_line(fmt.call(int(obj.trigger_rect.position.y)))
				play_file.store_line(fmt.call(obj.trigger_rect.size.x / 16.0))
				play_file.store_line(fmt.call(obj.trigger_rect.size.y / 16.0))
				var mul_direction = 1 if (obj.direction == 0 or obj.direction == 3) else -1
				play_file.store_line(str(mul_direction))
			
			elif obj is DarknessSprite:
				play_file.store_line("1417")
				play_file.store_line(fmt.call(obj.region_rect.position.x))
				play_file.store_line(fmt.call(obj.region_rect.position.x + obj.region_rect.size.x))
				play_file.store_line(fmt.call(obj.region_rect.position.y))
				play_file.store_line(fmt.call(obj.region_rect.position.y + obj.region_rect.size.y))
			
			elif obj is DoorSprite:
				var object_id = obj.object_id
				play_file.store_line(str(object_id))
				play_file.store_line(fmt.call(obj.position.x))
				play_file.store_line(fmt.call(obj.position.y))
				play_file.store_line(str(obj.sprite_id))
				play_file.store_line(str(0))
				play_file.store_line(str(obj.locked))
				play_file.store_line(str(obj.cutscene))
			
			elif obj is ObjectSprite:
				play_file.store_line(str(obj.object.object_id))
				play_file.store_line(fmt.call(obj.global_position.x))
				play_file.store_line(fmt.call(obj.global_position.y))
				play_file.store_line(str(obj.object.sprite_id))
				play_file.store_line(fmt.call(-int(obj.rotation_degrees)))
				if obj is NPCObjectSprite:
					play_file.store_line(str(float(obj.object_frame)))
				else:
					play_file.store_line(str(int(obj.object_frame)))
		
		play_file.close()

func save_cutscene_files(base_path: String) -> void:
	for ext in cutscene_files.keys():
		var bytes: PackedByteArray = cutscene_files[ext]
		var file := FileAccess.open("%s.%s" % [base_path, ext], FileAccess.WRITE)
		if file == null:
			continue
		file.store_buffer(bytes)
		file.close()

func _get_parent_id_by_object_id(object_id: int) -> int:
	if object_id == NPCObjectSprite.NPCobjectID:
		return 2406
	if object_id in EnemyTab.enemy_ids:
		return 10
	if object_id in MainTab.player_ids:
		return 1582
	if object_id in MainTab.car_ids:
		return 1583
	if object_id in MiscTab.weapon_ids:
		return 2401
	return 11

# ------------------------------------------------------- Draw

func _draw() -> void:
	_draw_walls()
	_draw_transition_targets()

func _draw_walls() -> void:
	if not View.wall_hint: return
	if previous_floor == null: return
	
	for obj in previous_floor.get_children():
		if obj is WallSprite:
			draw_rect(Rect2(obj.global_position, obj.get_rect().size), WALL_HINT_COLOR)

func _draw_transition_targets() -> void:
	var parent_node = get_parent()
	if not parent_node: return
	
	var player_def = Defs.get_sprite_def(TransitionSprite.PLAYER_SPRITE_ID)
	if not player_def or player_def.frames.is_empty(): return
	var p_tex = player_def.frames[0]
	var p_size = p_tex.get_size()
	var p_offset = p_size / 2.0
	
	for sibling: Floor in editor_level._floor_cache:
		if sibling == self:
			continue
		
		for marker: TransitionSprite in sibling._get_transition_markers():
			if marker.transition_offset == Vector2i.ZERO: continue
			if marker.target_floor == self.index:
				var center := Vector2(marker.trigger_rect.size) / 2.0
				var spawn_pos = marker.position + center + Vector2(marker.transition_offset)
				var exact_angle = (-Vector2(marker.transition_offset)).angle()
				var look_angle = snapped(exact_angle, PI / 2.0)
				
				draw_set_transform(spawn_pos, look_angle, Vector2.ONE)
				draw_texture(p_tex, -p_offset, Color(1, 1, 1, 0.7))
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		
		for marker: ElevatorSprite in sibling._get_elevator_markers():
			if marker.transition_offset == Vector2i.ZERO: continue
			if marker.target_floor == self.index:
				var local_offset = Vector2(marker.transition_offset).rotated(marker.rotation)
				var spawn_pos = marker.position + local_offset
				var exact_angle = (-local_offset).angle()
				var look_angle = snapped(exact_angle, PI / 2.0)
				
				draw_set_transform(spawn_pos, look_angle, Vector2.ONE)
				draw_texture(p_tex, -p_offset, Color(1.0, 1.0, 1.0, 0.7))
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
