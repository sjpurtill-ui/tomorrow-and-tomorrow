extends VBoxContainer
## THE TOWN'S WORKS AT A GLANCE: one inked card per work, homes or defence,
## HOI4-like: a mark, a figure, bars and before -> after numbers; sentences
## live in the tooltips. The cards come from the Buildings page
## (hud/content/dock_content_construction.gd), every number from the engine's
## own functions; this board only lays them out.
##
## Block: {"type":"town_works", "cards":[card]}. A card:
##   key, name, value, value_color, sub, detail (the card's tooltip), icon
##   (a resource_icons town_texture kind), accent, state ("building",
##   "waiting", "done", "plain")
##   progress {ratio, text, color}     a bar with its words beside it
##   meter {ratio, text, color, tick}  a level against its scale (tick: a need)
##   gains [{label, before, after, tone, tip}]   before -> after
##   effects [{label, value, tone, tip}]         a change in a word or two
##   needs [{resource | label, have, need, tip}] have / need bars
##   blockers [{text, tone ("bad" | "warn"), tip}]  short chips
##   notes [{text, tip}]                          neutral chips
##   choice {selected, options [{id, label, tip, on_press}]}
##   actions [{label, tip, on_press, primary}]
##   stamp {text, tip}                            the inked "Built" stamp

const T:=preload("res://scripts/hud/hud_tokens.gd")
const Icons:=preload("res://scripts/resource_icons.gd")

var data:Dictionary={}


func setup(block:Dictionary)->void:
	data=block;name="TownWorksBoard"
	add_theme_constant_override("separation",6)
	theme=_theme()
	for card:Dictionary in block.get("cards",[]):add_child(_card(card))


func _theme()->Theme:
	var skin:=Theme.new()
	skin.default_font=T.FONT_UI;skin.default_font_size=13
	skin.set_stylebox("normal","Button",T.action_button_style(false));skin.set_stylebox("hover","Button",T.action_button_style(false,true))
	skin.set_stylebox("pressed","Button",T.button_pressed_style());skin.set_stylebox("hover_pressed","Button",T.button_pressed_style())
	skin.set_stylebox("disabled","Button",T.button_disabled_style());skin.set_stylebox("focus","Button",StyleBoxEmpty.new())
	for state in ["font_color","font_hover_color","font_pressed_color","font_hover_pressed_color","font_focus_color"]:skin.set_color(state,"Button",T.INK)
	skin.set_color("font_disabled_color","Button",T.DISABLED);skin.set_font_size("font_size","Button",13)
	skin.set_color("font_color","Label",T.INK)
	T.add_tooltip_style(skin)
	return skin


static func tone_ink(tone:String)->Color:
	match tone:
		"good":return T.GREEN_TEXT
		"bad":return T.RED_TEXT
		"warn":return T.AMBER_TEXT
	return T.GOLD_TEXT


# --- One card ------------------------------------------------------------------------

func _card(card:Dictionary)->Control:
	var panel:=PanelContainer.new();panel.name="Card_"+String(card.get("key",card.get("name","work"))).replace(" ","_")
	var style:=T.flat(T.PAPER_RAISED,T.RULE,1,T.RADIUS_CARD,0)
	style.content_margin_left=0;style.content_margin_right=10;style.content_margin_top=8;style.content_margin_bottom=8
	if card.has("stamp"):style.border_color=T.GREEN
	panel.add_theme_stylebox_override("panel",style)
	panel.tooltip_text=String(card.get("detail",""))
	panel.mouse_filter=Control.MOUSE_FILTER_STOP
	var outer:=HBoxContainer.new();outer.add_theme_constant_override("separation",10);outer.mouse_filter=Control.MOUSE_FILTER_PASS;panel.add_child(outer)
	# The accent rule down the card's left edge: green while it rises, amber
	# while it waits, red when stopped, the town's gold otherwise.
	var accent:=ColorRect.new();accent.color=card.get("accent",T.RULE_STRONG);accent.custom_minimum_size=Vector2(4,0);accent.mouse_filter=Control.MOUSE_FILTER_IGNORE;outer.add_child(accent)
	var column:=VBoxContainer.new();column.size_flags_horizontal=Control.SIZE_EXPAND_FILL;column.add_theme_constant_override("separation",6);column.mouse_filter=Control.MOUSE_FILTER_PASS;outer.add_child(column)
	column.add_child(_head(card))
	if card.get("progress") is Dictionary:column.add_child(_bar_line(card.progress,"Progress"))
	if card.get("meter") is Dictionary:column.add_child(_bar_line(card.meter,"Meter"))
	if not (card.get("gains",[]) as Array).is_empty():column.add_child(_gains(card.gains))
	if not (card.get("effects",[]) as Array).is_empty():column.add_child(_effects(card.effects))
	if not (card.get("needs",[]) as Array).is_empty():column.add_child(_needs(card.needs))
	if not (card.get("blockers",[]) as Array).is_empty() or not (card.get("notes",[]) as Array).is_empty():column.add_child(_chips(card.get("blockers",[]),card.get("notes",[])))
	if card.get("choice") is Dictionary:column.add_child(_choice(card.choice))
	if not (card.get("actions",[]) as Array).is_empty():column.add_child(_actions(card.actions))
	return panel


func _head(card:Dictionary)->Control:
	var head:=HBoxContainer.new();head.name="Head";head.add_theme_constant_override("separation",10);head.mouse_filter=Control.MOUSE_FILTER_PASS
	var ink:Color=card.get("value_color",T.INK)
	var mark:=TextureRect.new();mark.name="Mark";mark.texture=Icons.town_texture(String(card.get("icon","hall")),T.INK,64)
	mark.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;mark.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mark.custom_minimum_size=Vector2(30,30);mark.size_flags_vertical=Control.SIZE_SHRINK_CENTER;mark.mouse_filter=Control.MOUSE_FILTER_IGNORE
	head.add_child(mark)
	var words:=VBoxContainer.new();words.size_flags_horizontal=Control.SIZE_EXPAND_FILL;words.add_theme_constant_override("separation",0);words.mouse_filter=Control.MOUSE_FILTER_IGNORE;head.add_child(words)
	var title:=_label(String(card.get("name","")),15,T.INK,true);title.name="Name";words.add_child(title)
	if String(card.get("sub",""))!="":
		var sub:=_label(String(card.sub),12,T.TEXT_SOFT);sub.name="Sub";sub.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;words.add_child(sub)
	if card.get("stamp") is Dictionary:
		var stamp:=Stamp.new();stamp.name="Stamp";stamp.text=String(card.stamp.get("text","Built"));stamp.tooltip_text=String(card.stamp.get("tip",""));head.add_child(stamp)
	if String(card.get("value",""))!="":
		var value:=_label(String(card.value),16,T.legible(ink,T.PAPER_RAISED),true);value.name="Value";value.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
		value.size_flags_vertical=Control.SIZE_SHRINK_CENTER;head.add_child(value)
	return head


## A bar across the card with its words at the right: progress, or a level
## against its scale with a tick at what is needed.
func _bar_line(spec:Dictionary,label_name:String)->Control:
	var line:=HBoxContainer.new();line.name=label_name;line.add_theme_constant_override("separation",10);line.mouse_filter=Control.MOUSE_FILTER_PASS
	line.tooltip_text=String(spec.get("tip",""))
	var bar:=Meter.new();bar.name="Bar";bar.ratio=clampf(float(spec.get("ratio",0.0)),0.0,1.0);bar.tick=float(spec.get("tick",-1.0))
	bar.fill=spec.get("color",T.GREEN);bar.size_flags_horizontal=Control.SIZE_EXPAND_FILL;bar.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	line.add_child(bar)
	if String(spec.get("text",""))!="":
		var words:=_label(String(spec.text),12,T.INK);words.name="Words";line.add_child(words)
	return line


## "Defenders +0% -> +4%": what the town has now, and what it will have.
func _gains(gains:Array)->Control:
	var flow:=HFlowContainer.new();flow.name="Gains";flow.add_theme_constant_override("h_separation",18);flow.add_theme_constant_override("v_separation",4);flow.mouse_filter=Control.MOUSE_FILTER_PASS
	for gain:Dictionary in gains:
		var chip:=HBoxContainer.new();chip.name="Gain";chip.add_theme_constant_override("separation",5);chip.tooltip_text=String(gain.get("tip",""));chip.mouse_filter=Control.MOUSE_FILTER_STOP
		if String(gain.get("icon",""))!="":chip.add_child(_mark(String(gain.icon),16))
		chip.add_child(_label(String(gain.get("label","")),12,T.TEXT_SOFT))
		chip.add_child(_label(String(gain.get("before","")),13,T.TEXT_SOFT))
		chip.add_child(_label("→",13,T.TEXT_SOFT))
		chip.add_child(_label(String(gain.get("after","")),14,tone_ink(String(gain.get("tone","good"))),true))
		flow.add_child(chip)
	return flow


func _effects(effects:Array)->Control:
	var flow:=HFlowContainer.new();flow.name="Effects";flow.add_theme_constant_override("h_separation",16);flow.add_theme_constant_override("v_separation",4);flow.mouse_filter=Control.MOUSE_FILTER_PASS
	for effect:Dictionary in effects:
		var chip:=HBoxContainer.new();chip.name="Effect";chip.add_theme_constant_override("separation",5);chip.tooltip_text=String(effect.get("tip",""));chip.mouse_filter=Control.MOUSE_FILTER_STOP
		chip.add_child(_label(String(effect.get("label","")),12,T.TEXT_SOFT))
		chip.add_child(_label(String(effect.get("value","")),13,tone_ink(String(effect.get("tone","plain"))),true))
		flow.add_child(chip)
	return flow


## Have against need, one small bar each: materials by their mark, hands by
## their name.
func _needs(needs:Array)->Control:
	var flow:=HFlowContainer.new();flow.name="Needs";flow.add_theme_constant_override("h_separation",16);flow.add_theme_constant_override("v_separation",4);flow.mouse_filter=Control.MOUSE_FILTER_PASS
	for need:Dictionary in needs:
		var have:=float(need.get("have",0.0));var wanted:=maxf(0.0001,float(need.get("need",0.0)))
		var short:=have+0.0001<wanted
		var chip:=HBoxContainer.new();chip.name="Need";chip.add_theme_constant_override("separation",5);chip.mouse_filter=Control.MOUSE_FILTER_STOP
		var resource:=String(need.get("resource",""))
		chip.tooltip_text=String(need.get("tip","")) if String(need.get("tip",""))!="" else "%s: %s in store, %s needed" % [preload("res://scripts/resource_names.gd").label(resource) if resource!="" else String(need.get("label","")),_n(have),_n(wanted)]
		if resource!="":
			var mark:=TextureRect.new();mark.texture=Icons.material_texture(resource,40);mark.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;mark.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			mark.custom_minimum_size=Vector2(20,20);mark.size_flags_vertical=Control.SIZE_SHRINK_CENTER;mark.mouse_filter=Control.MOUSE_FILTER_IGNORE;chip.add_child(mark)
		else:chip.add_child(_label(String(need.get("label","")),12,T.TEXT_SOFT))
		var bar:=Meter.new();bar.ratio=clampf(have/wanted,0.0,1.0);bar.fill=T.RED if short else T.GREEN;bar.custom_minimum_size=Vector2(46,7);bar.size_flags_vertical=Control.SIZE_SHRINK_CENTER;chip.add_child(bar)
		chip.add_child(_label("%s/%s" % [_n(have),_n(wanted)],12,T.RED_TEXT if short else T.INK,short))
		flow.add_child(chip)
	return flow


## What stops the work, each in a few words: red for what is missing, amber
## for a reason (the danger is low, the god said hold off); neutral notes.
func _chips(blockers:Array,notes:Array)->Control:
	var flow:=HFlowContainer.new();flow.name="Chips";flow.add_theme_constant_override("h_separation",6);flow.add_theme_constant_override("v_separation",4);flow.mouse_filter=Control.MOUSE_FILTER_PASS
	for blocker:Dictionary in blockers:flow.add_child(_chip(blocker,String(blocker.get("tone","bad"))))
	for note:Dictionary in notes:flow.add_child(_chip(note,"note"))
	return flow


func _chip(item:Dictionary,tone:String)->Control:
	var chip:=PanelContainer.new();chip.name="Blocker" if tone!="note" else "Note";chip.tooltip_text=String(item.get("tip",""));chip.mouse_filter=Control.MOUSE_FILTER_STOP
	var ground:Color=T.DANGER_BG if tone=="bad" else (T.WARN_BG if tone=="warn" else Color(0,0,0,0))
	var rule:Color=T.DANGER_BORDER if tone=="bad" else (T.WARN_BORDER if tone=="warn" else T.RULE)
	var style:=T.flat(ground,rule,1,10);style.content_margin_left=8;style.content_margin_right=8;style.content_margin_top=1;style.content_margin_bottom=2
	chip.add_theme_stylebox_override("panel",style)
	var ink:=T.RED_TEXT if tone=="bad" else (T.AMBER_TEXT if tone=="warn" else T.TEXT_SOFT)
	chip.add_child(_label(String(item.get("text","")),12,ink))
	return chip


## Who decides, as three plain choices; the chosen one is held down.
func _choice(choice:Dictionary)->Control:
	var row:=HBoxContainer.new();row.name="Choice";row.add_theme_constant_override("separation",6);row.mouse_filter=Control.MOUSE_FILTER_PASS
	for option:Dictionary in choice.get("options",[]):
		var button:=Button.new();button.name="Choose_"+String(option.get("id",""));button.text=String(option.get("label",""))
		button.toggle_mode=true;button.button_pressed=String(option.get("id",""))==String(choice.get("selected",""));button.focus_mode=Control.FOCUS_NONE
		button.tooltip_text=String(option.get("tip",""));button.custom_minimum_size=Vector2(0,28)
		var action:Variant=option.get("on_press")
		button.pressed.connect(func()->void:
			button.button_pressed=true
			if action is Callable:(action as Callable).call())
		row.add_child(button)
	return row


func _actions(actions:Array)->Control:
	var row:=HFlowContainer.new();row.name="Actions";row.add_theme_constant_override("h_separation",6);row.add_theme_constant_override("v_separation",4);row.mouse_filter=Control.MOUSE_FILTER_PASS
	for item:Dictionary in actions:
		var button:=Button.new();button.name="Act";button.text=String(item.get("label",""));button.tooltip_text=String(item.get("tip",""));button.focus_mode=Control.FOCUS_NONE
		button.custom_minimum_size=Vector2(0,28)
		if bool(item.get("primary",false)):
			button.add_theme_stylebox_override("normal",T.action_button_style(true));button.add_theme_color_override("font_color",T.GOLD_TEXT)
		var action:Variant=item.get("on_press")
		if action is Callable:button.pressed.connect(func()->void:(action as Callable).call())
		else:button.disabled=true
		row.add_child(button)
	return row


# --- Small builders ------------------------------------------------------------------

func _label(text:String,size:int,color:Color,strong:bool=false)->Label:
	var label:=T.make_label(text,size,color)
	if strong:label.add_theme_font_override("font",T.font("ui_strong"))
	label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	label.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	return label


func _mark(kind:String,side:float)->TextureRect:
	var mark:=TextureRect.new();mark.texture=Icons.town_texture(kind,T.TEXT_SOFT,40)
	mark.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;mark.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mark.custom_minimum_size=Vector2(side,side);mark.size_flags_vertical=Control.SIZE_SHRINK_CENTER;mark.mouse_filter=Control.MOUSE_FILTER_IGNORE
	return mark


## A count as the stores read it: whole units, a part never rounded up to
## make a need look met (2.6 timber is "2").
static func _n(value:float)->String:
	if value>=10.0:return preload("res://scripts/hud/era_words.gd").grouped(floori(value+0.0001))
	return str(floori(maxf(0.0,value)+0.0001))


# --- Drawing ------------------------------------------------------------------------

class Meter extends Control:
	## An inked bar: the track, its fill, and a tick where a need stands.
	var ratio:=0.0
	var fill:=Color.WHITE
	var tick:=-1.0
	func _init()->void:
		custom_minimum_size=Vector2(60,9);mouse_filter=MOUSE_FILTER_IGNORE
	func _draw()->void:
		var h:=size.y
		draw_rect(Rect2(Vector2.ZERO,size),T.TRACK)
		if ratio>0.0:draw_rect(Rect2(0,0,size.x*ratio,h),fill)
		draw_rect(Rect2(Vector2.ZERO,size),T.RULE_STRONG,false,1.0)
		if tick>=0.0:
			var x:=size.x*clampf(tick,0.0,1.0)
			draw_line(Vector2(x,-3),Vector2(x,h+3),T.INK,2.0)


class Stamp extends Control:
	## The builders' mark on a finished work: an inked, slightly turned
	## frame around one word, as a clerk stamps a finished tally.
	var text:="Built"
	func _init()->void:
		custom_minimum_size=Vector2(70,30);mouse_filter=MOUSE_FILTER_STOP;size_flags_vertical=Control.SIZE_SHRINK_CENTER
	func _draw()->void:
		var ink:=T.legible(T.GREEN_TEXT,T.PAPER_RAISED)
		var font:=T.font("ui_strong")
		var centre:=size*0.5
		draw_set_transform(centre,deg_to_rad(-8.0),Vector2.ONE)
		var box:=Rect2(Vector2(-31,-11),Vector2(62,22))
		draw_rect(box,Color(ink,0.10))
		draw_rect(box,ink,false,2.0)
		draw_rect(box.grow(-3.0),Color(ink,0.55),false,1.0)
		var words:=text.to_upper()
		var width:=font.get_string_size(words,HORIZONTAL_ALIGNMENT_LEFT,-1,13).x
		draw_string(font,Vector2(-width*0.5,5),words,HORIZONTAL_ALIGNMENT_LEFT,-1,13,ink)
		draw_set_transform(Vector2.ZERO,0.0,Vector2.ONE)
