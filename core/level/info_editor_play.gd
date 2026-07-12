class_name EditorPlayInfo
extends RefCounted

var name: String
var cover: Texture2D
var folder_path: String
var exist: bool

# --------------------------------------------------

func get_cover_texture() -> Texture2D:
	return cover
