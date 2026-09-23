extends RefCounted
const Early:=preload("res://scripts/hud/early_civ_art.gd")
static func texture(index:int)->Texture2D:
	if Early.active():
		if index<0 or index>=14:return null
		return Early.cell(Early.ROOT+"directions-a-v1.png",index,4,2) if index<8 else Early.cell(Early.ROOT+"directions-b-v1.png",index-8,3,2)
	return Early.cell("res://assets/ui/ambition_atlas_v1.png",posmod(index,8),4,2)
