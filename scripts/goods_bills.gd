extends RefCounted
## Bills of materials without civilian intermediates.
##
## Plants, infrastructure, research programmes and military equipment used to
## name manufactured civilian parts (motors, cable, glass, cloth, fitted
## timber). Those parts are no longer made on separate lines: a bill that
## names one is expanded, through the former recipe, into the raw materials it
## was made from plus Civilian Goods for the craft work. Military equipment and
## other end items keep their own names; only their inputs are flattened.

const Industry=preload("res://scripts/civilian_industry.gd")
const Goods=preload("res://scripts/civilian_goods.gd")
## Civilian Goods charged per workshop day a former recipe took.
const GOODS_PER_RECIPE_DAY:=1.0
## Deepest recipe chain followed; deeper parts are charged as goods.
const MAX_DEPTH:=24
## Outputs of former recipes that are also extracted from deposits. Tables are
## flattened when scripts load, before the resource catalog exists.
const EXTRACTED:={"Refractory Clay":true}
## Materials that are gathered, extracted or collected rather than made: the
## deposit catalog plus hunting byproducts and money. Anything else a recipe
## names that no recipe makes is a workshop byproduct and counts as goods.
const RAW:={"Timber":true,"Freshwater":true,"Stone":true,"Fertile Soil":true,"Game":true,"Fiber Plants":true,"Clay":true,"Flint":true,"Salt":true,"Medicinal Plants":true,"Peat":true,"Limestone":true,"Copper Ore":true,"Tin Ore":true,"Lead Ore":true,"Bitumen":true,"Fine Sand":true,"Iron Ore":true,"Coal":true,"Sulfur":true,"Nitrates":true,"Deep Aquifer":true,"Refractory Clay":true,"Phosphate Rock":true,"Uranium Ore":true,"Graphite":true,"Silver Ore":true,"Gold Ore":true,"Crude Oil":true,"Nickel Ore":true,"Bauxite":true,"Rutile Ore":true,"Ochre Earth":true,
	"Raw Hides":true,"Recovered Animal Fat":true,"Recovered Bone":true,"Pancreatic Tissue":true,"Food":true,"Coin":true,"Civilian Goods":true}

static var _by_output:Dictionary={}
static var _co_products:Dictionary={}
static var _expanded:Dictionary={}
static var _cache:Dictionary={}

## The recipe that made `item`, preferring the shortest one when several did.
static func _recipe_for(item:String)->Dictionary:
	if _by_output.is_empty():
		for id:String in Industry.PRODUCTS:
			var definition:Dictionary=Industry.PRODUCTS[id]
			var output:=String(definition.get("output",""))
			if output.is_empty():continue
			if not _by_output.has(output):_by_output[output]=[]
			_by_output[output].append(definition)
			for co:String in definition.get("co_products",{}):_co_products[co]=true
		# Prefer the recipe that starts from raw or makeable inputs (not a
		# recycling or inspection step fed by byproducts), then the quickest.
		for output:String in _by_output:
			var best:Dictionary={};var best_score:=INF
			for definition:Dictionary in _by_output[output]:
				var score:=float(definition.get("days",0))
				for part:String in definition.get("materials",{}):
					if not RAW.has(part) and not _by_output.has(part):score+=1000.0
				if score<best_score:best=definition;best_score=score
			_by_output[output]=best
	return _by_output.get(item,{})

## Whether `item` is a manufactured civilian part that bills no longer name.
## Extracted and gathered materials (RAW) are never expanded.
static func manufactured(item:String)->bool:
	if item in Goods.LEGACY_PRODUCTS:return true
	if EXTRACTED.has(item) or RAW.has(item):return false
	return not _recipe_for(item).is_empty() or _co_products.has(item)

## Raw materials and Civilian Goods for one unit of `item`.
static func _unit(item:String,depth:int,visiting:Dictionary)->Dictionary:
	if _expanded.has(item):return _expanded[item]
	if item in Goods.LEGACY_PRODUCTS:return {Goods.GOODS:1.0}
	if not manufactured(item):
		# Inside a former recipe, an input nothing makes and nobody extracts is a
		# workshop byproduct (offcuts, rejected parts, separated gases): goods.
		return {Goods.GOODS:1.0} if depth>0 and not RAW.has(item) else {item:1.0}
	var recipe:=_recipe_for(item)
	# Byproducts of former recipes (offcuts, rejected parts, separated gases)
	# count as ordinary goods.
	if recipe.is_empty():return {Goods.GOODS:1.0}
	if depth>=MAX_DEPTH or visiting.has(item):return {Goods.GOODS:GOODS_PER_RECIPE_DAY}
	visiting[item]=true
	# Recipe quantities are per batch; a batch yields one unit of the output.
	var result:Dictionary={Goods.GOODS:GOODS_PER_RECIPE_DAY*maxf(0.25,float(recipe.get("days",1.0)))}
	var materials:Dictionary=recipe.get("materials",{})
	for part:String in materials:
		var expanded:=_unit(part,depth+1,visiting)
		for raw:String in expanded:result[raw]=float(result.get(raw,0.0))+float(expanded[raw])*float(materials[part])
	visiting.erase(item)
	_expanded[item]=result
	return result

## `bill` with every manufactured civilian part replaced by its raw materials
## and Civilian Goods. Other entries are unchanged. Cached by content.
static func flatten(bill:Dictionary)->Dictionary:
	if bill.is_empty():return bill
	var key:=bill.hash()
	var cached:Variant=_cache.get(key)
	if cached!=null:return cached
	var result:Dictionary={}
	var changed:=false
	for item:String in bill:
		if not manufactured(item):
			result[item]=float(result.get(item,0.0))+float(bill[item])
			continue
		changed=true
		var unit:=_unit(item,0,{})
		for raw:String in unit:result[raw]=float(result.get(raw,0.0))+float(unit[raw])*float(bill[item])
	if not changed:result=bill
	result.make_read_only()
	if _cache.size()>=4096:_cache.clear()
	_cache[key]=result
	return result

## A table of specs whose listed bill fields are flattened, for module tables
## that used to name manufactured parts.
static func flatten_table(table:Dictionary,fields:Array)->Dictionary:
	var result:Dictionary={}
	for id in table:
		var spec:Variant=table[id]
		if not spec is Dictionary:result[id]=spec;continue
		var copy:Dictionary=(spec as Dictionary).duplicate(true)
		for field:String in fields:
			if copy.get(field) is Dictionary:copy[field]=flatten(copy[field]).duplicate()
		result[id]=copy
	return result
