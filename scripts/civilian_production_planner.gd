extends RefCounted
## Workshop supply orders for stocked military items. Civilian manufactures are
## Civilian Goods made by Crafting households, so a bill that names raw
## materials or Civilian Goods has nothing to order from a line. Callers that
## follow a missing input here receive {} and treat the chain as unsupplied.
## Recommendations grant no materials, knowledge, labor, or workshop capacity.
const P=preload("res://scripts/persistent_production.gd")
## Former recipe table; infrastructure planners read product metadata through it.
const I=preload("res://scripts/civilian_industry.gd")
## Stockpile resources that a military line makes, keyed to its product id.
const LINE_PRODUCTS:={"Transport Carts":"transport_cart"}

## No civilian line orders remain: studies, clothing, crop nutrients and plant
## operating inputs draw on Civilian Goods and raw materials directly.
static func recommendation(_plan_power:bool=false)->Dictionary:
	return {}

## A bounded order that raises `resource` to `target` from a military line,
## or {} when no line makes it or the next batch cannot be supplied.
static func supply(resource:String,target:int,_path:Dictionary={},_plan_power:bool=false)->Dictionary:
	var item:=String(LINE_PRODUCTS.get(resource,""))
	if item.is_empty():return {}
	var host=WorldSimulation.military
	var recipe:=P.recipe(host,item)
	if recipe.has("error"):return {}
	var existing:Dictionary={}
	for job:Dictionary in host.equipment_queue:
		if String(job.get("item",""))!=item:continue
		if not bool(job.get("persistent",false)) or bool(job.get("paused",false)):return {}
		existing=job;break
	# A line may begin with one batch in hand; the target is not an upfront
	# reservation. Inputs are raw materials and goods, never another line.
	if existing.is_empty():
		if not P.startup_blockers(host,item).is_empty():return {}
	else:
		for input:String in recipe.materials:
			if float(WorldSimulation.state.resource_stockpiles.get(input,0.0))<float(recipe.materials[input]):return {}
	var batches:=maxi(1,ceili(target-float(WorldSimulation.state.resource_stockpiles.get(resource,0.0))))
	return {"item":item,"target":target,"work":float(recipe.work_per_item)*batches}

## Former civilian lines are retired, so none is ever free to reuse.
static func finished_line(_resource:String="")->int:
	return -1

## No line makes a civilian part, so no line input depends on another line.
static func input_depends_on(_output:String,_resource:String,_visited:Dictionary)->bool:
	return false

## Study media are Civilian Goods; no study line is ever ordered.
static func study_recommendation(_plan_power:bool=false)->Dictionary:
	return {}

## Plant operating inputs are raw materials and Civilian Goods, never a line.
static func operating_input_needs()->Dictionary:
	return {}

static func clothing_recommendation(_plan_power:bool=false)->Dictionary:
	# Clothing is made as part of Civilian Goods; there are no garment lines.
	return {}
