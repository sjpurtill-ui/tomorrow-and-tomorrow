extends RefCounted
const PATH:="res://assets/ui/provisions/food-atlas.png"
static var atlas:Texture2D
static func texture(index:int)->Texture2D:
	if atlas==null:
		atlas=load(PATH) as Texture2D
	var result:=AtlasTexture.new();result.atlas=atlas
	var cell:=Vector2(atlas.get_width()/2.0,atlas.get_height()/3.0)
	result.region=Rect2(Vector2(index%2,index/2)*cell+Vector2(0,cell.y*.06),Vector2(cell.x,cell.y*.85))
	return result
static func food(kind:String)->int:
	return {"Fresh plants":0,"Meat & fish":1,"Dry staples":2,"Preserved food":3}.get(kind,4)
static func picture(index:int,width:float,height:float)->TextureRect:
	var rect:=TextureRect.new();rect.texture=texture(index);rect.custom_minimum_size=Vector2(width,height)
	rect.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;rect.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.mouse_filter=Control.MOUSE_FILTER_IGNORE
	return rect
