extends RefCounted
const PATH:="res://assets/ui/materials/material-atlas.png"
static var atlas:Texture2D
static func texture(index:int)->Texture2D:
	if atlas==null:
		var image:=Image.load_from_file(PATH)
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
