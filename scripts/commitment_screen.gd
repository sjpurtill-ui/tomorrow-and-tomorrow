extends Control
## The Council of Nations: the promises between your people and the peoples
## you know, set as one paper sheet over the court (docs/ART_DIRECTION.md).
##
## Left: a card for every people you can reach (what binds you, what either
## side owes) and your league's roster with its terms in one sentence.
## Right: promises called upon (actions only when something is really owed)
## and a short dated ledger of recent dealings.
## Bottom: the terms your envoys can carry, each with its real cost, travel
## time and likely answer shown before anything is sent.
##
## All state comes from ForeignDiplomacy.commitments (diplomatic_commitments.gd),
## the rulers' characters (rival_rulers.gd) and the diplomatic mission quotes in
## CivilizationSystem. This screen changes state only through
## commitments.send() and dispatch_diplomat(...,"send_aid").

const Tokens:=preload("res://scripts/hud/hud_tokens.gd")
const Icons:=preload("res://scripts/resource_icons.gd")
const Identity:=preload("res://scripts/city_map_identity.gd")
const Portrait:=preload("res://scripts/hud/person_portrait.gd")
const EarlyArt:=preload("res://scripts/hud/early_civ_art.gd")
const Rivals:=preload("res://scripts/rival_rulers.gd")
const Divine:=preload("res://scripts/divine_regard.gd")
const Chronicle:=preload("res://scripts/chronicle.gd")
const Motion:=preload("res://scripts/hud/motion.gd")

const DESIGN_SIZE:=Vector2(1320,900)
const LEDGER_SHOWN:=8
## Plain names for the league aims (the model's GOALS keys).
const AIM_WORDS:={"defense":"Defend one another","exchange":"Share skills and knowledge","routes":"Keep the paths safe for trade"}
const AIM_ICONS:={"defense":"security","exchange":"knowledge","routes":"logistics"}
const LEAGUE_TERMS:="Members answer a siege on any one of them with whatever help they can spare, and talk before any of them starts a war. No one is bound to conquer, and each people keeps its own ruler and fighters."
const PROTECTION_TERMS:="If either people is besieged, the other sends what help it can spare. It does not cover wars either of you starts."
const BOND_WORDS:={"inlaw":"Marriage","hunting":"Hunting leave","dependent":"In your debt","frontier":"Agreed border","recognised":"You named their ruler rightful","hostage":"Kin held as pledges","pilgrimage":"Leave to visit","no_scouts":"Your word on scouts","rites":"Shared rites","cairn":"A cairn raised","hunt_partner":"Hunted together","passage":"Leave to cross"}
const RELIEF_WORDS:={"outbound":"on the road to you","delivered":"arrived at the siege","camped":"camped at the siege","returning":"going home"}
const OBLIGATION_WORDS:={"dispatched":"help was sent","food_aid_delivered":"food was delivered","expired":"the call lapsed","declined":"they declined"}

## Set by the opener before add_child.
var civ_id:=""
var draft:Dictionary={}

# The people being addressed, and the offer being weighed.
var focus_id:=""
var sel_action:=""
var sel_goal:="defense"
var sel_target:=""
var sel_siege:=""

var card:PanelContainer
var peoples_box:VBoxContainer
var league_box:VBoxContainer
var called_box:VBoxContainer
var ledger_box:VBoxContainer
var offers_row:HFlowContainer
var detail_box:VBoxContainer
var cost_box:VBoxContainer
var send_button:Button
var aid_button:Button
var aid_note:Label
var outcome:Label
var address_label:Label
var close_button:Button
var _signature:=""
var timer:=0.0

func _ready()->void:
	name="CouncilOfNations"
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	mouse_filter=MOUSE_FILTER_STOP
	theme=Tokens.control_theme()
	focus_id=civ_id
	sel_action=String(draft.get("action",""))
	if not model().ACTIONS.has(sel_action):sel_action=""
	if model().GOALS.has(String(draft.get("goal",""))):sel_goal=String(draft.goal)
	sel_target=String(draft.get("target_id",""))
	sel_siege=String(draft.get("siege_id",""))
	var scrim:=ColorRect.new();scrim.name="Scrim";scrim.color=Tokens.SCRIM;scrim.set_anchors_and_offsets_preset(PRESET_FULL_RECT);add_child(scrim)
	card=PanelContainer.new();card.name="CouncilSheet"
	var sheet:=Tokens.paper_panel_style(false,Tokens.RADIUS_CARD,0)
	sheet.shadow_color=Color(0,0,0,.18 if Tokens.is_light() else .45);sheet.shadow_size=18;sheet.shadow_offset=Vector2(0,6)
	card.add_theme_stylebox_override("panel",sheet);add_child(card)
	var column:=VBoxContainer.new();column.add_theme_constant_override("separation",0);card.add_child(column)
	column.add_child(_build_header())
	var body:=MarginContainer.new();body.size_flags_vertical=SIZE_EXPAND_FILL
	for side:String in ["left","right"]:body.add_theme_constant_override("margin_"+side,24)
	body.add_theme_constant_override("margin_top",16);body.add_theme_constant_override("margin_bottom",12)
	column.add_child(body)
	var split:=HBoxContainer.new();split.add_theme_constant_override("separation",24);body.add_child(split)
	split.add_child(_build_left())
	split.add_child(_divider())
	split.add_child(_build_middle())
	split.add_child(_divider())
	split.add_child(_build_right())
	column.add_child(_build_proposal())
	_fit()
	refresh(true)
	Motion.fade_in(self)

func model():
	return WorldSimulation.diplomacy.commitments

# --- Chrome helpers -----------------------------------------------------------

func _label(text:String,role:String="body",color:Color=Tokens.BODY,wrap:bool=true)->Label:
	var label:=Label.new();label.text=text
	Tokens.text(label,role,color)
	if wrap:label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	return label

func _voice(text:String,size:int=22,color:Color=Tokens.INK,italic:bool=false)->Label:
	var label:=Label.new();label.text=text;label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_override("font",Tokens.voice_font(italic))
	label.add_theme_font_size_override("font_size",size);label.add_theme_color_override("font_color",color)
	return label

func _kicker(text:String,color:Color=Tokens.INK_MUTED)->Label:
	## Kickers are the only all-caps text (ART_DIRECTION type rules).
	return Tokens.make_label(text.to_upper(),12,color,.12)

func _section(parent:Control,node_name:String,heading:String)->VBoxContainer:
	var box:=VBoxContainer.new();box.name=node_name;box.add_theme_constant_override("separation",8);parent.add_child(box)
	box.add_child(_kicker(heading,Tokens.GOLD))
	var rule:=ColorRect.new();rule.color=Tokens.RULE;rule.custom_minimum_size=Vector2(0,1);box.add_child(rule)
	return box

func _quiet(text:String)->Label:
	var label:=_voice(text,17,Tokens.INK_MUTED,true);label.name="Quiet"
	return label

func _icon(texture:Texture2D,size:float=22.0)->TextureRect:
	var picture:=TextureRect.new();picture.texture=texture;picture.custom_minimum_size=Vector2(size,size)
	picture.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;picture.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.mouse_filter=MOUSE_FILTER_IGNORE;picture.size_flags_vertical=SIZE_SHRINK_CENTER
	return picture

func _box_style(bg:Color,border:Color,width:int=1,radius:int=Tokens.RADIUS_CONTROL,pad_x:float=12,pad_y:float=8)->StyleBoxFlat:
	var style:=StyleBoxFlat.new();style.bg_color=bg;style.border_color=border;style.set_border_width_all(width);style.set_corner_radius_all(radius)
	style.content_margin_left=pad_x;style.content_margin_right=pad_x;style.content_margin_top=pad_y;style.content_margin_bottom=pad_y
	return style

func _style_button(button:Button,primary:bool)->Button:
	button.focus_mode=FOCUS_NONE
	Tokens.text(button,"body",Tokens.INK)
	var ink:=Tokens.GOLD if primary else Tokens.RULE_STRONG
	var wash:=Tokens.GOLD_WASH if primary else Tokens.PAPER_RAISED
	button.add_theme_stylebox_override("normal",_box_style(wash,ink,1,Tokens.RADIUS_CONTROL,16,6))
	var hover:=_box_style(Tokens.PAPER_SUNK,Tokens.GOLD,1,Tokens.RADIUS_CONTROL,16,6)
	button.add_theme_stylebox_override("hover",hover);button.add_theme_stylebox_override("pressed",hover)
	button.add_theme_stylebox_override("disabled",_box_style(Tokens.PAPER_SUNK,Tokens.RULE,1,Tokens.RADIUS_CONTROL,16,6))
	button.add_theme_color_override("font_disabled_color",Tokens.INK_MUTED)
	button.add_theme_color_override("font_color",Tokens.GOLD_BRIGHT if primary else Tokens.INK)
	button.custom_minimum_size.y=36
	return button

func _chip(text:String,texture:Texture2D,tone:Color,tip:String="")->PanelContainer:
	## A small tie or cost mark: icon and words on a paper tab with a tone rule.
	var chip:=PanelContainer.new();chip.mouse_filter=MOUSE_FILTER_PASS;chip.tooltip_text=tip
	var style:=_box_style(Tokens.PAPER_RAISED,tone,1,Tokens.RADIUS_CONTROL,8,3)
	style.border_width_left=3;style.border_width_top=0;style.border_width_right=0;style.border_width_bottom=0
	chip.add_theme_stylebox_override("panel",style)
	var row:=HBoxContainer.new();row.add_theme_constant_override("separation",6);row.mouse_filter=MOUSE_FILTER_IGNORE;chip.add_child(row)
	if texture!=null:row.add_child(_icon(texture,20))
	var words:=_label(text,"small",Tokens.INK,false);words.mouse_filter=MOUSE_FILTER_IGNORE;row.add_child(words)
	return chip

func _clear(box:Node)->void:
	if box==null:return
	for child in box.get_children():box.remove_child(child);child.queue_free()

# --- Names and dates ------------------------------------------------------------

func name_of(id:String)->String:
	if id=="player":return "Your people"
	for value:Dictionary in WorldSimulation.world.civilizations:
		if String(value.get("id",""))==id:return String(value.get("name",id))
	return "another people"

func leader_name(id:String)->String:
	if id=="player":return "You"
	return String(WorldSimulation.diplomacy.leader(id).get("name","their ruler"))

static func when(day:int)->String:
	## Game-calendar words, as the Chronicle dates things ("Year 43 · Spring").
	return Chronicle.date_label(maxi(0,day))

func plain(text:String)->String:
	## A model record in the ledger's words: names for ids, seasons for day numbers.
	var clean:=text.strip_edges()
	var lead:=RegEx.new();lead.compile("^Day \\d+:\\s*")
	clean=lead.sub(clean,"")
	var days:=RegEx.new();days.compile("\\b[Dd]ay (\\d+)\\b")
	for found:RegExMatch in days.search_all(clean):clean=clean.replace(found.get_string(),when(int(found.get_string(1))))
	for value:Dictionary in WorldSimulation.world.civilizations:
		var id:=String(value.get("id",""))
		if id.is_empty() or not id in clean:continue
		var word:=RegEx.new();word.compile("\\b"+id+"\\b")
		clean=word.sub(clean,String(value.get("name",id)),true)
	var player:=RegEx.new();player.compile("\\bplayer\\b")
	clean=player.sub(clean,"your people",true)
	# Whole amounts read as whole: "60.0 Food" is "60 Food".
	var whole:=RegEx.new();whole.compile("\\b(\\d+)\\.0\\b")
	return whole.sub(clean,"$1",true)

static func first_sentence(text:String)->String:
	## The ledger keeps each dealing to its first sentence; the rest is on hover.
	var cut:=RegEx.new();cut.compile("^(.+?[.!?])(\\s|$)")
	var found:=cut.search(text)
	return found.get_string(1) if found!=null else text

static func their_words(text:String)->String:
	## Bond texts are spoken by the other ruler ("the keeper who lives among
	## us"); on your side of the table they read as theirs.
	var result:=text
	for pair:Array in [["\\bour\\b","their"],["\\bOur\\b","Their"],["\\bus\\b","them"],["\\bwe\\b","they"],["\\bWe\\b","They"]]:
		var rule:=RegEx.new();rule.compile(String(pair[0]));result=rule.sub(result,String(pair[1]),true)
	return result.substr(0,1).to_upper()+result.substr(1)

func _emblem(id:String)->Texture2D:
	if id=="player":return Identity.player_crest(maxi(0,int(GameState.founding_banner_index)))
	return Identity.foreign(id).texture

func _ruler_person(id:String)->Dictionary:
	var person:Dictionary=Rivals.portrait_person(id)
	EarlyArt.bind_foreign_identity(person,id,int(GameState.world_seed))
	return person

# --- Layout ----------------------------------------------------------------------

func _build_header()->Control:
	var band:=PanelContainer.new();band.name="Herald"
	var style:=_box_style(Tokens.PAPER,Tokens.GOLD,0,0,24,14)
	style.corner_radius_top_left=Tokens.RADIUS_CARD;style.corner_radius_top_right=Tokens.RADIUS_CARD;style.border_width_bottom=3
	band.add_theme_stylebox_override("panel",style)
	var row:=HBoxContainer.new();row.add_theme_constant_override("separation",16);band.add_child(row)
	row.add_child(_icon(Icons.moment_texture("contact",Tokens.GOLD.lightened(.25),112),56))
	var words:=VBoxContainer.new();words.size_flags_horizontal=SIZE_EXPAND_FILL;words.add_theme_constant_override("separation",2);row.add_child(words)
	words.add_child(_kicker("Pacts and leagues"))
	var title:=Label.new();title.name="Title";title.text="The Council of Nations";Tokens.text(title,"title",Tokens.INK);words.add_child(title)
	words.add_child(_voice("Who stands with you, what each side has promised, and what it costs to ask for more.",18,Tokens.BODY,true))
	close_button=Button.new();close_button.name="ReturnToConversation"
	close_button.text=("‹ Back to %s" % leader_name(civ_id)) if not WorldSimulation.diplomacy.leader(civ_id).is_empty() else "‹ Back"
	close_button.tooltip_text="Close the council and return to the conversation."
	_style_button(close_button,false);close_button.size_flags_vertical=SIZE_SHRINK_CENTER
	close_button.pressed.connect(_close);row.add_child(close_button)
	return band

func _divider()->ColorRect:
	var rule:=ColorRect.new();rule.color=Tokens.RULE;rule.custom_minimum_size=Vector2(1,0)
	return rule

func _column(node_name:String,ratio:float)->Array:
	## A scrolling column: [scroll, stack]. Prose wraps; nothing scrolls sideways.
	var scroll:=ScrollContainer.new();scroll.name=node_name;scroll.size_flags_horizontal=SIZE_EXPAND_FILL;scroll.size_flags_stretch_ratio=ratio
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	# A thin inked rule for the scroll bar, not the engine's grey gutter.
	var bar:=scroll.get_v_scroll_bar()
	var track:=StyleBoxFlat.new();track.bg_color=Tokens.PAPER_SUNK;track.set_corner_radius_all(2);track.content_margin_left=3;track.content_margin_right=3
	var grip:=StyleBoxFlat.new();grip.bg_color=Tokens.RULE;grip.set_corner_radius_all(2);grip.content_margin_left=3;grip.content_margin_right=3
	var grip_hover:=grip.duplicate() as StyleBoxFlat;grip_hover.bg_color=Tokens.RULE_STRONG
	bar.add_theme_stylebox_override("scroll",track)
	bar.add_theme_stylebox_override("grabber",grip)
	bar.add_theme_stylebox_override("grabber_highlight",grip_hover);bar.add_theme_stylebox_override("grabber_pressed",grip_hover)
	var stack:=VBoxContainer.new();stack.size_flags_horizontal=SIZE_EXPAND_FILL;stack.add_theme_constant_override("separation",24);scroll.add_child(stack)
	return [scroll,stack]

func _build_left()->Control:
	var parts:=_column("LeftColumn",1.3)
	var peoples:=_section(parts[1],"Peoples","Peoples you know")
	peoples_box=VBoxContainer.new();peoples_box.name="PeopleCards";peoples_box.add_theme_constant_override("separation",8);peoples.add_child(peoples_box)
	return parts[0]

func _build_middle()->Control:
	var parts:=_column("MiddleColumn",1.0)
	var league:=_section(parts[1],"League","Your league")
	league_box=VBoxContainer.new();league_box.name="LeagueRoster";league_box.add_theme_constant_override("separation",6);league.add_child(league_box)
	var called:=_section(parts[1],"CalledUpon","Promises called upon")
	called_box=VBoxContainer.new();called_box.name="Calls";called_box.add_theme_constant_override("separation",8);called.add_child(called_box)
	return parts[0]

func _build_right()->Control:
	var parts:=_column("RightColumn",.9)
	var dealings:=_section(parts[1],"Dealings","Recent dealings")
	ledger_box=VBoxContainer.new();ledger_box.name="Ledger";ledger_box.size_flags_horizontal=SIZE_EXPAND_FILL;ledger_box.add_theme_constant_override("separation",12);dealings.add_child(ledger_box)
	return parts[0]

func _build_proposal()->Control:
	var panel:=PanelContainer.new();panel.name="Proposal"
	var style:=_box_style(Tokens.PAPER_SUNK,Tokens.RULE,0,0,24,14)
	style.border_width_top=1;style.corner_radius_bottom_left=Tokens.RADIUS_CARD;style.corner_radius_bottom_right=Tokens.RADIUS_CARD
	panel.add_theme_stylebox_override("panel",style)
	var stack:=VBoxContainer.new();stack.add_theme_constant_override("separation",10);panel.add_child(stack)
	address_label=_kicker("",Tokens.GOLD);address_label.name="AddressedTo";stack.add_child(address_label)
	offers_row=HFlowContainer.new();offers_row.name="Offers";offers_row.add_theme_constant_override("h_separation",8);offers_row.add_theme_constant_override("v_separation",8);stack.add_child(offers_row)
	var row:=HBoxContainer.new();row.add_theme_constant_override("separation",24);stack.add_child(row)
	detail_box=VBoxContainer.new();detail_box.name="OfferDetail";detail_box.size_flags_horizontal=SIZE_EXPAND_FILL;detail_box.add_theme_constant_override("separation",6);row.add_child(detail_box)
	cost_box=VBoxContainer.new();cost_box.name="OfferCost";cost_box.custom_minimum_size.x=230;cost_box.add_theme_constant_override("separation",6);row.add_child(cost_box)
	var actions:=VBoxContainer.new();actions.custom_minimum_size.x=240;actions.add_theme_constant_override("separation",8);row.add_child(actions)
	send_button=Button.new();send_button.name="SendTerms";send_button.text="Send the envoys";_style_button(send_button,true);actions.add_child(send_button)
	send_button.pressed.connect(send_terms)
	aid_button=Button.new();aid_button.name="SendFood";aid_button.text="Send food";_style_button(aid_button,false);actions.add_child(aid_button)
	aid_button.pressed.connect(_on_send_food)
	aid_note=_label("","small",Tokens.INK_MUTED);aid_note.name="FoodNote";actions.add_child(aid_note)
	outcome=_voice("",17,Tokens.INK,true);outcome.name="Outcome";outcome.visible=false;stack.add_child(outcome)
	return panel

func _fit()->void:
	if not is_instance_valid(card):return
	var view:=get_viewport_rect().size
	var target:=Vector2(minf(DESIGN_SIZE.x,view.x-40),minf(DESIGN_SIZE.y,view.y-40))
	if card.size!=target:card.size=target
	var place:=((view-card.size)*.5).round()
	if card.position!=place:card.position=place

# --- Content ---------------------------------------------------------------------

func known_peoples()->Array[String]:
	var ids:Array[String]=[]
	for value:Dictionary in WorldSimulation.world.civilizations:
		var id:=String(value.get("id",""))
		if id.is_empty() or not bool(value.get("alive",true)):continue
		if not WorldSimulation.diplomacy.leader(id).is_empty():ids.append(id)
	return ids

func ties(id:String,state:Dictionary)->Array[Dictionary]:
	## What binds your people to this one, each as {text,icon,tone,tip}.
	var out:Array[Dictionary]=[]
	var civ:Dictionary=WorldSimulation.diplomacy.civilization(id)
	var relation:Dictionary=civ.get("player_relation",{}) if civ.get("player_relation") is Dictionary else {}
	if bool(relation.get("at_war",false)):
		out.append({"text":"At war with you","icon":Icons.moment_texture("war",Tokens.RED,56),"tone":Tokens.RED,"tip":"No promise holds while you are at war."})
	var league:Dictionary=state.get("league",{})
	if not league.is_empty() and id in league.get("members",[]):
		out.append({"text":"In your league","icon":Icons.moment_texture("court",Tokens.GOLD,56),"tone":Tokens.GOLD,"tip":LEAGUE_TERMS})
	var pacts:Dictionary=model().state.get("pacts",{})
	if pacts.has(id):
		out.append({"text":"Protection since %s" % when(int((pacts[id] as Dictionary).get("since",0))),"icon":Icons.domain_texture("security",Tokens.TEAL),"tone":Tokens.TEAL,"tip":PROTECTION_TERMS})
	var character:Dictionary=Rivals.rival_character(id)
	for bond:Dictionary in character.get("bonds",[]):
		var kind:=String(bond.get("kind",""))
		out.append({"text":String(BOND_WORDS.get(kind,"Bound")),"icon":Icons.moment_texture("birth" if kind=="inlaw" else "ceremony",Tokens.GREEN,56),"tone":Tokens.GREEN,"tip":"%s, since %s." % [their_words(String(bond.get("text",""))),when(int(bond.get("day",0)))]})
	for debt:Dictionary in character.get("debts",[]):
		var amount:=roundi(float(debt.get("amount",0)))
		var resource:=String(debt.get("resource",""))
		var text:=("They owe you %d %s" if String(debt.get("owed_by",""))=="them" else "You owe them %d %s") % [amount,resource]
		out.append({"text":text,"icon":Icons.domain_texture("wealth",Tokens.AMBER),"tone":Tokens.AMBER,"tip":"Due by %s." % when(int(debt.get("due",0)))})
	var grudges:Array=character.get("grudges",[])
	if not grudges.is_empty():
		out.append({"text":"Holds a grudge","icon":Icons.war_texture("feud",Tokens.RED),"tone":Tokens.RED,"tip":"They remember %s." % String((grudges[0] as Dictionary).get("text",""))})
	return out

func people_card(id:String,state:Dictionary)->Control:
	var addressed:=id==focus_id
	var card_panel:=PanelContainer.new();card_panel.name="People_"+id
	var style:=_box_style(Tokens.PAPER_RAISED,Tokens.GOLD if addressed else Tokens.RULE,1,Tokens.RADIUS_CARD,14,12)
	if addressed:style.border_width_left=3
	card_panel.add_theme_stylebox_override("panel",style)
	var row:=HBoxContainer.new();row.add_theme_constant_override("separation",14);card_panel.add_child(row)
	var frame:=PanelContainer.new();frame.add_theme_stylebox_override("panel",_box_style(Tokens.PAPER_SUNK,Tokens.RULE,1,Tokens.RADIUS_CONTROL,1,1));frame.size_flags_vertical=SIZE_SHRINK_BEGIN;row.add_child(frame)
	var holder:=Control.new();holder.custom_minimum_size=Vector2(64,78);holder.clip_contents=true;frame.add_child(holder)
	var face:=Portrait.picture(_ruler_person(id),64,78);face.set_anchors_and_offsets_preset(PRESET_FULL_RECT);holder.add_child(face)
	var crest:=_icon(_emblem(id),24);crest.position=Vector2(40,2);crest.size=Vector2(22,26);holder.add_child(crest)
	var words:=VBoxContainer.new();words.size_flags_horizontal=SIZE_EXPAND_FILL;words.add_theme_constant_override("separation",4);row.add_child(words)
	var head:=HBoxContainer.new();head.add_theme_constant_override("separation",10);words.add_child(head)
	var title:=_voice(name_of(id),22,Tokens.INK);title.size_flags_horizontal=SIZE_EXPAND_FILL;head.add_child(title)
	if addressed:
		var tag:=_kicker("Addressed",Tokens.GOLD);tag.size_flags_vertical=SIZE_SHRINK_CENTER;head.add_child(tag)
	else:
		var pick:=Button.new();pick.name="Address_"+id;pick.text="Address";_style_button(pick,false);pick.custom_minimum_size.y=30
		pick.tooltip_text="Weigh terms with %s instead." % leader_name(id)
		pick.size_flags_vertical=SIZE_SHRINK_CENTER;pick.pressed.connect(address.bind(id));head.add_child(pick)
	var regard:=Divine.foreign_regard(id)
	var mood:=String(regard.get("id",""))
	var tone:=Tokens.RED if mood in ["war","scorn","fear"] else (Tokens.GREEN if mood in ["honor","awe"] else Tokens.BODY)
	words.add_child(_label("Ruled by %s · they %s" % [leader_name(id),String(regard.get("read","are undecided about you"))],"small",tone))
	var bonds:=ties(id,state)
	if bonds.is_empty():
		words.add_child(_voice("Nothing binds you yet.",16,Tokens.INK_MUTED,true))
	else:
		var flow:=HFlowContainer.new();flow.name="Ties";flow.add_theme_constant_override("h_separation",6);flow.add_theme_constant_override("v_separation",6);words.add_child(flow)
		for tie:Dictionary in bonds:flow.add_child(_chip(String(tie.text),tie.icon,tie.tone,String(tie.get("tip",""))))
	return card_panel

func _fill_peoples(state:Dictionary)->void:
	_clear(peoples_box)
	var ids:=known_peoples()
	if ids.is_empty():
		peoples_box.add_child(_quiet("You know no foreign ruler yet. Scouts and delegates must find them first."));return
	# The people addressed leads; the rest keep their order.
	if focus_id in ids:ids.erase(focus_id);ids.push_front(focus_id)
	for id:String in ids:peoples_box.add_child(people_card(id,state))

func _fill_league(state:Dictionary)->void:
	_clear(league_box)
	var league:Dictionary=state.get("league",{})
	if league.is_empty():
		league_box.add_child(_quiet("You belong to no league. You can found one below with a people who trusts you."));return
	var head:=HBoxContainer.new();head.add_theme_constant_override("separation",10);league_box.add_child(head)
	var goal:=String(league.get("goal","defense"))
	head.add_child(_icon(Icons.domain_texture(String(AIM_ICONS.get(goal,"security")),Tokens.GOLD),36))
	var names:=VBoxContainer.new();names.add_theme_constant_override("separation",0);names.size_flags_horizontal=SIZE_EXPAND_FILL;head.add_child(names)
	var title:=_voice(String(league.get("name","The league")),22,Tokens.INK);title.name="LeagueName";names.add_child(title)
	names.add_child(_label("Aim: %s · founded %s" % [String(AIM_WORDS.get(goal,model().GOALS.get(goal,""))),when(int(league.get("since",0)))],"small",Tokens.INK_MUTED))
	var terms:=_voice(LEAGUE_TERMS,17,Tokens.BODY);terms.name="LeagueTerms";league_box.add_child(terms)
	var joined:Dictionary=league.get("joined",{})
	var votes:Dictionary=league.get("votes",{})
	for member:String in league.get("members",[]):
		var row:=PanelContainer.new();row.name="Member_"+member
		row.add_theme_stylebox_override("panel",_box_style(Tokens.PAPER_RAISED,Tokens.RULE,1,Tokens.RADIUS_CONTROL,10,6))
		var line:=HBoxContainer.new();line.add_theme_constant_override("separation",10);row.add_child(line)
		line.add_child(_icon(_emblem(member),26))
		var who:=_label(name_of(member),"body",Tokens.INK,false);who.add_theme_font_override("font",Tokens.font("ui_strong"));line.add_child(who)
		var ruler:=_label("You" if member=="player" else leader_name(member),"small",Tokens.BODY,false);ruler.size_flags_horizontal=SIZE_EXPAND_FILL;line.add_child(ruler)
		if votes.has(member):
			var vote:Dictionary=votes[member]
			var agrees:=bool(vote.get("accept",false))
			var mark:=_label("agreed" if agrees else "disagreed","small",Tokens.GREEN if agrees else Tokens.RED,false)
			mark.tooltip_text=String(vote.get("reason",""));mark.mouse_filter=MOUSE_FILTER_PASS;line.add_child(mark)
		line.add_child(_label("since %s" % when(int(joined.get(member,league.get("since",0)))),"small",Tokens.INK_MUTED,false))
		league_box.add_child(row)

func _fill_called(state:Dictionary)->void:
	_clear(called_box)
	var shown:=0
	var answered:Array[Dictionary]=[]
	for obligation:Dictionary in state.get("obligations",[]):
		if String(obligation.get("status",""))!="requested":answered.append(obligation);continue
		var donor:=String(obligation.get("donor",""))
		var beneficiary:=String(obligation.get("beneficiary",""))
		var attacker:=String(obligation.get("attacker",""))
		if donor=="player":
			var item:=_call_row("Call_"+beneficiary,Icons.war_texture("band",Tokens.RED),Tokens.RED,
				"%s is under attack by %s and calls on your promise." % [name_of(beneficiary),name_of(attacker)],
				"Since %s. A promise sends nothing by itself: send food, or order an army from your war council." % when(int(obligation.get("day",0))))
			var quote:Dictionary=WorldSimulation.world.diplomatic_mission_quote(beneficiary,"Food","send_aid")
			var send:=Button.new();send.name="SendFood_"+beneficiary;send.text="Send food to %s" % name_of(beneficiary);_style_button(send,true)
			send.disabled=quote.has("error");send.size_flags_horizontal=SIZE_SHRINK_BEGIN
			send.tooltip_text=String(quote.get("error","")) if quote.has("error") else _aid_words(quote)
			send.pressed.connect(send_food.bind(beneficiary))
			(item.get_meta("stack") as VBoxContainer).add_child(send)
			called_box.add_child(item);shown+=1
		elif beneficiary=="player":
			var item:=_call_row("Owed_"+donor,Icons.domain_texture("security",Tokens.TEAL),Tokens.TEAL,
				"%s promised to help you against %s." % [name_of(donor),name_of(attacker)],
				"Owed since %s. Relief comes only if they can spare fighters and food." % when(int(obligation.get("day",0))))
			var ask:=Button.new();ask.name="CallOn_"+donor;ask.text="Call on %s" % name_of(donor);_style_button(ask,false);ask.size_flags_horizontal=SIZE_SHRINK_BEGIN
			ask.tooltip_text="Weigh the call for relief below before sending envoys."
			ask.pressed.connect(call_on.bind(donor,String(obligation.get("siege_id",""))))
			(item.get_meta("stack") as VBoxContainer).add_child(ask)
			called_box.add_child(item);shown+=1
	for receipt:Dictionary in state.get("relief",[]):
		var status:=String(receipt.get("status",""))
		var words:="%s: %d fighters %s" % [name_of(String(receipt.get("donor",""))),int(receipt.get("troops",0)),String(RELIEF_WORDS.get(status,status))]
		if status in ["outbound","returning"]:words+=", expected %s" % when(int(receipt.get("due_day",0)))
		called_box.add_child(_call_row("Relief_"+String(receipt.get("id","")),Icons.war_texture("band",Tokens.TEAL),Tokens.TEAL,words+".",""));shown+=1
	for obligation:Dictionary in answered.slice(maxi(0,answered.size()-3)):
		called_box.add_child(_label("%s · %s: %s." % [when(int(obligation.get("day",0))),name_of(String(obligation.get("beneficiary",""))),String(OBLIGATION_WORDS.get(String(obligation.get("status","")),"settled"))],"small",Tokens.INK_MUTED))
	if shown==0 and answered.is_empty():
		called_box.add_child(_quiet("No one has called on a promise, and no one owes you help in arms."))

func _call_row(node_name:String,texture:Texture2D,tone:Color,head:String,sub:String)->PanelContainer:
	var row:=PanelContainer.new();row.name=node_name
	var style:=_box_style(Tokens.PAPER_RAISED,Tokens.RULE,1,Tokens.RADIUS_CARD,12,10);style.border_color=tone;style.border_width_left=3
	row.add_theme_stylebox_override("panel",style)
	var line:=HBoxContainer.new();line.add_theme_constant_override("separation",12);row.add_child(line)
	line.add_child(_icon(texture,32))
	var stack:=VBoxContainer.new();stack.size_flags_horizontal=SIZE_EXPAND_FILL;stack.add_theme_constant_override("separation",4);line.add_child(stack)
	stack.add_child(_label(head,"body",Tokens.INK))
	if not sub.is_empty():stack.add_child(_label(sub,"small",Tokens.INK_MUTED))
	row.set_meta("stack",stack)
	return row

func _fill_ledger(state:Dictionary)->void:
	_clear(ledger_box)
	var history:Array=state.get("history",[])
	if history.is_empty():
		ledger_box.add_child(_quiet("Nothing has passed between you and other peoples yet."));return
	for item:Dictionary in history.slice(0,LEDGER_SHOWN):
		var entry:=VBoxContainer.new();entry.name="Dealing";entry.add_theme_constant_override("separation",2);ledger_box.add_child(entry)
		var date:=_kicker(when(int(item.get("day",0))),Tokens.GOLD);date.name="When";entry.add_child(date)
		var full:=plain(String(item.get("text","")))
		var line:=_voice(first_sentence(full),17,Tokens.BODY);line.tooltip_text=full;line.mouse_filter=MOUSE_FILTER_PASS
		entry.add_child(line)

# --- Offers ----------------------------------------------------------------------

func offer_keys(state:Dictionary)->Array[String]:
	## The terms that make sense between you and the people addressed now.
	var keys:Array[String]=["protection"]
	var league:Dictionary=state.get("league",{})
	if league.is_empty():
		keys.append("found_faction")
		if not model().faction(focus_id).is_empty():keys.append("join_faction")
	elif focus_id in league.get("members",[]):
		for key:String in ["set_goal","debate_war","leave_faction"]:keys.append(key)
	else:
		keys.append("join_faction")
	for obligation:Dictionary in state.get("obligations",[]):
		if String(obligation.get("donor",""))==focus_id and String(obligation.get("beneficiary",""))=="player" and String(obligation.get("status",""))=="requested" and not "request_relief" in keys:
			keys.append("request_relief")
	var siege:Dictionary=model().siege_info("current")
	if bool(siege.get("active",false)) and focus_id in [String(siege.get("attacker_id","")),String(siege.get("defender_id",""))]:keys.append("negotiate_siege")
	if model().ACTIONS.has(sel_action) and not sel_action in keys:keys.append(sel_action)
	return keys

func offer_words(action:String)->Array:
	## [title, one plain sentence] for an offer to the people addressed.
	var them:=name_of(focus_id)
	match action:
		"protection":return ["Mutual protection",PROTECTION_TERMS]
		"found_faction":return ["Found a league","A standing league with %s under one shared aim. Others may join later, but only if every member agrees." % them]
		"join_faction":
			if model().faction().is_empty():return ["Ask to join their league","Every member of their league is asked, and all of them must agree."]
			return ["Invite them into the league","Every member of your league is asked about %s, and all of them must agree." % them]
		"set_goal":return ["Change the league's aim","Every member must agree. Their peoples then lean a little toward the new aim; your own choices stay yours."]
		"debate_war":return ["Put a war to the league","Ask the members whether they would back a war on another people. A vote sends no one to fight."]
		"leave_faction":return ["Leave the league","Your people step out of the league. Any separate protection promise still holds."]
		"request_relief":return ["Call on their promise","Ask %s to send fighters and food to break the siege, as they promised." % them]
		"negotiate_siege":return ["Ask them to lift the siege","Offer terms for their fighters to withdraw from the siege."]
	return [String(model().ACTIONS.get(action,action)),""]

func selected_terms()->Dictionary:
	var siege:=sel_siege
	if siege.is_empty():siege=String(model().siege_info("current").get("id",""))
	return model().terms(sel_action if model().ACTIONS.has(sel_action) else "protection",sel_goal,sel_target,siege)

func address(id:String)->void:
	focus_id=id
	if sel_action=="request_relief":sel_siege=""
	refresh(true)

func choose(action:String)->void:
	sel_action=action
	refresh(true)

func call_on(donor:String,siege_id:String)->void:
	focus_id=donor;sel_action="request_relief";sel_siege=siege_id
	refresh(true)

func pick_goal(value:String)->void:
	sel_goal=value;refresh(true)

func pick_target(value:String)->void:
	sel_target=value;refresh(true)

func _offer_button(action:String)->Button:
	var words:=offer_words(action)
	var button:=Button.new();button.name="Offer_"+action;button.text=String(words[0]);button.toggle_mode=true;button.focus_mode=FOCUS_NONE
	Tokens.text(button,"body",Tokens.INK);button.custom_minimum_size.y=34
	var blocker:=String(model().eligibility(focus_id,model().terms(action,sel_goal,sel_target,String(selected_terms().siege_id))))
	button.tooltip_text=String(words[1]) if blocker.is_empty() else blocker
	var chosen:=action==sel_action
	var normal:=_box_style(Tokens.PAPER_RAISED,Tokens.RULE,1,Tokens.RADIUS_CONTROL,14,6)
	var on:=_box_style(Tokens.GOLD_WASH,Tokens.GOLD,1,Tokens.RADIUS_CONTROL,14,6);on.border_width_bottom=3
	button.add_theme_stylebox_override("normal",on if chosen else normal)
	button.add_theme_stylebox_override("pressed",on)
	button.add_theme_stylebox_override("hover",on if chosen else _box_style(Tokens.PAPER_RAISED,Tokens.RULE_STRONG,1,Tokens.RADIUS_CONTROL,14,6))
	button.add_theme_stylebox_override("hover_pressed",on)
	var ink:=Tokens.INK if blocker.is_empty() else Tokens.INK_MUTED
	for key:String in ["font_color","font_hover_color","font_pressed_color","font_hover_pressed_color"]:button.add_theme_color_override(key,ink)
	button.set_pressed_no_signal(chosen)
	button.pressed.connect(choose.bind(action))
	return button

func _choice_row(node_name:String,caption:String,options:Array,current:String,pick:Callable)->Control:
	## A small row of paper tabs for the aim or the people named in an offer.
	var row:=HFlowContainer.new();row.name=node_name;row.add_theme_constant_override("h_separation",6);row.add_theme_constant_override("v_separation",6)
	var lead:=_label(caption,"small",Tokens.INK_MUTED,false);lead.size_flags_vertical=SIZE_SHRINK_CENTER;row.add_child(lead)
	for option:Array in options:
		var value:=String(option[0])
		var tab:=Button.new();tab.name="Choice_"+value;tab.text=String(option[1]);tab.focus_mode=FOCUS_NONE;Tokens.text(tab,"small",Tokens.INK);tab.custom_minimum_size.y=28
		var on:=value==current
		var style:=_box_style(Tokens.GOLD_WASH if on else Tokens.PAPER_RAISED,Tokens.GOLD if on else Tokens.RULE,1,Tokens.RADIUS_CONTROL,10,3)
		for state_name:String in ["normal","hover","pressed"]:tab.add_theme_stylebox_override(state_name,style)
		tab.pressed.connect(pick.bind(value))
		row.add_child(tab)
	return row

func _fill_proposal(state:Dictionary)->void:
	var keys:=offer_keys(state)
	if not sel_action in keys:
		# Nothing drafted: open on the first offer that could actually be sent.
		sel_action=keys[0]
		for key:String in keys:
			if String(model().eligibility(focus_id,model().terms(key,sel_goal,sel_target,sel_siege))).is_empty():sel_action=key;break
	address_label.text=("Propose terms to %s of %s" % [leader_name(focus_id),name_of(focus_id)]).to_upper()
	_clear(offers_row)
	for action:String in keys:offers_row.add_child(_offer_button(action))
	_clear(detail_box);_clear(cost_box)
	var terms:=selected_terms()
	var words:=offer_words(sel_action)
	# The chosen tab names the offer; the sheet says what it means.
	var meaning:=_voice(String(words[1]),18,Tokens.INK);meaning.name="OfferMeaning";detail_box.add_child(meaning)
	if sel_action in ["found_faction","set_goal"]:
		var aims:Array=[]
		for key:String in model().GOALS:aims.append([key,String(AIM_WORDS.get(key,model().GOALS[key]))])
		detail_box.add_child(_choice_row("Aims","Shared aim:",aims,sel_goal,pick_goal))
	if sel_action=="debate_war":
		var others:Array=[]
		var league:Dictionary=state.get("league",{})
		for known:Dictionary in state.get("known_civilizations",[]):
			if not String(known.id) in league.get("members",[]):others.append([String(known.id),String(known.name)])
		if others.is_empty():detail_box.add_child(_label("There is no people outside the league to name.","small",Tokens.INK_MUTED))
		else:detail_box.add_child(_choice_row("Targets","War on:",others,sel_target,pick_target))
	var assessment:Dictionary=model().assessment(focus_id,terms)
	var quote:Dictionary=model().mission_quote(focus_id,terms)
	var blocker:=String(assessment.get("blocker",""))
	if blocker.is_empty() and quote.has("error"):blocker=String(quote.error)
	var reception:Label
	if not blocker.is_empty():
		reception=_label(blocker,"body",Tokens.RED);reception.name="Blocker"
	else:
		var yes:=bool(assessment.get("accepted",false))
		reception=_label("Likely answer: yes." if yes else "Likely answer: no.","body",Tokens.GREEN if yes else Tokens.RED)
		reception.name="Reception";reception.mouse_filter=MOUSE_FILTER_PASS
		reception.tooltip_text="Things may change before the envoys come back."
	detail_box.add_child(reception)
	var votes:Dictionary=assessment.get("votes",{})
	var split_vote:=false
	for vote:Dictionary in votes.values():split_vote=split_vote or not bool(vote.get("accept",false))
	if blocker.is_empty() and votes.size()>1 and split_vote:
		for member:String in votes:
			var vote:Dictionary=votes[member]
			detail_box.add_child(_label("%s would %s: %s" % [name_of(member),"agree" if bool(vote.accept) else "refuse",String(vote.reason)],"small",Tokens.GREEN if bool(vote.accept) else Tokens.RED))
	send_button.disabled=not blocker.is_empty()
	send_button.tooltip_text=blocker if not blocker.is_empty() else "Your envoys carry these terms there and back. Nothing is agreed until they return."
	cost_box.add_child(_kicker("What it takes"))
	if quote.has("error"):
		cost_box.add_child(_label("Nothing can be sent yet.","small",Tokens.INK_MUTED))
	else:
		var food:=float(quote.get("provisions",0))+float(quote.get("consultation_food",0))
		var days:=int(quote.get("total_days",0))+int(quote.get("consultation_days",0))
		var people:=int(quote.get("personnel",0))
		var consult:=int(quote.get("consultation_days",0))
		cost_box.add_child(_chip("%d %s" % [people,"envoy" if people==1 else "envoys"],Icons.moment_texture("contact",Tokens.BLUE,56),Tokens.BLUE,"The delegation that carries your terms."))
		cost_box.add_child(_chip("%d Food for the road" % roundi(food),Icons.domain_texture("nutrition",Tokens.AMBER),Tokens.AMBER,"Taken from your stores when the envoys leave."))
		cost_box.add_child(_chip("%d days there and back" % days,Icons.moment_texture("hearth_count",Tokens.RULE_STRONG,56),Tokens.RULE_STRONG,("Includes %d days to consult the other members." % consult) if consult>0 else "The answer comes back with them."))
	_fill_aid()

func _aid_words(quote:Dictionary)->String:
	var gift:Dictionary=quote.get("gift",{}) if quote.get("gift") is Dictionary else {}
	return "%d Food delivered and %d eaten on the road; about %d days there and back." % [roundi(float(gift.get("amount",0))),roundi(float(quote.get("provisions",0))),int(quote.get("total_days",0))]

func _fill_aid()->void:
	var quote:Dictionary=WorldSimulation.world.diplomatic_mission_quote(focus_id,"Food","send_aid")
	aid_button.text="Send food to %s" % name_of(focus_id)
	aid_button.disabled=quote.has("error")
	aid_note.text=String(quote.get("error","")) if quote.has("error") else _aid_words(quote)
	aid_button.tooltip_text=aid_note.text

# --- Actions ---------------------------------------------------------------------

func send_terms()->Dictionary:
	var result:Dictionary=model().send(focus_id,selected_terms())
	_say(String(result.get("error","Your envoys set out for %s. Nothing is agreed until they come back with an answer." % name_of(focus_id))),result.has("error"))
	refresh(true)
	return result

func _on_send_food()->void:
	send_food(focus_id)

func send_food(id:String)->Dictionary:
	var result:Dictionary=WorldSimulation.world.dispatch_diplomat(id,"Food","send_aid")
	_say(String(result.get("error","Food leaves for %s with your envoys. It helps only once it arrives." % name_of(id))),result.has("error"))
	refresh(true)
	return result

func _say(text:String,failed:bool)->void:
	outcome.text=text;outcome.visible=true
	outcome.add_theme_color_override("font_color",Tokens.RED if failed else Tokens.INK)

func _close()->void:
	queue_free()

func _unhandled_input(event:InputEvent)->void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled();_close()

# --- Refresh ---------------------------------------------------------------------

func refresh(force:bool=false)->void:
	var state:Dictionary=model().public_snapshot(focus_id)
	var mission:Dictionary=WorldSimulation.world.diplomatic_mission
	var signature:=JSON.stringify([state.get("protection"),state.get("league"),state.get("obligations"),state.get("relief"),state.get("history"),model().state.get("pacts",{}),
		String(mission.get("civ_id","")),int(mission.get("return_day",0)),roundi(WorldSimulation.food.total_stored()/5.0),focus_id,sel_action,sel_goal,sel_target,sel_siege])
	if not force and signature==_signature:return
	_signature=signature
	_fill_peoples(state)
	_fill_league(state)
	_fill_called(state)
	_fill_ledger(state)
	_fill_proposal(state)

func _process(delta:float)->void:
	_fit()
	timer+=delta
	if timer>=1.0:
		timer=0.0;refresh()
