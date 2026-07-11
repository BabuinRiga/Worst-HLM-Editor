extends BaseSprite
class_name TransitionSprite

const TEXTURE    = preload("uid://rbq7y31dg321")
const ARROW_SPRITE_ID := 286
const PLAYER_SPRITE_ID := 4283

var trigger_rect:      Rect2
var direction:         int
var target_floor:      int
var transition_offset: Vector2i

func _init(_trigger_rect: Rect2, _direction: int, _target_floor: int, _transition_offset: Vector2) -> void:
	trigger_rect      = _trigger_rect
	direction         = _direction
	target_floor      = _target_floor
	transition_offset = _transition_offset
	
	z_index        = 999
	texture        = TEXTURE
	position       = trigger_rect.position
	region_enabled = true
	region_rect    = trigger_rect
	mode           = LevelTab.Modes.MAIN

func _draw() -> void:
	var center := Vector2(trigger_rect.size / 2.0)
	var def := Defs.get_sprite_def(ARROW_SPRITE_ID)
	if def and def.frames.size() > direction:
		draw_texture(def.frames[direction], Vector2i(center) - Vector2i(6, 6))
	
	if self in Selection.selected:
		if transition_offset == Vector2i.ZERO: return
		var player_def := Defs.get_sprite_def(PLAYER_SPRITE_ID)
		if player_def and not player_def.frames.is_empty():
			var p_tex = player_def.frames[0]
			var p_size = p_tex.get_size()
			var p_offset = p_size / 2.0
			
			var spawn_pos_local = center + Vector2(transition_offset)
			var exact_angle = (-Vector2(transition_offset)).angle() if transition_offset != Vector2i.ZERO else 0.0
			var look_angle = snapped(exact_angle, PI / 2.0)
			
			draw_set_transform(spawn_pos_local, look_angle, Vector2.ONE)
			draw_texture(p_tex, -p_offset, Color(0.0, 0.8, 1.0, 0.7))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func set_coords(new_coord: Vector2):
	var delta = new_coord - global_position
	trigger_rect.position += delta
	region_rect = trigger_rect
	global_position = new_coord
	xya_changed.emit()

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
