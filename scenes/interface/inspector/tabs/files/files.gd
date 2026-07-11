extends PanelContainer
class_name FilesTab

@onready var file_list: VBoxContainer = $ScrollContainer/Margin/VBoxContainer
const CUTSCENE_FILE = preload("uid://ccayrx0tbow25")

@onready var editor_level: EditorLevel = get_tree().get_first_node_in_group("EditorLevel")

func _ready() -> void:
	editor_level.level_loaded.connect(_update_list)
	editor_level.floor_switched.connect(_on_floor_switched)

func _on_floor_switched(_floor: Floor) -> void:
	_update_list()

func _update_list() -> void:
	for child in file_list.get_children():
		child.queue_free()
	
	var active_floor = editor_level.get_active_floor()
	if not active_floor:
		return
	
	for ext in active_floor.cutscene_files.keys():
		var file_node := CUTSCENE_FILE.instantiate() as CutsceneFile
		file_list.add_child(file_node)
		
		file_node.setup(ext)
		file_node.delete_requested.connect(_on_file_delete_requested)

func _on_file_delete_requested(ext: String) -> void:
	var active_floor = editor_level.get_active_floor()
	if not active_floor or not active_floor.cutscene_files.has(ext):
		return
	
	var file_data: PackedByteArray = active_floor.cutscene_files[ext]
	
	UndoRedoManager.commit(
		"EDR_DEL_CS_FILE",
		func():
			if is_instance_valid(active_floor):
				active_floor.cutscene_files.erase(ext)
				editor_level.level_updated.emit()
				_update_list(),
		func():
			if is_instance_valid(active_floor):
				active_floor.cutscene_files[ext] = file_data
				editor_level.level_updated.emit()
				_update_list()
	)
