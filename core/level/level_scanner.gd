class_name LevelScanner

const DOCS_PATH := "/My Games/HotlineMiami2"

# ------------------------------------------------- API

static func single_levels_path() -> String:
	return OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS) + DOCS_PATH + "/Levels/single"

static func campaigns_path() -> String:
	return OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS) + DOCS_PATH + "/Levels/campaigns"

static func cover_path() -> String:
	return OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS) + DOCS_PATH + "/covers/"

static func scan_single() -> Array[LevelInfo]:
	var result: Array[LevelInfo] = []
	var base := single_levels_path()
	
	if not DirAccess.dir_exists_absolute(base):
		return result
	
	for dir_name in DirAccess.get_directories_at(base):
		var folder := base + "/" + dir_name
		var hlm_path := folder + "/level.hlm"
		if not FileAccess.file_exists(hlm_path):
			continue
		
		var info := LevelInfo.new()
		info.type = LevelInfo.Type.SINGLE
		info.folder_path = folder
		info.hlm_path = hlm_path
		info.prefix = "level"
		info.cover = _load_cover(folder + "/level.png", true)
		info.exist = true
		info.load_hlm()
		result.append(info)
	
	return result

static func scan_campaigns() -> Array:
	var result: Array = []
	var base := campaigns_path()
	
	if not DirAccess.dir_exists_absolute(base):
		return result
	
	for dir_name in DirAccess.get_directories_at(base):
		var folder := base + "/" + dir_name
		var cpg_path := folder + "/campaign.cpg"
		if not FileAccess.file_exists(cpg_path):
			continue
		
		var cpg_info := CampaignInfo.new()
		cpg_info.folder_path = folder
		cpg_info.cpg_path = cpg_path
		cpg_info.cover = _load_cover(folder + "/campaign.png", false)
		cpg_info.name = _read_first_line(cpg_path)
		cpg_info.exist = true
		
		var chapter_count := _read_campaign_chapter_count(cpg_path)
		var chapters: Array = []
		
		for i in range(chapter_count):
			var chpt_hlm := folder + "/main%d.hlm" % i
			if not FileAccess.file_exists(chpt_hlm):
				continue
			
			var chpt_info := LevelInfo.new()
			chpt_info.folder_path = folder
			chpt_info.hlm_path = chpt_hlm
			chpt_info.cover = _load_cover(folder + "/main%d.png" % i, true)
			chpt_info.exist = true
			chpt_info.load_hlm()
			
			var levels: Array[LevelInfo] = []
			for prefix in ["intro%d" % i, "main%d" % i, "outro%d" % i]:
				var lvl_hlm: String = folder + "/" + prefix + ".hlm"
				if not FileAccess.file_exists(lvl_hlm):
					continue
				
				var lvl_info := LevelInfo.new()
				lvl_info.type = LevelInfo.Type.CAMPAIGN_LEVEL
				lvl_info.folder_path = folder
				lvl_info.hlm_path = lvl_hlm
				lvl_info.prefix = prefix
				lvl_info.cover = chpt_info.cover
				lvl_info.exist = true
				lvl_info.load_hlm()
				levels.append(lvl_info)
			
			chapters.append({"info": chpt_info, "levels": levels})
		
		result.append({"info": cpg_info, "chapters": chapters})
	
	return result

# -------------------------------------------------

static func _read_first_line(path: String) -> String:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return path.get_file()
	var line := f.get_line().strip_edges()
	f.close()
	return line if not line.is_empty() else path.get_file()

static func _read_campaign_chapter_count(cpg_path: String) -> int:
	var f := FileAccess.open(cpg_path, FileAccess.READ)
	if f == null:
		return 0
	f.get_line()
	f.get_line()
	var count := int(f.get_line())
	f.close()
	return count

static func _load_cover(path: String, single: bool) -> Texture2D:
	if FileAccess.file_exists(path):
		var img := Image.load_from_file(path)
		if img:
			return ImageTexture.create_from_image(img)
	return null
