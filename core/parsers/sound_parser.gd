class_name SoundParser

static func parse(
	raw: Dictionary, 
	emit_progress: bool = true
) -> Dictionary:
	var result: Dictionary = {}
	var keys := raw.keys().filter(func(k: String) -> bool: return k.ends_with(".wav"))
	var total := keys.size()
	var last_tick := Time.get_ticks_msec()
	
	if emit_progress:
		AppEvents.load_started.emit("LOADING_SOUNDS")
	
	for idx in range(total):
		var asset_name: String = keys[idx]
		
		var stream := _parse_wav(raw[asset_name])
		if stream != null:
			var key := asset_name.get_file().get_basename()
			result[key] = stream
		
		var now := Time.get_ticks_msec()
		if emit_progress and now - last_tick >= 50:
			AppEvents.load_progress.emit(
				idx, 
				total,
				"%s" % [asset_name.get_file().get_basename()]
			)
			await Engine.get_main_loop().process_frame
			last_tick = Time.get_ticks_msec()
	
	if emit_progress:
		AppEvents.load_finished.emit()
	
	return result

# ----------------------------------------------

static func _parse_wav(data: PackedByteArray) -> AudioStreamWAV:
	var stream  := AudioStreamWAV.new()
	var pos     := 0
	var size    := data.size()
	
	var has_riff := false
	var has_fmt  := false
	var has_data := false
	
	while pos + 4 <= size:
		var tag := data.slice(pos, pos + 4).get_string_from_ascii()
		pos += 4
		
		match tag:
			"RIFF":
				has_riff = true
				pos += 4
			"WAVE":
				pass
			"fmt ":
				pos += 4
				if pos + 16 > size:
					break
				stream.format = data.decode_u16(pos); pos += 2
				stream.stereo = data.decode_u16(pos) == 2; pos += 2
				stream.mix_rate = data.decode_u32(pos); pos += 4
				pos += 6
				pos += 2
				has_fmt = true
			"data":
				if pos + 4 > size:
					break
				var data_len := data.decode_u32(pos); pos += 4
				stream.data = data.slice(pos, pos + data_len)
				has_data = true
				break
			_:
				pos -= 3
	
	if not (has_riff and has_fmt and has_data):
		return null
	
	return stream
