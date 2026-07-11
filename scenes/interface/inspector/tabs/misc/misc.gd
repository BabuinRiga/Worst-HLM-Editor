extends PanelContainer
class_name MiscTab

@onready var list_weapons: ItemList = $ScrollContainer/Margin/VBoxContainer/VBoxWeapons/ListWeapons

var weapons: Array = []
static var weapon_ids: Array = []

# -------------------------------------------------


func _ready() -> void:
	_parse_weapons()
	list_weapons.item_selected.connect(_on_list_weapons_selected)
	ToolManager.tool_changed.connect(_on_tool_changed)
	Assets.asset_rebuilded.connect(_on_asset_rebuilded)


# -------------------------------------------------

func _on_asset_rebuilded() -> void:
	_rebuild_weapons()

func _rebuild_weapons() -> void:
	list_weapons.clear()
	for i in weapons.size():
		var weapon: Dictionary = weapons[i]
		var sprite := Defs.get_sprite_def(weapon["sprite_id"]).frames[0]
		list_weapons.add_icon_item(sprite)
		list_weapons.set_item_tooltip(i, weapon["name"])

func _on_list_weapons_selected(index: int) -> void:
	var tool := ToolManager._tools[ToolManager.Tool.OBJ_PLACE] as ToolObjPlace
	tool.init(weapons[index]["object_id"], weapons[index]["sprite_id"], LevelTab.Modes.MISC)
	ToolManager.set_tool(ToolManager.Tool.OBJ_PLACE)

# -------------------------------------------------

func _on_tool_changed(tool_id: ToolManager.Tool) -> void:
	if tool_id != ToolManager.Tool.OBJ_PLACE: list_weapons.deselect_all()

func _parse_weapons() -> void:
	var weapons_tsv := FileAccess.open("res://resources/tables/weapons.tsv", FileAccess.READ)
	if !weapons_tsv.eof_reached():
		weapons_tsv.get_csv_line("\t")
	while !weapons_tsv.eof_reached():
		var params = weapons_tsv.get_csv_line("\t")
		weapons.append({
			"name": params[0],
			"object_id": int(params[1]),
			"sprite_id": int(params[2]),
			})
		weapon_ids.append(int(params[1]))
	weapons_tsv.close()
