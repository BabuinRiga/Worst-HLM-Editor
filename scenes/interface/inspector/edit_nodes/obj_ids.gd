extends PanelContainer
class_name ObjEd_Ids

@onready var sprite_label: Label = $MarginContainer/VBoxContainer/Labels/SpriteIds
@onready var object_label: Label = $MarginContainer/VBoxContainer/Labels/ObjectIds

@onready var sprite_input: LineEdit = $MarginContainer/VBoxContainer/Inputs/SpriteInput
@onready var object_input: LineEdit = $MarginContainer/VBoxContainer/Inputs/ObjectInput
@onready var frame_container: PanelContainer = $MarginContainer/VBoxContainer/FrameContainer
@onready var frame_input: SpinBox = $MarginContainer/VBoxContainer/FrameContainer/VBox/FrameInput
@onready var anim_container: VBoxContainer = $MarginContainer/VBoxContainer/AnimContainer
@onready var anim_input: SpinBox = $MarginContainer/VBoxContainer/AnimContainer/HBox/AnimInput
@onready var anim_slider: HSlider = $MarginContainer/VBoxContainer/AnimContainer/AnimSlider

var _sprites: Array[BaseSprite] = []
var _is_npc: bool = false
var _is_wall_or_door: bool = false
var _anim_old_values: Array = []
var _updating: bool = false

# -------------------------------------------------

func _setup(sprites: Array[BaseSprite]) -> void:
	_sprites = sprites
	_is_npc  = _sprites.all(func(s): return s is NPCObjectSprite)
	_is_wall_or_door = _sprites.all(func(s): return s is WallSprite or s is DoorSprite)

func _ready() -> void:
	sprite_input.text_submitted.connect(_on_sprite_submitted)
	object_input.text_submitted.connect(_on_object_submitted)
	frame_input.value_changed.connect(_on_frame_changed)
	anim_input.value_changed.connect(_on_anim_changed)
	
	anim_slider.value_changed.connect(_on_anim_slider_moved)
	anim_slider.drag_ended.connect(_on_anim_slider_released)
	
	_update_max_frame()
	_update()
	UndoRedoManager.history_changed.connect(_on_history_changed)

func _exit_tree() -> void:
	if UndoRedoManager.history_changed.is_connected(_on_history_changed):
		UndoRedoManager.history_changed.disconnect(_on_history_changed)

func _on_history_changed() -> void:
	_update_max_frame()
	_update()

# -------------------------------------------------

func _update() -> void:
	if _is_wall_or_door:
		frame_container.visible = false
		anim_container.visible = false
		object_label.visible = false
		object_input.visible = false
	else:
		frame_container.visible = not _is_npc
		anim_container.visible = _is_npc
		object_label.visible = true
		object_input.visible = true
	if _sprites.is_empty():
		return
	
	_updating = true
	
	var all_same := func(getter: Callable) -> bool:
		return _sprites.all(func(s): return getter.call(s) == getter.call(_sprites[0]))
	
	var get_sprite_id = func(s):
		if s is ObjectSprite: return s.object.sprite_id
		return s.sprite_id
	
	if all_same.call(get_sprite_id):
		sprite_input.text = str(get_sprite_id.call(_sprites[0]))
	else:
		sprite_input.text = ""
	
	if not _is_wall_or_door:
		if all_same.call(func(s): return s.object.object_id):
			object_input.text = str(_sprites[0].object.object_id)
		else:
			object_input.text = ""
		
		if _is_npc:
			if all_same.call(func(s): return s.object_frame):
				var speed: float = _sprites[0].object_frame
				anim_input.value = speed
				anim_slider.value = speed
			else:
				anim_input.value  = 0.0
				anim_slider.value = 0.0
		else:
			if all_same.call(func(s): return s.object_frame):
				frame_input.value = _sprites[0].object_frame + 1
			else:
				frame_input.value = 1
	
	_updating = false

func _update_max_frame() -> void:
	if _sprites.is_empty() or _is_npc or _is_wall_or_door:
		return
	var min_max = _sprites.map(func(s):
		var def := Defs.get_sprite_def(s.object.sprite_id)
		return def.frames.size() if def and not def.frames.is_empty() else 1
	).min()
	frame_input.max_value = min_max

# -------------------------------------------------

func _on_sprite_submitted(text: String) -> void:
	var id  := text.to_int()
	var def := Defs.get_sprite_def(id)
	if def == null:
		if _is_wall_or_door:
			sprite_input.text = str(_sprites[0].sprite_id)
		else:
			sprite_input.text = str(_sprites[0].object.sprite_id)
		return
	
	if _is_wall_or_door:
		_emit_wall_door_changed(id)
	else:
		_emit_changed(null, id, null)

func _on_object_submitted(text: String) -> void:
	if _is_wall_or_door: return
	var new_id := text.to_int()
	_emit_changed(new_id, null, null)

func _on_frame_changed(value: float) -> void:
	if _updating or _is_npc or _is_wall_or_door:
		return
	_emit_changed(null, null, int(value) - 1)

func _on_anim_changed(value: float) -> void:
	if _updating or not _is_npc or _is_wall_or_door:
		return
	_updating = true
	anim_slider.value = value
	_updating = false
	if not anim_slider.has_focus():
		_emit_changed(null, null, value)

func _on_anim_slider_moved(value: float) -> void:
	if _updating or not _is_npc or _is_wall_or_door:
		return
	
	if not anim_slider.has_focus() or _anim_old_values.is_empty():
		var targets: Array[ObjectSprite] = []
		targets.assign(_sprites)
		_anim_old_values = targets.map(func(s): return s.object_frame)
	
	_updating = true
	anim_input.value = value
	_updating = false
	
	for s in _sprites:
		if is_instance_valid(s) and s is ObjectSprite:
			s.object_frame = value

func _on_anim_slider_released(value_changed: bool) -> void:
	if not _is_npc or not value_changed or _is_wall_or_door:
		_anim_old_values.clear()
		return
	
	var new_val: float = anim_slider.value
	var targets: Array[ObjectSprite] = []
	targets.assign(_sprites.duplicate())
	
	var old_values := _anim_old_values.duplicate()
	_anim_old_values.clear()
	
	UndoRedoManager.commit(
		"EDR_NPC_SPEED",
		func():
			for s in targets:
				if is_instance_valid(s):
					s.object_frame = new_val,
		func():
			for i in range(targets.size()):
				if is_instance_valid(targets[i]):
					targets[i].object_frame = old_values[i],
	)

# -------------------------------------------------

func _emit_wall_door_changed(sprite_id: int) -> void:
	if _sprites.is_empty():
		return
		
	var targets = _sprites.duplicate()
	var snapshot = targets.map(func(s): return {
		"ref": s,
		"sid": s.sprite_id
	})

	UndoRedoManager.commit(
		"EDR_OBJ_PROP",
		func():
			for s in targets:
				if is_instance_valid(s):
					s.set_sprite_id(sprite_id),
		func():
			for d in snapshot:
				if is_instance_valid(d["ref"]):
					d["ref"].set_sprite_id(d["sid"])
	)

func _emit_changed(object_id, sprite_id, frame) -> void:
	if _sprites.is_empty(): return
	
	var targets: Array[ObjectSprite] = []
	targets.assign(_sprites.duplicate())
	
	if frame != null and targets.all(func(s: ObjectSprite): return s.object_frame == frame):
		return
	
	var snapshot := []
	var npc_ids = NPCObjectSprite.NPCobjectID
	
	for old_spr in targets:
		var new_spr = old_spr
		
		if object_id != null:
			var should_be_npc = (object_id in npc_ids) if npc_ids is Array else (object_id == npc_ids)
			var is_already_npc = old_spr is NPCObjectSprite
			
			if should_be_npc != is_already_npc:
				var obj_dup := old_spr.object.duplicate() as HLMObject
				obj_dup.object_id = object_id
				
				if should_be_npc:
					new_spr = NPCObjectSprite.new(obj_dup, old_spr.object_frame, LevelTab.Modes.OBJECTS)
				else:
					new_spr = ObjectSprite.new(obj_dup, old_spr.object_frame, LevelTab.Modes.OBJECTS)
				
				new_spr.global_position  = old_spr.global_position
				new_spr.rotation_degrees = old_spr.rotation_degrees
				new_spr.level            = old_spr.level
		
		var final_oid = object_id if object_id != null else old_spr.object.object_id
		var final_sid = sprite_id if sprite_id != null else old_spr.object.sprite_id
		var final_fr  = frame     if frame     != null else old_spr.object_frame
		
		snapshot.append({
			"old_node": old_spr,
			"new_node": new_spr,
			"parent": old_spr.get_parent(),
			"index": old_spr.get_index(),
			
			"do_method": &"set_ids",
			"do_args": [final_oid, final_sid, final_fr],
			
			"undo_method": &"set_ids",
			"undo_args": [old_spr.object.object_id, old_spr.object.sprite_id, old_spr.object_frame]
		})
	
	UndoRedoManager.commit(
		"EDR_OBJ_PROP",
		Callable(UndoRedoManager.TreeUtils, "do_replace").bind(snapshot),
		Callable(UndoRedoManager.TreeUtils, "undo_replace").bind(snapshot)
	)
	
	var final_targets: Array[BaseSprite] = []
	for d in snapshot:
		final_targets.append(d["new_ref"] if d.has("new_ref") else d["new_node"])
	_sprites.assign(final_targets)
	_is_npc = _sprites.all(func(s): return s is NPCObjectSprite)
