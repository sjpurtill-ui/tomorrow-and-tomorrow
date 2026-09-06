extends RefCounted
## One bounded social record per existing region, never a second population ledger.
## Harm follows coercion and unequal institutions; cultural origin is not a penalty.
const POLICIES:Dictionary={
	"stewardship":{"label":"Civil administration","rights":0.65,"coercion":0.10,"extraction":0.08,"autonomy":0.25,"description":"Protect local institutions and rebuild services. Modest revenue, a continuing administrative burden, and gradual trust."},
	"self_rule":{"label":"Local self-rule","rights":0.90,"coercion":0.02,"extraction":0.02,"autonomy":0.85,"description":"Residents govern local affairs. Lower revenue and direct control; stronger legitimacy and a path to negotiated autonomy."},
	"equal_citizenship":{"label":"Equal citizenship","rights":1.0,"coercion":0.03,"extraction":0.10,"autonomy":0.50,"description":"Equal legal status and access to institutions. Integration requires years of security, welfare and trust; past harms remain."},
	"military_rule":{"label":"Military government","rights":0.25,"coercion":0.60,"extraction":0.20,"autonomy":0.05,"description":"More immediate control while a supplied garrison remains. Inequality, grievance and resistance grow."},
	"forced_labor":{"label":"Enslavement","rights":0.0,"coercion":0.95,"extraction":0.45,"autonomy":0.0,"description":"Residents are held in slavery. Extraction increases at the cost of welfare, lasting injustice, resistance and diplomatic legitimacy."}
}
const FIELDS:Array[String]=["grievance","inherited_grievance","inequality","trust","welfare","local_institutions","support","suspicion","repression","legitimacy"]

static func state(region:Dictionary)->Dictionary:
	var data:Dictionary=(region.get("governance",{}) as Dictionary).duplicate(true)
	var defaults:Dictionary={"policy":"stewardship","grievance":float(region.get("damage",0.0))*.5,"inherited_grievance":0.0,"inequality":.25,"trust":.15,"welfare":.5,"local_institutions":.4,"support":.15,"suspicion":.1,"repression":0.0,"legitimacy":.2,"months":0,"milestone":"Occupation","history":[],"ruined":false,"reconstruction":false,"last_order_day":-9999}
	for key in defaults:
		if not data.has(key): data[key]=defaults[key]
	return data

static func policy(region:Dictionary)->Dictionary:
	return POLICIES.get(String(state(region).policy),POLICIES.stewardship)

static func advance(region:Dictionary,coverage:float,supply:float,peace:bool)->Dictionary:
	var result:=region.duplicate(true)
	var data:=state(region)
	var rules:Dictionary=POLICIES[String(data.policy)]
	var coercion:=float(rules.coercion)
	var rights:=float(rules.rights)
	var damage:=float(region.get("damage",0.0))
	var security:=clampf(coverage,0.0,1.0)*clampf(supply,0.0,1.0)
	data.months=int(data.months)+1
	data.inequality=move_toward(float(data.inequality),1.0-rights,.006+.014*coercion)
	data.repression=move_toward(float(data.repression),coercion*security,.02)
	data.welfare=clampf(float(data.welfare)+.008*supply*rights-.010*coercion-.006*damage-.005*(1.0-supply),0,1)
	data.grievance=clampf(float(data.grievance)+.008*coercion+.004*float(data.inequality)+.003*damage-.008*rights*float(data.welfare)*security,0,1)
	# A generation is roughly 25 years. Reform changes present treatment first;
	# inherited distrust fades over generations, not on the policy-click frame.
	data.inherited_grievance=move_toward(float(data.inherited_grievance),float(data.grievance),1.0/300.0)
	data.local_institutions=clampf(float(data.local_institutions)+.004*rights*supply-.005*coercion-.002*damage,0,1)
	data.trust=clampf(float(data.trust)+.006*rights*float(data.welfare)*security-.009*coercion-.003*float(data.inherited_grievance),0,1)
	data.legitimacy=clampf(float(data.trust)*.45+rights*.30+float(data.local_institutions)*.25-float(data.grievance)*.25,0,1)
	data.support=clampf(float(data.support)+.004*float(data.grievance)+.003*float(data.inequality)-.003*float(data.legitimacy),0,1)
	data.suspicion=clampf(float(data.suspicion)-.005+.003*coercion,0,1)
	var resistance:=float(region.get("resistance",.5))+.008*float(data.grievance)+.004*float(data.inherited_grievance)+.01*(1.0-security)-.012*security*(.4+coercion)-.008*float(data.legitimacy)
	result.resistance=clampf(resistance,.01,1)
	var integration_gain:=.008*(1.0 if peace else .22)*supply*rights*float(data.trust)*(1-float(result.resistance))
	result.integration=clampf(float(region.get("integration",0))+integration_gain-.002*coercion,0,1)
	if bool(data.ruined) and not bool(data.reconstruction): result.damage=1.0
	else: result.damage=maxf(0,damage-.006*supply*float(data.local_institutions))
	if bool(data.reconstruction) and float(result.damage)<.1: data.ruined=false; data.reconstruction=false
	data.milestone="Occupation"
	if float(data.welfare)>=.55 and float(result.resistance)<.5: data.milestone="Services recovering"
	if float(data.trust)>=.5 and float(data.local_institutions)>=.5: data.milestone="Local institutions trusted"
	if float(result.integration)>=.75 and float(data.legitimacy)>=.7 and peace: data.milestone="Durable civic integration"
	if String(data.policy)=="self_rule" and float(data.trust)>=.6 and peace: data.milestone="Autonomy agreement ready"
	result.governance=data
	return result

static func change(region:Dictionary,order:String,day:int)->Dictionary:
	var result:=region.duplicate(true)
	var data:=state(region)
	if day-int(data.last_order_day)<30: return {"error":"Allow 30 days for the current administrative order to take effect before changing course."}
	var description:=""
	if POLICIES.has(order):
		data.policy=order
		description=String(POLICIES[order].description)
	elif order=="raze":
		data.ruined=true; data.reconstruction=false; result.damage=1.0
		data.grievance=clampf(float(data.grievance)+.25,0,1)
		data.local_institutions=maxf(0,float(data.local_institutions)-.3)
		description="Infrastructure was razed. Inhabitants remain here under the current legal status; no people were killed or moved by this order. Reconstruction now requires an explicit program."
	elif order=="reconstruct":
		data.reconstruction=true
		description="Reconstruction authorized. Recovery depends on supplied administration and local institutions; ruined infrastructure does not instantly reappear."
	else: return {"error":"Unknown occupation policy."}
	data.last_order_day=day
	var history:Array=data.history
	history.push_front({"day":day,"order":order,"description":description})
	while history.size()>16: history.pop_back()
	data.history=history; result.governance=data
	return {"ok":true,"region":result,"message":description}

static func validate(region:Dictionary)->Array[String]:
	var errors:Array[String]=[]
	if not region.has("governance"): return errors
	if not region.governance is Dictionary: return ["Occupation governance must be a dictionary."]
	var data:=state(region)
	if not POLICIES.has(String(data.policy)): errors.append("Unknown occupation policy.")
	for field in FIELDS:
		var value:=float(data[field])
		if not is_finite(value) or value<0 or value>1: errors.append("Invalid occupation measure: "+field)
	if not data.history is Array or data.history.size()>16: errors.append("Occupation history exceeds its bound.")
	if data.has("last_coercive_day"):
		var day:Variant=data.last_coercive_day
		if not (day is int or day is float) or not is_finite(float(day)) or float(day)<0 or floorf(float(day))!=float(day):errors.append("Invalid coercive operation day.")
	if int(data.months)<0: errors.append("Negative occupation duration.")
	return errors
