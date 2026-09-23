extends RefCounted
## Household clothing is part of Civilian Goods. Adopted clothing techniques
## decide how much protection a supplied household's garments give; goods
## coverage decides how many households are actually supplied. Hunting still
## yields hides, fat, bone and gland tissue as local byproducts.
const K=preload("res://scripts/clothing_knowledge.gd")
const Goods=preload("res://scripts/civilian_goods.gd")
const HUNTING_BYPRODUCTS:={"Pancreatic Tissue": "Selected gland tissue from actual newly hunted rations, bounded and rapidly decaying","Recovered Animal Fat": "Actual newly hunted rations, once per local day; bounded stock and daily decay","Raw Hides": "Actual newly hunted rations, once per local day; bounded stock and daily decay","Recovered Bone":"Ordinary local hunting byproduct, bounded and collected once per local day"}
const BONE_RESOURCE:="Recovered Bone"
## Cold protection a fully supplied household gains from each garment method.
const INSULATION:={"knit":.32,"twill":.25,"pile":.48,"sew":.32,"fit":.42,"grade":.42,"leather":.32,"tied":.25,"quilt":.50,"rain_shell":.18}
## Protection any settled household keeps from basic wraps and skins.
const BASE_COLD:=.12
const BASE_STORM:=.06

static func empty_state()->Dictionary:return {"last_day":-1,"report":{}}
static func data()->Dictionary:return WorldSimulation.state.household_clothing
static func available(item:String)->float:
	return maxf(0,float(WorldSimulation.state.resource_stockpiles.get(item,0)))

## Adopted garment protection for a supplied household.
static func protection()->Dictionary:
	var best_cold:=0.0;var layers:=0.0;var storm:=0.0
	for id:String in K.METHODS:
		if id not in WorldSimulation.state.known_discoveries:continue
		var adoption:=clampf(WorldSimulation.discovery.adoption(id),0.0,1.0)
		if adoption<.1:continue
		var mode:=String(K.METHODS[id].get("mode",""))
		if mode=="rain_shell":storm=maxf(storm,.40*adoption)
		elif mode=="layer":layers=maxf(layers,.25*adoption)
		elif INSULATION.has(mode):best_cold=maxf(best_cold,float(INSULATION[mode])*adoption)
	return {"cold":minf(.8,BASE_COLD+best_cold+layers),"storm":minf(.5,BASE_STORM+storm)}

static func coverage(population:float,_day:int)->Dictionary:
	var supplied:=Goods.coverage()
	var garments:=protection()
	return {"cold":float(garments.cold)*supplied,"storm":float(garments.storm)*supplied,"issued":maxf(0,population)*supplied}

static func power_demand()->float:return 0.0
## Clothing no longer holds separate leather or patterned-cloth stocks.
static func leather_target(_population:float)->float:return 0.0
static func figured_target(_population:float)->float:return 0.0

## Collects today's hunting byproducts and reports clothing coverage. Garment
## work is part of Civilian Goods and uses no separate workers.
static func advance(_workers:float,population:float,traveling:bool,hunted_rations:float=0)->Dictionary:
	var day:=int(WorldSimulation.state.elapsed_days)
	if int(data().get("last_day",-1))==day:return {"workers":0.0,"coverage":coverage(population,day)}
	data().last_day=day
	var stocks:Dictionary=WorldSimulation.state.resource_stockpiles
	var tissue:=available("Pancreatic Tissue")*.25
	if "enzyme_catalysis" in WorldSimulation.state.known_discoveries and WorldSimulation.discovery.adoption("enzyme_catalysis")>=.1 and is_finite(hunted_rations):tissue+=maxf(0,hunted_rations)*.0002
	stocks["Pancreatic Tissue"]=minf(maxf(0,population)*.001,tissue)
	for enzyme:String in ["Pancreatic Enzyme Fraction","Bating Protease"]:
		if stocks.has(enzyme):stocks[enzyme]=available(enzyme)*(.5 if enzyme=="Pancreatic Enzyme Fraction" else .98)
	var fat:=available("Recovered Animal Fat")*.75
	var raw:=available("Raw Hides")*.75
	var tanning:="hide_tanning" in WorldSimulation.state.known_discoveries and WorldSimulation.discovery.adoption("hide_tanning")>=.1
	if is_finite(hunted_rations) and not traveling:
		raw+=maxf(0,hunted_rations)*.001
		if tanning:fat+=maxf(0,hunted_rations)*.0005
	stocks["Recovered Animal Fat"]=minf(maxf(0,population)*.01,fat)
	stocks["Raw Hides"]=minf(maxf(0,population)*.02,raw)
	var recovered:=maxf(0,hunted_rations)*.002 if is_finite(hunted_rations) else 0.0
	stocks[BONE_RESOURCE]=minf(maxf(0,population)*.05,available(BONE_RESOURCE)+recovered)
	var result:={"workers":0.0,"coverage":coverage(population,day)}
	data().report=result.coverage.duplicate()
	return result

static func number(value:Variant)->bool:return (value is float or value is int) and is_finite(float(value))
static func valid(value:Variant)->bool:
	if not value is Dictionary:return false
	var last:Variant=value.get("last_day",-1)
	return number(last) and float(last)>=-1 and float(last)<=1e12 and float(last)==floorf(float(last)) and value.get("report",{}) is Dictionary
static func valid_settlements(records:Variant)->bool:
	if not records is Array:return false
	for record:Variant in records:
		if not record is Dictionary or not record.get("local_resources",{}) is Dictionary:return false
		if not valid(record.get("local_resources",{}).get("household_clothing",empty_state())):return false
	return true
