extends Control
## Subject-aware framing shared by discovery announcements, research cards and unit portraits.
var texture:Texture2D:
	set(value):
		texture=value
		if fit_whole_width:_fit()
		queue_redraw()
var focus:=Vector2(.5,.5)
## Hero mode: the control takes the painting's own height for its width, so a
## wide banner painting is shown whole. min/max bound the height; only when a
## bound bites is the painting cropped, around its focus point.
var fit_whole_width:=false
var min_height:=0.0
var max_height:=0.0
var contain:bool=false
## Ground behind a contained or missing painting; paper screens pass their own.
var backdrop:=Color("102027")
var fetch:Callable
var scroll:ScrollContainer
func _ready()->void:
	clip_contents=true;resized.connect(queue_redraw)
	if fit_whole_width:resized.connect(_fit);_fit()
	if is_instance_valid(scroll):
		resized.connect(refresh)
		visibility_changed.connect(refresh)
		scroll.resized.connect(refresh)
		scroll.get_v_scroll_bar().value_changed.connect(func(_value:float)->void:refresh())
		# Cards reflowed into view (e.g. a second row placed after layout) move without resizing.
		set_notify_transform(true)
		call_deferred("refresh")
func _notification(what:int)->void:
	if what==NOTIFICATION_TRANSFORM_CHANGED and texture==null:refresh()
## Height the painting needs to show its full width at this width, within the bounds.
static func whole_width_height(source_texture:Texture2D,width:float,low:float,high:float)->float:
	if source_texture==null or source_texture.get_width()<=0 or width<=0:return low
	var natural:=width*source_texture.get_height()/float(source_texture.get_width())
	return clampf(natural,low,high if high>0 else natural)
## Deferred, once per frame: changing the height inside a resize would re-enter
## container sorting (a scrollbar appearing can narrow the width again).
var _fit_queued:=false
func _fit()->void:
	if not fit_whole_width or _fit_queued:return
	_fit_queued=true;_apply_fit.call_deferred()
func _apply_fit()->void:
	_fit_queued=false
	if texture==null or size.x<=0:return
	var wanted:=roundf(whole_width_height(texture,size.x,min_height,max_height))
	if absf(custom_minimum_size.y-wanted)>=1.0:custom_minimum_size.y=wanted
func refresh()->void:
	if not is_instance_valid(scroll) or not fetch.is_valid():return
	if is_visible_in_tree() and size.y>0 and scroll.get_global_rect().intersects(get_global_rect()):
		if texture==null:texture=fetch.call()
	else:texture=null
	queue_redraw()
static func crop_region(source_texture:Texture2D,target:Vector2,focal_point:Vector2)->Rect2:
	var source:=source_texture.get_size();var scale:=maxf(target.x/source.x,target.y/source.y)
	var extent:=target/maxf(scale,.0001);var origin:=source*focal_point-extent*.5
	origin.x=clampf(origin.x,0,source.x-extent.x);origin.y=clampf(origin.y,0,source.y-extent.y)
	return Rect2(origin,extent)
func _draw()->void:
	if texture and contain:
		var extent:=texture.get_size()*minf(size.x/texture.get_width(),size.y/texture.get_height())
		draw_rect(Rect2(Vector2.ZERO,size),backdrop)
		draw_texture_rect(texture,Rect2((size-extent)*.5,extent),false)
	elif texture:
		draw_texture_rect_region(texture,Rect2(Vector2.ZERO,size),crop_region(texture,size,focus))
	else:
		draw_rect(Rect2(Vector2.ZERO,size),backdrop)
		draw_string(ThemeDB.fallback_font,Vector2(size.x*.5-8,size.y*.5+10),"?",HORIZONTAL_ALIGNMENT_LEFT,-1,28,Color("7a909a"))
