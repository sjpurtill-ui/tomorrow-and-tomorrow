extends PanelContainer
## The court's one compose area for word to a foreign ruler (one-court-screen).
##
## Under the conversation with the ruler you are addressing: what the message
## is (words, friendship, pacts and leagues, war and peace, menace), what goes
## with it (a gift where one makes sense, or a token of menace; backing,
## demand and its weight, deadline and consequence; accord terms; league
## terms), its cost and likely answer, and one Send. Offline the words are
## chosen from preset briefs and phrasings; online the ruler may also be
## given the god's own typed words (offline-choices-online-typing).
##
## State changes only through the existing calls: CivilizationSystem
## .dispatch_diplomat, EnvoyMessages.send, ForeignDiplomacy.send /
## send_audience, commitments.send and ForeignDialogue.ask / ask_offline.

signal sent(message:String)

const Tokens:=preload("res://scripts/hud/hud_tokens.gd")
const Messages:=preload("res://scripts/envoy_messages.gd")
const Chronicle:=preload("res://scripts/chronicle.gd")

const GROUPS:=[["talk","Words"],["friendship","Friendship"],["pacts","Pacts and leagues"],["war","War and peace"],["menace","Menace"]]
const FRIENDSHIP:=["goodwill","open_trade","non_aggression","send_aid","shared_work"]
const PACT_ACTIONS:=["protection","found_faction","join_faction","set_goal","debate_war","leave_faction","request_relief","negotiate_siege"]
const LABELS:={"shared_work":"Shared work","protection":"Mutual protection","found_faction":"Found a league","join_faction":"Join or invite","set_goal":"League aim","debate_war":"Put a war to the league","leave_faction":"Leave the league","request_relief":"Call on their promise","negotiate_siege":"Lift the siege"}
const PACT_LINES:={"protection":"If either people is besieged, the other sends what help it can spare. It does not cover wars either of you starts.",
	"found_faction":"A standing league under one shared aim. Others may join later, but only if every member agrees.",
	"join_faction":"Every member of the league is asked, and all of them must agree.",
	"set_goal":"Every member must agree. Their peoples then lean a little toward the new aim.",
	"debate_war":"Ask the members whether they would back a war on another people. A vote sends no one to fight.",
	"leave_faction":"Your people step out of the league. Any separate protection promise still holds.",
	"request_relief":"Ask them to send fighters and food to break the siege, as they promised.",
	"negotiate_siege":"Offer terms for their fighters to withdraw from the siege."}
const AIM_WORDS:={"defense":"Defend one another","exchange":"Share skills and knowledge","routes":"Keep the paths safe for trade"}

var civ_id:=""
var group:="talk"
var purpose:="leader_parley"
var sel:={"gift":"","token":"none","by":"wrath","demand":"tribute","size":"heavy","good":"","deadline":182,"consequence":"war","phrase":0,"talk":"",
	"accord":"","tone":"equals","generous":false,"goal":"defense","target":"","siege":""}

var groups_row:HFlowContainer
var purposes_row:HFlowContainer
var options_scroll:ScrollContainer
var options:VBoxContainer
var words_edit:TextEdit
var cost_label:Label
var reception:Label
var blocker_label:Label
var outcome:Label
var send_button:Button
var retry_button:Button
var aside_button:Button
var _signature:=""

func _init()->void:
	name="Compose"

func _ready()->void:
	add_theme_stylebox_override("panel",_box(Tokens.PAPER,Tokens.RULE,1,Tokens.RADIUS_CARD,14,10))
	var stack:=VBoxContainer.new();stack.add_theme_constant_override("separation",6);add_child(stack)
	var head:=HBoxContainer.new();head.add_theme_constant_override("separation",10);stack.add_child(head)
	var kicker:=_kicker("Your envoy carries",Tokens.GOLD);kicker.size_flags_vertical=SIZE_SHRINK_CENTER;head.add_child(kicker)
	groups_row=HFlowContainer.new();groups_row.name="Groups";groups_row.size_flags_horizontal=SIZE_EXPAND_FILL;groups_row.add_theme_constant_override("h_separation",4);head.add_child(groups_row)
	purposes_row=HFlowContainer.new();purposes_row.name="Purposes";purposes_row.add_theme_constant_override("h_separation",6);purposes_row.add_theme_constant_override("v_separation",6);stack.add_child(purposes_row)
	options_scroll=ScrollContainer.new();options_scroll.name="Options";options_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	options_scroll.custom_minimum_size.y=0;stack.add_child(options_scroll)
	options=VBoxContainer.new();options.size_flags_horizontal=SIZE_EXPAND_FILL;options.add_theme_constant_override("separation",6);options_scroll.add_child(options)
	words_edit=TextEdit.new();words_edit.name="WordsEdit";words_edit.custom_minimum_size=Vector2(0,54);words_edit.wrap_mode=TextEdit.LINE_WRAPPING_BOUNDARY
	words_edit.add_theme_stylebox_override("normal",_box(Tokens.PAPER_RAISED,Tokens.RULE,1,Tokens.RADIUS_CONTROL,10,6))
	words_edit.add_theme_stylebox_override("focus",_box(Tokens.PAPER_RAISED,Tokens.GOLD,1,Tokens.RADIUS_CONTROL,10,6))
	words_edit.add_theme_font_override("font",Tokens.voice_font(false));words_edit.add_theme_font_size_override("font_size",17);words_edit.add_theme_color_override("font_color",Tokens.INK)
	words_edit.text_changed.connect(func()->void:
		if purpose=="leader_parley" and civ_id!="":ForeignDialogue.thread(civ_id)["next_brief"]=words_edit.text.substr(0,1500)
		_fill_footer())
	stack.add_child(words_edit)
	var foot:=HBoxContainer.new();foot.add_theme_constant_override("separation",12);stack.add_child(foot)
	var said:=VBoxContainer.new();said.size_flags_horizontal=SIZE_EXPAND_FILL;said.add_theme_constant_override("separation",1);foot.add_child(said)
	cost_label=_label("","small",Tokens.INK_MUTED);cost_label.name="Cost";said.add_child(cost_label)
	reception=_voice("",16,Tokens.INK,true);reception.name="Reception";said.add_child(reception)
	blocker_label=_label("","small",Tokens.RED);blocker_label.name="Blocker";blocker_label.visible=false;said.add_child(blocker_label)
	outcome=_voice("",16,Tokens.INK,true);outcome.name="Outcome";outcome.visible=false;said.add_child(outcome)
	retry_button=_button("Retry reply");retry_button.name="RetryReply";retry_button.size_flags_vertical=SIZE_SHRINK_CENTER
	retry_button.pressed.connect(func()->void:ForeignDialogue.retry(civ_id);refresh(true));foot.add_child(retry_button)
	aside_button=_button("Set aside");aside_button.name="SetAsideReply";aside_button.size_flags_vertical=SIZE_SHRINK_CENTER
	aside_button.tooltip_text="Set the unanswered exchange aside. No agreement was made."
	aside_button.pressed.connect(func()->void:ForeignDialogue.set_aside_reply(civ_id);refresh(true));foot.add_child(aside_button)
	send_button=_button("Send the envoy",true);send_button.name="Send";send_button.custom_minimum_size=Vector2(170,38);send_button.size_flags_vertical=SIZE_SHRINK_CENTER
	send_button.pressed.connect(send);foot.add_child(send_button)
	var thread:Dictionary=ForeignDialogue.thread(civ_id) if civ_id!="" else {}
	words_edit.text=String(thread.get("next_brief",""))
	refresh(true)

# --- Chrome ---------------------------------------------------------------------

func _label(text:String,role:String="body",color:Color=Tokens.BODY,wrap:bool=true)->Label:
	var label:=Label.new();label.text=text;Tokens.text(label,role,color)
	if wrap:label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	return label

func _voice(text:String,size:int=17,color:Color=Tokens.INK,italic:bool=false)->Label:
	var label:=Label.new();label.text=text;label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_override("font",Tokens.voice_font(italic));label.add_theme_font_size_override("font_size",size);label.add_theme_color_override("font_color",color)
	return label

func _kicker(text:String,color:Color=Tokens.INK_MUTED)->Label:
	return Tokens.make_label(text.to_upper(),12,color,.12)

func _box(bg:Color,border:Color,width:int=1,radius:int=Tokens.RADIUS_CONTROL,pad_x:float=12,pad_y:float=6)->StyleBoxFlat:
	var style:=StyleBoxFlat.new();style.bg_color=bg;style.border_color=border;style.set_border_width_all(width);style.set_corner_radius_all(radius)
	style.content_margin_left=pad_x;style.content_margin_right=pad_x;style.content_margin_top=pad_y;style.content_margin_bottom=pad_y
	return style

func _button(text:String,primary:bool=false,selected:bool=false,small:bool=false)->Button:
	var button:=Button.new();button.text=text;button.focus_mode=FOCUS_NONE
	Tokens.text(button,"small" if small else "body",Tokens.INK)
	var ink:=Tokens.GOLD if primary or selected else Tokens.RULE_STRONG
	var normal:=_box(Tokens.GOLD_WASH if primary or selected else Tokens.PAPER_RAISED,ink,1,Tokens.RADIUS_CONTROL,10 if small else 14,3 if small else 5)
	if selected:normal.border_width_bottom=3
	button.add_theme_stylebox_override("normal",normal)
	var hover:=_box(Tokens.PAPER_SUNK,Tokens.GOLD,1,Tokens.RADIUS_CONTROL,10 if small else 14,3 if small else 5)
	if selected:hover.border_width_bottom=3
	button.add_theme_stylebox_override("hover",hover);button.add_theme_stylebox_override("pressed",hover)
	button.add_theme_stylebox_override("disabled",_box(Tokens.PAPER_SUNK,Tokens.RULE,1,Tokens.RADIUS_CONTROL,10 if small else 14,3 if small else 5))
	for key:String in ["font_color","font_hover_color","font_pressed_color"]:button.add_theme_color_override(key,Tokens.GOLD_BRIGHT if primary or selected else Tokens.INK)
	button.add_theme_color_override("font_disabled_color",Tokens.INK_MUTED)
	button.custom_minimum_size.y=28 if small else 34
	return button

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

static func plain(text:String)->String:
	## Engine wording in plain numbers: no stray decimals, no ledger capitals.
	if text=="":return ""
	var numbers:=RegEx.new();numbers.compile("(\\d+\\.\\d+)")
	var out:=text
	for found:RegExMatch in numbers.search_all(text):out=out.replace(found.get_string(),about(float(found.get_string())))
	return out.replace("\n"," ")

func _name_of(id:String)->String:
	var index:=preload("res://scripts/audience_hall.gd")._civ_index(id)
	return String(WorldSimulation.world.civilizations[index].get("name",id)) if index>=0 else "another people"

func _leader_name(id:String)->String:
	return String(WorldSimulation.diplomacy.leader(id).get("name","their ruler"))

func online()->bool:
	return Messages.voice_available()

func model():
	return WorldSimulation.diplomacy.commitments

# --- Catalogue ------------------------------------------------------------------

func purposes_in(kind:String)->Array[String]:
	var out:Array[String]=[]
	match kind:
		"talk":out.append("leader_parley")
		"friendship":for id:String in FRIENDSHIP:out.append(id)
		"pacts":for id:String in pact_keys():out.append(id)
		"war":out.append("seek_peace");out.append("declare_war")
		"menace":for id:String in Messages.HOSTILE:out.append(id)
	return out

func all_purposes()->Array[String]:
	var out:Array[String]=[]
	for pair:Array in GROUPS:out.append_array(purposes_in(String(pair[0])))
	return out

func group_of(kind:String)->String:
	for pair:Array in GROUPS:
		if kind in purposes_in(String(pair[0])):return String(pair[0])
	if kind in PACT_ACTIONS:return "pacts"
	return "talk"

func label_of(kind:String)->String:
	if LABELS.has(kind):return String(LABELS[kind])
	return String((Messages.PURPOSES.get(kind,{}) as Dictionary).get("label",kind))

func line_of(kind:String)->String:
	if PACT_LINES.has(kind):return String(PACT_LINES[kind])
	if kind=="shared_work":return "Work together for two years: teachers, waystations or a quiet border. It costs Timber."
	return String((Messages.PURPOSES.get(kind,{}) as Dictionary).get("line",""))

func pact_keys()->Array[String]:
	## The league and protection terms that make sense with this people now.
	var keys:Array[String]=["protection"]
	if civ_id=="":return keys
	var state:Dictionary=model().public_snapshot(civ_id)
	var league:Dictionary=state.get("league",{})
	if league.is_empty():
		keys.append("found_faction")
		if not model().faction(civ_id).is_empty():keys.append("join_faction")
	elif civ_id in league.get("members",[]):
		for key:String in ["set_goal","debate_war","leave_faction"]:keys.append(key)
	else:
		keys.append("join_faction")
	for obligation:Dictionary in state.get("obligations",[]):
		if String(obligation.get("donor",""))==civ_id and String(obligation.get("beneficiary",""))=="player" and String(obligation.get("status",""))=="requested" and not "request_relief" in keys:keys.append("request_relief")
	var siege:Dictionary=model().siege_info("current")
	if bool(siege.get("active",false)) and civ_id in [String(siege.get("attacker_id","")),String(siege.get("defender_id",""))]:keys.append("negotiate_siege")
	if purpose in PACT_ACTIONS and not purpose in keys:keys.append(purpose)
	return keys

func pact_terms()->Dictionary:
	var siege:=String(sel.siege)
	if siege=="":siege=String(model().siege_info("current").get("id",""))
	return model().terms(purpose if purpose in PACT_ACTIONS else "protection",String(sel.goal),String(sel.target),siege)

# --- Choices --------------------------------------------------------------------

func address(id:String)->void:
	civ_id=id;sel.gift="";sel.talk="";sel.good=""
	if is_instance_valid(words_edit):words_edit.text=String(ForeignDialogue.thread(id).get("next_brief",""))
	refresh(true)

func choose(kind:String,extra:Dictionary={})->void:
	if kind=="":return
	purpose=kind;group=group_of(kind);sel.gift=""
	for key in extra:sel[key]=extra[key]
	if is_instance_valid(outcome):outcome.visible=false
	refresh(true)

func choose_group(kind:String)->void:
	group=kind
	var list:=purposes_in(kind)
	if not purpose in list and not list.is_empty():purpose=list[0]
	sel.gift=""
	refresh(true)

func pick(key:String,value:Variant)->void:
	sel[key]=value
	refresh(true)

func take_up_draft()->void:
	## The terms drafted in the last exchange, set up to send.
	var proposed:Dictionary=ForeignDialogue.thread(civ_id).get("draft",{}) if ForeignDialogue.thread(civ_id).get("draft") is Dictionary else {}
	if proposed.has("commitment"):
		var c:Dictionary=proposed.commitment
		choose(String(c.get("action","protection")),{"goal":String(c.get("goal","defense")),"target":String(c.get("target_id","")),"siege":String(c.get("siege_id",""))})
	elif proposed.has("accord"):
		choose("shared_work",{"accord":String(proposed.accord),"tone":String(proposed.get("tone","equals")),"generous":bool(proposed.get("generous",false))})

# --- Filling --------------------------------------------------------------------

func refresh(force:bool=false)->void:
	if civ_id=="" or groups_row==null:return
	var thread:Dictionary=ForeignDialogue.thread(civ_id)
	var mission:Dictionary=WorldSimulation.world.diplomatic_mission
	var signature:=JSON.stringify([civ_id,group,purpose,sel,String(mission.get("civ_id","")),int(mission.get("return_day",0)),bool(thread.get("retryable",false)),bool(thread.get("in_transit",false)),
		bool(thread.get("returned_home",false)),ForeignDialogue.pending.has(civ_id),roundi(WorldSimulation.food.total_stored()/10.0),online(),bool(ForeignDialogue.access(civ_id).get("ok",false)),int(WorldSimulation.state.elapsed_days)])
	if not force and signature==_signature:return
	_signature=signature
	if not purpose in all_purposes():
		purpose=purposes_in(group)[0] if not purposes_in(group).is_empty() else "leader_parley"
	_fill_groups()
	_fill_purposes()
	_fill_options()
	_fill_footer()

func _fill_groups()->void:
	_clear(groups_row)
	for pair:Array in GROUPS:
		var button:=_button(String(pair[1]),false,String(pair[0])==group,true);button.name="Group_"+String(pair[0])
		button.pressed.connect(choose_group.bind(String(pair[0])));groups_row.add_child(button)

func _fill_purposes()->void:
	_clear(purposes_row)
	for kind:String in purposes_in(group):
		var button:=_button(label_of(kind),false,kind==purpose);button.name="Purpose_"+kind
		var problem:=blocker(kind)
		button.tooltip_text=line_of(kind)+("\n"+problem if problem!="" else "")
		if problem!="" and kind!=purpose:
			for key:String in ["font_color","font_hover_color"]:button.add_theme_color_override(key,Tokens.INK_MUTED)
		button.pressed.connect(choose.bind(kind));purposes_row.add_child(button)
	var draft:Dictionary=ForeignDialogue.thread(civ_id).get("draft",{}) if ForeignDialogue.thread(civ_id).get("draft") is Dictionary else {}
	if not draft.is_empty() and not draft.has("exchange"):
		var take:=_button("Take up their draft",false,false,true);take.name="ReviewDraft";take.size_flags_vertical=SIZE_SHRINK_CENTER
		take.tooltip_text="The terms drafted in your last exchange.";take.pressed.connect(take_up_draft);purposes_row.add_child(take)

func _row(node_name:String,heading:String,choices:Array,current:String,key:String)->Control:
	## choices: [[value,label,tip,enabled]]
	var row:=HBoxContainer.new();row.name=node_name;row.add_theme_constant_override("separation",10)
	var lead:=_kicker(heading);lead.custom_minimum_size.x=128;lead.size_flags_vertical=SIZE_SHRINK_BEGIN;row.add_child(lead)
	var flow:=HFlowContainer.new();flow.size_flags_horizontal=SIZE_EXPAND_FILL;flow.add_theme_constant_override("h_separation",6);flow.add_theme_constant_override("v_separation",6);row.add_child(flow)
	for option:Array in choices:
		var value:=str(option[0])
		var button:=_button(String(option[1]),false,value==current,true);button.name="Choice_"+value.replace(" ","_")
		button.tooltip_text=String(option[2]) if option.size()>2 else ""
		button.disabled=option.size()>3 and not bool(option[3])
		var stored:Variant=option[0]
		button.pressed.connect(pick.bind(key,stored));flow.add_child(button)
	return row

func _note(text:String)->void:
	options.add_child(_voice(text,15,Tokens.INK_MUTED,true))

func _fill_options()->void:
	_clear(options)
	var typed:=false
	var rule:=Messages.gift_rule(purpose) if Messages.PURPOSES.has(purpose) else "none"
	if rule in ["required","optional","food"]:
		var gifts:Array=[]
		if rule=="optional":gifts.append(["","No gift","The message alone.",true])
		for gift:Dictionary in WorldSimulation.world.diplomatic_gift_options(civ_id):
			if rule=="food" and String(gift.resource)!="Food":continue
			var tip:="You hold about %s. They would find it %s." % [about(float(gift.available)),String(gift.reception)] if bool(gift.can_send) else "You hold only about %s." % about(float(gift.available))
			gifts.append([String(gift.resource),"About %s %s" % [about(float(gift.amount)),String(gift.resource)],tip,bool(gift.can_send)])
		if rule!="optional" and String(sel.gift)=="":
			for option:Array in gifts:
				if bool(option[3]):sel.gift=String(option[0]);break
		var allowed:=false
		for option:Array in gifts:allowed=allowed or String(option[0])==String(sel.gift)
		if not allowed:sel.gift=""
		if gifts.is_empty():_note("You have nothing to spare for a gift.")
		else:options.add_child(_row("Gifts","A gift",gifts,String(sel.gift),"gift"))
	else:
		sel.gift=""
	match purpose:
		"leader_parley":typed=_fill_talk()
		"shared_work":_fill_accord()
		"declare_war":
			_fill_tokens()
			_note("War begins the day they hear it. Your generals choose how it is fought.")
		_:
			if purpose in Messages.HOSTILE:typed=_fill_menace()
			elif purpose in PACT_ACTIONS:_fill_pact()
	words_edit.visible=typed
	words_edit.placeholder_text="Say it in your own words; your envoy carries the meaning." if purpose in Messages.HOSTILE else "Brief your envoy: what you want, what you will not give, how far they may bend."
	options_scroll.visible=options.get_child_count()>0
	_fit_options.call_deferred()

func _fit_options()->void:
	## The options scroll within a bounded height; the conversation keeps its room.
	if not is_inside_tree():return
	await get_tree().process_frame
	if not is_instance_valid(options):return
	options_scroll.custom_minimum_size.y=clampf(options.get_combined_minimum_size().y,0.0,176.0)

func _fill_talk()->bool:
	var dialogue=WorldSimulation.dialogue
	if not bool(dialogue.access(civ_id).get("ok",false)):
		_note("Your envoys must first find their ruler and learn the way. After that you can speak to them through your envoys.")
		return false
	if online():return true
	var choices:Array=[]
	for choice:Dictionary in dialogue.offline_choices(civ_id):
		var cost:Dictionary=choice.get("cost",{}) if choice.get("cost") is Dictionary else {}
		var tip:=String(choice.get("reason","")) if not bool(choice.get("enabled",true)) else (("Your envoy carries %d %s." % [roundi(float(cost.amount)),String(cost.resource)]) if not cost.is_empty() else "Your envoy carries these words there and back.")
		choices.append([String(choice.id),String(choice.label),tip,bool(choice.get("enabled",true))])
	if choices.is_empty():_note("There is nothing to say to them just now.");return false
	var ids:=choices.map(func(o:Array)->String:return String(o[0]))
	if not String(sel.talk) in ids:sel.talk=String(choices[0][0])
	var row:=_row("Talk","What your envoy says",choices,String(sel.talk),"talk")
	options.add_child(row)
	return false

func _fill_accord()->void:
	var accords:Array=[]
	for key:String in ForeignDiplomacy.ACCORDS:accords.append([key,String(ForeignDiplomacy.ACCORDS[key].name),String(ForeignDiplomacy.ACCORDS[key].purpose)])
	if not String(sel.accord) in ForeignDiplomacy.ACCORDS:
		sel.accord=String(WorldSimulation.diplomacy.situation(civ_id).get("priority",""))
		if not String(sel.accord) in ForeignDiplomacy.ACCORDS:sel.accord=String(ForeignDiplomacy.ACCORDS.keys()[0])
	options.add_child(_row("Accord","The work",accords,String(sel.accord),"accord"))
	var tones:Array=[]
	for key:String in ForeignDiplomacy.TONES:tones.append([key,String(ForeignDiplomacy.TONES[key]),""])
	options.add_child(_row("Tone","How to ask",tones,String(sel.tone),"tone"))
	options.add_child(_row("Offer","What you give",[[false,"4 Timber","The usual offer: a 12% research benefit for you."],[true,"12 Timber","A larger offer: better received, an 8% benefit for you."]],str(bool(sel.generous)).to_lower(),"generous"))

func _fill_pact()->void:
	if purpose in ["found_faction","set_goal"]:
		var aims:Array=[]
		for key:String in model().GOALS:aims.append([key,String(AIM_WORDS.get(key,model().GOALS[key])),""])
		options.add_child(_row("Aims","Shared aim",aims,String(sel.goal),"goal"))
	if purpose=="debate_war":
		var others:Array=[]
		var state:Dictionary=model().public_snapshot(civ_id)
		var league:Dictionary=state.get("league",{})
		for known:Dictionary in state.get("known_civilizations",[]):
			if not String(known.id) in league.get("members",[]):others.append([String(known.id),String(known.name),""])
		if others.is_empty():_note("There is no people outside the league to name.")
		else:
			if String(sel.target)=="":sel.target=String(others[0][0])
			options.add_child(_row("Targets","War on",others,String(sel.target),"target"))
	var assessment:Dictionary=model().assessment(civ_id,pact_terms())
	var votes:Dictionary=assessment.get("votes",{})
	if votes.size()>1:
		for member:String in votes:
			var vote:Dictionary=votes[member]
			options.add_child(_label("%s would %s: %s" % [_name_of(member),"agree" if bool(vote.get("accept",false)) else "refuse",String(vote.get("reason",""))],"small",Tokens.GREEN if bool(vote.get("accept",false)) else Tokens.RED))

func _fill_tokens()->void:
	var tokens:Array=[]
	for id:String in Messages.tokens_for(civ_id,purpose):tokens.append([id,String(Messages.TOKENS[id].label),String(Messages.TOKENS[id].line)])
	if not String(sel.token) in Messages.tokens_for(civ_id,purpose):sel.token="none"
	if not tokens.is_empty():options.add_child(_row("Tokens","Instead of a gift",tokens,String(sel.token),"token"))

func _fill_menace()->bool:
	if purpose!="warn":
		options.add_child(_row("Backing","What backs it",[["wrath",Messages.BY.wrath.label,Messages.BY.wrath.line],["spears",Messages.BY.spears.label,Messages.BY.spears.line]],String(sel.by),"by"))
	if purpose in ["demand","ultimatum"]:
		var allowed:=Messages.demands_for(civ_id)
		if not String(sel.demand) in allowed:sel.demand="tribute"
		var demands:Array=[]
		for id:String in Messages.DEMANDS:
			var line:=String(Messages.DEMANDS[id].line)
			if id=="apology" and Messages.grievance(civ_id)!="":line="Their ruler owns %s." % Messages.grievance(civ_id)
			demands.append([id,String(Messages.DEMANDS[id].label),line,id in allowed])
		options.add_child(_row("Demands","What you demand",demands,String(sel.demand),"demand"))
		if String(sel.demand)=="tribute":
			var goods:Array=[]
			for option:Dictionary in Messages.tribute_options(civ_id):
				goods.append([String(option.resource),String(option.resource),("They hold about %s." if bool(option.known) else "They hold perhaps %s.") % about(float(option.stock))])
			var terms:=Messages.tribute_terms(civ_id,String(sel.good),String(sel.size))
			if String(sel.good)=="":sel.good=String(terms.resource)
			if not goods.is_empty():options.add_child(_row("Goods","Which goods",goods,String(sel.good),"good"))
			var sizes:Array=[]
			for id:String in Messages.SIZES:
				var t:=Messages.tribute_terms(civ_id,String(sel.good),id)
				sizes.append([id,"%s · about %s %s" % [String(Messages.SIZES[id].label),about(float(t.amount)),String(t.resource)],"%s (%d%% of what they hold)" % [String(Messages.SIZES[id].line),roundi(float(Messages.SIZES[id].share)*100)]])
			options.add_child(_row("Size","How much",sizes,String(sel.size),"size"))
	if purpose=="ultimatum":
		var arrive:=_arrival_day()
		var deadlines:Array=[]
		for days:int in Messages.DEADLINES:deadlines.append([days,String(Messages.DEADLINE_WORDS[days]).substr(0,1).to_upper()+String(Messages.DEADLINE_WORDS[days]).substr(1),"About %s, counted from the day they hear it." % Chronicle.date_label(arrive+days)])
		options.add_child(_row("Deadline","How long they have",deadlines,str(int(sel.deadline)),"deadline"))
		var consequences:Array=[]
		for id:String in Messages.CONSEQUENCES:consequences.append([id,String(Messages.CONSEQUENCES[id].label),String(Messages.CONSEQUENCES[id].line)])
		options.add_child(_row("Consequence","If they refuse",consequences,String(sel.consequence),"consequence"))
		var hold:=_label(String(Messages.CONSEQUENCES[String(sel.consequence)].line),"small",Tokens.RED);hold.name="Holds";options.add_child(hold)
	_fill_tokens()
	var menace:=Messages.priced(civ_id,Messages.build(purpose,sel))
	var lines:=Messages.phrasings(civ_id,purpose,menace)
	var phrasings:Array=[]
	for i in lines.size():phrasings.append([i,"“%s”" % lines[i],"Your envoy carries these words."])
	sel.phrase=clampi(int(sel.phrase),0,maxi(0,lines.size()-1))
	var row:=_row("Words","Your words",phrasings,str(int(sel.phrase)),"phrase")
	for button in row.find_children("Choice_*","Button",true,false):
		(button as Button).autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;(button as Button).alignment=HORIZONTAL_ALIGNMENT_LEFT
		(button as Button).add_theme_font_override("font",Tokens.voice_font(true));(button as Button).add_theme_font_size_override("font_size",15)
		(button as Button).custom_minimum_size.x=220
	options.add_child(row)
	return online()

func _arrival_day()->int:
	var quote:Dictionary=WorldSimulation.world.diplomatic_mission_quote(civ_id,"","leader_parley")
	return int(WorldSimulation.state.elapsed_days)+int(quote.get("travel_days",0))

# --- Cost, blockers and likely answer --------------------------------------------

func blocker(kind:String)->String:
	## One plain line on why this message cannot go now ("" if it can).
	if civ_id=="":return "Choose a ruler to address."
	var mission:Dictionary=WorldSimulation.world.diplomatic_mission
	if not mission.is_empty():
		return "Your envoys are away until about %s; only one party can travel at a time." % Chronicle.date_label(int(mission.get("return_day",0)))
	var dialogue=WorldSimulation.dialogue
	if dialogue.pending.has(civ_id):return "Their last answer is still being set down."
	if bool(dialogue.thread(civ_id).get("in_transit",false)):return "Their answer to your last brief has not been told yet. Retry it or set it aside."
	if kind in Messages.HOSTILE:
		var problem:=Messages.check(civ_id,Messages.build(kind,sel))
		if problem!="":return problem
		return plain(String(WorldSimulation.world.diplomatic_mission_quote(civ_id,"",kind).get("error","")))
	if kind=="leader_parley":
		var q:Dictionary=WorldSimulation.world.diplomatic_mission_quote(civ_id,"","leader_parley")
		if q.has("error"):return plain(String(q.error))
		if bool(dialogue.access(civ_id).get("ok",false)) and kind==purpose:
			if online() and is_instance_valid(words_edit) and words_edit.text.strip_edges()=="":return "Write what your envoy should say."
			if not online() and String(sel.talk)=="":return "Choose what your envoy should say."
		return ""
	if kind=="shared_work":
		var f:Dictionary=WorldSimulation.diplomacy.forecast(civ_id,String(sel.accord) if String(sel.accord) in ForeignDiplomacy.ACCORDS else String(ForeignDiplomacy.ACCORDS.keys()[0]),String(sel.tone),bool(sel.generous))
		if f.has("error"):return plain(String(f.error))
		if String(f.get("blocker",""))!="":return plain(String(f.blocker))
		if float(WorldSimulation.state.resource_stockpiles.get("Timber",0))<float(f.get("cost",4)):return "You need %d Timber for these terms." % int(f.get("cost",4))
		return plain(String(WorldSimulation.world.diplomatic_mission_quote(civ_id,"","leader_parley").get("error","")))
	if kind in PACT_ACTIONS:
		var terms:=model().terms(kind,String(sel.goal),String(sel.target),String(pact_terms().siege_id))
		var reason:=String(model().eligibility(civ_id,terms))
		if reason=="":reason=String(model().mission_quote(civ_id,terms).get("error",""))
		return plain(reason)
	var gift:=String(sel.gift) if kind==purpose else ("Food" if Messages.gift_rule(kind)=="food" else "")
	if Messages.gift_rule(kind)=="required" and gift=="":
		for option:Dictionary in WorldSimulation.world.diplomatic_gift_options(civ_id):
			if bool(option.can_send):gift=String(option.resource);break
		if gift=="":return "You have nothing to spare for a gift."
	return plain(String(WorldSimulation.world.diplomatic_mission_quote(civ_id,gift,kind).get("error","")))

func quote()->Dictionary:
	if purpose in PACT_ACTIONS:return model().mission_quote(civ_id,pact_terms())
	if purpose in ["leader_parley","shared_work"]:return WorldSimulation.world.diplomatic_mission_quote(civ_id,"","leader_parley")
	var gift:=String(sel.gift) if not purpose in Messages.HOSTILE else ""
	return WorldSimulation.world.diplomatic_mission_quote(civ_id,gift,purpose)

func reception_words()->String:
	if purpose in Messages.HOSTILE:
		var f:=Messages.forecast(civ_id,Messages.priced(civ_id,Messages.build(purpose,sel)))
		var why:Array=f.get("why",[])
		var text:=String(f.words)+" (about %d in 10)" % roundi(float(f.chance)*10.0)
		if not why.is_empty():text+=": "+", ".join(PackedStringArray(why))+"."
		else:text+="."
		return text
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
		"shared_work":
			var f2:Dictionary=WorldSimulation.diplomacy.forecast(civ_id,String(sel.accord) if String(sel.accord) in ForeignDiplomacy.ACCORDS else String(ForeignDiplomacy.ACCORDS.keys()[0]),String(sel.tone),bool(sel.generous))
			return "%s. %s" % [String(f2.get("label","")),String(f2.get("reasons",""))] if not f2.has("error") else ""
	if purpose in PACT_ACTIONS:
		var a:Dictionary=model().assessment(civ_id,pact_terms())
		return "Likely answer: yes." if bool(a.get("accepted",false)) else "Likely answer: no."
	return "They decide when your envoys arrive."

func _fill_footer()->void:
	if send_button==null:return
	var problem:=blocker(purpose)
	var q:=quote()
	var parts:PackedStringArray=PackedStringArray()
	if q.has("personnel"):
		parts.append("%d %s" % [int(q.personnel),"envoy" if int(q.personnel)==1 else "envoys"])
		parts.append("about %s Food for the road" % about(float(q.get("provisions",0))+float(q.get("consultation_food",0))))
		parts.append("about %d days there and back" % (int(q.get("total_days",0))+int(q.get("consultation_days",0))))
		var gift:Dictionary=q.get("gift",{}) if q.get("gift") is Dictionary else {}
		if float(gift.get("amount",0.0))>0.0:parts.append("about %s %s given away" % [about(float(gift.amount)),String(gift.resource)])
	if purpose=="shared_work":parts.append("%d Timber" % (12 if bool(sel.generous) else 4))
	cost_label.text=(" · ".join(parts)).substr(0,1).to_upper()+(" · ".join(parts)).substr(1) if not parts.is_empty() else ""
	cost_label.visible=not parts.is_empty()
	reception.text=reception_words()
	blocker_label.text=problem
	blocker_label.visible=problem!=""
	send_button.disabled=problem!=""
	send_button.tooltip_text=problem if problem!="" else "Your envoy leaves now. The answer comes home with them."
	send_button.text="Send envoys to find their ruler" if purpose=="leader_parley" and not bool(WorldSimulation.dialogue.access(civ_id).get("ok",false)) else "Send the envoy"
	var thread:Dictionary=ForeignDialogue.thread(civ_id)
	retry_button.visible=bool(thread.get("retryable",false)) and bool(thread.get("in_transit",false))
	retry_button.disabled=not PronouncementInterpreter.connection_problem().is_empty() or ForeignDialogue.pending.has(civ_id)
	aside_button.visible=bool(thread.get("returned_home",false)) and bool(thread.get("in_transit",false))

# --- Sending ----------------------------------------------------------------------

func send_words(text:String)->bool:
	## Speak with their ruler in the god's own words (online).
	choose("leader_parley")
	words_edit.text=text
	return not send().has("error")

func send()->Dictionary:
	var problem:=blocker(purpose)
	if problem!="":_say(problem,true);return {"error":problem}
	var typed:=words_edit.text.strip_edges() if is_instance_valid(words_edit) and words_edit.visible else ""
	var result:Dictionary={}
	var dialogue=WorldSimulation.dialogue
	match purpose:
		"leader_parley":
			if not bool(dialogue.access(civ_id).get("ok",false)):result=WorldSimulation.diplomacy.send_audience(civ_id)
			else:
				var ok:bool=dialogue.ask(civ_id,typed) if typed!="" else dialogue.ask_offline(civ_id,String(sel.talk))
				result={"ok":true} if ok else {"error":String(dialogue.thread(civ_id).get("status","Your envoy could not leave."))}
				if ok:words_edit.text=""
		"shared_work":result=WorldSimulation.diplomacy.send(civ_id,String(sel.accord),String(sel.tone),bool(sel.generous))
		_:
			if purpose in Messages.HOSTILE:
				var choice:=sel.duplicate();choice["words"]=typed
				result=Messages.send(civ_id,purpose,choice)
				if not result.has("error"):words_edit.text=""
			elif purpose in PACT_ACTIONS:result=model().send(civ_id,pact_terms())
			else:
				result=WorldSimulation.world.dispatch_diplomat(civ_id,String(sel.gift),purpose)
				if not result.has("error"):
					dialogue._append(civ_id,"user","%s%s" % [line_of(purpose)," (with about %s %s)" % [about(float((WorldSimulation.world.diplomatic_mission.get("gift_amount",0.0)))),String(sel.gift)] if String(sel.gift)!="" else ""])
	if result.has("error"):_say(plain(String(result.error)),true);return result
	var message:="Your envoy has left for %s. The answer comes home with them." % _name_of(civ_id)
	_say(message,false)
	sent.emit(message)
	refresh(true)
	return result

func _say(text:String,failed:bool)->void:
	if outcome==null:return
	outcome.text=text;outcome.visible=true
	outcome.add_theme_color_override("font_color",Tokens.RED if failed else Tokens.INK)
