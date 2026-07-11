extends BaseSprite
class_name WallSprite

signal sprite_changed

var object_id: int
var sprite_id: int
var wall_offset: Vector2

func _init(_object_id: int, _sprite_id: int) -> void:
	object_id = _object_id
	sprite_id = _sprite_id
	
	var object := Defs.get_object(object_id)
	var def := Defs.get_sprite_def(sprite_id)
	wall_offset = -Vector2(def.center)
	texture = def.frames[0] if not def.frames.is_empty() else null
	z_index = object.z_index
	
	mode = LevelTab.Modes.TILES

func _ready() -> void:
	super._ready()

func set_sprite_id(new_id: int) -> void:
	sprite_id = new_id
	var def := Defs.get_sprite_def(sprite_id)
	if def:
		wall_offset = -Vector2(def.center)
		texture = def.frames[0] if not def.frames.is_empty() else null
	queue_redraw()
	sprite_changed.emit()
