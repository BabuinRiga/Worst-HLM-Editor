extends ModalWindow

@onready var item_list: ItemList = $Panel/VPanel/Content/VBox/ItemList
@onready var search_field: LineEdit = $Panel/VPanel/Content/VBox/LineEdit

var _assets: Dictionary = {}

var _load_queue: Array = []
const BATCH_SIZE := 10

func _ready() -> void:
	search_field.text_changed.connect(_rebuild_list)
	_create_library()

func _process(delta: float) -> void:
	pass


func _create_library() -> void:
	_assets.clear()
	_load_queue.clear()
	
	for asset_name: String in Assets._sprites.keys():
		var asset := Assets.get_sprite(asset_name)
		_assets[asset_name] = {
			"name": asset_name.get_file(),
			"texture": asset[0]
		}
	
	_rebuild_list("")

func _rebuild_list(query: String) -> void:
	item_list.clear()
	_load_queue.clear()
	
	var q := query.to_lower()
	
	for asset_name in _assets:
		var entry: Dictionary = _assets[asset_name]
		
		if not q.is_empty() and not entry["name"].to_lower().contains(q):
			continue
		
		var tip := ""
		for tooltip in Assets._base_raw.keys():
			var t_name = tooltip.get_file().get_basename()
			if asset_name == t_name:
				tip = tooltip
				break
			
		
		item_list.add_item(entry["name"])
		item_list.set_item_tooltip(item_list.item_count - 1, tip)
		item_list.set_item_metadata(item_list.item_count - 1, asset_name)
		
		if entry["texture"] != null:
			item_list.set_item_icon(item_list.item_count - 1, entry["texture"])
		else:
			_load_queue.append(asset_name)
