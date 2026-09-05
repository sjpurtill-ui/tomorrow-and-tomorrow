## Data authority for military unit archetypes and equipment gates, following
## the design bible (docs/Historical_Military_Unit_Progression.docx §17–18):
## units are archetypes on branching lineage spines, unlocked by knowledge but
## fielded only through people, material, training, command, and sustainment.
## Combat coefficients stay in combat_simulator.gd; this file owns identity,
## gating, lineage, and fielding data.

# Branch ids follow §17's spines. "lineage" points at the archetype this form
# grows out of — a viable transformation when its gates exist, never an
# automatic replacement; older forms persist wherever they stay rational.
const ARCHETYPES:Dictionary={
	"levy":{"label":"Levy","branch":"force_generation","lineage":"","era":"village warfare","gate":"","training_days":7,"equipment":["improvised","spear"],"movement":"foot","purpose":"Numbers, garrison mass, and the mobilization base every later form draws on.","sustainment":"Eats from settlement stores; every levy is labor withheld from fields.","politics":"Broad legitimacy; cheap to raise, costly to keep standing."},
	"line_infantry":{"label":"Line Infantry","branch":"heavy_infantry","lineage":"levy","era":"early iron","gate":"shield_wall","training_days":30,"equipment":["spear","sword_shield"],"movement":"foot","purpose":"Holds ground in formation; the anchor other arms maneuver around.","sustainment":"Standard rations; armor and shields need craft replacement.","politics":"Drill time builds cohesion and a soldier identity distinct from the levy."},
	"skirmisher":{"label":"Skirmisher","branch":"reconnaissance","lineage":"levy","era":"early iron","gate":"bow_craft","training_days":21,"equipment":["bow"],"movement":"foot","purpose":"Screens, harasses, and scouts ahead of the line; the army's forward eyes.","sustainment":"Light burden; consumes arrows on every engagement.","politics":"Recruits from hunters; blurs the line between forager skill and war skill."},
	"cavalry":{"label":"Cavalry","branch":"mounted","lineage":"skirmisher","era":"early iron","gate":"domesticated_mounts","training_days":45,"equipment":["lance","sword_shield"],"movement":"mounted","purpose":"Shock, pursuit, and operational reach; turns victories into routs.","sustainment":"Fodder doubles the supply burden; every mount is a bred, fed animal.","politics":"Mounts concentrate in wealthy hands; cavalry breeds an elite arm."},
	"siege_engineer":{"label":"Siege Engineers","branch":"siege_fires","lineage":"line_infantry","era":"early states","gate":"siege_engineering","training_days":48,"equipment":["siege_kit"],"movement":"foot","purpose":"Breaks fortifications and builds the works that protect a besieging army.","sustainment":"Timber, tools, and skilled labor; slow to replace when lost.","politics":"Specialist knowledge held by few; institutions must retain it."},
	"field_artillery":{"label":"Field Artillery","branch":"siege_fires","lineage":"siege_engineer","era":"gunpowder","gate":"powder_artillery","training_days":60,"equipment":["field_gun"],"movement":"wheeled","purpose":"Massed fire against formations and works alike.","sustainment":"Powder, shot, and draft teams; ammunition dominates its logistics.","politics":"Guns are state property; artillery centralizes military power."},
	"rifle_infantry":{"label":"Rifle Infantry","branch":"heavy_infantry","lineage":"line_infantry","era":"industrial","gate":"__military_tier_5__","training_days":42,"equipment":["service_rifle"],"movement":"foot","purpose":"Dispersed accurate fire; the standard formation of industrial war.","sustainment":"Cartridge supply and arsenal-pattern repair.","politics":"Mass conscription becomes practical and expected."},
	"machine_gun_company":{"label":"Machine-Gun Company","branch":"siege_fires","lineage":"rifle_infantry","era":"industrial","gate":"__military_tier_5__","training_days":56,"equipment":["machine_gun"],"movement":"foot","purpose":"Sustained suppression; makes open ground impassable.","sustainment":"Devours ammunition; crew-served weapons need trained teams.","politics":"Defense-dominant; changes what offensives cost."},
	"motorized_infantry":{"label":"Motorized Infantry","branch":"mounted","lineage":"cavalry","era":"mechanization","gate":"__military_tier_6__","training_days":70,"equipment":["motorized_kit"],"movement":"motorized","purpose":"Operational mobility for infantry; reach without exhaustion.","sustainment":"Fuel, parts, and mechanics; roads or firm ground.","politics":"Industry becomes the recruiting ground as much as the village."},
	"armored_formation":{"label":"Armored Formation","branch":"protection","lineage":"motorized_infantry","era":"mechanization","gate":"__military_tier_6__","training_days":110,"equipment":["armored_vehicle"],"movement":"tracked","purpose":"Protected shock and breakthrough; the war wagon's industrial heir.","sustainment":"The heaviest burden fielded: fuel, ammunition, recovery, and repair.","politics":"A national industrial commitment visible to every rival."},
	"modern_artillery":{"label":"Modern Artillery","branch":"siege_fires","lineage":"field_artillery","era":"mechanization","gate":"__military_tier_6__","training_days":84,"equipment":["modern_field_gun"],"movement":"wheeled","purpose":"Long-range indirect fire coordinated by survey and signals.","sustainment":"Shell industry and fire-direction specialists.","politics":"Invisible killing at range; doctrine and staffs matter more than valor."},
}

const EQUIPMENT_GATES:Dictionary={"improvised":"","spear":"hafted_weapons","bow":"bow_craft","sword_shield":"bronze_weaponry","lance":"domesticated_mounts","siege_kit":"siege_engineering","field_gun":"powder_artillery","service_rifle":"__military_tier_5__","machine_gun":"__military_tier_5__","motorized_kit":"__military_tier_6__","armored_vehicle":"__military_tier_6__","modern_field_gun":"__military_tier_6__"}

## Fielding-readiness bands (§18.4) derived from a formation's continuous
## state. Veteran is an overlay earned through combat experience.
static func readiness_band(formation:Dictionary)->String:
	var condition:=clampf(float(formation.get("personnel_condition",1.0)),0.0,1.0)
	var training:=clampf(float(formation.get("training",0.0)),0.0,1.0)
	var experience:=clampf(float(formation.get("experience",0.0)),0.0,1.0)
	if condition<0.30: return "BROKEN"
	if condition<0.55: return "DEGRADED"
	if experience>=0.50 and training>=0.55: return "VETERAN"
	if training>=0.80: return "READY"
	if training>=0.50: return "TRAINED"
	if training>=0.25: return "GREEN"
	return "ASSEMBLING"


static func archetype(unit:String)->Dictionary:
	return (ARCHETYPES.get(unit,{}) as Dictionary)

static func gate_for(unit:String)->String:
	return String(archetype(unit).get("gate",""))

static func equipment_for(unit:String)->Array:
	return (archetype(unit).get("equipment",["improvised"]) as Array)

static func training_days(unit:String)->float:
	return float(archetype(unit).get("training_days",21))

static func lineage_for(unit:String)->String:
	return String(archetype(unit).get("lineage",""))
