extends PanelContainer
class_name ObjEd_Transition

@onready var option_floor:   OptionButton = $MarginContainer/VBoxContainer/VBoxFloor/OptionFloor
@onready var offset_box:     Control      = $MarginContainer/VBoxContainer/HBoxOffset
@onready var spin_offset_x:  SpinBox      = $MarginContainer/VBoxContainer/HBoxOffset/VBoxX/SpinBox
@onready var spin_offset_y:  SpinBox      = $MarginContainer/VBoxContainer/HBoxOffset/VBoxY/SpinBox

var editor_level = (Engine.get_main_loop() as SceneTree).get_first_node_in_group("EditorLevel") as EditorLevel

var _sprites:  Array[BaseSprite] = []
var _is_mixed: bool = false
var _updating: bool = false

# -------------------------------------------------

func _setup(sprites: Array[BaseSprite]) -> void:
	_sprites = sprites
	var is_all_transition := _sprites.all(func(s): return s is TransitionSprite)
	var is_all_elevator   := _sprites.all(func(s): return s is ElevatorSprite)
	_is_mixed = not (is_all_transition or is_all_elevator)

func _ready() -> void:
	_refresh_floor_list()
	option_floor.item_selected.connect(_on_floor_selected)
	spin_offset_x.value_changed.connect(_on_offset_changed)
	spin_offset_y.value_changed.connect(_on_offset_changed)
	
	if editor_level != null:
		editor_level.level_loaded.connect(_on_level_loaded)
	
	_update()
	UndoRedoManager.history_changed.connect(_on_history_changed)

func _exit_tree() -> void:
	if UndoRedoManager.history_changed.is_connected(_on_history_changed):
		UndoRedoManager.history_changed.disconnect(_on_history_changed)
	if editor_level != null and editor_level.level_loaded.is_connected(_on_level_loaded):
		editor_level.level_loaded.disconnect(_on_level_loaded)

func _on_history_changed() -> void:
	_update()

func _on_level_loaded() -> void:
	_refresh_floor_list()
	_update()

# -------------------------------------------------

func _refresh_floor_list() -> void:
	option_floor.clear()
	if editor_level == null:
		return
	for i in range(editor_level.get_floor_count()):
		option_floor.add_item(tr("FLOOR") + " " + str(i + 1), i)

func _update() -> void:
	offset_box.visible = not _is_mixed
	
	if _sprites.is_empty():
		return
	
	_updating = true
	
	var all_same := func(getter: Callable) -> bool:
		return _sprites.all(func(s): return getter.call(s) == getter.call(_sprites[0]))
	
	if all_same.call(func(s): return s.target_floor):
		var idx := option_floor.get_item_index(_sprites[0].target_floor)
		if idx != -1:
			option_floor.select(idx)
		else:
			option_floor.select(-1)
	else:
		option_floor.select(-1)
	
	if not _is_mixed:
		if all_same.call(func(s): return s.transition_offset):
			var off: Vector2i = _sprites[0].transition_offset
			spin_offset_x.value = off.x
			spin_offset_y.value = off.y
		else:
			spin_offset_x.value = 0
			spin_offset_y.value = 0
	
	_updating = false

# -------------------------------------------------

func _on_floor_selected(index: int) -> void:
	if _updating or _sprites.is_empty():
		return
	var new_floor := option_floor.get_item_id(index)
	_emit_changed(new_floor, null)

func _on_offset_changed(_value: float) -> void:
	if _updating or _is_mixed or _sprites.is_empty():
		return
	var new_offset := Vector2i(int(spin_offset_x.value), int(spin_offset_y.value))
	_emit_changed(null, new_offset)

# -------------------------------------------------

func _emit_changed(new_floor, new_offset) -> void:
	if _sprites.is_empty():
		return
	
	var targets := _sprites.duplicate()
	
	var unchanged := targets.all(func(s):
		var floor_ok = new_floor == null or s.target_floor == new_floor
		var offset_ok = new_offset == null or s.transition_offset == new_offset
		return floor_ok and offset_ok
	)
	if unchanged:
		return
	
	var snapshot := targets.map(func(s): return {
		"ref":         s,
		"old_floor":   s.target_floor,
		"old_offset":  s.transition_offset,
	})
	
	UndoRedoManager.commit(
		"EDR_TRANSITION_PROP",
		func():
			for s in targets:
				if is_instance_valid(s):
					if new_floor != null:
						s.target_floor = new_floor
					if new_offset != null:
						s.transition_offset = new_offset
					if s.has_method("queue_redraw"):
						s.queue_redraw(),
		func():
			for d in snapshot:
				if is_instance_valid(d["ref"]):
					d["ref"].target_floor      = d["old_floor"]
					d["ref"].transition_offset = d["old_offset"]
					if d["ref"].has_method("queue_redraw"):
						d["ref"].queue_redraw()
	)
