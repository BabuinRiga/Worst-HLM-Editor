extends PanelContainer
class_name ObjEd_Door

@onready var check_locked: CheckBox = $MarginContainer/HBoxContainer/CheckLocked
@onready var check_cutscene: CheckBox = $MarginContainer/HBoxContainer/CheckCutscene

var _sprites: Array[DoorSprite] = []

# -------------------------------------------------

func _setup(sprites: Array[DoorSprite]) -> void:
	_sprites = sprites

func _ready() -> void:
	_update()
	check_locked.toggled.connect(_on_locked_toggled)
	check_cutscene.toggled.connect(_on_cutscene_toggled)
	UndoRedoManager.history_changed.connect(_update)

func _exit_tree() -> void:
	if UndoRedoManager.history_changed.is_connected(_update):
		UndoRedoManager.history_changed.disconnect(_update)

# -------------------------------------------------

func _update() -> void:
	if _sprites.is_empty():
		return
	
	var all_locked_same := _sprites.all(func(s: DoorSprite): return s.locked == _sprites[0].locked)
	var all_cutscene_same := _sprites.all(func(s: DoorSprite): return s.cutscene == _sprites[0].cutscene)
	
	if all_locked_same:
		check_locked.set_pressed_no_signal(bool(_sprites[0].locked))
	else:
		check_locked.set_pressed_no_signal(false)
		
	if all_cutscene_same:
		check_cutscene.set_pressed_no_signal(bool(_sprites[0].cutscene))
	else:
		check_cutscene.set_pressed_no_signal(false)

# -------------------------------------------------

func _on_locked_toggled(toggled_on: bool) -> void:
	if _sprites.is_empty():
		return
	
	var new_val := 1 if toggled_on else 0
	var targets: Array[DoorSprite] = []
	targets.assign(_sprites.duplicate())
	
	var snapshot := targets.map(func(s): return {
		"ref": s,
		"val": s.locked
	})
	
	var do_action = func():
		for s in targets:
			if is_instance_valid(s):
				s.locked = new_val
		
	var undo_action = func():
		for d in snapshot:
			if is_instance_valid(d["ref"]):
				d["ref"].locked = d["val"]
	
	UndoRedoManager.commit("EDR_DOOR_LOCKED", do_action, undo_action)


func _on_cutscene_toggled(toggled_on: bool) -> void:
	if _sprites.is_empty():
		return
	
	var new_val := 1 if toggled_on else 0
	var targets: Array[DoorSprite] = []
	targets.assign(_sprites.duplicate())
	
	var snapshot := targets.map(func(s): return {
		"ref": s,
		"val": s.cutscene
	})
	
	var do_action = func():
		for s in targets:
			if is_instance_valid(s):
				s.cutscene = new_val
		
	var undo_action = func():
		for d in snapshot:
			if is_instance_valid(d["ref"]):
				d["ref"].cutscene = d["val"]
	
	UndoRedoManager.commit("EDR_DOOR_CUTSCENE", do_action, undo_action)
