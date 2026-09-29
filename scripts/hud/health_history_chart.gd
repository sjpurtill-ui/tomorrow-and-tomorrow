extends Control
class_name HealthHistoryChart
## A line over the recorded months with marks where something changed. Drawn
## for life expectancy (the Health dock) and for each of the twelve capacities
## (dock_detail_capacity.gd); the defaults are the Health dock's.

const Tokens:=preload("res://scripts/hud/hud_tokens.gd")

var points:Array=[]
var plot_rect:=Rect2()
## Which key of each point holds its value.
var value_key:="life_expectancy"
## The smallest span the vertical axis shows, and the bounds it never passes.
var min_span:=4.0
var floor_value:=0.0
var ceiling_value:=INF
## A point in words for the hover text; the Health dock's words by default.
var describe:Callable=Callable()

func _ready()->void:
	custom_minimum_size=Vector2(0,230)
	mouse_filter=Control.MOUSE_FILTER_STOP
	resized.connect(queue_redraw)

func set_points(value:Array)->void:
	points=value.duplicate(true)
	queue_redraw()

func _draw()->void:
	var bounds:=Rect2(Vector2.ZERO,size)
	draw_style_box(Tokens.flat(Tokens.TILE_BG,Tokens.BORDER_2,1,5),bounds)
	plot_rect=Rect2(Vector2(42,16),Vector2(maxf(10.0,size.x-56.0),maxf(10.0,size.y-48.0)))
	if points.is_empty():
		draw_string(ThemeDB.fallback_font,Vector2(18,42),"History begins with the next recorded month.",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Tokens.MUTED)
		return
	var low:=INF
	var high:=-INF
	for point_variant in points:
		var value:=float((point_variant as Dictionary).get(value_key,0.0))
		low=minf(low,value)
		high=maxf(high,value)
	if not is_finite(low) or not is_finite(high): return
	var padding:=maxf(1.5,(high-low)*0.12)
	low=maxf(floor_value,floor(low-padding))
	high=minf(ceiling_value,ceil(high+padding))
	if high-low<min_span:
		high=minf(ceiling_value,low+min_span)
		low=maxf(floor_value,high-min_span)
	for grid_index in 3:
		var ratio:=float(grid_index)/2.0
		var y:=plot_rect.position.y+plot_rect.size.y*ratio
		draw_line(Vector2(plot_rect.position.x,y),Vector2(plot_rect.end.x,y),Tokens.BORDER_2,1.0)
		var label_value:=lerpf(high,low,ratio)
		draw_string(ThemeDB.fallback_font,Vector2(6,y+5),"%.0f" % label_value,HORIZONTAL_ALIGNMENT_LEFT,34,12,Tokens.MUTED)
	var line:=PackedVector2Array()
	for index in points.size():
		var point:Dictionary=points[index]
		var x_ratio:=0.0 if points.size()==1 else float(index)/float(points.size()-1)
		var y_ratio:=(high-float(point.get(value_key,low)))/maxf(0.0001,high-low)
		line.append(Vector2(plot_rect.position.x+plot_rect.size.x*x_ratio,plot_rect.position.y+plot_rect.size.y*y_ratio))
	if line.size()>1: draw_polyline(line,Tokens.TEAL,2.5,true)
	elif line.size()==1: draw_circle(line[0],3.0,Tokens.TEAL)
	for index in points.size():
		var point:Dictionary=points[index]
		var marker:=String(point.get("marker_type",""))
		if marker=="": continue
		draw_marker(self,marker,line[index],float(point.get("delta",0.0)))
	var first_day:=int((points[0] as Dictionary).get("day",0))
	var last_day:=int((points[-1] as Dictionary).get("day",first_day))
	var Era:=preload("res://scripts/hud/era_words.gd")
	draw_string(ThemeDB.fallback_font,Vector2(plot_rect.position.x,size.y-8),Era.when(first_day),HORIZONTAL_ALIGNMENT_LEFT,plot_rect.size.x*0.5,12,Tokens.MUTED)
	draw_string(ThemeDB.fallback_font,Vector2(plot_rect.end.x-plot_rect.size.x*0.5,size.y-8),Era.when(last_day),HORIZONTAL_ALIGNMENT_RIGHT,plot_rect.size.x*0.5,12,Tokens.MUTED)

## One mark: a gold diamond for new knowledge, a circle for a shift in how we
## live (blue when better, red when worse), a square for a finished work, a
## triangle for a decree or a new office holder, a cross for hard times.
static func draw_marker(canvas:CanvasItem,kind:String,at:Vector2,delta:float,radius:float=6.0)->void:
	match kind:
		"discovery":
			canvas.draw_colored_polygon(PackedVector2Array([at+Vector2(0,-radius),at+Vector2(radius,0),at+Vector2(0,radius),at+Vector2(-radius,0)]),Tokens.GOLD)
		"building":
			var side:=radius*0.8
			canvas.draw_rect(Rect2(at-Vector2(side,side),Vector2(side,side)*2.0),Tokens.TEAL)
		"decree":
			canvas.draw_colored_polygon(PackedVector2Array([at+Vector2(0,-radius),at+Vector2(radius,radius*0.8),at+Vector2(-radius,radius*0.8)]),Tokens.VIOLET)
		"crisis":
			var arm:=radius*0.75
			canvas.draw_line(at+Vector2(-arm,-arm),at+Vector2(arm,arm),Tokens.RED,2.5,true)
			canvas.draw_line(at+Vector2(-arm,arm),at+Vector2(arm,-arm),Tokens.RED,2.5,true)
		"up":
			canvas.draw_circle(at,radius-1.0,Tokens.BLUE)
		"down":
			canvas.draw_circle(at,radius-1.0,Tokens.RED)
		_:
			canvas.draw_circle(at,radius-1.0,Tokens.RED if delta<0.0 else Tokens.BLUE)

func _gui_input(event:InputEvent)->void:
	var motion:=event as InputEventMouseMotion
	if motion==null or points.is_empty() or not plot_rect.has_point(motion.position): return
	var ratio:=clampf((motion.position.x-plot_rect.position.x)/maxf(1.0,plot_rect.size.x),0.0,1.0)
	var index:=clampi(roundi(ratio*float(points.size()-1)),0,points.size()-1)
	var point:Dictionary=points[index]
	var text:=""
	if describe.is_valid(): text=String(describe.call(point))
	else: text="%s: a newborn could hope for %.1f years" % [preload("res://scripts/hud/era_words.gd").when(int(point.get("day",0))),float(point.get("life_expectancy",0.0))]
	if String(point.get("marker_label",""))!="": text+="\n"+String(point.marker_label)
	tooltip_text=text

## A small glyph drawn exactly as the chart draws its marks, for a legend.
class Glyph extends Control:
	var kind:=""
	var delta:=0.0
	func _init(glyph_kind:String="",glyph_delta:float=0.0)->void:
		kind=glyph_kind;delta=glyph_delta
		custom_minimum_size=Vector2(14,14)
		size_flags_vertical=Control.SIZE_SHRINK_CENTER
		mouse_filter=Control.MOUSE_FILTER_IGNORE
	func _draw()->void:
		HealthHistoryChart.draw_marker(self,kind,size*0.5,delta,5.0)
