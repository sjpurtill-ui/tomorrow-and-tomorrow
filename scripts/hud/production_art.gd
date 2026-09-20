extends RefCounted
const PATH:="res://assets/ui/production/workshop-atlas.png"
static var atlas:Texture2D
static func texture(index:int)->Texture2D:
	if atlas==null:
		var image:=Image.load_from_file(PATH)
		if image==null:return null
		atlas=ImageTexture.create_from_image(image)
	var result:=AtlasTexture.new();result.atlas=atlas
	var cell:=Vector2(atlas.get_width()/4.0,atlas.get_height()/3.0)
	result.region=Rect2(Vector2(index%4,index/4)*cell,cell)
	if index==0:result.region=Rect2(Vector2(0,cell.y*.20),Vector2(cell.x,cell.y*.64))
	return result
static func product(item:String)->int:
	return {"spear":0,"woven_cloth":2,"bow":3,"transport_cart":4}.get(item,11)
static func resource(item:String)->int:
	return {"Timber":6,"Fiber Plants":7,"Spun Yarn":7,"Stone":8,"Clay":9,"Copper Ore":10,"Refined Copper":10,"Woven Cloth":2}.get(item,11)
static func picture(index:int,width:float,height:float)->TextureRect:
	var rect:=TextureRect.new();rect.texture=texture(index);rect.custom_minimum_size=Vector2(width,height)
	rect.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;rect.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.mouse_filter=Control.MOUSE_FILTER_IGNORE
	return rect
