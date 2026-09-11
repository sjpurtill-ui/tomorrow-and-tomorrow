extends RefCounted
## Follow manufactured inputs for bounded paper demand from returned studies.
## Recommendations grant no materials, knowledge, labor, or workshop capacity.
const I=preload("res://scripts/civilian_industry.gd")
const P=preload("res://scripts/persistent_production.gd")
const E=preload("res://scripts/society_exchange.gd")
const S=preload("res://scripts/paper_study.gd")
static func recommendation()->Dictionary:
	var state=WorldSimulation.state
	if state.effective_workers("Knowledge")<=0:return {}
	var remaining:=0.0
	for item:Dictionary in E.data().collections.values():
		if int(item.returned_day)>int(state.elapsed_days):continue
		remaining+=maxf(0.0,1.0-float(item.study))*float(item.work)
	var printed_target:=mini(10,ceili(remaining*S.PAPER_PER_WORK/(1.0+S.PRINTED_BONUS)))
	remaining=maxf(0.0,remaining-maxf(0.0,float(state.resource_stockpiles.get("Printed Sheets",0.0)))*(1.0+S.PRINTED_BONUS)/S.PAPER_PER_WORK)
	if remaining<=0.0:return {}
	var printed:=supply("Printed Sheets",printed_target,{})
	if not printed.is_empty():return printed
	var target:=mini(10,ceili(remaining*S.PAPER_PER_WORK/(1.0+S.BONUS)))
	if target<=0 or float(state.resource_stockpiles.get("Paper",0.0))>=target:return {}
	return supply("Paper",target,{})

static func supply(resource:String,target:int,path:Dictionary)->Dictionary:
	if path.has(resource) or path.size()>=24:return {}
	var next:=path.duplicate();next[resource]=true
	var candidates:Array[String]=[]
	var existing:Dictionary={}
	for job:Dictionary in WorldSimulation.military.equipment_queue:
		if String(I.product(String(job.get("item",""))).get("output",""))!=resource:continue
		if not bool(job.get("persistent",false)) or bool(job.get("paused",false)):return {}
		existing=job;candidates.append(String(job.item));break
	if existing.is_empty():
		for item:String in I.PRODUCTS:
			if String(I.PRODUCTS[item].output)==resource:candidates.append(item)
	var best:Dictionary={};var best_work:=INF
	for item:String in candidates:
		var recipe:=P.recipe(WorldSimulation.military,item)
		if recipe.has("error"):continue
		if float(I.PRODUCTS[item].get("power",0.0))>0.0 and preload("res://scripts/technology_operations.gd").service("electricity")<=0.0:continue
		var batches:=maxi(1,ceili(target-float(WorldSimulation.state.resource_stockpiles.get(resource,0.0))))
		# A line may begin with one batch in hand; the target is not an upfront
		# reservation. Plan upstream only when the next batch cannot be made.
		var ready:=true
		for input:String in recipe.materials:
			if float(WorldSimulation.state.resource_stockpiles.get(input,0.0))<float(recipe.materials[input]):ready=false;break
		if existing.is_empty():ready=P.startup_blockers(WorldSimulation.military,item).is_empty()
		if ready:
			var direct_work:=float(recipe.work_per_item)*batches
			if direct_work<best_work:best={"item":item,"target":target,"work":direct_work};best_work=direct_work
			continue
		var needed:Dictionary={}
		for input:String in recipe.materials:needed[input]=float(recipe.materials[input])*batches
		if existing.is_empty():
			for input:String in recipe.tooling:needed[input]=float(needed.get(input,0.0))+float(recipe.tooling[input])
		var first:Dictionary={};var possible:=true
		var work:=float(recipe.work_per_item)*batches
		for input:String in needed:
			if float(WorldSimulation.state.resource_stockpiles.get(input,0.0))>=float(needed[input]):continue
			var upstream:=supply(input,ceili(float(needed[input])),next)
			if upstream.is_empty():possible=false;break
			work+=float(upstream.get("work",0.0))
			if first.is_empty():first=upstream
		if not possible:continue
		if first.is_empty():
			if existing.is_empty() and not P.startup_blockers(WorldSimulation.military,item).is_empty():continue
			first={"item":item,"target":target}
		if work<best_work:best=first.duplicate();best["work"]=work;best_work=work
	return best

static func finished_line()->int:
	for job:Dictionary in WorldSimulation.military.equipment_queue:
		if String(job.get("job_type",""))!="civilian" or not bool(job.get("persistent",false)):continue
		if bool(job.get("paused",false)) or float(job.get("progress_days",0.0))>0.0:continue
		if not (job.get("reserved_materials",{}) as Dictionary).is_empty():continue
		if P.state(WorldSimulation.military,job)=="Target met":return int(job.id)
	return -1
