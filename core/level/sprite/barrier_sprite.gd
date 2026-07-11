extends BaseSprite
class_name BarrierSprite

const COLOR = Color(1, 0, 0, 0.4)
var lenght

func _init(_lenght: int = 0):
	set_lenght(_lenght)
	mode = LevelTab.Modes.TILES

func set_lenght(_lenght):
	lenght = _lenght
	custom_rect = Rect2(Vector2.ZERO, Vector2(lenght * 16, 4))

func _draw():
	draw_line(Vector2.ZERO, Vector2(lenght * 16, 0), COLOR, 3)
