extends Node

const ASSET_FILTERS: Array[String] = ["Atlases/*", "Sounds/*", "GL/*", "Fonts/*"]
var _base_raw_clean: Dictionary = {}
var _base_raw: Dictionary = {}

var _sprites: Dictionary = {}
var _sounds: Dictionary = {}

const BASE_WAD_NAME := "/hlm2_data_desktop.wad"
const MODS_SUBDIR := "/My Games/HotlineMiami2/mods/"

signal asset_rebuilded

# -------------------------------------------------


func _ready() -> void:
	await Engine.get_main_loop().process_frame
	await load_base()


# ------------------------------------------------- API

func load_base() -> void:
	var paths := _collect_base_paths()
	_base_raw = {}
	
	var base_wad_path: String = SettingsData.settings["hm2_path"] + BASE_WAD_NAME
	_base_raw_clean = await WadLoader.load_wads([base_wad_path], ASSET_FILTERS, null)
	_base_raw.merge(_base_raw_clean, true)
	
	for path in paths:
		if path == base_wad_path:
			continue
		var wad := await WadLoader.load_wads([path], ASSET_FILTERS, self)
		_base_raw.merge(wad, true)
	
	var override_pngs := _base_raw.keys().filter(func(k: String) -> bool:
		return k.ends_with(".png") and (
			not _base_raw_clean.has(k) or _base_raw[k] != _base_raw_clean[k]
		)
	)
	
	await _rebuild_assets(_base_raw, override_pngs)

func load_level(wad_paths: Array[String]) -> void:
	if wad_paths.is_empty():
		var override_pngs := _base_raw.keys().filter(func(k: String) -> bool:
			return k.ends_with(".png") and (
				not _base_raw_clean.has(k) or _base_raw[k] != _base_raw_clean[k]
			)
		)
		await _rebuild_assets(_base_raw, override_pngs)
		return
	
	var level_raw := await WadLoader.load_wads(wad_paths, ASSET_FILTERS, self)
	var override_pngs := level_raw.keys().filter(func(k: String): return k.ends_with(".png"))
	
	var merged := _base_raw.duplicate(true)
	merged.merge(level_raw, true)
	await _rebuild_assets(merged, override_pngs)

func get_sprite(name: String) -> Array[ImageTexture]:
	return _sprites.get(name, [] as Array[ImageTexture])

func get_sound(name: String) -> AudioStreamWAV:
	return _sounds.get(name, null)

# -------------------------------------------------

func _rebuild_assets(raw: Dictionary, override_pngs: Array = []) -> void:
	_sprites = await SpriteParser.parse(raw, true, override_pngs)
	_sounds = await SoundParser.parse(raw)
	#var collision_masks := await CollisionMaskParser.parse(raw)
	var bin_objects := await ObjectsBinParser.parse(raw)
	var bin_sprites := await SpritesBinParser.parse(raw)
	await Defs.link_assets(bin_objects, bin_sprites)
	asset_rebuilded.emit()

func _collect_base_paths() -> Array[String]:
	var result: Array[String] = []
	
	var base_wad: String = SettingsData.settings["hm2_path"] + BASE_WAD_NAME
	if not FileAccess.file_exists(base_wad):
		SettingsData._apply_hm2path()
		return result
	
	result.append(base_wad)
	
	var mods_dir := OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS) + MODS_SUBDIR
	if DirAccess.dir_exists_absolute(mods_dir):
		for file_name in DirAccess.get_files_at(mods_dir):
			if file_name.get_extension() == "patchwad":
				result.append(mods_dir + file_name)
	else:
		DirAccess.make_dir_recursive_absolute(mods_dir)
	
	return result

func _collect_level_paths(level_dir: String) -> Array[String]:
	var result: Array[String] = []
	
	var mods_dir := level_dir + "/mods/"
	if DirAccess.dir_exists_absolute(mods_dir):
		for file_name in DirAccess.get_files_at(mods_dir):
			if file_name.get_extension() == "patchwad":
				result.append(mods_dir + file_name)
	else:
		DirAccess.make_dir_recursive_absolute(mods_dir)
	
	return result
