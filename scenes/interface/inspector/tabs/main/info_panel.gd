extends PanelContainer

@onready var level_tab = get_tree().get_first_node_in_group("LevelTab") as LevelTab
@onready var editor_level = get_tree().get_first_node_in_group("EditorLevel") as EditorLevel

@onready var option_player: OptionButton = $Margin/VBoxContainer/HBoxPC/PlayerButton/OptionButton
@onready var option_sprite: OptionButton = $Margin/VBoxContainer/HBoxPC/PlayerButton/OptionSprite
@onready var option_car: OptionButton = $Margin/VBoxContainer/HBoxPC/CarButton/OptionButton

@onready var option_char: OptionButton = $Margin/VBoxContainer/VBoxСB/CharFold/VBox/OptionChar
@onready var option_mask: OptionButton = $Margin/VBoxContainer/VBoxСB/CharFold/VBox/OptionMask

@onready var b_floor: Button = $Margin/VBoxContainer/VBoxEdit/HBoxTrans/BFloor
@onready var b_elevator: Button = $Margin/VBoxContainer/VBoxEdit/HBoxTrans/BElevator
@onready var b_dark: Button = $Margin/VBoxContainer/VBoxEdit/HBoxOverlay/BDark
@onready var b_rain: Button = $Margin/VBoxContainer/VBoxEdit/HBoxOverlay/BRain
@onready var check_light: CheckBox = $Margin/VBoxContainer/VBoxEdit/HBoxEffects/CheckLight
@onready var check_sunset: CheckBox = $Margin/VBoxContainer/VBoxEdit/HBoxEffects/CheckSunset
@onready var b_top: SpinBox = $Margin/VBoxContainer/VBoxСB/Borders/VBoxBorder/Top/BTop
@onready var b_left: SpinBox = $Margin/VBoxContainer/VBoxСB/Borders/VBoxBorder/LeftRight/BLeft
@onready var b_right: SpinBox = $Margin/VBoxContainer/VBoxСB/Borders/VBoxBorder/LeftRight/BRight
@onready var b_bottom: SpinBox = $Margin/VBoxContainer/VBoxСB/Borders/VBoxBorder/Bottom/BBottom
@onready var b_button: Button = $Margin/VBoxContainer/VBoxСB/Borders/BButton

@onready var level_title: LineEdit = $Margin/VBoxContainer/VBoxInfo/Title
@onready var level_author: LineEdit = $Margin/VBoxContainer/VBoxInfo/Author
@onready var s_rank: SpinBox = $Margin/VBoxContainer/VBoxInfo/SRank
@onready var cover_button: Button = $Margin/VBoxContainer/HBoxCover/Button
@onready var c_file_dialog: FileDialog = $Margin/VBoxContainer/HBoxCover/CFileDialog

@onready var option_bg: OptionButton = $Margin/VBoxContainer/VBoxPRM/VBoxBG/OptionBG
@onready var line_bg: LineEdit = $Margin/VBoxContainer/VBoxPRM/VBoxBG/LineBG
@onready var option_music: OptionButton = $Margin/VBoxContainer/VBoxPRM/VBoxMusic/OptionM

@onready var hour_input: SpinBox = $Margin/VBoxContainer/VBoxDate/HBoxTime/VBoxHour/Input
@onready var minute_input: SpinBox = $Margin/VBoxContainer/VBoxDate/HBoxTime/VBoxMinute/Input
@onready var day_input: SpinBox = $Margin/VBoxContainer/VBoxDate/IDay
@onready var month_input: SpinBox = $Margin/VBoxContainer/VBoxDate/HBoxCalend/VBoxMonth/Input
@onready var year_input: SpinBox = $Margin/VBoxContainer/VBoxDate/HBoxCalend/VBoxYear/Input

@onready var city_input: LineEdit = $Margin/VBoxContainer/VBoxCSA/HBoxPlace/VBoxCity/Input
@onready var state_input: LineEdit = $Margin/VBoxContainer/VBoxCSA/HBoxPlace/VBoxState/Input
@onready var address_input: LineEdit = $Margin/VBoxContainer/VBoxCSA/IAddress

const ALL_MASK_ID: int = -1
const NO_MASK_ID: int = 26
const CUSTOM_BG_ID: int = 9999

# -------------------------------------------------


func _ready() -> void:
	editor_level.level_loaded.connect(_update_level_info)
	editor_level.floor_switched.connect(_on_floor_switched)
	option_player.item_selected.connect(_on_player_option_pressed)
	option_sprite.item_selected.connect(_on_variant_option_pressed)
	option_car.item_selected.connect(_on_car_option_pressed)
	
	b_floor.pressed.connect(_on_b_floor_pressed)
	b_elevator.pressed.connect(_on_b_elevator_pressed)
	b_dark.pressed.connect(_on_b_dark_pressed)
	b_rain.pressed.connect(_on_b_rain_pressed)
	check_light.toggled.connect(_on_check_light_toggled)
	check_sunset.toggled.connect(_on_check_sunset_toggled)
	option_bg.item_selected.connect(_on_bg_option_selected)
	
	b_left.value_changed.connect(_on_b_left_value_changed)
	b_top.value_changed.connect(_on_b_top_value_changed)
	b_right.value_changed.connect(_on_b_right_value_changed)
	b_bottom.value_changed.connect(_on_b_bottom_value_changed)
	b_button.pressed.connect(_on_b_button_pressed)
	
	level_title.text_changed.connect(_on_level_title_changed)
	level_author.text_changed.connect(_on_level_author_changed)
	s_rank.value_changed.connect(_on_s_rank_value_changed)
	cover_button.pressed.connect(_on_cover_button_pressed)
	c_file_dialog.file_selected.connect(_on_cover_file_selected)
	option_char.item_selected.connect(_on_char_option_selected)
	option_mask.item_selected.connect(_on_mask_option_selected)
	line_bg.text_changed.connect(_on_line_bg_text_changed)
	option_music.item_selected.connect(_on_music_option_selected)
	hour_input.value_changed.connect(_on_hour_value_changed)
	minute_input.value_changed.connect(_on_minute_value_changed)
	day_input.value_changed.connect(_on_day_value_changed)
	month_input.value_changed.connect(_on_month_value_changed)
	year_input.value_changed.connect(_on_year_value_changed)
	city_input.text_changed.connect(_on_city_text_changed)
	state_input.text_changed.connect(_on_state_text_changed)
	address_input.text_changed.connect(_on_address_text_changed)
	
	ToolManager._tools[ToolManager.Tool.BOUNDARIES].boundaries_changed.connect(_on_boundaries_changed)
	ToolManager.tool_changed.connect(_on_tool_changed)
	Assets.asset_rebuilded.connect(_on_asset_rebuilded)

func _on_asset_rebuilded() -> void:
	_build_player_option()
	_build_variant_option(option_player.selected)
	_build_char_option()
	_build_mask_option()
	_build_car_option()
	_build_bg_option()
	_build_music_option()


# -------------------------------------------------

func _update_level_info() -> void:
	var level_info: LevelInfo = editor_level.level_info
	
	level_title.text = level_info.name
	level_author.text = level_info.author
	s_rank.value = level_info.s_rank
	cover_button.icon = level_info.get_cover_texture()
	
	option_char.selected = level_info.character_id
	for i in option_mask.item_count:
		if option_mask.get_item_metadata(i) == level_info.mask_id:
			option_mask.selected = i
			break
	_on_boundaries_changed(level_info.boundaries)
	
	_update_bg(level_info)
	
	hour_input.value = int(level_info.hour)
	minute_input.value = int(level_info.minute)
	day_input.value = int(level_info.day)
	month_input.value = int(level_info.month)
	year_input.value = int(level_info.year)
	
	city_input.text = level_info.city
	state_input.text = level_info.state
	address_input.text = level_info.address

func _on_floor_switched(floor: Floor) -> void:
	var is_daylight: bool = false if floor.light_overlays.find(Floor.DAYLIGHT_OVERLAY) == -1 else true
	var is_sunset: bool = false if floor.light_overlays.find(Floor.SUNSET_OVERLAY) == -1 else true
	check_light.set_pressed_no_signal(is_daylight)
	check_sunset.set_pressed_no_signal(is_sunset)

# -------------------------------------------------

func _build_player_option() -> void:
	option_player.clear()
	for key in MainTab.players_data:
		var player = MainTab.players_data[key]
		var sprite_id: int = player["ids"][0][1]
		option_player.add_icon_item(
			Defs.get_sprite_def(sprite_id).frames[0],
			player["name"],
			key
		)

func _build_variant_option(index: int) -> void:
	var object_id: int = option_player.get_item_id(index)
	var player = MainTab.players_data[object_id]
	option_sprite.clear()
	for i in player["ids"].size():
		var variant = player["ids"][i]
		var variant_object_id: int = variant[0]
		var variant_sprite_id: int = variant[1]
		var variant_name: String = variant[2] if variant.size() > 2 else ""
		var variant_frame: int = variant[3] if variant.size() > 3 else 0
		option_sprite.add_icon_item(Defs.get_sprite_def(variant_sprite_id).frames[variant_frame], variant_name, variant_object_id)
		option_sprite.set_item_metadata(i, variant_sprite_id)

func _build_char_option() -> void:
	option_char.clear()
	for char in MainTab.hlm_char_data:
		var char_name: String = char["name"]
		var char_texture := Defs.get_sprite_def(char["sprite_id"]).frames[0]
		option_char.add_icon_item(
			char_texture,
			char_name
		)

func _build_mask_option() -> void:
	option_mask.clear()
	for key in MainTab.masks_data:
		var mask_name: String = MainTab.masks_data[key]
		var mask_texture := Defs.get_sprite_def(4139).frames[key] if key != -1 and key != NO_MASK_ID else Defs.get_sprite_def(4129).frames[0]
		option_mask.add_icon_item(mask_texture, mask_name)
		option_mask.set_item_metadata(option_mask.item_count - 1, key)

func _build_car_option() -> void:
	option_car.clear()
	for key in MainTab.cars_data:
		var car = MainTab.cars_data[key]
		option_car.add_icon_item(
			Defs.get_sprite_def(car["sprite_id"]).frames[0],
			"",
			car["object_id"]
		)

# -------------------------------------------------

func _on_player_option_pressed(index: int) -> void:
	_build_variant_option(index)
	_on_variant_option_pressed(0)

func _on_variant_option_pressed(index: int) -> void:
	var object_id: int = option_sprite.get_item_id(index)
	var sprite_id: int = option_sprite.get_item_metadata(index)
	var tool := ToolManager._tools[ToolManager.Tool.OBJ_PLACE] as ToolObjPlace
	tool.init(object_id, sprite_id, level_tab.Modes.MAIN)
	ToolManager.set_tool(ToolManager.Tool.OBJ_PLACE)

func _on_car_option_pressed(index: int) -> void:
	var object_id: int = option_car.get_item_id(index)
	var tool := ToolManager._tools[ToolManager.Tool.OBJ_PLACE] as ToolObjPlace
	tool.init(object_id, Defs.get_object(object_id).sprite_id, level_tab.Modes.MAIN)
	ToolManager.set_tool(ToolManager.Tool.OBJ_PLACE)

# --------------------------------------------------

func _on_b_floor_pressed() -> void:
	var tool := ToolManager._tools[ToolManager.Tool.TRANSITION] as ToolTransition
	var is_active := ToolManager.current() == tool and tool.current_subtool == ToolTransition.SubTool.TRANSITION
	if is_active:
		ToolManager.set_tool(ToolManager.Tool.SELECT)
	else:
		tool.init(ToolTransition.SubTool.TRANSITION)
		ToolManager.set_tool(ToolManager.Tool.TRANSITION)

func _on_b_elevator_pressed() -> void:
	var tool := ToolManager._tools[ToolManager.Tool.TRANSITION] as ToolTransition
	var is_active := ToolManager.current() == tool and tool.current_subtool == ToolTransition.SubTool.ELEVATOR
	if is_active:
		ToolManager.set_tool(ToolManager.Tool.SELECT)
	else:
		tool.init(ToolTransition.SubTool.ELEVATOR)
		ToolManager.set_tool(ToolManager.Tool.TRANSITION)

func _on_b_dark_pressed() -> void:
	var tool := ToolManager._tools[ToolManager.Tool.OVERLAYS] as ToolOverlays
	var is_active := ToolManager.current() == tool and tool.current_subtool == ToolOverlays.SubTool.DARKNESS
	if is_active:
		ToolManager.set_tool(ToolManager.Tool.SELECT)
	else:
		tool.init(ToolOverlays.SubTool.DARKNESS)
		ToolManager.set_tool(ToolManager.Tool.OVERLAYS)

func _on_b_rain_pressed() -> void:
	var tool := ToolManager._tools[ToolManager.Tool.OVERLAYS] as ToolOverlays
	var is_active := ToolManager.current() == tool and tool.current_subtool == ToolOverlays.SubTool.RAIN
	if is_active:
		ToolManager.set_tool(ToolManager.Tool.SELECT)
	else:
		tool.init(ToolOverlays.SubTool.RAIN)
		ToolManager.set_tool(ToolManager.Tool.OVERLAYS)

func _on_tool_changed(tool_id: ToolManager.Tool) -> void:
	b_floor.button_pressed = false
	b_elevator.button_pressed = false
	b_dark.button_pressed = false
	b_rain.button_pressed = false
	b_button.button_pressed = false
	if tool_id == ToolManager.Tool.TRANSITION and ToolManager._tools[ToolManager.Tool.TRANSITION].current_subtool == ToolTransition.SubTool.TRANSITION: b_floor.button_pressed = true
	elif tool_id == ToolManager.Tool.TRANSITION and ToolManager._tools[ToolManager.Tool.TRANSITION].current_subtool == ToolTransition.SubTool.ELEVATOR: b_elevator.button_pressed = true
	if tool_id == ToolManager.Tool.OVERLAYS and ToolManager._tools[ToolManager.Tool.OVERLAYS].current_subtool == ToolOverlays.SubTool.DARKNESS: b_dark.button_pressed = true
	elif tool_id == ToolManager.Tool.OVERLAYS and ToolManager._tools[ToolManager.Tool.OVERLAYS].current_subtool == ToolOverlays.SubTool.RAIN: b_rain.button_pressed = true
	if tool_id == ToolManager.Tool.BOUNDARIES: b_button.button_pressed = true

func _on_check_light_toggled(toggled_on: bool) -> void:
	editor_level.active_floor.light_overlays.clear()
	if toggled_on:
		editor_level.active_floor.light_overlays.append(Floor.DAYLIGHT_OVERLAY)
		check_sunset.set_pressed_no_signal(false)

func _on_check_sunset_toggled(toggled_on: bool) -> void:
	editor_level.active_floor.light_overlays.clear()
	if toggled_on:
		editor_level.active_floor.light_overlays.append(Floor.SUNSET_OVERLAY)
		check_light.set_pressed_no_signal(false)

func _on_b_button_pressed() -> void:
	if ToolManager.current() != ToolManager._tools[ToolManager.Tool.BOUNDARIES]:
		ToolManager.set_tool(ToolManager.Tool.BOUNDARIES)
	else:
		ToolManager.set_tool(ToolManager.Tool.SELECT)

func _on_b_left_value_changed(value: float) -> void:
	var boundary: Rect2i = editor_level.border_overlay._boundary
	editor_level.update_boundary(Rect2i(value, boundary.position.y, boundary.size.x, boundary.size.y))
func _on_b_top_value_changed(value: float) -> void:
	var boundary: Rect2i = editor_level.border_overlay._boundary
	editor_level.update_boundary(Rect2i(boundary.position.x, value, boundary.size.x, boundary.size.y))
func _on_b_right_value_changed(value: float) -> void:
	var boundary: Rect2i = editor_level.border_overlay._boundary
	editor_level.update_boundary(Rect2i(boundary.position.x, boundary.position.y, value, boundary.size.y))
func _on_b_bottom_value_changed(value: float) -> void:
	var boundary: Rect2i = editor_level.border_overlay._boundary
	editor_level.update_boundary(Rect2i(boundary.position.x, boundary.position.y, boundary.size.x, value))

func _on_boundaries_changed(new_boundaries: Rect2i) -> void:
	b_left.value = editor_level.level_info.boundaries.position.x
	b_top.value = editor_level.level_info.boundaries.position.y
	b_right.value = editor_level.level_info.boundaries.size.x
	b_bottom.value = editor_level.level_info.boundaries.size.y

# --------------------------------------------------

func _update_bg(level_info: LevelInfo) -> void:
	var bg_found := false
	for i in option_bg.item_count:
		if option_bg.get_item_id(i) == level_info.background_id and option_bg.get_item_id(i) != CUSTOM_BG_ID:
			option_bg.select(i)
			bg_found = true
			break
	if bg_found:
		line_bg.visible = false
	else:
		line_bg.visible = true
		line_bg.text = str(level_info.background_id)
		option_bg.select(option_bg.item_count - 1) 
	if level_info.music_id >= 0 and level_info.music_id < option_music.item_count:
		option_music.select(level_info.music_id)
	else:
		option_music.select(-1)

func _build_bg_option() -> void:
	option_bg.clear()
	for bg in MainTab.backgrounds_data:
		var bg_id: int = bg["object_id"]
		var bg_name: String = bg["name"]
		option_bg.add_item(bg_name, bg_id)
	
	option_bg.add_item("CUSTOM", CUSTOM_BG_ID)
	_on_bg_option_selected(0)

func _build_music_option() -> void:
	option_music.clear()
	for i in MainTab.music_data.size():
		var music_name: String = MainTab.music_data[i]
		option_music.add_item(music_name, i)

func _on_bg_option_selected(index: int) -> void:
	var item_id := option_bg.get_item_id(index)
	if item_id == CUSTOM_BG_ID:
		line_bg.visible = true
		if line_bg.text.is_valid_int():
			editor_level.level_info.background_id = int(line_bg.text)
	else:
		line_bg.visible = false
		editor_level.level_info.background_id = item_id

func _on_level_title_changed(new_text: String) -> void:
	editor_level.level_info.name = new_text

func _on_level_author_changed(new_text: String) -> void:
	editor_level.level_info.author = new_text

func _on_s_rank_value_changed(value: float) -> void:
	editor_level.level_info.s_rank = int(value)

func _on_cover_button_pressed() -> void:
	c_file_dialog.current_path = LevelScanner.cover_path()
	c_file_dialog.popup_centered()

func _on_cover_file_selected(path: String) -> void:
	var image := Image.load_from_file(path)
	if image:
		var texture := ImageTexture.create_from_image(image)
		cover_button.icon = texture
		editor_level.level_info.cover = texture

func _on_char_option_selected(index: int) -> void:
	editor_level.level_info.character_id = index

func _on_mask_option_selected(index: int) -> void:
	var mask_id = option_mask.get_item_metadata(index)
	editor_level.level_info.mask_id = mask_id

func _on_line_bg_text_changed(new_text: String) -> void:
	if new_text.is_valid_int():
		editor_level.level_info.background_id = int(new_text)

func _on_music_option_selected(index: int) -> void:
	editor_level.level_info.music_id = index

func _on_hour_value_changed(value: float) -> void:
	editor_level.level_info.hour = str(int(value))

func _on_minute_value_changed(value: float) -> void:
	editor_level.level_info.minute = str(int(value))

func _on_day_value_changed(value: float) -> void:
	editor_level.level_info.day = str(int(value))

func _on_month_value_changed(value: float) -> void:
	editor_level.level_info.month = str(int(value))

func _on_year_value_changed(value: float) -> void:
	editor_level.level_info.year = str(int(value))

func _on_city_text_changed(new_text: String) -> void:
	editor_level.level_info.city = new_text

func _on_state_text_changed(new_text: String) -> void:
	editor_level.level_info.state = new_text

func _on_address_text_changed(new_text: String) -> void:
	editor_level.level_info.address = new_text
