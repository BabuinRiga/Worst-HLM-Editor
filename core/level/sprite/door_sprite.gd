extends BaseSprite
class_name DoorSprite

signal sprite_changed

const object_ids: Array[int] = [26, 25, 2254, 2255]
const sprite_ids: Array[int] = [92, 91, 3902, 3903]

var object_id: int
var sprite_id: int
var direction: int
var locked:    int
var cutscene:  int

func _init(_object_id: int, _locked: int, _cutscene: int) -> void:
	object_id = _object_id
	locked    = _locked
	cutscene  = _cutscene
	mode      = LevelTab.Modes.TILES

func _ready() -> void:
	super._ready()
	ToolManager.tool_changed.connect(_on_tool_changed)
	direction = object_ids.find(object_id)
	if direction == -1:
		direction = 0
	
	if sprite_id == 0:
		sprite_id = sprite_ids[direction]
	
	_apply_texture()

func _apply_texture() -> void:
	var def := Defs.get_sprite_def(sprite_id)
	if def and not def.frames.is_empty():
		texture = def.frames[0]
		offset  = Vector2(def.center.x, -def.center.y) if direction in [0, 2] else Vector2(-def.center.x, def.center.y)

func set_sprite_id(new_id: int) -> void:
	sprite_id = new_id
	_apply_texture()
	queue_redraw()
	sprite_changed.emit()

func _draw() -> void:
	super._draw()
	if ToolManager.current() == ToolManager._tools[ToolManager.Tool.DOOR_PLACE]:
		draw_circle(Vector2.ZERO, 2, Color.YELLOW)

func _on_tool_changed(tool_id: ToolManager.Tool):
	queue_redraw()
