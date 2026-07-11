class_name BorderOverlay
extends Node2D

@onready var top_bar = get_tree().get_first_node_in_group("TopBar") as TopBar

const DARK_COLOR  := Color(0, 0, 0, 0.3)
const WORLD_EXTENT := 32768

func _ready() -> void:
	top_bar.view.view_updated.connect(queue_redraw)

func set_boundary(rect: Rect2i) -> void:
	_boundary = rect
	queue_redraw()

var _boundary := Rect2i()

func _draw() -> void:
	if not visible or not View.level_border:
		return
	var e  := WORLD_EXTENT
	var r  := Rect2(_boundary)
	
	# Сверху
	draw_rect(Rect2(-e, -e, e * 2, r.position.y + e), DARK_COLOR)
	# Снизу
	draw_rect(Rect2(-e, r.end.y, e * 2, e - r.end.y + e), DARK_COLOR)
	# Слева
	draw_rect(Rect2(-e, r.position.y, r.position.x + e, r.size.y), DARK_COLOR)
	# Справа
	draw_rect(Rect2(r.end.x, r.position.y, e - r.end.x, r.size.y), DARK_COLOR)
