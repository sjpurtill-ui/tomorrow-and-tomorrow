extends Control
class_name HealthHistoryChart

const Tokens:=preload("res://scripts/hud/hud_tokens.gd")

var points:Array=[]
var plot_rect:=Rect2()

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
		var value:=float((point_variant as Dictionary).get("life_expectancy",0.0))
		low=minf(low,value)
		high=maxf(high,value)
	if not is_finite(low) or not is_finite(high): return
	var padding:=maxf(1.5,(high-low)*0.12)
	low=maxf(0.0,floor(low-padding))
	high=ceil(high+padding)
	if high-low<4.0: high=low+4.0
	for grid_index in 3:
		var ratio:=float(grid_index)/2.0
		var y:=plot_rect.position.y+plot_rect.size.y*ratio
		draw_line(Vector2(plot_rect.position.x,y),Vector2(plot_rect.end.x,y),Tokens.BORDER_2,1.0)
		var label_value:=lerpf(high,low,ratio)
		draw_string(ThemeDB.fallback_font,Vector2(7,y+4),"%.0f" % label_value,HORIZONTAL_ALIGNMENT_LEFT,32,10,Tokens.MUTED)
	var line:=PackedVector2Array()
	for index in points.size():
		var point:Dictionary=points[index]
		var x_ratio:=0.0 if points.size()==1 else float(index)/float(points.size()-1)
		var y_ratio:=(high-float(point.get("life_expectancy",low)))/(high-low)
		line.append(Vector2(plot_rect.position.x+plot_rect.size.x*x_ratio,plot_rect.position.y+plot_rect.size.y*y_ratio))
	if line.size()>1: draw_polyline(line,Tokens.TEAL,2.5,true)
	elif line.size()==1: draw_circle(line[0],3.0,Tokens.TEAL)
	for index in points.size():
		var point:Dictionary=points[index]
		var marker:=String(point.get("marker_type",""))
		if marker=="": continue
		var marker_position:Vector2=line[index]
		if marker=="discovery":
			var diamond:=PackedVector2Array([marker_position+Vector2(0,-6),marker_position+Vector2(6,0),marker_position+Vector2(0,6),marker_position+Vector2(-6,0)])
			draw_colored_polygon(diamond,Tokens.GOLD)
		else:
			draw_circle(marker_position,5.0,Tokens.RED if float(point.get("delta",0.0))<0.0 else Tokens.BLUE)
	var first_day:=int((points[0] as Dictionary).get("day",0))
	var last_day:=int((points[-1] as Dictionary).get("day",first_day))
	draw_string(ThemeDB.fallback_font,Vector2(plot_rect.position.x,size.y-10),"Y%d" % (first_day/365+1),HORIZONTAL_ALIGNMENT_LEFT,50,10,Tokens.MUTED)
	draw_string(ThemeDB.fallback_font,Vector2(plot_rect.end.x-50,size.y-10),"Y%d" % (last_day/365+1),HORIZONTAL_ALIGNMENT_RIGHT,50,10,Tokens.MUTED)

func _gui_input(event:InputEvent)->void:
	var motion:=event as InputEventMouseMotion
	if motion==null or points.is_empty() or not plot_rect.has_point(motion.position): return
	var ratio:=clampf((motion.position.x-plot_rect.position.x)/maxf(1.0,plot_rect.size.x),0.0,1.0)
	var index:=clampi(roundi(ratio*float(points.size()-1)),0,points.size()-1)
	var point:Dictionary=points[index]
	var text:="Year %d, day %d · %.1f years" % [int(point.get("day",0))/365+1,int(point.get("day",0))%365+1,float(point.get("life_expectancy",0.0))]
	if String(point.get("marker_label",""))!="": text+="\n"+String(point.marker_label)
	tooltip_text=text
