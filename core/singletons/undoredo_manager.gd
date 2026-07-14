extends Node

signal history_changed

var _saved_index: int = 0
var _undo_stack: Array = []
var _redo_stack: Array = []
var _dirty: bool = false

# -------------------------------------------------

class Command:
	var execute: Callable
	var revert:  Callable
	var label:   String
	func _init(lbl: String, do_fn: Callable, undo_fn: Callable) -> void:
		label   = lbl
		execute = do_fn
		revert  = undo_fn

# -------------------------------------------------

class TreeUtils:
	static func do_replace(snapshot: Array) -> void:
		for d in snapshot:
			var old_node = d.get("old_node")
			var new_node = d.get("new_node")
			var parent = d.get("parent")
			
			if old_node != new_node and is_instance_valid(parent):
				if old_node.is_inside_tree():
					parent.remove_child(old_node)
				if not new_node.is_inside_tree():
					parent.add_child(new_node)
					parent.move_child(new_node, d.get("index", -1))
			
			if is_instance_valid(new_node) and d.has("do_method"):
				new_node.callv(d["do_method"], d["do_args"])
	
	static func undo_replace(snapshot: Array) -> void:
		for d in snapshot:
			var old_node = d.get("old_node")
			var new_node = d.get("new_node")
			var parent = d.get("parent")
			
			if old_node != new_node and is_instance_valid(parent):
				if new_node.is_inside_tree():
					parent.remove_child(new_node)
				if not old_node.is_inside_tree():
					parent.add_child(old_node)
					parent.move_child(old_node, d.get("index", -1))
			
			if is_instance_valid(old_node) and d.has("undo_method"):
				old_node.callv(d["undo_method"], d["undo_args"])

# -------------------------------------------------

func commit(label: String, do_fn: Callable, undo_fn: Callable) -> void:
	do_fn.call()
	_undo_stack.push_back(Command.new(label, do_fn, undo_fn))
	_redo_stack.clear()
	_dirty = true
	history_changed.emit()

func redo() -> void:
	if _redo_stack.is_empty(): return
	var cmd: Command = _redo_stack.pop_back()
	if cmd.execute.is_valid():
		cmd.execute.call()
	_undo_stack.push_back(cmd)
	_dirty = _undo_stack.size() != _saved_index
	history_changed.emit()

func undo() -> void:
	if _undo_stack.is_empty(): return
	var cmd: Command = _undo_stack.pop_back()
	if cmd.revert.is_valid():
		cmd.revert.call()
	_redo_stack.push_back(cmd)
	_dirty = _undo_stack.size() != _saved_index
	history_changed.emit()

func mark_saved() -> void:
	_saved_index = _undo_stack.size()
	_dirty = false
	history_changed.emit()

func clear_history() -> void:
	_undo_stack.clear()
	_redo_stack.clear()
	_saved_index = 0
	_dirty = false
	history_changed.emit()

func is_dirty() -> bool: return _dirty
func can_undo() -> bool: return not _undo_stack.is_empty()
func can_redo() -> bool: return not _redo_stack.is_empty()

func get_undo_label() -> String: return _undo_stack.back().label if can_undo() else ""
func get_redo_label() -> String: return _redo_stack.back().label if can_redo() else ""
