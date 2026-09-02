extends Node

const SOCIETAL_VALUES_MODEL:=preload("res://scripts/societal_values_model.gd")

const POPULATION_ROLES := ["Food","Survey","Extraction","Construction","Crafting","Logistics","Knowledge","Administration","Defense"]
const PRODUCTIVE_POPULATION_ROLES := ["Food","Survey","Extraction","Construction","Crafting","Logistics"]
const SUPPORT_POPULATION_ROLES := ["Knowledge","Administration"]
const POPULATION_FUNCTIONS := ["productive","support","mobilized","dependent","absent"]
const POPULATION_AGE_COHORTS := ["children","youth","early_adults","established_adults","mature_adults","elders"]
const POPULATION_COHORT_DURATIONS_DAYS := {
	"children":5110.0,"youth":4015.0,"early_adults":3650.0,
	"established_adults":3650.0,"mature_adults":5475.0,"elders":6205.0
}
const FOUNDING_FOCUS_ORDER := ["provision","generations","inquiry","industry","defense","exchange"]
const FOUNDING_FOCUSES := {
	"provision":{
		"name":"PROVISION FIRST","short":"PROVISION","creed":"Survival begins with a dependable store.",
		"strengths":"FOOD • HEALTH • RESERVES","tradeoff":"Slower inquiry and material development.","color":"#9eb879",
		"description":"The founding population is organized around harvest discipline, ration security, and practical care. It is harder to starve or sicken, but fewer people begin in inquiry and specialized production.",
		"allocations":{"Food":48.0,"Survey":6.0,"Extraction":9.0,"Construction":10.0,"Crafting":6.0,"Logistics":7.0,"Knowledge":4.0,"Administration":5.0,"Defense":5.0},
		"starting":{"food_days_ratio":0.18,"food_capacity_ratio":0.08,"health":0.04,"knowledge":-0.02,"material_capacity":-0.02},
		"effects":{"food_yield":0.10,"health_target":0.035,"knowledge_gain":-0.08,"material_target":-0.025}
	},
	"generations":{
		"name":"MANY GENERATIONS","short":"GENERATIONS","creed":"Build for descendants, not only survivors.",
		"strengths":"POPULATION • HOUSING • COHESION","tradeoff":"More dependents and slower early specialization.","color":"#d2a977",
		"description":"Shelter, family support, and social continuity take priority. Population can grow more reliably and remain cohesive, while the larger care burden slows early specialized work.",
		"allocations":{"Food":43.0,"Survey":5.0,"Extraction":9.0,"Construction":15.0,"Crafting":5.0,"Logistics":6.0,"Knowledge":5.0,"Administration":6.0,"Defense":6.0},
		"starting":{"housing_ratio":0.14,"health":0.015,"cohesion":0.04,"material_capacity":-0.015},
		"effects":{"conception_support":0.12,"construction_output":0.10,"cohesion_target":0.035,"labor_multiplier":-0.025}
	},
	"inquiry":{
		"name":"OPEN INQUIRY","short":"INQUIRY","creed":"Understanding is the first durable advantage.",
		"strengths":"KNOWLEDGE • SURVEY • ADOPTION","tradeoff":"Leaner stores and less military preparation.","color":"#78b7c5",
		"description":"Observers, records, and exploration receive unusual support. Discovery and adoption accelerate, but the founders carry fewer reserves and devote less effort to immediate defense.",
		"allocations":{"Food":39.0,"Survey":10.0,"Extraction":8.0,"Construction":8.0,"Crafting":5.0,"Logistics":6.0,"Knowledge":12.0,"Administration":7.0,"Defense":5.0},
		"starting":{"food_days_ratio":-0.04,"knowledge":0.09,"security":-0.04},
		"effects":{"knowledge_gain":0.18,"survey_output":0.15,"adoption_rate":0.08,"food_yield":-0.045,"training_rate":-0.06}
	},
	"industry":{
		"name":"MATERIAL POWER","short":"INDUSTRY","creed":"Capacity is built, hauled, repaired, and multiplied.",
		"strengths":"MATERIALS • BUILDING • OUTPUT","tradeoff":"Higher ecological and health pressure.","color":"#c58d6e",
		"description":"Extraction, craft, and construction define the founding economy. Material capacity grows quickly, while intensive work imposes lasting pressure on health and land.",
		"allocations":{"Food":38.0,"Survey":6.0,"Extraction":15.0,"Construction":12.0,"Crafting":11.0,"Logistics":8.0,"Knowledge":4.0,"Administration":3.0,"Defense":3.0},
		"starting":{"food_days_ratio":-0.04,"starting_materials":0.25,"health":-0.02,"material_capacity":0.09,"logistics":0.04,"ecology":-0.06},
		"effects":{"resource_output":0.10,"material_target":0.07,"construction_output":0.12,"health_target":-0.012,"ecology_delta":-0.00006}
	},
	"defense":{
		"name":"COMMON DEFENSE","short":"DEFENSE","creed":"Readiness prevents weakness from choosing the hour.",
		"strengths":"SECURITY • TRAINING • COMMAND","tradeoff":"Military preparation consumes food and inquiry.","color":"#bd7770",
		"description":"Watch rotations, drill, supply discipline, and command practice are established immediately. Forces prepare faster, but their permanent claim on labor and provisions slows civilian learning.",
		"allocations":{"Food":39.0,"Survey":7.0,"Extraction":9.0,"Construction":9.0,"Crafting":7.0,"Logistics":8.0,"Knowledge":5.0,"Administration":5.0,"Defense":11.0},
		"starting":{"food_days_ratio":-0.08,"knowledge":-0.025,"security":0.11},
		"effects":{"security_target":0.085,"training_rate":0.15,"training_capacity":0.10,"command_development":0.12,"food_yield":-0.04,"knowledge_gain":-0.055}
	},
	"exchange":{
		"name":"OPEN ROADS","short":"EXCHANGE","creed":"Movement and agreement turn distance into strength.",
		"strengths":"LOGISTICS • TRADE • DIPLOMACY","tradeoff":"Less immediate defense and food production.","color":"#b8a76e",
		"description":"Carrying networks, negotiation, and exchange institutions are favored from the outset. The civilization moves goods and builds relationships well, but begins with a thinner defensive and subsistence margin.",
		"allocations":{"Food":38.0,"Survey":9.0,"Extraction":8.0,"Construction":8.0,"Crafting":7.0,"Logistics":14.0,"Knowledge":5.0,"Administration":7.0,"Defense":4.0},
		"starting":{"starting_materials":0.08,"food_capacity_ratio":-0.03,"logistics":0.09,"cohesion":0.02,"institutions":0.06,"security":-0.03},
		"effects":{"logistics_target":0.08,"trade_access":0.12,"diplomacy":0.12,"knowledge_gain":0.04,"security_target":-0.025}
	}
}

var world_seed := 0
var founding_banner_index := -1
var founding_focus := ""
var founding_focus_selected_day := -1
var active_province := -1
var province_name := ""
var province_terrain := "Plains"
var province_mask: Image
var province_aspect := 1.0
var elapsed_days := 0.0
var leadership_positions: Dictionary = {}
var advisor_roster: Array[Dictionary] = []
var council_inbox: Array[Dictionary] = []
var sovereign_orders: Array[Dictionary] = []
var research_allocations := {"demography":0,"nutrition":1,"health":1,"labor":0,"knowledge":1,"production":0,"infrastructure":0,"logistics":0,"ecology":1,"institutions":0,"security":0,"culture":0}
var research_subcategory_allocations:Dictionary={
	"demography":{"Fertility conditions":0,"Maternal safety":0,"Child survival":0,"Shelter capacity":0},
	"nutrition":{"Daily supply":1,"Diet quality":0,"Stored reserve":0,"Land productivity":0},
	"health":{"General health":0,"Water & sanitation":0,"Disease control":0,"Injury safety":1},
	"labor":{"Able workforce":0,"Work efficiency":0,"Coordination":0,"Workload balance":0},
	"knowledge":{"Observers":0,"Directed attention":0,"Preserved knowledge":1,"Communication":0},
	"production":{"Material supply":0,"Tool quality":0,"Craft capacity":0,"Standardization":0},
	"infrastructure":{"Housing":0,"Construction":0,"Public works":0,"Resilience":0},
	"logistics":{"Carrying capacity":0,"Route quality":0,"Storage system":0,"Trade reach":0},
	"ecology":{"Land health":1,"Natural recovery":0,"Pollution control":0,"Resource sustainability":0},
	"institutions":{"Administration":0,"Legitimacy":0,"State capacity":0,"Institutional flexibility":0},
	"security":{"Public safety":0,"Organized defense":0,"Military readiness":0,"Crisis resilience":0},
	"culture":{"Social cohesion":0,"Shared legitimacy":0,"Inquiry breadth":0,"Collective memory":0}
}
var known_discoveries: Array[String] = []
var discovery_adoption: Dictionary = {}
var knowledge_effects: Dictionary = {}
var society_capacities: Dictionary = {"demography":0.5,"nutrition":0.5,"health":0.5,"labor":0.5,"knowledge":0.18,"production":0.12,"infrastructure":0.05,"logistics":0.16,"ecology":0.88,"institutions":0.25,"security":0.38,"culture":0.58}
var society_subcategories:Dictionary={}
## What this civilization regards as legitimate, how its institutions actually
## operate, and the bounded tension between the two. This is aggregate state;
## it never grows with population.
var societal_values:Dictionary=SOCIETAL_VALUES_MODEL.initial_state("",world_seed,"player")
var combined_intelligence:=0.18
var discovery_log: Array[Dictionary] = []
var active_observations: Array[String] = []
var active_investigations:Dictionary={}
var discovery_progress:Dictionary={}
var population_allocations := {"Food": 30, "Survey": 6, "Extraction": 8, "Construction": 8, "Crafting": 5, "Logistics": 5, "Knowledge": 4, "Administration": 3, "Defense": 3}
var population_allocation_percentages := {"Food":42.0,"Survey":8.0,"Extraction":11.0,"Construction":11.0,"Crafting":7.0,"Logistics":7.0,"Knowledge":6.0,"Administration":4.0,"Defense":4.0}
var population_allocation_auto := true
var population_total := 120
var population_exact := 120.0
var population_health := 0.72
var food_security := 0.82
var housing_capacity := 150
var housing_progress := 0.0
var settlement_projects: Dictionary = {}
var settlement_completed: Array[String] = []
var settlement_site_committed := false
var settlement_founded_at := Vector3.ZERO
var settlement_name := ""
var settlement_founded_day := -1
var settlement_plots:Array[Dictionary]=[]
var settlement_nuclei:Array[Dictionary]=[]
var settlement_routes:Array[Dictionary]=[]
var settlement_morphology:Dictionary={}
var settlement_plot_history:Array[Dictionary]=[]
var next_settlement_plot_id:=1
var next_settlement_nucleus_id:=1
## A bounded aggregate settlement network. One record represents an entire
## settlement regardless of population; no resident entities are created.
var player_settlements:Array[Dictionary]=[]
var next_player_settlement_id:=1
var settlement_convoy:Dictionary={}
var settlement_network_revision:=0
var morphology_revision:=0
var last_morphology_day:=-1
var resource_deposits: Array[Dictionary] = []
var resource_stockpiles: Dictionary = {}
var resource_events: Array[Dictionary] = []
var resource_practice: Dictionary = {}
var resource_priorities: Dictionary = {}
var founding_manifest:Dictionary={}
var economy_stage := "subsistence"
var economy_benchmarks:Dictionary={"subsistence":{"day":0,"from":"founding"}}
var market_prices:Dictionary={}
var economy_metrics:Dictionary={}
var economy_history:Array[Dictionary]=[]
var economy_events:Array[Dictionary]=[]
var economy_known_goods:Dictionary={}
var currency_supply:=0.0
var public_treasury:=0.0
var private_currency:=0.0
var currency_hoards:=0.0
var mutual_aid_reserve:=0.0
var weighed_metal_circulation:=0.0
var weighed_metal_composition:Dictionary={}
var weighed_metal_losses:=0.0
var monetary_reserve_metals:Dictionary={}
var currency_issued:=0.0
var currency_retired:=0.0
var currency_demand:=0.0
var civil_arrears:=0.0
var military_arrears:=0.0
var in_kind_labor_arrears:=0.0
var in_kind_material_arrears:=0.0
var public_debt:=0.0
var public_borrowed:=0.0
var public_debt_repaid:=0.0
var public_interest_accrued:=0.0
var credit_outstanding:=0.0
var credit_defaulted:=0.0
var wealth_shares:Array[float]=[0.08,0.13,0.19,0.25,0.35]
var economic_ledger:Array[Dictionary]=[]
var tax_rate:=0.06
var external_trade_policy:="balanced"
var public_spending_priority:="balanced"
var external_trade_credit:=0.0
var external_trade_exports:=0.0
var external_trade_imports:=0.0
var external_trade_losses:=0.0
var material_metrics: Dictionary = {
	"extracted_today":0.0,"delivered_today":0.0,"lost_today":0.0,
	"at_source":0.0,"in_transit":0.0,"stored_bulk":0.0,"storage_capacity":0.0,
	"flow_ratio":0.0
}
var material_history: Array[Dictionary] = []
var water_metrics: Dictionary = {"stored":0.0,"capacity":0.0,"collected_today":0.0,"required_today":0.0,"consumed_today":0.0,"intake_ratio":0.0,"days":0.0,"source_accessible":false}
var water_history: Array[Dictionary] = []
var food_stocks: Dictionary = {}
var food_source_health := {"Wild gathering":0.92,"Hunting":0.88,"Fishing":0.90,"Cultivation":0.94}
var food_history: Array[Dictionary] = []
## Bounded aggregate audit trail for food removed outside the daily meal cycle
## (scouts, envoys, convoys, trade, tribute, training, and similar obligations).
## One record represents an entire issue; no ration or traveler entities exist.
var food_issue_history: Array[Dictionary] = []
var nutrition_reserve := 0.90
var malnutrition_burden := 0.0

var active_modifiers: Array[Dictionary] = []
var simulation_metrics := {
	"food_days":30.0,
	"food_balance":-1.0,
	"health":0.72,
	"labor_efficiency":0.72,
	"cohesion":0.58,
	"knowledge":0.18,
	"material_capacity":0.12,
	"logistics":0.16,
	"security":0.38,
	"ecology":0.88,
	"legitimacy":0.62,
	"resource_access":0.0,
	"settlement":0.0
}
var simulation_trends: Dictionary = {}
var simulation_events: Array[Dictionary] = []
var last_simulation_event_days: Dictionary = {}
## Evidence signals contributed by returned field parties (scouts, envoys).
## Each entry is signal_name -> {"strength": float, "until_day": int}. While a
## report circulates, matching discovery lines find their evidence environment
## genuinely richer — the same pathway daily activity signals use.
var field_observation_signals: Dictionary = {}


func register_field_observations(signals:Dictionary,until_day:int)->void:
	for signal_name in signals:
		var strength:=clampf(float(signals[signal_name]),0.0,1.0)
		var existing:Dictionary=field_observation_signals.get(String(signal_name),{})
		field_observation_signals[String(signal_name)]={
			"strength":maxf(strength,float(existing.get("strength",0.0))),
			"until_day":maxi(until_day,int(existing.get("until_day",0))),
		}


func active_field_observation_signals(day:int)->Dictionary:
	var active:Dictionary={}
	for signal_name in field_observation_signals.keys():
		var record:Dictionary=field_observation_signals[signal_name]
		if day>int(record.get("until_day",0)):
			field_observation_signals.erase(signal_name)
			continue
		active[signal_name]=float(record.get("strength",0.0))
	return active
var demographic_ledger: Array[Dictionary] = []
var lifetime_births := 0
var lifetime_deaths := 0
var death_progress := 0.0
var consecutive_food_shortage_days := 0.0
var consecutive_water_shortage_days := 0.0
var convoy_traveling := false
var convoy_exposure_days := 0.0
var convoy_emergency_halt_reason := ""
var population_cohorts: Dictionary = {}
var pregnancy_cohorts:Dictionary={"first_trimester":0.0,"second_trimester":0.0,"third_trimester":0.0,"postpartum":0.0}
var demographic_remainders:Dictionary={"conceptions":0.0,"births":0.0,"pregnancy_losses":0.0,"stillbirths":0.0,"maternal_deaths":0.0,"neonatal_deaths":0.0}
var mortality_by_age_cohort:Dictionary={}
var last_population_removal_by_cohort:Dictionary={}
var observed_death_age_sum:=0.0
var lifetime_conceptions := 0
var lifetime_pregnancy_losses := 0
var lifetime_stillbirths := 0
var lifetime_maternal_deaths := 0
var lifetime_neonatal_deaths := 0

func reset_for_new_world(new_seed:int)->void:
	world_seed=new_seed
	founding_banner_index=-1
	founding_focus=""
	founding_focus_selected_day=-1
	active_province=-1
	province_name=""
	province_terrain="Plains"
	province_mask=null
	province_aspect=1.0
	elapsed_days=0.0
	leadership_positions={}
	advisor_roster=[]
	council_inbox=[]
	sovereign_orders=[]
	research_allocations={"demography":0,"nutrition":1,"health":1,"labor":0,"knowledge":1,"production":0,"infrastructure":0,"logistics":0,"ecology":1,"institutions":0,"security":0,"culture":0}
	research_subcategory_allocations={
		"demography":{"Fertility conditions":0,"Maternal safety":0,"Child survival":0,"Shelter capacity":0},"nutrition":{"Daily supply":1,"Diet quality":0,"Stored reserve":0,"Land productivity":0},
		"health":{"General health":0,"Water & sanitation":0,"Disease control":0,"Injury safety":1},"labor":{"Able workforce":0,"Work efficiency":0,"Coordination":0,"Workload balance":0},
		"knowledge":{"Observers":0,"Directed attention":0,"Preserved knowledge":1,"Communication":0},"production":{"Material supply":0,"Tool quality":0,"Craft capacity":0,"Standardization":0},
		"infrastructure":{"Housing":0,"Construction":0,"Public works":0,"Resilience":0},"logistics":{"Carrying capacity":0,"Route quality":0,"Storage system":0,"Trade reach":0},
		"ecology":{"Land health":1,"Natural recovery":0,"Pollution control":0,"Resource sustainability":0},"institutions":{"Administration":0,"Legitimacy":0,"State capacity":0,"Institutional flexibility":0},
		"security":{"Public safety":0,"Organized defense":0,"Military readiness":0,"Crisis resilience":0},"culture":{"Social cohesion":0,"Shared legitimacy":0,"Inquiry breadth":0,"Collective memory":0}
	}
	known_discoveries=[]
	discovery_adoption={}
	knowledge_effects={}
	society_capacities={"demography":0.5,"nutrition":0.5,"health":0.5,"labor":0.5,"knowledge":0.18,"production":0.12,"infrastructure":0.05,"logistics":0.16,"ecology":0.88,"institutions":0.25,"security":0.38,"culture":0.58}
	society_subcategories={}
	societal_values=SOCIETAL_VALUES_MODEL.initial_state("",world_seed,"player")
	combined_intelligence=0.18
	discovery_log=[]
	active_observations=[]
	active_investigations={}
	discovery_progress={}
	population_allocations={"Food":30,"Survey":6,"Extraction":8,"Construction":8,"Crafting":5,"Logistics":5,"Knowledge":4,"Administration":3,"Defense":3}
	population_allocation_percentages={"Food":42.0,"Survey":8.0,"Extraction":11.0,"Construction":11.0,"Crafting":7.0,"Logistics":7.0,"Knowledge":6.0,"Administration":4.0,"Defense":4.0}
	population_allocation_auto=true
	population_total=120
	population_exact=120.0
	population_health=0.72
	food_security=0.82
	housing_capacity=150
	housing_progress=0.0
	settlement_projects={}
	settlement_completed=[]
	settlement_site_committed=false
	settlement_founded_at=Vector3.ZERO
	settlement_name=""
	settlement_founded_day=-1
	settlement_plots=[]
	settlement_nuclei=[]
	settlement_routes=[]
	settlement_morphology={}
	settlement_plot_history=[]
	next_settlement_plot_id=1
	next_settlement_nucleus_id=1
	player_settlements=[]
	next_player_settlement_id=1
	settlement_convoy={}
	settlement_network_revision=0
	morphology_revision=0
	last_morphology_day=-1
	resource_deposits=[]
	resource_stockpiles={}
	resource_events=[]
	resource_practice={}
	resource_priorities={}
	founding_manifest={}
	economy_stage="subsistence"
	economy_benchmarks={"subsistence":{"day":0,"from":"founding"}}
	market_prices={}
	economy_metrics={}
	economy_history=[]
	economy_events=[]
	economy_known_goods={}
	currency_supply=0.0
	public_treasury=0.0
	private_currency=0.0
	currency_hoards=0.0
	mutual_aid_reserve=0.0
	weighed_metal_circulation=0.0
	weighed_metal_composition={}
	weighed_metal_losses=0.0
	monetary_reserve_metals={}
	currency_issued=0.0
	currency_retired=0.0
	currency_demand=0.0
	civil_arrears=0.0
	military_arrears=0.0
	in_kind_labor_arrears=0.0
	in_kind_material_arrears=0.0
	public_debt=0.0
	public_borrowed=0.0
	public_debt_repaid=0.0
	public_interest_accrued=0.0
	credit_outstanding=0.0
	credit_defaulted=0.0
	wealth_shares=[0.08,0.13,0.19,0.25,0.35]
	economic_ledger=[]
	tax_rate=0.06
	external_trade_policy="balanced"
	public_spending_priority="balanced"
	external_trade_credit=0.0
	external_trade_exports=0.0
	external_trade_imports=0.0
	external_trade_losses=0.0
	material_metrics={"extracted_today":0.0,"delivered_today":0.0,"lost_today":0.0,"at_source":0.0,"in_transit":0.0,"stored_bulk":0.0,"storage_capacity":0.0,"flow_ratio":0.0}
	material_history=[]
	water_metrics={"stored":0.0,"capacity":0.0,"collected_today":0.0,"required_today":0.0,"consumed_today":0.0,"intake_ratio":0.0,"days":0.0,"source_accessible":false}
	water_history=[]
	food_stocks={}
	food_source_health={"Wild gathering":0.92,"Hunting":0.88,"Fishing":0.90,"Cultivation":0.94}
	food_history=[]
	food_issue_history=[]
	nutrition_reserve=0.90
	malnutrition_burden=0.0
	active_modifiers=[]
	simulation_metrics={"food_days":30.0,"food_balance":-1.0,"health":0.72,"labor_efficiency":0.72,"cohesion":0.58,"knowledge":0.18,"material_capacity":0.12,"logistics":0.16,"security":0.38,"ecology":0.88,"legitimacy":0.62,"resource_access":0.0,"settlement":0.0}
	simulation_trends={}
	simulation_events=[]
	last_simulation_event_days={}
	field_observation_signals={}
	demographic_ledger=[]
	lifetime_births=0
	lifetime_deaths=0
	death_progress=0.0
	consecutive_food_shortage_days=0.0
	consecutive_water_shortage_days=0.0
	convoy_traveling=false
	convoy_exposure_days=0.0
	convoy_emergency_halt_reason=""
	population_cohorts={}
	pregnancy_cohorts={"first_trimester":0.0,"second_trimester":0.0,"third_trimester":0.0,"postpartum":0.0}
	demographic_remainders={"conceptions":0.0,"births":0.0,"pregnancy_losses":0.0,"stillbirths":0.0,"maternal_deaths":0.0,"neonatal_deaths":0.0}
	mortality_by_age_cohort={}
	last_population_removal_by_cohort={}
	observed_death_age_sum=0.0
	lifetime_conceptions=0
	lifetime_pregnancy_losses=0
	lifetime_stillbirths=0
	lifetime_maternal_deaths=0
	lifetime_neonatal_deaths=0


func settlement_lifecycle_phase()->String:
	# Founding travel, committed ground, and an established settlement are distinct
	# states. Presentation code should use this contract instead of inferring a
	# "convoy" from an empty construction list after the expedition has stopped.
	if bool(settlement_convoy.get("active",false)):
		return "expansion_convoy"
	if not settlement_site_committed:
		return "founding_expedition"
	if "Hearth Circle" not in settlement_completed:
		return "founding_site"
	return "established_network"


func founding_expedition_active()->bool:
	return settlement_lifecycle_phase()=="founding_expedition"


func founding_focus_catalog()->Array[Dictionary]:
	var catalog:Array[Dictionary]=[]
	for focus_id in FOUNDING_FOCUS_ORDER:
		var definition:Dictionary=(FOUNDING_FOCUSES[focus_id] as Dictionary).duplicate(true)
		definition["id"]=focus_id
		catalog.append(definition)
	return catalog


func founding_focus_definition(focus_id:String=founding_focus)->Dictionary:
	return (FOUNDING_FOCUSES.get(focus_id,{}) as Dictionary).duplicate(true)


func founding_effect(effect_id:String)->float:
	if founding_focus=="": return 0.0
	var effects:Dictionary=(FOUNDING_FOCUSES.get(founding_focus,{}) as Dictionary).get("effects",{})
	return float(effects.get(effect_id,0.0))


func select_founding_focus(focus_id:String)->Dictionary:
	if focus_id not in FOUNDING_FOCUS_ORDER: return {"error":"Choose one of the available founding focuses."}
	if founding_focus!="": return {"error":"The founding focus was already established."}
	if elapsed_days>=1.0: return {"error":"A founding focus can only be established before the first day passes."}
	var definition:Dictionary=FOUNDING_FOCUSES[focus_id]
	founding_focus=focus_id
	founding_focus_selected_day=int(floor(elapsed_days))
	founding_banner_index=FOUNDING_FOCUS_ORDER.find(focus_id)
	_apply_founding_focus_start(definition)
	societal_values=SOCIETAL_VALUES_MODEL.apply_founding_focus(societal_values,focus_id)
	return {"ok":true,"id":focus_id,"name":String(definition.name),"message":"%s now defines the civilization's durable founding strengths and costs." % String(definition.name).capitalize()}


func _apply_founding_focus_start(definition:Dictionary)->void:
	var starting:Dictionary=definition.get("starting",{})
	var food_ratio:=1.0+float(starting.get("food_days_ratio",0.0))
	if not resource_stockpiles.is_empty():
		resource_stockpiles["Food"]=maxf(0.0,float(resource_stockpiles.get("Food",0.0))*food_ratio)
	if not food_stocks.is_empty():
		for food_type in food_stocks: food_stocks[food_type]=maxf(0.0,float(food_stocks[food_type])*food_ratio)
	if not founding_manifest.is_empty(): founding_manifest["food_storage_rations"]=maxf(0.0,float(founding_manifest.get("food_storage_rations",population_exact*30.0))*maxf(1.0,food_ratio))
	var material_ratio:=1.0+float(starting.get("starting_materials",0.0))
	if not resource_stockpiles.is_empty() and material_ratio!=1.0:
		for resource_name in ["Timber","Stone","Clay","Fiber Plants"]:
			resource_stockpiles[resource_name]=maxf(0.0,float(resource_stockpiles.get(resource_name,0.0))*material_ratio)
	housing_capacity=maxi(1,roundi(float(housing_capacity)*(1.0+float(starting.get("housing_ratio",0.0)))))
	population_health=clampf(population_health+float(starting.get("health",0.0)),0.05,0.98)
	food_security=clampf(food_security+float(starting.get("food_capacity_ratio",0.0))*0.25,0.05,0.98)
	for metric in ["knowledge","material_capacity","logistics","security","ecology","cohesion","legitimacy"]:
		if starting.has(metric): simulation_metrics[metric]=clampf(float(simulation_metrics.get(metric,0.0))+float(starting[metric]),0.02,0.98)
	for capacity in ["knowledge","production","logistics","security","ecology","culture","institutions"]:
		if starting.has(capacity): society_capacities[capacity]=clampf(float(society_capacities.get(capacity,0.0))+float(starting[capacity]),0.02,0.98)
	combined_intelligence=clampf(float(simulation_metrics.get("knowledge",combined_intelligence)),0.0,1.0)
	var allocations:Dictionary=definition.get("allocations",{})
	if not allocations.is_empty():
		population_allocation_percentages=allocations.duplicate(true)
		synchronize_population_allocations()

func initialize_population_model() -> void:
	if not population_cohorts.is_empty():
		_normalize_population_cohorts()
		return
	var total:=maxf(1.0,population_exact)
	population_cohorts={
		"children":total*0.32,
		"youth":total*0.15,
		"early_adults":total*0.14,
		"established_adults":total*0.13,
		"mature_adults":total*0.18,
		"elders":total*0.08
	}
	var reproductive_population:=_reproductive_age_population()
	var seeded_pregnancies:=reproductive_population*0.045
	pregnancy_cohorts={
		"first_trimester":seeded_pregnancies*0.34,
		"second_trimester":seeded_pregnancies*0.33,
		"third_trimester":seeded_pregnancies*0.33,
		"postpartum":reproductive_population*0.018
	}
	_refresh_population_summary()

func _age_cohort_sum() -> float:
	var total:=0.0
	for key in POPULATION_AGE_COHORTS:
		total+=maxf(0.0,float(population_cohorts.get(key,0.0)))
	return total

func _normalize_population_cohorts() -> void:
	var current:=_age_cohort_sum()
	var target:=maxf(1.0,population_exact)
	if current<=0.000001:
		population_cohorts.clear()
		initialize_population_model()
		return
	var scale:=target/current
	for key in POPULATION_AGE_COHORTS:
		population_cohorts[key]=maxf(0.0,float(population_cohorts.get(key,0.0))*scale)
	_refresh_population_summary()

func _refresh_population_summary() -> void:
	var working:=0.0
	for key in ["youth","early_adults","established_adults","mature_adults"]:
		working+=float(population_cohorts.get(key,0.0))
	population_cohorts["working_age"]=working
	population_cohorts["female"]=population_exact*0.495
	population_cohorts["male"]=population_exact-float(population_cohorts.female)
	population_total=maxi(1,roundi(population_exact))

func _integer_age_cohorts() -> Dictionary:
	initialize_population_model()
	var result:Dictionary={}
	var fractions:Array[Dictionary]=[]
	var assigned:=0
	for key in POPULATION_AGE_COHORTS:
		var exact:=maxf(0.0,float(population_cohorts.get(key,0.0)))
		var whole:=floori(exact)
		result[key]=whole
		assigned+=whole
		fractions.append({"key":key,"fraction":exact-float(whole)})
	fractions.sort_custom(func(a:Dictionary,b:Dictionary)->bool: return float(a.fraction)>float(b.fraction))
	var remaining:=maxi(0,population_total-assigned)
	for index in mini(remaining,fractions.size()):
		var key:=String(fractions[index].key)
		result[key]=int(result.get(key,0))+1
	return result

func estimated_active_pregnancies() -> int:
	initialize_population_model()
	return roundi(float(pregnancy_cohorts.get("first_trimester",0.0))+float(pregnancy_cohorts.get("second_trimester",0.0))+float(pregnancy_cohorts.get("third_trimester",0.0)))

func _reproductive_age_population() -> float:
	return float(population_cohorts.get("youth",0.0))*0.45+float(population_cohorts.get("early_adults",0.0))*0.50+float(population_cohorts.get("established_adults",0.0))*0.45+float(population_cohorts.get("mature_adults",0.0))*0.16

func pregnancy_summary() -> Dictionary:
	initialize_population_model()
	var first:=roundi(float(pregnancy_cohorts.get("first_trimester",0.0)))
	var second:=roundi(float(pregnancy_cohorts.get("second_trimester",0.0)))
	var third:=roundi(float(pregnancy_cohorts.get("third_trimester",0.0)))
	return {
		"active":first+second+third,
		"due_within_year":first+second+third,
		"first_trimester":first,
		"second_trimester":second,
		"third_trimester":third,
		"postpartum":roundi(float(pregnancy_cohorts.get("postpartum",0.0))),
		"eligible":roundi(maxf(0.0,_reproductive_age_population()-float(first+second+third)))
	}

func _conception_condition_factor(context:Dictionary) -> float:
	var health:=clampf(float(context.get("health",population_health)),0.0,1.0)
	var food:=clampf(float(context.get("food_security",food_security)),0.0,1.0)
	var housing:=clampf(float(context.get("housing_ratio",0.5)),0.0,1.0)
	var cohesion:=clampf(float(context.get("cohesion",0.58)),0.0,1.0)
	var factor:=lerpf(0.12,1.08,health)*lerpf(0.10,1.05,food)*lerpf(0.55,1.03,housing)*lerpf(0.82,1.04,cohesion)
	if bool(context.get("traveling",false)): factor*=0.62
	if bool(context.get("birth_crisis",false)): factor*=0.06
	factor*=1.0+clampf(float(context.get("conception_support",0.0)),-0.30,0.30)
	return clampf(factor,0.0,1.30)

func _pregnancy_risk_multiplier(context:Dictionary) -> float:
	var health:=clampf(float(context.get("health",population_health)),0.0,1.0)
	var food:=clampf(float(context.get("food_security",food_security)),0.0,1.0)
	var housing:=clampf(float(context.get("housing_ratio",0.5)),0.0,1.0)
	var multiplier:=1.0+maxf(0.0,0.72-health)*3.2+maxf(0.0,0.58-food)*2.6+maxf(0.0,0.55-housing)*1.8
	if bool(context.get("traveling",false)): multiplier*=1.32
	multiplier*=1.0-clampf(float(context.get("maternal_safety",0.0)),0.0,0.60)
	return clampf(multiplier,0.72,5.0)

func _advance_age_cohorts_one_day() -> void:
	initialize_population_model()
	for transition in [["children","youth"],["youth","early_adults"],["early_adults","established_adults"],["established_adults","mature_adults"],["mature_adults","elders"]]:
		var source:=String(transition[0])
		var destination:=String(transition[1])
		var moving:=float(population_cohorts.get(source,0.0))/float(POPULATION_COHORT_DURATIONS_DAYS[source])
		population_cohorts[source]=maxf(0.0,float(population_cohorts.get(source,0.0))-moving)
		population_cohorts[destination]=float(population_cohorts.get(destination,0.0))+moving

func _accumulate_demographic_count(key:String,amount:float) -> int:
	var accumulated:=maxf(0.0,float(demographic_remainders.get(key,0.0))+maxf(0.0,amount))
	var emitted:=floori(accumulated)
	demographic_remainders[key]=accumulated-float(emitted)
	return emitted

func _mortality_weights_for(cause:String) -> Dictionary:
	match cause:
		"Hunger": return {"children":2.2,"youth":0.8,"early_adults":0.7,"established_adults":0.8,"mature_adults":1.2,"elders":2.0}
		"Illness","Dehydration","Exposure": return {"children":1.8,"youth":0.7,"early_adults":0.7,"established_adults":0.9,"mature_adults":1.4,"elders":2.6}
		"Travel exhaustion": return {"children":1.3,"youth":1.1,"early_adults":1.2,"established_adults":1.2,"mature_adults":1.5,"elders":2.1}
		"Insecurity","Killed in battle": return {"children":0.2,"youth":1.2,"early_adults":1.8,"established_adults":1.7,"mature_adults":1.1,"elders":0.3}
		"Complications of childbirth": return {"children":0.0,"youth":1.2,"early_adults":2.0,"established_adults":1.5,"mature_adults":0.4,"elders":0.0}
		"Neonatal complications": return {"children":1.0,"youth":0.0,"early_adults":0.0,"established_adults":0.0,"mature_adults":0.0,"elders":0.0}
		_: return {"children":0.8,"youth":0.25,"early_adults":0.32,"established_adults":0.55,"mature_adults":1.25,"elders":3.2}

func _remove_population_exact(amount:float,cause:String) -> float:
	initialize_population_model()
	var actual:=clampf(amount,0.0,maxf(0.0,population_exact-1.0))
	last_population_removal_by_cohort={}
	if actual<=0.0: return 0.0
	var weights:=_mortality_weights_for(cause)
	var remaining:=actual
	var midpoints:={"children":7.0,"youth":19.0,"early_adults":29.5,"established_adults":39.5,"mature_adults":52.0,"elders":68.5}
	# Redistribute capped shares across the six fixed cohorts. This remains O(1)
	# at a population of 120 or 12 billion and accounts for every numeric death.
	for _pass in POPULATION_AGE_COHORTS.size()+1:
		if remaining<=0.000001: break
		var weighted_total:=0.0
		for key in POPULATION_AGE_COHORTS:
			var available:=float(population_cohorts.get(key,0.0))
			if available>0.000001: weighted_total+=available*maxf(0.0,float(weights.get(key,1.0)))
		var use_fallback:=weighted_total<=0.000001
		if use_fallback:
			for key in POPULATION_AGE_COHORTS: weighted_total+=float(population_cohorts.get(key,0.0))
		if weighted_total<=0.000001: break
		var pass_remaining:=remaining
		var removed_this_pass:=0.0
		for key in POPULATION_AGE_COHORTS:
			var available:=float(population_cohorts.get(key,0.0))
			if available<=0.000001: continue
			var basis:=available if use_fallback else available*maxf(0.0,float(weights.get(key,1.0)))
			if basis<=0.0: continue
			var removed:=minf(available,pass_remaining*basis/weighted_total)
			population_cohorts[key]=available-removed
			last_population_removal_by_cohort[key]=float(last_population_removal_by_cohort.get(key,0.0))+removed
			mortality_by_age_cohort[key]=float(mortality_by_age_cohort.get(key,0.0))+removed
			observed_death_age_sum+=removed*float(midpoints[key])
			removed_this_pass+=removed
		remaining=maxf(0.0,remaining-removed_this_pass)
		if removed_this_pass<=0.000001: break
	var removed_total:=actual-remaining
	population_exact=maxf(1.0,population_exact-removed_total)
	_normalize_population_cohorts()
	return removed_total

func register_population_deaths(count:int,cause:String) -> Dictionary:
	initialize_population_model()
	var actual:=mini(maxi(0,count),maxi(0,population_total-1))
	var removed:=_remove_population_exact(float(actual),cause)
	var emitted:=roundi(removed)
	var affected_cohorts:=last_population_removal_by_cohort.duplicate(true)
	lifetime_deaths+=emitted
	synchronize_population_allocations()
	return {"count":emitted,"cause":cause,"affected_cohorts":affected_cohorts,"population_after":population_total}

func register_directive_population_deaths(count:int,directive_id:String,description:String)->Dictionary:
	# Directives operate on one numeric population, never generated people. This
	# authoritative entry point preserves the same cohort conservation used by
	# illness, hunger, travel, and war, and leaves at least one living person.
	var safe_id:=directive_id.strip_edges().to_lower().replace(" ","_").substr(0,80)
	var cause:="Directive: %s" % safe_id.replace("_"," ").capitalize()
	var result:=register_population_deaths(count,cause)
	var actual:=int(result.get("count",0))
	if actual<=0: return result
	var day:=int(elapsed_days)
	var record:Dictionary={
		"id":"directive_deaths_%d_%d" % [day,demographic_ledger.size()],"day":day,"start_day":day,"end_day":day,
		"title":"%d deaths during %s" % [actual,safe_id.replace("_"," ")],"description":description.substr(0,320),
		"domain":"population","severity":"demographic","kind":"death","count":actual,"cause":cause,
		"location":"Civilization under directive","population_after":population_total,
		"affected_cohorts":(result.get("affected_cohorts",{}) as Dictionary).duplicate(true),"aggregate":true
	}
	demographic_ledger.push_front(record)
	if demographic_ledger.size()>120: demographic_ledger.resize(120)
	result["record"]=record
	return result

func register_population_arrivals(count:int,source:String="new arrivals",cohort_profile:Dictionary={}) -> Dictionary:
	initialize_population_model()
	var actual:=maxi(0,count)
	if actual<=0: return {"count":0,"source":source,"population_after":population_total,"cohorts":{}}
	var weights:=cohort_profile.duplicate(true)
	if weights.is_empty():
		# Small mobile groups skew toward working ages while still allowing
		# families. One aggregate update scales identically at 120 or 12B.
		weights={"children":0.12,"youth":0.20,"early_adults":0.28,"established_adults":0.22,"mature_adults":0.14,"elders":0.04}
	var total_weight:=0.0
	for key in POPULATION_AGE_COHORTS: total_weight+=maxf(0.0,float(weights.get(key,0.0)))
	if total_weight<=0.000001: total_weight=1.0
	var added:Dictionary={}
	for key in POPULATION_AGE_COHORTS:
		var amount:=float(actual)*maxf(0.0,float(weights.get(key,0.0)))/total_weight
		population_cohorts[key]=float(population_cohorts.get(key,0.0))+amount
		added[key]=amount
	population_exact+=float(actual)
	_refresh_population_summary()
	synchronize_population_allocations()
	return {"count":actual,"source":source,"population_after":population_total,"cohorts":added}

func process_reproduction_day(context:Dictionary) -> Dictionary:
	initialize_population_model()
	_advance_age_cohorts_one_day()
	var reproductive_population:=_reproductive_age_population()
	var active:=float(pregnancy_cohorts.get("first_trimester",0.0))+float(pregnancy_cohorts.get("second_trimester",0.0))+float(pregnancy_cohorts.get("third_trimester",0.0))
	var postpartum:=float(pregnancy_cohorts.get("postpartum",0.0))
	var eligible:=maxf(0.0,reproductive_population-active-postpartum*0.55)
	var baseline_annual:=float(population_cohorts.get("youth",0.0))*0.45*0.23+float(population_cohorts.get("early_adults",0.0))*0.50*0.285+float(population_cohorts.get("established_adults",0.0))*0.45*0.18+float(population_cohorts.get("mature_adults",0.0))*0.16*0.040
	var availability:=clampf(eligible/maxf(1.0,reproductive_population),0.0,1.0)
	var annual_conceptions:=baseline_annual*_conception_condition_factor(context)*availability
	var conceptions_exact:=annual_conceptions/365.0
	var risk:=_pregnancy_risk_multiplier(context)
	var first:=float(pregnancy_cohorts.get("first_trimester",0.0))
	var second:=float(pregnancy_cohorts.get("second_trimester",0.0))
	var third:=float(pregnancy_cohorts.get("third_trimester",0.0))
	var first_losses:=first*0.00105*risk
	var second_losses:=second*0.00024*risk
	var third_losses:=third*0.00007*risk
	var to_second:=maxf(0.0,first-first_losses)/91.0
	var to_third:=maxf(0.0,second-second_losses)/91.0
	var deliveries:=maxf(0.0,third-third_losses)/98.0
	var stillbirth_rate:=clampf(0.018+(risk-1.0)*0.018,0.010,0.14)
	var stillbirths_exact:=deliveries*stillbirth_rate
	var live_births_exact:=maxf(0.0,deliveries-stillbirths_exact)
	var neonatal_rate:=clampf((0.018+(risk-1.0)*0.025)*(1.0-clampf(float(context.get("neonatal_survival",0.0)),0.0,0.60)),0.004,0.18)
	var neonatal_deaths_exact:=live_births_exact*neonatal_rate
	var maternal_rate:=clampf((0.0045+(risk-1.0)*0.0065)*(1.0-clampf(float(context.get("maternal_safety",0.0)),0.0,0.65)),0.0008,0.055)
	var maternal_deaths_exact:=deliveries*maternal_rate
	pregnancy_cohorts["first_trimester"]=maxf(0.0,first+conceptions_exact-first_losses-to_second)
	pregnancy_cohorts["second_trimester"]=maxf(0.0,second+to_second-second_losses-to_third)
	pregnancy_cohorts["third_trimester"]=maxf(0.0,third+to_third-third_losses-deliveries)
	pregnancy_cohorts["postpartum"]=maxf(0.0,postpartum+deliveries-postpartum/365.0)
	population_cohorts["children"]=float(population_cohorts.get("children",0.0))+live_births_exact
	population_exact+=live_births_exact
	_remove_population_exact(neonatal_deaths_exact,"Neonatal complications")
	_remove_population_exact(maternal_deaths_exact,"Complications of childbirth")
	_normalize_population_cohorts()
	var conceptions_count:=_accumulate_demographic_count("conceptions",conceptions_exact)
	var births_count:=_accumulate_demographic_count("births",live_births_exact)
	var loss_exact:=first_losses+second_losses+third_losses
	var losses_count:=_accumulate_demographic_count("pregnancy_losses",loss_exact)
	var stillbirth_count:=_accumulate_demographic_count("stillbirths",stillbirths_exact)
	var maternal_count:=_accumulate_demographic_count("maternal_deaths",maternal_deaths_exact)
	var neonatal_count:=_accumulate_demographic_count("neonatal_deaths",neonatal_deaths_exact)
	lifetime_conceptions+=conceptions_count
	lifetime_births+=births_count
	lifetime_pregnancy_losses+=losses_count
	lifetime_stillbirths+=stillbirth_count
	lifetime_maternal_deaths+=maternal_count
	lifetime_neonatal_deaths+=neonatal_count
	lifetime_deaths+=maternal_count+neonatal_count
	synchronize_population_allocations()
	return {
		"births_count":births_count,
		"pregnancy_losses_count":losses_count,
		"stillbirths_count":stillbirth_count,
		"maternal_deaths_count":maternal_count,
		"neonatal_deaths_count":neonatal_count,
		"conceptions_count":conceptions_count,
		"active_pregnancies":estimated_active_pregnancies(),
		"eligible_parents":roundi(eligible),
		"annual_conceptions_expected":annual_conceptions,
		"projected_live_births":annual_conceptions*(1.0-stillbirth_rate)*(1.0-neonatal_rate),
		"projected_birth_rate":annual_conceptions*(1.0-stillbirth_rate)*(1.0-neonatal_rate)/maxf(1.0,population_exact),
		"births_expected_next_year":annual_conceptions*(1.0-stillbirth_rate)*(1.0-neonatal_rate)
	}

func age_distribution(bucket_years:=5,max_age:=85) -> Array[Dictionary]:
	initialize_population_model()
	var buckets:Array[Dictionary]=[]
	for start_age in range(0,max_age,bucket_years):
		buckets.append({"start":start_age,"end":start_age+bucket_years-1,"count":0})
	var ranges:={"children":Vector2(0,14),"youth":Vector2(14,25),"early_adults":Vector2(25,35),"established_adults":Vector2(35,45),"mature_adults":Vector2(45,60),"elders":Vector2(60,max_age)}
	for key in POPULATION_AGE_COHORTS:
		var cohort_range:Vector2=ranges[key]
		var cohort_count:=float(population_cohorts.get(key,0.0))
		var duration:=maxf(1.0,cohort_range.y-cohort_range.x)
		for bucket in buckets:
			var overlap:=maxf(0.0,minf(cohort_range.y,float(bucket.end+1))-maxf(cohort_range.x,float(bucket.start)))
			bucket.count=int(bucket.count)+roundi(cohort_count*overlap/duration)
	var assigned:=0
	for bucket in buckets: assigned+=int(bucket.count)
	if not buckets.is_empty(): buckets[mini(5,buckets.size()-1)].count=int(buckets[mini(5,buckets.size()-1)].count)+(population_total-assigned)
	return buckets

func population_age_profile() -> Dictionary:
	var counts:=_integer_age_cohorts()
	var labels:=["CHILDREN","YOUTH","EARLY ADULT","ESTABLISHED","MATURE","ELDERS"]
	var ranges:=["0–13","14–24","25–34","35–44","45–59","60+"]
	var bands:Array[Dictionary]=[]
	for index in POPULATION_AGE_COHORTS.size():
		var count:=int(counts.get(POPULATION_AGE_COHORTS[index],0))
		bands.append({"label":labels[index],"range":ranges[index],"count":count,"share":float(count)/maxf(1.0,float(population_total))})
	var working:=int(counts.youth)+int(counts.early_adults)+int(counts.established_adults)+int(counts.mature_adults)
	var dependents:=population_total-working
	var observed_age:=-1.0 if lifetime_deaths<=0 else observed_death_age_sum/maxf(1.0,float(lifetime_deaths))
	return {"bands":bands,"total":population_total,"median_age":29.0,"working_age":working,"dependents":dependents,"dependents_per_100_workers":100.0*float(dependents)/maxf(1.0,float(working)),"projected_life_expectancy":projected_life_expectancy(),"observed_age_at_death":observed_age,"recorded_deaths":lifetime_deaths}


# One conserved, aggregate answer to "what is the population doing?". Missions
# pass their fixed-size source totals in `commitments.by_function`; no person,
# household, or traveler records are created. Absent people are removed from
# their former function so UI totals cannot double-count them.
func population_function_profile(commitments:Dictionary={}) -> Dictionary:
	synchronize_population_allocations()
	var base:Dictionary={"productive":0,"support":0,"mobilized":0,"dependent":maxi(0,population_total-able_population())}
	for role in PRODUCTIVE_POPULATION_ROLES:
		base.productive=int(base.productive)+maxi(0,int(population_allocations.get(role,0)))
	for role in SUPPORT_POPULATION_ROLES:
		base.support=int(base.support)+maxi(0,int(population_allocations.get(role,0)))
	base.mobilized=maxi(0,int(population_allocations.get("Defense",0)))
	var mobilized_target:=maxi(int(base.mobilized),maxi(0,int(commitments.get("mobilized_total",base.mobilized))))
	var mobilized_transfer:Dictionary={"productive":0,"support":0}
	var mobilization_excess:=maxi(0,mobilized_target-int(base.mobilized))
	for function_id in ["productive","support"]:
		if mobilization_excess<=0: break
		var transferred:=mini(mobilization_excess,maxi(0,int(base.get(function_id,0))))
		base[function_id]=int(base.get(function_id,0))-transferred
		base.mobilized=int(base.mobilized)+transferred
		mobilized_transfer[function_id]=transferred
		mobilization_excess-=transferred
	var available:=base.duplicate(true)
	var removed:Dictionary={"productive":0,"support":0,"mobilized":0,"dependent":0}
	var requested:Dictionary=commitments.get("by_function",commitments.get("by_source",{}))
	for function_id in ["productive","support","mobilized","dependent"]:
		var amount:=maxi(0,int(requested.get(function_id,0)))
		var taken:=mini(amount,maxi(0,int(available.get(function_id,0))))
		available[function_id]=int(available.get(function_id,0))-taken
		removed[function_id]=taken
	var explicitly_removed:=0
	for amount in removed.values(): explicitly_removed+=int(amount)
	var requested_total:=maxi(explicitly_removed,maxi(0,int(commitments.get("total_absent",explicitly_removed))))
	var overflow:=maxi(0,requested_total-explicitly_removed)
	# Old saves may know only the mission headcount. Draw unclassified absences in
	# a deterministic order and never let total absence exceed the population.
	for function_id in ["productive","support","mobilized","dependent"]:
		if overflow<=0: break
		var taken:=mini(overflow,maxi(0,int(available.get(function_id,0))))
		available[function_id]=int(available.get(function_id,0))-taken
		removed[function_id]=int(removed.get(function_id,0))+taken
		overflow-=taken
	var absent:=0
	for amount in removed.values(): absent+=int(amount)
	var records:Array[Dictionary]=[]
	var labels:={"productive":"PRODUCTIVE","support":"SUPPORT & SERVICES","mobilized":"MOBILIZED","dependent":"DEPENDENTS","absent":"AWAY"}
	for function_id in POPULATION_FUNCTIONS:
		var count:=absent if function_id=="absent" else maxi(0,int(available.get(function_id,0)))
		records.append({
			"id":function_id,"label":String(labels[function_id]),"count":count,
			"share":float(count)/maxf(1.0,float(population_total)),
			"available_at_settlements":function_id!="absent",
			"productive":function_id=="productive"
		})
	var accounted:=absent
	for function_id in ["productive","support","mobilized","dependent"]: accounted+=int(available.get(function_id,0))
	return {
		"total":population_total,"accounted":accounted,"functions":records,
		"productive":int(available.productive),"support":int(available.support),
		"mobilized":int(available.mobilized),"dependent":int(available.dependent),"absent":absent,
		"absent_from":removed,"mobilized_from":mobilized_transfer,"mobilization":(commitments.get("mobilization",{}) as Dictionary).duplicate(true),
		"commitments":(commitments.get("records",[]) as Array).duplicate(true),
		"bounded":true
	}


# Divide a moving aggregate across the same conserved functions. This is used
# when a founding convoy includes working adults and dependents; largest-
# remainder rounding keeps the exact requested headcount at every scale.
func proportional_population_commitment(requested_count:int) -> Dictionary:
	var count:=clampi(requested_count,0,population_total)
	var profile:=population_function_profile()
	var result:Dictionary={"productive":0,"support":0,"mobilized":0,"dependent":0}
	var remainders:Dictionary={}
	var assigned:=0
	for function_id in ["productive","support","mobilized","dependent"]:
		var exact:=float(count)*float(profile.get(function_id,0))/maxf(1.0,float(population_total))
		var whole:=floori(exact)
		result[function_id]=whole
		remainders[function_id]=exact-float(whole)
		assigned+=whole
	while assigned<count:
		var best_id:="productive"
		var best_remainder:=-1.0
		for function_id in ["productive","support","mobilized","dependent"]:
			if float(remainders.get(function_id,-1.0))>best_remainder:
				best_remainder=float(remainders[function_id])
				best_id=function_id
		result[best_id]=int(result[best_id])+1
		remainders[best_id]=-1.0
		assigned+=1
	return result

func projected_life_expectancy() -> float:
	var health_factor:=lerpf(1.90,0.64,clampf(population_health,0.0,1.0))
	var food_factor:=lerpf(2.40,0.78,clampf(food_security,0.0,1.0))
	var housing_ratio:=clampf(float(housing_capacity)/maxf(1.0,population_exact),0.0,1.15)
	var shelter_factor:=lerpf(1.65,0.88,clampf(housing_ratio,0.0,1.0))
	var condition_factor:=health_factor*food_factor*shelter_factor
	var current_total_rate:=float(simulation_metrics.get("annual_death_rate",0.01))
	var exceptional_hazard:=maxf(0.0,current_total_rate-0.014)
	var survival:=1.0
	var expected_years:=0.0
	for age in 110:
		var baseline_hazard:=0.004
		if age==0: baseline_hazard=0.090
		elif age<5: baseline_hazard=0.025
		elif age<15: baseline_hazard=0.004
		elif age<25: baseline_hazard=0.006
		elif age<35: baseline_hazard=0.008
		elif age<45: baseline_hazard=0.012
		elif age<55: baseline_hazard=0.025
		elif age<65: baseline_hazard=0.055
		elif age<75: baseline_hazard=0.120
		elif age<85: baseline_hazard=0.230
		else: baseline_hazard=0.380
		var annual_hazard:=clampf(baseline_hazard*condition_factor+exceptional_hazard,0.0001,0.98)
		expected_years+=survival
		survival*=1.0-annual_hazard
	return clampf(expected_years,1.0,110.0)

func able_population() -> int:
	initialize_population_model()
	return maxi(1,roundi(float(population_cohorts.get("working_age",population_exact*0.60))))

func synchronize_population_allocations() -> void:
	initialize_population_model()
	var total_percentage:=0.0
	for role in POPULATION_ROLES:
		total_percentage+=maxf(0.0,float(population_allocation_percentages.get(role,0.0)))
	if total_percentage<=0.001:
		population_allocation_percentages={"Food":42.0,"Survey":8.0,"Extraction":11.0,"Construction":11.0,"Crafting":7.0,"Logistics":7.0,"Knowledge":6.0,"Administration":4.0,"Defense":4.0}
		total_percentage=100.0
	var able:=able_population()
	var assigned:=0
	var remainders:Dictionary={}
	for role in POPULATION_ROLES:
		var normalized:=maxf(0.0,float(population_allocation_percentages.get(role,0.0)))/total_percentage
		var exact:=float(able)*normalized
		var count:=floori(exact)
		population_allocations[role]=count
		remainders[role]=exact-count
		assigned+=count
	while assigned<able:
		var best_role:=String(POPULATION_ROLES[0])
		var best_remainder:=-INF
		for role in POPULATION_ROLES:
			if float(remainders.get(role,-1.0))>best_remainder:
				best_remainder=float(remainders[role])
				best_role=String(role)
		population_allocations[best_role]=int(population_allocations.get(best_role,0))+1
		remainders[best_role]=-1.0
		assigned+=1

func ensure_population_total(target:int) -> void:
	target=maxi(1,target)
	initialize_population_model()
	var scale:=float(target)/maxf(1.0,population_exact)
	for key in pregnancy_cohorts: pregnancy_cohorts[key]=maxf(0.0,float(pregnancy_cohorts.get(key,0.0))*scale)
	population_exact=float(target)
	_normalize_population_cohorts()
	synchronize_population_allocations()

func adjust_population_role_percentage(role:String,delta:float) -> void:
	if role not in POPULATION_ROLES: return
	var current:=clampf(float(population_allocation_percentages.get(role,0.0)),0.0,100.0)
	var target:=clampf(current+delta,0.0,82.0)
	var other_total:=maxf(0.0,100.0-current)
	var remaining:=100.0-target
	if other_total<=0.001:
		var share:=remaining/float(POPULATION_ROLES.size()-1)
		for other in POPULATION_ROLES:
			if other!=role: population_allocation_percentages[other]=share
	else:
		for other in POPULATION_ROLES:
			if other==role: continue
			population_allocation_percentages[other]=maxf(0.0,float(population_allocation_percentages.get(other,0.0))*remaining/other_total)
	population_allocation_percentages[role]=target
	synchronize_population_allocations()
