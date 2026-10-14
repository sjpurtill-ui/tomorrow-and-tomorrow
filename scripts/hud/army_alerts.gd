extends RefCounted
## WHAT IS WRONG WITH OUR FIGHTERS, AND WAR NEWS THAT STANDS (HOI4's alerts):
## the conditions the one notice stack keeps on screen while they last
## (hud/standing_notices.gd turns each into a row at the top right). Red when
## men are starving, ready to break, or a feud is hot; amber for what wants
## seeing to (gear short, a band under half its men). Every line carries the
## same numbers the army bar and the War screen show. Only what is known at
## home counts (a band far off counts by its runner's last word, as on the
## army bar). War itself is told here too, instead of stopping time: a band
## coming at us, a battle being fought, a battle just fought. Nothing is
## listed while nothing is wrong.

const BarModel:=preload("res://scripts/hud/army_bar_model.gd")
const ArmyMarks:=preload("res://scripts/hud/army_marks.gd")
const Ledger:=preload("res://scripts/hud/war_ledger_model.gd")
const Rations:=preload("res://scripts/field_rations.gd")
## A band under this share of its full strength is under strength.
const UNDER_STRENGTH:=0.5
## A band's will under this is ready to break: within a tenth of the one
## break line (army_lines.gd).
const LOW_WILL:=preload("res://scripts/hud/army_bar_model.gd").NEAR_BREAK
## A battle just fought stays in the stack this many days after it is fought.
const RECENT_DAYS:=10


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
	# Trade turned against us, and trade news, told once (hud/trade_alerts.gd).
	out.append_array(preload("res://scripts/hud/trade_alerts.gd").alerts())
	if not gear.is_empty(): out.append({"id":"gear","glyph":"gear","tone":"amber","count":gear.size(),"title":"Short of gear","lines":gear,"page":"support"})
	# Drafts come from the watch (watch_military.gd): the War screen's
	# manpower is where more are set to keep watch.
	if not thin.is_empty(): out.append({"id":"men","glyph":"men","tone":"amber","count":thin.size(),"title":"Under strength","lines":thin,"page":"war"})
	if not fought.is_empty(): out.append({"id":"fought","war":"feud","tone":"amber","count":fought.size(),"title":"Battles just fought","lines":fought,"page":"wars"})
	# Spies and assassins: an agent caught or killed, a strike done, their spy
	# caught (covert_ops.gd). Told here, never as a pop-up.
	for covert_alert in preload("res://scripts/covert_ops.gd").alerts(): out.append(covert_alert)
	# Soldiers gone short of their pay (realm_purse.gd's monthly reckoning):
	# told here, never stopping time; a click opens the Wealth page.
	var unpaid:=unpaid_alert()
	if not unpaid.is_empty(): out.append(unpaid)
	return out


## The soldiers' pay short: months running, the share unpaid, who went home.
static func unpaid_alert()->Dictionary:
	if WorldSimulation.state==null: return {}
	var purse:Dictionary=WorldSimulation.state.realm_purse
	var months:=int(purse.get("unpaid_months",0))
	if months<=0: return {}
	var last:Dictionary=purse.get("last_army",{}) if purse.get("last_army") is Dictionary else {}
	var lines:=PackedStringArray()
	lines.append("%d in 100 of their pay unpaid this month" % roundi(float(last.get("unpaid",1.0))*100.0))
	lines.append("Will down %d points" % roundi(float(last.get("will_lost",0.0))*100.0))
	if int(last.get("deserted",0))>0: lines.append("%d went home" % int(last.deserted))
	return {"id":"unpaid","glyph":"will","tone":"red" if months>=3 else "amber","count":months,"title":"Soldiers unpaid %d %s" % [months,"month" if months==1 else "months"],"lines":lines,"page":"forces","dock":["economy",2]}
