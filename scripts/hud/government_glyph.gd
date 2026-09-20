extends Control
## Compact vector marks used by the cabinet cards.

var kind:="portrait"
var accent:=Color.WHITE
var seed:=1
var ratio:=0.0

func setup(new_kind:String,new_accent:Color,new_seed:int=1,new_ratio:float=0.0)->Control:
	kind=new_kind;accent=new_accent;seed=new_seed;ratio=new_ratio
	custom_minimum_size=Vector2(48,48)
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	queue_redraw()
	return self

func _draw()->void:
	var center:=size*0.5
	match kind.to_lower():
		"portrait":
			draw_circle(center,minf(size.x,size.y)*0.47,accent.darkened(0.15),true)
			var skin:=Color.from_hsv(fmod(float(seed)*0.173,1.0),0.26,0.82)
			draw_circle(center+Vector2(0,-7),8,skin,true)
			draw_circle(center+Vector2(0,17),17,accent.lightened(0.08),true)
			draw_colored_polygon(PackedVector2Array([center+Vector2(-8,-11),center+Vector2(0,-17),center+Vector2(9,-10),center+Vector2(6,-3),center+Vector2(-7,-4)]),Color("292823"))
		"fit":
			draw_arc(center,19,-PI/2,PI*1.5,40,HudTokens.TRACK,5,true)
			draw_arc(center,19,-PI/2,-PI/2+TAU*clampf(ratio,0,1),40,accent,5,true)
			draw_circle(center,3,accent,true)
		"dismiss":
			draw_rect(Rect2(center+Vector2(-10,-12),Vector2(11,24)),accent,false,3)
			draw_line(center+Vector2(-4,0),center+Vector2(12,0),accent,3,true)
			draw_colored_polygon(PackedVector2Array([center+Vector2(12,0),center+Vector2(6,-5),center+Vector2(6,5)]),accent)
		"execute":
			draw_colored_polygon(PackedVector2Array([center+Vector2(-9,-11),center+Vector2(8,-7),center+Vector2(4,4),center+Vector2(-12,0)]),accent)
			draw_line(center+Vector2(2,1),center+Vector2(11,12),accent,4,true)
		_:
			_draw_office(center,kind.to_lower())

func _draw_office(c:Vector2,office:String)->void:
	match office:
		"steward":
			draw_circle(c,16,accent,false,3,true);draw_circle(c,5,accent,true)
			for angle in [0.0,PI/2,PI,PI*1.5]: draw_line(c+Vector2.from_angle(angle)*8,c+Vector2.from_angle(angle)*16,accent,4,true)
		"quartermaster":
			draw_rect(Rect2(c-Vector2(15,11),Vector2(30,22)),accent,false,3)
			draw_line(c-Vector2(15,2),c+Vector2(15,-2),accent,3,true);draw_line(c+Vector2(0,-11),c+Vector2(0,11),accent,3,true)
		"marshal":
			draw_colored_polygon(PackedVector2Array([c+Vector2(0,-17),c+Vector2(14,-11),c+Vector2(11,8),c+Vector2(0,18),c+Vector2(-11,8),c+Vector2(-14,-11)]),accent)
		"scholar":
			draw_colored_polygon(PackedVector2Array([c+Vector2(-16,-13),c+Vector2(-2,-9),c+Vector2(-2,14),c+Vector2(-16,10)]),accent)
			draw_colored_polygon(PackedVector2Array([c+Vector2(2,-9),c+Vector2(16,-13),c+Vector2(16,10),c+Vector2(2,14)]),accent)
		"envoy":
			draw_circle(c-Vector2(8,3),8,accent,true);draw_circle(c+Vector2(8,3),8,accent,true)
			draw_line(c-Vector2(11,-10),c+Vector2(11,10),accent,3,true)
		_:
			draw_circle(c,15,accent,false,3,true);draw_circle(c,5,accent,true)
