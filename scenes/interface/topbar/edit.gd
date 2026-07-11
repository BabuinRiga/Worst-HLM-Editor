extends PopupMenu

@onready var editor_level = get_tree().get_first_node_in_group("EditorLevel") as EditorLevel


func _ready() -> void:
	id_pressed.connect(_on_edit_pressed)


func _on_edit_pressed(id: int) -> void:
	match id:
		0:
			UndoRedoManager.undo()
		1:
			UndoRedoManager.redo()
		_:
			pass
