extends HBoxContainer
## HOI4's ALERTS, for our fighters: a row of small marks under the clock, at
## the map's top left. Each mark is a glyph on paper with a count beside it:
## red when men are starving, ready to break, or a feud is hot; amber for
## what wants seeing to (gear short, a band under half its men). A pointer
## over a mark lists who and how, with the same numbers the army bar and the
## Warriors screen show. Only what is known at home counts (a band far off
## counts by its runner's last word, as on the army bar). War itself is told
## here too, instead of stopping time: a band coming at us, a battle being
## fought, a battle just fought. A click opens the War screen. Nothing shows
## while nothing is wrong.

const T:=preload("res://scripts/hud/hud_tokens.gd")
const Icons:=preload("res://scripts/resource_icons.gd")
const BarModel:=preload("res://scripts/hud/army_bar_model.gd")
const ArmyMarks:=preload("res://scripts/hud/army_marks.gd")
const Ledger:=preload("res://scripts/hud/war_ledger_model.gd")
const Rations:=preload("res://scripts/field_rations.gd")
const REFRESH_SECONDS:=1.0
## A band under this share of its full strength is under strength.
const UNDER_STRENGTH:=0.5
## A band's will under this is ready to break: within a tenth of the one
## break line (army_lines.gd).
const LOW_WILL:=preload("res://scripts/hud/army_bar_model.gd").NEAR_BREAK
## A battle stays under the clock this many days after it is fought.
const RECENT_DAYS:=10
const RED:=Color("#a8463a")
const AMBER:=Color("#a8782a")

var clock:=REFRESH_SECONDS
var signature:=""
## For tests: the alerts last shown.
var shown:Array[Dictionary]=[]
## Bands hungry or ready to break: the red badge on the rail's Warriors
## button, which shows even while a dock covers this row (-1: not yet set).
var urgent:=-1


## What will not wait: a band coming at us, a battle being fought, bands
## hungry in the field or ready to break. Hot feuds are a state of things,
## not an interruption.
static func urgent_count(list:Array)->int:
	var count:=0
	for alert:Dictionary in list:
		if String(alert.id) in ["attack","battle","hungry","will"] and String(alert.tone)=="red": count+=int(alert.count)
	return count


## A band coming at us: "The Reedbank raiders toward Ashford · about 40 ·
## here in 6 days".
static func threat_line(threat:Dictionary,today:int)->String:
	var place:=String(threat.get("target_region_name",""))
	if place=="": place=String(GameState.settlement_name) if GameState.settlement_name!="" else "us"
	var days:=int(threat.get("deadline_day",today))-today
	var size:=int(threat.get("estimated_strength",0))
	return "%s toward %s%s · %s" % [String(threat.get("source_name","A band we cannot name")),place,(" · about %d" % size) if size>0 else "",("here in %s" % Ledger.span_words(days)) if days>0 else "here now"]


## A battle being fought: "At Ashford · day 3 · 34 of ours against 40".
static func battle_line(engagement:Dictionary)->String:
	var threat:Dictionary=engagement.get("threat",{}) if engagement.get("threat") is Dictionary else {}
	var place:=String(threat.get("target_region_name",""))
	var home:=String(engagement.get("home_side","defender"))
	var enemy:="attacker" if home=="defender" else "defender"
	var ours:Dictionary=engagement.get(home,{}) if engagement.get(home) is Dictionary else {}
	var theirs:Dictionary=engagement.get(enemy,{}) if engagement.get(enemy) is Dictionary else {}
	return "%s · day %d · %d of ours against %d" % [("At "+place) if place!="" else "In the field",maxi(1,int(engagement.get("day_count",0))),int(ours.get("troops",0)),int(theirs.get("troops",0))]


## A battle just fought, from our side: "Won at Ashford · the raiders broke".
static func fought_line(record:Dictionary)->String:
	var home:=String(record.get("home_side",""))
	var outcome:=String(record.get("outcome",""))
	var word:="Fought"
	if outcome==home+"_victory": word="Won"
	elif outcome.ends_with("_victory"): word="Lost"
	elif outcome.ends_with("_retreat"): word="Pulled back" if outcome.begins_with(home) else "Drove them off"
	var threat:Dictionary=record.get("threat",{}) if record.get("threat") is Dictionary else {}
	var place:=String(threat.get("target_region_name",record.get("target_region_name","")))
	var said:=String(record.get("message",""))
	return "%s%s%s" % [word,(" at "+place) if place!="" else "",(" · "+said.trim_suffix(".")) if said!="" and said.length()<=90 else ""]


## What is wrong with our fighters, worst first:
## [{id, glyph (a command glyph), or war / logistics (a war or logistics
## glyph instead), tone ("red" or "amber"), count, title, lines, page}].
## page: the Warriors page to open.
static func alerts(mc:Node=null)->Array[Dictionary]:
	var hungry:=PackedStringArray(); var breaking:=PackedStringArray(); var gear:=PackedStringArray(); var thin:=PackedStringArray()
	var broken:=false
	if mc==null: mc=MilitaryCampaign
	if mc!=null and WorldSimulation.world!=null:
		for army_variant in mc.field_armies:
			if not army_variant is Dictionary: continue
			var army:Dictionary=army_variant
			if int(army.get("troops",0))<=0 or bool(army.get("embarked",false)): continue
			var card:=BarModel.army_card(mc,army)
			if bool(card.get("unknown",false)): continue
			var title:=String(card.title)
			# Hunger is known at home the day it starts (the war leader sends
			# word, court_war_orders), however far off the band is.
			if Rations.is_hungry(army) or String(card.supply_state)=="starving":
				hungry.append("%s · %d%% fed" % [title,roundi(float(card.supply)*100.0)])
			if float(card.will)<LOW_WILL:
				breaking.append("%s · will %d%%" % [title,roundi(float(card.will)*100.0)])
				if float(card.will)<ArmyMarks.BROKEN_MORALE: broken=true
			var kit:Dictionary=card.get("gear_detail",{})
			if float(card.gear)<0.999 and int(kit.get("required",0))>0:
				gear.append("%s · %d of %d armed" % [title,int(kit.get("issued",0)),int(kit.get("required",0))])
			if float(card.men)<float(card.full)*UNDER_STRENGTH:
				thin.append("%s · %d of %d men" % [title,int(card.men),int(card.full)])
	var hot:=PackedStringArray()
	for e:Dictionary in Ledger.entries():
		if String(e.kind)!="ended" and bool(e.get("hot",false)): hot.append("%s · %s" % [String(e.name),Ledger.subtitle(e)])
	# War comes to us, and battles: told here; nothing stops time for them.
	var coming:=PackedStringArray(); var fighting:=PackedStringArray(); var fought:=PackedStringArray()
	if mc!=null and WorldSimulation.state!=null:
		var today:=int(WorldSimulation.state.elapsed_days)
		var threat:Dictionary=mc.active_threat
		if not threat.is_empty() and String(threat.get("campaign_mode","defensive"))!="offensive": coming.append(threat_line(threat,today))
		# Their bands the war council has seen marching on a town of ours.
		var council:GDScript=load("res://scripts/war_council.gd")
		for band:Dictionary in council.call("incoming"): coming.append(threat_line(band,today))
		for engagement_variant in mc.own_engagements.values():
			if engagement_variant is Dictionary and not (engagement_variant as Dictionary).is_empty(): fighting.append(battle_line(engagement_variant))
		# Our home besieged: told while it lasts (it is lost only if the ruler yields it).
		var siege:Dictionary=mc.active_siege
		if String(siege.get("mode",""))=="defensive":
			var home:=String((siege.get("home_city",{}) as Dictionary).get("name","our home"))
			fighting.append("%s besieged · day %d · yours unless you yield it" % [home,maxi(1,today-int(siege.get("start_day",today)))])
		for record_variant in mc.battle_history:
			if not record_variant is Dictionary: continue
			if today-int((record_variant as Dictionary).get("day",-100000))>RECENT_DAYS: break
			fought.append(fought_line(record_variant))
	var out:Array[Dictionary]=[]
	if not coming.is_empty(): out.append({"id":"attack","war":"band","tone":"red","count":coming.size(),"title":"Coming at us","lines":coming,"page":"wars"})
	if not fighting.is_empty(): out.append({"id":"battle","war":"feud","tone":"red","count":fighting.size(),"title":"Fighting now","lines":fighting,"page":"wars"})
	if not hungry.is_empty(): out.append({"id":"hungry","logistics":"hungry","tone":"red","count":hungry.size(),"title":"Hungry in the field","lines":hungry,"page":"support"})
	if not breaking.is_empty(): out.append({"id":"will","glyph":"will","tone":"red" if broken else "amber","count":breaking.size(),"title":"Ready to break","lines":breaking,"page":"forces"})
	if not hot.is_empty(): out.append({"id":"feud","war":"feud","tone":"red","count":hot.size(),"title":"Hot feuds","lines":hot,"page":"wars"})
	if not gear.is_empty(): out.append({"id":"gear","glyph":"gear","tone":"amber","count":gear.size(),"title":"Short of gear","lines":gear,"page":"support"})
	if not thin.is_empty(): out.append({"id":"men","glyph":"men","tone":"amber","count":thin.size(),"title":"Under strength","lines":thin,"page":"recruitment"})
	if not fought.is_empty(): out.append({"id":"fought","war":"feud","tone":"amber","count":fought.size(),"title":"Battles just fought","lines":fought,"page":"wars"})
	return out


## The pointer's words: the title, then one line per band or people, then
## where a click goes.
static func tip(alert:Dictionary)->String:
	var page:="the War screen"
	return "%s\n%s\nClick to open %s." % [String(alert.title),"\n".join(alert.lines as PackedStringArray),page]


func _ready()->void:
	name="ArmyAlerts"
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_theme_constant_override("separation",6)


func _process(delta:float)->void:
	clock+=delta
	if clock<REFRESH_SECONDS: return
	clock=0.0
	refresh()


func refresh()->void:
	var next:=alerts()
	var pressing:=urgent_count(next)
	if pressing!=urgent:
		urgent=pressing
		var hud:=get_parent()
		if hud!=null and hud.has_method("_set_badge"): hud.call("_set_badge","military",str(pressing) if pressing>0 else "",T.RED)
	var words:=str(next)
	if words==signature: return
	signature=words
	shown=next
	for child in get_children(): remove_child(child);child.queue_free()
	for alert:Dictionary in next:
		var mark:=AlertMark.new()
		mark.setup(alert)
		add_child(mark)


## One alert: a glyph on a paper tile rimmed in its tone, its count on a tab.
class AlertMark extends Control:
	const T:=preload("res://scripts/hud/hud_tokens.gd")
	const Icons:=preload("res://scripts/resource_icons.gd")
	const RED:=Color("#a8463a")
	const AMBER:=Color("#a8782a")
	var alert:Dictionary={}
	var texture:Texture2D
	var hover:=false

	func setup(next:Dictionary)->void:
		alert=next
		var tone:=RED if String(next.tone)=="red" else AMBER
		if next.has("war"): texture=Icons.war_texture(String(next.war),tone,64)
		elif next.has("logistics"): texture=Icons.logistics_texture(String(next.logistics),tone.darkened(0.15),64)
		else: texture=Icons.command_texture(String(next.glyph),tone.darkened(0.15),64)
		name="Alert_%s" % String(next.id)
		tooltip_text=preload("res://scripts/hud/army_alerts.gd").tip(next)
		custom_minimum_size=Vector2(_width(),40)
		mouse_filter=Control.MOUSE_FILTER_STOP
		mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
		mouse_entered.connect(func()->void: hover=true;queue_redraw())
		mouse_exited.connect(func()->void: hover=false;queue_redraw())

	func _width()->float:
		var text:=str(int(alert.get("count",0)))
		return 40.0+T.font("ui_strong").get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,15).x+10.0

	func _gui_input(event:InputEvent)->void:
		if event is InputEventMouseButton and (event as InputEventMouseButton).pressed and (event as InputEventMouseButton).button_index==MOUSE_BUTTON_LEFT:
			MilitaryCampaign.open_roster("army",false,String(alert.get("page","forces")))
			accept_event()

	func _draw()->void:
		var tone:=RED if String(alert.get("tone",""))=="red" else AMBER
		var box:=Rect2(Vector2.ZERO,size)
		draw_rect(Rect2(box.position+Vector2(0,2),box.size),Color(0,0,0,0.18))
		draw_rect(box,T.PAPER_RAISED if not hover else T.PAPER)
		draw_rect(Rect2(box.position,Vector2(4,box.size.y)),tone)
		draw_rect(box,Color(tone,0.9),false,1.5)
		if texture: draw_texture_rect(texture,Rect2(Vector2(8,6),Vector2(28,28)),false)
		var font:=T.font("ui_strong")
		draw_string(font,Vector2(40,26),str(int(alert.get("count",0))),HORIZONTAL_ALIGNMENT_LEFT,-1,15,tone.darkened(0.25))
