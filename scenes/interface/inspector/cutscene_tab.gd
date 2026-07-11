extends TabContainer
class_name CutsceneTab

@onready var files: PanelContainer = $Files
@onready var frames: PanelContainer = $Frames
@onready var npc: PanelContainer = $NPC

func _ready() -> void:
	files.visible = true
