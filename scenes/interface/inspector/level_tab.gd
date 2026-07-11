extends TabContainer
class_name LevelTab

@onready var tiles: TilesTab = $Tiles
@onready var objects: ObjectsTab = $Objects
@onready var enemy: EnemyTab = $Enemy
@onready var misc: MiscTab = $Misc
@onready var main: MainTab = $Main

enum Modes {
	TILES,
	OBJECTS,
	ENEMY,
	MISC,
	MAIN
}

var current_mode = Modes.MAIN

signal mode_changed(new_mode: int)


func _ready() -> void:
	main.visible = true


func _on_tab_changed(tab: int) -> void:
	current_mode = tab
	mode_changed.emit(current_mode)
