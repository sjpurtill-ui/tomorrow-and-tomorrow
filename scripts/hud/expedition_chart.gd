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
	tooltip_text="The road they walked. Point at a stop to see how far it was from where they set out."

func _draw()->void:
	draw_style_box(T.flat(T.PAPER_SUNK,T.RULE,1,T.RADIUS_CARD),Rect2(Vector2.ZERO,size))
	var font:=T.font("ui")
	var grid:=Color(T.RULE.r,T.RULE.g,T.RULE.b,0.35)
	for x in range(24,int(size.x),32): draw_line(Vector2(x,42),Vector2(x,size.y-34),grid)
	for y in range(48,int(size.y-28),32): draw_line(Vector2(16,y),Vector2(size.x-16,y),grid)
	draw_string(font,Vector2(20,26),"Their road, as they drew it",HORIZONTAL_ALIGNMENT_LEFT,-1,14,T.INK)
	draw_string(font,Vector2(20,size.y-14),"● where they set out     ─ their road     ◇ something they found",HORIZONTAL_ALIGNMENT_LEFT,-1,12,T.INK_MUTED)
	var compass:=Vector2(size.x-33,62)
	draw_line(compass-Vector2(0,14),compass+Vector2(0,14),T.INK_MUTED,1,true)
	draw_line(compass-Vector2(9,0),compass+Vector2(9,0),T.INK_MUTED,1,true)
	draw_string(font,compass+Vector2(-4,-20),"N",HORIZONTAL_ALIGNMENT_LEFT,-1,12,T.INK)
	if route.size()<2:
		draw_string(font,Vector2(24,125),"They brought back no drawing of their road.",HORIZONTAL_ALIGNMENT_LEFT,-1,14,T.INK_MUTED)
		return
	_points.clear()
	var raw:PackedVector2Array=[]
	for point in route: raw.append(Vector2(float(point.get("x",0)),float(point.get("z",0))))
	_bounds=Rect2(raw[0],Vector2.ZERO)
	for point in raw: _bounds=_bounds.expand(point)
	_scale=minf((size.x-110)/maxf(1.0,_bounds.size.x),(size.y-104)/maxf(1.0,_bounds.size.y))
	_offset=Vector2(size.x/2.0,(size.y+18)/2.0)-_bounds.get_center()*_scale
	for point in raw: _points.append(point*_scale+_offset)
	draw_polyline(_points,Color(T.GOLD.r,T.GOLD.g,T.GOLD.b,0.14),12,true)
	draw_polyline(_points,T.GOLD_TEXT,2.0,true)
	for point in _points: draw_circle(point,2.5,T.GOLD_TEXT)
	draw_circle(_points[0],7,T.PAPER_RAISED)
	draw_arc(_points[0],7,0,TAU,24,T.INK,1.5,true)
	draw_circle(_points[0],3,T.INK)
	for finding in discoveries:
		if not finding.has("position"): continue
		var position:Dictionary=finding.position
		var p:=Vector2(float(position.get("x",0)),float(position.get("z",0)))*_scale+_offset
		var diamond:=PackedVector2Array([p+Vector2(0,-6),p+Vector2(6,0),p+Vector2(0,6),p+Vector2(-6,0),p+Vector2(0,-6)])
		draw_colored_polygon(diamond,T.PAPER_RAISED)
		draw_polyline(diamond,T.TEAL_TEXT,2,true)

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
		tooltip_text="Stop %d · %d km from where they set out" % [nearest+1,roundi(km)]
	else: tooltip_text="North is up. Diamonds mark what they found."
