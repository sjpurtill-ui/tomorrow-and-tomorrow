extends Control
## Small, text-free command-rail pictograms. Drawing them from primitives keeps
## every icon legible and consistent in both interface themes.

var icon_id:String="settlement"
var icon_color:Color=Color.WHITE

func _init(id:String="settlement")->void:
	icon_id=id
	custom_minimum_size=Vector2(26,26)
	mouse_filter=Control.MOUSE_FILTER_IGNORE

func set_icon_color(value:Color)->void:
	icon_color=value
	queue_redraw()

func _draw()->void:
	var c:=icon_color
	var w:=2.0
	match icon_id:
		"settlement":
			draw_polyline(PackedVector2Array([Vector2(4,12),Vector2(13,4),Vector2(22,12)]),c,w,true)
			draw_rect(Rect2(7,11,12,11),c,false,w)
			draw_rect(Rect2(11,16,4,6),c,false,w)
		"economy":
			_coin(Vector2(13,7),8,c,w)
			_coin(Vector2(13,13),8,c,w)
			_coin(Vector2(13,19),8,c,w)
		"government":
			draw_polyline(PackedVector2Array([Vector2(3,9),Vector2(13,3),Vector2(23,9),Vector2(3,9)]),c,w,true)
			for x in [6.0,11.0,16.0,21.0]: draw_line(Vector2(x,10),Vector2(x,20),c,w,true)
			draw_line(Vector2(3,21),Vector2(23,21),c,w,true)
		"civ":
			draw_circle(Vector2(13,13),10,c,false,w,true)
			draw_circle(Vector2(13,13),4,c,false,w,true)
			draw_line(Vector2(13,3),Vector2(13,23),c,w,true)
			draw_line(Vector2(3,13),Vector2(23,13),c,w,true)
		"inquiry":
			draw_circle(Vector2(11,11),7,c,false,w,true)
			draw_line(Vector2(16,16),Vector2(23,23),c,3.0,true)
			draw_circle(Vector2(11,11),2,c,true)
		"world":
			draw_circle(Vector2(13,13),10,c,false,w,true)
			draw_arc(Vector2(13,13),5,PI/2,PI*1.5,18,c,w,true)
			draw_arc(Vector2(13,13),5,-PI/2,PI/2,18,c,w,true)
			draw_line(Vector2(3,13),Vector2(23,13),c,w,true)
		"military":
			draw_polyline(PackedVector2Array([Vector2(13,3),Vector2(22,7),Vector2(20,17),Vector2(13,23),Vector2(6,17),Vector2(4,7),Vector2(13,3)]),c,w,true)
			draw_line(Vector2(9,12),Vector2(17,12),c,w,true)
			draw_line(Vector2(13,8),Vector2(13,17),c,w,true)

func _coin(center:Vector2,half_width:float,color:Color,width:float)->void:
	draw_arc(center,Vector2(half_width,2.8).x,0,TAU,24,color,width,true)
	# Flatten the circle visually into a coin ellipse with a horizontal mark.
	draw_line(center-Vector2(half_width,0),center+Vector2(half_width,0),color,width,true)
