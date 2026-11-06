extends RefCounted
## The acting civilization owns its chapter in DiscoverySystem's saved ledger.
## Reports only read it. A daily observation earns progress; opening a UI never does.
const WIDTH:=300.0
const HOLD_DAYS:=90
const Goods:=preload("res://scripts/civilian_goods.gd")
const Paths:=preload("res://scripts/knowledge_pathways.gd")
static var _definitions:Array=[]

static func definitions()->Array:
	if _definitions.is_empty():
		var parsed:Variant=JSON.parse_string(FileAccess.get_file_as_string("res://data/campaign_chapters.json"))
		_definitions=parsed.get("chapters",[]) if parsed is Dictionary else []
	return _definitions

static func fresh()->Dictionary:
	return {"index":0,"last_day":-1,"streaks":{},"history":[],"completed":false,"focus":""}

static func index(discovery:Object)->int:
	return clampi(int(discovery.chapter_progress.get("index",0)),0,definitions().size()-1)

static func frontier(discovery:Object)->float:
	return float(definitions()[index(discovery)].end)

static func chapter_of(entry:Dictionary)->int:
	return clampi(floori(float(entry.get("earliest_year",0.0))/WIDTH),0,definitions().size()-1)

## Real capacity, never another troop, stock or population pool.
static func capabilities()->Dictionary:
	var s:Node=WorldSimulation.state
	var mc:Node=WorldSimulation.military
	var soldiers:=0.0
	var trained:=0.0
	var forces:Array=[mc.home_army]
	forces.append_array(mc.field_armies)
	for force:Dictionary in forces:
		for formation:Dictionary in force.get("formations",[]):
			var count:=maxf(0,float(formation.get("count",0)))
			soldiers+=count
			if float(formation.get("training",0))>=0.25 and float(formation.get("personnel_condition",0))>=0.6 and float(formation.get("equipment",0))>=float(formation.get("equipment_required",count))*0.8:
				trained+=count
	var minimum:=maxf(8.0,ceil(float(s.population_exact)*0.03))
	var goods_target:=Goods.target()
	return {"trained":trained,"military_need":minimum,"soldiers":soldiers,
		"goods":Goods.stock(),"goods_need":goods_target,"makers":float(s.effective_workers("Crafting")),
		"administrators":float(s.effective_workers("Administration")),"administration_need":maxf(1.0,float(s.population_exact)*0.02),
		"legitimacy":float(s.simulation_metrics.get("legitimacy",0.0)),"cohesion":float(s.simulation_metrics.get("cohesion",0.0)),
		"food_security":float(s.food_security)}

static func measures(route:String,c:Dictionary)->Array:
	match route:
		"military":return [{"label":"Trained, fit, equipped soldiers","value":c.trained,"need":c.military_need,"unit":"people"},{"label":"Food security","value":c.food_security*100.0,"need":80.0,"unit":"%"}]
		"productive":return [{"label":"Civilian goods held","value":c.goods,"need":c.goods_need,"unit":"goods"},{"label":"Working makers","value":c.makers,"need":1.0,"unit":"people"},{"label":"Food security","value":c.food_security*100.0,"need":80.0,"unit":"%"}]
	return [{"label":"Working administrators","value":c.administrators,"need":c.administration_need,"unit":"people"},{"label":"Legitimacy","value":c.legitimacy*100.0,"need":65.0,"unit":"%"},{"label":"Cohesion","value":c.cohesion*100.0,"need":65.0,"unit":"%"}]

static func routes(discovery:Object,c:Dictionary,known:Array)->Array:
	var result:Array=[]
	for definition:Dictionary in definitions()[index(discovery)].routes:
		var route:=definition.duplicate(true)
		route["checks"]=measures(String(route.id),c)
		route["ready"]=true
		for id:String in route.milestones:
			if not known.has(id):route.ready=false
		for check:Dictionary in route.checks:
			if float(check.value)+0.000001<float(check.need):route.ready=false
		route["days"]=int(discovery.chapter_progress.get("streaks",{}).get(String(route.id),0))
		result.append(route)
	return result

## At most the observed span can count, never an unobserved calendar gap.
## A changed condition resets the route's run. Duplicate days cannot advance it.
static func advance(discovery:Object,day:int,span:int,c:Dictionary,known:Array)->Dictionary:
	if discovery.chapter_progress.is_empty():discovery.chapter_progress=fresh()
	var ledger:Dictionary=discovery.chapter_progress
	if bool(ledger.completed) or day<=int(ledger.last_day):return {}
	var previous:=int(ledger.last_day)
	var observed:=mini(maxi(1,span),maxi(1,day-previous)) if previous>=0 else 1
	if previous>=0 and day-previous>maxi(1,span):ledger.streaks.clear()
	ledger.last_day=day
	for route:Dictionary in routes(discovery,c,known):
		var days:=int(route.days)+(observed if int(route.days)>0 else 1) if bool(route.ready) else 0
		ledger.streaks[String(route.id)]=days
		if days<HOLD_DAYS:continue
		var record:={"chapter":index(discovery),"name":String(definitions()[index(discovery)].name),"route":String(route.name),"day":day,"population":float(WorldSimulation.state.population_exact),"discoveries":known.size(),"capabilities":c.duplicate(true)}
		(ledger.history as Array).append(record)
		ledger.streaks.clear();ledger.focus=""
		if index(discovery)==definitions().size()-1:ledger.completed=true
		else:ledger.index=index(discovery)+1
		return record
	return {}

static func snapshot(discovery:Object)->Dictionary:
	var definition:Dictionary=definitions()[index(discovery)].duplicate(true)
	definition["routes"]=routes(discovery,capabilities(),WorldSimulation.state.known_discoveries)
	definition["history"]=discovery.chapter_progress.get("history",[]).duplicate(true)
	definition["completed"]=bool(discovery.chapter_progress.get("completed",false))
	definition["focus"]=String(discovery.chapter_progress.get("focus",""))
	definition["legacy_entry"]=int(discovery.chapter_progress.get("legacy_entry",-1))
	definition["hold_days"]=HOLD_DAYS
	return definition

## Manual route focus is optional and uses the same finite research capacity.
## The scheduler boosts genuine prerequisite candidates, never grants knowledge.
static func focus(discovery:Object,route_id:String)->void:
	if discovery.chapter_progress.is_empty():discovery.chapter_progress=fresh()
	if route_id!="" and not definitions()[index(discovery)].routes.any(func(r:Dictionary)->bool:return String(r.id)==route_id):return
	discovery.chapter_progress.focus=route_id
	discovery.chapter_cache.key=[]
	if route_id!="":
		var fields:Dictionary={}
		for id:String in focus_ids(discovery):
			var field:=String(discovery.discovery_definition(id).get("dynamic",""))
			if field!="":fields[field]=true
		for field:String in fields:
			if int(WorldSimulation.state.research_allocations.get(field,0))==0:discovery.set_domain_research_priority(field,1)
	discovery.refresh_investigations()

class Cache extends RefCounted:
	var key:Array=[]
	var ancestors:Dictionary={}

static func focus_ids(discovery:Object)->Dictionary:
	var focus_id:=String(discovery.chapter_progress.get("focus",""))
	var key:=[index(discovery),focus_id,WorldSimulation.state.known_discoveries.size()]
	if discovery.chapter_cache.key==key:return discovery.chapter_cache.ancestors
	var pending:Array=[]
	for route:Dictionary in definitions()[index(discovery)].routes:
		if focus_id=="" or String(route.id)==focus_id:pending.append_array(route.milestones)
	var found:Dictionary={}
	while not pending.is_empty():
		var id:=String(pending.pop_back())
		if found.has(id) or WorldSimulation.state.known_discoveries.has(id):continue
		found[id]=true
		var entry:Dictionary=discovery.discovery_definition(id)
		if not entry.is_empty():pending.append_array(Paths.definition_parents(entry))
	discovery.chapter_cache.key=key;discovery.chapter_cache.ancestors=found
	return found
