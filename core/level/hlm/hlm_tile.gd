class_name HLMTile
extends Resource

@export var title: String = ""
@export var name: String = ""
@export var id: int = -1
@export var depth: int = 0
@export var size: int = 16

var tiles: Dictionary = {}
var view_tiles: Dictionary = {}
var tilemap: ImageTexture


func get_texture(tx: int, ty: int, view: bool = false) -> ImageTexture:
	var key := "%d %d" % [tx, ty]
	var dict := view_tiles if view else tiles
	return dict.get(key, null)
