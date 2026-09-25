extends "res://scripts/hud/content/dock_content_base.gd"
const Construction:=preload("res://scripts/settlement_construction.gd")
var selected_project:=""
var history_filter:=""
var history:RefCounted

## Individual buildings are drawn from each city's population and construction
## era; this dock shows what builders actually work on: the city's capacity and
## condition, its civic works, its infrastructure and its landmarks.
func meta()->Dictionary:
	return {"eyebrow":"CITIES & INFRASTRUCTURE","title":"Construction","serif":true,"subtabs":["CITY","CIVIC WORKS","INFRASTRUCTURE","LANDMARKS"]}
func tab(sub:int)->Dictionary:
	if sub==3:return preload("res://scripts/hud/content/dock_content_undertakings.gd").new(terrain,hud).tab(0)
	if sub==2:return _infrastructure_tab()
	return SettlementModel.with_city_resources(GameState.selected_player_settlement_id,func()->Dictionary:return SettlementModel.with_local_population(func()->Dictionary:return _city_tab() if sub==0 else _civic_tab()))

const ERAS:=["Founding","Foothold","Hamlet","Village","Local centre","Town","Mature town","Urban system","City","Historic city","Regional system","Industrial age","Metropolitan age"]

## The selected city's built capacity, condition and the builders' material draw.
func _city_tab()->Dictionary:
	var city:=SettlementModel.settlement_record(GameState.selected_player_settlement_id)
	var form:Dictionary=SettlementModel.city_form()
	var capacities:Dictionary=SettlementModel.city_capacities()
	var tier:=clampi(floori(float(form.get("tier",0.0))),0,ERAS.size()-1)
	var paid:=float(form.get("materials_paid",1.0))
	var storage:Dictionary=capacities.get("storage_bulk",{})
	var builders:=int(GameState.population_allocations.get("Construction",0))
	var rows:Array=[
		{"name":"Construction era","value":ERAS[tier],"sub":"Buildings are drawn in this era; it rises with builders, materials, age and knowledge","accent":Tokens.GOLD},
		{"name":"Condition","value":"%d%%" % roundi(float(form.get("condition",1.0))*100.0),"sub":"Builders keep the city in repair; damage and neglect lower it","accent":Tokens.GREEN if float(form.get("condition",1.0))>=.7 else Tokens.AMBER},
		{"name":"Building materials","value":"%d%% supplied" % roundi(paid*100.0),"sub":"Monthly timber, fibre, clay and stone for upkeep and renewal (stone and lime come later, with walls of stone)","accent":Tokens.GREEN if paid>=.9 else Tokens.AMBER},
		{"name":"Builders","value":str(builders),"sub":"Construction workers maintain the city and raise infrastructure","accent":Tokens.MUTED},
		{"name":"Housing","value":"%d places" % int(GameState.housing_capacity),"sub":"%d residents" % int(GameState.population_total),"accent":Tokens.GREEN if int(GameState.housing_capacity)>=int(GameState.population_total) else Tokens.AMBER},
		{"name":"Built storage","value":"%.0f" % (float(storage.get("dry",0))+float(storage.get("covered",0))+float(storage.get("sealed",0))+float(storage.get("secure",0))),"sub":"Dry %.0f · covered %.0f · sealed %.0f · secure %.0f" % [float(storage.get("dry",0)),float(storage.get("covered",0)),float(storage.get("sealed",0)),float(storage.get("secure",0))],"accent":Tokens.MUTED},
		{"name":"Workshops and stores","value":"%d%% · %d%%" % [roundi(float(capacities.get("workshop_function",0))*100.0),roundi(float(capacities.get("storage_function",0))*100.0)],"sub":"How well the city's workshops and stores serve its crafts and logistics","accent":Tokens.MUTED},
	]
	return {"blocks":[{"type":"rows","heading":String(city.get("name","Founding camp")).to_upper(),"note":"The city's look follows its population and era","items":rows}]}

## Civic works: the named early works, in progress and completed.
func _civic_tab()->Dictionary:
	var civic:=_local_tab(0)
	var completed:Array=[]
	for project:Dictionary in Construction._settlement_definitions():
		if String(project.name) in GameState.settlement_completed:completed.append({"name":String(project.name),"value":"Complete","sub":String(project.get("effect","")),"accent":Tokens.GREEN})
	if not completed.is_empty():civic.blocks.append({"type":"rows","heading":"COMPLETED CIVIC WORKS","items":completed})
	return civic

## Infrastructure in every city: water works, conduits, rail, docks and plants.
func _infrastructure_tab()->Dictionary:
	var blocks:Array=[]
	for city:Dictionary in GameState.player_settlements:
		var id:=String(city.get("id",""))
		var rows:Array=SettlementModel.with_city_resources(id,func()->Array:return _infrastructure_rows(id))
		if not rows.is_empty():blocks.append({"type":"rows","heading":String(city.get("name","Settlement")).to_upper(),"items":rows})
	if blocks.is_empty():blocks.append({"type":"text","heading":"INFRASTRUCTURE","text":"No water works, conduits, rail lines, docks or plants yet. Builders raise them once their practices are adopted and materials arrive."})
	return {"blocks":blocks}

static func _infrastructure_rows(city_id:String)->Array:
	var rows:Array=[]
	var works=preload("res://scripts/water_waste_works.gd")
	for work:Dictionary in works.data().get("works",[]):
		rows.append({"name":String(works.SPECS.get(String(work.kind),{}).get("name",String(work.kind).capitalize())),"value":String(work.get("status","")).replace("_"," ").capitalize(),"sub":"Condition %d%%" % roundi(float(work.get("condition",1.0))*100.0),"accent":Tokens.TEAL})
	for line:Dictionary in preload("res://scripts/water_conveyance.gd").data().get("lines",[]):
		rows.append({"name":"Water conduit","value":String(line.get("status","")).replace("_"," ").capitalize(),"sub":"Condition %d%%" % roundi(float(line.get("condition",1.0))*100.0),"accent":Tokens.TEAL})
	for line:Dictionary in preload("res://scripts/rail_freight.gd").data().get("lines",[]):
		rows.append({"name":"Rail line","value":String(line.get("status","")).replace("_"," ").capitalize(),"sub":"%d wagons" % int(line.get("wagons",0)),"accent":Tokens.BLUE})
	for base:Dictionary in MilitaryCampaign.joint_operations.state.get("bases",[]):
		if String(base.get("city_id",""))==city_id:rows.append({"name":"Naval dock","value":"Condition %d%%" % roundi(float(base.get("condition",1.0))*100.0),"accent":Tokens.BLUE})
	var ops=preload("res://scripts/technology_operations.gd")
	if GameState.resource_settlement_id.is_empty():
		for plant:String in ops.data().get("plants",{}):
			var record:Dictionary=ops.data().plants[plant]
			if int(record.get("installed",0))+int(record.get("building",0))<=0:continue
			rows.append({"name":String(ops.PLANTS.get(plant,{}).get("name",plant.capitalize())),"value":"%d installed" % int(record.get("installed",0)),"sub":ops.status(plant),"accent":Tokens.GOLD})
	return rows

func _local_tab(sub:int)->Dictionary:
	var city:=SettlementModel.settlement_record(GameState.selected_player_settlement_id)
	var priority:=String(city.get("construction_priority",""))
	var current:=Construction._current_settlement_project()
	var projects:Array=[]
	for project:Dictionary in Construction._settlement_definitions():
		var done:=String(project.name) in GameState.settlement_completed
		if done!=(sub==1):continue
		var discovery:=String(project.get("discovery",""))
		if not done and not discovery.is_empty() and discovery not in GameState.known_discoveries:continue
		projects.append(_project(project,current,done))
	var stocks:Dictionary={}
	for resource in ["Timber","Stone","Clay","Fiber Plants"]:stocks[resource]=float(GameState.resource_stockpiles.get(resource,0))
	return {"blocks":[{"type":"construction_queue","shelter":preload("res://scripts/hud/shelter_status.gd").describe(GameState.settlement_completed,GameState.housing_capacity,GameState.population_total),"projects":projects,"selected":selected_project,"priority":priority,"stocks":stocks,"city":String(city.get("name","Founding camp")),"builders":int(GameState.population_allocations.get("Construction",0)),"carriers":int(GameState.population_allocations.get("Logistics",0)),"can_prioritize":not city.is_empty() and String(city.get("occupied_by","")).is_empty(),"committed":GameState.settlement_site_committed,"completed":GameState.settlement_completed.size(),"on_select":_select,"on_priority":_priority,"on_site":terrain._on_settlement_action_pressed,"on_record":func():hud.open_detail(preload("res://scripts/hud/content/dock_detail_building_ledger.gd").new(terrain,hud,GameState.selected_player_settlement_id))}]}
func _project(project:Dictionary,current:Dictionary,done:bool)->Dictionary:
	var title:=String(project.name)
	var materials:Dictionary=Construction._settlement_project_material_plan(project)
	var feasible:=not materials.is_empty()
	if not feasible:
		var least_missing:=INF
		for option:Dictionary in Construction.material_options(project):
			if not String(option.get("requires","")).is_empty() and String(option.requires) not in GameState.known_discoveries:continue
			var missing:=0.0
			for resource:String in option.cost:missing+=maxf(0,float(option.cost[resource])-float(GameState.resource_stockpiles.get(resource,0)))/maxf(1,float(option.cost[resource]))
			if missing<least_missing:least_missing=missing;materials=option.cost
	var inputs:Array=[]
	var blockers:Array[String]=[]
	for resource:String in materials:
		var stored:=float(GameState.resource_stockpiles.get(resource,0));var required:=float(materials[resource])
		inputs.append({"resource":resource,"stored":stored,"required":required})
		if stored+.0001<required:blockers.append("Need %.1f %s" % [required-stored,ResourceSystem.display_name(resource)])
	for required in project.requires:
		if String(required) not in GameState.settlement_completed:blockers.push_front("Awaiting "+String(required))
	for role:String in project.minimum:
		var available:=int(GameState.population_allocations.get(role,0))
		if available<=0:blockers.append("No %s workers assigned" % role)
	var discovery:=String(project.get("discovery",""))
	if not discovery.is_empty() and DiscoverySystem.adoption(discovery)<.10:blockers.push_front("Practice not yet adopted")
	if bool(project.get("requires_water",false)) and not bool(GameState.water_metrics.get("source_accessible",false)):blockers.push_front("Water access needed")
	if bool(project.get("known_resource",false)) and ResourceSystem.visible_deposits().is_empty():blockers.push_front("Scout a resource deposit")
	if GameState.convoy_traveling:blockers.push_front("Convoy traveling")
	if not GameState.settlement_site_committed:blockers.push_front("Choose a settlement site")
	var active:=title==String(current.get("name","")) and blockers.is_empty()
	return {"name":title,"done":done,"active":active,"progress":1.0 if done else clampf(float(GameState.settlement_projects.get(title,0))/float(project.days),0,1),"state":"Complete" if done else ("Building" if active else (blockers[0] if not blockers.is_empty() else "Leader planned")),"blockers":blockers,"inputs":inputs,"bill_note":"Selected material mix" if feasible else "Closest known mix · alternatives considered","effect":String(project.get("effect",""))}
func _select(title:String)->void:
	selected_project="" if selected_project==title else title;hud.request_immediate_dock_refresh()
func _priority(title:String)->void:
	terrain._report_military_action(Construction.set_priority(GameState.selected_player_settlement_id,title));hud.request_immediate_dock_refresh()
func signature()->Array:
	return [GameState.selected_player_settlement_id,GameState.settlement_site_committed,GameState.settlement_projects.duplicate(true),GameState.settlement_completed.duplicate(),GameState.resource_stockpiles.duplicate(),GameState.population_allocations.duplicate(),GameState.elapsed_days,GameState.settlement_network_revision,selected_project,GameState.building_ledger.size(),GameState.next_building_record_id,history_filter,history.signature() if history!=null else []]

func _settlements_tab()->Dictionary:
	var blocks:Array=[{"type":"text","heading":"CONSTRUCTION BY SETTLEMENT","text":"Completed works count finished projects. A shelter project can provide several structures. History records later building changes, repairs and losses."}]
	for city:Dictionary in GameState.player_settlements:
		var id:=String(city.get("id",""))
		var report:Dictionary=SettlementModel.with_city_resources(id,func()->Dictionary:
			return _settlement_report(GameState.settlement_completed,GameState.settlement_projects))
		blocks.append({"type":"text","heading":String(city.get("name","Settlement")),"text":"%d completed works · %d underway" % [report.completed,report.underway]})
		if not report.items.is_empty():blocks.append({"type":"rows","items":report.items})
		blocks.append({"type":"actions","items":[{"label":"CONSTRUCTION HISTORY","sub":String(city.get("name","Settlement")),"on_press":_open_city_record.bind(id)}]})
	if GameState.player_settlements.is_empty():blocks.append({"type":"text","heading":"SETTLEMENTS","text":"Choose a settlement site to begin construction."})
	return {"blocks":blocks}

static func _settlement_report(completed:Array,progress:Dictionary)->Dictionary:
	var items:Array=[]
	var underway:=0
	for title in completed:
		items.append({"name":String(title),"value":"1 completed work","accent":Tokens.GREEN})
	for project:Dictionary in Construction._settlement_definitions():
		var title:=String(project.name)
		if title in completed or float(progress.get(title,0))<=0:continue
		underway+=1
		items.append({"name":title,"value":"%.1f%%" % (100.0*clampf(float(progress[title])/float(project.days),0,1)),"sub":"Work in progress","accent":Tokens.AMBER})
	return {"completed":completed.size(),"underway":underway,"items":items}

func _open_city_record(id:String)->void:
	hud.open_detail(preload("res://scripts/hud/content/dock_detail_building_ledger.gd").new(terrain,hud,id))

func _history_tab()->Dictionary:
	if history==null:history=preload("res://scripts/hud/content/dock_detail_building_ledger.gd").new(terrain,hud)
	history.settlement_id=history_filter
	var result:Dictionary=history.tab(0)
	var filters:Array=[{"label":"ALL SETTLEMENTS","on_press":_filter_history.bind("")}]
	for city:Dictionary in GameState.player_settlements:
		filters.append({"label":String(city.get("name","Settlement")),"on_press":_filter_history.bind(String(city.get("id","")))})
	result.blocks.push_front({"type":"actions","items":filters})
	return result

func _filter_history(id:String)->void:
	history_filter=id
	if history!=null:history.pages[0]=0
	hud.request_immediate_dock_refresh()
