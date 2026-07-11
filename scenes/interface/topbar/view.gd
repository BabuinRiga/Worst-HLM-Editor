extends PopupMenu
class_name View

@onready var grid_submenu: PopupMenu = $Grid

static var grid_value: Vector2i = Vector2i(16, 16)
static var show_outline: bool = true
static var show_mask: bool = false
static var show_pivot: bool = false

static var wall_hint: bool = true
static var rain: bool = true
static var level_border: bool = false

var grid_params: Array = [
	Vector2i(4, 4),
	Vector2i(8, 8),
	Vector2i(16, 16),
	Vector2i(32, 32),
	Vector2i(64, 64)
]

signal view_updated
signal grid_updated


func _ready() -> void:
	_init_view()
	_update_view()
	_init_grid()
	_grid_update()


func _init_view() -> void:
	id_pressed.connect(_on_view_pressed)
	grid_submenu.id_pressed.connect(_on_grid_pressed)

func _on_view_pressed(id: int) -> void:
	match id:
		2:
			show_outline = not show_outline
		3:
			show_pivot = not show_pivot
			
		5:
			wall_hint = not wall_hint
		6:
			rain = not rain
		7:
			level_border = not level_border
		_:
			pass
	_update_view()
	view_updated.emit()

func _update_view() -> void:
	set_item_checked(2, show_outline)
	set_item_checked(3, show_pivot)
	# ---
	set_item_checked(5, wall_hint)
	set_item_checked(6, rain)
	set_item_checked(7, level_border)


func _init_grid() -> void:
	var item_index = get_item_index(0)
	set_item_submenu_node(item_index, grid_submenu)
	for grid_param: Vector2i in grid_params:
		grid_submenu.add_radio_check_item(str(grid_param.x) + "x" + str(grid_param.y))

func _on_grid_pressed(id: int) -> void:
	var i = 0
	for grid_param: Vector2i in grid_params:
		if id == i:
			grid_value = grid_param
			break
		i += 1
	grid_updated.emit(grid_value)
	_grid_update()

func _grid_update() -> void:
	var i = 0
	for grid_param: Vector2i in grid_params:
		if grid_value == grid_param:
			grid_submenu.set_item_checked(i, true)
		else:
			grid_submenu.set_item_checked(i, false)
		i += 1
