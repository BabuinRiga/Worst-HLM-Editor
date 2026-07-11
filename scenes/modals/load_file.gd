extends ModalWindow

signal level_selected(info: LevelInfo)

@onready var tab_container: TabContainer = $Panel/VPanel/Content/TabContainer
@onready var tree_single: Tree = $Panel/VPanel/Content/TabContainer/Single
@onready var tree_campaigns: Tree = $Panel/VPanel/Content/TabContainer/Campaigns
@onready var btn_load: Button = $Panel/VPanel/MarginPanels/Panels/Load

const META_INFO := "level_info"

# -------------------------------------------------


func _ready() -> void:
	btn_load.disabled = true
	btn_load.pressed.connect(_on_load_pressed)
	tab_container.tab_selected.connect(_on_tab_changed)
	tree_single.item_selected.connect(_on_selection_changed)
	tree_campaigns.item_selected.connect(_on_selection_changed)
	
	_populate()


# -------------------------------------------------

func _populate() -> void:
	_fill_single()
	_fill_campaigns()

func _fill_single() -> void:
	tree_single.clear()
	tree_single.create_item()
	
	for info: LevelInfo in LevelScanner.scan_single():
		var item := tree_single.create_item()
		item.set_text(0, info.name)
		item.set_icon(0, info.get_cover_texture())
		item.set_meta(META_INFO, info)

func _fill_campaigns() -> void:
	tree_campaigns.clear()
	tree_campaigns.create_item()
	
	for campaign in LevelScanner.scan_campaigns():
		# Кампания
		var cpg_item := tree_campaigns.create_item()
		cpg_item.set_text(0, campaign["info"].name)
		cpg_item.set_icon(0, campaign["info"].get_cover_texture())
		cpg_item.collapsed = true
		
		for chapter in campaign["chapters"]:
			# Глава
			var chpt_item := tree_campaigns.create_item(cpg_item)
			chpt_item.set_text(0, chapter["info"].name)
			chpt_item.set_icon(0, chapter["info"].get_cover_texture())
			chpt_item.collapsed = true
			
			for info: LevelInfo in chapter["levels"]:
				# Конкретный уровень
				var lvl_item := tree_campaigns.create_item(chpt_item)
				lvl_item.set_text(0, info.name)
				lvl_item.set_icon(0, info.get_cover_texture())
				lvl_item.set_meta(META_INFO, info)

# -------------------------------------------------

func _on_tab_changed(_tab: int) -> void:
	_on_selection_changed()

func _on_selection_changed() -> void:
	btn_load.disabled = (_get_selected_info() == null)

func _on_load_pressed() -> void:
	var info := _get_selected_info()
	if info == null:
		return
	level_selected.emit(info)
	close()

# -------------------------------------------------

func _get_selected_info() -> LevelInfo:
	var tree := _active_tree()
	var item := tree.get_selected()
	if item == null:
		return null
	if not item.has_meta(META_INFO):
		return null
	return item.get_meta(META_INFO) as LevelInfo

func _active_tree() -> Tree:
	return tree_single if tab_container.current_tab == 0 else tree_campaigns
