extends RefCounted
## A bounded first civilian demand: paper for physically returned study material.
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
	var target:=mini(10,ceili(remaining*S.PAPER_PER_WORK/(1.0+S.BONUS)))
	if target<=0 or float(state.resource_stockpiles.get("Paper",0.0))>=target:return {}
	# Reuse an existing paper line rather than paying to tool a competing method.
	for job:Dictionary in WorldSimulation.military.equipment_queue:
		if String(I.product(String(job.get("item",""))).get("output",""))=="Paper":
			if bool(job.get("persistent",false)) and not bool(job.get("paused",false)):
				return {"item":String(job.item),"target":target}
			return {}
	var chosen:="";var days:=INF
	for item:String in I.PRODUCTS:
		var definition:Dictionary=I.PRODUCTS[item]
		if String(definition.output)!="Paper":continue
		if not P.startup_blockers(WorldSimulation.military,item).is_empty():continue
		if float(definition.days)<days:chosen=item;days=float(definition.days)
	return {} if chosen=="" else {"item":chosen,"target":target}
