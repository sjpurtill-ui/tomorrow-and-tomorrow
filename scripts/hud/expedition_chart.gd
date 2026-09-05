extends Control
## A chart of the returned route only. Decorative graticule is not terrain data.
const T:=preload("res://scripts/hud/hud_tokens.gd")
var route:Array=[]
var discoveries:Array=[]
var _points:PackedVector2Array=[]
var _bounds:=Rect2()
var _scale:=1.0
var _offset:=Vector2.ZERO

func _ready()->void:
	custom_minimum_size=Vector2(0,240)
	size_flags_horizontal=Control.SIZE_EXPAND_FILL
	resized.connect(queue_redraw)
	mouse_filter=Control.MOUSE_FILTER_PASS
	tooltip_text="The actual returned route, drawn to a common scale. Hover a waypoint for its distance from departure."

func _draw()->void:
	draw_style_box(T.flat(Color("#102528"),Color("#42605b"),1,8),Rect2(Vector2.ZERO,size))
	var font:=ThemeDB.fallback_font
	for x in range(24,int(size.x),32): draw_line(Vector2(x,42),Vector2(x,size.y-30),Color(0.55,0.7,0.65,0.055))
	for y in range(48,int(size.y-24),32): draw_line(Vector2(16,y),Vector2(size.x-16,y),Color(0.55,0.7,0.65,0.055))
	draw_string(font,Vector2(20,25),"THE RETURNED CHART",HORIZONTAL_ALIGNMENT_LEFT,-1,12,T.GOLD_BRIGHT)
	draw_string(font,Vector2(20,size.y-14),"● departure     ─ outward route     ◇ recorded discovery",HORIZONTAL_ALIGNMENT_LEFT,-1,11,T.TEXT_SOFT)
	var compass:=Vector2(size.x-33,62)
	draw_line(compass-Vector2(0,14),compass+Vector2(0,14),T.GOLD,1,true)
	draw_line(compass-Vector2(9,0),compass+Vector2(9,0),T.GOLD,1,true)
	draw_string(font,compass+Vector2(-4,-20),"N",HORIZONTAL_ALIGNMENT_LEFT,-1,10,T.GOLD)
	if route.size()<2:
		draw_string(font,Vector2(24,125),"No route chart survived in this record.",HORIZONTAL_ALIGNMENT_LEFT,-1,14,T.MUTED)
		return
	_points.clear()
	var raw:PackedVector2Array=[]
	for point in route: raw.append(Vector2(float(point.get("x",0)),float(point.get("z",0))))
	_bounds=Rect2(raw[0],Vector2.ZERO)
	for point in raw: _bounds=_bounds.expand(point)
	_scale=minf((size.x-110)/maxf(1.0,_bounds.size.x),(size.y-104)/maxf(1.0,_bounds.size.y))
	_offset=Vector2(size.x/2.0,(size.y+18)/2.0)-_bounds.get_center()*_scale
	for point in raw: _points.append(point*_scale+_offset)
	draw_polyline(_points,Color(0.8,0.68,0.36,0.10),12,true)
	draw_polyline(_points,T.GOLD_BRIGHT,2.0,true)
	for point in _points: draw_circle(point,2.5,T.GOLD)
	draw_circle(_points[0],7,Color("#102528"))
	draw_arc(_points[0],7,0,TAU,24,T.INK,1.5,true)
	draw_circle(_points[0],3,T.INK)
	for finding in discoveries:
		if not finding.has("position"): continue
		var position:Dictionary=finding.position
		var p:=Vector2(float(position.get("x",0)),float(position.get("z",0)))*_scale+_offset
		var diamond:=PackedVector2Array([p+Vector2(0,-6),p+Vector2(6,0),p+Vector2(0,6),p+Vector2(-6,0),p+Vector2(0,-6)])
		draw_colored_polygon(diamond,Color("#102528"))
		draw_polyline(diamond,T.TEAL,2,true)

func _gui_input(event:InputEvent)->void:
	if not event is InputEventMouseMotion or _points.is_empty(): return
	var nearest:=-1
	var distance:=18.0
	for i in _points.size():
		var candidate:=_points[i].distance_to(event.position)
		if candidate<distance: nearest=i; distance=candidate
	if nearest>=0:
		var point:Dictionary=route[nearest]
		var start:Dictionary=route[0]
		var km:=Vector2(float(point.x)-float(start.x),float(point.z)-float(start.z)).length()
		tooltip_text="Waypoint %d · %d km from departure" % [nearest+1,roundi(km)]
	else: tooltip_text="Returned route · north is up · discoveries are marked with diamonds"
