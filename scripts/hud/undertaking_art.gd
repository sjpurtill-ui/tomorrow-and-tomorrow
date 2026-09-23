extends RefCounted
## Design plates, not evidence that a project was built or maintained.
const Early:=preload("res://scripts/hud/early_civ_art.gd")
const IDS:=["ancestor_ring","great_hall","rain_court","flood_terraces","star_steps","kiln_court","long_song","common_stores","safe_passage","living_orchard","stone_crown","measures_house"]
static func texture(id:String)->Texture2D:
	var index:=IDS.find(id)
	if index<0 or not Early.active():return null
	var sheet:=Early.source("res://assets/ui/early-paper/undertakings-%s-v1.png" % ("a" if index<6 else "b"))
	var cell:=index%6
	var result:=AtlasTexture.new();result.atlas=sheet
	result.region=Rect2(Vector2(float(cell%3)/3.0,0.10 if cell<3 else 0.50)*sheet.get_size(),Vector2(1.0/3.0,.41)*sheet.get_size())
	result.filter_clip=true
	return result
