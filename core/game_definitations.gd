extends Node

class SpriteDef:
	var id:     int
	var name:   String
	var center: Vector2i
	var frames: Array[ImageTexture] = []
	#var mask:   ImageTexture

# -------------------------------------------------

var _sprites: Dictionary = {}
var _objects: Dictionary = {}
var _objects_paths: Dictionary[int, String] = {}
var _tiles:   Array[HLMTile] = []

var _DEFAULT_TEXTURE := ImageTexture.create_from_image(preload("uid://d3n5tb8d3ytgg").get_image())

# -------------------------------------------------


func _ready() -> void:
	_load_tsv_definitions()


func link_assets(bin_objects: Dictionary = {}, bin_sprites: Dictionary = {}) -> void:
	await _link_sprites(bin_sprites)
	await _build_tiles()
	#await _link_masks(collision_masks, bin_sprites)
	await _apply_bin_objects(bin_objects)


# ------------------------------------------------- API

func get_sprite_def(sprite_id: int) -> SpriteDef:
	return _sprites.get(sprite_id, _sprites.get(-1))

func get_object(object_id: int) -> HLMObject:
	return _objects.get(object_id, null)

func get_all_objects() -> Array:
	return _objects.values()

func get_tile(tile_id: int) -> HLMTile:
	for t in _tiles:
		if t.id == tile_id:
			return t
	return null

func get_all_tiles() -> Array[HLMTile]:
	return _tiles

#func get_mask_texture(mask_id: int) -> ImageTexture:
	#var def := _sprites.get(mask_id, null) as SpriteDef
	#return def.mask if def else null

func get_sprite_name(sprite_id: int) -> String:
	var def := _sprites.get(sprite_id, null) as SpriteDef
	return def.name if def else ""

func get_object_name(object_id: int) -> String:
	var obj := _objects.get(object_id, null) as HLMObject
	return obj.object_name if obj else ""

# -------------------------------------------------

func _count_tsv_rows(f: FileAccess, min_cols: int) -> int:
	var n := 0
	while not f.eof_reached():
		var row := f.get_csv_line("\t")
		if row.size() >= min_cols and not row[0].is_empty():
			n += 1
	f.seek(0)
	return n

# ------------------------------------------------- TSV

func _load_tsv_definitions() -> void:
	#await _load_sprites_tsv()
	await _load_tiles_tsv()
	await _load_objects_tsv()

func _load_objects_tsv() -> void:
	var f := FileAccess.open("res://resources/tables/objects.tsv", FileAccess.READ)
	if f == null:
		push_error("GameDefinitions: file not found objects.tsv")
		return
	
	var total     := _count_tsv_rows(f, 2)
	var last_tick := Time.get_ticks_msec()
	var idx        := 0
	var load_name := "OBJECT_PATHS"
	AppEvents.load_started.emit(load_name)
	
	if not f.eof_reached():
		f.get_csv_line("\t")
	
	_objects_paths.clear()
	
	while not f.eof_reached():
		var row := f.get_csv_line("\t")
		if row.size() < 2 or row[0].is_empty():
			continue
		
		var id := int(row[0])
		var path := row[1]
		_objects_paths[id] = path.substr(1)
		
		idx += 1
		var now := Time.get_ticks_msec()
		if now - last_tick >= 50:
			AppEvents.load_progress.emit(idx, total, load_name)
			await Engine.get_main_loop().process_frame
			last_tick = Time.get_ticks_msec()
	
	f.close()
	AppEvents.load_finished.emit()

#func _load_sprites_tsv() -> void:
	#var f := FileAccess.open("res://resources/tables/sprites.tsv", FileAccess.READ)
	#if f == null:
		#push_error("GameDefinitions: file not found sprites.tsv")
		#return
	#
	#var total     := _count_tsv_rows(f, 4)
	#var last_tick := Time.get_ticks_msec()
	#var idx       := 0
	#AppEvents.load_started.emit("LOADING_SPRITE")
	#
	#if not f.eof_reached():
		#f.get_csv_line("\t")
	#
	#while not f.eof_reached():
		#var row := f.get_csv_line("\t")
		#if row.size() < 4 or row[0].is_empty():
			#continue
		#var id     := int(row[0])
		#var def    := SpriteDef.new()
		#def.id     = id
		#def.name   = row[1]
		#def.center = -Vector2i(int(row[2]), int(row[3]))
		#_sprites[id] = def
		#idx += 1
		#var now := Time.get_ticks_msec()
		#if now - last_tick >= 50:
			#AppEvents.load_progress.emit(idx, total, def.name)
			#await Engine.get_main_loop().process_frame
			#last_tick = Time.get_ticks_msec()
	#f.close()
	#AppEvents.load_finished.emit()
	#
	#var fallback    := SpriteDef.new()
	#fallback.id     = -1
	#fallback.name   = "No Texture"
	#fallback.center = -Vector2i(10, 10)
	#fallback.frames = [_DEFAULT_TEXTURE]
	#_sprites[-1]    = fallback

func _load_tiles_tsv() -> void:
	var f := FileAccess.open("res://resources/tables/tiles.tsv", FileAccess.READ)
	if f == null:
		push_error("GameDefinitions: file not found tiles.tsv")
		return
	
	var total     := _count_tsv_rows(f, 5)
	var last_tick := Time.get_ticks_msec()
	var idx       := 0
	var load_name := "LOADING_TILES"
	AppEvents.load_started.emit(load_name)
	
	if not f.eof_reached():
		f.get_csv_line("\t")
	
	while not f.eof_reached():
		var row := f.get_csv_line("\t")
		if row.size() < 5 or row[0].is_empty():
			continue
		var tile       := HLMTile.new()
		tile.title     = row[0]
		tile.name      = row[1]
		tile.id        = int(row[2])
		tile.depth     = int(row[3])
		tile.size      = int(row[4])
		_tiles.append(tile)
		idx += 1
		var now := Time.get_ticks_msec()
		if now - last_tick >= 50:
			AppEvents.load_progress.emit(idx, total, load_name)
			await Engine.get_main_loop().process_frame
			last_tick = Time.get_ticks_msec()
	f.close()
	AppEvents.load_finished.emit()

# -------------------------------------------------

func _link_sprites(bin_sprites: Dictionary = {}) -> void:
	if bin_sprites.is_empty():
		return
	
	_sprites.clear()
	
	var keys      := bin_sprites.keys()
	var total     := keys.size()
	var last_tick := Time.get_ticks_msec()
	var load_name := "LINKING_SPRITES"
	AppEvents.load_started.emit(load_name)
	
	for idx in range(total):
		var id: int        = keys[idx]
		var bs: Dictionary = bin_sprites[id]
		
		var def    := SpriteDef.new()
		def.id     = id
		def.name   = bs["name"]
		def.center = -bs["center"]
		
		var frames := Assets.get_sprite(def.name)
		if not frames.is_empty():
			def.frames = frames
			
		_sprites[id] = def
		
		var now := Time.get_ticks_msec()
		if now - last_tick >= 50:
			AppEvents.load_progress.emit(idx + 1, total, def.name)
			await Engine.get_main_loop().process_frame
			last_tick = Time.get_ticks_msec()
	
	var fallback    := SpriteDef.new()
	fallback.id     = -1
	fallback.name   = "NO_TEXTURE"
	fallback.center = -Vector2i(10, 10)
	fallback.frames = [_DEFAULT_TEXTURE]
	_sprites[-1]    = fallback
	
	AppEvents.load_finished.emit()

func _build_tiles() -> void:
	var total     := _tiles.size()
	var last_tick := Time.get_ticks_msec()
	var load_name := "BUILDING_TILES"
	AppEvents.load_started.emit(load_name)
	
	for idx in range(total):
		var tile: HLMTile = _tiles[idx]
		tile.tilemap    = null
		tile.tiles      = {}
		tile.view_tiles = {}
		var frames := Assets.get_sprite(tile.name)
		if not frames.is_empty():
			tile.tilemap = frames[0]
			var img  := frames[0].get_image()
			var w    := img.get_width()
			var h    := img.get_height()
			var s16  := 16 if tile.size != 8 else 8
			
			for x in range(0, w, s16):
				for y in range(0, h, s16):
					var key := "%d %d" % [x, y]
					tile.tiles[key] = ImageTexture.create_from_image(
						img.get_region(Rect2i(x, y, s16, s16)))
			
			if tile.size != 8 and tile.size != 16:
				for x in range(0, w, tile.size):
					for y in range(0, h, tile.size):
						var key := "%d %d" % [x, y]
						tile.view_tiles[key] = ImageTexture.create_from_image(
							img.get_region(Rect2i(x, y, tile.size, tile.size)))
			else:
				tile.view_tiles = tile.tiles
		
		var now := Time.get_ticks_msec()
		if now - last_tick >= 50:
			AppEvents.load_progress.emit(idx + 1, total, load_name)
			await Engine.get_main_loop().process_frame
			last_tick = Time.get_ticks_msec()
	AppEvents.load_finished.emit()

#func _link_masks(collision_masks: Dictionary = {}, bin_sprites: Dictionary = {}) -> void:
	#var total     := _sprites.size()
	#var idx       := 0
	#var last_tick := Time.get_ticks_msec()
	#var load_name := "LINKING_MASKS"
	#AppEvents.load_started.emit(load_name)
	#
	#for id in _sprites:
		#var def: SpriteDef = _sprites[id]
		#
		#if collision_masks.has(id):
			#def.mask = collision_masks[id]
		#elif bin_sprites.has(id):
			#var bs = bin_sprites[id]
			#var mx: Vector2i = bs["mask_x_bounds"]
			#var my: Vector2i = bs["mask_y_bounds"]
			#var sz: Vector2i = bs["size"]
			#if mx.x >= 0 and mx.y > mx.x and my.x >= 0 and my.y > my.x:
				#var w := sz.x if sz.x > 0 else 1
				#var h := sz.y if sz.y > 0 else 1
				#var mask_bytes := PackedByteArray()
				#mask_bytes.resize(w * h * 2)
				#for py in range(h):
					#for px in range(w):
						#var inside := (px >= mx.x and px <= mx.y and
										#py >= my.x and py <= my.y)
						#mask_bytes[(py * w + px) * 2]     = 255
						#mask_bytes[(py * w + px) * 2 + 1] = 255 if inside else 0
				#def.mask = ImageTexture.create_from_image(
					#Image.create_from_data(w, h, false, Image.FORMAT_LA8, mask_bytes))
			#elif not def.frames.is_empty():
				#_build_alpha_mask(def)
		#elif not def.frames.is_empty():
			#_build_alpha_mask(def)
		#
		#idx += 1
		#var now := Time.get_ticks_msec()
		#if now - last_tick >= 50:
			#AppEvents.load_progress.emit(idx, total, load_name)
			#await Engine.get_main_loop().process_frame
			#last_tick = Time.get_ticks_msec()
	#
	#for mask_id in collision_masks:
		#var def: SpriteDef = _sprites.get(mask_id, null)
		#if def:
			#def.mask = collision_masks[mask_id]
	#
	#AppEvents.load_finished.emit()
#
#func _build_alpha_mask(def: SpriteDef) -> void:
	#var first_img  := def.frames[0].get_image()
	#var src        := first_img.get_data()
	#var mask_bytes := PackedByteArray()
	#mask_bytes.resize(first_img.get_width() * first_img.get_height() * 2)
	#var px := 0
	#var i  := 3
	#while i < src.size():
		#var alpha: int = src[i]
		#mask_bytes[px]     = 255
		#mask_bytes[px + 1] = 255 if alpha != 0 else 0
		#px += 2
		#i  += 4
	#def.mask = ImageTexture.create_from_image(
		#Image.create_from_data(
			#first_img.get_width(), first_img.get_height(),
			#false, Image.FORMAT_LA8, mask_bytes))

func _apply_bin_objects(bin_objects: Dictionary) -> void:
	if bin_objects.is_empty():
		push_error("GameDefinitions: bin_objects is empty")
		return
	
	_objects.clear()
	
	var keys      := bin_objects.keys()
	var total     := keys.size()
	var last_tick := Time.get_ticks_msec()
	AppEvents.load_started.emit("LOADING_OBJECTS")
	
	for idx in range(total):
		var id: int        = keys[idx]
		var src: Dictionary = bin_objects[id]
		var obj             := HLMObject.new()
		obj.object_id      = src["object_id"]
		obj.object_name    = src["object_name"]
		obj.sprite_id      = src["sprite_id"] if src["sprite_id"] >= 0 else -1
		obj.mask_id        = src["mask_id"]
		obj.z_index        = src["z_index"]
		obj.solid          = src["solid"]
		if not _sprites.has(obj.sprite_id):
			obj.sprite_id = -1
		_objects[id] = obj
		
		if _objects_paths.has(id):
			obj.object_path = _objects_paths[id]
		else:
			obj.object_path = obj.object_name
		
		var now := Time.get_ticks_msec()
		if now - last_tick >= 50:
			AppEvents.load_progress.emit(idx + 1, total, obj.object_path)
			await Engine.get_main_loop().process_frame
			last_tick = Time.get_ticks_msec()
	
	AppEvents.load_finished.emit()
