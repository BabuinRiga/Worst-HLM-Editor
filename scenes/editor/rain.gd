extends GPUParticles2D
class_name Rain

var no_rain_zone: Array[Rect2] = []
const SPLASH_SPRITE_ID := 1091

@onready var top_bar: TopBar = get_tree().get_first_node_in_group("TopBar")
@onready var camera_2d: Camera2D = $".."

func _ready() -> void:
	Assets.asset_rebuilded.connect(_on_assets_rebuilded)
	top_bar.view.view_updated.connect(_on_view_updated)
	toggle_rain(false)

func _process(_delta: float) -> void:
	if not camera_2d or not process_material:
		return
	
	var canvas_transform = camera_2d.get_canvas_transform()
	var top_left = -canvas_transform.origin / canvas_transform.get_scale()
	var size = get_viewport_rect().size / canvas_transform.get_scale()
	
	var halfw = (size.x / 2.0)
	var halfh = (size.y / 2.0)
	
	var mat = process_material as ShaderMaterial
	
	mat.set_shader_parameter("camera_pos", top_left)
	mat.set_shader_parameter("camera_size", size)
	mat.set_shader_parameter("camera_half_size_offset", Vector2(halfw, halfh))
	
	_update_no_rain_zones(mat)

func _update_no_rain_zones(mat: ShaderMaterial) -> void:
	var rects_data = PackedVector4Array()
	
	var count = no_rain_zone.size()
	
	for i in range(count):
		var zone = no_rain_zone[i]
		rects_data.append(Vector4(
			zone.position.x,
			zone.position.y,
			zone.position.x + zone.size.x,
			zone.position.y + zone.size.y
		))
	
	mat.set_shader_parameter("exclusion_rects", rects_data)
	mat.set_shader_parameter("exclusion_count", count)

func toggle_rain(toggle: bool) -> void:
	if not toggle:
		restart()
		emitting = false
		visible = false
	else:
		emitting = true
		_on_view_updated()

func _on_view_updated() -> void:
	visible = emitting and top_bar.view.rain

func _init_hit_textures() -> void:
	var def = Defs.get_sprite_def(SPLASH_SPRITE_ID)
	if not def or def.frames.is_empty():
		return
	
	var image: Texture2D = def.frames[0]
	var images: Array[Image] = []
	var frame_size := image.get_size()
	
	for tex in def.frames:
		images.append(tex.get_image())
	
	var tex_array = Texture2DArray.new()
	tex_array.create_from_images(images)
	
	var canvas_mat = material as ShaderMaterial
	if canvas_mat:
		canvas_mat.set_shader_parameter("splash_frames", tex_array)
		canvas_mat.set_shader_parameter("num_frames", def.frames.size())
		
	var particle_mat = process_material as ShaderMaterial
	if particle_mat:
		particle_mat.set_shader_parameter("splash_size", frame_size)

func _on_assets_rebuilded() -> void:
	_init_hit_textures()
