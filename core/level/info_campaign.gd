class_name CampaignInfo
extends EditorPlayInfo

const CAMPAIGN_COVER_ID = 4267

var cpg_path: String

# ------------------------------------------------------

var author: String = ""

# ------------------------------------------------------

func get_cover_texture() -> Texture2D:
	if cover == null:
		return Defs.get_sprite_def(CAMPAIGN_COVER_ID).frames[0]
	return cover
