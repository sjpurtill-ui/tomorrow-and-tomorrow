extends RefCounted
## Read-only explanation of the existing discovery ledger. Source contributions
## are before shared caps/upkeep; they are never presented as isolated life years.
const Care:=preload("res://scripts/early_life_conditions.gd")
const Era:=preload("res://scripts/hud/era_words.gd")
const CHANNELS:={
	"health_protection":["Protection from illness","Helps people resist sickness."],
	"disease_exposure":["Disease exposure","Changes how readily disease reaches people."],
	"sanitation":["Sanitation","Reduces the burden of infection from waste."],
	"water_safety":["Water safety","Protects people from unsafe drinking water."],
	"maternal_safety":["Safety in childbirth","Protects mothers during and after birth."],
	"neonatal_survival":["Newborn survival","Protects babies in their first days."],
	"injury_risk":["Risk of injury","Changes the danger from injuries."],
	"health_risk":["Health risk","Changes the risks that wear down health."],
	"modern_survival":["Medical protection","Lowers age-specific mortality as modern care spreads."],
	"nutrition_quality":["Nutrition","Improves the food people live on."],
	"food_storage":["Food preservation","Helps food last through lean seasons."],
}

static func read()->Dictionary:
	var discovery:Node=WorldSimulation.discovery
	if discovery==null:return {"totals":[],"recent":[]}
	var model:RefCounted=discovery.society_model
	var sources:Dictionary=model.effect_sources(model.practice_basis(),CHANNELS.keys(),null,false)
	var dates:Dictionary={}
	for event:Dictionary in GameState.discovery_log:dates[String(event.get("id",""))]=int(event.get("day",-1))
	var result:Array=[]
	var totals:Dictionary={}
	var neglect:float=model.neglect_for(model.line_focus)
	for index in range(GameState.known_discoveries.size()-1,-1,-1):
		var id:=String(GameState.known_discoveries[index])
		var definition:Dictionary=discovery.discovery_definition(id)
		var effects:Dictionary=definition.get("effects",{})
		var lines:Array=[]
		var scale:float=model.practice_scale(String(definition.get("dynamic","")),model.line_focus,neglect)
		for channel:String in CHANNELS:
			if not effects.has(channel):continue
			var amount:=float((sources.get(channel,{}) as Dictionary).get(index,0.0))
			var unlocked:float=model.scaled_effect(channel,float(effects[channel]),scale)
			lines.append({"label":CHANNELS[channel][0],"value":points(amount),"amount":amount,"unlocked":unlocked,"tip":CHANNELS[channel][1]})
			if not totals.has(channel):totals[channel]={"id":channel,"label":CHANNELS[channel][0],"amount":0.0,"unlocked":0.0,"count":0,"tip":CHANNELS[channel][1]}
			totals[channel].amount+=amount
			totals[channel].unlocked+=unlocked
			totals[channel].count+=1
		var protections:Array=[]
		for category:Dictionary in Care.CATEGORIES:
			if not (category.practices as Dictionary).has(id):continue
			var weight:=float(category.practices[id])
			protections.append({"label":category.label,"value":"%.1f / %.0f points" % [weight*discovery.practiced(id)*100.0,weight*100.0],
				"tip":"This practice's coverage now / at full use. Overlapping protections share a 100-point ceiling. "+String(category.missing)})
		if lines.is_empty() and protections.is_empty():continue
		result.append({"id":id,"order":index,"day":int(dates.get(id,-1)),"name":definition.get("name",id.replace("_"," ").capitalize()),
			"mechanism":definition.get("causal_mechanism",definition.get("observation","")),
			"adoption":discovery.adoption(id),"practice":discovery.practiced(id),"effects":lines,"protections":protections,
			"record":record_for(id,GameState.discovery_log,GameState.health_history)})
	result.sort_custom(func(a:Dictionary,b:Dictionary)->bool:
		var a_day:=int(a.get("day",-1));var b_day:=int(b.get("day",-1))
		return int(a.order)>int(b.order) if a_day==b_day else a_day>b_day)
	var rows:Array=[]
	for channel:String in CHANNELS:
		if totals.has(channel):rows.append(totals[channel])
	return {"totals":rows,"recent":result.slice(0,3)}

static func points(amount:float)->String:
	if is_zero_approx(amount):return "0 points"
	if absf(amount)*100.0<0.01:return ("+" if amount>0.0 else "−")+"<0.01 points"
	return "%+.2f points" % (amount*100.0)

static func record_for(id:String,events:Array,history:Array)->String:
	var day:=-1
	for event:Dictionary in events:
		if String(event.get("id",""))==id:day=int(event.get("day",-1));break
	if day<0:return "No discovery date was recorded for this knowledge."
	var date:="Discovered %s." % Era.when(day)
	for index in history.size():
		var point:Dictionary=history[index]
		if int(point.get("day",0))<day:continue
		if index==0:return date+" No earlier lifespan reading is kept for comparison."
		if int((history[index-1] as Dictionary).get("day",0))>=day:continue
		return date+" Lifespan changed by %s in that recording interval, from all causes together. This is not an isolated gain from this discovery." % Era.life_change(float(point.get("delta",0.0)))
	return date+" The next monthly lifespan reading has not been recorded yet."
