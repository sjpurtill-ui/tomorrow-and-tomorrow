extends RefCounted
## THE MAP TICKER'S WORDS: one calm sentence over the map saying what is
## happening and, when it helps, what the ruler can do next with a control
## that really exists (right-click on land, the survey card, the toolbar's
## Found and Scout buttons, the court). No system titles, no capitals, no
## instrument read-outs.

const Kit:=preload("res://scripts/hud/paper_kit.gd")

static func duration(days:float)->String:
	var hours:=maxi(0,ceili(days*24.0))
	if hours<24:return "%d hour%s" % [hours,"" if hours==1 else "s"]
	var whole:=roundi(days)
	if whole<14:return "%d day%s" % [whole,"" if whole==1 else "s"]
	if whole<60:return "%d weeks" % roundi(days/7.0)
	return "%d months" % roundi(days/30.0)

static func _days(value:float)->String:
	if value>=365.0:return "a year or more"
	if value<1.0:return "less than a day"
	return "%d day%s" % [roundi(value),"" if roundi(value)==1 else "s"]

## The founding travellers and settler caravans, from the map's live state.
static func journey(travel_active:bool,remaining_days:float,colony:Dictionary,halt_reason:String,site_committed:bool,camped:bool,hearth_done:bool,targeting:bool,placing:bool,founded_day:int,today:float)->String:
	var food_days:=float(GameState.simulation_metrics.get("food_days",0.0))
	var water_days:=float(GameState.water_metrics.get("days",0.0))
	var advice:Dictionary=preload("res://scripts/civilization_travel.gd").advice() if not site_committed else {}
	if travel_active:
		var lead:=_leader_line(advice)
		return "%s About %s still to walk; food for %s, water for %s." % [lead,duration(remaining_days),_days(food_days),_days(water_days)]
	if bool(colony.get("active",false)):
		var intent:=String((colony.get("caravan",{}) as Dictionary).get("intent",""))
		var remaining:=maxf(0.0,float(colony.get("arrival_day",today))-today)
		return "%d settlers are on the road%s. About %s to go." % [int(colony.get("population",0)),(": "+_lower_first(intent)) if intent!="" else "",duration(remaining)]
	if halt_reason!="":
		return "The travellers have stopped: %s. Time is paused until you choose." % _lower_first(Kit.sentence(halt_reason)).trim_suffix(".")
	if not site_committed and camped:
		if String(advice.get("intent",""))!="":
			return "%s Food today %+.0f; water for %s." % [_leader_line(advice),float(GameState.simulation_metrics.get("food_net",0.0)),_days(water_days)]
		var ready:=bool(advice.get("ready",false))
		return ("The camp has enough put by to walk on, about %.0f km in one go. Right-click land to set out." if ready else "The travellers are camped and gathering food; they could walk about %.0f km now.") % float(advice.get("approximate_reach_km",0.0))
	if site_committed and not hearth_done:
		return "The first hearth is being built."
	if targeting:
		return "Choose land for the new settlement. Right-click or press Esc to stop choosing."
	if placing:return ""
	if not site_committed:
		return "Right-click land to walk the travellers there. Left-click to look at the ground first."
	if founded_day>=0 and today-float(founded_day)>30.0:return latest_telling()
	return ""

static func _leader_line(advice:Dictionary)->String:
	var intent:=String(advice.get("intent",""))
	if intent!="":return "%s: %s." % [String(advice.get("leader","The caravan leader")),_lower_first(intent).trim_suffix(".")]
	match String(advice.get("status","")):
		"STOP & FORAGE":return "The food will not last this leg; the travellers should stop and gather."
		"CAMP SOON":return "Supplies are thin; the travellers should make camp soon."
	return "The travellers are on the move."

static func _lower_first(text:String)->String:
	if text.length()<2:return text
	# Keep names ("Tilla leads...") but lower a sentence's opening word.
	var first:=text.get_slice(" ",0)
	if first.length()>1 and first==first.capitalize() and first.to_lower() in ["the","we","they","our","a","an","camping","marching","resting","waiting","holding","heading","making","looking","following","crossing","gathering","returning"]:
		return text.substr(0,1).to_lower()+text.substr(1)
	return text

## The Chronicle's newest tale, as one line.
static func latest_telling()->String:
	var newest:Array=preload("res://scripts/chronicle.gd").entries("notice",1)
	if newest.is_empty():return ""
	var entry:Dictionary=newest[0]
	var title:=Kit.sentence(String(entry.get("title",""))).trim_suffix(".")
	var text:=String(entry.get("text","")).strip_edges()
	var first:=text.get_slice(". ",0).trim_suffix(".")
	if first=="" or first.length()>150:return title+"."
	return "%s: %s." % [title,_lower_first(first)]

## One day's news, when the day brought any.
static func day_news(progression:Array,discoveries:Array,resources:Array,events:Array)->String:
	if not progression.is_empty():
		return "A new stage for our people: %s." % String((progression[0] as Dictionary).get("name","")).to_lower()
	if not discoveries.is_empty():
		return "Our people have worked out %s." % String((discoveries[0] as Dictionary).get("name","something new")).to_lower()
	for source in [resources,events]:
		if not source.is_empty():
			var entry:Dictionary=source[0]
			var text:=String(entry.get("description","")).strip_edges()
			return text if text!="" else Kit.sentence(String(entry.get("title","")))+"."
	return ""

## What a left-click on land tells the ticker.
static func inspection(kind:String,facts:Dictionary)->String:
	match kind:
		"uncharted":return "Nobody has seen this ground yet. Send scouts this way to learn it."
		"blocked":return "%s. Pick dry ground beyond the bank." % Kit.sentence(String(facts.get("reason","This ground cannot hold a settlement"))).trim_suffix(".")
		"foreign_settlement":return "%s live here. Ask in court to learn more of them." % String(facts.get("name","Strangers"))
		"encounter":return "We met %s here. %s" % [String(facts.get("name","strangers")),"We know where they live." if bool(facts.get("home_known",false)) else "Where they live is still unknown."]
		"inside":return "Inside %s, %.1f km from its hearth." % [String(facts.get("name","our town")),float(facts.get("km",0.0))]
		"open":
			var ground:=Kit.first_capital(String(facts.get("ground","Open ground")))
			if bool(facts.get("site_committed",false)):return "%s. To settle it, press Found on the toolbar." % ground
			return "%s. Right-click to walk the travellers here." % ground
	return ""
