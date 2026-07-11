extends PanelContainer
class_name ObjectsTab

@onready var line_search: LineEdit = $VBoxContainer/MarginSearch/HBoxSearch/LineSearch
@onready var option_filter: OptionButton = $VBoxContainer/MarginSearch/HBoxSearch/OptionFilter
@onready var item_list: ItemList = $VBoxContainer/VBoxObjects/ItemList

@onready var panel_object: Control = $VBoxContainer/VBoxObjects/PanelObject
@onready var texture_rect: TextureRect = $VBoxContainer/VBoxObjects/PanelObject/Margin/VBoxContainer/TextureRect
@onready var label_name: Label = $VBoxContainer/VBoxObjects/PanelObject/Margin/VBoxContainer/LabelName
@onready var label_path: Label = $VBoxContainer/VBoxObjects/PanelObject/Margin/VBoxContainer/LabelPath
@onready var frame_list: ItemList = $VBoxContainer/VBoxObjects/PanelObject/Margin/VBoxContainer/FrameList

enum SortMode { NAME_ASC, NAME_DESC, ID_ASC, ID_DESC }

var _all_objects: Array[HLMObject] = []
var _current_sort: SortMode = SortMode.NAME_ASC
var _current_search: String = ""

func _ready() -> void:
	panel_object.hide()
	
	Assets.asset_rebuilded.connect(_on_asset_rebuilded)
	
	option_filter.clear()
	option_filter.add_item("A-Z", SortMode.NAME_ASC)
	option_filter.add_item("Z-A", SortMode.NAME_DESC)
	option_filter.add_item("ID ↑", SortMode.ID_ASC)
	option_filter.add_item("ID ↓", SortMode.ID_DESC)
	option_filter.select(0)
	option_filter.item_selected.connect(_on_filter_selected)
	
	line_search.text = "Furniture/"
	_on_search_text_changed(line_search.text)
	line_search.text_changed.connect(_on_search_text_changed)
	
	item_list.item_selected.connect(_on_object_selected)
	frame_list.item_selected.connect(_on_frame_selected)
	
	ToolManager.tool_changed.connect(_on_tool_changed)
	var obj_tool = ToolManager._tools[ToolManager.Tool.OBJ_PLACE] as ToolObjPlace
	if obj_tool:
		obj_tool.frame_changed.connect(_on_tool_frame_changed)

func _clear_selection() -> void:
	item_list.deselect_all()
	panel_object.hide()

func _refresh_list() -> void:
	item_list.clear()
	
	var search_mask: String = "*" + _current_search.replace("/", "*") + "*"
	
	var filtered: Array[HLMObject] = []
	for obj in _all_objects:
		if _current_search.is_empty() or obj.object_path.matchn(search_mask):
			filtered.append(obj)
	
	filtered.sort_custom(_sort_objects)
	
	for obj in filtered:
		var icon := _get_icon_for_object(obj)
		var idx := item_list.add_item(obj.object_name, icon)
		item_list.set_item_metadata(idx, obj.object_id)
		item_list.set_item_tooltip(idx, obj.object_path)

func _sort_objects(a: HLMObject, b: HLMObject) -> bool:
	match _current_sort:
		SortMode.NAME_ASC:
			return a.object_name.naturalnocasecmp_to(b.object_name) < 0
		SortMode.NAME_DESC:
			return a.object_name.naturalnocasecmp_to(b.object_name) > 0
		SortMode.ID_ASC:
			return a.object_id < b.object_id
		SortMode.ID_DESC:
			return a.object_id > b.object_id
	
	return false

func _on_tool_changed(tool_id: int) -> void:
	if ToolManager and tool_id != ToolManager.Tool.OBJ_PLACE:
		_clear_selection()

func _on_object_selected(index: int) -> void:
	var obj_id = item_list.get_item_metadata(index)
	var obj = _get_object_by_id(obj_id)
	if not obj: return
	
	panel_object.show()
	label_name.text = obj.object_name
	label_path.text = obj.object_path
	
	var def = Defs.get_sprite_def(obj.sprite_id)
	frame_list.clear()
	
	if def and def.frames.size() > 1:
		frame_list.show()
		for i in range(def.frames.size()):
			var f_idx = frame_list.add_item("", def.frames[i])
			frame_list.set_item_tooltip(f_idx, str(i + 1))
		frame_list.select(0)
	else:
		frame_list.hide()
	
	if def and not def.frames.is_empty():
		texture_rect.texture = def.frames[0]
	
	ToolManager.set_tool(ToolManager.Tool.OBJ_PLACE)
	var obj_tool = ToolManager.current() as ToolObjPlace
	obj_tool.init(obj.object_id, obj.sprite_id, LevelTab.Modes.OBJECTS, 0)

func _on_frame_selected(index: int) -> void:
	var obj_id = item_list.get_item_metadata(item_list.get_selected_items()[0])
	var obj = _get_object_by_id(obj_id)
	var def = Defs.get_sprite_def(obj.sprite_id)
	
	if def and index < def.frames.size():
		texture_rect.texture = def.frames[index]
	
	if ToolManager.current_id() == ToolManager.Tool.OBJ_PLACE:
		var obj_tool = ToolManager.current() as ToolObjPlace
		obj_tool.set_frame_from_ui(index)

func _on_tool_frame_changed(new_frame: int) -> void:
	if panel_object.visible and frame_list.visible and new_frame < frame_list.item_count:
		frame_list.select(new_frame)
		
		var obj_id = item_list.get_item_metadata(item_list.get_selected_items()[0])
		var obj = _get_object_by_id(obj_id)
		var def = Defs.get_sprite_def(obj.sprite_id)
		if def and new_frame < def.frames.size():
			texture_rect.texture = def.frames[new_frame]

func _on_asset_rebuilded() -> void:
	_all_objects.clear()
	for obj in Defs.get_all_objects():
		_all_objects.append(obj as HLMObject)
	_refresh_list()

func _on_filter_selected(index: int) -> void:
	_current_sort = option_filter.get_item_id(index) as SortMode
	_refresh_list()

func _on_search_text_changed(new_text: String) -> void:
	_current_search = new_text.strip_edges().to_lower()
	_refresh_list()

func _get_object_by_id(id: int) -> HLMObject:
	for obj in _all_objects:
		if obj.object_id == id:
			return obj
	return null

func _get_icon_for_object(obj: HLMObject) -> Texture2D:
	var def := Defs.get_sprite_def(obj.sprite_id)
	if def and not def.frames.is_empty():
		return def.frames[0]
	var fallback := Defs.get_sprite_def(-1)
	if fallback and not fallback.frames.is_empty():
		return fallback.frames[0]
	return null
