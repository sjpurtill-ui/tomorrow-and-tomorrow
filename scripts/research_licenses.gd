extends RefCounted
## A paid, time-limited manufacturing contract; no discovery or evidence grant.
const I=preload("res://scripts/civilian_industry.gd")
const E=preload("res://scripts/society_exchange.gd")
const TERM:=365
const LIMIT:=5000
static func subjects()->Array[String]:
	var result:Array[String]=[]
	for recipe:Dictionary in I.PRODUCTS.values():
		if recipe.gate not in result:result.append(recipe.gate)
	return result
static func available()->bool:
	return "workshop_standards" in WorldSimulation.state.known_discoveries and "material_accounting" in WorldSimulation.state.known_discoveries
static func records()->Dictionary:return E.data().get("production_licenses",{})
static func independent(subject:String)->bool:
	return subject in WorldSimulation.state.known_discoveries and WorldSimulation.discovery.adoption(subject)>=.10
static func supported(source:String,subject:String)->bool:
	var provider:=E.owner_state(source)
	if provider==null or subject not in provider.known_discoveries or provider.society_exchange.sharing_policy!="open" or provider.effective_workers("Crafting")<1:return false
	var index:int=WorldSimulation.world._civilization_index("human" if source=="player" and WorldSimulation.actor_id!="player" else source)
	if index<0 or bool(WorldSimulation.world.civilizations[index].get("player_relation",{}).get("at_war",false)):return false
	return float(provider.discovery_adoption.get(subject,0))>=.35
static func active(subject:String)->bool:
	var contract:Dictionary=records().get(subject,{})
	if contract.is_empty() or int(WorldSimulation.state.elapsed_days)<int(contract.issued_day) or int(WorldSimulation.state.elapsed_days)>=int(contract.expires_day):return false
	return supported(String(contract.source),subject)
static func uses_license(item:String)->bool:
	var recipe:Dictionary=I.product(item)
	return not recipe.is_empty() and not independent(String(recipe.gate)) and active(String(recipe.gate))
static func quote(source:String,subject:String,payment:String)->Dictionary:
	if not available() or subject not in subjects():return {"error":"Production licenses need workshop standards, material accounting and a supported civilian manufacturing process."}
	if independent(subject):return {"error":"Local mastery already supports independent manufacture."}
	var contract:Dictionary=records().get(subject,{})
	if active(subject) and int(contract.get("expires_day",0))-int(WorldSimulation.state.elapsed_days)>90:return {"error":"This contract is not yet due for renewal; renew during its final 90 days."}
	if not records().has(subject) and records().size()>=LIMIT:return {"error":"The production contract register is full."}
	var terms:Dictionary=WorldSimulation.world.diplomatic_mission_quote(source,payment,"goodwill")
	if terms.has("error"):return terms
	terms["purpose_label"]="NEGOTIATE PRODUCTION LICENSE"
	terms["message"]="Offer %s for 365 days of licensed manufacture of %s, starting on return. Licensed throughput is 65%% of independent manufacture. Real tooling, inputs, craftspeople and power remain necessary. War, supplier withdrawal or expiry pause dependent lines. No research or adoption is granted. Travel costs %.1f Food over %d days; the supplier may refuse." % [terms.gift.label,WorldSimulation.discovery.discovery_definition(subject).name,float(terms.provisions),int(terms.total_days)]
	return terms
static func dispatch(source:String,subject:String,payment:String)->Dictionary:
	return WorldSimulation.world.dispatch_diplomat(source,payment,"goodwill",subject,"license")
static func valid(value:Variant)->bool:
	if not value is Dictionary or value.size()>LIMIT:return false
	for subject:Variant in value:
		var record:Variant=value[subject]
		if not subject is String or subject not in subjects() or not record is Dictionary or not record.has_all(["source","issued_day","expires_day"]):return false
		if not E.short_text(record.source) or String(record.source).is_empty():return false
		for field:String in ["issued_day","expires_day"]:
			if not E.number(record[field]) or record[field]<0 or float(record[field])!=floorf(float(record[field])):return false
		if int(record.expires_day)-int(record.issued_day)!=TERM:return false
	return true
static func valid_mission(mission:Dictionary)->bool:
	if String(mission.get("research_subject","")) not in subjects():return false
	for flag:String in ["license_authorized","license_delivered"]:
		if mission.has(flag) and not mission[flag] is bool:return false
	if mission.get("license_authorized",false) and mission.get("research_refused",false):return false
	if mission.get("license_delivered",false) and not mission.get("license_authorized",false):return false
	return true
static func negotiate(mission:Dictionary,source:String,day:int)->void:
	if mission.has("research_refused") or day<int(mission.get("arrival_day",day+1)):return
	if E.owner_id(source)!=E.owner_id(String(mission.get("civ_id",""))):return
	var accepted:=valid_mission(mission) and float(mission.get("gift_amount",0))>0 and supported(E.owner_id(source),String(mission.research_subject))
	mission["research_refused"]=not accepted;mission["accepted"]=accepted;mission["license_authorized"]=accepted
	mission["outcome"]="The supplier authorized a one-year manufacturing contract. It takes effect when the envoys return." if accepted else "The supplier declined the manufacturing contract. Unused payment returns with the envoys."
static func prepare_return(mission:Dictionary)->void:
	if not mission.get("license_authorized",false):mission["research_refused"]=true;mission["accepted"]=false
static func deliver(mission:Dictionary,day:int)->Array[Dictionary]:
	if day<int(mission.get("return_day",day+1)) or mission.get("license_delivered",false) or mission.get("research_refused",false) or not mission.get("license_authorized",false) or not valid_mission(mission):return []
	var subject:=String(mission.research_subject)
	if not E.data().has("production_licenses"):E.data()["production_licenses"]={}
	if not records().has(subject) and records().size()>=LIMIT:return []
	E.data().production_licenses[subject]={"source":E.owner_id(String(mission.civ_id)),"issued_day":day,"expires_day":day+TERM}
	mission["license_delivered"]=true
	return [{"title":"Production contract returned","consequence":"Licensed manufacture of %s is available for one year while supplier support continues. Independent knowledge is unchanged." % WorldSimulation.discovery.discovery_definition(subject).name}]
static func describe(subject:String)->String:
	var contract:Dictionary=records().get(subject,{})
	if contract.is_empty():return ""
	if independent(subject):return "Local mastery supports independent manufacture; the foreign production contract is no longer required."
	return "Production license: %s; expires on day %d. Licensed throughput: 65%%. Materials, tooling, labor and power still apply." % ["supplier support available" if active(subject) else "expired or supplier support interrupted",int(contract.expires_day)]
