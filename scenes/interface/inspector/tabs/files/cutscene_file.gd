extends PanelContainer
class_name CutsceneFile

signal delete_requested(extension: String)

@onready var label: Label = $MarginContainer/HBox/Label
@onready var del_button: Button = $MarginContainer/Button

var _extension: String = ""

func _ready() -> void:
	del_button.pressed.connect(_on_del_button_pressed)

func setup(ext: String) -> void:
	_extension = ext
	label.text = ext

func _on_del_button_pressed() -> void:
	delete_requested.emit(_extension)
