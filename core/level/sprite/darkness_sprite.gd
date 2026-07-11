extends BaseSprite
class_name DarknessSprite

const TEXTURE = preload("uid://chwap2hcoxllk")

var darkness_rect: Rect2i

func _init(_darkness_rect: Rect2i) -> void:
	darkness_rect  = _darkness_rect
	texture        = TEXTURE
	position       = Vector2(darkness_rect.position)
	region_enabled = true
	region_rect    = Rect2(darkness_rect)
	mode           = LevelTab.Modes.MAIN

func set_coords(new_coord: Vector2) -> void:
	super.set_coords(new_coord)
	darkness_rect.position = Vector2i(position)
