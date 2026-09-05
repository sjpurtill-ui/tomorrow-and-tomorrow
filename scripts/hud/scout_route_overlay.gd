extends Control
## Hover-only route account; existing grounded ribbons own the route drawing.
var camera:Camera3D
var points:=PackedVector3Array()
var caption:=""

func _ready()->void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	clip_contents=true

func _process(_delta:float)->void:
	queue_redraw()

func _draw()->void:
	if not is_instance_valid(camera) or points.size()<2: return
	if get_viewport().gui_get_hovered_control()!=null: return
	var mouse:=get_local_mouse_position()
	var hovered:=false
	for i in range(1,points.size()):
		if camera.is_position_behind(points[i-1]) or camera.is_position_behind(points[i]): continue
		var a:=camera.unproject_position(points[i-1])
		var b:=camera.unproject_position(points[i])
		if Geometry2D.get_closest_point_to_segment(mouse,a,b).distance_to(mouse)<8.0:
			hovered=true
			break
	if not hovered: return
	var font:=ThemeDB.fallback_font
	var text_size:=font.get_string_size(caption,HORIZONTAL_ALIGNMENT_LEFT,-1,13)
	var box_size:=text_size+Vector2(20,14)
	var origin:=mouse+Vector2(14,18)
	origin.x=clampf(origin.x,8,maxf(8,size.x-box_size.x-8))
	origin.y=clampf(origin.y,8,maxf(8,size.y-box_size.y-8))
	var style:=StyleBoxFlat.new()
	style.bg_color=Color(0.035,0.065,0.07,0.94)
	style.set_corner_radius_all(4)
	draw_style_box(style,Rect2(origin,box_size))
	draw_string(font,origin+Vector2(10,7+font.get_ascent(13)),caption,HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("#d9c99e"))
