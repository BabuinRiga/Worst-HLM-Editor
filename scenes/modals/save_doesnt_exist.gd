extends ModalWindow

signal save_non_exist_level

@onready var editor_level = get_tree().get_first_node_in_group("EditorLevel") as EditorLevel
@onready var top_bar = get_tree().get_first_node_in_group("TopBar") as TopBar
@onready var yes: Button = $Panel/VPanel/MarginPanels/Panels/Yes

func _ready() -> void:
	top_bar.file.set_item_disabled(3, true)
	yes.pressed.connect(_on_yes_pressed)

func _on_yes_pressed() -> void:
	save_non_exist_level.emit()
	close()

func close() -> void:
	top_bar.file.set_item_disabled(3, false)
	super.close()
