class_name LevelInfo
extends RefCounted

enum Type { SINGLE, CAMPAIGN_CHAPTER, CAMPAIGN_LEVEL }

var type: Type
var name: String
var cover: Texture2D
var folder_path: String
var hlm_path: String
var prefix: String

var exist: bool

# ------------------------------------------------------

var author: String = ""
var floors: int = 0
var cutscene: bool = false
var s_rank: int = 0
var character_id: int = 0
var mask_id: int = 0
var music_id: int = 0
var boundaries: Rect2i = Rect2i()
var background_id: int = 0
var hour: String = ""
var minute: String = ""
var day: String = ""
var month: String = ""
var year: String = ""
var city: String = ""
var state: String = ""
var address: String = ""

# ------------------------------------------------------

func load_hlm() -> bool:
	var f := FileAccess.open(hlm_path, FileAccess.READ)
	if f == null:
		return false
	
	name = f.get_line().strip_edges()
	floors = int(f.get_line())
	author = f.get_line().strip_edges()
	cutscene = f.get_line().strip_edges() == "1"
	s_rank = int(f.get_line())
	character_id = int(f.get_line())
	f.get_line()
	mask_id = int(f.get_line())
	music_id = int(f.get_line())
	
	var left := int(f.get_line())
	var top := int(f.get_line())
	var right := int(f.get_line())
	var bottom := int(f.get_line())
	boundaries = Rect2i(left, top, right - left, bottom - top)
	
	background_id = int(f.get_line())
	f.get_line()
	
	hour = f.get_line().strip_edges()
	minute = f.get_line().strip_edges()
	day = f.get_line().strip_edges()
	month = f.get_line().strip_edges()
	year = f.get_line().strip_edges()
	city = f.get_line().strip_edges()
	state = f.get_line().strip_edges()
	address = f.get_line().strip_edges()
	
	f.close()
	return true

func save_hlm() -> bool:
	var f := FileAccess.open(hlm_path, FileAccess.WRITE)
	if f == null:
		return false
	
	f.store_line(name)
	f.store_line(str(floors))
	f.store_line(author)
	f.store_line(str(int(cutscene)))
	f.store_line(str(s_rank))
	f.store_line(str(character_id))
	f.store_line("1")
	f.store_line(str(mask_id))
	f.store_line(str(music_id))
	f.store_line(str(boundaries.position.x))
	f.store_line(str(boundaries.position.y))
	f.store_line(str(boundaries.end.x))
	f.store_line(str(boundaries.end.y))
	f.store_line(str(background_id))
	f.store_line("0")
	f.store_line(hour)
	f.store_line(minute)
	f.store_line(day)
	f.store_line(month)
	f.store_line(year)
	f.store_line(city)
	f.store_line(state)
	f.store_line(address)
	f.store_line("0")
	f.store_line("9999")
	f.store_line("9999")
	
	f.close()
	return true

func save_ver() -> bool:
	var ver_path: String = folder_path + "/" + prefix + ".ver"
	var f := FileAccess.open(ver_path, FileAccess.WRITE)
	if f == null:
		return false
	
	f.store_line("2")
	return true

func level_folder() -> String:
	return folder_path

func get_cover_texture() -> Texture2D:
	if cover != null:
		return cover
	
	if type == Type.SINGLE:
		return Defs.get_sprite_def(LevelScanner.SINGLE_COVER_ID).frames[0]
	else:
		return Defs.get_sprite_def(LevelScanner.CAMPAIGN_COVER_ID).frames[0]
