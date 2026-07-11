class_name SpritesBinParser

const SPRITES_BIN_KEY := "GL/hlm2_sprites.bin"

static func parse(raw: Dictionary, emit_progress: bool = true) -> Dictionary:
	var result: Dictionary = {}
	if not raw.has(SPRITES_BIN_KEY):
		return result
	
	var bytes: PackedByteArray = raw[SPRITES_BIN_KEY]
	var pos := 0
	
	var index_count := _u32(bytes, pos); pos += 4
	pos += index_count * 4
	
	var sprite_count := _u32(bytes, pos); pos += 4
	var entries := []
	
	if emit_progress:
		AppEvents.load_started.emit("LOADING_SPRITES_BIN")
	
	var last_tick := Time.get_ticks_msec()
	
	for i in range(sprite_count):
		if pos + 64 > bytes.size():
			break
		var e := {}
		e["id"]            = _u32(bytes, pos);                              pos += 4
		e["size"]          = Vector2i(_u32(bytes, pos), _u32(bytes, pos+4)); pos += 8
		e["center"]        = Vector2i(_s32(bytes, pos), _s32(bytes, pos+4)); pos += 8
		e["mask_x_bounds"] = Vector2i(_s32(bytes, pos), _s32(bytes, pos+4)); pos += 8
		e["mask_y_bounds"] = Vector2i(_s32(bytes, pos), _s32(bytes, pos+4)); pos += 8
		e["frame_count"]   = _u32(bytes, pos);                              pos += 4
		pos += 16
		e["name_pos"]      = _u32(bytes, pos);                              pos += 4
		pos += 4
		entries.append(e)
		
		var now := Time.get_ticks_msec()
		if emit_progress and now - last_tick >= 50:
			AppEvents.load_progress.emit(i, sprite_count, "SPRITE_BIN")
			await Engine.get_main_loop().process_frame
			last_tick = Time.get_ticks_msec()
	
	var string_map := _parse_string_map(bytes, pos)
	for e in entries:
		e["name"] = string_map.get(e["name_pos"], "spr_%d" % e["id"])
		result[e["id"]] = e
		
	if emit_progress:
		AppEvents.load_finished.emit()
	
	return result

static func _parse_string_map(bytes: PackedByteArray, pos: int) -> Dictionary:
	var result := {}
	if pos + 4 > bytes.size():
		return result
	var total := _u32(bytes, pos); pos += 4
	var start := pos
	var end   := pos + total
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
