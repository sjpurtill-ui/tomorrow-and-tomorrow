extends RefCounted
## Follow manufactured inputs for studies, cultivation and commissioned machinery.
## Recommendations grant no materials, knowledge, labor, or workshop capacity.
const I=preload("res://scripts/civilian_industry.gd")
const P=preload("res://scripts/persistent_production.gd")
const E=preload("res://scripts/society_exchange.gd")
const S=preload("res://scripts/paper_study.gd")
static func recommendation(plan_power:bool=false)->Dictionary:
	var research:=study_recommendation(plan_power)
	if not research.is_empty():return research
	var clothing:=clothing_recommendation(plan_power)
	if not clothing.is_empty():return clothing
	var nutrients:=nutrient_recommendation(plan_power)
	return nutrients if not nutrients.is_empty() else operating_input_recommendation(plan_power)

static func study_recommendation(plan_power:bool=false)->Dictionary:
	var state=WorldSimulation.state
	if state.effective_workers("Knowledge")<=0:return {}
	var remaining:=0.0
	for item:Dictionary in E.data().collections.values():
		if int(item.returned_day)>int(state.elapsed_days):continue
		remaining+=maxf(0.0,1.0-float(item.study))*float(item.work)
	var numeric_remaining:=0.0
	for item:Dictionary in E.data().collections.values():
		if int(item.returned_day)<=int(state.elapsed_days) and S.supports("Record Cords",item):numeric_remaining+=maxf(0,1.0-float(item.study))*float(item.work)
	for resource:String in S.MEDIA:
		var spec:Dictionary=S.MEDIA[resource]
		var eligible:=minf(remaining,numeric_remaining) if resource=="Record Cords" else remaining
		var target:=mini(10,ceili(eligible*float(spec.per_work)/(1.0+float(spec.bonus))))
		var covered:=maxf(0,float(state.resource_stockpiles.get(resource,0)))*(1.0+float(spec.bonus))/float(spec.per_work)
		remaining=maxf(0,remaining-minf(eligible,covered))
		if remaining<=0:return {}
		if target<=0:continue
		if float(state.resource_stockpiles.get(resource,0))>=target:return {}
		var candidate:=supply(resource,target,{},plan_power)
		if not candidate.is_empty():return candidate
	return {}

static func usable_input(item:String,input:String)->float:
	var spec:=I.product(item)
	if spec.get("abrasive_inspection","")==input:return preload("res://scripts/abrasive_inspection.gd").available(spec)
	return float(WorldSimulation.state.resource_stockpiles.get(input,0.0))

static func supply(resource:String,target:int,path:Dictionary,plan_power:bool=false)->Dictionary:
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
	var installed:Dictionary={}
	if existing.is_empty() and WorldSimulation.military.equipment_queue.size()>=WorldSimulation.military.production_line_capacity():
		var reusable:=finished_line(resource)
		for job:Dictionary in WorldSimulation.military.equipment_queue:
			if int(job.id)==reusable:installed=P.installed_tooling(job);break
	var best:Dictionary={};var best_work:=INF
	for item:String in candidates:
		var recipe:=P.recipe(WorldSimulation.military,item)
		if recipe.has("error"):continue
		if not plan_power and float(I.PRODUCTS[item].get("power",0.0))>0.0 and preload("res://scripts/technology_operations.gd").service("electricity")<=0.0:continue
		var services_ready:=true
		for service_name:String in I.PRODUCTS[item].get("services",{}):
			if preload("res://scripts/technology_operations.gd").service(service_name)<=0:services_ready=false
		if not services_ready:continue
		var batches:=maxi(1,ceili(target-float(WorldSimulation.state.resource_stockpiles.get(resource,0.0))))
		# A line may begin with one batch in hand; the target is not an upfront
		# reservation. Plan upstream only when the next batch cannot be made.
		var ready:=true
		for input:String in recipe.materials:
			if usable_input(item,input)<float(recipe.materials[input]):ready=false;break
		if existing.is_empty():ready=P.startup_blockers(WorldSimulation.military,item,installed).is_empty()
		elif existing.has("abrasive_pending"):ready=P.state(WorldSimulation.military,existing)=="Working"
		if ready:
			var direct_work:=float(recipe.work_per_item)*batches
			if direct_work<best_work:best={"item":item,"target":target,"work":direct_work};best_work=direct_work
			continue
		var needed:Dictionary={}
		for input:String in recipe.materials:needed[input]=float(recipe.materials[input])*batches
		if existing.is_empty():
			for input:String in P.missing_tooling(recipe.tooling,installed):needed[input]=float(needed.get(input,0.0))+maxf(0,float(recipe.tooling[input])-float(installed.get(input,0)))
		var first:Dictionary={};var possible:=true
		var work:=float(recipe.work_per_item)*batches
		for input:String in needed:
			if usable_input(item,input)>=float(needed[input]):continue
			var input_target:=ceili(float(needed[input]))
			if I.product(item).get("abrasive_inspection","")==input:
				input_target=ceili(float(WorldSimulation.state.resource_stockpiles.get(input,0))+float(needed[input])-usable_input(item,input))
			var upstream:=supply(input,input_target,next,plan_power)
			if upstream.is_empty():possible=false;break
			work+=float(upstream.get("work",0.0))
			if first.is_empty():first=upstream
		if not possible:continue
		if first.is_empty():
			if existing.is_empty() and not P.startup_blockers(WorldSimulation.military,item,installed).is_empty():continue
			first={"item":item,"target":target}
		if work<best_work:best=first.duplicate();best["work"]=work;best_work=work
	return best

static func finished_line(resource:String="")->int:
	for job:Dictionary in WorldSimulation.military.equipment_queue:
		if String(job.get("job_type",""))!="civilian" or not bool(job.get("persistent",false)):continue
		if bool(job.get("paused",false)) or float(job.get("progress_days",0.0))>0.0:continue
		if not (job.get("reserved_materials",{}) as Dictionary).is_empty():continue
		var status:=P.state(WorldSimulation.military,job)
		if status=="Target met":return int(job.id)
		if resource.is_empty() or not bool(job.get("planner_managed",false)) or not status.begins_with("Missing "):continue
		for input:String in job.materials:
			if float(WorldSimulation.state.resource_stockpiles.get(input,0))>.000000001:continue
			if input==resource or input_depends_on(input,resource,{}):return int(job.id)
	return -1


## Only unblock an ancestor of the waiting line's actual missing input. This
## does not let an unrelated new demand steal an unfinished production target.
static func input_depends_on(output:String,resource:String,visited:Dictionary)->bool:
	if visited.has(output) or visited.size()>=24:return false
	var next:=visited.duplicate();next[output]=true
	for item:String in I.PRODUCTS:
		var spec:Dictionary=I.PRODUCTS[item]
		if String(spec.output)!=output or P.recipe(WorldSimulation.military,item).has("error"):continue
		for input:String in spec.materials:
			if input==resource or input_depends_on(input,resource,next):return true
	return false

static func nutrient_recommendation(plan_power:bool=false)->Dictionary:
	var state=WorldSimulation.state
	var nutrition=preload("res://scripts/crop_nutrition.gd")
	var needs:Dictionary=nutrition.needs()
	var choices:Array[Dictionary]=[]
	for nutrient:String in needs:
		var daily:=float(needs[nutrient].daily)
		var available:=float(needs[nutrient].available)
		var deficit:=float(needs[nutrient].deficit)
		if deficit<=.000001:continue
		var best:Dictionary={};var work:=INF
		for resource:String in nutrition.INPUTS:
			var concentration:=float(nutrition.INPUTS[resource].get(nutrient,0))
			if concentration<=0:continue
			var target:=ceili(maxf(0,float(state.resource_stockpiles.get(resource,0)))+minf(10.0,deficit/concentration))
			var candidate:=supply(resource,target,{},plan_power)
			if not candidate.is_empty() and float(candidate.get("work",INF))<work:
				best=candidate;work=float(candidate.work)
		# Avoid making an unusable nutrient when its complement has no supply route.
		if best.is_empty() and available<daily*.1:return {}
		if not best.is_empty():choices.append({"order":best,"coverage":available/daily})
	choices.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return float(a.coverage)<float(b.coverage))
	return {} if choices.is_empty() else choices[0].order

## Replenish manufactured consumables for installed, enabled home machinery.
## Raw extraction and imported supplies remain separate acquisition systems.
static func operating_input_needs()->Dictionary:
	var state=WorldSimulation.state
	if not state.settlement_site_committed or state.convoy_traveling or not state.resource_settlement_id.is_empty():return {}
	if state.effective_workers("Crafting")+preload("res://scripts/technology_operations.gd").reserved_workers(state)<=0:return {}
	var condition:=clampf(float(state.population_health)*float(state.simulation_metrics.get("labor_efficiency",.72)),0,1)
	if condition<=0:return {}
	var daily_inputs:Dictionary={}
	var operations=preload("res://scripts/technology_operations.gd")
	for id:String in operations.data().plants:
		var record:Dictionary=operations.data().plants[id]
		if not record.enabled or int(record.installed)<=0:continue
		var spec:Dictionary=operations.PLANTS[id]
		for item:String in spec.inputs:daily_inputs[item]=float(daily_inputs.get(item,0))+int(record.installed)*condition*float(spec.inputs[item])
	var needs:Dictionary={}
	for item:String in daily_inputs:
		var daily:=float(daily_inputs[item])
		if daily<=0:continue
		var stock:=maxf(0,float(state.resource_stockpiles.get(item,0)))
		var target:=ceili(daily*30.0)
		if stock<target:needs[item]={"daily":daily,"available":stock,"target":target}
	return needs
static func operating_input_recommendation(plan_power:bool=false)->Dictionary:
	var choices:Array[Dictionary]=[]
	var needs:=operating_input_needs()
	for item:String in needs:
		var need:Dictionary=needs[item]
		var candidate:=supply(item,int(need.target),{},plan_power)
		if not candidate.is_empty():choices.append({"order":candidate,"coverage":float(need.available)/float(need.daily)})
	choices.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return float(a.coverage)<float(b.coverage))
	return {} if choices.is_empty() else choices[0].order

## A bounded supply target follows actual clothing needs. This requests an
## ordinary paid civilian line; it grants neither yarn nor textile mastery.
static func figured_clothing_recommendation(plan_power:bool=false)->Dictionary:
	var clothing=preload("res://scripts/household_clothing.gd")
	var state=WorldSimulation.state
	var population:=WorldSimulation.settlements.primary_population_exact()
	# Optional pattern-cloth demand is shared with real city trade targets.
	var target:=int(clothing.figured_target(population))
	if target<=0:return {}
	if float(state.resource_stockpiles.get("Figured Cloth",0))>=target:return {}
	return supply("Figured Cloth",target,{},plan_power)

static func clothing_recommendation(plan_power:bool=false)->Dictionary:
	var state=WorldSimulation.state
	if state.convoy_traveling or not state.settlement_site_committed or not state.resource_settlement_id.is_empty():return {}
	if state.effective_workers("Logistics")<=0 or state.effective_workers("Crafting")<=0:return {}
	var clothing=preload("res://scripts/household_clothing.gd")
	var knowledge=preload("res://scripts/clothing_knowledge.gd")
	var requirements=preload("res://scripts/technology_requirements.gd")
	var population:=WorldSimulation.settlements.primary_population_exact()
	var deficit:=maxf(0,population*1.1-clothing.count())
	var leather_target:=int(clothing.leather_target(population))
	if leather_target>0 and clothing.available("Flexible Leather")<leather_target:
		var leather:=supply("Flexible Leather",leather_target,{},plan_power)
		if not leather.is_empty():return leather
	var figured:=figured_clothing_recommendation(plan_power)
	if not figured.is_empty():return figured
	var best:Dictionary={};var best_work:=INF
	for id:String in knowledge.METHODS:
		var spec:Dictionary=knowledge.METHODS[id]
		if id not in state.known_discoveries or WorldSimulation.discovery.adoption(id)<.1 or not requirements.evaluate(spec,state.known_discoveries).ready:continue
		var amount:=minf(10,deficit)
		var quilt_repairs:=0.0
		if spec.mode=="quilt":
			for lot:Dictionary in clothing.data().lots:
				if lot.kind=="quilt" and float(lot.condition)>=.15 and float(lot.condition)<.6 and int(lot.ready)<=int(state.elapsed_days):quilt_repairs=minf(10,quilt_repairs+float(lot.amount))
		if spec.mode not in clothing.CREATION_MODES:
			amount=0.0
			for lot:Dictionary in clothing.data().lots:
				if int(lot.ready)>int(state.elapsed_days) or not clothing.compatible_service(String(spec.mode),lot):continue
				if (spec.mode in ["wash","machine_wash"] and float(lot.soil)>=.35) or (spec.mode=="wick" and not lot.wick) or (spec.mode=="repair" and float(lot.condition)>=.15 and float(lot.condition)<.6):amount+=float(lot.amount)
			if spec.mode=="test":
				amount=1.0 if clothing.count()-population>=.25 else 0.0
				for trial:Dictionary in clothing.data().get("trials",{}).values():
					if int(trial.cycles)<5:amount+=1.0
			amount=minf(10,amount)
		if amount<=.000001 and quilt_repairs<=.000001:continue
		var needed:Dictionary={}
		var inputs:=clothing.materials(id)
		for item:String in inputs:needed[item]=amount*float(inputs[item])
		if quilt_repairs>0:
			for item:String in clothing.QUILT_REPAIR_INPUTS:
				var cost:float=clothing.QUILT_REPAIR_INPUTS[item]
				needed[item]=float(needed.get(item,0))+quilt_repairs*cost
		if int(clothing.data().tools.get(id,0))==0:
			var costs:=clothing.materials(id,true)
			for item:String in costs:needed[item]=float(needed.get(item,0))+float(costs[item])
		var first:Dictionary={};var possible:=true;var work:=0.0
		for item:String in needed:
			if clothing.available(item)>=float(needed[item]):continue
			var order:=supply(item,ceili(float(needed[item])),{},plan_power)
			if order.is_empty():possible=false;break
			if first.is_empty():first=order
			work+=float(order.get("work",0))
		if possible and not first.is_empty() and work<best_work:best=first;best_work=work
	return best
