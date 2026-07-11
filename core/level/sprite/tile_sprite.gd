class_name TileSprite
extends BaseSprite

var tile_id: int
var tile_x:  int
var tile_y:  int
var depth:   int

func _init(_tile_id: int, _tile_x: int, _tile_y: int, _depth: int) -> void:
	tile_id = _tile_id
	tile_x  = _tile_x
	tile_y  = _tile_y
	depth   = _depth
	mode    = LevelTab.Modes.TILES
	z_index = -depth

	var tile := Defs.get_tile(tile_id)
	if tile == null:
		push_warning("TileSprite: тайл %d не найден" % tile_id)
		queue_free()
		return
	
	texture = tile.get_texture(tile_x, tile_y)
	if texture == null:
		push_warning("TileSprite: текстура [%d %d] не найдена в тайле %d" % [tile_x, tile_y, tile_id])
		queue_free()

func _should_delete() -> bool:
	return not Input.is_key_pressed(KEY_CTRL) \
		and is_pixel_opaque(to_local(_mouse_world_pos()))
