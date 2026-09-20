extends Control
const T:=preload("res://scripts/hud/hud_tokens.gd")
var points:Array=[]
func _ready()->void:
	custom_minimum_size=Vector2(95,36);mouse_filter=Control.MOUSE_FILTER_PASS
	tooltip_text="Recorded stock history; missing observations are gaps."
func _draw()->void:
	var known:Array=[]
	for p:Dictionary in points:
		if p.value!=null:known.append(p)
	if known.size()<2:
		draw_string(ThemeDB.fallback_font,Vector2(3,22),"No history",HORIZONTAL_ALIGNMENT_LEFT,-1,10,T.MUTED);return
	var low:=INF;var high:=-INF
	for p:Dictionary in known:low=minf(low,float(p.value));high=maxf(high,float(p.value))
	var first:=float(points[0].day);var span:=maxf(1,float(points[-1].day)-first)
	var previous:=Vector2.ZERO;var connected:=false
	for p:Dictionary in points:
		if p.value==null:connected=false;continue
		var here:=Vector2(3+(size.x-6)*(float(p.day)-first)/span,size.y-5-(size.y-10)*(float(p.value)-low)/maxf(1,high-low))
		if connected:draw_line(previous,here,T.GREEN,1.6,true)
		previous=here;connected=true
