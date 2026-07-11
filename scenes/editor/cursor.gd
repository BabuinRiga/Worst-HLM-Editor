extends Node2D
class_name Cursor

func _ready() -> void:
	ToolManager.tool_changed.connect(_on_tool_changed)
	UndoRedoManager.history_changed.connect(_on_history_changed)

func _unhandled_input(event: InputEvent) -> void:
	if ToolManager.current().handle_input(event):
		queue_redraw()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion:
		queue_redraw()

func _draw() -> void:
	ToolManager.current().draw(self)

func _on_tool_changed(tool_id: ToolManager.Tool) -> void:
	queue_redraw()

func _on_history_changed() -> void:
	queue_redraw()
