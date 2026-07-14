extends PanelContainer
class_name ObjEd_Tls

@onready var depth_spin: SpinBox = $MarginContainer/VBoxContainer/DepthSpin

var _sprites: Array[BaseSprite] = []
var _updating: bool = false

# -------------------------------------------------

func _setup(sprites: Array[BaseSprite]) -> void:
	_sprites = sprites

func _ready() -> void:
	depth_spin.value_changed.connect(_on_depth_changed)
	_update()
	UndoRedoManager.history_changed.connect(_on_history_changed)

func _exit_tree() -> void:
	if UndoRedoManager.history_changed.is_connected(_on_history_changed):
		UndoRedoManager.history_changed.disconnect(_on_history_changed)

func _on_history_changed() -> void:
	_update()

# -------------------------------------------------

func _update() -> void:
	if _sprites.is_empty():
		return
	
	_updating = true
	
	var first_depth = _sprites[0].depth
	var all_same = _sprites.all(func(s): return s is TileSprite and s.depth == first_depth)
	
	if all_same:
		depth_spin.value = first_depth
	
	_updating = false

func _on_depth_changed(value: float) -> void:
	if _updating or _sprites.is_empty():
		return
		
	var new_depth := int(value)
	var targets := _sprites.duplicate()
	
	if targets.all(func(s): return s is TileSprite and s.depth == new_depth):
		return
	
	var old_depths = targets.map(func(s): return s.depth)
	
	UndoRedoManager.commit(
		"EDR_TILE_DEPTH",
		func():
			for s in targets:
				if is_instance_valid(s) and s is TileSprite:
					_apply_depth(s, new_depth),
		func():
			for i in range(targets.size()):
				var s = targets[i]
				if is_instance_valid(s) and s is TileSprite:
					_apply_depth(s, old_depths[i])
	)

func _apply_depth(sprite: TileSprite, new_depth: int) -> void:
	sprite.depth = new_depth
	sprite.z_index = -new_depth
	
	var t_size = 16 if new_depth > -99 else 8
	sprite.region_rect = Rect2(sprite.tile_x, sprite.tile_y, t_size, t_size)
