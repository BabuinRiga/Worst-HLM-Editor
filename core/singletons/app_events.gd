extends Node

signal load_started(title: String)
signal load_progress(current: int, total: int, label: String)
signal load_finished()
