extends "res://scripts/hud/town_works_board.gd"
## THE BUILDINGS PAGE AS A STRATEGY-GAME PANEL: sections of one-line rows
## (icon, name, a few words, a bar, the figure, a state tag, verb buttons),
## with a second short line only where a row carries effects, a bill or what
## stops it. Sections flow into two or three columns as the page widens.
## Presentation only: every reading and action arrives from the providers
## (hud/content/dock_content_construction.gd and dock_content_undertakings.gd).
##
## Block: {"type":"town_works", "board":true, "sections":[section], "cards":[card]}
##   section: {id, heading, note, span (full width), actions [{label, tip, on_press, primary}]}
##   card: the town_works card (town_works_board.gd) plus
##     section     the section id it sits in
##     bar {ratio, color, tick, text}      a short bar on the row (also read: progress, meter)
##     segments [{share, color, label, value, tip}]  a stacked bar on the row
##     tag {text, tone}                    a coloured state word
##     pips true                           needs shown as pips (have / need)

const COLUMN_MIN:=400.0
const BAR_WIDTH:=80.0
## A row's name keeps at most this much width when the row is narrow.
const NAME_MAX:=150.0

var _sections:Dictionary={}
var _bands:Array=[]
var _columns:=0


func setup(block:Dictionary)->void:
	data=block;name="BuildingsBoard"
	theme=_theme()
	add_theme_constant_override("separation",14)
	var by_section:Dictionary={}
	for card:Dictionary in block.get("cards",[]):
		var id:=String(card.get("section","main"))
		if not by_section.has(id):by_section[id]=[]
		(by_section[id] as Array).append(card)
	# Consecutive narrow sections share one band of columns; a span section
	# takes the whole width.
	var band:Array=[]
	for section:Dictionary in block.get("sections",[]):
		var id:=String(section.get("id",""))
		var cards:Array=by_section.get(id,[])
		if cards.is_empty() and String(section.get("note",""))=="" and (section.get("actions",[]) as Array).is_empty():continue
		var node:=_section(section,cards)
		_sections[id]=node
		node.set_meta("weight",_weight(cards))
		if bool(section.get("span",false)):
			if not band.is_empty():_bands.append(band);band=[]
			_bands.append([node])
			node.set_meta("span",true)
		else:band.append(node)
	if not band.is_empty():_bands.append(band)
	for each:Array in _bands:
		var row:=HBoxContainer.new();row.name="Band";row.add_theme_constant_override("separation",28);add_child(row)
		row.set_meta("sections",each)
	resized.connect(_fit)
	_layout(2)
	_fit.call_deferred()


func _fit()->void:
	var count:=clampi(floori((size.x+28.0)/(COLUMN_MIN+28.0)),1,3)
	if count!=_columns:_layout(count)


## Deal each band's sections into `count` columns, the next to the shortest.
func _layout(count:int)->void:
	_columns=count
	for row:HBoxContainer in get_children().filter(func(n:Node)->bool:return n is HBoxContainer and n.has_meta("sections")):
		for column in row.get_children():
			for child in column.get_children():column.remove_child(child)
			row.remove_child(column);column.free()
		var nodes:Array=row.get_meta("sections")
		var spanned:=nodes.size()==1 and bool((nodes[0] as Node).get_meta("span",false))
		var n:=1 if spanned else mini(count,nodes.size())
		var columns:Array=[];var heights:Array=[]
		for i in n:
			var column:=VBoxContainer.new();column.name="Column%d" % i;column.size_flags_horizontal=Control.SIZE_EXPAND_FILL
			column.add_theme_constant_override("separation",14);row.add_child(column);columns.append(column);heights.append(0.0)
		for node:Control in nodes:
			var best:=0
			for i in n:if float(heights[i])<float(heights[best]):best=i
			if node.get_parent()!=null:node.get_parent().remove_child(node)
			(columns[best] as VBoxContainer).add_child(node)
			heights[best]=float(heights[best])+float(node.get_meta("weight",1.0))


static func _weight(cards:Array)->float:
	var w:=1.2
	for card:Dictionary in cards:
		w+=1.0
		if _has_second_line(card):w+=0.8
	return w


static func _has_second_line(card:Dictionary)->bool:
	if card.get("choice") is Dictionary:return true
	for key in ["gains","effects","needs","blockers","notes","actions2"]:
		if not (card.get(key,[]) as Array).is_empty():return true
	return false


# --- A section -------------------------------------------------------------------

func _section(section:Dictionary,cards:Array)->Control:
	var box:=VBoxContainer.new();box.name="Section_"+String(section.get("id",""));box.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation",0)
	var head:=HBoxContainer.new();head.name="Head";head.add_theme_constant_override("separation",8);box.add_child(head)
	var title:=T.make_label(String(section.get("heading","")),19,T.GOLD_TEXT)
	title.add_theme_font_override("font",T.font("voice"));title.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	title.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	head.add_child(title)
	if String(section.get("note",""))!="":
		var note:=_label(String(section.note),12,T.TEXT_SOFT);note.name="Note";note.tooltip_text=String(section.get("note_tip",""))
		note.mouse_filter=Control.MOUSE_FILTER_STOP if note.tooltip_text!="" else Control.MOUSE_FILTER_IGNORE
		head.add_child(note)
	for item:Dictionary in section.get("actions",[]):head.add_child(_button(item))
	var rule:=ColorRect.new();rule.color=T.RULE_STRONG;rule.custom_minimum_size=Vector2(0,1);rule.mouse_filter=Control.MOUSE_FILTER_IGNORE;box.add_child(rule)
	for i in cards.size():
		box.add_child(_row(cards[i]))
		if i<cards.size()-1:
			var hair:=ColorRect.new();hair.color=Color(T.RULE,0.55);hair.custom_minimum_size=Vector2(0,1);hair.mouse_filter=Control.MOUSE_FILTER_IGNORE;box.add_child(hair)
	return box


# --- A row -----------------------------------------------------------------------

func _row(card:Dictionary)->Control:
	var panel:=PanelContainer.new();panel.name="Card_"+String(card.get("key",card.get("name","row"))).replace(" ","_")
	var style:=T.flat(Color(0,0,0,0));style.content_margin_top=4;style.content_margin_bottom=4;style.content_margin_left=2;style.content_margin_right=2
	if bool(card.get("highlight",false)):style.bg_color=T.GOLD_WASH
	panel.add_theme_stylebox_override("panel",style)
	panel.tooltip_text=String(card.get("detail",""))
	panel.mouse_filter=Control.MOUSE_FILTER_STOP
	var lines:=VBoxContainer.new();lines.add_theme_constant_override("separation",3);lines.mouse_filter=Control.MOUSE_FILTER_PASS;panel.add_child(lines)
	var line:=HBoxContainer.new();line.name="Line";line.add_theme_constant_override("separation",8);line.mouse_filter=Control.MOUSE_FILTER_PASS;lines.add_child(line)
	line.add_child(_icon(card))
	var name_label:=_label(String(card.get("name","")),14,T.INK,true);name_label.name="Name"
	name_label.clip_text=true;name_label.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;name_label.tooltip_text=name_label.text
	name_label.custom_minimum_size.x=minf(NAME_MAX,T.font("ui_strong").get_string_size(name_label.text,HORIZONTAL_ALIGNMENT_LEFT,-1,14).x+2.0)
	line.add_child(name_label)
	var sub:=_label(String(card.get("sub","")),12,T.TEXT_SOFT);sub.name="Sub"
	sub.size_flags_horizontal=Control.SIZE_EXPAND_FILL;sub.clip_text=true;sub.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	sub.custom_minimum_size.x=0
	line.add_child(sub)
	if card.get("stamp") is Dictionary:
		var stamp:=Stamp.new();stamp.name="Stamp";stamp.text=String(card.stamp.get("text","Built"));stamp.tooltip_text=String(card.stamp.get("tip",""));stamp.custom_minimum_size=Vector2(66,24);line.add_child(stamp)
	var bar:Variant=card.get("bar",card.get("progress",card.get("meter")))
	if not (card.get("segments",[]) as Array).is_empty():line.add_child(_segments(card.segments))
	elif bar is Dictionary:line.add_child(_inline_bar(bar))
	if String(card.get("value",""))!="":
		var value:=_label(String(card.value),15,T.legible(card.get("value_color",T.INK),T.PAPER),true);value.name="Value"
		value.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT;value.custom_minimum_size.x=float(card.get("value_width",44))
		line.add_child(value)
	if card.get("tag") is Dictionary and not (card.tag as Dictionary).is_empty():line.add_child(_tag(card.tag))
	for item:Dictionary in card.get("actions",[]):line.add_child(_button(item))
	if _has_second_line(card):
		var second:=HFlowContainer.new();second.name="Second";second.add_theme_constant_override("h_separation",16);second.add_theme_constant_override("v_separation",3)
		second.mouse_filter=Control.MOUSE_FILTER_PASS
		var indent:=Control.new();indent.custom_minimum_size=Vector2(22,0);indent.mouse_filter=Control.MOUSE_FILTER_IGNORE;second.add_child(indent)
		for gain:Dictionary in card.get("gains",[]):second.add_child(_gain_chip(gain))
		for effect:Dictionary in card.get("effects",[]):second.add_child(_effect_chip(effect))
		for need:Dictionary in card.get("needs",[]):second.add_child(_pips(need))
		for blocker:Dictionary in card.get("blockers",[]):second.add_child(_chip(blocker,String(blocker.get("tone","bad"))))
		for note:Dictionary in card.get("notes",[]):second.add_child(_chip(note,"note"))
		for item:Dictionary in card.get("actions2",[]):second.add_child(_button(item))
		if card.get("choice") is Dictionary:second.add_child(_small_choice(card.choice))
		lines.add_child(second)
	var press:Variant=card.get("on_press")
	if press is Callable and (press as Callable).is_valid():
		panel.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
		panel.gui_input.connect(func(event:InputEvent)->void:
			if event is InputEventMouseButton and (event as InputEventMouseButton).pressed and (event as InputEventMouseButton).button_index==MOUSE_BUTTON_LEFT:
				panel.accept_event();(press as Callable).call())
	return panel


func _icon(card:Dictionary)->Control:
	var mark:=TextureRect.new();mark.name="Mark"
	var kind:=String(card.get("icon",""))
	if card.get("texture") is Texture2D:mark.texture=card.texture
	elif kind.begins_with("res:"):mark.texture=Icons.material_texture(kind.trim_prefix("res:"),40)
	else:mark.texture=Icons.town_texture(kind if kind!="" else "hall",T.INK,40)
	mark.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;mark.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mark.custom_minimum_size=Vector2(20,20);mark.size_flags_vertical=Control.SIZE_SHRINK_CENTER;mark.mouse_filter=Control.MOUSE_FILTER_IGNORE
	if card.has("icon_color"):mark.modulate=card.icon_color
	return mark


func _inline_bar(spec:Dictionary)->Control:
	var box:=HBoxContainer.new();box.name="Bar";box.add_theme_constant_override("separation",6);box.mouse_filter=Control.MOUSE_FILTER_PASS
	box.tooltip_text=String(spec.get("tip",""))
	var bar:=Meter.new();bar.ratio=clampf(float(spec.get("ratio",0.0)),0.0,1.0);bar.tick=float(spec.get("tick",-1.0))
	bar.fill=spec.get("color",T.GREEN);bar.custom_minimum_size=Vector2(float(spec.get("width",BAR_WIDTH)),8);bar.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	box.add_child(bar)
	if String(spec.get("text",""))!="" and bool(spec.get("show_text",false)):box.add_child(_label(String(spec.text),12,T.TEXT_SOFT))
	return box


## One bar split by share: the builders by job, the homes by kind.
func _segments(items:Array)->Control:
	var bar:=Segments.new();bar.name="Segments";bar.items=items;bar.custom_minimum_size=Vector2(BAR_WIDTH+40.0,10)
	bar.size_flags_vertical=Control.SIZE_SHRINK_CENTER;bar.mouse_filter=Control.MOUSE_FILTER_STOP
	var tips:PackedStringArray=[]
	for item:Dictionary in items:tips.append("%s %s" % [String(item.get("label","")),String(item.get("value",""))])
	bar.tooltip_text=" · ".join(tips)
	return bar


func _tag(tag:Dictionary)->Control:
	var tone:=String(tag.get("tone","note"))
	var chip:=PanelContainer.new();chip.name="Tag";chip.tooltip_text=String(tag.get("tip",""));chip.mouse_filter=Control.MOUSE_FILTER_STOP;chip.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	var ground:Color={"good":Color(T.GREEN,0.14),"bad":T.DANGER_BG,"warn":T.WARN_BG,"info":T.INFO_BG}.get(tone,Color(0,0,0,0))
	var rule:Color={"good":T.GREEN,"bad":T.DANGER_BORDER,"warn":T.WARN_BORDER,"info":T.INFO_BORDER}.get(tone,T.RULE)
	var style:=T.flat(ground,rule,1,3);style.content_margin_left=6;style.content_margin_right=6;style.content_margin_top=0;style.content_margin_bottom=1
	chip.add_theme_stylebox_override("panel",style)
	chip.add_child(_label(String(tag.get("text","")),12,tone_ink(tone) if tone!="note" and tone!="info" else (T.TEAL_TEXT if tone=="info" else T.TEXT_SOFT),true))
	return chip


func _button(item:Dictionary)->Button:
	var button:=Button.new();button.name="Act_"+String(item.get("label","")).replace(" ","_");button.text=String(item.get("label",""))
	button.tooltip_text=String(item.get("tip",""));button.focus_mode=Control.FOCUS_NONE
	button.custom_minimum_size=Vector2(0,24);button.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	button.add_theme_font_size_override("font_size",12)
	if bool(item.get("primary",false)):
		button.add_theme_stylebox_override("normal",T.action_button_style(true));button.add_theme_color_override("font_color",T.GOLD_TEXT)
	if bool(item.get("pressed",false)):
		button.toggle_mode=true;button.set_pressed_no_signal(true)
	var action:Variant=item.get("on_press")
	if action is Callable and (action as Callable).is_valid():button.pressed.connect(func()->void:(action as Callable).call())
	else:button.disabled=true
	return button


## Who decides, as small toggles on the row's second line; the chosen one is held down.
func _small_choice(choice:Dictionary)->Control:
	var row:=_choice(choice)
	for button in row.get_children():
		(button as Button).custom_minimum_size=Vector2(0,22);(button as Button).add_theme_font_size_override("font_size",12)
	return row


func _gain_chip(gain:Dictionary)->Control:
	var chip:=HBoxContainer.new();chip.name="Gain";chip.add_theme_constant_override("separation",4);chip.tooltip_text=String(gain.get("tip",""));chip.mouse_filter=Control.MOUSE_FILTER_STOP
	if String(gain.get("icon",""))!="":chip.add_child(_mark(String(gain.icon),14))
	chip.add_child(_label(String(gain.get("label","")),12,T.TEXT_SOFT))
	chip.add_child(_label("%s → " % String(gain.get("before","")),12,T.TEXT_SOFT))
	chip.add_child(_label(String(gain.get("after","")),13,tone_ink(String(gain.get("tone","good"))),true))
	return chip


func _effect_chip(effect:Dictionary)->Control:
	var chip:=HBoxContainer.new();chip.name="Effect";chip.add_theme_constant_override("separation",4);chip.tooltip_text=String(effect.get("tip",""));chip.mouse_filter=Control.MOUSE_FILTER_STOP
	chip.add_child(_label(String(effect.get("label","")),12,T.TEXT_SOFT))
	chip.add_child(_label(String(effect.get("value","")),12,tone_ink(String(effect.get("tone","plain"))),true))
	return chip


## Have against need as five pips: filled by the share in store, green when
## the bill is met, red when short; the counts beside them.
func _pips(need:Dictionary)->Control:
	var have:=float(need.get("have",0.0));var wanted:=maxf(0.0001,float(need.get("need",0.0)))
	var short:=have+0.0001<wanted
	var chip:=HBoxContainer.new();chip.name="Need";chip.add_theme_constant_override("separation",4);chip.mouse_filter=Control.MOUSE_FILTER_STOP
	var resource:=String(need.get("resource",""))
	var title:=preload("res://scripts/resource_names.gd").label(resource) if resource!="" else String(need.get("label",""))
	chip.tooltip_text=String(need.get("tip","")) if String(need.get("tip",""))!="" else "%s: %s in store, %s needed" % [title,_n(have),_n(wanted)]
	if resource!="":
		var mark:=TextureRect.new();mark.texture=Icons.material_texture(resource,40);mark.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;mark.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		mark.custom_minimum_size=Vector2(16,16);mark.size_flags_vertical=Control.SIZE_SHRINK_CENTER;mark.mouse_filter=Control.MOUSE_FILTER_IGNORE;chip.add_child(mark)
	chip.add_child(_label(title,12,T.TEXT_SOFT))
	var pips:=Pips.new();pips.ratio=clampf(have/wanted,0.0,1.0);pips.fill=T.RED if short else T.GREEN;chip.add_child(pips)
	chip.add_child(_label("%s/%s" % [_n(have),_n(wanted)],12,T.RED_TEXT if short else T.INK,short))
	return chip


class Segments extends Control:
	var items:Array=[]
	func _draw()->void:
		var total:=0.0
		for item:Dictionary in items:total+=maxf(0.0,float(item.get("share",0.0)))
		draw_rect(Rect2(Vector2.ZERO,size),T.TRACK)
		if total>0.0:
			var x:=0.0
			for item:Dictionary in items:
				var w:=size.x*maxf(0.0,float(item.get("share",0.0)))/maxf(1.0,total)
				if w<=0.0:continue
				draw_rect(Rect2(x,0,w,size.y),item.get("color",T.GREEN))
				x+=w
				if x<size.x-1.0:draw_line(Vector2(x,0),Vector2(x,size.y),T.PAPER,1.0)
		draw_rect(Rect2(Vector2.ZERO,size),T.RULE_STRONG,false,1.0)


class Pips extends Control:
	var ratio:=0.0
	var fill:=Color.WHITE
	const COUNT:=5
	func _init()->void:
		custom_minimum_size=Vector2(COUNT*8+2,10);mouse_filter=MOUSE_FILTER_IGNORE;size_flags_vertical=SIZE_SHRINK_CENTER
	func _draw()->void:
		var lit:=roundi(ratio*COUNT)
		if ratio>0.0 and lit==0:lit=1
		if ratio<1.0 and lit==COUNT:lit=COUNT-1
		for i in COUNT:
			var box:=Rect2(1+i*8,1,6,8)
			draw_rect(box,fill if i<lit else Color(T.TRACK,0.8))
			draw_rect(box,Color(T.RULE_STRONG,0.8),false,1.0)
