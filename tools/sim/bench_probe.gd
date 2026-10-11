extends "res://tools/sim/truth_probe.gd"
## The simulator bench's run of the real engine (tools/sim/bench.py): the
## truth probe's disposable people, set up from a JSON file of the bench's
## numbers (--spec=<file>: research, start_population, site_profile, ambition,
## phases) and read each year with the game's own readings on top of the
## truth row (row.bench: the nine strengths, the watch, goods, the built
## fabric, the stores and every number in simulation_metrics). Run with
## --span=N for the game's multi-day steps and --stream=<file> for a row a
## year as it happens. Headless, never the player's game.
##   Godot --headless --path <wt> res://tools/sim/bench_probe.tscn -- --scenario=sensible --seed=1 --years=100 --span=30 --spec=<json> --stream=<jsonl> --out=<json>

const BenchStanding:=preload("res://scripts/standing.gd")
const BenchWatch:=preload("res://scripts/watch_military.gd")
const BenchGoods:=preload("res://scripts/civilian_goods.gd")
const BenchFabric:=preload("res://scripts/built_fabric.gd")
const BenchManual:=preload("res://scripts/manual_work.gd")

var _spec:Dictionary={}
var _phase_done:=-1

func _spec_data()->Dictionary:
	if _spec.is_empty():
		var path:=_arg("spec","")
		if path!="":
			var parsed:Variant=JSON.parse_string(FileAccess.get_file_as_string(path))
			if parsed is Dictionary:_spec=parsed
		if _spec.is_empty():_spec={"none":true}
	return _spec

func _scenarios()->Dictionary:
	var spec:=_spec_data()
	var all:Dictionary=super._scenarios()
	for name:String in all:
		var scenario:Dictionary=all[name]
		if spec.get("research") is Dictionary and not (spec.research as Dictionary).is_empty():scenario["research"]=spec.research
		if spec.has("start_population"):scenario["population"]=int(spec.start_population)
	return all

func _site_profile(origin:Vector2,site:String)->Dictionary:
	var profile:Dictionary=super._site_profile(origin,site)
	var land:Variant=_spec_data().get("site_profile")
	if land is Dictionary:
		for key:String in land:profile[key]=float(land[key])
	return profile

func _row(year:int,tally:Dictionary,start:int)->Dictionary:
	var row:Dictionary=super._row(year,tally,start)
	row["bench"]=_readings()
	_apply_phases(year)
	return row

## The ambition at the founding, and each change of course in its year.
func _apply_phases(year:int)->void:
	var spec:=_spec_data()
	if year==0 and String(spec.get("ambition","makers"))!="makers":
		WorldSimulation.submit("ec",{"kind":"ambition","id":String(spec.ambition)})
	var phases:Array=spec.get("phases",[]) if spec.get("phases") is Array else []
	for index in phases.size():
		var phase:Dictionary=phases[index]
		if index<=_phase_done or float(phase.get("from",0))>float(year):continue
		_phase_done=index
		if phase.get("manual") is Dictionary:
			BenchManual.set_manual(true)
			WorldSimulation.direction.work_baseline=(phase.manual as Dictionary).duplicate()
			BenchManual.apply()
		elif String(phase.get("path",""))!="":
			BenchManual.set_manual(false)
			WorldSimulation.submit("ec",{"kind":"work_path","path":String(phase.path),"why":"bench"})

func _readings()->Dictionary:
	var state:=WorldSimulation.state
	var people:=maxf(1.0,float(state.population_total))
	var out:={}
	var strengths:Dictionary=BenchStanding.values()
	for id:String in strengths:
		if strengths[id] is Dictionary:out["st_"+id]=snappedf(float((strengths[id] as Dictionary).get("value",0.0))*100.0,0.1)
	out["field_strength"]=snappedf(BenchStanding.our_fighting_strength(),0.01)
	var watch:Dictionary=BenchWatch.reading(WorldSimulation.military)
	for key:String in ["watch","drill","armed","guard","serving","able"]:out[key]=snappedf(float(watch.get(key,0.0)),0.001)
	var goods:=BenchGoods.stock()
	out["goods"]=snappedf(goods,0.01)
	out["goods_per_head"]=snappedf(goods/people,0.001)
	out["goods_cover"]=snappedf(BenchGoods.coverage(),0.001)
	out["goods_per_maker_day"]=snappedf(BenchGoods.goods_per_maker_day(),0.001)
	if not (state.built_fabric as Dictionary).is_empty():
		out["home_quality"]=snappedf(BenchFabric.quality(),0.001)
		out["roads"]=snappedf(BenchFabric.roads(),0.001)
		out["beauty"]=snappedf(BenchFabric.beauty(),0.001)
		out["stone_share"]=snappedf(BenchFabric.stone(),0.001)
		out["craft"]=snappedf(BenchFabric.craft(),0.01)
	out["walls"]=float(int(WorldSimulation.military.settlement_defense_snapshot().get("stage",0)))
	out["housing_places"]=float(state.housing_capacity)
	var works:={"great_works":0,"works_under_way":0}
	for city:Dictionary in state.player_settlements:
		for record:Dictionary in city.get("undertakings",[]):
			if String(record.get("status",""))=="complete":works.great_works+=1
			else:works.works_under_way+=1
	out.merge(works)
	for key:Variant in state.resource_stockpiles:
		var held:Variant=state.resource_stockpiles[key]
		if (held is float or held is int) and absf(float(held))>0.0005:out["stock_"+String(key)]=snappedf(float(held),0.01)
	for key:Variant in state.simulation_metrics:
		var value:Variant=state.simulation_metrics[key]
		if value is float or value is int:out["m_"+String(key)]=snappedf(float(value),0.0001)
	return out
