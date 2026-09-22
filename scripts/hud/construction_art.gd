extends RefCounted
const PATH:="res://assets/ui/construction/building-atlas.png"
const EARLY_PATH:="res://assets/ui/early-paper/buildings-v1.png"
static var atlas:Texture2D
static func texture(index:int)->Texture2D:
	var chosen:=EARLY_PATH if preload("res://scripts/hud/early_civ_art.gd").active() else PATH
	if atlas==null or atlas.resource_path!=chosen:
		atlas=load(chosen) as Texture2D
	var result:=AtlasTexture.new();result.atlas=atlas
	var cell:=Vector2(atlas.get_width()/4.0,atlas.get_height()/2.0)
	result.region=Rect2(Vector2(index%4,index/4)*cell,cell)
	return result
static func building(title:String)->int:
	return {"Hearth Circle":0,"Lean-to Shelters":1,"Storage Pits":2,"Open Work Area":3,"Gathering Yard":4,"Public Stores":5,"Framed Hall":6}.get(title,7)
static func picture(index:int,width:float,height:float)->TextureRect:
	var rect:=TextureRect.new();rect.texture=texture(index);rect.custom_minimum_size=Vector2(width,height)
	rect.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;rect.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.mouse_filter=Control.MOUSE_FILTER_IGNORE
	return rect
