class_name ObjectSprite
extends BaseSprite

var object:       HLMObject
var object_frame: float  = 0.0
var comment:      String = ""

var _moving:           bool    = false
var _move_start_pos:   Vector2
var _move_delta:       Vector2

var patrol_path_points: Array = []

signal sprite_changed

# -------------------------------------------------

func _init(_object: HLMObject, _frame: float, _mode: int) -> void:
	if _object == null: return
	object       = _object.duplicate() as HLMObject
	object_frame = _frame
	mode         = _mode
	z_index      = object.z_index
	_apply_sprite()

# -------------------------------------------------

func _draw() -> void:
	super._draw()
	if mode != level_tab.current_mode:
		return
	if View.show_pivot: draw_circle(Vector2.ZERO, 2, Color.YELLOW)
	if View.show_outline: draw_rect(get_rect(), Color.WHITE, false)

# -------------------------------------------------

func set_ids(new_object_id: int, new_sprite_id: int, new_frame: float) -> void:
	object.object_id   = new_object_id
	object.sprite_id   = new_sprite_id
	object.object_name = ""
	object_frame       = new_frame
	_apply_sprite()
	queue_redraw()
	sprite_changed.emit()

# -------------------------------------------------

func _apply_sprite() -> void:
	var def := Defs.get_sprite_def(object.sprite_id)
	if def == null or def.frames.is_empty():
		return
	var idx := clampi(object_frame, 0, def.frames.size() - 1)
	texture = def.frames[idx]
	offset  = def.center
	z_index = object.z_index
