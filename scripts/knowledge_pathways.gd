extends RefCounted
## Alternative routes converge on one discovery/adoption record. An imported
## example is evidence, never a second copy of its effects or an instant unlock.
const Requirements=preload("res://scripts/technology_requirements.gd")
const ALTERNATIVES:={
	"smoking":{"label":"Hearth experiments","requires":["charcoal"],"signals":["fire","food"]},
	"basketry":{"label":"Container experiments","requires":["clay_shaping"],"signals":["fiber","storage"]},
	"pit_firing":{"label":"Cooking-fire experiments","requires":["clay_shaping","food_drying"],"signals":["fire","clay"]},
	"joinery":{"label":"Workshop fitting","requires":["stone_sorting"],"signals":["timber","construction"]},
	"well_siting":{"label":"Comparing water-bearing ground","requires":["seasonal_patterns","route_memory"],"signals":["freshwater","survey"]},
	"clean_water":{"label":"Comparing household illness","requires":["tallies","well_siting"],"signals":["freshwater","illness"]},
	"standard_measures":{"label":"Exchange between communities","requires":["route_memory"],"signals":["trade","construction"]},
	"customary_law":{"label":"Remembered judgments","requires":["oral_epics","tallies"],"signals":["dispute","administration"]},
	"public_stores":{"label":"Coordinated household reserves","requires":["standard_measures","basketry"],"signals":["storage","administration"]},
	"formation_drill":{"label":"Coordinated public exercises","requires":["watch_rotation","festival_calendar"],"signals":["training","defense"]},
	"supply_groups":{"label":"Carrying teams","requires":["pack_animals","labor_rotations"],"signals":["logistics","travel"]},
	"river_craft":{"label":"Timber boatbuilding","requires":["cordage","joinery"],"signals":["freshwater","timber"]},
	"coastal_watercraft":{"label":"Woven-hull experiments","requires":["river_craft","basketry"],"signals":["fiber","travel"]},
	"festival_calendar":{"label":"Gatherings and remembered journeys","requires":["oral_epics","route_memory"],"signals":["culture","travel"]},
	"civic_games":{"label":"Public exercises and agreed rules","requires":["formation_drill","customary_law"],"signals":["culture","administration"]}
}

static func book()->Dictionary:
	return WorldSimulation.state.society_exchange

static func evidence(id:String)->Dictionary:
	var key:=String(book().get("evidence",{}).get(id,""))
	return book().collections.get(key,{})

static func routes(entry:Dictionary)->Array[Dictionary]:
	var result:Array[Dictionary]=[{"id":"local","label":"Local practice","requires":entry.get("requires",[]).duplicate(),"signals":entry.get("signals",[]).duplicate()}]
	if ALTERNATIVES.has(String(entry.id)):
		var alternate:Dictionary=ALTERNATIVES[String(entry.id)].duplicate(true);alternate.id="experimental";result.append(alternate)
	var source:=evidence(String(entry.id))
	if not source.is_empty():
		# Demonstrations shorten the search; underlying scientific and material
		# prerequisites still apply, preventing a late artifact from skipping eras.
		result.append({"id":"fieldwork" if source.kind=="specimen" else "exchange","label":("Field experiments: " if source.kind=="specimen" else "Learned from ")+String(source.source_name),"requires":entry.get("requires",[]).duplicate(),"signals":entry.get("signals",[]).duplicate(),"collection_id":source.id})
	for route:Dictionary in result:
		# Common foundations and every OR group apply to foreign learning as well.
		if entry.has("requires_all"):
			route["requires_any"]=entry.get("requires_any",[]).duplicate(true)
		route["ready"]=bool(Requirements.evaluate(entry,WorldSimulation.state.known_discoveries).ready) if entry.has("requires_all") else true
		for requirement:String in route.requires:
			if requirement not in WorldSimulation.state.known_discoveries:route.ready=false
		for group:Array in route.get("requires_any",[]):
			for parent:String in group:
				if parent in WorldSimulation.state.known_discoveries:
					if parent not in route.requires:route.requires.append(parent)
					break
		var support:=0.0
		for signal_name:String in route.signals:support+=clampf(float(WorldSimulation.discovery.latest_context.get(signal_name,0)),0,2)
		route["support"]=support/maxi(1,route.signals.size())
		if route.id=="experimental" and float(route.support)<.25:route.ready=false
	return result

static func chosen(entry:Dictionary)->Dictionary:
	var result:Dictionary={};var best:=-1.0
	for route:Dictionary in routes(entry):
		if not bool(route.ready):continue
		var score:=float(route.support)+(2.0 if route.id in ["exchange","fieldwork"] else .05 if route.id=="local" else .1)
		if score>best:result=route;best=score
	return result

static func ready(entry:Dictionary,day:int)->bool:
	var route:=chosen(entry)
	if route.is_empty():return false
	# Imported, studied evidence can introduce an already existing practice
	# before the local earliest-question date, without removing its prerequisites.
	return day>=int(entry.get("day",0)) or route.id=="exchange"

static func multiplier(entry:Dictionary)->float:
	var route:=chosen(entry)
	if route.is_empty():return 1.0
	return 1.8 if route.id=="exchange" else 1.0+minf(.4,float(route.support)*.15)

static func need(entry:Dictionary)->float:
	var metrics:=WorldSimulation.state.simulation_metrics
	var domain:=String(entry.get("dynamic",""))
	var pressure:=float(preload("res://scripts/society_exchange.gd").pressure().get("unsettled_share",0))
	if domain in ["institutions","culture"]:return pressure*40
	if domain=="infrastructure":return maxf(0,1-float(metrics.get("housing_ratio",1)))*35
	if domain in ["nutrition","health"]:return maxf(0,1-float(metrics.get("food_intake_ratio",1)))*35
	return 0

static func remember(entry:Dictionary,day:int)->void:
	var route:=chosen(entry)
	if route.is_empty():route={"id":"local","label":"Local practice","requires":entry.get("requires",[])}
	book().origins[String(entry.id)]={"route":route.id,"label":route.label,"requires":route.requires.duplicate(),"collection_id":route.get("collection_id",""),"day":day}

static func describe(entry:Dictionary)->String:
	var origin:Dictionary=book().origins.get(String(entry.id),{})
	if not origin.is_empty():return "Developed through %s · day %d" % [String(origin.label).to_lower(),int(origin.day)]
	var route:=chosen(entry)
	return "Current approach: "+String(route.label) if not route.is_empty() else "Several approaches may lead here; foundations or evidence are still missing."
