extends PanelContainer
class_name EnemyTab

@onready var option_gang: OptionButton = $ScrollContainer/Margin/VBoxContainer/OptionGang
@onready var h_flow_container: HFlowContainer = $ScrollContainer/Margin/VBoxContainer/PanelEnemy/MarginEnemy/HFlowContainer

const V_BOX_OPTION = preload("uid://cxrrfhp86q47k")

var enemy_data: Array = []
static var enemy_ids: Array = []


# ----------------------------------------------------


func _ready() -> void:
	Assets.asset_rebuilded.connect(_on_asset_rebuilded)
	
	option_gang.item_selected.connect(_on_gang_selected)
	_parse_enemies()

func _on_asset_rebuilded() -> void:
	if option_gang.item_count > 0:
		var current_idx = option_gang.selected if option_gang.selected >= 0 else 0
		_on_gang_selected(current_idx)


# ----------------------------------------------------


func _parse_enemies() -> void:
	enemy_data.clear()
	enemy_ids.clear()
	option_gang.clear()
	
	var file := FileAccess.open("res://resources/tables/enemies.json", FileAccess.READ)
	if not file:
		return
		
	var json_text := file.get_as_text()
	file.close()
	
	var json_result = JSON.parse_string(json_text)
	if typeof(json_result) != TYPE_ARRAY:
		return
		
	enemy_data = json_result
	
	for i in range(enemy_data.size()):
		var faction: Dictionary = enemy_data[i]
		option_gang.add_item(faction.get("name", "UNKNOWN"), i)
		
		var types: Dictionary = faction.get("types", {})
		for type_key in types:
			var enemies_list: Array = types[type_key]
			for enemy in enemies_list:
				var obj_id = int(enemy[0])
				if not obj_id in enemy_ids:
					enemy_ids.append(obj_id)

func _on_gang_selected(index: int) -> void:
	for child in h_flow_container.get_children():
		child.queue_free()
		
	var faction_idx = option_gang.get_item_id(index)
	var faction: Dictionary = enemy_data[faction_idx]
	var types: Dictionary = faction.get("types", {})
	
	var used_sprites: Array = [] 
	
	for type_name in types:
		var enemy_node = V_BOX_OPTION.instantiate() as EnemyOption
		h_flow_container.add_child(enemy_node)
		
		enemy_node.label.text = type_name
		var opt_btn: OptionButton = enemy_node.option_button
		opt_btn.clear()
		
		var enemies_list: Array = types[type_name]
		var valid_indices_for_random: Array = []
		
		for i in range(enemies_list.size()):
			var enemy_info: Array = enemies_list[i]
			var obj_id = int(enemy_info[0])
			var sprite_id = int(enemy_info[1])
			var e_name = str(enemy_info[2]) if enemy_info.size() > 2 else ""
			
			var icon := Defs.get_sprite_def(sprite_id).frames[0]
			
			if icon:
				opt_btn.add_icon_item(icon, e_name, i)
			else:
				opt_btn.add_item(e_name, i)
			
			opt_btn.set_item_metadata(i, {
				"object_id": obj_id,
				"sprite_id": sprite_id
			})
			
			if not sprite_id in used_sprites:
				valid_indices_for_random.append(i)
		
		opt_btn.item_selected.connect(_on_enemy_selected.bind(opt_btn))
		
		if opt_btn.item_count > 0:
			var chosen_idx: int = 0
			
			if valid_indices_for_random.size() > 0:
				chosen_idx = valid_indices_for_random.pick_random()
			else:
				chosen_idx = randi() % opt_btn.item_count
				
			opt_btn.select(chosen_idx)
			
			var meta = opt_btn.get_item_metadata(chosen_idx)
			if meta:
				used_sprites.append(meta["sprite_id"])

func _on_enemy_selected(index: int, opt_btn: OptionButton) -> void:
	var meta = opt_btn.get_item_metadata(index)
	if meta == null:
		return
		
	var obj_id: int = meta["object_id"]
	var sprite_id: int = meta["sprite_id"]
	
	ToolManager.set_tool(ToolManager.Tool.OBJ_PLACE)
	var obj_tool = ToolManager.current() as ToolObjPlace
	
	if obj_tool:
		obj_tool.init(obj_id, sprite_id, LevelTab.Modes.ENEMY, 0)
