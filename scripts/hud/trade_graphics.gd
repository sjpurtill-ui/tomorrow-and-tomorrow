extends Control
## Two recent trade values on one scale. No history or net profit is inferred.
const T:=preload("res://scripts/hud/hud_tokens.gd")
const EraWords:=preload("res://scripts/hud/era_words.gd")

var values:Array=[]:
	set(next):
		if values==next:return
		values=next.duplicate();queue_redraw()
var labels:Array=["Sent","Received"]:
	set(next):
		if labels==next:return
		labels=next.duplicate();queue_redraw()
var inline:bool=false:
	set(next):
		inline=next;custom_minimum_size.y=76 if inline else 112;queue_redraw()

func _init()->void:
	custom_minimum_size=Vector2(180,112)
	size_flags_horizontal=Control.SIZE_EXPAND_FILL
	mouse_filter=Control.MOUSE_FILTER_PASS

func _notification(what:int)->void:
	if what==NOTIFICATION_RESIZED or what==NOTIFICATION_THEME_CHANGED:queue_redraw()

func _value(index:int)->float:
	if index>=values.size() or not (values[index] is int or values[index] is float):return 0.0
	var value:=float(values[index])
	return maxf(value,0.0) if is_finite(value) else 0.0

func _fraction(index:int)->float:
	var top:=maxf(_value(0),_value(1))
	return _value(index)/top if top>0.0 else 0.0

func _draw()->void:
	var font:=T.font("ui")
	var number_font:=T.font("voice")
	if inline:
		var width:=maxf(0.0,(size.x-24.0)/2.0)
		for index in 2:
			var x:=(width+24.0)*index
			var color:=T.GOLD if index==0 else T.TEAL
			draw_string(number_font,Vector2(x,17),String(labels[index]),HORIZONTAL_ALIGNMENT_LEFT,width,17,T.INK_MUTED)
			draw_string(number_font,Vector2(x,48),EraWords.grouped(roundi(_value(index))),HORIZONTAL_ALIGNMENT_LEFT,width,30,T.INK)
			draw_rect(Rect2(x,59,width,4),Color(T.RULE,0.24))
			draw_rect(Rect2(x,59,width*_fraction(index),4),Color(color,0.85))
		return
	var row:=size.y/2.0
	for index in 2:
		var y:=row*index
		var color:=T.GOLD if index==0 else T.TEAL
		var label:=String(labels[index]) if index<labels.size() else ("Sent" if index==0 else "Received")
		var number:=EraWords.grouped(roundi(_value(index)))
		draw_string(font,Vector2(0,y+18),label,HORIZONTAL_ALIGNMENT_LEFT,maxf(0,size.x*.48),14,T.INK_MUTED)
		var number_size:=26
		var width:=number_font.get_string_size(number,HORIZONTAL_ALIGNMENT_LEFT,-1,number_size).x
		while number_size>14 and width>size.x*.5:
			number_size-=1
			width=number_font.get_string_size(number,HORIZONTAL_ALIGNMENT_LEFT,-1,number_size).x
		draw_string(number_font,Vector2(maxf(size.x*.5,size.x-width),y+23),number,HORIZONTAL_ALIGNMENT_LEFT,size.x*.5,number_size,T.INK)
		var bar:=Rect2(0,y+34,size.x,8)
		draw_rect(bar,Color(T.RULE,0.24))
		if _fraction(index)>0.0:draw_rect(Rect2(bar.position,Vector2(bar.size.x*_fraction(index),bar.size.y)),Color(color,0.85))
