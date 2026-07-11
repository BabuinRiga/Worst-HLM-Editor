extends Node

@onready var level_tab = get_tree().get_first_node_in_group("LevelTab") as LevelTab

signal tool_changed(tool_id: Tool)

enum Tool {
	SELECT,
	OBJ_PLACE,
	TILE_PAINT,
	WALL_PLACE,
	DOOR_PLACE,
	ENTRY_PLACE,
	BARRIER_PLACE,
	
	TRANSITION,
	OVERLAYS,
	BOUNDARIES
}

var _current_tool: EditorTool = null
var _current_id:   Tool       = Tool.SELECT

var _tools: Dictionary = {}

func _ready() -> void:
	_tools[Tool.SELECT] = ToolSelect.new()
	_tools[Tool.OBJ_PLACE]  = ToolObjPlace.new()
	_tools[Tool.TILE_PAINT] = ToolTilePaint.new()
	_tools[Tool.WALL_PLACE] = ToolWallPlace.new()
	_tools[Tool.DOOR_PLACE] = ToolDoorPlace.new()
	_tools[Tool.ENTRY_PLACE] = ToolEntryPlace.new()
	_tools[Tool.BARRIER_PLACE] = ToolBarrierPlace.new()
	# ---
	_tools[Tool.TRANSITION] = ToolTransition.new()
	_tools[Tool.OVERLAYS] = ToolOverlays.new()
	_tools[Tool.BOUNDARIES] = ToolBoundaries.new()
	set_tool(Tool.SELECT)
	level_tab.mode_changed.connect(_on_mode_changed)

func set_tool(id: Tool) -> void:
	if _current_tool:
		_current_tool.deactivate()
	_current_id   = id
	_current_tool = _tools[id]
	_current_tool.activate()
	tool_changed.emit(id)

func current() -> EditorTool:
	return _current_tool

func current_id() -> Tool:
	return _current_id


func _on_mode_changed(new_mode: int) -> void:
	set_tool(Tool.SELECT)
