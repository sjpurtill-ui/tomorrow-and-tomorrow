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

## Widths are the UI's own units (the game draws at a UI scale, so 1600 px
## wide gives this page about 665 units and 2000 px about 850).
const Dense:=preload("res://scripts/hud/dense_blocks.gd")
const COLUMN_MIN:=262.0
const BAR_WIDTH:=80.0

var _specs:Array=[]
var _columns:=0
## Rows in side-by-side columns: shorter bars, the tag on the second line.
var _compact:=false


func setup(block:Dictionary)->void:
	data=block;name="BuildingsBoard"
	theme=_theme()
	add_theme_constant_override("separation",14)
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


func _fit()->void:
	if size.x<=0.0:return
	var count:=clampi(floori((size.x+28.0)/(COLUMN_MIN+28.0)),1,3)
	if count!=_columns:_layout(count)


## Lay the sections out in `count` columns: a span section takes the whole
## width; consecutive narrow ones share a band, each dealt to the shortest
## column. Rows are drawn afresh for the width they get.
func _layout(count:int)->void:
	_columns=count
	_compact=count>1
	for child in get_children():
		remove_child(child);child.free()
	var bands:Array=[]
	var band:Array=[]
	for spec:Dictionary in _specs:
		if bool((spec.section as Dictionary).get("span",false)):
			if not band.is_empty():bands.append(band);band=[]
			bands.append([spec])
		else:band.append(spec)
	if not band.is_empty():bands.append(band)
	for each:Array in bands:
		var row:=HBoxContainer.new();row.name="Band";row.add_theme_constant_override("separation",28);add_child(row)
		var spanned:=each.size()==1 and bool((each[0].section as Dictionary).get("span",false))
		var n:=1 if spanned else mini(count,each.size())
		var was:=_compact
		if spanned:_compact=false
		var columns:Array=[];var heights:Array=[]
		for i in n:
			var column:=VBoxContainer.new();column.name="Column%d" % i;column.size_flags_horizontal=Control.SIZE_EXPAND_FILL
			column.add_theme_constant_override("separation",14);row.add_child(column);columns.append(column);heights.append(0.0)
		if n==1:_compact=false
		for spec:Dictionary in each:
			var best:=0
			for i in n:if float(heights[i])<float(heights[best]):best=i
			(columns[best] as VBoxContainer).add_child(_section(spec.section,spec.cards))
			heights[best]=float(heights[best])+_weight(spec.cards)
		_compact=was


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
	# A tiles section lays its items side by side, one per column of the
	# page when three fit (2000 px), each item a small stacked card; narrower
	# pages keep the one-line rows.
	if bool(section.get("tiles",false)) and _columns>=3:
		var grid:=GridContainer.new();grid.name="Tiles";grid.columns=_columns
		grid.add_theme_constant_override("h_separation",20);grid.add_theme_constant_override("v_separation",10)
		for card:Dictionary in cards:grid.add_child(_tile(card))
		box.add_child(grid)
		return box
	for i in cards.size():
		box.add_child(_row(cards[i]))
		if i<cards.size()-1:
			var hair:=ColorRect.new();hair.color=Color(T.RULE,0.55);hair.custom_minimum_size=Vector2(0,1);hair.mouse_filter=Control.MOUSE_FILTER_IGNORE;box.add_child(hair)
	return box


# --- A tile ----------------------------------------------------------------------

## One item as a small stacked card: its mark and full name, its few words,
## its bar, figure and state, then what it does, its bill and its verbs.
func _tile(card:Dictionary)->Control:
	var panel:=PanelContainer.new();panel.name="Card_"+String(card.get("key",card.get("name","tile"))).replace(" ","_")
	panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	var style:=T.flat(Color(0,0,0,0),Color(T.RULE,0.7),0,0);style.border_width_bottom=1;style.content_margin_top=6;style.content_margin_bottom=8
	if bool(card.get("highlight",false)):style.bg_color=T.GOLD_WASH
	panel.add_theme_stylebox_override("panel",style)
	panel.tooltip_text=String(card.get("detail",""));panel.mouse_filter=Control.MOUSE_FILTER_STOP
	var lines:=VBoxContainer.new();lines.add_theme_constant_override("separation",4);lines.mouse_filter=Control.MOUSE_FILTER_PASS;panel.add_child(lines)
	var head:=HBoxContainer.new();head.add_theme_constant_override("separation",8);head.mouse_filter=Control.MOUSE_FILTER_PASS;lines.add_child(head)
	head.add_child(_icon(card))
	var name_label:=_label(String(card.get("name","")),14,T.INK,true);name_label.name="Name";head.add_child(name_label)
	if String(card.get("sub",""))!="":
		var sub:=_label(String(card.sub),12,T.TEXT_SOFT);sub.name="Sub";sub.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;sub.custom_minimum_size.x=120;lines.add_child(sub)
	var figures:=HBoxContainer.new();figures.add_theme_constant_override("separation",8);figures.mouse_filter=Control.MOUSE_FILTER_PASS;lines.add_child(figures)
	var bar:Variant=card.get("bar",card.get("progress",card.get("meter")))
	if bar is Dictionary and not (bar as Dictionary).is_empty():
		var spec:=(bar as Dictionary).duplicate();spec.width=60.0
		var meter:=_inline_bar(spec);meter.size_flags_horizontal=Control.SIZE_EXPAND_FILL;figures.add_child(meter)
		(meter.get_child(0) as Control).size_flags_horizontal=Control.SIZE_EXPAND_FILL
	if String(card.get("value",""))!="":figures.add_child(_label(String(card.value),15,T.legible(card.get("value_color",T.INK),T.PAPER),true))
	if card.get("tag") is Dictionary and not (card.tag as Dictionary).is_empty():figures.add_child(_tag(card.tag))
	var flow:=HFlowContainer.new();flow.add_theme_constant_override("h_separation",12);flow.add_theme_constant_override("v_separation",4);flow.mouse_filter=Control.MOUSE_FILTER_PASS
	for effect:Dictionary in card.get("effects",[]):flow.add_child(_effect_chip(effect))
	for need:Dictionary in card.get("needs",[]):flow.add_child(_pips(need))
	if flow.get_child_count()>0:lines.add_child(flow)
	var verbs:=HFlowContainer.new();verbs.add_theme_constant_override("h_separation",6);verbs.mouse_filter=Control.MOUSE_FILTER_PASS
	for item:Dictionary in card.get("actions",[]):verbs.add_child(_button(item))
	if card.get("choice") is Dictionary:verbs.add_child(_small_choice(card.choice))
	if verbs.get_child_count()>0:lines.add_child(verbs)
	return panel


# --- A row -----------------------------------------------------------------------

func _row(card:Dictionary)->Control:
	# Side by side, a row keeps to one line: what it does waits in its tooltip.
	if _compact and not (card.get("effects",[]) as Array).is_empty():
		card=card.duplicate()
		var said:PackedStringArray=[]
		for effect:Dictionary in card.effects:said.append("%s %s" % [String(effect.get("label","")),String(effect.get("value",""))])
		card.detail=("%s
%s" % [String(card.get("detail","")),", ".join(said)]).strip_edges()
		card.erase("effects")
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
	# A name is never cut: providers keep names short enough for a column.
	line.add_child(name_label)
	var sub:=_label(String(card.get("sub","")),12,T.TEXT_SOFT);sub.name="Sub"
	sub.size_flags_horizontal=Control.SIZE_EXPAND_FILL;sub.clip_text=true;sub.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	sub.custom_minimum_size.x=0
	line.add_child(sub)
	if card.get("stamp") is Dictionary:
		var stamp:=Stamp.new();stamp.name="Stamp";stamp.text=String(card.stamp.get("text","Built"));stamp.tooltip_text=String(card.stamp.get("tip",""));stamp.custom_minimum_size=Vector2(66,24);line.add_child(stamp)
	var bar:Variant=card.get("bar",card.get("progress",card.get("meter")))
	if not (card.get("segments",[]) as Array).is_empty():line.add_child(_segments(card.segments))
	elif bar is Dictionary and not (bar as Dictionary).is_empty():line.add_child(_inline_bar(bar))
	if String(card.get("value",""))!="":
		var value:=_label(String(card.value),15,T.legible(card.get("value_color",T.INK),T.PAPER),true);value.name="Value"
		value.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT;value.custom_minimum_size.x=float(card.get("value_width",44))
		line.add_child(value)
	# Side by side, the state word takes the place of the row's few words.
	if card.get("tag") is Dictionary and not (card.tag as Dictionary).is_empty():
		if _compact:
			sub.text=String(card.tag.get("text",""));sub.tooltip_text=String(card.tag.get("tip",""))
			var tone:=String(card.tag.get("tone","note"))
			sub.add_theme_color_override("font_color",tone_ink(tone) if tone in ["good","bad","warn"] else (T.TEAL_TEXT if tone=="info" else T.TEXT_SOFT))
		else:line.add_child(_tag(card.tag))
	# Words that do not fit the room the row leaves them wait in the
	# tooltip, never cut: checked once the row has its width.
	sub.text_overrun_behavior=TextServer.OVERRUN_NO_TRIMMING
	var words:=sub.text
	if words!="":
		panel.tooltip_text=("%s\n%s" % [words,panel.tooltip_text]).strip_edges()
		var width:=T.font("ui").get_string_size(words,HORIZONTAL_ALIGNMENT_LEFT,-1,12).x
		sub.resized.connect(func()->void:
			if sub.size.x<=0.0:return
			var fits:=width<=sub.size.x+1.0
			if fits!=(sub.text!=""):sub.text=words if fits else "")
	for item:Dictionary in card.get("actions",[]):line.add_child(_button(item))
	# Full width, who decides sits beside the verb; side by side, below it.
	var chose_here:=card.get("choice") is Dictionary and not _compact
	if chose_here:line.add_child(_small_choice(card.choice))
	var rest:=card.duplicate();if chose_here:rest.erase("choice")
	if _has_second_line(rest):
		var second:=HFlowContainer.new();second.name="Second";second.add_theme_constant_override("h_separation",16);second.add_theme_constant_override("v_separation",3)
		second.mouse_filter=Control.MOUSE_FILTER_PASS
		var indent:=Control.new();indent.custom_minimum_size=Vector2(22,0);indent.mouse_filter=Control.MOUSE_FILTER_IGNORE;second.add_child(indent)
		for gain:Dictionary in card.get("gains",[]):second.add_child(_gain_chip(gain))
		for effect:Dictionary in card.get("effects",[]):second.add_child(_effect_chip(effect))
		for need:Dictionary in card.get("needs",[]):second.add_child(_pips(need))
		for blocker:Dictionary in card.get("blockers",[]):second.add_child(_chip(blocker,String(blocker.get("tone","bad"))))
		for note:Dictionary in card.get("notes",[]):second.add_child(_chip(note,"note"))
		for item:Dictionary in card.get("actions2",[]):second.add_child(_button(item))
		if card.get("choice") is Dictionary and not chose_here:second.add_child(_small_choice(card.choice))
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
	bar.fill=spec.get("color",T.GREEN);bar.custom_minimum_size=Vector2((44.0 if _columns>=3 else minf(56.0,float(spec.get("width",BAR_WIDTH)))) if _compact else float(spec.get("width",BAR_WIDTH)),8);bar.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	box.add_child(bar)
	if String(spec.get("text",""))!="" and bool(spec.get("show_text",false)):box.add_child(_label(String(spec.text),12,T.TEXT_SOFT))
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
	if bool(item.get("primary",false)):
		var skin:=(go.get_theme_stylebox("normal") as StyleBoxFlat).duplicate() as StyleBoxFlat
		skin.bg_color=Color(T.GOLD,0.22);go.add_theme_stylebox_override("normal",skin)
	if bool(item.get("pressed",false)):
		go.add_theme_stylebox_override("normal",go.get_theme_stylebox("pressed"))
	return go


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


## Have against need: a good's icon, have / need in green or red and five
## pips (dense_blocks.gd cost_chip); hands (makers, carriers) by name.
func _pips(need:Dictionary)->Control:
	var have:=float(need.get("have",0.0));var wanted:=maxf(0.0001,float(need.get("need",0.0)))
	var resource:=String(need.get("resource",""))
	var chip:HBoxContainer
	if resource!="":
		chip=Dense.cost_chip(resource,have,wanted)
	else:
		var short:=have+0.0001<wanted
		chip=HBoxContainer.new();chip.add_theme_constant_override("separation",4)
		chip.add_child(_label(String(need.get("label","")),12,T.TEXT_SOFT))
		chip.add_child(_label("%s / %s" % [_n(have),_n(wanted)],12,T.RED_TEXT if short else T.GREEN_TEXT,true))
		var pips:=Dense.Pips.new();pips.share=clampf(have/wanted,0.0,1.0);pips.ink=T.RED_TEXT if short else T.GREEN_TEXT
		pips.custom_minimum_size=Vector2(35,8);pips.size_flags_vertical=Control.SIZE_SHRINK_CENTER;chip.add_child(pips)
	chip.name="Need";chip.mouse_filter=Control.MOUSE_FILTER_STOP
	if String(need.get("tip",""))!="":chip.tooltip_text=String(need.tip)
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
