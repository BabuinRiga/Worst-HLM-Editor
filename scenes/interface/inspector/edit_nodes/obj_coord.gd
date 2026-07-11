extends PanelContainer
class_name ObjEd_Coord

@onready var x_input: SpinBox = $MarginContainer/VBoxContainer/Inputs/SpriteInput
@onready var y_input: SpinBox = $MarginContainer/VBoxContainer/Inputs/ObjectInput
@onready var angle_input: SpinBox  = $MarginContainer/VBoxContainer/AnglePanel/AngleInput
@onready var angle_panel: VBoxContainer = $MarginContainer/VBoxContainer/AnglePanel

var _base_angle: float = 0.0
var _sprites: Array[BaseSprite] = []
var _updating: bool = false

# -------------------------------------------------

func _setup(sprites: Array[BaseSprite]) -> void:
	_sprites = sprites
	for s in _sprites:
		if not s.xya_changed.is_connected(_update):
			s.xya_changed.connect(_update)

func _ready() -> void:
	_update()
	x_input.value_changed.connect(func(t): _emit_move(float(t), null))
	y_input.value_changed.connect(func(t): _emit_move(null, float(t)))
	angle_input.value_changed.connect(func(t): _emit_rotate(float(t)))

func _exit_tree() -> void:
	for s in _sprites:
		if s.xya_changed.is_connected(_update):
			s.xya_changed.disconnect(_update)

# -------------------------------------------------

func _get_center() -> Vector2:
	var sum := Vector2.ZERO
	for s in _sprites:
		sum += s.global_position
	return sum / _sprites.size()

func _update() -> void:
	if _sprites.is_empty():
		return
	_updating = true
	var center := _get_center()
	x_input.value = center.x
	y_input.value = center.y
	
	if _sprites.all(func(s): return s is ObjectSprite):
		angle_panel.visible = true
		var all_same_angle := _sprites.all(func(s): return s.rotation_degrees == _sprites[0].rotation_degrees)
		_base_angle = _sprites[0].rotation_degrees if all_same_angle else 0.0
		angle_input.value = _sprites[0].rotation_degrees if all_same_angle else 0.0
	else:
		angle_panel.visible = false
	_updating = false

# -------------------------------------------------

func _emit_move(new_x, new_y) -> void:
	if _updating: return
	if _sprites.is_empty(): return
	if new_x and _sprites.all(func(s: BaseSprite): return s.global_position.x == new_x): return
	if new_y and _sprites.all(func(s: BaseSprite): return s.global_position.y == new_y): return
	
	var old_center := _get_center()
	var target_x: float = new_x if new_x != null else old_center.x
	var target_y: float = new_y if new_y != null else old_center.y
	var delta := Vector2(target_x, target_y) - old_center
	
	var targets   := _sprites.duplicate()
	var snapshot  := targets.map(func(s): return { "ref": s, "pos": s.global_position })
	
	UndoRedoManager.commit(
		"EDR_SPR_MOVE",
		func():
			for s in targets:
				if is_instance_valid(s):
					s.global_position += delta
					if s.has_method("set_coords"):
						s.set_coords(s.global_position),
		func():
			for d in snapshot:
				if is_instance_valid(d["ref"]):
					d["ref"].global_position = d["pos"]
					if d["ref"].has_method("set_coords"):
						d["ref"].set_coords(d["pos"])
	)

func _emit_rotate(new_angle: float) -> void:
	if _updating: return
	if _sprites.is_empty(): return
	if new_angle and _sprites.all(func(s: BaseSprite): return s.rotation_degrees == new_angle): return
	
	var center    := _get_center()
	var targets   := _sprites.duplicate()
	var snapshot  := targets.map(func(s): return {
		"ref": s,
		"pos": s.global_position,
		"rot": s.rotation_degrees
	})
	var delta_rad := deg_to_rad(new_angle - _base_angle)
	_base_angle = new_angle
	
	UndoRedoManager.commit(
		"EDR_SPR_ROTATE",
		func():
			for d in snapshot:
				var s = d["ref"]
				if not is_instance_valid(s): continue
				s.global_position = center + (d["pos"] - center).rotated(delta_rad).round()
				s.rotation_degrees = d["rot"] + rad_to_deg(delta_rad)
				if s.has_method("set_coords"): s.set_coords(s.global_position)
				if s.has_method("set_angle"):  s.set_angle(s.rotation_degrees),
		func():
			for d in snapshot:
				if not is_instance_valid(d["ref"]): continue
				d["ref"].global_position  = d["pos"]
				d["ref"].rotation_degrees = d["rot"]
				if d["ref"].has_method("set_coords"): d["ref"].set_coords(d["pos"])
				if d["ref"].has_method("set_angle"):  d["ref"].set_angle(d["rot"])
	)
