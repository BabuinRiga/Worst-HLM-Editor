extends PanelContainer
class_name ObjEd_Count

@onready var count_label: Label = $MarginContainer/Count

var count: int

func _setup(sprites: Array[BaseSprite]) -> void:
	count = sprites.size()

func _ready() -> void:
	count_label.text = tr("SELECTED_C") % count
