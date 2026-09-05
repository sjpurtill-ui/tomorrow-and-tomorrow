class_name UnitVisualCatalog
extends RefCounted

## Appearance only. Combat equipment, training, costs and counters stay authoritative.
const THEMES := ["equipment", "classical", "medieval"]
const LABELS := ["Issued equipment", "Classical appearance", "Medieval appearance"]
const VARIANTS := {
	"levy": ["levy", "slinger", "javelin_skirmisher"],
	"line_infantry": ["line_infantry", "pike_phalanx", "legionary_infantry", "armored_foot"],
	"skirmisher": ["skirmisher", "crossbow_infantry", "longbowman", "pavise_crossbowman"],
	"cavalry": ["cavalry", "horse_archer", "camel_cavalry", "chariot_archer", "war_elephant"],
	"siege_engineer": ["siege_engineer", "battering_ram", "siege_tower", "counterweight_trebuchet"],
	"field_artillery": ["field_artillery", "bombard", "hand_cannon_team"],
	"rifle_infantry": ["rifle_infantry"], "machine_gun_company": ["machine_gun_company"],
	"motorized_infantry": ["motorized_infantry"]
}

static func model(formation: Dictionary, theme: String = "equipment", index: int = 0) -> String:
	var unit := String(formation.get("unit", formation.get("unit_id", "levy")))
	var options: Array = VARIANTS.get(unit, [])
	var explicit := String(formation.get("visual_model", ""))
	if explicit in options: return explicit
	# Unsupported armor/modern artillery remain labelled proxies, not missing people.
	if options.is_empty(): return "motorized_infantry" if unit == "armored_formation" else ("field_artillery" if unit == "modern_artillery" else "levy")
	var weapon := String(formation.get("weapon", ""))
	if theme == "classical":
		match unit:
			"line_infantry": return "legionary_infantry" if weapon == "sword_shield" else "pike_phalanx"
			"skirmisher": return "crossbow_infantry"
			"siege_engineer": return ["siege_engineer", "battering_ram", "siege_tower"][posmod(index,3)]
	elif theme == "medieval":
		match unit:
			"line_infantry": return "armored_foot" if weapon == "sword_shield" else "pike_phalanx"
			"skirmisher": return "longbowman" if index % 2 == 0 else "pavise_crossbowman"
			"siege_engineer": return "counterweight_trebuchet"
			"field_artillery": return "bombard"
	if unit == "line_infantry" and weapon == "sword_shield": return "legionary_infantry"
	return String(options[0])

static func counts(force: Dictionary) -> Dictionary:
	var result := {}
	var formations: Array = force.get("formations", [])
	if formations.is_empty(): return {"levy": maxi(0,int(force.get("troops",force.get("remaining_troops",0))))}
	for index in formations.size():
		var id := model(formations[index], String(force.get("visual_theme","equipment")), index)
		result[id] = int(result.get(id,0)) + maxi(0,int(formations[index].get("count",0)))
	return result

static func role(id: String) -> String:
	if id in ["cavalry","horse_archer","camel_cavalry","chariot_archer","war_elephant","motorized_infantry"]: return "mobile"
	if id in ["siege_engineer","field_artillery","battering_ram","siege_tower","counterweight_trebuchet","bombard"]: return "siege"
	if id in ["skirmisher","slinger","javelin_skirmisher","crossbow_infantry","longbowman","pavise_crossbowman","rifle_infantry","machine_gun_company","hand_cannon_team"]: return "ranged"
	return "melee"
