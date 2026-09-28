extends ScrollContainer
## Pacts and leagues, inside the court (one-court-screen): what used to be the
## Council of Nations overlay. Your league and its terms, promises called
## upon, standing exchanges and a short dated ledger of dealings. Every offer
## is made in the court's compose area: the buttons here only turn it to the
## right ruler and purpose (compose_request). Ending a standing exchange is
## the one direct act, since it sends no one.
##
## ties() gives the addressed ruler's ties for the court's "What you know".

signal compose_request(civ_id:String,purpose:String,extra:Dictionary)

const Tokens:=preload("res://scripts/hud/hud_tokens.gd")
const Icons:=preload("res://scripts/resource_icons.gd")
const Identity:=preload("res://scripts/city_map_identity.gd")
const Rivals:=preload("res://scripts/rival_rulers.gd")
const Chronicle:=preload("res://scripts/chronicle.gd")
const Pacts:=preload("res://scripts/trade_pacts.gd")
const Messages:=preload("res://scripts/envoy_messages.gd")

const LEDGER_SHOWN:=8
const AIM_WORDS:={"defense":"Defend one another","exchange":"Share skills and knowledge","routes":"Keep the paths safe for trade"}
const LEAGUE_TERMS:="Members answer a siege on any one of them with whatever help they can spare, and talk before any of them starts a war. No one is bound to conquer, and each people keeps its own ruler and fighters."
const PROTECTION_TERMS:="If either people is besieged, the other sends what help it can spare. It does not cover wars either of you starts."
const BOND_WORDS:={"inlaw":"Marriage","hunting":"Hunting leave","dependent":"In your debt","frontier":"Agreed border","recognised":"You named their ruler rightful","hostage":"Kin held as pledges","pilgrimage":"Leave to visit","no_scouts":"Your word on scouts","rites":"Shared rites","cairn":"A cairn raised","hunt_partner":"Hunted together","passage":"Leave to cross","marriage":"Marriage"}
const RELIEF_WORDS:={"outbound":"on the road to you","delivered":"arrived at the siege","camped":"camped at the siege","returning":"going home"}
const EXCHANGE_OUTCOMES:={"sealed":"sealed","delivered":"delivered","partial":"partly delivered","skipped":"skipped","suspended":"suspended by war","cancelled":"ended","lapsed":"lapsed","completed":"completed"}
const OBLIGATION_WORDS:={"dispatched":"help was sent","food_aid_delivered":"food was delivered","expired":"the call lapsed","declined":"they declined"}

var civ_id:=""
var stack:VBoxContainer
var league_box:VBoxContainer
var called_box:VBoxContainer
var exchange_box:VBoxContainer
var ledger_box:VBoxContainer
var outcome:Label
var _signature:=""

func _init()->void:
	name="PactsAndLeagues"

func _ready()->void:
	horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	size_flags_vertical=SIZE_EXPAND_FILL;size_flags_horizontal=SIZE_EXPAND_FILL
	stack=VBoxContainer.new();stack.size_flags_horizontal=SIZE_EXPAND_FILL;stack.add_theme_constant_override("separation",20);add_child(stack)
	league_box=_section("League","Your league")
	called_box=_section("CalledUpon","Promises called upon")
	exchange_box=_section("Exchanges","Standing exchanges")
	ledger_box=_section("Dealings","Recent dealings")
	outcome=_voice("",16,Tokens.INK,true);outcome.name="Outcome";outcome.visible=false;stack.add_child(outcome)
	refresh(true)

# --- Chrome -----------------------------------------------------------------------

func _label(text:String,role:String="body",color:Color=Tokens.BODY,wrap:bool=true)->Label:
	var label:=Label.new();label.text=text;Tokens.text(label,role,color)
	if wrap:label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	return label

func _voice(text:String,size:int=18,color:Color=Tokens.INK,italic:bool=false)->Label:
	var label:=Label.new();label.text=text;label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_override("font",Tokens.voice_font(italic));label.add_theme_font_size_override("font_size",size);label.add_theme_color_override("font_color",color)
	return label

func _kicker(text:String,color:Color=Tokens.INK_MUTED)->Label:
	return Tokens.make_label(text.to_upper(),12,color,.12)

func _box(bg:Color,border:Color,width:int=1,radius:int=Tokens.RADIUS_CONTROL,pad_x:float=12,pad_y:float=8)->StyleBoxFlat:
	var style:=StyleBoxFlat.new();style.bg_color=bg;style.border_color=border;style.set_border_width_all(width);style.set_corner_radius_all(radius)
	style.content_margin_left=pad_x;style.content_margin_right=pad_x;style.content_margin_top=pad_y;style.content_margin_bottom=pad_y
	return style

func _button(text:String,primary:bool=false)->Button:
	var button:=Button.new();button.text=text;button.focus_mode=FOCUS_NONE
	Tokens.text(button,"small",Tokens.INK)
	button.add_theme_stylebox_override("normal",_box(Tokens.GOLD_WASH if primary else Tokens.PAPER_RAISED,Tokens.GOLD if primary else Tokens.RULE_STRONG,1,Tokens.RADIUS_CONTROL,12,4))
	var hover:=_box(Tokens.PAPER_SUNK,Tokens.GOLD,1,Tokens.RADIUS_CONTROL,12,4)
	button.add_theme_stylebox_override("hover",hover);button.add_theme_stylebox_override("pressed",hover)
	button.add_theme_stylebox_override("disabled",_box(Tokens.PAPER_SUNK,Tokens.RULE,1,Tokens.RADIUS_CONTROL,12,4))
	for key:String in ["font_color","font_hover_color","font_pressed_color"]:button.add_theme_color_override(key,Tokens.GOLD_BRIGHT if primary else Tokens.INK)
	button.add_theme_color_override("font_disabled_color",Tokens.INK_MUTED)
	button.custom_minimum_size.y=30;button.size_flags_horizontal=SIZE_SHRINK_BEGIN
	return button

func _icon(texture:Texture2D,size:float=22.0)->TextureRect:
	var picture:=TextureRect.new();picture.texture=texture;picture.custom_minimum_size=Vector2(size,size)
	picture.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;picture.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.mouse_filter=MOUSE_FILTER_IGNORE;picture.size_flags_vertical=SIZE_SHRINK_CENTER
	return picture

func _section(node_name:String,heading:String)->VBoxContainer:
	var box:=VBoxContainer.new();box.name=node_name;box.add_theme_constant_override("separation",8);stack.add_child(box)
	box.add_child(_kicker(heading,Tokens.GOLD))
	var rule:=ColorRect.new();rule.color=Tokens.RULE;rule.custom_minimum_size=Vector2(0,1);box.add_child(rule)
	var body:=VBoxContainer.new();body.name=node_name+"Body";body.add_theme_constant_override("separation",8);box.add_child(body)
	return body

func _quiet(text:String)->Label:
	var label:=_voice(text,16,Tokens.INK_MUTED,true);label.name="Quiet"
	return label

func _clear(box:Node)->void:
	if box==null:return
	for child in box.get_children():box.remove_child(child);child.queue_free()

func _row(node_name:String,texture:Texture2D,tone:Color,head:String,sub:String)->PanelContainer:
	var row:=PanelContainer.new();row.name=node_name
	var style:=_box(Tokens.PAPER_RAISED,tone,1,Tokens.RADIUS_CARD,12,8);style.border_width_left=3
	row.add_theme_stylebox_override("panel",style)
	var line:=HBoxContainer.new();line.add_theme_constant_override("separation",12);row.add_child(line)
	line.add_child(_icon(texture,28))
	var inner:=VBoxContainer.new();inner.size_flags_horizontal=SIZE_EXPAND_FILL;inner.add_theme_constant_override("separation",4);line.add_child(inner)
	inner.add_child(_label(head,"body",Tokens.INK))
	if not sub.is_empty():inner.add_child(_label(sub,"small",Tokens.INK_MUTED))
	row.set_meta("stack",inner)
	return row

# --- Names and dates ---------------------------------------------------------------

static func model():
	return WorldSimulation.diplomacy.commitments

static func name_of(id:String)->String:
	if id=="player":return "Your people"
	for value:Dictionary in WorldSimulation.world.civilizations:
		if String(value.get("id",""))==id:return String(value.get("name",id))
	return "another people"

static func when(day:int)->String:
	return Chronicle.date_label(maxi(0,day))

static func plain(text:String)->String:
	## A model record in the ledger's words: names for ids, seasons for days.
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
	var whole:=RegEx.new();whole.compile("\\b(\\d+)\\.0\\b")
	return whole.sub(clean,"$1",true)

static func first_sentence(text:String)->String:
	var cut:=RegEx.new();cut.compile("^(.+?[.!?])(\\s|$)")
	var found:=cut.search(text)
	return found.get_string(1) if found!=null else text

static func their_words(text:String)->String:
	var result:=text
	for pair:Array in [["\\bour\\b","their"],["\\bOur\\b","Their"],["\\bus\\b","them"],["\\bwe\\b","they"],["\\bWe\\b","They"]]:
		var rule:=RegEx.new();rule.compile(String(pair[0]));result=rule.sub(result,String(pair[1]),true)
	return result.substr(0,1).to_upper()+result.substr(1)

static func exchange_tip(pact:Dictionary)->String:
	var lines:PackedStringArray=[Pacts.describe(pact.terms),Pacts.next_words(pact)+"."]
	for entry:Dictionary in (pact.get("log",[]) as Array).slice(0,4):
		lines.append("%s · %s: %s" % [when(int(entry.get("d",0))),String(EXCHANGE_OUTCOMES.get(String(entry.get("o","")),String(entry.get("o","")))),first_sentence(String(entry.get("n","")))])
	return "\n".join(lines)

static func ties(id:String)->Array[Dictionary]:
	## What binds your people to this one: [{text,tip,tone}], tone is one of
	## "danger", "good", "gold", "note".
	var out:Array[Dictionary]=[]
	var state:Dictionary=model().public_snapshot(id)
	var civ:Dictionary=WorldSimulation.diplomacy.civilization(id)
	var relation:Dictionary=civ.get("player_relation",{}) if civ.get("player_relation") is Dictionary else {}
	# A small people's fight is a feud (war_loop.gd), never called a war.
	var war_loop:GDScript=load("res://scripts/war_loop.gd")
	if war_loop!=null and bool(war_loop.call("feuding",id)) and bool(war_loop.call("hot",id)):out.append({"text":"In a feud with you","tip":"Raids and killings back and forth; no promise holds while the feud is hot.","tone":"danger"})
	elif bool(relation.get("at_war",false)):out.append({"text":"At war with you","tip":"No promise holds while you are at war.","tone":"danger"})
	var league:Dictionary=state.get("league",{})
	if not league.is_empty() and id in league.get("members",[]):out.append({"text":"In your league","tip":LEAGUE_TERMS,"tone":"gold"})
	for pact:Dictionary in Pacts.pacts(id):out.append({"text":"Trade: %s" % Pacts.short_words(pact.terms),"tip":exchange_tip(pact),"tone":"good"})
	var pacts:Dictionary=model().state.get("pacts",{})
	if pacts.has(id):out.append({"text":"Protection since %s" % when(int((pacts[id] as Dictionary).get("since",0))),"tip":PROTECTION_TERMS,"tone":"good"})
	var character:Dictionary=Rivals.rival_character(id)
	for bond:Dictionary in character.get("bonds",[]):
		out.append({"text":String(BOND_WORDS.get(String(bond.get("kind","")),"Bound")),"tip":"%s, since %s." % [their_words(String(bond.get("text",""))),when(int(bond.get("day",0)))],"tone":"good"})
	for debt:Dictionary in character.get("debts",[]):
		var amount:=roundi(float(debt.get("amount",0)))
		var text:=("They owe you %d %s" if String(debt.get("owed_by",""))=="them" else "You owe them %d %s") % [amount,String(debt.get("resource",""))]
		out.append({"text":text,"tip":"Due by %s." % when(int(debt.get("due",0))),"tone":"note"})
	var grudges:Array=character.get("grudges",[])
	if not grudges.is_empty():out.append({"text":"Holds a grudge","tip":"They remember %s." % String((grudges[0] as Dictionary).get("text","")),"tone":"danger"})
	out.append_array(Messages.ties(id))
	return out

# --- Content ------------------------------------------------------------------------

func refresh(force:bool=false)->void:
	if stack==null:return
	var state:Dictionary=model().public_snapshot(civ_id)
	var signature:=JSON.stringify([state.get("league"),state.get("obligations"),state.get("relief"),state.get("history"),Pacts.store().get("pacts",[]),civ_id,String(WorldSimulation.world.diplomatic_mission.get("civ_id",""))])
	if not force and signature==_signature:return
	_signature=signature
	_fill_league(state)
	_fill_called(state)
	_fill_exchanges()
	_fill_ledger(state)

func _fill_league(state:Dictionary)->void:
	_clear(league_box)
	var league:Dictionary=state.get("league",{})
	if league.is_empty():
		league_box.add_child(_quiet("You belong to no league. Found one with a people who trusts you: choose Pacts and leagues when you address their ruler."));return
	var goal:=String(league.get("goal","defense"))
	var head:=HBoxContainer.new();head.add_theme_constant_override("separation",10);league_box.add_child(head)
	head.add_child(_icon(Icons.domain_texture({"defense":"security","exchange":"knowledge","routes":"logistics"}.get(goal,"security"),Tokens.GOLD),32))
	var names:=VBoxContainer.new();names.size_flags_horizontal=SIZE_EXPAND_FILL;head.add_child(names)
	var title:=_voice(String(league.get("name","The league")),20,Tokens.INK);title.name="LeagueName";names.add_child(title)
	names.add_child(_label("Aim: %s · founded %s" % [String(AIM_WORDS.get(goal,model().GOALS.get(goal,""))),when(int(league.get("since",0)))],"small",Tokens.INK_MUTED))
	var terms:=_voice(LEAGUE_TERMS,16,Tokens.BODY);terms.name="LeagueTerms";league_box.add_child(terms)
	var joined:Dictionary=league.get("joined",{})
	var votes:Dictionary=league.get("votes",{})
	for member:String in league.get("members",[]):
		var row:=PanelContainer.new();row.name="Member_"+member
		row.add_theme_stylebox_override("panel",_box(Tokens.PAPER_RAISED,Tokens.RULE,1,Tokens.RADIUS_CONTROL,10,5))
		var line:=HBoxContainer.new();line.add_theme_constant_override("separation",10);row.add_child(line)
		line.add_child(_icon(Identity.emblem(member),24))
		var who:=_label(name_of(member),"body",Tokens.INK,false);who.size_flags_horizontal=SIZE_EXPAND_FILL;line.add_child(who)
		if votes.has(member):
			var agrees:=bool((votes[member] as Dictionary).get("accept",false))
			var mark:=_label("agreed" if agrees else "disagreed","small",Tokens.GREEN if agrees else Tokens.RED,false)
			mark.tooltip_text=String((votes[member] as Dictionary).get("reason",""));mark.mouse_filter=MOUSE_FILTER_PASS;line.add_child(mark)
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
			var item:=_row("Call_"+beneficiary,Icons.war_texture("band",Tokens.RED),Tokens.RED,"%s is under attack by %s and calls on your promise." % [name_of(beneficiary),name_of(attacker)],
				"Since %s. A promise sends nothing by itself: send food, or order an army from your war council." % when(int(obligation.get("day",0))))
			var send:=_button("Send food to %s" % name_of(beneficiary),true);send.name="SendFood_"+beneficiary
			send.tooltip_text="Turns your envoy's message to food aid for them."
			send.pressed.connect(func()->void:compose_request.emit(beneficiary,"send_aid",{}))
			(item.get_meta("stack") as VBoxContainer).add_child(send)
			called_box.add_child(item);shown+=1
		elif beneficiary=="player":
			var item2:=_row("Owed_"+donor,Icons.domain_texture("security",Tokens.TEAL),Tokens.TEAL,"%s promised to help you against %s." % [name_of(donor),name_of(attacker)],
				"Owed since %s. Relief comes only if they can spare fighters and food." % when(int(obligation.get("day",0))))
			var ask:=_button("Call on %s" % name_of(donor));ask.name="CallOn_"+donor
			ask.tooltip_text="Turns your envoy's message to a call for relief."
			var siege:=String(obligation.get("siege_id",""))
			ask.pressed.connect(func()->void:compose_request.emit(donor,"request_relief",{"siege":siege}))
			(item2.get_meta("stack") as VBoxContainer).add_child(ask)
			called_box.add_child(item2);shown+=1
	for receipt:Dictionary in state.get("relief",[]):
		var status:=String(receipt.get("status",""))
		var words:="%s: %d fighters %s" % [name_of(String(receipt.get("donor_civ_id",receipt.get("donor","")))),int(receipt.get("troops",0)),String(RELIEF_WORDS.get(status,status))]
		if status in ["outbound","returning"]:words+=", expected %s" % when(int(receipt.get("due_day",0)))
		called_box.add_child(_row("Relief_"+String(receipt.get("id","")),Icons.war_texture("band",Tokens.TEAL),Tokens.TEAL,words+".",""));shown+=1
	for obligation:Dictionary in answered.slice(maxi(0,answered.size()-3)):
		called_box.add_child(_label("%s · %s: %s." % [when(int(obligation.get("day",0))),name_of(String(obligation.get("beneficiary",""))),String(OBLIGATION_WORDS.get(String(obligation.get("status","")),"settled"))],"small",Tokens.INK_MUTED))
	if shown==0 and answered.is_empty():called_box.add_child(_quiet("No one has called on a promise, and no one owes you help in arms."))

func _fill_exchanges()->void:
	_clear(exchange_box)
	var shown:=0
	for pact:Dictionary in Pacts.pacts("",false):
		var active:=String(pact.status)=="active"
		if not active and int(pact.get("ended",0))<int(GameState.elapsed_days)-730:continue
		var tone:=Tokens.GREEN if active else Tokens.RULE_STRONG
		var item:=_row("Exchange_"+String(pact.id),Icons.domain_texture("wealth",tone),tone,"%s: %s, for %s." % [name_of(String(pact.civ)),Pacts.short_words(pact.terms),Pacts.span_words(pact.terms)],
			"%s. %d of %d portions carried." % [Pacts.next_words(pact),int(pact.done),int(pact.terms.portions)])
		var inner:=item.get_meta("stack") as VBoxContainer
		for entry:Dictionary in (pact.get("log",[]) as Array).slice(0,3):
			var line:=_label("%s · %s" % [when(int(entry.get("d",0))),first_sentence(String(entry.get("n","")))],"small",Tokens.INK_MUTED)
			line.name="ExchangeHistory";line.tooltip_text=String(entry.get("n",""));line.mouse_filter=MOUSE_FILTER_PASS;inner.add_child(line)
		if active:
			var end:=_button("End this exchange");end.name="EndExchange_"+String(pact.id)
			end.tooltip_text="Ending it while they keep their side is a broken word, and they will remember it."
			end.pressed.connect(end_exchange.bind(String(pact.id)))
			inner.add_child(end)
		exchange_box.add_child(item);shown+=1
	if shown==0:exchange_box.add_child(_quiet("No goods pass between you and another people on a schedule. Agree one in talk with their ruler."))

func end_exchange(pact_id:String)->Dictionary:
	var result:=Pacts.cancel(pact_id,"player")
	outcome.text=String(result.get("error","The exchange is ended. Their traders will not come again."));outcome.visible=true
	refresh(true)
	return result

func _fill_ledger(state:Dictionary)->void:
	_clear(ledger_box)
	var history:Array=state.get("history",[])
	if history.is_empty():ledger_box.add_child(_quiet("Nothing has passed between you and other peoples yet."));return
	for item:Dictionary in history.slice(0,LEDGER_SHOWN):
		var entry:=VBoxContainer.new();entry.name="Dealing";entry.add_theme_constant_override("separation",2);ledger_box.add_child(entry)
		var date:=_kicker(when(int(item.get("day",0))),Tokens.GOLD);date.name="When";entry.add_child(date)
		var full:=plain(String(item.get("text","")))
		var line:=_voice(first_sentence(full),16,Tokens.BODY);line.tooltip_text=full;line.mouse_filter=MOUSE_FILTER_PASS
		entry.add_child(line)
