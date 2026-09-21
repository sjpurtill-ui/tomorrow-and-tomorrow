extends "res://scripts/hud/content/dock_content_base.gd"
const Construction:=preload("res://scripts/settlement_construction.gd")
var selected_project:=""
var history_filter:=""
var history:RefCounted

func meta()->Dictionary:
	return {"eyebrow":"BUILDINGS & INFRASTRUCTURE","title":"Construction","serif":true,"subtabs":["PROJECTS","COMPLETED","SETTLEMENTS","HISTORY"]}
func tab(sub:int)->Dictionary:
	if sub==2:return _settlements_tab()
	if sub==3:return _history_tab()
	return SettlementModel.with_city_resources(GameState.selected_player_settlement_id,func()->Dictionary:return SettlementModel.with_local_population(func()->Dictionary:return _local_tab(sub)))
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
