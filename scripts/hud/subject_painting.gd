extends Control
## Subject-aware framing shared by discovery announcements, research cards and unit portraits.
var texture:Texture2D
var focus:=Vector2(.5,.5)
var contain:bool=false
func _ready()->void:
	clip_contents=true;resized.connect(queue_redraw)
static func crop_region(source_texture:Texture2D,target:Vector2,focal_point:Vector2)->Rect2:
	var source:=source_texture.get_size();var scale:=maxf(target.x/source.x,target.y/source.y)
	var extent:=target/maxf(scale,.0001);var origin:=source*focal_point-extent*.5
	origin.x=clampf(origin.x,0,source.x-extent.x);origin.y=clampf(origin.y,0,source.y-extent.y)
	return Rect2(origin,extent)
func _draw()->void:
	if texture and contain:
		var extent:=texture.get_size()*minf(size.x/texture.get_width(),size.y/texture.get_height())
		draw_rect(Rect2(Vector2.ZERO,size),Color("102027"))
		draw_texture_rect(texture,Rect2((size-extent)*.5,extent),false)
	elif texture:
		draw_texture_rect_region(texture,Rect2(Vector2.ZERO,size),crop_region(texture,size,focus))
	else:
		draw_rect(Rect2(Vector2.ZERO,size),Color("102027"))
		draw_string(ThemeDB.fallback_font,Vector2(size.x*.5-8,size.y*.5+10),"?",HORIZONTAL_ALIGNMENT_LEFT,-1,28,Color("7a909a"))
