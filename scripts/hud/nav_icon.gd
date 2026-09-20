extends Control
## Bold, text-free navigation marks with a consistent filled weight.

var icon_id:String="settlement"
var icon_color:Color=Color.WHITE
var active:=false

func _init(id:String="settlement")->void:
	icon_id=id
	custom_minimum_size=Vector2(30,30)
	mouse_filter=Control.MOUSE_FILTER_IGNORE

func set_icon_color(value:Color)->void:
	icon_color=value
	queue_redraw()

func set_active(value:bool)->void:
	active=value
	queue_redraw()

func _draw()->void:
	var c:=icon_color
	if active:
		c=HudTokens.GOLD_BRIGHT
	match icon_id:
		"settlement":
			draw_colored_polygon(PackedVector2Array([Vector2(5,14),Vector2(15,5),Vector2(25,14)]),c)
			draw_rect(Rect2(8,13,14,11),c,true)
			draw_rect(Rect2(13,18,4,6),_cut_color(),true)
		"economy":
			# Three stacked coins with curved rims, not a menu/list glyph.
			for y in [21.0,15.0,9.0]:
				draw_rect(Rect2(5,y-2,20,4),c)
				_ellipse(Vector2(15,y+2),Vector2(10,3),c)
				_ellipse(Vector2(15,y-2),Vector2(10,3),_cut_color())
				_ellipse(Vector2(15,y-2),Vector2(10,3),c,false)
		"government":
			draw_colored_polygon(PackedVector2Array([Vector2(4,11),Vector2(15,4),Vector2(26,11)]),c)
			draw_rect(Rect2(5,12,20,3),c,true)
			for x in [7.0,13.0,19.0]: draw_rect(Rect2(x,15,4,8),c,true)
			draw_rect(Rect2(4,23,22,3),c,true)
		"civ":
			draw_circle(Vector2(15,8),4,c,true)
			draw_circle(Vector2(5,11),3,c,true);draw_circle(Vector2(25,11),3,c,true)
			draw_arc(Vector2(5,23),7,PI,TAU,24,c,4,true)
			draw_arc(Vector2(25,23),7,PI,TAU,24,c,4,true)
			draw_colored_polygon(PackedVector2Array([Vector2(8,25),Vector2(9,18),Vector2(12,14),Vector2(18,14),Vector2(21,18),Vector2(22,25)]),c)
		"inquiry":
			draw_circle(Vector2(13,12),8,c,true)
			draw_circle(Vector2(13,12),4,_cut_color(),true)
			draw_line(Vector2(19,18),Vector2(25,24),c,5,true)
		"world":
			draw_circle(Vector2(15,15),11,c,false,2.3,true)
			_ellipse(Vector2(15,15),Vector2(5,11),c,false)
			draw_line(Vector2(4,15),Vector2(26,15),c,2.0,true)
		"military":
			draw_colored_polygon(PackedVector2Array([Vector2(15,3),Vector2(25,7),Vector2(23,19),Vector2(15,27),Vector2(7,19),Vector2(5,7)]),c)
			draw_colored_polygon(PackedVector2Array([Vector2(15,8),Vector2(20,10),Vector2(18,18),Vector2(15,21)]),_cut_color())

func _cut_color()->Color:
	return HudTokens.PANEL_BG_SOLID

func _ellipse(center:Vector2,radii:Vector2,color:Color,filled:bool=true)->void:
	var points:=PackedVector2Array()
	for i in 49: points.append(center+Vector2(cos(TAU*i/48.0),sin(TAU*i/48.0))*radii)
	if filled: draw_colored_polygon(points,color)
	else: draw_polyline(points,color,2.0,true)
