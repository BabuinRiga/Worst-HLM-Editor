extends PanelContainer

@onready var file: PopupMenu = $MarginContainer/HBoxLeft/MenuBar/File

func _ready() -> void:
	_add_shortcuts()

func _process(delta: float) -> void:
	pass


func _add_shortcuts() -> void:
	var sc: Shortcut
	var ev: InputEvent
	
	sc = Shortcut.new()
	ev = InputMap.action_get_events("SaveLvl")[0]
	sc.events = [ev]
	file.set_item_shortcut(3, sc)
