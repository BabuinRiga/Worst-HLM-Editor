extends Node2D
class_name EditorLevel

@onready var modal_layer = get_tree().get_first_node_in_group("ModalLayer") as CanvasLayer
@onready var inspector: PanelContainer = $"../../../Inspector"

@onready var camera_2d: Camera2D = $Camera2D
@onready var border_overlay: BorderOverlay = $BorderOverlay
@onready var rain: Rain = $Camera2D/Rain

const SAVE_DOESNT_EXIST = preload("uid://cyyvgm8v200p6")

var level_info: LevelInfo
var floor_count: int = 0
var current_floor_index: int = -1
var active_floor: Floor = null
var _floor_cache: Array[Floor] = []

signal level_loaded
signal level_updated
signal floor_switched(floor: Floor)

# -------------------------------------------------

func _ready() -> void:
	inspector.visible = false
	await Assets.asset_rebuilded
	_load_resource_level("res://resources/levels/welcome")
	inspector.visible = true

func _load_resource_level(folder: String) -> void:
	var hlm_path := folder + "/level.hlm"
	if not FileAccess.file_exists(hlm_path):
		return
	
	var info := LevelInfo.new()
	info.type = LevelInfo.Type.SINGLE
	info.folder_path = folder
	info.hlm_path = hlm_path
	info.prefix = "level"
	info.cover = LevelScanner._load_cover(folder + "/level.png", true)
	info.exist = false
	info.load_hlm()
	
	load_level(info)

# -------------------------------------------------

func load_level(info: LevelInfo) -> void:
	level_info = info
	_clear_cache()
	
	ToolManager.set_tool(ToolManager.Tool.SELECT)
	
	if info.exist:
		await Assets.load_level(Assets._collect_level_paths(level_info.folder_path))
	
	_detect_floor_count()
	if floor_count == 0:
		var type_name = LevelInfo.Type.keys()[level_info.type]
		return
	for i in range(floor_count):
		_floor_cache.append(_create_floor_node(i))
	
	border_overlay.set_boundary(level_info.boundaries)
	
	switch_floor(0)
	level_loaded.emit()
	level_updated.emit()
	UndoRedoManager.mark_saved()

func save_level() -> void:
	if !level_info.exist:
		var modal = SAVE_DOESNT_EXIST.instantiate()
		modal.save_non_exist_level.connect(_save_level_non_exist)
		modal_layer.add_child(modal)
		return
	if DirAccess.dir_exists_absolute(level_info.folder_path):
		var dir := DirAccess.open(level_info.folder_path)
		if dir:
			dir.list_dir_begin()
			var file_name := dir.get_next()
			while file_name != "":
				if not dir.current_is_dir() and file_name != "campaign.cpg":
					
					if level_info.type == LevelInfo.Type.SINGLE:
						if file_name.begins_with(level_info.prefix) or file_name == "level.hlm" or file_name == "level.png":
							dir.remove(file_name)
					else:
						if file_name == level_info.prefix + ".hlm" or \
						   file_name == level_info.prefix + ".png" or \
						   file_name.begins_with(level_info.prefix + "_"):
							dir.remove(file_name)
							
				file_name = dir.get_next()
			dir.list_dir_end()
	
	for floor_node in _floor_cache:
		if floor_node.cutscene_files:
			level_info.cutscene = true
			break
	level_info.floors = floor_count - 1
	level_info.save_hlm()
	level_info.save_ver()
	
	if level_info.cover:
		if level_info.type == LevelInfo.Type.CAMPAIGN_LEVEL and !level_info.prefix.begins_with("main"): return
		var img := level_info.cover.get_image()
		if img:
			var cover_path := level_info.folder_path + "/" + level_info.prefix + ".png"
			if level_info.type == LevelInfo.Type.SINGLE:
				cover_path = level_info.folder_path + "/level.png"
			img.save_png(cover_path)
	
	for floor_node in _floor_cache:
		var base := _base_path(floor_node.index)
		floor_node.save_floor(base, level_info)
		floor_node.save_cutscene_files(base)
	
	level_updated.emit()
	UndoRedoManager.mark_saved()

func _save_level_non_exist() -> void:
	var new_folder_name := _generate_uuid_v4()
	
	var single_path := LevelScanner.single_levels_path()
	var new_folder_path := single_path + "/" + new_folder_name
	
	DirAccess.make_dir_recursive_absolute(new_folder_path)
	
	level_info.folder_path = new_folder_path
	level_info.hlm_path = new_folder_path + "/" + level_info.prefix + ".hlm"
	level_info.exist = true
	save_level()

# -------------------------------------------------

func switch_floor(floor_index: int) -> bool:
	if floor_index < 0 or floor_index >= floor_count: return false
	if floor_index == current_floor_index: return true
	
	var previous_floor := active_floor
	
	if active_floor != null:
		remove_child(active_floor)
	
	active_floor = _floor_cache[floor_index]
	current_floor_index = floor_index
	active_floor.previous_floor = previous_floor
	add_child(active_floor)
	floor_switched.emit(active_floor)
	return true

func add_floor() -> void:
	var new_index := floor_count
	floor_count += 1
	var floor_node := _create_floor_node(new_index)
	_floor_cache.append(floor_node)
	switch_floor(new_index)

func del_floor() -> void:
	if floor_count == 0 or current_floor_index < 0:
		return
	
	if floor_count <= 1:
		return
	
	var deleted_index := current_floor_index
	
	if active_floor != null:
		remove_child(active_floor)
		active_floor.queue_free()
		active_floor = null
	
	_floor_cache.remove_at(deleted_index)
	floor_count = maxi(floor_count - 1, 0)
	
	for i in range(_floor_cache.size()):
		_floor_cache[i].index = i
		_floor_cache[i].name = "Floor%d" % i
	
	current_floor_index = -1
	
	if floor_count > 0:
		var next_index := mini(deleted_index, floor_count - 1)
		switch_floor(next_index)

# -------------------------------------------------

func get_floor_count() -> int:
	return floor_count

func get_current_floor_index() -> int:
	return current_floor_index

func get_active_floor() -> Floor:
	return active_floor

# -------------------------------------------------

func update_boundary(rect: Rect2i) -> void:
	level_info.boundaries = rect
	border_overlay.set_boundary(rect)

# -------------------------------------------------

func _base_path(idx: int) -> String:
	if level_info.type == LevelInfo.Type.SINGLE:
		return "%s/%s%d" % [level_info.folder_path, level_info.prefix, idx]
	else:
		return "%s/%s_%d" % [level_info.folder_path, level_info.prefix, idx]

func _detect_floor_count() -> void:
	floor_count = 0
	const REQUIRED_EXTENSIONS := ["tls", "obj", "play"]
	
	while true:
		var base := _base_path(floor_count)
		var has_required_file := false
		
		for ext in REQUIRED_EXTENSIONS:
			if FileAccess.file_exists(base + "." + ext):
				has_required_file = true
				break
		
		if has_required_file:
			floor_count += 1
		else:
			break

func _create_floor_node(floor_index: int) -> Floor:
	var floor_node := Floor.new(floor_index)
	var base := _base_path(floor_index)
	
	for ext in ["tls", "obj", "wll", "play", "npc", "itm", "csf"]:
		var file_path: String = base + "." + ext
		if FileAccess.file_exists(file_path):
			floor_node.load_floor(file_path, level_info.type)
	
	return floor_node

func _clear_cache() -> void:
	if active_floor != null:
		remove_child(active_floor)
		active_floor = null
	
	for floor_node in _floor_cache:
		floor_node.previous_floor = null
		floor_node.queue_free()
	
	_floor_cache.clear()
	floor_count = 0
	current_floor_index = -1

func _generate_uuid_v4() -> String:
	var uuid := ""
	for i in range(16):
		if i == 4 or i == 6 or i == 8 or i == 10:
			uuid += "-"
		
		var byte := randi() % 256
		
		if i == 6:
			byte = (byte & 0x0f) | 0x40
		elif i == 8:
			byte = (byte & 0x3f) | 0x80
			
		uuid += "%02x" % byte
	
	return uuid
