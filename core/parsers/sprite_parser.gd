class_name SpriteParser

static func parse(
	raw: Dictionary,
	emit_progress: bool = true,
	override_pngs: Array = []
) -> Dictionary:
	var result: Dictionary = {}
	var keys := raw.keys().filter(func(k: String) -> bool: return k.ends_with(".meta"))
	var total := keys.size()
	var last_tick := Time.get_ticks_msec()
	
	if emit_progress:
		AppEvents.load_started.emit("LOADING_SPRITES")
	
	for idx in range(total):
		var meta_name: String = keys[idx]
		var png_name          := meta_name.replace(".meta", ".png")
		
		if not raw.has(png_name):
			continue
		
		var png_bytes: PackedByteArray = raw[png_name]
		if not _is_png(png_bytes):
			continue
		
		var atlas := Image.new()
		if atlas.load_png_from_buffer(png_bytes) != OK:
			continue
		
		var frames := _slice_meta(raw[meta_name], atlas)
		result.merge(frames, true)
		
		var now := Time.get_ticks_msec()
		if emit_progress and now - last_tick >= 50:
			AppEvents.load_progress.emit(idx, total,
				"%s" % [meta_name.replace(".meta", "")])
			await Engine.get_main_loop().process_frame
			last_tick = Time.get_ticks_msec()
	
	for png_name in override_pngs:
		if not raw.has(png_name) or not _is_png(raw[png_name]):
			continue
		var atlas := Image.new()
		if atlas.load_png_from_buffer(raw[png_name]) != OK:
			continue
		var meta_name: String = png_name.replace(".png", ".meta")
		if raw.has(meta_name):
			result.merge(_slice_meta(raw[meta_name], atlas), true)
		else:
			result[png_name.get_file().get_basename()] = [ImageTexture.create_from_image(atlas)]
	
	if emit_progress:
		AppEvents.load_finished.emit()
	
	return result

# --------------------------------------------------

static func _slice_meta(meta_bytes: PackedByteArray, atlas: Image) -> Dictionary:
	var result: Dictionary = {}
	var pos := 24
	
	while pos < meta_bytes.size():
		var name_len  := meta_bytes.decode_u8(pos);  pos += 1
		var full_name := meta_bytes.slice(pos, pos + name_len).get_string_from_ascii()
		var sprite_name := full_name.split("/")[-1]
		pos += name_len
		
		var frame_count := meta_bytes.decode_u32(pos); pos += 4
		var frames: Array[ImageTexture] = []
		
		for _i in range(frame_count):
			pos += 4
			var w := meta_bytes.decode_u32(pos); pos += 4
			var h := meta_bytes.decode_u32(pos); pos += 4
			var x := meta_bytes.decode_u32(pos); pos += 4
			var y := meta_bytes.decode_u32(pos); pos += 4
			pos += 16
			
			var region := atlas.get_region(Rect2i(x, y, w, h))
			frames.append(ImageTexture.create_from_image(region))
		
		result[sprite_name] = frames
	
	return result

static func _is_png(b: PackedByteArray) -> bool:
	return b.size() >= 4 \
		and b[0] == 0x89 and b[1] == 0x50 \
		and b[2] == 0x4E and b[3] == 0x47
