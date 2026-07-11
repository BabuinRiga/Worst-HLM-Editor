class_name WadLoader

static func load_wads(
	wad_paths: Array[String],
	filters: Array[String] = [],
	progress_target: Node = null
) -> Dictionary:
	var result: Dictionary = {}
	
	for i in range(wad_paths.size()):
		var path := wad_paths[i]
		var file := FileAccess.open(path, FileAccess.READ)
		if file == null:
			push_error("WadLoader: не удалось открыть файл: %s" % path)
			continue
		await _read_wad(file, result, path.get_file(), filters, progress_target)
		file.close()
	return result

# ------------------------------------------------------

static func _read_wad(
	file: FileAccess,
	result: Dictionary,
	wad_name: String,
	filters: Array[String],
	progress_target: Node
) -> void:
	file.seek(16)
	
	var locations: Dictionary = {}
	var asset_count := file.get_32()
	
	for _i in range(asset_count):
		var name_len  := file.get_32()
		var asset_name := file.get_buffer(name_len).get_string_from_ascii()
		var asset_len   := file.get_64()
		var asset_start := file.get_64()
		
		if not _passes_filters(asset_name, filters):
			continue
		
		locations[asset_name] = {"len": asset_len, "start": asset_start}
	
	_skip_directories(file)
	
	var data_start := file.get_position()
	var keys       := locations.keys()
	var total      := keys.size()
	var last_tick  := Time.get_ticks_msec()
	
	if progress_target:
		AppEvents.load_started.emit("LOADING_WAD")
	
	for idx in range(total):
		var asset_name: String   = keys[idx]
		var info: Dictionary     = locations[asset_name]
		
		file.seek(data_start + info["start"])
		result[asset_name] = file.get_buffer(info["len"])
		
		var now := Time.get_ticks_msec()
		if progress_target and now - last_tick >= 50:
			AppEvents.load_progress.emit(
				idx, total,
				"%s/%s" % [wad_name, asset_name]
			)
			await Engine.get_main_loop().process_frame
			last_tick = Time.get_ticks_msec()
	
	if progress_target:
		AppEvents.load_finished.emit()

static func _skip_directories(file: FileAccess) -> void:
	var dir_count := file.get_32()
	for _i in range(dir_count):
		var dir_name_len := file.get_32()
		file.seek(file.get_position() + dir_name_len)
		var entry_count := file.get_32()
		for _j in range(entry_count):
			var entry_name_len := file.get_32()
			file.seek(file.get_position() + 1 + entry_name_len)

static func _passes_filters(name: String, filters: Array[String]) -> bool:
	if filters.is_empty():
		return true
	return filters.any(func(p: String) -> bool: return name.match(p))
