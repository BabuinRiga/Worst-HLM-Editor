extends HTTPRequest

@onready var modal_layer: CanvasLayer = $"../Interface/ModalLayer"

var app_version = ProjectSettings.get_setting("application/config/version", "vTILOX")
const GITHUB_API_URL = "https://api.github.com/repos/BabuinRiga/Worst-HLM-Editor/releases/latest"
const UPDATE_MODAL_SCENE = preload("uid://4ajnig573320")

func _ready() -> void:
	check_for_updates()

func check_for_updates() -> void:
	var headers = ["User-Agent: Worst-HLM-Editor"]
	request(GITHUB_API_URL, headers)
	request_completed.connect(_on_request_completed)

func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200: return
	
	var json = JSON.new()
	if json.parse(body.get_string_from_utf8()) == OK:
		var data = json.get_data()
		
		var latest_version = data.get("tag_name", "")
		var release_url = data.get("html_url", "")
		var changelog = data.get("body", "-")
		
		var image_url = ""
		
		var img_regex := RegEx.new()
		img_regex.compile("(?i)<img[^>]+src=[\"']([^\"']+)[\"']")
		var regex_match := img_regex.search(changelog)
		
		if regex_match:
			image_url = regex_match.get_string(1)
		elif data.has("assets"):
			for asset in data["assets"]:
				var file_name = asset.get("name", "").to_lower()
				if file_name.ends_with(".png") or file_name.ends_with(".jpg") or file_name.ends_with(".jpeg"):
					image_url = asset.get("url", "") 
					break
		
		if _is_version_newer(latest_version, app_version):
			if image_url != "":
				_download_image_and_show_modal(latest_version, release_url, changelog, image_url)
			else:
				_show_update_modal(latest_version, release_url, changelog, null)

func _download_image_and_show_modal(latest_version: String, release_url: String, changelog: String, image_url: String) -> void:
	var img_req = HTTPRequest.new()
	add_child(img_req)
	img_req.request(image_url)
	
	var response = await img_req.request_completed
	var result: int = response[0]
	var response_code: int = response[1]
	var body: PackedByteArray = response[3]
	
	var texture: ImageTexture = null
	
	if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
		var image = Image.new()
		var err = image.load_png_from_buffer(body)
		if err != OK:
			err = image.load_jpg_from_buffer(body)
		
		if err == OK:
			texture = ImageTexture.create_from_image(image)
	
	img_req.queue_free()
	_show_update_modal(latest_version, release_url, changelog, texture)

func _is_version_newer(latest: String, current: String) -> bool:
	latest = latest.replace("v", "")
	current = current.replace("v", "")
	
	var latest_parts = latest.split(".")
	var current_parts = current.split(".")
	
	var max_len = maxi(latest_parts.size(), current_parts.size())
	
	for i in range(max_len):
		var l_val = int(latest_parts[i]) if i < latest_parts.size() else 0
		var c_val = int(current_parts[i]) if i < current_parts.size() else 0
		
		if l_val > c_val:
			return true
		elif l_val < c_val:
			return false
			
	return false

func _show_update_modal(latest_version: String, release_url: String, changelog: String, texture: Texture2D) -> void:
	var modal = UPDATE_MODAL_SCENE.instantiate()
	modal.setup(latest_version, release_url, changelog, texture)
	modal_layer.add_child(modal)
