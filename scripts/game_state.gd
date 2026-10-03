extends Node

var civilian_injuries:Dictionary={"limited":0.0,"severe":0.0}

const SOCIETAL_VALUES_MODEL:=preload("res://scripts/societal_values_model.gd")
const EARLY_CARE:=preload("res://scripts/early_life_conditions.gd")
const CRISIS_BACKGROUND:=preload("res://scripts/crisis_background.gd")
const TRACE:=preload("res://scripts/performance_trace.gd")
## Pregnancies under way at founding, as a share of the baseline annual
## conceptions: about 0.65 of the baseline is conceived in ordinary founding
## conditions, and a pregnancy lasts about three quarters of a year.
const FOUNDING_PREGNANCY_SHARE:=0.5
## The founders' ages: those who set out to found a people are young families
## (children, and parents in their twenties and thirties), not a settled
## village's full mix. Close to the mix a growing pre-modern people settles
## into (life expectancy about 28, growth about half a percent): a third
## children, a few of the old. The older mix (a fifth past 45, 18% of them
## 45-60) made the first decades' deaths those of founders growing old, and a
## healthy, fed band shrank for twenty years. Shares of POPULATION_AGE_COHORTS.
const FOUNDING_AGE_MIX:={"children":0.36,"youth":0.21,"early_adults":0.17,"established_adults":0.12,"mature_adults":0.10,"elders":0.04}
## Girls among the newborn, and women among the grown of a people nobody has
## culled: the share the birth model reads its mothers against.
const BIRTH_FEMALE_SHARE:=0.495
## The women in each age cohort, kept only once a people's women and men have
## been struck apart (a killing or a flight of one sex: ensure_female_cohorts):
## "female_children", "female_youth"... Ordinary peoples keep none and read
## BIRTH_FEMALE_SHARE of every cohort, exactly as before.
const FEMALE_PREFIX:="female_"

const POPULATION_ROLES := ["Food","Survey","Extraction","Construction","Crafting","Logistics","Knowledge","Administration","Defense"]
const PRODUCTIVE_POPULATION_ROLES := ["Food","Survey","Extraction","Construction","Crafting","Logistics"]
const SUPPORT_POPULATION_ROLES := ["Knowledge","Administration"]
const POPULATION_FUNCTIONS := ["productive","support","mobilized","dependent","absent"]
const POPULATION_AGE_COHORTS := ["children","youth","early_adults","established_adults","mature_adults","elders"]
const POPULATION_COHORT_DURATIONS_DAYS := {
	"children":5110.0,"youth":4015.0,"early_adults":3650.0,
	"established_adults":3650.0,"mature_adults":5475.0,"elders":6205.0
}
const POPULATION_COHORT_AGE_RANGES := {
	"children":Vector2(0.0,14.0),"youth":Vector2(14.0,25.0),"early_adults":Vector2(25.0,35.0),
	"established_adults":Vector2(35.0,45.0),"mature_adults":Vector2(45.0,60.0),"elders":Vector2(60.0,85.0)
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

var opponent_count := 12
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
## The god's own orders and how each is carried out (order_tracker.gd): the
## fail-safe cards at the bottom right. Bounded; an older save loads empty.
var order_tracker: Dictionary = {}
## Bounded, persistent exchanges between the player and named settlement
## leaders. The API may interpret the player's language, but only deterministic
## government and consequence code can add a commitment or change simulation
## state. Keys are settlement ids; values are newest-last dialogue records.
var civic_dialogues: Dictionary = {}
## Player-facing interpreter routing preference. When true, CIVICS bypasses
## both the deterministic fast reply and semantic cache whenever an API route
## is configured. The simulation's deterministic feasibility gate still owns
## every actual consequence.
var civic_always_use_ai := true
## Master player switch for paid civic interpretation. This is distinct from
## SMART / ALWAYS ASK AI routing: when false, no civic API request may leave
## the game even if credentials are present.
var civic_api_enabled := true
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
var society_exchange:Dictionary=preload("res://scripts/society_exchange.gd").empty_state()
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
var technology_operations:Dictionary=preload("res://scripts/technology_operations.gd").empty_state()
var research_notification_mode:="milestones"
var discovery_log: Array[Dictionary] = []
var active_observations: Array[String] = []
var research_targets:Dictionary={}
## Accumulated scholarship in game-year equivalents; -1 until established.
var scholarship_level:=-1.0
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
## What all our towns together are called, once there are two (nation_name.gd); "" until named.
var nation_name := ""
## What makes our people's own tongue ({family, seed, v, world_seed};
## people_language.gd). Empty in older saves: made again from the world seed.
var people_language:Dictionary={}
var settlement_founded_day := -1
var settlement_plots:Array[Dictionary]=[]
var settlement_nuclei:Array[Dictionary]=[]
var settlement_routes:Array[Dictionary]=[]
var settlement_morphology:Dictionary={}
var settlement_plot_history:Array[Dictionary]=[]
## Permanent, append-only architectural record. Unlike settlement_plot_history,
## this is player history rather than bounded rendering telemetry: one row is a
## meaningful construction/lifecycle event, never a daily simulation sample.
var building_ledger:Array[Dictionary]=[]
var next_building_record_id:=1
var next_settlement_plot_id:=1
var next_settlement_nucleus_id:=1
## A bounded aggregate settlement network. One record represents an entire
## settlement regardless of population; no resident entities are created.
var player_settlements:Array[Dictionary]=[]
var next_player_settlement_id:=1
## The settlement currently addressed by the map and settlement dock. This is
## an id, never a scene node, so selecting one of hundreds of places remains
## constant-size state and survives saving/loading.
var resource_settlement_id:String=""
var city_trade_shipments:Array[Dictionary]=[]
var city_trade_history:Array[Dictionary]=[]
var last_city_trade_day:int=-1
var next_city_trade_id:int=1
var selected_player_settlement_id:=""
var settlement_convoy:Dictionary={}
var settlement_network_revision:=0
## A city's construction era (fabric tier) and overall condition; its built
## capacities derive from these and its population (SettlementModel.city_form).
var city_form:Dictionary={"tier":-1.0,"condition":-1.0}
## [built-fabric] The town's built fabric (built_fabric.gd): its homes by
## grade, roads, fine works and work buildings; each town its own
## (settlement_model.gd CITY_RESOURCE_DEFAULTS). {} until first reckoned.
var built_fabric:Dictionary={}
## [built-fabric] The whole people's builders' craft and each town's last
## fabric reading (built_fabric.gd realm_data); never swapped per town.
var fabric_realm:Dictionary={}
var morphology_revision:=0
var last_morphology_day:=-1
var resource_deposits: Array[Dictionary] = []
var resource_stockpiles: Dictionary = {}
var civilian_goods:Dictionary=preload("res://scripts/civilian_goods.gd").empty_state()
var opening_opportunities:Dictionary=preload("res://scripts/opening_opportunities.gd").empty_state()
var resource_events: Array[Dictionary] = []
var resource_practice: Dictionary = {}
var resource_priorities: Dictionary = {}
## The land searched (resource_system.gd land_survey): its cover, the month
## of the last find roll and the finds told. Kept per town (settlement_model).
var land_survey:Dictionary={}
var founding_manifest:Dictionary={}
var economy_stage := "subsistence"
var economy_benchmarks:Dictionary={"subsistence":{"day":0,"from":"founding"}}
var market_prices:Dictionary={}
var economy_metrics:Dictionary={}
var economy_history:Array[Dictionary]=[]
var strategic_history:Dictionary={}
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
## The realm's one purse, the god's account for the whole people
## (realm_purse.gd). Empty in an older save: made whole on first reading.
var realm_purse:Dictionary={}
## The people's business sector (enterprise.gd): its rung, size and the
## god's stance. Empty in an older save: made whole on first reading.
var enterprise:Dictionary={}
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
var fire_practice:Dictionary=preload("res://scripts/fire_practice.gd").empty_state()
var household_clothing:Dictionary=preload("res://scripts/household_clothing.gd").empty_state()
var water_conveyance:Dictionary={"lines":[],"next_id":1,"last_day":-1,"report":{}}
var water_waste_works:Dictionary=preload("res://scripts/water_waste_works_state.gd").empty()
var civilian_care:Dictionary=preload("res://scripts/civilian_care_fabric.gd").empty_state()
var rail_freight:Dictionary=preload("res://scripts/rail_freight_fabric.gd").empty_state()
var food_batches:Dictionary=preload("res://scripts/food_batches.gd").empty_state()
var grain_processing:Dictionary=preload("res://scripts/grain_processing.gd").empty_state()
var microscopy:Dictionary=preload("res://scripts/microscopy_samples.gd").empty_state()
var field_botany:Dictionary=preload("res://scripts/field_botany.gd").empty_state()
var cultivation_nutrients:Dictionary={"nitrogen":0.0,"phosphorus":0.0}
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


func record_building_event(event:Dictionary)->Dictionary:
	## Preserve what people actually built and consumed across the complete run.
	## Callers provide plot/work facts; this normalizes them into a stable schema.
	var row:Dictionary=event.duplicate(true)
	row["id"]=next_building_record_id
	next_building_record_id+=1
	row["day"]=int(row.get("day",floori(elapsed_days)))
	row["settlement_id"]=String(row.get("settlement_id",selected_player_settlement_id))
	if String(row.settlement_id)=="" and not player_settlements.is_empty():
		for settlement in player_settlements:
			if bool((settlement as Dictionary).get("primary",false)):
				row["settlement_id"]=String((settlement as Dictionary).get("id",""))
				break
	row["settlement_name"]=String(row.get("settlement_name",settlement_name if settlement_name!="" else "The founding settlement"))
	row["event"]=String(row.get("event","recorded"))
	row["kind"]=String(row.get("kind",row.get("form",row.get("land_use","Building"))))
	row["form"]=String(row.get("form",row.kind))
	row["land_use"]=String(row.get("land_use",""))
	row["roof_plan"]=String(row.get("roof_plan",""))
	row["material_family"]=String(row.get("material_family",""))
	row["materials"]=(row.get("materials",{}) as Dictionary).duplicate(true)
	row["counts_materials"]=bool(row.get("counts_materials",false))
	building_ledger.append(row)
	return row


func ensure_building_ledger()->void:
	## Old saves predate the permanent ledger. Reconstruct honest surviving facts
	## once, explicitly marking quantities that the old save never retained.
	if not building_ledger.is_empty() or (settlement_completed.is_empty() and settlement_plots.is_empty()): return
	for work_name in settlement_completed:
		record_building_event({
			"day":settlement_founded_day,
			"event":"legacy_completed",
			"kind":String(work_name),
			"form":"communal_work",
			"materials":{},
			"counts_materials":false,
			"note":"Completed before detailed material records began; quantities are unknown.",
			"reconstructed":true,
		})
	for plot in settlement_plots:
		var p:Dictionary=plot
		var materials:Dictionary={}
		for material_name in (p.get("supply_provenance",{}) as Dictionary):
			var amount:Variant=(p.get("supply_provenance",{}) as Dictionary)[material_name]
			if amount is int or amount is float: materials[String(material_name)]=float(amount)
		record_building_event({
			"day":int(p.get("created_day",settlement_founded_day)),
			"event":"legacy_surviving_fabric",
			"plot_id":int(p.get("id",-1)),
			"kind":String(p.get("form",p.get("land_use","Building"))),
			"form":String(p.get("form","")),
			"land_use":String(p.get("land_use","")),
			"roof_plan":String(p.get("roof_plan","")),
			"material_family":String(p.get("material_family","")),
			"materials":materials,
			"counts_materials":not materials.is_empty(),
			"condition":float(p.get("condition",1.0)),
			"status":String(p.get("status","active")),
			"note":"Surviving fabric reconstructed from an older save.",
			"reconstructed":true,
		})


func building_ledger_summary(settlement_id:String="")->Dictionary:
	ensure_building_ledger()
	var materials:Dictionary={}
	var kinds:Dictionary={}
	var events:Dictionary={}
	var records:Array[Dictionary]=[]
	for row_variant in building_ledger:
		var row:Dictionary=row_variant
		if settlement_id!="" and String(row.get("settlement_id","")) not in ["",settlement_id]: continue
		records.append(row)
		var kind:=String(row.get("kind","Building")).replace("_"," ").capitalize()
		if String(row.get("event","")) in ["founded","started","infilled","rebuilt","legacy_completed","legacy_surviving_fabric"] or (String(row.get("event",""))=="completed" and int(row.get("plot_id",-1))<0):
			kinds[kind]=int(kinds.get(kind,0))+1
		var event_name:=String(row.get("event","recorded"))
		events[event_name]=int(events.get(event_name,0))+1
		if bool(row.get("counts_materials",false)):
			for material_name in (row.get("materials",{}) as Dictionary):
				materials[String(material_name)]=float(materials.get(String(material_name),0.0))+float((row.get("materials",{}) as Dictionary)[material_name])
	return {"records":records,"materials":materials,"kinds":kinds,"events":events}
var demographic_ledger: Array[Dictionary] = []
## Seasonal fold of routine births, deaths and losses (see consequence_engine),
## and the Chronicle: graded story of the people (scripts/chronicle.gd).
var hearth_season:Dictionary={}
var chronicle:Dictionary={}
var lifetime_births := 0
var lifetime_deaths := 0
## Exact daily vital counts retained for rolling population statistics. Older
## saves fall back to their demographic ledger until new tracking begins.
var vital_statistics_history: Array[Dictionary] = []
var vital_statistics_tracking_start_day := -1
## Deaths by cause, the whole people's, a row a day and cause ({day, cause,
## count}) for the last DEATH_CAUSE_DAYS (rolling_death_causes): every death
## the people registers, ordinary or not (fires, war, executions, the road),
## so the People card names what really took them. Not swapped into a town's
## scope: a town's deaths are the people's.
var death_cause_days: Array[Dictionary] = []
## Monthly life-expectancy observations. Meaningful changes carry either the
## health discovery that occurred in the interval or an explicit conditions
## marker, so the chart never implies that every change came from research.
var health_history: Array[Dictionary] = []
## Monthly record of the twelve capacities and why each moved
## (scripts/capacity_history.gd). Older saves start empty.
var capacity_history:Dictionary={}
var death_progress := 0.0
var consecutive_food_shortage_days := 0.0
var consecutive_water_shortage_days := 0.0
var founding_journey:Dictionary={}
var convoy_traveling := false
var convoy_exposure_days := 0.0
var convoy_emergency_halt_reason := ""
var population_cohorts: Dictionary = {}
var pregnancy_cohorts:Dictionary={"first_trimester":0.0,"second_trimester":0.0,"third_trimester":0.0,"postpartum":0.0}
var demographic_remainders:Dictionary={"conceptions":0.0,"births":0.0,"pregnancy_losses":0.0,"stillbirths":0.0,"maternal_deaths":0.0,"neonatal_deaths":0.0}
var mortality_by_age_cohort:Dictionary={}
# --- Early care and living conditions (early_life_conditions.gd) ---
## Excess infant, child, adult, birth and conception factors from missing early
## practices, diet and overwork. Refreshed daily by ConsequenceEngine.
var early_care:Dictionary={}
## 0 for a save written before these rules; rises to 1 over two game years.
var early_care_blend:=0.0
# --- end early care ---
## The exceptional death risks (hunger, sickness, exposure, thirst, insecurity,
## work) averaged over about a month, for "how long a child born now can hope
## to live". The day's own risks swing: one wet day resets a village's run of
## short water, one storm, one hard day at the pits. Read raw, a lucky day on
## the monthly count showed as three winters gained and lost again. Deaths
## still happen at each day's own risk; only the projection is steadied.
## Below zero until the first day is counted (then it starts from that day).
var exceptional_hazard_smoothed:=-1.0
## The same month-long mean for each exceptional cause of death (hunger,
## illness, exposure...), so a change in how long we live can be told by cause.
var exceptional_hazard_causes_smoothed:Dictionary={}
var last_population_removal_by_cohort:Dictionary={}
var observed_death_age_sum:=0.0
var lifetime_conceptions := 0
var lifetime_pregnancy_losses := 0
var lifetime_stillbirths := 0
var lifetime_maternal_deaths := 0
var lifetime_neonatal_deaths := 0

func reset_for_new_world(new_seed:int)->void:
	if WorldSimulation.actor_id=="player":WorldSimulation.clear()
	civilian_injuries={"limited":0.0,"severe":0.0}
	for system_name in ["HistoricalFigures","PeopleDirection","CommunityNetwork","GeneralCampaign"]:
		var system:=WorldSimulation.system(system_name)
		if system: system.reset_for_new_world()
	var foreign:=WorldSimulation.system("ForeignDiplomacy")
	if foreign: foreign.reset_for_new_world()
	resource_settlement_id=""
	opening_opportunities=preload("res://scripts/opening_opportunities.gd").empty_state()
	city_trade_shipments=[]
	city_trade_history=[]
	last_city_trade_day=-1
	next_city_trade_id=1
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
	order_tracker={}
	civic_dialogues={}
	civic_always_use_ai=true
	civic_api_enabled=true
	research_allocations={"demography":0,"nutrition":1,"health":1,"labor":0,"knowledge":1,"production":0,"infrastructure":0,"logistics":0,"ecology":1,"institutions":0,"security":0,"culture":0}
	research_subcategory_allocations={
		"demography":{"Fertility conditions":0,"Maternal safety":0,"Child survival":0,"Shelter capacity":0},"nutrition":{"Daily supply":1,"Diet quality":0,"Stored reserve":0,"Land productivity":0},
		"health":{"General health":0,"Water & sanitation":0,"Disease control":0,"Injury safety":1},"labor":{"Able workforce":0,"Work efficiency":0,"Coordination":0,"Workload balance":0},
		"knowledge":{"Observers":0,"Directed attention":0,"Preserved knowledge":1,"Communication":0},"production":{"Material supply":0,"Tool quality":0,"Craft capacity":0,"Standardization":0},
		"infrastructure":{"Housing":0,"Construction":0,"Public works":0,"Resilience":0},"logistics":{"Carrying capacity":0,"Route quality":0,"Storage system":0,"Trade reach":0},
		"ecology":{"Land health":1,"Natural recovery":0,"Pollution control":0,"Resource sustainability":0},"institutions":{"Administration":0,"Legitimacy":0,"State capacity":0,"Institutional flexibility":0},
		"security":{"Public safety":0,"Organized defense":0,"Military readiness":0,"Crisis resilience":0},"culture":{"Social cohesion":0,"Shared legitimacy":0,"Inquiry breadth":0,"Collective memory":0}
	}
	society_exchange=preload("res://scripts/society_exchange.gd").empty_state()
	known_discoveries=preload("res://scripts/founding_knowledge.gd").PRACTICES.duplicate()
	discovery_adoption=preload("res://scripts/founding_knowledge.gd").adoption()
	knowledge_effects={}
	society_capacities={"demography":0.5,"nutrition":0.5,"health":0.5,"labor":0.5,"knowledge":0.18,"production":0.12,"infrastructure":0.05,"logistics":0.16,"ecology":0.88,"institutions":0.25,"security":0.38,"culture":0.58}
	society_subcategories={}
	societal_values=SOCIETAL_VALUES_MODEL.initial_state("",world_seed,"player")
	combined_intelligence=0.18
	technology_operations=preload("res://scripts/technology_operations.gd").empty_state()
	research_notification_mode="milestones"
	discovery_log=[]
	active_observations=[]
	research_targets={}
	scholarship_level=-1.0
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
	nation_name=""
	settlement_founded_day=-1
	settlement_plots=[]
	settlement_nuclei=[]
	settlement_routes=[]
	settlement_morphology={}
	settlement_plot_history=[]
	building_ledger=[]
	next_building_record_id=1
	next_settlement_plot_id=1
	next_settlement_nucleus_id=1
	player_settlements=[]
	next_player_settlement_id=1
	selected_player_settlement_id=""
	settlement_convoy={}
	settlement_network_revision=0
	city_form={"tier":-1.0,"condition":-1.0}
	built_fabric={}
	fabric_realm={}
	morphology_revision=0
	last_morphology_day=-1
	resource_deposits=[]
	resource_stockpiles={}
	civilian_goods=preload("res://scripts/civilian_goods.gd").empty_state()
	resource_events=[]
	resource_practice={}
	resource_priorities={}
	land_survey={}
	founding_manifest={}
	economy_stage="subsistence"
	economy_benchmarks={"subsistence":{"day":0,"from":"founding"}}
	market_prices={}
	economy_metrics={}
	economy_history=[]
	strategic_history={}
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
	realm_purse={}
	enterprise={}
	external_trade_credit=0.0
	external_trade_exports=0.0
	external_trade_imports=0.0
	external_trade_losses=0.0
	material_metrics={"extracted_today":0.0,"delivered_today":0.0,"lost_today":0.0,"at_source":0.0,"in_transit":0.0,"stored_bulk":0.0,"storage_capacity":0.0,"flow_ratio":0.0}
	material_history=[]
	water_metrics={"stored":0.0,"capacity":0.0,"collected_today":0.0,"required_today":0.0,"consumed_today":0.0,"intake_ratio":0.0,"days":0.0,"source_accessible":false}
	water_history=[]
	food_stocks={}
	fire_practice=preload("res://scripts/fire_practice.gd").empty_state()
	household_clothing=preload("res://scripts/household_clothing.gd").empty_state()
	water_conveyance={"lines":[],"next_id":1,"last_day":-1,"report":{}}
	water_waste_works=preload("res://scripts/water_waste_works_state.gd").empty()
	civilian_care=preload("res://scripts/civilian_care_fabric.gd").empty_state()
	rail_freight=preload("res://scripts/rail_freight_fabric.gd").empty_state()
	food_batches=preload("res://scripts/food_batches.gd").empty_state()
	grain_processing=preload("res://scripts/grain_processing.gd").empty_state()
	microscopy=preload("res://scripts/microscopy_samples.gd").empty_state()
	field_botany=preload("res://scripts/field_botany.gd").empty_state()
	cultivation_nutrients={"nitrogen":0.0,"phosphorus":0.0}
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
	hearth_season={}
	chronicle={}
	lifetime_births=0
	lifetime_deaths=0
	vital_statistics_history=[]
	vital_statistics_tracking_start_day=-1
	death_cause_days=[]
	health_history=[]
	capacity_history={}
	lifetime_departures=0
	death_progress=0.0
	consecutive_food_shortage_days=0.0
	consecutive_water_shortage_days=0.0
	founding_journey={}
	convoy_traveling=false
	convoy_exposure_days=0.0
	convoy_emergency_halt_reason=""
	population_cohorts={}
	pregnancy_cohorts={"first_trimester":0.0,"second_trimester":0.0,"third_trimester":0.0,"postpartum":0.0}
	demographic_remainders={"conceptions":0.0,"births":0.0,"pregnancy_losses":0.0,"stillbirths":0.0,"maternal_deaths":0.0,"neonatal_deaths":0.0}
	mortality_by_age_cohort={}
	early_care={}
	early_care_blend=0.0
	exceptional_hazard_smoothed=-1.0
	exceptional_hazard_causes_smoothed={}
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
	if focus_id=="collective_ambition": return {"name":String(PeopleDirection.AMBITIONS.get(WorldSimulation.direction.ambition,{}).get("name","Collective ambition")),"effects":{},"description":"Our people are pursuing a shared direction."}
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
	population_cohorts={}
	for key in POPULATION_AGE_COHORTS:population_cohorts[key]=total*float(FOUNDING_AGE_MIX.get(key,0.0))
	var reproductive_population:=_reproductive_age_population()
	# fun-pop: the founders arrive already carrying the pregnancies of their
	# usual conception rate, about FOUNDING_PREGNANCY_SHARE of the baseline
	# annual conceptions (process_reproduction_day). The old seed (4.5% of the
	# reproductive weight, about 1.2 pregnancies among 120 people) left the
	# first year with half its births and cost the band 2-3 people for nothing.
	var baseline_annual:=float(population_cohorts.youth)*0.45*0.23+float(population_cohorts.early_adults)*0.50*0.285+float(population_cohorts.established_adults)*0.45*0.18+float(population_cohorts.mature_adults)*0.16*0.040
	var seeded_pregnancies:=baseline_annual*FOUNDING_PREGNANCY_SHARE
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
	# Reads and loads revisit this method. Do not rescale already conserved
	# cohorts for floating-point summation noise; that made inspection mutate them.
	var by_sex:=has_female_cohorts()
	if absf(current-target)>maxf(1.0,target)*1e-12:
		var scale:=target/current
		for key in POPULATION_AGE_COHORTS:
			population_cohorts[key]=maxf(0.0,float(population_cohorts.get(key,0.0))*scale)
			if by_sex: population_cohorts[FEMALE_PREFIX+key]=float(population_cohorts.get(FEMALE_PREFIX+key,0.0))*scale
	if by_sex:
		for key in POPULATION_AGE_COHORTS:
			population_cohorts[FEMALE_PREFIX+key]=clampf(float(population_cohorts.get(FEMALE_PREFIX+key,0.0)),0.0,float(population_cohorts.get(key,0.0)))
	_refresh_population_summary()

func _refresh_population_summary() -> void:
	var working:=0.0
	for key in ["youth","early_adults","established_adults","mature_adults"]:
		working+=float(population_cohorts.get(key,0.0))
	population_cohorts["working_age"]=working
	# Preserve demographic imbalance caused by targeted migration, war, or policy.
	# Older saves have no durable sex totals, so only those saves receive the
	# founding estimate. Ordinary normalization then keeps both totals conserved.
	var female:=maxf(0.0,float(population_cohorts.get("female",0.0)))
	var male:=maxf(0.0,float(population_cohorts.get("male",0.0)))
	var sex_total:=female+male
	if has_female_cohorts():
		# The women by age are the count; the totals are read from them.
		female=0.0
		for key in POPULATION_AGE_COHORTS: female+=float(population_cohorts.get(FEMALE_PREFIX+key,0.0))
		female=clampf(female,0.0,population_exact)
		male=population_exact-female
	elif sex_total<=0.000001:
		female=population_exact*0.495
		male=population_exact-female
	elif absf(sex_total-population_exact)>maxf(1.0,population_exact)*1e-12:
		var sex_scale:=population_exact/sex_total
		female*=sex_scale
		male*=sex_scale
	population_cohorts["female"]=female
	population_cohorts["male"]=male
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
	# The women of child-bearing ages: each cohort's share of mothers against an
	# ordinary cohort's (1 unless its women were killed or driven off; girls and
	# old women are never counted; men lost never change it).
	return float(population_cohorts.get("youth",0.0))*0.45*_mothers_ratio("youth")+float(population_cohorts.get("early_adults",0.0))*0.50*_mothers_ratio("early_adults")+float(population_cohorts.get("established_adults",0.0))*0.45*_mothers_ratio("established_adults")+float(population_cohorts.get("mature_adults",0.0))*0.16*_mothers_ratio("mature_adults")

func _fertile_age_weight() -> float:
	return float(population_cohorts.get("youth",0.0))*0.45+float(population_cohorts.get("early_adults",0.0))*0.50+float(population_cohorts.get("established_adults",0.0))*0.45+float(population_cohorts.get("mature_adults",0.0))*0.16

func has_female_cohorts() -> bool:
	return population_cohorts.has(FEMALE_PREFIX+"children")

func ensure_female_cohorts() -> void:
	## Begin keeping the women of each age cohort (before a killing or a flight
	## of one sex): every cohort gets the realm's own share of women.
	if has_female_cohorts() or population_cohorts.is_empty(): return
	var female:=float(population_cohorts.get("female",0.0))
	var male:=float(population_cohorts.get("male",0.0))
	var share:=clampf(female/(female+male),0.0,1.0) if female+male>0.000001 else BIRTH_FEMALE_SHARE
	for key in POPULATION_AGE_COHORTS: population_cohorts[FEMALE_PREFIX+key]=maxf(0.0,float(population_cohorts.get(key,0.0)))*share

func women_in(cohorts:Array) -> float:
	## The women among these age cohorts, from the population model.
	var total:=0.0
	var by_sex:=has_female_cohorts()
	var share:=float(population_cohorts.get("female",0.0))/maxf(0.000001,population_exact) if population_cohorts.has("female") else BIRTH_FEMALE_SHARE
	for key in cohorts:
		var n:=maxf(0.0,float(population_cohorts.get(String(key),0.0)))
		total+=clampf(float(population_cohorts.get(FEMALE_PREFIX+String(key),0.0)),0.0,n) if by_sex else n*share
	return total

func _mothers_ratio(cohort:String) -> float:
	if not has_female_cohorts(): return 1.0
	var n:=float(population_cohorts.get(cohort,0.0))
	if n<=0.000001: return 1.0
	var r:=maxf(0.0,float(population_cohorts.get(FEMALE_PREFIX+cohort,0.0)))/(BIRTH_FEMALE_SHARE*n)
	return 1.0 if absf(r-1.0)<1e-9 else r

func fertile_women() -> float:
	## Women of an age to bear children (the birth model's own reckoning).
	return _reproductive_age_population()

func fertile_women_factor() -> float:
	## The mothers a people has against an ordinary people of its size and ages:
	## 1 unless its women of child-bearing ages were killed or driven off.
	var base:=_fertile_age_weight()
	if base<=0.000001: return 1.0
	var factor:=_reproductive_age_population()/base
	return 1.0 if absf(factor-1.0)<1e-9 else factor

func lose_pregnancies(share:float) -> float:
	## Mothers-to-be killed or driven off take their pregnancies with them:
	## that share of every stage is gone. Returns the pregnancies lost.
	var s:=clampf(share,0.0,1.0)
	if s<=0.0: return 0.0
	var lost:=0.0
	for key in ["first_trimester","second_trimester","third_trimester","postpartum"]:
		var v:=float(pregnancy_cohorts.get(key,0.0))
		if key!="postpartum": lost+=v*s
		pregnancy_cohorts[key]=v*(1.0-s)
	return lost

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
	# research_600 balance: chronic shortfall lowers conception less than famine
	# does (sqrt response), so a hungry pre-modern society shrinks, not vanishes.
	var factor:=lerpf(0.12,1.08,health)*lerpf(0.10,1.05,sqrt(food))*lerpf(0.55,1.03,housing)*lerpf(0.82,1.04,cohesion)
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
		var before:=float(population_cohorts.get(source,0.0))
		var moving:=before/float(POPULATION_COHORT_DURATIONS_DAYS[source])
		population_cohorts[source]=maxf(0.0,before-moving)
		population_cohorts[destination]=float(population_cohorts.get(destination,0.0))+moving
		if has_female_cohorts() and before>0.000001:
			var women:=float(population_cohorts.get(FEMALE_PREFIX+source,0.0))*moving/before
			population_cohorts[FEMALE_PREFIX+source]=maxf(0.0,float(population_cohorts.get(FEMALE_PREFIX+source,0.0))-women)
			population_cohorts[FEMALE_PREFIX+destination]=float(population_cohorts.get(FEMALE_PREFIX+destination,0.0))+women

func _accumulate_demographic_count(key:String,amount:float) -> int:
	var accumulated:=maxf(0.0,float(demographic_remainders.get(key,0.0))+maxf(0.0,amount))
	var emitted:=floori(accumulated)
	demographic_remainders[key]=accumulated-float(emitted)
	return emitted

func _mortality_weights_for(cause:String) -> Dictionary:
	match cause:
		# These are proportional age-specific hazards, paired with
		# current_natural_mortality_rate(). Previously the total was nearly flat
		# and this ratio was too shallow, allowing the 60+ cohort to accumulate
		# while projected life expectancy remained low.
		"Natural causes":
			# Early care changes which ages die: follow the current life table.
			if early_care_blend>0.0 and not early_care.is_empty(): return _background_cohort_hazards()
			return {"children":1.0,"youth":0.36,"early_adults":0.50,"established_adults":0.75,"mature_adults":2.20,"elders":10.0}
		"Hunger": return {"children":2.2,"youth":0.8,"early_adults":0.7,"established_adults":0.8,"mature_adults":1.2,"elders":2.0}
		"Illness","Dehydration","Exposure": return {"children":1.8,"youth":0.7,"early_adults":0.7,"established_adults":0.9,"mature_adults":1.4,"elders":2.6}
		"Travel exhaustion": return {"children":1.3,"youth":1.1,"early_adults":1.2,"established_adults":1.2,"mature_adults":1.5,"elders":2.1}
		"Insecurity","Killed in battle": return {"children":0.2,"youth":1.2,"early_adults":1.8,"established_adults":1.7,"mature_adults":1.1,"elders":0.3}
		"Complications of childbirth": return {"children":0.0,"youth":1.2,"early_adults":2.0,"established_adults":1.5,"mature_adults":0.4,"elders":0.0}
		"Neonatal complications": return {"children":1.0,"youth":0.0,"early_adults":0.0,"established_adults":0.0,"mature_adults":0.0,"elders":0.0}
		_: return {"children":0.8,"youth":0.25,"early_adults":0.32,"established_adults":0.55,"mature_adults":1.25,"elders":3.2}

func _remove_population_exact(amount:float,cause:String,weight_override:Dictionary={},record_mortality:bool=true,sex:String="") -> float:
	## sex "female"/"male": only women (or men) of the cohorts are taken, and the
	## women of each cohort are kept from then on (ensure_female_cohorts).
	initialize_population_model()
	if sex in ["female","male"]: ensure_female_cohorts()
	var by_sex:=has_female_cohorts()
	var actual:=clampf(amount,0.0,maxf(0.0,population_exact-1.0))
	last_population_removal_by_cohort={}
	if actual<=0.0: return 0.0
	var weights:=weight_override.duplicate(true) if not weight_override.is_empty() else _mortality_weights_for(cause)
	var remaining:=actual
	var midpoints:={"children":7.0,"youth":19.0,"early_adults":29.5,"established_adults":39.5,"mature_adults":52.0,"elders":68.5}
	# Redistribute capped shares across the six fixed cohorts. This remains O(1)
	# at a population of 120 or 12 billion and accounts for every numeric death.
	for _pass in POPULATION_AGE_COHORTS.size()+1:
		if remaining<=0.000001: break
		var weighted_total:=0.0
		for key in POPULATION_AGE_COHORTS:
			var available:=_removable(key,sex)
			if available>0.000001: weighted_total+=available*maxf(0.0,float(weights.get(key,1.0)))
		var use_fallback:=weighted_total<=0.000001
		if use_fallback:
			for key in POPULATION_AGE_COHORTS: weighted_total+=_removable(key,sex)
		if weighted_total<=0.000001: break
		var pass_remaining:=remaining
		var removed_this_pass:=0.0
		for key in POPULATION_AGE_COHORTS:
			var available:=_removable(key,sex)
			if available<=0.000001: continue
			var basis:=available if use_fallback else available*maxf(0.0,float(weights.get(key,1.0)))
			if basis<=0.0: continue
			var removed:=minf(available,pass_remaining*basis/weighted_total)
			var cohort_before:=float(population_cohorts.get(key,0.0))
			population_cohorts[key]=maxf(0.0,cohort_before-removed)
			if by_sex:
				var women:=float(population_cohorts.get(FEMALE_PREFIX+key,0.0))
				var women_gone:=removed if sex=="female" else (0.0 if sex=="male" else (women*removed/cohort_before if cohort_before>0.000001 else 0.0))
				population_cohorts[FEMALE_PREFIX+key]=maxf(0.0,women-women_gone)
			last_population_removal_by_cohort[key]=float(last_population_removal_by_cohort.get(key,0.0))+removed
			if record_mortality:
				mortality_by_age_cohort[key]=float(mortality_by_age_cohort.get(key,0.0))+removed
				observed_death_age_sum+=removed*float(midpoints[key])
			removed_this_pass+=removed
		remaining=maxf(0.0,remaining-removed_this_pass)
		if removed_this_pass<=0.000001: break
	var removed_total:=actual-remaining
	if cause!="Killed in battle" and resource_settlement_id.is_empty():
		var survival:=clampf(1.0-removed_total/maxf(1.0,population_exact),0,1)
		for severity in civilian_injuries: civilian_injuries[severity]*=survival
	population_exact=maxf(1.0,population_exact-removed_total)
	_normalize_population_cohorts()
	if TRACE.enabled and self==GameState:TRACE.flow("death" if record_mortality else "departure",cause,removed_total)
	return removed_total

## What of a cohort a removal may take: all of it, or its women, or its men.
func _removable(key:String,sex:String) -> float:
	var n:=maxf(0.0,float(population_cohorts.get(key,0.0)))
	if not sex in ["female","male"] or not has_female_cohorts(): return n
	var women:=clampf(float(population_cohorts.get(FEMALE_PREFIX+key,0.0)),0.0,n)
	return women if sex=="female" else n-women

var lifetime_departures := 0

func register_population_departures(count:int,reason:String,age_weights:Dictionary={},sex:String="") -> Dictionary:
	## People who leave the civilization alive — staying with foreign bands,
	## marrying out. Reduces the population without touching mortality records.
	## sex "female"/"male": only women (or men) left, and the realm's count of
	## each says so (as register_directive_population_deaths keeps it).
	initialize_population_model()
	var actual:=mini(maxi(0,count),maxi(0,population_total-1))
	if sex in ["female","male"]:
		ensure_female_cohorts()
		var eligible:=0.0
		for key in POPULATION_AGE_COHORTS:
			if age_weights.is_empty() or float(age_weights.get(key,0.0))>0.0: eligible+=_removable(key,sex)
		actual=mini(actual,floori(eligible+0.000001))
	var removed:=_remove_population_exact(float(actual),reason,age_weights,false,sex)
	var emitted:=roundi(removed)
	lifetime_departures+=emitted
	synchronize_population_allocations()
	return {"count":emitted,"reason":reason,"population_after":population_total}

func register_population_deaths(count:int,cause:String) -> Dictionary:
	initialize_population_model()
	var actual:=mini(maxi(0,count),maxi(0,population_total-1))
	var removed:=_remove_population_exact(float(actual),cause)
	var emitted:=roundi(removed)
	var affected_cohorts:=last_population_removal_by_cohort.duplicate(true)
	lifetime_deaths+=emitted
	_record_vital_statistics(0,emitted)
	record_death_cause(cause,emitted)
	synchronize_population_allocations()
	return {"count":emitted,"cause":cause,"affected_cohorts":affected_cohorts,"population_after":population_total}

func _record_vital_statistics(births:int,deaths:int)->void:
	var safe_births:=maxi(0,births)
	var safe_deaths:=maxi(0,deaths)
	if safe_births==0 and safe_deaths==0: return
	var day:=floori(elapsed_days)
	if vital_statistics_tracking_start_day<0: vital_statistics_tracking_start_day=day
	if not vital_statistics_history.is_empty() and int(vital_statistics_history[-1].get("day",-1))==day:
		vital_statistics_history[-1]["births"]=int(vital_statistics_history[-1].get("births",0))+safe_births
		vital_statistics_history[-1]["deaths"]=int(vital_statistics_history[-1].get("deaths",0))+safe_deaths
	else:
		vital_statistics_history.append({"day":day,"births":safe_births,"deaths":safe_deaths})
	# Two years of daily bins are enough for a true trailing-year display while
	# keeping long-running saves compact.
	var retention_cutoff:=day-730
	while not vital_statistics_history.is_empty() and int(vital_statistics_history[0].get("day",day))<retention_cutoff:
		vital_statistics_history.pop_front()

## Days of deaths by cause kept (death_cause_days).
const DEATH_CAUSE_DAYS:=400

## Counts `count` deaths of `cause` today (death_cause_days).
func record_death_cause(cause:String,count:int)->void:
	if count<=0:return
	var day:=floori(elapsed_days)
	var name:=cause if cause!="" else "Hardship"
	if not death_cause_days.is_empty():
		var last:Dictionary=death_cause_days[-1]
		if int(last.get("day",-1))==day and String(last.get("cause",""))==name:
			last["count"]=int(last.get("count",0))+count
			return
	death_cause_days.append({"day":day,"cause":name,"count":count})
	while not death_cause_days.is_empty() and int(death_cause_days[0].get("day",day))<day-DEATH_CAUSE_DAYS:death_cause_days.pop_front()

## Moves `count` of today's deaths kept under `from` to `to` (the share of a
## day's deaths that was another cause's: consequence_engine.gd).
func reclassify_death_cause(from:String,to:String,count:int)->void:
	if count<=0 or death_cause_days.is_empty():return
	var day:=floori(elapsed_days)
	for index in range(death_cause_days.size()-1,-1,-1):
		var row:Dictionary=death_cause_days[index]
		if int(row.get("day",-1))!=day:break
		if String(row.get("cause",""))!=from:continue
		var moved:=mini(count,int(row.get("count",0)))
		row["count"]=int(row.count)-moved
		if int(row.count)<=0:death_cause_days.remove_at(index)
		record_death_cause(to,moved)
		return

## Deaths by cause in the trailing `days` ({cause: count}).
func rolling_death_causes(days:int=365)->Dictionary:
	var cutoff:=floori(elapsed_days)-maxi(1,days)+1
	var out:={}
	for row:Dictionary in death_cause_days:
		if int(row.get("day",-1))<cutoff:continue
		out[String(row.cause)]=int(out.get(String(row.cause),0))+int(row.get("count",0))
	return out

func rolling_vital_balance(days:int=365)->Dictionary:
	## Actual births and deaths during the trailing window. For an older save,
	## pre-tracker history is reconstructed from its aggregate demographic
	## episodes, prorating only an episode that crosses the window boundary.
	var window_days:=maxi(1,days)
	var today:=floori(elapsed_days)
	var cutoff:=today-window_days+1
	var births_exact:=0.0
	var deaths_exact:=0.0
	for row_variant in vital_statistics_history:
		var row:Dictionary=row_variant
		var row_day:=int(row.get("day",-1))
		if row_day<cutoff or row_day>today: continue
		births_exact+=float(row.get("births",0))
		deaths_exact+=float(row.get("deaths",0))
	var legacy_last_day:=today if vital_statistics_tracking_start_day<0 else vital_statistics_tracking_start_day-1
	if legacy_last_day>=cutoff:
		for record_variant in demographic_ledger:
			var record:Dictionary=record_variant
			var kind:=String(record.get("kind",""))
			if kind not in ["birth","death"]: continue
			var start_day:=int(record.get("start_day",record.get("day",today)))
			var end_day:=int(record.get("end_day",record.get("day",start_day)))
			var overlap_start:=maxi(cutoff,start_day)
			var overlap_end:=mini(legacy_last_day,end_day)
			if overlap_end<overlap_start: continue
			var episode_days:=maxi(1,end_day-start_day+1)
			var overlap_days:=overlap_end-overlap_start+1
			var represented:=float(record.get("count",0))*float(overlap_days)/float(episode_days)
			if kind=="birth": births_exact+=represented
			else: deaths_exact+=represented
	var births:=roundi(births_exact)
	var deaths:=roundi(deaths_exact)
	return {"births":births,"deaths":deaths,"net":births-deaths,"days":window_days}

func record_health_history(force:bool=false)->void:
	var day:=floori(elapsed_days)
	var life_expectancy:=projected_life_expectancy()
	var last_day:=-1
	var previous_expectancy:=life_expectancy
	if not health_history.is_empty():
		last_day=int(health_history[-1].get("day",day))
		previous_expectancy=float(health_history[-1].get("life_expectancy",life_expectancy))
		if not force and day-last_day<30: return
		if day==last_day:
			health_history[-1]["life_expectancy"]=life_expectancy
			health_history[-1]["health"]=population_health
			return
	var discovery_names:Array[String]=[]
	var health_effects:=["health_protection","disease_exposure","sanitation","water_safety","maternal_safety","neonatal_survival","injury_risk","health_risk"]
	for event_variant in discovery_log:
		var event:Dictionary=event_variant
		var event_day:=int(event.get("day",-1))
		if event_day<=last_day or event_day>day: continue
		var effects:Dictionary=event.get("effects",{})
		var affects_health:=false
		for effect_id in health_effects:
			if effects.has(effect_id):
				affects_health=true
				break
		if affects_health:
			var discovery_name:=String(event.get("name",event.get("title","Health discovery")))
			if discovery_name!="" and discovery_name not in discovery_names: discovery_names.append(discovery_name)
	var delta:=life_expectancy-previous_expectancy
	var inputs:=life_inputs()
	var reasons:Array[Dictionary]=[]
	if not health_history.is_empty() and health_history[-1].get("inputs") is Dictionary:
		reasons=life_change_reasons(health_history[-1].inputs,inputs,delta)
	var marker_type:=""
	var marker_label:=""
	if not discovery_names.is_empty():
		marker_type="discovery"
		marker_label=", ".join(PackedStringArray(discovery_names))
	elif last_day>=0 and absf(delta)>=0.5:
		marker_type="conditions"
		marker_label="Living conditions changed"
	health_history.append({
		"day":day,"life_expectancy":life_expectancy,"health":population_health,
		"delta":delta,"marker_type":marker_type,"marker_label":marker_label,
		"inputs":inputs,"reasons":reasons
	})
	if health_history.size()>480: health_history.pop_front()

func health_history_snapshot()->Array[Dictionary]:
	if health_history.is_empty():
		return [{"day":floori(elapsed_days),"life_expectancy":projected_life_expectancy(),"health":population_health,"delta":0.0,"marker_type":"","marker_label":"Tracking begins"}]
	return health_history.duplicate(true)

func register_directive_population_deaths(count:int,directive_id:String,description:String,target:Dictionary={})->Dictionary:
	# Directives operate on one numeric population, never generated people. This
	# authoritative entry point preserves the same cohort conservation used by
	# illness, hunger, travel, and war, and leaves at least one living person.
	var safe_id:=directive_id.strip_edges().to_lower().replace(" ","_").substr(0,80)
	var cause:="Directive: %s" % safe_id.replace("_"," ").capitalize()
	var age_weights:Dictionary={}
	var selected_cohorts:Array=target.get("age_cohorts",[])
	if not selected_cohorts.is_empty():
		for key in POPULATION_AGE_COHORTS: age_weights[key]=1.0 if selected_cohorts.has(key) else 0.0
	var eligible:=population_exact-1.0
	if not selected_cohorts.is_empty():
		eligible=0.0
		for key_variant in selected_cohorts: eligible+=maxf(0.0,float(population_cohorts.get(String(key_variant),0.0)))
	var target_sex:=String(target.get("sex",""))
	if target_sex in ["female","male"]:
		# Only the women (or men) of those ages: kept by age from now on.
		initialize_population_model()
		ensure_female_cohorts()
		eligible=0.0
		for key in POPULATION_AGE_COHORTS:
			if selected_cohorts.is_empty() or selected_cohorts.has(key): eligible+=_removable(key,target_sex)
	var actual_request:=mini(maxi(0,count),maxi(0,floori(eligible+0.000001)))
	var removed:=_remove_population_exact(float(actual_request),cause,age_weights,true,target_sex if target_sex in ["female","male"] else "")
	var emitted:=roundi(removed)
	_refresh_population_summary()
	lifetime_deaths+=emitted
	_record_vital_statistics(0,emitted)
	record_death_cause(cause,emitted)
	synchronize_population_allocations()
	var result:Dictionary={"count":emitted,"cause":cause,"affected_cohorts":last_population_removal_by_cohort.duplicate(true),"population_after":population_total}
	var actual:=int(result.get("count",0))
	if actual<=0: return result
	var day:=int(elapsed_days)
	var record:Dictionary={
		"id":"directive_deaths_%d_%d" % [day,demographic_ledger.size()],"day":day,"start_day":day,"end_day":day,
		"title":("%d executed by decree" % actual) if target.has("exact_count") else "%d %s during %s" % [actual,"death" if actual==1 else "deaths",safe_id.replace("_"," ")],"description":description.substr(0,320),
		"domain":"population","severity":"demographic","kind":"death","count":actual,"cause":cause,
		"location":"Civilization under directive","population_after":population_total,"source_order_id":String(target.get("source_order_id","")),
		"affected_cohorts":(result.get("affected_cohorts",{}) as Dictionary).duplicate(true),"demographic_target":target.duplicate(true),"target_label":String(target.get("label","")),"aggregate":true
	}
	demographic_ledger.push_front(record)
	if demographic_ledger.size()>120: demographic_ledger.resize(120)
	result["record"]=record
	return result

func register_population_deaths_by_cell(cells:Array,directive_id:String,description:String,label:String="")->Dictionary:
	## Deaths of people named by age and sex ([{cohort, sex, count}]): each off
	## its own cohort, its women or its men, never more than are there; one
	## record in the demographic ledger. {count, cells (each with its dead),
	## population_after}.
	initialize_population_model()
	var safe_id:=directive_id.strip_edges().to_lower().replace(" ","_").substr(0,80)
	var cause:="Directive: %s" % safe_id.replace("_"," ").capitalize()
	var done:Array=[]
	var total:=0
	var affected:={}
	for c in cells:
		if not c is Dictionary: continue
		var cohort:=String((c as Dictionary).get("cohort",""))
		var sex:=String((c as Dictionary).get("sex",""))
		if not cohort in POPULATION_AGE_COHORTS: continue
		if sex in ["female","male"]: ensure_female_cohorts()
		var want:=mini(maxi(0,int((c as Dictionary).get("count",0))),floori(_removable(cohort,sex)+0.000001))
		want=mini(want,maxi(0,floori(population_exact-1.0)))
		var dead:=0
		if want>0:
			var weights:={}
			for key in POPULATION_AGE_COHORTS: weights[key]=1.0 if key==cohort else 0.0
			dead=roundi(_remove_population_exact(float(want),cause,weights,true,sex))
			affected[cohort]=float(affected.get(cohort,0.0))+float(dead)
		var row:=(c as Dictionary).duplicate(); row["dead"]=dead
		done.append(row); total+=dead
	_refresh_population_summary()
	lifetime_deaths+=total
	_record_vital_statistics(0,total)
	record_death_cause(cause,total)
	synchronize_population_allocations()
	var result:={"count":total,"cells":done,"cause":cause,"population_after":population_total}
	if total<=0: return result
	var day:=int(elapsed_days)
	var record:Dictionary={
		"id":"directive_deaths_%d_%d" % [day,demographic_ledger.size()],"day":day,"start_day":day,"end_day":day,
		"title":"%d %s during %s" % [total,"death" if total==1 else "deaths",safe_id.replace("_"," ")],"description":description.substr(0,320),
		"domain":"population","severity":"demographic","kind":"death","count":total,"cause":cause,
		"location":"Civilization under directive","population_after":population_total,"source_order_id":"",
		"affected_cohorts":affected,"demographic_target":{"cells":cells.duplicate(true),"label":label},"target_label":label,"aggregate":true
	}
	demographic_ledger.push_front(record)
	if demographic_ledger.size()>120: demographic_ledger.resize(120)
	result["record"]=record
	return result

func register_population_arrivals(count:int,source:String="new arrivals",cohort_profile:Dictionary={},female_share:float=-1.0,female_shares:Dictionary={}) -> Dictionary:
	## female_shares: the share of women and girls in each age cohort when the
	## arrivals' make-up is known (captives taken home: town_fate.gd, the women
	## and girls, men and boys as they were chosen); it wins. female_share: the
	## women among them as one share when only that is known; otherwise about
	## half. Arrivals of one sex start the count of women by age
	## (ensure_female_cohorts), so that count stays true.
	initialize_population_model()
	var actual:=maxi(0,count)
	if actual<=0: return {"count":0,"source":source,"population_after":population_total,"cohorts":{}}
	var by_age:=not female_shares.is_empty()
	var share_known:=female_share>=0.0 and is_finite(female_share)
	var arriving_women:=clampf(female_share,0.0,1.0) if share_known else BIRTH_FEMALE_SHARE
	if share_known and absf(arriving_women-BIRTH_FEMALE_SHARE)>0.02: ensure_female_cohorts()
	if by_age:
		for key in female_shares:
			if absf(float(female_shares[key])-BIRTH_FEMALE_SHARE)>0.02: ensure_female_cohorts(); break
	var weights:=cohort_profile.duplicate(true)
	if weights.is_empty():
		# Small mobile groups skew toward working ages while still allowing
		# families. One aggregate update scales identically at 120 or 12B.
		weights={"children":0.12,"youth":0.20,"early_adults":0.28,"established_adults":0.22,"mature_adults":0.14,"elders":0.04}
	var total_weight:=0.0
	for key in POPULATION_AGE_COHORTS: total_weight+=maxf(0.0,float(weights.get(key,0.0)))
	if total_weight<=0.000001: total_weight=1.0
	var added:Dictionary={}
	# One share only, neither all of one sex nor none: children arrive about
	# half girls, as born, and the grown carry the rest, so the women among them
	# still come to the share given (clamped when the children alone exceed it).
	# All of one sex ("the women and girls"): every age, children too.
	var children:=float(actual)*maxf(0.0,float(weights.get("children",0.0)))/total_weight
	var grown_women:=arriving_women
	var one_sex:=arriving_women<=0.0001 or arriving_women>=0.9999
	if share_known and not one_sex and float(actual)-children>0.0:
		grown_women=clampf((arriving_women*float(actual)-children*BIRTH_FEMALE_SHARE)/(float(actual)-children),0.0,1.0)
	for key in POPULATION_AGE_COHORTS:
		var amount:=float(actual)*maxf(0.0,float(weights.get(key,0.0)))/total_weight
		population_cohorts[key]=float(population_cohorts.get(key,0.0))+amount
		var women_share:=BIRTH_FEMALE_SHARE if key=="children" and share_known and not one_sex else grown_women
		if by_age: women_share=clampf(float(female_shares.get(key,BIRTH_FEMALE_SHARE)),0.0,1.0)
		if has_female_cohorts(): population_cohorts[FEMALE_PREFIX+key]=float(population_cohorts.get(FEMALE_PREFIX+key,0.0))+amount*women_share
		added[key]=amount
	population_exact+=float(actual)
	if TRACE.enabled and self==GameState:TRACE.flow("arrival",source,float(actual))
	_refresh_population_summary()
	synchronize_population_allocations()
	return {"count":actual,"source":source,"population_after":population_total,"cohorts":added}

func process_reproduction_day(context:Dictionary) -> Dictionary:
	initialize_population_model()
	_advance_age_cohorts_one_day()
	var reproductive_population:=_reproductive_age_population()
	var active:=float(pregnancy_cohorts.get("first_trimester",0.0))+float(pregnancy_cohorts.get("second_trimester",0.0))+float(pregnancy_cohorts.get("third_trimester",0.0))
	var postpartum:=float(pregnancy_cohorts.get("postpartum",0.0))
	# People physically away on missions (scouts, envoys, convoys) are drawn
	# from the working-age cohort; they cannot conceive at home while out.
	# They are men and women of every working age, so they take their share
	# of the mothers-to-be away, not one each: counted one each, 11 scouts
	# held abroad left a people of 43 with one mother able to conceive.
	var absent_adults:=maxf(0.0,float(context.get("absent_adults",0.0)))
	var away_share:=clampf(absent_adults/maxf(1.0,float(population_cohorts.get("working_age",population_exact*0.6))),0.0,1.0)
	var eligible:=maxf(0.0,reproductive_population*(1.0-away_share)-active-postpartum*0.55)
	# Fewer women of child-bearing age, fewer mothers (1 in an ordinary people).
	var baseline_annual:=float(population_cohorts.get("youth",0.0))*0.45*0.23*_mothers_ratio("youth")+float(population_cohorts.get("early_adults",0.0))*0.50*0.285*_mothers_ratio("early_adults")+float(population_cohorts.get("established_adults",0.0))*0.45*0.18*_mothers_ratio("established_adults")+float(population_cohorts.get("mature_adults",0.0))*0.16*0.040*_mothers_ratio("mature_adults")
	var availability:=clampf(eligible/maxf(1.0,reproductive_population),0.0,1.0)
	var annual_conceptions:=baseline_annual*_conception_condition_factor(context)*availability*clampf(float(context.get("conception_care",1.0)),0.3,2.0)
	annual_conceptions*=1.0-clampf(float(context.get("fertility_transition",0.0)),0.0,0.85) # research_3000: births couples choose not to have
	var conceptions_exact:=annual_conceptions/365.0
	var risk:=_pregnancy_risk_multiplier(context)*clampf(float(context.get("pregnancy_care",1.0)),0.5,2.5)
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
	# research_3000: modern care (EarlyLifeConditions.modern_factors) may bring
	# newborn and maternal deaths down to modern rates, below the old floors.
	var neonatal_rate:=clampf((0.018+(risk-1.0)*0.025)*(1.0-clampf(float(context.get("neonatal_survival",0.0)),-0.50,0.60))*clampf(float(context.get("neonatal_care",1.0)),0.1,4.0),0.0008,0.18)
	var neonatal_deaths_exact:=live_births_exact*neonatal_rate
	var maternal_rate:=clampf((0.0045+(risk-1.0)*0.0065)*(1.0-clampf(float(context.get("maternal_safety",0.0)),0.0,0.65))*clampf(float(context.get("maternal_care",1.0)),0.02,4.0),0.00002,0.055)
	var maternal_deaths_exact:=deliveries*maternal_rate
	pregnancy_cohorts["first_trimester"]=maxf(0.0,first+conceptions_exact-first_losses-to_second)
	pregnancy_cohorts["second_trimester"]=maxf(0.0,second+to_second-second_losses-to_third)
	pregnancy_cohorts["third_trimester"]=maxf(0.0,third+to_third-third_losses-deliveries)
	pregnancy_cohorts["postpartum"]=maxf(0.0,postpartum+deliveries-postpartum/365.0)
	population_cohorts["children"]=float(population_cohorts.get("children",0.0))+live_births_exact
	population_exact+=live_births_exact
	# Newborns come about half girls, whatever became of their mothers' generation:
	# a people that lost its women regains them as the girls grow up.
	if has_female_cohorts(): population_cohorts[FEMALE_PREFIX+"children"]=float(population_cohorts.get(FEMALE_PREFIX+"children",0.0))+live_births_exact*BIRTH_FEMALE_SHARE
	if TRACE.enabled and self==GameState:TRACE.flow("birth","Live births",live_births_exact)
	_remove_population_exact(neonatal_deaths_exact,"Neonatal complications")
	_remove_population_exact(maternal_deaths_exact,"Complications of childbirth",{},true,"female" if has_female_cohorts() else "")
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
	_record_vital_statistics(births_count,maternal_count+neonatal_count)
	record_death_cause("Complications of childbirth",maternal_count)
	record_death_cause("Neonatal complications",neonatal_count)
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
	var ranges:=POPULATION_COHORT_AGE_RANGES.duplicate()
	ranges["elders"]=Vector2(60,max_age)
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
	var median_target:=float(population_total)*0.5
	var cumulative:=0.0
	var median_age:=0.0
	for key in POPULATION_AGE_COHORTS:
		var count:=float(counts.get(key,0))
		var age_range:Vector2=POPULATION_COHORT_AGE_RANGES[key]
		if cumulative+count>=median_target and count>0.0:
			median_age=lerpf(age_range.x,age_range.y,clampf((median_target-cumulative)/count,0.0,1.0))
			break
		cumulative+=count
	var observed_age:=-1.0 if lifetime_deaths<=0 else observed_death_age_sum/maxf(1.0,float(lifetime_deaths))
	return {"bands":bands,"total":population_total,"median_age":median_age,"working_age":working,"dependents":dependents,"dependents_per_100_workers":100.0*float(dependents)/maxf(1.0,float(working)),"projected_life_expectancy":projected_life_expectancy(),"observed_age_at_death":observed_age,"recorded_deaths":lifetime_deaths}


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

func _mortality_condition_factor(housing_ratio:float=-1.0)->float:
	var health_factor:=lerpf(1.90,0.64,clampf(population_health,0.0,1.0))
	var food_factor:=lerpf(2.40,0.78,clampf(fed_security(),0.0,1.0))
	var resolved_housing:=clampf(float(housing_capacity)/maxf(1.0,population_exact),0.0,1.15) if housing_ratio<0.0 else clampf(housing_ratio,0.0,1.15)
	var shelter_factor:=lerpf(1.65,0.88,clampf(resolved_housing,0.0,1.0))
	return health_factor*food_factor*shelter_factor

# _baseline_mortality_hazard_at_age for ages 0-109, for the 110-year projection.
const BASELINE_HAZARD_BY_AGE:Array[float]=[0.090,0.025,0.025,0.025,0.025,0.004,0.004,0.004,0.004,0.004,0.004,0.004,0.004,0.004,0.004,0.006,0.006,0.006,0.006,0.006,0.006,0.006,0.006,0.006,0.006,0.008,0.008,0.008,0.008,0.008,0.008,0.008,0.008,0.008,0.008,0.012,0.012,0.012,0.012,0.012,0.012,0.012,0.012,0.012,0.012,0.025,0.025,0.025,0.025,0.025,0.025,0.025,0.025,0.025,0.025,0.055,0.055,0.055,0.055,0.055,0.055,0.055,0.055,0.055,0.055,0.120,0.120,0.120,0.120,0.120,0.120,0.120,0.120,0.120,0.120,0.230,0.230,0.230,0.230,0.230,0.230,0.230,0.230,0.230,0.230,0.380,0.380,0.380,0.380,0.380,0.380,0.380,0.380,0.380,0.380,0.380,0.380,0.380,0.380,0.380,0.380,0.380,0.380,0.380,0.380,0.380,0.380,0.380,0.380,0.380]

func _baseline_mortality_hazard_at_age(age:int)->float:
	if age==0: return 0.090
	if age<5: return 0.025
	if age<15: return 0.004
	if age<25: return 0.006
	if age<35: return 0.008
	if age<45: return 0.012
	if age<55: return 0.025
	if age<65: return 0.055
	if age<75: return 0.120
	if age<85: return 0.230
	return 0.380

func current_natural_mortality_rate(housing_ratio:float=-1.0)->float:
	# The table is all-cause; the crises take their expected share themselves
	# (crisis_background.gd), so the day's deaths emit only the rest.
	return _natural_rate(housing_ratio,true)

## What the hard times (sickness, floods, lean seasons: crisis_background.gd)
## take in a usual year, per head a year: the whole age table less the
## background the day's ordinary deaths emit, under the same conditions. The
## "What is killing people now" bars show it, so the causes add up to the
## rate behind LIVES in a calm year too.
func usual_hardship_rate(housing_ratio:float=-1.0)->float:
	return maxf(0.0,_natural_rate(housing_ratio,false)-_natural_rate(housing_ratio,true))

## Yearly deaths per head by the age table: the background (`background`) or
## the whole table, under today's conditions.
func _natural_rate(housing_ratio:float,background:bool)->float:
	initialize_population_model()
	var condition_factor:=_mortality_condition_factor(housing_ratio)
	var deaths_per_year:=0.0
	# Average the same life-table hazards used by projected life expectancy over
	# each fixed age band. This stays O(1) at every population scale.
	var cohort_hazards:=_background_cohort_hazards(condition_factor) if background else _natural_cohort_hazards(condition_factor)
	for key in POPULATION_AGE_COHORTS:
		var average_hazard:float=cohort_hazards[key]
		deaths_per_year+=float(population_cohorts.get(key,0.0))*clampf(average_hazard*condition_factor,0.0001,0.98)
	return deaths_per_year/maxf(1.0,population_exact)

## Each cohort's age-table hazard less the crises' expected share of it
## (crisis_background.gd): what the day's ordinary deaths take. The screens
## read the whole table (_natural_cohort_hazards, life_expectancy_from).
func _background_cohort_hazards(condition_factor:float=-1.0)->Dictionary:
	var hazards:=_natural_cohort_hazards(condition_factor)
	var kept:=CRISIS_BACKGROUND.background(elapsed_days/365.0)
	for key in POPULATION_AGE_COHORTS:hazards[key]=float(hazards[key])*float(kept.get(key,1.0))
	return hazards

## Mean baseline hazard of each cohort's ages, scaled by the early-care age
## multipliers. O(110) and independent of population.
func _natural_cohort_hazards(condition_factor:float=-1.0)->Dictionary:
	var result:Dictionary={}
	var conditions:=_mortality_condition_factor() if condition_factor<0.0 else condition_factor
	var care:=care_profile()
	for key in POPULATION_AGE_COHORTS:
		var age_range:Vector2=POPULATION_COHORT_AGE_RANGES[key]
		var hazard_sum:=0.0
		var years:=maxi(1,roundi(age_range.y-age_range.x))
		for age in range(roundi(age_range.x),roundi(age_range.y)):
			hazard_sum+=BASELINE_HAZARD_BY_AGE[age]*EARLY_CARE.age_multiplier(care,age,conditions)
		result[key]=hazard_sum/float(years)
	return result

func _current_exceptional_mortality_rate()->float:
	var components:Dictionary=simulation_metrics.get("mortality_components",{})
	if not components.is_empty():
		var exceptional:=0.0
		for cause in components:
			if String(cause)!="Natural causes": exceptional+=maxf(0.0,float(components[cause]))
		return exceptional
	# Only a save from before the mortality components keeps a rate without
	# them, and its rate holds the whole age table: take the whole table out,
	# so the crises' share (crisis_background.gd) is never counted twice.
	return maxf(0.0,float(simulation_metrics.get("annual_death_rate",0.0))-_natural_rate(-1.0,false))

## Counts today's exceptional risks into the month-long average the projection
## reads (exceptional_hazard_smoothed). `weight` is the day span's share of a
## 30-day mean (ConsequenceEngine passes day_span.rate(1/30)).
func smooth_exceptional_hazard(weight:float)->void:
	var today:=_current_exceptional_mortality_rate()
	exceptional_hazard_smoothed=today if exceptional_hazard_smoothed<0.0 else lerpf(exceptional_hazard_smoothed,today,clampf(weight,0.0,1.0))
	var components:Dictionary=simulation_metrics.get("mortality_components",{})
	for cause_variant in components:
		var cause:=String(cause_variant)
		if cause=="Natural causes": continue
		var value:=maxf(0.0,float(components[cause_variant]))
		exceptional_hazard_causes_smoothed[cause]=value if not exceptional_hazard_causes_smoothed.has(cause) else lerpf(float(exceptional_hazard_causes_smoothed[cause]),value,clampf(weight,0.0,1.0))

## Food security with the store counted full: what is eaten, which deaths
## and sickness read (food_care.gd; consequence_engine.gd keeps it with the
## day's metrics). The size of the store never kills; going without does.
func fed_security()->float:
	return clampf(float(simulation_metrics.get("food_fed_security",food_security)),0.0,1.0)

## The early-care profile the day's rates use. Before the first simulated day
## of a new world (or of a save loaded without one) it is not yet stored, and
## LIVES and the babes lost read the bare life table: 46 winters at the
## founding that became 22 the next day. Computing it on demand shows the
## founders' true odds from the start (fun audit 2, item 3).
func care_profile()->Dictionary:
	if not early_care.is_empty() or WorldSimulation.discovery==null:return early_care
	if elapsed_days<30.0:early_care_blend=1.0
	return EARLY_CARE.profile(self,WorldSimulation.discovery)

func projected_life_expectancy() -> float:
	return life_expectancy_from(life_inputs())

## What how long we live is reckoned from this month: health, food to go round,
## roofs for our numbers and the month's exceptional risks (a month's average,
## not one day's luck: exceptional_hazard_smoothed), by cause.
func life_inputs()->Dictionary:
	var hazard:=exceptional_hazard_smoothed if exceptional_hazard_smoothed>=0.0 else _current_exceptional_mortality_rate()
	return {"health":population_health,"food":fed_security(),"housing":clampf(float(housing_capacity)/maxf(1.0,population_exact),0.0,1.15),
		"hazard":hazard,"hazard_causes":exceptional_hazard_causes_smoothed.duplicate()}

## Life expectancy from `inputs` (life_inputs' shape) under today's care of
## mothers, babies and the sick: the one formula projected_life_expectancy uses.
func life_expectancy_from(inputs:Dictionary)->float:
	var care:=care_profile()
	var condition_factor:=lerpf(1.90,0.64,clampf(float(inputs.get("health",population_health)),0.0,1.0))*lerpf(2.40,0.78,clampf(float(inputs.get("food",food_security)),0.0,1.0))*lerpf(1.65,0.88,clampf(float(inputs.get("housing",1.0)),0.0,1.0))
	var exceptional_hazard:=maxf(0.0,float(inputs.get("hazard",0.0)))
	var survival:=1.0
	var expected_years:=0.0
	for age in 110:
		var baseline_hazard:=BASELINE_HAZARD_BY_AGE[age]*EARLY_CARE.age_multiplier(care,age,condition_factor)
		var annual_hazard:=clampf(baseline_hazard*condition_factor+exceptional_hazard,0.0001,0.98)
		expected_years+=survival
		survival*=1.0-annual_hazard
	return clampf(expected_years,1.0,110.0)

## Why life expectancy moved between two months' inputs: each input's share of
## the change (the mean of swapping it alone from either month), the month's
## exceptional risk split by cause in proportion to each cause's change, and
## what is left (care of mothers, babies and the sick, and new ways) as "care".
## [{"key","years","from","to"}], largest first; small shares dropped.
func life_change_reasons(before:Dictionary,after:Dictionary,total:float)->Array[Dictionary]:
	var result:Array[Dictionary]=[]
	var base_before:=life_expectancy_from(before)
	var base_after:=life_expectancy_from(after)
	var explained:=0.0
	for key:String in ["health","food","housing","hazard"]:
		var forward:=before.duplicate();forward[key]=after.get(key,before.get(key))
		var backward:=after.duplicate();backward[key]=before.get(key,after.get(key))
		var share:=((life_expectancy_from(forward)-base_before)+(base_after-life_expectancy_from(backward)))*0.5
		explained+=share
		if key!="hazard":
			result.append({"key":key,"years":share,"from":float(before.get(key,0.0)),"to":float(after.get(key,0.0))})
			continue
		# The risk's share, told by cause: each cause's change in risk times what
		# a unit of risk costs in years this month.
		var causes_before:Dictionary=before.get("hazard_causes",{})
		var causes_after:Dictionary=after.get("hazard_causes",{})
		var bumped:=after.duplicate();bumped.hazard=float(after.get("hazard",0.0))+0.001
		var years_per_risk:=(life_expectancy_from(bumped)-base_after)/0.001
		var seen:Dictionary={}
		var parts:Array[Dictionary]=[]
		var raw_total:=0.0
		for cause in causes_after.keys()+causes_before.keys():
			if seen.has(String(cause)): continue
			seen[String(cause)]=true
			var from_risk:=float(causes_before.get(cause,0.0))
			var to_risk:=float(causes_after.get(cause,0.0))
			var raw:=years_per_risk*(to_risk-from_risk)
			raw_total+=raw
			parts.append({"key":"cause:"+String(cause),"years":raw,"from":from_risk,"to":to_risk})
		# Scaled so the causes add up to the risk's own share exactly.
		var scale:=share/raw_total if absf(raw_total)>0.000001 and signf(raw_total)==signf(share) else 1.0
		for part:Dictionary in parts:
			part.years=float(part.years)*scale
			result.append(part)
	# What the inputs above do not explain comes from how we care for the weak.
	result.append({"key":"care","years":total-explained,"from":0.0,"to":0.0})
	result=result.filter(func(reason:Dictionary)->bool:return absf(float(reason.years))>=1.0/24.0)
	result.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return absf(float(a.years))>absf(float(b.years)))
	return result

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

func civilian_workforce_fraction()->float:
	var civilian:=0.0
	for role in population_allocations:
		if role!="Defense":civilian+=maxf(0,float(population_allocations[role]))
	if civilian<=0:return 0.0
	var committed:=WorldSimulation.military._mobilized_count() if WorldSimulation.military!=null else 0
	var displaced:=maxf(0,float(committed)-float(population_allocations.get("Defense",0)))
	return clampf(1.0-displaced/civilian,0.0,1.0)

## The people at a work today, as heads: the hurt, the absent and the
## reserved counted as effective_workers counts them, but not what makes each
## of them count for more (a great work's favour, a gifted person). Wages and
## head counts read this; the work's output reads effective_workers.
func workers_at(role:String)->float:
	return effective_workers(role,false,false,false,false,false)

## The work a role does today, in workers: the people at it (the hurt count
## less, the absent and the reserved not at all), each counting for more
## where a great work favours it or a gifted person leads it (`include_lifts`).
func effective_workers(role:String,include_military_construction:bool=false,include_clinical_care:bool=false,include_civic_records:bool=false,include_microscopy:bool=false,include_lifts:bool=true)->float:
	var civilian_workers:=0.0
	for value in population_allocations.values(): civilian_workers+=maxf(0,float(value))
	var capacity:=PermanentInjuries.effective(float(population_allocations.get(role,0)),role,civilian_injuries if resource_settlement_id.is_empty() else {},civilian_workers)
	if role!="Defense":capacity*=WorldSimulation.settlements.civilian_workforce_fraction()
	if role=="Construction" and not include_military_construction and WorldSimulation.military.joint_operations!=null:capacity*=1.0-WorldSimulation.military.joint_operations.construction_share(resource_settlement_id)
	if role=="Knowledge":capacity=maxf(0,capacity-preload("res://scripts/scholar_visits.gd").absent(self,int(elapsed_days)))
	if role=="Knowledge" and not include_clinical_care:capacity=maxf(0,capacity-preload("res://scripts/civilian_care.gd").reserved(self,capacity))
	if role=="Knowledge" and not include_clinical_care and not include_microscopy:capacity=maxf(0,capacity-preload("res://scripts/microscopy_lab.gd").reserved(self,capacity))
	if role=="Administration" and not include_civic_records:capacity=maxf(0,capacity-preload("res://scripts/civic_administration.gd").reserved(self,capacity))
	if role=="Crafting":capacity=maxf(0,capacity-preload("res://scripts/technology_operations.gd").reserved_workers(self))
	var lifts:=1.0
	if include_lifts or role=="Crafting":lifts=(1.0+preload("res://scripts/undertaking_system.gd").benefit(self,role))*(1.0+preload("res://scripts/geniuses.gd").bonus(self,role))
	if include_lifts:
		# A great work favouring it, and a grown genius of this work, make each
		# person on it count for more (undertaking_system.gd, geniuses.gd).
		capacity*=lifts
	# Makers on arms give the whole day to them (civilian_goods.gd arms_hands,
	# counted as the makers' day is, every lift in; as heads without them).
	if role=="Crafting":capacity=maxf(0,capacity-preload("res://scripts/civilian_goods.gd").arms_hands(self)/(1.0 if include_lifts else maxf(0.0001,lifts)))
	if role=="Construction":capacity*=1.0-preload("res://scripts/undertaking_system.gd").share(self)
	return capacity

func receive_injured_veterans(count:int,severe:int)->void:
	# Transfer within this population: never add people or deaths here.
	severe=clampi(severe,0,maxi(0,count))
	civilian_injuries["limited"]=float(civilian_injuries.get("limited",0))+maxi(0,count-severe)
	civilian_injuries["severe"]=float(civilian_injuries.get("severe",0))+severe
	synchronize_population_allocations()

func workforce_capacity_snapshot()->Dictionary:
	var heads:=0.0; var effective:=0.0; var roles:Dictionary={}
	for role in population_allocations:
		var amount:=effective_workers(role)
		heads+=float(population_allocations[role]); effective+=amount
		roles[role]={"people":population_allocations[role],"effective_workers":amount}
	return {"people":heads,"effective_workers":effective,"lasting_injuries":PermanentInjuries.total(civilian_injuries),"roles":roles}
