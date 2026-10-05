extends Control
## Small, retained wealth readings. Values stay in their original units;
## charts never normalize household shares or invent a history to draw.
## Assign values/labels as complete arrays to invalidate the retained drawing.
const T:=preload("res://scripts/hud/hud_tokens.gd")
const FIFTH_LABELS:=["Poorest","2nd","Middle","4th","Richest"]

var kind:String="fifths":
	set(next):
		if kind==next:return
		kind=next
		_size_for_kind()
		queue_redraw()
var values:Array=[]:
	set(next):
		if values==next:return
		values=next.duplicate()
		queue_redraw()
var labels:Array=[]:
	set(next):
		if labels==next:return
		labels=next.duplicate()
		queue_redraw()
var _accent:=Color.TRANSPARENT
var _has_accent:=false
var accent:Color:
	get:return _accent if _has_accent else T.TEAL
	set(next):
		if _has_accent and _accent==next:return
		_accent=next;_has_accent=true
		queue_redraw()

func _init()->void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	focus_mode=Control.FOCUS_NONE
	_size_for_kind()

func _size_for_kind()->void:
	match kind:
		"ring":custom_minimum_size=Vector2(150,150)
		"comparison":custom_minimum_size=Vector2(200,62)
		_:custom_minimum_size=Vector2(240,170)

func _notification(what:int)->void:
	if what==NOTIFICATION_RESIZED or what==NOTIFICATION_THEME_CHANGED:queue_redraw()

func _value(index:int)->float:
	if index>=values.size() or not (values[index] is float or values[index] is int):return 0.0
	var value:=float(values[index])
	return maxf(0.0,value) if is_finite(value) else 0.0

func _label(index:int,fallback:String)->String:
	return String(labels[index]) if index<labels.size() else fallback

func _fifths_scale()->float:
	var peak:=0.4
	for index in 5:peak=maxf(peak,_value(index))
	return ceilf(peak/0.2-0.000001)*0.2

## A negative fraction means that there is no denominator, not zero percent
## of a fictitious stock. Over-reserved or invalid inputs cannot draw >1 turn.
func _available_fraction()->float:
	var total:=_value(1)
	return clampf(_value(0)/total,0.0,1.0) if total>0.0 else -1.0

func _draw()->void:
	if size.x<=0.0 or size.y<=0.0:return
	match kind:
		"ring":_draw_ring()
		"comparison":_draw_comparison()
		_:_draw_fifths()

func _draw_fifths()->void:
	var plot:=Rect2(32,25,maxf(1.0,size.x-38.0),maxf(1.0,size.y-55.0))
	var scale:=_fifths_scale()
	var ticks:=maxi(2,roundi(scale/0.2))
	# Normal shares need at most six rules. Malformed larger inputs still
	# retain a bounded drawing workload while their labels show their values.
	var step:=maxi(1,ceili(float(ticks)/5.0))
	for tick in range(0,ticks+1,step):
		var fraction:=float(tick)/float(ticks)
		var y:=plot.end.y-plot.size.y*fraction
		draw_line(Vector2(plot.position.x-3,y),Vector2(plot.end.x,y),Color(T.RULE,0.55 if tick==0 else 0.28),1.0,true)
		_text("%d%%" % roundi(float(tick)*20.0),Rect2(0,y-8,27,16),12,T.INK_MUTED,false,HORIZONTAL_ALIGNMENT_RIGHT)
	var cell:=plot.size.x/5.0
	var width:=minf(35.0,cell*0.56)
	for index in 5:
		var amount:=_value(index)
		var middle:=plot.position.x+(float(index)+0.5)*cell
		var height:=plot.size.y*clampf(amount/scale,0.0,1.0)
		var color:=accent.lerp(T.GOLD,float(index)/4.0)
		if height>0.0:
			var bar:=Rect2(middle-width*0.5,plot.end.y-height,width,height)
			draw_rect(bar,Color(color,0.78))
			draw_line(bar.position,Vector2(bar.end.x,bar.position.y),color,2.0,true)
		_text("%d%%" % roundi(amount*100.0),Rect2(middle-cell*0.5,plot.end.y-height-23,cell,20),14,T.INK,true)
		_text(_label(index,FIFTH_LABELS[index]),Rect2(middle-cell*0.5,plot.end.y+7,cell,20),12,T.INK_MUTED)

func _draw_ring()->void:
	var center:=size*0.5
	var radius:=maxf(1.0,minf(size.x,size.y)*0.5-13.0)
	var stroke:=9.0
	var fraction:=_available_fraction()
	draw_arc(center,radius,-PI*0.5,PI*1.5,96,Color(T.RULE,0.38),stroke,true)
	if fraction>0.0:
		var finish:=-PI*0.5+TAU*fraction
		draw_arc(center,radius,-PI*0.5,finish,maxi(3,ceili(96.0*fraction)),accent,stroke,true)
		draw_circle(center+Vector2(0,-radius),stroke*0.5,accent)
		draw_circle(center+Vector2.from_angle(finish)*radius,stroke*0.5,accent)
	var text:="%d%%" % roundi(fraction*100.0) if fraction>=0.0 else "—"
	_text(text,Rect2(center-Vector2(radius,24),Vector2(radius*2,39)),31,T.INK if fraction>=0.0 else T.INK_MUTED,true)
	_text("available",Rect2(center-Vector2(radius,-16),Vector2(radius*2,18)),12,T.INK_MUTED)

func _draw_comparison()->void:
	var first:=_value(0);var second:=_value(1)
	var top:=maxf(first,second)
	var font:=T.font("ui_strong")
	var value_width:=maxf(46.0,maxf(font.get_string_size("%.1f" % first,HORIZONTAL_ALIGNMENT_LEFT,-1,13).x,font.get_string_size("%.1f" % second,HORIZONTAL_ALIGNMENT_LEFT,-1,13).x)+6.0)
	value_width=minf(value_width,size.x*0.45)
	var left:=53.0;var right:=maxf(left+10.0,size.x-value_width-7.0)
	var row_height:=size.y*0.5
	for tick in 3:
		var x:=lerpf(left,right,float(tick)*0.5)
		draw_line(Vector2(x,7),Vector2(x,size.y-7),Color(T.RULE,0.28),1.0,true)
	for index in 2:
		var amount:=first if index==0 else second
		var y:=(float(index)+0.5)*row_height
		var color:=accent if index==0 else T.GOLD
		_text(_label(index,"Ours" if index==0 else "Typical"),Rect2(0,y-10,left-6,20),13,T.INK_MUTED)
		draw_rect(Rect2(left,y-4,right-left,8),Color(T.RULE,0.17))
		if top>0.0 and amount>0.0:draw_rect(Rect2(left,y-4,(right-left)*(amount/top),8),Color(color,0.82))
		_text("%.1f" % amount,Rect2(right+7,y-10,value_width,20),13,T.INK,true,HORIZONTAL_ALIGNMENT_RIGHT)

func _text(text:String,rect:Rect2,font_size:int,color:Color,strong:=false,alignment:=HORIZONTAL_ALIGNMENT_CENTER)->void:
	var font:=T.font("ui_strong" if strong else "ui")
	var width:=font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x
	var x:=rect.position.x
	if alignment==HORIZONTAL_ALIGNMENT_CENTER:x+=maxf(0.0,(rect.size.x-width)*0.5)
	elif alignment==HORIZONTAL_ALIGNMENT_RIGHT:x+=maxf(0.0,rect.size.x-width)
	var y:=rect.position.y+(rect.size.y-font.get_height(font_size))*0.5+font.get_ascent(font_size)
	draw_string(font,Vector2(x,y),text,HORIZONTAL_ALIGNMENT_LEFT,maxf(0.0,rect.end.x-x),font_size,color)
