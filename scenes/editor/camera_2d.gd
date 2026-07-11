extends Camera2D

var dragging: bool = false
var dragging_start: Vector2 = Vector2.ZERO

func _ready() -> void:
	position = Vector2(726.5, 389.5)

func _process(delta: float) -> void:
	pass

func _unhandled_input(event: InputEvent) -> void:
	_move_camera(event)
	_zoom_camera(event)

func _move_camera(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			dragging = event.pressed
			dragging_start = event.position
		else:
			dragging = false
			dragging_start = Vector2.ZERO
	
	if event is InputEventMouseMotion and dragging:
		position -= event.relative / zoom

func _zoom_camera(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		if event.ctrl_pressed or event.shift_pressed or event.alt_pressed:
			return
		var move_pos_b = get_global_mouse_position()
		match event.button_index:
			MOUSE_BUTTON_WHEEL_UP:
				zoom *= 1.1
			MOUSE_BUTTON_WHEEL_DOWN:
				zoom *= 0.9
		var move_pos_a = get_global_mouse_position()
		position += move_pos_b - move_pos_a
