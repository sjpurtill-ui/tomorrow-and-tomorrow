extends Control
## A single engraved, 48-unit icon vocabulary for government.

var kind := "portrait"
var accent := Color.WHITE
var seed := 1
var ratio := 0.0

func setup(new_kind:String, new_accent:Color, new_seed:int=1, new_ratio:float=0.0)->Control:
	kind = new_kind.to_lower()
	accent = new_accent
	seed = new_seed
	ratio = new_ratio
	custom_minimum_size = Vector2(48,48)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()
	return self

func _draw()->void:
	var scale_factor := minf(size.x,size.y)/48.0
	draw_set_transform(size*0.5,0,Vector2.ONE*scale_factor)
	match kind:
		"portrait": _draw_portrait()
		"vacant":
			_medallion()
			# An empty council chair, deliberately without a person.
			_line([Vector2(-8,1),Vector2(-8,-11),Vector2(8,-11),Vector2(8,1)],2)
			_line([Vector2(-12,-2),Vector2(-12,7),Vector2(12,7),Vector2(12,-2)],2)
			_line([Vector2(-9,7),Vector2(-9,13)],2)
			_line([Vector2(9,7),Vector2(9,13)],2)
		"fit":
			draw_arc(Vector2.ZERO,20,-PI/2,PI*1.5,64,HudTokens.TRACK,2.5,true)
			if ratio>0.0:
				draw_arc(Vector2.ZERO,20,-PI/2,-PI/2+TAU*clampf(ratio,0,1),64,accent,2.5,true)
			var value := str(roundi(clampf(ratio,0,1)*100.0))
			var font := ThemeDB.fallback_font
			var text_width := font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,16).x
			draw_string(font,Vector2(-text_width*0.5,5.5),value,HORIZONTAL_ALIGNMENT_LEFT,-1,16,HudTokens.INK)
		"dismiss":
			# Person-minus: removal from office, without a door/exit metaphor.
			draw_circle(Vector2(-5,-7),5,accent,false,2.4,true)
			draw_arc(Vector2(-5,9),10,PI,TAU,32,accent,2.4,true)
			_line([Vector2(6,-3),Vector2(17,-3)],2.6)
		"execute":
			# Skull: the consequence stays legible even without the tooltip.
			draw_circle(Vector2(0,-3),12,accent,true,-1,true)
			draw_rect(Rect2(-7,5,14,9),accent)
			draw_circle(Vector2(-5,-3),3.2,HudTokens.ROW_BG,true,-1,true)
			draw_circle(Vector2(5,-3),3.2,HudTokens.ROW_BG,true,-1,true)
			draw_colored_polygon(PackedVector2Array([Vector2(0,1),Vector2(-2,5),Vector2(2,5)]),HudTokens.ROW_BG)
			for x in [-3.0,3.0]: draw_line(Vector2(x,10),Vector2(x,14),HudTokens.ROW_BG,1.6,true)
		_: _draw_office()

func _medallion()->void:
	draw_circle(Vector2.ZERO,22,Color(accent,0.07),true,-1,true)
	draw_circle(Vector2.ZERO,22,Color(accent,0.55),false,1.2,true)

func _draw_portrait()->void:
	_medallion()
	# Classical profile cameo: monochrome relief rather than invented skin tones.
	var silhouette := PackedVector2Array([
		Vector2(-15,15),Vector2(-13,11),Vector2(-8,8),Vector2(-3,6),
		Vector2(-3,2),Vector2(-7,-2),Vector2(-9,-7),Vector2(-8,-12),
		Vector2(-5,-16),Vector2(0,-17),Vector2(5,-15),Vector2(7,-12),
		Vector2(7,-8),Vector2(11,-3),Vector2(8,-2),Vector2(8,1),
		Vector2(6,4),Vector2(2,4),Vector2(2,7),Vector2(7,10),
		Vector2(12,13),Vector2(14,16),Vector2(8,19),Vector2(0,20),Vector2(-8,19)])
	draw_colored_polygon(silhouette,accent)
	silhouette.append(silhouette[0])
	draw_polyline(silhouette,accent,0.75,true)
	# A restrained mantle seam and hairline supply relief at small sizes.
	draw_polyline(PackedVector2Array([Vector2(-11,13),Vector2(-3,10),Vector2(3,16)]),HudTokens.ROW_BG,1.2,true)
	draw_arc(Vector2(-1,-9),5.5,PI*1.04,PI*1.83,24,Color(HudTokens.ROW_BG,0.65),1.1,true)

func _draw_office()->void:
	_medallion()
	match kind:
		"steward":
			# A council's laurel, open at the crown.
			for direction in [-1.0,1.0]:
				_line([Vector2(0,13),Vector2(direction*8,6),Vector2(direction*11,-2),Vector2(direction*9,-10)],1.8)
				for i in 3:
					var y := 4.0-i*6.0
					draw_colored_polygon(PackedVector2Array([Vector2(direction*9,y+2),Vector2(direction*15,y-3),Vector2(direction*11,y-5)]),accent)
			_line([Vector2(-3,9),Vector2(3,9)],1.6)
		"quartermaster":
			_line([Vector2(0,14),Vector2(0,-13)],1.8)
			for i in 3:
				var y := -8.0+i*7.0
				for direction in [-1.0,1.0]:
					draw_colored_polygon(PackedVector2Array([Vector2(0,y+5),Vector2(direction*8,y),Vector2(direction*8,y-5),Vector2(direction*2,y-1)]),accent)
		"marshal":
			_line([Vector2(0,-14),Vector2(12,-9),Vector2(10,4),Vector2(0,14),Vector2(-10,4),Vector2(-12,-9),Vector2(0,-14)],2)
			_line([Vector2(0,-8),Vector2(0,8)],2)
			_line([Vector2(-4,2),Vector2(4,2)],2)
		"scholar":
			_line([Vector2(0,-8),Vector2(-13,-12),Vector2(-13,9),Vector2(0,13),Vector2(13,9),Vector2(13,-12),Vector2(0,-8),Vector2(0,13)],2)
			_line([Vector2(-9,-5),Vector2(-4,-3)],1.4)
			_line([Vector2(4,-3),Vector2(9,-5)],1.4)
		"envoy":
			_line([Vector2(-10,13),Vector2(0,0),Vector2(9,-12)],1.8)
			for i in 3:
				var c := Vector2(-4+i*5,6-i*7)
				draw_colored_polygon(PackedVector2Array([c,c+Vector2(-8,-2),c+Vector2(-7,-8)]),accent)
				draw_colored_polygon(PackedVector2Array([c,c+Vector2(8,1),c+Vector2(8,-5)]),accent)
		_:
			# Neutral civic seal for any future office.
			_line([Vector2(-12,-5),Vector2(0,-13),Vector2(12,-5)],2)
			for x in [-8.0,0.0,8.0]: _line([Vector2(x,-3),Vector2(x,9)],2)
			_line([Vector2(-13,12),Vector2(13,12)],2)

func _line(points:Array[Vector2], width:float=2.0)->void:
	draw_polyline(PackedVector2Array(points),accent,width,true)
