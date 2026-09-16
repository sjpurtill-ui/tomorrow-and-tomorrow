extends RefCounted
## Alternative routes converge on one discovery/adoption record. An imported
## example is evidence, never a second copy of its effects or an instant unlock.
const Requirements=preload("res://scripts/technology_requirements.gd")
const ALTERNATIVES:={
	"smoking":{"label":"Hearth experiments","requires":["charcoal"],"signals":["fire","food"]},
	"basketry":{"label":"Container experiments","requires":["clay_shaping"],"signals":["fiber","storage"]},
	"pit_firing":{"label":"Cooking-fire experiments","requires":["clay_shaping","food_drying"],"signals":["fire","clay"]},
	"joinery":{"label":"Corded-frame fitting","requires":["cordage"],"signals":["timber","construction"]},
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

static func routes(entry:Dictionary,known:Variant=null)->Array[Dictionary]:
	return routes_for(entry,WorldSimulation.state.known_discoveries if known==null else known,WorldSimulation.discovery.latest_context,evidence(String(entry.id)))

static func routes_for(entry:Dictionary,known:Variant,context:Dictionary,source:Dictionary={})->Array[Dictionary]:
	var result:Array[Dictionary]=[]
	var common:Dictionary={"requires_all":entry.get("requires_all",[]),"requires_any":entry.get("requires_any",[])}
	var definitions:Array=entry.get("learning_routes",[]).duplicate(true)
	if definitions.is_empty():
		definitions.append({"id":"local","label":"Local practice","requires":entry.get("requires",[]).duplicate()})
		if ALTERNATIVES.has(String(entry.id)):
			var alternate:Dictionary=ALTERNATIVES[String(entry.id)].duplicate(true);alternate.id="experimental";definitions.append(alternate)
	for definition:Dictionary in definitions:
		var route:Dictionary=definition.duplicate(true)
		route["signals"]=route.get("signals",entry.get("signals",[])).duplicate()
		route["requires_all"]=route.get("requires_all",route.get("requires",[])).duplicate()
		route["requires_any"]=route.get("requires_any",[]).duplicate(true)
		route["requires_all"].append_array(common.requires_all)
		route["requires_any"].append_array(common.requires_any)
		route["requires"]=Requirements.parents(route)
		route["collection_id"]=""
		route["progress_multiplier"]=float(route.get("progress_multiplier",1.0))
		result.append(route)
	# A studied foreign example supports any valid causal approach. It never
	# forces the recipient to reconstruct the source's historical sequence.
	if not source.is_empty():
		for foundation:Dictionary in result.duplicate():
			var imported:=foundation.duplicate(true)
			imported["id"]=("fieldwork" if source.kind=="specimen" else "exchange")+("" if foundation.id=="local" else ":"+String(foundation.id))
			imported["label"]=("Field experiments: " if source.kind=="specimen" else "Learned from ")+String(source.source_name)+" · "+String(foundation.label)
			imported["collection_id"]=source.id
			imported["imported"]=source.kind!="specimen"
			imported["progress_multiplier"]*=preload("res://scripts/society_exchange.gd").evidence_strength(source)
			if source.get("reverse_engineered",false):imported["label"]="Workshop examination · "+String(foundation.label)
			result.append(imported)
	for route:Dictionary in result:
		var assessment:=Requirements.evaluate(route,known)
		route.merge(assessment,true)
		var support:=0.0
		for signal_name:String in route.signals:support+=clampf(float(context.get(signal_name,0)),0,2)
		route["support"]=support/maxi(1,route.signals.size())
		if String(route.id).begins_with("experimental") and float(route.support)<.25:route.ready=false
	return result

# The legacy day field is an authoring/order hint, never an eligibility gate.
# Time is still required to do research; calendar age cannot replace foundations.
static func chosen(entry:Dictionary,_day:int=-1,known:Variant=null)->Dictionary:
	var result:Dictionary={};var best:=-1.0
	for route:Dictionary in routes(entry,known):
		if not bool(route.ready):continue
		var score:=float(route.support)+float(route.progress_multiplier)+(0.05 if route.id=="local" else .1)
		if score>best:result=route;best=score
	return result

static func ready(entry:Dictionary,day:int,known:Variant=null)->bool:
	return not chosen(entry,day,known).is_empty()

static func multiplier(entry:Dictionary)->float:
	var route:=chosen(entry,int(WorldSimulation.state.elapsed_days))
	if route.is_empty():return 1.0
	return preload("res://scripts/scholar_visits.gd").bonus(String(entry.id),int(WorldSimulation.state.elapsed_days))*float(route.progress_multiplier)*(1.0 if route.get("imported",false) else 1.0+minf(.4,float(route.support)*.15))

static func missing(entry:Dictionary,day:int,known:Variant=null)->Array[String]:
	if ready(entry,day,known):return []
	var best:Array[String]=[]
	var found:=false
	for route:Dictionary in routes(entry,known):
		var reasons:Array[String]=[]
		for id:String in route.missing_all:reasons.append(_name(id))
		for group:Array in route.missing_any:
			var names:Array[String]=[]
			for id:String in group:names.append(_name(id))
			reasons.append("one of: "+" or ".join(names))
		if reasons.is_empty():reasons.append("more supporting observations")
		if not found or reasons.size()<best.size():best=reasons;found=true
	return best

static func _name(id:String)->String:
	return String(WorldSimulation.discovery.discovery_definition(id).get("name",id))

static func need(entry:Dictionary)->float:
	var metrics:=WorldSimulation.state.simulation_metrics
	var domain:=String(entry.get("dynamic",""))
	var pressure:=float(preload("res://scripts/society_exchange.gd").pressure().get("unsettled_share",0))
	if domain in ["institutions","culture"]:return pressure*40
	if domain=="infrastructure":return maxf(0,1-float(metrics.get("housing_ratio",1)))*35
	if domain in ["nutrition","health"]:return maxf(0,1-float(metrics.get("food_intake_ratio",1)))*35
	return 0

static func remember(entry:Dictionary,day:int)->void:
	var route:=chosen(entry,day)
	if route.is_empty():route={"id":"local","label":"Local practice","requires":entry.get("requires",[])}
	var foundations:Array=route.get("requires_all",route.get("requires",[])).duplicate()
	for group:Array in route.get("requires_any",[]):
		for parent:String in group:
			if parent in WorldSimulation.state.known_discoveries:
				if parent not in foundations:foundations.append(parent)
				break
	book().origins[String(entry.id)]={"route":route.id,"label":route.label,"requires":foundations,"collection_id":route.get("collection_id",""),"day":day}

static func describe(entry:Dictionary,known:Variant=null)->String:
	var origin:Dictionary=book().origins.get(String(entry.id),{})
	if not origin.is_empty():return "Developed through %s · day %d" % [String(origin.label).to_lower(),int(origin.day)]
	var route:=chosen(entry,-1,known)
	return "Current approach: "+String(route.label) if not route.is_empty() else "Several approaches may lead here; foundations or evidence are still missing."

static func graph_entry(entry:Dictionary)->Dictionary:
	return {"id":entry.id,"requires_all":[],"learning_routes":routes_for(entry,[],{})}

static func definition_parents(entry:Dictionary)->Array[String]:
	var parents:Array[String]=[]
	for route:Dictionary in routes_for(entry,[],{}):
		for id:String in route.requires:
			if id not in parents:parents.append(id)
	return parents
