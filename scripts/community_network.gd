extends Node
const PROJECTS:={
	"records":{"name":"Shared records","purpose":"Preserve useful observations beyond their original teachers.","cost":{"Timber":8,"Fiber Plants":4},"work":120,"domain":"knowledge","effect":"12% faster knowledge research once established."},
	"gathering":{"name":"A recurring gathering","purpose":"Create a place for known communities to exchange ideas without surrendering independence.","cost":{"Timber":16,"Fiber Plants":8},"work":180,"domain":"culture","effect":"12% faster culture research once established."},
	"routes":{"name":"A route-keeping tradition","purpose":"Maintain and teach the routes your scouts have actually returned to describe.","cost":{"Timber":6,"Fiber Plants":6},"work":150,"domain":"logistics","effect":"12% faster logistics research once established."}
}
var active:=""
var progress:=0.0
var completed:Array[String]=[]
var history:Array[Dictionary]=[]
var last_day:=0
var world_seed:=-999999
var panel:Control
var layer:CanvasLayer
func ensure()->void:
	if world_seed==GameState.world_seed: return
	reset_for_new_world(); world_seed=GameState.world_seed; last_day=int(GameState.elapsed_days)
func reset_for_new_world()->void:
	active=""; progress=0; completed.clear(); history.clear(); last_day=0; world_seed=-999999
	if is_instance_valid(panel): panel.queue_free()
func nodes()->Array[Dictionary]:
	var result:Array[Dictionary]=[{"id":"player","name":GameState.settlement_name if GameState.settlement_name!="" else "Your people","treaty":"home","war":false}]
	for known:Dictionary in CivilizationSystem.known_competition_snapshot().get("leaders",[]):
		if String(known.get("id",""))=="player": continue
		var relation:Dictionary=known.get("player_relation",{})
		result.append({"id":known.id,"name":known.name,"treaty":String(relation.get("treaty","none")),"war":bool(relation.get("at_war",false))})
	return result
func blocker(id:String)->String:
	ensure()
	if not PROJECTS.has(id): return "Unknown project."
	if id in completed: return "Already established."
	if active!="": return "One collective project at a time."
	return _prerequisite(id)
func _prerequisite(id:String)->String:
	match id:
		"records":
			if GameState.known_discoveries.is_empty(): return "Requires at least one established discovery to preserve."
		"gathering":
			if not GameState.settlement_site_committed: return "Requires a chosen settlement site."
			if nodes().size()<2: return "Requires direct contact with another community."
		"routes":
			if CivilizationSystem.scout_reports.is_empty(): return "Requires a returned scouting report."
	return ""
func start(id:String)->Dictionary:
	var reason:=blocker(id)
	if reason!="": return {"error":reason}
	var project:Dictionary=PROJECTS[id]
	for item in project.cost:
		if float(GameState.resource_stockpiles.get(item,0))<float(project.cost[item]): return {"error":"Requires %d %s in stores." % [int(project.cost[item]),item]}
	for item in project.cost: GameState.resource_stockpiles[item]=float(GameState.resource_stockpiles.get(item,0))-float(project.cost[item])
	active=id; progress=0; last_day=int(GameState.elapsed_days)
	_log("Backed "+String(project.name)+".")
	return {"ok":true}
func advance(day:int)->void:
	ensure()
	if day<=last_day: return
	var elapsed:=day-last_day; last_day=day
	if active=="" or _prerequisite(active)!="": return
	var workers:=float(GameState.population_allocations.get("Knowledge",0))+float(GameState.population_allocations.get("Administration",0))
	if workers<=0: return
	progress+=elapsed*minf(1.0,workers/4.0)
	if progress>=float(PROJECTS[active].work):
		completed.append(active); _log(String(PROJECTS[active].name)+" is established."); active=""; progress=0
func multiplier(domain:String)->float:
	ensure()
	var bonus:=0.0
	for id in completed:
		if PROJECTS[id].domain==domain: bonus+=.12
	return (1.0+bonus)*(.92 if active!="" else 1.0)
func _log(message:String)->void:
	history.push_front({"day":int(GameState.elapsed_days),"text":message})
	if history.size()>12: history.resize(12)
func propose(id:String,purpose:String)->Dictionary:
	if purpose not in ["open_trade","non_aggression"]: return {"error":"Unknown cooperation proposal."}
	var visible:=false
	for node in nodes():
		if node.id==id and id!="player": visible=true
	if not visible: return {"error":"No known community selected."}
	return CivilizationSystem.dispatch_diplomat(id,"",purpose)
func export_state()->Dictionary:
	ensure()
	return {"version":1,"seed":world_seed,"active":active,"progress":progress,"completed":completed.duplicate(),"history":history.duplicate(true),"last_day":last_day}
func import_state(data:Dictionary)->Dictionary:
	if not data.has_all(["version","seed","active","progress","completed","history","last_day"]): return {"error":"Incomplete network state."}
	if data.get("version",0)!=1 or data.get("seed",0)!=GameState.world_seed: return {"error":"Incompatible network state."}
	if not data.get("completed",[]) is Array or data.completed.size()>3 or not data.get("history",[]) is Array or data.history.size()>12: return {"error":"Invalid network history."}
	var seen:Dictionary={}
	for id in data.completed:
		if not PROJECTS.has(id) or seen.has(id): return {"error":"Invalid completed project."}
		seen[id]=true
	if not data.active is String: return {"error":"Invalid active project."}
	var pending:String=data.active
	if pending!="" and (not PROJECTS.has(pending) or seen.has(pending)): return {"error":"Invalid active project."}
	if not (data.get("progress",0) is float or data.get("progress",0) is int) or not is_finite(float(data.get("progress",0))) or float(data.get("progress",0))<0: return {"error":"Invalid project progress."}
	if (pending=="" and float(data.progress)!=0) or (pending!="" and float(data.progress)>=float(PROJECTS[pending].work)): return {"error":"Invalid project progress."}
	if not (data.last_day is float or data.last_day is int) or not is_finite(float(data.last_day)) or float(data.last_day)<0: return {"error":"Invalid network date."}
	for event in data.history:
		if not event is Dictionary or not event.has_all(["day","text"]): return {"error":"Invalid network event."}
	active=pending; progress=float(data.get("progress",0)); completed.assign(data.completed); history.assign(data.history.duplicate(true)); last_day=int(data.get("last_day",0)); world_seed=GameState.world_seed
	return {"ok":true}
func _unhandled_key_input(event:InputEvent)->void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_F9:
		open_network(); get_viewport().set_input_as_handled()
func open_network()->void:
	ensure()
	if is_instance_valid(panel): panel.queue_free(); return
	if not is_instance_valid(layer): layer=CanvasLayer.new(); layer.layer=82; add_child(layer)
	panel=preload("res://scripts/community_network_screen.gd").new(); layer.add_child(panel)
