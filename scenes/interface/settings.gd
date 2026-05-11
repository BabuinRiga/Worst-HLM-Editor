extends PopupMenu

var languages: PopupMenu = null

const SETTINGS_PATH = "user://settings.cfg"
var settings: Dictionary = {
	"fullscreen": true,
	"lang": "automatic"
}
enum settings_id {
	FULLSCREEN,
	LANG
}


func _ready() -> void:
	_load_settings()
	_init_window_popup()
	_init_settings()
	_init_lang_popup()

func _process(delta: float) -> void:
	pass


func _save_settings() -> void:
	var config = ConfigFile.new()
	for key in settings:
		print(settings.get(key))
		config.set_value("SETTINGS", key, settings.get(key))
	config.save(SETTINGS_PATH)

func _load_settings() -> void:
	var config = ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return
	for key in settings:
		if config.has_section_key("SETTINGS", key):
			print(settings[key])
			settings[key] = config.get_value("SETTINGS", key)


func _init_settings() -> void:
	id_pressed.connect(_on_settings_pressed)
	
	var is_fullscreen: bool = settings["fullscreen"]
	_apply_window(settings_id.FULLSCREEN, is_fullscreen)
	
	var language: String = settings["lang"]
	if language == "automatic":
		var preferred_language = OS.get_locale_language()
		TranslationServer.set_locale(preferred_language)
	else:
		TranslationServer.set_locale(language)

func _on_settings_pressed(id: int) -> void:
	match id:
		settings_id.FULLSCREEN:
			_on_window_pressed(id)
		_:
			pass


func _init_window_popup() -> void:
	add_radio_check_item("FULLSCREEN", settings_id.FULLSCREEN)

func _on_window_pressed(id: int) -> void:
	var is_fullscreen: bool = settings["fullscreen"]
	is_fullscreen = !is_fullscreen
	settings["fullscreen"] = is_fullscreen
	_apply_window(id, is_fullscreen)
	_save_settings()

func _apply_window(id: int, is_fullscreen: bool) -> void:
	if is_fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	set_item_checked(id, is_fullscreen)
		

func _init_lang_popup() -> void:
	languages = PopupMenu.new()
	var current_locale = TranslationServer.get_locale()
	var i = 0
	for locale in TranslationServer.get_loaded_locales():
		TranslationServer.set_locale(locale)
		languages.add_radio_check_item(tr("LANG_NAME"), i)
		if current_locale.split("_")[0] == locale:
			languages.set_item_checked(i, true)
		i += 1
	languages.id_pressed.connect(_on_language_pressed)
	TranslationServer.set_locale(current_locale)
	
	add_child(languages)
	add_submenu_node_item("LANG", languages, settings_id.LANG)

func _on_language_pressed(id: int) -> void:
	var i = 0
	for locale in TranslationServer.get_loaded_locales():
		if i == id:
			languages.set_item_checked(i, true)
			TranslationServer.set_locale(locale)
			settings["lang"] = locale
		else:
			languages.set_item_checked(i, false)
		i += 1
	_save_settings()
