class_name BaseSprite
extends Sprite2D

var _selected: bool = false

const SELECT_BORDER_COLOR := Color(1.0, 0.8, 0.0, 0.8)
const COLLISION_HINT_COLOR := Color(1.0, 0.0, 1.0, 0.6)

@onready var level_tab = get_tree().get_first_node_in_group("LevelTab") as LevelTab
@onready var top_bar = get_tree().get_first_node_in_group("TopBar") as TopBar

var mode:    int = LevelTab.Modes.OBJECTS
var level:   int = -1

var custom_rect: Rect2 = Rect2()

signal xya_changed

# -------------------------------------------------

func _ready() -> void:
	z_as_relative = false
	centered      = false
	add_to_group("sprites")
	level_tab.mode_changed.connect(_on_mode_changed)
	top_bar.view.view_updated.connect(queue_redraw)

func set_selected(value: bool) -> void:
	_selected = value
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if not visible: return
	if level_tab.current_mode != mode: return
	if ToolManager.current_id() != ToolManager.Tool.SELECT: return
	
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			if mb.alt_pressed: return
			if mb.ctrl_pressed: return
			if _hit_test(_mouse_world_pos()):
				if mb.shift_pressed:
					Selection.add_to_selection(self)
				else:
					Selection.select_one(self)
				get_viewport().set_input_as_handled()

func _draw() -> void:
	if _selected:
		var rect = get_rect()
		draw_rect(rect, SELECT_BORDER_COLOR, false, 2.0)

# -------------------------------------------------

func set_coords(new_coord: Vector2):
	global_position = new_coord
	xya_changed.emit()

func set_angle(new_angle: float):
	rotation_degrees = new_angle
	xya_changed.emit()

# -------------------------------------------------

func _mouse_world_pos() -> Vector2:
	var cam := get_viewport().get_camera_2d()
	return cam.get_global_mouse_position() if cam else get_viewport().get_mouse_position()

func _hit_test(world_pos: Vector2) -> bool:
	var local_pos := to_local(world_pos)
	
	if custom_rect != Rect2():
		if not custom_rect.has_point(local_pos): return false
	else:
		if not get_rect().has_point(local_pos): return false
	
	if texture:
		var img := texture.get_image()
		if img:
			var rect := get_rect()
			
			var tex_x := int(local_pos.x - rect.position.x)
			var tex_y := int(local_pos.y - rect.position.y)
			
			if region_enabled:
				tex_x += int(region_rect.position.x)
				tex_y += int(region_rect.position.y)
			
			if tex_x >= 0 and tex_x < img.get_width() and tex_y >= 0 and tex_y < img.get_height():
				var pixel_color := img.get_pixel(tex_x, tex_y)
				
				return pixel_color.a > 0.1
	
	return false

func _is_preview() -> bool:
	if modulate.a == 1.0:
		return true
	return false

# -------------------------------------------------

func _on_mode_changed(new_mode: int) -> void:
	queue_redraw()
