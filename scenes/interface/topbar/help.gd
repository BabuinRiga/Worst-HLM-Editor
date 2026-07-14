extends PopupMenu

const CONTROL_GUIDE = preload("uid://fhlwtcqum6e4")

func _ready() -> void:
	_init_help()


func _init_help() -> void:
	id_pressed.connect(_on_help_id_pressed)

func _on_help_id_pressed(id: int) -> void:
	match id:
		0:
			_open_about()
		1:
			_open_control_popup()


# -------------------------------------------------------


func _open_about() -> void:
	OS.shell_open("https://github.com/BabuinRiga/Worst-HLM-Editor")

func _open_control_popup() -> void:
	var modal_layer = get_tree().current_scene.get_node("Interface/ModalLayer") as CanvasLayer
	var modal = CONTROL_GUIDE.instantiate()
	modal_layer.add_child(modal)
