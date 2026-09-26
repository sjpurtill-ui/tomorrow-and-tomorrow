extends Control
## Hover-only route account; existing grounded ribbons own the route drawing.
const T=preload("res://scripts/hud/hud_tokens.gd")
var camera:Camera3D
var points:=PackedVector3Array()
var caption:=""

func _ready()->void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	clip_contents=true

## What the last drawing showed: 0 when nothing (the route is not hovered),
## else the pointer and camera it was drawn for. Counter for probes only.
var drawn_signature:=0
var redraw_requests:=0
var tested_key:=0

## Redraws only when the hover caption appears, moves or goes away; an
## unhovered route draws nothing; an idle pointer and camera cost one hash.
func _process(_delta:float)->void:
	if not is_instance_valid(camera) or not is_inside_tree(): return
	# Pointer, camera and route unchanged: the last hit test still holds.
	var key:=hash([get_local_mouse_position(),camera.global_transform,camera.size,points.size(),get_viewport().gui_get_hovered_control()==null])
	if key==tested_key: return
	tested_key=key
	var signature:=0
	if _hovered():
		signature=hash([get_local_mouse_position(),camera.global_transform,camera.size,caption])
	if signature==drawn_signature: return
	drawn_signature=signature
	redraw_requests+=1
	queue_redraw()

func _hovered()->bool:
	if not is_instance_valid(camera) or points.size()<2 or not is_inside_tree(): return false
	if get_viewport().gui_get_hovered_control()!=null: return false
	var mouse:=get_local_mouse_position()
	for i in range(1,points.size()):
		if camera.is_position_behind(points[i-1]) or camera.is_position_behind(points[i]): continue
		var a:=camera.unproject_position(points[i-1])
		var b:=camera.unproject_position(points[i])
		if Geometry2D.get_closest_point_to_segment(mouse,a,b).distance_to(mouse)<8.0: return true
	return false

func _draw()->void:
	if drawn_signature==0: return
	var mouse:=get_local_mouse_position()
	var font:=ThemeDB.fallback_font
	var text_size:=font.get_string_size(caption,HORIZONTAL_ALIGNMENT_LEFT,-1,13)
	var box_size:=text_size+Vector2(20,14)
	var origin:=mouse+Vector2(14,18)
	origin.x=clampf(origin.x,8,maxf(8,size.x-box_size.x-8))
	origin.y=clampf(origin.y,8,maxf(8,size.y-box_size.y-8))
	var style:=T.flat(T.MAP_LABEL_BG,T.BORDER_SOFT,1,4,0)
	draw_style_box(style,Rect2(origin,box_size))
	draw_string(font,origin+Vector2(10,7+font.get_ascent(13)),caption,HORIZONTAL_ALIGNMENT_LEFT,-1,13,T.INK)
