extends RefCounted
const PATH:="res://assets/ui/wealth/approved-atlas.png"
static var atlas:Texture2D
static func crop(rect:Rect2)->Texture2D:
	if atlas==null:
		atlas=load(PATH) as Texture2D if ResourceLoader.exists(PATH) else ImageTexture.create_from_image(Image.load_from_file(PATH))
	var result:=AtlasTexture.new();result.atlas=atlas;result.region=rect;return result
static func picture(rect:Rect2,width:float,height:float)->TextureRect:
	var image:=TextureRect.new();image.texture=crop(rect);image.custom_minimum_size=Vector2(width,height);image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;image.mouse_filter=Control.MOUSE_FILTER_IGNORE;return image
static func icon(index:int)->TextureRect:
	var ys:=[72,150,229,306,388,468,549,629,708]
	return picture(Rect2(15,ys[index],47,40),40,36)
static func account(index:int)->TextureRect:
	var ys:=[353,444,531,621]
	return picture(Rect2(104,ys[index],220,78),185,78)
