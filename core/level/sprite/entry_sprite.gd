extends BaseSprite
class_name EntrySprite

const TEXTURE         = preload("uid://bekboxgxg8qyn")
const ARROW_SPRITE_ID := 286

var trigger_rect: Rect2
var direction:    int

func _init(_trigger_rect: Rect2, _direction: int) -> void:
	trigger_rect = _trigger_rect
	direction    = _direction
	
	texture        = TEXTURE
	position       = trigger_rect.position
	region_enabled = true
	region_rect    = trigger_rect
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	mode           = LevelTab.Modes.TILES

func _draw() -> void:
	var def := Defs.get_sprite_def(ARROW_SPRITE_ID)
	if def and def.frames.size() > direction:
		draw_texture(def.frames[direction], trigger_rect.size / 2.0 - Vector2(6, 6))

func _hit_test(world_pos: Vector2) -> bool:
	return trigger_rect.has_point(world_pos)

func get_ver_direction() -> int:
	if direction == 1: return -1
	if direction == 3: return 1
	return 0

func get_hor_direction() -> int:
	if direction == 2: return -1
	if direction == 0: return 1
	return 0
