extends Node2D

@export var cell_size: Vector2i = Vector2i(16, 16)
@export var grid_color_s: Color = Color(1, 1, 1, 0.10)
@export var grid_color_l: Color = Color(1, 1, 1, 0.20)
@export var grid_pixel_size: Vector2i = Vector2i(2048, 2048)

@onready var top_bar = get_tree().get_first_node_in_group("TopBar") as TopBar


func _ready() -> void:
	top_bar.view.grid_updated.connect(_on_grid_update)
	queue_redraw()

func _draw() -> void:
	var w = grid_pixel_size.x
	var h = grid_pixel_size.y
	
	var cols = w / cell_size.x
	var rows = h / cell_size.y
	
	for x in range(cols + 1):
		var px = x * cell_size.x
		var color = grid_color_l if x % 2 == 0 else grid_color_s
		draw_line(Vector2(px, 0), Vector2(px, h), color)
	
	for y in range(rows + 1):
		var py = y * cell_size.y
		var color = grid_color_l if y % 2 == 0 else grid_color_s
		draw_line(Vector2(0, py), Vector2(w, py), color)


func _on_grid_update(grid_value: Vector2i) -> void:
	cell_size = grid_value
	queue_redraw()
