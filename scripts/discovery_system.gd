extends Node

const Pathways=preload("res://scripts/knowledge_pathways.gd")
const Exchange=preload("res://scripts/society_exchange.gd")
const OpeningOpportunities=preload("res://scripts/opening_opportunities.gd")
const ResourceKnowledgeCatalog = preload("res://scripts/resource_knowledge_catalog.gd")
const SocietyKnowledgeCatalog = preload("res://scripts/society_knowledge_catalog.gd")
const DiscoveryFrontierCatalog = preload("res://scripts/discovery_frontier_catalog.gd")
const SocietyModelScript = preload("res://scripts/society_model.gd")
const TechnologyEras=preload("res://scripts/technology_eras.gd")
const Research600=preload("res://scripts/research_600_catalog.gd")
## The last day free teams read questions far ahead of their age
## (_place_free_teams, at most once in each block of SWITCH_CHECK_DAYS days).
## The name is older: saves hold it.
var _research_600_return_day:=-100000
var society_model = SocietyModelScript.new()
## Years this people's own learning has run ahead of the calendar (0 at a
## normal pace): keeping more learners than the age can spare carries it ahead,
## fewer let the calendar catch up (Research600.lead_rate). Questions are dated
## against learning_year(), the calendar plus this lead. Saved with the system;
## an older save starts at 0, where it always stood.
var learning_lead:=0.0
## Today's learning goods (transient, never saved: an Object): the day, the
## share of the learners' goods the stores covered, the goods a day they ask,
## the step's length and what they took from each place ("" home, else a town).
## The day's makers read it after the learners (civilian_goods.gd).
class LearningDay extends RefCounted:
	var day:=-1
	var cover:=1.0
	var need:=0.0
	var span:=1.0
	var places:Dictionary={}
var _learning_day:=LearningDay.new()

var rng := RandomNumberGenerator.new()
var initialized := false
var technology_catalog:Array[Dictionary]=[]
var technology_limits:Dictionary={}
var catalog_by_id:Dictionary={}
var catalog_by_channel:Dictionary={}
var _candidate_index=preload("res://scripts/research_candidate_index.gd").new()

## Transient research bookkeeping, held in one Object so saves never capture it
## (this system and its society model are saved by reflection).
##
## A scan is one batch of research reads (refreshing the lines, a ruler's
## research review) inside which nothing those reads depend on changes: the
## known discoveries, the calendar, the society's materials, ground, people,
## institutions and contacts, its context signals and its evidence. Inside a
## scan each question's eligibility, the design-condition snapshot, the home
## ground and each field's need are read once, and a line's best question is
## scored once per allocation and chosen target. Another calendar day, another
## discovery count or another acting people starts the batch afresh. The seeded
## tables depend only on a question, the world seed and the fixed catalog.
class ResearchScan extends RefCounted:
	var depth:=0
	var state:Object=null
	var day:=-1
	var known_size:=-1
	var known:Dictionary={}
	var has_known:=false
	var society:Dictionary={}
	var has_society:=false
	var environment:Dictionary={}
	var has_environment:=false
	var home_resources:Dictionary={}
	var has_home_resources:=false
	var eligible:Dictionary={}
	var best:Dictionary={}
	var needs:Dictionary={}
	var seed_value:=0
	var seeded:=false
	var seed_tables:Dictionary={}
	## Tables of technology_catalog, each with the catalog basis it was read
	## from (_catalog_basis): dynamic -> entries in catalog order; foundation id
	## -> ascending indices of the questions naming it; each entry's opening
	## year (research_open_year), by catalog index.
	var by_dynamic:Dictionary={}
	var by_dynamic_basis:Array=[]
	var children:Dictionary={}
	var children_basis:Array=[]
	var open_years:=PackedFloat64Array()
	var open_years_basis:Array=[]
	## Foundation work (_research_600_foundation_ids), per field: its entries by
	## whole opening year, and the discovery count at which every question of
	## the field then unknown had its opening year recorded.
	var year_buckets:Dictionary={}
	var year_buckets_basis:Array=[]
	var foundation_scanned:Dictionary={}
	## Each channel's open questions in order of their opening years, with the
	## list they were read from (_channel_by_age).
	var by_age:Dictionary={}
	func clear_batch()->void:
		day=-1;known_size=-1;known={};has_known=false;society={};has_society=false
		environment={};has_environment=false;home_resources={};has_home_resources=false
		eligible={};best={};needs={}
	func clear_catalog()->void:
		seed_value=0;seeded=false;seed_tables={};by_dynamic={};by_dynamic_basis=[]
		children={};children_basis=[];open_years=PackedFloat64Array();open_years_basis=[]
		year_buckets={};year_buckets_basis=[];foundation_scanned={};by_age={}
var _scan:=ResearchScan.new()

var latest_context:Dictionary={}
var established_threads_cache:Array[Dictionary]=[]
var established_threads_signature:=""
var era_by_id:Dictionary={}
const BASE_DISCOVERY_COUNT:=31
const FRONTIER_PATH_AVAILABILITY:=7200
const EFFECT_DISPLAY_NAMES:Dictionary={
	"conception_support":"safe conception support","maternal_safety":"maternal safety","food_output":"usable food output","nutrition_quality":"diet quality",
	"health_protection":"health protection","disease_exposure":"disease exposure","labor_efficiency":"labor efficiency","task_coordination":"task coordination",
	"knowledge_rate":"rate of learning","knowledge_preservation":"knowledge preservation","tool_quality":"tool quality","craft_output":"craft output",
	"construction_rate":"construction rate","disaster_resilience":"disaster resilience","haul_capacity":"carrying capacity","route_speed":"travel speed",
	"ecology_recovery":"ecological recovery","ecological_pressure":"ecological pressure","state_capacity":"state capacity","legitimacy":"legitimacy",
	"security_efficiency":"security efficiency","warfare_readiness":"military readiness","cohesion":"social cohesion","adoption_rate":"spread of new practices"
}

## Pristine copies of the base entries: initialize() replaces them with
## design-applied versions, which must not survive into another world or
## research block manifest.
var _base_entries:Array[Dictionary]=[]

func reset_for_new_world()->void:
	initialized=false
	catalog.resize(BASE_DISCOVERY_COUNT)
	for i in mini(_base_entries.size(),BASE_DISCOVERY_COUNT): catalog[i]=_base_entries[i].duplicate(true)
	technology_catalog.clear()
	technology_limits.clear()
	catalog_by_id.clear()
	catalog_by_channel.clear()
	era_by_id.clear()
	_open_year_cache.clear()
	_candidate_index=preload("res://scripts/research_candidate_index.gd").new()
	_scan=ResearchScan.new()
	_team_memo=TeamMemo.new()
	learning_lead=0.0
	_learning_day=LearningDay.new()
	# The teams' look days start afresh with the world (a save restores its own).
	_switch_checked={}
	_research_600_return_day=-100000
	latest_context.clear()
	established_threads_cache.clear()
	established_threads_signature=""
	society_model=SocietyModelScript.new()
	rng=RandomNumberGenerator.new()

# This catalog is intentionally never exposed to player UI. It is the causal
# machinery that turns activity, environment, attention, and chance into history.
var catalog: Array[Dictionary] = [
	{"id":"seasonal_patterns","name":"Seasonal Patterns","direction":"Nature","chance":0.010,"day":0,"requires":[],"signals":["foraging","exploration"],"observation":"Gatherers report that plants and animals return in recurring cycles."},
	{"id":"seed_selection","name":"Selective Planting","direction":"Sustenance","chance":0.006,"day":20,"requires":["seasonal_patterns"],"signals":["foraging","food"],"observation":"Some gathered seeds consistently produce stronger plants.","production_contract":"Settled food workers reserve finite dry seed and tend two ninety-day comparison plantings on recognized fertile ground before the question opens. Cultivation requires a continuing local seed reserve."},
	{"id":"food_drying","name":"Food Drying","direction":"Sustenance","chance":0.009,"day":0,"requires":["edible_resource_recognition"],"requires_all":["edible_resource_recognition"],"signals":["food","storage"],"observation":"Repeated handling of known edible foods shows that dry moving air slows spoilage.","production_contract":"Crafted drying mats expose finite fresh food to local air. Logistics labor and weather bound daily output; mats wear and must be replaced."},
	{"id":"smoking","name":"Smoke Preservation","direction":"Sustenance","chance":0.005,"day":18,"requires":["hearth_heat_retention"],"requires_all":["hearth_heat_retention"],"signals":["food","fire"],"observation":"Food kept above smoky fires changes texture and lasts longer.","production_contract":"Crafted smoke frames hold finite meat and fish above a maintained fire. Logistics labor, frame coverage, and consumed timber bound daily output.","learning_routes":[{"id":"local","label":"Drying practice extended over smoke","requires_all":["food_drying"]},{"id":"charcoal","label":"Hearth experiments with restricted combustion","requires_all":["charcoal"]}]},
	{"id":"cordage","name":"Twisted Cordage","direction":"Materials","chance":0.010,"day":3,"requires":["fiber_grading"],"requires_all":["fiber_grading"],"signals":["fiber","construction"],"observation":"Graded plant fibers twisted together hold more weight than loose strands."},
	{"id":"basketry","name":"Basketry","direction":"Materials","chance":0.006,"day":12,"requires":["cordage","fiber_grading"],"requires_all":["cordage","fiber_grading"],"signals":["fiber","storage"],"observation":"Interlaced graded fibers form containers that remain light and repairable."},
	{"id":"charcoal","name":"Charcoal Production","direction":"Materials","chance":0.004,"day":35,"requires":["hearth_heat_retention"],"requires_all":["hearth_heat_retention"],"signals":["fire","timber"],"observation":"Wood heated beneath restricted air leaves an unusually hot-burning residue.","effects":{},"production_items":["wood_charcoal"],"production_contract":"A finite workshop converts timber into physical charcoal with paid earth-and-stone tooling. No fuel stock is granted by discovery."},
	{"id":"clay_shaping","name":"Clay Vessels","direction":"Materials","chance":0.006,"day":15,"requires":["clay_testing"],"requires_all":["clay_testing"],"signals":["clay","storage"],"observation":"Tested local clay can be shaped into containers before it dries."},
	{"id":"pit_firing","name":"Pit Firing","direction":"Materials","chance":0.003,"day":50,"requires":["clay_shaping","hearth_heat_retention"],"requires_all":["clay_shaping","hearth_heat_retention"],"signals":["fire","clay"],"observation":"Clay exposed to sustained heat becomes permanently hard.","learning_routes":[{"id":"local","label":"Charcoal-supported firing trials","requires_all":["charcoal"]},{"id":"experimental","label":"Cooking-fire experiments","requires_all":["food_drying"],"signals":["fire","clay"]}]},
	{"id":"joinery","name":"Wood Joinery","direction":"Infrastructure","chance":0.005,"day":22,"requires":["hafted_tools","timber_grading"],"requires_all":["hafted_tools","timber_grading"],"signals":["timber","construction"],"observation":"Hafted cutting tools shape selected wooden members so they lock together without cord."},
	{"id":"drainage","name":"Ground Drainage","direction":"Infrastructure","chance":0.007,"day":10,"requires":[],"signals":["construction","rain"],"observation":"Shallow channels keep occupied ground drier after storms."},
	{"id":"well_siting","name":"Well Siting","direction":"Infrastructure","chance":0.004,"day":40,"requires":["drainage"],"signals":["freshwater","construction"],"observation":"Certain terrain features reliably indicate water beneath the ground."},
	{"id":"wound_cleaning","name":"Wound Cleaning","direction":"Health","chance":0.007,"day":0,"requires":[],"signals":["injury","freshwater"],"observation":"Washed wounds become dangerous less often than untreated wounds.","production_contract":"Households spend additional locally collected freshwater washing wounds after drinking needs are met. Benefits scale with the share of daily demand actually supplied."},
	{"id":"herbal_classification","name":"Medicinal Classification","direction":"Health","chance":0.004,"day":28,"requires":[],"signals":["foraging","illness"],"observation":"Healers begin separating plants by repeatable effects rather than appearance."},
	{"id":"clean_water","name":"Clean-Water Practice","direction":"Health","chance":0.004,"day":45,"requires":["wound_cleaning"],"signals":["freshwater","illness"],"observation":"Families using cleaner water suffer fewer stomach illnesses.","production_contract":"Households spend additional locally collected freshwater separating and handling cleaner water after drinking and wound washing. Benefits scale with the share of daily demand actually supplied."},
	{"id":"tallies","name":"Material Tallies","direction":"Information","chance":0.007,"day":0,"requires":[],"signals":["storage","administration"],"observation":"Repeated marks can preserve quantities after memory becomes unreliable."},
	{"id":"standard_measures","name":"Shared Measures","direction":"Information","chance":0.003,"day":70,"requires":["tallies"],"signals":["trade","construction"],"observation":"Disputes fall when different workers use the same reference quantities."},
	{"id":"route_memory","name":"Encoded Routes","direction":"Information","chance":0.006,"day":12,"requires":[],"signals":["exploration","travel"],"observation":"Travelers develop repeatable stories that preserve direction and distance."},
	{"id":"labor_rotations","name":"Labor Rotations","direction":"Society","chance":0.007,"day":8,"requires":[],"signals":["administration","construction"],"observation":"Regular rotations distribute exhausting work without abandoning essential tasks."},
	{"id":"customary_law","name":"Customary Law","direction":"Society","chance":0.003,"day":55,"requires":["labor_rotations"],"signals":["dispute","administration"],"observation":"Repeated judgments are being remembered as rules that bind future decisions."},
	{"id":"public_stores","name":"Public Stores","direction":"Society","chance":0.003,"day":80,"requires":["tallies","labor_rotations"],"signals":["storage","administration"],"observation":"Shared reserves can support projects no household could sustain alone."},
	{"id":"watch_rotation","name":"Organized Watch","direction":"Warfare","chance":0.007,"day":6,"requires":[],"signals":["defense","danger"],"observation":"Scheduled sentries detect threats earlier and reduce exhaustion."},
	{"id":"formation_drill","name":"Formation Drill","direction":"Warfare","chance":0.003,"day":60,"requires":["watch_rotation","labor_rotations"],"signals":["defense","training"],"observation":"Groups moving under repeated commands retain cohesion under pressure."},
	{"id":"supply_groups","name":"Organized Supply Parties","direction":"Warfare","chance":0.003,"day":75,"requires":["tallies","route_memory"],"signals":["logistics","travel"],"observation":"Separating carriers from scouts allows groups to travel farther."},
	# — Domestication line. The physical mount population the military's
	# cavalry gate has always demanded, and the transformative stride for
	# scouting range.
	{"id":"animal_taming","name":"Animal Taming","dynamic":"ecology","subcategory":"Resource sustainability","direction":"ecology","chance":0.005,"day":90,"requires":["seasonal_patterns"],"signals":["foraging","exploration"],"resource_requirements":[{"resource":"Game","stage":"recognized"}],"observation":"Orphaned young of herd animals raised beside the settlement stay, breed, and follow.","effects":{"food_output":0.004},"production_contract":"A small group is removed from a suitable recognized wild population, then consumes finite plant food under daily settled handling for sixty qualifying days. Benefits and downstream animal practices scale with the maintained living herd."},
	{"id":"pack_animals","name":"Pack Animal Husbandry","dynamic":"logistics","subcategory":"Carrying capacity","direction":"logistics","chance":0.004,"day":220,"requires":["animal_taming"],"signals":["logistics","travel"],"observation":"Tamed beasts under pack-frames carry loads no human team matches, day after day.","effects":{"haul_capacity":0.008,"route_speed":0.004}},
	{"id":"domesticated_mounts","name":"Domesticated Mounts","dynamic":"logistics","subcategory":"Route quality","direction":"logistics","chance":0.003,"day":400,"requires":["pack_animals"],"signals":["travel","defense"],"observation":"Selected bloodlines accept riders. A mounted person moves like weather, not like walking.","effects":{"route_speed":0.010}},
	{"id":"mounted_scouts","name":"Mounted Scouting","dynamic":"logistics","subcategory":"Route quality","direction":"logistics","chance":0.004,"day":460,"requires":["domesticated_mounts"],"signals":["exploration","travel"],"observation":"Riders range in days across country that costs walkers weeks, and return fresh enough to tell it.","effects":{"route_speed":0.012}},
	# — Watercraft line. From river floats to coastal passage; open water stops
	# being an absolute wall for scout parties.
	{"id":"hide_floats","name":"Hide Floats","dynamic":"logistics","subcategory":"Route quality","direction":"logistics","chance":0.005,"day":140,"requires":["cordage"],"signals":["freshwater","travel"],"observation":"Inflated hides lashed into rafts carry people and bundles across still water."},
	{"id":"river_craft","name":"River Craft","dynamic":"logistics","subcategory":"Carrying capacity","direction":"logistics","chance":0.004,"day":320,"requires":["hide_floats","basketry"],"signals":["freshwater","logistics"],"observation":"Framed hulls with paddles run the river both ways; the current becomes a road.","effects":{"haul_capacity":0.006,"route_speed":0.006}},
	{"id":"coastal_watercraft","name":"Coastal Watercraft","dynamic":"logistics","subcategory":"Trade reach","direction":"logistics","chance":0.003,"day":600,"requires":["river_craft","joinery"],"signals":["travel","exploration"],"observation":"Sewn-plank hulls hold a heading along the coast and cross the mouths of bays.","effects":{"route_speed":0.008}}
]

func initialize() -> void:
	if initialized:
		return
	if _base_entries.is_empty():
		for i in mini(catalog.size(),BASE_DISCOVERY_COUNT): _base_entries.append(catalog[i].duplicate(true))
	catalog_by_id.clear()
	catalog_by_channel.clear()
	era_by_id.clear()
	_open_year_cache.clear()
	_candidate_index=preload("res://scripts/research_candidate_index.gd").new()
	_scan.clear_catalog()
	_scan.clear_batch()
	rng.seed = WorldSimulation.state.world_seed ^ 0x6c8e9cf5
	catalog.append_array(ResourceKnowledgeCatalog.entries())
	catalog.append_array(SocietyKnowledgeCatalog.entries())
	catalog.append_array(preload("res://scripts/settlement_architecture_knowledge.gd").entries())
	catalog.append_array(preload("res://scripts/joint_force_knowledge.gd").entries())
	catalog.append_array(preload("res://scripts/technology_branch_catalog.gd").entries())
	catalog.append_array(preload("res://scripts/fire_knowledge.gd").entries())
	catalog.append_array(preload("res://scripts/food_preparation.gd").entries())
	catalog.append_array(preload("res://scripts/grain_processing.gd").entries())
	catalog.append_array(preload("res://scripts/food_batch_knowledge.gd").entries())
	catalog.append_array(preload("res://scripts/clothing_knowledge.gd").entries())
	catalog.append_array(preload("res://scripts/food_water_knowledge.gd").entries())
	catalog.append_array(preload("res://scripts/military_education_knowledge.gd").entries())
	catalog.append_array(preload("res://scripts/civilian_science_knowledge.gd").entries())
	catalog.append_array(preload("res://scripts/civilian_industry.gd").entries())
	catalog.append_array(preload("res://scripts/semiconductor_knowledge.gd").entries())
	catalog.append_array(preload("res://scripts/combined_arms_doctrine.gd").entries())
	catalog.append_array(preload("res://scripts/mathematics_knowledge.gd").entries())
	catalog.append_array(preload("res://scripts/chemical_process_knowledge.gd").entries())
	catalog.append_array(preload("res://scripts/mechanics_knowledge.gd").entries())
	catalog.append_array(preload("res://scripts/geoscience_knowledge.gd").entries())
	catalog.append_array(preload("res://scripts/field_medicine.gd").entries())
	catalog.append_array(preload("res://scripts/field_repair.gd").entries())
	catalog.append_array(preload("res://scripts/agronomy_knowledge.gd").entries())
	catalog.append_array(preload("res://scripts/crop_nutrition_knowledge.gd").entries())
	catalog.append_array(preload("res://scripts/electrical_storage_knowledge.gd").entries())
	catalog.append_array(preload("res://scripts/pneumatic_knowledge.gd").entries())
	catalog.append_array(preload("res://scripts/optical_instrument_knowledge.gd").entries())
	catalog.append_array(preload("res://scripts/refractory_ceramics_knowledge.gd").entries())
	catalog.append_array(preload("res://scripts/finery_knowledge.gd").entries())
	catalog.append_array(preload("res://scripts/charcoal_knowledge.gd").entries())
	catalog.append_array(preload("res://scripts/canning_knowledge.gd").entries())
	catalog.append_array(preload("res://scripts/shipbuilding_knowledge.gd").entries())
	catalog.append_array(preload("res://scripts/cartwright_knowledge.gd").entries())
	catalog.append_array(preload("res://scripts/machine_tool_knowledge.gd").entries())
	catalog.append_array(preload("res://scripts/mechanical_drive_knowledge.gd").entries())
	catalog.append_array(preload("res://scripts/precision_component_knowledge.gd").entries())
	catalog.append_array(preload("res://scripts/abrasive_knowledge.gd").entries())
	catalog.append_array(preload("res://scripts/formed_metal_knowledge.gd").entries())
	catalog.append_array(preload("res://scripts/metal_process_knowledge.gd").entries())
	catalog.append_array(preload("res://scripts/fastener_knowledge.gd").entries())
	catalog.append_array(preload("res://scripts/communications_knowledge.gd").entries())
	catalog.append_array(preload("res://scripts/building_material_knowledge.gd").entries())
	catalog.append_array(preload("res://scripts/earthen_building_knowledge.gd").entries())
	catalog.append_array(preload("res://scripts/water_conveyance_knowledge.gd").entries())
	catalog.append_array(preload("res://scripts/naval_service_knowledge.gd").entries())
	catalog.append_array(preload("res://scripts/rail_freight_knowledge.gd").entries())
	catalog.append_array(preload("res://scripts/civilian_care_knowledge.gd").entries())
	catalog.append_array(preload("res://scripts/textile_knowledge.gd").entries())
	catalog.append_array(preload("res://scripts/textile_mechanization.gd").entries())
	catalog.append_array(preload("res://scripts/textile_process_knowledge.gd").entries())
	catalog.append_array(preload("res://scripts/armor_knowledge.gd").entries())
	catalog.append_array(preload("res://scripts/early_machinery_knowledge.gd").entries())
	catalog.append_array(preload("res://scripts/polymer_knowledge.gd").entries())
	catalog.append_array(preload("res://scripts/selected_food_knowledge.gd").entries())
	catalog.append_array(preload("res://scripts/paper_knowledge.gd").entries())
	catalog.append_array(preload("res://scripts/record_media_knowledge.gd").entries())
	catalog.append_array(preload("res://scripts/parchment_knowledge.gd").entries())
	catalog.append_array(preload("res://scripts/type_composition_knowledge.gd").entries())
	catalog.append_array(preload("res://scripts/glassworking_knowledge.gd").entries())
	catalog.append_array(preload("res://scripts/glass_ceramic_process_knowledge.gd").entries())
	catalog.append_array(preload("res://scripts/leather_knowledge.gd").entries())
	catalog.append_array(preload("res://scripts/electronic_components.gd").entries())
	catalog.append_array(preload("res://scripts/digital_logic_knowledge.gd").entries())
	catalog.append_array(preload("res://scripts/computing_memory_knowledge.gd").entries())
	catalog.append_array(preload("res://scripts/microprogramming_knowledge.gd").entries())
	catalog.append_array(preload("res://scripts/printing_knowledge.gd").entries())
	catalog.append_array(preload("res://scripts/intaglio_knowledge.gd").entries())
	catalog.append_array(preload("res://scripts/civic_administration_knowledge.gd").entries())
	catalog.append_array(preload("res://scripts/field_botany_knowledge.gd").entries())
	catalog.append_array(preload("res://scripts/microscopy_knowledge.gd").entries())
	catalog.append_array(preload("res://scripts/colorant_knowledge.gd").entries())
	catalog.append_array(preload("res://scripts/machine_process_knowledge.gd").entries())
	catalog.append_array(preload("res://scripts/metallurgy_process_knowledge.gd").entries())
	catalog.append_array(preload("res://scripts/settlement_fabric_knowledge.gd").entries())
	catalog.append_array(preload("res://scripts/early_practice_knowledge.gd").entries())
	catalog.append_array(preload("res://scripts/town_practice_knowledge.gd").entries())
	# --- research_600 (begin): register design discoveries the catalog lacks ---
	var authored_ids:Dictionary={}
	for authored:Dictionary in catalog: authored_ids[String(authored.get("id",""))]=true
	catalog.append_array(Research600.new_entries(authored_ids))
	# --- research_600 (end) ---
	catalog.append_array(DiscoveryFrontierCatalog.entries())
	for i in catalog.size():
		catalog[i]=_classify_discovery(catalog[i])
		catalog[i]=society_model.normalize_discovery(catalog[i])
		catalog[i]=preload("res://scripts/technology_branch_rules.gd").apply(catalog[i])
		catalog[i]=preload("res://scripts/mathematics_knowledge.gd").apply(catalog[i])
		catalog[i]=preload("res://scripts/mechanics_knowledge.gd").apply(catalog[i])
		catalog[i]=Research600.apply(catalog[i]) # research_600: design foundations and pace win
		var discovery:Dictionary=catalog[i]
		catalog_by_id[String(discovery.get("id",""))]=discovery
		if not bool(discovery.get("frontier",false)): technology_catalog.append(discovery)
		if bool(discovery.get("frontier",false)): continue
		var channel:=_channel_key(String(discovery.get("dynamic","")),String(discovery.get("subcategory","")))
		if not catalog_by_channel.has(channel): catalog_by_channel[channel]=[]
		(catalog_by_channel[channel] as Array).append(discovery)
	_assign_research_600_years() # research_600
	# Candidate order depends only on the world seed and static definition, so
	# sort each fixed research channel once instead of sorting the full frontier
	# on every simulated day.
	for channel_variant in catalog_by_channel:
		var channel_catalog:Array=catalog_by_channel[channel_variant]
		channel_catalog.sort_custom(func(first:Dictionary,second:Dictionary)->bool:
			var first_order:int=int(first.get("day",0))+absi(hash("%s:%s" % [WorldSimulation.state.world_seed,first.get("id","")]))%240
			var second_order:int=int(second.get("day",0))+absi(hash("%s:%s" % [WorldSimulation.state.world_seed,second.get("id","")]))%240
			return first_order<second_order)
		catalog_by_channel[channel_variant]=channel_catalog
	# Tables that follow the fixed catalog alone are built with it, keeping
	# their cost out of the day's steps.
	foundation_children()
	_technology_entries("")
	initialized = true
	_refresh_active_investigations()

func process_day(context: Dictionary) -> Array[Dictionary]:
	initialize()
	WorldSimulation.figures.advance(int(WorldSimulation.state.elapsed_days))
	WorldSimulation.direction.advance(int(WorldSimulation.state.elapsed_days))
	WorldSimulation.communities.advance(int(WorldSimulation.state.elapsed_days))
	WorldSimulation.diplomacy.advance(int(WorldSimulation.state.elapsed_days))
	Exchange.advance(int(WorldSimulation.state.elapsed_days))
	var effective_context:=context.duplicate(true)
	var military_campaign:=WorldSimulation.system("MilitaryCampaign")
	if military_campaign!=null and military_campaign.has_method("military_inquiry_context"):
		var military_context:Dictionary=military_campaign.military_inquiry_context()
		for signal_name in military_context:
			effective_context[signal_name]=float(effective_context.get(signal_name,0.0))+float(military_context[signal_name])
	latest_context=effective_context.duplicate(true)
	OpeningOpportunities.advance(effective_context)
	society_model.process_day(catalog,effective_context)
	var results: Array[Dictionary] = []
	var current_day := int(floor(WorldSimulation.state.elapsed_days))
	WorldSimulation.state.scholarship_level=scholarship_level()+scholarship_rate()*float(WorldSimulation.span)/365.0
	_advance_learning(current_day)
	_refresh_active_investigations()
	var teams:=research_teams()
	# A field's leadership factor is read once for all its lines, and each
	# office's executing office once for all fields: nothing they read moves
	# between lines until a question is answered, which clears both.
	var leader_factors:Dictionary={}
	var executing_offices:Dictionary={}
	# The known discoveries as a set for the route checks, kept current below.
	var known_set:Dictionary={}
	for known_id:String in WorldSimulation.state.known_discoveries: known_set[known_id]=true
	# Questions that reached a step to proof today (first cases, repeated).
	var stepped:Array[Dictionary]=[]
	for channel_variant in WorldSimulation.state.active_investigations.keys().duplicate():
		var channel:=String(channel_variant)
		var discovery_id:=String(WorldSimulation.state.active_investigations.get(channel,""))
		var discovery:=discovery_definition(discovery_id)
		if discovery.is_empty(): continue
		var home:=_research_600_channel_home(channel) # research_600: foundation work is staffed by its channel
		var research_capacity:=research_capacity_for(home[0],home[1],teams)
		var attention:=float(research_capacity.get("progress_multiplier",0.0))
		if attention<=0.0: continue
		var activity := 0.65
		for activity_signal in discovery.signals:
			activity += float(effective_context.get(activity_signal, 0.0)) * 0.22
		var direction:=String(discovery.dynamic)
		var known_factor:Variant=leader_factors.get(direction)
		var leader_factor:float=_loop_leader_factor(direction,executing_offices) if known_factor==null else float(known_factor)
		leader_factors[direction]=leader_factor
		# Catalog chances describe relative discoverability. The global time scale keeps
		# knowledge unfolding across generations instead of exhausting an era in months.
		var material_evidence:=_resource_evidence(discovery.get("resource_requirements",[]))
		var probability: float = discovery.chance / research_difficulty(discovery,WorldSimulation.state.world_seed) * attention * activity * material_evidence * leader_factor*WorldSimulation.consequences.discovery_multiplier()*(1.0+WorldSimulation.progression.effect("knowledge_rate"))*0.12
		probability*=Pathways.multiplier(discovery,known_set)*(.85 if Exchange.studying() else 1.0)
		var progress:=float(WorldSimulation.state.discovery_progress.get(discovery_id,0.0))
		var before:=progress
		# A multi-day step (day_span.gd) covers `span` days of inquiry.
		progress+=probability*rng.randf_range(0.72,1.28)*WorldSimulation.span
		if rng.randf()<preload("res://scripts/day_span.gd").chance(probability*0.10): progress+=rng.randf_range(0.025,0.085)
		WorldSimulation.state.discovery_progress[discovery_id]=clampf(progress,0.0,1.0)
		if progress<1.0 and Research600.stage(progress)>Research600.stage(before):
			stepped.append({"day":current_day,"id":discovery_id,"name":String(discovery.get("name",discovery_id)),"dynamic":String(discovery.get("dynamic","")),"stage":Research600.stage(progress),"share":Research600.trial_share(progress)})
		if progress>=1.0:
			leader_factors.clear()
			executing_offices.clear()
			Pathways.remember(discovery,current_day)
			WorldSimulation.state.known_discoveries.append(discovery.id)
			known_set[String(discovery.id)]=true
			WorldSimulation.figures.record_discovery(String(discovery.dynamic),String(discovery.name),current_day)
			society_model.register_discovery(discovery,catalog)
			var event := player_facing_discovery_event({"day": current_day, "id":discovery.id, "name": discovery.name, "description": discovery.observation, "ability_reason":String(discovery.get("ability_reason","")),"social_consequence":String(discovery.get("social_consequence","")),"effect_summary":_discovery_effect_summary(discovery),"direction":discovery.dynamic,"dynamic":discovery.dynamic,"subcategory":discovery.subcategory,"effects":discovery.get("effects",{}).duplicate(true),"adoption":society_model.adoption(String(discovery.id))})
			# The line whose team proved it: its turns count from the log (_team_turns).
			event["team_line"]=home[0]
			WorldSimulation.state.discovery_log.push_front(event)
			if WorldSimulation.state.discovery_log.size()>512: WorldSimulation.state.discovery_log.resize(512)
			WorldSimulation.state.active_investigations.erase(channel)
			WorldSimulation.state.discovery_progress.erase(discovery_id)
			results.append(event)
	if not stepped.is_empty():
		# Trial use starts with the step (SocietyModel trial levels).
		society_model._rebuild_effect_totals(catalog)
		_team_memo.steps.append_array(stepped)
		if _team_memo.steps.size()>32: _team_memo.steps=_team_memo.steps.slice(_team_memo.steps.size()-32)
	if not results.is_empty():
		var held:=WorldSimulation.state.active_investigations.duplicate()
		_refresh_active_investigations()
		_note_freed_teams(results,held)
	return results

## Settles the teams now, reading every line's questions (a request from outside
## the day's step).
func refresh_investigations()->void:
	initialize()
	_refresh_active_investigations(true)


func set_domain_research_priority(dynamic_id:String,weight:int)->void:
	initialize()
	if not WorldSimulation.state.research_subcategory_allocations.has(dynamic_id): return
	var bounded_weight:=clampi(weight,0,12)
	WorldSimulation.state.research_allocations[dynamic_id]=bounded_weight
	_auto_allocate_domain_attention(dynamic_id,bounded_weight,int(floor(WorldSimulation.state.elapsed_days)))
	_refresh_active_investigations(true)


func _auto_allocate_domain_attention(dynamic_id:String,weight:int,current_day:int)->void:
	# The player chooses one macro emphasis. Programs distribute that fixed attention
	# among the domain's four possible problem areas according to viable evidence,
	# lived activity and civilizational affinity. This is a constant 4-channel pass,
	# independent of population and hidden discoveries.
	var subcategories:Dictionary=(WorldSimulation.state.research_subcategory_allocations.get(dynamic_id,{}) as Dictionary).duplicate(true)
	if subcategories.is_empty(): return
	for subcategory in subcategories: subcategories[subcategory]=0
	WorldSimulation.state.research_subcategory_allocations[dynamic_id]=subcategories
	var channels:Array[Dictionary]=[]
	for subcategory_variant in subcategories:
		var subcategory:=String(subcategory_variant)
		var channel:=_channel_key(dynamic_id,subcategory)
		var candidate:=_best_candidate_for_channel(channel,current_day)
		if not candidate.is_empty(): channels.append({"subcategory":subcategory,"candidate":candidate,"live":true})
	# If evidence is temporarily unavailable, preserve the broad priority as quiet
	# preparatory attention rather than deleting it or leaking it into another domain.
	if channels.is_empty():
		for subcategory_variant in subcategories:
			channels.append({"subcategory":String(subcategory_variant),"candidate":{},"live":false})
	for _unit in maxi(0,weight):
		var best:Dictionary={}
		var best_score:=-INF
		for channel_data in channels:
			var subcategory:=String(channel_data.subcategory)
			var assigned:=int((WorldSimulation.state.research_subcategory_allocations[dynamic_id] as Dictionary).get(subcategory,0))
			var candidate:Dictionary=channel_data.candidate
			var score:=_candidate_score(candidate) if not candidate.is_empty() else float(posmod(hash("%s:%s:%s:auto_research" % [WorldSimulation.state.world_seed,dynamic_id,subcategory]),10_000))/100.0
			score-=float(assigned)*14.0
			if score>best_score:
				best_score=score
				best=channel_data
		if best.is_empty(): break
		var target:=String(best.subcategory)
		var allocations:Dictionary=WorldSimulation.state.research_subcategory_allocations[dynamic_id]
		allocations[target]=int(allocations.get(target,0))+1
		WorldSimulation.state.research_subcategory_allocations[dynamic_id]=allocations

func active_investigation_records()->Array[Dictionary]:
	initialize()
	begin_research_scan()
	_refresh_active_investigations()
	# One record per question. Two teams can hold the same question for a day
	# (its own line takes up a question another line borrowed as foundation
	# work, or the player chooses it); both are listed on its one record.
	var lines_by_id:Dictionary={}
	for channel in WorldSimulation.state.active_investigations:
		var id:=String(WorldSimulation.state.active_investigations.get(channel,""))
		if id=="": continue
		if not lines_by_id.has(id): lines_by_id[id]=[]
		(lines_by_id[id] as Array).append(String(channel))
	var records:Array[Dictionary]=[]
	var teams:=research_teams()
	var normal:=Research600.normal_team(float(WorldSimulation.state.population_exact))
	for id:String in lines_by_id:
		var discovery:=discovery_definition(id).duplicate(true)
		if discovery.is_empty(): continue
		var progress:=float(WorldSimulation.state.discovery_progress.get(id,0.0))
		var channels:Array=lines_by_id[id]
		var allocation:=0
		var followed:=0
		var research_capacity:={"researchers":0.0,"team_people":0.0,"workforce_share":0.0,"progress_multiplier":0.0,"support_multiplier":1.0}
		for channel:String in channels:
			var home:=_research_600_channel_home(channel) # research_600
			allocation+=_subcategory_allocation(home[0],home[1])
			followed=maxi(followed,_line_weight(home[0]))
			var line:=research_capacity_for(home[0],home[1],teams)
			for key:String in ["researchers","team_people","progress_multiplier"]: research_capacity[key]=float(research_capacity[key])+float(line.get(key,0.0))
			research_capacity["support_multiplier"]=float(line.get("support_multiplier",1.0))
		research_capacity["workforce_share"]=float(research_capacity.team_people)/maxf(0.000001,float(teams.researchers)) if float(teams.researchers)>0.0 else 0.0
		var leader_factor:=_leader_factor(String(discovery.get("dynamic","")))
		var material_evidence:=_resource_evidence(discovery.get("resource_requirements",[]))
		var daily:=daily_progress(discovery,float(research_capacity.progress_multiplier),leader_factor,material_evidence)
		discovery["discovery_name"]=String(discovery.get("name","Undetermined discovery"))
		discovery["name"]=String(discovery.get("name","Investigation"))
		discovery["progress"]=progress
		discovery["observer_allocation"]=allocation
		discovery["research_workforce"]=float(research_capacity.team_people)
		discovery["research_share"]=float(research_capacity.workforce_share)
		discovery["research_capacity_multiplier"]=float(research_capacity.progress_multiplier)
		discovery["teams_on"]=channels.size()
		discovery["normal_team"]=normal
		discovery["leader_factor"]=leader_factor
		discovery["material_evidence"]=material_evidence
		discovery["project_goal"]=_project_goal(discovery)
		discovery["project_method"]=_project_method(discovery)
		discovery["unlock_summary"]=String(discovery.get("observation",""))+"\n"+_discovery_effect_summary(discovery)
		discovery["bottleneck"]=_investigation_bottleneck(discovery,followed,leader_factor,material_evidence,progress,research_capacity)
		# The clock: days to proof at today's pace.
		discovery["estimated_days"]=ceili((1.0-progress)/maxf(0.000001,daily))
		discovery["stage"]=Research600.stage(progress)
		discovery["trial_share"]=Research600.trial_share(progress)
		discovery["years_ahead"]=research_years_ahead(discovery)
		discovery["work_factor"]=research_early_factor(discovery)
		# A young people's slow learning, beside the clock ("" at the usual pace).
		discovery["founding_note"]=founding_words()
		discovery["opens"]=questions_opened(id)
		discovery["channels"]=channels
		records.append(discovery)
	end_research_scan()
	return records


## A question's expected progress per day with a team of `team_multiplier`
## (research_capacity_for progress_multiplier): the day's own steps without
## their luck (process_day), the lines' activity included.
func daily_progress(discovery:Dictionary,team_multiplier:float,leader_factor:float=NAN,material_evidence:float=NAN)->float:
	if is_nan(leader_factor): leader_factor=_leader_factor(String(discovery.get("dynamic","")))
	if is_nan(material_evidence): material_evidence=_resource_evidence(discovery.get("resource_requirements",[]))
	var activity:=0.65
	for activity_signal in discovery.get("signals",[]): activity+=float(latest_context.get(activity_signal,0.0))*0.22
	var daily:=float(discovery.get("chance",0.001))/research_difficulty(discovery,WorldSimulation.state.world_seed)*team_multiplier*activity*material_evidence*leader_factor*WorldSimulation.consequences.discovery_multiplier()*(1.0+WorldSimulation.progression.effect("knowledge_rate"))*0.12
	return daily*Pathways.multiplier(discovery)*(.85 if Exchange.studying() else 1.0)


## Unknown questions that build on `id` (name it among their foundations).
func questions_opened(id:String)->int:
	var count:=0
	var known:=_scan_known()
	for index:Variant in foundation_children().get(id,[]):
		if not known.has(String((technology_catalog[int(index)] as Dictionary).get("id",""))): count+=1
	return count


func _default_line_name(discovery:Dictionary)->String:
	## Base-catalog discoveries carry no authored line name; draw a varied one
	## deterministically so the investigations page never reads as one
	## sentence repeated with the noun swapped.
	var templates:Array=DiscoveryFrontierCatalog.LINE_NAME_TEMPLATES
	var index:=absi(hash("%s:%s:line" % [WorldSimulation.state.world_seed,String(discovery.get("id",""))]))%templates.size()
	return String(templates[index]).format({"subject":String(discovery.get("subcategory","an unresolved condition")).to_lower(),"lens":"practical evidence"})


func _project_goal(discovery:Dictionary) -> String:
	var explicit:=String(discovery.get("question",""))
	if explicit!="": return explicit
	var subcategory:=String(discovery.get("subcategory","this condition")).to_lower()
	return "Can repeated evidence turn %s into a reliable, teachable advantage?" % subcategory


func _project_method(discovery:Dictionary) -> String:
	var explicit:=String(discovery.get("method",""))
	if explicit!="": return explicit
	var signals:Array=discovery.get("signals",[])
	var signal_text:=", ".join(PackedStringArray(signals)) if not signals.is_empty() else "daily work"
	return "Observers compare %s and preserve results until the method can be repeated." % signal_text


## An effect as a signed percentage that never reads "+0.0%": tenths from a
## tenth of a percent up, hundredths below that, "+<0.01%" at the smallest.
static func effect_percent(value:float)->String:
	var pct:=value*100.0
	if absf(pct)>=0.05:return "%+.1f%%" % pct
	if absf(pct)>=0.005:return "%+.2f%%" % pct
	return ("+" if pct>=0.0 else "-")+"<0.01%"


func _effect_summary(effects:Dictionary) -> String:
	if effects.is_empty(): return "Unlocks a prerequisite used by later practical methods."
	var parts:Array[String]=[]
	for effect_id in effects:
		var value:=float(effects[effect_id])
		parts.append("%s %s" % [String(EFFECT_DISPLAY_NAMES.get(String(effect_id),String(effect_id).replace("_"," "))).capitalize(),effect_percent(value)])
	return "ESTABLISHED CAPACITY CHANGE  •  "+"  •  ".join(parts)


## A work multiplier in words: "a little more work than usual", "about twice
## the usual work", "about six times the usual work".
static func work_words(factor:float)->String:
	if factor<1.05: return "the usual work"
	if factor<1.75: return "a little more work than usual"
	var whole:=roundi(factor)
	if whole<=2: return "about twice the usual work"
	return "about %s times the usual work" % (["","","","three","four","five","six","seven","eight","nine","ten"][whole] if whole<=10 else str(whole))


## What holds a question back, as a key and its words. Ahead of its age is
## told first, so a thin team never hides the price of working ahead; a thin
## team is one under a third of the team a people of this size would put on a
## question (Research600.normal_team); with nothing holding it back, its step.
func _investigation_bottleneck(discovery:Dictionary,allocation:int,leader_factor:float,material_evidence:float,progress:float,research_capacity:Dictionary={}) -> String:
	if allocation<=0: return "NO RESEARCH PRIORITY — project is paused"
	var ahead:=research_years_ahead(discovery)
	if ahead>=1.0: return "AHEAD OF ITS AGE — %d years early: %s" % [roundi(ahead),work_words(research_early_factor(discovery))]
	var team:=float(research_capacity.get("team_people",research_capacity.get("researchers",0.0)))
	var normal:=Research600.normal_team(float(WorldSimulation.state.population_exact))
	if team<normal*Research600.THIN_TEAM_FRACTION: return "RESEARCH WORKFORCE — a thin team: %s at it, where a people of our size would put %s on one question" % [people_words(team),people_words(normal)]
	if material_evidence<0.78: return "MATERIAL BASIS — survey or work the required resource"
	if era_cost_multiplier(discovery)>=2.0: return "BEYOND OUR SCHOLARSHIP — broader learning must mature before this question can be answered quickly"
	if leader_factor<0.72: return "LEADERSHIP — the responsible office is weak or vacant"
	var goods:=Research600.goods_factor(learning_goods_cover())
	if goods<0.9: return "LEARNING GOODS — the learners lack tallies, writing stuff and tools: learning goes at %d in 100 of its pace" % roundi(goods*100.0)
	if float(research_capacity.get("support_multiplier",1.0))<0.82: return "RESEARCH SUPPORT — food, tools, records, or administration are constraining the program"
	match Research600.stage(progress):
		0: return "EARLY EVIDENCE — gathering the first cases"
		1: return "REPLICATION — the first cases hold; %d in 100 households try it" % roundi(Research600.trial_share(progress)*100.0)
	return "VALIDATION — repeated with the same result; %d in 100 households use it" % roundi(Research600.trial_share(progress)*100.0)

## A number of people as the people would say it: "one person", "about 3 people".
static func people_words(amount:float)->String:
	if amount<0.75: return "less than one person"
	if amount<1.5: return "about one person"
	if amount<9.5: return "about %d people" % roundi(amount)
	return "about %d people" % (roundi(amount/5.0)*5)

## Opens a scan (see ResearchScan) for the acting people. Each call needs its
## end_research_scan; nested scans share the outermost one.
func begin_research_scan()->void:
	if _scan.depth==0:
		_scan.clear_batch()
		_scan.state=WorldSimulation.state
	_scan.depth+=1

func end_research_scan()->void:
	_scan.depth=maxi(0,_scan.depth-1)
	if _scan.depth==0:
		_scan.clear_batch()
		_scan.state=null

## True inside a scan of the acting people. A new calendar day or a new
## discovery count starts the scan's tables afresh.
func _scan_active()->bool:
	if _scan.depth<=0 or not is_same(_scan.state,WorldSimulation.state): return false
	var day:=int(floor(WorldSimulation.state.elapsed_days))
	var known_size:=WorldSimulation.state.known_discoveries.size()
	if day!=_scan.day or known_size!=_scan.known_size:
		_scan.clear_batch()
		_scan.day=day
		_scan.known_size=known_size
	return true

## The known discoveries as a set.
func _scan_known()->Dictionary:
	if not _scan_active():
		var fresh:Dictionary={}
		for id:String in WorldSimulation.state.known_discoveries: fresh[id]=true
		return fresh
	if not _scan.has_known:
		for id:String in WorldSimulation.state.known_discoveries: _scan.known[id]=true
		_scan.has_known=true
	return _scan.known

## _discovery_is_eligible, judged once per question inside a scan (with the
## known discoveries as a set, which answers exactly as the list does).
func _scan_eligible(discovery:Dictionary,current_day:int,known:Variant=null)->bool:
	if not _scan_active(): return _discovery_is_eligible(discovery,current_day,known)
	var id:=String(discovery.get("id",""))
	var cached:Variant=_scan.eligible.get(id)
	if cached==null:
		cached=_discovery_is_eligible(discovery,current_day,_scan_known())
		_scan.eligible[id]=cached
	return bool(cached)

## The acting society as the design conditions see it, once per scan.
func _player_society()->Dictionary:
	if not _scan_active(): return research_600_player_society()
	if not _scan.has_society:
		_scan.society=research_600_player_society()
		_scan.has_society=true
	return _scan.society

## The home ground's environment profile (read-only), once per scan.
func _home_environment()->Dictionary:
	if WorldSimulation.food==null: return {}
	if not _scan_active(): return WorldSimulation.food.current_environment_profile()
	if not _scan.has_environment:
		_scan.environment=WorldSimulation.food.current_environment_profile()
		_scan.has_environment=true
	return _scan.environment

## Research600.home_surface_resources of the acting people, once per scan.
func _home_surface_resources()->Dictionary:
	if not _scan_active(): return Research600.home_surface_resources(WorldSimulation.state.player_settlements,_home_environment())
	if not _scan.has_home_resources:
		_scan.home_resources=Research600.home_surface_resources(WorldSimulation.state.player_settlements,_home_environment())
		_scan.has_home_resources=true
	return _scan.home_resources

## Pathways.need, once per field inside a scan (it reads only the field and
## the society's housing, food and newcomers).
func _field_need(discovery:Dictionary)->float:
	if not _scan_active(): return Pathways.need(discovery)
	var domain:=String(discovery.get("dynamic",""))
	var cached:Variant=_scan.needs.get(domain)
	if cached==null:
		cached=Pathways.need(discovery)
		_scan.needs[domain]=cached
	return float(cached)

## A table of values fixed by a question and this world's seed.
func _seed_table(table_name:String)->Dictionary:
	var seed_value:=int(WorldSimulation.state.world_seed)
	if not _scan.seeded or _scan.seed_value!=seed_value:
		_scan.seed_tables={}
		_scan.seed_value=seed_value
		_scan.seeded=true
	var table:Variant=_scan.seed_tables.get(table_name)
	if table==null:
		table={}
		_scan.seed_tables[table_name]=table
	return table

## What a table of technology_catalog was read from: its size and end entries
## and the world seed. The catalog is fixed once initialized; tests that
## replace it change these.
func _catalog_basis()->Array:
	var size:=technology_catalog.size()
	return [size,technology_catalog[0] if size>0 else null,technology_catalog[size-1] if size>0 else null,int(WorldSimulation.state.world_seed)]

static func _same_basis(table:Array,basis:Array)->bool:
	return table.size()==basis.size() and int(table[0])==int(basis[0]) and is_same(table[1],basis[1]) and is_same(table[2],basis[2]) and int(table[3])==int(basis[3])

## technology_catalog entries of one field, in catalog order.
func _technology_entries(dynamic_id:String)->Array:
	var basis:=_catalog_basis()
	if not _same_basis(_scan.by_dynamic_basis,basis):
		_scan.by_dynamic={}
		for entry:Dictionary in technology_catalog:
			var field:=String(entry.get("dynamic",""))
			if not _scan.by_dynamic.has(field): _scan.by_dynamic[field]=[]
			(_scan.by_dynamic[field] as Array).append(entry)
		_scan.by_dynamic_basis=basis
	return _scan.by_dynamic.get(dynamic_id,[])

## Every foundation some question could name, with the ascending
## technology_catalog indices of the questions naming it: the requires,
## requires_all and requires_any of the question, of its learning routes and
## of its experimental alternative (Pathways.ALTERNATIVES). That covers the
## parents of every route Pathways.routes_for builds for it, imported copies
## included. Built with the catalog (initialize), so no day's step pays for it.
func foundation_children()->Dictionary:
	var basis:=_catalog_basis()
	if not _same_basis(_scan.children_basis,basis):
		var children:Dictionary={}
		for index in technology_catalog.size():
			var entry:Dictionary=technology_catalog[index]
			_name_children(children,entry,index)
			for route:Variant in entry.get("learning_routes",[]): _name_children(children,route,index)
			var alternate:Variant=Pathways.ALTERNATIVES.get(String(entry.get("id","")))
			if alternate is Dictionary: _name_children(children,alternate,index)
		_scan.children=children
		_scan.children_basis=basis
	return _scan.children

static func _name_children(children:Dictionary,spec:Dictionary,index:int)->void:
	for key:String in ["requires","requires_all"]:
		for id:Variant in spec.get(key,[]): _add_child(children,String(id),index)
	for group:Variant in spec.get("requires_any",[]):
		for id:Variant in group: _add_child(children,String(id),index)

static func _add_child(children:Dictionary,parent:String,index:int)->void:
	var listed:Variant=children.get(parent)
	if listed==null: children[parent]=[index]
	elif int((listed as Array)[-1])!=index: (listed as Array).append(index)

## Each technology_catalog entry's opening year (research_open_year), by
## index. Building it reads every entry's opening year once, in catalog order,
## as research_foundations always did on its first pass.
func technology_open_years()->PackedFloat64Array:
	var basis:=_catalog_basis()
	if not _same_basis(_scan.open_years_basis,basis):
		var years:=PackedFloat64Array()
		years.resize(technology_catalog.size())
		# research_open_year for every entry in turn, inlined: the same records,
		# made in the same order.
		var seed_value:=int(WorldSimulation.state.world_seed)
		if not technology_catalog.is_empty() and _open_year_seed!=seed_value: _open_year_cache.clear();_open_year_seed=seed_value
		for index in technology_catalog.size():
			var entry:Dictionary=technology_catalog[index]
			var id:=String(entry.get("id",""))
			var recorded:Variant=_open_year_cache.get(id)
			if recorded==null:
				recorded=Research600.open_year(float(entry.get("earliest_year",0.0)),_research_draw(id,seed_value,"open_year"))
				_open_year_cache[id]=recorded
			years[index]=float(recorded)
		_scan.open_years=years
		_scan.open_years_basis=basis
	return _scan.open_years

## `full`: free teams also read questions far ahead of their age today (see
## _place_free_teams); a change of plan by the player asks for it.
func _refresh_active_investigations(full:=false)->void:
	begin_research_scan()
	var current_day:=int(floor(WorldSimulation.state.elapsed_days))
	# A team keeps its question until it is proven. It lets go only when the
	# question is known, out of reach, or its line is no longer followed.
	for channel_variant in WorldSimulation.state.active_investigations.keys().duplicate():
		var channel:=String(channel_variant)
		var id:=String(WorldSimulation.state.active_investigations.get(channel,""))
		var discovery:=discovery_definition(id)
		if discovery.is_empty() or not _research_600_investigation_placed(channel,discovery) or _scan_known().has(id) or not _scan_eligible(discovery,current_day):
			WorldSimulation.state.active_investigations.erase(channel)
	var count:=int(research_teams().count)
	_release_extra_teams(count)
	_place_free_teams(current_day,count,full)
	_switch_to_quicker_questions(current_day)
	WorldSimulation.state.active_observations.clear()
	for record in active_investigation_records_shallow():
		WorldSimulation.state.active_observations.append(String(record.observation))
	end_research_scan()


# --- Research teams (begin) ----------------------------------------------------
# Teams carry questions (Research600.TEAMS_*). Each entry of
# active_investigations is one team: its key is the team's desk, a channel of a
# followed line, and its value the question it works until proof. A people
# fields Research600.team_count of its researchers on the lines; every team does
# an equal part of their whole work, so spreading attention never adds work.
# A followed line's share of the plan sets how often it gets a team (its turns,
# read from the discovery log); no line with a question of its age waits more
# than TEAM_MAX_WAIT_YEARS. A free team takes a question of its age from any
# followed line first, then one within NEAR_AGE_YEARS of its age, then one
# further ahead at the proportional extra work, the nearest band first
# (FAR_BANDS): lines help each other before working ahead, and a cheap lead in
# one line comes before another line's long leap.

## Transient team bookkeeping, never saved (an Object): the steps to proof
## reached since the chronicle last took them. Nothing here steers research, so
## a loaded game goes on exactly as the one that was saved.
class TeamMemo extends RefCounted:
	var steps:Array[Dictionary]=[]
var _team_memo:=TeamMemo.new()

## Whether the team at `channel` works the question the player chose for it
## (select_research_target): it keeps that question until it is proven.
func _pinned(channel:String)->bool:
	var id:=String(WorldSimulation.state.active_investigations.get(channel,""))
	return id!="" and String(WorldSimulation.state.research_targets.get(channel,""))==id

## How a question stands to its age: 0 its age has come, 1 within
## NEAR_AGE_YEARS of it, 2 further ahead (at the proportional extra work).
func age_bucket(discovery:Dictionary,year:float=NAN)->int:
	var ahead:=research_years_ahead(discovery,year)
	if ahead<=0.0: return 0
	return 1 if ahead<NEAR_AGE_YEARS else 2

## Bands of work further ahead than NEAR_AGE_YEARS (years ahead of the
## question's age, upper bounds): a free team takes work in the nearest band
## any followed line offers before work in a band further ahead.
const FAR_BANDS:=[10.0,20.0,35.0,60.0]
## The band beyond the last of FAR_BANDS (2 + FAR_BANDS.size()).
const TEAM_TIER_LAST:=6

## A question's band in the order free teams take work: 0 its age has come, 1
## within NEAR_AGE_YEARS of it, then 2 to TEAM_TIER_LAST by FAR_BANDS.
func team_tier(discovery:Dictionary,year:float=NAN)->int:
	var ahead:=research_years_ahead(discovery,year)
	if ahead<=0.0: return 0
	if ahead<NEAR_AGE_YEARS: return 1
	for index in FAR_BANDS.size():
		if ahead<=float(FAR_BANDS[index]): return 2+index
	return TEAM_TIER_LAST

## Where work of band `tier` stands in the order free teams take it. A line
## that has waited TEAM_MAX_WAIT_YEARS for a team counts its far work two bands
## nearer (never nearer than the first far band): it still gets its turn,
## unless its next question stands three bands or more further ahead than the
## nearest work any line offers.
static func _team_rank(tier:int,waiting:bool)->int:
	return maxi(2,tier-2) if waiting and tier>2 else tier

## The bands a line reads for a free team's `rank` (_team_rank).
static func _rank_tiers(rank:int,waiting:bool)->Array:
	if not waiting or rank<2: return [rank]
	if rank==2: return [2,3,4]
	return [rank+2] if rank+2<=TEAM_TIER_LAST else []

## A line's weight in the plan: its steps of attention over its channels.
func _line_weight(dynamic_id:String)->int:
	var total:=0
	for value:Variant in (WorldSimulation.state.research_subcategory_allocations.get(dynamic_id,{}) as Dictionary).values(): total+=maxi(0,int(value))
	return total

## The followed lines and their weights: {line: weight}.
func _team_lines()->Dictionary:
	var lines:Dictionary={}
	for dynamic_variant in WorldSimulation.state.research_subcategory_allocations:
		var weight:=_line_weight(String(dynamic_variant))
		if weight>0: lines[String(dynamic_variant)]=weight
	return lines

## Teams held by each line (by the line of the team's desk): {line: count}.
func _teams_by_line()->Dictionary:
	var held:Dictionary={}
	for channel_variant in WorldSimulation.state.active_investigations:
		var line:=_research_600_channel_home(String(channel_variant))[0]
		held[line]=int(held.get(line,0))+1
	return held

## Questions some team holds now: {id: true}.
func _busy_ids()->Dictionary:
	var busy:Dictionary={}
	for id:Variant in WorldSimulation.state.active_investigations.values(): busy[String(id)]=true
	return busy

## Each followed line's recent turns: its teams' proofs over TEAM_TURN_YEARS
## (from the discovery log; a proof names its team's line) plus the teams it
## holds now; and the day of its last proof (-1 when none is on record).
func _team_turns(lines:Dictionary,held:Dictionary,today:int)->Dictionary:
	var turns:Dictionary={}
	var last:Dictionary={}
	for line:String in lines:
		turns[line]=float(held.get(line,0))
		last[line]=-1
	var since:=float(today)-Research600.TEAM_TURN_YEARS*365.0
	for event_variant:Variant in WorldSimulation.state.discovery_log:
		if not event_variant is Dictionary: continue
		var event:Dictionary=event_variant
		var line:=String(event.get("team_line",event.get("dynamic","")))
		if not turns.has(line): continue
		var day:=int(event.get("day",0))
		if int(last[line])<0: last[line]=day
		if float(day)>=since: turns[line]=float(turns[line])+1.0
	return {"turns":turns,"last":last}

## One team more (+1) or fewer (-1) on `line`, in the counts a pick reads.
static func _count_turn(held:Dictionary,turns:Dictionary,line:String,change:int)->void:
	held[line]=int(held.get(line,0))+change
	var counts:Dictionary=turns.turns
	if counts.has(line): counts[line]=float(counts[line])+float(change)

## Years since `line` last proved a question (since the world began when it
## never has).
static func _line_wait_years(turns:Dictionary,line:String,today:int)->float:
	return float(today-maxi(0,int((turns.last as Dictionary).get(line,-1))))/365.0

## Each followed line's place in the queue for the next free team: a line that
## has gone TEAM_MAX_WAIT_YEARS without a team first (longest first), then the
## line furthest below its share of the recent turns (its weight's share of all
## turns, less its own): {line: [waiting, years waited, claim] as a sort key}.
func _turn_keys(lines:Dictionary,turns:Dictionary,held:Dictionary,today:int)->Dictionary:
	var weight_total:=0.0
	var turn_total:=0.0
	for line:String in lines:
		weight_total+=float(lines[line])
		turn_total+=float((turns.turns as Dictionary).get(line,0.0))
	var keys:Dictionary={}
	for line:String in lines:
		var waited:=_line_wait_years(turns,line,today)
		var waiting:=int(held.get(line,0))<=0 and waited>=Research600.TEAM_MAX_WAIT_YEARS
		var claim:=float(lines[line])/maxf(1.0,weight_total)*turn_total-float((turns.turns as Dictionary).get(line,0.0))
		keys[line]=[0.0 if waiting else 1.0,-waited if waiting else 0.0,-claim]
	return keys

## The placement a free team takes from `placements`: the nearest band first
## (a question of its age, then one within NEAR_AGE_YEARS of it, then each of
## FAR_BANDS; _team_rank); then the line whose turn it is (_turn_keys); then the
## best question. _next_team_placement finds the same placement without reading
## every row.
func _pick_team_placement(placements:Array,lines:Dictionary,turns:Dictionary,held:Dictionary,today:int)->Dictionary:
	var turn_keys:=_turn_keys(lines,turns,held,today)
	var best:Dictionary={}
	var best_key:Array=[]
	for placement:Dictionary in placements:
		var turn:Array=turn_keys.get(String(placement.line),[1.0,0.0,0.0])
		var key:Array=[float(_team_rank(int(placement.tier),float(turn[0])==0.0))]
		key.append_array(turn)
		key.append(-float(placement.score))
		if best.is_empty() or _key_before(key,best_key) or (_key_same(key,best_key) and String(placement.channel)<String(best.channel)):
			best=placement
			best_key=key
	return best

static func _key_before(key:Array,other:Array)->bool:
	for index in key.size():
		if is_equal_approx(float(key[index]),float(other[index])): continue
		return float(key[index])<float(other[index])
	return false

static func _key_same(key:Array,other:Array)->bool:
	return not _key_before(key,other) and not _key_before(other,key)

## Lines lending a team to foundation work (a desk holding another channel's
## question), the desk `also` left out: {line: true}. A line lends one team at a
## time, so a field waiting on others' foundations never fills its every desk.
func _lending_lines(also:String="")->Dictionary:
	var lending:Dictionary={}
	var active:Dictionary=WorldSimulation.state.active_investigations
	for desk_variant in active:
		var desk:=String(desk_variant)
		if desk==also: continue
		var held:=discovery_definition(String(active[desk]))
		if _channel_key(String(held.get("dynamic","")),String(held.get("subcategory","")))!=desk: lending[_research_600_channel_home(desk)[0]]=true
	return lending

## Where a free team can work in `line`, among questions of band `tier`
## (team_tier): the line's best question on each channel without a team (and
## `also`, a team looking again) whose best stands in that band; and, when
## none of its channels holds a question at least that near its age, its
## foundation work of that band. Rows: line, channel, id, tier, score.
func _line_placements(line:String,current_day:int,busy:Dictionary,tier:int,lending:Dictionary,also:String="")->Array:
	var rows:Array=[]
	var active:Dictionary=WorldSimulation.state.active_investigations
	var free:Array[String]=[]
	var own:=false
	var lends:=lending.has(line)
	for sub_variant in (WorldSimulation.state.research_subcategory_allocations.get(line,{}) as Dictionary):
		var channel:=_channel_key(line,String(sub_variant))
		if active.has(channel) and channel!=also: continue
		free.append(channel)
		var candidate:=_best_free_candidate(channel,current_day,busy,tier)
		if candidate.is_empty(): continue
		own=true
		if team_tier(candidate)!=tier: continue
		if not lends and Research600.deferred(String(candidate.get("id","")),society_model.ceiling_era):
			# research_3000: foundations of current questions before a dead end or leftover.
			var foundation:=_research_600_foundation_candidate(line,current_day,busy)
			if not foundation.is_empty() and team_tier(foundation)<=tier:
				var row:=_placement(line,channel,foundation)
				row["tier"]=tier
				rows.append(row)
				lends=true
				continue
		rows.append(_placement(line,channel,candidate))
	if not own and not lends and not free.is_empty():
		var foundation:=_research_600_foundation_candidate(line,current_day,busy)
		if not foundation.is_empty() and team_tier(foundation)==tier: rows.append(_placement(line,free[0],foundation))
	return rows

## The followed lines in the order their turns come (`turn_keys`, from
## _turn_keys). Lines that stand level share a group (their best question
## decides between them).
func _lines_by_turn(lines:Dictionary,turn_keys:Dictionary)->Array:
	var keyed:Array=[]
	for line:String in lines: keyed.append([turn_keys[line],line])
	keyed.sort_custom(func(a:Array,b:Array)->bool: return _key_before(a[0],b[0]) or (_key_same(a[0],b[0]) and String(a[1])<String(b[1])))
	var groups:Array=[]
	var last:Array=[]
	for entry:Array in keyed:
		if groups.is_empty() or not _key_same(entry[0],last): groups.append([])
		(groups[-1] as Array).append(String(entry[1]))
		last=entry[0]
	return groups

## The placement a free team takes, as _pick_team_placement would choose it
## from every row, read lazily: rank by rank (_team_rank), line by line in turn
## order, so a scan reads a band further ahead only when nothing nearer is open
## anywhere. No further than `max_rank`; {} when nothing is open.
func _next_team_placement(lines:Dictionary,turns:Dictionary,held:Dictionary,current_day:int,busy:Dictionary,also:String="",max_rank:int=TEAM_TIER_LAST,skip_channels:Dictionary={})->Dictionary:
	var turn_keys:=_turn_keys(lines,turns,held,current_day)
	var groups:=_lines_by_turn(lines,turn_keys)
	var lending:=_lending_lines(also)
	for rank in range(0,max_rank+1):
		for group:Array in groups:
			var best:Dictionary={}
			for line:String in group:
				for tier:int in _rank_tiers(rank,float((turn_keys[line] as Array)[0])==0.0):
					for row:Dictionary in _line_placements(line,current_day,busy,tier,lending,also):
						if skip_channels.has(String(row.channel)): continue
						if best.is_empty() or float(row.score)>float(best.score) or (is_equal_approx(float(row.score),float(best.score)) and String(row.channel)<String(best.channel)): best=row
			if not best.is_empty(): return best
	return {}

func _placement(line:String,channel:String,discovery:Dictionary)->Dictionary:
	return {"line":line,"channel":channel,"id":String(discovery.get("id","")),"tier":team_tier(discovery),"score":_candidate_score(discovery)}

## The channel's best open question that no team holds yet (in its nearest
## band, and no further from its age than `max_tier`).
func _best_free_candidate(channel:String,current_day:int,busy:Dictionary,max_tier:int=TEAM_TIER_LAST)->Dictionary:
	if max_tier<2: return _score_best_candidate(channel,current_day,busy,max_tier)
	var best:=_best_candidate_for_channel(channel,current_day)
	if best.is_empty() or not busy.has(String(best.get("id",""))): return best
	return _score_best_candidate(channel,current_day,busy)

## Fewer researchers, fewer teams: the teams with the most work still ahead of
## them stop first (a question far ahead of its age, or barely begun), so a
## question nearly proven keeps its team; their progress stays with the
## question. A question the player chose keeps its team.
func _release_extra_teams(count:int)->void:
	var active:Dictionary=WorldSimulation.state.active_investigations
	var pins:=0
	var order:Array=[]
	for channel_variant in active:
		var channel:=String(channel_variant)
		if _pinned(channel): pins+=1
		else: order.append([_expected_work(discovery_definition(String(active[channel]))),channel])
	var extra:=active.size()-maxi(count,pins)
	if extra<=0: return
	order.sort_custom(func(a:Array,b:Array)->bool: return float(a[0])>float(b[0]) if not is_equal_approx(float(a[0]),float(b[0])) else String(a[1])<String(b[1]))
	for index in mini(extra,order.size()): active.erase(String(order[index][1]))

## Free teams take up questions (see the section's notes). A question the player
## chose is taken up first and may hold a team beyond the count. Questions of
## their age and near it are read every day; free teams read further ahead once
## in each block of SWITCH_CHECK_DAYS days, on a day a question is proven, or
## when `full` asks: such a look reads every line's questions, and on the days
## between it would find nothing new. The rule reads only the saved state and
## the calendar, so a loaded game places its teams as the saved one would have.
func _place_free_teams(current_day:int,count:int,full:=false)->void:
	var active:Dictionary=WorldSimulation.state.active_investigations
	var lines:=_team_lines()
	if lines.is_empty(): return
	var pins:=0
	for channel_variant in WorldSimulation.state.research_targets:
		var channel:=String(channel_variant)
		var id:=String(WorldSimulation.state.research_targets[channel])
		if String(active.get(channel,""))==id:
			pins+=1
			continue
		if active.has(channel) or not lines.has(_research_600_channel_home(channel)[0]): continue
		var target:=discovery_definition(id)
		if target.is_empty() or _scan_known().has(id) or not _scan_eligible(target,current_day): continue
		active[channel]=id
		pins+=1
	var capacity:=maxi(count,pins)
	if active.size()>=capacity: return
	var log:Array=WorldSimulation.state.discovery_log
	var proved_today:=not log.is_empty() and log[0] is Dictionary and int((log[0] as Dictionary).get("day",-1))==current_day
	var reach:=1
	if full or proved_today or floori(float(current_day)/SWITCH_CHECK_DAYS)!=floori(float(_research_600_return_day)/SWITCH_CHECK_DAYS):
		reach=TEAM_TIER_LAST
		_research_600_return_day=current_day
	var busy:=_busy_ids()
	var held:=_teams_by_line()
	var turns:=_team_turns(lines,held,current_day)
	while active.size()<capacity:
		var pick:=_next_team_placement(lines,turns,held,current_day,busy,"",reach)
		if pick.is_empty(): break
		active[String(pick.channel)]=String(pick.id)
		busy[String(pick.id)]=true
		_count_turn(held,turns,String(pick.line),1)

## Once a month each team working ahead of its age looks again: a question of
## its age on any followed line takes the team; failing that, for a team more
## than FAR_BANDS[1] years ahead, the work a free team would take when it
## stands two bands nearer its age or more and is SWITCH_MARGIN less work;
## failing that, a much quicker question (SWITCH_MARGIN less work) in its own
## channel. The progress made stays with the question for later. A question the
## player chose keeps its team. The teams look together on the first day of each
## block of SWITCH_CHECK_DAYS days, so the month's reading of every line is done
## once; a team placed during a block first looks in the next.
const SWITCH_CHECK_DAYS:=30
const SWITCH_MARGIN:=1.5
## The day each desk's team last looked again ({channel: day}).
var _switch_checked:Dictionary={}

func _expected_work(discovery:Dictionary)->float:
	var progress:=float(WorldSimulation.state.discovery_progress.get(String(discovery.get("id","")),0.0))
	return (1.0-progress)*research_difficulty(discovery,WorldSimulation.state.world_seed)/maxf(0.000001,float(discovery.get("chance",0.001)))

func _switch_to_quicker_questions(current_day:int)->void:
	var active:Dictionary=WorldSimulation.state.active_investigations
	var ahead:Array=[]
	for channel_variant in active:
		var channel:=String(channel_variant)
		# Once in each block of SWITCH_CHECK_DAYS days; a desk new to the record
		# first looks in the next block.
		if not _switch_checked.has(channel): _switch_checked[channel]=current_day
		if floori(float(current_day)/SWITCH_CHECK_DAYS)==floori(float(int(_switch_checked[channel]))/SWITCH_CHECK_DAYS): continue
		_switch_checked[channel]=current_day
		var current:=discovery_definition(String(active[channel]))
		if current.is_empty() or _pinned(channel): continue
		var years:=research_years_ahead(current)
		if years>0.0: ahead.append([years,channel])
	if _switch_checked.size()>96:
		for desk:Variant in _switch_checked.keys():
			if not active.has(desk): _switch_checked.erase(desk)
	if ahead.is_empty(): return
	ahead.sort_custom(func(a:Array,b:Array)->bool: return float(a[0])>float(b[0]) if not is_equal_approx(float(a[0]),float(b[0])) else String(a[1])<String(b[1]))
	var lines:=_team_lines()
	var held:=_teams_by_line()
	var turns:=_team_turns(lines,held,current_day)
	var busy:=_busy_ids()
	for entry:Array in ahead:
		var channel:=String(entry[1])
		if not active.has(channel): continue
		var current:=discovery_definition(String(active[channel]))
		var current_id:=String(current.get("id",""))
		var line:=_research_600_channel_home(channel)[0]
		busy.erase(current_id)
		# Questions of their age first: the monthly look stays cheap.
		_count_turn(held,turns,line,-1)
		var best:=_next_team_placement(lines,turns,held,current_day,busy,channel,0)
		var tier:=team_tier(current)
		if best.is_empty() and tier>=4:
			# Far ahead: the work a free team would take, two bands nearer or more.
			# Only this team's own line may count as waiting here: another waiting
			# line's turn comes with the next team a proof frees, and a team far
			# ahead moves only to nearer, cheaper work.
			var others:=held.duplicate()
			for other:String in lines:
				if other!=line: others[other]=maxi(1,int(others.get(other,0)))
			var nearer:=_next_team_placement(lines,turns,others,current_day,busy,channel,tier-2)
			if not nearer.is_empty() and int(nearer.tier)<=tier-2 and String(nearer.id)!=current_id and _expected_work(discovery_definition(String(nearer.id)))*SWITCH_MARGIN<_expected_work(current): best=nearer
		_count_turn(held,turns,line,1)
		if best.is_empty() and channel==_channel_key(String(current.get("dynamic","")),String(current.get("subcategory",""))):
			# In its own channel, a much quicker question (SWITCH_MARGIN less work).
			var quicker:=_best_free_candidate(channel,current_day,busy)
			if not quicker.is_empty() and String(quicker.get("id",""))!=current_id and _expected_work(quicker)*SWITCH_MARGIN<_expected_work(current): best=_placement(line,channel,quicker)
		if best.is_empty():
			busy[current_id]=true
			continue
		active.erase(channel)
		_count_turn(held,turns,line,-1)
		active[String(best.channel)]=String(best.id)
		busy[String(best.id)]=true
		_count_turn(held,turns,String(best.line),1)

## The questions the teams freed by today's proofs took up, kept on each proof's
## record ("next"): for a season the research dock offers that team the next
## best questions instead (team_choices). Only the player's people is offered.
func _note_freed_teams(results:Array,held:Dictionary)->void:
	if WorldSimulation.state!=GameState: return
	var taken:Array=[]
	for channel_variant in WorldSimulation.state.active_investigations:
		var channel:=String(channel_variant)
		var id:=String(WorldSimulation.state.active_investigations[channel])
		if String(held.get(channel,""))!=id: taken.append({"channel":channel,"id":id})
	for index in mini(taken.size(),results.size()):
		(results[index] as Dictionary)["next"]=taken[index]

## Steps to proof reached since the last call (first cases, repeated), oldest
## first; the chronicle tells them in the season's tally.
func take_research_steps()->Array[Dictionary]:
	var steps:=_team_memo.steps
	_team_memo.steps=[]
	return steps
## How long a freed team's choice stays open: a season. Past it the question
## the team took up stays its own (the default).
const CHOICE_DAYS:=91

## Free-team choices for the research dock, newest first. A team freed by a
## proof this season took up the best question open to it (the default); the
## player may send it to one of the next best two instead. Each choice: the
## proof that freed the team, the question it took, the days left to choose,
## and its options (choice_option).
func team_choices(limit:int=2)->Array[Dictionary]:
	initialize()
	var result:Array[Dictionary]=[]
	var today:=int(floor(WorldSimulation.state.elapsed_days))
	var active:Dictionary=WorldSimulation.state.active_investigations
	begin_research_scan()
	for event_variant:Variant in WorldSimulation.state.discovery_log:
		if not event_variant is Dictionary: continue
		var event:Dictionary=event_variant
		var day:=int(event.get("day",0))
		if today-day>CHOICE_DAYS: break
		if event.has("choice") or not event.get("next") is Dictionary: continue
		var next:Dictionary=event.next
		var channel:=String(next.get("channel",""))
		var taken:=String(next.get("id",""))
		if String(active.get(channel,""))!=taken: continue
		var options:=_choice_options(channel,taken,today)
		if options.size()<2: continue
		result.append({"key":choice_key(event),"proved":String(event.get("name","")),"proved_id":String(event.get("id","")),"day":day,
			"channel":channel,"taken":taken,"days_left":maxi(0,CHOICE_DAYS-(today-day)),"options":options})
		if result.size()>=limit: break
	end_research_scan()
	return result

static func choice_key(event:Dictionary)->String:
	return "%d:%s" % [int(event.get("day",0)),String(event.get("id",""))]

## The question a freed team took (first) and the next two it would take in
## its place, in the order a free team chooses (_pick_team_placement).
func _choice_options(channel:String,taken:String,today:int)->Array[Dictionary]:
	var options:Array[Dictionary]=[]
	var lines:=_team_lines()
	if lines.is_empty(): return options
	var busy:=_busy_ids()
	var held:=_teams_by_line()
	var home:=_research_600_channel_home(channel)[0]
	var turns:=_team_turns(lines,held,today)
	_count_turn(held,turns,home,-1)
	options.append(choice_option(channel,taken))
	var used:Dictionary={}
	while options.size()<3:
		var pick:=_next_team_placement(lines,turns,held,today,busy,channel,TEAM_TIER_LAST,used)
		if pick.is_empty(): break
		options.append(choice_option(String(pick.channel),String(pick.id)))
		busy[String(pick.id)]=true
		used[String(pick.channel)]=true
	return options

## One option of a free team's choice: the question, its field, the team's
## time to proof at today's pace, its effects at full use, how many questions
## it opens, and how far ahead of its age it stands.
func choice_option(channel:String,id:String)->Dictionary:
	var discovery:=discovery_definition(id)
	var home:=_research_600_channel_home(channel)
	var capacity:=research_capacity_for(home[0],home[1])
	var daily:=daily_progress(discovery,float(capacity.progress_multiplier))
	var progress:=float(WorldSimulation.state.discovery_progress.get(id,0.0))
	return {"id":id,"channel":channel,"name":String(discovery.get("name",id)),"dynamic":String(discovery.get("dynamic","")),
		"days":ceili((1.0-progress)/maxf(0.000001,daily)),"progress":progress,"effects":(discovery.get("effects",{}) as Dictionary).duplicate(true),
		"opens":questions_opened(id),"years_ahead":research_years_ahead(discovery),"work_factor":research_early_factor(discovery),
		"observation":String(discovery.get("observation",""))}

## The player's choice for a freed team (`key` from team_choices): `id` is the
## question it took, which it keeps, or one of its other options, which it
## takes up instead until it is proven. The progress already made stays with
## the question it leaves.
func choose_team_question(key:String,id:String)->Dictionary:
	initialize()
	var today:=int(floor(WorldSimulation.state.elapsed_days))
	var active:Dictionary=WorldSimulation.state.active_investigations
	for event_variant:Variant in WorldSimulation.state.discovery_log:
		if not event_variant is Dictionary or choice_key(event_variant)!=key: continue
		var event:Dictionary=event_variant
		if event.has("choice"): return {"ok":false,"reason":"That choice was already made."}
		var next:Dictionary=event.get("next",{})
		var channel:=String(next.get("channel",""))
		var taken:=String(next.get("id",""))
		if String(active.get(channel,""))!=taken: return {"ok":false,"reason":"That team has moved on to other work."}
		if id==taken:
			event["choice"]="kept"
			return {"ok":true,"id":id}
		begin_research_scan()
		var options:=_choice_options(channel,taken,today)
		end_research_scan()
		for option:Dictionary in options:
			if String(option.id)!=id: continue
			active.erase(channel)
			active[String(option.channel)]=id
			WorldSimulation.state.research_targets[String(option.channel)]=id
			event["choice"]=id
			return {"ok":true,"id":id}
		return {"ok":false,"reason":"That question is no longer open to this team."}
	return {"ok":false,"reason":"The season for that choice has passed."}
# --- Research teams (end) ------------------------------------------------------


func _rebuild_research_domain_totals()->void:
	for dynamic_variant in WorldSimulation.state.research_subcategory_allocations:
		var total:=0
		for allocation in (WorldSimulation.state.research_subcategory_allocations[dynamic_variant] as Dictionary).values():
			total+=int(allocation)
		WorldSimulation.state.research_allocations[String(dynamic_variant)]=total

func active_investigation_records_shallow()->Array[Dictionary]:
	var records:Array[Dictionary]=[]
	for channel in WorldSimulation.state.active_investigations:
		var id:=String(WorldSimulation.state.active_investigations.get(channel,""))
		if id=="": continue
		var discovery:=discovery_definition(id)
		if not discovery.is_empty(): records.append(discovery)
	return records

func _discovery_is_eligible(discovery:Dictionary,current_day:int,known:Variant=null)->bool:
	if known==null:known=WorldSimulation.state.known_discoveries
	var id:=String(discovery.get("id",""))
	if id in known:return false
	# Most questions still wait on a shared foundation. Every check here is a
	# pure reading except an opening rule's readiness (it can repair its own
	# record), so outside those rules the foundations are settled first.
	if not OpeningOpportunities.RULES.has(id) and not Pathways.common_foundations_known(discovery,known):return false
	if not _path_is_viable(discovery):return false
	if not research_600_open(discovery,{},current_day):return false # research_600: era and design conditions
	if not Research600.pursued(id,society_model.ceiling_era):return false # research_3000: superseded practice abandoned
	return OpeningOpportunities.ready(id) and Pathways.ready(discovery,current_day,known) and _resource_requirements_met(discovery.get("resource_requirements",[]))

## A line whose open questions all stand NEAR_AGE_YEARS or more ahead of their
## age lends its people to the lines of its field that have work of their own
## age; when the whole field is ahead, everyone works ahead at the proportional
## cost. No line ever sits idle and nobody has to move people by hand.
const NEAR_AGE_YEARS:=5.0

## True when the line has an open question within NEAR_AGE_YEARS of its age.
func _channel_has_candidate(channel:String,current_day:int)->bool:
	var candidates:=_candidate_index.candidates(channel,catalog_by_channel.get(channel,[]),WorldSimulation.state.known_discoveries)
	var known:Dictionary=_candidate_index.known
	var year:=learning_year(current_day)
	# _scan_eligible, inlined for the channel's many candidates.
	var scanning:=_scan_active()
	var memo:Dictionary=_scan.eligible
	var judged_known:Dictionary=_scan_known() if scanning else known
	for discovery:Dictionary in candidates:
		if research_years_ahead(discovery,year)>=NEAR_AGE_YEARS: continue
		var id:=String(discovery.get("id","")) if scanning else ""
		var eligible:Variant=memo.get(id) if scanning else null
		if eligible==null:
			eligible=_discovery_is_eligible(discovery,current_day,judged_known)
			if scanning: memo[id]=eligible
		if eligible: return true
	return false


## The fields with an eligible question (a ruler's research review): questions
## are judged in catalog order, each field's only until it shows one, and
## inside a scan through its memo (_scan_eligible, inlined).
func viable_fields(current_day:int,known:Dictionary)->Dictionary:
	var viable:Dictionary={}
	var scanning:=_scan_active()
	var memo:Dictionary=_scan.eligible
	var judged_known:Dictionary=_scan_known() if scanning else known
	for entry:Dictionary in technology_catalog:
		var field:=String(entry.dynamic)
		if viable.has(field):continue
		var id:=String(entry.get("id","")) if scanning else ""
		var eligible:Variant=memo.get(id) if scanning else null
		if eligible==null:
			eligible=_discovery_is_eligible(entry,current_day,judged_known)
			if scanning: memo[id]=eligible
		if eligible:viable[field]=true
	return viable

## The line's best open question. Inside a scan it is chosen once for each
## allocation and chosen target of the line (the only inputs a scan changes).
func _best_candidate_for_channel(channel:String,current_day:int)->Dictionary:
	if not _scan_active(): return _score_best_candidate(channel,current_day)
	var home:=_research_600_channel_home(channel)
	var allocation:=_subcategory_allocation(home[0],home[1])
	var target:=String(WorldSimulation.state.research_targets.get(channel,""))
	var memo:Variant=_scan.best.get(channel)
	if memo is Array and int(memo[0])==allocation and String(memo[1])==target and int(memo[2])==current_day: return memo[3]
	var best:=_score_best_candidate(channel,current_day)
	_scan.best[channel]=[allocation,target,current_day,best]
	return best


## The line's best open question, passing over the questions in `skip` (ids
## other teams hold) and any standing further from its age than `max_tier`
## (team_tier). Nearest first: the best question of the nearest band with one
## open (a question of its age, then within NEAR_AGE_YEARS, then each of
## FAR_BANDS), so a further band is read only when the nearer ones hold nothing
## open; a question the player chose wins wherever it stands.
func _score_best_candidate(channel:String,current_day:int,skip:Dictionary={},max_tier:int=TEAM_TIER_LAST)->Dictionary:
	var candidates:=_candidate_index.candidates(channel,catalog_by_channel.get(channel,[]),WorldSimulation.state.known_discoveries)
	var known:Dictionary=_candidate_index.known
	# _scan_eligible, inlined for the channel's many candidates.
	var scanning:=_scan_active()
	var memo:Dictionary=_scan.eligible
	var judged_known:Dictionary=_scan_known() if scanning else known
	var target:=String(WorldSimulation.state.research_targets.get(channel,""))
	if target!="" and not known.has(target) and not skip.has(target):
		var chosen:Dictionary=catalog_by_id.get(target,{})
		if not chosen.is_empty() and _channel_key(String(chosen.get("dynamic","")),String(chosen.get("subcategory","")))==channel:
			var open:Variant=memo.get(target) if scanning else null
			if open==null:
				open=_discovery_is_eligible(chosen,current_day,judged_known)
				if scanning: memo[target]=open
			if open: return chosen
	var year:=learning_year()
	var by_age:=_channel_by_age(channel,candidates)
	var index:=0
	for tier in range(0,max_tier+1):
		var best:Dictionary={}
		var best_score:=-INF
		while index<by_age.size():
			var discovery:Dictionary=by_age[index]
			if team_tier(discovery,year)>tier: break
			index+=1
			var id:=String(discovery.get("id",""))
			if id==target or (not skip.is_empty() and skip.has(id)): continue
			var eligible:Variant=memo.get(id) if scanning else null
			if eligible==null:
				eligible=_discovery_is_eligible(discovery,current_day,judged_known)
				if scanning: memo[id]=eligible
			if not eligible: continue
			var score:=_candidate_score(discovery)
			if score>best_score:
				best_score=score
				best=discovery
		if not best.is_empty(): return best
	return {}

## A channel's open questions (`candidates`, those not yet known) in order of
## their opening years, kept while that list stands: a look for questions of
## their age reads only the front of it.
func _channel_by_age(channel:String,candidates:Array)->Array:
	var cached:Variant=_scan.by_age.get(channel)
	if cached is Array and is_same((cached as Array)[0],candidates): return (cached as Array)[1]
	var opens:Dictionary={}
	for discovery:Dictionary in candidates: opens[String(discovery.get("id",""))]=research_open_year(discovery)
	var by_age:=candidates.duplicate()
	by_age.sort_custom(func(a:Dictionary,b:Dictionary)->bool:
		var first:=float(opens[String(a.get("id",""))]);var second:=float(opens[String(b.get("id",""))])
		return first<second if first!=second else String(a.get("id",""))<String(b.get("id","")))
	_scan.by_age[channel]=[candidates,by_age]
	return by_age


# Each world has a different but generous subset of the 4,608 latent routes.
# Availability is decided per entire investigative tradition, not per person or
# per day, so it is reproducible, save-free, and constant-time at population scale.
func _path_is_viable(discovery:Dictionary,civilization_seed:int=0)->bool:
	# Old generated maturity/lens entries remain readable for saved bonuses and
	# history, but are retired from both player and rival research pools.
	if bool(discovery.get("frontier",false)): return false
	# research_3000: each world offers a seeded subset of the registry's dead ends.
	var id:=String(discovery.get("id",""))
	if civilization_seed!=0: return _registry_route_offered(id,civilization_seed)
	# Fixed by the question and this world's seed: worked out once.
	var offered:=_seed_table("route offered")
	var cached:Variant=offered.get(id)
	if cached==null:
		cached=_registry_route_offered(id,int(WorldSimulation.state.world_seed))
		offered[id]=cached
	return bool(cached)

## False only for a registry dead end this world's people never meet.
func _registry_route_offered(id:String,seed_value:int)->bool:
	return not (Research600.has(id) and not Research600.dead_end_offered(id,_research_draw(id,seed_value,"dead_end")))

func _legacy_path_was_viable(discovery:Dictionary,civilization_seed:int=0)->bool:
	if not bool(discovery.get("frontier",false)): return true
	var seed_value:=WorldSimulation.state.world_seed if civilization_seed==0 else civilization_seed
	var path_key:=String(discovery.get("path_key",discovery.get("id","")))
	var channel:=_channel_key(String(discovery.get("dynamic","")),String(discovery.get("subcategory","")))
	var lens_index:=int(discovery.get("lens_index",0))
	# Every subcondition always has at least two viable traditions. The remaining
	# routes are contingent, giving worlds meaningful divergence without dead ends.
	var guaranteed_a:=posmod(hash("%s:%s:anchor" % [seed_value,channel]),DiscoveryFrontierCatalog.LENSES.size())
	var guaranteed_b:=posmod(guaranteed_a+3+posmod(hash("%s:%s:counter" % [seed_value,channel]),4),DiscoveryFrontierCatalog.LENSES.size())
	if lens_index==guaranteed_a or lens_index==guaranteed_b: return true
	return posmod(hash("%s:%s:viability" % [seed_value,path_key]),10_000)<FRONTIER_PATH_AVAILABILITY


## Score a line gives up for each extra "usual work" a question ahead of its
## age costs (research_early_factor - 1).
const EARLY_SCORE_PER_WORK:=60.0
## Age first: a question of its age always outranks one ahead of it, and one
## within NEAR_AGE_YEARS of its age outranks one further ahead (age_bucket).
const AGE_BUCKET_SCORE:=1000.0

func _candidate_score(discovery:Dictionary)->float:
	var id:=String(discovery.get("id",""))
	var score:=research_affinity(discovery,WorldSimulation.state.world_seed,_home_environment())
	var dynamic_id:=String(discovery.get("dynamic",""))
	var subcategory:=String(discovery.get("subcategory",""))
	var allocation:=_subcategory_allocation(dynamic_id,subcategory)
	score+=float(allocation)*8.0
	for signal_name in discovery.get("signals",[]):
		score+=clampf(float(latest_context.get(signal_name,0.0)),0.0,4.0)*13.0
	var subcategory_scores:Dictionary=WorldSimulation.state.society_subcategories.get(dynamic_id,{})
	score+=clampf(float(subcategory_scores.get(subcategory,0.0)),0.0,1.0)*12.0
	score+=_founding_lens_affinity(String(discovery.get("lens","")))*18.0
	# Once a society has invested in a viable tradition, its deeper methods have
	# a modest continuity advantage, but other routes can still overtake it.
	score+=float(discovery.get("stage_index",0))*3.5
	# Work far beyond current scholarship is slow; lines prefer questions of their
	# age. The penalty for being ahead grows with the extra work itself, so a line
	# goes ahead only when nothing of its own age is open.
	score-=log(era_cost_multiplier(discovery))/log(2.0)*20.0
	score-=(research_early_factor(discovery)-1.0)*EARLY_SCORE_PER_WORK
	# Age first: a question of its age outranks any question ahead of it.
	score-=AGE_BUCKET_SCORE*float(age_bucket(discovery))
	# research_3000: and they take up the current frontier before older leftovers.
	score-=Research600.staleness(id,society_model.ceiling_era)*20.0
	if Research600.dead_end(id): score-=Research600.DEAD_END_PENALTY
	score+=_field_need(discovery)+(35.0 if not Pathways.evidence(id).is_empty() else 0.0)
	return score


const FOUNDING_LENSES:Dictionary={
	"provision":["Seasonal Comparison","Household Experience","Environmental Contrast"],
	"generations":["Household Experience","Recorded Cases","Institutional Trial"],
	"inquiry":["Recorded Cases","Regional Comparison","Material Experiment"],
	"industry":["Material Experiment","Workplace Practice","Institutional Trial"],
	"defense":["Workplace Practice","Institutional Trial","Regional Comparison"],
	"exchange":["Regional Comparison","Seasonal Comparison","Recorded Cases"]
}

func _founding_lens_affinity(lens:String)->float:
	var focus:=WorldSimulation.state.founding_focus if WorldSimulation.state.founding_focus!="" else "provision"
	var list:Array=FOUNDING_LENSES.get(focus,[])
	var index:=list.find(lens)
	return 1.0-float(index)*0.22 if index>=0 else 0.0


# Saved discovery events are historical facts, but old saves may contain the
# former adjective-permutation titles and prose. Always resolve authored fields
# from the current definition so the repaired knowledge record takes effect
# without deleting a player's campaign.
func player_facing_discovery_event(source:Dictionary)->Dictionary:
	initialize()
	var event:=source.duplicate(true)
	var discovery_id:=String(event.get("id",""))
	var definition:Dictionary=catalog_by_id.get(discovery_id,{})
	if definition.is_empty(): return event
	for field in ["name","thread_key","thread_name","milestone_key","breakthrough_name","route_name","causal_mechanism","evidence_method","operating_capability","ability_reason","social_consequence","maturity","lens"]:
		if definition.has(field): event[field]=definition[field]
	event["dynamic"]=String(definition.get("dynamic",event.get("dynamic",event.get("direction","knowledge"))))
	event["direction"]=event["dynamic"]
	event["subcategory"]=String(definition.get("subcategory",event.get("subcategory","Established practice")))
	event["description"]=String(definition.get("causal_mechanism",definition.get("observation",event.get("description",""))))
	event["effects"]=(definition.get("effects",event.get("effects",{})) as Dictionary).duplicate(true)
	event["effect_summary"]=_discovery_effect_summary(definition)
	return event


# The library is organized around concrete bodies of knowledge rather than an
# archaeological dump of every survey/measurement/validation step. Each row is
# one practical thread; its details retain the actual breakthroughs, route,
# evidence, date, adoption, and cumulative consequences.
func established_knowledge_threads()->Array[Dictionary]:
	initialize()
	var log_signature:="%d:%d" % [WorldSimulation.state.discovery_log.size(),hash(WorldSimulation.state.discovery_log)]
	if log_signature==established_threads_signature:
		return established_threads_cache.duplicate(true)
	var by_thread:Dictionary={}
	var thread_order:Array[String]=[]
	for event_variant in WorldSimulation.state.discovery_log:
		if not event_variant is Dictionary: continue
		var event:=player_facing_discovery_event(event_variant)
		var definition:Dictionary=catalog_by_id.get(String(event.get("id","")),{})
		var dynamic_id:=String(event.get("dynamic",event.get("direction","knowledge")))
		var subcategory:=String(event.get("subcategory","Established practice"))
		var thread_key:=String(event.get("thread_key","%s::%s" % [dynamic_id,subcategory])) if bool(definition.get("frontier",false)) else String(event.get("id","%s::%s" % [dynamic_id,subcategory]))
		if not by_thread.has(thread_key):
			var thread:=event.duplicate(true)
			thread["thread_key"]=thread_key
			thread["name"]=String(event.get("thread_name",event.get("name",subcategory))) if bool(definition.get("frontier",false)) else String(event.get("name",subcategory))
			thread["legacy_refinement"]=bool(definition.get("frontier",false))
			thread["latest_breakthrough"]=String(event.get("name","Established practice"))
			thread["latest_stage_name"]=String(event.get("breakthrough_name","Established practice"))
			thread["breakthrough_count"]=0
			thread["raw_event_count"]=0
			thread["effects"]={}
			thread["history"]=[]
			thread["_milestones"]={}
			by_thread[thread_key]=thread
			thread_order.append(thread_key)
		var current:Dictionary=by_thread[thread_key]
		current["raw_event_count"]=int(current.get("raw_event_count",0))+1
		var history:Array=current.get("history",[])
		if history.size()<12: history.append(event)
		current["history"]=history
		var milestone_token:=String(event.get("milestone_key",event.get("id","")))
		var milestones:Dictionary=current.get("_milestones",{})
		if milestone_token=="" or not milestones.has(milestone_token):
			if milestone_token!="": milestones[milestone_token]=true
			current["breakthrough_count"]=int(current.get("breakthrough_count",0))+1
			var cumulative_effects:Dictionary=current.get("effects",{})
			for effect_id in (event.get("effects",{}) as Dictionary):
				cumulative_effects[effect_id]=float(cumulative_effects.get(effect_id,0.0))+float((event.effects as Dictionary)[effect_id])
			current["effects"]=cumulative_effects
		current["_milestones"]=milestones
		by_thread[thread_key]=current
	var result:Array[Dictionary]=[]
	for thread_key in thread_order:
		var thread:Dictionary=by_thread[thread_key]
		thread.erase("_milestones")
		var count:=int(thread.get("breakthrough_count",1))
		thread["description"]="Latest breakthrough: %s\n%s" % [String(thread.get("latest_breakthrough","Established practice")),String(thread.get("description",""))]
		thread["effect_summary"]=_effect_summary(thread.get("effects",{}))
		thread["record_summary"]="Archived practice · %d historical refinements · no further repeat research" % count if bool(thread.get("legacy_refinement",false)) else "Discovered once · day %d" % int(thread.get("day",0))
		result.append(thread)
	established_threads_signature=log_signature
	established_threads_cache=result.duplicate(true)
	return result


# Player-facing summaries intentionally describe only knowledge the civilization
# has established and the shape of its current frontier. Hidden candidate names,
# total route counts, and future order never leave this API.
func frontier_snapshot(dynamic_id:String)->Dictionary:
	initialize()
	var known:Array[Dictionary]=[]
	var recent:Array[Dictionary]=[]
	var lenses:Dictionary={}
	var subcategories:Dictionary={}
	var highest_maturity:=0
	for id_variant in WorldSimulation.state.known_discoveries:
		var definition:Dictionary=catalog_by_id.get(String(id_variant),{})
		if String(definition.get("dynamic",""))!=dynamic_id: continue
		known.append(definition)
		highest_maturity=maxi(highest_maturity,int(definition.get("maturity",1)))
		var lens:=String(definition.get("lens","Practical experience"))
		lenses[lens]=int(lenses.get(lens,0))+1
		var subcategory:=String(definition.get("subcategory","General practice"))
		subcategories[subcategory]=int(subcategories.get(subcategory,0))+1
	for event_variant in established_knowledge_threads():
		var event:Dictionary=event_variant
		if String(event.get("dynamic",event.get("direction","")))==dynamic_id:
			recent.append(event.duplicate(true))
			if recent.size()>=8: break
	var active:Array[Dictionary]=[]
	for record in active_investigation_records():
		if String(record.get("dynamic",""))==dynamic_id: active.append(record)
	var viable_now:=0
	var viable_later:=0
	var current_day:=int(floor(WorldSimulation.state.elapsed_days))
	for channel_variant in catalog_by_channel:
		var channel:=String(channel_variant)
		if not channel.begins_with(dynamic_id+"::"): continue
		for definition_variant in (catalog_by_channel[channel] as Array):
			var definition:Dictionary=definition_variant
			if String(definition.get("id","")) in WorldSimulation.state.known_discoveries or not _path_is_viable(definition): continue
			if _discovery_is_eligible(definition,current_day): viable_now+=1
			else: viable_later+=1
	var emphasis:Array[Dictionary]=[]
	var allocations:Dictionary=WorldSimulation.state.research_subcategory_allocations.get(dynamic_id,{})
	for subcategory in allocations:
		var observers:=int(allocations[subcategory])
		if observers>0: emphasis.append({"name":String(subcategory),"observers":observers})
	emphasis.sort_custom(func(a:Dictionary,b:Dictionary)->bool: return int(a.observers)>int(b.observers))
	var opportunity_signal:="QUIET"
	if viable_now>=12: opportunity_signal="ABUNDANT"
	elif viable_now>=4: opportunity_signal="SEVERAL LIVE LEADS"
	elif viable_now>0: opportunity_signal="NARROW LEADS"
	elif viable_later>0: opportunity_signal="LATENT"
	return {
		"domain":dynamic_id,"known_count":known.size(),"highest_maturity":highest_maturity,
		"subcategory_breadth":subcategories.size(),"tradition_breadth":lenses.size(),
		"traditions":_ranked_keys(lenses,4),"emphasis":emphasis,"active":active,
		"recent":recent,"opportunity_signal":opportunity_signal,"catalog_hidden":true
	}


func _ranked_keys(counts:Dictionary,limit:int)->Array[String]:
	var keys:Array=counts.keys()
	keys.sort_custom(func(a:Variant,b:Variant)->bool:
		var delta:=int(counts.get(a,0))-int(counts.get(b,0))
		return String(a)<String(b) if delta==0 else delta>0)
	var result:Array[String]=[]
	for index in mini(limit,keys.size()): result.append(String(keys[index]))
	return result


# Internal deterministic probes used by tests and rival simulation diagnostics.
# This is never called by UI code.
func candidate_ids_for_channel(channel:String,civilization_seed:int,limit:int=16)->Array[String]:
	initialize()
	var scored:Array[Dictionary]=[]
	for definition_variant in (catalog_by_channel.get(channel,[]) as Array):
		var definition:Dictionary=definition_variant
		if not _path_is_viable(definition,civilization_seed): continue
		scored.append({"id":String(definition.id),"score":posmod(hash("%s:%s" % [civilization_seed,definition.id]),10_000)})
	scored.sort_custom(func(a:Dictionary,b:Dictionary)->bool: return int(a.score)>int(b.score))
	var result:Array[String]=[]
	for index in mini(limit,scored.size()): result.append(String(scored[index].id))
	return result

func _alternative_research_stock_met(requirement:Dictionary)->bool:
	for resource:String in requirement.get("alternative_stocks",{}):
		var amount:=float(requirement.alternative_stocks[resource])
		if is_finite(amount) and amount>0.0 and float(WorldSimulation.state.resource_stockpiles.get(resource,0.0))>=amount:return true
	return false

func _resource_requirements_met(requirements: Array) -> bool:
	for requirement_variant in requirements:
		var requirement:Dictionary=requirement_variant
		var resource_name:=String(requirement.get("resource",""))
		var needed_stage:=String(requirement.get("stage","recognized"))
		var minimum_stock:=float(requirement.get("minimum_stock",0.0))
		var found:=_alternative_research_stock_met(requirement)
		for deposit in WorldSimulation.state.resource_deposits:
			if String(deposit.get("resource",""))!=resource_name:
				continue
			if _stage_rank(String(deposit.get("stage","unknown")))>=_stage_rank(needed_stage):
				found=true
				break
		if not found and float(WorldSimulation.state.resource_stockpiles.get(resource_name,0.0))>=minimum_stock and minimum_stock>0.0:
			found=true
		# The home ground's own clay, soil or timber is recognized and within reach
		# (dug from a bank, cut nearby) without a mapped deposit; only "developed"
		# needs worked ground. Requiring a mapped pit for bonfire firing stalled
		# every line whose questions descend from Pit Firing.
		if not found and _home_ground_supplies(resource_name,needed_stage): found=true
		if not found and bool(requirement.get("sample_sufficient",false)) and needed_stage in ["recognized","surveyed"]:
			found=preload("res://scripts/society_exchange.gd").studied_resource_sample(resource_name)
		if not found:
			return false
	return true

func _resource_evidence(requirements:Array)->float:
	if requirements.is_empty(): return 1.0
	var evidence:=0.0
	for requirement_variant in requirements:
		var requirement:Dictionary=requirement_variant
		var resource_name:=String(requirement.get("resource",""))
		var best:=0.0
		for deposit in WorldSimulation.state.resource_deposits:
			if String(deposit.get("resource",""))!=resource_name: continue
			var stage_score:=float(_stage_rank(String(deposit.get("stage","unknown"))))/4.0
			var worked:=clampf(float(deposit.get("lifetime_extracted",0.0))/200.0,0.0,0.35)
			best=maxf(best,0.65+stage_score*0.25+worked)
		if float(WorldSimulation.state.resource_stockpiles.get(resource_name,0.0))>0.0: best=maxf(best,0.82)
		if _home_ground_supplies(resource_name,String(requirement.get("stage","recognized"))): best=maxf(best,0.82)
		if _alternative_research_stock_met(requirement):best=maxf(best,0.82)
		evidence+=best
	return clampf(evidence/maxf(1.0,float(requirements.size())),0.55,1.25)

func _home_ground_supplies(resource_name:String,needed_stage:String)->bool:
	if _stage_rank(needed_stage)>_stage_rank("accessible") or not resource_name in Research600.HOME_SURFACE_RESOURCES: return false
	return _home_surface_resources().has(resource_name)

const STAGE_RANKS:Dictionary={"unknown":0,"recognized":1,"surveyed":2,"accessible":3,"developed":4}

func _stage_rank(stage:String)->int:
	return STAGE_RANKS.get(stage,0)

func effect(effect_id:String)->float:
	initialize()
	return society_model.effect(effect_id)

func refresh_operating_effects()->void:
	initialize()
	society_model._rebuild_effect_totals(catalog)
	WorldSimulation.state.knowledge_effects=society_model.effect_totals.duplicate(true)

func adoption(discovery_id:String)->float:
	return society_model.adoption(discovery_id)

## research_600: adoption less specialization neglect (SocietyModel.practiced).
func practiced(discovery_id:String)->float:
	return society_model.practiced(discovery_id)

func validate_catalog()->Array[String]:
	initialize()
	return society_model.validate_catalog(catalog)

func reset_society_clock()->void:
	society_model.last_processed_day=-1

func discovery_definition(discovery_id:String)->Dictionary:
	if not initialized:initialize()
	return catalog_by_id.get(discovery_id,{})

# The named-person government has seven canonical aptitudes. Specific fields
# of inquiry still differ, but they are composed from those visible skills so
# an excellent Scholar or Steward actually changes research throughput.
const RESEARCH_OFFICES:Dictionary={
	"demography":["Steward",["Provisioning","Diplomacy"]],"nutrition":["Quartermaster",["Provisioning","Logistics"]],
	"health":["Steward",["Provisioning","Knowledge"]],"labor":["Steward",["Administration","Construction"]],
	"knowledge":["Scholar",["Knowledge","Administration"]],"production":["Quartermaster",["Construction","Logistics"]],
	"infrastructure":["Steward",["Construction","Administration"]],"logistics":["Quartermaster",["Logistics","Administration"]],
	"ecology":["Scholar",["Knowledge","Provisioning"]],"institutions":["Steward",["Administration","Diplomacy"]],
	"security":["Marshal",["Defense","Administration"]],"culture":["Envoy",["Diplomacy","Knowledge"]]
}

func research_leadership(direction:String)->Dictionary:
	var assignment: Array = RESEARCH_OFFICES.get(direction,["Scholar",["Knowledge"]])
	var requested:=String(assignment[0])
	var actual:=WorldSimulation.government.executing_office(requested)
	var person:Dictionary=WorldSimulation.state.leadership_positions.get(actual,{})
	return {"requested_office":requested,"office":actual,"name":String(person.get("name","Vacant office")),"person_id":int(person.get("person_id",person.get("id",0))),"vacant":person.is_empty(),"acting":actual!=requested,"skills":assignment[1].duplicate()}

func _leader_factor(direction:String)->float:
	var leadership:=research_leadership(direction)
	return WorldSimulation.advisors.execution_modifier(leadership.requested_office,leadership.skills)*WorldSimulation.diplomacy.multiplier(direction)*WorldSimulation.figures.multiplier(direction)*WorldSimulation.direction.research_multiplier(direction)*WorldSimulation.communities.multiplier(direction)

## _leader_factor inside the day's research loop, where no office changes
## until a question is answered (which clears `offices`). `offices` keeps each
## requested office's executing office (GovernmentPeopleSystem.executing_office),
## so it is worked out once per office rather than twice per line; the steps
## after it are AdvisorSystem.execution_modifier's own, in its order.
func _loop_leader_factor(direction:String,offices:Dictionary)->float:
	var assignment:Array=RESEARCH_OFFICES.get(direction,["Scholar",["Knowledge"]])
	var requested:=String(assignment[0])
	var known_office:Variant=offices.get(requested)
	var executing:String=WorldSimulation.government.executing_office(requested) if known_office==null else String(known_office)
	offices[requested]=executing
	var advisor:Dictionary=WorldSimulation.state.leadership_positions.get(executing,{})
	var execution:float=WorldSimulation.advisors.execution_modifier_for_advisor(advisor,executing,(assignment[1] as Array).duplicate())
	if executing!=requested: execution*=0.84
	return clampf(execution,0.28,1.12)*WorldSimulation.diplomacy.multiplier(direction)*WorldSimulation.figures.multiplier(direction)*WorldSimulation.direction.research_multiplier(direction)*WorldSimulation.communities.multiplier(direction)

func research_assignment(discovery:Dictionary)->Dictionary:
	# Read the same assignment and capacity used by the daily simulation. Opening
	# the research UI must never refresh targets or redistribute anyone's time.
	var domain:=String(discovery.get("dynamic",""))
	var subcategory:=String(discovery.get("subcategory",""))
	var capacity:=research_capacity_for(domain,subcategory)
	var leadership:=research_leadership(domain)
	var id:=String(discovery.get("id",""))
	var channel:=_channel_key(domain,subcategory)
	var active:=String(WorldSimulation.state.active_investigations.get(channel,""))==id
	var evidence:=_resource_evidence(discovery.get("resource_requirements",[]))
	# Who would work it: a team (teams carry questions), and its part of the
	# people's hours at learning.
	capacity["researchers"]=float(capacity.team_people)
	capacity["workforce_share"]=float(capacity.team_people)/maxf(0.000001,float(capacity.total_researchers)) if float(capacity.total_researchers)>0.0 else 0.0
	return {"leader":leadership,"capacity":capacity,"active":active,"channel":channel,"current_target":String(WorldSimulation.state.active_investigations.get(channel,"")),"bottleneck":_investigation_bottleneck(discovery,_line_weight(domain),_leader_factor(domain),evidence,float(WorldSimulation.state.discovery_progress.get(id,0)),capacity) if active else "","method":_project_method(discovery) if active else ""}


func _subcategory_allocation(dynamic_id:String,subcategory:String)->int:
	return int((WorldSimulation.state.research_subcategory_allocations.get(dynamic_id,{}) as Dictionary).get(subcategory,0))


# Research allocation values are strategic weights, never person records. The
# Knowledge labor role supplies the aggregate workforce; emphasis shares it out
# by turns. One rule for every people: the community's whole work comes from
# its researchers alone (Research600.team_capacity) and it works in equal teams,
# each on one question until proof (Research600.team_count of them), so the same
# researchers make the same total progress under any emphasis and any ruler: a
# line's share sets how often it gets a team, never how much work there is.
# Every learner counts (no cap) and only learners count: research comes from
# the number of people at learning, never from the people's size. One
# question's people work at about n^0.85, so a billion learners never prove
# everything in a tick; knowledge, institutions, materials, goods and food
# compound the civilization's ability to use that scale.
#
# For a channel: "researchers" and "workforce_share" are the people its own
# steps of attention follow it with; "team_people" the people on a team working
# it (the team at work there, or one a free team would bring); "team_scale" that
# team's part of the community's work; "progress_multiplier" its pace.
func research_capacity_for(dynamic_id:String,subcategory:String,teams:Dictionary={})->Dictionary:
	if teams.is_empty(): teams=research_teams()
	var weight:=maxi(0,_subcategory_allocation(dynamic_id,subcategory))
	var total_weight:=int(teams.total_weight)
	var total_researchers:=float(teams.researchers)
	var workforce_share:=float(weight)/maxf(1.0,float(total_weight)) if weight>0 else 0.0
	var researchers:=total_researchers*workforce_share
	# Every team does an equal part of the whole work. A team at work shares it
	# with the teams at work (fewer questions than teams: they double up).
	var holds:=WorldSimulation.state.active_investigations.has(_channel_key(dynamic_id,subcategory))
	var sharing:=maxi(1,int(teams.placed) if holds else int(teams.count))
	var team_scale:=0.0
	var team_people:=0.0
	if _line_weight(dynamic_id)>0 and float(teams.work)>0.0:
		team_scale=float(teams.work)/float(sharing)
		team_people=float(teams.on_lines)/float(sharing)
	elif weight==0 and subcategory==_diffusion_subcategory(dynamic_id):
		team_scale=Research600.DIFFUSION_TEAM # research_3000: diffusion
	# Learners use goods (tallies, writing stuff, tools): short of them, learning
	# slows, to half at none (Research600.goods_factor).
	var goods_cover:=learning_goods_cover()
	var goods_factor:=Research600.goods_factor(goods_cover)
	var food_support:=lerpf(0.62,1.08,clampf(float(WorldSimulation.state.food_security),0.0,1.0))
	var material_capacity:=clampf(float(WorldSimulation.state.simulation_metrics.get("material_capacity",WorldSimulation.state.society_capacities.get("production",0.12))),0.0,1.2)
	var material_support:=lerpf(0.72,1.12,material_capacity/1.2)
	var institutional_capacity:=clampf(float(WorldSimulation.state.society_capacities.get("institutions",0.25)),0.0,1.0)
	# Each people is taught by its own schooling (the one being simulated).
	var education:=preload("res://scripts/civilization_indicators.gd").education_index(WorldSimulation.state)
	var support_multiplier:=food_support*material_support*lerpf(0.78,1.18,institutional_capacity)*lerpf(0.55,1.45,education)
	# A large people runs many investigations at once only by putting many
	# people to learning (team_count): nothing multiplies research with size alone.
	return {
		"weight":weight,"total_weight":total_weight,"total_researchers":total_researchers,
		"workforce_share":workforce_share,"researchers":researchers,"team_scale":team_scale,"team_people":team_people,
		"teams":int(teams.count),"placed":int(teams.placed),
		"education":education,"science_capacity":researchers*education,
		"goods_cover":goods_cover,"goods_factor":goods_factor,
		"support_multiplier":support_multiplier,"progress_multiplier":team_scale*support_multiplier*goods_factor*(1.0+preload("res://scripts/artifact_collection.gd").bonus(dynamic_id))*preload("res://scripts/realm_purse.gd").scholars_factor()
	}


## The research community as the teams share it: the emphasis total, the
## researchers, those on the lines (not on artifact study), their whole work
## (Research600.team_capacity), how many teams they field (Research600.team_count)
## and how many are at work. One reading serves every team of a day.
func research_teams()->Dictionary:
	var total_weight:=research_emphasis_total()
	var researchers:=maxf(0.0,float(WorldSimulation.state.effective_workers("Knowledge")))
	var per_step:=researchers/maxf(1.0,float(total_weight))
	var staffed:=0
	for dynamic_id in WorldSimulation.state.research_subcategory_allocations:
		for value in (WorldSimulation.state.research_subcategory_allocations[dynamic_id] as Dictionary).values():
			if int(value)>0: staffed+=int(value)
	var on_lines:=per_step*float(staffed)
	return {"total_weight":total_weight,"researchers":researchers,"on_lines":on_lines,"work":Research600.team_capacity(on_lines),
		"count":Research600.team_count(on_lines) if staffed>0 else 0,"placed":WorldSimulation.state.active_investigations.size()}


# --- Learning without a cap (docs/PEOPLE_FIRST.md A) ----------------------------
# Every learner counts (Research600.team_capacity), learners use goods, and a
# people that keeps more learners than its age can spare runs ahead of the
# calendar: its questions are dated against its own age (learning_year) and
# what it knows pays off to the age its knowledge reached (SocietyModel
# society_era). The same rules for every people, each in its own scope.

## The people's own age for research, in game years: the calendar on `day`
## (today when -1) plus the lead its learning has earned (learning_lead).
func learning_year(day:int=-1)->float:
	var calendar:=float(WorldSimulation.state.elapsed_days) if day<0 else float(day)
	return calendar/365.0+maxf(0.0,learning_lead)

## The day's learning: every learner takes goods from the realm's stores
## (Research600.goods_draw: home first, then the towns) and the lead moves with
## the learning done: the learners on the research lines, a learner without
## goods counting half, against the share the age can spare
## (Research600.lead_rate). A multi-day step covers `span` days.
func _advance_learning(current_day:int)->void:
	var learners:=maxf(0.0,float(WorldSimulation.state.effective_workers("Knowledge")))
	var span:=float(maxi(1,WorldSimulation.span))
	var drawn:=Research600.goods_draw(learners,span,true,learning_lead)
	_learning_day.day=current_day
	_learning_day.cover=float(drawn.cover)
	_learning_day.need=Research600.goods_need(learners,1.0,learning_lead)
	_learning_day.span=span
	_learning_day.places=drawn.places
	var on_lines:=float(research_teams().on_lines)
	learning_lead=maxf(0.0,learning_lead+learning_lead_rate(on_lines*Research600.goods_factor(float(drawn.cover)))*span/365.0)

## What the learners took from the place `place` ("" home, else a town id) in
## today's step, a day, and the goods its makers should keep for them before
## the next step: the home stores the realm learners' whole need for a step, a
## town what they took from it ({taken, wanted}; nothing on another day).
func learning_goods_today(place:String)->Dictionary:
	if _learning_day.day!=int(floor(WorldSimulation.state.elapsed_days)): return {"taken":0.0,"wanted":0.0}
	var span:=maxf(1.0,_learning_day.span)
	var taken:=float(_learning_day.places.get(place,0.0))
	return {"taken":taken/span,"wanted":_learning_day.need*span if place.is_empty() else taken}

## A young people's slow learning in plain words, from the engine's own number
## at the people's own age (Research600.founding_work): "A young people learns
## slowly: every question takes 2.2 times the work until year 15, easing to
## normal by year 30." Years are the calendar's (the people's lead counted).
## "" once it learns at the usual pace.
func founding_words()->String:
	var age:=learning_year()
	var factor:=Research600.founding_work(age)
	if factor<=1.0001: return ""
	var lead:=maxf(0.0,learning_lead)
	var times:=("%.1f" % factor).trim_suffix(".0")
	var normal:=maxi(1,roundi(Research600.FOUNDING_FADE_YEARS-lead))
	if age<Research600.FOUNDING_HOLD_YEARS:
		return "A young people learns slowly: every question takes %s times the work until year %d, easing to normal by year %d." % [times,maxi(1,roundi(Research600.FOUNDING_HOLD_YEARS-lead)),normal]
	return "A young people learns slowly: every question takes %s times the work now, easing to normal by year %d." % [times,normal]

## Share of the able people the age can spare as full-time learners
## (society_model.gd SUSTAINABLE_SPECIALISTS). It reads what the economy has
## reached (SocietyModel.economy_era: the calendar or the knowledge frontier,
## whichever is earlier), never the learners' own lead: a lead never pays for
## itself by making more learners sustainable. Past it learners cost upkeep and
## earn a lead.
func sustainable_learning_share()->float:
	return SocietyModelScript._rise(SocietyModelScript.SUSTAINABLE_SPECIALISTS,float(society_model.economy_era()))

## Years a year the lead moves with `learners` on the research lines (goods
## counted).
func learning_lead_rate(learners:float)->float:
	var able:=maxf(1.0,float(WorldSimulation.state.able_population()))
	return Research600.lead_rate(maxf(0.0,learners)/able,sustainable_learning_share())

## Share of the learners' goods the stores covered today (before today's step,
## what they would cover now).
func learning_goods_cover()->float:
	if _learning_day.day==int(floor(WorldSimulation.state.elapsed_days)): return _learning_day.cover
	return Research600.goods_cover(maxf(0.0,float(WorldSimulation.state.effective_workers("Knowledge"))),1.0,false,learning_lead)

## What learning does now and what `extra` more learners would add, in the
## engine's own numbers (the People view's learning row reads them):
## learners and teams (questions at once) now and with more; the work
## (team_capacity) now and with more, and the pace gain as a share;
## goods asked a day now and with more, the share the stores cover and the pace
## it allows; the lead in years and how it moves a year now and with more; the
## share of the able at learning and the share the age can spare.
func role_effect(role:String="Knowledge",extra:float=1.0)->Dictionary:
	if role!="Knowledge": return {}
	extra=maxf(0.0,extra)
	var teams:=research_teams()
	var learners:=float(teams.researchers)
	# More learners join the lines in the share the plan gives them now.
	var on_share:=float(teams.on_lines)/learners if learners>0.0 else (1.0 if int(teams.total_weight)>0 else 0.0)
	var more_on:=float(teams.on_lines)+extra*on_share
	var cover:=learning_goods_cover()
	var factor:=Research600.goods_factor(cover)
	var taken:=cover*Research600.goods_need(learners,1.0,learning_lead) if _learning_day.day==int(floor(WorldSimulation.state.elapsed_days)) else 0.0
	var held:=Research600.goods_held()
	var need_more:=Research600.goods_need(learners+extra,1.0,learning_lead)
	var cover_more:=clampf((held+taken)/need_more,0.0,1.0) if need_more>0.0 else 1.0
	var factor_more:=Research600.goods_factor(cover_more)
	var work:=float(teams.work)
	var work_more:=Research600.team_capacity(more_on)
	var able:=maxf(1.0,float(WorldSimulation.state.able_population()))
	return {"role":role,"extra":extra,"learners":learners,
		"teams":int(teams.count),"teams_more":Research600.team_count(more_on) if more_on>0.0 else 0,
		"work":work,"work_more":work_more,
		"pace_gain":(work_more*factor_more)/(work*factor)-1.0 if work*factor>0.0 else (1.0 if work_more>0.0 else 0.0),
		"goods_a_day":Research600.goods_need(learners,1.0,learning_lead),"goods_a_day_more":need_more,
		"goods_per_learner":Research600.goods_per_learner_day(learning_lead),
		"goods_cover":cover,"goods_factor":factor,"goods_held":held,
		"lead_years":maxf(0.0,learning_lead),"lead_rate":learning_lead_rate(float(teams.on_lines)*factor),"lead_rate_more":learning_lead_rate(more_on*factor_more),
		"share":learners/able,"sustainable_share":sustainable_learning_share(),"learning_year":learning_year()}


func research_emphasis_total()->int:
	var total:=0
	for dynamic_id in WorldSimulation.state.research_subcategory_allocations:
		for value in (WorldSimulation.state.research_subcategory_allocations[dynamic_id] as Dictionary).values(): total+=maxi(0,int(value))
	# Artifact study is a research-team role drawing on the same observers.
	return total+int(preload("res://scripts/artifact_collection.gd").study_role().weight)


func research_program_summary()->Dictionary:
	var active_lines:=0
	var total_weight:=research_emphasis_total()
	var teams:=research_teams()
	for dynamic_id in WorldSimulation.state.research_subcategory_allocations:
		if _line_weight(String(dynamic_id))>0: active_lines+=1
	var team_people:=float(teams.on_lines)/maxf(1.0,float(maxi(int(teams.count),int(teams.placed))))
	return {
		"researchers":maxi(0,int(WorldSimulation.state.effective_workers("Knowledge"))),
		"emphasis_total":total_weight,"active_lines":active_lines,
		"teams":int(teams.count),"teams_at_work":int(teams.placed),"team_people":team_people,
		"average_line_capacity":float(teams.work)/maxf(1.0,float(maxi(int(teams.count),int(teams.placed))))
	}

func _channel_key(dynamic_id:String,subcategory:String)->String:
	return "%s::%s" % [dynamic_id,subcategory]

## research_3000: the channel through which a line with no emphasis learns by
## diffusion (its first subcategory), or "" when the line has emphasis.
func _diffusion_subcategory(dynamic_id:String)->String:
	# Diffusion off (Research600.DIFFUSION_TEAM 0): no channel, so an
	# unstaffed line never holds an investigation.
	if Research600.DIFFUSION_TEAM<=0.0: return ""
	var subcategories:Dictionary=WorldSimulation.state.research_subcategory_allocations.get(dynamic_id,{})
	if subcategories.is_empty(): return ""
	for value:Variant in subcategories.values():
		if int(value)>0: return ""
	return String(subcategories.keys()[0])

func _classify_discovery(source:Dictionary)->Dictionary:
	var discovery:=source.duplicate(true)
	if discovery.has("dynamic") and discovery.has("subcategory"):
		if not discovery.has("social_consequence"): discovery["social_consequence"]=String(DiscoveryFrontierCatalog.SOCIAL_RESULTS.get(String(discovery.dynamic),"Collective expectations change as the practice spreads"))
		return discovery
	var old_direction:=String(discovery.get("direction","Information"))
	var dynamic_id:String={"Sustenance":"nutrition","Movement":"logistics","Materials":"production","Infrastructure":"infrastructure","Health":"health","Nature":"ecology","Information":"knowledge","Society":"institutions","Warfare":"security"}.get(old_direction,old_direction.to_lower())
	var text:=(String(discovery.get("name",""))+" "+String(discovery.get("observation",""))).to_lower()
	var subcategory:=String((DiscoveryFrontierCatalog.SUBCATEGORIES.get(dynamic_id,["Directed attention"]) as Array)[0])
	var keyword_map:Dictionary={
		"demography":{"birth":"Maternal safety","child":"Child survival","shelter":"Shelter capacity"},
		"nutrition":{"store":"Stored reserve","soil":"Land productivity","diet":"Diet quality","food":"Daily supply"},
		"health":{"water":"Water & sanitation","disease":"Disease control","wound":"Injury safety"},
		"labor":{"coord":"Coordination","workload":"Workload balance","efficien":"Work efficiency"},
		"knowledge":{"record":"Preserved knowledge","tall":"Preserved knowledge","memory":"Preserved knowledge","commun":"Communication","attention":"Directed attention"},
		"production":{"tool":"Tool quality","standard":"Standardization","craft":"Craft capacity"},
		"infrastructure":{"house":"Housing","public":"Public works","resilien":"Resilience"},
		"logistics":{"route":"Route quality","storage":"Storage system","trade":"Trade reach"},
		"ecology":{"recover":"Natural recovery","pollut":"Pollution control","resource":"Resource sustainability"},
		"institutions":{"legitim":"Legitimacy","law":"State capacity","reform":"Institutional flexibility"},
		"security":{"military":"Military readiness","defen":"Organized defense","crisis":"Crisis resilience"},
		"culture":{"memory":"Collective memory","inquiry":"Inquiry breadth","cohesion":"Social cohesion"}
	}
	for keyword in keyword_map.get(dynamic_id,{}):
		if String(keyword) in text: subcategory=String(keyword_map[dynamic_id][keyword]); break
	discovery["dynamic"]=dynamic_id
	discovery["subcategory"]=subcategory
	discovery["direction"]=dynamic_id
	discovery["social_consequence"]=String(DiscoveryFrontierCatalog.SOCIAL_RESULTS.get(dynamic_id,"Collective expectations change as the practice spreads"))
	return discovery

## Concrete authored technologies are the live tree. Historical generated entries
## stay in the catalog solely so existing discoveries retain their effects.
func technology_tree(dynamic_id:String="")->Array[Dictionary]:
	initialize()
	var rows:Array[Dictionary]=[]
	var known_index:=Pathways.Requirements.index_known(WorldSimulation.state.known_discoveries)
	var children:Dictionary={}
	for entry in technology_catalog:
		if bool(entry.get("frontier",false)): continue
		for requirement in Pathways.definition_parents(entry):
			if not children.has(String(requirement)): children[String(requirement)]=[]
			(children[String(requirement)] as Array).append(String(entry.name))
	for entry in technology_catalog:
		if bool(entry.get("frontier",false)): continue
		if dynamic_id!="" and String(entry.dynamic)!=dynamic_id: continue
		var id:=String(entry.id)
		var row:=entry.duplicate(true)
		var missing:Array[String]=Pathways.missing(entry,int(WorldSimulation.state.elapsed_days),known_index)
		row["pathways"]=Pathways.routes(entry,known_index)
		row["requires"]=entry.get("requires_all",entry.get("requires",[])).duplicate()
		row["pathway_description"]=Pathways.describe(entry,known_index)
		if not _resource_requirements_met(entry.get("resource_requirements",[])):
			for requirement:Dictionary in entry.get("resource_requirements",[]):
				if _resource_requirements_met([requirement]):continue
				var alternative:=" or a returned, studied specimen" if bool(requirement.get("sample_sufficient",false)) and String(requirement.get("stage","recognized")) in ["recognized","surveyed"] else ""
				if float(requirement.get("minimum_stock",0.0))>0:alternative+=" or %.1f in stores" % float(requirement.minimum_stock)
				for resource:String in requirement.get("alternative_stocks",{}):alternative+=" or %.1f %s in stores" % [float(requirement.alternative_stocks[resource]),resource]
				missing.append("%s: %s access%s" % [String(requirement.get("resource","material")),String(requirement.get("stage","recognized")),alternative])
		if not OpeningOpportunities.ready(id):missing.append(OpeningOpportunities.remaining(id))
		var design_missing:=research_600_missing(entry) # research_600
		missing.append_array(design_missing)
		if design_missing.is_empty() and OpeningOpportunities.ready(id) and Pathways.ready(entry,int(WorldSimulation.state.elapsed_days),known_index) and _resource_requirements_met(entry.get("resource_requirements",[])):missing.clear()
		elif missing.is_empty():missing.append("A supported approach and its evidence are needed")
		var known:=known_index.has(id)
		row["ready"]=not known and missing.is_empty()
		row["missing"]=missing
		row["leads_to"]=children.get(id,[])
		row["progress"]=float(WorldSimulation.state.discovery_progress.get(id,0.0))
		row["research_difficulty"]=research_difficulty(entry,WorldSimulation.state.world_seed)
		var ahead:=research_years_ahead(entry)
		row["years_ahead"]=ahead
		if ahead>=1.0 and not known: row["ahead_note"]="%d years ahead of its age: %s" % [roundi(ahead),work_words(research_early_factor(entry))]
		var channel:=_channel_key(String(entry.dynamic),String(entry.subcategory))
		row["status"]="DISCOVERED" if known else ("RESEARCHING" if String(WorldSimulation.state.active_investigations.get(channel,""))==id else ("AVAILABLE" if missing.is_empty() else "LOCKED"))
		rows.append(row)
	return rows

## Splits technology_tree rows for display: a LOCKED row whose prerequisites
## are all known is the next reachable question and is shown by name with what
## it waits on; deeper LOCKED rows only count toward "further questions beyond".
func technology_frontier(rows:Array)->Dictionary:
	var known:Dictionary={}
	for row:Dictionary in rows:
		if String(row.get("status",""))=="DISCOVERED":known[String(row.id)]=true
	var next:Dictionary={}
	var beyond:=0
	for row:Dictionary in rows:
		if String(row.get("status",""))!="LOCKED":continue
		var reachable:=true
		for parent:Variant in row.get("requires",[]):
			if not known.has(String(parent)) and not WorldSimulation.state.known_discoveries.has(String(parent)):reachable=false;break
		if reachable:next[String(row.id)]=true
		else:beyond+=1
	return {"next":next,"beyond":beyond}


## Plain words for a line's first unmet condition ("Needs knowledge of Clay").
static func plain_wait_reason(missing:Array)->String:
	if missing.is_empty():return "Needs earlier knowledge before a question here is in reach."
	var text:=String(missing[0]).strip_edges()
	if text.begins_with("Knowledge of ") or text.begins_with("A ") or text.begins_with("At least ") or text.begins_with("Contact "):return "Needs "+text[0].to_lower()+text.substr(1)
	return "Waits on "+text


## Why a staffed line has no open question, in plain words; "" when it has one.
func line_wait_reason(dynamic_id:String,subcategory:String,rows:Array=[])->String:
	var channel:=_channel_key(dynamic_id,subcategory)
	var today:=int(floor(WorldSimulation.state.elapsed_days))
	var next:=_best_candidate_for_channel(channel,today)
	# Open work near its age: teams take questions in turns, by each line's share.
	if _channel_has_candidate(channel,today):
		return "%s waits for a free team; teams take up the questions of their age in turns, each field as often as its share of attention." % (String(next.get("name","")) if not next.is_empty() else "Its next question")
	# Only questions ahead of their age: its turns go to other lines' questions of
	# their age until one comes of age, or all work ahead when none has any.
	if not next.is_empty():
		return "Its next question, %s, is %d years ahead of its age (%s); free teams take nearer work in other fields first, so this field's turn comes as its questions draw nearer their age." % [String(next.get("name","")),roundi(research_years_ahead(next)),work_words(research_early_factor(next))]
	if rows.is_empty():rows=technology_tree(dynamic_id)
	var frontier:=technology_frontier(rows)
	var best:Dictionary={}
	for row:Dictionary in rows:
		if String(row.get("subcategory",""))!=subcategory or not frontier.next.has(String(row.id)):continue
		if best.is_empty() or float(row.get("earliest_year",0.0))<float(best.get("earliest_year",0.0)):best=row
	if best.is_empty():return "No question in reach yet: this line needs earlier knowledge from another line."
	return "%s (next: %s)" % [plain_wait_reason(best.get("missing",[])),String(best.get("name",""))]


func select_research_target(discovery_id:String)->Dictionary:
	initialize()
	var discovery:Dictionary=catalog_by_id.get(discovery_id,{})
	if discovery.is_empty() or not _discovery_is_eligible(discovery,int(WorldSimulation.state.elapsed_days)): return {"ok":false,"reason":"This technology is not currently researchable."}
	var domain:=String(discovery.dynamic)
	var subcategory:=String(discovery.subcategory)
	var channel:=_channel_key(domain,subcategory)
	var allocations:Dictionary=WorldSimulation.state.research_subcategory_allocations.get(domain,{})
	if int(allocations.get(subcategory,0))<=0:
		for other in allocations:
			if int(allocations[other])>0:
				allocations[other]=int(allocations[other])-1
				break
		allocations[subcategory]=1
	WorldSimulation.state.research_subcategory_allocations[domain]=allocations
	WorldSimulation.state.research_targets[channel]=discovery_id
	WorldSimulation.state.active_investigations[channel]=discovery_id
	_rebuild_research_domain_totals()
	return {"ok":true}

## A stable seeded draw: saves/reloads never reroll the same technology.
## Bounded variance changes pace without bypassing any causal eligibility gate.
## `known` (default: the acting society's discoveries) supplies design
## precedents, which make research quicker but are never required.
func research_difficulty(discovery:Dictionary,civilization_seed:int,level:float=NAN,known:Variant=null)->float:
	# research_3000: the society's own superseded practices are slower to take up.
	var stale:=Research600.stale_factor(String(discovery.get("id","")),society_model.ceiling_era) if known==null else 1.0
	# Each age's questions ask the work of the learners a people of that age
	# usually keeps (Research600.age_work: research from learners, not size).
	var age_work:=Research600.age_work(float(discovery.get("design_year",discovery_era(String(discovery.get("id","")))))) if known==null else 1.0
	# A young people learns slowly, whatever the question (Research600.founding_work):
	# the acting people at its own age, another people's research (`known`
	# given) at the calendar's.
	age_work*=Research600.founding_work(learning_year() if known==null else float(WorldSimulation.state.elapsed_days)/365.0)
	if known==null: known=WorldSimulation.state.known_discoveries
	return (0.85+_research_draw(String(discovery.id),civilization_seed,"cost")*0.30)*era_cost_multiplier(discovery,level)/Research600.precedent_factor(String(discovery.id),known)*stale*age_work*research_early_factor(discovery)


## Game-year equivalent of a discovery's historical period (TechnologyEras).
## Undated entries inherit the latest era among their required foundations.
func discovery_era(id:String,visiting:Dictionary={})->float:
	if era_by_id.has(id): return float(era_by_id[id])
	var era:=0.0
	if TechnologyEras.HISTORICAL_YEAR.has(id):
		era=TechnologyEras.game_year_for(float(TechnologyEras.HISTORICAL_YEAR[id]))
	else:
		var entry:Dictionary=catalog_by_id.get(id,{})
		if entry.is_empty() or visiting.has(id): return 0.0
		var path:=visiting.duplicate()
		path[id]=true
		for parent in entry.get("requires_all",entry.get("requires",[])): era=maxf(era,discovery_era(String(parent),path))
	era_by_id[id]=era
	return era


## Inquiry beyond the society's accumulated scholarship costs exponentially
## more. Nothing is granted by age: knowledge still needs its foundations,
## evidence and researchers. `level` defaults to the acting society's own.
func era_cost_multiplier(discovery:Dictionary,level:float=NAN)->float:
	# A people's learning lead carries its scholarship with it.
	if is_nan(level): level=scholarship_level()+maxf(0.0,learning_lead)
	return TechnologyEras.cost_multiplier(discovery_era(String(discovery.get("id",""))),level)


## Accumulated scholarship, in game-year equivalents on the pacing curve.
## Saves from before this field existed start from the breadth of what the
## society already knows, never beyond the time it has actually lived.
func scholarship_level()->float:
	var level:=float(WorldSimulation.state.scholarship_level)
	if level>=0.0: return level
	var eras:Array[float]=[]
	for id in WorldSimulation.state.known_discoveries: eras.append(discovery_era(String(id)))
	eras.sort()
	var breadth:=eras[int(eras.size()*0.5)] if not eras.is_empty() else 0.0
	level=minf(breadth,float(WorldSimulation.state.elapsed_days)/365.0)
	WorldSimulation.state.scholarship_level=level
	return level


## Scholarship-years gained per year. A staffed, fed, literate research
## program advances about one year per year; oral tradition alone about half.
func scholarship_rate()->float:
	var researchers:=maxf(0.0,float(WorldSimulation.state.effective_workers("Knowledge")))
	var population:=maxf(1.0,float(WorldSimulation.state.population_total))
	var staffing:=clampf(minf(researchers/6.0,researchers/population/0.03),0.0,1.0)
	var education:=preload("res://scripts/civilization_indicators.gd").education_index(WorldSimulation.state)
	var food:=clampf(float(WorldSimulation.state.food_security),0.0,1.0)
	return (0.45+0.55*staffing)*lerpf(0.85,1.2,education)*lerpf(0.7,1.0,food)

func research_affinity(discovery:Dictionary,civilization_seed:int,environment:Dictionary)->float:
	var score:=_research_draw(String(discovery.id),civilization_seed,"affinity")*100.0
	var domain:=String(discovery.get("dynamic",""))
	var hazards:Dictionary=environment.get("hazards",{})
	if domain=="nutrition": score+=float(hazards.get("drought",0.0))*25.0+float(environment.get("fertility",0.0))*20.0
	if domain=="health": score+=float(hazards.get("disease",0.0))*30.0
	if domain=="logistics": score+=float(environment.get("route_potential",0.0))*25.0
	if domain=="infrastructure": score+=float(environment.get("relief",0.0))*20.0+float(hazards.get("cold",0.0))*20.0
	for requirement in discovery.get("resource_requirements",[]): score+=float((environment.get("resource_potentials",{}) as Dictionary).get(String(requirement.get("resource","")),0.0))*15.0
	return score

func rival_research_candidates(civ:Dictionary,domain:String)->Array[Dictionary]:
	initialize()
	var profile:Dictionary=civ.get("discovery_profile",{})
	var known:Array=profile.get("technologies",[])
	var environment:Dictionary=civ.get("environment_profile",{})
	var resources:Dictionary=environment.get("resource_potentials",{})
	var candidates:Array[Dictionary]=[]
	var society:=research_600_rival_society(civ) # research_600: same gate as the player
	for entry in technology_catalog:
		if bool(entry.get("frontier",false)) or String(entry.dynamic)!=domain or String(entry.id) in known: continue
		if not research_600_open(entry,society,-1,Research600.RIVAL_AHEAD_YEARS): continue
		var viable:=false
		for route:Dictionary in Pathways.routes_for(entry,known,{}):
			if route.ready:viable=true;break
		if not viable: continue
		for requirement in entry.get("resource_requirements",[]):
			if float(resources.get(String(requirement.get("resource","")),0.0))<0.16: viable=false; break
			var access:=String(requirement.get("stage","recognized"))
			var capacity_floor:=0.12 if access=="recognized" else (0.20 if access=="surveyed" else (0.35 if access=="accessible" else 0.55))
			if minf(float(civ.get("production",0.0)),float(civ.get("logistics",0.0)))<capacity_floor: viable=false; break
		if viable: candidates.append(entry)
	var seed_value:=int(profile.get("seed",WorldSimulation.state.world_seed))
	# Rivals too take up the questions of their age first.
	var year:=float(society.get("year",float(WorldSimulation.state.elapsed_days)/365.0))
	var rank:=func(entry:Dictionary)->float: return research_affinity(entry,seed_value,environment)-(research_early_factor(entry,year)-1.0)*EARLY_SCORE_PER_WORK
	candidates.sort_custom(func(a:Dictionary,b:Dictionary)->bool: return float(rank.call(a))>float(rank.call(b)))
	return candidates

func technology_depth(id:String,visiting:Dictionary={})->int:
	if visiting.has(id): return 0
	var entry:Dictionary=catalog_by_id.get(id,{})
	# Unknown parents remain graph validation errors, not invented root nodes.
	if entry.is_empty(): return 0
	if entry.has("causal_depth"): return int(entry.causal_depth)
	var path:=visiting.duplicate()
	path[id]=true
	var depth:=1
	for parent in Pathways.definition_parents(entry): depth=maxi(depth,1+technology_depth(String(parent),path))
	entry["causal_depth"]=depth
	return depth

func domain_technology_limits(domain:String)->Dictionary:
	initialize()
	if technology_limits.has(domain): return technology_limits[domain]
	var total:=0
	var depth:=1
	var conditions:Dictionary={}
	for entry in technology_catalog:
		if String(entry.dynamic)!=domain: continue
		total+=1
		depth=maxi(depth,technology_depth(String(entry.id)))
		conditions[String(entry.subcategory)]=true
	var limits:={"available_count":total,"available_maturity":depth,"available_breadth":conditions.size(),"available_lens_count":1}
	technology_limits[domain]=limits
	return limits

func _research_draw(id:String,seed_value:int,purpose:String)->float:
	# A fixed function of its inputs: this world's draws are worked out once.
	if seed_value!=int(WorldSimulation.state.world_seed): return _seeded_draw(id,seed_value,purpose)
	var draws:=_seed_table(purpose)
	var cached:Variant=draws.get(id)
	if cached==null:
		cached=_seeded_draw(id,seed_value,purpose)
		draws[id]=cached
	return float(cached)

static func _seeded_draw(id:String,seed_value:int,purpose:String)->float:
	var random:=RandomNumberGenerator.new()
	random.seed=hash(id+":"+purpose)^(seed_value*0x45d9f3b)
	return random.randf()


func food_storage_multiplier(food_type:String,traveling:bool)->float:
	# These are settlement practices, not portable refrigerators. Knowledge
	# persists when stores are abandoned; its storage benefit does not travel.
	if traveling or not WorldSimulation.state.settlement_site_committed:return 1.0
	if WorldSimulation.state.effective_workers("Logistics")+WorldSimulation.state.effective_workers("Crafting")<1:return 1.0
	var result:=1.0
	for id:String in WorldSimulation.state.known_discoveries:
		var definition:Dictionary=catalog_by_id.get(id,{})
		var reduction:=clampf(float(definition.get("preservation_profile",{}).get(food_type,0)),0,.5)
		result*=1.0-reduction*adoption(id)
	return maxf(.3,result)


# Holder object (never captured by saves) for food_storage_multipliers.
var _storage_multiplier_cache:=RefCounted.new()

func food_storage_multipliers(food_types:Array,traveling:bool)->Dictionary:
	var result:Dictionary={}
	for food_type:String in food_types:result[food_type]=1.0
	if traveling or not WorldSimulation.state.settlement_site_committed:return result
	if WorldSimulation.state.effective_workers("Logistics")+WorldSimulation.state.effective_workers("Crafting")<1:return result
	# One pass over established knowledge serves all food categories. The pass
	# depends only on the requested types, known discoveries and adoption, so it
	# is reused while their content hashes match; staffing is checked above
	# on every call, and any adoption change produces a new key.
	var key:=[food_types.hash(),catalog.size(),WorldSimulation.state.known_discoveries.hash(),WorldSimulation.state.discovery_adoption.hash()]
	if _storage_multiplier_cache.has_meta("key") and _storage_multiplier_cache.get_meta("key")==key:return (_storage_multiplier_cache.get_meta("value") as Dictionary).duplicate()
	for id:String in WorldSimulation.state.known_discoveries:
		var profile:Dictionary=catalog_by_id.get(id,{}).get("preservation_profile",{})
		if profile.is_empty():continue
		var level:=adoption(id)
		for food_type:String in profile:
			if not result.has(food_type):continue
			var reduction:=clampf(float(profile[food_type]),0,.5)
			result[food_type]=float(result[food_type])*(1.0-reduction*level)
	for food_type in result:result[food_type]=maxf(.3,float(result[food_type]))
	_storage_multiplier_cache.set_meta("key",key);_storage_multiplier_cache.set_meta("value",result.duplicate())
	return result


func _discovery_effect_summary(entry:Dictionary)->String:
	# What it does for the army, in the engine's numbers (supply, kits, units).
	var army:=preload("res://scripts/military_research_notes.gd").note(String(entry.get("id","")))
	var summary:=_discovery_effect_summary_base(entry)
	return summary if army=="" else (summary+"
"+army if summary!="" else army)


func _discovery_effect_summary_base(entry:Dictionary)->String:
	var opening:=preload("res://scripts/civilian_goods.gd")
	var opening_id:=String(entry.get("id",""))
	if opening.TECHNIQUES.has(opening_id):
		return "A household technique. Once adopted it raises how many Civilian Goods craftspeople make and how many households keep. Its listed benefits operate in proportion to Civilian Goods coverage (currently %.0f%%); the knowledge remains when goods wear out." % [opening.factor(opening_id)*100.0]
	if opening_id=="public_stores":return "This knowledge permits a material Public Stores construction project after Storage Pits. Its listed benefits and common-reserve accounting operate only after that staffed communal store is completed."
	if opening_id=="framed_construction":return "%s Current maintained local operating coverage is %.0f%%." % [String(entry.get("production_contract","This knowledge requires a physical framed structure.")),opening.factor(opening_id)*100.0]
	if opening_id in ["wound_cleaning","clean_water"]:
		return "%s Current local operating coverage is %.0f%%; knowledge alone provides no health benefit when the water cannot be supplied." % [String(entry.get("production_contract","This practice requires additional freshwater.")),opening.factor(opening_id)*100.0]
	if opening_id in ["latrine_siting","protected_wellheads","rainwater_cisterns","water_settling_basins"]:
		return "%s Current maintained local works coverage is %.0f%%; knowledge alone provides no settlement-wide benefit." % [String(entry.get("production_contract","This practice requires a physical local work.")),opening.factor(opening_id)*100.0]
	if opening_id in ["kiln_control","lime_burning","lime_mortar"]:
		return "%s Current local operating coverage is %.0f%%; knowledge alone supplies neither firing capacity nor durable masonry." % [String(entry.get("production_contract","This practice requires operating capital and physical material.")),opening.factor(opening_id)*100.0]
	if opening_id in ["seed_selection","animal_taming","pack_animals","domesticated_mounts","mounted_scouts"]:
		return "%s Current local physical coverage is %.0f%%; knowledge alone supplies neither seed nor animals." % [String(entry.get("production_contract","This practice requires a maintained local biological stock.")),opening.factor(opening_id)*100.0]
	if not String(entry.get("clinical_care_method","")).is_empty():return String(entry.production_contract)
	if not String(entry.get("rail_service_method","")).is_empty():return String(entry.production_contract)
	if not String(entry.get("naval_service_method","")).is_empty():return String(entry.production_contract)
	if not String(entry.get("grain_method","")).is_empty():return String(entry.production_contract)
	if not String(entry.get("clothing_method","")).is_empty():return String(entry.production_contract)
	if not String(entry.get("food_batch_method","")).is_empty():return String(entry.production_contract)
	if not String(entry.get("meal_preparation","")).is_empty():return String(entry.production_contract)
	if String(entry.get("id",""))=="smoking":return "Adopted smoking converts meat and fish to preserved rations at 82% yield using shared Logistics/Crafting capacity and 0.04 Timber per input ration. Fuel shortages limit output; unavailable during travel."
	if String(entry.get("id",""))=="food_drying":return "Adopted air drying converts fresh plants to dry staples at 88% yield using shared Logistics/Crafting capacity, without fuel. Unavailable during travel."
	if not entry.get("agronomy_profile",{}).is_empty():
		var p:Dictionary=entry.agronomy_profile
		return "At full adoption: cultivation performance +%.1f%%, labor cost %.1f%%, harvest-area cost %.1f%%, soil-wear reduction %.1f%% and adverse-weather loss reduction %.1f%%. Applies to staffed, settled cultivation; strongest adopted practice per family." % [float(p.yield_gain)*100,float(p.labor_cost)*100,float(p.land_cost)*100,float(p.soil_protection)*100,float(p.weather_buffer)*100]
	var medical:=String(entry.get("medical_method",""))
	if not medical.is_empty():return String(entry.get("production_contract",""))+" Care consumes Woven Dressings or Fiber Plants, plus Medicinal Plants, during supported recovery at home."
	if not String(entry.get("doctrine","")).is_empty():return String(entry.get("production_contract",""))+" Requires rehearsal during supplied preparation; understanding alone does not improve the army."
	var summary:=_effect_summary(entry.get("effects",{})) if not entry.get("effects",{}).is_empty() else ""
	var profile:Dictionary=entry.get("preservation_profile",{})
	if not profile.is_empty():
		var parts:Array[String]=[]
		for food:String in profile:parts.append("%s %.0f%%" % [food,float(profile[food])*100])
		summary+="\nSettled storage spoilage reductions at full adoption: "+", ".join(parts)+". Requires Logistics or Crafting workers; unavailable during travel."
	var training:Dictionary=entry.get("training_profile",{})
	if not training.is_empty():
		var parts:Array[String]=[]
		for unit:String in training:parts.append("%s %.0f%%" % [unit.replace("_"," "),float(training[unit])*100])
		summary+="\nShorter new training orders at full adoption: "+", ".join(parts)+". Requires normal staff, personnel, equipment and provisions. Existing orders retain their schedule."
	var prospecting:Dictionary=entry.get("prospecting_profile",{})
	if not prospecting.is_empty():
		var targets:Array[String]=[]
		for deposit:Dictionary in WorldSimulation.resources.visible_deposits():
			var resource:=String(deposit.resource)
			if resource in prospecting.resources and resource not in targets:targets.append(resource)
		var target_text:=", ".join(PackedStringArray(targets)) if not targets.is_empty() else "matching geological materials"
		summary+="\nSurvey workers at full adoption: +%.0f%% identification effort and +%.0f%% extent-survey effort for %s. Strongest method per family; combined improvement capped at 75%%. No deposits, stocks or extraction access are granted." % [float(prospecting.recognition)*100,float(prospecting.survey)*100,target_text]
	# The rebalanced research blocks give many practical methods adoption
	# effects; keep telling the player what physical work they still require.
	var contract:=String(entry.get("production_contract",""))
	if not summary.is_empty() and not contract.is_empty() and not contract in summary:summary+="\n"+contract
	return summary if not summary.is_empty() else String(entry.get("production_contract","Unlocks a prerequisite used by later practical methods."))


func military_training_multiplier(unit:String)->float:
	var result:=1.0
	for id:String in WorldSimulation.state.known_discoveries:
		var definition:Dictionary=catalog_by_id.get(id,{})
		var reduction:=clampf(float(definition.get("training_profile",{}).get(unit,0)),0,.25)
		result*=1.0-reduction*adoption(id)
	return maxf(.7,result)


# --- research_600 (begin) -----------------------------------------------------
# Era gate and design conditions from the 600-year research layer
# (scripts/research_600_catalog.gd). They gate availability only: nothing here
# grants or revokes knowledge. Player and rivals share research_600_open(); only
# the society snapshot differs.

## Registry ids take their design era; other entries are re-dated so none is
## older than its required foundations; every live entry gets an earliest year.
func _assign_research_600_years()->void:
	for id:String in Research600.ids():
		if catalog_by_id.has(id): era_by_id[id]=float(Research600.item(id).get("proposed_year",0.0))
	for discovery:Dictionary in technology_catalog: _research_600_reconciled_era(String(discovery.get("id","")),{})
	for discovery:Dictionary in technology_catalog:
		if discovery.has("earliest_year"): continue
		var id:=String(discovery.get("id",""))
		discovery["earliest_year"]=Research600.earliest_year(discovery,discovery_era(id),TechnologyEras.HISTORICAL_YEAR.has(id))


## TechnologyEras date (or 0 when undated), raised to the latest era among the
## entry's required foundations, which may now carry later design years.
func _research_600_reconciled_era(id:String,visiting:Dictionary)->float:
	if era_by_id.has(id): return float(era_by_id[id])
	var entry:Dictionary=catalog_by_id.get(id,{})
	if entry.is_empty() or visiting.has(id): return 0.0
	var era:=TechnologyEras.game_year_for(float(TechnologyEras.HISTORICAL_YEAR[id])) if TechnologyEras.HISTORICAL_YEAR.has(id) else 0.0
	visiting[id]=true
	for parent:Variant in entry.get("requires_all",entry.get("requires",[])): era=maxf(era,_research_600_reconciled_era(String(parent),visiting))
	visiting.erase(id)
	era_by_id[id]=era
	return era


## Earliest game year at which `discovery` can be researched (0 when ungated).
func research_600_earliest_year(discovery:Dictionary)->float:
	return float(discovery.get("earliest_year",0.0))


## This world's opening year for `discovery` (its authored age, shifted per world).
func research_open_year(discovery:Dictionary)->float:
	var id:=String(discovery.get("id",""))
	var seed_value:=int(WorldSimulation.state.world_seed)
	if _open_year_seed!=seed_value: _open_year_cache.clear();_open_year_seed=seed_value
	if not _open_year_cache.has(id): _open_year_cache[id]=Research600.open_year(float(discovery.get("earliest_year",0.0)),_research_draw(id,seed_value,"open_year"))
	return float(_open_year_cache[id])

var _open_year_cache:Dictionary={}
var _open_year_seed:=0


## Years `discovery` stands ahead of its age at `year` (0 once its age has
## come); `year` is the people's own age, learning_year() by default.
func research_years_ahead(discovery:Dictionary,year:float=NAN)->float:
	if is_nan(year): year=learning_year()
	return maxf(0.0,research_open_year(discovery)-year)


## Work multiplier for `discovery` before its age: proportional to the years
## ahead of the people's own age (1 once its age has come). Never a wall.
func research_early_factor(discovery:Dictionary,year:float=NAN)->float:
	if is_nan(year): year=learning_year()
	return Research600.early_factor(research_open_year(discovery),year)


## True when the entry's design conditions hold for `society` (default: the
## acting player-side society). Its age is never a wall (research_early_factor
## makes early work proportionally slower); `horizon_years` >= 0 limits how far
## ahead of its age a question may be (rival peoples keep to their age).
## `day` (>=0) evaluates the calendar at that simulated day instead of today.
func research_600_open(discovery:Dictionary,society:Dictionary={},day:int=-1,horizon_years:float=-1.0)->bool:
	if horizon_years>=0.0:
		# The acting people's own age; a rival society snapshot carries its year.
		var year:=learning_year(day) if society.is_empty() else (float(day)/365.0 if day>=0 else float(society.get("year",float(WorldSimulation.state.elapsed_days)/365.0)))
		if research_open_year(discovery)-year>horizon_years: return false
	if (discovery.get("conditions",{}) as Dictionary).is_empty(): return true
	return Research600.conditions_met(String(discovery.get("id","")),society if not society.is_empty() else _player_society())


## Player-facing reasons the design conditions still hold `discovery` (its age
## never does: early work is only slower).
func research_600_missing(discovery:Dictionary,society:Dictionary={})->Array[String]:
	var reasons:Array[String]=[]
	if not (discovery.get("conditions",{}) as Dictionary).is_empty():
		reasons.append_array(Research600.unmet_conditions(String(discovery.get("id","")),society if not society.is_empty() else research_600_player_society()))
	return reasons


## The acting (player-side or owned) society as the design conditions see it.
func research_600_player_society()->Dictionary:
	var state:Node=WorldSimulation.state
	var resources:Dictionary={}
	for deposit:Dictionary in state.resource_deposits:
		if _stage_rank(String(deposit.get("stage","unknown")))>=_stage_rank("recognized"): resources[String(deposit.get("resource",""))]=true
	for resource_name:Variant in state.resource_stockpiles:
		if float(state.resource_stockpiles[resource_name])>0.0: resources[String(resource_name)]=true
	# Materials of the home ground count as known, as they do for rivals.
	Research600.home_surface_resources(state.player_settlements,_home_environment(),resources)
	var environment:Dictionary={}
	for settlement:Dictionary in state.player_settlements:
		Research600.environment_tags(settlement.get("environment_profile",{}),environment)
	if environment.is_empty() and WorldSimulation.food!=null: Research600.environment_tags(_home_environment(),environment)
	if bool(state.water_metrics.get("source_accessible",false)): environment["river"]=true
	var contact:=false
	if WorldSimulation.world!=null:
		for civ:Dictionary in WorldSimulation.world.civilizations:
			if int((civ.get("player_relation",{}) as Dictionary).get("contact_level",0))>=Research600.CONTACT_MET_LEVEL: contact=true;break
	return {"year":float(state.elapsed_days)/365.0,"population":float(state.population_total),"settlements":maxi(1,state.player_settlements.size()),
		"resources":resources,"environment":environment,"institutions":float(state.society_capacities.get("institutions",0.0)),"contact":contact}


## A projected rival civilization as the design conditions see it. Materials are
## landscape potentials at the floor rival research already uses.
func research_600_rival_society(civ:Dictionary)->Dictionary:
	var profile:Dictionary=civ.get("environment_profile",{})
	var potentials:Dictionary=profile.get("resource_potentials",civ.get("resource_endowment",{}))
	var resources:Dictionary={}
	for resource_name:Variant in potentials:
		if float(potentials[resource_name])>=Research600.RIVAL_RESOURCE_FLOOR: resources[String(resource_name)]=true
	var contact:=int((civ.get("player_relation",{}) as Dictionary).get("rival_contact_level",0))>=Research600.CONTACT_MET_LEVEL
	for relation_variant:Variant in (civ.get("relations",{}) as Dictionary).values():
		var relation:Dictionary=relation_variant
		if float(relation.get("trade",0.0))>0.0 or bool(relation.get("at_war",false)) or String(relation.get("treaty","none"))!="none": contact=true;break
	return {"year":float(WorldSimulation.state.elapsed_days)/365.0,"population":float(civ.get("population",0.0)),"settlements":maxi(1,int(civ.get("settlement_count",1))),
		"resources":resources,"environment":Research600.environment_tags(profile,{}),"institutions":float(civ.get("institutions",0.0)),"contact":contact}


## A line whose domain has no open question of its own does foundation work:
## it investigates an open prerequisite, from any line, of one of its domain's
## era-open questions (the design has 534 cross-line foundations). Without this
## an emphasis on a single line starved on foundations nobody researched. The
## observers and emphasis stay with the chosen domain; only the question differs.
var _research_600_foundation_cache:Dictionary={}

func _research_600_channel_home(channel:String)->Array[String]:
	var parts:=channel.split("::")
	return [String(parts[0]),String(parts[1]) if parts.size()>1 else ""]


func _research_600_investigation_placed(channel:String,discovery:Dictionary)->bool:
	var home:=_research_600_channel_home(channel)
	# A team's desk is any channel of a followed line.
	if _line_weight(home[0])<=0 and home[1]!=_diffusion_subcategory(home[0]): return false
	var own:=_channel_key(String(discovery.get("dynamic","")),String(discovery.get("subcategory","")))
	if channel==own: return true
	# Foundation work is for questions no line of their own is pursuing. Once the
	# question's own line takes it up, the borrowing line hands it back and finds
	# other work, so one question is never worked (and listed) twice.
	if String(WorldSimulation.state.active_investigations.get(own,""))==String(discovery.get("id","")): return false
	return String(discovery.get("id","")) in _research_600_foundation_ids(home[0],int(floor(WorldSimulation.state.elapsed_days)))


func _research_600_foundation_candidate(dynamic_id:String,current_day:int,busy:Dictionary={})->Dictionary:
	var active:Array=WorldSimulation.state.active_investigations.values()
	for id:String in _research_600_foundation_ids(dynamic_id,current_day):
		if not id in active and not busy.has(id): return discovery_definition(id)
	return {}


## How far ahead of their age the questions are whose foundations a line with
## nothing of its own takes up.
const FOUNDATION_HORIZON_YEARS:=50.0

## Open prerequisites (followed down to ones that can be researched now) of the
## domain's unknown questions near their age, earliest age first.
func _research_600_foundation_ids(dynamic_id:String,current_day:int)->Array[String]:
	var key:="%s:%d:%d" % [dynamic_id,current_day,WorldSimulation.state.known_discoveries.size()]
	if _research_600_foundation_cache.has(key): return _research_600_foundation_cache[key]
	if _research_600_foundation_cache.size()>64: _research_600_foundation_cache.clear()
	var known:Dictionary={}
	for id:Variant in WorldSimulation.state.known_discoveries: known[String(id)]=true
	var frontier:Array[String]=[]
	# The first pass over a field reads the opening year of every question of
	# it then unknown. Discoveries are never lost, so afterwards (or at once,
	# when those years are already on record) only questions near the horizon
	# need reading: the others are passed over below all the same.
	var known_size:=WorldSimulation.state.known_discoveries.size()
	var buckets:=_foundation_year_buckets(dynamic_id)
	var scanned:Variant=_scan.foundation_scanned.get(dynamic_id)
	var entries:=_technology_entries(dynamic_id)
	if (scanned!=null and known_size>=int(scanned)) or _years_recorded(entries,known): entries=_foundation_horizon_entries(buckets,entries,current_day)
	for entry:Dictionary in entries:
		if known.has(String(entry.get("id",""))): continue
		# Foundation work serves questions within FOUNDATION_HORIZON_YEARS of their age.
		if research_600_open(entry,{},current_day,FOUNDATION_HORIZON_YEARS) and Research600.pursued(String(entry.get("id","")),society_model.ceiling_era): frontier.append_array(_research_600_missing_parents(entry,known)) # research_3000: only questions still pursued
	if scanned==null or known_size<int(scanned): _scan.foundation_scanned[dynamic_id]=known_size
	var found:Dictionary={}
	var visited:Dictionary={}
	var depth:=0
	while not frontier.is_empty() and depth<8:
		var next:Array[String]=[]
		for id:String in frontier:
			if visited.has(id) or known.has(id): continue
			visited[id]=true
			var foundation:=discovery_definition(id)
			if foundation.is_empty() or not research_600_open(foundation,{},current_day): continue
			if _scan_eligible(foundation,current_day,known):
				# Foundation work keeps near its age: no more than NEAR_AGE_YEARS ahead.
				if research_years_ahead(foundation,learning_year(current_day))<NEAR_AGE_YEARS: found[id]=research_open_year(foundation)
			else: next.append_array(_research_600_missing_parents(foundation,known))
		frontier=next
		depth+=1
	var ids:Array[String]=[]
	for id:Variant in found: ids.append(String(id))
	ids.sort_custom(func(a:String,b:String)->bool: return float(found[a])<float(found[b]))
	_research_600_foundation_cache[key]=ids
	return ids


## A field's questions by whole opening year: {"buckets": {year: indices into
## _technology_entries(field)}, "last": the latest year}. A question's year is
## its recorded opening year, or the one research_open_year would record
## (nothing is recorded here).
func _foundation_year_buckets(dynamic_id:String)->Dictionary:
	var basis:=_catalog_basis()
	if not _same_basis(_scan.year_buckets_basis,basis):
		_scan.year_buckets={}
		_scan.foundation_scanned={}
		_scan.year_buckets_basis=basis
	var table:Variant=_scan.year_buckets.get(dynamic_id)
	if table==null:
		var buckets:Dictionary={}
		var last:=0
		var seed_value:=int(WorldSimulation.state.world_seed)
		var entries:=_technology_entries(dynamic_id)
		for index in entries.size():
			var entry:Dictionary=entries[index]
			var id:=String(entry.get("id",""))
			var recorded:Variant=_open_year_cache.get(id) if _open_year_seed==seed_value else null
			var open:float=float(recorded) if recorded!=null else Research600.open_year(float(entry.get("earliest_year",0.0)),_research_draw(id,seed_value,"open_year"))
			var bucket:=int(floor(open))
			if not buckets.has(bucket): buckets[bucket]=[]
			(buckets[bucket] as Array).append(index)
			last=maxi(last,bucket)
		table={"buckets":buckets,"last":last}
		_scan.year_buckets[dynamic_id]=table
	return table

## Whether every question of `entries` not in `known` has its opening year on
## record for this world's seed (research_open_year would record nothing new).
func _years_recorded(entries:Array,known:Dictionary)->bool:
	if _open_year_seed!=int(WorldSimulation.state.world_seed): return false
	for entry:Dictionary in entries:
		var id:=String(entry.get("id",""))
		if not known.has(id) and not _open_year_cache.has(id): return false
	return true

## The field's questions, in catalog order, whose whole opening year stands
## within FOUNDATION_HORIZON_YEARS of `day` (a question in a later year opens
## beyond the horizon, as does every question after it).
func _foundation_horizon_entries(table:Dictionary,entries:Array,day:int)->Array:
	var year:=learning_year(day)
	var buckets:Dictionary=table.buckets
	var indices:Array=[]
	for bucket in int(table.last)+1:
		if float(bucket)-year>FOUNDATION_HORIZON_YEARS: break
		var listed:Variant=buckets.get(bucket)
		if listed!=null: indices.append_array(listed)
	indices.sort()
	var result:Array=[]
	for index:int in indices: result.append(entries[index])
	return result

func _research_600_missing_parents(entry:Dictionary,known:Dictionary)->Array[String]:
	var parents:Array[String]=[]
	for parent:Variant in entry.get("requires_all",[]):
		if not known.has(String(parent)): parents.append(String(parent))
	for group:Variant in entry.get("requires_any",[]):
		var satisfied:=false
		for option:Variant in group:
			if known.has(String(option)): satisfied=true
		if not satisfied and not (group as Array).is_empty(): parents.append(String((group as Array)[0]))
	return parents
# --- research_600 (end) -------------------------------------------------------
