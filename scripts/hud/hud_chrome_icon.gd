extends Control
## A small family of ink marks for the command rail and KPI captions.
## Geometry uses a 24-unit square; counters remain transparent over any paper.

const Tokens:=preload("res://scripts/hud/hud_tokens.gd")
const GRID:=24.0
const STROKE:=1.8

var icon_id:String="population":
	set(value):
		icon_id=value.to_lower()
		queue_redraw()
var active:=false
var _custom_color:=Color.WHITE
var _has_custom_color:=false
var _ink:=Color.WHITE
var _detail:=true

func _init(id:String="population")->void:
	icon_id=id
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	focus_mode=Control.FOCUS_NONE
	custom_minimum_size=Vector2(16,16)

func set_icon_color(value:Color)->void:
	_custom_color=value
	_has_custom_color=true
	queue_redraw()

func set_active(value:bool)->void:
	active=value
	queue_redraw()

func _notification(what:int)->void:
	if what==NOTIFICATION_RESIZED or what==NOTIFICATION_THEME_CHANGED:
		queue_redraw()

func _draw()->void:
	var side:=minf(size.x,size.y)
	if side<=0.0:return
	_ink=Tokens.GOLD if active else (_custom_color if _has_custom_color else Tokens.INK)
	_detail=side>=22.0
	var factor:=side/GRID
	draw_set_transform((size-Vector2.ONE*side)*0.5,0.0,Vector2.ONE*factor)
	match icon_id:
		"court":_court()
		"population","overview":_people()
		"standing":_standing()
		"world":_world()
		"military":_military()
		"chronicle":_chronicle()
		"drawer":_ledger()
		"economy","food":_wheat()
		"materials":_materials()
		"wealth":_scales()
		"trade":_trade()
		"construction":_hammer()
		"production":_anvil()
		"civ":_flame()
		"inquiry","science":_book()
		"water":_water()
		"goods":_jug()
		"health":_leaf()
		"gdp":_work()
		"menu":
			for y in [6.0,12.0,18.0]:_line([4,y,20,y],2.0)
		"chevron":_line([9,5,16,12,9,19],2.1)
		_:_people()
	draw_set_transform(Vector2.ZERO)

func _court()->void:
	_line([12,5,12,19],2.0)
	_line([5,9,12,14,19,9])
	_line([7,4,12,9,17,4])
	_fill([10,18,14,18,16,21,8,21])
	_fill([2.8,6,6.5,6.5,7,10,3.5,9.5])
	_fill([21.2,6,17.5,6.5,17,10,20.5,9.5])
	_fill([12,1.8,14.3,4.5,12,7,9.7,4.5])

func _people()->void:
	_oval(12,6.5,2.7,2.7,true)
	_oval(4.8,9,1.9,1.9,true)
	_oval(19.2,9,1.9,1.9,true)
	_bezier([7,20,7,14,8.5,12,12,12,15.5,12,17,14,17,20],false)
	_line([7,20,17,20])
	_bezier([2,18,2,14.2,3.5,12.6,5.5,13.5])
	_bezier([22,18,22,14.2,20.5,12.6,18.5,13.5])

func _standing()->void:
	_shape([7,19,6.5,10,8.5,4,13.5,2.8,17,7,17.5,19])
	_fill([13,5,15,7.5,15.5,17,13,17])
	_line([3,21,21,21])
	if _detail:_line([9,8,8.8,12],1.1)

func _world()->void:
	_oval(12,12,8.5,8.5)
	_oval(12,12,3.7,8.5)
	_line([3.5,12,20.5,12],1.5)
	if _detail:
		_bezier([5,7.3,9,9,15,9,19,7.3],false,1.0)
		_bezier([5,16.7,9,15,15,15,19,16.7],false,1.0)

func _military()->void:
	_shape([12,2.8,20,5.3,18.8,14,16,18,12,21,8,18,5.2,14,4,5.3])
	_fill([12,6,16.8,7.4,15.8,13.5,12,17.5])

func _chronicle()->void:
	_line([6,4,18,4,18,18,16,21,4.5,21])
	_bezier([6,4,2,2,1.8,8,6,7,6,11,6,15,6,18,6,22,1.5,22,3,18])
	_line([10,8,10,15,14,8,14,15],1.5)
	if _detail:_line([8.5,14,15.5,10],1.1)

func _ledger()->void:
	_shape([5,3,20,3,20,21,5,21,3.5,19.5,3.5,5])
	_line([8,3,8,21],1.5)
	_line([11,8,17,8],1.6)
	if _detail:_line([11,12,16,12],1.0)

func _wheat()->void:
	_line([12,5,12,21],1.6)
	_fill([12,2,14,5.5,12,8,10,5.5])
	for y in [8.0,13.0]:
		_fill([6,y-1,10.5,y+0.5,11.5,y+4,7.5,y+2.5])
		_fill([18,y-1,13.5,y+0.5,12.5,y+4,16.5,y+2.5])

func _materials()->void:
	_shape([3,4,15,4,17,6,17,10,3,10])
	_shape([7,14,20,14,21,16,21,20,7,20])
	_line([14,4,14,10],1.4)
	_line([17.5,14,17.5,20],1.4)
	if _detail:
		_line([5.5,7,10.5,7],1.0)
		_line([9.5,17,14,17],1.0)

func _scales()->void:
	_line([12,3,12,20],1.8)
	_line([4,7,20,7],1.8)
	_fill([8,21,10,18,14,18,16,21])
	_shape([5.5,8,2.5,14,8.5,14],false,1.5)
	_shape([18.5,8,15.5,14,21.5,14],false,1.5)
	_bezier([2.5,14,3,17.5,8,17.5,8.5,14],false,1.5)
	_bezier([15.5,14,16,17.5,21,17.5,21.5,14],false,1.5)

func _trade()->void:
	_line([3,7,20,7],1.9)
	_line([16,3,20,7,16,11],1.9)
	_line([21,17,4,17],1.9)
	_line([8,13,4,17,8,21],1.9)

func _hammer()->void:
	_fill([5,19,12,10,14,12,7.5,21])
	_shape([10,5,13,2.5,21,9,17.5,13,10,7])
	if _detail:_line([14.5,5.5,18,8.5],1.0)

func _anvil()->void:
	_shape([3,5,16,5,16,8,21,8,18.5,11,14,12.5,14,17,18,19,18,21,6,21,6,19,10,17,10,12.5,5,10])
	_fill([10,13,14,13,14,17,10,17])
	if _detail:_line([5.5,8,12.5,8],1.0)

func _flame()->void:
	_bezier([12,2,13,6,10,8,11,10,14,10,16,8,16,6,22,12,19,21,12,21,4,21,3,14,7,9,6,14,11,11,12,2])
	_fill([12,12.5,9,17,10.5,19.5,14,19,15,16.5])

func _book()->void:
	_shape([2.5,7,7,5,12,7,17,5,21.5,7,21.5,20,17,18,12,20,7,18,2.5,20])
	_line([12,7,12,20],1.5)
	if _detail:
		_line([5.5,10,8.5,9.5],1.0)
		_line([15.5,9.5,18.5,10],1.0)
		_line([12,2,12,3.5],1.4)

func _water()->void:
	_bezier([12,2,9.5,6,5.5,9,5.5,14,5.5,23,18.5,23,18.5,14,18.5,9,14.5,6,12,2])
	_bezier([8.5,13,8,16,9.5,18,12,18],false,1.5)

func _jug()->void:
	_line([8,3,15,3],1.9)
	_bezier([9,3,10,7,9,8,7,10,2,16,6,21,12,21,18,21,19,16,16,11,14,8,13,7,14,3])
	_bezier([16,9,23,6,23,17,18,16],false,1.8)
	if _detail:_line([8,17,14,17],1.0)

func _leaf()->void:
	_bezier([4,20,1,10,9,3,21,3,21,14,14,22,4,20])
	_line([3,21,16,8],1.6)
	if _detail:_line([8,16,8,11],1.0)

func _work()->void:
	_shape([8.5,4,15.5,4,15.5,11,8.5,11],false,1.7)
	_line([3,12,3,17,8,21,16,21,21,17,21,12],1.8)
	_line([3,13,5,12,9,16,15,16,19,12,21,13],1.8)
	if _detail:_line([12,6,12,9],1.0)

func _points(coords:Array)->PackedVector2Array:
	var points:=PackedVector2Array()
	for i in range(0,coords.size(),2):
		points.append(Vector2(float(coords[i]),float(coords[i+1])))
	return points

func _line(coords:Array,width:float=STROKE)->void:
	draw_polyline(_points(coords),_ink,width,true)

func _shape(coords:Array,filled:bool=false,width:float=STROKE)->void:
	var points:=_points(coords)
	if filled:draw_colored_polygon(points,_ink)
	points.append(points[0])
	draw_polyline(points,_ink,width,true)

func _fill(coords:Array)->void:
	# The fine same-ink outline antialiases the edge of each small solid cut.
	_shape(coords,true,0.55)

func _oval(x:float,y:float,rx:float,ry:float,filled:bool=false)->void:
	var points:=PackedVector2Array()
	for i in 33:
		var angle:=TAU*float(i)/32.0
		points.append(Vector2(x+cos(angle)*rx,y+sin(angle)*ry))
	if filled:draw_colored_polygon(points,_ink)
	draw_polyline(points,_ink,0.55 if filled else STROKE,true)

func _bezier(coords:Array,filled:bool=false,width:float=STROKE)->void:
	var controls:=_points(coords)
	var points:=PackedVector2Array([controls[0]])
	for i in range(0,controls.size()-1,3):
		for step in range(1,13):
			var t:=float(step)/12.0
			var u:=1.0-t
			points.append(u*u*u*controls[i]+3.0*u*u*t*controls[i+1]+3.0*u*t*t*controls[i+2]+t*t*t*controls[i+3])
	if filled:draw_colored_polygon(points,_ink)
	draw_polyline(points,_ink,width,true)
