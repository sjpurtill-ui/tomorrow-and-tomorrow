extends Control
const Tokens:=preload("res://scripts/hud/hud_tokens.gd")
var points:Array=[]
var series:Array=[]
var unit:=""
var plot:=Rect2()
var low:=0.0
var high:=1.0
var first_day:=0
var last_day:=1
var hover_index:=-1
static func number(value:float)->String:
	if absf(value)>=1e9: return "%.2fB" % (value/1e9)
	if absf(value)>=1e6: return "%.2fM" % (value/1e6)
	if absf(value)>=1e3: return "%.1fk" % (value/1e3)
	return "%.1f" % value
func _ready()->void:
	custom_minimum_size=Vector2(0,215)
	mouse_filter=Control.MOUSE_FILTER_PASS
	resized.connect(queue_redraw)
	mouse_exited.connect(func()->void:hover_index=-1;queue_redraw())
func configure(rows:Array,lines:Array,units:String)->void:
	points=rows
	series=lines
	unit=units
	hover_index=-1
	queue_redraw()
func position_for(point:Dictionary,key:String)->Vector2:
	return Vector2(plot.position.x+plot.size.x*float(int(point.day)-first_day)/maxf(1.0,last_day-first_day),plot.end.y-plot.size.y*(float(point[key])-low)/(high-low))
func _draw()->void:
	draw_style_box(Tokens.flat(Tokens.TILE_BG,Tokens.BORDER_2,1,5),Rect2(Vector2.ZERO,size))
	plot=Rect2(Vector2(61,24),Vector2(maxf(1,size.x-76),maxf(1,size.y-60)))
	if points.is_empty():
		draw_string(ThemeDB.fallback_font,Vector2(16,64),"No recorded history yet.",HORIZONTAL_ALIGNMENT_LEFT,-1,13,Tokens.MUTED)
		draw_string(ThemeDB.fallback_font,Vector2(16,86),"Recording begins as the simulation advances.",HORIZONTAL_ALIGNMENT_LEFT,-1,11,Tokens.MUTED)
		return
	first_day=int(points[0].day)
	last_day=maxi(first_day+1,int(points[-1].day))
	low=0.0
	high=1.0
	for row in points:
		for line in series:
			if row.has(line.key) and is_finite(float(row[line.key])): high=maxf(high,float(row[line.key]))
	high*=1.12
	draw_string(ThemeDB.fallback_font,Vector2(9,15),unit,HORIZONTAL_ALIGNMENT_LEFT,-1,10,Tokens.MUTED)
	for index in 4:
		var ratio:=float(index)/3.0
		var y:=plot.end.y-plot.size.y*ratio
		draw_line(Vector2(plot.position.x,y),Vector2(plot.end.x,y),Tokens.BORDER_2)
		draw_string(ThemeDB.fallback_font,Vector2(5,y+4),number(high*ratio),HORIZONTAL_ALIGNMENT_LEFT,54,10,Tokens.MUTED)
	var has_values:=false
	for line in series:
		var segment:=PackedVector2Array()
		for row in points:
			if not row.has(line.key) or not is_finite(float(row[line.key])):
				_draw_segment(segment,line.color)
				segment=PackedVector2Array()
				continue
			has_values=true
			segment.append(position_for(row,line.key))
		_draw_segment(segment,line.color)
	if not has_values: draw_string(ThemeDB.fallback_font,plot.position+Vector2(8,48),"No observations for these measures in this range.",HORIZONTAL_ALIGNMENT_LEFT,-1,11,Tokens.MUTED)
	for index in 3:
		var ratio:=float(index)/2.0
		var day:=roundi(lerpf(first_day,last_day,ratio))
		var label:="Y%d · d%d" % [day/365+1,day%365+1]
		var width:=ThemeDB.fallback_font.get_string_size(label,HORIZONTAL_ALIGNMENT_LEFT,-1,10).x
		draw_string(ThemeDB.fallback_font,Vector2(plot.position.x+plot.size.x*ratio-width*ratio,size.y-12),label,HORIZONTAL_ALIGNMENT_LEFT,-1,10,Tokens.MUTED)
	if hover_index>=0 and hover_index<points.size():
		var row:Dictionary=points[hover_index]
		var x:=plot.position.x+plot.size.x*float(int(row.day)-first_day)/maxf(1,last_day-first_day)
		draw_line(Vector2(x,plot.position.y),Vector2(x,plot.end.y),Tokens.MUTED,1)
		for line in series:
			if row.has(line.key): draw_circle(position_for(row,line.key),4,line.color)
func _draw_segment(segment:PackedVector2Array,color:Color)->void:
	if segment.size()>1: draw_polyline(segment,color,2.2,true)
	elif segment.size()==1: draw_circle(segment[0],3,color)
func _gui_input(event:InputEvent)->void:
	if not event is InputEventMouseMotion or points.is_empty() or not plot.has_point(event.position): return
	var day:float=first_day+(event.position.x-plot.position.x)/plot.size.x*(last_day-first_day)
	var distance:=INF
	for index in points.size():
		var candidate:=absf(float(points[index].day)-day)
		if candidate<distance: distance=candidate;hover_index=index
	var row:Dictionary=points[hover_index]
	tooltip_text="Year %d, day %d · recorded snapshot" % [int(row.day)/365+1,int(row.day)%365+1]
	for line in series: tooltip_text+="\n%s: %s %s" % [line.label,number(float(row[line.key])) if row.has(line.key) else "not recorded",unit]
	queue_redraw()
