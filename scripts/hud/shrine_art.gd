extends Control
## The two shrines, drawn in the painted building sheet's colours (earth,
## stone, clay, thatch and fire), for the Buildings page. The sheet
## (hud/construction_art.gd) has no shrine; these stand beside its paintings.
##   "Hearth Shrine"  a stone altar with offerings, a small fire in its ring
##   "Shrine House"   a thatched house for the god, a standing stone at its door

var kind:="Hearth Shrine"

const EARTH:=Color("d8c294")
const EARTH_DARK:=Color("bca173")
const STONE:=Color("8f9298")
const STONE_DARK:=Color("62656b")
const CLAY:=Color("a9582f")
const CLAY_DARK:=Color("7d3f22")
const THATCH:=Color("c9a35a")
const THATCH_DARK:=Color("8f6d33")
const WALL:=Color("dcc391")
const WALL_DARK:=Color("b99c68")
const WOOD:=Color("6b4a2a")
const FLAME:=Color("e99a36")
const FLAME_CORE:=Color("f7d77a")
const GRASS:=Color("8a9a5b")


static func picture(title:String,width:float,height:float)->Control:
	var art:=new()
	art.kind=title
	art.custom_minimum_size=Vector2(width,height)
	art.mouse_filter=Control.MOUSE_FILTER_IGNORE
	return art


func _draw()->void:
	var s:=minf(size.x/256.0,size.y/170.0)
	var o:=size*0.5-Vector2(128.0,85.0)*s
	var p:=func(x:float,y:float)->Vector2: return o+Vector2(x,y)*s
	_ground(p,s)
	if kind=="Shrine House": _house(p,s)
	else: _altar(p,s)


func _poly(points:Array,fill:Color,edge:Color=Color(0,0,0,0),width:=1.0)->void:
	var packed:=PackedVector2Array(points)
	draw_colored_polygon(packed,fill)
	if edge.a>0.0:
		packed.append(packed[0])
		draw_polyline(packed,edge,width,true)


func _ground(p:Callable,s:float)->void:
	var ring:=PackedVector2Array()
	for i in 40:
		var a:=TAU*float(i)/40.0
		var wobble:=1.0+0.04*sin(a*5.0)
		ring.append(p.call(128.0+cos(a)*112.0*wobble,118.0+sin(a)*42.0*wobble))
	draw_colored_polygon(ring,EARTH)
	ring.append(ring[0])
	draw_polyline(ring,Color(EARTH_DARK,0.6),1.4*s,true)
	for tuft in [[34,120],[214,112],[70,146],[186,146],[52,100]]:
		var at:Vector2=p.call(float(tuft[0]),float(tuft[1]))
		for k in 3: draw_line(at,at+Vector2(-3+3*k,-7)*s,GRASS,1.3*s,true)


func _stone(p:Callable,x:float,y:float,w:float,h:float)->void:
	_poly([p.call(x,y+h*0.3),p.call(x+w*0.2,y),p.call(x+w*0.85,y+h*0.05),p.call(x+w,y+h*0.5),p.call(x+w*0.8,y+h),p.call(x+w*0.15,y+h*0.95)],STONE,STONE_DARK,1.1)


func _pot(p:Callable,x:float,y:float,r:float)->void:
	var c:Vector2=p.call(x,y)
	var s:float=(p.call(1.0,0.0) as Vector2).x-(p.call(0.0,0.0) as Vector2).x
	draw_circle(c,r*s,CLAY)
	draw_arc(c,r*s,0.0,TAU,20,CLAY_DARK,1.1,true)
	draw_rect(Rect2(c+Vector2(-r*0.45,-r*1.25)*s,Vector2(r*0.9,r*0.45)*s),CLAY_DARK)


func _fire(p:Callable,x:float,y:float,h:float)->void:
	for i in 6:
		var a:=TAU*float(i)/6.0
		_stone(p,x+cos(a)*13.0-4.0,y+sin(a)*5.0-3.0,8.0,6.0)
	_poly([p.call(x-7,y),p.call(x,y-h),p.call(x+7,y)],FLAME)
	_poly([p.call(x-3.5,y),p.call(x+1,y-h*0.6),p.call(x+3.5,y)],FLAME_CORE)


func _altar(p:Callable,s:float)->void:
	# A low altar of fitted stones, a carved post behind it, offerings and fire.
	_poly([p.call(118,40),p.call(126,34),p.call(134,40),p.call(134,86),p.call(118,86)],WOOD,Color(WOOD.darkened(0.3)),1.2)
	draw_circle(p.call(126,46),5.0*s,WOOD.lightened(0.15))
	_poly([p.call(92,86),p.call(160,86),p.call(168,98),p.call(100,100)],STONE,STONE_DARK,1.3)
	_poly([p.call(100,100),p.call(168,98),p.call(168,112),p.call(100,114)],STONE_DARK,STONE_DARK.darkened(0.2),1.0)
	_pot(p,108,84,7.0)
	_pot(p,150,82,6.0)
	for grain in [[124,82],[129,80],[134,83]]: draw_circle(p.call(float(grain[0]),float(grain[1])),2.0*s,THATCH)
	_fire(p,176,126,22.0)
	_stone(p,60,118,16,10)
	_stone(p,196,100,14,9)


func _house(p:Callable,s:float)->void:
	# Walls, a steep thatched gable, a dark door, a standing stone and a fire.
	_poly([p.call(78,78),p.call(150,70),p.call(150,118),p.call(78,126)],WALL,WALL_DARK,1.3)
	_poly([p.call(150,70),p.call(186,84),p.call(186,128),p.call(150,118)],WALL_DARK,WALL_DARK.darkened(0.2),1.2)
	_poly([p.call(66,82),p.call(114,26),p.call(158,66),p.call(150,74)],THATCH,THATCH_DARK,1.4)
	_poly([p.call(114,26),p.call(196,48),p.call(198,90),p.call(158,66)],THATCH_DARK,THATCH_DARK.darkened(0.25),1.2)
	for i in 7:
		var x:=74.0+float(i)*11.0
		draw_line(p.call(x,78-float(i)*7.6+2),p.call(x+10,78-float(i)*7.6+10),Color(THATCH_DARK,0.55),1.0*s,true)
	draw_line(p.call(108,20),p.call(120,32),WOOD,2.2*s,true);draw_line(p.call(120,20),p.call(108,32),WOOD,2.2*s,true)
	_poly([p.call(104,124),p.call(104,96),p.call(122,94),p.call(122,122)],Color("3b2a1c"))
	_poly([p.call(52,122),p.call(56,84),p.call(66,82),p.call(70,124)],STONE,STONE_DARK,1.2)
	_pot(p,132,124,6.0)
	_pot(p,94,130,5.0)
	_fire(p,154,146,18.0)
