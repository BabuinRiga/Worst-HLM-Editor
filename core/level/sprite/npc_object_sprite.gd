class_name NPCObjectSprite
extends ObjectSprite

static var NPCobjectID: int = 2406

var _anim_frame:   float = 0.0
var _frame_count:  int   = 1

const BASE_FPS: float = 60.0

# -------------------------------------------------

func _init(_object: HLMObject, _frame: float, _mode: int) -> void:
	super._init(_object, _frame, _mode)
	
	var def := Defs.get_sprite_def(object.sprite_id)
	if def and not def.frames.is_empty():
		_frame_count = def.frames.size()

func _physics_process(delta: float) -> void:
	if _frame_count <= 1 or object_frame <= 0.0:
		return
	
	_anim_frame += object_frame * BASE_FPS * delta
	if _anim_frame >= _frame_count:
		_anim_frame -= _frame_count
	
	var def := Defs.get_sprite_def(object.sprite_id)
	if def and not def.frames.is_empty():
		texture = def.frames[int(_anim_frame)]

func _apply_sprite() -> void:
	super._apply_sprite()
	var def := Defs.get_sprite_def(object.sprite_id)
	_frame_count = def.frames.size() - 1 if def and not def.frames.is_empty() else 0
