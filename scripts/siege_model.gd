class_name SiegeModel
extends RefCounted

## Bounded strategic state. Food, population and armies remain in their owners.
const HISTORY_LIMIT:=24
const RELIEF_LIMIT:=8

static func advance(previous:Dictionary,day:int,inputs:Dictionary)->Dictionary:
	var state:=previous.duplicate(true)
	if state.is_empty() or day<=int(state.get("last_day",day)): return state
	var strength:=maxf(0,float(inputs.get("besiegers",0)))
	var relief:=maxf(0,float(inputs.get("defender_relief",0)))
	var supply:=clampf(float(inputs.get("besieger_supply",0)),0,1)
	var population:=maxf(1,float(inputs.get("population",1)))
	var ring_need:=maxf(20,sqrt(population)*5+float(inputs.get("defenders",0))*.3+relief)
	var closure:=clampf(strength/ring_need,0,.9)*(.35+.65*supply)
	var hunger:=clampf(1-float(inputs.get("defender_food_days",30))/7,0,1)
	var fort:=clampf(float(inputs.get("fortification",0)),0,1)
	state["last_day"]=day
	state["days"]=maxi(0,day-int(state.start_day))
	state["blockade"]=closure
	state["pressure"]=clampf(float(state.get("pressure",0))+.004*closure/(1+fort*3)+hunger*.008-relief/maxf(1,strength)*.004,0,1)
	state["fatigue"]=clampf(float(state.get("fatigue",0))+.0015+(.012 if supply<.45 else 0)+maxf(0,.3-closure)*.003,0,1)
	state["hardship"]=clampf(hunger*.75+closure*.15+float(state.pressure)*.1,0,1)
	state["supply_ratio"]=supply
	state["starving_days"]=int(state.get("starving_days",0))+1 if supply<.1 else 0
	return state

static func validate(state:Variant)->String:
	if not state is Dictionary: return "Siege state must be a record."
	if state.is_empty(): return ""
	if not state.has_all(["id","mode","attacker_id","defender_id","start_day","last_day","target_position","threat"]): return "Incomplete siege record."
	for key in ["id","attacker_id","defender_id"]:
		if not state[key] is String or state[key].is_empty() or state[key].length()>128: return "Invalid siege identity."
	if (state.get("mode","")=="offensive")!=(state.attacker_id=="player"): return "Siege mode disagrees with its sides."
	if state.attacker_id==state.defender_id or "player" not in [state.attacker_id,state.defender_id]: return "Siege must identify opposing sides including the player."
	if not (state.get("army_id",0) is int or state.get("army_id",0) is float) or not is_finite(float(state.get("army_id",0))) or float(state.get("army_id",0))<0 or floorf(float(state.get("army_id",0)))!=float(state.get("army_id",0)): return "Invalid siege army."
	if state.mode not in ["offensive","defensive"] or not state.id is String: return "Invalid siege identity."
	for key in ["start_day","last_day","days","pressure","fatigue","blockade","hardship","starving_days","supply_ratio"]:
		var value:Variant=state.get(key,0)
		if not (value is int or value is float) or not is_finite(float(value)) or float(value)<0: return "Invalid siege value: "+key
	for key in ["pressure","fatigue","blockade","hardship","supply_ratio"]:
		if float(state.get(key,0))>1: return "Siege fraction exceeds one."
	if int(state.last_day)<int(state.start_day): return "Siege predates its start."
	if not state.threat is Dictionary or not state.target_position is Dictionary: return "Invalid siege target."
	var enemy:Variant=state.threat.get("enemy_force",{})
	if not enemy is Dictionary or not (enemy.get("troops",0) is int or enemy.get("troops",0) is float) or not is_finite(float(enemy.get("troops",0))) or float(enemy.get("troops",0))<0: return "Invalid siege force."
	for axis in ["x","z"]:
		var coordinate:Variant=state.target_position.get(axis,null)
		if not (coordinate is float or coordinate is int) or not is_finite(float(coordinate)): return "Invalid siege coordinates."
	var camps:Variant=state.get("relief",[])
	if not camps is Array or camps.size()>RELIEF_LIMIT: return "Too many siege relief camps."
	var receipts:Dictionary={}
	for camp in camps:
		if not camp is Dictionary or not camp.has_all(["receipt_id","troops","food","beneficiary_id"]): return "Invalid relief camp."
		if not camp.receipt_id is String or camp.receipt_id.is_empty() or camp.beneficiary_id not in [state.attacker_id,state.defender_id]: return "Invalid relief beneficiary or receipt."
		if receipts.has(camp.receipt_id): return "Duplicate relief receipt."
		receipts[camp.receipt_id]=true
		for key in ["troops","food"]:
			if not (camp[key] is int or camp[key] is float) or not is_finite(float(camp[key])) or camp[key]<0: return "Invalid relief resources."
	return ""
