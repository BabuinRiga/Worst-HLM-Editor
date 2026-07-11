extends PopupMenu
class_name Settings


func _ready() -> void:
	_init_settings()
	_init_window_popup()
	_init_hm2path_popup()
	add_separator()
	_init_lang_popup()

func _process(delta: float) -> void:
	pass


func _init_settings() -> void:
	id_pressed.connect(_on_settings_pressed)

func _on_settings_pressed(id: int) -> void:
	match id:
		SettingsData.settings_id.FULLSCREEN:
			_on_window_pressed(id)
		SettingsData.settings_id.HM2PATH:
			_on_hm2path_pressed(id)
		_:
			pass


# --------------------------------------------------------------


func _init_window_popup() -> void:
	add_radio_check_item("FULLSCREEN", SettingsData.settings_id.FULLSCREEN)
	set_item_as_checkable(SettingsData.settings_id.FULLSCREEN, true)
	set_item_checked(SettingsData.settings_id.FULLSCREEN, SettingsData.settings["fullscreen"])

func _on_window_pressed(id: int) -> void:
	var is_fullscreen: bool = SettingsData.settings["fullscreen"]
	is_fullscreen = !is_fullscreen
	SettingsData.settings["fullscreen"] = is_fullscreen
	SettingsData._apply_window(is_fullscreen)
	set_item_checked(id, is_fullscreen)
	SettingsData._save_settings()


# --------------------------------------------------------------


func _init_hm2path_popup() -> void:
	add_item("HM2PATH", SettingsData.settings_id.HM2PATH)

func _on_hm2path_pressed(id: int) -> void:
	SettingsData._apply_hm2path()


# --------------------------------------------------------------


func _init_lang_popup() -> void:
	SettingsData.languages = PopupMenu.new()
	var current_locale = TranslationServer.get_locale()
	var i = 0
	for locale in TranslationServer.get_loaded_locales():
		TranslationServer.set_locale(locale)
		SettingsData.languages.add_radio_check_item(tr("LANG_NAME"), i)
		if current_locale.split("_")[0] == locale:
			SettingsData.languages.set_item_checked(i, true)
		i += 1
	SettingsData.languages.id_pressed.connect(_on_language_pressed)
	TranslationServer.set_locale(current_locale)
	
	add_child(SettingsData.languages)
	add_submenu_node_item("LANG", SettingsData.languages, SettingsData.settings_id.LANG)

func _on_language_pressed(id: int) -> void:
	var i = 0
	for locale in TranslationServer.get_loaded_locales():
		if i == id:
			SettingsData.languages.set_item_checked(i, true)
			SettingsData._apply_lang(locale)
			SettingsData.settings["lang"] = locale
		else:
			SettingsData.languages.set_item_checked(i, false)
		i += 1
	SettingsData._save_settings()
