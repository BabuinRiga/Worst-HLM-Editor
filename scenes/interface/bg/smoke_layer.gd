extends Node2D

var frames: Array[ImageTexture] = []
var particles: Array[Dictionary] = []

@onready var master_controller: CanvasLayer = $"../../.."

func _ready() -> void:
	Assets.asset_rebuilded.connect(_init_smoke)

func _init_smoke() -> void:
	var sprite_def = Defs.get_sprite_def(1636)
	if sprite_def and sprite_def.frames.size() > 0:
		frames = sprite_def.frames
	
	particles.clear()
	for i in range(16):
		particles.append(_create_particle())

func _create_particle() -> Dictionary:
	var dir = randf_range(0, PI * 2)
	return {
		"x": randf_range(0, 192),
		"y": randf_range(0, 104),
		"xspeed": cos(dir) * 0.15,
		"yspeed": -sin(dir) * 0.15,
		"angle": randf_range(0, PI * 2),
		"scale": 1.0 + randf_range(0, 1.0),
		"index": randf_range(0, 28.0)
	}

func _process(delta: float) -> void:
	if frames.is_empty(): return
	var frame_step = 60.0 * delta
	
	var current_blink = master_controller.blink
	var addspeed = 1.0 if current_blink > 0.0 else 0.0
	
	for p in particles:
		p["index"] += (0.15 + (addspeed * 0.5)) * frame_step
		p["x"] += p["xspeed"] * (1.0 + addspeed * 4.0) * frame_step
		p["y"] += p["yspeed"] * (1.0 + addspeed * 4.0) * frame_step
		
		if p["index"] > 28.0:
			var new_p = _create_particle()
			p["x"] = new_p["x"]
			p["y"] = randf_range(0, 102)
			p["xspeed"] = new_p["xspeed"]
			p["yspeed"] = new_p["yspeed"]
			p["angle"] = new_p["angle"]
			p["scale"] = new_p["scale"]
			p["index"] = 0.0
	
	queue_redraw()

func _draw() -> void:
	if frames.is_empty(): return
	
	for p in particles:
		var frame_idx = int(floor(p["index"])) % frames.size()
		var tex = frames[frame_idx]
		
		draw_set_transform(Vector2(p["x"], p["y"]), p["angle"], Vector2(p["scale"], p["scale"]))
		draw_texture(tex, -tex.get_size() / 2.0, Color.WHITE)
	
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
