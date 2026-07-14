extends ModalWindow

@onready var tools: PanelContainer = $Panel/VPanel/Content/ControlTab/Tools

func _ready() -> void:
	tools.visible = true
