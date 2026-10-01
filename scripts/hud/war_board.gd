extends VBoxContainer
## THE WAR SCREEN: grand strategy, one page, no tabs. The ruler decides three
## things and the war leader and the generals do the rest (who goes, the
## road, the camps, the pace, the fight):
##   the army   how many of the people serve, as a share that reads the same
##              for 120 people and a billion (army_levy_law.gd). The war
##              leader calls up, drills and arms to that share, and sends the
##              surplus home;
##   enemies    one row per people at feud or war with us: the dead on each
##              side, what is happening now, and a stance (war_loop.gd order):
##              Leave them be, Defend, Punish (burn their stores), Take a town
##              of theirs (the war leader marches on it: army_orders.gd), Seek
##              peace (messengers), and where a feud's blood price would end
##              it, Pay;
##   leaders    the war leader and the generals: who they are, how they are
##              rated, and what they are doing now.
## Nothing here moves a band or draws a line: the map shows what happens.

signal close_wanted

const T:=preload("res://scripts/hud/hud_tokens.gd")
const Law:=preload("res://scripts/army_levy_law.gd")
const Ledger:=preload("res://scripts/hud/war_ledger_model.gd")
const LedgerMarks:=preload("res://scripts/hud/war_ledger_marks.gd")
const Identity:=preload("res://scripts/city_map_identity.gd")
const WarLoop:=preload("res://scripts/war_loop.gd")
const Orders:=preload("res://scripts/army_orders.gd")
const Commands:=preload("res://scripts/leader_commands.gd")
const Portrait:=preload("res://scripts/hud/person_portrait.gd")
const EraWords:=preload("res://scripts/hud/era_words.gd")
const Icons:=preload("res://scripts/resource_icons.gd")
const BarModel:=preload("res://scripts/hud/army_bar_model.gd")
const Strips:=preload("res://scripts/hud/force_strips.gd")
const GeneralRecord:=preload("res://scripts/general_record.gd")
const REFRESH_SECONDS:=1.0
## The stances, in the order the row shows them: [id, label, war_loop objective, tip].
const STANCES:=[
	["leave","Leave them be","war_let","Bury the dead and let it pass this year. Their grudge cools, unless they are the kind to come back bolder."],
	["defend","Defend","war_guard","Keep a watch on the approaches for half a year. Their raiders meet our fighters, not our fields."],
	["punish","Punish","war_burn","Send a band to burn their stores. If no one knows where they live, they track the raiders home first."],
	["take","Take a town","","March on a town of theirs and take it. The war leader chooses who goes and how; you choose the town."],
	["peace","Seek peace","war_parley","Send two messengers to ask for an end to it."],
]

var army_box:VBoxContainer
var enemy_box:VBoxContainer
var leader_box:VBoxContainer
var feedback:Label
var clock:=0.0
## Each section's last signature, and how long a rebuild has waited on the
## ruler's hand (seconds).
var signatures:={}
var waited:={}
## A section under the pointer waits this long for the pointer to leave
## before its numbers are read again; never while one of its menus is open
## or a button is held.
const HOVER_HOLD_SECONDS:=5.0


func setup(_block:Dictionary={})->void:
	name="WarBoard"
	size_flags_horizontal=Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation",14)
	army_box=_section("The army")
	feedback=_line("",15,T.GOLD_TEXT,true);feedback.name="Said";feedback.visible=false;add_child(feedback)
	enemy_box=_section("Our enemies")
	leader_box=_section("Our leaders")
	refresh(true)


func _process(delta:float)->void:
	clock+=delta
	if clock<REFRESH_SECONDS:return
	clock=0.0
	refresh()


## Each section is read again only when what it shows has changed, and not
## under the ruler's hand: a menu of it open, a button held, or the pointer
## on it (for a few seconds). After the ruler's own word (force) all three.
func refresh(force:=false)->void:
	var reading:=Law.reading(MilitaryCampaign)
	var glance:=strength(MilitaryCampaign)
	_rebuild("army",army_box,str([reading,glance]),force,func()->void:_build_army(reading,glance))
	var entries:=Ledger.entries().filter(func(e:Dictionary)->bool:return String(e.kind)!="ended")
	_rebuild("enemies",enemy_box,str(entries.map(func(e:Dictionary)->Array:
		var front:Dictionary=WarLoop.front(String(e.civ_id))
		return [e.civ_id,e.kind,e.hot,e.our_dead,e.their_dead,e.get("quiet",0),front.get("stance",""),front.get("general",""),e.get("strength",1.0),now_words(e)])),force,func()->void:_build_enemies(entries))
	var commands:=Commands.commands(MilitaryCampaign)
	_rebuild("leaders",leader_box,str(commands.map(func(c:Dictionary)->Array:return [c.id,c.bands,c.men,c.full,c.hungry,snappedf(float(c.will),0.05),snappedf(float(c.supply),0.05)])),force,func()->void:_build_leaders(commands))


func _rebuild(key:String,box:Control,next:String,force:bool,build:Callable)->void:
	if not force and next==String(signatures.get(key,"")):
		waited.erase(key)
		return
	if not force and _in_use(box,float(waited.get(key,0.0))):
		waited[key]=float(waited.get(key,0.0))+REFRESH_SECONDS
		return
	signatures[key]=next
	waited.erase(key)
	build.call()


## Whether the ruler is using a section: one of its menus open or a button
## held on it always; the pointer resting on it, for HOVER_HOLD_SECONDS.
func _in_use(box:Control,waited_seconds:float)->bool:
	if box==null or not box.is_visible_in_tree():return false
	for node in box.find_children("*","",true,false):
		if node is MenuButton and (node as MenuButton).get_popup().visible:return true
		if node is OptionButton and (node as OptionButton).get_popup().visible:return true
	if not box.get_global_rect().has_point(box.get_global_mouse_position()):return false
	return Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or waited_seconds<HOVER_HOLD_SECONDS


# --- The army -------------------------------------------------------------

func _build_army(reading:Dictionary,glance:Dictionary)->void:
	_clear(army_box)
	var panel:=_panel(army_box,"Army")
	var column:=VBoxContainer.new();column.add_theme_constant_override("separation",8);panel.add_child(column)
	var head:=HBoxContainer.new();head.add_theme_constant_override("separation",18);column.add_child(head)
	var serving:=_number(head,EraWords.grouped(int(reading.now)),"under arms")
	serving.tooltip_text="Everyone under arms: fighters, those in drill, recruits waiting and the hurt."
	if int(reading.target)>=0:
		var gap:=int(reading.gap)
		_number(head,EraWords.grouped(int(reading.target)),"to keep"+((" · %s more to call up" % EraWords.grouped(gap)) if gap>0 else (" · %s too many" % EraWords.grouped(-gap) if gap<0 else "")))
	if float(glance.armed)<0.999 and int(reading.now)>0:_number(head,"%d%%" % roundi(float(glance.armed)*100.0),"armed")
	if float(glance.fed)>=0.0:_number(head,"%d%%" % roundi(float(glance.fed)*100.0),"fed in the field")
	# HOI4's manpower bar: those ready, in drill and waiting, against the
	# share the war leader keeps (the tick).
	var bar:=StrengthBar.new();bar.name="Strength";bar.parts=glance;bar.target=int(reading.target);bar.custom_minimum_size=Vector2(0,16)
	var words:=strength_words(glance,int(reading.now),int(reading.target))
	bar.tooltip_text=words;column.add_child(bar)
	column.add_child(_line(words,13,T.INK_MUTED,true))
	if int(glance.get("watch",0))>0:
		var watch:=_line("Apart from the army, %s keep the watch at home." % EraWords.grouped(int(glance.watch)),13,T.INK_MUTED,true);watch.name="Watch"
		watch.tooltip_text="Home defence is not the army: it is kept by those set to defence work, and no share counts it, calls it up or sends it home."
		column.add_child(watch)
	var pick:=HBoxContainer.new();pick.name="Levels";pick.add_theme_constant_override("separation",6);column.add_child(pick)
	for entry:Dictionary in Law.LEVELS:
		var id:=String(entry.id)
		var button:=Button.new();button.name="Level_%s" % id;button.toggle_mode=true;button.focus_mode=Control.FOCUS_NONE
		button.text="%s · %d%%" % [Law.level_name(id),roundi(float(entry.share)*100.0)]
		button.set_pressed_no_signal(id==String(reading.level))
		button.tooltip_text=Law.cost_words(id,int(reading.population),int(reading.able))+".\nThe war leader calls up, drills and arms them, and sends home any more than that. Every person serving is one fewer at work."
		button.pressed.connect(func()->void:_choose_level(id))
		pick.add_child(button)
	var said:=("Choose how many of our people serve." if String(reading.level)=="" else
		"%s: %s" % [Law.level_name(String(reading.level)),Law.cost_words(String(reading.level),int(reading.population),int(reading.able))])
	var line:=_line(said,14,T.INK_MUTED,true);line.tooltip_text="The war leader keeps the army at the share you choose: calling up, drilling and arming, and sending home any surplus."
	column.add_child(line)


func _choose_level(id:String)->void:
	var result:=Law.choose(MilitaryCampaign,id)
	_say(String(result.get("said",result.get("error",""))) if String(result.get("said",""))!="" else "%s. The war leader will keep the army at that size." % Law.level_name(id))
	refresh(true)


# --- Our enemies ----------------------------------------------------------

func _build_enemies(entries:Array)->void:
	_clear(enemy_box)
	if entries.is_empty():
		var calm:=_panel(enemy_box,"Calm")
		calm.add_child(_line("At peace: no feud or war with anyone.",14,T.INK_MUTED,true))
		return
	for e:Dictionary in entries:enemy_box.add_child(_enemy_row(e))


func _enemy_row(e:Dictionary)->Control:
	var civ_id:=String(e.civ_id)
	var panel:=PanelContainer.new();panel.name="Enemy_%s" % civ_id
	panel.add_theme_stylebox_override("panel",_skin(T.PAPER_RAISED,LedgerMarks.chip_tone(Ledger.state_word(e)),12,3))
	var column:=VBoxContainer.new();column.add_theme_constant_override("separation",8);panel.add_child(column)
	var head:=HBoxContainer.new();head.add_theme_constant_override("separation",12);column.add_child(head)
	var emblem:=TextureRect.new();emblem.texture=Identity.emblem(civ_id);emblem.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;emblem.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;emblem.custom_minimum_size=Vector2(40,40);head.add_child(emblem)
	var words:=VBoxContainer.new();words.add_theme_constant_override("separation",0);words.size_flags_horizontal=Control.SIZE_EXPAND_FILL;head.add_child(words)
	var title:=Label.new();title.text=String(e.name);T.text(title,"voice",T.INK);words.add_child(title)
	words.add_child(_line(Ledger.subtitle(e),13,T.INK_MUTED))
	var dead:=DeadStrip.new();dead.ours=int(e.our_dead);dead.theirs=int(e.their_dead);dead.custom_minimum_size=Vector2(220,26);dead.tooltip_text="The dead of it all told: %d of ours, %d of theirs." % [int(e.our_dead),int(e.their_dead)];head.add_child(dead)
	var chip:=Chip.new();chip.word=Ledger.state_word(e);head.add_child(chip)
	# HOI4's read of who is stronger: our share of the strength against theirs.
	var odds:=Strips.OddsBar.new();odds.name="Odds";column.add_child(odds)
	odds.set_odds(Ledger.odds(e),Ledger.odds_words(e))
	odds.tooltip_text="Their strength against ours, by the war leader's reckoning: people, warriors and readiness on one scale.
Worn by the fighting: we are %d%% worn, they are %d%%." % [roundi(float(e.get("our_worn",0.0))*100.0),roundi(float(e.get("their_worn",0.0))*100.0)]
	var now:=_line("Now: "+now_words(e),14,T.INK,true);now.tooltip_text=now_details(e);column.add_child(now)
	var stances:=HBoxContainer.new();stances.name="Stances";stances.add_theme_constant_override("separation",6);column.add_child(stances)
	var chosen:=String(WarLoop.front(civ_id).get("stance",""))
	for spec:Array in STANCES:
		var id:=String(spec[0])
		if id=="take":
			var take:=_take_button(civ_id,chosen=="take");stances.add_child(take);continue
		var button:=Button.new();button.name="Stance_%s" % id;button.text=String(spec[1]);button.toggle_mode=true;button.focus_mode=Control.FOCUS_NONE
		button.set_pressed_no_signal(chosen==id);button.tooltip_text=String(spec[3])
		button.pressed.connect(func()->void:_stance(civ_id,id,String(spec[2])))
		stances.add_child(button)
	if String(e.kind)=="feud" and float(e.get("blood_price",0.0))>0.0:
		var pay:=Button.new();pay.name="Stance_pay";pay.text="Pay %s food to end it" % EraWords.grouped(roundi(float(e.blood_price)));pay.focus_mode=Control.FOCUS_NONE
		pay.tooltip_text="A blood price for the dead of theirs ends the feud at once; their raiders will not come for it."
		pay.pressed.connect(func()->void:_stance(civ_id,"pay","war_price"))
		stances.add_child(pay)
	column.add_child(_led_by(civ_id))
	return panel


## Who leads against this people: the war leader's choice, or a general the
## ruler names (WarLoop.front(civ_id).general: a figure id, "" for the war
## leader's choice). The war council gives that general the bands it sends.
func _led_by(civ_id:String)->Control:
	var row:=HBoxContainer.new();row.name="LedBy";row.add_theme_constant_override("separation",8)
	var generals:=Commands.leaders(MilitaryCampaign).filter(func(l:Dictionary)->bool:return String(l.id)!=Commands.WAR_LEADER and String(l.get("status",""))=="living")
	var chosen:=String(WarLoop.front(civ_id).get("general",""))
	row.add_child(_line("Led by",13,T.INK_MUTED))
	if generals.is_empty():
		row.add_child(_line("the war leader · no general has come forward yet",13,T.INK))
		return row
	var pick:=OptionButton.new();pick.name="General";pick.focus_mode=Control.FOCUS_NONE
	pick.add_item("The war leader's choice");pick.set_item_metadata(0,"")
	var selected:=0
	for general:Dictionary in generals:
		var commander:Dictionary=general.get("commander",{})
		var levers:=GeneralRecord.levers(commander)
		pick.add_item("%s · fight %+d%%, march %+d%%" % [String(general.name),roundi(float(levers.fight)*100.0),roundi(float(levers.pace)*100.0)])
		pick.set_item_metadata(pick.item_count-1,String(general.id))
		if String(general.id)==chosen:selected=pick.item_count-1
	pick.select(selected)
	pick.tooltip_text="The general who leads what we send against them. The war leader's choice: whoever the war leader thinks best for the work."
	pick.item_selected.connect(func(index:int)->void:_lead(civ_id,String(pick.get_item_metadata(index)),pick.get_item_text(index).get_slice(" · ",0)))
	row.add_child(pick)
	return row


func _lead(civ_id:String,general:String,name_words:String)->void:
	WarLoop.front(civ_id)["general"]=general
	_say(("%s leads against them from now on." % name_words) if general!="" else "The war leader chooses who leads against them.")
	refresh(true)


## The army at a glance, the watch at home apart: {ready (fighters at home
## beyond the watch, in the field and holding towns), drill, drill_days,
## waiting (recruits waiting to drill), away (hurt, scattered or taken),
## watch (keeping the watch at home), armed (0..1: gear issued of gear
## wanted), fed (0..1 of those out by the bars' own measure; -1 when nobody
## is out)}.
static func strength(mc:Node)->Dictionary:
	var ledger:Dictionary=mc.personnel_ledger()
	var watch:=Law.watch(mc)
	var formations:Array=(mc.home_army.get("formations",[]) as Array).duplicate()
	var out:=0
	var fed:=0.0
	for army_variant in mc.field_armies:
		if not army_variant is Dictionary or int((army_variant as Dictionary).get("troops",0))<=0:continue
		var army:Dictionary=army_variant
		formations.append_array(army.get("formations",[]))
		var card:=BarModel.army_card(mc,army)
		if bool(card.get("unknown",false)):continue
		out+=int(card.men);fed+=float(card.men)*clampf(float(card.get("supply",1.0)),0.0,1.0)
	var drill:=BarModel.drill_card(mc)
	return {"ready":maxi(0,int(ledger.home)-int(watch.home))+int(ledger.field)+int(ledger.occupation),"drill":maxi(0,int(ledger.training)-int(watch.drill)),"drill_days":int(drill.get("days",0)),
		"waiting":int(ledger.recruits),"away":int(ledger.recovering)+int(ledger.get("missing",0)),"watch":int(watch.kept),
		"armed":float(BarModel.gear_of(formations,mc).share),"fed":snappedf(fed/float(out),0.01) if out>0 else -1.0}


## The bar in words: "327 ready · 85 in drill, about 40 days · 12 waiting to
## drill · 9 hurt or away · 188 to call up".
static func strength_words(glance:Dictionary,now:int,target:int)->String:
	var parts:=PackedStringArray(["%s ready" % EraWords.grouped(int(glance.ready))])
	if int(glance.drill)>0:parts.append("%s in drill%s" % [EraWords.grouped(int(glance.drill)),(", about %d days" % int(glance.drill_days)) if int(glance.drill_days)>0 else ""])
	if int(glance.waiting)>0:parts.append("%s waiting to drill" % EraWords.grouped(int(glance.waiting)))
	if int(glance.get("away",0))>0:parts.append("%s hurt or away" % EraWords.grouped(int(glance.away)))
	if target>now:parts.append("%s to call up" % EraWords.grouped(target-now))
	elif target>=0 and now>target:parts.append("%s above the share" % EraWords.grouped(now-target))
	return " · ".join(parts)


## What is happening with this people now, in a few words (the details in
## now_details): the war council's own reading (war_council.gd
## operation_words): our band out and how it stands ("Rovik besieges
## Oakford, day 12: odds 3 to 2, fed 80%"), their band coming, the trackers
## or messengers out, or why the war leader waits.
static func now_words(e:Dictionary)->String:
	var civ_id:=String(e.get("civ_id",""))
	var council:GDScript=load("res://scripts/war_council.gd")
	var said:=String(council.call("operation_words",civ_id)) if civ_id!="" else ""
	if said!="":return said
	var bands:Array=e.get("bands",[])
	if not bands.is_empty():
		var b:Dictionary=bands[0]
		return "%s %s%s" % [String(b.name),String(b.where),(" and %d more" % (bands.size()-1)) if bands.size()>1 else ""]
	if bool(e.get("hot",false)):return "nobody of ours is out; their raiders may come"
	return "quiet for %s" % Ledger.span_words(int(e.get("quiet",0)))


## Everything happening with this people now, for the pointer: the council's
## account (the band, the odds it set out at, how it is fed, the stance in
## force), our other bands at their towns, and their last raid.
static func now_details(e:Dictionary)->String:
	var civ_id:=String(e.get("civ_id",""))
	var parts:=PackedStringArray()
	var council:GDScript=load("res://scripts/war_council.gd")
	var said:=String(council.call("operation_details",civ_id)).trim_suffix(".") if civ_id!="" else ""
	if said!="":parts.append(said)
	for b:Dictionary in e.get("bands",[]):parts.append("%s · %s · %s" % [String(b.name),EraWords.grouped(int(b.troops)),String(b.where)])
	var raid:Dictionary=e.get("last_raid",{})
	if not raid.is_empty() and int(raid.get("days_ago",9999))<=120:parts.append("their last raid %s ago" % Ledger.span_words(int(raid.days_ago)))
	if parts.is_empty():
		if bool(e.get("hot",false)):parts.append("no one of ours is out against them; their raiders may come")
		else:parts.append("quiet for %s" % Ledger.span_words(int(e.get("quiet",0))))
	return "; ".join(parts)+"."


func _take_button(civ_id:String,chosen:bool)->Control:
	var pick:=MenuButton.new();pick.name="Stance_take";pick.text="Take a town ▾";pick.flat=false;pick.focus_mode=Control.FOCUS_NONE
	pick.tooltip_text=String(STANCES[3][3])+" The war leader gathers until the odds are 3 to 2, feeds the march or waits, then lays siege or storms."
	if chosen:pick.add_theme_stylebox_override("normal",T.button_pressed_style())
	var popup:=pick.get_popup()
	var council:GDScript=load("res://scripts/war_council.gd")
	var towns:Array=council.call("known_towns",civ_id)
	if towns.is_empty():
		pick.disabled=true;pick.tooltip_text="We know of no town of theirs yet: scouts find their towns."
		return pick
	var aim:Dictionary=WarLoop.front(civ_id).get("take",{}) if WarLoop.front(civ_id).get("take") is Dictionary else {}
	var preview:=towns.slice(0,8)
	for i in preview.size():
		var p:Dictionary=preview[i]
		var look:=Orders.preview(Orders.HOME,"attack",{"type":"place","place":p})
		var days:=int(look.get("days",0))
		var odds:Dictionary=look.get("odds",{}) if look.get("odds") is Dictionary else {}
		var marked:=" ✓" if String(aim.get("city_id",""))==String(p.city_id) else ""
		popup.add_item("%s%s%s%s" % [Orders.place_name(p),(" · %d days" % days) if days>0 else "",(" · odds "+Orders.odds_short(float(odds.odds),bool(odds.ours))) if not odds.is_empty() else "",marked],i)
		popup.set_item_tooltip(i,"\n".join(look.get("lines",[])))
	popup.id_pressed.connect(func(index:int)->void:_take(civ_id,preview[index]))
	return pick


## A stance is the god's word to the war council (war_council.gd order): it
## acts on it at once with the real army, says what it did or why it waits,
## and keeps to it. Pay settles the feud with a blood price (war_loop.gd).
func _stance(civ_id:String,id:String,objective:String)->void:
	# One "Go anyway" at most, and only for the latest word.
	for child in get_children():
		if String(child.name).begins_with("GoAnyway"):remove_child(child);child.queue_free()
	if id=="pay":
		_say(WarLoop.order(civ_id,objective))
		refresh(true)
		return
	var council:GDScript=load("res://scripts/war_council.gd")
	var label:=""
	for spec:Array in STANCES:
		if String(spec[0])==id:label=String(spec[1])
	var answer:Dictionary=council.call("order",civ_id,id,{"card":true,"words":"%s: %s" % [WarLoop._name(civ_id),label.to_lower()]})
	_say(String(answer.get("says",answer.get("outcome",""))))
	# The war leader waits for the odds or the road: the god can send them anyway.
	if String(answer.get("verdict","")) in ["object","wait"] and id=="punish":
		var go:=Button.new();go.text="Go anyway";go.name="GoAnyway"
		go.pressed.connect(func()->void:
			go.queue_free()
			var again:Dictionary=council.call("order",civ_id,id,{"insist":true,"card":true,"words":"%s: %s, go anyway" % [WarLoop._name(civ_id),label.to_lower()]})
			_say(String(again.get("says",again.get("outcome",""))))
			refresh(true))
		feedback.add_sibling(go)
	refresh(true)


func _take(civ_id:String,place:Dictionary,insist:=false)->void:
	# One "Go anyway" at most, and only for the latest word.
	for child in get_children():
		if String(child.name).begins_with("GoAnyway"):remove_child(child);child.queue_free()
	var council:GDScript=load("res://scripts/war_council.gd")
	var answer:Dictionary=council.call("order",civ_id,"take",{"place":place,"insist":insist,"card":true,"words":"Take %s%s" % [Orders.place_name(place),", go anyway" if insist else ""]})
	_say(String(answer.get("says",answer.get("outcome",""))))
	if String(answer.get("verdict","")) in ["object","wait"] and not insist:
		var go:=Button.new();go.text="Go anyway";go.name="GoAnyway";go.pressed.connect(func()->void:go.queue_free();_take(civ_id,place,true))
		feedback.add_sibling(go)
	refresh(true)


# --- Our leaders ----------------------------------------------------------

func _build_leaders(commands:Array)->void:
	_clear(leader_box)
	for c:Dictionary in commands:leader_box.add_child(_leader_row(c))
	var name_one:=Button.new();name_one.name="NameGeneral";name_one.text="Name a general";name_one.focus_mode=Control.FOCUS_NONE
	name_one.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN
	name_one.tooltip_text="Raise one of our people to lead bands as a general. The war council gives them work against an enemy; you can name who leads against each people."
	name_one.pressed.connect(_name_general)
	leader_box.add_child(name_one)


func _name_general()->void:
	var result:Dictionary=Commands.commission_general(MilitaryCampaign)
	if result.has("error"):_say(String(result.error));return
	_say(("%s is named a general. %s" if bool(result.get("new",false)) else "%s is free to lead already. %s") % [String(result.name),String(result.get("line",""))])
	refresh(true)


func _leader_row(c:Dictionary)->Control:
	var leader:Dictionary=c.leader
	var panel:=PanelContainer.new();panel.name="Leader_%s" % String(c.id);panel.add_theme_stylebox_override("panel",_skin(T.PAPER_RAISED,T.RULE,8,0))
	var row:=HBoxContainer.new();row.add_theme_constant_override("separation",12);panel.add_child(row)
	var frame:=PanelContainer.new();frame.clip_contents=true;frame.custom_minimum_size=Vector2(44,52);frame.add_theme_stylebox_override("panel",T.flat(T.PAPER_SUNK));row.add_child(frame)
	var face:=TextureRect.new();face.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;face.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
	var key:=String(leader.get("figure_id","")) if String(leader.get("figure_id",""))!="" else String(leader.get("name",""))
	face.texture=Portrait.texture({"name":String(leader.get("name","")),"person_id":absi(key.hash())%997+1});frame.add_child(face)
	var words:=VBoxContainer.new();words.add_theme_constant_override("separation",1);words.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(words)
	var name_label:=_line("%s · %s" % [String(leader.name),String(leader.title).to_lower()],15,T.INK);name_label.add_theme_font_override("font",T.font("ui_strong"));words.add_child(name_label)
	var rated:=skill_words(leader.get("commander",{}))
	if rated!="":words.add_child(_line(rated,13,T.INK_MUTED))
	# What their hand changes, in the engine's numbers, and what they have done.
	var record:=Commands.record(leader)
	var fought:=int(record.get("battles",0))
	if fought>0:words.add_child(_line("Fought %d · won %d · lost %d" % [fought,int(record.get("won",0)),int(record.get("lost",0))],13,T.INK_MUTED))
	var told:=PackedStringArray()
	for said:String in [GeneralRecord.lever_line(leader.get("commander",{}),String(leader.name),float(c.get("men",0))),GeneralRecord.words(record)]:
		if said!="":told.append(said)
	panel.tooltip_text="
".join(told)
	if not (leader.get("commander",{}) as Dictionary).is_empty():
		var pips:=Strips.GeneralPips.new();pips.name="Pips";words.add_child(pips)
		pips.set_commander(leader.get("commander",{}),String(leader.name),String(c.id)==Commands.WAR_LEADER)
	words.add_child(_line(leader_doing(c),13,T.INK))
	if int(c.get("men",0))>0:
		var bars:=CommandBars.new();bars.name="Bars";bars.men=int(c.men);bars.full=int(c.full);bars.will=float(c.will);bars.fed=float(c.supply)
		bars.tooltip_text="Men %d of %d · will %d%% · fed %d%%" % [int(c.men),int(c.full),roundi(float(c.will)*100.0),roundi(float(c.supply)*100.0)]
		words.add_child(bars)
	if String(c.id)==Commands.WAR_LEADER:
		var other:=Button.new();other.name="NameWarLeader";other.text="Name another";other.flat=true;other.focus_mode=Control.FOCUS_NONE
		other.size_flags_vertical=Control.SIZE_SHRINK_CENTER
		other.tooltip_text="The war leader at home is the Marshal among the officials, or the best of the field staff while no one holds that office. Choose the Marshal among the officials."
		other.pressed.connect(_name_war_leader)
		row.add_child(other)
	return panel


## The officials, where the ruler names the Marshal (the war leader at home).
func _name_war_leader()->void:
	var scene:=get_tree().current_scene if is_inside_tree() else null
	var hud:Variant=scene.get("hud") if scene!=null else null
	if hud==null or not hud.has_method("has_provider") or not hud.has_provider("government"):return
	close_wanted.emit()
	hud.open_dock("government",0)


## What a leader is best and worst at, by the skills the engine fights,
## camps and marches with: "Best at holding firm (5/5) · weakest at supply
## (2/5)".
const SKILL_WORDS:={"command":"planning","tactics":"fighting","resolve":"holding firm","logistics":"supply"}
static func skill_words(commander:Dictionary)->String:
	if commander.is_empty():return ""
	var best:="";var worst:="";var high:=-1;var low:=6
	for skill:String in SKILL_WORDS:
		var pips:=Strips.GeneralPips.pips(float(commander.get(skill,0.5)))
		if pips>high:high=pips;best=skill
		if pips<low:low=pips;worst=skill
	if high==low:return "Even in every skill (%d/5)" % high
	return "Best at %s (%d/5) · weakest at %s (%d/5)" % [SKILL_WORDS[best],high,SKILL_WORDS[worst],low]


## What a leader is doing now: their bands and men and where, or "at home".
static func leader_doing(c:Dictionary)->String:
	var bands:=(c.bands as Array).size()
	if bands==0:return "Keeps the watch at home." if String(c.id)==Commands.WAR_LEADER else "Waits at home for a command."
	var places:=PackedStringArray()
	for place in (c.get("places",{}) as Dictionary):places.append(String(place))
	var hungry:=(" · %d hungry" % int(c.hungry)) if int(c.get("hungry",0))>0 else ""
	return "Leads %s men in %d %s · %s%s" % [EraWords.grouped(int(c.men)),bands,"band" if bands==1 else "bands",", ".join(places),hungry]


# --- Pieces ---------------------------------------------------------------

func _say(text:String)->void:
	feedback.text=text
	feedback.visible=text!=""


func _section(title:String)->VBoxContainer:
	var kicker:=_line(title.to_upper(),13,T.INK_MUTED);kicker.add_theme_font_override("font",T.font("ui_strong"));add_child(kicker)
	var box:=VBoxContainer.new();box.add_theme_constant_override("separation",8);add_child(box)
	return box


func _panel(parent:Node,name_hint:String)->PanelContainer:
	var panel:=PanelContainer.new();panel.name=name_hint;panel.add_theme_stylebox_override("panel",_skin(T.PAPER_RAISED,T.RULE,12,0));parent.add_child(panel)
	return panel


func _number(parent:Node,value:String,word:String)->Control:
	var chip:=HBoxContainer.new();chip.add_theme_constant_override("separation",6);chip.mouse_filter=Control.MOUSE_FILTER_PASS;parent.add_child(chip)
	var big:=_line(value,22,T.INK);big.add_theme_font_override("font",T.font("ui_strong"));chip.add_child(big)
	var small:=_line(word,13,T.INK_MUTED);small.size_flags_vertical=Control.SIZE_SHRINK_CENTER;chip.add_child(small)
	return chip


func _clear(box:Node)->void:
	for child in box.get_children():box.remove_child(child);child.queue_free()


static func _skin(bg:Color,border:Color,margin:int,left:int)->StyleBoxFlat:
	var style:=StyleBoxFlat.new();style.bg_color=bg;style.border_color=border;style.set_border_width_all(1)
	if left>0:style.border_width_left=left
	style.set_corner_radius_all(T.RADIUS_CARD);style.set_content_margin_all(margin)
	return style


static func _line(text:String,size:int,color:Color,wrap:=false)->Label:
	var label:=Label.new();label.text=text;label.mouse_filter=Control.MOUSE_FILTER_PASS
	label.add_theme_font_override("font",T.font("ui"));label.add_theme_font_size_override("font_size",maxi(T.MIN_FONT_SIZE,size));label.add_theme_color_override("font_color",color)
	if wrap:label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	return label


## HOI4's manpower bar: ready (green), in drill (amber), waiting, hurt or
## away (rule), against the share kept (the ink tick); over the share, the
## tick falls inside the bar.
class StrengthBar extends Control:
	const T:=preload("res://scripts/hud/hud_tokens.gd")
	var parts:Dictionary={}
	var target:=-1
	func _ready()->void:mouse_filter=Control.MOUSE_FILTER_PASS
	func _draw()->void:
		var whole:=Rect2(Vector2.ZERO,size)
		draw_rect(whole,T.PAPER_SUNK)
		var segments:=[[int(parts.get("ready",0)),T.GREEN],[int(parts.get("drill",0)),T.AMBER],[int(parts.get("waiting",0))+int(parts.get("away",0)),T.RULE_STRONG]]
		var total:=0
		for segment:Array in segments:total+=int(segment[0])
		var scale:=float(maxi(1,maxi(total,target)))
		var x:=0.0
		for segment:Array in segments:
			var width:=size.x*float(segment[0])/scale
			if width>0.0:draw_rect(Rect2(x,0.0,width,size.y),segment[1]);x+=width
		draw_rect(whole,T.RULE,false,1.0)
		if target>0:
			var tick:=clampf(size.x*float(target)/scale,1.0,size.x-1.0)
			draw_line(Vector2(tick,-3.0),Vector2(tick,size.y+3.0),T.INK,2.0)


## A command at a glance, as HOI4's army card: men of full strength, will
## and fed, each a short bar in the army bar's colours.
class CommandBars extends Control:
	const BarModel:=preload("res://scripts/hud/army_bar_model.gd")
	const T:=preload("res://scripts/hud/hud_tokens.gd")
	var men:=0
	var full:=0
	var will:=0.0
	var fed:=0.0
	func _ready()->void:custom_minimum_size=Vector2(240,14);mouse_filter=Control.MOUSE_FILTER_PASS
	func _draw()->void:
		var width:=minf(120.0,(size.x-16.0)/3.0)
		var shares:=[float(men)/maxf(1.0,float(full)),will,fed]
		var inks:=[T.GREEN,BarModel.will_color(will),T.TEAL if fed>=0.75 else (T.AMBER if fed>=0.4 else T.RED)]
		for i in 3:BarModel.draw_bar(self,Rect2(Vector2(float(i)*(width+8.0),2.0),Vector2(width,10.0)),clampf(float(shares[i]),0.0,1.0),inks[i])


## The dead on each side, compact (war_ledger_marks.draw_dead).
class DeadStrip extends Control:
	const Marks:=preload("res://scripts/hud/war_ledger_marks.gd")
	var ours:=0
	var theirs:=0
	func _ready()->void:mouse_filter=Control.MOUSE_FILTER_PASS
	func _draw()->void:Marks.draw_dead(self,Rect2(Vector2.ZERO,size),ours,theirs,true)


## HOT, SIMMERING, WAR (war_ledger_marks.draw_chip).
class Chip extends Control:
	const Marks:=preload("res://scripts/hud/war_ledger_marks.gd")
	var word:=""
	func _ready()->void:
		custom_minimum_size=Vector2(Marks.chip_width(word),28);size_flags_vertical=Control.SIZE_SHRINK_CENTER
	func _draw()->void:Marks.draw_chip(self,Rect2(Vector2(0,0),Vector2(size.x,28)),word)
