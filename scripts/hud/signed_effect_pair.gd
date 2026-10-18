extends Control
## Shared scale within one effect category; negative values extend left of zero.
## These are measured coefficients, not additional years of life.
const T=preload("res://scripts/hud/hud_tokens.gd")
var unlocked:=0.0
var delivered:=0.0
func _init()->void:
	custom_minimum_size=Vector2(48,16);size_flags_vertical=Control.SIZE_SHRINK_CENTER
func fill(full:float,current:float)->void:
	unlocked=full;delivered=current;queue_redraw()
func _draw()->void:
	var middle:=size.x/2.0;var span:=maxf(absf(unlocked),absf(delivered))
	draw_line(Vector2(middle,0),Vector2(middle,size.y),T.MUTED,1)
	if is_zero_approx(span):return
	for index in 2:
		var value:=unlocked if index==0 else delivered
		var length:=(middle-2)*value/span
		draw_rect(Rect2(minf(middle,middle+length),2+index*7,absf(length),4),T.GOLD if index==0 else T.TEAL)
