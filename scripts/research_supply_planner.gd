extends RefCounted
## AI advice from visible, surveyed sources and actual stores. This chooses a
## research frontier; it neither predicts a complete route nor grants knowledge.
const P=preload("res://scripts/knowledge_pathways.gd")
const R=preload("res://scripts/technology_requirements.gd")

static func frontier(target:String)->Dictionary:
	var state:=WorldSimulation.state
	var discovery:=WorldSimulation.discovery
	var pending:Array[Dictionary]=[{"id":target,"distance":0}]
	var visited:Dictionary={};var result:Dictionary={};var cursor:=0
	while cursor<pending.size():
		var item:Dictionary=pending[cursor];cursor+=1
		var id:=String(item.id)
		if visited.has(id) or id in state.known_discoveries:continue
		visited[id]=true
		var entry:Dictionary=discovery.discovery_definition(id)
		if entry.is_empty():continue
		if discovery._discovery_is_eligible(entry,int(state.elapsed_days)):
			result[id]=int(item.distance);continue
		for route:Dictionary in P.routes(entry):
			var missing:Dictionary=R.evaluate(route,state.known_discoveries)
			var parents:Array=missing.missing_all.duplicate()
			for group:Array in missing.missing_any:parents.append_array(group)
			for parent:String in parents:pending.append({"id":parent,"distance":int(item.distance)+1})
	return result

static func recommendation()->Dictionary:
	var state:=WorldSimulation.state
	if state.effective_workers("Extraction")<=0:return {}
	var best:Dictionary={};var best_score:=-INF;var examined:Dictionary={}
	for deposit:Dictionary in WorldSimulation.resources.visible_deposits():
		var resource:=String(deposit.resource)
		if examined.has(resource) or String(deposit.stage)!="surveyed" or float(deposit.get("access",0))>=1 or float(deposit.get("remaining",0))<=0:continue
		var stock:=maxf(0,float(state.resource_stockpiles.get(resource,0)))
		if stock>=20:continue
		examined[resource]=true
		var definition:Dictionary=WorldSimulation.resources.catalog.get(resource,{})
		for method:String in definition.get("processing",[]):
			var candidates:=frontier(method)
			for id:String in candidates:
				var entry:Dictionary=WorldSimulation.discovery.discovery_definition(id)
				var distance:int=candidates[id]
				var score:=(1.0-stock/20.0)/(1.0+float(distance)*.25)
				score+=clampf(float(state.discovery_progress.get(id,0)),0,1)*.1
				if score>best_score:
					best_score=score;best={"id":id,"domain":String(entry.dynamic),"resource":resource,"method":method,"distance":distance}
	return best
