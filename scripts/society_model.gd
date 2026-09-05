extends RefCounted

const SOCIETAL_VALUES_MODEL:=preload("res://scripts/societal_values_model.gd")

# Canonical causal contract for the civilization simulation. Discoveries may
# only change these named coefficients; every coefficient is bounded and must
# be consumed by at least one physical or social flow elsewhere in the game.

const DYNAMICS:= ["demography","nutrition","health","labor","knowledge","production","infrastructure","logistics","ecology","institutions","security","culture"]
const OFFICE_DYNAMICS:Dictionary={
	"Steward":["demography","health","labor","institutions"],
	"Quartermaster":["nutrition","production","logistics","ecology"],
	"Scholar":["knowledge","culture","institutions","ecology"],
	"Marshal":["security","logistics","labor","institutions"],
	"Envoy":["culture","institutions","logistics","knowledge"]
}

# A practice cannot be imagined into existence merely because enough days pass.
# These gates require the society to have encountered or physically accessed the
# materials that make the observation possible. Later abstract discoveries rest
# on earlier material practices through their prerequisite chains.
const RESOURCE_GATES:Dictionary={
	"seed_selection":[{"resource":"Fertile Soil","stage":"recognized"}],
	"cordage":[{"resource":"Fiber Plants","stage":"recognized"}],"basketry":[{"resource":"Fiber Plants","stage":"accessible"}],
	"charcoal":[{"resource":"Timber","stage":"accessible"}],"clay_shaping":[{"resource":"Clay","stage":"recognized"}],
	"pit_firing":[{"resource":"Clay","stage":"accessible"},{"resource":"Timber","stage":"accessible"}],
	"joinery":[{"resource":"Timber","stage":"accessible"}],"well_siting":[{"resource":"Freshwater","stage":"recognized"}],
	"wound_cleaning":[{"resource":"Freshwater","stage":"accessible"}],"clean_water":[{"resource":"Freshwater","stage":"accessible"}],
	"herbal_classification":[{"resource":"Medicinal Plants","stage":"recognized"}],
	"crop_calendars":[{"resource":"Fertile Soil","stage":"recognized"}],"managed_fallow":[{"resource":"Fertile Soil","stage":"accessible"}],
	"seed_reserves":[{"resource":"Fertile Soil","stage":"accessible"}],"irrigation_schedules":[{"resource":"Freshwater","stage":"accessible"},{"resource":"Fertile Soil","stage":"accessible"}],
	"crop_rotation":[{"resource":"Fertile Soil","stage":"developed"}],"grain_milling":[{"resource":"Stone","stage":"accessible"}],
	"fermentation_control":[{"resource":"Clay","stage":"developed"}],"regional_granaries":[{"resource":"Timber","stage":"developed"}],
	"soil_assays":[{"resource":"Fertile Soil","stage":"developed"}],"intensive_gardens":[{"resource":"Fertile Soil","stage":"developed"},{"resource":"Freshwater","stage":"developed"}],
	"birth_attendants":[{"resource":"Freshwater","stage":"accessible"}],"latrine_siting":[{"resource":"Freshwater","stage":"recognized"}],
	"public_baths":[{"resource":"Freshwater","stage":"developed"},{"resource":"Limestone","stage":"accessible"}],
	"civic_infirmaries":[{"resource":"Medicinal Plants","stage":"developed"}],"contagion_mapping":[{"resource":"Freshwater","stage":"developed"}],
	"pictographic_records":[{"resource":"Clay","stage":"accessible"}],"phonetic_notation":[{"resource":"Clay","stage":"developed"}],
	"geometric_survey":[{"resource":"Stone","stage":"accessible"}],"regional_maps":[{"resource":"Fiber Plants","stage":"developed"}],
	"paper_making":[{"resource":"Fiber Plants","stage":"developed"},{"resource":"Freshwater","stage":"developed"}],
	"printing_process":[{"resource":"Timber","stage":"developed"},{"resource":"Iron Ore","stage":"accessible"}],
	"graded_roads":[{"resource":"Stone","stage":"accessible"}],"timber_bridges":[{"resource":"Timber","stage":"developed"}],
	"canal_locks":[{"resource":"Freshwater","stage":"developed"},{"resource":"Limestone","stage":"developed"}],
	"water_mills":[{"resource":"Freshwater","stage":"developed"},{"resource":"Timber","stage":"developed"}],
	"urban_street_plans":[{"resource":"Stone","stage":"developed"}],"covered_sewers":[{"resource":"Limestone","stage":"developed"}],
	"precision_machinery":[{"resource":"Iron Ore","stage":"developed"},{"resource":"Coal","stage":"developed"}],
	"field_fortifications":[{"resource":"Timber","stage":"accessible"}],"fortified_stores":[{"resource":"Timber","stage":"developed"}],
	"siege_engineering":[{"resource":"Timber","stage":"developed"}],"powder_artillery":[{"resource":"Iron Ore","stage":"developed"},{"resource":"Sulfur","stage":"developed"},{"resource":"Nitrates","stage":"developed"}]
}

const EFFECT_LIMITS:Dictionary={
	"conception_support":Vector2(-0.35,0.35),"maternal_safety":Vector2(-0.10,0.65),"neonatal_survival":Vector2(-0.10,0.65),
	"food_output":Vector2(-0.35,0.80),"foraging_yield":Vector2(-0.35,0.65),"hunting_yield":Vector2(-0.35,0.65),"cultivation_yield":Vector2(-0.35,0.90),
	"food_storage":Vector2(-0.40,1.20),"food_spoilage":Vector2(-0.75,0.40),"nutrition_quality":Vector2(-0.30,0.45),"soil_productivity":Vector2(-0.40,0.80),
	"health_protection":Vector2(-0.30,0.55),"water_safety":Vector2(-0.30,0.60),"disease_exposure":Vector2(-0.55,0.55),"injury_risk":Vector2(-0.45,0.55),"health_risk":Vector2(-0.20,0.40),
	"labor_efficiency":Vector2(-0.35,0.55),"labor_demand":Vector2(-0.25,0.35),"fatigue":Vector2(-0.35,0.45),"task_coordination":Vector2(-0.30,0.65),
	"knowledge_rate":Vector2(-0.40,0.90),"observation_rate":Vector2(-0.35,0.75),"knowledge_preservation":Vector2(-0.35,0.85),"adoption_rate":Vector2(-0.40,0.80),
	"survey_speed":Vector2(-0.40,0.85),"water_access":Vector2(-0.35,0.80),
	"tool_quality":Vector2(-0.35,0.90),"craft_output":Vector2(-0.40,1.00),"extraction_yield":Vector2(-0.40,1.10),"metal_yield":Vector2(-0.40,1.20),
	"timber_yield":Vector2(-0.40,0.90),"stone_yield":Vector2(-0.40,0.90),"clay_yield":Vector2(-0.40,0.90),"fiber_yield":Vector2(-0.40,0.90),
	"fuel_efficiency":Vector2(-0.40,0.85),"repair_capacity":Vector2(-0.30,0.75),"standardization":Vector2(-0.25,0.80),
	"construction_rate":Vector2(-0.40,1.00),"housing_output":Vector2(-0.35,0.90),"disaster_resilience":Vector2(-0.40,0.80),"mine_safety":Vector2(-0.40,0.80),"mining_output":Vector2(-0.35,0.80),
	"mobile_shelter":Vector2(-0.35,0.70),
	"haul_capacity":Vector2(-0.40,1.00),"route_speed":Vector2(-0.40,0.85),"travel_speed":Vector2(-0.40,0.65),"storage_loss":Vector2(-0.70,0.40),
	"dry_storage":Vector2(-0.35,1.00),"container_capacity":Vector2(-0.35,1.20),"logistics_endurance":Vector2(-0.35,0.70),"trade_capacity":Vector2(-0.40,1.00),
	"state_capacity":Vector2(-0.45,0.90),"legitimacy":Vector2(-0.45,0.55),"cohesion":Vector2(-0.45,0.55),"institutional_rigidity":Vector2(-0.20,0.55),
	"warfare_readiness":Vector2(-0.40,1.00),"security_efficiency":Vector2(-0.40,0.80),"naval_capacity":Vector2(-0.30,0.90),
	"ecology_recovery":Vector2(-0.50,0.65),"ecological_pressure":Vector2(-0.45,0.80),"timber_pressure":Vector2(-0.45,0.80),"pollution":Vector2(-0.15,0.80),"water_pollution":Vector2(-0.15,0.70),
	"fuel_demand":Vector2(-0.35,0.70),"disaster_risk":Vector2(-0.20,0.65),"chemical_control":Vector2(-0.20,0.80),"sanitation":Vector2(-0.45,0.65)
}

const BASE_EFFECTS:Dictionary={
	"seasonal_patterns":{"foraging_yield":0.08,"observation_rate":0.04,"ecological_pressure":-0.02},
	"seed_selection":{"cultivation_yield":0.16,"nutrition_quality":0.02,"soil_productivity":0.03,"labor_demand":0.02},
	"food_drying":{"food_storage":0.10,"food_spoilage":-0.10,"labor_demand":0.01},
	"smoking":{"food_storage":0.12,"food_spoilage":-0.12,"logistics_endurance":0.03,"fuel_demand":0.04,"pollution":0.008},
	"cordage":{"haul_capacity":0.08,"construction_rate":0.04,"mobile_shelter":0.08,"tool_quality":0.02,"labor_demand":0.01},
	"basketry":{"haul_capacity":0.07,"dry_storage":0.10,"food_storage":0.05,"craft_output":0.02},
	"charcoal":{"fuel_efficiency":0.14,"metal_yield":0.03,"timber_pressure":0.07,"pollution":0.018,"labor_demand":0.015},
	"clay_shaping":{"container_capacity":0.10,"food_storage":0.07,"water_safety":0.03,"craft_output":0.02},
	"pit_firing":{"container_capacity":0.12,"food_spoilage":-0.05,"craft_output":0.05,"fuel_demand":0.04,"pollution":0.012},
	"joinery":{"construction_rate":0.09,"housing_output":0.07,"repair_capacity":0.04,"tool_quality":0.03},
	"drainage":{"health_protection":0.04,"disease_exposure":-0.05,"disaster_resilience":0.04,"labor_demand":0.01},
	"well_siting":{"water_safety":0.09,"health_protection":0.05,"construction_rate":0.02,"labor_demand":0.01},
	"wound_cleaning":{"injury_risk":-0.09,"health_protection":0.05,"maternal_safety":0.02,"labor_demand":0.008},
	"herbal_classification":{"health_protection":0.05,"disease_exposure":-0.04,"observation_rate":0.03,"health_risk":0.006},
	"clean_water":{"water_safety":0.16,"disease_exposure":-0.13,"maternal_safety":0.04,"neonatal_survival":0.03,"labor_demand":0.01},
	"tallies":{"knowledge_preservation":0.12,"state_capacity":0.05,"task_coordination":0.05,"labor_demand":0.012},
	"standard_measures":{"standardization":0.13,"craft_output":0.05,"trade_capacity":0.06,"construction_rate":0.04,"state_capacity":0.03},
	"route_memory":{"route_speed":0.09,"travel_speed":0.05,"knowledge_preservation":0.04,"survey_speed":0.04},
	"labor_rotations":{"labor_efficiency":0.08,"fatigue":-0.06,"injury_risk":-0.03,"cohesion":0.03,"state_capacity":0.02},
	"customary_law":{"legitimacy":0.07,"cohesion":0.05,"state_capacity":0.06,"institutional_rigidity":0.03},
	"public_stores":{"food_storage":0.13,"container_capacity":0.06,"state_capacity":0.07,"cohesion":0.03,"labor_demand":0.02},
	"watch_rotation":{"security_efficiency":0.11,"warfare_readiness":0.04,"fatigue":-0.02,"labor_demand":0.02},
	"formation_drill":{"warfare_readiness":0.14,"security_efficiency":0.07,"task_coordination":0.03,"injury_risk":0.01,"labor_demand":0.02},
	"supply_groups":{"logistics_endurance":0.10,"haul_capacity":0.07,"warfare_readiness":0.06,"food_storage":0.03,"labor_demand":0.015}
}

var effect_totals:Dictionary={}
var capacities:Dictionary={}
var last_processed_day:=-1
var last_adoption_day:=-30
var definitions_by_id:Dictionary={}

func normalize_discovery(discovery:Dictionary)->Dictionary:
	var normalized:=discovery.duplicate(true)
	if (normalized.get("resource_requirements",[]) as Array).is_empty() and RESOURCE_GATES.has(String(normalized.get("id",""))):
		normalized["resource_requirements"]=RESOURCE_GATES[String(normalized.id)].duplicate(true)
	var effects:Dictionary=normalized.get("effects",{}).duplicate(true)
	if BASE_EFFECTS.has(String(normalized.get("id",""))):
		for key in BASE_EFFECTS[String(normalized.id)]:
			if not effects.has(key): effects[key]=BASE_EFFECTS[String(normalized.id)][key]
	for key in effects.keys():
		var limit:Vector2=EFFECT_LIMITS.get(String(key),Vector2(-0.50,0.80))
		effects[key]=clampf(float(effects[key]),limit.x,limit.y)
	normalized["effects"]=effects
	return normalized

func process_day(catalog:Array[Dictionary],context:Dictionary)->void:
	var day:=int(GameState.elapsed_days)
	if day==last_processed_day: return
	last_processed_day=day
	if definitions_by_id.size()!=catalog.size():
		definitions_by_id.clear()
		for definition in catalog: definitions_by_id[String(definition.get("id",""))]=definition
	var population:=maxf(1.0,GameState.population_exact)
	var observers:=float(GameState.population_allocations.get("Knowledge",0))
	var stewards:=float(GameState.population_allocations.get("Administration",0))
	var makers:=float(GameState.population_allocations.get("Crafting",0))
	var preserved:=clampf(float(GameState.simulation_metrics.get("knowledge",0.18))+effect("knowledge_preservation"),0.05,1.2)
	if day-last_adoption_day>=30:
		var adoption_days:=clampi(day-last_adoption_day,1,30)
		last_adoption_day=day
		for id in GameState.known_discoveries:
			var discovery:Dictionary=definitions_by_id.get(id,{})
			if discovery.is_empty(): continue
			var adoption_level:=float(GameState.discovery_adoption.get(id,0.025))
			var direction:=String(discovery.get("dynamic",discovery.get("direction","knowledge")))
			var attention:=float(GameState.research_allocations.get(direction,0))
			var relevant_activity:=0.0
			for signal_name in discovery.get("signals",[]): relevant_activity+=float(context.get(signal_name,0.0))
			var teaching:=observers/population*0.055+stewards/population*0.018+makers/population*0.012
			var practice:=minf(0.012,relevant_activity*0.0014)
			var directed:=minf(0.006,attention*0.0012)
			var spread:=(0.00035+teaching+practice+directed)*(1.0+clampf(effect("adoption_rate")+GameState.founding_effect("adoption_rate")+ProgressionSystem.effect("adoption_rate"),-0.35,0.80))
			spread*=1.0-adoption_level
			var retention_loss:=maxf(0.0,0.00018-preserved*0.00015) if relevant_activity<=0.05 else 0.0
			adoption_level=clampf(adoption_level+(spread-retention_loss)*adoption_days,0.015,1.0)
			GameState.discovery_adoption[id]=adoption_level
		_rebuild_effect_totals(catalog)
	GameState.societal_values=SOCIETAL_VALUES_MODEL.advance(
		GameState.societal_values,GameState.known_discoveries,GameState.discovery_adoption,
		_societal_value_context(context),day
	)
	capacities=evaluate_capacities(context)
	capacities["institutions"]=clampf(float(capacities.institutions)+SOCIETAL_VALUES_MODEL.simulation_effect(GameState.societal_values,"institutions"),0.01,1.0)
	capacities["culture"]=clampf(float(capacities.culture)+SOCIETAL_VALUES_MODEL.simulation_effect(GameState.societal_values,"cohesion"),0.01,1.0)
	capacities["knowledge"]=clampf(float(capacities.knowledge)+SOCIETAL_VALUES_MODEL.simulation_effect(GameState.societal_values,"knowledge"),0.01,1.0)
	capacities["ecology"]=clampf(float(capacities.ecology)+SOCIETAL_VALUES_MODEL.simulation_effect(GameState.societal_values,"ecology"),0.01,1.0)
	capacities["security"]=clampf(float(capacities.security)+SOCIETAL_VALUES_MODEL.simulation_effect(GameState.societal_values,"security"),0.01,1.0)
	GameState.society_capacities=capacities.duplicate(true)
	GameState.society_subcategories=evaluate_subcategories(context)
	GameState.knowledge_effects=effect_totals.duplicate(true)
	GameState.combined_intelligence=float(capacities.get("knowledge",0.0))

func register_discovery(discovery:Dictionary,catalog:Array[Dictionary])->void:
	var id:=String(discovery.get("id",""))
	GameState.discovery_adoption[id]=maxf(0.025,float(GameState.discovery_adoption.get(id,0.0)))
	_rebuild_effect_totals(catalog)
	GameState.societal_values=SOCIETAL_VALUES_MODEL.advance(
		GameState.societal_values,GameState.known_discoveries,GameState.discovery_adoption,
		_societal_value_context({}),int(GameState.elapsed_days)
	)


func _societal_value_context(context:Dictionary)->Dictionary:
	var metrics:Dictionary=GameState.simulation_metrics
	var trade_volume:=float(GameState.external_trade_exports)+float(GameState.external_trade_imports)
	var population:=maxf(1.0,GameState.population_exact)
	var inequality:=0.0
	if GameState.wealth_shares.size()>=2:
		inequality=clampf(float(GameState.wealth_shares[-1])-float(GameState.wealth_shares[0]),0.0,1.0)
	var war_pressure:=0.0
	var civilization_system:Node=null
	var main_loop:=Engine.get_main_loop()
	if main_loop is SceneTree: civilization_system=(main_loop as SceneTree).root.get_node_or_null("CivilizationSystem")
	if civilization_system!=null and civilization_system.has_method("military_fronts_snapshot"):
		war_pressure=clampf(float(civilization_system.military_fronts_snapshot().get("active",0))*0.24,0.0,1.0)
	return {
		"food":clampf(GameState.food_security,0.0,1.0),"health":clampf(GameState.population_health,0.0,1.0),
		"security":clampf(float(metrics.get("security",0.38)),0.0,1.0),"ecology":clampf(float(metrics.get("ecology",0.88)),0.0,1.0),
		"knowledge":clampf(float(metrics.get("knowledge",0.18)),0.0,1.0),"trade":clampf(trade_volume/population/0.20,0.0,1.0),
		"war_pressure":war_pressure,"inequality":inequality,"adaptability":clampf(float(context.get("adaptability",0.52)),0.0,1.0)
	}

func _rebuild_effect_totals(_catalog:Array[Dictionary])->void:
	effect_totals.clear()
	for id in GameState.known_discoveries:
		var discovery:Dictionary=definitions_by_id.get(id,{})
		if discovery.is_empty(): continue
		var adoption_level:=clampf(float(GameState.discovery_adoption.get(id,0.025)),0.0,1.0)
		for effect_name in (discovery.get("effects",{}) as Dictionary):
			effect_totals[effect_name]=float(effect_totals.get(effect_name,0.0))+float(discovery.effects[effect_name])*adoption_level
	for effect_name in effect_totals:
		var limit:Vector2=EFFECT_LIMITS.get(String(effect_name),Vector2(-0.50,0.80))
		effect_totals[effect_name]=clampf(float(effect_totals[effect_name]),limit.x,limit.y)

func effect(effect_id:String)->float:
	return float(effect_totals.get(effect_id,0.0))

func evaluate_capacities(_context:Dictionary)->Dictionary:
	var metrics:=GameState.simulation_metrics
	var population:=maxf(1.0,GameState.population_exact)
	var able_ratio:=clampf(float(GameState.able_population())/population,0.0,1.0)
	var health:=clampf(float(metrics.get("health",GameState.population_health)),0.0,1.0)
	var food:=clampf(GameState.food_security,0.0,1.0)
	var housing:=clampf(float(GameState.housing_capacity)/population,0.0,1.0)
	var cohesion:=clampf(float(metrics.get("cohesion",0.58)),0.0,1.0)
	var ecology:=clampf(float(metrics.get("ecology",0.88)),0.0,1.0)
	var security:=clampf(float(metrics.get("security",0.38)),0.0,1.0)
	var legitimacy:=clampf(float(metrics.get("legitimacy",0.62)),0.0,1.0)
	var observers:=float(GameState.population_allocations.get("Knowledge",0))
	var inquiry_total:=0.0
	var active_directions:=0
	for allocation in GameState.research_allocations.values():
		inquiry_total+=float(allocation)
		if int(allocation)>0: active_directions+=1
	var attention_fit:=clampf(observers/maxf(1.0,inquiry_total),0.10,1.0)
	var diversity:=clampf(float(active_directions)/12.0,0.05,1.0)
	var preserved:=clampf(float(metrics.get("knowledge",0.18))+effect("knowledge_preservation")*0.55,0.0,1.0)
	var communication:=clampf(0.28+effect("route_speed")*0.30+effect("standardization")*0.42+effect("state_capacity")*0.22,0.10,1.0)
	var institutional_support:=clampf(0.20+float(GameState.population_allocations.get("Administration",0))/maxf(1.0,population*0.06)*0.38+legitimacy*0.22,0.05,1.0)
	var overload:=clampf(maxf(0.0,inquiry_total-observers)/maxf(1.0,observers)*0.22+effect("institutional_rigidity")*0.25,0.0,0.55)
	var combined:=clampf((0.18+observers/maxf(1.0,population*0.08)*0.22+health*0.14+preserved*0.17+communication*0.10+institutional_support*0.10+diversity*0.09)*attention_fit*(1.0-overload),0.03,1.0)
	var labor:=clampf(able_ratio*(0.32+health*0.27+food*0.18+cohesion*0.13+housing*0.10)*(1.0+effect("labor_efficiency")-effect("labor_demand")*0.28-effect("fatigue")*0.20),0.08,1.15)
	var result:Dictionary={
		"demography":clampf(health*0.34+food*0.30+housing*0.18+cohesion*0.10+effect("maternal_safety")*0.08,0.02,1.0),
		"nutrition":clampf(food*0.72+float(metrics.get("food_diet_quality",0.45))*0.20+effect("nutrition_quality")*0.08,0.02,1.0),
		"health":clampf(health+effect("health_protection")*0.22-effect("disease_exposure")*0.18-effect("health_risk")*0.15,0.02,1.0),
		"labor":labor,"knowledge":combined,
		"production":clampf(float(metrics.get("material_capacity",0.12))*0.45+labor*0.30+effect("tool_quality")*0.14+effect("task_coordination")*0.11,0.02,1.0),
		"infrastructure":clampf(housing*0.38+float(GameState.settlement_completed.size())/10.0*0.32+effect("construction_rate")*0.18+effect("disaster_resilience")*0.12,0.01,1.0),
		"logistics":clampf(float(metrics.get("logistics",0.16))*0.55+effect("haul_capacity")*0.22+effect("route_speed")*0.16+effect("storage_loss")*-0.07,0.01,1.0),
		"ecology":clampf(ecology+effect("ecology_recovery")*0.20-effect("ecological_pressure")*0.18-effect("pollution")*0.12,0.01,1.0),
		"institutions":clampf(institutional_support+effect("state_capacity")*0.22+effect("legitimacy")*0.12,0.02,1.0),
		"security":clampf(security+effect("security_efficiency")*0.18+effect("warfare_readiness")*0.12,0.02,1.0),
		"culture":clampf(cohesion*0.52+legitimacy*0.25+diversity*0.12+effect("cohesion")*0.11,0.02,1.0)
	}
	# An office holder changes execution, judgment and coordination in the same
	# canonical systems shown to the player. A merely impressive dossier can
	# never create a thirteenth hidden stat.
	for dynamic_id in result:
		result[dynamic_id]=clampf(float(result[dynamic_id])+leadership_effect(String(dynamic_id)),0.01,1.0)
	return result

func leadership_effect(dynamic_id:String)->float:
	var total:=0.0
	var contributors:=0
	for office in GameState.leadership_positions:
		var advisor:Dictionary=GameState.leadership_positions[office]
		var contribution:=_doctrine_dynamic_effect(String(office),advisor,dynamic_id)
		if contribution==0.0: continue
		total+=contribution
		contributors+=1
	if contributors==0: return 0.0
	return clampf(total/sqrt(float(contributors)), -0.12,0.14)

func leadership_subcategory_effect(dynamic_id:String,subcategory:String)->float:
	var total:=0.0
	var contributors:=0
	for office in GameState.leadership_positions:
		var advisor:Dictionary=GameState.leadership_positions[office]
		if String(advisor.get("doctrine",""))!="":
			# Doctrine institutions execute a whole portfolio; subcategories inherit
			# the same structural strength slightly damped rather than a second
			# random per-subcategory competence.
			var contribution:=_doctrine_dynamic_effect(String(office),advisor,dynamic_id)*0.85
			if contribution==0.0: continue
			total+=contribution
			contributors+=1
			continue
		if dynamic_id not in OFFICE_DYNAMICS.get(String(office),[]): continue
		var by_dynamic:Dictionary=advisor.get("subcategory_profile",{})
		var profile:Dictionary=by_dynamic.get(dynamic_id,{})
		if not profile.has(subcategory): continue
		total+=(float(profile[subcategory])-0.5)*0.15
		contributors+=1
	if contributors==0: return leadership_effect(dynamic_id)*0.72
	return clampf(total/sqrt(float(contributors)),-0.10,0.12)


# -- institutional doctrines -------------------------------------------------
# The chosen governing structure, not a hidden aptitude scalar, decides how an
# office executes. Each doctrine reads current, player-visible state, so no
# structure is best in every situation and none adds a thirteenth stat.

func _doctrine_dynamic_effect(office:String,advisor:Dictionary,dynamic_id:String)->float:
	var doctrine:=String(advisor.get("doctrine",""))
	if doctrine=="":
		# Institutions commissioned before doctrines keep their recorded profile.
		if dynamic_id not in OFFICE_DYNAMICS.get(office,[]): return 0.0
		var profile:Dictionary=advisor.get("dynamic_profile",{})
		if not profile.has(dynamic_id): return 0.0
		return (float(profile[dynamic_id])-0.5)*0.18
	var effect_total:=0.0
	if dynamic_id in OFFICE_DYNAMICS.get(office,[]):
		# Structure determines how authority travels; the appointed person's visible
		# aptitude determines how well they use it. Neither can substitute entirely
		# for the other, and a weak appointment can squander a strong structure.
		effect_total+=doctrine_execution_strength(doctrine)*0.55
		var skills:Dictionary=advisor.get("skills",{})
		var has_named_person_skills:=int(advisor.get("person_id",0))>0
		if not has_named_person_skills:
			for skill in GovernmentPeopleSystem.SKILL_KEYS:
				if skills.has(skill): has_named_person_skills=true; break
		if has_named_person_skills:
			effect_total+=(GovernmentPeopleSystem.dynamic_competency(advisor,dynamic_id)-0.50)*0.13
	effect_total+=_doctrine_side_effect(doctrine,dynamic_id)
	return effect_total


func leadership_effect_for_holder(office:String,advisor:Dictionary,dynamic_id:String)->float:
	return clampf(_doctrine_dynamic_effect(office,advisor,dynamic_id),-0.12,0.14)

func doctrine_execution_strength(doctrine:String)->float:
	var legitimacy:=clampf(float(GameState.simulation_metrics.get("legitimacy",0.62)),0.0,1.0)
	match doctrine:
		"directive":
			# A central service is the strongest executor the state can field, but it
			# runs on obedience: it weakens as legitimacy slips and works against the
			# realm once the realm no longer believes in its orders.
			return lerpf(-0.06,0.13,clampf((legitimacy-0.25)/0.55,0.0,1.0))
		"federated":
			# Federated bodies execute through local assemblies: modest alone,
			# stronger with every settlement actually federated.
			return 0.045+0.011*float(mini(GameState.player_settlements.size(),6))
		"measured":
			# A records-and-measurement service is unconditionally steady: never the
			# strongest hand, never a liability.
			return 0.075
		"representative":
			# Rotation keeps authority accountable, but capability arrives in waves
			# as experienced cohorts hand duties to new ones.
			return 0.065+0.045*sin(TAU*float(GameState.elapsed_days)/540.0)
		"territorial":
			# A territorial network holds its strength across distance; it is thin
			# until the realm has actual territory to administer.
			return 0.05+0.07*_territorial_spread_ratio()
	return 0.0

func _doctrine_side_effect(doctrine:String,dynamic_id:String)->float:
	match doctrine:
		"directive":
			# Central command crowds out the council culture it does not consult.
			if dynamic_id=="culture": return -0.02
		"federated":
			if dynamic_id=="institutions": return 0.015
		"measured":
			if dynamic_id=="knowledge": return 0.012
		"representative":
			if dynamic_id=="culture": return 0.02
		"territorial":
			if dynamic_id=="logistics": return 0.012
	return 0.0

func _territorial_spread_ratio()->float:
	var origin:=Vector2(GameState.settlement_founded_at.x,GameState.settlement_founded_at.z)
	var spread:=0.0
	for settlement_variant in GameState.player_settlements:
		var settlement:Dictionary=settlement_variant
		var value:Variant=settlement.get("position",Vector2.ZERO)
		var position:Vector2=value if value is Vector2 else Vector2.ZERO
		spread=maxf(spread,position.distance_to(origin))
	return clampf(spread/6.0+float(maxi(0,GameState.player_settlements.size()-1))*0.18,0.0,1.0)

func evaluate_subcategories(_context:Dictionary)->Dictionary:
	var metrics:=GameState.simulation_metrics
	var population:=maxf(1.0,GameState.population_exact)
	var able_ratio:=clampf(float(GameState.able_population())/population,0.0,1.0)
	var health:=clampf(float(metrics.get("health",GameState.population_health)),0.0,1.0)
	var food:=clampf(GameState.food_security,0.0,1.0)
	var housing:=clampf(float(GameState.housing_capacity)/population,0.0,1.0)
	var cohesion:=clampf(float(metrics.get("cohesion",0.58)),0.0,1.0)
	var ecology:=clampf(float(metrics.get("ecology",0.88)),0.0,1.0)
	var security:=clampf(float(metrics.get("security",0.38)),0.0,1.0)
	var legitimacy:=clampf(float(metrics.get("legitimacy",0.62)),0.0,1.0)
	var observers:=float(GameState.population_allocations.get("Knowledge",0))
	var inquiry_total:=0.0
	var active_directions:=0
	for allocation in GameState.research_allocations.values():
		inquiry_total+=float(allocation)
		if int(allocation)>0: active_directions+=1
	var attention:=clampf(observers/maxf(1.0,inquiry_total),0.0,1.0)
	var administration:=clampf(float(GameState.population_allocations.get("Administration",0))/maxf(1.0,population*0.06),0.0,1.0)
	var diet:=clampf(float(metrics.get("food_diet_quality",0.45))+effect("nutrition_quality")*0.25,0.0,1.0)
	var stores:=clampf(float(metrics.get("food_days",0.0))/90.0+effect("food_storage")*0.12,0.0,1.0)
	var water:=clampf(0.42+effect("water_safety")*0.65+effect("sanitation")*0.45-effect("disease_exposure")*0.35,0.0,1.0)
	var preservation:=clampf(float(metrics.get("knowledge",0.18))+effect("knowledge_preservation")*0.55,0.0,1.0)
	var communication:=clampf(0.28+effect("route_speed")*0.30+effect("standardization")*0.42+effect("state_capacity")*0.22,0.0,1.0)
	var materials:=clampf(float(metrics.get("material_capacity",0.12))+effect("extraction_yield")*0.20+effect("metal_yield")*0.12,0.0,1.0)
	var routes:=clampf(float(metrics.get("logistics",0.16))+effect("route_speed")*0.35,0.0,1.0)
	var result:Dictionary={
		"demography":{"Fertility conditions":clampf(food*0.45+housing*0.30+health*0.25+effect("conception_support")*0.20,0.0,1.0),"Maternal safety":clampf(health*0.62+effect("maternal_safety")*0.38,0.0,1.0),"Child survival":clampf(health*0.58+food*0.22+effect("neonatal_survival")*0.20,0.0,1.0),"Shelter capacity":housing},
		"nutrition":{"Daily supply":food,"Diet quality":diet,"Stored reserve":stores,"Land productivity":clampf(ecology*0.55+effect("soil_productivity")*0.45,0.0,1.0)},
		"health":{"General health":health,"Water & sanitation":water,"Disease control":clampf(0.45+effect("health_protection")*0.45-effect("disease_exposure")*0.40,0.0,1.0),"Injury safety":clampf(0.68-effect("injury_risk")*0.55,0.0,1.0)},
		"labor":{"Able workforce":able_ratio,"Work efficiency":clampf(float(metrics.get("labor_efficiency",0.72)),0.0,1.0),"Coordination":clampf(cohesion*0.55+effect("task_coordination")*0.45,0.0,1.0),"Workload balance":clampf(0.78-effect("labor_demand")*0.55-effect("fatigue")*0.35,0.0,1.0)},
		"knowledge":{"Observers":clampf(observers/maxf(1.0,population*0.08),0.0,1.0),"Directed attention":attention,"Preserved knowledge":preservation,"Communication":communication},
		"production":{"Material supply":materials,"Tool quality":clampf(0.28+effect("tool_quality")*0.65,0.0,1.0),"Craft capacity":clampf(float(metrics.get("material_capacity",0.12))*0.55+effect("craft_output")*0.45,0.0,1.0),"Standardization":clampf(0.18+effect("standardization")*0.82,0.0,1.0)},
		"infrastructure":{"Housing":housing,"Construction":clampf(float(metrics.get("construction_capacity",0.0))/maxf(1.0,population*0.12)+effect("construction_rate")*0.30,0.0,1.0),"Public works":clampf(float(GameState.settlement_completed.size())/10.0,0.0,1.0),"Resilience":clampf(0.25+effect("disaster_resilience")*0.65,0.0,1.0)},
		"logistics":{"Carrying capacity":clampf(float(metrics.get("logistics",0.16))+effect("haul_capacity")*0.42,0.0,1.0),"Route quality":routes,"Storage system":clampf(0.22+effect("food_storage")*0.22-effect("storage_loss")*0.35,0.0,1.0),"Trade reach":clampf(0.12+effect("trade_capacity")*0.70,0.0,1.0)},
		"ecology":{"Land health":ecology,"Natural recovery":clampf(ecology*0.62+effect("ecology_recovery")*0.38,0.0,1.0),"Pollution control":clampf(0.92-effect("pollution")*0.70-effect("water_pollution")*0.45,0.0,1.0),"Resource pressure":clampf(0.88-effect("ecological_pressure")*0.62-effect("timber_pressure")*0.30,0.0,1.0)},
		"institutions":{"Administration":administration,"Legitimacy":legitimacy,"State capacity":clampf(0.18+effect("state_capacity")*0.70,0.0,1.0),"Institutional flexibility":clampf(0.84-effect("institutional_rigidity")*0.65,0.0,1.0)},
		"security":{"Public safety":security,"Organized defense":clampf(0.22+effect("security_efficiency")*0.48,0.0,1.0),"Military readiness":clampf(0.12+effect("warfare_readiness")*0.65,0.0,1.0),"Crisis resilience":clampf(0.24+effect("disaster_resilience")*0.48+cohesion*0.20,0.0,1.0)},
		"culture":{"Social cohesion":cohesion,"Shared legitimacy":legitimacy,"Inquiry breadth":clampf(float(active_directions)/12.0,0.0,1.0),"Collective memory":preservation}
	}
	for dynamic_id in result:
		for subcategory in (result[dynamic_id] as Dictionary):
			var influence:=leadership_subcategory_effect(String(dynamic_id),String(subcategory))
			result[dynamic_id][subcategory]=clampf(float(result[dynamic_id][subcategory])+influence,0.0,1.0)
	return result

func adoption(discovery_id:String)->float:
	return clampf(float(GameState.discovery_adoption.get(discovery_id,0.0)),0.0,1.0)

func validate_catalog(catalog:Array[Dictionary])->Array[String]:
	var errors:Array[String]=[]
	var ids:Dictionary={}
	var definitions:Dictionary={}
	for discovery in catalog:
		var discovery_id:=String(discovery.get("id",""))
		if discovery_id=="": errors.append("Discovery has an empty ID")
		elif ids.has(discovery_id): errors.append("Duplicate discovery ID %s" % discovery_id)
		ids[discovery_id]=true
		definitions[discovery_id]=discovery
	for discovery in catalog:
		var id:=String(discovery.get("id",""))
		var effects:Dictionary=discovery.get("effects",{})
		if effects.is_empty(): errors.append("%s has no simulation effects" % id)
		for effect_name in effects:
			if not EFFECT_LIMITS.has(String(effect_name)): errors.append("%s uses unregistered effect %s" % [id,effect_name])
		for requirement in discovery.get("requires",[]):
			if not ids.has(String(requirement)): errors.append("%s requires missing %s" % [id,requirement])
	var visit_state:Dictionary={}
	for discovery_id in definitions:
		_visit_catalog_dependency(String(discovery_id),definitions,visit_state,[],errors)
	return errors


func _visit_catalog_dependency(discovery_id:String,definitions:Dictionary,visit_state:Dictionary,path:Array,errors:Array[String])->void:
	var state:=int(visit_state.get(discovery_id,0))
	if state==2: return
	if state==1:
		var cycle_start:=path.find(discovery_id)
		var cycle:Array=path.slice(cycle_start if cycle_start>=0 else 0)
		cycle.append(discovery_id)
		var message:="Discovery dependency cycle: %s" % " -> ".join(cycle)
		if message not in errors: errors.append(message)
		return
	if not definitions.has(discovery_id): return
	visit_state[discovery_id]=1
	var next_path:=path.duplicate(); next_path.append(discovery_id)
	for requirement in (definitions[discovery_id] as Dictionary).get("requires",[]):
		if definitions.has(String(requirement)): _visit_catalog_dependency(String(requirement),definitions,visit_state,next_path,errors)
	visit_state[discovery_id]=2
