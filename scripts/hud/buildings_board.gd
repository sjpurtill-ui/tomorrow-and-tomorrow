extends "res://scripts/hud/town_works_board.gd"
## Buildings: one selected work with its actual costs, effects and controls.
## Section filters and bounded search keep every work available in a compact index.
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

## Widths are the UI's own units (the game draws at a UI scale, so 1600 px
## wide gives this page about 665 units and 2000 px about 850).
const Selection=preload("res://scripts/hud/production_selection.gd")
const Dense:=preload("res://scripts/hud/dense_blocks.gd")
const COLUMN_MIN:=360.0
const BAR_WIDTH:=80.0

var view_state:Dictionary={}
var browser:Control
var category:HFlowContainer
var _specs:Array=[]
var _columns:=0
## Supporting sections use shorter bars when arranged side by side.
var _compact:=false


func setup(block:Dictionary)->void:
	data=block;view_state=block.get("view_state",{});name="BuildingsBoard"
	theme=_theme()
	add_theme_constant_override("separation",10)
	var by_section:Dictionary={}
	for card:Dictionary in block.get("cards",[]):
		var id:=String(card.get("section","main"))
		if not by_section.has(id):by_section[id]=[]
		(by_section[id] as Array).append(card)
	for section:Dictionary in block.get("sections",[]):
		var cards:Array=by_section.get(String(section.get("id","")),[])
		if cards.is_empty() and String(section.get("note",""))=="" and (section.get("actions",[]) as Array).is_empty():continue
		_specs.append({"section":section,"cards":cards})
	resized.connect(_fit)
	_layout(1)
	_fit.call_deferred()


func _fit()->void:pass

## Sections are filters on one reading, not a wall of independent cards.
func _layout(_count:int)->void:
	for child in get_children():remove_child(child);child.queue_free()
	if _specs.is_empty():add_child(_label("No building work is recorded here yet.",16,T.INK_MUTED));return
	if not (data.get("readings",[]) as Array).is_empty():add_child(_context_readings(data.readings))
	var selected:=String(view_state.get("section",String(_specs[0].section.id)))
	if not _specs.any(func(spec:Dictionary)->bool:return String(spec.section.id)==selected):selected=String(_specs[0].section.id)
	view_state.section=selected
	category=HFlowContainer.new();category.name="SectionChoices";category.add_theme_constant_override("h_separation",6);category.add_theme_constant_override("v_separation",6);category.visible=_specs.size()>1;add_child(category)
	for spec:Dictionary in _specs:
		var key:=String(spec.section.id)
		var button:=_button({"label":String(spec.section.heading) if spec.section.get("presentation","")=="effects" else "%s · %d" % [String(spec.section.heading),spec.cards.size()],"primary":key==selected,"on_press":func():view_state.section=key;_layout(1)})
		button.name="Section_"+key;button.toggle_mode=true;button.set_pressed_no_signal(key==selected);category.add_child(button)
	for spec:Dictionary in _specs:
		if String(spec.section.id)==selected:add_child(_section(spec.section,spec.cards));break


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
	if section.get("presentation","")=="effects":
		var effects:=preload("res://scripts/hud/building_effects_view.gd").new();effects.setup(section.metrics);browser=null;return effects
	var box:=VBoxContainer.new();box.name="Section_"+String(section.get("id",""));box.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation",10)
	if _specs.size()==1:
		var title:=T.make_label(String(section.get("heading","")),26,T.INK)
		title.add_theme_font_override("font",T.font("ui_strong"));title.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;box.add_child(title)
	if String(section.get("note",""))!="":
		var note:=_label(String(section.note),14,T.TEXT_SOFT);note.name="Note";note.tooltip_text=String(section.get("note_tip",""));note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		note.mouse_filter=Control.MOUSE_FILTER_STOP if note.tooltip_text!="" else Control.MOUSE_FILTER_IGNORE;box.add_child(note)
	if not (section.get("actions",[]) as Array).is_empty():
		var actions:=HFlowContainer.new();actions.add_theme_constant_override("h_separation",8);actions.add_theme_constant_override("v_separation",8);box.add_child(actions)
		for item:Dictionary in section.actions:actions.add_child(_button(item))
	var id:=String(section.get("id",""))
	if not view_state.has(id):view_state[id]={}
	browser=Selection.new();browser.tiles=id=="works";box.add_child(browser);browser.setup(view_state[id],6)
	for i in cards.size():
		var card:Dictionary=cards[i]
		var content:=VBoxContainer.new();content.add_theme_constant_override("separation",10)
		var key:=str(card.get("key",i))
		var status:=String(card.get("sub",""))
		if status.is_empty():status=String(card.get("tag",{}).get("text",card.get("value","")))
		if id=="works":
			var benefits:PackedStringArray=[]
			for effect:Dictionary in (card.get("effects",[]) as Array).slice(0,2):benefits.append(String(effect.get("label",""))+" "+String(effect.get("value","")))
			for gain:Dictionary in (card.get("gains",[]) as Array).slice(0,1):benefits.append(String(gain.get("label",""))+" "+str(gain.get("before",""))+" → "+str(gain.get("after","")))
			if not benefits.is_empty():status=" · ".join(benefits)+"\n"+status
		browser.add_record(key,String(card.get("name","Work")),status,content)
		browser.records.back()["icon"]=Icons.town_texture(String(card.get("icon","hall")),T.INK,28)
		content.add_child(_row(card))
		var detail:=String(card.get("reading",card.get("detail",""))).replace("\r","").replace("\n\n","\n")
		if not detail.is_empty():
			var words:=_label(detail,16,T.INK);words.name="WhatItDoes";words.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;content.add_child(words)
		var further:=String(card.get("further",""))
		if not further.is_empty():
			var disclosure:=_button({"label":String(card.get("further_label","How it works"))});disclosure.disabled=false;disclosure.toggle_mode=true;content.add_child(disclosure)
			var explanation:=_label(further.replace("\r","").replace("\n\n","\n"),15,T.TEXT_SOFT);explanation.name="FullExplanation";explanation.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;explanation.visible=false;content.add_child(explanation)
			disclosure.toggled.connect(func(open:bool):explanation.visible=open)
	browser.refresh()
	return box


# --- A row -----------------------------------------------------------------------

func _row(card:Dictionary)->Control:
	var panel:=PanelContainer.new();panel.name="Card_"+String(card.get("key",card.get("name","row"))).replace(" ","_")
	var actionable:=not (card.get("actions",[]) as Array).is_empty() or card.get("choice") is Dictionary
	var style:=T.flat(T.PAPER_RAISED if actionable else Color.TRANSPARENT,T.RULE,0,4)
	style.content_margin_top=12;style.content_margin_bottom=12;style.content_margin_left=12 if actionable else 0;style.content_margin_right=12 if actionable else 0
	if not actionable:style.border_width_bottom=1;style.border_color=T.RULE
	if bool(card.get("highlight",false)):style.border_width_left=3;style.border_color=T.GOLD
	panel.add_theme_stylebox_override("panel",style);panel.tooltip_text=String(card.get("detail",""));panel.mouse_filter=Control.MOUSE_FILTER_STOP
	var lines:=VBoxContainer.new();lines.add_theme_constant_override("separation",8);lines.mouse_filter=Control.MOUSE_FILTER_PASS;panel.add_child(lines)
	var line:=HBoxContainer.new();line.name="Line";line.add_theme_constant_override("separation",10);line.mouse_filter=Control.MOUSE_FILTER_PASS;lines.add_child(line)
	line.add_child(_icon(card))
	var words:=VBoxContainer.new();words.size_flags_horizontal=Control.SIZE_EXPAND_FILL;words.add_theme_constant_override("separation",3);line.add_child(words)
	var name_label:=_label(String(card.get("name","")),18,T.INK,true);name_label.name="Name";name_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;words.add_child(name_label)
	if String(card.get("sub",""))!="":
		var sub:=_label(String(card.sub),14,T.TEXT_SOFT);sub.name="Sub";sub.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;words.add_child(sub)
	var figures:=VBoxContainer.new();figures.add_theme_constant_override("separation",5);figures.size_flags_vertical=Control.SIZE_SHRINK_CENTER;line.add_child(figures)
	if String(card.get("value",""))!="":
		var value:=_label(String(card.value),20,T.legible(card.get("value_color",T.INK),T.PAPER),true);value.name="Value";value.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
		figures.add_child(value)
	if String(card.get("value_note",""))!="":
		var meaning:=_label(String(card.value_note),14,T.TEXT_SOFT);meaning.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT;figures.add_child(meaning)
	var bar:Variant=card.get("bar",card.get("progress",card.get("meter")))
	if not (card.get("segments",[]) as Array).is_empty():figures.add_child(_segments(card.segments))
	elif bar is Dictionary and not (bar as Dictionary).is_empty():figures.add_child(_inline_bar(bar))
	if card.get("stamp") is Dictionary:
		var stamp:=Stamp.new();stamp.name="Stamp";stamp.text=String(card.stamp.get("text","Built"));stamp.tooltip_text=String(card.stamp.get("tip",""));stamp.custom_minimum_size=Vector2(66,26);figures.add_child(stamp)
	if card.get("tag") is Dictionary and not (card.tag as Dictionary).is_empty():figures.add_child(_tag(card.tag))
	if actionable:
		var actions:=HFlowContainer.new();actions.name="Actions";actions.add_theme_constant_override("h_separation",8);actions.add_theme_constant_override("v_separation",8);lines.add_child(actions)
		for item:Dictionary in card.get("actions",[]):actions.add_child(_button(item))
		if card.get("choice") is Dictionary:
			var choices:=_small_choice(card.choice)
			for button in choices.get_children():choices.remove_child(button);actions.add_child(button)
			choices.free()
	if _has_second_line(card):
		var second:=HFlowContainer.new();second.name="Second";second.add_theme_constant_override("h_separation",16);second.add_theme_constant_override("v_separation",8);second.mouse_filter=Control.MOUSE_FILTER_PASS
		for gain:Dictionary in card.get("gains",[]):second.add_child(_gain_chip(gain))
		for effect:Dictionary in card.get("effects",[]):second.add_child(_effect_chip(effect))
		if not (card.get("needs",[]) as Array).is_empty():
			var needs:=VBoxContainer.new();needs.size_flags_horizontal=Control.SIZE_EXPAND_FILL;needs.add_theme_constant_override("separation",5)
			needs.add_child(_label(String(card.get("needs_label","In store / build cost")),14,T.TEXT_SOFT))
			var bill:=HFlowContainer.new();bill.add_theme_constant_override("h_separation",16);needs.add_child(bill)
			for need:Dictionary in card.needs:bill.add_child(_pips(need))
			second.add_child(needs)
		for blocker:Dictionary in card.get("blockers",[]):second.add_child(_chip(blocker,String(blocker.get("tone","bad"))))
		for note:Dictionary in card.get("notes",[]):second.add_child(_chip(note,"note"))
		for item:Dictionary in card.get("actions2",[]):second.add_child(_button(item))
		if second.get_child_count()>0:lines.add_child(second)
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
	mark.custom_minimum_size=Vector2(28,28);mark.size_flags_vertical=Control.SIZE_SHRINK_CENTER;mark.mouse_filter=Control.MOUSE_FILTER_IGNORE
	if card.has("icon_color"):mark.modulate=card.icon_color
	return mark


func _inline_bar(spec:Dictionary)->Control:
	var box:=HBoxContainer.new();box.name="Bar";box.add_theme_constant_override("separation",6);box.mouse_filter=Control.MOUSE_FILTER_PASS
	box.tooltip_text=String(spec.get("tip",""))
	var bar:=Meter.new();bar.ratio=clampf(float(spec.get("ratio",0.0)),0.0,1.0);bar.tick=float(spec.get("tick",-1.0))
	bar.fill=spec.get("color",T.GREEN);bar.custom_minimum_size=Vector2((44.0 if _columns>=3 else minf(56.0,float(spec.get("width",BAR_WIDTH)))) if _compact else float(spec.get("width",BAR_WIDTH)),5);bar.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	box.add_child(bar)
	if String(spec.get("text",""))!="" and bool(spec.get("show_text",false)):box.add_child(_label(String(spec.text),14,T.TEXT_SOFT))
	return box


## One bar split by share: the builders by job, the homes by kind.
func _segments(items:Array)->Control:
	var bar:=Segments.new();bar.name="Segments";bar.items=items;bar.custom_minimum_size=Vector2((56.0 if _columns>=3 else 80.0) if _compact else BAR_WIDTH+40.0,10)
	bar.size_flags_vertical=Control.SIZE_SHRINK_CENTER;bar.mouse_filter=Control.MOUSE_FILTER_STOP
	var tips:PackedStringArray=[]
	for item:Dictionary in items:tips.append("%s %s" % [String(item.get("label","")),String(item.get("value",""))])
	bar.tooltip_text=" · ".join(tips)
	return bar


## State tags and verbs are the shared strategy-screen pieces (dense_blocks.gd).
func _tag(tag:Dictionary)->Control:
	var tone:=String(tag.get("tone",""))
	var pill:=Dense.tag(String(tag.get("text","")),tone if tone in ["good","warn","bad"] else "")
	pill.tooltip_text=String(tag.get("tip",""))
	if pill.tooltip_text!="":pill.mouse_filter=Control.MOUSE_FILTER_STOP
	return pill


func _button(item:Dictionary)->Button:
	var label:=String(item.get("label",""))
	var action:Variant=item.get("on_press")
	var valid:=action is Callable and (action as Callable).is_valid()
	var go:=Dense.verb(label,action if valid else null,String(item.get("tip","")),not valid)
	go.name="Act_"+label.replace(" ","_")
	T.apply_button_style(go,bool(item.get("primary",false)))
	if bool(item.get("pressed",false)):
		go.add_theme_stylebox_override("normal",go.get_theme_stylebox("pressed"))
	return go


## Who decides, as small toggles on the row's second line; the chosen one is held down.
func _small_choice(choice:Dictionary)->Control:
	return _choice(choice)


func _gain_chip(gain:Dictionary)->Control:
	var tile:=preload("res://scripts/hud/comparison_tile.gd").new();tile.name="Gain"
	tile.fill(String(gain.get("label","")),"NOW",gain.get("before",""),"AFTER",gain.get("after",""),String(gain.get("unit","")),"",String(gain.get("tip","")))
	return tile


func _effect_chip(effect:Dictionary)->Control:
	var chip:=HBoxContainer.new();chip.name="Effect";chip.add_theme_constant_override("separation",4);chip.tooltip_text=String(effect.get("tip",""));chip.mouse_filter=Control.MOUSE_FILTER_STOP
	chip.add_child(_label(String(effect.get("label","")),14,T.TEXT_SOFT))
	chip.add_child(_label(String(effect.get("value","")),14,tone_ink(String(effect.get("tone","plain"))),true))
	return chip


## Have against need: a good's icon, have / need in green or red and five
## pips (dense_blocks.gd cost_chip); hands (makers, carriers) by name.
func _pips(need:Dictionary)->Control:
	var tile:=preload("res://scripts/hud/comparison_tile.gd").new();tile.name="Need"
	var resource:=String(need.get("resource",""))
	tile.fill(String(need.get("label",resource)),"HAVE",float(need.get("have",0)),"NEED",float(need.get("need",0)),"",resource,String(need.get("tip","")))
	return tile


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

func _context_readings(readings:Array)->Control:
	var flow:=HFlowContainer.new();flow.name="ContextReadings";flow.add_theme_constant_override("h_separation",18);flow.add_theme_constant_override("v_separation",8)
	for reading:Dictionary in readings:
		if String(reading.get("label","")) in data.get("hide_readings",[]):continue
		var cell:=HBoxContainer.new();cell.add_theme_constant_override("separation",6);cell.tooltip_text=String(reading.get("delta",""))+"\n"+String(reading.get("tip",""));flow.add_child(cell)
		cell.add_child(_label(String(reading.get("label","")).capitalize(),14,T.INK_MUTED))
		cell.add_child(_label(String(reading.get("value","")),16,T.INK,true))
		var press:Variant=reading.get("on_press")
		if press is Callable and (press as Callable).is_valid():
			cell.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND;cell.gui_input.connect(func(event:InputEvent)->void:
				if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:(press as Callable).call())
	return flow
