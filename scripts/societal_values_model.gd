extends RefCounted

# A civilization's normative identity is a fixed-size aggregate model. It never
# stores people, households, voters, or opinions per resident, so its runtime is
# independent of population. Values describe what ought to happen; institutions
# describe how collective power actually operates; the existing twelve society
# dynamics continue to describe what the civilization is capable of doing.

const MODEL_VERSION:=2
const HISTORY_LIMIT:=24
const VALUE_ORDER:Array[String]=[
	"hierarchy","collective_obligation","centralization","experimentation","pluralism",
	"common_stewardship","restorative_justice","openness","ecological_restraint","achieved_status"
]
const VALUE_DEFINITIONS:Dictionary={
	"hierarchy":{"name":"STATUS","low":"EQUAL STANDING","high":"RANKED AUTHORITY","meaning":"Whether unequal rank and command are considered legitimate."},
	"collective_obligation":{"name":"OBLIGATION","low":"PERSONAL AUTONOMY","high":"COMMON DUTY","meaning":"Whether people owe labor, resources, and care to the wider community."},
	"centralization":{"name":"POWER","low":"LOCAL RULE","high":"CENTRAL DIRECTION","meaning":"Whether binding decisions should be made locally or by a common center."},
	"experimentation":{"name":"CHANGE","low":"INHERITED PRACTICE","high":"EXPERIMENTATION","meaning":"Whether tested custom or deliberate novelty deserves the presumption of trust."},
	"pluralism":{"name":"DIFFERENCE","low":"CONFORMITY","high":"PLURALISM","meaning":"How much disagreement and distinct ways of life are treated as legitimate."},
	"common_stewardship":{"name":"OWNERSHIP","low":"PRIVATE CONTROL","high":"COMMON STEWARDSHIP","meaning":"Whether essential land, work, and reserves should be privately controlled or collectively governed."},
	"restorative_justice":{"name":"JUSTICE","low":"PUNISHMENT","high":"RESTORATION","meaning":"Whether wrongdoing is answered primarily through coercion or repaired relationships."},
	"openness":{"name":"OUTSIDERS","low":"EXCLUSION","high":"OPENNESS","meaning":"Whether exchange, migration, and foreign practices are welcomed or contained."},
	"ecological_restraint":{"name":"LAND","low":"EXTRACTION","high":"RESTRAINT","meaning":"Whether growth should be limited to preserve ecological continuity."},
	"achieved_status":{"name":"ADVANCEMENT","low":"INHERITED STANDING","high":"ACHIEVED STANDING","meaning":"Whether social position follows birth and tradition or demonstrated contribution."}
}

const FOCUS_BIASES:Dictionary={
	"provision":{"collective_obligation":0.12,"common_stewardship":0.10,"ecological_restraint":0.05},
	"generations":{"collective_obligation":0.10,"restorative_justice":0.08,"ecological_restraint":0.07,"experimentation":-0.04},
	"inquiry":{"experimentation":0.17,"pluralism":0.10,"openness":0.08,"achieved_status":0.08,"hierarchy":-0.05},
	"industry":{"experimentation":0.09,"achieved_status":0.10,"ecological_restraint":-0.15,"common_stewardship":-0.05},
	"defense":{"collective_obligation":0.10,"centralization":0.13,"hierarchy":0.10,"openness":-0.08,"restorative_justice":-0.06},
	"exchange":{"openness":0.17,"pluralism":0.10,"achieved_status":0.07,"centralization":-0.04,"common_stewardship":-0.05}
}

# Every entry is an already-existing organizational discovery. Discovery makes
# an institution possible; it never dictates the form a civilization adopts.
# Variant `fit` values are normative targets in the same ten-dimensional space.
const INSTITUTIONS:Dictionary={
	"household_councils":{"name":"HOUSEHOLD COUNCILS","variants":[
		{"id":"delegated_councils","name":"Delegated Councils","fit":{"hierarchy":0.30,"collective_obligation":0.72,"centralization":0.28,"pluralism":0.72,"restorative_justice":0.70}},
		{"id":"appointed_stewards","name":"Appointed Stewards","fit":{"hierarchy":0.72,"collective_obligation":0.62,"centralization":0.72,"pluralism":0.30,"achieved_status":0.55}},
		{"id":"customary_elders","name":"Customary Elders","fit":{"hierarchy":0.68,"centralization":0.30,"experimentation":0.22,"pluralism":0.38,"achieved_status":0.25}}
	]},
	"census_rolls":{"name":"POPULATION REGISTRATION","variants":[
		{"id":"civic_registry","name":"Civic Registry","fit":{"centralization":0.58,"common_stewardship":0.58,"pluralism":0.62,"achieved_status":0.68}},
		{"id":"obligation_rolls","name":"Obligation Rolls","fit":{"collective_obligation":0.78,"centralization":0.74,"hierarchy":0.58,"common_stewardship":0.66}},
		{"id":"status_registers","name":"Status Registers","fit":{"hierarchy":0.82,"centralization":0.67,"pluralism":0.22,"achieved_status":0.18}}
	]},
	"public_levies":{"name":"PUBLIC OBLIGATIONS","variants":[
		{"id":"reciprocal_service","name":"Reciprocal Service","fit":{"collective_obligation":0.78,"centralization":0.35,"common_stewardship":0.72,"restorative_justice":0.66}},
		{"id":"assessed_contributions","name":"Assessed Contributions","fit":{"collective_obligation":0.58,"centralization":0.65,"achieved_status":0.62,"pluralism":0.55}},
		{"id":"compulsory_levy","name":"Compulsory Levy","fit":{"hierarchy":0.78,"collective_obligation":0.74,"centralization":0.82,"restorative_justice":0.22}}
	]},
	"specialized_courts":{"name":"FORMAL JUSTICE","variants":[
		{"id":"restorative_tribunals","name":"Restorative Tribunals","fit":{"hierarchy":0.30,"pluralism":0.67,"restorative_justice":0.86,"achieved_status":0.60}},
		{"id":"codified_courts","name":"Codified Courts","fit":{"centralization":0.68,"pluralism":0.58,"restorative_justice":0.54,"achieved_status":0.74}},
		{"id":"status_courts","name":"Status Courts","fit":{"hierarchy":0.84,"centralization":0.70,"pluralism":0.20,"restorative_justice":0.24,"achieved_status":0.18}}
	]},
	"property_registers":{"name":"TENURE SYSTEM","variants":[
		{"id":"common_tenure","name":"Common Tenure","fit":{"collective_obligation":0.70,"centralization":0.35,"common_stewardship":0.88,"ecological_restraint":0.68}},
		{"id":"household_title","name":"Household Title","fit":{"collective_obligation":0.34,"centralization":0.42,"common_stewardship":0.18,"achieved_status":0.65}},
		{"id":"state_allotment","name":"State Allotment","fit":{"hierarchy":0.66,"centralization":0.86,"common_stewardship":0.72,"pluralism":0.30}}
	]},
	"craft_guilds":{"name":"ORGANIZED PRODUCTION","variants":[
		{"id":"mutual_associations","name":"Mutual Craft Associations","fit":{"collective_obligation":0.68,"centralization":0.30,"common_stewardship":0.62,"pluralism":0.62}},
		{"id":"licensed_guilds","name":"Licensed Guilds","fit":{"hierarchy":0.66,"centralization":0.70,"pluralism":0.32,"achieved_status":0.54}},
		{"id":"open_professions","name":"Open Professions","fit":{"hierarchy":0.25,"experimentation":0.74,"pluralism":0.72,"openness":0.68,"achieved_status":0.86}}
	]},
	"public_credit":{"name":"PUBLIC CREDIT","variants":[
		{"id":"civic_bonds","name":"Civic Bonds","fit":{"collective_obligation":0.62,"centralization":0.55,"common_stewardship":0.58,"openness":0.60}},
		{"id":"directed_credit","name":"Directed State Credit","fit":{"hierarchy":0.66,"centralization":0.86,"common_stewardship":0.70,"pluralism":0.28}},
		{"id":"merchant_credit","name":"Merchant Credit","fit":{"collective_obligation":0.25,"centralization":0.30,"common_stewardship":0.16,"openness":0.80,"achieved_status":0.76}}
	]},
	"risk_pools":{"name":"SHARED RISK","variants":[
		{"id":"mutual_aid_funds","name":"Mutual Aid Funds","fit":{"collective_obligation":0.82,"centralization":0.30,"common_stewardship":0.76,"restorative_justice":0.68}},
		{"id":"public_insurance","name":"Public Insurance","fit":{"collective_obligation":0.70,"centralization":0.78,"common_stewardship":0.72,"achieved_status":0.66}},
		{"id":"private_underwriting","name":"Private Underwriting","fit":{"collective_obligation":0.24,"centralization":0.24,"common_stewardship":0.15,"openness":0.74,"achieved_status":0.76}}
	]},
	"professional_service":{"name":"CIVIL SERVICE","variants":[
		{"id":"merit_service","name":"Merit Civil Service","fit":{"hierarchy":0.48,"centralization":0.72,"experimentation":0.62,"pluralism":0.56,"achieved_status":0.90}},
		{"id":"patronage_service","name":"Patronage Service","fit":{"hierarchy":0.84,"centralization":0.78,"experimentation":0.28,"pluralism":0.22,"achieved_status":0.20}},
		{"id":"communal_rotation","name":"Communal Office Rotation","fit":{"hierarchy":0.22,"collective_obligation":0.76,"centralization":0.34,"pluralism":0.70,"achieved_status":0.62}}
	]}
}

# Later institutional inquiry does not merely add a generic capacity score. Four
# bounded organizational families become possible when a civilization has
# actually established sufficiently mature, concrete lines of inquiry into the
# relevant problem. Their variants are selected by the civilization's lived
# values, so identical discoveries can produce very different states.
const EMERGENT_INSTITUTIONS:Dictionary={
	"territorial_administration":{"name":"TERRITORIAL ADMINISTRATION","variants":[
		{"id":"federated_districts","name":"Federated District Councils","fit":{"hierarchy":0.30,"collective_obligation":0.68,"centralization":0.36,"pluralism":0.72,"common_stewardship":0.64}},
		{"id":"prefectural_administration","name":"Prefectural Administration","fit":{"hierarchy":0.74,"collective_obligation":0.66,"centralization":0.86,"pluralism":0.30,"achieved_status":0.60}},
		{"id":"chartered_localities","name":"Chartered Localities","fit":{"hierarchy":0.42,"centralization":0.28,"pluralism":0.66,"openness":0.74,"achieved_status":0.70}}
	]},
	"constitutional_order":{"name":"CONSTITUTIONAL ORDER","variants":[
		{"id":"deliberative_compact","name":"Deliberative Compact","fit":{"hierarchy":0.24,"centralization":0.42,"pluralism":0.82,"restorative_justice":0.74,"openness":0.70}},
		{"id":"codified_constitution","name":"Codified Constitution","fit":{"hierarchy":0.42,"centralization":0.62,"experimentation":0.62,"pluralism":0.68,"achieved_status":0.76}},
		{"id":"sovereign_charter","name":"Sovereign Charter","fit":{"hierarchy":0.84,"collective_obligation":0.72,"centralization":0.88,"pluralism":0.20,"restorative_justice":0.28}}
	]},
	"mass_public_systems":{"name":"MASS PUBLIC SYSTEMS","variants":[
		{"id":"universal_public_service","name":"Universal Public Service","fit":{"collective_obligation":0.84,"centralization":0.70,"common_stewardship":0.82,"pluralism":0.64,"achieved_status":0.72}},
		{"id":"coordinated_social_bodies","name":"Coordinated Social Bodies","fit":{"hierarchy":0.62,"collective_obligation":0.72,"centralization":0.64,"pluralism":0.42,"common_stewardship":0.56}},
		{"id":"command_ministries","name":"Command Ministries","fit":{"hierarchy":0.82,"collective_obligation":0.78,"centralization":0.92,"pluralism":0.16,"common_stewardship":0.72}}
	]},
	"adaptive_governance":{"name":"ADAPTIVE GOVERNANCE","variants":[
		{"id":"experimental_federalism","name":"Experimental Federalism","fit":{"hierarchy":0.24,"centralization":0.34,"experimentation":0.88,"pluralism":0.82,"openness":0.72}},
		{"id":"independent_review_service","name":"Independent Review Service","fit":{"hierarchy":0.44,"centralization":0.66,"experimentation":0.78,"pluralism":0.66,"achieved_status":0.86}},
		{"id":"mobilized_revision_committees","name":"Mobilized Revision Committees","fit":{"hierarchy":0.70,"collective_obligation":0.82,"centralization":0.86,"experimentation":0.72,"pluralism":0.24}}
	]}
}

# Prefixes address whole investigative traditions rather than one hard-coded
# discovery. Any viable lens can open the organizational possibility once its
# concrete practice reaches the required maturity.
const FRONTIER_INSTITUTION_UNLOCKS:Array[Dictionary]=[
	{"id":"territorial_administration","prefix":"inquiry_institutions_administration_","maturity":5},
	{"id":"constitutional_order","prefix":"inquiry_institutions_legitimacy_","maturity":6},
	{"id":"mass_public_systems","prefix":"inquiry_institutions_state_capacity_","maturity":9},
	{"id":"adaptive_governance","prefix":"inquiry_institutions_institutional_flexibility_","maturity":11}
]

static func initial_state(founding_focus:String="",world_seed:int=0,civilization_id:String="player")->Dictionary:
	var rng:=RandomNumberGenerator.new()
	rng.seed=world_seed^hash(civilization_id)^0x45d9f3b
	var lived:Dictionary={}
	for axis in VALUE_ORDER: lived[axis]=clampf(0.50+rng.randf_range(-0.035,0.035),0.05,0.95)
	var state:Dictionary={
		"version":MODEL_VERSION,"lived":lived,"official":lived.duplicate(true),
		"institutional_orientation":lived.duplicate(true),"institutions":{},
		"tension":0.0,"alignment":1.0,"last_update_day":0,"history":[],
		"identity":{},"architecture":{}
	}
	if founding_focus!="": state=apply_founding_focus(state,founding_focus)
	return _refresh_summaries(state)


static func apply_founding_focus(state:Dictionary,focus_id:String)->Dictionary:
	var result:=normalize_state(state)
	var biases:Dictionary=FOCUS_BIASES.get(focus_id,{})
	for axis in biases:
		var shift:=float(biases[axis])
		result.lived[axis]=clampf(float(result.lived.get(axis,0.5))+shift*0.72,0.04,0.96)
		result.official[axis]=clampf(float(result.official.get(axis,0.5))+shift,0.04,0.96)
		result.institutional_orientation[axis]=clampf(float(result.institutional_orientation.get(axis,0.5))+shift*0.55,0.04,0.96)
	return _refresh_summaries(result)


static func normalize_state(state:Dictionary)->Dictionary:
	var result:=state.duplicate(true)
	if result.is_empty(): return initial_state()
	result["version"]=MODEL_VERSION
	for vector_name in ["lived","official"]:
		var vector:Dictionary=(result.get(vector_name,{}) as Dictionary).duplicate(true)
		for axis in VALUE_ORDER: vector[axis]=clampf(float(vector.get(axis,0.5)),0.0,1.0)
		result[vector_name]=vector
	result["institutions"]=_normalize_institution_records(result.get("institutions",{}))
	var orientation:Dictionary=(result.get("institutional_orientation",{}) as Dictionary).duplicate(true)
	if orientation.is_empty(): orientation=_institutional_target(result)
	for axis in VALUE_ORDER: orientation[axis]=clampf(float(orientation.get(axis,result.lived.get(axis,0.5))),0.0,1.0)
	result["institutional_orientation"]=orientation
	result["history"]=(result.get("history",[]) as Array).duplicate(true)
	if (result.history as Array).size()>HISTORY_LIMIT: result.history.resize(HISTORY_LIMIT)
	result["last_update_day"]=maxi(0,int(result.get("last_update_day",0)))
	return _refresh_summaries(result)


# Saves use arrays for the fixed value axes and omit every derived presentation
# field. This keeps the civilization save budget independent of population while
# the live state remains self-documenting for simulation and UI code.
static func serialize_state(state:Dictionary)->Dictionary:
	var normalized:=normalize_state(state)
	var lived:Array=[]
	var official:Array=[]
	for axis in VALUE_ORDER:
		lived.append(float(normalized.lived[axis]))
		official.append(float(normalized.official[axis]))
	var forms:Dictionary={}
	for institution_id in normalized.institutions:
		var record:Dictionary=normalized.institutions[institution_id]
		forms[institution_id]=[
			String(record.get("variant","")),float(record.get("adoption",0.025)),
			int(record.get("discovered_day",0)),int(record.get("last_reformed_day",0)),
			String(record.get("source_discovery",institution_id))
		]
	return {"v":MODEL_VERSION,"l":lived,"o":official,"f":forms,"d":int(normalized.last_update_day),"h":_pack_history(normalized.history)}


static func deserialize_state(payload:Dictionary)->Dictionary:
	# Full dictionaries remain valid for in-memory snapshots and older saves.
	if not payload.has("l"): return normalize_state(payload)
	var lived:Dictionary={}
	var official:Dictionary={}
	var lived_values:Array=payload.get("l",[])
	var official_values:Array=payload.get("o",[])
	for index in VALUE_ORDER.size():
		var axis:=VALUE_ORDER[index]
		lived[axis]=float(lived_values[index]) if index<lived_values.size() else 0.5
		official[axis]=float(official_values[index]) if index<official_values.size() else float(lived[axis])
	var institutions:Dictionary={}
	for institution_id in (payload.get("f",{}) as Dictionary):
		var packed:Variant=payload.f[institution_id]
		if not packed is Array: continue
		institutions[institution_id]={
			"variant":String(packed[0]) if packed.size()>0 else "",
			"adoption":float(packed[1]) if packed.size()>1 else 0.025,
			"discovered_day":int(packed[2]) if packed.size()>2 else 0,
			"last_reformed_day":int(packed[3]) if packed.size()>3 else 0,
			"source_discovery":String(packed[4]) if packed.size()>4 else institution_id
		}
	return normalize_state({"version":int(payload.get("v",MODEL_VERSION)),"lived":lived,"official":official,"institutions":institutions,"last_update_day":int(payload.get("d",0)),"history":_unpack_history(payload.get("h",[]))})


static func advance(state:Dictionary,known_organizations:Array,adoption:Dictionary,context:Dictionary,day:int)->Dictionary:
	var result:=normalize_state(state)
	var prior_identity:=String((result.get("identity",{}) as Dictionary).get("name",""))
	day=maxi(0,day)
	var possibilities:=organizational_possibilities(known_organizations,adoption)
	result=_synchronize_institutions(result,possibilities.known,possibilities.adoption,day,possibilities.sources)
	var elapsed_months:=clampf(float(day-int(result.get("last_update_day",day)))/30.0,0.0,24.0)
	if elapsed_months>0.0:
		var institutional_target:=_institutional_target(result)
		var outcome_target:=_outcome_target(result.lived,context)
		var adaptability:=clampf(float(context.get("adaptability",0.5)),0.0,1.0)
		var lived_rate:=(0.0018+adaptability*0.0018)*elapsed_months
		var official_rate:=(0.0030+adaptability*0.0020)*elapsed_months
		for axis in VALUE_ORDER:
			var lived_target:=lerpf(float(outcome_target[axis]),float(institutional_target[axis]),0.38)
			result.lived[axis]=move_toward(float(result.lived[axis]),lived_target,lived_rate)
			var official_target:=lerpf(float(result.lived[axis]),float(institutional_target[axis]),0.72)
			result.official[axis]=move_toward(float(result.official[axis]),official_target,official_rate)
		result["institutional_orientation"]=institutional_target
		result["last_update_day"]=day
	result=_refresh_summaries(result)
	var current_identity:=String((result.get("identity",{}) as Dictionary).get("name",""))
	if day>0 and prior_identity!="" and current_identity!=prior_identity:
		result=_append_history(result,{"day":day,"type":"identity_shift","title":"Social identity changed","from":prior_identity,"to":current_identity})
	return result


static func organizational_discoveries_for_rival(civ:Dictionary)->Dictionary:
	# Rivals pay for discoveries through the same bounded progression profile.
	# Their abstract profile intentionally does not enumerate thousands of named
	# findings; society-domain breadth unlocks these nine organizational forms.
	var profile:Dictionary=civ.get("discovery_profile",{})
	var society_record:Dictionary=(profile.get("domains",{}) as Dictionary).get("institutions",{})
	var count:=maxi(0,int(society_record.get("count",0)))
	var maturity:=clampi(int(society_record.get("maturity",0)),0,12)
	var general_adoption:=clampf(float(society_record.get("adoption",0.025)),0.025,1.0)
	var known:Array=[]
	var adoption:Dictionary={}
	var order:Array[String]=["household_councils","census_rolls","public_levies","specialized_courts","property_registers","craft_guilds","public_credit","risk_pools","professional_service"]
	for index in order.size():
		if count<index+1: continue
		known.append(order[index])
		adoption[order[index]]=clampf(general_adoption*(1.0-float(index)*0.045),0.025,1.0)
	for unlock in FRONTIER_INSTITUTION_UNLOCKS:
		if maturity<int(unlock.maturity): continue
		var institution_id:=String(unlock.id)
		known.append(institution_id)
		adoption[institution_id]=clampf(general_adoption*(0.82+float(unlock.maturity)*0.01),0.025,1.0)
	return {"known":known,"adoption":adoption}


# Converts thousands of possible discovery ids into a fixed set of currently
# possible institutional families. The mapping is deterministic, bounded by the
# catalog above, and carries the exact discovery that opened each possibility.
static func organizational_possibilities(known_discoveries:Array,adoption:Dictionary)->Dictionary:
	var known:Array=[]
	var resolved_adoption:Dictionary={}
	var sources:Dictionary={}
	var best_frontier:Dictionary={}
	for discovery_variant in known_discoveries:
		var discovery_id:=String(discovery_variant)
		var spread:=clampf(float(adoption.get(discovery_id,0.025)),0.025,1.0)
		if not _institution_definition(discovery_id).is_empty():
			if discovery_id not in known: known.append(discovery_id)
			resolved_adoption[discovery_id]=spread
			sources[discovery_id]=discovery_id
		for unlock in FRONTIER_INSTITUTION_UNLOCKS:
			var maturity:=_frontier_maturity(discovery_id,String(unlock.prefix))
			if maturity<int(unlock.maturity): continue
			var institution_id:=String(unlock.id)
			var score:=float(maturity)+spread
			if score<=float((best_frontier.get(institution_id,{}) as Dictionary).get("score",-INF)): continue
			best_frontier[institution_id]={"id":discovery_id,"maturity":maturity,"adoption":spread,"score":score}
	for unlock in FRONTIER_INSTITUTION_UNLOCKS:
		var source:Dictionary=best_frontier.get(String(unlock.id),{})
		if source.is_empty(): continue
		var institution_id:=String(unlock.id)
		if institution_id not in known: known.append(institution_id)
		resolved_adoption[institution_id]=float(source.adoption)
		sources[institution_id]=String(source.id)
	return {"known":known,"adoption":resolved_adoption,"sources":sources}


static func simulation_effect(state:Dictionary,effect_id:String)->float:
	var normalized:=normalize_state(state)
	var lived:Dictionary=normalized.lived
	var alignment:=float(normalized.alignment)
	match effect_id:
		"cohesion": return clampf((alignment-0.50)*0.12+(float(lived.collective_obligation)-0.50)*0.035,-0.08,0.09)
		"legitimacy": return clampf((alignment-0.50)*0.14,-0.09,0.07)
		"institutions": return clampf((alignment-0.50)*0.10+(float(lived.centralization)-0.50)*0.025,-0.07,0.07)
		"knowledge": return clampf((float(lived.experimentation)-0.50)*0.08+(float(lived.pluralism)-0.50)*0.035,-0.06,0.07)
		"adoption": return clampf((float(lived.experimentation)-0.50)*0.10+(float(lived.openness)-0.50)*0.035,-0.07,0.08)
		"ecology": return clampf((float(lived.ecological_restraint)-0.50)*0.10,-0.05,0.05)
		"security": return clampf((float(lived.collective_obligation)-0.50)*0.035+(float(lived.hierarchy)-0.50)*0.025,-0.035,0.035)
		"trade": return clampf((float(lived.openness)-0.50)*0.09+(float(lived.pluralism)-0.50)*0.035,-0.06,0.07)
	return 0.0


static func identity_snapshot(state:Dictionary)->Dictionary:
	return (normalize_state(state).identity as Dictionary).duplicate(true)


static func architecture_snapshot(state:Dictionary)->Dictionary:
	return (normalize_state(state).architecture as Dictionary).duplicate(true)


static func value_definition(axis:String)->Dictionary:
	return (VALUE_DEFINITIONS.get(axis,{}) as Dictionary).duplicate(true)


static func active_institutions(state:Dictionary)->Array[Dictionary]:
	var normalized:=normalize_state(state)
	var records:Array[Dictionary]=[]
	for institution_id in normalized.institutions:
		records.append((normalized.institutions[institution_id] as Dictionary).duplicate(true))
	records.sort_custom(func(a:Dictionary,b:Dictionary)->bool: return float(a.get("adoption",0.0))>float(b.get("adoption",0.0)))
	return records


static func validate_state(state:Dictionary)->Array[String]:
	var errors:Array[String]=[]
	if state.is_empty(): errors.append("Societal values state is missing."); return errors
	for vector_name in ["lived","official","institutional_orientation"]:
		if not state.get(vector_name,{}) is Dictionary: errors.append("Societal %s values are malformed." % vector_name); continue
		var vector:Dictionary=state[vector_name]
		if vector.size()!=VALUE_ORDER.size(): errors.append("Societal %s values must contain exactly %d aggregate axes." % [vector_name,VALUE_ORDER.size()])
		for axis in VALUE_ORDER:
			var value:=float(vector.get(axis,NAN))
			if not is_finite(value) or value<0.0 or value>1.0: errors.append("Societal value %s.%s must be normalized." % [vector_name,axis])
	if not state.get("institutions",{}) is Dictionary: errors.append("Societal institutions are malformed.")
	elif (state.institutions as Dictionary).size()>INSTITUTIONS.size()+EMERGENT_INSTITUTIONS.size(): errors.append("Societal institutions exceed their fixed bound.")
	if not state.get("history",[]) is Array or (state.get("history",[]) as Array).size()>HISTORY_LIMIT: errors.append("Societal value history exceeds its fixed bound.")
	for metric in ["tension","alignment"]:
		var value:=float(state.get(metric,NAN))
		if not is_finite(value) or value<0.0 or value>1.0: errors.append("Societal %s must be normalized." % metric)
	return errors


static func _institution_definition(institution_id:String)->Dictionary:
	if INSTITUTIONS.has(institution_id): return INSTITUTIONS[institution_id]
	return EMERGENT_INSTITUTIONS.get(institution_id,{})


static func _frontier_maturity(discovery_id:String,prefix:String)->int:
	if not discovery_id.begins_with(prefix) or discovery_id.length()<3: return 0
	var suffix:=discovery_id.substr(discovery_id.length()-2,2)
	if not suffix.is_valid_int(): return 0
	return clampi(int(suffix),0,12)


static func _synchronize_institutions(state:Dictionary,known_organizations:Array,adoption:Dictionary,day:int,sources:Dictionary={})->Dictionary:
	var result:=state.duplicate(true)
	var records:Dictionary=(result.get("institutions",{}) as Dictionary).duplicate(true)
	for institution_id_variant in known_organizations:
		var institution_id:=String(institution_id_variant)
		var definition:=_institution_definition(institution_id)
		if definition.is_empty(): continue
		var selected:=_best_variant(definition,result.lived)
		var record:Dictionary=(records.get(institution_id,{}) as Dictionary).duplicate(true)
		if record.is_empty():
			var source:=String(sources.get(institution_id,institution_id))
			record={"id":institution_id,"name":String(definition.name),"variant":String(selected.id),"form":String(selected.name),"adoption":0.025,"discovered_day":day,"last_reformed_day":day,"source_discovery":source}
			result=_append_history(result,{"day":day,"type":"institution_adopted","title":"%s began to spread" % String(selected.name),"institution":institution_id,"form":String(selected.name),"source_discovery":source})
		else:
			var current:=_variant_by_id(definition,String(record.get("variant","")))
			var current_fit:=_variant_fitness(current,result.lived) if not current.is_empty() else -1.0
			var selected_fit:=_variant_fitness(selected,result.lived)
			if day-int(record.get("last_reformed_day",day))>=3650 and selected_fit>current_fit+0.16:
				var prior_form:=String(record.get("form","Earlier practice"))
				record["variant"]=String(selected.id)
				record["form"]=String(selected.name)
				record["last_reformed_day"]=day
				result=_append_history(result,{"day":day,"type":"institution_reformed","title":"%s was reorganized" % String(definition.name),"institution":institution_id,"from":prior_form,"to":String(selected.name)})
		var old_adoption:=float(record.get("adoption",0.025))
		record["adoption"]=clampf(float(adoption.get(institution_id,old_adoption)),0.025,1.0)
		records[institution_id]=record
	result["institutions"]=records
	return result


static func _append_history(state:Dictionary,event:Dictionary)->Dictionary:
	var result:=state.duplicate(true)
	var history:Array=(result.get("history",[]) as Array).duplicate(true)
	history.push_front(event.duplicate(true))
	if history.size()>HISTORY_LIMIT: history.resize(HISTORY_LIMIT)
	result["history"]=history
	return result


static func _normalize_institution_records(raw:Variant)->Dictionary:
	var records:Dictionary={}
	if not raw is Dictionary: return records
	for institution_id_variant in raw:
		var institution_id:=String(institution_id_variant)
		var definition:=_institution_definition(institution_id)
		if definition.is_empty(): continue
		var source:Dictionary=(raw[institution_id_variant] as Dictionary).duplicate(true)
		var variant:=_variant_by_id(definition,String(source.get("variant","")))
		if variant.is_empty(): variant=(definition.variants as Array)[0]
		records[institution_id]={
			"id":institution_id,"name":String(definition.name),"variant":String(variant.id),"form":String(variant.name),
			"adoption":clampf(float(source.get("adoption",0.025)),0.025,1.0),
			"discovered_day":maxi(0,int(source.get("discovered_day",0))),
			"last_reformed_day":maxi(0,int(source.get("last_reformed_day",source.get("discovered_day",0)))),
			"source_discovery":String(source.get("source_discovery",institution_id))
		}
	return records


static func _pack_history(history:Variant)->Array:
	var packed:Array=[]
	if not history is Array: return packed
	for event_variant in history:
		if not event_variant is Dictionary: continue
		var event:Dictionary=event_variant
		match String(event.get("type","")):
			"institution_adopted": packed.append([int(event.get("day",0)),0,String(event.get("institution","")),String(event.get("form","")),String(event.get("source_discovery",event.get("institution","")))])
			"institution_reformed": packed.append([int(event.get("day",0)),1,String(event.get("institution","")),String(event.get("from","")),String(event.get("to",""))])
			"identity_shift": packed.append([int(event.get("day",0)),2,String(event.get("from","")),String(event.get("to",""))])
			_: packed.append(event.duplicate(true))
	return packed


static func _unpack_history(history:Variant)->Array:
	var unpacked:Array=[]
	if not history is Array: return unpacked
	for event_variant in history:
		if event_variant is Dictionary:
			unpacked.append((event_variant as Dictionary).duplicate(true))
			continue
		if not event_variant is Array or event_variant.size()<2: continue
		var event:Array=event_variant
		var day:=int(event[0])
		match int(event[1]):
			0:
				var form:=String(event[3]) if event.size()>3 else "New practice"
				var institution_id:=String(event[2]) if event.size()>2 else ""
				unpacked.append({"day":day,"type":"institution_adopted","title":"%s began to spread" % form,"institution":institution_id,"form":form,"source_discovery":String(event[4]) if event.size()>4 else institution_id})
			1:
				unpacked.append({"day":day,"type":"institution_reformed","title":"Institution reorganized","institution":String(event[2]) if event.size()>2 else "","from":String(event[3]) if event.size()>3 else "","to":String(event[4]) if event.size()>4 else ""})
			2:
				unpacked.append({"day":day,"type":"identity_shift","title":"Social identity changed","from":String(event[2]) if event.size()>2 else "","to":String(event[3]) if event.size()>3 else ""})
	if unpacked.size()>HISTORY_LIMIT: unpacked.resize(HISTORY_LIMIT)
	return unpacked


static func _best_variant(definition:Dictionary,values:Dictionary)->Dictionary:
	var best:Dictionary={}
	var best_score:=-INF
	for variant_variant in (definition.get("variants",[]) as Array):
		var variant:Dictionary=variant_variant
		var score:=_variant_fitness(variant,values)
		if score>best_score: best_score=score; best=variant
	return best


static func _variant_by_id(definition:Dictionary,variant_id:String)->Dictionary:
	for variant_variant in (definition.get("variants",[]) as Array):
		var variant:Dictionary=variant_variant
		if String(variant.get("id",""))==variant_id: return variant
	return {}


static func _variant_fitness(variant:Dictionary,values:Dictionary)->float:
	if variant.is_empty(): return -1.0
	var fit:Dictionary=variant.get("fit",{})
	var total:=0.0
	for axis in fit: total+=1.0-absf(float(values.get(axis,0.5))-float(fit[axis]))
	return total/maxf(1.0,float(fit.size()))


static func _institutional_target(state:Dictionary)->Dictionary:
	var target:Dictionary=(state.lived as Dictionary).duplicate(true)
	var totals:Dictionary={}
	for axis in VALUE_ORDER: totals[axis]=0.0
	var total_weight:=0.0
	for institution_id in state.institutions:
		var record:Dictionary=state.institutions[institution_id]
		var definition:=_institution_definition(String(institution_id))
		var variant:=_variant_by_id(definition,String(record.get("variant","")))
		var weight:=clampf(float(record.get("adoption",0.025)),0.025,1.0)
		for axis in (variant.get("fit",{}) as Dictionary): totals[axis]=float(totals[axis])+float(variant.fit[axis])*weight
		total_weight+=weight
	if total_weight>0.0:
		for axis in VALUE_ORDER:
			if float(totals[axis])>0.0: target[axis]=lerpf(float(target[axis]),float(totals[axis])/total_weight,0.62)
	return target


static func _outcome_target(current:Dictionary,context:Dictionary)->Dictionary:
	var target:=current.duplicate(true)
	var food:=clampf(float(context.get("food",0.6)),0.0,1.0)
	var health:=clampf(float(context.get("health",0.6)),0.0,1.0)
	var security:=clampf(float(context.get("security",0.4)),0.0,1.0)
	var ecology:=clampf(float(context.get("ecology",0.7)),0.0,1.0)
	var knowledge:=clampf(float(context.get("knowledge",0.2)),0.0,1.0)
	var trade:=clampf(float(context.get("trade",0.0)),0.0,1.0)
	var war:=clampf(float(context.get("war_pressure",0.0)),0.0,1.0)
	var inequality:=clampf(float(context.get("inequality",0.35)),0.0,1.0)
	var crisis:=clampf((1.0-food)*0.42+(1.0-health)*0.28+war*0.30,0.0,1.0)
	target.collective_obligation=clampf(float(target.collective_obligation)+(crisis-0.35)*0.16,0.05,0.95)
	target.centralization=clampf(float(target.centralization)+war*0.18+crisis*0.06-trade*0.04,0.05,0.95)
	target.hierarchy=clampf(float(target.hierarchy)+war*0.13-(knowledge*0.04),0.05,0.95)
	target.experimentation=clampf(float(target.experimentation)+(knowledge-0.35)*0.16+crisis*0.035,0.05,0.95)
	target.pluralism=clampf(float(target.pluralism)+trade*0.12-war*0.10,0.05,0.95)
	target.openness=clampf(float(target.openness)+trade*0.16-war*0.16,0.05,0.95)
	target.common_stewardship=clampf(float(target.common_stewardship)+(inequality-0.45)*0.12+crisis*0.05,0.05,0.95)
	target.restorative_justice=clampf(float(target.restorative_justice)-war*0.12+(security-0.45)*0.04,0.05,0.95)
	target.ecological_restraint=clampf(float(target.ecological_restraint)+(0.65-ecology)*0.18,0.05,0.95)
	target.achieved_status=clampf(float(target.achieved_status)+(knowledge-0.40)*0.10,0.05,0.95)
	return target


static func _refresh_summaries(state:Dictionary)->Dictionary:
	var result:=state.duplicate(true)
	var lived:Dictionary=result.get("lived",{})
	var official:Dictionary=result.get("official",{})
	var institutional:Dictionary=result.get("institutional_orientation",lived)
	var official_gap:=0.0
	var institutional_gap:=0.0
	for axis in VALUE_ORDER:
		official_gap+=absf(float(lived.get(axis,0.5))-float(official.get(axis,0.5)))
		institutional_gap+=absf(float(lived.get(axis,0.5))-float(institutional.get(axis,0.5)))
	var tension:=clampf((official_gap*0.56+institutional_gap*0.44)/float(VALUE_ORDER.size()),0.0,1.0)
	result["tension"]=tension
	result["alignment"]=clampf(1.0-tension*1.55,0.0,1.0)
	result["identity"]=_derive_identity(result)
	result["architecture"]=_derive_architecture(result)
	return result


static func _derive_identity(state:Dictionary)->Dictionary:
	var values:Dictionary=state.lived
	var governance:="CENTRALIZED" if float(values.centralization)>=0.66 else ("LOCALIST" if float(values.centralization)<=0.36 else "FEDERATED")
	var social:="STRATIFIED" if float(values.hierarchy)>=0.68 else ("COMMUNAL" if float(values.collective_obligation)>=0.66 else ("PLURAL" if float(values.pluralism)>=0.66 else "CIVIC"))
	var noun:="ORDER"
	if state.institutions.has("professional_service"): noun="STATE"
	elif state.institutions.has("specialized_courts"): noun="COMMONWEALTH"
	elif state.institutions.has("household_councils"): noun="COUNCIL SOCIETY"
	var traits:Array[Dictionary]=[]
	for axis in VALUE_ORDER:
		var value:=float(values[axis])
		traits.append({"axis":axis,"strength":absf(value-0.5),"label":String(VALUE_DEFINITIONS[axis].high if value>=0.5 else VALUE_DEFINITIONS[axis].low),"value":value})
	traits.sort_custom(func(a:Dictionary,b:Dictionary)->bool: return float(a.strength)>float(b.strength))
	if traits.size()>3: traits.resize(3)
	var labels:Array[String]=[]
	for entry in traits: labels.append(String(entry.label).capitalize())
	return {"name":"%s %s %s" % [governance,social,noun],"traits":traits,"summary":", ".join(labels),"alignment":float(state.alignment),"tension":float(state.tension)}


static func _derive_architecture(state:Dictionary)->Dictionary:
	var values:Dictionary=state.lived
	return {
		"axiality":clampf(float(values.centralization)*0.62+float(values.hierarchy)*0.38,0.0,1.0),
		"monumentality":clampf(float(values.hierarchy)*0.68+float(values.centralization)*0.32,0.0,1.0),
		"civic_space":clampf(float(values.collective_obligation)*0.42+float(values.common_stewardship)*0.38+float(values.pluralism)*0.20,0.0,1.0),
		"permeability":clampf(float(values.openness)*0.62+float(values.pluralism)*0.38,0.0,1.0),
		"defensive_depth":clampf((1.0-float(values.openness))*0.46+float(values.centralization)*0.32+float(values.hierarchy)*0.22,0.0,1.0),
		"terrain_conformity":clampf(float(values.ecological_restraint)*0.78+(1.0-float(values.centralization))*0.22,0.0,1.0),
		# These five bounded practices keep different social priorities visible at
		# Google-Earth scale. They are derived from the same aggregate lived values,
		# not from founding-focus labels, so architecture changes as the society does.
		"productive_order":clampf(float(values.common_stewardship)*0.44+float(values.ecological_restraint)*0.32+float(values.collective_obligation)*0.24,0.0,1.0),
		"lineage_clustering":clampf((1.0-float(values.experimentation))*0.36+float(values.restorative_justice)*0.30+float(values.collective_obligation)*0.24+(1.0-float(values.achieved_status))*0.10,0.0,1.0),
		"inquiry_openness":clampf(float(values.experimentation)*0.40+float(values.pluralism)*0.25+float(values.openness)*0.20+float(values.achieved_status)*0.15,0.0,1.0),
		"industrial_intensity":clampf(float(values.achieved_status)*0.30+float(values.experimentation)*0.25+(1.0-float(values.ecological_restraint))*0.35+float(values.centralization)*0.10,0.0,1.0),
		"exchange_network":clampf(float(values.openness)*0.42+float(values.pluralism)*0.22+float(values.achieved_status)*0.18+(1.0-float(values.centralization))*0.18,0.0,1.0)
	}
