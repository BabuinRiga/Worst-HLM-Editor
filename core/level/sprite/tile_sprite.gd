class_name TileSprite
extends BaseSprite

var tile_id: int
var tile_x: int
var tile_y: int
var depth: int

func _init(_tile_id: int, _tile_x: int, _tile_y: int, _depth: int) -> void:
	tile_id = _tile_id
	tile_x = _tile_x
	tile_y = _tile_y
	depth = _depth
	mode = LevelTab.Modes.TILES
	z_index = -depth
	
	var tile := Defs.get_tile(tile_id)
	if tile == null or tile.tilemap == null:
		queue_free()
		return
	
	texture = tile.tilemap 
	
	var t_size = 16 if depth > -99 else 8
	
	region_enabled = true
	region_rect = Rect2(tile_x, tile_y, t_size, t_size)
