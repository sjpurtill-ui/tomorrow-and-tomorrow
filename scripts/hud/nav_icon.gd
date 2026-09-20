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
		draw_circle(Vector2(15,15),14,c,true)
		c=HudTokens.GLYPH_DARK
	match icon_id:
		"settlement":
			draw_colored_polygon(PackedVector2Array([Vector2(5,14),Vector2(15,5),Vector2(25,14)]),c)
			draw_rect(Rect2(8,13,14,11),c,true)
			draw_rect(Rect2(13,18,4,6),_cut_color(),true)
		"economy":
			for i in 3:
				var y:=8.0+i*7.0
				draw_rect(Rect2(6,y-2,18,4),c,true)
				draw_circle(Vector2(6,y),2,c,true);draw_circle(Vector2(24,y),2,c,true)
				draw_rect(Rect2(11,y-1,8,2),_cut_color(),true)
		"government":
			draw_colored_polygon(PackedVector2Array([Vector2(4,11),Vector2(15,4),Vector2(26,11)]),c)
			draw_rect(Rect2(5,12,20,3),c,true)
			for x in [7.0,13.0,19.0]: draw_rect(Rect2(x,15,4,8),c,true)
			draw_rect(Rect2(4,23,22,3),c,true)
		"civ":
			draw_circle(Vector2(15,9),4,c,true)
			draw_circle(Vector2(7,13),3,c,true);draw_circle(Vector2(23,13),3,c,true)
			draw_colored_polygon(PackedVector2Array([Vector2(9,25),Vector2(10,16),Vector2(15,13),Vector2(20,16),Vector2(21,25)]),c)
			draw_circle(Vector2(7,22),6,c,true);draw_circle(Vector2(23,22),6,c,true)
		"inquiry":
			draw_circle(Vector2(13,12),8,c,true)
			draw_circle(Vector2(13,12),4,_cut_color(),true)
			draw_line(Vector2(19,18),Vector2(25,24),c,5,true)
		"world":
			draw_circle(Vector2(15,15),11,c,true)
			draw_arc(Vector2(15,15),7,-PI/2,PI/2,20,_cut_color(),2.2,true)
			draw_arc(Vector2(15,15),7,PI/2,PI*1.5,20,_cut_color(),2.2,true)
			draw_line(Vector2(5,15),Vector2(25,15),_cut_color(),2.2,true)
		"military":
			draw_colored_polygon(PackedVector2Array([Vector2(15,3),Vector2(25,7),Vector2(23,19),Vector2(15,27),Vector2(7,19),Vector2(5,7)]),c)
			draw_colored_polygon(PackedVector2Array([Vector2(15,8),Vector2(20,10),Vector2(18,18),Vector2(15,21)]),_cut_color())

func _cut_color()->Color:
	return HudTokens.PANEL_BG_SOLID
