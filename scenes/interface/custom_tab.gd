extends VBoxContainer
class_name CustomTabController

@export var buttons_container: HBoxContainer
@export var target_tab_container: TabContainer

func _ready():
	if not buttons_container or not target_tab_container:
		return
	
	var buttons = buttons_container.get_children()
	for i in range(buttons.size()):
		var btn = buttons[i]
		if btn is BaseButton:
			btn.pressed.connect(_on_tab_button_pressed.bind(i))
			btn.toggle_mode = true 
	
	_update_buttons_state(target_tab_container.current_tab)

func _on_tab_button_pressed(tab_index: int):
	target_tab_container.current_tab = tab_index
	_update_buttons_state(tab_index)

func _update_buttons_state(active_index: int):
	var buttons = buttons_container.get_children()
	for i in range(buttons.size()):
		if buttons[i] is BaseButton:
			buttons[i].button_pressed = (i == active_index)
