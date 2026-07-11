extends Node

const HM_2_PATH = preload("uid://s6p65vjqtos8")

var modal_layer: CanvasLayer
var languages: PopupMenu

const SETTINGS_PATH = "user://settings.cfg"
var settings: Dictionary = {
	"fullscreen": true,
	"hm2_path": "/",
	"lang": "automatic"
}
enum settings_id {
	FULLSCREEN,
	HM2PATH,
	LANG
}


func _ready() -> void:
	modal_layer = get_tree().current_scene.get_node("Interface/ModalLayer")
	
	_load_settings()
	_apply_window(settings["fullscreen"])
	_apply_lang(settings["lang"])

func _process(delta: float) -> void:
	pass


func _save_settings() -> void:
	var config = ConfigFile.new()
	for key in settings:
		config.set_value("SETTINGS", key, settings.get(key))
	config.save(SETTINGS_PATH)

func _load_settings() -> void:
	var config = ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return
	for key in settings:
		if config.has_section_key("SETTINGS", key):
			settings[key] = config.get_value("SETTINGS", key)


# --------------------------------------------------------------


func _apply_window(is_fullscreen: bool) -> void:
	if is_fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _apply_hm2path() -> void:
	var modal = HM_2_PATH.instantiate()
	modal_layer.add_child(modal)

func _apply_lang(lang: String) -> void:
	if lang == "automatic":
		var preferred_language = OS.get_locale_language()
		TranslationServer.set_locale(preferred_language)
	else:
		TranslationServer.set_locale(lang)
