class_name EditorTool
extends RefCounted

var level_tab = (Engine.get_main_loop() as SceneTree).get_first_node_in_group("LevelTab") as LevelTab
var editor_level = (Engine.get_main_loop() as SceneTree).get_first_node_in_group("EditorLevel") as EditorLevel

func activate() -> void:
	pass

func deactivate() -> void:
	pass

func handle_input(event: InputEvent) -> bool:
	return false

func draw(canvas: CanvasItem) -> void:
	pass

# --------------------------------------------------

func _world_pos() -> Vector2:
	var cam = editor_level.camera_2d
	return cam.get_global_mouse_position() if cam else Vector2.ZERO
