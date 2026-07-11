extends MarginContainer

@onready var close: Button = $Object/VBox/TitlePanel/Close
@onready var sprite_bg: TextureRect = $SpriteBG
@onready var edit_nodes: VBoxContainer = $Object/VBox/EditNodes

@onready var editor_level = get_tree().get_first_node_in_group("EditorLevel") as EditorLevel

# ------------------------------ НОДЫ ОБЪЕКТОВ

const OBJ_COUNT = preload("uid://ceijvc3xae0j8")
const OBJ_PREVIEW = preload("uid://ct1y0rntv0ku4")
const OBJ_IDS = preload("uid://cu5yywhit8efh")
const OBJ_COORD = preload("uid://tlwafnkrjgrg")
const DOOR_PRM = preload("uid://bngpcqfwj5w6c")
const TRANSITION_PRM = preload("uid://jrram36rfvkb")

# ------------------------------

var _sprites: Array[BaseSprite] = []

func _ready() -> void:
	visible = false
	_change_bg()
	
	Selection.selection_changed.connect(_on_selection_changed)
	close.pressed.connect(_on_close_pressed)
	editor_level.level_loaded.connect(_on_close_pressed)

# ------------------------------

func _rebuild_nodes() -> void:
	_clear_nodes()
	if _sprites.is_empty():
		return
	# --- Количество выделенного
	var obj_count: ObjEd_Count = OBJ_COUNT.instantiate()
	obj_count._setup(_sprites)
	edit_nodes.add_child(obj_count)
	# --- ObjectSprite / WallSprite / DoorSprite
	var is_first_wod = [ObjectSprite, WallSprite, DoorSprite].any(func(t): return is_instance_of(_sprites[0], t))
	var is_all_objects = _sprites.all(func(s): return s is ObjectSprite)
	var is_all_walls = _sprites.all(func(s): return s is WallSprite)
	var is_all_doors = _sprites.all(func(s): return s is DoorSprite)
	if is_first_wod:
		var obj_sprites: Array[BaseSprite] = []
		obj_sprites.assign(_sprites)
		if obj_sprites.size() == 1:
			var obj_prev: ObjEd_Preview = OBJ_PREVIEW.instantiate()
			obj_prev._sprite = obj_sprites[0]
			edit_nodes.add_child(obj_prev)
	if is_all_objects or is_all_walls or is_all_doors:
		var obj_ids: ObjEd_Ids = OBJ_IDS.instantiate()
		obj_ids._setup(_sprites)
		edit_nodes.add_child(obj_ids)
	if is_all_doors:
		var door_sprites: Array[DoorSprite] = []
		door_sprites.assign(_sprites)
		var door_prm: ObjEd_Door = DOOR_PRM.instantiate()
		door_prm._setup(door_sprites)
		edit_nodes.add_child(door_prm)
	# --- Переходы
	var is_all_transitions := _sprites.all(func(s): return s is TransitionSprite)
	var is_all_elevators   := _sprites.all(func(s): return s is ElevatorSprite)
	if is_all_transitions or is_all_elevators or (is_all_transitions or is_all_elevators):
		var trans_prm: ObjEd_Transition = TRANSITION_PRM.instantiate()
		trans_prm._setup(_sprites)
		edit_nodes.add_child(trans_prm)
	# --- Координаты
	#var first_class = _sprites[0].get_script()
	#if _sprites.all(func(s): return s.get_script() == first_class):
	var coord: ObjEd_Coord = OBJ_COORD.instantiate()
	coord._setup(_sprites)
	edit_nodes.add_child(coord)

func _clear_nodes() -> void:
	for child in edit_nodes.get_children():
		child.queue_free()

# ------------------------------

func _on_selection_changed(sprites: Array[BaseSprite]) -> void:
	_sprites = sprites
	if _sprites.is_empty():
		visible = false
	else:
		visible = true
	_change_bg()
	_rebuild_nodes()

func _on_close_pressed() -> void:
	visible = false
	Selection.clear()
	_change_bg()
	_rebuild_nodes()


func _change_bg() -> void:
	if not _sprites.is_empty():
		var tex = _sprites[0].texture
		sprite_bg.texture = tex
		sprite_bg.material.set_shader_parameter("sprite_texture", tex)
	else:
		sprite_bg.texture = null
