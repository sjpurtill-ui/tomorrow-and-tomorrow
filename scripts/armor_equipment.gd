extends RefCounted
## Complete infantry kits; coefficients are game balance, not measured protection.
const KITS:Dictionary={
  "shield_spear":{"name": "Fitted shield and spear", "gate": "shield_equipment_fitting", "materials": {"Fitted Shields": 1, "Timber": 0.65, "Stone": 0.1}, "days": 1.5, "crew": 1, "ammo": "", "ammo_per": 0, "attack": 1, "defense": 1.18, "armor": 0.5, "penetration": 0.55, "delivery": 1.5},
  "padded_spear": {
    "name": "Padded Armor and spear",
    "gate": "textile_armor_layering",
    "materials": {
      "Padded Armor": 1,
      "Timber": 0.65,
      "Stone": 0.1
    },
    "days": 2,
    "crew": 1,
    "ammo": "",
    "ammo_per": 0,
    "attack": 1.0,
    "defense": 1.18,
    "armor": 0.3,
    "penetration": 0.55,
    "delivery": 1.5
  },
  "lamellar_spear": {
    "name": "Lamellar Armor and spear",
    "gate": "lamellar_armor_assembly",
    "materials": {
      "Lamellar Armor": 1,
      "Timber": 0.65,
      "Stone": 0.1
    },
    "days": 3,
    "crew": 1,
    "ammo": "",
    "ammo_per": 0,
    "attack": 1.0,
    "defense": 1.18,
    "armor": 0.8,
    "penetration": 0.55,
    "delivery": 2.5
  },
  "scale_spear": {
    "name": "Scale Armor and spear",
    "gate": "scale_armor_attachment",
    "materials": {
      "Scale Armor": 1,
      "Timber": 0.65,
      "Stone": 0.1
    },
    "days": 2.5,
    "crew": 1,
    "ammo": "",
    "ammo_per": 0,
    "attack": 1.0,
    "defense": 1.18,
    "armor": 0.7,
    "penetration": 0.55,
    "delivery": 2.4
  },
  "mail_spear": {
    "name": "Mail Armor and spear",
    "gate": "mail_armor_fabrication",
    "materials": {
      "Mail Armor": 1,
      "Timber": 0.65,
      "Stone": 0.1
    },
    "days": 4,
    "crew": 1,
    "ammo": "",
    "ammo_per": 0,
    "attack": 1.0,
    "defense": 1.18,
    "armor": 0.85,
    "penetration": 0.55,
    "delivery": 2.3
  },
  "plate_spear": {
    "name": "Fitted Plate Armor and spear",
    "gate": "articulated_plate_armor",
    "materials": {
      "Fitted Plate Armor": 1,
      "Timber": 0.65,
      "Stone": 0.1
    },
    "days": 6,
    "crew": 1,
    "ammo": "",
    "ammo_per": 0,
    "attack": 1.0,
    "defense": 1.18,
    "armor": 1.35,
    "penetration": 0.55,
    "delivery": 3.0
  }
}

## Choose an actually supplied kit within a fixed infantry role. Stock and
## startup checks remain authoritative; ratings do not create equipment.
static func preference(host:Node,item:String,plan:Dictionary)->float:
	var spec:Dictionary=host.simulator.WEAPONS[item]
	var defensive:=not bool(plan.get("offensive",false))
	var protection_weight:=.45 if defensive else .25
	var value:=float(spec.attack)*float(spec.defense)+float(spec.armor)*protection_weight
	if KITS.has(item):
		value-=log(1.0+float(KITS[item].days))*.04
		value-=float(KITS[item].delivery)*.02
	return value

static func selection(host:Node,unit:String,plan:Dictionary)->String:
	var best:="";var score:=-INF
	for item:String in host.UnitCatalog.equipment_for(unit):
		if host._training_gate(unit,item).has("error"):continue
		if int(host.military_inventory.get(item,0))<=0 and not host.PersistentProduction.startup_blockers(host,item).is_empty():continue
		if unit not in ["line_infantry","spearman"]:return item
		var value:=preference(host,item,plan)
		if value>score:best=item;score=value
	return best

static func investment(host:Node,unit:String,current:String,target:int,plan:Dictionary)->Dictionary:
	if unit not in ["line_infantry","spearman"] or target<=0:return {}
	if KITS.has(current) and int(host.military_inventory.get(current,0))<target:
		var replenishment:=upstream(host,current,target)
		if not replenishment.is_empty():return replenishment
	var best:Dictionary={};var score:=preference(host,current,plan) if current!="" else -INF
	for item:String in KITS:
		if host._training_gate(unit,item).has("error"):continue
		var value:=preference(host,item,plan)
		if value<=score:continue
		var next:=upstream(host,item,target)
		if not next.is_empty():best=next;score=value
	return best

static func upstream(host:Node,item:String,target:int)->Dictionary:
	if not KITS.has(item):return {}
	var P=preload("res://scripts/persistent_production.gd")
	var Supply=preload("res://scripts/civilian_production_planner.gd")
	var recipe:=P.recipe(host,item)
	if recipe.has("error"):return {}
	var staff:=P.workforce()
	if host.production_labor_share<=0 or float(staff.workers)<=0 or float(staff.condition_factor)<=0:return {}
	var materials:Dictionary=recipe.materials
	var fraction:=1.0
	for job:Dictionary in host.equipment_queue:
		if String(job.get("item",""))!=item:continue
		if not bool(job.get("persistent",false)) or bool(job.get("paused",false)):return {}
		materials=job.materials
		fraction=maxf(0,1.0-float(job.progress_days)/float(job.work_per_item));break
	var first:Dictionary={}
	var batches:=clampi(target-int(host.military_inventory.get(item,0)),1,32)
	for resource:String in materials:
		var needed:=float(materials[resource])*fraction
		if float(WorldSimulation.state.resource_stockpiles.get(resource,0))+.000001>=needed:continue
		# Kit bills name raw materials and Civilian Goods (armor parts are
		# flattened), so a shortfall has no upstream line. Do not spend on a
		# kit with a missing input.
		var next:=Supply.supply(resource,maxi(1,ceili(float(materials[resource])*batches)),{})
		if next.is_empty():return {}
		if first.is_empty():first=next
	return first if not first.is_empty() else {"item":item,"target":target}
