extends Node2D

@onready var editor_level: EditorLevel = get_tree().get_first_node_in_group("EditorLevel")
@onready var modal_layer: CanvasLayer = $Interface/ModalLayer
