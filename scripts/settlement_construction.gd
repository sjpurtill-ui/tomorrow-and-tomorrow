extends RefCounted
## The settlement construction rules formerly embedded in the rendered map.
## Every local city, regardless of controller, uses this work and material bill.
##
## Housing is one ledger, state.housing_capacity. Its places are either the
## shelters the founders carried (recorded once in founding_manifest as
## "shelter_places") or built here: the Lean-to Shelters and the homes the
## builders add whenever the town fills. The Buildings page reads the same
## rules through housing() and daily_work(), so it can say when and how fast.

## Builders put up more homes once more people live here than this share of
## the places (and only after the Lean-to Shelters stand).
const HOUSING_TRIGGER:=0.80
## Builder work (see housing_work_per_day) for each batch of new homes.
const HOUSING_BATCH_WORK:=28.0
## Places the Lean-to Shelters add before any building knowledge.
const LEAN_TO_PLACES:=90
## The places in the thirty shelters the founding band carries: the start of
## the housing ledger in GameState.reset_for_new_world. Read only to explain
## saves made before the carried places were recorded.
const STARTING_SHELTER_PLACES:=150

static func _settlement_definitions() -> Array[Dictionary]:
	return [
		{"name":"Hearth Circle", "days":6.0, "requires":[], "minimum":{"Construction":3},"materials":{"Timber":6.0,"Fiber Plants":6.0},"requires_water":true,"effect":"anchors the camp and makes communal work possible"},
		{"name":"Lean-to Shelters", "days":9.0, "requires":["Hearth Circle"], "minimum":{"Construction":5},"materials":{"Timber":18.0,"Fiber Plants":12.0},"effect":"protects health and expands shelter"},
		{"name":"Storage Pits", "days":7.0, "requires":["Hearth Circle"], "minimum":{"Construction":4, "Logistics":4},"materials":{"Timber":4.0,"Fiber Plants":3.0},"effect":"slows spoilage and expands food storage"},
		{"name":"Public Stores", "days":14.0, "requires":["Storage Pits"], "discovery":"public_stores", "minimum":{"Construction":5,"Logistics":6,"Administration":3},"materials":{"Timber":14.0,"Clay":8.0,"Fiber Plants":6.0},"effect":"keeps a counted, guarded store of food for the whole town"},
		{"name":"Open Work Area", "days":12.0, "requires":["Hearth Circle"], "minimum":{"Construction":6, "Crafting":4},"materials":{"Timber":12.0,"Fiber Plants":5.0},"effect":"improves tools and material work"},
		{"name":"Framed Hall", "days":22.0, "requires":["Lean-to Shelters","Open Work Area"], "discovery":"framed_construction", "minimum":{"Construction":8,"Crafting":5,"Logistics":4},"materials":{"Civilian Goods":6.0,"Timber":18.0,"Fiber Plants":12.0,"Clay":8.0},"effect":"gives the council and the feasts a roof: the people heed their leaders more and hold together, the stewards reach further, and timber framing speeds building and makes new homes hold more"},
		{"name":"Gathering Yard", "days":10.0, "requires":["Hearth Circle"], "minimum":{"Construction":4, "Extraction":4},"materials":{"Timber":10.0,"Fiber Plants":4.0}, "known_resource":true,"effect":"organizes digging and cutting at known deposits: every deposit worked gives more"},
		{"name":"Hearth Shrine", "days":5.0, "requires":["Hearth Circle"], "discovery":"hearth_shrine_offerings", "minimum":{"Construction":2},"materials":{"Stone":4.0,"Clay":4.0},"effect":"a hearth-shrine for offerings to the god: the people draw together and toward the god, and give up a little food in offerings"},
		{"name":"Shrine House", "days":18.0, "requires":["Hearth Shrine","Lean-to Shelters"], "discovery":"first_shrine_house", "minimum":{"Construction":6},"materials":{"Timber":16.0,"Clay":12.0,"Stone":8.0},"effect":"a house for the god, tended by keepers: the people hold together, heed their leaders, love the god more and fear the god less; the offerings cost food and the keepers must be at work"}
	]

static func _settlement_project_available(project: Dictionary) -> bool:
	if String(project.name) in WorldSimulation.state.settlement_completed:
		return false
	for required in project.requires:
		if String(required) not in WorldSimulation.state.settlement_completed:
			return false
	var discovery:=String(project.get("discovery",""))
	if not discovery.is_empty() and (discovery not in WorldSimulation.state.known_discoveries or WorldSimulation.discovery.adoption(discovery)<0.10):return false
	# Crew targets describe normal staffing. Smaller crews still do proportional
	# work; only a completely missing required trade prevents construction.
	for role in project.minimum:
		if int(WorldSimulation.state.population_allocations.get(role, 0)) <= 0:
			return false
	if bool(project.get("known_resource", false)) and WorldSimulation.resources.visible_deposits().is_empty():
		return false
	if bool(project.get("requires_water",false)) and not bool(WorldSimulation.state.water_metrics.get("source_accessible",false)):
		return false
	if _settlement_project_material_plan(project).is_empty(): return false
	return true


static func _settlement_project_material_plan(project:Dictionary)->Dictionary:
	var selected:=preload("res://scripts/construction_materials.gd").choose(material_options(project),WorldSimulation.state.resource_stockpiles,WorldSimulation.state.known_discoveries)
	return selected.get("cost",{})

static func material_options(project:Dictionary)->Array[Dictionary]:
	var required:Dictionary=(project.get("materials",{}) as Dictionary).duplicate(true)
	var options:Array[Dictionary]=[{"cost":required}]
	match String(project.get("name","")):
		"Hearth Circle":
			options.append_array([{"cost":{"Stone":8.0,"Fiber Plants":6.0}}, {"cost":{"Clay":10.0,"Fiber Plants":6.0}}])
		"Lean-to Shelters":
			options.append_array([
				{"cost":{"Timber":25.0}}, {"cost":{"Timber":15.0,"Clay":10.0}}, {"cost":{"Timber":14.0,"Stone":14.0}},
				{"cost":{"Fiber Plants":32.0}},
				{"cost":{"Clay":32.0,"Fiber Plants":12.0},"requires":"clay_shaping"}
			])
		"Storage Pits":options.append({"cost":{"Clay":8.0,"Fiber Plants":3.0}})
		"Public Stores":options.append_array([{"cost":{"Stone":18.0,"Timber":10.0,"Fiber Plants":6.0}},{"cost":{"Clay":18.0,"Fiber Plants":9.0}}])
		"Open Work Area":options.append({"cost":{"Clay":16.0,"Fiber Plants":8.0}})
		"Framed Hall":options.append_array([
			{"cost":{"Civilian Goods":6.0,"Timber":20.0,"Fiber Plants":24.0}},
			{"cost":{"Civilian Goods":8.0,"Timber":16.0,"Stone":16.0,"Fiber Plants":8.0}}
		])
		"Gathering Yard":options.append_array([{"cost":{"Stone":16.0,"Fiber Plants":4.0}}, {"cost":{"Clay":18.0,"Fiber Plants":4.0}}])
		"Hearth Shrine":options.append_array([{"cost":{"Clay":8.0}}, {"cost":{"Stone":8.0}}, {"cost":{"Timber":6.0,"Clay":3.0}}])
		"Shrine House":options.append_array([{"cost":{"Timber":22.0,"Clay":18.0}}, {"cost":{"Stone":24.0,"Timber":8.0,"Clay":6.0}}])
	return options


static func _current_settlement_project() -> Dictionary:
	var available: Array[Dictionary] = []
	for project in _settlement_definitions():
		if _settlement_project_available(project): available.append(project)
	if available.is_empty(): return {}
	if WorldSimulation.state.settlement_completed.is_empty():
		for project in available:
			if String(project.name)=="Hearth Circle": return project
	var city:=WorldSimulation.settlements.settlement_record(WorldSimulation.state.resource_settlement_id)
	var priority:=String(city.get("construction_priority",""))
	for project in available:
		if String(project.name)==priority:return project
	var best: Dictionary = available[0]
	var best_score := -INF
	for project in available:
		var score := float(WorldSimulation.state.settlement_projects.get(project.name,0.0))*0.08
		match String(project.name):
			"Lean-to Shelters": score+=(1.0-clampf(float(WorldSimulation.state.housing_capacity)/maxf(1.0,WorldSimulation.state.population_exact),0.0,1.0))*4.0+1.1
			"Storage Pits": score+=(1.0-clampf(float(WorldSimulation.state.simulation_metrics.get("food_days",30.0))/45.0,0.0,1.0))*3.4+float(WorldSimulation.state.population_allocations.get("Logistics",0))/10.0
			"Public Stores": score+=float(WorldSimulation.state.population_allocations.get("Logistics",0))/8.0+float(WorldSimulation.state.population_allocations.get("Administration",0))/6.0
			"Open Work Area": score+=float(WorldSimulation.state.population_allocations.get("Crafting",0))/5.0+float(WorldSimulation.state.effective_workers("Construction"))/12.0
			"Framed Hall": score+=float(WorldSimulation.state.effective_workers("Construction"))/8.0+float(WorldSimulation.state.population_allocations.get("Crafting",0))/10.0
			"Gathering Yard": score+=float(WorldSimulation.state.population_allocations.get("Extraction",0))/4.0+float(WorldSimulation.resources.visible_deposits().size())*0.5
			# A shrine when the people are drifting apart; never before shelter or stores are pressing.
			"Hearth Shrine": score+=0.5+maxf(0.0,0.62-float(WorldSimulation.state.simulation_metrics.get("cohesion",0.58)))*4.0
			"Shrine House": score+=0.4+maxf(0.0,0.62-float(WorldSimulation.state.simulation_metrics.get("cohesion",0.58)))*3.0+WorldSimulation.state.effective_workers("Knowledge")/12.0
		if score>best_score:
			best_score=score
			best=project
	return best

## A day's work on the current project at today's crews: builders set the
## pace, carriers and makers help, and so do health, knowledge and policy.
static func daily_work()->float:
	var builders:=float(WorldSimulation.state.effective_workers("Construction"))
	var carriers:=float(WorldSimulation.state.population_allocations.get("Logistics",0))
	var makers:=float(WorldSimulation.state.population_allocations.get("Crafting",0))
	# Crews the realm's purse pays work faster (realm_purse.gd crews_bonus).
	return (builders/8.0)*(.82+carriers/30.0+makers/50.0)*float(WorldSimulation.state.simulation_metrics.get("labor_efficiency",.72))*(1.0+WorldSimulation.discovery.effect("construction_rate")+WorldSimulation.progression.effect("construction_rate")+WorldSimulation.consequences.policy_effect("construction_rate")+preload("res://scripts/realm_purse.gd").crews_bonus())

## A day's work on new homes at today's crews (HOUSING_BATCH_WORK a batch).
static func housing_work_per_day()->float:
	return float(WorldSimulation.state.effective_workers("Construction"))/8.0*float(WorldSimulation.state.simulation_metrics.get("labor_efficiency",.72))*(1.0+preload("res://scripts/realm_purse.gd").crews_bonus())

## The places one batch of new homes adds, with what the people know of
## building (housing_output: framing, room division; the Framed Hall's share
## acts only while it stands and is kept, civilian_goods.gd).
static func housing_batch_places()->int:
	return roundi(maxi(24,roundi(WorldSimulation.state.population_total*.12))*(1.0+housing_output()))

## What the people's building knowledge adds to each new home's places.
static func housing_output()->float:
	return maxf(0.0,WorldSimulation.discovery.effect("housing_output")+WorldSimulation.progression.effect("housing_output"))

## Builders put up homes when the Lean-to Shelters stand and more people live
## here than HOUSING_TRIGGER of the places.
static func housing_under_way()->bool:
	return "Lean-to Shelters" in WorldSimulation.state.settlement_completed and WorldSimulation.state.population_total>housing_trigger_people()

## The most people who can live here before the builders start more homes.
static func housing_trigger_people()->int:
	return int(WorldSimulation.state.housing_capacity*HOUSING_TRIGGER)

## The places the Lean-to Shelters add, with what the people know of building.
static func lean_to_places()->int:
	return roundi(LEAN_TO_PLACES*(1.0+housing_output()))

## How many of the town's places are the shelters the founders carried. Until
## the first shelters are built every place is a carried one; afterwards the
## figure recorded then (record_carried_places), never more than the places
## still standing. Saves made before it was recorded fall back to the founding
## stock: the first town's carried shelters, or four places to each shelter a
## later town's founders brought (within three places of what they carried).
static func carried_places()->int:
	var state=WorldSimulation.state
	var places:=maxi(0,int(state.housing_capacity))
	var manifest:Dictionary=state.founding_manifest
	if manifest.has("shelter_places"):return clampi(int(manifest.shelter_places),0,places)
	if "Lean-to Shelters" not in state.settlement_completed:return places
	var founding:=4*int(manifest.get("portable_shelters",0))
	var record:Dictionary=WorldSimulation.settlements.settlement_record(state.resource_settlement_id) if not state.resource_settlement_id.is_empty() else {}
	if state.resource_settlement_id.is_empty() or bool(record.get("primary",false)):
		founding=roundi(STARTING_SHELTER_PLACES*(1.0+float(state.founding_focus_definition().get("starting",{}).get("housing_ratio",0.0))))
	return clampi(founding,0,places)

## Records the carried places once the people have settled, and keeps the
## record no larger than the places still standing: shelters lost to fire or
## flood stay lost, and places rebuilt afterwards are built ones. Adds and
## removes no places; housing_capacity stays the one ledger.
static func record_carried_places()->void:
	var manifest:Dictionary=WorldSimulation.state.founding_manifest
	# An empty manifest is not yet initialised (ResourceSystem fills it).
	if manifest.is_empty():return
	var carried:=carried_places()
	if int(manifest.get("shelter_places",-1))!=carried:manifest["shelter_places"]=carried

## The housing ledger in plain parts for the Buildings page.
static func housing()->Dictionary:
	var state=WorldSimulation.state
	var places:=maxi(0,int(state.housing_capacity))
	var people:=maxi(0,int(state.population_total))
	var carried:=carried_places()
	var rate:=housing_work_per_day()
	var progress:=clampf(float(state.housing_progress)/HOUSING_BATCH_WORK,0.0,1.0)
	return {"places":places,"people":people,"carried":carried,"built":places-carried,"spare":maxi(0,places-people),"short":maxi(0,people-places),
		"shelters_built":"Lean-to Shelters" in state.settlement_completed,"lean_to_places":lean_to_places(),
		"trigger":housing_trigger_people(),"building":housing_under_way(),"batch":housing_batch_places(),"progress":progress,
		"work_per_day":rate,"days_per_batch":HOUSING_BATCH_WORK/rate if rate>0.0 else -1.0,
		"days_left":(HOUSING_BATCH_WORK-float(state.housing_progress))/rate if rate>0.0 else -1.0}

static func process_day()->Array[Dictionary]:
	var events:Array[Dictionary]=[]
	if not WorldSimulation.state.settlement_site_committed or WorldSimulation.state.convoy_traveling:return events
	record_carried_places()
	if housing_under_way():
		# A multi-day step (day_span.gd) covers `span` days of building.
		WorldSimulation.state.housing_progress+=housing_work_per_day()*WorldSimulation.span
		for completed in WorldSimulation.span:
			if WorldSimulation.state.housing_progress<HOUSING_BATCH_WORK:break
			WorldSimulation.state.housing_progress-=HOUSING_BATCH_WORK
			WorldSimulation.state.housing_capacity+=housing_batch_places()
	var project:=_current_settlement_project()
	if project.is_empty():return events
	var title:=String(project.name)
	WorldSimulation.state.settlement_projects[title]=float(WorldSimulation.state.settlement_projects.get(title,0))+daily_work()*WorldSimulation.span
	if float(WorldSimulation.state.settlement_projects[title])<float(project.days):return events
	var materials:=_settlement_project_material_plan(project)
	if materials.is_empty():return events
	for resource in materials:WorldSimulation.state.resource_stockpiles[resource]=maxf(0,float(WorldSimulation.state.resource_stockpiles.get(resource,0))-float(materials[resource]))
	WorldSimulation.state.settlement_completed.append(title)
	if title=="Hearth Circle":
		WorldSimulation.state.settlement_founded_day=int(WorldSimulation.state.elapsed_days)
		WorldSimulation.settlements.ensure_founded()
		WorldSimulation.government.initialize()
	elif title=="Lean-to Shelters":WorldSimulation.state.housing_capacity+=lean_to_places()
	var completed_form:String="communal_work"
	var completed_use:String="communal"
	if title=="Public Stores":completed_form="public_storehouse";completed_use="storage"
	elif title=="Framed Hall":completed_form="timber_frame_hall"
	var event:={"day":int(WorldSimulation.state.elapsed_days),"settlement_id":WorldSimulation.state.resource_settlement_id,"settlement_name":WorldSimulation.state.settlement_name,"event":"completed","kind":title,"form":completed_form,"land_use":completed_use,"roof_plan":"thatched_ridge" if title=="Framed Hall" else "","material_family":preload("res://scripts/construction_materials.gd").family_for(materials),"materials":materials,"counts_materials":true,"condition":1.0,"status":"active","note":String(project.get("effect",""))}
	WorldSimulation.state.record_building_event(event)
	events.append(event)
	tell_finished(title)
	return events

## A civic work stands: the god's own people remember it in their Chronicle
## (rival peoples keep none), with the first things it does in the engine's
## numbers (building_impact.gd). The Buildings page stamps it too.
static func tell_finished(title:String)->Dictionary:
	var chronicle=preload("res://scripts/chronicle.gd")
	if not chronicle.active():return {}
	# The Chronicle is told in whole numbers (its voice splits a sentence at a
	# decimal point): the first two effects that read so.
	var said:PackedStringArray=[]
	for line in (preload("res://scripts/building_impact.gd").work(title).get("lines",[]) as Array):
		var value:=String(line.value)
		if "." in value or "×" in value or said.size()>=2:continue
		said.append("%s %s" % [String(line.label).to_lower(),value])
	var id:=String(WorldSimulation.state.resource_settlement_id)
	var town:=String(WorldSimulation.settlements.settlement_record(id).get("name","")) if not id.is_empty() else ""
	if town.is_empty():town=String(WorldSimulation.state.settlement_name)
	var before:=works_before(WorldSimulation.state.settlement_completed,title)
	var told:=finished_telling(title,id,town,said,int(WorldSimulation.state.elapsed_days),_era_step(),before)
	return chronicle.record(told) if not told.is_empty() else {}

## Works a town finished before `title` (just added to `completed`), not
## counting the Hearth Circle every new town is founded with
## (settlement_model.gd CITY_RESOURCE_DEFAULTS). An older save's towns have no
## mark in the Chronicle's firsts, so this tells whether it is a town's first.
static func works_before(completed:Array,title:String)->int:
	var n:=0
	var skipped:=false
	for done in completed:
		if String(done)=="Hearth Circle":continue
		if String(done)==title and not skipped:skipped=true;continue
		n+=1
	return n

## The realm's era step (0 bands .. 3 iron and sail), from what the people
## know (character_voice.gd era_tier).
static func _era_step()->int:
	var voice:=preload("res://scripts/character_voice.gd")
	return voice.era_tier(voice.era_tags("player"))

## How a finished work is told. The first of its kind is a moment. After that
## a kind is told once per era step: the same work raised in another town in
## the same step folds into that telling, counted (chronicle.gd fold_as),
## unless it is a new town's first work, which is told as its own notice.
## Marks the Chronicle's firsts; {} when the Chronicle keeps none.
static func finished_telling(title:String,town_id:String,town:String,said:PackedStringArray,day:int,era:int,works_before:int=0)->Dictionary:
	var chronicle=preload("res://scripts/chronicle.gd")
	if not chronicle.active():return {}
	var firsts:Dictionary=chronicle.data().firsts
	var kind_mark:="work:"+title
	var era_mark:="work:%s:era%d" % [title,era]
	var town_mark:="town_work:"+(town_id if not town_id.is_empty() else "home")
	var kind_first:=not firsts.has(kind_mark)
	if kind_first:
		# An older save told its works before these marks were kept.
		for key in chronicle.data().keys:
			if String(key).begins_with("work_done:") and String(key).ends_with(":"+title):kind_first=false;break
	var era_first:=not firsts.has(era_mark)
	# The home's first work is its Hearth Circle; a new town's is its own news.
	var town_first:=not town_id.is_empty() and works_before<=0 and not firsts.has(town_mark)
	for mark in [kind_mark,era_mark,town_mark]:
		if not firsts.has(mark):firsts[mark]=day
	var text:=("Raised at %s" % town) if not town.is_empty() else "Raised"
	if town_first and not kind_first:text+=", its first work"
	text+=(": "+", ".join(said)+".") if not said.is_empty() else "."
	var told:={"key":"work_done:%s:%s" % [town_id,title],"day":day,"title":"The %s %s" % [title,"stand" if title.ends_with("s") else "stands"],"text":text,
		"kind":"work","tier":"moment" if kind_first and title!="Hearth Circle" else "notice","domain":"infrastructure","action":{"kind":"section","section":"construction","sub":0},
		"fold_as":"work_done:%s:era%d" % [title.to_lower(),era],"fold_days":1<<30}
	# A kind's first telling in a new era step, and a new town's first work,
	# each stand on their own.
	if era_first or town_first:told["fold"]=false
	return told

static func set_priority(city_id:String,title:String)->Dictionary:
	var city:=WorldSimulation.settlements.settlement_record(city_id)
	if city.is_empty():return {"error":"Found a settlement before setting construction priorities."}
	if not String(city.get("occupied_by","")).is_empty():return {"error":"Construction is unavailable while occupied."}
	if not title.is_empty():
		var valid:=false
		for project in _settlement_definitions():
			if String(project.name)!=title:continue
			var discovery:=String(project.get("discovery",""))
			valid=discovery.is_empty() or discovery in WorldSimulation.state.known_discoveries
		if not valid:return {"error":"That project is not known."}
	city["construction_priority"]=title
	WorldSimulation.state.settlement_network_revision+=1
	return {"ok":true,"message":"Leader manages construction." if title.is_empty() else title+" prioritized when requirements are met."}
