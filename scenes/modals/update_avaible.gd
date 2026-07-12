extends ModalWindow
class_name UpdateAvailable

@onready var header: TextureRect = $Panel/VPanel/Content/VBox/Header
@onready var rich_text_label: RichTextLabel = $Panel/VPanel/Content/VBox/ScrollContainer/MarginContainer/RichTextLabel
@onready var update_btn: Button = $Panel/VPanel/MarginPanels/Panels/Update

var _download_url: String = ""

func _ready() -> void:
	update_btn.pressed.connect(_on_update_pressed)
	rich_text_label.bbcode_enabled = true
	header.visible = false

func setup(latest_version: String, url: String, changelog: String, image_texture: Texture2D) -> void:
	_download_url = url
	
	if not is_node_ready():
		await ready
	
	rich_text_label.text = "[b][font_size=30]v" + latest_version + "[/font_size][/b]\n\n" + _markdown_to_bbcode(changelog)
	
	if image_texture != null:
		header.texture = image_texture
		header.visible = true
	else:
		header.visible = false

func _on_update_pressed() -> void:
	OS.shell_open(_download_url)
	close()

func _markdown_to_bbcode(text: String) -> String:
	var regex := RegEx.new()
	var result := text
	
	regex.compile("(?i)<img[^>]*>")
	result = regex.sub(result, "", true)
	
	regex.compile("(?m)^#{1,6}\\s+(.*)$")
	result = regex.sub(result, "[b][font_size=20]$1[/font_size][/b]", true)
	
	regex.compile("(?m)^[\\-\\*]\\s+(.*)$")
	result = regex.sub(result, "• $1", true)
	
	regex.compile("\\*\\*(.*?)\\*\\*")
	result = regex.sub(result, "[b]$1[/b]", true)
	
	regex.compile("\\*(.*?)\\*")
	result = regex.sub(result, "[i]$1[/i]", true)
	
	return result.strip_edges()
