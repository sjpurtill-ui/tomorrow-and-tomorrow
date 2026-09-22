extends RefCounted
## Representative practices, not literal city inventories. Five lazy textures.
const PATHS:=[
	"res://assets/ui/provisions/paper/fresh-plants-v1.png",
	"res://assets/ui/provisions/paper/meat-fish-v1.png",
	"res://assets/ui/provisions/paper/dry-staples-v1.png",
	"res://assets/ui/research/paper/food_drying.png",
	"res://assets/ui/research/paper/clean_water.png"]
static var textures:Dictionary={}
static func texture(index:int)->Texture2D:
	var key:=clampi(index,0,PATHS.size()-1)
	if not textures.has(key):
		var source:=load(PATHS[key]) as Texture2D
		if source==null:return null
		var result:=AtlasTexture.new();result.atlas=source
		# Frame the scene below the blank title area without editing originals.
		var top:=.40 if key>=3 else .18
		var bottom:=.85 if key==4 else 1.0
		result.region=Rect2(0,source.get_height()*top,source.get_width(),source.get_height()*(bottom-top))
		textures[key]=result
	return textures[key]
static func food(kind:String)->int:
	return {"Fresh plants":0,"Meat & fish":1,"Dry staples":2,"Preserved food":3}.get(kind,4)
static func picture(index:int,width:float,height:float)->TextureRect:
	var rect:=TextureRect.new();rect.texture=texture(index);rect.custom_minimum_size=Vector2(width,height)
	rect.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;rect.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.mouse_filter=Control.MOUSE_FILTER_IGNORE
	rect.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	return rect
