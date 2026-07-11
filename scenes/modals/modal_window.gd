extends PanelContainer
class_name ModalWindow

@onready var cancel: Button = $Panel/VPanel/MarginPanels/Panels/Cancel

func close() -> void:
	queue_free()

func _on_cancel_pressed() -> void:
	close()
