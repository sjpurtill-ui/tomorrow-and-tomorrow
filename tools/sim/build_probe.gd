extends "res://tools/sim/truth_probe.gd"
## Phase 1 diagnostic (codex/built-fabric): what the builders actually do, day
## by day, on the real engine. Run with --debug_days=<years*365> so _row is
## called every day; each day's builder-days are booked to what they worked
## on (a civic work, new homes, or nothing but repair), and a small row is
## written once a year. Headless, disposable actor, as truth_probe.
##   Godot --headless --path <wt> res://tools/sim/build_probe.tscn -- --path=building --years=10 --debug_days=3650 --out=<file.json>

var _calls:=0
var _use:={"project":0.0,"homes":0.0,"idle":0.0}
var _project_days:={}

func _row(year:int,tally:Dictionary,start:int)->Dictionary:
	var state:=WorldSimulation.state
	var C:=preload("res://scripts/settlement_construction.gd")
	var builders:=float(state.effective_workers("Construction"))
	var project:Dictionary=C._current_settlement_project()
	var kind:="idle"
	if not project.is_empty():
		kind="project"
		_project_days[String(project.name)]=float(_project_days.get(String(project.name),0.0))+builders
	elif C.housing_under_way():kind="homes"
	_use[kind]=float(_use[kind])+builders
	var day:=_calls
	_calls+=1
	if day%365!=0:return {"year":year}
	var form:Dictionary=WorldSimulation.settlements.city_form()
	var defense:Dictionary=WorldSimulation.military.settlement_defense_snapshot()
	var works:Array=[]
	for city:Dictionary in state.player_settlements:
		for r:Dictionary in city.get("undertakings",[]):works.append({"id":String(r.id),"status":String(r.status),"progress":float(r.get("progress",0.0))})
	var stocks:Dictionary={}
	for key in ["Timber","Stone","Clay","Fiber Plants","Civilian Goods"]:stocks[key]=snappedf(float(state.resource_stockpiles.get(key,0.0)),0.1)
	return {"year":year,"day":day,"population":state.population_total,"builders":snappedf(builders,0.01),"builder_share":snappedf(float(state.population_allocation_percentages.get("Construction",0.0)),0.1),
		"places":int(state.housing_capacity),"housing_ratio":snappedf(float(state.simulation_metrics.get("housing_ratio",0.0)),0.001),"completed":state.settlement_completed.duplicate(),
		"project":String(project.get("name","")),"daily_work":snappedf(C.daily_work(),0.001),"homes_building":C.housing_under_way(),
		"use_builder_days":_use.duplicate(),"project_builder_days":_project_days.duplicate(),
		"city_tier":snappedf(float(form.get("tier",0.0)),0.01),"city_condition":snappedf(float(form.get("condition",0.0)),0.001),"materials_paid":snappedf(float(form.get("materials_paid",0.0)),0.01),
		"defense_stage":int(defense.get("stage",0)),"defense_project":(defense.get("construction",{}) as Dictionary).get("name",""),
		"great_works":works,"stocks":stocks,"labor_efficiency":snappedf(float(state.simulation_metrics.get("labor_efficiency",0.0)),0.001),
		"health":snappedf(state.population_health,0.001),"cohesion":snappedf(float(state.simulation_metrics.get("cohesion",0.0)),0.001),
		"standing_splendor":snappedf(float(state.simulation_metrics.get("standing_splendor",0.0)),0.001),"standing_might":snappedf(float(state.simulation_metrics.get("standing_might",0.0)),0.001),
		"standing_awe":snappedf(float(state.simulation_metrics.get("standing_awe",0.0)),0.001),"standing_allure":snappedf(float(state.simulation_metrics.get("standing_allure",0.0)),0.001),
		"fabric":_fabric(),"known":state.known_discoveries.size(),"seconds":(Time.get_ticks_msec()-start)/1000.0}

func _fabric()->Dictionary:
	var F:=preload("res://scripts/built_fabric.gd")
	var f:Dictionary=WorldSimulation.state.built_fabric
	if f.is_empty():return {}
	var homes:Array=[]
	for v in (f.homes as Array):homes.append(snappedf(float(v),0.001))
	var spent:Dictionary={}
	for k in (f.get("spent",{}) as Dictionary):spent[k]=snappedf(float(f.spent[k]),0.1)
	return {"homes":homes,"quality":snappedf(F.quality(),0.001),"roads":snappedf(F.roads(),0.001),"beauty":snappedf(F.beauty(),0.001),"cover":snappedf(float((f.effects as Dictionary).get("cover",0.0)),0.001),
		"craft":snappedf(F.craft(),0.01),"craft_settles":snappedf(F.craft_settles(),0.01),"paid":snappedf(float(f.get("paid",1.0)),0.01),"spent":spent,"idle":snappedf(float(f.get("idle",0.0)),0.1),"caps":F.grade_caps()}
