extends BaseSprite
class_name ElevatorSprite

const SPRITE_ID := 1512
const HM_OFFSET := Vector2(-16, 0)

var target_floor:      int
var transition_offset: Vector2i

func _init(_target_floor: int, _transition_offset: Vector2i) -> void:
	z_index           = 999
	target_floor      = _target_floor
	transition_offset = _transition_offset
	mode              = LevelTab.Modes.MAIN

func _ready() -> void:
	super._ready()
	var def := Defs.get_sprite_def(SPRITE_ID)
	if def and not def.frames.is_empty():
		texture = def.frames[-1]
		offset  = HM_OFFSET # не ебу как по другому фиксить
	flip_v = true

func _draw() -> void:
	super._draw()
	if mode != level_tab.current_mode:
		return
	if View.show_outline: draw_rect(get_rect(), Color.WHITE, false)
	if self in Selection.selected:
		if transition_offset == Vector2i.ZERO: return
		var player_def := Defs.get_sprite_def(TransitionSprite.PLAYER_SPRITE_ID)
		if player_def and not player_def.frames.is_empty():
			var p_tex = player_def.frames[0]
			var p_size = p_tex.get_size()
			var p_offset = p_size / 2.0
			var local_offset = Vector2(transition_offset)
			var exact_angle = (-local_offset).angle() if local_offset != Vector2.ZERO else 0.0
			var look_angle = snapped(exact_angle, PI / 2.0)
			draw_set_transform(local_offset, look_angle, Vector2.ONE)
			draw_texture(p_tex, -p_offset, Color(0.0, 0.8, 1.0, 0.7))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
