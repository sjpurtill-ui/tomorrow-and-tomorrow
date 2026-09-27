extends Control
## Send envoys: one paper sheet over the map (docs/ART_DIRECTION.md), in the
## order a ruler thinks: to whom, what the message is, what (if anything)
## goes with it, what it takes and how it may be received, then send.
##
## Gifts appear only where a gift makes sense (envoy_messages.gd PURPOSES);
## a message of menace may carry a token instead, or nothing. Offline, the
## envoy's words are chosen from preset phrasings; with a live model the god
## may also say it in their own words. State changes only through
## CivilizationSystem.dispatch_diplomat, EnvoyMessages.send and the existing
## ForeignDiplomacy / ForeignDialogue calls.

const Tokens:=preload("res://scripts/hud/hud_tokens.gd")
const Icons:=preload("res://scripts/resource_icons.gd")
const Identity:=preload("res://scripts/city_map_identity.gd")
const Portrait:=preload("res://scripts/hud/person_portrait.gd")
const EarlyArt:=preload("res://scripts/hud/early_civ_art.gd")
const Rivals:=preload("res://scripts/rival_rulers.gd")
const Divine:=preload("res://scripts/divine_regard.gd")
const Chronicle:=preload("res://scripts/chronicle.gd")
const Motion:=preload("res://scripts/hud/motion.gd")
const Messages:=preload("res://scripts/envoy_messages.gd")

const DESIGN_SIZE:=Vector2(1180,820)
const RECENT_DAYS:=365

signal sent(message:String)
signal show_on_map(civ_id:String)

## Set by the opener before add_child ("" purpose: the ruler chooses).
var civ_id:=""
var purpose:=""

var sel:={"gift":"","token":"none","by":"wrath","demand":"tribute","deadline":182,"consequence":"war","phrase":0,"talk":""}
var card:PanelContainer
var body:MarginContainer
var people_box:VBoxContainer
var purpose_box:VBoxContainer
var extras_box:VBoxContainer
var last_box:VBoxContainer
var cost_row:HFlowContainer
var reception:Label
var blocker_label:Label
var send_button:Button
var outcome:Label
var words_edit:TextEdit
var close_button:Button

func _ready()->void:
	name="EnvoyDispatch"
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	mouse_filter=MOUSE_FILTER_STOP
	theme=Tokens.control_theme()
	var scrim:=ColorRect.new();scrim.name="Scrim";scrim.color=Tokens.SCRIM;scrim.set_anchors_and_offsets_preset(PRESET_FULL_RECT);add_child(scrim)
	scrim.gui_input.connect(func(event:InputEvent)->void:
		if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:close())
	card=PanelContainer.new();card.name="EnvoySheet"
	var sheet:=Tokens.paper_panel_style(false,Tokens.RADIUS_CARD,0)
	sheet.shadow_color=Color(0,0,0,.18 if Tokens.is_light() else .45);sheet.shadow_size=18;sheet.shadow_offset=Vector2(0,6)
	card.add_theme_stylebox_override("panel",sheet);add_child(card)
	var column:=VBoxContainer.new();column.add_theme_constant_override("separation",0);card.add_child(column)
	column.add_child(_build_header())
	body=MarginContainer.new();body.name="Body";body.size_flags_vertical=SIZE_EXPAND_FILL
	for side:String in ["left","right"]:body.add_theme_constant_override("margin_"+side,24)
	body.add_theme_constant_override("margin_top",16);body.add_theme_constant_override("margin_bottom",16)
	column.add_child(body)
	purpose=_normal(purpose)
	_fit()
	rebuild()
	Motion.fade_in(self)

# --- Chrome -------------------------------------------------------------------

func _label(text:String,role:String="body",color:Color=Tokens.BODY,wrap:bool=true)->Label:
	var label:=Label.new();label.text=text
	Tokens.text(label,role,color)
	if wrap:label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	return label

func _voice(text:String,size:int=20,color:Color=Tokens.INK,italic:bool=false)->Label:
	var label:=Label.new();label.text=text;label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_override("font",Tokens.voice_font(italic))
	label.add_theme_font_size_override("font_size",size);label.add_theme_color_override("font_color",color)
	return label

func _kicker(text:String,color:Color=Tokens.INK_MUTED)->Label:
	return Tokens.make_label(text.to_upper(),12,color,.12)

func _box(bg:Color,border:Color,width:int=1,radius:int=Tokens.RADIUS_CONTROL,pad_x:float=12,pad_y:float=8)->StyleBoxFlat:
	var style:=StyleBoxFlat.new();style.bg_color=bg;style.border_color=border;style.set_border_width_all(width);style.set_corner_radius_all(radius)
	style.content_margin_left=pad_x;style.content_margin_right=pad_x;style.content_margin_top=pad_y;style.content_margin_bottom=pad_y
	return style

func _button(text:String,primary:bool=false,selected:bool=false)->Button:
	var button:=Button.new();button.text=text;button.focus_mode=FOCUS_NONE
	Tokens.text(button,"body",Tokens.INK)
	var ink:=Tokens.GOLD if primary or selected else Tokens.RULE_STRONG
	var wash:=Tokens.GOLD_WASH if primary or selected else Tokens.PAPER_RAISED
	var normal:=_box(wash,ink,1,Tokens.RADIUS_CONTROL,14,6)
	if selected:normal.border_width_left=3
	button.add_theme_stylebox_override("normal",normal)
	var hover:=_box(Tokens.PAPER_SUNK,Tokens.GOLD,1,Tokens.RADIUS_CONTROL,14,6)
	if selected:hover.border_width_left=3
	button.add_theme_stylebox_override("hover",hover);button.add_theme_stylebox_override("pressed",hover)
	button.add_theme_stylebox_override("disabled",_box(Tokens.PAPER_SUNK,Tokens.RULE,1,Tokens.RADIUS_CONTROL,14,6))
	button.add_theme_color_override("font_disabled_color",Tokens.INK_MUTED)
	button.add_theme_color_override("font_color",Tokens.GOLD_BRIGHT if primary or selected else Tokens.INK)
	button.add_theme_color_override("font_hover_color",Tokens.INK)
	button.custom_minimum_size.y=34
	return button

func _icon(texture:Texture2D,size:float=22.0)->TextureRect:
	var picture:=TextureRect.new();picture.texture=texture;picture.custom_minimum_size=Vector2(size,size)
	picture.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;picture.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.mouse_filter=MOUSE_FILTER_IGNORE;picture.size_flags_vertical=SIZE_SHRINK_CENTER
	return picture

func _chip(text:String,texture:Texture2D,tone:Color,tip:String="")->PanelContainer:
	var chip:=PanelContainer.new();chip.mouse_filter=MOUSE_FILTER_PASS;chip.tooltip_text=tip
	var style:=_box(Tokens.PAPER_RAISED,tone,1,Tokens.RADIUS_CONTROL,8,3)
	style.border_width_left=3;style.border_width_top=0;style.border_width_right=0;style.border_width_bottom=0
	chip.add_theme_stylebox_override("panel",style)
	var row:=HBoxContainer.new();row.add_theme_constant_override("separation",6);row.mouse_filter=MOUSE_FILTER_IGNORE;chip.add_child(row)
	if texture!=null:row.add_child(_icon(texture,20))
	var words:=_label(text,"small",Tokens.INK,false);words.mouse_filter=MOUSE_FILTER_IGNORE;row.add_child(words)
	return chip

func _section(parent:Control,node_name:String,heading:String)->VBoxContainer:
	var box:=VBoxContainer.new();box.name=node_name;box.add_theme_constant_override("separation",8);parent.add_child(box)
	box.add_child(_kicker(heading,Tokens.GOLD))
	var rule:=ColorRect.new();rule.color=Tokens.RULE;rule.custom_minimum_size=Vector2(0,1);box.add_child(rule)
	return box

func _scroll(node_name:String,ratio:float)->Array:
	var scroll:=ScrollContainer.new();scroll.name=node_name;scroll.size_flags_horizontal=SIZE_EXPAND_FILL;scroll.size_flags_vertical=SIZE_EXPAND_FILL;scroll.size_flags_stretch_ratio=ratio
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	var bar:=scroll.get_v_scroll_bar()
	var track:=StyleBoxFlat.new();track.bg_color=Tokens.PAPER_SUNK;track.set_corner_radius_all(2);track.content_margin_left=3;track.content_margin_right=3
	var grip:=StyleBoxFlat.new();grip.bg_color=Tokens.RULE;grip.set_corner_radius_all(2);grip.content_margin_left=3;grip.content_margin_right=3
	bar.add_theme_stylebox_override("scroll",track);bar.add_theme_stylebox_override("grabber",grip)
	bar.add_theme_stylebox_override("grabber_highlight",grip);bar.add_theme_stylebox_override("grabber_pressed",grip)
	var stack:=VBoxContainer.new();stack.size_flags_horizontal=SIZE_EXPAND_FILL;stack.add_theme_constant_override("separation",24);scroll.add_child(stack)
	return [scroll,stack]

func _clear(node:Node)->void:
	if node==null:return
	for child in node.get_children():node.remove_child(child);child.queue_free()

static func about(value:float)->String:
	## Rounded, readable amounts: 17308.4 -> "17,300".
	var n:=absf(value)
	var rounded:int
	if n<20.0:rounded=roundi(n)
	elif n<100.0:rounded=roundi(n/5.0)*5
	elif n<1000.0:rounded=roundi(n/10.0)*10
	else:rounded=roundi(n/100.0)*100
	var digits:=str(rounded)
	var out:=""
	for i in digits.length():
		if i>0 and (digits.length()-i)%3==0:out+=","
		out+=digits[i]
	return out

func name_of(id:String)->String:
	for value:Dictionary in WorldSimulation.world.civilizations:
		if String(value.get("id",""))==id:return String(value.get("name",id))
	return "another people"

func leader_name(id:String)->String:
	return String(WorldSimulation.diplomacy.leader(id).get("name","their ruler"))

func _ruler_person(id:String)->Dictionary:
	var person:Dictionary=Rivals.portrait_person(id)
	EarlyArt.bind_foreign_identity(person,id,int(GameState.world_seed))
	return person

func _normal(value:String)->String:
	var clean:=value.strip_edges().to_lower().replace(" ","_")
	return clean if clean in Messages.ORDER else ""

# --- Layout ---------------------------------------------------------------------

func _build_header()->Control:
	var band:=PanelContainer.new();band.name="Herald"
	var style:=_box(Tokens.PAPER,Tokens.GOLD,0,0,24,14)
	style.corner_radius_top_left=Tokens.RADIUS_CARD;style.corner_radius_top_right=Tokens.RADIUS_CARD;style.border_width_bottom=3
	band.add_theme_stylebox_override("panel",style)
	var row:=HBoxContainer.new();row.add_theme_constant_override("separation",16);band.add_child(row)
	row.add_child(_icon(Icons.moment_texture("contact",Tokens.GOLD.lightened(.25),112),52))
	var words:=VBoxContainer.new();words.size_flags_horizontal=SIZE_EXPAND_FILL;words.add_theme_constant_override("separation",2);row.add_child(words)
	words.add_child(_kicker("Envoys"))
	var title:=Label.new();title.name="Title";title.text="Send a messenger";Tokens.text(title,"title",Tokens.INK)
	title.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;words.add_child(title)
	words.add_child(_voice("Whom you send to, what they carry, and what it will cost your people.",18,Tokens.BODY,true))
	close_button=_button("Close");close_button.name="Close";close_button.size_flags_vertical=SIZE_SHRINK_CENTER
	close_button.tooltip_text="Close and let the days run again.";close_button.pressed.connect(close);row.add_child(close_button)
	return band

func _fit()->void:
	if not is_instance_valid(card):return
	var view:=get_viewport_rect().size
	# Nothing to choose (envoys away, nobody known): a shorter sheet.
	var tall:=DESIGN_SIZE.y if people_box!=null else 560.0
	var target:=Vector2(minf(DESIGN_SIZE.x,view.x-32),minf(tall,view.y-32))
	if card.size!=target:card.size=target
	var place:=((view-card.size)*.5).round()
	if card.position!=place:card.position=place

func _process(_delta:float)->void:
	_fit()

func contacts()->Array[String]:
	var ids:Array[String]=[]
	for value:Dictionary in WorldSimulation.world.civilizations:
		var id:=String(value.get("id",""))
		if id=="" or not bool(value.get("alive",true)):continue
		if int((value.get("player_relation",{}) as Dictionary).get("contact_level",0))>=2:ids.append(id)
	return ids

func reachable(id:String)->bool:
	for value:Dictionary in WorldSimulation.world.civilizations:
		if String(value.get("id",""))==id:return bool((value.get("player_relation",{}) as Dictionary).get("home_location_known",false))
	return false

func rebuild()->void:
	_clear(body)
	people_box=null;purpose_box=null;extras_box=null;cost_row=null;reception=null;blocker_label=null;send_button=null;words_edit=null;last_box=null
	var status:Dictionary=WorldSimulation.world.diplomatic_mission_status()
	if bool(status.get("active",false)):
		body.add_child(_away(status));return
	var ids:=contacts()
	if ids.is_empty():
		var none:=_voice("You know no people well enough to send envoys to. Scouts must meet them first, and find where they live.",20,Tokens.INK_MUTED,true)
		none.name="NoContacts";body.add_child(none);return
	if civ_id=="" or not civ_id in ids:
		civ_id=""
		for id in ids:
			if reachable(id):civ_id=id;break
		if civ_id=="":civ_id=ids[0]
	var split:=HBoxContainer.new();split.add_theme_constant_override("separation",24);body.add_child(split)
	var left:=_scroll("Whom",0.72);split.add_child(left[0])
	var whom:=_section(left[1],"ToWhom","To whom")
	people_box=VBoxContainer.new();people_box.name="PeopleCards";people_box.add_theme_constant_override("separation",8);whom.add_child(people_box)
	var rule:=ColorRect.new();rule.color=Tokens.RULE;rule.custom_minimum_size=Vector2(1,0);split.add_child(rule)
	var right_column:=VBoxContainer.new();right_column.size_flags_horizontal=SIZE_EXPAND_FILL;right_column.size_flags_stretch_ratio=1.28;right_column.add_theme_constant_override("separation",12);split.add_child(right_column)
	var right:=_scroll("Message",1.0);right_column.add_child(right[0])
	var message:=_section(right[1],"WhatMessage","What the message is")
	purpose_box=VBoxContainer.new();purpose_box.name="Purposes";purpose_box.add_theme_constant_override("separation",10);message.add_child(purpose_box)
	var extras:=_section(right[1],"WithIt","What goes with it")
	extras_box=VBoxContainer.new();extras_box.name="Extras";extras_box.add_theme_constant_override("separation",10);extras.add_child(extras_box)
	last_box=VBoxContainer.new();last_box.name="LastWord";last_box.add_theme_constant_override("separation",6);right[1].add_child(last_box)
	right_column.add_child(_build_footer())
	refresh()

func _build_footer()->Control:
	var panel:=PanelContainer.new();panel.name="Footer"
	panel.add_theme_stylebox_override("panel",_box(Tokens.PAPER_SUNK,Tokens.RULE,1,Tokens.RADIUS_CARD,16,12))
	var stack:=VBoxContainer.new();stack.add_theme_constant_override("separation",8);panel.add_child(stack)
	stack.add_child(_kicker("What it takes"))
	cost_row=HFlowContainer.new();cost_row.name="Cost";cost_row.add_theme_constant_override("h_separation",8);cost_row.add_theme_constant_override("v_separation",6);stack.add_child(cost_row)
	var row:=HBoxContainer.new();row.add_theme_constant_override("separation",16);stack.add_child(row)
	var words:=VBoxContainer.new();words.size_flags_horizontal=SIZE_EXPAND_FILL;words.add_theme_constant_override("separation",4);row.add_child(words)
	reception=_voice("",18,Tokens.INK,true);reception.name="Reception";words.add_child(reception)
	blocker_label=_label("","small",Tokens.RED);blocker_label.name="Blocker";blocker_label.visible=false;words.add_child(blocker_label)
	send_button=_button("Send the envoys",true);send_button.name="Send";send_button.custom_minimum_size=Vector2(200,40);send_button.size_flags_vertical=SIZE_SHRINK_CENTER
	send_button.pressed.connect(send);row.add_child(send_button)
	outcome=_voice("",17,Tokens.INK,true);outcome.name="Outcome";outcome.visible=false;stack.add_child(outcome)
	return panel

func _away(status:Dictionary)->Control:
	var box:=VBoxContainer.new();box.name="Away";box.add_theme_constant_override("separation",14)
	var id:=String(status.get("civ_id",""))
	var head:=HBoxContainer.new();head.add_theme_constant_override("separation",14);box.add_child(head)
	head.add_child(_icon(Identity.foreign(id).texture,48))
	var words:=VBoxContainer.new();words.size_flags_horizontal=SIZE_EXPAND_FILL;head.add_child(words)
	words.add_child(_kicker("Your envoys are on the road",Tokens.GOLD))
	words.add_child(_voice(String(status.get("destination",name_of(id))),24,Tokens.INK))
	var stage:="on the way there" if String(status.get("stage",""))=="outbound" else "on the way home with their answer"
	var line:="%d envoys, %s. They carry %s." % [int(status.get("personnel",0)),stage,_purpose_words(String(status.get("purpose","goodwill")),status)]
	box.add_child(_label(line,"body",Tokens.BODY))
	var track:=ProgressBar.new();track.name="Journey";track.max_value=1.0;track.value=float(status.get("progress",0.0));track.show_percentage=false;track.custom_minimum_size.y=8
	track.add_theme_stylebox_override("background",_box(Tokens.PAPER_SUNK,Tokens.RULE,1,2,0,0));track.add_theme_stylebox_override("fill",_box(Tokens.GOLD,Tokens.GOLD,0,2,0,0))
	box.add_child(track)
	var dates:=HBoxContainer.new();dates.add_theme_constant_override("separation",24);box.add_child(dates)
	for pair:Array in [["Left",int(status.get("depart_day",0))],["Reach them",int(status.get("arrival_day",0))],["Home",int(status.get("return_day",0))]]:
		var cell:=VBoxContainer.new();cell.size_flags_horizontal=SIZE_EXPAND_FILL;dates.add_child(cell)
		cell.add_child(_kicker(String(pair[0])));cell.add_child(_label(Chronicle.date_label(int(pair[1])),"body",Tokens.INK,false))
	box.add_child(_voice("Only one party can be away at a time. The answer is brought to your court when they are home.",17,Tokens.INK_MUTED,true))
	var actions:=HBoxContainer.new();actions.add_theme_constant_override("separation",12);box.add_child(actions)
	var map:=_button("Show them on the map");map.name="ShowOnMap";actions.add_child(map)
	map.pressed.connect(func()->void:show_on_map.emit(id);close())
	var court:=_button("Open their court");court.name="OpenCourt";actions.add_child(court)
	court.pressed.connect(func()->void:close();ForeignDiplomacy.open(id))
	outcome=_voice("",17,Tokens.INK,true);outcome.name="Outcome";outcome.visible=false;box.add_child(outcome)
	return box

func _purpose_words(kind:String,status:Dictionary)->String:
	var gift:=float(status.get("gift_amount",0.0))
	var base:=String({"goodwill":"good words","open_trade":"an offer of trade","non_aggression":"a promise of peace","send_aid":"food for a people in need",
		"seek_peace":"a plea for peace","declare_war":"your declaration of war","leader_parley":"your words to their ruler",
		"warn":"your warning","threaten":"your threat","demand":"your demand","ultimatum":"your ultimatum"}.get(kind,"your message"))
	if gift>0.0:base+=" and about %s %s" % [about(gift),String(status.get("gift_resource",""))]
	return base

# --- Content --------------------------------------------------------------------

func refresh()->void:
	if people_box==null:return
	_fill_people()
	_fill_purposes()
	_fill_extras()
	_fill_last()
	_fill_cost()

func _fill_people()->void:
	_clear(people_box)
	for id in contacts():people_box.add_child(people_card(id))

func people_card(id:String)->Control:
	var chosen:=id==civ_id
	var panel:=PanelContainer.new();panel.name="People_"+id;panel.mouse_filter=MOUSE_FILTER_STOP
	var style:=_box(Tokens.PAPER_RAISED,Tokens.GOLD if chosen else Tokens.RULE,1,Tokens.RADIUS_CARD,12,10)
	if chosen:style.border_width_left=3
	panel.add_theme_stylebox_override("panel",style)
	panel.gui_input.connect(func(event:InputEvent)->void:
		if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:address(id))
	var row:=HBoxContainer.new();row.add_theme_constant_override("separation",12);row.mouse_filter=MOUSE_FILTER_IGNORE;panel.add_child(row)
	var frame:=PanelContainer.new();frame.mouse_filter=MOUSE_FILTER_IGNORE;frame.add_theme_stylebox_override("panel",_box(Tokens.PAPER_SUNK,Tokens.RULE,1,Tokens.RADIUS_CONTROL,1,1));frame.size_flags_vertical=SIZE_SHRINK_BEGIN;row.add_child(frame)
	var holder:=Control.new();holder.custom_minimum_size=Vector2(56,68);holder.clip_contents=true;holder.mouse_filter=MOUSE_FILTER_IGNORE;frame.add_child(holder)
	if not WorldSimulation.diplomacy.leader(id).is_empty():
		var face:=Portrait.picture(_ruler_person(id),56,68);face.mouse_filter=MOUSE_FILTER_IGNORE;face.set_anchors_and_offsets_preset(PRESET_FULL_RECT);holder.add_child(face)
	var crest:=_icon(Identity.foreign(id).texture,22);crest.position=Vector2(34,2);crest.size=Vector2(20,24);holder.add_child(crest)
	var words:=VBoxContainer.new();words.size_flags_horizontal=SIZE_EXPAND_FILL;words.add_theme_constant_override("separation",2);words.mouse_filter=MOUSE_FILTER_IGNORE;row.add_child(words)
	var title:=_voice(name_of(id),20,Tokens.INK);title.mouse_filter=MOUSE_FILTER_IGNORE;words.add_child(title)
	var regard:=Divine.foreign_regard(id)
	var mood:=String(regard.get("id",""))
	var tone:=Tokens.RED if mood in ["war","scorn","fear","wary"] else (Tokens.GREEN if mood in ["honor","awe"] else Tokens.BODY)
	var ruler:=_label("%s · they %s" % [leader_name(id),String(regard.get("read","are undecided about you"))],"small",tone);ruler.mouse_filter=MOUSE_FILTER_IGNORE;words.add_child(ruler)
	var road:=""
	if not reachable(id):road="Their home is not yet found. Scouts must find it first."
	else:
		var quote:Dictionary=WorldSimulation.world.diplomatic_mission_quote(id,"","leader_parley")
		road="About %d days there and back" % int(quote.total_days) if quote.has("total_days") else ""
	if road!="":
		var travel:=_label(road,"small",Tokens.INK_MUTED);travel.mouse_filter=MOUSE_FILTER_IGNORE;words.add_child(travel)
	return panel

func _fill_purposes()->void:
	_clear(purpose_box)
	for group:String in Messages.GROUPS:
		var flow:=HFlowContainer.new();flow.name="Group_"+group;flow.add_theme_constant_override("h_separation",8);flow.add_theme_constant_override("v_separation",8)
		for kind:String in Messages.ORDER:
			var info:Dictionary=Messages.PURPOSES[kind]
			if String(info.group)!=group:continue
			var button:=_button(String(info.label),false,kind==purpose);button.name="Purpose_"+kind
			var problem:=blocker(kind)
			button.tooltip_text=String(info.line)+("\n"+problem if problem!="" else "")
			if problem!="" and kind!=purpose:button.add_theme_color_override("font_color",Tokens.INK_MUTED)
			button.pressed.connect(choose.bind(kind));flow.add_child(button)
		var line:=HBoxContainer.new();line.add_theme_constant_override("separation",12);purpose_box.add_child(line)
		var tag:=_kicker(String(Messages.GROUPS[group]));tag.custom_minimum_size.x=120;tag.size_flags_vertical=SIZE_SHRINK_CENTER;line.add_child(tag)
		flow.size_flags_horizontal=SIZE_EXPAND_FILL;line.add_child(flow)
	if purpose!="":
		var what:=_voice(String(Messages.PURPOSES[purpose].line),18,Tokens.BODY,true);what.name="PurposeLine";purpose_box.add_child(what)

func _choice_row(node_name:String,heading:String,options:Array,current:String,callback:Callable)->Control:
	## options: [[id,label,tip,enabled]]
	var box:=VBoxContainer.new();box.name=node_name;box.add_theme_constant_override("separation",6)
	box.add_child(_kicker(heading))
	var flow:=HFlowContainer.new();flow.add_theme_constant_override("h_separation",8);flow.add_theme_constant_override("v_separation",8);box.add_child(flow)
	for option:Array in options:
		var button:=_button(String(option[1]),false,String(option[0])==current);button.name="Choice_"+String(option[0])
		button.tooltip_text=String(option[2]) if option.size()>2 else ""
		button.disabled=option.size()>3 and not bool(option[3])
		button.pressed.connect(callback.bind(String(option[0])));flow.add_child(button)
	return box

func _fill_extras()->void:
	_clear(extras_box);words_edit=null
	if purpose=="":
		extras_box.add_child(_voice("Choose what your envoys will say first. Gifts go only with messages that call for them.",17,Tokens.INK_MUTED,true));return
	var rule:=Messages.gift_rule(purpose)
	if rule in ["required","optional","food"]:
		var options:Array=[]
		if rule=="optional":options.append(["","No gift","The message alone.",true])
		for gift:Dictionary in WorldSimulation.world.diplomatic_gift_options(civ_id):
			if rule=="food" and String(gift.resource)!="Food":continue
			var words:="About %s %s" % [about(float(gift.amount)),String(gift.resource)]
			var tip:="You hold about %s. They would find it %s." % [about(float(gift.available)),String(gift.reception)]
			if not bool(gift.can_send):tip="You hold only about %s." % about(float(gift.available))
			options.append([String(gift.resource),words,tip,bool(gift.can_send)])
		if rule!="optional" and sel.gift=="":
			for option:Array in options:
				if bool(option[3]):sel.gift=String(option[0]);break
		var allowed:=false
		for option:Array in options:allowed=allowed or String(option[0])==String(sel.gift)
		if not allowed:sel.gift=""
		extras_box.add_child(_choice_row("Gifts","A gift" if rule!="food" else "The food they carry",options,String(sel.gift),pick_gift))
		if options.is_empty():extras_box.add_child(_label("You have nothing to spare for a gift.","small",Tokens.INK_MUTED))
	else:
		sel.gift=""
	if purpose in Messages.HOSTILE:
		_fill_menace()
	elif purpose=="leader_parley":
		_fill_parley()
	elif purpose=="declare_war":
		extras_box.add_child(_voice("War begins the day they hear it. Your generals choose how it is fought.",17,Tokens.BODY,true))
	elif rule=="none":
		extras_box.add_child(_voice("Nothing goes with it.",17,Tokens.INK_MUTED,true))

func _fill_menace()->void:
	if purpose!="warn":
		extras_box.add_child(_choice_row("Backing","What backs it",[["wrath",Messages.BY.wrath.label,Messages.BY.wrath.line],["spears",Messages.BY.spears.label,Messages.BY.spears.line]],String(sel.by),pick_by))
	if purpose in ["demand","ultimatum"]:
		var options:Array=[]
		var allowed:=Messages.demands_for(civ_id)
		if not String(sel.demand) in allowed:sel.demand="tribute"
		for id:String in Messages.DEMANDS:
			var line:=String(Messages.DEMANDS[id].line)
			if id=="tribute":
				var t:=Messages.tribute_terms(civ_id)
				line="About %s %s from their stores, carried home by your envoys." % [about(float(t.amount)),String(t.resource)]
			if id=="apology" and Messages.grievance(civ_id)!="":line="Their ruler owns %s." % Messages.grievance(civ_id)
			options.append([id,String(Messages.DEMANDS[id].label),line,id in allowed])
		extras_box.add_child(_choice_row("Demands","What you demand",options,String(sel.demand),pick_demand))
	if purpose=="ultimatum":
		var arrive:=_arrival_day()
		var deadlines:Array=[]
		for days:int in Messages.DEADLINES:deadlines.append([str(days),_first_up(String(Messages.DEADLINE_WORDS[days])),"About %s, counted from the day they hear it." % Chronicle.date_label(arrive+days)])
		extras_box.add_child(_choice_row("Deadline","How long they have",deadlines,str(int(sel.deadline)),pick_deadline))
		var consequences:Array=[]
		for id:String in Messages.CONSEQUENCES:consequences.append([id,String(Messages.CONSEQUENCES[id].label),String(Messages.CONSEQUENCES[id].line)])
		extras_box.add_child(_choice_row("Consequence","If they refuse",consequences,String(sel.consequence),pick_consequence))
		var hold:=_label(String(Messages.CONSEQUENCES[String(sel.consequence)].line),"small",Tokens.RED);hold.name="Holds";extras_box.add_child(hold)
	var tokens:Array=[]
	for id:String in Messages.tokens_for(civ_id,purpose):tokens.append([id,String(Messages.TOKENS[id].label),String(Messages.TOKENS[id].line)])
	if not String(sel.token) in Messages.tokens_for(civ_id,purpose):sel.token="none"
	extras_box.add_child(_choice_row("Tokens","A token instead of a gift",tokens,String(sel.token),pick_token))
	var menace:=Messages.build(purpose,sel)
	var lines:=Messages.phrasings(civ_id,purpose,menace)
	var phrasings:Array=[]
	for i in lines.size():phrasings.append([str(i),"“%s”" % lines[i],"Your envoy says it in these words."])
	sel.phrase=clampi(int(sel.phrase),0,maxi(0,lines.size()-1))
	var chosen:=_choice_row("Words","Their words",phrasings,str(int(sel.phrase)),pick_phrase)
	for button in chosen.find_children("Choice_*","Button",true,false):
		(button as Button).autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;(button as Button).alignment=HORIZONTAL_ALIGNMENT_LEFT;(button as Button).size_flags_horizontal=SIZE_EXPAND_FILL
		(button as Button).add_theme_font_override("font",Tokens.voice_font(true));(button as Button).add_theme_font_size_override("font_size",17)
	extras_box.add_child(chosen)
	if Messages.voice_available():_words_box("Or say it in your own words; your envoy will carry the meaning.")

func _words_box(hint:String)->void:
	var box:=VBoxContainer.new();box.name="OwnWords";box.add_theme_constant_override("separation",6);extras_box.add_child(box)
	box.add_child(_kicker("In your own words"))
	words_edit=TextEdit.new();words_edit.name="WordsEdit";words_edit.placeholder_text=hint;words_edit.custom_minimum_size=Vector2(0,78)
	words_edit.wrap_mode=TextEdit.LINE_WRAPPING_BOUNDARY
	words_edit.add_theme_stylebox_override("normal",_box(Tokens.PAPER_RAISED,Tokens.RULE,1,Tokens.RADIUS_CONTROL,10,8))
	words_edit.add_theme_stylebox_override("focus",_box(Tokens.PAPER_RAISED,Tokens.GOLD,1,Tokens.RADIUS_CONTROL,10,8))
	words_edit.add_theme_font_override("font",Tokens.voice_font(false));words_edit.add_theme_font_size_override("font_size",18)
	words_edit.add_theme_color_override("font_color",Tokens.INK)
	box.add_child(words_edit)

func _fill_parley()->void:
	var dialogue=WorldSimulation.dialogue
	if not bool(dialogue.access(civ_id).get("ok",false)):
		extras_box.add_child(_voice("Your envoys must first find their ruler and learn the way. After that you can speak to them through your envoys.",17,Tokens.BODY,true));return
	if Messages.voice_available():
		_words_box("What should your envoy say to %s?" % leader_name(civ_id));return
	var options:Array=[]
	for choice:Dictionary in dialogue.offline_choices(civ_id):
		options.append([String(choice.id),String(choice.label),String(choice.get("reason","")),bool(choice.get("enabled",true))])
	if options.is_empty():
		extras_box.add_child(_voice("There is nothing to say to them just now.",17,Tokens.INK_MUTED,true));return
	var ids:Array=options.map(func(o:Array)->String:return String(o[0]))
	if not String(sel.talk) in ids:sel.talk=String(options[0][0])
	var row:=_choice_row("Talk","What your envoy says",options,String(sel.talk),pick_talk)
	for button in row.find_children("Choice_*","Button",true,false):(button as Button).autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;(button as Button).alignment=HORIZONTAL_ALIGNMENT_LEFT
	extras_box.add_child(row)

func _fill_last()->void:
	_clear(last_box)
	for record in WorldSimulation.world.diplomatic_history:
		if not record is Dictionary or String(record.get("civ_id",""))!=civ_id or not record.has("returned_day"):continue
		if _today()-int(record.returned_day)>RECENT_DAYS:return
		var menace:Dictionary=record.get("menace",{}) if record.get("menace") is Dictionary else {}
		var result:Dictionary=menace.get("result",{}) if menace.get("result") is Dictionary else {}
		var voiced:Dictionary=menace.get("voiced",{}) if menace.get("voiced") is Dictionary else {}
		var text:=String(voiced.get("reply",result.get("reply","")))
		if text=="":text=_answer_of(String(record.get("outcome","")))
		if text=="":return
		var box:=_section(last_box,"Latest","Their last answer · "+Chronicle.date_label(int(record.returned_day)))
		box.add_child(_voice("“%s”" % text.substr(0,320),17,Tokens.BODY,true))
		return

func _answer_of(outcome_text:String)->String:
	var marker:=" answered: “"
	var at:=outcome_text.find(marker)
	if at>=0:return outcome_text.substr(at+marker.length()).get_slice("”",0)
	var cut:=RegEx.new();cut.compile("^(.+?[.!?])(\\s|$)")
	var found:=cut.search(outcome_text)
	return found.get_string(1) if found!=null else outcome_text.substr(0,200)

static func _first_up(text:String)->String:
	return text.substr(0,1).to_upper()+text.substr(1)

func _today()->int:
	return int(WorldSimulation.state.elapsed_days)

func _arrival_day()->int:
	var quote:Dictionary=WorldSimulation.world.diplomatic_mission_quote(civ_id,"","leader_parley")
	return _today()+int(quote.get("travel_days",0))

# --- Blockers, cost and reception -----------------------------------------------

func blocker(kind:String)->String:
	## One plain line on why this message cannot go now ("" if it can).
	if kind=="":return "Choose what your envoys will say."
	if not reachable(civ_id):return "Their home is not yet found. Scouts must find it first."
	if kind in Messages.HOSTILE:
		var problem:=Messages.check(civ_id,Messages.build(kind,sel))
		if problem!="":return problem
		var q:Dictionary=WorldSimulation.world.diplomatic_mission_quote(civ_id,"",kind)
		return _plain(String(q.get("error","")))
	if kind=="leader_parley":
		var q2:Dictionary=WorldSimulation.world.diplomatic_mission_quote(civ_id,"","leader_parley")
		if q2.has("error"):return _plain(String(q2.error))
		if WorldSimulation.dialogue.pending.has(civ_id):return "Their last answer is still being told."
		return ""
	var gift:=String(sel.gift) if kind==purpose else ("Food" if Messages.gift_rule(kind)=="food" else "")
	if Messages.gift_rule(kind)=="required" and gift=="":
		for option:Dictionary in WorldSimulation.world.diplomatic_gift_options(civ_id):
			if bool(option.can_send):gift=String(option.resource);break
		if gift=="":return "You have nothing to spare for a gift."
	var q3:Dictionary=WorldSimulation.world.diplomatic_mission_quote(civ_id,gift,kind)
	return _plain(String(q3.get("error","")))

func _plain(text:String)->String:
	## Engine wording, in the sheet's words: whole numbers, no stray decimals.
	if text=="":return ""
	var numbers:=RegEx.new();numbers.compile("(\\d+\\.\\d+)")
	var out:=text
	for found:RegExMatch in numbers.search_all(text):out=out.replace(found.get_string(),about(float(found.get_string())))
	return out.replace("\n"," ")

func quote()->Dictionary:
	if purpose=="":return {}
	var gift:=String(sel.gift) if not purpose in Messages.HOSTILE else ""
	return WorldSimulation.world.diplomatic_mission_quote(civ_id,gift,purpose)

func _fill_cost()->void:
	_clear(cost_row)
	var problem:=blocker(purpose)
	var q:=quote()
	if q.has("personnel"):
		var people:=int(q.personnel)
		cost_row.add_child(_chip("%d %s" % [people,"envoy" if people==1 else "envoys"],Icons.moment_texture("contact",Tokens.BLUE,56),Tokens.BLUE,"They leave the fields while they are away."))
		cost_row.add_child(_chip("About %s Food for the road" % about(float(q.provisions)),Icons.domain_texture("nutrition",Tokens.AMBER),Tokens.AMBER,"Taken from your stores when they leave."))
		cost_row.add_child(_chip("About %d days there and back" % int(q.total_days),Icons.moment_texture("hearth_count",Tokens.RULE_STRONG,56),Tokens.RULE_STRONG,"They reach %s around %s and are home around %s." % [name_of(civ_id),Chronicle.date_label(_today()+int(q.travel_days)),Chronicle.date_label(_today()+int(q.total_days))]))
		var gift:Dictionary=q.get("gift",{}) if q.get("gift") is Dictionary else {}
		if float(gift.get("amount",0.0))>0.0:cost_row.add_child(_chip("About %s %s as a gift" % [about(float(gift.amount)),String(gift.resource)],Icons.texture_for(String(gift.resource)),Tokens.GOLD,"Given away for good."))
	elif purpose!="":
		cost_row.add_child(_label("Nothing can leave yet.","small",Tokens.INK_MUTED))
	reception.text=reception_words()
	blocker_label.text=problem if purpose!="" else ""
	blocker_label.visible=problem!="" and purpose!=""
	send_button.disabled=problem!=""
	send_button.tooltip_text=problem if problem!="" else "Your envoys leave now. Their answer comes home with them."
	send_button.text="Send the envoys" if purpose!="leader_parley" or bool(WorldSimulation.dialogue.access(civ_id).get("ok",false)) else "Send envoys to find their ruler"

static func _reasons(why:Array)->String:
	## "They dread you, and your fighters outnumber theirs."
	if why.is_empty():return ""
	var parts:=PackedStringArray(why)
	var text:=", ".join(parts.slice(0,parts.size()-1))+(", and " if parts.size()>2 else " and ")+parts[parts.size()-1] if parts.size()>1 else parts[0]
	var first:=text.get_slice(" ",0)
	var start:=text.substr(0,1).to_upper()+text.substr(1) if first=="they" or first=="their" or first=="your" else text
	return start+"."

func reception_words()->String:
	if purpose=="":return "Choose whom to send to, and what they will say."
	if purpose in Messages.HOSTILE:
		var f:=Messages.forecast(civ_id,Messages.build(purpose,sel))
		return String(f.words)+" "+_reasons(f.get("why",[]))
	match purpose:
		"goodwill":
			for gift:Dictionary in WorldSimulation.world.diplomatic_gift_options(civ_id):
				if String(gift.resource)==String(sel.gift):return "They would find it %s." % String(gift.reception)
			return "A gift opens doors; words alone do not."
		"send_aid":return "Food helps them only once it arrives."
		"seek_peace":
			var peace:Dictionary=WorldSimulation.world.peace_forecast(civ_id)
			return "They decide when your envoys arrive." if peace.has("error") else "Their mood: %s." % String(peace.get("label","uncertain")).to_lower()
		"declare_war":return "War begins when they hear it."
		"leader_parley":return "Their ruler answers in their own words when your envoys return."
	return "They decide when your envoys arrive."

# --- Choices ----------------------------------------------------------------------

func address(id:String)->void:
	civ_id=id
	sel.gift="";sel.talk=""
	refresh()

func choose(kind:String)->void:
	purpose=_normal(kind)
	sel.gift=""
	if outcome!=null:outcome.visible=false
	refresh()

func pick_gift(resource:String)->void:sel.gift=resource;refresh()
func pick_by(value:String)->void:sel.by=value;refresh()
func pick_demand(value:String)->void:sel.demand=value;refresh()
func pick_deadline(value:String)->void:sel.deadline=int(value);refresh()
func pick_consequence(value:String)->void:sel.consequence=value;refresh()
func pick_token(value:String)->void:sel.token=value;refresh()
func pick_phrase(value:String)->void:sel.phrase=int(value);refresh()
func pick_talk(value:String)->void:sel.talk=value;refresh()

# --- Sending --------------------------------------------------------------------

func send()->Dictionary:
	var problem:=blocker(purpose)
	if problem!="":_say(problem,true);return {"error":problem}
	var typed:=words_edit.text.strip_edges() if is_instance_valid(words_edit) else ""
	var result:Dictionary={}
	var who:=name_of(civ_id)
	if purpose in Messages.HOSTILE:
		var choice:=sel.duplicate();choice["words"]=typed
		result=Messages.send(civ_id,purpose,choice)
	elif purpose=="leader_parley":
		var dialogue=WorldSimulation.dialogue
		if not bool(dialogue.access(civ_id).get("ok",false)):result=ForeignDiplomacy.send_audience(civ_id)
		else:
			var ok:bool=dialogue.ask(civ_id,typed) if typed!="" else (dialogue.ask_offline(civ_id,String(sel.talk)) if String(sel.talk)!="" else false)
			result={"ok":true} if ok else {"error":String(dialogue.thread(civ_id).get("status","Your envoy could not leave."))}
	else:
		result=WorldSimulation.world.dispatch_diplomat(civ_id,String(sel.gift),purpose)
	if result.has("error"):
		_say(_plain(String(result.error)),true);return result
	var message:="Your envoys have left for %s. Their answer comes home with them." % who
	sent.emit(message)
	rebuild()
	_say(message,false)
	return result

func _say(text:String,failed:bool)->void:
	if outcome==null:return
	outcome.text=text;outcome.visible=true
	outcome.add_theme_color_override("font_color",Tokens.RED if failed else Tokens.INK)

func close()->void:
	if is_queued_for_deletion():return
	queue_free()

func _unhandled_input(event:InputEvent)->void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled();close()
