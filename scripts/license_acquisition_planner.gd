extends RefCounted
## License existing dependent lines or immediately supplied study production.
## Leads are examined returned evidence or the civilization's own contracts.
const L=preload("res://scripts/research_licenses.gd")
const E=preload("res://scripts/society_exchange.gd")
const I=preload("res://scripts/civilian_industry.gd")
const Supply=preload("res://scripts/civilian_production_planner.gd")
const Paper=preload("res://scripts/paper_study.gd")
static func recommendation(plan:Dictionary={})->Dictionary:
	var state=WorldSimulation.state;var world=WorldSimulation.world
	if bool(plan.get("hungry",false)) or bool(plan.get("at_war",false)) or not world.diplomatic_mission.is_empty():return {}
	if not L.available() or state.effective_workers("Crafting")<1:return {}
	var wanted:=demanded_subjects()
	if wanted.is_empty():return {}
	var leads:Array[Dictionary]=[]
	for item:Dictionary in E.data().collections.values():
		if float(item.get("study",0))>=1 and int(item.get("returned_day",0))<=int(state.elapsed_days):
			leads.append({"source":String(item.get("source_id","")),"subject":String(item.get("discovery_id",""))})
	for subject:String in L.records():leads.append({"source":String(L.records()[subject].source),"subject":subject})
	var best:Dictionary={};var best_score:=-INF;var considered:Dictionary={}
	for lead:Dictionary in leads:
		var source:=String(lead.source);var subject:=String(lead.subject)
		if source.is_empty() or not wanted.has(subject):continue
		var key:=source+":"+subject
		if considered.has(key):continue
		considered[key]=true
		var recent:=false
		for mission:Dictionary in world.diplomatic_history:
			if String(mission.get("research_mode",""))=="license" and String(mission.get("research_subject",""))==subject and E.owner_id(String(mission.get("civ_id","")))==E.owner_id(source) and int(state.elapsed_days)-int(mission.get("returned_day",0))<30:recent=true;break
		if recent:continue
		for gift:Dictionary in world.diplomatic_gift_options(source):
			if String(gift.resource)=="Food" or not bool(gift.can_send) or float(gift.amount)>float(gift.available)*.10:continue
			var quote:=L.quote(source,subject,String(gift.resource))
			if quote.has("error"):continue
			var score:=float(wanted[subject])-float(quote.total_days)/365.0-float(gift.amount)/maxf(1,float(gift.available))
			if score>best_score:best_score=score;best={"kind":"research_license","source":source,"subject":subject,"resource":String(gift.resource)}
	return best
static func supplied(recipe:Dictionary,tooling:bool)->bool:
	var costs:Dictionary=recipe.materials.duplicate()
	if tooling:
		for resource:String in recipe.tooling:costs[resource]=float(costs.get(resource,0))+float(recipe.tooling[resource])
	for resource:String in costs:
		if float(WorldSimulation.state.resource_stockpiles.get(resource,0))<float(costs[resource]):return false
	return true
static func demanded_subjects()->Dictionary:
	var wanted:Dictionary={};var state=WorldSimulation.state
	for job:Dictionary in WorldSimulation.military.equipment_queue:
		if not bool(job.get("persistent",false)) or bool(job.get("paused",false)):continue
		var recipe:=I.product(String(job.get("item","")))
		if recipe.is_empty() or L.independent(String(recipe.gate)):continue
		if int(job.get("target_stock",0))>0 and float(state.resource_stockpiles.get(recipe.output,0))>=int(job.target_stock):continue
		if supplied(recipe,false):wanted[recipe.gate]=3.0
	if state.effective_workers("Knowledge")<=0 or not Supply.recommendation().is_empty():return wanted
	var remaining:=0.0
	for item:Dictionary in E.data().collections.values():
		if int(item.get("returned_day",0))<=int(state.elapsed_days):remaining+=maxf(0,1-float(item.get("study",0)))*float(item.get("work",0))
	remaining-=maxf(0,float(state.resource_stockpiles.get("Printed Sheets",0)))*(1.0+Paper.PRINTED_BONUS)/Paper.PAPER_PER_WORK
	remaining-=maxf(0,float(state.resource_stockpiles.get("Paper",0)))*(1.0+Paper.BONUS)/Paper.PAPER_PER_WORK
	if remaining<=0:return wanted
	for recipe:Dictionary in I.PRODUCTS.values():
		if String(recipe.output) not in ["Paper","Printed Sheets"] or L.independent(String(recipe.gate)):continue
		if not supplied(recipe,true):continue
		if float(recipe.get("power",0))>0 and preload("res://scripts/technology_operations.gd").service("electricity")<=0:continue
		if not wanted.has(recipe.gate):wanted[recipe.gate]=1.0
	return wanted
