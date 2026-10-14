extends RefCounted
## Small controls for the compact Production screen, drawn in ink on paper:
## icon buttons (up, down, pause, resume, close, minus, plus, grip), chips,
## the output bar with its rate, and the skill (efficiency) mini-graph.
const T:=preload("res://scripts/hud/hud_tokens.gd")

## A square button that draws its own glyph, so no font symbol is needed.
class IconButton extends Button:
	var glyph:="plus"
	var danger:=false
	var bare:=false
	func _init(kind:String="plus",tip:String="",side:float=26.0,borderless:bool=false)->void:
		glyph=kind;tooltip_text=tip;bare=borderless
		custom_minimum_size=Vector2(maxf(side,40),maxf(side,40));focus_mode=Control.FOCUS_ALL
		size_flags_vertical=Control.SIZE_SHRINK_CENTER
		restyle()
	func restyle()->void:
		T.apply_button_style(self)
		if bare:add_theme_stylebox_override("normal",T.flat(Color.TRANSPARENT,T.BORDER,0,T.RADIUS_CONTROL))
		queue_redraw()
	func set_glyph(kind:String,tip:String="")->void:
		glyph=kind
		if not tip.is_empty():tooltip_text=tip
		queue_redraw()
	func _draw()->void:
		var ink:=T.DISABLED if disabled else (T.RED_TEXT if danger else T.INK)
		var c:=size*0.5
		var r:=minf(size.x,size.y)*0.24
		match glyph:
			"up":draw_polyline(PackedVector2Array([c+Vector2(-r,r*0.5),c+Vector2(0,-r*0.55),c+Vector2(r,r*0.5)]),ink,2.0,true)
			"down":draw_polyline(PackedVector2Array([c+Vector2(-r,-r*0.5),c+Vector2(0,r*0.55),c+Vector2(r,-r*0.5)]),ink,2.0,true)
			"pause":
				draw_rect(Rect2(c+Vector2(-r*0.75,-r),Vector2(r*0.5,r*2.0)),ink)
				draw_rect(Rect2(c+Vector2(r*0.25,-r),Vector2(r*0.5,r*2.0)),ink)
			"play":draw_colored_polygon(PackedVector2Array([c+Vector2(-r*0.6,-r),c+Vector2(r,0),c+Vector2(-r*0.6,r)]),ink)
			"close":
				draw_line(c+Vector2(-r,-r)*0.85,c+Vector2(r,r)*0.85,ink,2.0,true)
				draw_line(c+Vector2(-r,r)*0.85,c+Vector2(r,-r)*0.85,ink,2.0,true)
			"minus":draw_line(c+Vector2(-r,0),c+Vector2(r,0),ink,2.0,true)
			"plus":
				draw_line(c+Vector2(-r,0),c+Vector2(r,0),ink,2.0,true)
				draw_line(c+Vector2(0,-r),c+Vector2(0,r),ink,2.0,true)
			"grip":
				for column in [-1.0,1.0]:
					for row in [-1.0,0.0,1.0]:draw_circle(c+Vector2(column*r*0.45,row*r*0.8),1.4,ink)

## A button with a word on it, in the screen's small type.
static func text_button(label:String,tip:String,active:bool=false,min_width:float=0.0)->Button:
	var b:=Button.new();b.text=label;b.tooltip_text=tip;b.focus_mode=Control.FOCUS_ALL
	b.custom_minimum_size=Vector2(min_width,40);b.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	style_text_button(b,active)
	return b

static func style_text_button(b:Button,active:bool)->void:
	T.apply_button_style(b)
	if active:b.add_theme_stylebox_override("normal",T.button_pressed_style())

## A small label in a tinted pill, for badges ("for Rovik's levy") and tags.
class Chip extends PanelContainer:
	var label:Label
	func _init(text:String="",accent:Color=Color(0,0,0,0),tip:String="")->void:
		label=Label.new();add_child(label)
		label.autowrap_mode=TextServer.AUTOWRAP_OFF
		mouse_filter=Control.MOUSE_FILTER_PASS;size_flags_vertical=Control.SIZE_SHRINK_CENTER;size_flags_horizontal=Control.SIZE_SHRINK_BEGIN
		set_reading(text,accent,tip)
	func set_reading(text:String,accent:Color,tip:String="")->void:
		label.text=text;tooltip_text=tip
		var tone:=accent if accent.a>0.0 else T.RULE_STRONG
		T.text(label,"small",T.text_for(tone) if accent.a>0.0 else T.INK_MUTED)
		var style:=T.flat(Color(tone,0.12),Color(tone,0.55),1,T.RADIUS_CONTROL)
		style.content_margin_left=6;style.content_margin_right=6;style.content_margin_top=1;style.content_margin_bottom=1
		add_theme_stylebox_override("panel",style)

## Output per day as HOI4 shows it: a bar in the line's condition colour with
## the rate on it. The fill is how full the store is against the target (or
## how far the next item is when there is no target).
class OutputBar extends Control:
	var ratio:=0.0
	var tone:=Color.GREEN
	var look:="good"
	var reading:=""
	func _init(width:float=176.0)->void:
		custom_minimum_size=Vector2(width,26);mouse_filter=Control.MOUSE_FILTER_PASS
		size_flags_vertical=Control.SIZE_SHRINK_CENTER
	func set_reading(fill:float,condition:String,text:String,tip:String)->void:
		ratio=clampf(fill,0.0,1.0);look=condition;reading=text;tooltip_text=tip
		match condition:
			"good":tone=T.GREEN
			"warn":tone=T.AMBER
			"bad":tone=T.RED
			_:tone=T.RULE_STRONG
		queue_redraw()
	func text_color()->Color:
		# Ink on every wash: the bar's colour already says the condition, and
		# tinted text on a tinted fill falls under 4.5:1.
		return T.INK
	func _draw()->void:
		# The number is output; only the fine underline is progress to the
		# target. A full-tinted rectangle made a blocked order look productive.
		var track_y:=size.y-4.0
		draw_rect(Rect2(Vector2(0,track_y),Vector2(size.x,3)),T.TRACK)
		if ratio>0.0:draw_rect(Rect2(Vector2(0,track_y),Vector2(size.x*ratio,3)),tone)
		var font:=T.font("ui_strong");var font_size:=16
		draw_string(font,Vector2(0,minf(size.y-8.0,18.0)),reading,HORIZONTAL_ALIGNMENT_LEFT,size.x,font_size,text_color())

## Skill (production efficiency) as a small ramp: the climb from a new
## line's 20% to today's skill in ink, the rest of the way to full skill
## dotted, and the value beside it.
class SkillGraph extends Control:
	var value:=0.2
	func _init()->void:
		custom_minimum_size=Vector2(72,26);mouse_filter=Control.MOUSE_FILTER_PASS
		size_flags_vertical=Control.SIZE_SHRINK_CENTER
	func set_reading(skill:float,tip:String)->void:
		value=clampf(skill,0.0,1.0);tooltip_text=tip;queue_redraw()
	func _point(x:float,left:float,right:float,top:float,bottom:float)->Vector2:
		var t:=clampf((x-left)/maxf(1.0,right-left),0.0,1.0)
		var level:=.1+.9*(1.0-pow(1.0-t,2.2))
		return Vector2(x,bottom-(bottom-top)*level)
	func _draw()->void:
		var left:=1.0;var right:=size.x-30.0;var top:=3.0;var bottom:=size.y-4.0
		draw_line(Vector2(left,bottom),Vector2(right,bottom),T.RULE,1.0)
		draw_line(Vector2(left,top),Vector2(right,top),Color(T.RULE,0.6),1.0)
		# Where today's skill sits on the ramp.
		var t:=1.0-pow(clampf(1.0-(value-.1)/.9,0.0,1.0),1.0/2.2)
		var here:=left+(right-left)*t
		var done:=PackedVector2Array();var ahead:=PackedVector2Array()
		for step in 13:
			var x:=left+(right-left)*step/12.0
			if x<=here:done.append(_point(x,left,right,top,bottom))
			else:ahead.append(_point(x,left,right,top,bottom))
		done.append(_point(here,left,right,top,bottom));ahead.insert(0,_point(here,left,right,top,bottom))
		if done.size()>1:draw_polyline(done,T.GREEN,2.0,true)
		for index in range(0,ahead.size()-1,2):draw_line(ahead[index],ahead[index+1],T.RULE_STRONG,1.2,true)
		draw_circle(_point(here,left,right,top,bottom),2.6,T.INK)
		var font:=T.font("ui_strong");var text:="%d%%" % roundi(value*100.0)
		draw_string(font,Vector2(right+4.0,size.y*0.5+5.0),text,HORIZONTAL_ALIGNMENT_LEFT,-1,12,T.INK)
