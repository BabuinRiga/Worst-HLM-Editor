extends ModalWindow

@onready var button: Button = $Panel/VPanel/Content/VBoxContainer/SelectPath/Button
@onready var line_edit: LineEdit = $Panel/VPanel/Content/VBoxContainer/SelectPath/LineEdit

@onready var apply: Button = $Panel/VPanel/MarginPanels/Panels/Apply
@onready var file_dialog: FileDialog = $Panel/VPanel/Content/VBoxContainer/SelectPath/FileDialog

signal path_confirm

func _ready() -> void:
	line_edit.text_changed.connect(_on_line_changed)
	line_edit.text = SettingsData.settings["hm2_path"]
	_on_line_changed(line_edit.text)
	
	button.pressed.connect(_on_button_pressed)
	file_dialog.dir_selected.connect(_on_dir_selected)
	apply.pressed.connect(_on_apply_pressed)


func _on_apply_pressed() -> void:
	SettingsData.settings["hm2_path"] = line_edit.text
	SettingsData._save_settings()
	Assets.load_base()
	queue_free()


func _on_line_changed(new_text: String) -> void:
	if DirAccess.dir_exists_absolute(new_text):
		if FileAccess.file_exists(new_text + Assets.BASE_WAD_NAME):
			apply.disabled = false
			return
	apply.disabled = true

func _on_dir_selected(path: String) -> void:
	line_edit.text = path
	_on_line_changed(line_edit.text)

func _on_button_pressed() -> void:
	file_dialog.popup_centered()
