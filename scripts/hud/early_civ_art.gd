extends RefCounted
## Presentation only. No RNG use, gameplay modifiers, or per-frame image work.
const ROOT:="res://assets/ui/early-paper/"
const PROFILES:=["kilnfold","reedwake","windseam","stoneweft"]
const PATHS:=[ROOT+"kilnfold-scenes-v1.png",ROOT+"reedwake-scenes-v1.png",ROOT+"windseam-scenes-v1.png","res://assets/portraits/paper/stoneweft-actions-v4.png"]
static var sheets:Dictionary={}
static func active()->bool:
	return GameState.elapsed_days<300.0*365.0
static func owner(person:Dictionary)->String:
	return String(person.get("appearance_civ_id",person.get("civilization_id","player")))
static func profile(person:Dictionary)->int:
	var saved:=PROFILES.find(String(person.get("early_art_profile","")))
	if saved>=0:return saved
	var seed_value:=int(person.get("appearance_world_seed",GameState.world_seed))
	return posmod((str(seed_value)+":"+owner(person)+":visual_ancestry").hash(),PROFILES.size())
static func source(path:String)->Texture2D:
	if not sheets.has(path):
		if sheets.size()>=8:sheets.erase(sheets.keys()[0])
		sheets[path]=load(path) as Texture2D
	return sheets[path]
static func cell(path:String,index:int,columns:int,rows:int)->AtlasTexture:
	var source_image:=source(path)
	var result:=AtlasTexture.new();result.atlas=source_image
	var size:=source_image.get_size()/Vector2(columns,rows)
	result.region=Rect2(Vector2(index%columns,index/columns)*size+size*.025,size*.95)
	result.filter_clip=true
	return result
static func person_scene(person:Dictionary,index:int)->Texture2D:
	var family:=profile(person)
	return cell(PATHS[family],posmod(index,5 if family==3 else 4),5 if family==3 else 2,1 if family==3 else 2)
static func civic_index(values:Dictionary)->int:
	# These are visual interpretations of declared values, never race or mood.
	if float(values.get("hierarchy",.5))>=.68 and float(values.get("centralization",.5))>=.60:return 0
	if float(values.get("hierarchy",.5))<=.38 and float(values.get("pluralism",.5))>=.60:return 1
	if float(values.get("common_stewardship",.5))>=.64:return 2
	return 3
static func civic_scene(values:Dictionary)->Texture2D:
	return cell(ROOT+"civic-practices-v1.png",civic_index(values),2,2)
