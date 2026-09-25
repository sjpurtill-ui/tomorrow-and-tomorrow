extends RefCounted
const Goods=preload("res://scripts/civilian_goods.gd")

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
	"Envoy":["culture","institutions","logistics","knowledge"],
	"ChiefScout":["security","knowledge","logistics"]
}

# A practice cannot be imagined into existence merely because enough days pass.
# These gates require the society to have encountered or physically accessed the
# materials that make the observation possible. Later abstract discoveries rest
# on earlier material practices through their prerequisite chains.
const RESOURCE_GATES:Dictionary={
	"seed_selection":[{"resource":"Fertile Soil","stage":"recognized"}],
	"cordage":[{"resource":"Fiber Plants","stage":"recognized"}],"basketry":[{"resource":"Fiber Plants","stage":"accessible"}],
	"charcoal":[{"resource":"Timber","stage":"accessible"}],"clay_shaping":[{"resource":"Clay","stage":"recognized","sample_sufficient":true}],
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
	"fuel_demand":Vector2(-0.35,0.70),"disaster_risk":Vector2(-0.20,0.65),"chemical_control":Vector2(-0.20,0.80),"sanitation":Vector2(-0.45,0.65),
	# research_3000 modern transition (EarlyLifeConditions, CivilizationIndicators):
	# share of the baseline life table's hazard that modern medicine and public
	# health remove, the share of births a society chooses not to have, and the
	# share of adults who read.
	"modern_survival":Vector2(-0.10,0.85),"fertility_transition":Vector2(-0.10,0.75),"literacy":Vector2(-0.10,0.99),
	# Extra output per farm worker from machines, fertilizer and bred seed
	# (FoodSystem cultivated staples): 3.0 is four times the pre-industrial output.
	"farm_mechanization":Vector2(-0.10,3.0)
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
	var day:=int(WorldSimulation.state.elapsed_days)
	if day==last_processed_day: return
	last_processed_day=day
	if definitions_by_id.size()!=catalog.size():
		definitions_by_id.clear()
		for definition in catalog: definitions_by_id[String(definition.get("id",""))]=definition
	var population:=maxf(1.0,WorldSimulation.state.population_exact)
	var observers:=float(WorldSimulation.state.effective_workers("Knowledge"))
	var stewards:=float(WorldSimulation.state.population_allocations.get("Administration",0))
	var makers:=float(WorldSimulation.state.population_allocations.get("Crafting",0))
	var preserved:=clampf(float(WorldSimulation.state.simulation_metrics.get("knowledge",0.18))+effect("knowledge_preservation"),0.05,1.2)
	if day-last_adoption_day>=30:
		var adoption_days:=clampi(day-last_adoption_day,1,30)
		last_adoption_day=day
		var teaching:=observers/population*0.055+stewards/population*0.018+makers/population*0.012
		var adoption_factor:=1.0+clampf(effect("adoption_rate")+WorldSimulation.state.founding_effect("adoption_rate")+WorldSimulation.progression.effect("adoption_rate"),-0.35,0.80)
		for id in WorldSimulation.state.known_discoveries:
			var discovery:Dictionary=definitions_by_id.get(id,{})
			if discovery.is_empty(): continue
			var adoption_level:=float(WorldSimulation.state.discovery_adoption.get(id,0.025))
			var direction:=String(discovery.get("dynamic",discovery.get("direction","knowledge")))
			var attention:=float(WorldSimulation.state.research_allocations.get(direction,0))
			var relevant_activity:=0.0
			for signal_name in discovery.get("signals",[]): relevant_activity+=float(context.get(signal_name,0.0))
			var practice:=minf(0.012,relevant_activity*0.0014)
			var directed:=minf(0.006,attention*0.0012)
			# research_600 balance: ADOPTION_PACE spreads a practice over years to
			# decades instead of weeks (see ERA CEILINGS below).
			var spread:=(0.00035+teaching+practice+directed)*adoption_factor*ADOPTION_PACE
			spread*=1.0-adoption_level
			var retention_loss:=maxf(0.0,0.00018-preserved*0.00015)*ADOPTION_PACE if relevant_activity<=0.05 else 0.0
			adoption_level=clampf(adoption_level+(spread-retention_loss)*adoption_days,0.015,1.0)
			WorldSimulation.state.discovery_adoption[id]=adoption_level
		_rebuild_effect_totals(catalog)
	WorldSimulation.state.societal_values=SOCIETAL_VALUES_MODEL.advance(
		WorldSimulation.state.societal_values,WorldSimulation.state.known_discoveries,WorldSimulation.state.discovery_adoption,
		_societal_value_context(context),day
	)
	capacities=evaluate_capacities(context)
	capacities["institutions"]=clampf(float(capacities.institutions)+SOCIETAL_VALUES_MODEL.simulation_effect(WorldSimulation.state.societal_values,"institutions"),0.01,1.0)
	capacities["culture"]=clampf(float(capacities.culture)+SOCIETAL_VALUES_MODEL.simulation_effect(WorldSimulation.state.societal_values,"cohesion"),0.01,1.0)
	capacities["knowledge"]=clampf(float(capacities.knowledge)+SOCIETAL_VALUES_MODEL.simulation_effect(WorldSimulation.state.societal_values,"knowledge"),0.01,1.0)
	capacities["ecology"]=clampf(float(capacities.ecology)+SOCIETAL_VALUES_MODEL.simulation_effect(WorldSimulation.state.societal_values,"ecology"),0.01,1.0)
	capacities["security"]=clampf(float(capacities.security)+SOCIETAL_VALUES_MODEL.simulation_effect(WorldSimulation.state.societal_values,"security"),0.01,1.0)
	WorldSimulation.state.society_capacities=capacities.duplicate(true)
	WorldSimulation.state.society_subcategories=evaluate_subcategories(context)
	WorldSimulation.state.knowledge_effects=effect_totals.duplicate(true)
	WorldSimulation.state.combined_intelligence=float(capacities.get("knowledge",0.0))

func register_discovery(discovery:Dictionary,catalog:Array[Dictionary])->void:
	var id:=String(discovery.get("id",""))
	WorldSimulation.state.discovery_adoption[id]=maxf(0.025,float(WorldSimulation.state.discovery_adoption.get(id,0.0)))
	_rebuild_effect_totals(catalog)
	WorldSimulation.state.societal_values=SOCIETAL_VALUES_MODEL.advance(
		WorldSimulation.state.societal_values,WorldSimulation.state.known_discoveries,WorldSimulation.state.discovery_adoption,
		_societal_value_context({}),int(WorldSimulation.state.elapsed_days)
	)


func _societal_value_context(context:Dictionary)->Dictionary:
	var metrics:Dictionary=WorldSimulation.state.simulation_metrics
	var trade_volume:=float(WorldSimulation.state.external_trade_exports)+float(WorldSimulation.state.external_trade_imports)
	var population:=maxf(1.0,WorldSimulation.state.population_exact)
	var inequality:=0.0
	if WorldSimulation.state.wealth_shares.size()>=2:
		inequality=clampf(float(WorldSimulation.state.wealth_shares[-1])-float(WorldSimulation.state.wealth_shares[0]),0.0,1.0)
	var war_pressure:=0.0
	var civilization_system:Node=null
	var main_loop:=Engine.get_main_loop()
	if main_loop is SceneTree: civilization_system=(main_loop as SceneTree).root.get_node_or_null("CivilizationSystem")
	if civilization_system!=null and civilization_system.has_method("military_fronts_snapshot"):
		war_pressure=clampf(float(civilization_system.military_fronts_snapshot().get("active",0))*0.24,0.0,1.0)
	return {
		"food":clampf(WorldSimulation.state.food_security,0.0,1.0),"health":clampf(WorldSimulation.state.population_health,0.0,1.0),
		"security":clampf(float(metrics.get("security",0.38)),0.0,1.0),"ecology":clampf(float(metrics.get("ecology",0.88)),0.0,1.0),
		"knowledge":clampf(float(metrics.get("knowledge",0.18)),0.0,1.0),"trade":clampf(trade_volume/population/0.20,0.0,1.0),
		"war_pressure":war_pressure,"inequality":inequality,"adaptability":clampf(float(context.get("adaptability",0.52)),0.0,1.0)
	}

## Per-discovery effect names, values and whether its adoption is scaled by a
## technique factor; rebuilt with the definitions.
var _effect_rows:Dictionary={}

func _rebuild_effect_totals(_catalog:Array[Dictionary])->void:
	if definitions_by_id.size()!=_catalog.size():
		definitions_by_id.clear()
		for definition:Dictionary in _catalog:definitions_by_id[String(definition.get("id",""))]=definition
		_effect_rows.clear()
	effect_totals.clear()
	_refresh_line_focus() # research_600: specialization amplifies the focused line
	var adoption:Dictionary=WorldSimulation.state.discovery_adoption
	for id in WorldSimulation.state.known_discoveries:
		var row:Array=_effect_rows.get(id,[])
		if row.is_empty():
			var discovery:Dictionary=definitions_by_id.get(id,{})
			if discovery.is_empty(): continue
			var effects:Dictionary=discovery.get("effects",{})
			var values:=PackedFloat64Array()
			for effect_name in effects:values.append(float(effects[effect_name]))
			row=[effects.keys(),values,Goods.FACTOR_SPECIAL.has(id) or Goods.TECHNIQUES.has(id)]
			_effect_rows[id]=row
		var adoption_level:=clampf(float(adoption.get(id,0.025)),0.0,1.0)
		# factor() is exactly 1.0 for ids that are neither special nor techniques.
		if row[2]:adoption_level*=Goods.factor(String(id))
		var names:Array=row[0]
		var values:PackedFloat64Array=row[1]
		var focus:=float(line_focus.get(String((definitions_by_id.get(id,{}) as Dictionary).get("dynamic","")),0.0)) if not line_focus.is_empty() else 0.0
		# research_600: a focused line's practices are worked harder, every other
		# line's a little less (benefits only; costs are never scaled).
		var practice_scale:=1.0+SPECIALIZATION_HEADROOM*focus if focus>0.0 else 1.0-SPECIALIZATION_NEGLECT*_max_focus
		for i in names.size():
			var effect_name=names[i]
			var value:=values[i]
			if practice_scale!=1.0 and (value<0.0)==(String(effect_name) in LOWER_IS_BETTER): value*=practice_scale
			effect_totals[effect_name]=float(effect_totals.get(effect_name,0.0))+value*adoption_level
	# research_600 balance: totals are held under the society's era ceiling,
	# never the flat modern limit alone.
	ceiling_era=society_era()
	for effect_name in effect_totals:
		var limit:=era_ceiling(String(effect_name))
		effect_totals[effect_name]=clampf(float(effect_totals[effect_name]),limit.x,limit.y)
	_apply_specialist_upkeep()

func effect(effect_id:String)->float:
	return float(effect_totals.get(effect_id,0.0))

func evaluate_capacities(_context:Dictionary)->Dictionary:
	var metrics:=WorldSimulation.state.simulation_metrics
	var population:=maxf(1.0,WorldSimulation.state.population_exact)
	var able_ratio:=clampf(float(WorldSimulation.state.able_population())/population,0.0,1.0)
	var health:=clampf(float(metrics.get("health",WorldSimulation.state.population_health)),0.0,1.0)
	var food:=clampf(WorldSimulation.state.food_security,0.0,1.0)
	var housing:=clampf(float(WorldSimulation.state.housing_capacity)/population,0.0,1.0)
	var cohesion:=clampf(float(metrics.get("cohesion",0.58)),0.0,1.0)
	var ecology:=clampf(float(metrics.get("ecology",0.88)),0.0,1.0)
	var security:=clampf(float(metrics.get("security",0.38)),0.0,1.0)
	var legitimacy:=clampf(float(metrics.get("legitimacy",0.62)),0.0,1.0)
	var observers:=float(WorldSimulation.state.effective_workers("Knowledge"))
	var inquiry_total:=0.0
	var active_directions:=0
	for allocation in WorldSimulation.state.research_allocations.values():
		inquiry_total+=float(allocation)
		if int(allocation)>0: active_directions+=1
	var attention_fit:=clampf(observers/maxf(1.0,inquiry_total),0.10,1.0)
	var diversity:=clampf(float(active_directions)/12.0,0.05,1.0)
	var preserved:=clampf(float(metrics.get("knowledge",0.18))+effect("knowledge_preservation")*0.55,0.0,1.0)
	var communication:=clampf(0.28+effect("route_speed")*0.30+effect("standardization")*0.42+effect("state_capacity")*0.22,0.10,1.0)
	var institutional_support:=clampf(0.20+float(WorldSimulation.state.population_allocations.get("Administration",0))/maxf(1.0,population*0.06)*0.38+legitimacy*0.22,0.05,1.0)
	var overload:=clampf(maxf(0.0,inquiry_total-observers)/maxf(1.0,observers)*0.22+effect("institutional_rigidity")*0.25,0.0,0.55)
	var combined:=clampf((0.18+observers/maxf(1.0,population*0.08)*0.22+health*0.14+preserved*0.17+communication*0.10+institutional_support*0.10+diversity*0.09)*attention_fit*(1.0-overload),0.03,1.0)
	var labor:=clampf(able_ratio*(0.32+health*0.27+food*0.18+cohesion*0.13+housing*0.10)*(1.0+effect("labor_efficiency")-effect("labor_demand")*0.28-effect("fatigue")*0.20),0.08,1.15)
	var result:Dictionary={
		"demography":clampf(health*0.34+food*0.30+housing*0.18+cohesion*0.10+effect("maternal_safety")*0.08,0.02,1.0),
		"nutrition":clampf(food*0.72+float(metrics.get("food_diet_quality",0.45))*0.20+effect("nutrition_quality")*0.08,0.02,1.0),
		"health":clampf(health+effect("health_protection")*0.22-effect("disease_exposure")*0.18-effect("health_risk")*0.15,0.02,1.0),
		"labor":labor,"knowledge":combined,
		"production":clampf(float(metrics.get("material_capacity",0.12))*0.45+labor*0.30+effect("tool_quality")*0.14+effect("task_coordination")*0.11,0.02,1.0),
		"infrastructure":clampf(housing*0.38+float(WorldSimulation.state.settlement_completed.size())/10.0*0.32+effect("construction_rate")*0.18+effect("disaster_resilience")*0.12,0.01,1.0),
		"logistics":clampf(float(metrics.get("logistics",0.16))*0.55+effect("haul_capacity")*0.22+effect("route_speed")*0.16+effect("storage_loss")*-0.07,0.01,1.0),
		"ecology":clampf(ecology+effect("ecology_recovery")*0.20-effect("ecological_pressure")*0.18-effect("pollution")*0.12,0.01,1.0),
		"institutions":clampf(institutional_support+effect("state_capacity")*0.22+effect("legitimacy")*0.12,0.02,1.0),
		"security":clampf(security+effect("security_efficiency")*0.18+effect("warfare_readiness")*0.12,0.02,1.0),
		"culture":clampf(cohesion*0.52+legitimacy*0.25+diversity*0.12+effect("cohesion")*0.11+preload("res://scripts/artifact_collection.gd").bonus("culture")*.12,0.02,1.0)
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
	for office in WorldSimulation.state.leadership_positions:
		var advisor:Dictionary=WorldSimulation.state.leadership_positions[office]
		var contribution:=_doctrine_dynamic_effect(String(office),advisor,dynamic_id)
		if contribution==0.0: continue
		total+=contribution
		contributors+=1
	if contributors==0: return 0.0
	return clampf(total/sqrt(float(contributors)), -0.12,0.14)

func leadership_subcategory_effect(dynamic_id:String,subcategory:String)->float:
	return _leadership_subcategory_effect(dynamic_id,subcategory,{})

func _leadership_subcategory_effect(dynamic_id:String,subcategory:String,doctrine_effects:Dictionary)->float:
	var total:=0.0
	var contributors:=0
	for office in WorldSimulation.state.leadership_positions:
		var advisor:Dictionary=WorldSimulation.state.leadership_positions[office]
		if String(advisor.get("doctrine",""))!="":
			# Doctrine institutions execute a whole portfolio; subcategories inherit
			# the same structural strength slightly damped rather than a second
			# random per-subcategory competence.
			var contribution:float=doctrine_effects[office] if doctrine_effects.has(office) else _doctrine_dynamic_effect(String(office),advisor,dynamic_id)*0.85
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
			effect_total+=(WorldSimulation.government.dynamic_competency(advisor,dynamic_id)-0.50)*0.13
	effect_total+=_doctrine_side_effect(doctrine,dynamic_id)
	return effect_total


func leadership_effect_for_holder(office:String,advisor:Dictionary,dynamic_id:String)->float:
	return clampf(_doctrine_dynamic_effect(office,advisor,dynamic_id),-0.12,0.14)

func doctrine_execution_strength(doctrine:String)->float:
	var legitimacy:=clampf(float(WorldSimulation.state.simulation_metrics.get("legitimacy",0.62)),0.0,1.0)
	match doctrine:
		"directive":
			# A central service is the strongest executor the state can field, but it
			# runs on obedience: it weakens as legitimacy slips and works against the
			# realm once the realm no longer believes in its orders.
			return lerpf(-0.06,0.13,clampf((legitimacy-0.25)/0.55,0.0,1.0))
		"federated":
			# Federated bodies execute through local assemblies: modest alone,
			# stronger with every settlement actually federated.
			return 0.045+0.011*float(mini(WorldSimulation.state.player_settlements.size(),6))
		"measured":
			# A records-and-measurement service is unconditionally steady: never the
			# strongest hand, never a liability.
			return 0.075
		"representative":
			# Rotation keeps authority accountable, but capability arrives in waves
			# as experienced cohorts hand duties to new ones.
			return 0.065+0.045*sin(TAU*float(WorldSimulation.state.elapsed_days)/540.0)
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
	var origin:=Vector2(WorldSimulation.state.settlement_founded_at.x,WorldSimulation.state.settlement_founded_at.z)
	var spread:=0.0
	for settlement_variant in WorldSimulation.state.player_settlements:
		var settlement:Dictionary=settlement_variant
		var value:Variant=settlement.get("position",Vector2.ZERO)
		var position:Vector2=value if value is Vector2 else Vector2.ZERO
		spread=maxf(spread,position.distance_to(origin))
	return clampf(spread/6.0+float(maxi(0,WorldSimulation.state.player_settlements.size()-1))*0.18,0.0,1.0)

func evaluate_subcategories(_context:Dictionary)->Dictionary:
	var metrics:=WorldSimulation.state.simulation_metrics
	var population:=maxf(1.0,WorldSimulation.state.population_exact)
	var able_ratio:=clampf(float(WorldSimulation.state.able_population())/population,0.0,1.0)
	var health:=clampf(float(metrics.get("health",WorldSimulation.state.population_health)),0.0,1.0)
	var food:=clampf(WorldSimulation.state.food_security,0.0,1.0)
	var housing:=clampf(float(WorldSimulation.state.housing_capacity)/population,0.0,1.0)
	var cohesion:=clampf(float(metrics.get("cohesion",0.58)),0.0,1.0)
	var ecology:=clampf(float(metrics.get("ecology",0.88)),0.0,1.0)
	var security:=clampf(float(metrics.get("security",0.38)),0.0,1.0)
	var legitimacy:=clampf(float(metrics.get("legitimacy",0.62)),0.0,1.0)
	var observers:=float(WorldSimulation.state.effective_workers("Knowledge"))
	var inquiry_total:=0.0
	var active_directions:=0
	for allocation in WorldSimulation.state.research_allocations.values():
		inquiry_total+=float(allocation)
		if int(allocation)>0: active_directions+=1
	var attention:=clampf(observers/maxf(1.0,inquiry_total),0.0,1.0)
	var administration:=clampf(float(WorldSimulation.state.population_allocations.get("Administration",0))/maxf(1.0,population*0.06),0.0,1.0)
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
		"infrastructure":{"Housing":housing,"Construction":clampf(float(metrics.get("construction_capacity",0.0))/maxf(1.0,population*0.12)+effect("construction_rate")*0.30,0.0,1.0),"Public works":clampf(float(WorldSimulation.state.settlement_completed.size())/10.0,0.0,1.0),"Resilience":clampf(0.25+effect("disaster_resilience")*0.65,0.0,1.0)},
		"logistics":{"Carrying capacity":clampf(float(metrics.get("logistics",0.16))+effect("haul_capacity")*0.42,0.0,1.0),"Route quality":routes,"Storage system":clampf(0.22+effect("food_storage")*0.22-effect("storage_loss")*0.35,0.0,1.0),"Trade reach":clampf(0.12+effect("trade_capacity")*0.70,0.0,1.0)},
		"ecology":{"Land health":ecology,"Natural recovery":clampf(ecology*0.62+effect("ecology_recovery")*0.38,0.0,1.0),"Pollution control":clampf(0.92-effect("pollution")*0.70-effect("water_pollution")*0.45,0.0,1.0),"Resource pressure":clampf(0.88-effect("ecological_pressure")*0.62-effect("timber_pressure")*0.30,0.0,1.0)},
		"institutions":{"Administration":administration,"Legitimacy":legitimacy,"State capacity":clampf(0.18+effect("state_capacity")*0.70,0.0,1.0),"Institutional flexibility":clampf(0.84-effect("institutional_rigidity")*0.65,0.0,1.0)},
		"security":{"Public safety":security,"Organized defense":clampf(0.22+effect("security_efficiency")*0.48,0.0,1.0),"Military readiness":clampf(0.12+effect("warfare_readiness")*0.65,0.0,1.0),"Crisis resilience":clampf(0.24+effect("disaster_resilience")*0.48+cohesion*0.20,0.0,1.0)},
		"culture":{"Social cohesion":cohesion,"Shared legitimacy":legitimacy,"Inquiry breadth":clampf(float(active_directions)/12.0,0.0,1.0),"Collective memory":preservation}
	}
	for dynamic_id in result:
		# Reuse only within this evaluation; appointments and state stay live.
		var doctrine_effects:Dictionary={}
		for office in WorldSimulation.state.leadership_positions:
			var advisor:Dictionary=WorldSimulation.state.leadership_positions[office]
			if String(advisor.get("doctrine",""))!="":
				doctrine_effects[office]=_doctrine_dynamic_effect(String(office),advisor,String(dynamic_id))*0.85
		for subcategory in (result[dynamic_id] as Dictionary):
			var influence:=_leadership_subcategory_effect(String(dynamic_id),String(subcategory),doctrine_effects)
			result[dynamic_id][subcategory]=clampf(float(result[dynamic_id][subcategory])+influence,0.0,1.0)
	return result

func adoption(discovery_id:String)->float:
	return clampf(float(WorldSimulation.state.discovery_adoption.get(discovery_id,0.0)),0.0,1.0)

## research_600: how thoroughly a known practice is carried out, which is its
## adoption, less the specialization neglect when another line has the focus.
func practiced(discovery_id:String)->float:
	var level:=adoption(discovery_id)
	if _max_focus<=0.0: return level
	var line:=String((definitions_by_id.get(discovery_id,{}) as Dictionary).get("dynamic",""))
	if float(line_focus.get(line,0.0))>0.0: return level
	return level*(1.0-SPECIALIZATION_NEGLECT*_max_focus)

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


# --- research_600 era ceilings (begin) ----------------------------------------
# Phase 3 balance. A society's discoveries fill what its age allowed and no more:
# every effect total is clamped to an era-anchored ceiling on its beneficial side
# (the harmful side keeps the flat EFFECT_LIMITS bound, so costs always bite).
# The ceiling rises with the society's era, the more conservative of the elapsed
# calendar and the frontier of what it actually knows, and reaches the modern
# EFFECT_LIMITS only at MODERN_ERA. Player, owned AI seats and projected rivals
# (ProgressionSystem.rival_effect) use the same era_ceiling_for().
# Benchmarks: docs/research/BENCHMARKS_600.md.

## Practices spread through a society over years to decades (0.12: a practice
## people actively use reaches ~90% of households in about three years; one
## nobody works with drifts over decades), not within a season.
const ADOPTION_PACE:=0.12
## Game year of the modern limits (TechnologyEras: 3000 is 2030 CE). research_3000:
## the ceilings keep rising through the whole game instead of stopping at 1950 CE.
const MODERN_ERA:=3000.0
## Beneficial-side magnitude of each total at game year 600 (1500 BCE): what the
## best-documented Late Bronze Age societies achieved relative to having nothing.
## Keys not listed use half of their modern limit.
const ERA_CEILING_600:Dictionary={
	"conception_support":0.25,"maternal_safety":0.22,"neonatal_survival":0.22,
	"food_output":0.35,"foraging_yield":0.35,"hunting_yield":0.30,"cultivation_yield":0.50,
	"food_storage":0.55,"food_spoilage":0.40,"nutrition_quality":0.25,"soil_productivity":0.40,
	"health_protection":0.22,"water_safety":0.28,"disease_exposure":0.20,"injury_risk":0.22,"health_risk":0.08,
	"labor_efficiency":0.25,"labor_demand":0.10,"fatigue":0.15,"task_coordination":0.35,
	"knowledge_rate":0.30,"observation_rate":0.30,"knowledge_preservation":0.45,"adoption_rate":0.30,
	"survey_speed":0.40,"water_access":0.40,"tool_quality":0.40,"craft_output":0.45,"extraction_yield":0.40,"metal_yield":0.45,
	"fuel_efficiency":0.35,"repair_capacity":0.30,"standardization":0.40,"construction_rate":0.45,"housing_output":0.45,
	"disaster_resilience":0.35,"haul_capacity":0.45,"route_speed":0.35,"travel_speed":0.30,"storage_loss":0.35,
	"dry_storage":0.45,"container_capacity":0.55,"logistics_endurance":0.35,"trade_capacity":0.45,
	"state_capacity":0.45,"legitimacy":0.40,"cohesion":0.40,"warfare_readiness":0.45,"security_efficiency":0.40,
	"naval_capacity":0.35,"ecology_recovery":0.35,"ecological_pressure":0.25,"timber_pressure":0.25,
	"pollution":0.08,"water_pollution":0.08,"fuel_demand":0.15,"disaster_risk":0.12,"sanitation":0.22,
	"modern_survival":0.0,"fertility_transition":0.0,"literacy":0.01,"farm_mechanization":0.0
}
## Keys whose beneficial direction is negative (a lower total is better).
const LOWER_IS_BETTER:Array[String]=["disease_exposure","injury_risk","health_risk","labor_demand","fatigue","food_spoilage","storage_loss",
	"institutional_rigidity","ecological_pressure","timber_pressure","pollution","water_pollution","fuel_demand","disaster_risk"]
## Share of the year-600 ceiling open at each era (game year, share).
const ERA_RISE:Array=[[0.0,0.45],[50.0,0.50],[100.0,0.56],[200.0,0.66],[300.0,0.75],[450.0,0.88],[600.0,1.0]]
## Technical and organizational capacities (metals, wheels, writing, states)
## grew most within the window, so less of their year-600 level was open at 5000 BCE.
const TECH_KEYS:Array[String]=["tool_quality","craft_output","extraction_yield","metal_yield","fuel_efficiency","repair_capacity","standardization",
	"construction_rate","housing_output","haul_capacity","route_speed","travel_speed","trade_capacity","naval_capacity","logistics_endurance",
	"container_capacity","dry_storage","state_capacity","knowledge_rate","knowledge_preservation","adoption_rate","observation_rate","survey_speed",
	"warfare_readiness","security_efficiency","task_coordination","cultivation_yield","soil_productivity","water_access","mining_output","mine_safety","disaster_resilience"]
const TECH_RISE:Array=[[0.0,0.25],[50.0,0.30],[100.0,0.36],[200.0,0.47],[300.0,0.58],[450.0,0.78],[600.0,1.0]]
## Forager knowledge, kinship and shelter-on-the-move were mature long before 5000 BCE.
const EARLY_MATURE:Array[String]=["foraging_yield","hunting_yield","mobile_shelter","conception_support"]
const EARLY_MATURE_RISE:Array=[[0.0,0.85],[600.0,1.0]]
## --- research_3000 era ceilings (0-3000) ---
## Beyond 600 the ceiling closes on the modern limit, as a share of the gap
## between the year-600 anchor and EFFECT_LIMITS, along one curve per kind of
## capacity. Anchors: 1200 is about 400 CE, 1800 about 1360 CE, 2400 about
## 1800 CE, 2800 1950 CE, 3000 2030 CE (TechnologyEras). Pre-industrial ages
## close little of the gap; industry and modern science close most of it.
## Every block's full-knowledge total follows these curves
## (tools/research/rebalance_effects_3000.py), so each era's research still
## moves outcomes inside its own band instead of saturating a flat clamp.
const LATER_RISE:Array=[[600.0,0.0],[1200.0,0.10],[1800.0,0.20],[2400.0,0.33],[2500.0,0.40],[2600.0,0.48],[2700.0,0.58],[2800.0,0.70],[2900.0,0.85],[3000.0,1.0]]
## Technical and organizational keys (TECH_KEYS) take off with industry.
const TECH_LATER_RISE:Array=[[600.0,0.0],[1200.0,0.12],[1800.0,0.24],[2400.0,0.40],[2500.0,0.48],[2600.0,0.57],[2700.0,0.67],[2800.0,0.78],[2900.0,0.90],[3000.0,1.0]]
## Keys that follow their own historical curve after 600 (share of the gap):
## mass literacy (a few percent until printing and schooling, near universal by
## 1950 CE), and the modern mortality and fertility transitions, which barely
## exist before 1800 CE and follow the benchmark rows century by century.
const OWN_LATER_RISE:Dictionary={
	"literacy":[[600.0,0.0],[1200.0,0.09],[1500.0,0.10],[1800.0,0.19],[2100.0,0.30],[2400.0,0.55],[2500.0,0.68],[2600.0,0.85],[2700.0,0.95],[2800.0,0.98],[3000.0,1.0]],
	"modern_survival":[[600.0,0.0],[2400.0,0.02],[2500.0,0.06],[2600.0,0.14],[2700.0,0.30],[2800.0,0.55],[2900.0,0.80],[3000.0,1.0]],
	"farm_mechanization":[[600.0,0.0],[2200.0,0.01],[2400.0,0.04],[2500.0,0.09],[2600.0,0.16],[2700.0,0.30],[2800.0,0.55],[2900.0,0.82],[3000.0,1.0]],
	"fertility_transition":[[600.0,0.0],[2400.0,0.0],[2500.0,0.12],[2600.0,0.38],[2700.0,0.58],[2800.0,0.74],[2900.0,0.88],[3000.0,1.0]],
}
## Share of the known discoveries' eras that defines the knowledge frontier.
const FRONTIER_PERCENTILE:=0.95

## Society era used for the most recent effect totals.
var ceiling_era:=0.0

static func _rise(curve:Array,era:float)->float:
	if era<=float(curve[0][0]): return float(curve[0][1])
	for index in range(1,curve.size()):
		if era<=float(curve[index][0]):
			var low:Array=curve[index-1]
			var high:Array=curve[index]
			return lerpf(float(low[1]),float(high[1]),(era-float(low[0]))/maxf(0.001,float(high[0])-float(low[0])))
	return float(curve[curve.size()-1][1])

## Allowed [lower, upper] range of an effect total at game-year `era`.
static func era_ceiling_for(effect_id:String,era:float)->Vector2:
	var limit:Vector2=EFFECT_LIMITS.get(effect_id,Vector2(-0.50,0.80))
	var lower:=effect_id in LOWER_IS_BETTER
	var modern:=absf(limit.x) if lower else limit.y
	var anchor:=minf(modern,float(ERA_CEILING_600.get(effect_id,modern*0.5)))
	var curve:Array=ERA_RISE
	if effect_id in EARLY_MATURE: curve=EARLY_MATURE_RISE
	elif effect_id in TECH_KEYS: curve=TECH_RISE
	var bound:=anchor*_rise(curve,era)
	if era>600.0:
		var later:Array=OWN_LATER_RISE.get(effect_id,TECH_LATER_RISE if effect_id in TECH_KEYS else LATER_RISE)
		bound=anchor+(modern-anchor)*_rise(later,era)
	return Vector2(-bound,limit.y) if lower else Vector2(limit.x,bound)

## Allowed range of `effect_id` for this society as of its latest effect totals,
## including the headroom its research focus earns on that key's line.
func era_ceiling(effect_id:String)->Vector2:
	var limit:=era_ceiling_for(effect_id,ceiling_era)
	var focus:=float(line_focus.get(String(EFFECT_LINE.get(effect_id,"")),0.0))
	# A focused line's channels may pass the common ceiling; a neglected line's
	# channels stop short of it while another line takes the society's effort.
	var scale:=1.0+SPECIALIZATION_HEADROOM*focus if focus>0.0 else 1.0-SPECIALIZATION_NEGLECT*_max_focus
	if scale==1.0: return limit
	var modern:Vector2=EFFECT_LIMITS.get(effect_id,Vector2(-0.50,0.80))
	if effect_id in LOWER_IS_BETTER: return Vector2(maxf(modern.x,limit.x*scale),limit.y)
	return Vector2(limit.x,minf(modern.y,limit.y*scale))

## Specialization: a society that pours its research into one line works that
## line's practices harder (their benefits count up to SPECIALIZATION_HEADROOM
## more) and pushes that line's channels past the era's common ceiling by as
## much (all emphasis on it; nothing for an even spread), while every other
## line is researched less. Each effect key belongs to the line that carries most
## of its content (derived from the research data).
const SPECIALIZATION_HEADROOM:=0.35
## Share of their benefit the neglected lines lose when another line has full focus.
const SPECIALIZATION_NEGLECT:=0.35
const EFFECT_LINE:Dictionary={"adoption_rate":"knowledge","chemical_control":"production","clay_yield":"production","cohesion":"culture","conception_support":"demography","construction_rate":"infrastructure","container_capacity":"production","craft_output":"production","cultivation_yield":"nutrition","disaster_resilience":"infrastructure","disaster_risk":"infrastructure","disease_exposure":"health","dry_storage":"infrastructure","ecological_pressure":"ecology","ecology_recovery":"ecology","extraction_yield":"production","fatigue":"labor","fiber_yield":"production","food_output":"nutrition","food_spoilage":"nutrition","food_storage":"nutrition","foraging_yield":"ecology","fuel_demand":"ecology","fuel_efficiency":"production","haul_capacity":"logistics","health_protection":"health","health_risk":"labor","housing_output":"infrastructure","hunting_yield":"nutrition","injury_risk":"health","institutional_rigidity":"culture","knowledge_preservation":"knowledge","knowledge_rate":"knowledge","labor_demand":"labor","labor_efficiency":"labor","legitimacy":"institutions","logistics_endurance":"logistics","maternal_safety":"demography","metal_yield":"production","mine_safety":"infrastructure","mobile_shelter":"production","naval_capacity":"logistics","neonatal_survival":"demography","nutrition_quality":"nutrition","observation_rate":"knowledge","pollution":"ecology","repair_capacity":"infrastructure","route_speed":"logistics","sanitation":"health","security_efficiency":"security","soil_productivity":"ecology","standardization":"production","state_capacity":"institutions","stone_yield":"infrastructure","storage_loss":"nutrition","survey_speed":"knowledge","task_coordination":"labor","timber_pressure":"ecology","timber_yield":"ecology","tool_quality":"production","trade_capacity":"logistics","travel_speed":"logistics","warfare_readiness":"security","water_access":"infrastructure","water_pollution":"ecology","water_safety":"health","modern_survival":"health","fertility_transition":"demography","literacy":"knowledge","farm_mechanization":"nutrition"}
## Emphasis focus per line, 0 (even spread or less) to 1 (all emphasis).
var line_focus:Dictionary={}

var _max_focus:=0.0

func _refresh_line_focus()->void:
	line_focus.clear()
	_max_focus=0.0
	var total:=0.0
	for weight:Variant in WorldSimulation.state.research_allocations.values(): total+=maxf(0.0,float(weight))
	if total<=0.0: return
	var even:=1.0/float(DYNAMICS.size())
	for line:Variant in WorldSimulation.state.research_allocations:
		var share:=maxf(0.0,float(WorldSimulation.state.research_allocations[line]))/total
		if share>even: line_focus[String(line)]=clampf((share-even)/(1.0-even),0.0,1.0)
	for value:Variant in line_focus.values(): _max_focus=maxf(_max_focus,float(value))

## The society's age for effect ceilings: the elapsed calendar or its knowledge
## frontier (FRONTIER_PERCENTILE of its known discoveries' eras), whichever is
## earlier. Registry items carry their design year; other entries' era gates
## are 0.9 x their dated era (Research600.ERA_BAND_FRACTION).
func society_era()->float:
	var elapsed:=float(WorldSimulation.state.elapsed_days)/365.0
	var eras:=PackedFloat64Array()
	for id:Variant in WorldSimulation.state.known_discoveries:
		var definition:Dictionary=definitions_by_id.get(id,{})
		if definition.is_empty(): continue
		if definition.has("design_year"): eras.append(float(definition.design_year))
		else: eras.append(float(definition.get("earliest_year",0.0))/0.9)
	if eras.is_empty(): return 0.0
	eras.sort()
	return clampf(minf(elapsed,eras[int(float(eras.size()-1)*FRONTIER_PERCENTILE)]),0.0,MODERN_ERA)

## Research is never free. Full-time specialists (the Knowledge role) beyond what
## the era's surplus could keep (about 4% of workers at year 0, 10% by year 600:
## shamans and elders, then temple scribes) are fed, housed and served by the
## other workers, and a large separate class strains the community. The excess
## share adds labor demand and fatigue, draws on the stores, costs cohesion and
## lowers births (temple and scribal households married late or not at all),
## whatever the research buys (docs/research/BENCHMARKS_600.md, "Allowed lead").
const SUSTAINABLE_SPECIALISTS:Array=[[0.0,0.04],[300.0,0.07],[600.0,0.10],[2400.0,0.16],[2800.0,0.25],[3000.0,0.30]]
const SPECIALIST_UPKEEP:={"labor_demand":1.4,"fatigue":0.6,"cohesion":-1.0,"conception_support":-1.0,"food_storage":-0.6}
## Latest excess specialist share (0 when research staffing is sustainable).
var specialist_excess:=0.0

func _apply_specialist_upkeep()->void:
	var able:=maxf(1.0,float(WorldSimulation.state.able_population()))
	var share:=clampf(float(WorldSimulation.state.effective_workers("Knowledge"))/able,0.0,1.0)
	specialist_excess=maxf(0.0,share-_rise(SUSTAINABLE_SPECIALISTS,ceiling_era))
	if specialist_excess<=0.0: return
	for key:String in SPECIALIST_UPKEEP:
		var limit:Vector2=EFFECT_LIMITS.get(key,Vector2(-0.5,0.8))
		effect_totals[key]=clampf(float(effect_totals.get(key,0.0))+float(SPECIALIST_UPKEEP[key])*specialist_excess,limit.x,limit.y)
# --- research_600 era ceilings (end) ------------------------------------------
