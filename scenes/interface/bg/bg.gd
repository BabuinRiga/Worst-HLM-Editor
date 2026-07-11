extends CanvasLayer

@onready var bg_rect = $Background
@onready var smoke_container = $ViewportContainer

var cdir: float = 0.0
var blink: float = 0.0

func _process(delta: float) -> void:
	var frame_step = 60.0 * delta
	cdir += 1.0 * frame_step
	
	if blink > 0.0:
		blink = max(0.0, blink - (0.02 * frame_step))
	
	var t = 0.5 + (0.5 * cos(deg_to_rad(cdir)))
	var base_color = Color.FUCHSIA.lerp(Color.AQUA, t)
	
	var bg_color = base_color.lerp(Color.BLACK, 0.3)
	bg_rect.material.set_shader_parameter("bg_color", bg_color)
	
	var black_amount = 0.95 - randf_range(0.0, blink * 0.35) + (0.05 * cos(deg_to_rad(cdir * 0.5)))
	var surf_tint = base_color.lerp(Color.BLACK, clamp(black_amount, 0.0, 1.0))
	
	var final_surf_tint = surf_tint.lerp(Color.RED, randf_range(0.0, blink))
	
	smoke_container.modulate = final_surf_tint
