extends Control
## Issued route plans, drawn in screen pixels so zoom never turns them into roads.
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
	var mouse:=get_local_mouse_position()
	var hovered:=false
	var segments:Array[PackedVector2Array]=[]
	for i in range(1,points.size()):
		if camera.is_position_behind(points[i-1]) or camera.is_position_behind(points[i]): continue
		var a:=camera.unproject_position(points[i-1])
		var b:=camera.unproject_position(points[i])
		segments.append(PackedVector2Array([a,b]))
		if Geometry2D.get_closest_point_to_segment(mouse,a,b).distance_to(mouse)<8.0: hovered=true
	# Map annotations never compete with a dock or modal under the pointer.
	if get_viewport().gui_get_hovered_control()!=null: hovered=false
	var ink:=Color(0.82,0.73,0.48,0.85 if hovered else 0.48)
	for segment in segments:
		draw_dashed_line(segment[0],segment[1],ink,1.5 if hovered else 1.0,6.0,true,true)
	var endpoint:=points[points.size()-1]
	if not camera.is_position_behind(endpoint):
		var end:=camera.unproject_position(endpoint)
		draw_circle(end,3.0,Color(0.06,0.10,0.11,0.8))
		draw_arc(end,3.0,0,TAU,16,ink,1.0,true)
	if hovered:
		var font:=ThemeDB.fallback_font
		var text_size:=font.get_string_size(caption,HORIZONTAL_ALIGNMENT_LEFT,-1,13)
		var box_size:=text_size+Vector2(20,14)
		var origin:=mouse+Vector2(14,18)
		origin.x=clampf(origin.x,8,maxf(8,size.x-box_size.x-8))
		origin.y=clampf(origin.y,8,maxf(8,size.y-box_size.y-8))
		draw_style_box(_caption_style(),Rect2(origin,box_size))
		draw_string(font,origin+Vector2(10,7+font.get_ascent(13)),caption,HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("#d9c99e"))

func _caption_style()->StyleBoxFlat:
	var style:=StyleBoxFlat.new()
	style.bg_color=Color(0.035,0.065,0.07,0.94)
	style.set_corner_radius_all(4)
	return style
