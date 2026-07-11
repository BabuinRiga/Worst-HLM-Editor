extends Node

signal selection_changed(sprites: Array[BaseSprite])

var selected: Array[BaseSprite] = []

func _ready() -> void:
	if UndoRedoManager.history_changed.is_connected(validate_selection):
		return
	UndoRedoManager.history_changed.connect(validate_selection)

func validate_selection() -> void:
	var old_size = selected.size()
	var valid_selection: Array[BaseSprite] = []
	
	for s in selected:
		if is_instance_valid(s) and s.is_inside_tree():
			valid_selection.append(s)
		elif is_instance_valid(s):
			s.set_selected(false)
			
	if valid_selection.size() != old_size:
		selected = valid_selection
		selection_changed.emit(selected)

func select_one(sprite: BaseSprite) -> void:
	_deselect_all_silent()
	selected.append(sprite)
	sprite.set_selected(true)
	selection_changed.emit(selected)

func add_to_selection(sprite: BaseSprite) -> void:
	if sprite in selected:
		selected.erase(sprite)
		sprite.set_selected(false)
	else:
		selected.append(sprite)
		sprite.set_selected(true)
	selection_changed.emit(selected)

func select_many(sprites: Array[BaseSprite]) -> void:
	_deselect_all_silent()
	for s in sprites:
		selected.append(s)
		s.set_selected(true)
	selection_changed.emit(selected)

func clear() -> void:
	_deselect_all_silent()
	selection_changed.emit(selected)

func _deselect_all_silent() -> void:
	for s in selected:
		if is_instance_valid(s):
			s.set_selected(false)
	selected.clear()
