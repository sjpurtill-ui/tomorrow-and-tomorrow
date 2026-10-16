extends RefCounted
const PATH:="res://assets/ui/materials/material-atlas.png"
const EARLY_PATH:="res://assets/ui/early-paper/materials-v1.png"
## Dedicated stockyard specimens. These are presentation keys, not a resource
## visibility catalogue: only the provider decides which materials are known.
const STOCKYARD_ATLASES:={
	"common":["Flint","Salt","Medicinal Plants","Peat","Limestone","Fine Sand"],
	"earth":["Ochre Earth","Bitumen","Refractory Clay","Kaolin","Phosphate Rock","Graphite"],
	"fuel":["Sulfur","Nitrates","Coal","Crude Oil","Tin Ore","Lead Ore"],
	"ores":["Iron Ore","Zinc Ore","Silver Ore","Gold Ore","Nickel Ore","Bauxite"],
	"land":["Rutile Ore","Uranium Ore","Fertile Soil","Game","Deep Aquifer","__fallback__"]
}
const BASE_KEYS:=["Timber","Stone","Clay","Fiber Plants","Copper Ore"]
static var _stockyard_atlases:Dictionary={}
static var _stockyard_textures:Dictionary={}
static var atlas:Texture2D

static func has_dedicated(kind:String)->bool:
	if kind in BASE_KEYS:return true
	for keys:Array in STOCKYARD_ATLASES.values():
		if kind in keys and kind!="__fallback__":return true
	return false

## Keep every stock visible, including retained/imported products outside the
## raw-resource catalogue. Unknown keys receive honest generic goods artwork.
static func texture_for(kind:String)->Texture2D:
	var cache_key:=kind if has_dedicated(kind) else "__fallback__"
	if _stockyard_textures.has(cache_key):return _stockyard_textures[cache_key]
	var path:=PATH
	var index:=BASE_KEYS.find(cache_key)
	if index<0:
		for group:String in STOCKYARD_ATLASES:
			index=(STOCKYARD_ATLASES[group] as Array).find(cache_key)
			if index>=0:
				path="res://assets/ui/materials/stockyard-%s.jpg" % group
				break
	if index<0:return null
	var source:Texture2D=_stockyard_atlases.get(path)
	if source==null:
		if ResourceLoader.exists(path):source=load(path) as Texture2D
		elif FileAccess.file_exists(path):
			var image:=Image.load_from_file(ProjectSettings.globalize_path(path))
			if image!=null:source=ImageTexture.create_from_image(image)
		if source==null:return null
		_stockyard_atlases[path]=source
	var result:=AtlasTexture.new();result.atlas=source
	var cell:=Vector2(source.get_width()/2.0,source.get_height()/3.0)
	# Full cells retain the specimen's silhouette and do not distort its scale.
	result.region=Rect2(Vector2(index%2,index/2)*cell,cell)
	result.filter_clip=true
	_stockyard_textures[cache_key]=result
	return result

static func picture_for(kind:String,width:float,height:float)->TextureRect:
	var rect:=TextureRect.new();rect.texture=texture_for(kind);rect.custom_minimum_size=Vector2(width,height)
	rect.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;rect.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.mouse_filter=Control.MOUSE_FILTER_IGNORE
	rect.tooltip_text=kind if has_dedicated(kind) else "Generic stored-goods illustration for "+kind
	return rect

## Legacy six-cell API remains unchanged for Trade and earlier folio callers.
static func texture(index:int)->Texture2D:
	var chosen:=EARLY_PATH if preload("res://scripts/hud/early_civ_art.gd").active() else PATH
	if atlas==null or atlas.resource_path!=chosen:
		if ResourceLoader.exists(chosen):atlas=load(chosen) as Texture2D
		else:
			var image:=Image.load_from_file(chosen)
			if image==null:return null
			atlas=ImageTexture.create_from_image(image)
	var result:=AtlasTexture.new();result.atlas=atlas
	var cell:=Vector2(atlas.get_width()/2.0,atlas.get_height()/3.0)
	result.region=Rect2(Vector2(index%2,index/2)*cell+Vector2(0,cell.y*.06),Vector2(cell.x,cell.y*.85))
	return result
static func material(kind:String)->int:
	return {"Timber":0,"Stone":1,"Clay":2,"Fiber Plants":3,"Copper Ore":4}.get(kind,-1)
static func picture(index:int,width:float,height:float)->TextureRect:
	var rect:=TextureRect.new();rect.texture=texture(index) if index>=0 else null;rect.custom_minimum_size=Vector2(width,height)
	rect.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;rect.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.mouse_filter=Control.MOUSE_FILTER_IGNORE
	return rect
