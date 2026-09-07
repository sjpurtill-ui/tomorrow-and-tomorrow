extends RefCounted
## Raid choices use dated observed defense, never the player's hidden live state.
static func worthwhile(strength: int, readiness: float, observed_defense: float) -> bool:
	return strength >= 6 and float(strength)*clampf(readiness,.1,1.0) >= maxf(1.0,observed_defense)*.8

static func routine(threat: Dictionary, defenders: Dictionary) -> bool:
	if String(threat.get("incident_kind",""))!="raid" or String(threat.get("campaign_mode","defensive"))!="defensive": return false
	if not String(threat.get("target_region_id","")).is_empty(): return false
	var enemy: Dictionary = threat.get("enemy_force",{})
	var strength := int(threat.get("estimated_strength",enemy.get("troops",0)))
	if strength<=0 or strength>24: return false
	var attack := float(strength)*maxf(.15,float(enemy.get("readiness",.5)))
	var defense := float(defenders.get("troops",0))*maxf(.05,float(defenders.get("readiness",.5)))
	return defense >= attack*2.0

static func has_spoils(spoils: Dictionary) -> bool:
	for kind in ["supplies","carts","wealth"]:
		if int(spoils.get(kind,0))>0: return true
	for kind in ["weapons","consumables"]:
		for count in (spoils.get(kind,{}) as Dictionary).values():
			if int(count)>0: return true
	return false
