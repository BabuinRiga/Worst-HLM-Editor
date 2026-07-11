extends PanelContainer
class_name MainTab

static var player_ids: Array = []
static var car_ids: Array = []

static var players_data: Dictionary = {}
static var masks_data: Dictionary = {}
static var cars_data: Dictionary = {}
static var hlm_char_data: Array = []

static var backgrounds_data: Array = []
static var music_data: Array = []

# -------------------------------------------------


func _ready() -> void:
	_parse_players()
	_parse_masks()
	_parse_cars()
	_parse_hlm_char()
	_parse_backgrounds()
	_parse_music()


# -------------------------------------------------

func _parse_players() -> void:
	var file := FileAccess.open("res://resources/tables/players.json", FileAccess.READ)
	var json = JSON.parse_string(file.get_as_text())
	file.close()
	for player in json:
		var first_object_id: int = player["ids"][0][0]
		players_data[first_object_id] = player
		for pair in player["ids"]:
			var object_id: int = pair[0]
			if not player_ids.has(object_id):
				player_ids.append(object_id)

func _parse_masks() -> void:
	var file := FileAccess.open("res://resources/tables/masks.json", FileAccess.READ)
	var json = JSON.parse_string(file.get_as_text())
	file.close()
	for mask_key in json:
		var mask_id: int = mask_key.to_int()
		var mask_name: String = json[mask_key]
		masks_data[mask_id] = mask_name

func _parse_cars() -> void:
	var file := FileAccess.open("res://resources/tables/cars.json", FileAccess.READ)
	var json = JSON.parse_string(file.get_as_text())
	file.close()
	for car in json:
		var object_id: int = car["object_id"]
		cars_data[object_id] = car
		if not car_ids.has(object_id):
			car_ids.append(object_id)

func _parse_hlm_char() -> void:
	var file := FileAccess.open("res://resources/tables/hlm_char.json", FileAccess.READ)
	var json = JSON.parse_string(file.get_as_text())
	file.close()
	for char in json:
		hlm_char_data.append(char)

func _parse_backgrounds() -> void:
	var bg_tsv := FileAccess.open("res://resources/tables/backgrounds.tsv", FileAccess.READ)
	if !bg_tsv.eof_reached():
		bg_tsv.get_csv_line("\t")
	while !bg_tsv.eof_reached():
		var params = bg_tsv.get_csv_line("\t")
		var bg_data := {
			"object_id": params[0].to_int(),
			"name": params[1]
		}
		backgrounds_data.append(bg_data)
	bg_tsv.close()

func _parse_music() -> void:
	var music_tsv := FileAccess.open("res://resources/tables/music.tsv", FileAccess.READ)
	if !music_tsv.eof_reached():
		music_tsv.get_csv_line("\t")
	while !music_tsv.eof_reached():
		var params = music_tsv.get_csv_line("\t")
		music_data.append(params[0])
	music_tsv.close()
