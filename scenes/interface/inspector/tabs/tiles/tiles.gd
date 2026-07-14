extends PanelContainer
class_name TilesTab

@onready var tile_selector: OptionButton = $ScrollContainer/MarginFloor/VBox/VBoxFC/VBoxFloor/TileSelector
@onready var tile_picker: TilePicker = $ScrollContainer/MarginFloor/VBox/VBoxFC/VBoxFloor/TilePanel/ScrollC/TilePicker
@onready var c_picker: TilePicker = $ScrollContainer/MarginFloor/VBox/VBoxFC/VBoxCorner/CPanel/CPicker
@onready var place_layer_check: CheckButton = $ScrollContainer/MarginFloor/VBox/VBoxFC/PlaceLayerCheck

@onready var tile_extra_check: CheckBox = $ScrollContainer/MarginFloor/VBox/VBoxFC/VBoxFloor/HBoxLabel/ExtraCheck
@onready var tile_prop_check: CheckBox = $ScrollContainer/MarginFloor/VBox/VBoxFC/VBoxFloor/TileProp/VBox/HBoxLabel/TilePropCheck
@onready var tile_prop_margin: MarginContainer = $ScrollContainer/MarginFloor/VBox/VBoxFC/VBoxFloor/TileProp/VBox/TilePropMargin
@onready var depth_spin_box: SpinBox = $ScrollContainer/MarginFloor/VBox/VBoxFC/VBoxFloor/TileProp/VBox/TilePropMargin/TilePropHBox/VBoxDepth/SpinBox

@onready var wall_list: ItemList = $ScrollContainer/MarginFloor/VBox/VBoxWalls/WallList
@onready var entry_b: Button = $ScrollContainer/MarginFloor/VBox/HBoxEB/EntryB
@onready var barrier_b: Button = $ScrollContainer/MarginFloor/VBox/HBoxEB/BarrierB

@onready var door_b: Button = $ScrollContainer/MarginFloor/VBox/VBoxDoors/HBox/DoorB
@onready var option_dalign: OptionButton = $ScrollContainer/MarginFloor/VBox/VBoxDoors/HBox/VBox/OptionAlign
@onready var check_locked: CheckBox = $ScrollContainer/MarginFloor/VBox/VBoxDoors/HBox/VBox/CheckLocked
@onready var check_cutscene: CheckBox = $ScrollContainer/MarginFloor/VBox/VBoxDoors/HBox/VBox/CheckCutscene

var walls: Array = []
static var wall_ids: Array = []

var manual_place_layer: bool = true

# -------------------------------------------


func _ready() -> void:
	_parse_walls()
	Assets.asset_rebuilded.connect(_update_tile)
	tile_selector.item_selected.connect(_on_tile_selector_selected)
	option_dalign.item_selected.connect(_on_option_dalign_selected)
	place_layer_check.toggled.connect(_on_place_layer_toggled)
	
	tile_picker.tile_selected.connect(_on_tile_picker_used)
	tile_picker.selection_changed.connect(_on_tile_picker_used)
	c_picker.tile_selected.connect(_on_c_picker_used)
	c_picker.selection_changed.connect(_on_c_picker_used)
	
	tile_extra_check.pressed.connect(_on_tile_extra_check_pressed)
	tile_prop_check.toggled.connect(_on_tile_prop_check_toggled)
	depth_spin_box.value_changed.connect(_on_depth_spin_box_value_changed)
	_on_tile_prop_check_toggled(tile_prop_check.button_pressed)
	
	wall_list.item_selected.connect(_on_wall_list_selected)
	entry_b.pressed.connect(_on_entry_b_pressed)
	door_b.pressed.connect(_on_door_b_pressed)
	barrier_b.pressed.connect(_on_barrier_b_pressed)
	
	ToolManager.tool_changed.connect(_on_tool_changed)

func _process(_delta: float) -> void:
	var physical_alt := Input.is_key_pressed(KEY_ALT)
	var effective_state := manual_place_layer != physical_alt
	
	if place_layer_check.button_pressed != effective_state:
		place_layer_check.set_pressed_no_signal(effective_state)


# -------------------------------------------

func _update_tile() -> void:
	var last_tile_selected = max(0, tile_selector.selected)
	tile_selector.clear()
	wall_list.clear()
	for tile in Defs._tiles:
		if tile != Defs._tiles[-1]:
			if !tile_extra_check.button_pressed and tile.is_extra: continue
			tile_selector.add_item(tile.title)
	last_tile_selected = min(last_tile_selected, tile_selector.item_count - 1)
	if Defs._tiles.size() > 0:
		tile_selector.selected = last_tile_selected
		_on_tile_selector_selected(last_tile_selected)
		c_picker.set_tile(Defs._tiles[-1])
	for wall in walls:
		var orig_tex = Defs.get_sprite_def(wall["sprite_id"]).frames[0]
		var orig_img = orig_tex.get_image()
		var padded_img = Image.create_empty(35, 35, false, orig_img.get_format())
		padded_img.blit_rect(orig_img, Rect2(Vector2.ZERO, orig_img.get_size()), Vector2.ZERO)
		var padded_tex = ImageTexture.create_from_image(padded_img)
		var atlas_tex = AtlasTexture.new()
		atlas_tex.atlas = padded_tex
		atlas_tex.region = Rect2(Vector2.ZERO, Vector2(35, 35))
		wall_list.add_icon_item(atlas_tex)
	_update_aligns()

# -------------------------------------------

func _update_aligns() -> void:
	option_dalign.clear()
	for align_id in DoorSprite.object_ids:
		var label: String
		if align_id == DoorSprite.object_ids[0]:
			label = "LEFT"
		elif align_id == DoorSprite.object_ids[1]:
			label = "TOP"
		elif align_id == DoorSprite.object_ids[2]:
			label = "RIGHT"
		elif align_id == DoorSprite.object_ids[3]:
			label = "BOTTOM"
		option_dalign.add_item(label, align_id)
	option_dalign.select(0)
	_on_option_dalign_selected(0)

func _on_option_dalign_selected(index: int) -> void:
	door_b.icon = Defs.get_sprite_def(Defs.get_object(option_dalign.get_item_id(index)).sprite_id).frames[0]
	
	if ToolManager.current() is ToolDoorPlace:
		(ToolManager.current() as ToolDoorPlace).set_direction(index)

func _on_door_b_pressed() -> void:
	var tool = ToolManager._tools[ToolManager.Tool.DOOR_PLACE] as ToolDoorPlace
	tool.init(option_dalign.selected) 
	
	if ToolManager.current() != tool:
		ToolManager.set_tool(ToolManager.Tool.DOOR_PLACE)
	else:
		ToolManager.set_tool(ToolManager.Tool.SELECT)

# -------------------------------------------

func _on_tile_picker_used(_a = null, _b = null, _c = null) -> void:
	c_picker.clear_selection()

func _on_c_picker_used(_a = null, _b = null, _c = null) -> void:
	tile_picker.clear_selection()

func _on_place_layer_toggled(toggled_on: bool) -> void:
	if not Input.is_key_pressed(KEY_ALT):
		manual_place_layer = toggled_on

func select_tile_by_id(target_id: int) -> void:
	for i in range(Defs._tiles.size()):
		if Defs._tiles[i].id == target_id:
			tile_selector.select(min(i, tile_selector.item_count - 1))
			_on_tile_selector_selected(i)
			break

func _on_tile_selector_selected(index: int) -> void:
	tile_picker.set_tile(Defs._tiles[index])
	depth_spin_box.value = Defs._tiles[index].depth

# -------------------------------------------

func _on_tile_extra_check_pressed() -> void:
	ToolManager.set_tool(ToolManager.Tool.SELECT)
	_update_tile()

func _on_tile_prop_check_toggled(toggled_on: bool) -> void:
	tile_prop_margin.visible = toggled_on
	_refresh_tile_tools()

func _on_depth_spin_box_value_changed(value: float) -> void:
	_refresh_tile_tools()

func _refresh_tile_tools() -> void:
	tile_picker.queue_redraw()
	c_picker.queue_redraw()
	
	if ToolManager.current() == ToolManager._tools[ToolManager.Tool.TILE_PAINT]:
		var tool = ToolManager.current() as ToolTilePaint
		tool._create_preview()

# -------------------------------------------

func _on_wall_list_selected(index: int) -> void:
	var tool := ToolManager._tools[ToolManager.Tool.WALL_PLACE] as ToolWallPlace
	tool.init(WallSprite.new(walls[index]["object_id"], walls[index]["sprite_id"]))
	if ToolManager.current() != ToolManager._tools[ToolManager.Tool.WALL_PLACE]:
		ToolManager.set_tool(ToolManager.Tool.WALL_PLACE)

func _parse_walls() -> void:
	var walls_tsv = FileAccess.open("res://resources/tables/walls.tsv", FileAccess.READ)
	if !walls_tsv.eof_reached():
		walls_tsv.get_csv_line("\t")
	while !walls_tsv.eof_reached():
		var params = walls_tsv.get_csv_line("\t")
		var wall_data = {
			"object_id": int(params[0]),
			"sprite_id": int(params[1]),
			"next": int(params[2])
		}
		walls.append(wall_data)
		wall_ids.append(wall_data["object_id"])
	walls_tsv.close()

# -------------------------------------------

func _on_entry_b_pressed() -> void:
	if ToolManager.current() != ToolManager._tools[ToolManager.Tool.ENTRY_PLACE]:
		ToolManager.set_tool(ToolManager.Tool.ENTRY_PLACE)
	else:
		ToolManager.set_tool(ToolManager.Tool.SELECT)

func _on_barrier_b_pressed() -> void:
	if ToolManager.current() != ToolManager._tools[ToolManager.Tool.BARRIER_PLACE]:
		ToolManager.set_tool(ToolManager.Tool.BARRIER_PLACE)
	else:
		ToolManager.set_tool(ToolManager.Tool.SELECT)

# -------------------------------------------

func _on_tool_changed(tool_id: ToolManager.Tool) -> void:
	door_b.button_pressed = false
	entry_b.button_pressed = false
	barrier_b.button_pressed = false
	if tool_id == ToolManager.Tool.DOOR_PLACE: door_b.button_pressed = true
	elif tool_id == ToolManager.Tool.ENTRY_PLACE: entry_b.button_pressed = true
	elif tool_id == ToolManager.Tool.BARRIER_PLACE: barrier_b.button_pressed = true
