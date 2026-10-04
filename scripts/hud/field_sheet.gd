extends "res://scripts/hud/home_ledger.gd"
## A FIELD OF INQUIRY, drawn instead of told (Research › a field). Four pieces:
## - the field's painting as a banner, its glyph, name and what it is for;
## - its attention as a dial (its share of the learners' hours) beside a dot
##   for every learner, the ones on this field in its colour, with Less/More;
## - what its knowledge does now as a bar chart, one bar per effect, the
##   longest the largest, coloured by whether it helps or costs;
## - its questions under way as cards: the painting in its progress arc, the
##   team and its clock, and what answering it would bring as small chips.
## Every number comes from the page (dock_content_inquiry.gd _domain_report)
## and the engine readings behind it; the long accounts live in the tooltips
## and in a bar's opened detail.
##
## Block: {"type":"field_sheet","id","name","goal","share","weight","learners",
##   "on_field","caveat","rows":[ledger row + "value"],"questions":[{"record",
##   "rows"}],"state":Dictionary,"on_more","on_less","on_investigations","on_work"}.
const Visuals:=preload("res://scripts/hud/research_visuals.gd")
const Icons:=preload("res://scripts/resource_icons.gd")
const Arc:=preload("res://scripts/hud/learning_arc.gd")
const Painting:=preload("res://scripts/hud/subject_painting.gd")
const Board:=preload("res://scripts/hud/inquiry_board.gd")
## Bars shown before "Show all".
const FIRST_BARS:=6
const HERO_HEIGHT:=150.0
var state:Dictionary={}
var _effects_box:VBoxContainer
var _questions_box:VBoxContainer
var _accent:=T.GOLD

func setup(block:Dictionary)->void:
	data=block;name="FieldSheet";state=block.get("state",{})
	add_theme_constant_override("separation",14);size_flags_horizontal=Control.SIZE_EXPAND_FILL
	var id:=String(block.get("id",""))
	_accent=Visuals.color(id)
	_hero(self,block)
	_attention(self,block)
	_effects_box=VBoxContainer.new();_effects_box.name="Effects";_effects_box.add_theme_constant_override("separation",6);add_child(_effects_box)
	_effects(_effects_box)
	_questions_box=VBoxContainer.new();_questions_box.name="UnderWay";_questions_box.add_theme_constant_override("separation",8);add_child(_questions_box)
	_questions(_questions_box)

# --------------------------------------------------------------------------
# The banner
# --------------------------------------------------------------------------

func _hero(parent:Node,block:Dictionary)->void:
	var id:=String(block.get("id",""))
	var frame:=Control.new();frame.name="Hero";frame.custom_minimum_size.y=HERO_HEIGHT;frame.clip_contents=true;parent.add_child(frame)
	var painting:=Painting.new();painting.backdrop=_accent.darkened(0.55);painting.texture=Visuals.art(id)
	painting.mouse_filter=Control.MOUSE_FILTER_IGNORE;painting.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);frame.add_child(painting)
	var shade:=Shade.new();shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);frame.add_child(shade)
	var rule:=ColorRect.new();rule.color=_accent;rule.mouse_filter=Control.MOUSE_FILTER_IGNORE
	rule.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE);rule.offset_top=-3;frame.add_child(rule)
	var margin:=MarginContainer.new();margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);margin.mouse_filter=Control.MOUSE_FILTER_IGNORE
	for side in ["left","right","top","bottom"]:margin.add_theme_constant_override("margin_"+side,14)
	frame.add_child(margin)
	var column:=VBoxContainer.new();column.mouse_filter=Control.MOUSE_FILTER_IGNORE;margin.add_child(column)
	var top:=HBoxContainer.new();top.add_theme_constant_override("separation",6);column.add_child(top)
	var spacer:=Control.new();spacer.size_flags_horizontal=Control.SIZE_EXPAND_FILL;spacer.mouse_filter=Control.MOUSE_FILTER_IGNORE;top.add_child(spacer)
	_glass_button(top,"Who does the work",block.get("on_work"),"How many people the local leaders set to learning, and asking for more")
	var fill:=Control.new();fill.size_flags_vertical=Control.SIZE_EXPAND_FILL;fill.mouse_filter=Control.MOUSE_FILTER_IGNORE;column.add_child(fill)
	var title_row:=HBoxContainer.new();title_row.add_theme_constant_override("separation",10);title_row.mouse_filter=Control.MOUSE_FILTER_IGNORE;column.add_child(title_row)
	var glyph:=TextureRect.new();glyph.texture=Icons.domain_texture(id,_accent.lightened(0.35));glyph.custom_minimum_size=Vector2(40,40)
	glyph.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;glyph.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;glyph.size_flags_vertical=Control.SIZE_SHRINK_CENTER;title_row.add_child(glyph)
	var words:=VBoxContainer.new();words.add_theme_constant_override("separation",0);words.size_flags_horizontal=Control.SIZE_EXPAND_FILL;title_row.add_child(words)
	# The page's own title names the field; the banner says what it is for.
	var goal:=T.make_label(String(block.get("goal","")),24,Color("f6efe2"));goal.add_theme_font_override("font",T.voice_font());goal.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	goal.add_theme_constant_override("outline_size",4);goal.add_theme_color_override("font_outline_color",Color(0,0,0,0.35));words.add_child(goal)

## Dark ink rising from the banner's foot, so its words read on any painting.
class Shade extends Control:
	func _init()->void:mouse_filter=Control.MOUSE_FILTER_IGNORE
	func _draw()->void:
		var bands:=24
		for i in bands:
			var t:=float(i)/float(bands)
			var y0:=size.y*(0.25+0.75*t);var y1:=size.y*(0.25+0.75*float(i+1)/float(bands))
			draw_rect(Rect2(0,y0,size.x,y1-y0+1),Color(0.07,0.06,0.04,0.72*t*t))
		draw_rect(Rect2(0,0,size.x,size.y*0.3),Color(0.07,0.06,0.04,0.18))
	func _notification(what:int)->void:
		if what==NOTIFICATION_RESIZED:queue_redraw()

func _glass_button(parent:Node,label:String,callback:Variant,tip:String)->Button:
	var b:=Button.new();b.text=label;b.tooltip_text=tip;b.custom_minimum_size.y=28;b.focus_mode=Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size",13);b.add_theme_color_override("font_color",Color("f6efe2"));b.add_theme_color_override("font_hover_color",Color.WHITE)
	b.add_theme_stylebox_override("normal",T.flat(Color(0.08,0.07,0.05,0.55),Color(1,1,1,0.35),1,T.RADIUS_CONTROL,8))
	b.add_theme_stylebox_override("hover",T.flat(Color(0.08,0.07,0.05,0.8),Color(1,1,1,0.7),1,T.RADIUS_CONTROL,8))
	b.add_theme_stylebox_override("pressed",T.flat(Color(0.08,0.07,0.05,0.9),Color(1,1,1,0.7),1,T.RADIUS_CONTROL,8))
	parent.add_child(b)
	if callback is Callable and (callback as Callable).is_valid():b.pressed.connect(callback)
	else:b.disabled=true
	return b

# --------------------------------------------------------------------------
# Attention
# --------------------------------------------------------------------------

func _attention(parent:Node,block:Dictionary)->void:
	var panel:=PanelContainer.new();panel.name="Attention";parent.add_child(panel)
	panel.add_theme_stylebox_override("panel",T.flat(T.ROW_BG,T.BORDER_SOFT,1,T.RADIUS_CARD,12))
	panel.tooltip_text=String(block.get("caveat",""))
	var row:=HBoxContainer.new();row.add_theme_constant_override("separation",16);panel.add_child(row)
	var share:=float(block.get("share",0.0))
	var dial:=Dial.new();dial.name="Dial";dial.accent=_accent;dial.value=share;dial.custom_minimum_size=Vector2(92,92);dial.size_flags_vertical=Control.SIZE_SHRINK_CENTER;row.add_child(dial)
	var column:=VBoxContainer.new();column.size_flags_horizontal=Control.SIZE_EXPAND_FILL;column.add_theme_constant_override("separation",6);column.size_flags_vertical=Control.SIZE_SHRINK_CENTER;row.add_child(column)
	column.add_child(T.make_label("OUR LEARNERS' ATTENTION",12,T.GOLD_TEXT,0.06))
	var learners:=int(block.get("learners",0))
	var here:=float(block.get("on_field",0.0))
	var said:=_voice("No one is set to learning" if learners<=0 else ("No one is looking here" if share<=0.0 else "%s of our %d learners work here" % [Board._count(here),learners]),20)
	said.name="AttentionWords";column.add_child(said)
	var pips:=Pips.new();pips.name="Learners";pips.total=learners;pips.here=here;pips.accent=_accent;pips.size_flags_horizontal=Control.SIZE_EXPAND_FILL;column.add_child(pips)
	pips.tooltip_text="Each dot is one of our people at learning; the coloured ones give their hours to %s." % String(block.get("name","this field")).to_lower()
	var buttons:=HBoxContainer.new();buttons.add_theme_constant_override("separation",8);buttons.size_flags_vertical=Control.SIZE_SHRINK_CENTER;row.add_child(buttons)
	var less:=_step_button(buttons,"−","Less",block.get("on_less") if int(block.get("weight",0))>0 else null,"Give one step of this field's attention back to the others")
	less.name="Less"
	var more:=_step_button(buttons,"+","More",block.get("on_more"),"Move one step of attention to this field. More attention speeds the work here but cannot replace missing clues.")
	more.name="More"

## A round step button with its word beneath: "−" Less, "+" More.
func _step_button(parent:Node,glyph:String,word:String,callback:Variant,tip:String)->Button:
	var box:=VBoxContainer.new();box.add_theme_constant_override("separation",2);parent.add_child(box)
	var b:=Button.new();b.text=glyph;b.tooltip_text=tip;b.custom_minimum_size=Vector2(46,46);b.focus_mode=Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size",24);b.add_theme_color_override("font_color",T.INK);b.add_theme_color_override("font_hover_color",T.INK)
	b.add_theme_stylebox_override("normal",T.flat(T.PANEL_BG_SOLID,_accent.darkened(0.25),2,23))
	b.add_theme_stylebox_override("hover",T.flat(T.HOVER_BG,_accent.darkened(0.45),2,23))
	b.add_theme_stylebox_override("pressed",T.flat(T.ACTIVE_BG,_accent.darkened(0.45),2,23))
	b.add_theme_stylebox_override("disabled",T.flat(T.TILE_BG,T.BORDER_SOFT,1,23))
	b.add_theme_color_override("font_disabled_color",T.DISABLED)
	box.add_child(b)
	var label:=T.make_label(word,12,T.TEXT_SOFT);label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;box.add_child(label)
	if callback is Callable and (callback as Callable).is_valid():b.pressed.connect(callback)
	else:b.disabled=true
	return b

## The field's share of the learners' hours: an inked ring, the share as an
## arc in the field's colour, the number in the middle.
class Dial extends Control:
	const T:=preload("res://scripts/hud/hud_tokens.gd")
	var accent:=Color("8a6118")
	var value:=0.0
	func _draw()->void:
		var side:=minf(size.x,size.y);var center:=size*0.5;var width:=side*0.13;var radius:=side*0.5-width*0.5-1.0
		draw_circle(center,radius+width*0.5,T.PANEL_BG_SOLID)
		draw_arc(center,radius,0,TAU,64,T.TRACK,width,true)
		var share:=clampf(value,0.0,1.0)
		if share>0.0:draw_arc(center,radius,-PI*0.5,-PI*0.5+TAU*maxf(share,0.015),64,accent.darkened(0.2),width,true)
		for i in 20:
			var a:=-PI*0.5+TAU*float(i)/20.0;var inner:=radius-width*0.5-3.0
			draw_line(center+Vector2(cos(a),sin(a))*inner,center+Vector2(cos(a),sin(a))*(inner-(4.0 if i%5==0 else 2.0)),T.BORDER_SOFT,1.0,true)
		var font:Font=T.voice_font();var text:="%d%%" % roundi(share*100.0);var px:=int(side*0.28)
		var w:=font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,px).x
		draw_string(font,center+Vector2(-w*0.5,px*0.32),text,HORIZONTAL_ALIGNMENT_LEFT,-1,px,T.INK)
		var small:=T.font("ui");var caption:="of hours";var cpx:=12
		var cw:=small.get_string_size(caption,HORIZONTAL_ALIGNMENT_LEFT,-1,cpx).x
		draw_string(small,center+Vector2(-cw*0.5,px*0.32+cpx+1),caption,HORIZONTAL_ALIGNMENT_LEFT,-1,cpx,T.TEXT_SOFT)

## A dot for every learner (a dot for several once there are many), the ones
## on this field filled in its colour.
class Pips extends Control:
	const T:=preload("res://scripts/hud/hud_tokens.gd")
	const MAX_DOTS:=120
	var total:=0
	var here:=0.0
	var accent:=Color("8a6118")
	func _init()->void:custom_minimum_size=Vector2(120,14);mouse_filter=Control.MOUSE_FILTER_STOP
	func _notification(what:int)->void:
		if what==NOTIFICATION_RESIZED:
			var h:=_rows()*9.0+2.0
			if not is_equal_approx(custom_minimum_size.y,h):custom_minimum_size.y=h
			queue_redraw()
	func _per()->int:return maxi(1,ceili(float(total)/float(MAX_DOTS)))
	func _rows()->int:
		var dots:=ceili(float(total)/float(_per()))
		var across:=maxi(1,floori((maxf(size.x,120.0)+3.0)/9.0))
		return maxi(1,ceili(float(dots)/float(across)))
	func _draw()->void:
		var per:=_per();var dots:=ceili(float(total)/float(per));var lit:=roundi(here/float(per))
		if here>0.0:lit=maxi(1,lit)
		var across:=maxi(1,floori((size.x+3.0)/9.0))
		for i in dots:
			var at:=Vector2(4.0+float(i%across)*9.0,5.0+float(i/across)*9.0)
			if i<lit:draw_circle(at,3.4,accent.darkened(0.25))
			else:draw_circle(at,3.0,T.TRACK)

# --------------------------------------------------------------------------
# What the field's knowledge does now
# --------------------------------------------------------------------------

func _effects(box:VBoxContainer)->void:
	for child in box.get_children():box.remove_child(child);child.queue_free()
	var rows:Array=data.get("rows",[])
	var name_words:=String(data.get("name","this field")).to_lower()
	_heading(box,"WHAT OUR KNOWLEDGE OF %s DOES NOW" % name_words.to_upper(),"%d effect%s" % [rows.size(),"" if rows.size()==1 else "s"])
	if rows.is_empty():
		_line(box,"Nothing known in this field acts on the world yet.",13,T.TEXT_SOFT);return
	box.add_child(_hint("Each practice counts by how widely it is used, before what this age allows. Click a bar for everywhere it acts."))
	var key:="all:"+String(data.get("id",""))
	var shown:=rows if state.has(key) or rows.size()<=FIRST_BARS+1 else rows.slice(0,FIRST_BARS)
	_chart(box,shown,_largest(rows))
	if rows.size()>FIRST_BARS+1:
		var toggle:=_button(box,"Show fewer" if state.has(key) else "Show all %d effects" % rows.size(),func()->void:
			if state.has(key):state.erase(key)
			else:state[key]=true
			_effects(_effects_box),"")
		toggle.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN

static func _largest(rows:Array)->float:
	var top:=0.0
	for row:Dictionary in rows:top=maxf(top,absf(float(row.get("value",0.0))))
	return top

func _chart(parent:Node,rows:Array,largest:float)->void:
	var column:=VBoxContainer.new();column.name="Bars";column.add_theme_constant_override("separation",2);parent.add_child(column)
	for row:Dictionary in rows:_bar_row(column,row,largest)

## One effect: its icon, its name, a bar as long as its size against the
## largest here, and the amount; a click opens the plain account.
func _bar_row(parent:Node,row:Dictionary,largest:float)->void:
	var id:=String(row.get("id",row.get("key","")))
	var open_key:="r:"+id
	var tone:=String(row.get("tone",""))
	var panel:=PanelContainer.new();panel.name="Effect_"+id.validate_node_name();parent.add_child(panel)
	var rest:=T.flat(Color.TRANSPARENT,Color.TRANSPARENT,0,T.RADIUS_CONTROL,4);var lit:=T.flat(T.HOVER_BG,Color.TRANSPARENT,0,T.RADIUS_CONTROL,4)
	panel.add_theme_stylebox_override("panel",rest)
	var column:=VBoxContainer.new();column.add_theme_constant_override("separation",2);panel.add_child(column)
	var line:=HBoxContainer.new();line.add_theme_constant_override("separation",8);column.add_child(line)
	var icon:=TextureRect.new();icon.texture=effect_icon(String(row.get("key","")),T.GOLD);icon.custom_minimum_size=Vector2(24,24)
	icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;icon.size_flags_vertical=Control.SIZE_SHRINK_CENTER;line.add_child(icon)
	var label:=T.make_label(String(row.get("label","")),13,T.INK);label.custom_minimum_size.x=150;label.clip_text=true
	label.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;label.size_flags_vertical=Control.SIZE_SHRINK_CENTER;line.add_child(label)
	var bar:=EffectBar.new();bar.ratio=absf(float(row.get("value",0.0)))/maxf(largest,0.000001);bar.ink=bar_ink(tone)
	bar.size_flags_horizontal=Control.SIZE_EXPAND_FILL;bar.size_flags_vertical=Control.SIZE_SHRINK_CENTER;line.add_child(bar)
	var amount:=T.make_label(String(row.get("amount","")),14,ImpactInk.ink(tone));amount.name="Amount";amount.custom_minimum_size.x=64
	amount.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT;amount.size_flags_vertical=Control.SIZE_SHRINK_CENTER;line.add_child(amount)
	var detail:=VBoxContainer.new();detail.name="Detail";detail.add_theme_constant_override("separation",2);detail.visible=state.has(open_key);column.add_child(detail)
	if detail.visible:_detail(detail,row)
	panel.tooltip_text=String(row.get("headline",""))+"\n"+String(row.get("sentence",""))+"\n\nClick to see everywhere it acts."
	for child:Node in panel.find_children("*","Control",true,false):(child as Control).mouse_filter=Control.MOUSE_FILTER_IGNORE
	panel.mouse_filter=Control.MOUSE_FILTER_STOP;panel.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
	panel.mouse_entered.connect(func()->void:panel.add_theme_stylebox_override("panel",lit))
	panel.mouse_exited.connect(func()->void:panel.add_theme_stylebox_override("panel",rest))
	panel.gui_input.connect(func(event:InputEvent)->void:
		var mouse:=event as InputEventMouseButton
		if mouse and mouse.pressed and mouse.button_index==MOUSE_BUTTON_LEFT:
			panel.accept_event()
			if state.has(open_key):state.erase(open_key)
			else:state[open_key]=true
			detail.visible=state.has(open_key)
			if detail.visible and detail.get_child_count()==0:
				_detail(detail,row)
				for child:Node in detail.find_children("*","Control",true,false):(child as Control).mouse_filter=Control.MOUSE_FILTER_IGNORE)

## An opened bar: what it means in the game, which way is better, where the
## engine reads it and why it may be held back.
func _detail(box:VBoxContainer,row:Dictionary)->void:
	var inset:=MarginContainer.new();inset.add_theme_constant_override("margin_left",32);inset.add_theme_constant_override("margin_bottom",6);box.add_child(inset)
	var column:=VBoxContainer.new();column.add_theme_constant_override("separation",2);inset.add_child(column)
	if String(row.get("headline",""))!="":_line(column,String(row.headline),13,T.BODY)
	if String(row.get("sentence",""))!="":_line(column,String(row.sentence),12,T.TEXT_SOFT)
	if String(row.get("direction",""))!="":_line(column,String(row.direction),12,T.MUTED)
	var feeds:Array=row.get("feeds",[])
	if bool(row.get("inert",false)):_line(column,"Nothing in the simulation reads this yet, so it changes nothing.",12,T.AMBER_TEXT)
	elif not feeds.is_empty():_line(column,"Acts on: "+", ".join(PackedStringArray(feeds.map(func(f:Variant)->String:return String(f)))),12,T.TEXT_SOFT)
	for note:Variant in row.get("notes",[]):_line(column,String(note),12,T.AMBER_TEXT if String(note).begins_with("Held back") else T.MUTED)

## Whether an effect helps (green), costs (amber), only steers (blue) or is
## read by nothing (grey), as the impact ledger inks them.
class ImpactInk:
	const T:=preload("res://scripts/hud/hud_tokens.gd")
	static func ink(tone:String)->Color:
		match tone:
			"good":return T.GREEN_TEXT
			"cost":return T.AMBER_TEXT
			"steer":return T.BLUE_TEXT
		return T.MUTED

static func bar_ink(tone:String)->Color:
	match tone:
		"good":return T.GREEN
		"cost":return T.AMBER
		"steer":return T.BLUE
	return T.BORDER_SOFT

## A bar on its track: rounded, filled to its share of the largest effect.
class EffectBar extends Control:
	const T:=preload("res://scripts/hud/hud_tokens.gd")
	var ratio:=0.0
	var ink:=Color("536d32")
	func _init()->void:custom_minimum_size=Vector2(60,12);mouse_filter=Control.MOUSE_FILTER_IGNORE
	func _notification(what:int)->void:
		if what==NOTIFICATION_RESIZED:queue_redraw()
	func _draw()->void:
		var h:=size.y;var r:=h*0.5
		draw_style_box(T.flat(T.TRACK,Color.TRANSPARENT,0,int(r)),Rect2(Vector2.ZERO,size))
		var w:=clampf(ratio,0.0,1.0)*size.x
		if w>0.5:draw_style_box(T.flat(ink,Color.TRANSPARENT,0,int(r)),Rect2(0,0,maxf(w,h),h))

## A glyph for an effect, read from its key: the harvest a sprout, wild food a
## gatherer, spoilage the stores, sickness its omen; else the field's glyph.
static func effect_icon(key:String,ink:Color)->Texture2D:
	var people:={"hunt":"hunt","fish":"fish","forag":"gather","wild":"gather","gather":"gather","stor":"stores","spoil":"stores","preserv":"stores","diet":"fed","food":"fed","nutrition":"fed",
		"water":"water","construct":"build","build":"build","shelter":"shelter","hous":"shelter","carry":"carry","route":"carry","transport":"carry","logistic":"carry","supply":"carry",
		"learn":"learn","research":"learn","record":"learn","knowledge":"learn","tool":"make","craft":"make","product":"make","labor":"make","task":"make",
		"security":"watch","military":"watch","defen":"watch","readiness":"watch","care":"tend","spirit":"spirit","cohesion":"spirit","state":"steward","legitima":"steward","govern":"steward","coordinat":"steward"}
	var moments:={"harvest":"sprout","soil":"sprout","cultivat":"sprout","crop":"sprout","farm":"sprout","recover":"sprout","ecolog":"sprout","sick":"sickness","disease":"sickness","health":"sickness",
		"conception":"birth","maternal":"birth","neonatal":"birth","birth":"birth","fertility":"birth","surviv":"life","disaster":"flood","flood":"flood","fire":"fire","culture":"ceremony","practice":"ceremony"}
	for part:String in moments:
		if part in key:
			return Icons.people_texture("life",ink) if moments[part]=="life" else Icons.moment_texture(String(moments[part]),ink,56)
	for part:String in people:
		if part in key:return Icons.people_texture(String(people[part]),ink)
	return Icons.moment_texture("discovery",ink,56)

# --------------------------------------------------------------------------
# Questions under way
# --------------------------------------------------------------------------

func _questions(box:VBoxContainer)->void:
	for child in box.get_children():box.remove_child(child);child.queue_free()
	var questions:Array=data.get("questions",[])
	var head:=_heading(box,"BEING LEARNED HERE","%d question%s" % [questions.size(),"" if questions.size()==1 else "s"])
	var link:=_button(head,"Waiting lines",data.get("on_investigations"),"Every question in this field, its progress and what holds back the lines with none")
	link.custom_minimum_size.y=24;link.add_theme_font_size_override("font_size",12)
	if questions.is_empty():
		var empty:=PanelContainer.new();empty.add_theme_stylebox_override("panel",T.flat(T.TILE_BG,T.BORDER_SOFT,1,T.RADIUS_CARD,12));box.add_child(empty)
		var label:=_line(empty,"No question is being worked on here. Attention waits for clues: explore, work and watch the land to find them.",13,T.TEXT_SOFT)
		label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		return
	for question:Dictionary in questions:_question(box,question)

func _question(parent:Node,question:Dictionary)->void:
	var record:Dictionary=question.get("record",{})
	var id:=String(record.get("id",""))
	var open_key:="q:"+id
	var words:=Board._card_words(record)
	var panel:=PanelContainer.new();panel.name="Question_"+id.validate_node_name();parent.add_child(panel)
	var rest:=T.flat(T.ROW_BG,T.BORDER_SOFT,1,T.RADIUS_CARD,10);rest.border_color=_accent.darkened(0.15);rest.border_width_left=4
	var lit:=rest.duplicate() as StyleBoxFlat;lit.bg_color=T.HOVER_BG
	panel.add_theme_stylebox_override("panel",rest)
	var column:=VBoxContainer.new();column.add_theme_constant_override("separation",8);panel.add_child(column)
	var row:=HBoxContainer.new();row.add_theme_constant_override("separation",12);column.add_child(row)
	var arc:=Arc.new();arc.custom_minimum_size=Vector2(64,64);arc.accent=_accent.darkened(0.2);arc.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	var painting:=Visuals.thumbnail_for(record,256) if Board.has_painting(record) else null
	arc.glyph=painting==null;arc.focus=Visuals.focus_for(record)
	arc.texture=painting if painting!=null else Icons.domain_texture(String(data.get("id","knowledge")),arc.accent)
	arc.held=String(words.phase)!="";arc.set_value(float(words.progress),false);row.add_child(arc)
	var text:=VBoxContainer.new();text.size_flags_horizontal=Control.SIZE_EXPAND_FILL;text.add_theme_constant_override("separation",1);row.add_child(text)
	var name_label:=_voice(String(record.get("name","An open question")),18);text.add_child(name_label)
	_line(text,String(words.brief),12,T.BODY)
	_line(text,String(words.status),12,T.AMBER_TEXT if String(words.phase)!="" else T.TEXT_SOFT)
	var pct:=T.make_label("%d%%" % roundi(float(words.progress)*100.0),22,T.GOLD_TEXT)
	pct.add_theme_font_override("font",T.voice_font());pct.size_flags_vertical=Control.SIZE_SHRINK_CENTER;pct.tooltip_text="Evidence gathered towards proof";row.add_child(pct)
	# What answering it would bring: its largest effects as chips.
	var rows:Array=question.get("rows",[])
	if not rows.is_empty():
		var chips:=HFlowContainer.new();chips.add_theme_constant_override("h_separation",6);chips.add_theme_constant_override("v_separation",6);column.add_child(chips)
		var lead:=T.make_label("Would bring",12,T.TEXT_SOFT);lead.size_flags_vertical=Control.SIZE_SHRINK_CENTER;chips.add_child(lead)
		for effect:Dictionary in rows.slice(0,4):_chip(chips,effect)
		if rows.size()>4:
			var more:=T.make_label("+%d more" % (rows.size()-4),12,T.TEXT_SOFT);more.size_flags_vertical=Control.SIZE_SHRINK_CENTER;chips.add_child(more)
	var trying:=roundi(float(record.get("trial_share",0.0))*100.0)
	if trying>0:_line(column,"%d in 100 households already try it, and that share of each effect counts now." % trying,12,T.GREEN_TEXT)
	var detail:=VBoxContainer.new();detail.name="Detail";detail.add_theme_constant_override("separation",4);detail.visible=state.has(open_key);column.add_child(detail)
	var fill_detail:=func()->void:
		detail.add_child(_hint("If it is proven, at full use. It starts in about %d in 100 households and spreads over years." % roundi(preload("res://scripts/research_600_catalog.gd").PROOF_ADOPTION*100.0)))
		_chart(detail,rows,_largest(rows))
		for child:Node in detail.find_children("*","Control",true,false):(child as Control).mouse_filter=Control.MOUSE_FILTER_IGNORE
	if detail.visible and not rows.is_empty():fill_detail.call()
	panel.tooltip_text=String(words.tooltip).replace("Click to review this field, its current investigations and what they would do.","Click to see each effect it would bring.")
	for child:Node in panel.find_children("*","Control",true,false):(child as Control).mouse_filter=Control.MOUSE_FILTER_IGNORE
	if rows.is_empty():return
	panel.mouse_filter=Control.MOUSE_FILTER_STOP;panel.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
	panel.mouse_entered.connect(func()->void:panel.add_theme_stylebox_override("panel",lit))
	panel.mouse_exited.connect(func()->void:panel.add_theme_stylebox_override("panel",rest))
	panel.gui_input.connect(func(event:InputEvent)->void:
		var mouse:=event as InputEventMouseButton
		if mouse and mouse.pressed and mouse.button_index==MOUSE_BUTTON_LEFT:
			panel.accept_event()
			if state.has(open_key):state.erase(open_key)
			else:state[open_key]=true
			detail.visible=state.has(open_key)
			if detail.visible and detail.get_child_count()==0:fill_detail.call())

## A small token for one effect: its glyph and amount, the name on hover.
func _chip(parent:Node,row:Dictionary)->void:
	var tone:=String(row.get("tone",""))
	var panel:=PanelContainer.new();parent.add_child(panel)
	panel.add_theme_stylebox_override("panel",T.flat(T.PANEL_BG_SOLID,bar_ink(tone),1,10,4))
	panel.tooltip_text=String(row.get("label",""))+" "+String(row.get("amount",""))+"\n"+String(row.get("headline",""))
	var line:=HBoxContainer.new();line.add_theme_constant_override("separation",4);panel.add_child(line)
	var icon:=TextureRect.new();icon.texture=effect_icon(String(row.get("key","")),T.GOLD);icon.custom_minimum_size=Vector2(18,18)
	icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;line.add_child(icon)
	line.add_child(T.make_label(String(row.get("label","")),12,T.BODY))
	line.add_child(T.make_label(String(row.get("amount","")),12,ImpactInk.ink(tone)))

# --------------------------------------------------------------------------
# Small pieces
# --------------------------------------------------------------------------

func _heading(parent:Node,title:String,note:String)->HBoxContainer:
	var row:=HBoxContainer.new();row.add_theme_constant_override("separation",8);parent.add_child(row)
	var rule:=ColorRect.new();rule.color=_accent;rule.custom_minimum_size=Vector2(3,18);rule.size_flags_vertical=Control.SIZE_SHRINK_CENTER;row.add_child(rule)
	var label:=T.make_label(title,12,T.GOLD_TEXT,0.06);label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;label.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;row.add_child(label)
	if note!="":
		var aside:=T.make_label(note,12,T.MUTED);aside.size_flags_vertical=Control.SIZE_SHRINK_CENTER;row.add_child(aside)
	return row

func _hint(text:String)->Label:
	var label:=T.make_label(text,12,T.TEXT_SOFT);label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;return label
