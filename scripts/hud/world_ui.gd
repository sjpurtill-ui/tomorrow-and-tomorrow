extends RefCounted
## WORLD UI: the small dense pieces the World pages share (Expeditions,
## History, Standing, Spies): a paper sheet, a heading with its count on the
## right, one-line rows, chips, verb buttons, coloured tags and thin bars.
## Ink on paper, 12 px or more, no boxes that open other screens.

const T:=preload("res://scripts/hud/hud_tokens.gd")
const Icons:=preload("res://scripts/resource_icons.gd")

const ROW_H:=26.0

## A raised paper sheet; returns its inner column.
static func sheet(parent:Node,node_name:String,pad:float=12.0)->VBoxContainer:
	var frame:=PanelContainer.new();frame.name=node_name
	var style:=T.flat(T.PAPER_RAISED,T.BORDER_SOFT,1,T.RADIUS_CARD)
	style.content_margin_left=pad;style.content_margin_right=pad;style.content_margin_top=pad-2.0;style.content_margin_bottom=pad
	frame.add_theme_stylebox_override("panel",style)
	frame.size_flags_horizontal=Control.SIZE_EXPAND_FILL;frame.size_flags_vertical=Control.SIZE_SHRINK_BEGIN
	parent.add_child(frame)
	var column:=VBoxContainer.new();column.add_theme_constant_override("separation",4);frame.add_child(column)
	return column

## "UNREAD TELLINGS ....... 62" : a kicker and a right-hand count or note.
static func heading(parent:Node,text:String,note:String="",note_color:Color=Color(0,0,0,0))->HBoxContainer:
	var row:=HBoxContainer.new();row.add_theme_constant_override("separation",8);parent.add_child(row)
	var title:=T.make_label(text.to_upper(),12,T.GOLD_TEXT,0.06);title.name="Heading";title.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	title.add_theme_font_override("font",T.font("ui_strong"))
	row.add_child(title)
	if note!="":
		var aside:=T.make_label(note,12,note_color if note_color.a>0.0 else T.INK_MUTED);aside.name="Note"
		row.add_child(aside)
	return row

static func label(parent:Node,text:String,size:int=13,color:Color=Color(0,0,0,0),strong:bool=false,expand:bool=false)->Label:
	var node:=Label.new();node.text=text;node.mouse_filter=Control.MOUSE_FILTER_PASS
	node.add_theme_font_override("font",T.font("ui_strong" if strong else "ui"))
	node.add_theme_font_size_override("font_size",maxi(T.MIN_FONT_SIZE,size))
	node.add_theme_color_override("font_color",color if color.a>0.0 else T.BODY)
	node.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	if expand:
		node.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		node.clip_text=true;node.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	if parent!=null:parent.add_child(node)
	return node

## A fixed-width cell label (a table column).
static func cell(parent:Node,text:String,width:float,size:int=13,color:Color=Color(0,0,0,0),strong:bool=false,align:int=HORIZONTAL_ALIGNMENT_LEFT)->Label:
	var node:=label(parent,text,size,color,strong)
	node.custom_minimum_size.x=width;node.horizontal_alignment=align
	node.clip_text=true;node.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	return node

## One table line.
static func line(parent:Node,gap:int=8)->HBoxContainer:
	var row:=HBoxContainer.new();row.add_theme_constant_override("separation",gap)
	row.custom_minimum_size.y=ROW_H
	parent.add_child(row)
	return row

## A whole row that lights under the pointer and acts on a click.
static func hot_row(parent:Node,node_name:String,on_click:Callable,tip:String="")->HBoxContainer:
	var panel:=PanelContainer.new();panel.name=node_name
	var calm:=T.flat(Color(0,0,0,0),Color(0,0,0,0),0,T.RADIUS_CONTROL);calm.content_margin_left=4;calm.content_margin_right=4
	var lit:=T.flat(T.HOVER_BG,Color(0,0,0,0),0,T.RADIUS_CONTROL);lit.content_margin_left=4;lit.content_margin_right=4
	panel.add_theme_stylebox_override("panel",calm)
	panel.tooltip_text=tip
	parent.add_child(panel)
	if on_click.is_valid():
		panel.mouse_filter=Control.MOUSE_FILTER_STOP
		panel.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
		panel.mouse_entered.connect(func()->void:panel.add_theme_stylebox_override("panel",lit))
		panel.mouse_exited.connect(func()->void:panel.add_theme_stylebox_override("panel",calm))
		panel.gui_input.connect(func(event:InputEvent)->void:
			var click:=event as InputEventMouseButton
			if click!=null and click.pressed and click.button_index==MOUSE_BUTTON_LEFT:
				panel.accept_event();on_click.call())
	var row:=HBoxContainer.new();row.add_theme_constant_override("separation",8);row.custom_minimum_size.y=ROW_H
	row.mouse_filter=Control.MOUSE_FILTER_PASS
	panel.add_child(row)
	return row

## A small verb button ("Read", "Send", "Watch").
static func verb(parent:Node,text:String,on_press:Callable,tip:String="",primary:bool=false)->Button:
	var b:=Button.new();b.text=text;b.tooltip_text=tip;b.focus_mode=Control.FOCUS_NONE
	b.custom_minimum_size=Vector2(0,24);b.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	b.add_theme_font_override("font",T.font("ui_strong"));b.add_theme_font_size_override("font_size",12)
	for key in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:b.add_theme_color_override(key,T.GOLD_TEXT if primary else T.INK)
	b.add_theme_color_override("font_disabled_color",T.DISABLED)
	var normal:=T.flat(T.GOLD_WASH if primary else T.PAPER_SUNK,T.GOLD if primary else T.RULE,1,T.RADIUS_CONTROL);normal.content_margin_left=7;normal.content_margin_right=7
	var hover:=T.flat(T.HOVER_BG,T.RULE_STRONG,1,T.RADIUS_CONTROL);hover.content_margin_left=7;hover.content_margin_right=7
	var off:=T.flat(Color(T.PAPER_SUNK,0.5),Color(T.RULE,0.5),1,T.RADIUS_CONTROL);off.content_margin_left=7;off.content_margin_right=7
	b.add_theme_stylebox_override("normal",normal);b.add_theme_stylebox_override("hover",hover);b.add_theme_stylebox_override("pressed",hover)
	b.add_theme_stylebox_override("disabled",off);b.add_theme_stylebox_override("focus",StyleBoxEmpty.new())
	if on_press.is_valid():b.pressed.connect(on_press)
	if parent!=null:parent.add_child(b)
	return b

## A choice chip; a lit one is the choice in force.
static func chip(parent:Node,text:String,lit:bool,on_press:Callable,tip:String="")->Button:
	var b:=Button.new();b.text=text;b.tooltip_text=tip;b.focus_mode=Control.FOCUS_NONE;b.toggle_mode=true
	b.set_pressed_no_signal(lit)
	b.custom_minimum_size=Vector2(0,24);b.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	b.add_theme_font_override("font",T.font("ui_strong" if lit else "ui"));b.add_theme_font_size_override("font_size",12)
	for key in ["font_color","font_hover_color","font_pressed_color","font_hover_pressed_color","font_focus_color"]:b.add_theme_color_override(key,T.INK)
	var off:=T.flat(Color(0,0,0,0),T.RULE,1,10);off.content_margin_left=7;off.content_margin_right=7
	var on:=T.flat(T.GOLD_WASH,T.GOLD,1,10);on.content_margin_left=7;on.content_margin_right=7
	var hover:=T.flat(T.HOVER_BG,T.RULE_STRONG,1,10);hover.content_margin_left=7;hover.content_margin_right=7
	b.add_theme_stylebox_override("normal",off);b.add_theme_stylebox_override("hover",hover)
	b.add_theme_stylebox_override("pressed",on);b.add_theme_stylebox_override("hover_pressed",on)
	b.add_theme_stylebox_override("focus",StyleBoxEmpty.new())
	if on_press.is_valid():b.pressed.connect(on_press)
	if parent!=null:parent.add_child(b)
	return b

## A coloured state tag ("Unread", "Lost 3", "Watched").
static func tag(parent:Node,text:String,tone:String="info")->PanelContainer:
	var ink:=tone_color(tone)
	var pill:=PanelContainer.new();pill.name="Tag"
	var style:=T.flat(Color(ink,0.10),Color(ink,0.7),1,8);style.content_margin_left=6;style.content_margin_right=6
	pill.add_theme_stylebox_override("panel",style);pill.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	pill.mouse_filter=Control.MOUSE_FILTER_PASS
	var words:=label(pill,text,12,T.text_for(ink),true)
	words.name="Words"
	if parent!=null:parent.add_child(pill)
	return pill

static func tone_color(tone:String)->Color:
	match tone:
		"danger":return T.RED
		"warn":return T.AMBER
		"good":return T.GREEN
		"gold":return T.GOLD
		"info","teal":return T.TEAL
		"muted":return T.INK_MUTED
	return T.INK_MUTED

## A moment icon (resource_icons.gd) at row size.
static func icon(parent:Node,kind:String,tint:Color=Color(0,0,0,0),px:int=20)->TextureRect:
	var rect:=TextureRect.new();rect.name="Icon"
	rect.texture=Icons.moment_texture(kind,tint if tint.a>0.0 else T.GOLD,56)
	rect.custom_minimum_size=Vector2(px,px);rect.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;rect.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	rect.mouse_filter=Control.MOUSE_FILTER_PASS
	if parent!=null:parent.add_child(rect)
	return rect

static func spacer(parent:Node)->Control:
	var gap:=Control.new();gap.size_flags_horizontal=Control.SIZE_EXPAND_FILL;gap.mouse_filter=Control.MOUSE_FILTER_IGNORE
	parent.add_child(gap)
	return gap

static func rule(parent:Node)->ColorRect:
	var r:=ColorRect.new();r.color=T.RULE;r.custom_minimum_size=Vector2(0,1);r.mouse_filter=Control.MOUSE_FILTER_IGNORE
	parent.add_child(r)
	return r

static func clear(node:Node)->void:
	for child in node.get_children():
		node.remove_child(child);child.queue_free()


## A thin bar: a fill against a stated maximum, an optional band (low..high,
## faded) and an optional tick (a typical value), all as shares of the bar.
class Bar extends Control:
	const T:=preload("res://scripts/hud/hud_tokens.gd")
	var value:=0.0
	var low:=-1.0
	var high:=-1.0
	var tick:=-1.0
	var ghost:=-1.0
	var color:=Color.WHITE
	func _init()->void:
		custom_minimum_size=Vector2(60,8);mouse_filter=Control.MOUSE_FILTER_PASS
		size_flags_vertical=Control.SIZE_SHRINK_CENTER
	func set_to(amount:float,tint:Color,typical:float=-1.0)->void:
		value=clampf(amount,0.0,1.0);color=tint;tick=typical;queue_redraw()
	func _draw()->void:
		draw_rect(Rect2(Vector2.ZERO,size),Color(T.INK,0.10))
		if high>=0.0 and high>low:
			draw_rect(Rect2(size.x*clampf(low,0.0,1.0),0,size.x*(clampf(high,0.0,1.0)-clampf(low,0.0,1.0)),size.y),Color(color,0.25))
		if value>0.0:draw_rect(Rect2(0,0,maxf(2.0,size.x*value),size.y),color)
		if ghost>=0.0:
			var gx:=clampf(size.x*ghost,1.0,size.x-1.0)
			draw_line(Vector2(gx,0),Vector2(gx,size.y),Color(T.INK,0.45),1.0)
		if tick>=0.0:
			var x:=clampf(size.x*tick,1.0,size.x-1.0)
			draw_line(Vector2(x,-3),Vector2(x,size.y+3),T.INK,1.5)

static func bar(parent:Node,amount:float,tint:Color,width:float=80.0,typical:float=-1.0)->Bar:
	var b:=Bar.new();b.custom_minimum_size=Vector2(width,8);b.set_to(amount,tint,typical)
	if parent!=null:parent.add_child(b)
	return b

## Two (or three) columns on a wide page, one on a narrow one.
static func columns(parent:Node,node_name:String,gap:int=14)->GridContainer:
	var grid:=GridContainer.new();grid.name=node_name;grid.columns=2
	grid.add_theme_constant_override("h_separation",gap);grid.add_theme_constant_override("v_separation",gap)
	grid.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	parent.add_child(grid)
	return grid

## The eight compass words, short: "northeast" -> "NE".
static func short_compass(word:String)->String:
	return String({"north":"N","northeast":"NE","east":"E","southeast":"SE","south":"S","southwest":"SW","west":"W","northwest":"NW"}.get(word.to_lower(),""))
