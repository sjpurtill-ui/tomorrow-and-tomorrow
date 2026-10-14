extends Control
## One balance bar: left is more received, right is more sent. The midpoint
## is equal exchange. This compares recorded worth, not net profit or stocks.
const T:=preload("res://scripts/hud/hud_tokens.gd")
const EraWords:=preload("res://scripts/hud/era_words.gd")

var values:Array=[]:
	set(next):
		if values==next:return
		values=next.duplicate();queue_redraw()
var labels:Array=["Received","Sent"]:
	set(next):
		if labels==next:return
		labels=next.duplicate();queue_redraw()
var inline:bool=false:
	set(next):
		inline=next;custom_minimum_size.y=76 if inline else 112;queue_redraw()

## One line: "in 0" at the left, "out 13" at the right, the balance between.
var compact:bool=false:
	set(next):
		compact=next;custom_minimum_size=Vector2(160,20) if compact else custom_minimum_size;queue_redraw()

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

func _balance()->float:
	var total:=_value(0)+_value(1)
	return (_value(1)-_value(0))/total if total>0.0 else 0.0

func _draw()->void:
	if compact:
		_draw_compact()
		return
	var number_font:=T.font("voice")
	var width:=maxf(0.0,(size.x-24.0)/2.0)
	for index in 2:
		var x:=(width+24.0)*index
		var alignment:=HORIZONTAL_ALIGNMENT_LEFT if index==0 else HORIZONTAL_ALIGNMENT_RIGHT
		var label:=String(labels[index]) if index<labels.size() else ("Received" if index==0 else "Sent")
		var number:=EraWords.grouped(roundi(_value(index)))
		draw_string(number_font,Vector2(x,17),label,alignment,width,17,T.INK_MUTED)
		var number_size:=30
		while number_size>14 and number_font.get_string_size(number,HORIZONTAL_ALIGNMENT_LEFT,-1,number_size).x>width:
			number_size-=1
		draw_string(number_font,Vector2(x,48),number,alignment,width,number_size,T.INK)
	var center:=size.x/2.0
	var offset:=_balance()*center
	draw_rect(Rect2(0,59,size.x,5),Color(T.RULE,0.3))
	if absf(offset)>0.0:draw_rect(Rect2(center+minf(0.0,offset),59,absf(offset),5),T.GOLD if offset>0.0 else T.TEAL)
	draw_line(Vector2(center,55),Vector2(center,69),T.INK_MUTED,1.0)


func _draw_compact()->void:
	var face:=T.font("ui_strong")
	var left:="in "+EraWords.grouped(roundi(_value(0)))
	var right:="out "+EraWords.grouped(roundi(_value(1)))
	var lw:=face.get_string_size(left,HORIZONTAL_ALIGNMENT_LEFT,-1,13).x
	var rw:=face.get_string_size(right,HORIZONTAL_ALIGNMENT_LEFT,-1,13).x
	var mid:=size.y*0.5
	draw_string(face,Vector2(0,mid+5),left,HORIZONTAL_ALIGNMENT_LEFT,-1,13,T.TEAL_TEXT)
	draw_string(face,Vector2(size.x-rw,mid+5),right,HORIZONTAL_ALIGNMENT_LEFT,-1,13,T.GOLD_TEXT)
	var x0:=lw+8.0;var x1:=size.x-rw-8.0
	if x1-x0<10.0:return
	var center:=(x0+x1)*0.5
	var offset:=_balance()*(x1-x0)*0.5
	draw_rect(Rect2(x0,mid-2,x1-x0,4),Color(T.RULE,0.35))
	if absf(offset)>0.0:draw_rect(Rect2(center+minf(0.0,offset),mid-2,absf(offset),4),T.GOLD if offset>0.0 else T.TEAL)
	draw_line(Vector2(center,mid-6),Vector2(center,mid+6),T.INK_MUTED,1.0)
