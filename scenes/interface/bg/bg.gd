extends CanvasLayer

@onready var bg_rect = $Background

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
