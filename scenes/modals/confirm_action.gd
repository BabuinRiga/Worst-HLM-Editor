extends ModalWindow

@onready var yes: Button = $Panel/VPanel/MarginPanels/Panels/Yes

signal confirmed


func _ready() -> void:
	yes.pressed.connect(_on_yes_pressed)

func _on_yes_pressed() -> void:
	confirmed.emit()
	close()
