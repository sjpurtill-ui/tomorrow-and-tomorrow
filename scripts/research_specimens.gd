extends RefCounted
## Explicit physical examples; possession does not demonstrate tactics or organization.
const Industry=preload("res://scripts/civilian_industry.gd")
const MILITARY:Dictionary={
 "spear":"hafted_weapons", "bow":"bow_craft", "sword_shield":"bronze_weaponry",
 "crossbow":"crossbow_mechanism", "trebuchet":"counterweight_engines",
 "marksman_rifle":"rifled_barrels", "service_rifle":"metallic_cartridges",
 "machine_gun":"automatic_actions", "motorized_kit":"internal_combustion",
 "armored_vehicle":"armored_vehicles", "anti_tank_kit":"armor_piercing_weapons",
 "steam_corvette_equipment":"steam_propulsion", "ironclad_equipment":"armored_hulls",
 "torpedo_boat_equipment":"naval_torpedoes", "submarine_equipment":"submersible_hulls",
 "jet_fighter_equipment":"jet_propulsion", "transport_helicopter_equipment":"rotary_wing"
}
static func definition(item:String)->Dictionary:
 if item.begins_with("military:"):
  var equipment:=item.trim_prefix("military:")
  if not MILITARY.has(equipment):return {}
  return {"gate":MILITARY[equipment],"output":equipment.replace("_"," "),"military":true,"equipment":equipment}
 var product:Dictionary=Industry.product(item)
 return product.duplicate(true)
static func for_subject(subject:String)->Array[String]:
 var result:Array[String]=[]
 for item:String in Industry.PRODUCTS:
  if Industry.PRODUCTS[item].gate==subject:result.append(item)
 for equipment:String in MILITARY:
  if MILITARY[equipment]==subject:result.append("military:"+equipment)
 return result
