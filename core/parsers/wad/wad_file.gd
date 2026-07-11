class_name WadFile

var _data: PackedByteArray
var pos: int = 0

func _init(data: PackedByteArray) -> void:
	_data = data

# ---------------------------------------------------------------

func seek(p: int) -> void:
	pos = p

func skip(n: int) -> void:
	pos += n

func size() -> int:
	return _data.size()

func at_end() -> bool:
	return pos >= _data.size()

# ---------------------------------------------------------------

func get_buffer(length: int) -> PackedByteArray:
	var result := _data.slice(pos, pos + length)
	pos += length
	return result

func get_string(length: int) -> String:
	return get_buffer(length).get_string_from_ascii()

func bytes() -> PackedByteArray:
	return _data

# ---------------------------------------------------------------

func get_u8() -> int:
	var v := _data.decode_u8(pos)
	pos += 1
	return v

func get_u16() -> int:
	var v := _data.decode_u16(pos)
	pos += 2
	return v

func get_u32() -> int:
	var v := _data.decode_u32(pos)
	pos += 4
	return v

func get_u64() -> int:
	var v := _data.decode_u64(pos)
	pos += 8
	return v

# ---------------------------------------------------------------

func get_s8() -> int:
	var v := _data.decode_s8(pos)
	pos += 1
	return v

func get_s16() -> int:
	var v := _data.decode_s16(pos)
	pos += 2
	return v

func get_s32() -> int:
	var v := _data.decode_s32(pos)
	pos += 4
	return v

func get_s64() -> int:
	var v := _data.decode_s64(pos)
	pos += 8
	return v
