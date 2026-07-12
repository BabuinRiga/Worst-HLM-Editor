class_name ObjectsBinParser

const OBJECTS_BIN_KEY := "GL/hlm2_objects.bin"

static func parse(raw: Dictionary, emit_progress: bool = true) -> Dictionary:
	var result: Dictionary = {}
	if not raw.has(OBJECTS_BIN_KEY):
		return result
	
	var bytes: PackedByteArray = raw[OBJECTS_BIN_KEY]
	var pos := 0
	
	var index_count := _u32(bytes, pos); pos += 4
	pos += index_count * 4
	
	var obj_count := _u32(bytes, pos); pos += 4
	var objects := []
	
	if emit_progress:
		AppEvents.load_started.emit("LOADING_OBJECTS_BIN")
	
	var last_tick := Time.get_ticks_msec()
	
	for i in range(obj_count):
		if pos + 40 > bytes.size():
			break
		var o := {}
		o["id"] = _u32(bytes, pos); pos += 4
		o["sprite_id"] = _s32(bytes, pos); pos += 4
		o["depth"] = _s32(bytes, pos); pos += 4
		o["parent"] = _s32(bytes, pos); pos += 4
		o["mask_id"] = _s32(bytes, pos); pos += 4
		o["solid"] = _u32(bytes, pos); pos += 4
		o["visible"] = _u32(bytes, pos); pos += 4
		o["persistent"] = _u32(bytes, pos); pos += 4
		o["priority"] = _u64(bytes, pos); pos += 8
		o["name_pos"] = _u32(bytes, pos); pos += 4
		objects.append(o)
		
		var now := Time.get_ticks_msec()
		if emit_progress and now - last_tick >= 50:
			AppEvents.load_progress.emit(i, obj_count, "OBJECT_BIN")
			await Engine.get_main_loop().process_frame
			last_tick = Time.get_ticks_msec()
	
	var string_map := _parse_string_map(bytes, pos)
	
	for o in objects:
		var name: String = string_map.get(o["name_pos"], "obj_%d" % o["id"])
		result[o["id"]] = {
			"object_id": o["id"],
			"object_name": name,
			"sprite_id": o["sprite_id"],
			"parent": o["parent"],
			"mask_id": o["mask_id"],
			"z_index": -o["depth"],
			"solid": o["solid"],
		}
	
	if emit_progress:
		AppEvents.load_finished.emit()
	
	return result

static func _parse_string_map(bytes: PackedByteArray, pos: int) -> Dictionary:
	var result := {}
	if pos + 4 > bytes.size():
		return result
	var total := _u32(bytes, pos); pos += 4
	var start := pos
	var end := pos + total
	while pos < end and pos < bytes.size():
		var str_start := pos - start
		var s := ""
		while pos < bytes.size() and bytes[pos] != 0:
			s += char(bytes[pos])
			pos += 1
		pos += 1
		result[str_start] = s
	return result

static func _u32(b: PackedByteArray, p: int) -> int:
	return b[p] | (b[p+1] << 8) | (b[p+2] << 16) | (b[p+3] << 24)
static func _s32(b: PackedByteArray, p: int) -> int:
	var n := _u32(b, p)
	return n if n <= 0x7FFFFFFF else n - 0x100000000
static func _u64(b: PackedByteArray, p: int) -> int:
	return _u32(b, p) | (_u32(b, p + 4) << 32)
