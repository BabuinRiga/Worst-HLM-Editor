extends BaseSprite
class_name RainSprite

const TEXTURE = preload("uid://dhqijjqfcsoxl")

var rain_rect: Rect2

func _init(_rain_rect: Rect2) -> void:
	rain_rect = _rain_rect
	texture = TEXTURE
	position = rain_rect.position
	
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	region_enabled = true
	region_rect = Rect2(Vector2.ZERO, rain_rect.size) 
	
	mode = LevelTab.Modes.MAIN

func _enter_tree() -> void:
	var active_floor: Floor = get_parent()
	if active_floor:
		active_floor._update_rain.call_deferred()
func _exit_tree() -> void:
	var active_floor: Floor = get_parent()
	if active_floor:
		active_floor._update_rain.call_deferred()

func _ready() -> void:
	super._ready()
	_update_visibility()

func _on_mode_changed(new_mode: int) -> void:
	super._on_mode_changed(new_mode)
	_update_visibility()

func _update_visibility() -> void:
	if level_tab == null:
		return
	visible = level_tab.current_mode == mode

func set_coords(new_coord: Vector2) -> void:
	super.set_coords(new_coord)
	rain_rect.position = position
