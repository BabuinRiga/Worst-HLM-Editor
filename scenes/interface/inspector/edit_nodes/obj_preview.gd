extends PanelContainer
class_name ObjEd_Preview

var _sprite: BaseSprite

@onready var texture_rect: TextureRect = $MarginContainer/HBoxContainer/TextureRect
@onready var sprite_size: Label = $MarginContainer/HBoxContainer/VBoxContainer/Size
@onready var sprite_text: Label = $MarginContainer/HBoxContainer/VBoxContainer/Sprite
@onready var object_text: Label = $MarginContainer/HBoxContainer/VBoxContainer/Object


func _ready() -> void:
	_update_preview()
	_sprite.sprite_changed.connect(_update_preview)

func _update_preview() -> void:
	_set_sprite_image()
	_set_sprite_size()
	_set_sprite_name()
	_set_object_name()

func _set_sprite_image() -> void:
	if _sprite.texture:
		texture_rect.texture = _sprite.texture

func _set_sprite_size() -> void:
	if _sprite.texture:
		sprite_size.text = "%dx%dpx" % [_sprite.texture.get_width(), _sprite.texture.get_height()]

func _set_sprite_name() -> void:
	var sid: int
	if _sprite is ObjectSprite:
		sid = _sprite.object.sprite_id
	elif _sprite is WallSprite:
		sid = _sprite.sprite_id
	elif _sprite is DoorSprite:
		sid = _sprite.sprite_id
	else:
		sid = -1
	sprite_text.text = Defs.get_sprite_name(sid)

func _set_object_name() -> void:
	var oid: int
	if _sprite is ObjectSprite:
		oid = _sprite.object.object_id
	elif _sprite is WallSprite:
		oid = _sprite.object_id
	elif _sprite is DoorSprite:
		oid = _sprite.object_id
	else:
		oid = -1
	object_text.text = Defs.get_object_name(oid)
