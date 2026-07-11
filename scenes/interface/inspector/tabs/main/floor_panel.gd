extends PanelContainer

@onready var item_list:   ItemList = $HBoxContainer/ItemList
@onready var btn_create:  Button   = $HBoxContainer/VBoxContainer/CreateFloor
@onready var btn_copy:    Button   = $HBoxContainer/VBoxContainer/CopyFloor
@onready var btn_del:     Button   = $HBoxContainer/VBoxContainer/DelFloor

@onready var editor_level = get_tree().get_first_node_in_group("EditorLevel") as EditorLevel

# -------------------------------------------------

func _ready() -> void:
	_refresh_list()
	btn_create.pressed.connect(_on_create_floor_pressed)
	btn_del.pressed.connect(_on_del_floor_pressed)
	item_list.item_selected.connect(_on_item_list_item_selected)
	
	editor_level.level_loaded.connect(_refresh_list)
	editor_level.floor_switched.connect(_on_floor_switched)

# -------------------------------------------------

func _on_create_floor_pressed() -> void:
	if editor_level == null: return
	editor_level.add_floor()
	_refresh_list()
	item_list.select(editor_level.get_current_floor_index())

func _on_del_floor_pressed() -> void:
	if editor_level == null: return
	editor_level.del_floor()
	_refresh_list()
	var idx = editor_level.get_current_floor_index()
	if idx >= 0:
		item_list.select(idx)
		editor_level.switch_floor(idx)

func _on_item_list_item_selected(index: int) -> void:
	if editor_level == null: return
	editor_level.switch_floor(index)

func _on_floor_switched(floor: Floor) -> void:
	_refresh_list()

# -------------------------------------------------

func _refresh_list() -> void:
	item_list.clear()
	if editor_level == null: return
	for i in range(editor_level.get_floor_count()):
		item_list.add_item(tr("FLOOR") + " " + str(i + 1))
		if i == editor_level.current_floor_index:
			item_list.select(i)
