extends PanelContainer
class_name TopBar

@onready var change_save: MarginContainer = $MarginContainer/HBoxLeft/ChangeSave
@onready var level_name: Label = $MarginContainer/HBoxLeft/LevelName

@onready var file: PopupMenu = $MarginContainer/HBoxLeft/MenuBar/File
@onready var edit: PopupMenu = $MarginContainer/HBoxLeft/MenuBar/Edit
@onready var view: View = $MarginContainer/HBoxLeft/MenuBar/View
@onready var settings: Settings = $MarginContainer/HBoxLeft/MenuBar/Settings

@onready var editor_level = get_tree().get_first_node_in_group("EditorLevel") as EditorLevel

# ------------------------------------------------- UndoRedo

var _undo_held := false
var _redo_held := false
var _hold_timer := 0.0
var _repeat_timer := 0.0
const HOLD_DELAY    := 0.5
const REPEAT_RATE   := 0.05

# -------------------------------------------------

func _ready() -> void:
	_add_shortcuts()
	UndoRedoManager.history_changed.connect(_on_commit)

func _process(delta: float) -> void:
	if _undo_held:
		if not Input.is_action_pressed("Undo"):
			_undo_held = false
			return
			
		_hold_timer += delta
		if _hold_timer >= HOLD_DELAY:
			_repeat_timer += delta
			if _repeat_timer >= REPEAT_RATE:
				_repeat_timer = 0.0
				UndoRedoManager.undo()
				
	elif _redo_held:
		if not Input.is_action_pressed("Redo"):
			_redo_held = false
			return
			
		_hold_timer += delta
		if _hold_timer >= HOLD_DELAY:
			_repeat_timer += delta
			if _repeat_timer >= REPEAT_RATE:
				_repeat_timer = 0.0
				UndoRedoManager.redo()

func _input(event: InputEvent) -> void:
	if event.is_action("Redo", true):
		var focused := get_viewport().gui_get_focus_owner()
		if focused is LineEdit or focused is TextEdit or focused is SpinBox:
			return
		if event.pressed and not event.is_echo():
			_redo_held = true
			_hold_timer = 0.0
			_repeat_timer = 0.0
			UndoRedoManager.redo()
			get_viewport().set_input_as_handled()
		elif not event.pressed:
			_redo_held = false
	elif event.is_action("Undo", true):
		var focused := get_viewport().gui_get_focus_owner()
		if focused is LineEdit or focused is TextEdit or focused is SpinBox:
			return
		if event.pressed and not event.is_echo():
			_undo_held = true
			_hold_timer = 0.0
			_repeat_timer = 0.0
			UndoRedoManager.undo()
			get_viewport().set_input_as_handled()
		elif not event.pressed:
			_undo_held = false

# -------------------------------------------------

func _add_shortcuts() -> void:
	var sc: Shortcut
	var ev: InputEvent
	
	sc = Shortcut.new()
	ev = InputMap.action_get_events("SaveLvl")[0]
	sc.events = [ev]
	file.set_item_shortcut(3, sc, true)
	
	sc = Shortcut.new()
	ev = InputMap.action_get_events("Undo")[0]
	sc.events = [ev]
	edit.set_item_shortcut(0, sc, true)
	sc = Shortcut.new()
	ev = InputMap.action_get_events("Redo")[0]
	sc.events = [ev]
	edit.set_item_shortcut(1, sc, true)

func _on_commit() -> void:
	_update_name()
	if UndoRedoManager.is_dirty():
		change_save.visible = true
	else:
		change_save.visible = false

func _update_name() -> void:
	level_name.text = editor_level.level_info.name if editor_level.level_info.exist else "Worst HLM Editor"
