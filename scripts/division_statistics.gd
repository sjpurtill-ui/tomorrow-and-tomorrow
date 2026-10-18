extends RefCounted
## HOI-style metric names; native game quantities and explicit aggregation.
## Never infer strength from the calendar or population. Equipment, unit,
## issued sets and actual drill determine all ratings.
const Catalog=preload("res://scripts/military_unit_catalog.gd")
const Ledger=preload("res://scripts/equipment_ledger.gd")
const March=preload("res://scripts/march_terrain.gd")
const POINT_MEN:=1000.0
const HP_PER_MAN:=0.025
const ORG_SCALE:=30.0
const BASE_FIELDS:=[
 ["speed","Max speed","km/h"],["hp","HP",""],["organization","Organization",""],["recovery","Recovery rate","/day"],
 ["recon","Reconnaissance",""],["suppression","Suppression",""],["weight","Weight","loads"],["supply","Supply use","k loads/day"],
 ["reliability","Reliability","%"],["trickleback","Trickleback","%"],["experience_loss","Exp. loss","%"],["fuel","Fuel use","k loads/day"]]
const COMBAT_FIELDS:=[
 ["soft_attack","Soft attack",""],["hard_attack","Hard attack",""],["air_attack","Air attack",""],["defense","Defense",""],
 ["breakthrough","Breakthrough",""],["armor","Armor",""],["piercing","Piercing",""],["initiative","Initiative","%"],
 ["entrenchment","Entrenchment","%"],["combat_width","Combat width",""],["hardness","Hardness","%"]]
const TIPS:={
 "speed":"Slowest combat or support group, on level ground. One marching day has eight travel hours; terrain and supply reduce actual progress.",
 "hp":"Strength expressed as HP: 40 people = 1 HP. Losses remove actual people and equipment, never a second health pool.",
 "organization":"Manpower-weighted unit cohesion at the shown drill. Larger copies do not multiply organization. Affects resistance to morale wear in battle.",
 "recovery":"Organization points restored per supplied resting day with an ordinary commander. Field and home conditions can lower this.",
 "recon":"Equipped scouts per thousand people; improves the ability to exploit favorable unit matchups, capped in combat.",
 "suppression":"Garrison manpower in thousands. No extra town-watch effect: occupation still needs real deployed soldiers.",
 "weight":"Equipment delivery loads, using the same kit transport costs as military logistics; excludes personnel transport.",
 "supply":"Thousands of daily loads: food plus equipment stores before local foraging. Uses the actual carrier bill.",
 "reliability":"Equipment survival factor used in daily wear. Maintenance support reduces wear; shortages and combat increase it.",
 "trickleback":"Medical recovery capacity per day as a percentage of formation size, at full supporting supplies. Actual home care consumes dressings and medicine; the dead and permanently disabled never return.",
 "experience_loss":"Experience dilution when 10% of this formation is replaced by raw recruits. Actual dilution depends on how many replacements arrive.",
 "fuel":"Motor equipment's fuel component, 60% of its stores load. Already included in Supply use, never charged twice.",
 "soft_attack":"Total firepower against an unarmored target, in thousand-person combat points, fully issued and at the shown drill.",
 "hard_attack":"The same firepower after the engine's piercing rule against reference armor 1.0. Actual damage depends on the opponent's armor.",
 "air_attack":"Equipped antiaircraft firepower; reduces hostile air pressure on this formation.",
 "defense":"Total protection while defending. Engineers contribute entrenchment; terrain, tactics and supply apply in battle.",
 "breakthrough":"Protection while attacking. Foot levies are exposed advancing; armored units retain more protection.",
 "armor":"Manpower-weighted issued armor. Combat resolves armor per cohort so one armored slot cannot protect the entire division.",
 "piercing":"Manpower-weighted issued penetration. Combat resolves each weapon separately against the target's armor.",
 "initiative":"Trained reconnaissance support improves morale recovery. No bonus from empty slots.",
 "entrenchment":"Maximum additional defensive protection from equipped engineers. Applied on defense, never on attack.",
 "combat_width":"Personnel per thousand. This engine counts combat-capable support groups against frontage too; terrain determines how many fight at once.",
 "hardness":"Manpower-weighted share protected by hard equipment, read from the combat engine. Equipment shortages lower it."}

static func breakthrough_factor(unit:String)->float:
	var branch:=String(Catalog.archetype(unit).get("branch",""))
	if branch in ["protection","autonomous"]:return 1.15
	if branch=="mounted":return .90
	if unit in ["assault_infantry","combat_engineer","marines"]:return .85
	return .65

static func support_traits(formations:Array)->Dictionary:
	var total:=0.0;var recon:=0.0;var engineer:=0.0;var repair:=0.0;var aa:=0.0
	for f:Dictionary in formations:
		var count:=maxf(0,float(f.get("count",0)));total+=count
		var issued:=clampf(float(f.get("equipment",count))/maxf(1,float(f.get("equipment_required",count))),0,1)
		var unit:=String(f.get("unit","levy"));var trained:=clampf(float(f.get("training",.8)),0,1)
		var staffed:=count*issued*trained
		if String(Catalog.archetype(unit).get("branch",""))=="reconnaissance" or unit in ["light_cavalry","armored_car"]:recon+=staffed
		if unit in ["combat_engineer","siege_engineer"]:engineer+=staffed
		if unit=="field_repair_company":repair+=staffed
		if unit in ["anti_air","counter_drone_battery"]:aa+=staffed*float(Ledger.row(String(f.get("weapon",""))).get("attack",1))
	var divisor:=maxf(1,total)
	return {"recon":recon/divisor*10,"entrenchment":minf(.25,engineer/divisor),"initiative":minf(.20,recon/divisor*.5),
		"trickleback":preload("res://scripts/field_medicine.gd").capacity({"formations":formations})*.08/divisor,"reliability":minf(.98,.80+repair/divisor),"air_attack":aa/POINT_MEN,"air_protection":minf(.75,aa/divisor*3)}

static func organization(formations:Array,sim:Variant)->float:
	var total:=0.0;var value:=0.0
	for f:Dictionary in formations:
		var n:=maxf(0,float(f.get("count",0)));total+=n
		var spec:Dictionary=sim.UNIT_TYPES.get(String(f.get("unit","levy")),sim.UNIT_TYPES.levy)
		value+=n*float(spec.organization)*(.1+.9*clampf(float(f.get("training",.8)),0,1.25))*ORG_SCALE
	return value/maxf(1,total)

static func morale_wear(formations:Array,sim:Variant)->float:
	return clampf(1.15-organization(formations,sim)/100.0,.70,1.15)

static func read(mc:Variant,entries:Array,drill:=.8)->Dictionary:
	var sim=mc.simulator;var formations:Array=[];var equipment:={};var cost:=0.0;var weight:=0.0;var days:=0.0;var speed:=INF
	var n:=0;var fuel:=0.0;var width:=0.0
	for e:Dictionary in entries:
		var unit:=String(e.unit);var weapon:=String(e.weapon);var count:=maxi(0,int(e.count))
		if count<=0:continue
		n+=count
		var sets:int=sim.equipment_required_for_weapon(weapon,count)
		equipment[weapon]=int(equipment.get(weapon,0))+sets
		formations.append({"unit":unit,"weapon":weapon,"count":count,"equipment":sets,"equipment_required":sets,"training":drill,"experience":0.0,"authorized_count":count,"ammunition":sim.ammunition_required_for_weapon(weapon,sets,count)})
		var spec:=Catalog.archetype(unit)
		speed=minf(speed,float(spec.get("pace_km_day",March._DEFAULT_PACE.get(unit,24.0)))/8.0)
		days=maxf(days,Catalog.training_days(unit))
		weight+=sets*mc._equipment_delivery_load(weapon)
		var recipe:Dictionary=mc.PersistentProduction.recipe(mc,weapon)
		cost+=sets*float(recipe.get("work_per_item",Ledger.row(weapon).get("days",1.0)))
		if String(spec.get("movement","foot")) in ["motorized","tracked"]:fuel+=sets*Ledger.supply(weapon)*.6
		width+=count/POINT_MEN
	var force:Dictionary=sim.create_formation_force("Design",formations,1.0,1.0)
	var rated:Array=sim.evaluate_force(force,{"formations":[]},1.0) if n>0 else []
	var soft:=0.0;var hard:=0.0;var defense:=0.0;var breakthrough:=0.0;var hardness:=0.0
	for i in rated.size():
		var r:Dictionary=rated[i];var e:Dictionary=formations[i]
		soft+=int(e.count)*float(r.attack)/POINT_MEN
		hard+=int(e.count)*float(r.attack)*sim.pierce_factor(float(sim.WEAPONS[e.weapon].penetration),1.0)/POINT_MEN
		defense+=int(e.count)*float(r.defense)/POINT_MEN
		breakthrough+=int(e.count)*float(r.defense)*breakthrough_factor(String(e.unit))/POINT_MEN
		hardness+=int(e.count)*sim.kit_hardness(String(e.weapon))
	var traits:=support_traits(formations)
	var org:=organization(formations,sim)
	return {"speed":speed if n>0 else 0.0,"hp":n*HP_PER_MAN,"organization":org,"recovery":org*.03*(1+float(traits.initiative)),
		"recon":traits.recon,"suppression":n/POINT_MEN,"weight":weight,"supply":preload("res://scripts/carriers.gd").daily_loads(force)/POINT_MEN,
		"reliability":float(traits.reliability)*100,"trickleback":float(traits.trickleback)*100,"experience_loss":10.0 if n>0 else 0.0,"fuel":fuel/POINT_MEN,
		"soft_attack":soft,"hard_attack":hard,"air_attack":traits.air_attack,"defense":defense,"breakthrough":breakthrough/(1+float(traits.entrenchment)),
		"armor":force.get("armor",0.0),"piercing":force.get("penetration",0.0),"initiative":float(traits.initiative)*100,"entrenchment":float(traits.entrenchment)*100,
		"combat_width":width,"hardness":hardness/maxi(1,n)*100,"manpower":n,"training_time":days,"production_cost":cost,"equipment":equipment,"formations":formations}

static func number(value:float)->String:
	if value==0:return "0"
	if absf(value)<.001:return "%.5f"%value
	if absf(value)<.1:return "%.3f"%value
	return ("%.2f"%value).trim_suffix("00").trim_suffix(".")
