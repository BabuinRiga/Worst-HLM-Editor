extends PopupMenu

const LOAD_FILE = preload("uid://cf2gawcj36dkd")
@onready var modal_layer: CanvasLayer = $"../../../../../../../ModalLayer"
@onready var editor_level = get_tree().get_first_node_in_group("EditorLevel") as EditorLevel


func _ready() -> void:
	id_pressed.connect(_on_file_pressed)
	editor_level.level_updated.connect(_on_level_updated)


func _on_file_pressed(id: int) -> void:
	match id:
		0:
			_create_file()
		1:
			pass
		2:
			_load_file()
		3:
			_save_file()
		4:
			pass
		5:
			_open_file_path()
		_:
			pass

func _create_file() -> void:
	var load_untitled = func(): editor_level._load_resource_level("res://resources/levels/untitled")
	if UndoRedoManager.is_dirty():
		const CONFIRM_MODAL = preload("uid://cb62o12ru8h5b")
		var modal = CONFIRM_MODAL.instantiate()
		modal.confirmed.connect(func():
			load_untitled.call()
		)
		modal_layer.add_child(modal)
	else:
		load_untitled.call()

func _load_file() -> void:
	var modal = LOAD_FILE.instantiate()
	modal.level_selected.connect(func(info: LevelInfo):
		editor_level.load_level(info)
	)
	modal_layer.add_child(modal)

func _save_file() -> void:
	if modal_layer.get_child_count() > 1: return
	editor_level.save_level()

func _open_file_path() -> void:
	var level_info = editor_level.level_info
	if not level_info:
		return
	var file_path = level_info.hlm_path
	if editor_level.level_info.exist and FileAccess.file_exists(file_path):
		OS.shell_show_in_file_manager(file_path)

func _on_level_updated() -> void:
	var level_exist: bool = editor_level.level_info.exist
	set_item_disabled(5, !level_exist)
