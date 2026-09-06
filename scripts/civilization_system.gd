extends Node

const OCCUPATION_GOVERNANCE=preload("res://scripts/occupation_governance.gd")

const SOCIETAL_VALUES_MODEL:=preload("res://scripts/societal_values_model.gd")

signal world_changed(snapshot:Dictionary)
signal diplomatic_event(event:Dictionary)
signal scout_report_returned(report:Dictionary)

const MILITARY_DEVELOPMENT:=preload("res://scripts/military_development_catalog.gd")

const SAVE_VERSION:=10
# Every new world draws its own rival count from this range; the player never
# knows how crowded the planet is until they chart it.
const MIN_RIVAL_CIVILIZATIONS:=12
const MAX_RIVAL_CIVILIZATIONS:=36
const STRATEGIC_REGIONS_PER_CIV:=5
const STRATEGIC_TURN_DAYS:=30
const HISTORY_LIMIT:=240
const INCIDENT_LIMIT:=4
const AGE_COHORTS:=["children","youth","early_adults","established_adults","mature_adults","elders"]
const COHORT_DURATION_TURNS:={"children":168.0,"youth":132.0,"early_adults":120.0,"established_adults":120.0,"mature_adults":180.0}
const STRATEGIES:=["sustenance","growth","inquiry","commerce","fortification","expansion"]
const CIV_PREFIXES:=["ASHEN","BRIGHTWATER","CEDAR","DEEP VALLEY","EASTERN","HIGH PLAIN","IRONWOOD","LONG RIVER","AMBER COAST","BLACK FEN","COLDSPRING","DUSTWIND","EMBER HILL","FALLOW MOOR","GREYSTONE","HOLLOW PINE","JADE MARSH","KESTREL RIDGE","LOW COUNTRY","MIRROR LAKE","NORTH SHOAL","OXBOW","PALE CLIFF","QUIET WATER","REEDBANK","SALT MEADOW","THORNFIELD","UPLAND","VIOLET GORGE","WHITE BIRCH","WINTER GATE","YELLOW REED","ZENITH PLAIN","BROKEN TOOTH","CINDER VALE","DRIFTWOOD"]
const CIV_FORMS:=["COMPACT","ASSEMBLIES","COMMONWEALTH","LEAGUE","FEDERATION","CONFEDERACY","DOMINION","COVENANT"]
const REGION_ROLES:=["frontier","granary","market","works","capital"]
const REGION_TITLES:={"frontier":"MARCH","granary":"BREADLANDS","market":"RIVER GATE","works":"FOUNDRY DISTRICT","capital":"HIGH SEAT"}
const REGION_POPULATION_SHARES:=[0.07,0.11,0.14,0.13,0.20]
const REGION_TERRITORY_SHARES:=[0.045,0.065,0.080,0.090,0.120]
const REGION_STRATEGIC_WEIGHTS:=[0.08,0.12,0.15,0.17,0.24]
const WAR_GOALS:=["none","limited","break_power","liberation","defend"]
const WAR_GOAL_LABELS:={"none":"NO OBJECTIVE","limited":"LIMITED WAR","break_power":"BREAK THEIR POWER","liberation":"LIBERATE A REGION","defend":"DEFEND THE REALM"}
const SCORE_DOMAINS:=["population","knowledge","production","logistics","military","resilience","territory"]
const VICTORY_FOOD_DAYS:=45.0
const VICTORY_HEALTH:=0.50
const VICTORY_COHESION:=0.45
const VICTORY_INSTITUTIONS:=0.35
const SCOUT_DURATIONS:=[30,90,180,365]
const REVEAL_HISTORY_LIMIT:=1024
const SCOUT_REPORT_LIMIT:=256
const SCOUT_ROUTE_POINT_LIMIT:=24
const REVEALED_TRAIL_POINT_LIMIT:=128
const SCOUT_LAND_SAMPLE_KM:=8.0
const SCOUT_ROUTE_GRID_LIMIT:=96
const DIPLOMATIC_HISTORY_LIMIT:=24
const CARRIED_DIPLOMATIC_ACTIONS:=["open_trade","non_aggression","send_aid","seek_peace","declare_war","leader_parley"]
const DIPLOMATIC_PURPOSE_LABELS:={
	"leader_parley":"NEGOTIATE WITH LEADER",
	"goodwill":"GOODWILL MISSION","open_trade":"PROPOSE TRADE","non_aggression":"PROPOSE NON-AGGRESSION",
	"send_aid":"DELIVER FOOD AID","seek_peace":"SEEK PEACE","declare_war":"CARRY DECLARATION OF WAR"
}
const FOREIGN_FORMATIONS_PER_CIV:=3
const MAX_FOREIGN_FORMATIONS:=MAX_RIVAL_CIVILIZATIONS*FOREIGN_FORMATIONS_PER_CIV
const FOREIGN_SIGHTING_LIMIT:=32
const CIVILIZATION_WORLD_RADIUS_X_KM:=18000.0
const CIVILIZATION_WORLD_RADIUS_Z_KM:=9000.0
const FOREIGN_SCOUT_GOLDEN_ANGLE:=2.399963229728653
const FOREIGN_SCOUT_MIN_RANGE_KM:=180.0
const FOREIGN_SCOUT_MAX_RANGE_KM:=18500.0
const FOREIGN_SCOUT_REPLACEMENT_DAYS:=45
const CAPTURED_SCOUT_COHORT_LIMIT:=MAX_RIVAL_CIVILIZATIONS
const WAR_HISTORY_LIMIT:=64
# Keep the complete named-war and casualty totals forever within the fixed war
# ledger. Individual engagements are a rolling operational appendix; the total
# battle count survives after old engagement detail is compacted.
const WAR_BATTLE_LIMIT:=12
const REGION_VALUE_TEXT:={
	"frontier":"Opens the road into the rival's strategic interior and weakens its logistics.",
	"granary":"Constrains the rival's food growth and can eventually support your provision network.",
	"market":"Cuts exchange access and can become a valuable integrated market.",
	"works":"Reduces rival production and can add bounded material capacity after integration.",
	"capital":"Cripples institutions and knowledge, creates major peace leverage, and may break organized resistance."
}

var civilizations:Array[Dictionary]=[]
var city_intelligence=preload("res://scripts/city_intelligence.gd").new(self)
var rumor_network=preload("res://scripts/rumor_network.gd").new(self)
var world_events:Array[Dictionary]=[]
var pending_player_incidents:Array[Dictionary]=[]
var last_world_seed:=-2147483648
var last_processed_day:=0
var last_turn_day:=0
var turn_index:=0
var dominance_turns:=0
var collapse_turns:=0
var competition_outcome:="ongoing"
var competition_winner_id:=""
var contender_dominance_turns:Dictionary={}
var player_territory_balance:=0.0
var scout_missions:Array[Dictionary]=[]
var next_scout_mission_id:=1
var scout_reports:Array[Dictionary]=[]
var last_scout_outcome:Dictionary={}
var diplomatic_mission:Dictionary={}
var diplomatic_history:Array[Dictionary]=[]
var captured_player_scouts:Dictionary={}
var captured_foreign_scouts:Dictionary={}
var foreign_scout_reports_denied:=0
var revealed_areas:Array[Dictionary]=[]
var fog_revision:=0
var player_world_origin:=Vector2.ZERO
var foreign_formations:Array[Dictionary]=[]
var foreign_sightings:Array[Dictionary]=[]
## Sightings of unaffiliated nomadic bands from returned scout reports. They
## are indicators, not contacts: nomads move, so each mark fades with seasons.
var nomad_sightings:Array[Dictionary]=[]
var next_nomad_sighting_id:=1
var observation_revision:=0
var last_observation_day:=-1
var war_history:Array[Dictionary]=[]
var next_war_id:=1
var scout_land_authority:Callable=Callable()
## Reads the rendered ground (woodland density, river distance, height) so
## returned reports describe what the map actually shows there.
var ground_survey_authority:Callable=Callable()


func _ready()->void:
	set_process(true)
	initialize()


func _process(_delta:float)->void:
	if GameState.world_seed!=last_world_seed:
		reset_for_new_world()
	advance_to_day(int(floor(GameState.elapsed_days)))


func initialize()->void:
	if civilizations.is_empty() or GameState.world_seed!=last_world_seed:
		reset_for_new_world()


func reset_for_new_world()->void:
	city_intelligence=preload("res://scripts/city_intelligence.gd").new(self)
	rumor_network=preload("res://scripts/rumor_network.gd").new(self)
	last_world_seed=GameState.world_seed
	last_processed_day=int(floor(GameState.elapsed_days))
	last_turn_day=(last_processed_day/STRATEGIC_TURN_DAYS)*STRATEGIC_TURN_DAYS
	turn_index=0
	dominance_turns=0
	collapse_turns=0
	competition_outcome="ongoing"
	competition_winner_id=""
	contender_dominance_turns={"player":0}
	player_territory_balance=0.0
	scout_missions.clear()
	next_scout_mission_id=1
	scout_reports.clear()
	last_scout_outcome.clear()
	diplomatic_mission.clear()
	diplomatic_history.clear()
	captured_player_scouts.clear()
	captured_foreign_scouts.clear()
	foreign_scout_reports_denied=0
	revealed_areas.clear()
	fog_revision=0
	player_world_origin=Vector2.ZERO
	foreign_formations.clear()
	foreign_sightings.clear()
	nomad_sightings.clear()
	next_nomad_sighting_id=1
	observation_revision=0
	last_observation_day=-1
	war_history.clear()
	next_war_id=1
	civilizations.clear()
	world_events.clear()
	pending_player_incidents.clear()
	var seed_value:=GameState.world_seed if GameState.world_seed!=0 else 1
	var rng:=RandomNumberGenerator.new()
	rng.seed=seed_value^0x5f3759df
	var rival_count:=rng.randi_range(MIN_RIVAL_CIVILIZATIONS,MAX_RIVAL_CIVILIZATIONS)
	for index in rival_count:
		var population:=float(rng.randi_range(88,310))
		# Rival origins occupy a planetary ellipse rather than a crowded regional
		# arena. Even the nearest possible foreign homeland is thousands of
		# kilometres away; early contact must be earned by travel or long scouting.
		var distance:=rng.randf_range(0.24,0.96)
		var angle:=TAU*(float(index)/float(rival_count))+rng.randf_range(-0.18,0.18)
		var aggression:=rng.randf_range(0.18,0.88)
		var diplomacy:=rng.randf_range(0.22,0.90)
		var knowledge:=rng.randf_range(0.12,0.30)
		var production:=rng.randf_range(0.10,0.29)
		var logistics:=rng.randf_range(0.10,0.30)
		var health:=rng.randf_range(0.56,0.82)
		var food_days:=rng.randf_range(24.0,64.0)
		var military_share:=rng.randf_range(0.025,0.105)
		var founding_focus_id:=String(GameState.FOUNDING_FOCUS_ORDER[(index+abs(seed_value))%GameState.FOUNDING_FOCUS_ORDER.size()])
		var name:="%s %s" % [CIV_PREFIXES[index],CIV_FORMS[(index+abs(seed_value))%CIV_FORMS.size()]]
		var civ_id:="civ_%02d" % (index+1)
		var territory:=rng.randf_range(0.65,1.55)
		var desired_world_position:=Vector2(cos(angle)*distance*CIVILIZATION_WORLD_RADIUS_X_KM,sin(angle)*distance*CIVILIZATION_WORLD_RADIUS_Z_KM)
		var world_position:=PlanetEnvironment.nearest_viable_land(desired_world_position,seed_value^(index+1)*104729)
		var normalized_position:=Vector2(world_position.x/CIVILIZATION_WORLD_RADIUS_X_KM,world_position.y/CIVILIZATION_WORLD_RADIUS_Z_KM)
		distance=normalized_position.length()
		var environment_profile:=PlanetEnvironment.profile_at(world_position)
		var food_potential:=clampf(float(environment_profile.get("food_potential",0.5)),0.0,1.0)
		var construction_potential:=clampf(float(environment_profile.get("construction_potential",0.5)),0.0,1.0)
		var route_potential:=clampf(float(environment_profile.get("route_potential",0.5)),0.0,1.0)
		var health_pressure:=clampf(float(environment_profile.get("health_pressure",0.3)),0.0,1.0)
		food_days*=lerpf(0.90,1.08,food_potential)
		health=clampf(health-health_pressure*0.14+float(environment_profile.get("water_access",0.0))*0.04,0.42,0.88)
		production=clampf(production+construction_potential*0.09,0.08,0.38)
		logistics=clampf(logistics+route_potential*0.08,0.08,0.38)
		var civ:Dictionary={
			"id":civ_id,"name":name,"population":population,
			"cohorts":_cohorts_for_population(population,rng.randf_range(-0.025,0.025)),
			"position":normalized_position,"distance":distance,"world_position":world_position,
			"environment_profile":environment_profile,"resource_endowment":environment_profile.get("resource_potentials",{}),
			"territory":territory,"food_capacity":population*rng.randf_range(0.96,1.08)*lerpf(0.84,1.20,food_potential),"food_days":food_days,
			"health":health,"cohesion":rng.randf_range(0.44,0.78),"knowledge":knowledge,"production":production,
			"logistics":logistics,"institutions":rng.randf_range(0.18,0.48),"ecology":clampf(0.40+float(environment_profile.get("ecological_resilience",0.5))*0.52+rng.randf_range(-0.05,0.05),0.32,0.96),
			"military_share":military_share,"military_population":population*military_share,"military_readiness":rng.randf_range(0.38,0.74),"command_readiness":rng.randf_range(0.30,0.68),"training_focus":"camp_drill","training_cycles":0,
			"aggression":aggression,"diplomacy":diplomacy,"adaptability":rng.randf_range(0.30,0.90),"founding_focus":founding_focus_id,
			"strategy":STRATEGIES[(index+abs(seed_value))%STRATEGIES.size()],"allocations":_allocation_for(STRATEGIES[(index+abs(seed_value))%STRATEGIES.size()]),
			"relations":{},"player_relation":{"opinion":rng.randf_range(-0.34,0.28),"stance":"watchful","treaty":"none","trade":0.0,"at_war":false,"border_tension":clampf(aggression*0.45+(1.0-distance)*0.20,0.0,1.0),"last_incident_day":-9999,"war_goal":"limited","war_target_region_id":"","war_score":0.0,"player_war_exhaustion":0.0,"rival_war_exhaustion":0.0,"conflict_turns":0,"war_started_day":-1,"truce_until_day":0,"last_war_result":"none","war_id":"","front_stance":"balanced","contact_level":0,"contact_intelligence":0.0,"met_day":-1,"contact_source":"","contact_formation_kind":"","contact_formation_id":"","encounter_position":{},"home_location_known":false,"home_position":{},"home_location_source":"","last_observed_day":-1,"rival_contact_level":0,"rival_player_intelligence":0.0,"rival_met_day":-1},
			"score":0.0,"rank":index+2,"wars_won":0,"wars_lost":0,"trade_total":0.0,"alive":true,
			"settlement_count":1,"world_reach":0.0,"progression_tiers":_initial_progression_tiers(),
			"discovery_profile":ProgressionSystem.initial_rival_discovery_profile(civ_id,founding_focus_id,STRATEGIES[(index+abs(seed_value))%STRATEGIES.size()]),
			"societal_values":SOCIETAL_VALUES_MODEL.initial_state(founding_focus_id,seed_value,civ_id)
		}
		civ=_apply_rival_founding_focus_start(civ)
		civ["strategic_regions"]=_create_strategic_regions(civ_id,CIV_PREFIXES[index],population,territory,rng)
		civilizations.append(civ)
		contender_dominance_turns[civ_id]=0
	_initialize_relations(seed_value)
	_initialize_foreign_formations(seed_value)
	_rebuild_competition()


func _initial_progression_tiers()->Dictionary:
	return {"demography":0,"nutrition":0,"health":0,"labor":0,"knowledge":0,"production":0,"infrastructure":0,"logistics":0,"ecology":0,"institutions":0,"security":0,"culture":0}


func _apply_rival_founding_focus_start(civ:Dictionary)->Dictionary:
	var definition:Dictionary=GameState.founding_focus_definition(String(civ.get("founding_focus","provision")))
	var starting:Dictionary=definition.get("starting",{})
	var effects:Dictionary=definition.get("effects",{})
	civ["food_days"]=clampf(float(civ.get("food_days",30.0))*(1.0+float(starting.get("food_days_ratio",0.0))),0.0,180.0)
	civ["food_capacity"]=maxf(1.0,float(civ.get("food_capacity",1.0))*(1.0+float(starting.get("food_capacity_ratio",0.0))))
	civ["health"]=clampf(float(civ.get("health",0.6))+float(starting.get("health",0.0)),0.05,0.98)
	civ["cohesion"]=clampf(float(civ.get("cohesion",0.5))+float(starting.get("cohesion",0.0)),0.05,0.98)
	civ["knowledge"]=clampf(float(civ.get("knowledge",0.15))+float(starting.get("knowledge",0.0)),0.02,1.0)
	civ["production"]=clampf(float(civ.get("production",0.15))+float(starting.get("material_capacity",0.0)),0.02,1.0)
	civ["logistics"]=clampf(float(civ.get("logistics",0.15))+float(starting.get("logistics",0.0)),0.02,1.0)
	civ["institutions"]=clampf(float(civ.get("institutions",0.2))+float(starting.get("institutions",0.0)),0.02,1.0)
	civ["ecology"]=clampf(float(civ.get("ecology",0.7))+float(starting.get("ecology",0.0)),0.08,1.0)
	var security_shift:=float(starting.get("security",0.0))
	civ["military_readiness"]=clampf(float(civ.get("military_readiness",0.4))+security_shift*0.75,0.08,1.0)
	civ["command_readiness"]=clampf(float(civ.get("command_readiness",0.35))+security_shift*0.55+float(effects.get("command_development",0.0))*0.20,0.08,1.0)
	civ["military_share"]=clampf(float(civ.get("military_share",0.05))+maxf(0.0,float(effects.get("training_capacity",0.0)))*0.10,0.015,0.38)
	civ["military_population"]=minf(float(civ.get("population",1.0)),float(civ.get("population",1.0))*float(civ.military_share))
	civ["diplomacy"]=clampf(float(civ.get("diplomacy",0.4))+float(effects.get("diplomacy",0.0))*0.75,0.0,1.0)
	return civ


func _create_strategic_regions(civ_id:String,prefix:String,population:float,territory:float,rng:RandomNumberGenerator)->Array[Dictionary]:
	var regions:Array[Dictionary]=[]
	for index in STRATEGIC_REGIONS_PER_CIV:
		var role:=String(REGION_ROLES[index])
		var fortification_base:={"frontier":0.42,"granary":0.18,"market":0.28,"works":0.34,"capital":0.62}
		regions.append({
			"id":"%s_region_%02d" % [civ_id,index+1],
			"name":"%s %s" % [prefix,String(REGION_TITLES[role])],
			"role":role,
			"approach_index":index,
			"original_controller":civ_id,
			"controller":civ_id,
			"population":maxf(0.0001,population*float(REGION_POPULATION_SHARES[index])),
			"population_share":float(REGION_POPULATION_SHARES[index]),
			"territory_value":maxf(0.005,territory*float(REGION_TERRITORY_SHARES[index])),
			"strategic_weight":float(REGION_STRATEGIC_WEIGHTS[index]),
			"fortification":clampf(float(fortification_base[role])+rng.randf_range(-0.07,0.07),0.08,0.82),
			"damage":0.0,
			"resistance":0.0,
			"integration":1.0,
			"occupation_turns":0,
			"last_control_change_day":0,
			"map_x":clampf(float(index)/float(STRATEGIC_REGIONS_PER_CIV-1)+rng.randf_range(-0.035,0.035),0.0,1.0),
			"map_y":clampf(0.5+rng.randf_range(-0.28,0.28),0.08,0.92)
		})
	return regions


func _relation_with_strategy_defaults(relation:Dictionary,civ:Dictionary={}) -> Dictionary:
	var normalized:=relation.duplicate(true)
	normalized["war_goal"]=String(normalized.get("war_goal","limited"))
	if String(normalized.war_goal) not in WAR_GOALS: normalized["war_goal"]="limited"
	normalized["war_target_region_id"]=String(normalized.get("war_target_region_id",""))
	normalized["war_score"]=clampf(float(normalized.get("war_score",0.0)),-100.0,100.0)
	normalized["player_war_exhaustion"]=clampf(float(normalized.get("player_war_exhaustion",0.0)),0.0,1.0)
	normalized["rival_war_exhaustion"]=clampf(float(normalized.get("rival_war_exhaustion",0.0)),0.0,1.0)
	normalized["conflict_turns"]=maxi(0,int(normalized.get("conflict_turns",0)))
	normalized["war_started_day"]=int(normalized.get("war_started_day",-1))
	normalized["truce_until_day"]=maxi(0,int(normalized.get("truce_until_day",0)))
	normalized["last_war_result"]=String(normalized.get("last_war_result","none"))
	normalized["war_id"]=String(normalized.get("war_id",""))
	normalized["front_stance"]=String(normalized.get("front_stance","balanced"))
	if String(normalized.front_stance) not in ["cautious","balanced","offensive"]: normalized["front_stance"]="balanced"
	normalized["contact_level"]=clampi(int(normalized.get("contact_level",0)),0,2)
	normalized["contact_intelligence"]=clampf(float(normalized.get("contact_intelligence",0.0)),0.0,1.0)
	normalized["met_day"]=int(normalized.get("met_day",-1))
	normalized["contact_source"]=String(normalized.get("contact_source",""))
	normalized["contact_formation_kind"]=String(normalized.get("contact_formation_kind",""))
	normalized["contact_formation_id"]=String(normalized.get("contact_formation_id",""))
	var encounter_position:Variant=normalized.get("encounter_position",{})
	if encounter_position is Vector2:
		normalized["encounter_position"]={"x":encounter_position.x,"z":encounter_position.y}
	elif not encounter_position is Dictionary:
		normalized["encounter_position"]={}
	normalized["home_location_known"]=bool(normalized.get("home_location_known",false))
	var home_position:Variant=normalized.get("home_position",{})
	if home_position is Vector2:
		normalized["home_position"]={"x":home_position.x,"z":home_position.y}
	elif not home_position is Dictionary:
		normalized["home_position"]={}
	if not bool(normalized.home_location_known): normalized["home_position"]={}
	normalized["home_location_source"]=String(normalized.get("home_location_source",""))
	normalized["last_observed_day"]=int(normalized.get("last_observed_day",-1))
	normalized["rival_contact_level"]=clampi(int(normalized.get("rival_contact_level",0)),0,2)
	normalized["rival_player_intelligence"]=clampf(float(normalized.get("rival_player_intelligence",0.0)),0.0,1.0)
	normalized["rival_met_day"]=int(normalized.get("rival_met_day",-1))
	normalized["rival_player_trace_confidence"]=clampf(float(normalized.get("rival_player_trace_confidence",0.0)),0.0,1.0)
	var trace_center:Variant=normalized.get("rival_player_trace_center",{})
	if trace_center is Vector2:
		normalized["rival_player_trace_center"]={"x":trace_center.x,"z":trace_center.y}
	elif not trace_center is Dictionary:
		normalized["rival_player_trace_center"]={}
	normalized["rival_player_trace_radius_km"]=maxf(0.0,float(normalized.get("rival_player_trace_radius_km",0.0)))
	normalized["rival_player_trace_day"]=int(normalized.get("rival_player_trace_day",-1))
	normalized["rival_player_trace_source"]=String(normalized.get("rival_player_trace_source",""))
	if bool(normalized.get("at_war",false)) or String(normalized.get("treaty","none")) not in ["none",""]:
		normalized["contact_level"]=2
		normalized["contact_intelligence"]=maxf(0.20,float(normalized.contact_intelligence))
		normalized["rival_contact_level"]=2
		normalized["rival_player_intelligence"]=maxf(0.20,float(normalized.rival_player_intelligence))
	if not bool(normalized.get("at_war",false)) and String(normalized.war_goal) in ["defend","none"]:
		normalized["war_goal"]="limited"
	if String(normalized.war_target_region_id)=="" and not civ.is_empty():
		normalized["war_target_region_id"]=_default_war_target(civ,String(normalized.war_goal))
	return normalized


func _default_war_target(civ:Dictionary,goal:String="limited") -> String:
	var regions:Array=civ.get("strategic_regions",[])
	if goal=="break_power":
		for region_variant in regions:
			var region:Dictionary=region_variant
			if String(region.get("role",""))=="capital": return String(region.get("id",""))
	var frontline:=_frontline_region_index(civ)
	return String((regions[frontline] as Dictionary).get("id","")) if frontline>=0 and frontline<regions.size() else ""


func _participant_name(participant_id:String)->String:
	if participant_id=="player": return _player_civilization_name()
	var index:=_civilization_index(participant_id)
	return String(civilizations[index].name) if index>=0 else "UNKNOWN POLITY"


func _war_name(first_id:String,second_id:String,target_region_id:String,day:int)->String:
	var year:=int(floor(float(day)/365.0))+1
	if target_region_id!="":
		var location:=_region_location(target_region_id)
		if not location.is_empty(): return "War of %s (Year %d)" % [String(civilizations[int(location.owner_index)].strategic_regions[int(location.region_index)].name).capitalize(),year]
	var first_name:=_participant_name(first_id).capitalize()
	var second_name:=_participant_name(second_id).capitalize()
	return "%s–%s War (Year %d)" % [first_name,second_name,year]


func _empty_war_casualties()->Dictionary:
	return {"military_dead":0,"civilian_dead":0,"wounded":0,"captured":0,"displaced":0}


func _start_war(first_id:String,second_id:String,goal:String,target_region_id:String,day:int,cause:String)->String:
	for record in war_history:
		if String(record.get("status",""))!="active": continue
		var participants:Array=record.get("participants",[])
		if first_id in participants and second_id in participants: return String(record.id)
	var war_id:="war_%04d" % next_war_id
	next_war_id+=1
	var casualties:Dictionary={first_id:_empty_war_casualties(),second_id:_empty_war_casualties()}
	var names:Dictionary={first_id:_participant_name(first_id),second_id:_participant_name(second_id)}
	war_history.push_front({"id":war_id,"name":_war_name(first_id,second_id,target_region_id,day),"started_day":day,"ended_day":-1,"status":"active","participants":[first_id,second_id],"participant_names":names,"war_goal":goal,"target_region_id":target_region_id,"cause":cause,"casualties":casualties,"battle_count":0,"battles":[],"territorial_changes":[],"result":"ongoing"})
	if war_history.size()>WAR_HISTORY_LIMIT: war_history.resize(WAR_HISTORY_LIMIT)
	return war_id


func record_player_hostile_order(civ_id:String,region_id:String,cause:String)->String:
	var index:=_civilization_index(civ_id)
	if index<0:return ""
	var civ:Dictionary=civilizations[index]
	var relation:Dictionary=_relation_with_strategy_defaults(civ.player_relation,civ)
	if not bool(relation.get("at_war",false)):
		relation["at_war"]=true;relation["treaty"]="war";relation["stance"]="hostile";relation["trade"]=0.0
		relation["contact_level"]=maxi(2,int(relation.get("contact_level",0)))
		relation["opinion"]=clampf(float(relation.get("opinion",0))-.42,-1,1);relation["border_tension"]=1.0
		relation["war_goal"]="limited";relation["war_target_region_id"]=region_id
		relation["war_score"]=0.0;relation["conflict_turns"]=0;relation["war_started_day"]=int(GameState.elapsed_days);relation["last_war_result"]="ongoing"
		relation["war_id"]=_start_war("player",civ_id,"limited",region_id,int(GameState.elapsed_days),cause)
	else:relation=_ensure_relation_war(relation,"player",civ_id,int(GameState.elapsed_days),cause)
	civ["player_relation"]=relation;civilizations[index]=civ
	return String(relation.war_id)


func _war_record_index(war_id:String)->int:
	for index in war_history.size():
		if String(war_history[index].get("id",""))==war_id: return index
	return -1


func _ensure_relation_war(relation:Dictionary,first_id:String,second_id:String,day:int,cause:String)->Dictionary:
	var normalized:=relation.duplicate(true)
	var war_id:=String(normalized.get("war_id",""))
	if _war_record_index(war_id)<0:
		war_id=_start_war(first_id,second_id,String(normalized.get("war_goal","limited")),String(normalized.get("war_target_region_id","")),day,cause)
	normalized["war_id"]=war_id
	return normalized


func _record_war_battle(war_id:String,battle:Dictionary)->void:
	var index:=_war_record_index(war_id)
	if index<0: return
	var record:Dictionary=war_history[index]
	var casualties:Dictionary=record.get("casualties",{}).duplicate(true)
	for participant_id_variant in (battle.get("losses",{}) as Dictionary):
		var participant_id:=String(participant_id_variant)
		var totals:Dictionary=(casualties.get(participant_id,_empty_war_casualties()) as Dictionary).duplicate(true)
		var losses:Dictionary=battle.losses[participant_id]
		for field in ["military_dead","civilian_dead","wounded","captured","displaced"]: totals[field]=maxi(0,int(totals.get(field,0))+maxi(0,int(losses.get(field,0))))
		casualties[participant_id]=totals
	record["casualties"]=casualties
	record["battle_count"]=maxi(int(record.get("battle_count",(record.get("battles",[]) as Array).size()))+1,1)
	var battles:Array=(record.get("battles",[]) as Array).duplicate(true)
	# Participant losses are already conserved in the war totals above, and land
	# changes are retained in their own ledger. Do not duplicate either inside
	# every battle summary: at century scale that repeats the same schema thousands
	# of times without adding information.
	var battle_summary:=battle.duplicate(true)
	battle_summary.erase("losses")
	battle_summary.erase("territorial_change")
	battles.append(battle_summary)
	if battles.size()>WAR_BATTLE_LIMIT: battles.pop_front()
	record["battles"]=battles
	var change:Dictionary=battle.get("territorial_change",{})
	if not change.is_empty():
		var changes:Array=(record.get("territorial_changes",[]) as Array).duplicate(true)
		changes.append(change.duplicate(true))
		if changes.size()>WAR_BATTLE_LIMIT: changes.pop_front()
		record["territorial_changes"]=changes
	war_history[index]=record


func _end_war(war_id:String,day:int,result:String)->void:
	var index:=_war_record_index(war_id)
	if index<0: return
	var record:Dictionary=war_history[index]
	record["status"]="ended"
	record["ended_day"]=day
	record["result"]=result
	war_history[index]=record


func war_history_snapshot(include_known_foreign:bool=false)->Array[Dictionary]:
	var visible:Array[Dictionary]=[]
	for record_variant in war_history:
		var record:Dictionary=record_variant
		var participants:Array=record.get("participants",[])
		var known:="player" in participants
		if include_known_foreign and not known:
			known=true
			for participant_id in participants:
				var index:=_civilization_index(String(participant_id))
				if index<0 or int((civilizations[index].player_relation as Dictionary).get("contact_level",0))<2: known=false; break
		if known: visible.append(record.duplicate(true))
	return visible


func military_fronts_snapshot()->Dictionary:
	var fronts:Array[Dictionary]=[]
	for civ_variant in civilizations:
		var civ:Dictionary=civ_variant
		var relation:Dictionary=_relation_with_strategy_defaults(civ.player_relation,civ)
		if not bool(relation.get("at_war",false)): continue
		var objective:=war_objective_status(String(civ.id))
		var target_name:=String(objective.get("target_name","HOME TERRITORY"))
		var target_region_id:=String(objective.get("target_region_id",""))
		var record_index:=_war_record_index(String(relation.get("war_id","")))
		var war_name:=String(war_history[record_index].name) if record_index>=0 else "Active war"
		var front_force:Dictionary={"field_personnel":0,"inbound_personnel":0,"occupation_personnel":0,"reserve_personnel":0,"supply":0.0,"readiness":0.0,"armies":[]}
		if MilitaryCampaign!=null and MilitaryCampaign.has_method("front_force_snapshot"):
			front_force=MilitaryCampaign.front_force_snapshot(String(civ.id),target_region_id if target_region_id!="" else "player_home")
		fronts.append({"id":"front_%s" % String(civ.id),"war_id":String(relation.get("war_id","")),"war_name":war_name,"opponent_id":String(civ.id),"opponent":String(civ.name),"target_region_id":target_region_id,"target":target_name,"stance":String(relation.get("front_stance","balanced")),"objective":String(objective.get("description","DEFEND")),"progress":float(objective.get("progress",0.0)),"field_personnel":int(front_force.get("field_personnel",0)),"inbound_personnel":int(front_force.get("inbound_personnel",0)),"occupation_personnel":int(front_force.get("occupation_personnel",0)),"reserve_personnel":int(front_force.get("reserve_personnel",0)),"supply":float(front_force.get("supply",0.0)),"readiness":float(front_force.get("readiness",0.0)),"armies":front_force.get("armies",[]),"enemy_personnel":float(strategic_assessment(String(civ.id),target_region_id).get("enemy_estimate",-1)),"war_score":float(relation.get("war_score",0.0)),"our_exhaustion":float(relation.get("player_war_exhaustion",0.0)),"enemy_exhaustion":float(relation.get("rival_war_exhaustion",0.0))})
	return {"fronts":fronts,"active":fronts.size(),"bounded":true}


func military_movement_destinations()->Array[Dictionary]:
	var destinations:Array[Dictionary]=[{"id":"player_home","civ_id":"player","region_id":"","label":GameState.settlement_name if GameState.settlement_name!="" else "HOME SETTLEMENT","kind":"home","position":{"x":player_world_origin.x,"z":player_world_origin.y},"known":true}]
	for city:Dictionary in city_intelligence.known_cities():
		var index:=_civilization_index(String(city.civ_id))
		var relation:Dictionary=civilizations[index].player_relation if index>=0 else {}
		destinations.append({"id":city.city_id,"civ_id":city.civ_id,"region_id":city.city_id,"label":city.name,"kind":"strategic_region","position":city.position.duplicate(true),"known":true,"controller":city.controller,"available_campaign":city.controller!="","at_war":bool(relation.get("at_war",false))})
	return destinations


func _position_is_revealed(position:Vector2)->bool:
	for area_variant in revealed_areas:
		var area:Dictionary=area_variant
		if _revealed_record_contains(area,position): return true
	return false


func _revealed_record_contains(area:Dictionary,position:Vector2,margin:float=1.0)->bool:
	var radius:=maxf(0.0,float(area.get("radius",0.0)))*maxf(0.0,margin)
	var points:Array=area.get("points",[])
	if String(area.get("kind","circle"))=="trail" and points.size()>=2:
		for point_index in points.size()-1:
			var start_data:Dictionary=points[point_index]
			var finish_data:Dictionary=points[point_index+1]
			var start:=Vector2(float(start_data.get("x",0.0)),float(start_data.get("z",0.0)))
			var finish:=Vector2(float(finish_data.get("x",0.0)),float(finish_data.get("z",0.0)))
			if position.distance_to(Geometry2D.get_closest_point_to_segment(position,start,finish))<=radius: return true
		return false
	var center:=Vector2(float(area.get("x",0.0)),float(area.get("z",0.0)))
	return center.distance_to(position)<=radius


func set_front_stance(civ_id:String,stance:String)->Dictionary:
	var index:=_civilization_index(civ_id)
	if index<0: return {"error":"Unknown civilization."}
	var normalized:=stance.to_lower()
	if normalized not in ["cautious","balanced","offensive"]: return {"error":"Front stance must be cautious, balanced, or offensive."}
	var civ:Dictionary=civilizations[index]
	var relation:Dictionary=_relation_with_strategy_defaults(civ.player_relation,civ)
	if not bool(relation.get("at_war",false)): return {"error":"A front stance requires an active war."}
	relation["front_stance"]=normalized
	civ["player_relation"]=relation
	civilizations[index]=civ
	return {"ok":true,"stance":normalized,"message":"%s front set to %s: replacement, supply, and battle orders will follow that priority." % [String(civ.name),normalized.to_upper()]}


func _initialize_relations(seed_value:int)->void:
	for first_index in civilizations.size():
		for second_index in range(first_index+1,civilizations.size()):
			var first:Dictionary=civilizations[first_index]
			var second:Dictionary=civilizations[second_index]
			var rng:=RandomNumberGenerator.new()
			rng.seed=seed_value^(first_index+1)*92821^(second_index+1)*68917
			var distance:=Vector2(first.position).distance_to(Vector2(second.position))
			var opinion:=clampf(rng.randf_range(-0.42,0.42)+(0.15 if distance<0.75 else -0.06),-1.0,1.0)
			var border_aggression:=(float(first.aggression)+float(second.aggression))*0.5
			var relation:={"opinion":opinion,"at_war":false,"trade":0.0,"border_tension":clampf((1.25-distance)*0.28+maxf(0.0,-opinion)*0.45+border_aggression*0.20,0.0,1.0),"treaty":"none"}
			(first.relations as Dictionary)[String(second.id)]=relation.duplicate(true)
			(second.relations as Dictionary)[String(first.id)]=relation.duplicate(true)
			civilizations[first_index]=first
			civilizations[second_index]=second


func advance_to_day(target_day:int)->void:
	initialize()
	target_day=maxi(0,target_day)
	if target_day<last_processed_day:
		# Civilization state cannot be rewound without a matching imported snapshot.
		# Ignoring a backward clock prevents the same strategic turns from being
		# applied twice to already-advanced aggregate state.
		return
	while last_turn_day+STRATEGIC_TURN_DAYS<=target_day:
		last_turn_day+=STRATEGIC_TURN_DAYS
		_process_strategic_turn(last_turn_day)
	last_processed_day=target_day
	city_intelligence.sample_missions(target_day)
	rumor_network.sample(target_day)
	_process_foreign_scout_reports(target_day)
	_complete_due_scout_missions(target_day)
	_process_diplomatic_mission(target_day)
	_process_local_observation(target_day)
	ForeignDiplomacy.advance(target_day)


func _process_strategic_turn(day:int)->void:
	turn_index+=1
	for index in civilizations.size():
		var civ:Dictionary=civilizations[index]
		if not bool(civ.get("alive",true)): continue
		civ["strategy"]=_choose_strategy(civ)
		civ["allocations"]=_allocation_for(String(civ.strategy))
		civ["allocations"]=ForeignDiplomacy.commitments.policy_allocations(String(civ.id),civ.allocations)
		civ=_advance_civilization(civ)
		civilizations[index]=civ
	_process_intercivilization_relations(day)
	_process_foreign_player_rumors(day)
	_process_foreign_scout_reports(day)
	_process_player_contact(day)
	_process_player_relations(day)
	city_intelligence.sample_missions(day)
	rumor_network.sample(day)
	_rebuild_competition(true,day)
	world_changed.emit(competition_snapshot())


func register_player_origin(position:Vector2)->void:
	# The seamless-world scene may choose its seed after autoloads enter _ready().
	# Synchronize the civilization world first so the next process tick cannot
	# clear the founding reveal and move the live fog origin back to (0, 0).
	initialize()
	player_world_origin=position
	if revealed_areas.is_empty(): _add_revealed_area(position,72.0,"founding knowledge")
	_process_local_observation(int(GameState.elapsed_days),true)


func record_player_travel(position:Vector2)->void:
	initialize()
	var previous_position:=player_world_origin
	var observation_moved:=previous_position.distance_to(position)
	player_world_origin=position
	if revealed_areas.is_empty():
		_add_revealed_area(position,34.0,"traveled ground")
	elif observation_moved>=12.0:
		_append_revealed_travel(previous_position,position)
	if observation_moved>=1.0: _process_local_observation(int(GameState.elapsed_days),true)


func fog_snapshot()->Dictionary:
	return {"revision":fog_revision,"areas":revealed_areas.duplicate(true),"current_origin":{"x":player_world_origin.x,"z":player_world_origin.y}}


func discovery_map_snapshot()->Dictionary:
	# The strategy map is itself part of the knowledge model. It may contain
	# bounded returned charts and currently visible formations, but never an
	# active scout route or observations that have not physically come home.
	var returned_reports:Array[Dictionary]=[]
	for report_variant in scout_reports:
		var report:Dictionary=report_variant
		returned_reports.append({
			"day":int(report.get("day",0)),
			"duration_days":int(report.get("duration_days",0)),
			"route":(report.get("route",[]) as Array).duplicate(true),
			"return_route":(report.get("return_route",[]) as Array).duplicate(true),
			"travel_mode":String(report.get("travel_mode","land")),
			"contact_records":(report.get("contact_records",[]) as Array).duplicate(true)
		})
	var observation:=local_observation_snapshot()
	return {
		"revision":fog_revision+observation_revision,
		"world_size":{"x":40075.0,"z":20004.0},
		"areas":revealed_areas.duplicate(true),
		"returned_reports":returned_reports,
		"encounters":contact_encounters_snapshot(),
		"visible_formations":(observation.get("visible",[]) as Array).duplicate(true),
		"current_origin":{"x":player_world_origin.x,"z":player_world_origin.y},
		"active_scout_party":not scout_missions.is_empty()
	}


func progression_reach_snapshot()->Dictionary:
	# Returned charts remain the only source of explored area. Direct contacts,
	# territorial systems, and settlement networks contribute separately. Four
	# fixed ratios preserve constant runtime cost at any population.
	var planet_area:=40075.0*20004.0
	var charted_area:=0.0
	for area_variant in revealed_areas:
		var area:Dictionary=area_variant
		var radius:=maxf(0.0,float(area.get("radius",0.0)))
		if String(area.get("kind","circle"))=="trail":
			var points:Array=area.get("points",[])
			var trail_length:=0.0
			for point_index in maxi(0,points.size()-1):
				var a:Dictionary=points[point_index]; var b:Dictionary=points[point_index+1]
				trail_length+=Vector2(float(a.get("x",0.0)),float(a.get("z",0.0))).distance_to(Vector2(float(b.get("x",0.0)),float(b.get("z",0.0))))
			charted_area+=trail_length*radius*2.0+PI*radius*radius
		else:
			charted_area+=PI*radius*radius
	var charted:=clampf(charted_area/maxf(1.0,planet_area),0.0,1.0)
	var contacts:=0
	for civ in civilizations:
		if int((civ.get("player_relation",{}) as Dictionary).get("contact_level",0))>=2: contacts+=1
	var contact_ratio:=clampf(float(contacts)/maxf(1.0,float(civilizations.size())),0.0,1.0)
	var settlement_ratio:=clampf(float(GameState.player_settlements.size())/64.0,0.0,1.0)
	if GameState.player_settlements.is_empty() and GameState.settlement_site_committed: settlement_ratio=1.0/64.0
	var territory_ratio:=clampf(_player_territory()/4.0,0.0,1.0)
	var combined:=charted*0.30+contact_ratio*0.20+settlement_ratio*0.25+territory_ratio*0.25
	return {"combined":clampf(combined,0.0,1.0),"charted":charted,"contacts":contact_ratio,"settlements":settlement_ratio,"territory":territory_ratio,"contacted_civilizations":contacts}


func _add_revealed_area(position:Vector2,radius:float,source:String)->void:
	revealed_areas.append({"kind":"circle","x":position.x,"z":position.y,"radius":maxf(1.0,radius),"source":source,"day":int(GameState.elapsed_days)})
	_trim_revealed_records()
	fog_revision+=1


func _trail_point(position:Vector2)->Dictionary:
	return {"x":position.x,"z":position.y}


func _add_revealed_trail(points_variant:Array,radius:float,source:String,day:int=-1)->void:
	var points:Array[Dictionary]=[]
	for point_variant in points_variant:
		if not point_variant is Dictionary: continue
		var point:Dictionary=point_variant
		var position:=Vector2(float(point.get("x",0.0)),float(point.get("z",0.0)))
		if not is_finite(position.x) or not is_finite(position.y): continue
		if points.is_empty() or Vector2(float(points[-1].x),float(points[-1].z)).distance_to(position)>0.001:
			points.append(_trail_point(position))
	if points.size()<2: return
	# Mission paths are already bounded. This guard also makes imported or future
	# callers incapable of turning one chart into an unbounded per-person trail.
	if points.size()>REVEALED_TRAIL_POINT_LIMIT:
		var bounded:Array[Dictionary]=[]
		for index in REVEALED_TRAIL_POINT_LIMIT:
			var source_index:=roundi(float(index)*float(points.size()-1)/float(REVEALED_TRAIL_POINT_LIMIT-1))
			bounded.append(points[source_index])
		points=bounded
	var first:Dictionary=points[0]
	revealed_areas.append({"kind":"trail","x":float(first.x),"z":float(first.z),"radius":maxf(1.0,radius),"points":points,"source":source,"day":int(GameState.elapsed_days) if day<0 else day})
	_trim_revealed_records()
	fog_revision+=1


func _append_revealed_travel(start:Vector2,finish:Vector2)->void:
	if start.distance_to(finish)<=0.001: return
	if not revealed_areas.is_empty():
		var latest:Dictionary=revealed_areas[-1]
		var latest_points:Array=latest.get("points",[])
		if String(latest.get("kind",""))=="trail" and String(latest.get("source",""))=="traveled ground" and latest_points.size()>=2 and latest_points.size()<REVEALED_TRAIL_POINT_LIMIT:
			var last:Dictionary=latest_points[-1]
			if Vector2(float(last.get("x",0.0)),float(last.get("z",0.0))).distance_to(start)<=18.0:
				latest_points.append(_trail_point(finish))
				latest["points"]=latest_points
				revealed_areas[-1]=latest
				fog_revision+=1
				return
	_add_revealed_trail([_trail_point(start),_trail_point(finish)],34.0,"traveled ground")


func _trim_revealed_records()->void:
	# A former implementation merged distant circles by growing a replacement
	# circle around them. Repeating that operation could reveal a continent after
	# one new scout report. Trail records make normal play stay far below this cap;
	# at the hard bound discard only redundant records already covered by another.
	while revealed_areas.size()>REVEAL_HISTORY_LIMIT:
		var removed:=false
		for candidate_index in mini(64,revealed_areas.size()):
			var candidate:Dictionary=revealed_areas[candidate_index]
			if String(candidate.get("kind","circle"))!="circle": continue
			var center:=Vector2(float(candidate.get("x",0.0)),float(candidate.get("z",0.0)))
			for cover_index in revealed_areas.size():
				if cover_index==candidate_index: continue
				var cover:Dictionary=revealed_areas[cover_index]
				if _revealed_record_contains(cover,center) and float(cover.get("radius",0.0))>=float(candidate.get("radius",0.0)):
					revealed_areas.remove_at(candidate_index)
					removed=true
					break
			if removed: break
		if not removed:
			# This path should be exceptional because travel and each returned report
			# occupy aggregate trail records. It forgets one oldest low-detail record
			# instead of fabricating knowledge of every place between unrelated records.
			revealed_areas.pop_front()


func _captured_player_scout_count()->int:
	var total:=0
	for cohort in captured_player_scouts.values(): total+=maxi(0,int((cohort as Dictionary).get("count",0)))
	return total


func _route_distance_to_point(route:Array,point:Vector2)->float:
	var closest:=INF
	for route_index in maxi(0,route.size()-1):
		var a_dict:Dictionary=route[route_index]; var b_dict:Dictionary=route[route_index+1]
		var a:=Vector2(float(a_dict.get("x",0.0)),float(a_dict.get("z",0.0)))
		var b:=Vector2(float(b_dict.get("x",0.0)),float(b_dict.get("z",0.0)))
		closest=minf(closest,point.distance_to(Geometry2D.get_closest_point_to_segment(point,a,b)))
	return closest


func _player_scout_hazards(mission:Dictionary)->Array[Dictionary]:
	var hazards:Array[Dictionary]=[]
	var route:Array=mission.get("route",[])
	var concealment:=clampf(float(mission.get("concealment",0.80)),0.0,1.0)
	var evasion:=clampf(float(mission.get("evasion",0.86)),0.0,1.0)
	var duration_factor:=clampf(float(mission.get("duration_days",90))/180.0,0.35,2.1)
	for civ in civilizations:
		var closest:=_route_distance_to_point(route,_civilization_world_position(civ))
		if closest>105.0: continue
		var exposure:=clampf(1.0-closest/105.0,0.0,1.0)
		var patrol_quality:=clampf(float(civ.get("military_readiness",0.5))*0.65+float(civ.get("logistics",0.2))*0.20+float(civ.get("knowledge",0.2))*0.15,0.0,1.0)
		var chance:=clampf(exposure*(0.16+patrol_quality*0.42)*(1.0-concealment*0.48)*(1.0-evasion*0.38)*duration_factor,0.0,0.42)
		if chance>0.005: hazards.append({"civ_id":String(civ.id),"chance":chance,"aggression":float(civ.get("aggression",0.5)),"closest_km":closest})
	return hazards


func _player_scout_risk_snapshot(mission:Dictionary)->Dictionary:
	# This is a planning estimate based only on known duration and the party's
	# own capabilities. Using hidden patrol locations here would itself leak
	# knowledge of civilizations the player has not encountered.
	var concealment:=clampf(float(mission.get("concealment",0.80)),0.0,1.0)
	var evasion:=clampf(float(mission.get("evasion",0.86)),0.0,1.0)
	var exposure:=0.06+clampf(float(mission.get("duration_days",90))/365.0,0.0,1.0)*0.24
	var risk:=clampf(exposure*(1.0-concealment*0.35)*(1.0-evasion*0.25),0.0,0.42)
	var label:="LOW" if risk<0.12 else ("GUARDED" if risk<0.26 else "HIGH")
	return {"estimated_risk":risk,"label":label,"concealment":concealment,"evasion":evasion}


# Scouting geography is supplied by the rendered world's authoritative height
# field. Fog is knowledge, never a terrain type: without this authority the
# simulation must not assume that an unknown straight line is dry land.
func set_ground_survey_authority(survey_query:Callable)->void:
	ground_survey_authority=survey_query


func set_scout_geography_authority(land_query:Callable)->void:
	scout_land_authority=land_query
	_audit_active_scout_land_route()


func _scout_land_at(position:Vector2)->bool:
	if absf(position.x)>CIVILIZATION_WORLD_RADIUS_X_KM or absf(position.y)>CIVILIZATION_WORLD_RADIUS_Z_KM:
		return false
	if not scout_land_authority.is_valid(): return false
	return bool(scout_land_authority.call(position))


func _scout_segment_is_land(start:Vector2,finish:Vector2,sample_step_km:float=SCOUT_LAND_SAMPLE_KM)->bool:
	var distance:=start.distance_to(finish)
	var samples:=clampi(ceili(distance/maxf(0.5,sample_step_km)),1,4096)
	# Coastal watercraft turn short water gaps (straits, bay mouths, river
	# deltas) from absolute walls into crossings. Open sea remains a wall:
	# only a bounded consecutive water stretch may be bridged.
	var water_allowance_km:=_scout_water_crossing_allowance_km()
	var consecutive_water_km:=0.0
	var step_km:=distance/float(samples)
	for sample_index in samples+1:
		var point:=start.lerp(finish,float(sample_index)/float(samples))
		if _scout_land_at(point):
			consecutive_water_km=0.0
			continue
		consecutive_water_km+=step_km
		if consecutive_water_km>water_allowance_km: return false
	return true


func _scout_water_crossing_allowance_km()->float:
	if "coastal_watercraft" in GameState.known_discoveries and DiscoverySystem.adoption("coastal_watercraft")>=0.10: return 40.0
	if "river_craft" in GameState.known_discoveries and DiscoverySystem.adoption("river_craft")>=0.10: return 10.0
	return 0.0


func _scout_route_is_land(route:Array)->bool:
	if route.size()<2: return false
	for route_index in route.size()-1:
		var start_data:Dictionary=route[route_index]
		var finish_data:Dictionary=route[route_index+1]
		var start:=Vector2(float(start_data.get("x",0.0)),float(start_data.get("z",0.0)))
		var finish:=Vector2(float(finish_data.get("x",0.0)),float(finish_data.get("z",0.0)))
		if not _scout_segment_is_land(start,finish): return false
	return true


func _scout_route_distance(route:Array)->float:
	var distance:=0.0
	for route_index in route.size()-1:
		var start_data:Dictionary=route[route_index]
		var finish_data:Dictionary=route[route_index+1]
		distance+=Vector2(float(start_data.get("x",0.0)),float(start_data.get("z",0.0))).distance_to(Vector2(float(finish_data.get("x",0.0)),float(finish_data.get("z",0.0))))
	return distance


func _scout_route_dictionaries(points:Array[Vector2])->Array[Dictionary]:
	var route:Array[Dictionary]=[]
	for point in points: route.append({"x":point.x,"z":point.y})
	return route


func _compress_scout_land_path(points:Array[Vector2])->Array[Vector2]:
	if points.size()<2: return []
	var compressed:Array[Vector2]=[points[0]]
	var anchor:=0
	while anchor<points.size()-1:
		var next_index:=points.size()-1
		while next_index>anchor+1 and not _scout_segment_is_land(points[anchor],points[next_index]):
			next_index-=1
		if next_index<=anchor or not _scout_segment_is_land(points[anchor],points[next_index]): return []
		compressed.append(points[next_index])
		anchor=next_index
		if compressed.size()>SCOUT_ROUTE_POINT_LIMIT: return []
	return compressed


func _scout_grid_point_is_land(point:Vector2,cell_size:float)->bool:
	if not _scout_land_at(point): return false
	var inset:=minf(SCOUT_LAND_SAMPLE_KM,cell_size*0.34)
	for offset in [Vector2(inset,0.0),Vector2(-inset,0.0),Vector2(0.0,inset),Vector2(0.0,-inset)]:
		if not _scout_land_at(point+offset): return false
	return true


func _plan_scout_land_route_at_resolution(start:Vector2,finish:Vector2,cell_size:float)->Dictionary:
	var goal_delta:=(finish-start)/cell_size
	var nominal_goal:=Vector2i(roundi(goal_delta.x),roundi(goal_delta.y))
	var margin_cells:=12
	var minimum:=Vector2i(mini(0,nominal_goal.x)-margin_cells,mini(0,nominal_goal.y)-margin_cells)
	var maximum:=Vector2i(maxi(0,nominal_goal.x)+margin_cells,maxi(0,nominal_goal.y)+margin_cells)
	var dimensions:=maximum-minimum+Vector2i.ONE
	if dimensions.x>SCOUT_ROUTE_GRID_LIMIT or dimensions.y>SCOUT_ROUTE_GRID_LIMIT:
		return {"ok":false,"reason":"The coastline search exceeded its bounded planning window."}
	var grid:=AStarGrid2D.new()
	grid.region=Rect2i(minimum,dimensions)
	grid.cell_size=Vector2.ONE*cell_size
	grid.offset=start
	grid.diagonal_mode=AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	grid.default_compute_heuristic=AStarGrid2D.HEURISTIC_EUCLIDEAN
	grid.default_estimate_heuristic=AStarGrid2D.HEURISTIC_EUCLIDEAN
	grid.update()
	for grid_y in range(minimum.y,maximum.y+1):
		for grid_x in range(minimum.x,maximum.x+1):
			var cell:=Vector2i(grid_x,grid_y)
			var world_point:=start+Vector2(cell)*cell_size
			if not _scout_grid_point_is_land(world_point,cell_size): grid.set_point_solid(cell,true)
	grid.set_point_solid(Vector2i.ZERO,false)
	var goal_cell:=Vector2i(2147483647,2147483647)
	var closest_goal_distance:=INF
	for radius in 3:
		for y_offset in range(-radius,radius+1):
			for x_offset in range(-radius,radius+1):
				var candidate:=nominal_goal+Vector2i(x_offset,y_offset)
				if not grid.is_in_boundsv(candidate) or grid.is_point_solid(candidate): continue
				var candidate_world:=start+Vector2(candidate)*cell_size
				var distance_to_goal:=candidate_world.distance_to(finish)
				if distance_to_goal>=closest_goal_distance or not _scout_segment_is_land(candidate_world,finish): continue
				closest_goal_distance=distance_to_goal
				goal_cell=candidate
		if goal_cell.x!=2147483647: break
	if goal_cell.x==2147483647:
		return {"ok":false,"reason":"The target has no land approach at this map resolution."}
	var grid_path:=grid.get_point_path(Vector2i.ZERO,goal_cell)
	if grid_path.is_empty(): return {"ok":false,"reason":"No continuous land route connects the known points."}
	var raw_points:Array[Vector2]=[]
	for point in grid_path: raw_points.append(point)
	raw_points[0]=start
	if raw_points[-1].distance_to(finish)>0.001: raw_points.append(finish)
	else: raw_points[-1]=finish
	for path_index in raw_points.size()-1:
		if not _scout_segment_is_land(raw_points[path_index],raw_points[path_index+1]):
			return {"ok":false,"reason":"The coarse route still crosses open water."}
	var compressed:=_compress_scout_land_path(raw_points)
	if compressed.size()<2:
		return {"ok":false,"reason":"The land route is too intricate for a bounded expedition record."}
	var route:=_scout_route_dictionaries(compressed)
	return {"ok":true,"route":route,"distance_km":_scout_route_distance(route),"travel_mode":"land"}


func _plan_scout_land_route(start:Vector2,finish:Vector2)->Dictionary:
	if not scout_land_authority.is_valid():
		return {"ok":false,"reason":"No terrain survey is available. Unknown ground cannot be assumed to be land."}
	if not _scout_land_at(start):
		return {"ok":false,"reason":"The expedition origin is not on traversable land."}
	if not _scout_land_at(finish):
		return {"ok":false,"reason":"The destination lies in open water. Land scouts require dry ground."}
	var direct_distance:=start.distance_to(finish)
	if direct_distance<=0.001:
		return {"ok":true,"route":[{"x":start.x,"z":start.y},{"x":finish.x,"z":finish.y}],"distance_km":0.0,"travel_mode":"land"}
	if _scout_segment_is_land(start,finish):
		return {"ok":true,"route":[{"x":start.x,"z":start.y},{"x":finish.x,"z":finish.y}],"distance_km":direct_distance,"travel_mode":"land"}
	var base_cell:=clampf(direct_distance/36.0,4.0,140.0)
	for cell_size in [base_cell,maxf(4.0,base_cell*0.5)]:
		var plan:=_plan_scout_land_route_at_resolution(start,finish,float(cell_size))
		if bool(plan.get("ok",false)): return plan
	return {"ok":false,"reason":"No continuous land route reaches this target. %s" % ("Even coastal craft cannot bridge this much open water." if _scout_water_crossing_allowance_km()>0.0 else "Open water blocks the expedition; river and coastal watercraft are not yet established knowledge.")}


const SCOUT_HEADINGS:Dictionary={"east":0.0,"southeast":45.0,"south":90.0,"southwest":135.0,"west":180.0,"northwest":225.0,"north":270.0,"northeast":315.0}

func _plan_open_scout_route(one_way_range:float,rng:RandomNumberGenerator,heading:String="")->Dictionary:
	if not scout_land_authority.is_valid():
		return {"ok":false,"reason":"No terrain survey is available. Unknown ground cannot be assumed to be land."}
	var ordered_heading:=heading.to_lower().strip_edges()
	# A dictated heading is an order, not a vague preference. Keep the endpoint
	# inside that compass sector. The land route may bend around terrain, but an
	# order to go north can no longer quietly produce an eastbound expedition.
	var has_ordered_heading:=SCOUT_HEADINGS.has(ordered_heading)
	var base_angle:=deg_to_rad(float(SCOUT_HEADINGS[ordered_heading])) if has_ordered_heading else rng.randf_range(-PI,PI)
	var angle_offsets:Array=[0.0,0.16,-0.16,0.31,-0.31] if has_ordered_heading else [0.0,0.42,-0.42,0.84,-0.84,1.26,-1.26]
	for range_share in [1.0,0.82,0.64,0.46,0.30]:
		for angle_offset in angle_offsets:
			var endpoint:=player_world_origin+Vector2.RIGHT.rotated(base_angle+float(angle_offset))*one_way_range*float(range_share)
			if not _scout_land_at(endpoint): continue
			var plan:=_plan_scout_land_route(player_world_origin,endpoint)
			if not bool(plan.get("ok",false)) or float(plan.get("distance_km",INF))>one_way_range: continue
			plan["target_reachable"]=true
			plan["ordered_heading"]=ordered_heading if has_ordered_heading else ""
			plan["planned_heading"]=_compass_phrase(player_world_origin,endpoint)
			return plan
	var direction_note:=" toward %s" % ordered_heading.to_upper() if has_ordered_heading else ""
	return {"ok":false,"reason":"No reachable land corridor%s was found within this expedition's range. Choose another heading or a longer expedition; the party was not sent." % direction_note}


func _audit_active_scout_land_route()->void:
	if scout_missions.is_empty() or not scout_land_authority.is_valid(): return
	for mission_index in scout_missions.size():
		var mission:Dictionary=scout_missions[mission_index]
		var route:Array=mission.get("route",[])
		if String(mission.get("travel_mode","land"))=="land" and _scout_route_is_land(route): continue
		var safe_route:Array[Dictionary]=[]
		if not route.is_empty():
			var first:Dictionary=route[0]
			safe_route.append(first.duplicate(true))
			for route_index in route.size()-1:
				var a_data:Dictionary=route[route_index]
				var b_data:Dictionary=route[route_index+1]
				var a:=Vector2(float(a_data.get("x",0.0)),float(a_data.get("z",0.0)))
				var b:=Vector2(float(b_data.get("x",0.0)),float(b_data.get("z",0.0)))
				if not _scout_segment_is_land(a,b): break
				safe_route.append(b_data.duplicate(true))
		if safe_route.is_empty(): safe_route.append({"x":player_world_origin.x,"z":player_world_origin.y})
		if safe_route.size()==1: safe_route.append(safe_route[0].duplicate(true))
		mission["route"]=safe_route
		mission["planned_distance"]=_scout_route_distance(safe_route)
		mission["reached_target"]=false
		mission["travel_mode"]="land"
		mission["route_status"]="turning_back"
		mission["turnback_reason"]="The planned route met open water. The land party turned back; no observations beyond the dry route can return."
		mission["return_day"]=mini(int(mission.get("return_day",int(GameState.elapsed_days)+1)),int(GameState.elapsed_days)+maxi(1,ceili(float(mission.get("planned_distance",0.0))/14.0)))
		# A turning-back party is rushing home; road variance no longer applies
		# beyond a short margin past the recomputed return.
		mission["actual_return_day"]=mini(int(mission.get("actual_return_day",int(mission.return_day))),int(mission.return_day)+2)
		scout_missions[mission_index]=mission


func scout_party_capacity()->int:
	## How many aggregate scout parties can be away at once. Purely a function
	## of population: roughly one organizable party per 60 people.
	return clampi(GameState.population_total/60,1,6)


func _soonest_returning_mission()->Dictionary:
	var soonest:Dictionary={}
	for mission_variant in scout_missions:
		var mission:Dictionary=mission_variant
		if soonest.is_empty() or int(mission.get("return_day",0))<int(soonest.get("return_day",0)): soonest=mission
	return soonest


func _complete_due_scout_missions(day:int)->void:
	for mission_variant in scout_missions.duplicate():
		var mission:Dictionary=mission_variant
		if day>=int(mission.get("actual_return_day",mission.get("return_day",day+1))):
			_complete_scout_mission(mission,day)


func exploration_status()->Dictionary:
	initialize()
	var known:=0
	for civ in civilizations:
		if int((civ.get("player_relation",{}) as Dictionary).get("contact_level",0))>=2: known+=1
	var active:=not scout_missions.is_empty()
	var current_day:=int(GameState.elapsed_days)
	# Scalar fields describe the soonest-returning party for legacy callers;
	# `parties` carries the complete concurrent picture.
	var mission:=_soonest_returning_mission()
	var remaining:=maxi(0,int(mission.get("return_day",current_day))-current_day) if active else 0
	var duration:=maxi(1,int(mission.get("duration_days",1))) if active else 1
	var risk:=_player_scout_risk_snapshot(mission) if active else {}
	var missing:=_captured_player_scout_count()
	var capacity:=scout_party_capacity()
	var parties:Array[Dictionary]=[]
	for party_variant in scout_missions:
		var party:Dictionary=party_variant
		var party_remaining:=maxi(0,int(party.get("return_day",current_day))-current_day)
		var party_duration:=maxi(1,int(party.get("duration_days",1)))
		# Overdue = past the PLANNED day the settlement counts down to. The real
		# return day is the road's secret; the UI must never leak it.
		var overdue_days:=maxi(0,current_day-int(party.get("return_day",current_day)))
		parties.append({"mission_id":int(party.get("mission_id",0)),"personnel":int(party.get("personnel",0)),"days_remaining":party_remaining,"return_day":int(party.get("return_day",-1)),"duration_days":party_duration,"overdue_days":overdue_days,"progress":clampf(1.0-float(party_remaining)/float(party_duration),0.0,1.0),"target_id":String(party.get("target_id","")),"target_label":String(party.get("target_label","OPEN EXPLORATION")),"ordered_heading":String(party.get("ordered_heading","")),"planned_heading":String(party.get("planned_heading","")),"route_status":String(party.get("route_status","")),"turnback_reason":String(party.get("turnback_reason","")),"provisions":float(party.get("provisions",0.0))})
	var idle_message:="The last scout party did not return, so none of its observations became knowledge. %d scouts remain missing from the population's available labor." % missing if missing>0 else ("No foreign polity has been met. Choose how long a scout party may range before it must return." if known==0 else "Dispatch another scout party; only its returned report reveals new ground or contacts.")
	var active_message:="%d scout part%s away. Observations remain aboard each party; interception can erase an entire report before it returns." % [scout_missions.size(),"y is" if scout_missions.size()==1 else "ies are"]
	if active and String(mission.get("route_status",""))=="turning_back": active_message=String(mission.get("turnback_reason","The land route was blocked, so the party is turning back."))
	return {"active":active,"progress":clampf(1.0-float(remaining)/float(duration),0.0,1.0) if active else 0.0,"days_remaining":remaining,"return_day":int(mission.get("return_day",-1)),"duration_days":int(mission.get("duration_days",0)),"personnel":int(mission.get("personnel",0)),"provisions":float(mission.get("provisions",0.0)),"target_id":String(mission.get("target_id","")),"target_kind":String(mission.get("target_kind","explore")),"target_label":String(mission.get("target_label","OPEN EXPLORATION")),"travel_mode":String(mission.get("travel_mode","land")),"route_status":String(mission.get("route_status","")),"contacted_count":known,"can_begin":scout_missions.size()<capacity,"active_count":scout_missions.size(),"capacity":capacity,"parties":parties,"report_count":scout_reports.size(),"latest_report":scout_reports[0].duplicate(true) if not scout_reports.is_empty() else {},"last_outcome":last_scout_outcome.duplicate(true),"missing_scouts":missing,"risk":risk,"message":active_message if active else idle_message}


func scout_target_options()->Array[Dictionary]:
	initialize()
	var options:Array[Dictionary]=[{
		"id":"open_world","kind":"explore","civ_id":"","label":"OPEN EXPLORATION",
		"description":"Chart an unexamined direction. Any encounters remain unknown until the party returns.","position":{}
	},{
		"id":"recruit_people","kind":"recruit_people","civ_id":"","label":"SEEK WILLING RECRUITS",
		"description":"Search reachable country for wanderers or small bands who may freely choose to join. A return with recruits is never guaranteed.","position":{}
	}]
	for encounter_variant in contact_encounters_snapshot():
		var encounter:Dictionary=encounter_variant
		var position:Dictionary=encounter.get("position",{})
		if not position.has("x") or not position.has("z"): continue
		options.append({
			"id":"contact:%s" % String(encounter.civ_id),"kind":"investigate_contact","civ_id":String(encounter.civ_id),
			"label":"INVESTIGATE %s ENCOUNTER" % String(encounter.name).to_upper(),
			"description":"Return to the known encounter site, chart its surroundings, and look for routes toward the polity's home.",
			"position":position.duplicate(true)
		})
	for lead:Dictionary in rumor_network.list_leads("player",int(GameState.elapsed_days)):
		options.append({"id":"lead:"+String(lead.id),"kind":"investigate_lead","lead_id":String(lead.id),"civ_id":String(lead.subject),"label":"INVESTIGATE LEAD · "+String(lead.name),"description":rumor_network.describe(lead),"position":lead.center.duplicate(true)})
	for city:Dictionary in city_intelligence.known_cities():
		options.append({"id":"city:"+String(city.city_id),"kind":"observe_city","city_id":city.city_id,"civ_id":city.civ_id,"label":"OBSERVE "+String(city.name).to_upper(),"description":"Revisit this independently reported city. Only a returning party updates its dated estimates.","position":city.position.duplicate(true)})
	return options


func _scout_target_option(target_id:String)->Dictionary:
	var normalized:=target_id if target_id!="" else "open_world"
	if normalized.begins_with("settlement:"): normalized="city:"+city_intelligence.primary_id(normalized.trim_prefix("settlement:"))
	for option in scout_target_options():
		if String(option.get("id",""))==normalized: return option.duplicate(true)
	return {}


func scout_mission_quote(duration_days:int,target_id:String="open_world",heading:String="")->Dictionary:
	if duration_days not in SCOUT_DURATIONS: return {"error":"Scout duration must be 30, 90, 180, or 365 days."}
	var target:=_scout_target_option(target_id)
	if target.is_empty(): return {"error":"That scouting target is not part of current knowledge."}
	var population:=maxf(1.0,GameState.population_exact)
	var personnel:=clampi(roundi(population*0.012),6,80)
	var provisions:=float(personnel)*float(duration_days)*0.55
	var logistics:=clampf(float(GameState.simulation_metrics.get("logistics",0.16)),0.0,1.0)
	var one_way_range:=scout_one_way_range(duration_days)
	var target_distance:=0.0
	var target_position:Dictionary=target.get("position",{})
	if target_position.has("x") and target_position.has("z"):
		target_distance=player_world_origin.distance_to(Vector2(float(target_position.x),float(target_position.z)))
	var route_plan:Dictionary={}
	var target_kind:=String(target.get("kind","explore"))
	var directional_search:=target_kind in ["explore","recruit_people"]
	var ordered_heading:=heading.to_lower().strip_edges() if SCOUT_HEADINGS.has(heading.to_lower().strip_edges()) else ""
	if target_kind=="investigate_lead":
		route_plan=rumor_network.plan("player",String(target.lead_id),next_scout_mission_id,one_way_range,int(GameState.elapsed_days))
		target_position=route_plan.get("search_position",{}).duplicate(true)
		target["position"]=target_position
		target_distance=player_world_origin.distance_to(rumor_network.vector(target_position)) if not target_position.is_empty() else 0.0
	elif directional_search and ordered_heading!="":
		var quote_rng:=RandomNumberGenerator.new()
		quote_rng.seed=last_world_seed^duration_days*8191^String(target.id).hash()
		route_plan=_plan_open_scout_route(one_way_range,quote_rng,ordered_heading)
	elif not directional_search and target_position.has("x") and target_position.has("z"):
		route_plan=_plan_scout_land_route(player_world_origin,Vector2(float(target_position.x),float(target_position.z)))
	var planning_mission:={"duration_days":duration_days,"concealment":clampf(0.72+clampf(float(GameState.combined_intelligence),0.0,1.0)*0.12+logistics*0.09-float(personnel)/80.0*0.06,0.68,0.93),"evasion":clampf(0.76+logistics*0.14+clampf(float(GameState.combined_intelligence),0.0,1.0)*0.08,0.74,0.95)}
	var risk:=_player_scout_risk_snapshot(planning_mission)
	var committed_scouts:=0
	for mission_variant in scout_missions: committed_scouts+=int((mission_variant as Dictionary).get("personnel",0))
	var blocker:=""
	if scout_missions.size()>=scout_party_capacity(): blocker="All %d scout parties this population can organize are already away." % scout_party_capacity()
	elif not scout_land_authority.is_valid(): blocker="No terrain survey is available. Unknown ground cannot be assumed to be land."
	elif population<float(personnel+committed_scouts)+12.0: blocker="The population cannot spare another viable party."
	elif FoodSystem.total_stored()+0.0001<provisions: blocker="Requires %.1f Food; only %.1f is stored." % [provisions,FoodSystem.total_stored()]
	elif target_distance>one_way_range: blocker="This mission can reach about %.0f km, but the target is %.0f km away. Choose a longer expedition." % [one_way_range,target_distance]
	elif not route_plan.is_empty() and not bool(route_plan.get("ok",false)): blocker=String(route_plan.get("reason","No continuous land-only route reaches this target."))
	elif not route_plan.is_empty() and float(route_plan.get("distance_km",INF))>one_way_range: blocker="The land route is %.0f km after following the coastline, beyond this party's %.0f km range. Choose a longer expedition." % [float(route_plan.get("distance_km",0.0)),one_way_range]
	var charted_distance:=one_way_range*2.0 if directional_search else float(route_plan.get("distance_km",target_distance))*2.0
	return {"duration_days":duration_days,"personnel":personnel,"provisions":provisions,"one_way_range_km":one_way_range,"charted_route_km":charted_distance,"target_distance_km":target_distance,"target":target,"risk":risk,"route_plan":route_plan,"ordered_heading":ordered_heading,"travel_mode":"land","can_dispatch":blocker=="","blocker":blocker}


func dispatch_scouts(duration_days:int,target_id:String="open_world",heading:String="")->Dictionary:
	initialize()
	var normalized_heading:=heading.to_lower().strip_edges()
	if normalized_heading!="" and not SCOUT_HEADINGS.has(normalized_heading): return {"error":"Unknown scout heading: %s." % heading}
	var quote:=scout_mission_quote(duration_days,target_id,normalized_heading)
	if quote.has("error"): return quote
	if not bool(quote.get("can_dispatch",false)): return {"error":String(quote.get("blocker","The mission cannot depart."))}
	var personnel:=int(quote.personnel)
	var provisions:=float(quote.provisions)
	var target_option:Dictionary=quote.target
	var rng:=RandomNumberGenerator.new()
	rng.seed=last_world_seed^int(GameState.elapsed_days)*104729^duration_days*8191^scout_reports.size()*65537^String(target_option.id).hash()^next_scout_mission_id*2654435761
	var one_way_range:=scout_one_way_range(duration_days)
	var target_position:Dictionary=target_option.get("position",{})
	var route_plan:Dictionary=quote.get("route_plan",{})
	if String(target_option.get("kind","explore")) in ["explore","recruit_people"] and route_plan.is_empty(): route_plan=_plan_open_scout_route(one_way_range,rng,normalized_heading)
	if not bool(route_plan.get("ok",false)):
		return {"error":String(route_plan.get("reason","No terrain-authoritative land route can support this expedition."))}
	var route:Array[Dictionary]=[]
	route.assign(route_plan.get("route",[]))
	if route.size()<2 or not _scout_route_is_land(route):
		return {"error":"The planned scout trail is not a continuous land route. Nothing was spent and the party did not depart."}
	var distance:=float(route_plan.get("distance_km",_scout_route_distance(route)))
	if distance>one_way_range+0.001:
		return {"error":"The coastline-aware route is %.0f km, beyond this party's %.0f km range." % [distance,one_way_range]}
	var start_day:=int(GameState.elapsed_days)
	var issued_provisions:=FoodSystem.issue_for_obligation(provisions,"scouting","Scout party • %s" % String(target_option.label),float(duration_days),personnel)
	if issued_provisions+0.0001<provisions: return {"error":"Food stores changed before the scout party could be provisioned."}
	var logistics:=clampf(float(GameState.simulation_metrics.get("logistics",0.16)),0.0,1.0)
	var field_knowledge:=clampf(float(GameState.combined_intelligence),0.0,1.0)
	var concealment:=clampf(0.72+field_knowledge*0.12+logistics*0.09-float(personnel)/80.0*0.06,0.68,0.93)
	var evasion:=clampf(0.76+logistics*0.14+field_knowledge*0.08,0.74,0.95)
	var planned_heading:=_compass_phrase(player_world_origin,Vector2(float(route[-1].get("x",player_world_origin.x)),float(route[-1].get("z",player_world_origin.y))))
	var mission:Dictionary={"mission_id":next_scout_mission_id,"start_day":start_day,"return_day":start_day+duration_days,"duration_days":duration_days,"personnel":personnel,"population_sources":{"productive":personnel},"provisions":issued_provisions,"route":route,"planned_distance":distance,"ordered_heading":normalized_heading if String(target_option.kind) in ["explore","recruit_people"] else "","planned_heading":planned_heading,"target_id":String(target_option.id),"target_kind":String(target_option.kind),"target_civ_id":String(target_option.get("civ_id","")),"target_city_id":String(target_option.get("city_id","")),"target_label":String(target_option.label),"target_position":target_position.duplicate(true),"reached_target":bool(route_plan.get("target_reachable",true)),"travel_mode":"land","route_status":"outbound_and_returning","concealment":concealment,"evasion":evasion}
	# Journeys are not clockwork. The settlement counts down to the planned
	# day; the road decides the real one. Delay scales with the expedition:
	# the old fixed 21-day cap made nearly every long overdue party return at
	# the same visibly artificial moment.
	var variance:=_scout_timing_variance(duration_days,next_scout_mission_id,start_day)
	mission["timing_variance_days"]=variance
	mission["actual_return_day"]=maxi(start_day+2,start_day+duration_days+variance)
	if String(target_option.kind)=="investigate_lead":
		mission["rumor_lead_id"]=String(target_option.lead_id)
		mission["rumor_subject"]=String(target_option.civ_id)
	rumor_network.prepare(mission,"player",start_day)
	next_scout_mission_id+=1
	var risk:=_player_scout_risk_snapshot(mission)
	mission["estimated_interception_risk"]=float(risk.estimated_risk)
	scout_missions.append(mission)
	var direction_clause:=" on a %s search corridor" % planned_heading.to_upper()
	if normalized_heading!="": direction_clause=" under orders to search %s; its traversable corridor runs %s" % [normalized_heading.to_upper(),planned_heading.to_upper()]
	var message:="A %d-person aggregate scout party departs for %d days to %s%s with %.1f Food. Its planned corridor is now marked on the map. Every observation remains aboard the party and is lost if it cannot return. Estimated route risk: %s." % [personnel,duration_days,String(target_option.label).capitalize(),direction_clause,issued_provisions,String(risk.label)]
	_record_world_event("Scout party departs",message,"diplomacy",start_day)
	# Callers that commissioned this physical expedition need a durable identity
	# for its eventual return report. The mission remains the authoritative state;
	# this ID only lets a civic directive wait for and cite the same party.
	return {"ok":true,"mission_id":int(mission.mission_id),"message":message,"status":exploration_status()}


func _scout_timing_variance(duration_days:int,mission_id:int,start_day:int)->int:
	## Deterministic for saving/replays, but broad enough that 90-, 180-, and
	## 365-day parties do not all collapse onto a twenty-day delay. Players see
	## only the planned date and elapsed overdue days, never this hidden result.
	var timing_rng:=RandomNumberGenerator.new()
	timing_rng.seed=last_world_seed^mission_id*49979693^start_day*15487019^duration_days*32452843
	var timing_roll:=timing_rng.randf()
	if timing_roll<0.22:
		return -maxi(1,roundi(float(duration_days)*timing_rng.randf_range(0.04,0.12)))
	if timing_roll<=0.58:
		return 0
	return maxi(1,roundi(float(duration_days)*timing_rng.randf_range(0.035,0.32)))


func begin_exploration(duration_days:int=90)->Dictionary:
	return dispatch_scouts(duration_days)


func diplomatic_gift_options(civ_id:String)->Array[Dictionary]:
	initialize()
	var index:=_civilization_index(civ_id)
	if index<0: return []
	var relation:=_relation_with_strategy_defaults(civilizations[index].get("player_relation",{}),civilizations[index])
	if int(relation.get("contact_level",0))<2: return []
	var population:=maxf(1.0,GameState.population_exact)
	var result:Array[Dictionary]=[]
	for resource_name in ["Food","Timber","Fiber Plants","Clay","Stone"]:
		var amount:=clampf(population*(1.25 if resource_name=="Food" else 0.22),10.0 if resource_name=="Food" else 5.0,300.0 if resource_name=="Food" else 80.0)
		var available:=FoodSystem.total_stored() if resource_name=="Food" else maxf(0.0,float(GameState.resource_stockpiles.get(resource_name,0.0)))
		var reception:="especially useful" if (resource_name=="Food" and String(civilizations[index].get("strategy",""))=="sustenance") or (resource_name in ["Timber","Clay","Stone"] and String(civilizations[index].get("strategy","")) in ["expansion","fortification"]) else "respectable"
		result.append({"resource":resource_name,"amount":amount,"available":available,"can_send":available+0.0001>=amount,"label":"%.1f %s" % [amount,resource_name],"reception":reception})
	return result


func diplomatic_mission_quote(civ_id:String,gift_resource:String="",purpose:String="goodwill")->Dictionary:
	initialize()
	if not diplomatic_mission.is_empty(): return {"error":"A diplomatic mission is already away."}
	var index:=_civilization_index(civ_id)
	if index<0: return {"error":"Unknown civilization."}
	var civ:Dictionary=civilizations[index]
	var relation:=_relation_with_strategy_defaults(civ.get("player_relation",{}),civ)
	if int(relation.get("contact_level",0))<2: return {"error":"No direct contact exists with this polity."}
	if not bool(relation.get("home_location_known",false)):
		return {"error":"Their settlement is still unlocated. Send scouts to investigate the returned contact site; diplomats need a confirmed physical destination."}
	var target_position:Dictionary=(relation.get("home_position",{}) as Dictionary).duplicate(true)
	if not target_position.has("x") or not target_position.has("z"):
		return {"error":"The settlement report has no usable map position. A returned scouting report must confirm the route before diplomats can depart."}
	var normalized_purpose:=purpose.strip_edges().to_lower().replace(" ","_")
	if normalized_purpose!="goodwill" and normalized_purpose not in CARRIED_DIPLOMATIC_ACTIONS: return {"error":"Unknown diplomatic purpose."}
	if normalized_purpose in CARRIED_DIPLOMATIC_ACTIONS:
		var availability:=player_action_availability(civ_id,normalized_purpose)
		if availability.has("error"): return availability
	elif bool(relation.get("at_war",false)):
		return {"error":"A goodwill delegation cannot cross an active war; send peace envoys instead."}
	var gift:Dictionary={"resource":"","amount":0.0,"available":0.0,"can_send":true,"label":"NO GIFT","reception":"proposal only"}
	if gift_resource!="":
		gift={}
		for option in diplomatic_gift_options(civ_id):
			if String(option.resource)==gift_resource: gift=option; break
		if gift.is_empty(): return {"error":"Choose a recognized physical gift."}
		if not bool(gift.can_send): return {"error":"The mission requires %s; only %.1f is available." % [String(gift.label),float(gift.available)]}
	if normalized_purpose=="goodwill" and gift_resource=="": return {"error":"A goodwill mission needs a physical gift or a concrete proposal."}
	if normalized_purpose=="send_aid" and gift_resource!="Food": return {"error":"Food-aid envoys must carry the food they are offering."}
	var target_kind:="known settlement"
	var target:=Vector2(float(target_position.x),float(target_position.z))
	var distance:=player_world_origin.distance_to(target)
	var logistics:=clampf(float(GameState.simulation_metrics.get("logistics",0.16)),0.0,1.0)
	var travel_days:=maxi(3,ceili(distance/(17.0*(0.75+logistics*0.25))))
	var personnel:=clampi(roundi(GameState.population_exact*0.004),2,16)
	var total_days:=travel_days*2
	var provisions:=float(personnel)*float(total_days)*0.55
	var food_required:=provisions+(float(gift.amount) if String(gift.resource)=="Food" else 0.0)
	if FoodSystem.total_stored()+0.0001<food_required: return {"error":"Envoys and gift require %.1f Food; only %.1f is stored." % [food_required,FoodSystem.total_stored()]}
	return {"ok":true,"civ_id":civ_id,"civilization":String(civ.name),"gift":gift,"purpose":normalized_purpose,"purpose_label":String(DIPLOMATIC_PURPOSE_LABELS.get(normalized_purpose,"DIPLOMATIC MISSION")),"personnel":personnel,"provisions":provisions,"origin_position":{"x":player_world_origin.x,"z":player_world_origin.y},"target_position":target_position,"target_kind":target_kind,"distance_km":distance,"travel_days":travel_days,"total_days":total_days}


func dispatch_diplomat(civ_id:String,gift_resource:String="",purpose:String="goodwill")->Dictionary:
	var quote:=diplomatic_mission_quote(civ_id,gift_resource,purpose)
	if quote.has("error"): return quote
	var provisions:=FoodSystem.issue_for_obligation(float(quote.provisions),"diplomacy","Envoy provisions • %s" % String(quote.civilization),float(quote.total_days),int(quote.personnel))
	if provisions+0.0001<float(quote.provisions): return {"error":"Food stores changed before the envoys could be provisioned."}
	var gift:Dictionary=quote.gift
	var amount:=float(gift.amount)
	var delivered:=0.0
	if amount<=0.0:
		delivered=0.0
	elif String(gift.resource)=="Food":
		delivered=FoodSystem.issue_for_obligation(amount,"diplomacy","Diplomatic gift • %s" % String(quote.civilization),float(quote.total_days),int(quote.personnel))
	else:
		var available:=maxf(0.0,float(GameState.resource_stockpiles.get(String(gift.resource),0.0)))
		delivered=minf(available,amount)
		GameState.resource_stockpiles[String(gift.resource)]=available-delivered
	if delivered+0.0001<amount:
		FoodSystem.receive_external_food(provisions)
		return {"error":"The selected gift changed before the envoy could depart."}
	var day:=int(GameState.elapsed_days)
	diplomatic_mission={"civ_id":civ_id,"civilization":String(quote.civilization),"purpose":String(quote.purpose),"purpose_label":String(quote.purpose_label),"personnel":int(quote.personnel),"population_sources":{"support":int(quote.personnel)},"provisions":provisions,"gift_resource":String(gift.resource),"gift_amount":delivered,"origin_position":quote.origin_position,"target_position":quote.target_position,"target_kind":String(quote.target_kind),"depart_day":day,"arrival_day":day+int(quote.travel_days),"return_day":day+int(quote.total_days),"stage":"outbound","arrival_resolved":false,"distance_km":float(quote.distance_km)}
	rumor_network.prepare(diplomatic_mission,"player",day)
	var gift_phrase:=" with no material gift" if delivered<=0.0 else " carrying %.1f %s" % [delivered,String(gift.resource)]
	var message:="%d envoys depart for %s to %s%s. The proposal does not take effect until they travel there and carry a response home; %.1f travel rations were issued." % [int(quote.personnel),String(quote.civilization),String(quote.purpose_label).to_lower(),gift_phrase,provisions]
	_record_world_event("Diplomatic mission departs",message,"diplomacy",day)
	return {"ok":true,"message":message,"status":diplomatic_mission_status()}


func diplomatic_mission_status()->Dictionary:
	if diplomatic_mission.is_empty():
		return {"active":false,"history_count":diplomatic_history.size(),"latest":diplomatic_history[0].duplicate(true) if not diplomatic_history.is_empty() else {}}
	var day:=int(GameState.elapsed_days)
	return {"active":true,"civilization":String(diplomatic_mission.get("civilization","FOREIGN POLITY")),"civ_id":String(diplomatic_mission.get("civ_id","")),"purpose":String(diplomatic_mission.get("purpose","goodwill")),"purpose_label":String(diplomatic_mission.get("purpose_label","DIPLOMATIC MISSION")),"personnel":int(diplomatic_mission.get("personnel",0)),"provisions":float(diplomatic_mission.get("provisions",0.0)),"gift_resource":String(diplomatic_mission.get("gift_resource","")),"gift_amount":float(diplomatic_mission.get("gift_amount",0.0)),"stage":String(diplomatic_mission.get("stage","outbound")),"days_remaining":maxi(0,int(diplomatic_mission.get("return_day",day))-day),"arrival_days_remaining":maxi(0,int(diplomatic_mission.get("arrival_day",day))-day),"target_kind":String(diplomatic_mission.get("target_kind","rendezvous"))}


func _process_diplomatic_mission(day:int)->void:
	if diplomatic_mission.is_empty(): return
	var civ_id:=String(diplomatic_mission.get("civ_id",""))
	var index:=_civilization_index(civ_id)
	if index<0:
		diplomatic_mission.clear()
		return
	var civ:Dictionary=civilizations[index]
	var relation:=_relation_with_strategy_defaults(civ.get("player_relation",{}),civ)
	if not bool(diplomatic_mission.get("arrival_resolved",false)) and day>=int(diplomatic_mission.get("arrival_day",day+1)):
		diplomatic_mission["arrival_resolved"]=true
		diplomatic_mission["stage"]="returning"
		if day<=int(diplomatic_mission.return_day):
			var access:=clampf(.46+float(relation.get("opinion",0))*.24+(.10 if float(diplomatic_mission.get("gift_amount",0))>0 else 0),.22,.85)
			city_intelligence.stage(diplomatic_mission,"player",city_intelligence.vector(diplomatic_mission.target_position),access,day,"envoy:%s:%d" % [civ_id,int(diplomatic_mission.depart_day)])
		rumor_network.exchange(diplomatic_mission,"player",civ_id,city_intelligence.vector(diplomatic_mission.target_position),day)
		var origin_city:=city_intelligence.primary_id("player")
		if origin_city!="": city_intelligence.publish(civ_id,city_intelligence.location_record({"city_id":origin_city,"civ_id":"player","name":"Envoys' reported home","position":diplomatic_mission.origin_position},day,"envoys disclosed their origin","envoy:%d" % int(diplomatic_mission.depart_day)),day)
		if String(diplomatic_mission.get("purpose","goodwill"))=="declare_war":
			var declaration_result:=conduct_player_action(civ_id,"declare_war",true)
			diplomatic_mission["proposal_resolved"]=true
			diplomatic_mission["accepted"]=bool(declaration_result.get("ok",false))
			diplomatic_mission["outcome"]=String(declaration_result.get("message",declaration_result.get("error","The declaration could not be delivered.")))
			diplomatic_mission["reception"]="The declaration has reached its destination; the state of war begins now. The envoys are returning with their observations."
			civ=civilizations[index]
			relation=_relation_with_strategy_defaults(civ.get("player_relation",{}),civ)
		else:
			diplomatic_mission["reception"]="The delegation reached its destination. Its answer remains with the returning envoys."
	if bool(diplomatic_mission.get("arrival_resolved",false)) and day>=int(diplomatic_mission.get("return_day",day+1)):
		var gift_resource:=String(diplomatic_mission.get("gift_resource",""))
		var gift_amount:=float(diplomatic_mission.get("gift_amount",0.0))
		var response:=0.0
		if gift_amount>0.0:
			response=0.075+minf(0.06,gift_amount/maxf(1.0,float(civ.get("population",1.0)))*0.05)
			if gift_resource=="Food" and String(civ.get("strategy",""))=="sustenance": response+=0.035
			elif gift_resource in ["Timber","Clay","Stone"] and String(civ.get("strategy","")) in ["expansion","fortification"]: response+=0.025
			relation["opinion"]=clampf(float(relation.get("opinion",0.0))+response,-1.0,1.0)
			relation["border_tension"]=maxf(0.0,float(relation.get("border_tension",0.0))-0.07)
			if gift_resource=="Food": civ["food_days"]=clampf(float(civ.get("food_days",0.0))+gift_amount/maxf(1.0,float(civ.get("population",1.0))),0.0,180.0)
			civ["gift_value_received"]=maxf(0.0,float(civ.get("gift_value_received",0.0)))+gift_amount
		civ["player_relation"]=relation
		civilizations[index]=civ
		var purpose:=String(diplomatic_mission.get("purpose","goodwill"))
		var proposal_result:Dictionary={"ok":bool(diplomatic_mission.get("accepted",true)),"message":String(diplomatic_mission.get("outcome","The goodwill delegation was received."))}
		if purpose in CARRIED_DIPLOMATIC_ACTIONS and purpose!="send_aid" and not bool(diplomatic_mission.get("proposal_resolved",false)): proposal_result=conduct_player_action(civ_id,purpose,true)
		elif purpose=="send_aid": proposal_result={"ok":gift_resource=="Food" and gift_amount>0.0,"message":"The food aid reached %s and improved its reserves." % String(civ.name) if gift_resource=="Food" and gift_amount>0.0 else "The aid proposal arrived without food and was refused."}
		var accepted:=bool(proposal_result.get("ok",false))
		if purpose=="send_aid" and accepted: ForeignDiplomacy.commitments.note_food_aid(civ_id,gift_amount,day)
		var outcome:=String(proposal_result.get("message",proposal_result.get("error","The proposal was refused.")))
		civ=civilizations[index]
		relation=_relation_with_strategy_defaults(civ.get("player_relation",{}),civ)
		var diplomatic_report:=_diplomatic_return_report(civ,relation,diplomatic_mission,day)
		relation["contact_intelligence"]=clampf(float(relation.get("contact_intelligence",0.0))+float(diplomatic_report.get("intelligence_gain",0.0)),0.0,0.95)
		relation["last_observed_day"]=day
		var target_position:Dictionary=diplomatic_mission.get("target_position",{})
		if target_position.has("x") and target_position.has("z"):
			var origin_position:Dictionary=diplomatic_mission.get("origin_position",{"x":player_world_origin.x,"z":player_world_origin.y})
			_reveal_diplomatic_route(Vector2(float(origin_position.get("x",player_world_origin.x)),float(origin_position.get("z",player_world_origin.y))),Vector2(float(target_position.x),float(target_position.z)))
		var record:=diplomatic_mission.duplicate(true)
		record["returned_day"]=day; record["accepted"]=accepted; record["outcome"]=outcome
		record["observations"]=(diplomatic_report.get("observations",[]) as Array).duplicate(true)
		record["intelligence_gain"]=float(diplomatic_report.get("intelligence_gain",0.0))
		diplomatic_history.push_front(record)
		if diplomatic_history.size()>DIPLOMATIC_HISTORY_LIMIT: diplomatic_history.resize(DIPLOMATIC_HISTORY_LIMIT)
		var observations:Array=diplomatic_report.get("observations",[])
		var report_text:=" No defensible observation survived the return journey." if observations.is_empty() else " RETURNED OBSERVATIONS: %s" % " • ".join(PackedStringArray(observations))
		var message:="The envoys return from %s. %s%s" % [String(civ.name),outcome,report_text]
		_record_world_event("Diplomatic mission returns",message,"diplomacy",day)
		GameState.simulation_events.push_front({"day":day,"title":"DIPLOMATS RETURN","description":message,"domain":"diplomacy","severity":"major"})
		diplomatic_mission.clear()
	civ["player_relation"]=relation
	civilizations[index]=civ


func _diplomatic_return_report(civ:Dictionary,_relation:Dictionary,mission:Dictionary,day:int)->Dictionary:
	var cities:Array[Dictionary]=city_intelligence.deliver(mission,"player",day)
	rumor_network.deliver(mission,"player",day)
	rumor_network.record_cities("player",cities,day)
	var observations:Array[String]=[]
	for city:Dictionary in cities: observations.append(city_intelligence.describe(city))
	if observations.is_empty(): observations.append("No dated city assessment survived this journey. The previously known location remains on the chart.")
	mission["returned_city_observations"]=cities
	return {"day":day,"observations":observations,"city_observations":cities,"intelligence_gain":.055 if not cities.is_empty() else .015,"access":.5}


func _diplomatic_capacity_word(value:float)->String:
	if value<0.22: return "FRAGILE"
	if value<0.40: return "LIMITED"
	if value<0.60: return "DEVELOPING"
	if value<0.78: return "STRONG"
	return "FORMIDABLE"


func _reveal_diplomatic_route(origin:Vector2,target:Vector2)->void:
	_add_revealed_trail([_trail_point(origin),_trail_point(target)],24.0,"returned diplomatic route")


func _civilization_world_position(civ:Dictionary)->Vector2:
	# The bounded diplomatic direction becomes a point across most of the actual
	# 40,075 × 20,004 km map. Bounded aggregate civilization records remain enough;
	# no settlement or inhabitant records are generated to represent this scale.
	var normalized:=Vector2(civ.get("position",Vector2.ZERO))
	return Vector2(normalized.x*CIVILIZATION_WORLD_RADIUS_X_KM,normalized.y*CIVILIZATION_WORLD_RADIUS_Z_KM)


func _initialize_foreign_formations(seed_value:int)->void:
	foreign_formations.clear()
	for index in civilizations.size():
		var civ:Dictionary=civilizations[index]
		var home:=_civilization_world_position(civ)
		var next_civ:Dictionary=civilizations[(index+1)%civilizations.size()]
		var neighbor:=_civilization_world_position(next_civ)
		var rng:=RandomNumberGenerator.new(); rng.seed=seed_value^(index+1)*15485863
		var patrol_axis:=Vector2.RIGHT.rotated(rng.randf_range(-PI,PI))*rng.randf_range(45.0,105.0)
		var patrol_leg:=rng.randf_range(28.0,64.0)
		foreign_formations.append({"id":"%s_patrol" % String(civ.id),"civ_id":String(civ.id),"kind":"patrol","point_a":home-patrol_axis,"point_b":home+patrol_axis,"depart_day":-rng.randi_range(0,roundi(patrol_leg)),"leg_days":patrol_leg,"strength_share":rng.randf_range(0.035,0.075),"readiness":clampf(float(civ.military_readiness)*rng.randf_range(0.82,1.04),0.1,1.0)})
		var expedition_leg:=clampf(home.distance_to(neighbor)/6.0,55.0,360.0)
		foreign_formations.append({"id":"%s_expedition" % String(civ.id),"civ_id":String(civ.id),"kind":"expedition","point_a":home,"point_b":neighbor,"depart_day":-rng.randi_range(0,roundi(expedition_leg)),"leg_days":expedition_leg,"strength_share":rng.randf_range(0.07,0.15),"readiness":clampf(float(civ.military_readiness)*rng.randf_range(0.76,1.02),0.1,1.0)})
		# One bounded aggregate scout record represents the polity's current field
		# party. Its route is replaced after every homecoming; it is not an immortal
		# patrol replaying the same first journey for centuries.
		var scout:Dictionary={"id":"%s_scout" % String(civ.id),"civ_id":String(civ.id),"kind":"scout","point_a":home,"point_b":home,"depart_day":0,"leg_days":30.0,"strength_share":rng.randf_range(0.006,0.016),"readiness":clampf(float(civ.military_readiness)*rng.randf_range(0.72,0.98),0.1,1.0),"concealment":rng.randf_range(0.72,0.92),"evasion":rng.randf_range(0.78,0.95),"last_report_cycle":0,"disabled_until_day":0,"evaded_until_day":0,"last_interception_day":-9999,"search_sequence":-1}
		scout=_schedule_foreign_scout_mission(scout,civ,0)
		foreign_formations.append(scout)
	observation_revision+=1


func _bounded_world_point(point:Vector2)->Vector2:
	return Vector2(clampf(point.x,-CIVILIZATION_WORLD_RADIUS_X_KM,CIVILIZATION_WORLD_RADIUS_X_KM),clampf(point.y,-CIVILIZATION_WORLD_RADIUS_Z_KM,CIVILIZATION_WORLD_RADIUS_Z_KM))


func _relation_trace_center(relation:Dictionary)->Vector2:
	var center:Variant=relation.get("rival_player_trace_center",{})
	if center is Vector2: return center
	if center is Dictionary and center.has("x") and (center.has("z") or center.has("y")):
		return Vector2(float(center.get("x",0.0)),float(center.get("z",center.get("y",0.0))))
	return Vector2.INF


func _player_settlement_signal_radius(day:int)->float:
	## This is not vision. It is the physical radius over which an outward party
	## can encounter smoke, fields, roads, boats, refugees, or repeated tracks and
	## infer that an organized settlement is nearby.
	if not GameState.settlement_site_committed: return 0.0
	var population:=maxf(1.0,float(GameState.population_exact))
	var founded_day:=maxi(0,int(GameState.settlement_founded_day))
	var age_years:=maxf(0.0,float(day-founded_day)/365.0)
	var population_trace:=maxf(0.0,log(population/120.0)/log(10.0))*22.0
	var settlement_count:=maxi(1,GameState.player_settlements.size())
	var network_trace:=sqrt(float(settlement_count)-1.0)*18.0
	var logistics:=clampf(float(GameState.simulation_metrics.get("logistics",0.16)),0.0,1.0)
	var production:=clampf(float(GameState.simulation_metrics.get("material_capacity",0.12)),0.0,1.0)
	var activity_trace:=(logistics*0.58+production*0.42)*36.0
	var inherited_trace:=log(1.0+age_years)/log(2.0)*4.0
	return clampf(10.0+population_trace+network_trace+activity_trace+inherited_trace,10.0,320.0)


func _foreign_scout_direct_contact_radius(day:int)->float:
	# Dense settlement networks put more inhabitants, farms, and routine traffic
	# beyond the central marker, but direct contact remains much tighter than the
	# radius at which indirect traces can be noticed.
	return clampf(8.0+_player_settlement_signal_radius(day)*0.20,10.0,58.0)


func _foreign_scout_operational_range(civ:Dictionary)->float:
	var reach:=clampf(float(civ.get("world_reach",0.0)),0.0,1.0)
	var population_scale:=clampf(log(maxf(10.0,float(civ.get("population",10.0))))/log(1_000_000_000.0),0.16,1.0)
	var logistics:=clampf(float(civ.get("logistics",0.10)),0.0,1.0)
	var knowledge:=clampf(float(civ.get("knowledge",0.10)),0.0,1.0)
	var institutional_support:=0.58+population_scale*0.20+logistics*0.14+knowledge*0.08
	return clampf(FOREIGN_SCOUT_MIN_RANGE_KM+pow(reach,0.82)*CIVILIZATION_WORLD_RADIUS_X_KM*institutional_support,FOREIGN_SCOUT_MIN_RANGE_KM,FOREIGN_SCOUT_MAX_RANGE_KM)


func _foreign_information_reach_km(civ:Dictionary)->float:
	# Hearsay can move through several human relays, so its frontier is somewhat
	# broader than one field party's safe radius, but it still advances only as
	# logistics, population, diplomacy, and accumulated world reach allow.
	var diplomacy:=clampf(float(civ.get("diplomacy",0.20)),0.0,1.0)
	var institutions:=clampf(float(civ.get("institutions",0.15)),0.0,1.0)
	return _foreign_scout_operational_range(civ)*(0.88+diplomacy*0.26+institutions*0.12)


func _foreign_scout_speed_km_per_day(civ:Dictionary)->float:
	var logistics:=clampf(float(civ.get("logistics",0.10)),0.0,1.0)
	var knowledge:=clampf(float(civ.get("knowledge",0.10)),0.0,1.0)
	var reach:=clampf(float(civ.get("world_reach",0.0)),0.0,1.0)
	return lerpf(16.0,32.0,clampf(logistics*0.46+knowledge*0.24+reach*0.30,0.0,1.0))


func _foreign_scout_exploration_target(civ:Dictionary,sequence:int,max_range:float)->Vector2:
	var home:=_civilization_world_position(civ)
	var phase:=fposmod(float(abs(String(civ.get("id","civ")).hash()))*0.000000119,TAU)
	var bearing:=phase+float(sequence)*FOREIGN_SCOUT_GOLDEN_ANGLE
	# Two incommensurate progressions distribute successive bearings and depths
	# over the reachable frontier without storing an unbounded explored-tile map.
	var depth:=0.62+0.38*fposmod(float(sequence+1)*0.61803398875,1.0)
	return _bounded_world_point(home+Vector2.from_angle(bearing)*max_range*depth)


func _foreign_scout_investigation_target(civ:Dictionary,relation:Dictionary,sequence:int,max_range:float)->Vector2:
	var home:=_civilization_world_position(civ)
	var center:=_relation_trace_center(relation)
	if not is_finite(center.x) or not is_finite(center.y): return _foreign_scout_exploration_target(civ,sequence,max_range)
	var uncertainty:=clampf(float(relation.get("rival_player_trace_radius_km",240.0)),8.0,2800.0)
	var angle:=float(sequence)*FOREIGN_SCOUT_GOLDEN_ANGLE+fposmod(float(abs(String(civ.get("id","civ")).hash()))*0.000000173,TAU)
	var radial_fraction:=sqrt(fposmod(float(sequence+1)*0.754877666,1.0))
	var target:=center+Vector2.from_angle(angle)*uncertainty*radial_fraction
	var outward:=target-home
	if outward.length()>max_range: target=home+outward.normalized()*max_range
	return _bounded_world_point(target)


func _schedule_foreign_scout_mission(formation:Dictionary,civ:Dictionary,depart_day:int,force_exploration:bool=false)->Dictionary:
	var result:=formation.duplicate(true)
	result.erase("city_observations")
	for key in ["route","rumor_lead_id","rumor_subject","rumor_waiting","rumor_provisions","rumor_personnel"]: result.erase(key)
	var relation:=_relation_with_strategy_defaults(civ.get("player_relation",{}),civ)
	var sequence:=maxi(-1,int(result.get("search_sequence",-1)))+1
	var max_range:=_foreign_scout_operational_range(civ)
	var trace_center:=_relation_trace_center(relation)
	var has_trace:=not force_exploration and float(relation.get("rival_player_trace_confidence",0.0))>0.0 and is_finite(trace_center.x) and is_finite(trace_center.y)
	var target:Vector2
	if has_trace:
		target=_foreign_scout_investigation_target(civ,relation,sequence,max_range)
	else:
		target=_foreign_scout_exploration_target(civ,sequence,max_range)
	var home:=_civilization_world_position(civ)
	var route_distance:=maxf(1.0,home.distance_to(target))
	result["point_a"]=home
	result["point_b"]=target
	result["depart_day"]=maxi(0,depart_day)
	result["leg_days"]=clampf(route_distance/_foreign_scout_speed_km_per_day(civ),8.0,1800.0)
	result["last_report_cycle"]=0
	result["search_sequence"]=sequence
	rumor_network.prepare(result,String(civ.id),depart_day)
	if not force_exploration: rumor_network.ai_plan(result,civ,depart_day)
	return result


func _set_foreign_player_trace(relation:Dictionary,center:Vector2,uncertainty_km:float,confidence:float,day:int,source:String)->Dictionary:
	var result:=_relation_with_strategy_defaults(relation)
	var previous_confidence:=float(result.get("rival_player_trace_confidence",0.0))
	var previous_radius:=float(result.get("rival_player_trace_radius_km",0.0))
	if confidence+0.0001<previous_confidence: return result
	result["rival_player_trace_confidence"]=clampf(maxf(previous_confidence,confidence),0.0,1.0)
	result["rival_player_trace_center"]={"x":center.x,"z":center.y}
	result["rival_player_trace_radius_km"]=maxf(1.0,minf(uncertainty_km,previous_radius) if previous_radius>0.0 else uncertainty_km)
	result["rival_player_trace_day"]=day
	result["rival_player_trace_source"]=source
	return result


func _process_foreign_player_rumors(day:int)->void:
	## This is the off-map human network: travelers, displaced people, exchanged
	## stories, and copied route knowledge. It can create a coarse search lead only
	## after a polity's physically attainable information frontier reaches the
	## player's region. It never creates diplomatic contact or an exact location.
	if not GameState.settlement_site_committed: return
	var settlement_signal:=_player_settlement_signal_radius(day)
	for index in civilizations.size():
		var civ:Dictionary=civilizations[index]
		if not bool(civ.get("alive",true)): continue
		var relation:=_relation_with_strategy_defaults(civ.get("player_relation",{}),civ)
		if int(relation.get("rival_contact_level",0))>=2 or float(relation.get("rival_player_trace_confidence",0.0))>0.0: continue
		var home:=_civilization_world_position(civ)
		var distance:=home.distance_to(player_world_origin)
		var information_reach:=_foreign_information_reach_km(civ)
		if information_reach<distance: continue
		var overlap:=clampf((information_reach-distance)/maxf(1.0,distance),0.0,1.0)
		var network_quality:=clampf(float(civ.get("diplomacy",0.2))*0.38+float(civ.get("logistics",0.1))*0.34+float(civ.get("institutions",0.1))*0.28,0.0,1.0)
		var monthly_chance:=clampf(0.002+overlap*0.024+network_quality*0.012+settlement_signal/320.0*0.008,0.0,0.055)
		var rng:=RandomNumberGenerator.new()
		rng.seed=last_world_seed^day*86028121^String(civ.get("id","civ")).hash()
		if rng.randf()>=monthly_chance: continue
		var uncertainty:=clampf(distance*lerpf(0.36,0.12,network_quality),160.0,2800.0)
		var error_bearing:=rng.randf_range(-PI,PI)
		var reported_center:=_bounded_world_point(player_world_origin+Vector2.from_angle(error_bearing)*uncertainty*rng.randf_range(0.32,0.88))
		relation=_set_foreign_player_trace(relation,reported_center,uncertainty,0.06+network_quality*0.18,day,"traveler rumor")
		var lead:=rumor_network.observation(String(civ.id),"player","the reported people",reported_center,uncertainty,day,"traveler account at the information frontier")
		lead.confidence=0.06+network_quality*.18; lead.heard_position=rumor_network.point(home)
		rumor_network.receive(String(civ.id),lead,day)
		relation["rival_contact_level"]=maxi(1,int(relation.get("rival_contact_level",0)))
		relation["rival_player_intelligence"]=maxf(float(relation.get("rival_player_intelligence",0.0)),0.015+network_quality*0.025)
		civ["player_relation"]=relation
		civilizations[index]=civ


func _foreign_formation_position(formation:Dictionary,day:float)->Vector2:
	var a:=Vector2(formation.get("point_a",Vector2.ZERO)); var b:=Vector2(formation.get("point_b",a))
	var leg:=maxf(1.0,float(formation.get("leg_days",90.0)))
	var cycle:=fposmod(maxf(0.0,day-float(formation.get("depart_day",0))),leg*2.0)
	var progress:=cycle/leg
	if progress>1.0: progress=2.0-progress
	if not formation.get("route",[]).is_empty(): return city_intelligence.route_position(formation.route,clampf(progress,0.0,1.0))
	return a.lerp(b,clampf(progress,0.0,1.0))


func _formation_route_distance_to(formation:Dictionary,point:Vector2)->float:
	if not formation.get("route",[]).is_empty(): return _route_distance_to_point(formation.route,point)
	var a:=Vector2(formation.get("point_a",Vector2.ZERO))
	var b:=Vector2(formation.get("point_b",a))
	return point.distance_to(Geometry2D.get_closest_point_to_segment(point,a,b))


func _foreign_scout_is_active(formation:Dictionary,day:int)->bool:
	return String(formation.get("kind",""))=="scout" and day>=int(formation.get("depart_day",0)) and day>=int(formation.get("disabled_until_day",0))


func _foreign_scout_detected(formation:Dictionary,position:Vector2,day:int,radius:float)->bool:
	if not _foreign_scout_is_active(formation,day) or day<int(formation.get("evaded_until_day",0)): return false
	if _nearby_player_army(position,12.0): return true
	var distance:=position.distance_to(player_world_origin)
	# Concealment helps a scout cross watched country; it cannot hide a physical
	# encounter with the settlement's inhabitants and routine local traffic.
	if distance<=_foreign_scout_direct_contact_radius(day): return true
	var concealment:=clampf(float(formation.get("concealment",0.80)),0.0,1.0)
	var effective_radius:=radius*lerpf(0.82,0.46,concealment)
	if distance>effective_radius: return false
	if distance<=radius*0.12: return true
	var security:=clampf(float(GameState.simulation_metrics.get("security",0.38)),0.0,1.0)
	var proximity:=1.0-distance/maxf(1.0,effective_radius)
	var detection_chance:=clampf(0.08+security*0.34+proximity*0.38-concealment*0.25,0.05,0.58)
	var rng:=RandomNumberGenerator.new()
	rng.seed=last_world_seed^day*32452843^String(formation.get("id","")).hash()
	return rng.randf()<detection_chance


func _nearby_player_army(position:Vector2,radius:float)->bool:
	for army in MilitaryCampaign.field_armies:
		if int(army.get("troops",0))<=0: continue
		var point:Dictionary=army.get("position",{})
		if position.distance_to(Vector2(float(point.get("x",0.0)),float(point.get("z",0.0))))<=radius: return true
	return false


func _foreign_scout_interception_chances(formation:Dictionary,position:Vector2)->Dictionary:
	var radius:=_local_observation_radius()
	var distance:=position.distance_to(player_world_origin)
	var proximity:=clampf(1.0-distance/maxf(1.0,radius),0.0,1.0)
	var security:=clampf(float(GameState.simulation_metrics.get("security",0.38)),0.0,1.0)
	var logistics:=clampf(float(GameState.simulation_metrics.get("logistics",0.16)),0.0,1.0)
	var evasion:=clampf(float(formation.get("evasion",0.86)),0.0,1.0)
	var pursuit:=clampf(0.07+security*0.24+logistics*0.12+proximity*0.20-evasion*0.20,0.04,0.48)
	return {"capture":clampf(pursuit*0.68,0.03,0.32),"destroy":clampf(pursuit*0.92,0.04,0.44),"evasion":evasion,"concealment":clampf(float(formation.get("concealment",0.80)),0.0,1.0)}


func _process_foreign_scout_reports(day:int)->void:
	for formation_index in foreign_formations.size():
		var formation:Dictionary=foreign_formations[formation_index]
		if String(formation.get("kind",""))!="scout" or day<int(formation.get("depart_day",0)) or day<int(formation.get("disabled_until_day",0)): continue
		var leg:=maxf(1.0,float(formation.get("leg_days",30.0)))
		var completed_cycles:=maxi(0,floori((float(day)-float(formation.get("depart_day",0)))/(leg*2.0)))
		var previous_cycles:=maxi(0,int(formation.get("last_report_cycle",0)))
		if completed_cycles<=previous_cycles: continue
		var civ_index:=_civilization_index(String(formation.get("civ_id","")))
		if civ_index>=0:
			var civ:Dictionary=civilizations[civ_index]
			# Nothing learned along the outward leg changes the home polity until the
			# party physically completes its return. At that point its actual route is
			# assessed, then a new mission is chosen from the updated evidence.
			if bool(formation.get("rumor_waiting",false)):
				foreign_formations[formation_index]=_schedule_foreign_scout_mission(formation,civ,day)
				continue
			civ["knowledge"]=clampf(float(civ.get("knowledge",0.0))+0.0025,0.0,1.0)
			var city_reports:Array[Dictionary]=city_intelligence.deliver(formation,String(civ.id),day)
			rumor_network.deliver(formation,String(civ.id),day)
			rumor_network.record_cities(String(civ.id),city_reports,day)
			if formation.has("rumor_lead_id"):
				var found:=false
				for city:Dictionary in city_reports:
					if String(city.get("civ_id",""))==String(formation.get("rumor_subject","")): found=true
				rumor_network.finish_search(formation,String(civ.id),day,found)
			var relation:=_relation_with_strategy_defaults(civ.player_relation,civ)
			var route_distance:=_formation_route_distance_to(formation,player_world_origin)
			var signal_radius:=_player_settlement_signal_radius(day)
			var direct_radius:=_foreign_scout_direct_contact_radius(day)
			if GameState.settlement_site_committed and route_distance<=direct_radius:
				relation=_set_foreign_player_trace(relation,player_world_origin,maxf(6.0,direct_radius*0.55),0.94,day,"returned direct encounter")
				relation["rival_contact_level"]=2
				relation["rival_player_intelligence"]=clampf(float(relation.get("rival_player_intelligence",0.0))+0.075+float(civ.get("knowledge",0.0))*0.025,0.0,0.95)
				if int(relation.get("rival_met_day",-1))<0: relation["rival_met_day"]=day
			elif GameState.settlement_site_committed and route_distance<=signal_radius:
				var evidence_quality:=clampf(1.0-route_distance/maxf(1.0,signal_radius),0.0,1.0)
				var uncertainty:=clampf(maxf(18.0,route_distance*1.15),18.0,maxf(24.0,signal_radius*0.90))
				var rng:=RandomNumberGenerator.new(); rng.seed=last_world_seed^day*32452843^String(formation.get("id","")).hash()
				var inferred_center:=_bounded_world_point(player_world_origin+Vector2.from_angle(rng.randf_range(-PI,PI))*uncertainty*rng.randf_range(0.12,0.55))
				relation=_set_foreign_player_trace(relation,inferred_center,uncertainty,0.38+evidence_quality*0.30,day,"returned physical traces")
				relation["rival_contact_level"]=maxi(1,int(relation.get("rival_contact_level",0)))
				relation["rival_player_intelligence"]=clampf(float(relation.get("rival_player_intelligence",0.0))+0.025+evidence_quality*0.035,0.0,0.90)
			civ["player_relation"]=relation
			civilizations[civ_index]=civ
			formation=_schedule_foreign_scout_mission(formation,civ,day)
		foreign_formations[formation_index]=formation


func _local_observation_radius()->float:
	var radius:=28.0
	if MilitaryCampaign!=null and MilitaryCampaign.has_method("settlement_defense_snapshot"):
		radius=float(MilitaryCampaign.settlement_defense_snapshot().get("observation_radius_km",radius))
	var security:=clampf(float(GameState.simulation_metrics.get("security",0.38)),0.0,1.0)
	return clampf(radius+security*10.0,24.0,110.0)


func _formation_sighting_index(formation_id:String)->int:
	for index in foreign_sightings.size():
		if String(foreign_sightings[index].get("formation_id",""))==formation_id: return index
	return -1


func _set_contact_provenance(relation:Dictionary,day:int,source:String,position:Vector2,formation_kind:String="",formation_id:String="")->Dictionary:
	var result:=relation.duplicate(true)
	# First contact is a historical fact. Later diplomacy may improve knowledge,
	# but it must never erase how or where the two civilizations first met.
	if String(result.get("contact_source",""))!="": return result
	result["contact_source"]=source
	result["contact_formation_kind"]=formation_kind
	result["contact_formation_id"]=formation_id
	result["encounter_position"]={"x":position.x,"z":position.y}
	if int(result.get("met_day",-1))<0: result["met_day"]=day
	return result


func _publish_observed_event(title:String,description:String,day:int,metadata:Dictionary)->void:
	var event_metadata:=metadata.duplicate(true)
	event_metadata["severity"]="major" if String(event_metadata.get("kind",""))=="first_contact" else "notice"
	_record_world_event(title,description,"diplomacy",day,event_metadata)
	var player_event:Dictionary={"id":"foreign_observation_%d_%s" % [day,String(event_metadata.get("formation_id",event_metadata.get("civ_id","unknown")))],"day":day,"title":title,"description":description,"domain":"diplomacy","severity":String(event_metadata.severity)}
	player_event.merge(event_metadata,true)
	GameState.simulation_events.push_front(player_event)
	if GameState.simulation_events.size()>80: GameState.simulation_events.resize(80)


func _process_local_observation(day:int,force:bool=false)->void:
	if not force and day==last_observation_day: return
	last_observation_day=day
	city_intelligence.observe_near_player(day)
	var radius:=_local_observation_radius()
	var visible_ids:Dictionary={}
	var changed:=false
	for formation in foreign_formations:
		if day<int(formation.get("disabled_until_day",0)): continue
		var position:=_foreign_formation_position(formation,float(day))
		var distance:=position.distance_to(player_world_origin)
		if distance>radius and not _nearby_player_army(position,12.0): continue
		var is_scout:=String(formation.get("kind",""))=="scout"
		if is_scout and not _foreign_scout_detected(formation,position,day,radius): continue
		var formation_id:=String(formation.id); var civ_id:=String(formation.civ_id)
		visible_ids[formation_id]=true
		var civ_index:=_civilization_index(civ_id)
		if civ_index<0: continue
		var civ:Dictionary=civilizations[civ_index]
		var relation:=_relation_with_strategy_defaults(civ.player_relation,civ)
		var previous_contact:=int(relation.contact_level)
		var direct_contact_radius:=_foreign_scout_direct_contact_radius(day) if is_scout else 8.0
		relation["contact_level"]=maxi(previous_contact,2 if distance<=direct_contact_radius else 1)
		relation["contact_intelligence"]=maxf(float(relation.contact_intelligence),0.18 if distance<=direct_contact_radius else 0.07)
		var direct_contact_began:=previous_contact<2 and int(relation.contact_level)>=2
		if direct_contact_began or (int(relation.contact_level)>=2 and String(relation.get("contact_source",""))==""):
			relation=_set_contact_provenance(relation,day,"local_formation",position,String(formation.get("kind","formation")),formation_id)
		if int(relation.contact_level)>=2:
			if int(relation.met_day)<0: relation["met_day"]=day
			# A foreign scout carries its observation physically. Its home polity
			# learns nothing from this encounter unless that scout returns.
			if String(formation.get("kind",""))!="scout":
				relation["rival_contact_level"]=maxi(2,int(relation.get("rival_contact_level",0)))
				relation["rival_player_intelligence"]=maxf(0.18,float(relation.get("rival_player_intelligence",0.0)))
				if int(relation.get("rival_met_day",-1))<0: relation["rival_met_day"]=day
		civ["player_relation"]=relation; civilizations[civ_index]=civ
		var strength:=maxf(1.0,float(civ.military_population)*float(formation.get("strength_share",0.08)))
		var sighting_index:=_formation_sighting_index(formation_id)
		var first_sighting:=sighting_index<0 or day-int(foreign_sightings[sighting_index].get("last_seen_day",-9999))>30
		var sighting:={"formation_id":formation_id,"civ_id":civ_id,"kind":String(formation.kind),"last_seen_day":day,"position":{"x":position.x,"z":position.y},"distance_km":distance,"strength":strength,"readiness":float(formation.readiness),"visible":true}
		if String(formation.get("kind",""))=="scout": sighting["interception"]=_foreign_scout_interception_chances(formation,position)
		if sighting_index<0:
			foreign_sightings.push_front(sighting)
			if foreign_sightings.size()>FOREIGN_SIGHTING_LIMIT: foreign_sightings.resize(FOREIGN_SIGHTING_LIMIT)
		else: foreign_sightings[sighting_index]=sighting
		if direct_contact_began:
			var contact_description:="Lookouts make direct contact with a %s of the %s at the marked position, %.0f km away. Their identity is now known; this encounter does not reveal their homeland." % [String(formation.get("kind","formation")).replace("_"," "),String(civ.name),distance]
			_publish_observed_event("First contact — %s" % String(civ.name),contact_description,day,{"kind":"first_contact","civ_id":civ_id,"formation_id":formation_id,"formation_kind":String(formation.get("kind","formation")),"identified":true,"position":{"x":position.x,"z":position.y}})
		elif first_sighting:
			var identified:=int(relation.contact_level)>=2
			var observed_name:=String(civ.name) if identified else "an unidentified aggregate formation"
			var sighting_description:="Lookouts sight %s about %.0f km away at the marked position. This is a local observation, not global tracking." % [observed_name,distance]
			_publish_observed_event("Foreign unit sighted",sighting_description,day,{"kind":"unit_sighting","civ_id":civ_id if identified else "","formation_id":formation_id,"formation_kind":String(formation.get("kind","formation")),"identified":identified,"position":{"x":position.x,"z":position.y}})
		changed=true
	for index in foreign_sightings.size():
		var was_visible:=bool(foreign_sightings[index].get("visible",false))
		var now_visible:=visible_ids.has(String(foreign_sightings[index].formation_id))
		if was_visible!=now_visible: foreign_sightings[index]["visible"]=now_visible; changed=true
	if changed:
		observation_revision+=1
		_rebuild_competition()
		world_changed.emit(known_competition_snapshot())


func _public_formation_sighting(sighting:Dictionary)->Dictionary:
	var civ_index:=_civilization_index(String(sighting.get("civ_id","")))
	var civ:Dictionary=civilizations[civ_index] if civ_index>=0 else {}
	var relation:Dictionary=(civ.get("player_relation",{}) as Dictionary)
	var identified:=int(relation.get("contact_level",0))>=2
	var strength:=maxf(1.0,float(sighting.get("strength",1.0)))
	var confidence:=clampf(float(relation.get("contact_intelligence",0.0)),0.0,1.0)
	var error:=lerpf(0.55,0.16,confidence)
	# Readiness is visible only as an observational range. Better contact narrows
	# the estimate, but the player never receives the rival simulation's exact
	# readiness value through a nearby sighting.
	var readiness:=clampf(float(sighting.get("readiness",0.5)),0.0,1.0)
	var readiness_error:=lerpf(0.32,0.10,confidence)
	var kind:=String(sighting.get("kind","movement"))
	var unidentified_label:="UNIDENTIFIED SCOUT PARTY" if kind=="scout" else "UNIDENTIFIED FOREIGN FORMATION"
	return {"id":String(sighting.get("formation_id","")),"civ_id":String(sighting.get("civ_id","")) if identified else "","label":"%s %s" % [String(civ.get("name","FOREIGN")).to_upper(),kind.to_upper()] if identified else unidentified_label,"civilization":String(civ.get("name","")) if identified else "","kind":kind if identified or kind=="scout" else "movement","identified":identified,"visible":bool(sighting.get("visible",false)),"last_seen_day":int(sighting.get("last_seen_day",0)),"position":sighting.get("position",{}).duplicate(true),"distance_km":float(sighting.get("distance_km",0.0)),"strength_estimate_low":maxi(1,roundi(strength*(1.0-error))),"strength_estimate_high":maxi(1,roundi(strength*(1.0+error))),"readiness_estimate_low":clampf(readiness-readiness_error,0.0,1.0),"readiness_estimate_high":clampf(readiness+readiness_error,0.0,1.0),"hostile":bool(relation.get("at_war",false)),"carries_report":kind=="scout","interception":sighting.get("interception",{}).duplicate(true)}


func local_observation_snapshot()->Dictionary:
	initialize()
	_process_local_observation(int(GameState.elapsed_days))
	var visible:Array[Dictionary]=[]; var recent:Array[Dictionary]=[]
	for sighting in foreign_sightings:
		var public:=_public_formation_sighting(sighting)
		if bool(public.visible): visible.append(public)
		elif int(GameState.elapsed_days)-int(public.last_seen_day)<=90: recent.append(public)
	return {"revision":observation_revision,"radius_km":_local_observation_radius(),"visible":visible,"recent":recent,"visible_count":visible.size(),"bounded_formation_count":foreign_formations.size(),"formation_limit":MAX_FOREIGN_FORMATIONS}


func visible_formation_sighting(formation_id:String)->Dictionary:
	## One public, uncertainty-preserving lookup for map interaction. Callers do
	## not receive the rival's hidden force record merely because its counter is
	## on screen.
	for sighting_variant in local_observation_snapshot().get("visible",[]):
		var sighting:Dictionary=sighting_variant
		if String(sighting.get("id",""))==formation_id:
			return sighting.duplicate(true)
	return {}


func foreign_formation_engagement_data(formation_id:String,fielded_strength:int)->Dictionary:
	## Converts a currently visible aggregate formation into the same bounded
	## incident shape used by campaign combat. Exact rival strength remains
	## backend-only; the map continues to show the public estimate range.
	initialize()
	if fielded_strength<=0: return {"error":"The selected field army has no personnel able to fight."}
	var public_sighting:=visible_formation_sighting(formation_id)
	if public_sighting.is_empty(): return {"error":"Contact has been lost. Reacquire the formation before ordering battle."}
	if bool(public_sighting.get("carries_report",false)): return {"error":"Use the local capture or attack pursuit against a scout party."}
	var formation_index:=_foreign_formation_index(formation_id)
	if formation_index<0: return {"error":"That formation is no longer present."}
	var formation:Dictionary=foreign_formations[formation_index]
	var civ_index:=_civilization_index(String(formation.get("civ_id","")))
	if civ_index<0: return {"error":"The formation's polity record no longer exists."}
	var civ:Dictionary=civilizations[civ_index]
	var relation:Dictionary=_relation_with_strategy_defaults(civ.player_relation,civ)
	var position:Dictionary=public_sighting.get("position",{})
	var strength:=maxi(1,roundi(float(civ.get("military_population",1.0))*float(formation.get("strength_share",0.06))))
	return {
		"id":"field_contact_%s_%d" % [formation_id,int(GameState.elapsed_days)],
		"source_civ_id":String(civ.id),"source_name":String(civ.name),
		"strength":strength,"technology":float(civ.knowledge),
		"readiness":clampf(float(formation.get("readiness",civ.military_readiness)),0.1,1.0),
		"aggression":float(civ.aggression),"created_day":int(GameState.elapsed_days),
		"campaign_mode":"offensive","field_encounter":true,"formation_id":formation_id,
		"target_region_id":"","target_region_name":"the field contact",
		"target_position":position.duplicate(true),"terrain_defense":1.04,
	}


func resolve_foreign_formation_after_battle(formation_id:String,result:Dictionary)->void:
	## The civilization's population losses are resolved by resolve_player_battle;
	## this updates only the bounded roaming formation record so a defeated host
	## does not remain visibly untouched on the same patch of ground.
	var formation_index:=_foreign_formation_index(formation_id)
	if formation_index<0: return
	var formation:Dictionary=foreign_formations[formation_index]
	var home_side:=String(result.get("home_side","attacker"))
	var rival_side:="defender" if home_side=="attacker" else "attacker"
	var rival_result:Dictionary=result.get(rival_side,{})
	var initial:=maxi(1,int(rival_result.get("initial_troops",1)))
	var remaining:=maxi(0,int(rival_result.get("remaining_troops",initial-int(rival_result.get("dead",0)))))
	var remaining_ratio:=clampf(float(remaining)/float(initial),0.0,1.0)
	formation["strength_share"]=maxf(0.002,float(formation.get("strength_share",0.05))*maxf(0.10,remaining_ratio))
	formation["readiness"]=clampf(float(formation.get("readiness",0.5))*lerpf(0.42,0.82,remaining_ratio),0.08,1.0)
	var termination:Dictionary=result.get("termination",{})
	if String(termination.get("type","continued"))!="continued":
		formation["disabled_until_day"]=int(GameState.elapsed_days)+45
	foreign_formations[formation_index]=formation
	_set_sighting_visibility(formation_id,false)
	observation_revision+=1


func contact_source_description(source:String,formation_kind:String="")->String:
	match source:
		"local_formation":
			return "Direct local encounter with a nearby %s" % formation_kind.replace("_"," ")
		"returned_scout_report":
			return "Your scout party encountered them and carried the report home"
		"captured_foreign_scout":
			return "A nearby foreign scout party was captured and identified"
		"reconstructed_scout_report":
			return "Recovered from an older returned scout report"
		"reconstructed_local_sighting":
			return "Recovered from an older local formation sighting"
		_:
			return "The older record does not preserve how contact began"


func contact_encounters_snapshot()->Array[Dictionary]:
	initialize()
	_repair_missing_contact_provenance()
	var encounters:Array[Dictionary]=[]
	for civ in civilizations:
		var relation:Dictionary=_relation_with_strategy_defaults(civ.get("player_relation",{}),civ)
		if int(relation.get("contact_level",0))<2: continue
		var position:Variant=relation.get("encounter_position",{})
		if not position is Dictionary or not position.has("x") or not position.has("z"): continue
		var home_position:Dictionary=relation.get("home_position",{}) if bool(relation.get("home_location_known",false)) else {}
		encounters.append({"civ_id":String(civ.id),"name":String(civ.name),"day":int(relation.get("met_day",-1)),"source":String(relation.get("contact_source","")),"source_description":contact_source_description(String(relation.get("contact_source","")),String(relation.get("contact_formation_kind","formation"))),"formation_kind":String(relation.get("contact_formation_kind","")),"formation_id":String(relation.get("contact_formation_id","")),"position":{"x":float(position.x),"z":float(position.z)},"home_location_known":bool(relation.get("home_location_known",false)),"home_position":home_position.duplicate(true),"home_location_source":String(relation.get("home_location_source","")),"last_observed_day":int(relation.get("last_observed_day",-1))})
	return encounters


func _repair_missing_contact_provenance()->void:
	for civ_index in civilizations.size():
		var civ:Dictionary=civilizations[civ_index]
		var relation:Dictionary=_relation_with_strategy_defaults(civ.get("player_relation",{}),civ)
		if int(relation.get("contact_level",0))<2 or String(relation.get("contact_source",""))!="": continue
		var repaired:=false
		for report_variant in scout_reports:
			var report:Dictionary=report_variant
			if String(civ.name) not in (report.get("contacts",[]) as Array): continue
			var encounter:=_closest_route_encounter(report.get("route",[]) as Array,_civilization_world_position(civ))
			if encounter.position is Vector2 and is_finite(float(encounter.distance)):
				relation=_set_contact_provenance(relation,int(report.get("day",relation.get("met_day",0))),"reconstructed_scout_report",encounter.position,"encountered people","")
				repaired=true
				break
		if not repaired:
			for sighting_variant in foreign_sightings:
				var sighting:Dictionary=sighting_variant
				if String(sighting.get("civ_id",""))!=String(civ.id): continue
				var sighting_position:Dictionary=sighting.get("position",{})
				if not sighting_position.has("x") or not sighting_position.has("z"): continue
				relation=_set_contact_provenance(relation,int(sighting.get("last_seen_day",relation.get("met_day",0))),"reconstructed_local_sighting",Vector2(float(sighting_position.x),float(sighting_position.z)),String(sighting.get("kind","formation")),String(sighting.get("formation_id","")))
				repaired=true
				break
		if repaired:
			civ["player_relation"]=relation
			civilizations[civ_index]=civ


func _foreign_formation_index(formation_id:String)->int:
	for index in foreign_formations.size():
		if String(foreign_formations[index].get("id",""))==formation_id: return index
	return -1


func _set_sighting_visibility(formation_id:String,visible:bool)->void:
	var sighting_index:=_formation_sighting_index(formation_id)
	if sighting_index>=0: foreign_sightings[sighting_index]["visible"]=visible


func _receive_captured_scout_cohort(civ:Dictionary,formation:Dictionary,count:int,day:int)->void:
	var civ_id:=String(civ.get("id",""))
	var existing:Dictionary=captured_foreign_scouts.get(civ_id,{})
	var a:=Vector2(formation.get("point_a",Vector2.ZERO)); var b:=Vector2(formation.get("point_b",a))
	existing["civ_id"]=civ_id
	existing["source_name"]=String(civ.get("name","FOREIGN POLITY"))
	existing["count"]=maxi(0,int(existing.get("count",0)))+maxi(0,count)
	existing["captured_day"]=day
	existing["information_remaining"]=maxf(float(existing.get("information_remaining",0.0)),1.0)
	existing["interrogations"]=maxi(0,int(existing.get("interrogations",0)))
	existing["last_interrogation_day"]=-9999
	existing["route_a"]={"x":a.x,"z":a.y}
	existing["route_b"]={"x":b.x,"z":b.y}
	captured_foreign_scouts[civ_id]=existing
	if MilitaryCampaign!=null and MilitaryCampaign.has_method("receive_scout_captives"):
		MilitaryCampaign.receive_scout_captives(count)


func _remove_foreign_scout_population(civ:Dictionary,count:int,remove_total_population:bool,remove_military:bool=true)->Dictionary:
	var actual:=mini(maxi(0,count),maxi(0,roundi(float(civ.get("population",1.0)))-1))
	if remove_military: civ["military_population"]=maxf(0.0,float(civ.get("military_population",0.0))-float(actual))
	if not remove_total_population or actual<=0: return civ
	var population_before:=float(civ.get("population",1.0))
	civ["population"]=maxf(1.0,population_before-float(actual))
	civ=_scale_strategic_region_populations(civ,float(civ.population)/maxf(1.0,population_before))
	var combat_weights:={"children":0.02,"youth":1.25,"early_adults":1.90,"established_adults":1.65,"mature_adults":0.95,"elders":0.08}
	civ["cohorts"]=_scaled_cohorts(_remove_weighted_cohort_population(civ.cohorts,float(actual),combat_weights),float(civ.population))
	return civ


func resolve_foreign_scout_interception(formation_id:String,action:String,roll_override:float=-1.0,army_id:int=-1)->Dictionary:
	initialize()
	var normalized:=action.to_lower()
	if normalized not in ["capture","destroy"]: return {"error":"Choose capture or destroy for the interception."}
	var formation_index:=_foreign_formation_index(formation_id)
	if formation_index<0: return {"error":"That scout party is no longer present."}
	var formation:Dictionary=foreign_formations[formation_index]
	if String(formation.get("kind",""))!="scout": return {"error":"Only a detected scout party carries an interceptable report."}
	var day:=int(GameState.elapsed_days)
	var position:=_foreign_formation_position(formation,float(day))
	if not _foreign_scout_detected(formation,position,day,_local_observation_radius()): return {"error":"The scouts have slipped out of reliable observation."}
	if day-int(formation.get("last_interception_day",-9999))<7: return {"error":"No second interception can be organized before the scouts clear the pursuit area."}
	var chances:=_foreign_scout_interception_chances(formation,position)
	var chance:=float(chances.get(normalized,0.0))
	if army_id>=0:
		var army_index:=MilitaryCampaign._field_army_index(army_id)
		if army_index<0: return {"error":"The pursuing army is no longer available."}
		var pursuer:Dictionary=MilitaryCampaign.field_armies[army_index]
		var point:Dictionary=pursuer.get("position",{})
		if position.distance_to(Vector2(float(point.get("x",0.0)),float(point.get("z",0.0))))>MilitaryCampaign.MAP_ENGAGEMENT_RANGE_KM:
			return {"error":"The army must reach the scouts before attempting capture."}
		if int(pursuer.get("troops",0))<=0: return {"error":"The pursuing army has no personnel."}
		var scout_pace:=Vector2(formation.get("point_a",Vector2.ZERO)).distance_to(Vector2(formation.get("point_b",Vector2.ZERO)))/maxf(1.0,float(formation.get("leg_days",30.0)))
		var advantage:=MilitaryCampaign._field_army_speed(pursuer)/maxf(8.0,scout_pace)
		chance=clampf(0.30+0.30*(advantage-1.0)+0.20*float(pursuer.get("readiness",0.5))-0.12*float(formation.get("evasion",0.8)),0.08,0.90)
	var rng:=RandomNumberGenerator.new(); rng.seed=last_world_seed^day*49979687^formation_id.hash()^normalized.hash()
	var roll:=roll_override if roll_override>=0.0 else rng.randf()
	formation["last_interception_day"]=day
	if roll>=chance:
		formation["evaded_until_day"]=day+7
		foreign_formations[formation_index]=formation
		_set_sighting_visibility(formation_id,false)
		observation_revision+=1
		var failure_message:="The interception fails. The fast, dispersed scouts break observation and continue carrying their report home."
		_record_world_event("Foreign scouts evade pursuit",failure_message,"diplomacy",day)
		return {"ok":true,"success":false,"action":normalized,"chance":chance,"message":failure_message}
	var civ_index:=_civilization_index(String(formation.get("civ_id","")))
	if civ_index<0: return {"error":"The scouts' polity record no longer exists."}
	var civ:Dictionary=civilizations[civ_index]
	var count:=maxi(1,roundi(float(civ.get("military_population",1.0))*float(formation.get("strength_share",0.01))))
	var relation:=_relation_with_strategy_defaults(civ.player_relation,civ)
	var message:=""
	var direct_contact_began:=false
	if normalized=="capture":
		civ=_remove_foreign_scout_population(civ,count,false)
		direct_contact_began=int(relation.get("contact_level",0))<2
		relation["contact_level"]=2
		relation["contact_intelligence"]=maxf(0.18,float(relation.get("contact_intelligence",0.0)))
		relation["met_day"]=day if int(relation.get("met_day",-1))<0 else int(relation.met_day)
		relation=_set_contact_provenance(relation,day,"captured_foreign_scout",position,"scout",formation_id)
		relation["opinion"]=clampf(float(relation.get("opinion",0.0))-0.05,-1.0,1.0)
		_receive_captured_scout_cohort(civ,formation,count,day)
		message="The pursuit seizes %d foreign scouts and their notes. Their report will not return; the prisoners can now be questioned, coerced, or tortured for information." % count
	else:
		civ=_remove_foreign_scout_population(civ,count,true)
		relation["contact_level"]=maxi(1,int(relation.get("contact_level",0)))
		relation["opinion"]=clampf(float(relation.get("opinion",0.0))-0.16,-1.0,1.0)
		relation["border_tension"]=clampf(float(relation.get("border_tension",0.0))+0.18,0.0,1.0)
		message="The pursuit destroys the %d-person scout party. No report returns, but no captives or route notes survive to provide intelligence." % count
	civ["player_relation"]=relation
	civilizations[civ_index]=civ
	if direct_contact_began:
		var contact_description:="A pursuit captures scouts of the %s at the marked position. Their identity is now known and their carried report is seized; their homeland remains unlocated." % String(civ.name)
		_publish_observed_event("First contact — %s" % String(civ.name),contact_description,day,{"kind":"first_contact","civ_id":String(civ.id),"formation_id":formation_id,"formation_kind":"scout","identified":true,"position":{"x":position.x,"z":position.y}})
	foreign_scout_reports_denied+=1
	# A replacement remains one future aggregate record; no unit list is spawned.
	# It receives only knowledge already held at home; whatever the intercepted
	# party saw on its denied route is gone with that report.
	formation=_schedule_foreign_scout_mission(formation,civ,day+FOREIGN_SCOUT_REPLACEMENT_DAYS)
	formation["disabled_until_day"]=day+FOREIGN_SCOUT_REPLACEMENT_DAYS
	formation["evaded_until_day"]=0
	foreign_formations[formation_index]=formation
	_set_sighting_visibility(formation_id,false)
	observation_revision+=1
	_record_world_event("Foreign scout report denied",message,"diplomacy",day)
	GameState.simulation_events.push_front({"day":day,"title":"SCOUT REPORT DENIED","description":message,"domain":"security","severity":"major"})
	return {"ok":true,"success":true,"action":normalized,"chance":chance,"captives":count if normalized=="capture" else 0,"killed":count if normalized=="destroy" else 0,"report_denied":true,"civilization_id":String(civ.id),"message":message}


func captured_scouts_snapshot()->Array[Dictionary]:
	var result:Array[Dictionary]=[]
	for civ_id in captured_foreign_scouts:
		var cohort:Dictionary=captured_foreign_scouts[civ_id]
		if int(cohort.get("count",0))<=0: continue
		result.append({"civ_id":String(civ_id),"source_name":String(cohort.get("source_name","FOREIGN POLITY")),"count":int(cohort.get("count",0)),"captured_day":int(cohort.get("captured_day",0)),"information_remaining":clampf(float(cohort.get("information_remaining",0.0)),0.0,1.0),"interrogations":int(cohort.get("interrogations",0)),"can_interrogate":int(GameState.elapsed_days)>int(cohort.get("last_interrogation_day",-9999)) and float(cohort.get("information_remaining",0.0))>0.02})
	return result


func _captured_route_point(cohort:Dictionary,key:String)->Vector2:
	var point:Variant=cohort.get(key,{})
	if point is Vector2: return point
	if point is Dictionary: return Vector2(float(point.get("x",0.0)),float(point.get("z",point.get("y",0.0))))
	return Vector2.ZERO


func interrogate_captured_scouts(civ_id:String,method:String,disclosure_roll_override:float=-1.0,truth_roll_override:float=-1.0)->Dictionary:
	initialize()
	var normalized:=method.to_lower()
	if normalized not in ["question","coerce","torture"]: return {"error":"Choose questioning, coercion, or torture."}
	if not captured_foreign_scouts.has(civ_id): return {"error":"No captured scout cohort from that civilization is held."}
	var cohort:Dictionary=captured_foreign_scouts[civ_id]
	var count:=maxi(0,int(cohort.get("count",0)))
	var remaining:=clampf(float(cohort.get("information_remaining",0.0)),0.0,1.0)
	var day:=int(GameState.elapsed_days)
	if count<=0 or remaining<=0.02: return {"error":"This prisoner cohort has no further actionable scouting knowledge."}
	if day<=int(cohort.get("last_interrogation_day",-9999)): return {"error":"This cohort has already been interrogated today."}
	var settings:Dictionary={
		"question":{"disclosure":0.46,"reliability":0.90,"gain_low":0.045,"gain_high":0.095,"consume":0.10,"opinion":-0.005,"legitimacy":0.0,"cohesion":0.0},
		"coerce":{"disclosure":0.64,"reliability":0.70,"gain_low":0.075,"gain_high":0.145,"consume":0.21,"opinion":-0.07,"legitimacy":-0.012,"cohesion":-0.006},
		"torture":{"disclosure":0.78,"reliability":0.42,"gain_low":0.10,"gain_high":0.21,"consume":0.34,"opinion":-0.19,"legitimacy":-0.055,"cohesion":-0.038}
	}[normalized]
	var rng:=RandomNumberGenerator.new(); rng.seed=last_world_seed^day*67867967^civ_id.hash()^normalized.hash()^int(cohort.get("interrogations",0))*86028121
	var disclosure_roll:=disclosure_roll_override if disclosure_roll_override>=0.0 else rng.randf()
	var truth_roll:=truth_roll_override if truth_roll_override>=0.0 else rng.randf()
	var disclosed:=disclosure_roll<float(settings.disclosure)
	var truthful:=disclosed and truth_roll<float(settings.reliability)
	var gain:=rng.randf_range(float(settings.gain_low),float(settings.gain_high))*remaining if truthful else 0.0
	var deaths:=0
	if normalized=="coerce" and count>=8 and rng.randf()<0.18: deaths=1
	elif normalized=="torture": deaths=mini(count,roundi(float(count)*rng.randf_range(0.04,0.16)))
	var civ_index:=_civilization_index(civ_id)
	if civ_index<0: return {"error":"The prisoners' civilization no longer exists."}
	var civ:Dictionary=civilizations[civ_index]
	var relation:=_relation_with_strategy_defaults(civ.player_relation,civ)
	relation["opinion"]=clampf(float(relation.get("opinion",0.0))+float(settings.opinion),-1.0,1.0)
	if normalized in ["coerce","torture"]: relation["border_tension"]=clampf(float(relation.get("border_tension",0.0))+(0.06 if normalized=="coerce" else 0.18),0.0,1.0)
	var finding:=""
	if truthful:
		relation["contact_level"]=2
		relation["contact_intelligence"]=clampf(float(relation.get("contact_intelligence",0.0))+gain,0.0,0.95)
		_add_revealed_area(_captured_route_point(cohort,"route_b"),18.0+gain*90.0,"captured scout testimony")
		finding="The statements corroborate route notes and add %d%% reliable intelligence." % roundi(gain*100.0)
	elif disclosed:
		relation["contact_intelligence"]=maxf(0.0,float(relation.get("contact_intelligence",0.0))-(0.015 if normalized=="coerce" else 0.045))
		finding="The prisoners give claims that conflict with physical evidence. The assessment is contaminated rather than improved."
	else:
		finding="The prisoners disclose nothing that can be corroborated."
	if deaths>0:
		civ=_remove_foreign_scout_population(civ,deaths,true,false)
		cohort["count"]=count-deaths
	civ["player_relation"]=relation
	civilizations[civ_index]=civ
	cohort["information_remaining"]=maxf(0.0,remaining-float(settings.consume))
	cohort["interrogations"]=int(cohort.get("interrogations",0))+1
	cohort["last_interrogation_day"]=day
	captured_foreign_scouts[civ_id]=cohort
	GameState.simulation_metrics["legitimacy"]=clampf(float(GameState.simulation_metrics.get("legitimacy",0.62))+float(settings.legitimacy),0.0,1.0)
	GameState.simulation_metrics["cohesion"]=clampf(float(GameState.simulation_metrics.get("cohesion",0.58))+float(settings.cohesion),0.0,1.0)
	if MilitaryCampaign!=null and MilitaryCampaign.has_method("register_scout_interrogation"):
		MilitaryCampaign.register_scout_interrogation(normalized,deaths)
	var method_label:String=String({"question":"Questioning","coerce":"Coercive interrogation","torture":"Torture"}[normalized])
	var death_text:=" %d prisoners die in custody." % deaths if deaths>0 else ""
	var message:="%s of the captured scouts concludes. %s%s" % [method_label,finding,death_text]
	_record_world_event("Captured scouts interrogated",message,"diplomacy",day)
	GameState.simulation_events.push_front({"day":day,"title":"SCOUT INTERROGATION","description":message,"domain":"security","severity":"major" if normalized=="torture" else "notice"})
	return {"ok":true,"method":normalized,"truthful":truthful,"disclosed":disclosed,"intelligence_gain":gain,"deaths":deaths,"information_remaining":float(cohort.information_remaining),"message":message}


func _resolve_player_scout_interception(mission:Dictionary,day:int,interception_roll_override:float=-1.0,fate_roll_override:float=-1.0)->Dictionary:
	if mission.is_empty(): return {"intercepted":false}
	var hazards:=_player_scout_hazards(mission)
	for hazard_index in hazards.size():
		var hazard:Dictionary=hazards[hazard_index]
		var civ_id:=String(hazard.get("civ_id",""))
		var rng:=RandomNumberGenerator.new(); rng.seed=last_world_seed^day*961748927^civ_id.hash()^hazard_index*15485863^int(mission.get("mission_id",0))*7919
		var interception_roll:=interception_roll_override if interception_roll_override>=0.0 else rng.randf()
		if interception_roll>=float(hazard.get("chance",0.0)): continue
		var aggression:=clampf(float(hazard.get("aggression",0.5)),0.0,1.0)
		var fate_roll:=fate_roll_override if fate_roll_override>=0.0 else rng.randf()
		var capture_threshold:=clampf(0.72-aggression*0.42,0.24,0.64)
		return {"intercepted":true,"fate":"captured" if fate_roll<capture_threshold else "destroyed","civ_id":civ_id,"chance":float(hazard.get("chance",0.0))}
	return {"intercepted":false}


func _fail_player_scout_mission(mission:Dictionary,interception:Dictionary,day:int)->void:
	var personnel:=maxi(0,int(mission.get("personnel",0)))
	var civ_id:=String(interception.get("civ_id",""))
	var fate:=String(interception.get("fate","destroyed"))
	var civ_index:=_civilization_index(civ_id)
	if fate=="captured":
		var cohort:Dictionary=captured_player_scouts.get(civ_id,{"count":0,"captured_day":day})
		cohort["count"]=int(cohort.get("count",0))+personnel
		cohort["captured_day"]=day
		captured_player_scouts[civ_id]=cohort
		if civ_index>=0:
			var civ:Dictionary=civilizations[civ_index]
			var relation:=_relation_with_strategy_defaults(civ.player_relation,civ)
			relation["rival_contact_level"]=2
			relation["rival_player_intelligence"]=clampf(float(relation.get("rival_player_intelligence",0.0))+0.10,0.0,0.95)
			if int(relation.get("rival_met_day",-1))<0: relation["rival_met_day"]=day
			civ["player_relation"]=relation
			civilizations[civ_index]=civ
	else:
		GameState.register_population_deaths(personnel,"Insecurity")
	last_scout_outcome={"mission_id":int(mission.get("mission_id",0)),"day":day,"status":"missing","personnel":personnel,"message":"The scout party fails to return. No map, contact, sighting, or foreign identity reaches the civilization; the entire carried report is lost."}
	var message:=String(last_scout_outcome.message)
	_record_world_event("Scout party overdue",message,"diplomacy",day)
	GameState.simulation_events.push_front({"day":day,"title":"SCOUT PARTY OVERDUE","description":message,"domain":"security","severity":"major"})
	_erase_scout_mission(mission)


func _erase_scout_mission(mission:Dictionary)->void:
	var mission_id:=int(mission.get("mission_id",-1))
	for index in scout_missions.size():
		if int((scout_missions[index] as Dictionary).get("mission_id",-2))==mission_id:
			scout_missions.remove_at(index)
			return


func _closest_route_encounter(route:Array,target:Vector2)->Dictionary:
	var closest_distance:=INF
	var closest_point:=Vector2.INF
	if route.size()==1:
		var only:Dictionary=route[0]
		closest_point=Vector2(float(only.get("x",0.0)),float(only.get("z",0.0)))
		closest_distance=closest_point.distance_to(target)
	for route_index in maxi(0,route.size()-1):
		var a_dict:Dictionary=route[route_index]
		var b_dict:Dictionary=route[route_index+1]
		var a:=Vector2(float(a_dict.get("x",0.0)),float(a_dict.get("z",0.0)))
		var b:=Vector2(float(b_dict.get("x",0.0)),float(b_dict.get("z",0.0)))
		var point:=Geometry2D.get_closest_point_to_segment(target,a,b)
		var distance:=target.distance_to(point)
		if distance<closest_distance:
			closest_distance=distance
			closest_point=point
	return {"distance":closest_distance,"position":closest_point}


func _reverse_scout_route(route:Array)->Array[Dictionary]:
	var reversed:Array[Dictionary]=[]
	for route_index in range(route.size()-1,-1,-1):
		reversed.append((route[route_index] as Dictionary).duplicate(true))
	return reversed


func _complete_scout_mission(mission:Dictionary,day:int)->void:
	var interception:=_resolve_player_scout_interception(mission,day)
	if bool(interception.get("intercepted",false)):
		_fail_player_scout_mission(mission,interception,day)
		return
	var route:Array=mission.get("route",[])
	var city_reports:Array[Dictionary]=city_intelligence.deliver(mission,"player",day)
	var rumor_count:=rumor_network.deliver(mission,"player",day)
	mission["rumor_return_note"]="The party carried home %d new accounts. Their heard locations and uncertain regions are available in Map of Rumors." % rumor_count if rumor_count>0 else ""
	rumor_network.record_cities("player",city_reports,day)
	if mission.has("rumor_lead_id"):
		var found:=false
		for city:Dictionary in city_reports:
			if String(city.get("civ_id",""))==String(mission.get("rumor_subject","")): found=true
		mission["rumor_search_result"]=rumor_network.finish_search(mission,"player",day,found)
	# One aggregate capsule trail follows the physical chart. Do not convert its
	# samples into circles: circle consolidation was what inflated a returned line
	# into an impossible continental reveal.
	_add_revealed_trail(route,18.0,"returned scout trail",day)
	var contacts:Array[String]=[]
	var contact_records:Array[Dictionary]=[]
	for index in civilizations.size():
		var civ:Dictionary=civilizations[index]
		var relation:Dictionary=_relation_with_strategy_defaults(civ.player_relation,civ)
		if int(relation.contact_level)>=2: continue
		var civ_position:=_civilization_world_position(civ)
		var encounter:=_closest_route_encounter(route,civ_position)
		if float(encounter.distance)>58.0 or not encounter.position is Vector2: continue
		var encounter_position:Vector2=encounter.position
		relation["contact_level"]=2
		relation["contact_intelligence"]=maxf(0.20,float(relation.contact_intelligence))
		relation["met_day"]=day
		relation=_set_contact_provenance(relation,day,"returned_scout_report",encounter_position,"encountered people","")
		relation["rival_contact_level"]=2
		relation["rival_player_intelligence"]=maxf(0.20,float(relation.get("rival_player_intelligence",0.0)))
		relation["rival_met_day"]=day
		civ["player_relation"]=relation
		civilizations[index]=civ
		contacts.append(String(civ.name))
		var contact_record:Dictionary={"civ_id":String(civ.id),"name":String(civ.name),"position":{"x":encounter_position.x,"z":encounter_position.y},"source":"returned_scout_report","day":day}
		contact_records.append(contact_record)
		var contact_description:="Returning scouts report direct contact with people of the %s at the marked point on their charted route. This is the encounter site, not a revealed homeland." % String(civ.name)
		_publish_observed_event("First contact — %s" % String(civ.name),contact_description,day,{"kind":"first_contact","civ_id":String(civ.id),"formation_id":"","formation_kind":"returned scout party","identified":true,"position":contact_record.position})
	var targeted_finding:=_resolve_targeted_scout_report(mission,day)
	city_intelligence.seed_known_homes()
	var recruits:=_resolve_scout_recruitment(mission,day)
	var recruitment_account:=_recruitment_return_account(mission,day,recruits)
	var fate:=_resolve_party_fate(mission,day)
	var windfalls:=_resolve_scout_windfalls(mission,route,day)
	if String(mission.get("rumor_return_note",""))!="": windfalls.append(String(mission.rumor_return_note))
	if String(fate.line)!="": windfalls.append(String(fate.line))
	var military_accounts:=_resolve_route_military_sightings(mission,route,day)
	windfalls.append_array(military_accounts)
	for account in military_accounts:
		(mission.discoveries as Array).push_front({"kind":"intelligence","title":"Armed strangers on the road","description":account,"consequence":"A dated sighting has been added to the map. The force may have moved since it was seen."})
	var rumor_line:=_resolve_scout_rumors(day,recruits)
	if rumor_line!="":
		windfalls.append(rumor_line)
		(mission.discoveries as Array).append({"kind":"hearsay","title":"A name beyond the horizon","description":rumor_line,"consequence":"A lead for a future expedition, not confirmed contact or a known homeland."})
	# A recruitment mission receives its own concrete encounter account below;
	# adding the generic nomad line would tell the same story twice.
	var nomad_line:="" if not recruitment_account.is_empty() else _resolve_nomad_sighting(mission,route,day,recruits)
	if nomad_line!="":
		windfalls.append(nomad_line)
		(mission.discoveries as Array).append({"kind":"encounter","title":"Lives beyond our own","description":nomad_line,"consequence":"The encounter site is marked. These people remain independent; no newcomers were added by this sighting."})
	var teaching_line:=_resolve_taught_knowledge(day,recruits,contacts)
	if teaching_line!="":
		windfalls.append(teaching_line)
		(mission.discoveries as Array).push_front({"kind":"knowledge","title":"What strangers taught us","description":teaching_line,"consequence":"Progress was added to the named active investigation. The discovery still completes through ordinary study."})
	var return_route:=_reverse_scout_route(route)
	var report:Dictionary={"mission_id":int(mission.get("mission_id",0)),"day":day,"duration_days":int(mission.duration_days),"personnel":int(mission.personnel),"distance_km":roundi(_scout_route_distance(route)*2.0),"mission_kind":String(mission.get("target_kind","explore")),"target_id":String(mission.get("target_id","open_world")),"target_label":String(mission.get("target_label","OPEN EXPLORATION")),"target_finding":targeted_finding,"recruitment_account":recruitment_account,"contacts":contacts,"contact_records":contact_records,"route":route.duplicate(true),"return_route":return_route,"travel_mode":String(mission.get("travel_mode","land")),"route_status":String(mission.get("route_status","returned")),"turnback_reason":String(mission.get("turnback_reason","")),"new_contact_count":contacts.size(),"recruits":recruits,"returned_personnel":int(fate.returned),"lost_personnel":int(fate.lost),"stayed_personnel":int(fate.stayed),"journal":_compose_scout_journal(mission,route),"windfalls":windfalls.duplicate()}
	report["discoveries"]=(mission.get("discoveries",[]) as Array).duplicate(true)
	report["city_observations"]=city_reports
	report["actual_days"]=maxi(1,day-int(mission.get("start_day",day-int(mission.duration_days))))
	report["start_day"]=int(mission.get("start_day",day-int(mission.duration_days)))
	report["archive_reviewed"]=false
	scout_reports.push_front(report)
	if scout_reports.size()>SCOUT_REPORT_LIMIT: scout_reports.resize(SCOUT_REPORT_LIMIT)
	var finding:=String(recruitment_account.get("summary","")) if not recruitment_account.is_empty() else ("No organized foreign polity was encountered." if contacts.is_empty() else ("Direct contact was established with %s." % ", ".join(contacts)))
	if not recruitment_account.is_empty() and not contacts.is_empty(): finding+=" Direct contact was also established with %s." % ", ".join(contacts)
	if targeted_finding!="": finding+=" "+targeted_finding
	if recruits>0 and recruitment_account.is_empty(): finding+=" The scouts also return with %d wanderers who agreed to join the settlement." % recruits
	for windfall in windfalls: finding+=" "+windfall
	var turnback_note:=String(report.get("turnback_reason",""))
	if turnback_note!="": finding="%s %s" % [turnback_note,finding]
	var is_recruitment:=not recruitment_account.is_empty()
	var party_name:="recruitment party" if is_recruitment else "scout party"
	var message:="The %s returns after %d days and charts roughly %d km of land travel. %s The map now reveals only the physical route contained in its returned report." % [party_name,int(report.duration_days),int(report.distance_km),finding]
	last_scout_outcome={"mission_id":int(mission.get("mission_id",0)),"day":day,"status":"returned","personnel":int(report.personnel),"message":message}
	_record_world_event("Recruitment party returns" if is_recruitment else "Scout party returns",message,"diplomacy",day)
	scout_report_returned.emit(report.duplicate(true))
	GameState.simulation_events.push_front({"day":day,"title":"RECRUITMENT PARTY RETURNS" if is_recruitment else "SCOUTS RETURN","description":message,"domain":"diplomacy","severity":"major"})
	_erase_scout_mission(mission)


func _compose_scout_journal(mission:Dictionary,route:Array)->Array[String]:
	## The journey itself, told from the ground the route actually crossed.
	## Every line derives from the rendered world via the survey authority —
	## nothing is invented that the map does not show.
	var journal:Array[String]=[]
	if not ground_survey_authority.is_valid() or route.size()<3: return journal
	var outbound_days:=maxi(2,int(mission.get("duration_days",30))/2)
	var legs:Array[Dictionary]=[]
	var river_crossings:=0
	var was_at_river:=false
	var highest:=0.0
	var saw_coast:=false
	var farthest_point:=player_world_origin
	var farthest_distance:=0.0
	for waypoint_variant in route:
		var waypoint:Dictionary=waypoint_variant
		var point:=Vector2(float(waypoint.get("x",0.0)),float(waypoint.get("z",0.0)))
		var survey:Dictionary=ground_survey_authority.call(point)
		var label:=String(survey.get("label","unknown country"))
		if legs.is_empty() or String(legs[legs.size()-1].label)!=label:
			legs.append({"label":label,"points":1})
		else:
			legs[legs.size()-1].points=int(legs[legs.size()-1].points)+1
		var at_river:=float(survey.get("river_distance_km",INF))<1.5
		if at_river and not was_at_river: river_crossings+=1
		was_at_river=at_river
		highest=maxf(highest,float(survey.get("height",0.0)))
		if bool(survey.get("coastal",false)): saw_coast=true
		var distance:=player_world_origin.distance_to(point)
		if distance>farthest_distance:
			farthest_distance=distance
			farthest_point=point
	var leg_phrases:Array[String]=[]
	for leg_index in mini(4,legs.size()):
		var leg:Dictionary=legs[leg_index]
		var leg_days:=maxi(1,roundi(float(leg.points)/float(route.size())*float(outbound_days)))
		leg_phrases.append("%d day%s across %s" % [leg_days,"" if leg_days==1 else "s",String(leg.label)])
	if legs.size()>4: leg_phrases.append("mixed country beyond")
	if not leg_phrases.is_empty():
		journal.append("The outward road: %s." % "; then ".join(leg_phrases))
	if river_crossings>0:
		journal.append("They forded running water %s." % ("once" if river_crossings==1 else ("twice" if river_crossings==2 else "%d times" % river_crossings)))
	if highest>6.0: journal.append("The route climbed above the treeline into bare summit country.")
	elif highest>3.2: journal.append("The road climbed through high bare ground.")
	if saw_coast: journal.append("For part of the journey they walked within sight of open water.")
	if farthest_distance>1.0:
		journal.append("At their farthest they stood roughly %d km to the %s of home." % [roundi(farthest_distance),_compass_phrase(player_world_origin,farthest_point)])
	return journal


func _resolve_targeted_scout_report(mission:Dictionary,day:int)->String:
	var kind:=String(mission.get("target_kind","explore"))
	if kind=="investigate_lead": return String(mission.get("rumor_search_result","No confirming observation returned."))
	if kind=="observe_city": return "The party reports only the city observations it physically carried home."
	if kind not in ["investigate_contact","observe_settlement"]: return ""
	if String(mission.get("route_status",""))=="turning_back":
		return String(mission.get("turnback_reason","The land route was blocked, so the party turned back."))
	if not bool(mission.get("reached_target",false)): return "The party could not reach its intended target."
	var civ_id:=String(mission.get("target_civ_id",""))
	var index:=_civilization_index(civ_id)
	if index<0: return "The intended polity could no longer be identified."
	var civ:Dictionary=civilizations[index]
	var relation:=_relation_with_strategy_defaults(civ.get("player_relation",{}),civ)
	var duration:=maxi(1,int(mission.get("duration_days",30)))
	var target_position_data:Dictionary=mission.get("target_position",{})
	var target_position:=Vector2(float(target_position_data.get("x",0.0)),float(target_position_data.get("z",0.0)))
	var result:=""
	if kind=="investigate_contact":
		var home:=_civilization_world_position(civ)
		var search_radius:=58.0+float(duration)*0.42
		relation["contact_intelligence"]=clampf(float(relation.get("contact_intelligence",0.0))+0.035+float(duration)/365.0*0.055,0.0,0.95)
		var home_route:=_plan_scout_land_route(target_position,home) if target_position.distance_to(home)<=search_radius else {}
		if target_position.distance_to(home)<=search_radius and bool(home_route.get("ok",false)):
			relation["home_location_known"]=true
			relation["home_position"]={"x":home.x,"z":home.y}
			relation["home_location_source"]="returned contact investigation"
			relation["last_observed_day"]=day
			_add_revealed_area(home,72.0,"foreign settlement observed")
			result="Tracks and traffic lead to the %s home settlement; its location is now confirmed." % String(civ.name)
		elif target_position.distance_to(home)<=search_radius:
			result="Tracks reach the coast, but no continuous land route to the %s home settlement can be confirmed. Its homeland remains unlocated." % String(civ.name)
		else:
			result="The encounter district is charted, but no defensible route to the %s home settlement is found." % String(civ.name)
	else:
		if not bool(relation.get("home_location_known",false)):
			return "The reported settlement location could not be corroborated."
		relation["contact_intelligence"]=clampf(float(relation.get("contact_intelligence",0.0))+0.065+float(duration)/365.0*0.075,0.0,0.95)
		relation["last_observed_day"]=day
		_add_revealed_area(target_position,86.0,"foreign settlement observation")
		result="The party observes visible population, movement, works, and defenses around the %s settlement." % String(civ.name)
	civ["player_relation"]=relation
	civilizations[index]=civ
	return result


func _resolve_scout_recruitment(mission:Dictionary,day:int)->int:
	var duration:=maxi(1,int(mission.get("duration_days",30)))
	var rng:=RandomNumberGenerator.new()
	rng.seed=last_world_seed^day*32452843^duration*49979687^scout_reports.size()*86028121^String(mission.get("target_id","open_world")).hash()
	var chance:=clampf(0.18+float(duration)/365.0*0.30+(0.05 if String(mission.get("target_kind","explore"))=="explore" else 0.0),0.0,0.55)
	if String(mission.get("target_kind",""))=="recruit_people": chance=clampf(chance+0.24,0.0,0.72)
	if rng.randf()>=chance: return 0
	# Whole families and small bands join, not lone stragglers.
	var maximum:=clampi(3+duration/45,4,12)
	var count:=rng.randi_range(2,maximum)
	# The rare jackpot: an entire band throws in its lot with the party.
	if rng.randf()<0.12: count+=rng.randi_range(10,clampi(14+duration/30,14,26))
	GameState.register_population_arrivals(count,"wanderers recruited by returning scouts")
	return count


func _recruitment_return_account(mission:Dictionary,day:int,recruits:int)->Dictionary:
	## Recruitment is a social mission, not merely exploration with a population
	## roll attached. Preserve the same mechanical result, then explain what the
	## party actually encountered and why the offer did or did not persuade them.
	if String(mission.get("target_kind",""))!="recruit_people": return {}
	var duration:=maxi(1,int(mission.get("duration_days",30)))
	var rng:=RandomNumberGenerator.new()
	rng.seed=last_world_seed^day*49979693^int(mission.get("mission_id",0))*86028157^recruits*104729
	var group_kinds:=PackedStringArray(["traveling households","a foraging band","several related families","a seasonal camp","a small migrant company"])
	var group_kind:=String(group_kinds[rng.randi_range(0,group_kinds.size()-1)])
	var encountered:=0
	var declined:=0
	var disposition:="none_found"
	var reasons:Array[String]=[]
	var summary:=""
	var variants:Array[String]=[]
	if recruits>0:
		declined=rng.randi_range(0,maxi(1,3+duration/90))
		encountered=recruits+declined
		disposition="some_joined" if declined>0 else "all_joined"
		var housing:=float(GameState.simulation_metrics.get("housing_ratio",1.0))
		var food_days:=float(GameState.simulation_metrics.get("food_days",0.0))
		var security:=float(GameState.simulation_metrics.get("security",GameState.society_capacities.get("security",0.4)))
		if housing>=1.08: reasons.append("The promise of room and shelter carried weight.")
		elif food_days>=45.0: reasons.append("The party could point to dependable stores rather than promises alone.")
		elif security>=0.62: reasons.append("The settlement's guarded roads made the offer credible.")
		else: reasons.append("Kin already willing to move trusted the party enough to take the risk.")
		if declined>0: reasons.append("Others would not abandon kin, obligations, or familiar country.")
		variants=[
			"The party found %s. After days of talk, %d chose to return with them%s." % [group_kind,recruits,"; %d declined" % declined if declined>0 else ""],
			"They shared fires with %s and made the settlement's offer plainly. %d accepted%s." % [group_kind,recruits," while %d stayed behind" % declined if declined>0 else ""],
			"Word traveled ahead of the party. Among %s, %d people agreed to uproot themselves and come%s." % [group_kind,recruits,"; %d would not" % declined if declined>0 else ""],
		]
	else:
		var met_people:=rng.randf()<clampf(0.42+float(duration)/365.0*0.28,0.0,0.78)
		if not met_people:
			summary=[
				"The party searched paths, smoke, camps, and old fire sites, but found no people willing to be approached.",
				"They followed signs of passage for days; every camp was cold before they reached it.",
				"The country held tracks and abandoned hearths, but no one remained to hear the settlement's offer.",
			][rng.randi_range(0,2)]
			reasons.append("No offer can persuade people the party never reaches.")
		else:
			encountered=rng.randi_range(2,clampi(5+duration/45,5,16))
			declined=encountered
			disposition="all_declined"
			var housing:=float(GameState.simulation_metrics.get("housing_ratio",1.0))
			var food_days:=float(GameState.simulation_metrics.get("food_days",0.0))
			var security:=float(GameState.simulation_metrics.get("security",GameState.society_capacities.get("security",0.4)))
			if housing<0.92: reasons.append("They asked where they would sleep; the party could promise no secure place.")
			elif food_days<18.0: reasons.append("News of thin stores made relocation look more dangerous than staying.")
			elif security<0.32: reasons.append("They did not believe the road or settlement could protect them.")
			else:
				var social_reasons:=PackedStringArray(["They would not leave kin and familiar country.","They distrusted an offer from strangers.","Their seasonal obligations mattered more than an uncertain new home.","They listened, traded news, and chose their independence."])
				reasons.append(String(social_reasons[rng.randi_range(0,social_reasons.size()-1)]))
			variants=[
				"The party spoke with %s—%d people in all. Every one declined the invitation." % [group_kind,encountered],
				"They found %s and made the settlement's case. All %d chose to remain where they were." % [group_kind,encountered],
				"For several nights the party negotiated with %s. They returned alone; none of the %d people approached would come." % [group_kind,encountered],
			]
			summary=variants[rng.randi_range(0,variants.size()-1)]
	if recruits>0: summary=variants[rng.randi_range(0,variants.size()-1)]
	return {"disposition":disposition,"group":group_kind if encountered>0 else "no settled encounter","encountered":encountered,"joined":recruits,"declined":declined,"summary":summary,"reasons":reasons}


func _resolve_party_fate(mission:Dictionary,day:int)->Dictionary:
	## The gamble of the road. Usually everyone comes home; sometimes the party
	## returns short — dead by misadventure, or alive and settled with people
	## met along the way. The survivors still carry the full report.
	var personnel:=maxi(1,int(mission.get("personnel",1)))
	var rng:=RandomNumberGenerator.new()
	rng.seed=last_world_seed^day*86028157^int(mission.get("mission_id",0))*67867979
	var duration:=maxi(1,int(mission.get("duration_days",30)))
	var hazard:=clampf(0.10+float(duration)/365.0*0.22,0.0,0.34)
	var lost:=0
	var stayed:=0
	if personnel>1 and rng.randf()<hazard:
		lost=mini(rng.randi_range(1,maxi(1,personnel/4)),personnel-1)
		GameState.register_population_deaths(lost,"lost on a scouting expedition")
	if personnel-lost>1 and rng.randf()<hazard*0.8:
		stayed=mini(rng.randi_range(1,maxi(1,personnel/3)),personnel-lost-1)
		GameState.register_population_departures(stayed,"remained with people met on the road")
	var line:=""
	if lost>0 and stayed>0: line="Not all who left came home: %d were lost on the road, and %d chose to remain with people they met." % [lost,stayed]
	elif lost>0: line="Not all who left came home: %d were lost on the road." % lost
	elif stayed>0: line="%d of the party chose to remain with people they met on the road — alive, but no longer ours." % stayed
	return {"lost":lost,"stayed":stayed,"returned":personnel-lost-stayed,"line":line}


const NOMAD_SIGHTING_LIMIT:=12
const NOMAD_SIGHTING_FADE_DAYS:=360


func nomad_sightings_snapshot()->Array[Dictionary]:
	## Only marks fresh enough to still mean anything: nomads move.
	var day:=int(GameState.elapsed_days)
	var visible:Array[Dictionary]=[]
	for sighting_variant in nomad_sightings:
		var sighting:Dictionary=sighting_variant
		if day-int(sighting.get("day",0))<=NOMAD_SIGHTING_FADE_DAYS: visible.append(sighting.duplicate(true))
	return visible


func rumored_civilizations_snapshot()->Array[Dictionary]:
	initialize()
	var rumors:Array[Dictionary]=[]
	for civ in civilizations:
		var relation:Dictionary=civ.get("player_relation",{})
		if int(relation.get("contact_level",0))>=2 or not bool(relation.get("rumored",false)): continue
		rumors.append({"civ_id":String(civ.id),"name":String(civ.name),"day":int(relation.get("rumor_day",0)),"direction":String(relation.get("rumor_direction","an unknown direction")),"distance_hint":String(relation.get("rumor_distance_hint","an unknown distance"))})
	return rumors


func _compass_phrase(from:Vector2,to:Vector2)->String:
	# World coordinates: +x east, +z south (Godot's -z is the map's north).
	var directions:=["east","southeast","south","southwest","west","northwest","north","northeast"]
	return directions[posmod(roundi(rad_to_deg((to-from).angle())/45.0),8)]


func _rumor_distance_hint(distance:float)->String:
	if distance<150.0: return "some days' travel"
	if distance<400.0: return "many days' travel"
	return "a season's journey or more"


func _resolve_scout_rumors(_day:int,_recruits:int)->String:
	# Accounts now come from encountered people and carried reports, not a draw
	# from the private list of all civilizations. Recruitment itself is unchanged.
	return ""


func _resolve_nomad_sighting(mission:Dictionary,route:Array,day:int,recruits:int)->String:
	## A band seen that chose not to join leaves an indicator on the chart,
	## never a contact record.
	if recruits>0 or route.size()<4: return ""
	var rng:=RandomNumberGenerator.new()
	rng.seed=last_world_seed^day*67867967^int(mission.get("mission_id",0))*122949829
	var duration:=maxi(1,int(mission.get("duration_days",30)))
	if rng.randf()>=clampf(0.22+float(duration)/365.0*0.25,0.0,0.55): return ""
	var waypoint:Dictionary=route[rng.randi_range(route.size()/2,route.size()-1)]
	var position:=Vector2(float(waypoint.get("x",0.0)),float(waypoint.get("z",0.0)))
	var band_hint:String=["a family group","a small band","a large traveling band"][rng.randi_range(0,2)]
	nomad_sightings.append({"id":"nomads_%d" % next_nomad_sighting_id,"day":day,"position":{"x":position.x,"z":position.y},"band_hint":band_hint})
	next_nomad_sighting_id+=1
	if nomad_sightings.size()>NOMAD_SIGHTING_LIMIT: nomad_sightings.pop_front()
	_record_world_event("Nomads sighted","The party passed %s of nomads near the marked point. The strangers kept their distance and did not join." % band_hint,"diplomacy",day)
	return "They passed %s of nomads who kept their distance and did not join; the sighting is marked on the chart." % band_hint


func _resolve_taught_knowledge(day:int,recruits:int,contacts:Array)->String:
	## Occasionally the people met on the road teach something: one live
	## investigation leaps forward. Meeting people is required — empty ground
	## teaches through the ordinary evidence channels instead.
	if recruits<=0 and contacts.is_empty(): return ""
	var rng:=RandomNumberGenerator.new()
	rng.seed=last_world_seed^day*179424673^recruits*15487469^scout_reports.size()*32452867
	if rng.randf()>=0.28: return ""
	var active:Array=GameState.active_investigations.values()
	if active.is_empty(): return ""
	var discovery_id:=String(active[rng.randi_range(0,active.size()-1)])
	var definition:Dictionary=DiscoverySystem.discovery_definition(discovery_id)
	if definition.is_empty(): return ""
	var boost:=rng.randf_range(0.08,0.20)
	# Cap below completion so the discovery still lands through the normal
	# daily tick and its established-knowledge event flow.
	GameState.discovery_progress[discovery_id]=clampf(float(GameState.discovery_progress.get(discovery_id,0.0))+boost,0.0,0.99)
	var line_name:=String(definition.get("subcategory","an open question")).to_lower()
	_record_world_event("Taught on the road","People met on the journey showed the party their way of doing things; the inquiry into %s leaps forward." % line_name,"knowledge",day)
	return "Strangers showed them a better way of doing things, and the inquiry into %s leaps forward." % line_name


const SCOUT_FIND_RESOURCES:Array[String]=["Timber","Stone","Fiber Plants","Fertile Soil","Game"]
func scout_one_way_range(duration_days:int)->float:
	## How far a party can range: logistics staffing, established route-speed knowledge from Logistics inquiry, and —
	## transformatively — an adopted mounted-scouting tradition.
	var logistics:=clampf(float(GameState.simulation_metrics.get("logistics",0.16)),0.0,1.0)
	var travel_knowledge:=clampf(DiscoverySystem.effect("route_speed")+ProgressionSystem.effect("route_speed"),0.0,0.60)
	var mount_bonus:=1.0+DiscoverySystem.adoption("mounted_scouts")*0.50
	return float(duration_days)*14.0*(0.72+logistics*0.28)*(1.0+travel_knowledge)*mount_bonus


func _resolve_route_military_sightings(mission:Dictionary,route:Array,day:int)->Array[String]:
	## Early-game field intelligence: a party that crossed near a foreign
	## column reports it on return, through the same sighting pipeline the
	## home lookouts use — dated to the march, not to today.
	var findings:Array[String]=[]
	if route.size()<2: return findings
	for formation_variant in foreign_formations:
		if findings.size()>=2: break
		var formation:Dictionary=formation_variant
		var closest_distance:=INF
		var closest_point:=Vector2.ZERO
		for waypoint_variant in route:
			var waypoint:Dictionary=waypoint_variant
			var point:=Vector2(float(waypoint.get("x",0.0)),float(waypoint.get("z",0.0)))
			var distance:=_formation_route_distance_to(formation,point)
			if distance<closest_distance:
				closest_distance=distance
				closest_point=point
		if closest_distance>45.0: continue
		var formation_id:=String(formation.get("id",""))
		var civ_id:=String(formation.get("civ_id",""))
		var civ_index:=_civilization_index(civ_id)
		if civ_index<0: continue
		var civ:Dictionary=civilizations[civ_index]
		var relation:=_relation_with_strategy_defaults(civ.player_relation,civ)
		var identified:=int(relation.get("contact_level",0))>=2
		relation["contact_level"]=maxi(int(relation.get("contact_level",0)),1)
		relation["contact_intelligence"]=maxf(float(relation.get("contact_intelligence",0.0)),0.08)
		civ["player_relation"]=relation
		civilizations[civ_index]=civ
		var strength:=maxf(1.0,float(civ.get("military_population",0.0))*float(formation.get("strength_share",0.08)))
		var sighting_index:=_formation_sighting_index(formation_id)
		var sighting:={"formation_id":formation_id,"civ_id":civ_id,"kind":String(formation.get("kind","formation")),"last_seen_day":day,"position":{"x":closest_point.x,"z":closest_point.y},"distance_km":player_world_origin.distance_to(closest_point),"strength":strength,"readiness":float(formation.get("readiness",0.5)),"visible":false,"source":"returned_scout_report"}
		if sighting_index<0:
			foreign_sightings.push_front(sighting)
			if foreign_sightings.size()>FOREIGN_SIGHTING_LIMIT: foreign_sightings.resize(FOREIGN_SIGHTING_LIMIT)
		else: foreign_sightings[sighting_index]=sighting
		var observed_name:=String(civ.get("name","an unidentified polity")) if identified else "an unidentified polity"
		var kind_label:=String(formation.get("kind","formation")).replace("_"," ")
		var strength_text:="roughly %d under arms" % roundi(strength) if strength>=5.0 else "of unknown strength"
		var description:="Returning scouts report a %s of %s — %s — moving near the marked point on their charted route. The report is days old; the column has since moved." % [kind_label,observed_name,strength_text]
		_publish_observed_event("Scouts report foreign %s" % kind_label,description,day,{"kind":"unit_sighting","civ_id":civ_id if identified else "","formation_id":formation_id,"formation_kind":kind_label,"identified":identified,"position":sighting.position})
		findings.append("They crossed the trail of a foreign %s (%s) and marked where they saw it." % [kind_label,strength_text])
	if not findings.is_empty():
		observation_revision+=1
	return findings

func _resolve_scout_windfalls(mission:Dictionary,route:Array,day:int)->Array[String]:
	## The concrete wins a returned party can bring home beyond charted ground
	## and contacts: recognized deposits along the route, field evidence for
	## running investigations, and salvage carried back.
	var windfalls:Array[String]=[]
	var duration:=maxi(1,int(mission.get("duration_days",30)))
	mission["discoveries"]=[]
	var rng:=RandomNumberGenerator.new()
	rng.seed=last_world_seed^day*179424673^duration*15485867^int(mission.get("mission_id",0))*982451653
	# 1) Recognized deposits: the party marks workable occurrences on its chart.
	# What they find is what the rendered ground actually is there — timber in
	# visible woodland, stone on bare high ground, fertile soil by the river.
	if route.size()>=4:
		var found_resources:Dictionary={}
		var find_count:=0
		var find_chance:=clampf(0.35+float(duration)/365.0*0.40,0.0,0.80)
		if rng.randf()<find_chance: find_count+=1
		if duration>=180 and rng.randf()<0.45: find_count+=1
		if duration>=180: find_count=maxi(1,find_count)
		for find_index in find_count:
			var waypoint_index:=rng.randi_range(route.size()/3,route.size()-1)
			var waypoint:Dictionary=route[waypoint_index]
			var position:=Vector3(float(waypoint.get("x",0.0))+rng.randf_range(-6.0,6.0),0.0,float(waypoint.get("z",0.0))+rng.randf_range(-6.0,6.0))
			var resource_name:=""
			var ground_note:=""
			var surveyed_ground:Dictionary={}
			if ground_survey_authority.is_valid():
				var ground:Dictionary=ground_survey_authority.call(Vector2(position.x,position.z))
				surveyed_ground=ground
				var ground_label:=String(ground.get("label","the ground"))
				ground_note=" on the %s there" % ground_label
			resource_name=ExpeditionFindings.resource_for(surveyed_ground,day,rng,duration>=180)
			if resource_name.is_empty() or found_resources.has(resource_name): continue
			found_resources[resource_name]=true
			var deposit:Dictionary=ResourceSystem._deposit(resource_name,position,rng.randf_range(0.55,0.95),rng.randf_range(600.0,2400.0),GameState.resource_deposits.size())
			deposit["stage"]="recognized"
			deposit["clues"]=1.0
			deposit["survey"]=0.55
			GameState.resource_deposits.append(deposit)
			var origin_distance:=roundi(player_world_origin.distance_to(Vector2(position.x,position.z)))
			var discovery:=ExpeditionFindings.deposit_card(deposit,origin_distance)
			(mission.discoveries as Array).append(discovery)
			windfalls.append("%s — %s %d km from home%s. %s" % [String(discovery.title),String(discovery.description),origin_distance,ground_note,String(discovery.consequence)])
	# 2) Field evidence: the returned charts and accounts circulate through the
	# collective mind, raising the evidence signals that ongoing inquiry lines
	# actually feed on (the same pathway as daily activity) — not a flat bonus
	# to one lucky project.
	var circulation_days:=clampi(30+duration/3,30,150)
	var strength:=clampf(0.45+float(duration)/365.0*0.35,0.45,0.80)
	var observed_signals:Dictionary={"exploration":strength,"travel":strength*0.85,"survey":strength*0.75,"nature":strength*0.6}
	var signal_summary:="exploration, travel, and natural-cycle"
	match String(mission.get("target_kind","explore")):
		"investigate_contact":
			observed_signals["administration"]=strength*0.6
			observed_signals["information"]=strength*0.6
			signal_summary="route, contact, and organizational"
		"observe_settlement":
			observed_signals["defense"]=strength*0.7
			observed_signals["construction"]=strength*0.5
			observed_signals["administration"]=strength*0.6
			signal_summary="defensive works, construction, and organizational"
	GameState.register_field_observations(observed_signals,day+circulation_days)
	(mission.discoveries as Array).append({"kind":"knowledge","title":"A wider world, carried home","description":"Their route sketches and field observations become material for your people's ongoing investigations.","consequence":"Field evidence for exploration, travel, surveying and nature circulates for %d days." % circulation_days,"duration_days":circulation_days})
	windfalls.append("Their charts and accounts circulate for ~%d days, enriching %s evidence for every inquiry that feeds on it." % [circulation_days,signal_summary])
	# 3) Salvage: hides, cordage fiber, seasoned wood carried home.
	if rng.randf()<0.45:
		var salvage_resource:="Fiber Plants" if rng.randf()<0.5 else "Timber"
		var salvage_amount:=float(3+duration/30)
		GameState.resource_stockpiles[salvage_resource]=float(GameState.resource_stockpiles.get(salvage_resource,0.0))+salvage_amount
		windfalls.append("Supplies brought home: %.0f bulk of %s. These are the party's remaining gathered materials, not the value of the country they charted." % [salvage_amount,ResourceSystem.display_name(salvage_resource).to_lower()])
	return windfalls


func _process_player_contact(day:int)->void:
	# Intelligence grows only after a real meeting. A scout mission reveals nothing
	# in transit; its bounded route and observations become knowledge on return.
	for index in civilizations.size():
		var civ:Dictionary=civilizations[index]
		var relation:Dictionary=_relation_with_strategy_defaults(civ.player_relation,civ)
		if int(relation.contact_level)>=2:
			var access:=0.006+float(civ.diplomacy)*0.003
			if String(relation.get("treaty","none"))=="trade": access+=0.018
			if bool(relation.get("at_war",false)): access+=0.010
			relation["contact_intelligence"]=clampf(float(relation.contact_intelligence)+access,0.0,0.95)
		civ["player_relation"]=relation
		civilizations[index]=civ
	_complete_due_scout_missions(day)


func _choose_strategy(civ:Dictionary)->String:
	var population:=maxf(1.0,float(civ.population))
	var cohorts:Dictionary=civ.cohorts
	var dependent_share:=(float(cohorts.get("children",0.0))+float(cohorts.get("elders",0.0)))/population
	var occupation:=_player_occupation_status(civ)
	if float(civ.food_days)<16.0 or float(civ.food_capacity)<population*0.90: return "sustenance"
	if dependent_share>0.46 and float(civ.food_days)<38.0: return "sustenance"
	# Losing the capital or several strategic regions changes what the rival does;
	# conquest is not merely a score modifier layered over an unchanged AI plan.
	if bool(occupation.capital_occupied) or int(occupation.region_count)>=2: return "fortification"
	if _war_count(civ)>0 or float(civ.military_readiness)<0.34: return "fortification"
	if _external_threat(civ)>0.64: return "fortification"
	var environment:Dictionary=civ.get("environment_profile",{})
	var hazards:Dictionary=environment.get("hazards",{})
	if float(hazards.get("drought",0.0))>0.68 and float(civ.food_days)<54.0: return "sustenance"
	# Founding identity is durable without making the AI rigid. Two turns out of
	# three favor its inherited comparative advantage; crises above always override.
	var focus_strategy:Dictionary={"provision":"sustenance","generations":"growth","inquiry":"inquiry","industry":"commerce","defense":"fortification","exchange":"commerce"}
	var inherited:=String(focus_strategy.get(String(civ.get("founding_focus","")),""))
	var civ_number:=int(String(civ.id).trim_prefix("civ_"))
	if inherited!="" and (turn_index+civ_number)%3!=0: return inherited
	var resources:Dictionary=environment.get("resource_potentials",{})
	if float(environment.get("food_potential",0.5))<0.36 and float(civ.food_days)<72.0: return "sustenance"
	if float(environment.get("construction_potential",0.5))>0.72 and maxf(float(resources.get("Copper Ore",0.0)),float(resources.get("Iron Ore",0.0)))>0.62: return "commerce"
	if float(environment.get("route_potential",0.5))>0.78 and float(civ.diplomacy)>0.44: return "commerce"
	if float(environment.get("food_potential",0.5))<0.30 and float(civ.aggression)>0.48: return "expansion"
	var values:Dictionary=SOCIETAL_VALUES_MODEL.normalize_state(civ.get("societal_values",{})).lived
	# Once immediate survival is secure, a civilization's actual values influence
	# its strategic choices. Values bias action but never override material crises.
	if float(values.get("experimentation",0.5))>0.66 and float(civ.knowledge)<0.72: return "inquiry"
	if float(values.get("openness",0.5))+float(values.get("pluralism",0.5))>1.34 and float(civ.diplomacy)>0.40: return "commerce"
	if float(values.get("centralization",0.5))+float(values.get("hierarchy",0.5))>1.38 and float(civ.aggression)>0.56: return "expansion"
	if float(civ.knowledge)<0.24+float(turn_index)*0.0005: return "inquiry"
	if float(civ.food_capacity)<population*1.06: return "growth"
	if _friendly_relation_count(civ)>=2 and float(civ.diplomacy)>0.48: return "commerce"
	if float(civ.aggression)+float(civ.adaptability)*0.35>0.78: return "expansion"
	return STRATEGIES[(turn_index+int(String(civ.id).trim_prefix("civ_")))%STRATEGIES.size()]


func _external_threat(civ:Dictionary) -> float:
	var highest:=0.0
	var own_power:=_military_power(civ)
	for other in civilizations:
		if String(other.id)==String(civ.id): continue
		var relation:Dictionary=(civ.get("relations",{}) as Dictionary).get(String(other.id),{})
		var power_ratio:=_military_power(other)/maxf(1.0,own_power)
		var pressure:=float(relation.get("border_tension",0.0))*0.50+maxf(0.0,-float(relation.get("opinion",0.0)))*0.20+clampf(power_ratio-0.8,0.0,1.5)*0.20
		if bool(relation.get("at_war",false)): pressure+=0.30
		highest=maxf(highest,pressure)
	var player_relation:Dictionary=civ.get("player_relation",{})
	var player_ratio:=float(city_intelligence.player_estimate(String(civ.id)).power)/maxf(1.0,own_power)
	var player_pressure:=float(player_relation.get("border_tension",0.0))*0.42+clampf(player_ratio-0.8,0.0,1.5)*0.18+(0.30 if bool(player_relation.get("at_war",false)) else 0.0)
	return clampf(maxf(highest,player_pressure),0.0,1.0)


func _allocation_for(strategy:String)->Dictionary:
	var allocation:={"sustenance":0.30,"growth":0.15,"knowledge":0.14,"production":0.16,"military":0.13,"diplomacy":0.12}
	match strategy:
		"sustenance": allocation={"sustenance":0.48,"growth":0.12,"knowledge":0.08,"production":0.14,"military":0.10,"diplomacy":0.08}
		"growth": allocation={"sustenance":0.34,"growth":0.27,"knowledge":0.09,"production":0.14,"military":0.09,"diplomacy":0.07}
		"inquiry": allocation={"sustenance":0.28,"growth":0.12,"knowledge":0.29,"production":0.14,"military":0.08,"diplomacy":0.09}
		"commerce": allocation={"sustenance":0.25,"growth":0.12,"knowledge":0.13,"production":0.21,"military":0.08,"diplomacy":0.21}
		"fortification": allocation={"sustenance":0.28,"growth":0.09,"knowledge":0.09,"production":0.18,"military":0.29,"diplomacy":0.07}
		"expansion": allocation={"sustenance":0.27,"growth":0.14,"knowledge":0.08,"production":0.17,"military":0.25,"diplomacy":0.09}
	return allocation


func _advance_civilization(civ:Dictionary)->Dictionary:
	var population:=maxf(1.0,float(civ.population))
	var allocations:Dictionary=civ.allocations
	var cohorts:Dictionary=civ.cohorts
	var control_effects:=_region_control_effects(civ)
	var working_age:=_working_age_population(cohorts)
	var labor_share:=clampf(working_age/population,0.0,1.0)
	var reproductive_population:=float(cohorts.get("youth",0.0))*0.45+float(cohorts.get("early_adults",0.0))*0.50+float(cohorts.get("established_adults",0.0))*0.45+float(cohorts.get("mature_adults",0.0))*0.16
	var reproductive_factor:=clampf((reproductive_population/population)/0.285,0.45,1.35)
	var siege_access:=MilitaryCampaign.siege_effects_for_civilization(String(civ.id))
	var siege_output:=float(siege_access.food_output_multiplier)
	var food_ratio:=float(civ.food_capacity)/population
	if siege_output<1.0:
		# Existing reserves bridge lost production before starvation affects cohorts.
		food_ratio=minf(food_ratio,food_ratio*siege_output+maxf(0,float(civ.food_days))/30.0)
	var health:=clampf(float(civ.health),0.05,0.98)
	var war_pressure:=clampf(float(_war_count(civ))*0.22,0.0,0.70)
	var environment:Dictionary=civ.get("environment_profile",{})
	if environment.is_empty():
		environment=PlanetEnvironment.profile_at(_civilization_world_position(civ))
		civ["environment_profile"]=environment
		civ["resource_endowment"]=environment.get("resource_potentials",{})
	var environmental_food:=clampf(float(environment.get("food_potential",0.5)),0.0,1.0)
	var environmental_construction:=clampf(float(environment.get("construction_potential",0.5)),0.0,1.0)
	var environmental_routes:=clampf(float(environment.get("route_potential",0.5)),0.0,1.0)
	var environmental_health_pressure:=clampf(float(environment.get("health_pressure",0.25)),0.0,1.0)
	var environmental_resilience:=clampf(float(environment.get("ecological_resilience",0.5)),0.0,1.0)
	var founding_effects:Dictionary=GameState.founding_focus_definition(String(civ.get("founding_focus","provision"))).get("effects",{})
	var progression_conception:=ProgressionSystem.rival_effect(civ,"conception_support")
	var progression_health:=ProgressionSystem.rival_effect(civ,"health_protection")
	var annual_birth_rate:=clampf((0.020+float(allocations.growth)*0.055+maxf(0.0,food_ratio-0.92)*0.018+health*0.008)*reproductive_factor*(1.0+float(founding_effects.get("conception_support",0.0))*0.45+progression_conception),0.004,0.082)
	var annual_death_rate:=clampf((0.010+(1.0-health)*0.030+maxf(0.0,0.92-food_ratio)*0.16+war_pressure*0.018+environmental_health_pressure*0.006)*(1.0-progression_health*0.45),0.006,0.20)
	var births:=population*annual_birth_rate/12.0
	var deaths:=population*annual_death_rate/12.0
	var next_population:=maxf(1.0,population+births-deaths)
	var capacity_change:=population*(0.0015+float(allocations.sustenance)*0.010+float(civ.production)*0.0025)*(0.70+float(civ.ecology)*0.30)*(0.55+labor_share*0.72)*float(control_effects.food_factor)*lerpf(0.62,1.34,environmental_food)*(1.0+float(founding_effects.get("food_yield",0.0))+ProgressionSystem.rival_effect(civ,"food_output"))
	civ["food_capacity"]=maxf(1.0,float(civ.food_capacity)+capacity_change-float(civ.food_capacity)*0.0006)
	var monthly_balance:=float(civ.food_capacity)*float(siege_access.food_output_multiplier)/maxf(1.0,next_population)-1.0
	civ["food_days"]=clampf(float(civ.food_days)+monthly_balance*(30.0 if siege_output<1.0 else 7.5),0.0,180.0)
	civ["health"]=clampf(health+(monthly_balance*0.0025)+(0.0012 if float(civ.food_days)>20.0 else 0.0)-war_pressure*0.0018-environmental_health_pressure*0.00035,0.05,0.98)
	civ["cohesion"]=clampf(float(civ.cohesion)+float(civ.institutions)*0.0012-float(civ.aggression)*war_pressure*0.0018+float(allocations.diplomacy)*0.0010,0.05,0.98)
	civ["knowledge"]=clampf(float(civ.knowledge)+(0.00045+float(allocations.knowledge)*0.0045)*(0.55+float(civ.cohesion)*0.45)*float(control_effects.knowledge_factor)*(1.0+float(founding_effects.get("knowledge_gain",0.0))+ProgressionSystem.rival_effect(civ,"knowledge_rate")),0.02,1.0)
	civ["production"]=clampf(float(civ.production)+(0.00035+float(allocations.production)*0.0038)*(0.55+float(civ.knowledge)*0.45)*float(control_effects.production_factor)*lerpf(0.72,1.24,environmental_construction)*(1.0+float(founding_effects.get("resource_output",0.0))+float(founding_effects.get("material_target",0.0))+ProgressionSystem.rival_effect(civ,"craft_output")),0.02,1.0)
	civ["logistics"]=clampf(float(civ.logistics)+(float(allocations.production)*0.0015+float(allocations.diplomacy)*0.0012)*float(control_effects.logistics_factor)*lerpf(0.72,1.22,environmental_routes)*(1.0+float(founding_effects.get("logistics_target",0.0))+float(founding_effects.get("trade_access",0.0))*0.35+ProgressionSystem.rival_effect(civ,"route_speed")),0.02,1.0)
	civ["institutions"]=clampf(float(civ.institutions)+(float(allocations.diplomacy)*0.0015+float(civ.knowledge)*0.0004)*float(control_effects.institutions_factor)*(1.0+float(founding_effects.get("diplomacy",0.0))*0.5+ProgressionSystem.rival_effect(civ,"state_capacity"))-war_pressure*0.0007,0.02,1.0)
	civ["ecology"]=clampf(float(civ.ecology)+0.00025+(environmental_resilience-float(civ.ecology))*0.00055-float(allocations.growth)*0.0010-maxf(0.0,1.0-food_ratio)*0.0007+float(founding_effects.get("ecology_delta",0.0))*30.0+ProgressionSystem.rival_effect(civ,"ecology_recovery")*0.0015,0.08,1.0)
	var target_military_share:=clampf(0.018+float(allocations.military)*0.30+war_pressure*0.08,0.015,0.38)
	civ["military_share"]=move_toward(float(civ.military_share),target_military_share,0.006)
	var next_cohorts:=_advance_cohorts(cohorts,births,deaths,maxf(0.0,1.0-food_ratio))
	var military_ceiling:=_working_age_population(next_cohorts)*0.55
	civ["military_population"]=minf(military_ceiling,maxf(0.0,float(civ.military_population)*0.985+next_population*float(civ.military_share)*0.015))
	civ=_advance_rival_military_training(civ,allocations,war_pressure)
	civ["territory"]=maxf(0.08,float(civ.territory)+float(allocations.military)*float(allocations.growth)*0.0025*float(control_effects.home_control))
	civ["population"]=next_population
	civ["cohorts"]=_scaled_cohorts(next_cohorts,next_population)
	civ["strategic_regions"]=_advance_strategic_regions(civ,next_population/population)
	civ["births_last_turn"]=births
	civ["deaths_last_turn"]=deaths
	var reach_gain:=(0.00035+float(civ.knowledge)*0.00035+float(civ.logistics)*0.00035+float(allocations.diplomacy)*0.00045)*lerpf(0.72,1.20,environmental_routes)*clampf(log(population+10.0)/log(1_000_000_000.0),0.25,1.25)
	civ["world_reach"]=clampf(float(civ.get("world_reach",0.0))+reach_gain,0.0,1.0)
	civ=ProgressionSystem.advance_rival(civ)
	var organizations:=SOCIETAL_VALUES_MODEL.organizational_discoveries_for_rival(civ)
	civ["societal_values"]=SOCIETAL_VALUES_MODEL.advance(
		civ.get("societal_values",SOCIETAL_VALUES_MODEL.initial_state(String(civ.get("founding_focus","provision")),last_world_seed,String(civ.get("id","rival")))),
		organizations.known,organizations.adoption,
		{"food":clampf(float(civ.food_days)/45.0,0.0,1.0),"health":float(civ.health),"security":float(civ.military_readiness),"ecology":float(civ.ecology),"knowledge":float(civ.knowledge),"trade":clampf(float(civ.trade_total)/maxf(1.0,float(civ.population))*20.0,0.0,1.0),"war_pressure":war_pressure,"inequality":0.34+float(civ.aggression)*0.12,"adaptability":float(civ.adaptability)},
		maxi(0,last_turn_day)
	)
	civ["cohesion"]=clampf(float(civ.cohesion)+SOCIETAL_VALUES_MODEL.simulation_effect(civ.societal_values,"cohesion")*0.025,0.05,0.98)
	civ["institutions"]=clampf(float(civ.institutions)+SOCIETAL_VALUES_MODEL.simulation_effect(civ.societal_values,"institutions")*0.025,0.02,1.0)
	civ["knowledge"]=clampf(float(civ.knowledge)+SOCIETAL_VALUES_MODEL.simulation_effect(civ.societal_values,"knowledge")*0.015,0.02,1.0)
	civ["ecology"]=clampf(float(civ.ecology)+SOCIETAL_VALUES_MODEL.simulation_effect(civ.societal_values,"ecology")*0.012,0.08,1.0)
	civ["military_readiness"]=clampf(float(civ.military_readiness)+SOCIETAL_VALUES_MODEL.simulation_effect(civ.societal_values,"security")*0.012,0.08,1.0)
	return civ


func _advance_rival_military_training(civ:Dictionary,allocations:Dictionary,war_pressure:float)->Dictionary:
	# Rival forces pay the same strategic opportunity costs as the player: a
	# military allocation, food consumed by exercises, production wear, and time.
	# This remains one fixed record per civilization, never an officer or unit list.
	var focus:=_rival_training_focus(civ)
	var military_allocation:=clampf(float(allocations.get("military",0.0)),0.0,1.0)
	var food_coverage:=clampf(float(civ.get("food_days",0.0))/30.0,0.0,1.0)
	var logistics:=clampf(float(civ.get("logistics",0.2)),0.0,1.0)
	var institutions:=clampf(float(civ.get("institutions",0.2)),0.0,1.0)
	var intensity:=clampf(military_allocation*(0.48+food_coverage*0.27+logistics*0.15+institutions*0.10),0.0,0.65)
	var founding_effects:Dictionary=GameState.founding_focus_definition(String(civ.get("founding_focus","provision"))).get("effects",{})
	var tiers:Dictionary=civ.get("progression_tiers",{})
	var era:Dictionary=MILITARY_DEVELOPMENT.era_for_tiers(int(tiers.get("security",0)),int(tiers.get("production",0)),int(tiers.get("logistics",0)),int(tiers.get("institutions",0)))
	var production_lines:=int(era.get("production_lines",1))
	var military_output:=float(civ.get("population",1.0))*military_allocation*float(civ.get("production",0.1))*(0.00035+float(era.get("tier",0))*0.00010)*float(production_lines)
	var replacement_demand:=float(civ.get("military_population",0.0))*(0.0025+war_pressure*0.0035)
	var stockpile:=maxf(0.0,float(civ.get("military_stockpile",0.0))+military_output-replacement_demand)
	var equipment_coverage:=clampf((military_output+stockpile*0.08)/maxf(1.0,replacement_demand+float(civ.get("military_population",0.0))*0.0015),0.0,1.0)
	intensity=clampf(intensity*(1.0+float(founding_effects.get("training_rate",0.0))+ProgressionSystem.rival_effect(civ,"warfare_readiness")),0.0,0.84)
	var profile:Dictionary={
		"camp_drill":{"readiness":0.032,"command":0.010,"food_days":0.20,"wear":0.00020},
		"field_exercise":{"readiness":0.044,"command":0.022,"food_days":0.55,"wear":0.00055},
		"staff_exercise":{"readiness":0.024,"command":0.050,"food_days":0.16,"wear":0.00018},
		"war_games":{"readiness":0.055,"command":0.042,"food_days":0.82,"wear":0.00085}
	}.get(focus,{})
	var readiness_gain:=float(profile.get("readiness",0.0))*intensity
	var command_gain:=float(profile.get("command",0.0))*intensity
	civ["military_readiness"]=clampf(float(civ.get("military_readiness",0.38))+readiness_gain+float(civ.get("production",0.1))*0.0010+equipment_coverage*0.0015-war_pressure*0.002-0.0015,0.08,1.0)
	civ["command_readiness"]=clampf(float(civ.get("command_readiness",0.35))+command_gain-war_pressure*0.0015-0.0008,0.08,1.0)
	civ["food_days"]=maxf(0.0,float(civ.get("food_days",0.0))-float(profile.get("food_days",0.0))*intensity)
	civ["production"]=clampf(float(civ.get("production",0.1))-float(profile.get("wear",0.0))*intensity,0.02,1.0)
	civ["training_focus"]=focus
	civ["training_cycles"]=maxi(0,int(civ.get("training_cycles",0)))+1
	civ["military_era"]=String(era.get("id","founding"))
	civ["military_era_tier"]=int(era.get("tier",0))
	civ["military_production_lines"]=production_lines
	civ["military_stockpile"]=stockpile
	civ["military_replacement_coverage"]=equipment_coverage
	return civ


func _rival_training_focus(civ:Dictionary)->String:
	var strategy:=String(civ.get("strategy","sustenance"))
	var command:=float(civ.get("command_readiness",0.35))
	var knowledge:=float(civ.get("knowledge",0.15))
	var institutions:=float(civ.get("institutions",0.20))
	if _war_count(civ)>0 or strategy=="expansion":
		return "war_games" if knowledge>=0.46 and institutions>=0.38 else "field_exercise"
	if command<0.48 and institutions>=0.30: return "staff_exercise"
	if strategy=="fortification": return "field_exercise"
	return "camp_drill"


func _advance_strategic_regions(civ:Dictionary,population_factor:float)->Array[Dictionary]:
	var advanced:Array[Dictionary]=[]
	var relation:Dictionary=civ.get("player_relation",{})
	for region_variant in civ.get("strategic_regions",[]):
		var region:Dictionary=(region_variant as Dictionary).duplicate(true)
		region["population"]=maxf(0.0,float(region.get("population",0.0))*population_factor)
		var controller:=String(region.get("controller",String(civ.id)))
		if controller=="player":
			region["occupation_turns"]=int(region.get("occupation_turns",0))+1
			var required:=occupation_requirement(civ,region)
			var committed:=0.0
			if MilitaryCampaign!=null and MilitaryCampaign.has_method("occupation_force_for_region"):
				committed=float(MilitaryCampaign.occupation_force_for_region(String(civ.id),String(region.id)).get("troops",0))
			var coverage:=clampf(committed/maxf(1.0,required),0.0,1.5)
			var supply:=clampf(float(GameState.simulation_metrics.get("logistics",0.16))*0.62+float(GameState.society_capacities.get("institutions",0.25))*0.23+minf(0.15,coverage*0.10),0.05,1.0)
			region=OCCUPATION_GOVERNANCE.advance(region,coverage,supply,not bool(relation.get("at_war",false)))
		elif controller!=String(civ.id):
			region["occupation_turns"]=int(region.get("occupation_turns",0))+1
			var controller_index:=_civilization_index(controller)
			var controller_civ:Dictionary=civilizations[controller_index] if controller_index>=0 else {}
			var occupation_capacity:=float(controller_civ.get("military_population",0.0))*float(region.get("strategic_weight",0.1))*0.35
			var required:=occupation_requirement(civ,region)
			var coverage:=clampf(occupation_capacity/maxf(1.0,required),0.0,1.5)
			var supply:=clampf(float(controller_civ.get("logistics",.2))*.6+float(controller_civ.get("institutions",.2))*.4,.05,1)
			region=OCCUPATION_GOVERNANCE.advance(region,coverage,supply,_war_count(controller_civ)==0)
		else:
			region["resistance"]=0.0
			region["integration"]=1.0
			region["occupation_turns"]=0
			if region.has("governance"):
				# Liberation does not erase damaged institutions or inherited harm.
				var local_governance:=OCCUPATION_GOVERNANCE.state(region)
				local_governance.policy="equal_citizenship"
				region.governance=local_governance
				var liberated:=OCCUPATION_GOVERNANCE.advance(region,1.0,float(civ.get("logistics",.2)),true)
				region.governance=liberated.governance
				if bool(region.governance.ruined): region.damage=liberated.damage
		advanced.append(region)
	return advanced


func _scale_strategic_region_populations(civ:Dictionary,population_factor:float)->Dictionary:
	var regions:Array=(civ.get("strategic_regions",[]) as Array).duplicate(true)
	for index in regions.size():
		regions[index]["population"]=maxf(0.0,float(regions[index].get("population",0.0))*clampf(population_factor,0.0,1.0))
	civ["strategic_regions"]=regions
	return civ


func _region_control_effects(civ:Dictionary)->Dictionary:
	var lost_weight:=0.0
	var lost_food:=0.0
	var lost_production:=0.0
	var lost_logistics:=0.0
	var lost_knowledge:=0.0
	var lost_institutions:=0.0
	for region_variant in civ.get("strategic_regions",[]):
		var region:Dictionary=region_variant
		if String(region.get("controller",String(civ.id)))==String(civ.id): continue
		var weight:=float(region.get("strategic_weight",0.0))
		lost_weight+=weight
		match String(region.get("role","")):
			"granary": lost_food+=0.22
			"market": lost_logistics+=0.18
			"works": lost_production+=0.22
			"capital": lost_institutions+=0.25; lost_knowledge+=0.12
			"frontier": lost_logistics+=0.08
	return {
		"home_control":clampf(1.0-lost_weight,0.20,1.0),
		"food_factor":clampf(1.0-lost_food,0.45,1.0),
		"production_factor":clampf(1.0-lost_production,0.45,1.0),
		"logistics_factor":clampf(1.0-lost_logistics,0.45,1.0),
		"knowledge_factor":clampf(1.0-lost_knowledge,0.55,1.0),
		"institutions_factor":clampf(1.0-lost_institutions,0.40,1.0)
	}


func _intercivilization_message_days(first:Dictionary,second:Dictionary,round_trip:bool=true)->int:
	var distance:=_civilization_world_position(first).distance_to(_civilization_world_position(second))
	var logistics:=clampf((float(first.get("logistics",0.16))+float(second.get("logistics",0.16)))*0.5,0.0,1.0)
	var one_way:=maxi(3,ceili(distance/(17.0*(0.75+logistics*0.25))))
	return one_way*(2 if round_trip else 1)


func _process_intercivilization_relations(day:int)->void:
	for first_index in civilizations.size():
		for second_index in range(first_index+1,civilizations.size()):
			var first:Dictionary=civilizations[first_index]
			var second:Dictionary=civilizations[second_index]
			if not bool(first.alive) or not bool(second.alive): continue
			var relation:Dictionary=(first.relations as Dictionary).get(String(second.id),{})
			var rng:=RandomNumberGenerator.new()
			rng.seed=last_world_seed^day*104729^(first_index+1)*8191^(second_index+1)*131071
			var pending_message:=String(relation.get("pending_message",""))
			var pending_due_day:=int(relation.get("pending_message_due_day",-1))
			if pending_message!="" and pending_due_day>=0 and day>=pending_due_day:
				var current_opinion:=float(relation.get("opinion",0.0))
				var current_tension:=float(relation.get("border_tension",0.0))
				match pending_message:
					"trade":
						if not bool(relation.get("at_war",false)) and current_opinion>0.14:
							relation["treaty"]="trade"
					"non_aggression":
						if not bool(relation.get("at_war",false)) and current_opinion>0.08 and current_tension<0.42:
							relation["treaty"]="non_aggression"
					"war":
						if not bool(relation.get("at_war",false)):
							relation["at_war"]=true
							relation["treaty"]="war"
							relation["war_started_day"]=day
							relation["war_id"]=_start_war(String(first.id),String(second.id),"limited","",day,"A physically carried declaration follows escalating border pressure")
							relation["trade"]=0.0
							relation["border_tension"]=maxf(current_tension,0.68)
							_record_world_event("War declaration delivered","A declaration carried between %s and %s opens a state of war." % [String(first.name),String(second.name)],"war",day)
				relation["pending_message"]=""
				relation["pending_message_sent_day"]=-1
				relation["pending_message_due_day"]=-1
			if bool(relation.get("at_war",false)):
				relation["trade"]=0.0
				civilizations[first_index]=first
				civilizations[second_index]=second
				_set_pair_relation(first_index,second_index,relation)
				_resolve_ai_war_turn(first_index,second_index,relation,rng,day)
				continue
			var opinion:=clampf(float(relation.get("opinion",0.0))+rng.randf_range(-0.006,0.006),-1.0,1.0)
			var proximity_distance:=Vector2(first.position).distance_to(Vector2(second.position))
			var trade:=0.0
			var treaty:=String(relation.get("treaty","none"))
			if treaty=="trade" and opinion>0.10 and proximity_distance<1.55:
				trade=minf(float(first.population),float(second.population))*(0.0008+opinion*0.0018)*(0.35+minf(float(first.logistics),float(second.logistics)))
				first["production"]=clampf(float(first.production)+trade/maxf(1.0,float(first.population))*0.004,0.0,1.0)
				second["production"]=clampf(float(second.production)+trade/maxf(1.0,float(second.population))*0.004,0.0,1.0)
				first["trade_total"]=float(first.trade_total)+trade
				second["trade_total"]=float(second.trade_total)+trade
				opinion=clampf(opinion+0.0015, -1.0,1.0)
			var pressure:=clampf(maxf(0.0,float(first.population)/maxf(1.0,float(first.food_capacity))-0.98)*0.30+maxf(0.0,float(second.population)/maxf(1.0,float(second.food_capacity))-0.98)*0.30,0.0,0.50)
			var shared_aggression:=(float(first.aggression)+float(second.aggression))*0.5
			var shared_diplomacy:=(float(first.diplomacy)+float(second.diplomacy))*0.5
			var tension:=clampf(float(relation.get("border_tension",0.0))+pressure*0.025+maxf(0.0,-opinion)*0.006+shared_aggression*0.004-shared_diplomacy*0.002-maxf(0.0,opinion)*0.004,0.0,1.0)
			if treaty=="truce":
				tension=maxf(0.0,tension-0.018)
				if tension<0.18: treaty="none"
			elif treaty in ["trade","non_aggression"] and opinion<0.04:
				treaty="none"
			relation["treaty"]=treaty
			var war_capacity:=_war_count(first)<2 and _war_count(second)<2
			var pact_blocks_war:=treaty in ["non_aggression","truce"]
			pending_message=String(relation.get("pending_message",""))
			if pending_message=="":
				if not pact_blocks_war and war_capacity and opinion<-0.20 and tension>0.48 and shared_aggression+rng.randf()*0.35>0.76:
					relation["pending_message"]="war"
					relation["pending_message_sent_day"]=day
					relation["pending_message_due_day"]=day+_intercivilization_message_days(first,second,false)
				elif treaty=="none" and opinion>0.38 and proximity_distance<1.55:
					relation["pending_message"]="trade"
					relation["pending_message_sent_day"]=day
					relation["pending_message_due_day"]=day+_intercivilization_message_days(first,second,true)
				elif treaty=="none" and opinion>0.18 and tension<0.27:
					relation["pending_message"]="non_aggression"
					relation["pending_message_sent_day"]=day
					relation["pending_message_due_day"]=day+_intercivilization_message_days(first,second,true)
			relation["opinion"]=opinion
			relation["trade"]=trade
			relation["border_tension"]=tension
			civilizations[first_index]=first
			civilizations[second_index]=second
			_set_pair_relation(first_index,second_index,relation)


func _resolve_ai_war_turn(first_index:int,second_index:int,relation:Dictionary,rng:RandomNumberGenerator,day:int)->void:
	var first:Dictionary=civilizations[first_index]
	var second:Dictionary=civilizations[second_index]
	var first_population_before:=float(first.population)
	var second_population_before:=float(second.population)
	var first_power:=_military_power(first)*rng.randf_range(0.82,1.18)
	var second_power:=_military_power(second)*rng.randf_range(0.82,1.18)
	var total_power:=maxf(1.0,first_power+second_power)
	relation=_ensure_relation_war(relation,String(first.id),String(second.id),day,"Ongoing interstate war")
	relation["trade"]=0.0
	var intensity:=rng.randf_range(0.002,0.010)
	var first_total_dead:=minf(float(first.population)*0.035,float(first.population)*intensity*(second_power/total_power))
	var second_total_dead:=minf(float(second.population)*0.035,float(second.population)*intensity*(first_power/total_power))
	var first_military_dead:=minf(float(first.military_population),first_total_dead*0.72)
	var second_military_dead:=minf(float(second.military_population),second_total_dead*0.72)
	var first_civilian_dead:=maxf(0.0,first_total_dead-first_military_dead)
	var second_civilian_dead:=maxf(0.0,second_total_dead-second_military_dead)
	first["population"]=maxf(1.0,float(first.population)-first_total_dead)
	second["population"]=maxf(1.0,float(second.population)-second_total_dead)
	first=_scale_strategic_region_populations(first,float(first.population)/maxf(1.0,first_population_before))
	second=_scale_strategic_region_populations(second,float(second.population)/maxf(1.0,second_population_before))
	first["military_population"]=maxf(0.0,float(first.military_population)-first_military_dead)
	second["military_population"]=maxf(0.0,float(second.military_population)-second_military_dead)
	var combat_weights:={"children":0.08,"youth":1.30,"early_adults":1.85,"established_adults":1.70,"mature_adults":1.05,"elders":0.18}
	first["cohorts"]=_scaled_cohorts(_remove_weighted_cohort_population(first.cohorts,first_total_dead,combat_weights),float(first.population))
	second["cohorts"]=_scaled_cohorts(_remove_weighted_cohort_population(second.cohorts,second_total_dead,combat_weights),float(second.population))
	_record_war_battle(String(relation.war_id),{"day":day,"name":"Campaign of Year %d" % (int(floor(float(day)/365.0))+1),"location":"contested frontier","outcome":"ongoing","losses":{String(first.id):{"military_dead":roundi(first_military_dead),"civilian_dead":roundi(first_civilian_dead),"wounded":roundi(first_military_dead*1.7),"captured":0,"displaced":roundi(first_civilian_dead*3.0)},String(second.id):{"military_dead":roundi(second_military_dead),"civilian_dead":roundi(second_civilian_dead),"wounded":roundi(second_military_dead*1.7),"captured":0,"displaced":roundi(second_civilian_dead*3.0)}}})
	var transfer:=rng.randf_range(0.002,0.012)
	var power_ratio:=maxf(first_power,second_power)/maxf(1.0,minf(first_power,second_power))
	if rng.randf()<clampf(0.035+(power_ratio-1.0)*0.055,0.035,0.16):
		var control_result:=_resolve_ai_region_control(first,second,first_power>second_power,day)
		first=control_result.first
		second=control_result.second
		if not bool(control_result.get("changed",false)):
			if first_power>second_power: first["territory"]=float(first.territory)+transfer; second["territory"]=maxf(0.08,float(second.territory)-transfer)
			else: second["territory"]=float(second.territory)+transfer; first["territory"]=maxf(0.08,float(first.territory)-transfer)
	elif first_power>second_power:
		first["territory"]=float(first.territory)+transfer
		second["territory"]=maxf(0.08,float(second.territory)-transfer)
	else:
		second["territory"]=float(second.territory)+transfer
		first["territory"]=maxf(0.08,float(first.territory)-transfer)
	relation["opinion"]=clampf(float(relation.get("opinion",-0.5))-0.015,-1.0,1.0)
	relation["border_tension"]=clampf(float(relation.get("border_tension",0.7))+0.01,0.0,1.0)
	if rng.randf()<0.035+minf(first_power,second_power)/maxf(first_power,second_power)*0.025:
		relation["at_war"]=false
		relation["treaty"]="truce"
		relation["border_tension"]=0.28
		var winner:=String(first.name) if first_power>second_power else String(second.name)
		if first_power>second_power: first["wars_won"]=int(first.wars_won)+1; second["wars_lost"]=int(second.wars_lost)+1
		else: second["wars_won"]=int(second.wars_won)+1; first["wars_lost"]=int(first.wars_lost)+1
		_end_war(String(relation.get("war_id","")),day,"%s advantage; truce" % winner)
		_record_world_event("Interstate truce","%s gains the advantage before a truce halts the current campaign." % winner,"diplomacy",day)
	civilizations[first_index]=first
	civilizations[second_index]=second
	_set_pair_relation(first_index,second_index,relation)


func _resolve_ai_region_control(first:Dictionary,second:Dictionary,first_won:bool,day:int)->Dictionary:
	var winner:=first if first_won else second
	var loser:=second if first_won else first
	var target_owner:Dictionary=loser
	var target_index:=-1
	var recapture:=false
	# A polity restores its own deepest occupied region before pushing farther
	# into its enemy's ordered strategic front.
	for index in range((winner.get("strategic_regions",[]) as Array).size()-1,-1,-1):
		var candidate:Dictionary=winner.strategic_regions[index]
		if String(candidate.get("controller",String(winner.id)))==String(loser.id): target_index=index; target_owner=winner; recapture=true; break
	if target_index<0:
		for index in (loser.get("strategic_regions",[]) as Array).size():
			var candidate:Dictionary=loser.strategic_regions[index]
			var controller:=String(candidate.get("controller",String(loser.id)))
			if controller==String(winner.id): continue
			if controller==String(loser.id): target_index=index
			# A third power or the player physically controls the next approach.
			# The winner cannot skip through that region and seize cities behind it.
			break
	if target_index<0: return {"first":first,"second":second,"changed":false}
	var regions:Array=(target_owner.get("strategic_regions",[]) as Array).duplicate(true)
	var region:Dictionary=regions[target_index]
	var territory_value:=minf(float(region.get("territory_value",0.01)),maxf(0.0,float(loser.territory)-0.08))
	region["controller"]=String(winner.id)
	region["resistance"]=0.0 if recapture else clampf(0.36+float(target_owner.cohesion)*0.32,0.25,0.86)
	region["integration"]=1.0 if recapture else 0.0
	region["occupation_turns"]=0
	region["damage"]=clampf(float(region.get("damage",0.0))+0.04,0.0,1.0)
	region["last_control_change_day"]=day
	regions[target_index]=region
	target_owner["strategic_regions"]=regions
	winner["territory"]=float(winner.territory)+territory_value
	loser["territory"]=maxf(0.08,float(loser.territory)-territory_value)
	if String(target_owner.id)==String(winner.id): winner=target_owner
	else: loser=target_owner
	var action:="recaptures" if recapture else "captures"
	_record_world_event("Strategic region changes hands","%s %s %s from %s; population remains aggregate while control, territory, and regional capacity change." % [String(winner.name),action,String(region.name),String(loser.name)],"war",day)
	return {"first":winner if first_won else loser,"second":loser if first_won else winner,"changed":true,"region_id":String(region.id),"recapture":recapture}


func _process_player_relations(day:int)->void:
	for index in civilizations.size():
		var civ:Dictionary=civilizations[index]
		var known_player:Dictionary=city_intelligence.player_estimate(String(civ.id))
		var player_power:=float(known_player.power) if float(known_player.power)>0 else _military_power(civ)
		var relation:Dictionary=_relation_with_strategy_defaults(civ.player_relation,civ)
		var opinion:=float(relation.get("opinion",0.0))
		if int(relation.get("contact_level",0))<2:
			relation["trade"]=0.0
			relation["opinion"]=opinion
			civ["player_relation"]=relation
			civilizations[index]=civ
			continue
		if String(relation.get("treaty","none"))=="trade" and not bool(relation.get("at_war",false)):
			var trade:=minf(GameState.population_exact,float(civ.population))*(0.001+maxf(0.0,opinion)*0.002)*(0.4+float(civ.logistics)*0.6)
			relation["trade"]=trade
			civ["trade_total"]=float(civ.trade_total)+trade
			opinion=clampf(opinion+0.002,-1.0,1.0)
		else: relation["trade"]=0.0
		if bool(relation.get("at_war",false)):
			relation=_ensure_relation_war(relation,"player",String(civ.id),day,"Ongoing player war")
			relation["conflict_turns"]=int(relation.get("conflict_turns",0))+1
			var occupied_status:=_player_occupation_status(civ)
			relation["player_war_exhaustion"]=clampf(float(relation.get("player_war_exhaustion",0.0))+0.012+float(occupied_status.region_count)*0.002,0.0,1.0)
			relation["rival_war_exhaustion"]=clampf(float(relation.get("rival_war_exhaustion",0.0))+0.014+float(occupied_status.region_count)*0.008,0.0,1.0)
			relation["border_tension"]=clampf(float(relation.get("border_tension",0.7))+0.018,0.0,1.0)
			opinion=clampf(opinion-0.01,-1.0,1.0)
			_queue_player_incident_if_due(civ,relation,day)
		elif String(relation.get("treaty","none"))!="non_aggression" and day>=int(relation.get("truce_until_day",0)):
			var rival_intelligence:=clampf(float(relation.get("rival_player_intelligence",0.0)),0.0,1.0)
			var strategic_pressure:=(float(civ.aggression)*0.45+maxf(0.0,_military_power(civ)/maxf(1.0,player_power)-1.0)*0.10+maxf(0.0,-opinion)*0.25)*lerpf(0.42,1.0,rival_intelligence)
			if int(relation.get("rival_contact_level",0))>=2 and rival_intelligence>=0.12 and GameState.settlement_site_committed and day>=90 and opinion<-0.34 and strategic_pressure>0.48:
				var rng:=RandomNumberGenerator.new(); rng.seed=last_world_seed^day*524287^(index+1)*4099
				if rng.randf()<clampf(0.06+strategic_pressure*0.16,0.0,0.32):
					relation["at_war"]=true
					relation["treaty"]="war"
					relation["war_goal"]="defend"
					relation["war_target_region_id"]=""
					relation["war_score"]=0.0
					relation["war_started_day"]=day
					relation["war_id"]=_start_war("player",String(civ.id),"defend","",day,"Organized rival invasion")
					relation["conflict_turns"]=0
					relation["trade"]=0.0
					relation["border_tension"]=maxf(0.72,float(relation.get("border_tension",0.0)))
					_record_world_event("A rival opens war","%s begins an organized campaign against the player civilization." % String(civ.name),"war",day)
					_queue_player_incident_if_due(civ,relation,day)
			# Hostile neighbors can also attempt a bounded raid without first opening a
			# conquest war. Contact, intelligence, disposition, distance/logistics, and a
			# long cooldown all constrain this; it is not a random alert generator.
			if not bool(relation.get("at_war",false)):
				_queue_player_raid_if_due(civ,relation,day,index)
		# A paper truce cannot make an unsupported occupation inert. High local
		# resistance can reopen the war as a bounded regional uprising, using the
		# same aggregate recapture campaign rather than spawning citizen agents.
		if not bool(relation.get("at_war",false)):
			relation["player_war_exhaustion"]=maxf(0.0,float(relation.get("player_war_exhaustion",0.0))-0.025)
			relation["rival_war_exhaustion"]=maxf(0.0,float(relation.get("rival_war_exhaustion",0.0))-0.025)
			relation["war_score"]=move_toward(float(relation.get("war_score",0.0)),0.0,5.0)
			relation["conflict_turns"]=0
			var uprising:=_occupation_uprising_pressure(civ)
			if bool(uprising.get("eligible",false)):
				var rng:=RandomNumberGenerator.new()
				rng.seed=last_world_seed^day*15485863^(index+1)*32452843^String(uprising.get("region_id","")).hash()
				if rng.randf()<float(uprising.get("chance",0.0)):
					relation["at_war"]=true
					relation["treaty"]="war"
					relation["stance"]="hostile"
					relation["war_goal"]="defend"
					relation["war_target_region_id"]=String(uprising.get("region_id",""))
					relation["war_score"]=-15.0
					relation["war_started_day"]=day
					relation["war_id"]=_start_war("player",String(civ.id),"defend",String(uprising.get("region_id","")),day,"Occupation uprising")
					relation["trade"]=0.0
					relation["border_tension"]=maxf(0.84,float(relation.get("border_tension",0.0)))
					_record_world_event("Occupation uprising","%s organizes a mass recapture campaign around %s; aggregate resistance became action because the occupation was under-garrisoned." % [String(civ.name),String(uprising.get("region_name","an occupied region"))],"war",day)
					_queue_player_incident_if_due(civ,relation,day)
		relation["opinion"]=opinion
		civ["player_relation"]=relation
		civilizations[index]=civ


func _player_occupation_status(civ:Dictionary)->Dictionary:
	var region_count:=0
	var population:=0.0
	var capital_occupied:=false
	var deepest:=-1
	for region_variant in civ.get("strategic_regions",[]):
		var region:Dictionary=region_variant
		if String(region.get("controller",String(civ.id)))!="player": continue
		region_count+=1
		population+=maxf(0.0,float(region.get("population",0.0)))
		capital_occupied=capital_occupied or String(region.get("role",""))=="capital"
		deepest=maxi(deepest,int(region.get("approach_index",0)))
	return {"region_count":region_count,"population":population,"capital_occupied":capital_occupied,"complete":region_count>=STRATEGIC_REGIONS_PER_CIV,"deepest":deepest}


func _home_control_status(civ:Dictionary)->Dictionary:
	var controlled:=0
	var capital_controlled:=false
	for region_variant in civ.get("strategic_regions",[]):
		var region:Dictionary=region_variant
		if String(region.get("controller",String(civ.id)))!=String(civ.id): continue
		controlled+=1
		capital_controlled=capital_controlled or String(region.get("role",""))=="capital"
	return {"controlled":controlled,"lost":STRATEGIC_REGIONS_PER_CIV-controlled,"capital_controlled":capital_controlled}


func _occupation_uprising_pressure(civ:Dictionary)->Dictionary:
	var selected:Dictionary={}
	var highest_pressure:=0.0
	for region_variant in civ.get("strategic_regions",[]):
		var region:Dictionary=region_variant
		if String(region.get("controller",String(civ.id)))!="player": continue
		if int(region.get("occupation_turns",0))<2: continue
		var force:Dictionary={}
		if MilitaryCampaign!=null and MilitaryCampaign.has_method("occupation_force_for_region"):
			force=MilitaryCampaign.occupation_force_for_region(String(civ.id),String(region.id))
		var required:=occupation_requirement(civ,region)
		var coverage:=clampf(float(force.get("troops",0))/maxf(1.0,required),0.0,1.5)
		var resistance:=float(region.get("resistance",0.0))
		var pressure:=resistance*(1.0-minf(1.0,coverage))*clampf(0.65+float(region.get("damage",0.0))*0.55,0.0,1.2)
		if resistance>=0.55 and coverage<0.72 and pressure>highest_pressure:
			highest_pressure=pressure
			selected={"eligible":true,"region_id":String(region.id),"region_name":String(region.name),"resistance":resistance,"coverage":coverage,"chance":clampf(0.06+maxf(0.0,resistance-0.55)*0.42+(1.0-minf(1.0,coverage))*0.14,0.06,0.32)}
	if selected.is_empty(): return {"eligible":false,"chance":0.0}
	return selected


func _queue_player_incident_if_due(civ:Dictionary,relation:Dictionary,day:int)->void:
	if pending_player_incidents.size()>=INCIDENT_LIMIT: return
	if day-int(relation.get("last_incident_day",-9999))<90: return
	for incident in pending_player_incidents:
		if String(incident.get("source_civ_id",""))==String(civ.id): return
	var known_player:Dictionary=city_intelligence.player_estimate(String(civ.id),true)
	if not bool(known_player.known) and _recapture_target(civ).is_empty(): return
	var projection:=float(civ.military_population)*0.42
	var strength:=maxi(3,roundi(projection*clampf(float(civ.military_readiness),0.25,1.0)))
	var incident_readiness:=clampf(float(civ.military_readiness)*0.82+float(civ.get("command_readiness",0.4))*0.18,0.1,1.0)
	var incident:Dictionary={"id":"campaign_%s_%d" % [String(civ.id),day],"source_civ_id":String(civ.id),"source_name":String(civ.name),"strength":strength,"technology":float(civ.knowledge),"readiness":incident_readiness,"aggression":float(civ.aggression),"created_day":day}
	var recapture_target:=_recapture_target(civ)
	if not recapture_target.is_empty():
		incident["target_region_id"]=String(recapture_target.id)
		incident["target_region_name"]=String(recapture_target.name)
		incident["target_population"]=float(recapture_target.population)
		incident["recapture_campaign"]=true
		incident["terrain_defense"]=clampf(1.02+float(recapture_target.get("fortification",0.2))*(1.0-float(recapture_target.get("damage",0.0))*0.70)*0.30,1.02,1.30)
	pending_player_incidents.append(incident)
	relation["last_incident_day"]=day


func _queue_player_raid_if_due(civ:Dictionary,relation:Dictionary,day:int,civ_index:int)->void:
	if not bool(city_intelligence.player_estimate(String(civ.id),true).known): return
	if pending_player_incidents.size()>=INCIDENT_LIMIT: return
	if day-int(relation.get("last_raid_day",-9999))<180: return
	if int(relation.get("rival_contact_level",0))<2: return
	var intelligence:=clampf(float(relation.get("rival_player_intelligence",0.0)),0.0,1.0)
	if intelligence<0.10: return
	var hostility:=clampf(float(civ.get("aggression",0.0))*0.46+maxf(0.0,-float(relation.get("opinion",0.0)))*0.34+float(relation.get("border_tension",0.0))*0.20,0.0,1.0)
	if hostility<0.30: return
	for queued in pending_player_incidents:
		if String((queued as Dictionary).get("source_civ_id",""))==String(civ.id): return
	var rng:=RandomNumberGenerator.new()
	rng.seed=last_world_seed^day*32452843^(civ_index+1)*49979687
	if rng.randf()>clampf(0.025+hostility*0.085,0.0,0.12): return
	var known_player:Dictionary=city_intelligence.player_estimate(String(civ.id),true)
	if not bool(known_player.known): return
	var projection:=float(civ.military_population)*0.16
	var strength:=maxi(3,roundi(projection*clampf(float(civ.military_readiness),0.25,1.0)))
	pending_player_incidents.append({"id":"raid_%s_%d" % [String(civ.id),day],"incident_kind":"raid","field_encounter":true,"source_civ_id":String(civ.id),"source_name":String(civ.name),"strength":strength,"technology":float(civ.knowledge),"readiness":clampf(float(civ.military_readiness),0.1,1.0),"aggression":float(civ.aggression),"created_day":day})
	relation["last_raid_day"]=day
	relation["border_tension"]=clampf(float(relation.get("border_tension",0.0))+0.08,0.0,1.0)


func _recapture_target(civ:Dictionary)->Dictionary:
	var selected:Dictionary={}
	var deepest:=-1
	for region_variant in civ.get("strategic_regions",[]):
		var region:Dictionary=region_variant
		if String(region.get("controller",String(civ.id)))!="player": continue
		var approach:=int(region.get("approach_index",0))
		if approach>deepest: deepest=approach; selected=region
	return selected.duplicate(true)


func consume_player_incident()->Dictionary:
	initialize()
	while not pending_player_incidents.is_empty():
		var incident:Dictionary=pending_player_incidents.pop_front()
		var index:=_civilization_index(String(incident.get("source_civ_id","")))
		if index<0: continue
		if String(incident.get("incident_kind","campaign"))!="raid" and not bool((civilizations[index].player_relation as Dictionary).get("at_war",false)): continue
		return incident.duplicate(true)
	return {}


func campaign_targets(civ_id:String)->Array[Dictionary]:
	initialize()
	var index:=_civilization_index(civ_id)
	if index<0: return []
	return _public_regions(civilizations[index])


func region_snapshot(civ_id:String,region_id:String)->Dictionary:
	var index:=_civilization_index(civ_id)
	if index<0: return {}
	var region_index:=_region_index(civilizations[index],region_id)
	if region_index<0: return {}
	return (civilizations[index].strategic_regions[region_index] as Dictionary).duplicate(true)


func occupation_control(civ_id:String,region_id:String,coercive:bool=false)->Dictionary:
	var region:=region_snapshot(civ_id,region_id)
	var index:=_civilization_index(civ_id)
	if index<0 or region.is_empty() or String(region.get("controller",""))!="player":return {"error":"Select an occupied city."}
	var force:=MilitaryCampaign.occupation_force_for_region(civ_id,region_id)
	var troops:=maxi(0,int(force.get("troops",0)))
	var supply:=clampf(float(force.get("supply_level",1.0)),0,1)
	var readiness:=clampf(float(force.get("readiness",1.0)),0,1)
	var effective:=troops*supply*(.5+.5*readiness)
	var base:=occupation_requirement(civilizations[index],region)
	var required:=base
	if coercive:required+=float(region.get("population",0))*.3*(.25+.75*clampf(float(region.get("resistance",.5)),0,1))
	var result:={"troops":troops,"effective":effective,"required":ceili(required),"base_required":ceili(base),"supply":supply,"controlled":effective>=ceili(required)}
	if not bool(result.controlled):result.error="%d soldiers present, %.1f effective after supply and readiness; %d needed for %s. Bring and supply a larger garrison, or return local control."%[troops,effective,int(result.required),"city-wide coercion" if coercive else "effective occupation"]
	return result

func occupation_coercion_availability(civ_id:String,region_id:String,count:int=0)->Dictionary:
	var control:=occupation_control(civ_id,region_id,true)
	if control.has("error"):return control
	var region:=region_snapshot(civ_id,region_id)
	var state:=OCCUPATION_GOVERNANCE.state(region)
	var remaining:=int(state.get("last_coercive_day",-9999))+30-int(GameState.elapsed_days)
	if remaining>0:return {"error":"The force is committed to its previous coercive operation for another %d days."%remaining}
	var capacity:=maxi(0,floori(float(control.effective)-int(control.base_required)))
	if count>capacity:return {"error":"At most %d residents can be involved in this operation while troops maintain the occupation. A coercive operation commits the force for 30 days."%capacity}
	return control

func set_occupation_policy(civ_id:String,region_id:String,order:String)->Dictionary:
	var index:=_civilization_index(civ_id)
	if index<0: return {"error":"The region's polity no longer exists."}
	var civ:Dictionary=civilizations[index]
	var region_index:=_region_index(civ,region_id)
	if region_index<0: return {"error":"Select an occupied region."}
	var region:Dictionary=civ.strategic_regions[region_index]
	if String(region.controller)!="player": return {"error":"You do not govern this region."}
	if order in ["raze","forced_labor","military_rule"]:
		var ability:=occupation_coercion_availability(civ_id,region_id)
		if ability.has("error"):return ability
	var result:Dictionary=OCCUPATION_GOVERNANCE.change(region,order,int(GameState.elapsed_days))
	if result.has("error"): return result
	if order in ["raze","forced_labor","military_rule"]:result.region.governance["last_coercive_day"]=int(GameState.elapsed_days)
	civ.strategic_regions[region_index]=result.region
	var coercion:=float(OCCUPATION_GOVERNANCE.policy(result.region).coercion)
	if coercion>.5 or order=="raze":
		civ.player_relation.opinion=clampf(float(civ.player_relation.get("opinion",0))-.12,-1,1)
		civ.player_relation.border_tension=clampf(float(civ.player_relation.get("border_tension",0))+.12,0,1)
	civilizations[index]=civ
	_record_world_event("Occupation administration",String(region.name)+": "+String(result.message),"war",int(GameState.elapsed_days))
	return result

func occupation_resident_order(civ_id:String,region_id:String,order:String,count:int=0)->Dictionary:
	var index:=_civilization_index(civ_id)
	if index<0:return {"error":"Unknown region owner."}
	var civ:Dictionary=civilizations[index]
	var position:=_region_index(civ,region_id)
	if position<0 or String(civ.strategic_regions[position].controller)!="player":return {"error":"Select a region under your occupation."}
	var region:Dictionary=civ.strategic_regions[position]
	if order=="restore_self_rule":
		var withdrawal:Dictionary={}
		if not MilitaryCampaign.occupation_force_for_region(civ_id,region_id).is_empty():
			withdrawal=MilitaryCampaign.evacuate_occupation(civ_id,region_id)
			if withdrawal.has("error"):return withdrawal
		var restored:=abandon_occupied_region(civ_id,region_id)
		if restored.has("error"):return restored
		return {"ok":true,"message":"Local control returned to the original polity. The occupation force is returning physically; prior damage and grievance remain."}
	if order!="kill_residents" or count<1:return {"error":"Choose a valid resident order and headcount."}
	var ability:=occupation_coercion_availability(civ_id,region_id,count)
	if ability.has("error"):return ability
	if count>floori(float(region.population)):return {"error":"The requested count exceeds the residents here."}
	var deaths:=_apply_rival_civilian_deaths(civ,region_id,count)
	civ=deaths.civilization
	region=civ.strategic_regions[position]
	var governance:=OCCUPATION_GOVERNANCE.state(region)
	governance["last_coercive_day"]=int(GameState.elapsed_days)
	governance.grievance=1.0;governance.trust=0.0;governance.legitimacy=0.0
	governance.welfare=maxf(0,float(governance.welfare)-.25)
	governance["mass_killing_deaths"]=int(governance.get("mass_killing_deaths",0))+int(deaths.dead)
	region.governance=governance;region.resistance=clampf(float(region.resistance)+.35,0,1)
	civ.strategic_regions[position]=region
	civ.military_population=minf(float(civ.military_population),_working_age_population(civ.cohorts)*.55)
	civ.player_relation.opinion=-1.0;civ.player_relation.border_tension=1.0
	civilizations[index]=civ
	var message:="%d residents were killed in %s. These are deaths, not transfers. Survivors retain lasting grievance; relations with their polity have collapsed." % [int(deaths.dead),String(region.name)]
	_record_world_event("Mass killing of residents",message,"war",int(GameState.elapsed_days))
	return {"ok":true,"dead":int(deaths.dead),"message":message}


func occupation_governance_snapshot(civ_id:String,region_id:String)->Dictionary:
	var region:=region_snapshot(civ_id,region_id)
	if region.is_empty() or String(region.controller)!="player": return {}
	var result:=OCCUPATION_GOVERNANCE.state(region)
	result["name"]=String(region.name)
	result["population"]=float(region.population)
	result["resistance"]=float(region.resistance)
	result["integration"]=float(region.integration)
	result["damage"]=float(region.damage)
	result["required_garrison"]=occupation_requirement(civilizations[_civilization_index(civ_id)],region)
	result["garrison"]=int(MilitaryCampaign.occupation_force_for_region(civ_id,region_id).get("troops",0))
	result["control"]=occupation_control(civ_id,region_id)
	return result


func occupation_requirement(civ:Dictionary,region:Dictionary)->float:
	var capital_load:=0.025 if String(region.get("role",""))=="capital" else 0.0
	var resistance:=float(region.get("resistance",0.45)) if String(region.get("controller",String(civ.id)))=="player" else (0.42+float(civ.cohesion)*0.28)
	return maxf(1.0,float(region.get("population",1.0))*(0.025+resistance*0.045+capital_load))


func _region_index(civ:Dictionary,region_id:String)->int:
	var regions:Array=civ.get("strategic_regions",[])
	for index in regions.size():
		if String((regions[index] as Dictionary).get("id",""))==region_id: return index
	return -1


func _region_location(region_id:String)->Dictionary:
	for owner_index in civilizations.size():
		var region_index:=_region_index(civilizations[owner_index],region_id)
		if region_index>=0: return {"owner_index":owner_index,"region_index":region_index}
	return {}


func _controller_label(controller_id:String)->String:
	if controller_id=="player": return "YOU"
	var index:=_civilization_index(controller_id)
	return String(civilizations[index].name) if index>=0 else "UNKNOWN CONTROL"


func _frontline_region_index(civ:Dictionary)->int:
	var regions:Array=civ.get("strategic_regions",[])
	var ordered:Array[Dictionary]=[]
	for index in regions.size(): ordered.append({"index":index,"approach":int((regions[index] as Dictionary).get("approach_index",index))})
	ordered.sort_custom(func(a:Dictionary,b:Dictionary)->bool: return int(a.approach)<int(b.approach))
	for entry in ordered:
		var index:=int(entry.index)
		var controller:=String((regions[index] as Dictionary).get("controller",String(civ.id)))
		if controller=="player": continue
		return index if controller==String(civ.id) else -1
	return -1


func offensive_campaign_data(civ_id:String,fielded_strength:int,region_id:String="",raid:bool=false)->Dictionary:
	initialize()
	var index:=_civilization_index(civ_id)
	if index<0: return {"error":"Unknown civilization."}
	var civ:Dictionary=civilizations[index]
	var relation:Dictionary=_relation_with_strategy_defaults(civ.player_relation,civ)
	if raid and String(relation.get("treaty","none")) in ["non_aggression","truce"]: return {"error":"A standing non-aggression compact or truce bars a raid."}
	if fielded_strength<=0: return {"error":"No trained field formation is available for an offensive campaign."}
	if region_id!="" and city_intelligence.known("player",region_id).is_empty(): return {"error":"No report identifies that city."}
	var selected_region_id:=region_id
	if selected_region_id=="":
		for target in campaign_targets(civ_id):
			if bool(target.get("available",false)): selected_region_id=String(target.id); break
	if selected_region_id=="": return {"error":"No region controlled by this civilization is exposed to your campaign."}
	var location:=_region_location(selected_region_id)
	if location.is_empty(): return {"error":"The selected strategic region no longer exists."}
	var owner:Dictionary=civilizations[int(location.owner_index)]
	var target_index:=int(location.region_index)
	var region:Dictionary=owner.strategic_regions[target_index]
	if String(region.get("controller",String(owner.id)))!=civ_id: return {"error":"%s is controlled by %s; conduct the campaign against that civilization instead." % [String(region.name),_controller_label(String(region.get("controller","")))]}
	var foreign_holding:=String(owner.id)!=civ_id
	if not foreign_holding and target_index!=_frontline_region_index(civ) and not _nearby_player_army(city_intelligence.vector(city_intelligence.site(selected_region_id).position),0.5): return {"error":"The campaign front has not reached %s. Capture the exposed regions first." % String(region.name)}
	var region_weight:=float(region.get("strategic_weight",0.12))
	var fortification:=float(region.get("fortification",0.25))*(1.0-float(region.get("damage",0.0))*0.65)
	# The defender is drawn from the rival's actual aggregate armed capacity.
	# It is never resized to make the player's current army artificially viable.
	var garrison:=float(civ.military_population)*region_weight*(0.72+fortification)*(0.82+float(civ.logistics)*0.36)
	return {"id":"%s_%s_%s_%d" % ["raid" if raid else "offensive",civ_id,String(region.id),int(GameState.elapsed_days)],"incident_kind":"raid" if raid else "campaign","field_encounter":raid,"source_civ_id":civ_id,"source_name":String(civ.name),"target_region_id":String(region.id),"target_region_name":String(region.name),"target_region_role":String(region.role),"target_population":float(region.population),"target_original_civ_id":String(owner.id),"liberation_campaign":foreign_holding,"occupation_required":0.0 if raid else occupation_requirement(owner,region),"strength":maxi(3,roundi(garrison*(0.72 if raid else 1.0))),"technology":float(civ.knowledge),"readiness":clampf(float(civ.military_readiness)*0.82+float(civ.get("command_readiness",0.4))*0.18,0.1,1.0),"aggression":float(civ.aggression),"terrain_defense":clampf(1.03+fortification*0.34+float(civ.logistics)*0.07+float(civ.institutions)*0.05,1.04,1.38),"created_day":int(GameState.elapsed_days),"campaign_mode":"offensive","front_stance":String(relation.get("front_stance","balanced")),"war_id":String(relation.get("war_id",""))}


func war_goal_options(civ_id:String,region_id:String="") -> Array[Dictionary]:
	initialize()
	var index:=_civilization_index(civ_id)
	if index<0: return []
	var civ:Dictionary=civilizations[index]
	var options:Array[Dictionary]=[]
	var selected:Dictionary={}
	for region in _public_regions(civ):
		if String(region.get("id",""))==region_id: selected=region; break
	var frontline_id:=""
	for known_region:Dictionary in _public_regions(civ):
		if bool(known_region.get("available",false)): frontline_id=String(known_region.id); break
	var limited_target:=region_id if not selected.is_empty() and bool(selected.get("available",false)) and not bool(selected.get("foreign_holding",false)) else frontline_id
	options.append({"id":"limited","label":String(WAR_GOAL_LABELS.limited),"target_region_id":limited_target,"available":limited_target!="","description":"Take one exposed strategic region, then press for a bounded settlement."})
	options.append({"id":"break_power","label":String(WAR_GOAL_LABELS.break_power),"target_region_id":_default_war_target(civ,"break_power") if not city_intelligence.known("player",_default_war_target(civ,"break_power")).is_empty() else "","available":not city_intelligence.known("player",_default_war_target(civ,"break_power")).is_empty(),"description":"Occupy the capital or three home regions. Greater leverage, exhaustion, and occupation cost."})
	var liberation_available:=not selected.is_empty() and bool(selected.get("foreign_holding",false))
	options.append({"id":"liberation","label":String(WAR_GOAL_LABELS.liberation),"target_region_id":region_id if liberation_available else "","available":liberation_available,"description":"Defeat this occupier and return the selected foreign region to its original polity."})
	return options


func set_player_war_goal(civ_id:String,goal:String,region_id:String="") -> Dictionary:
	initialize()
	var index:=_civilization_index(civ_id)
	if index<0: return {"error":"Unknown civilization."}
	var civ:Dictionary=civilizations[index]
	var relation:Dictionary=_relation_with_strategy_defaults(civ.player_relation,civ)
	if bool(relation.get("at_war",false)): return {"error":"War objectives are locked once open war begins."}
	var selected_option:Dictionary={}
	for option in war_goal_options(civ_id,region_id):
		if String(option.get("id",""))==goal: selected_option=option; break
	if selected_option.is_empty() or not bool(selected_option.get("available",false)): return {"error":"That war objective is not valid for the selected strategic region."}
	relation["war_goal"]=goal
	relation["war_target_region_id"]=String(selected_option.get("target_region_id",""))
	civ["player_relation"]=relation
	civilizations[index]=civ
	return {"ok":true,"goal":goal,"target_region_id":String(relation.war_target_region_id),"message":"War plan set: %s." % String(WAR_GOAL_LABELS.get(goal,goal)).capitalize()}


func war_objective_status(civ_id:String) -> Dictionary:
	var index:=_civilization_index(civ_id)
	if index<0: return {}
	var civ:Dictionary=civilizations[index]
	var relation:Dictionary=_relation_with_strategy_defaults(civ.player_relation,civ)
	var goal:=String(relation.get("war_goal","limited"))
	var occupation:=_player_occupation_status(civ)
	var progress:=0.0
	var complete:=false
	var target_name:=""
	var target_id:=String(relation.get("war_target_region_id",""))
	var location:=_region_location(target_id) if target_id!="" else {}
	var target:Dictionary={}
	if not location.is_empty():
		var owner:Dictionary=civilizations[int(location.owner_index)]
		target=(owner.strategic_regions[int(location.region_index)] as Dictionary)
		target_name=String(city_intelligence.known("player",target_id).get("name","Unconfirmed city"))
	match goal:
		"limited":
			complete=not target.is_empty() and String(target.get("controller",""))=="player"
			progress=1.0 if complete else 0.0
		"break_power":
			complete=bool(occupation.capital_occupied) or int(occupation.region_count)>=3
			progress=maxf(float(occupation.region_count)/3.0,1.0 if bool(occupation.capital_occupied) else 0.0)
		"liberation":
			complete=not target.is_empty() and String(target.get("controller",""))==String(target.get("original_controller","")) and int(target.get("last_control_change_day",0))>=int(relation.get("war_started_day",0))
			progress=1.0 if complete else 0.0
		"defend":
			complete=int(occupation.region_count)==0 and float(relation.get("war_score",0.0))>=10.0
			progress=clampf((float(relation.get("war_score",0.0))+25.0)/50.0,0.0,1.0)
		_:
			progress=0.0
	progress=clampf(progress,0.0,1.0)
	var description:=String(WAR_GOAL_LABELS.get(goal,"NO OBJECTIVE"))
	if target_name!="": description+=" • "+target_name
	return {"goal":goal,"label":String(WAR_GOAL_LABELS.get(goal,"NO OBJECTIVE")),"target_region_id":target_id,"target_name":target_name,"progress":progress,"complete":complete,"description":description}


func peace_forecast(civ_id:String) -> Dictionary:
	var index:=_civilization_index(civ_id)
	if index<0: return {"error":"Unknown civilization."}
	var civ:Dictionary=civilizations[index]
	var relation:Dictionary=_relation_with_strategy_defaults(civ.player_relation,civ)
	if not bool(relation.get("at_war",false)): return {"error":"There is no active war to settle."}
	var occupation:=_player_occupation_status(civ)
	var objective:=war_objective_status(civ_id)
	var strategic_leverage:=float(occupation.region_count)*0.11+(0.26 if bool(occupation.capital_occupied) else 0.0)+(0.16 if bool(occupation.complete) else 0.0)
	var score_factor:=float(relation.get("war_score",0.0))/100.0
	var exhaustion_gap:=float(relation.get("rival_war_exhaustion",0.0))-float(relation.get("player_war_exhaustion",0.0))*0.45
	var objective_factor:=0.30 if bool(objective.get("complete",false)) else float(objective.get("progress",0.0))*0.12
	var acceptance:=float(relation.get("opinion",0.0))*0.30+float(civ.diplomacy)*0.25+score_factor*0.42+strategic_leverage+exhaustion_gap*0.32+objective_factor-0.15
	var label:="WILL ACCEPT" if acceptance>=0.05 else ("MAY ACCEPT" if acceptance>=-0.12 else "WILL REFUSE")
	return {"acceptance":acceptance,"label":label,"objective":objective,"strategic_leverage":strategic_leverage,"war_score":float(relation.get("war_score",0.0)),"player_exhaustion":float(relation.get("player_war_exhaustion",0.0)),"rival_exhaustion":float(relation.get("rival_war_exhaustion",0.0)),"can_accept":acceptance>=0.05}


func strategic_assessment(civ_id:String,region_id:String="") -> Dictionary:
	var city:Dictionary=city_intelligence.known("player",region_id)
	var guard:Dictionary=city.get("fields",{}).get("garrison",{})
	var fielded:=int(MilitaryCampaign.home_army.get("troops",0))
	var low:=int(guard.get("low",-1)); var high:=int(guard.get("high",-1))
	var confidence:=float(guard.get("quality",0))
	var usable:=not guard.is_empty() and not bool(guard.get("stale",true))
	var ratio:=float(fielded)/maxf(1,float(high)*1.3) if usable else -1.0
	var food_days:=float(GameState.simulation_metrics.get("food_days",0))
	return {"outlook":"UNKNOWN — obtain city reconnaissance" if not usable else ("FAVORABLE ESTIMATE" if ratio>1.2 else "CONTESTED ESTIMATE"),"casualty_risk":"UNCERTAIN","power_ratio":ratio,"fielded":fielded,"enemy_estimate":roundi((low+high)*.5) if usable else -1,"enemy_estimate_low":low,"enemy_estimate_high":high,"intel_confidence":confidence,"player_readiness":float(MilitaryCampaign.home_army.get("readiness",0)),"player_supply":float(MilitaryCampaign.home_army.get("supply_level",1)),"supply_label":"ADEQUATE" if food_days>=20 else "STRAINED","food_days":food_days,"logistics":float(GameState.simulation_metrics.get("logistics",0)),"occupation_required":0.0,"region_value":"Dated city observations, not live enemy strength. Actual resistance is resolved at contact.","rival_intent":"UNCONFIRMED","threat_level":"UNCERTAIN","observation_day":int(guard.get("observed_day",-1))}


func _rival_intent(civ:Dictionary,relation:Dictionary,power_ratio:float=-1.0) -> String:
	var ratio:=power_ratio if power_ratio>=0.0 else _military_power(civ)/maxf(1.0,_player_military_power())
	if bool(relation.get("at_war",false)): return "Pressing the war" if ratio>=0.92 else "Preserving forces and seeking leverage"
	if int(relation.get("truce_until_day",0))>int(GameState.elapsed_days): return "Recovering under truce"
	if String(relation.get("treaty","none"))=="trade": return "Expanding exchange and production"
	if String(relation.get("treaty","none"))=="non_aggression": return "Developing behind a secured frontier"
	if String(relation.get("stance","watchful"))=="contain": return "Countering your influence"
	if String(civ.get("strategy",""))=="fortification": return "Fortifying strategic regions"
	if String(civ.get("strategy",""))=="expansion" and float(relation.get("border_tension",0.0))>=0.42: return "Testing the frontier for weakness"
	return {"sustenance":"Securing food reserves","growth":"Expanding population capacity","inquiry":"Pursuing a knowledge advantage","commerce":"Seeking profitable partners","expansion":"Building offensive capacity"}.get(String(civ.get("strategy","")),"Watching the balance of power")


func _threat_level(civ:Dictionary,relation:Dictionary,power_ratio:float=-1.0) -> String:
	if bool(relation.get("at_war",false)): return "WAR"
	var ratio:=power_ratio if power_ratio>=0.0 else _military_power(civ)/maxf(1.0,_player_military_power())
	var pressure:=float(relation.get("border_tension",0.0))*0.48+float(civ.aggression)*0.28+clampf(ratio-0.8,0.0,1.5)*0.16-maxf(0.0,float(relation.get("opinion",0.0)))*0.12
	return "CRITICAL" if pressure>=0.72 else ("HIGH" if pressure>=0.52 else ("GUARDED" if pressure>=0.32 else "LOW"))


func player_action_availability(civ_id:String,action:String)->Dictionary:
	initialize()
	var index:=_civilization_index(civ_id)
	if index<0: return {"error":"Unknown civilization."}
	var civ:Dictionary=civilizations[index]
	var relation:Dictionary=civ.player_relation
	var normalized:=action.strip_edges().to_lower().replace(" ","_")
	if int(relation.get("contact_level",0))<2: return {"error":"No direct contact exists with this foreign polity."}
	if normalized=="leader_parley":
		return {"ok":true,"action":normalized}
	if normalized in CARRIED_DIPLOMATIC_ACTIONS and not bool(relation.get("home_location_known",false)):
		return {"error":"Their settlement is unlocated. A returned scout report must establish a physical destination before this message can be sent.","requires_location":true}
	var opinion:=float(relation.get("opinion",0.0))
	var at_war:=bool(relation.get("at_war",false))
	match normalized:
		"open_trade":
			if at_war: return {"error":"Trade cannot open during active war."}
			if String(relation.get("treaty","none"))=="trade": return {"error":"A trade compact is already active."}
			if opinion<-0.48: return {"error":"Relations are too hostile for a trade compact; aid or de-escalation is required first."}
		"non_aggression":
			if at_war: return {"error":"Seek peace before proposing non-aggression."}
			if String(relation.get("treaty","none"))=="non_aggression": return {"error":"A non-aggression compact is already active."}
			if opinion<-0.28: return {"error":"Relations are too hostile for a non-aggression compact."}
		"send_aid":
			var available:=maxf(0.0,FoodSystem.total_stored())
			var amount:=minf(available*0.10,maxf(5.0,GameState.population_exact*0.75))
			if amount<5.0: return {"error":"At least 5.0 Food must be available for meaningful aid."}
			return {"ok":true,"action":normalized,"amount":amount}
		"contain":
			if at_war: return {"error":"Containment is a peacetime posture; this relation is already at war."}
			if String(relation.get("stance","watchful"))=="contain" and String(relation.get("treaty","none"))=="none": return {"error":"Containment is already the standing policy."}
		"declare_war":
			if at_war: return {"error":"Open war already exists with this civilization."}
			if int(relation.get("truce_until_day",0))>int(GameState.elapsed_days): return {"error":"The truce remains binding for %d more days." % (int(relation.truce_until_day)-int(GameState.elapsed_days))}
			var objective:=war_objective_status(civ_id)
			if String(objective.get("goal","limited"))!="defend" and city_intelligence.known("player",String(objective.get("target_region_id",""))).is_empty(): return {"error":"Choose a discovered city before declaring this offensive war."}
			if String(objective.get("target_region_id",""))=="" and String(objective.get("goal","limited"))!="defend": return {"error":"Choose a valid war objective before declaring war."}
		"seek_peace":
			if not at_war: return {"error":"There is no active war to end."}
			if MilitaryCampaign!=null and MilitaryCampaign.has_active_operation_for_civ(civ_id): return {"error":"Resolve the active field campaign before negotiating peace."}
			var forecast:=peace_forecast(civ_id)
			if not bool(forecast.get("can_accept",false)): return {"error":"%s refuses peace: %s. Improve war score, complete the objective, or exhaust its capacity." % [String(civ.name),String(forecast.get("label","WILL REFUSE"))]}
		_:
			return {"error":"Unknown diplomatic action."}
	return {"ok":true,"action":normalized}


func conduct_player_action(civ_id:String,action:String,arrived_via_envoy:bool=false)->Dictionary:
	if action=="leader_parley":
		if not arrived_via_envoy: return {"error":"Send these terms by envoy first."}
		return ForeignDiplomacy.resolve(civ_id)
	var availability:=player_action_availability(civ_id,action)
	if availability.has("error"): return availability
	var index:=_civilization_index(civ_id)
	var civ:Dictionary=civilizations[index]
	var relation:Dictionary=_relation_with_strategy_defaults(civ.player_relation,civ)
	var normalized:=String(availability.action)
	if normalized in CARRIED_DIPLOMATIC_ACTIONS and not arrived_via_envoy:
		return {"error":"%s must be carried by a physical delegation. Send envoys; the proposal takes effect only after the round trip." % String(DIPLOMATIC_PURPOSE_LABELS.get(normalized,"This proposal")).capitalize(),"requires_envoy":true,"action":normalized}
	var opinion:=float(relation.get("opinion",0.0))
	var message:=""
	match normalized:
		"open_trade":
			relation["treaty"]="trade"; relation["stance"]="cooperative"; relation["opinion"]=clampf(opinion+0.08,-1.0,1.0)
			message="A standing trade compact opens value-conserved exchange with %s." % String(civ.name)
		"non_aggression":
			relation["treaty"]="non_aggression"; relation["stance"]="cooperative"; relation["trade"]=0.0; relation["opinion"]=clampf(opinion+0.06,-1.0,1.0); relation["border_tension"]=maxf(0.0,float(relation.border_tension)-0.18)
			message="%s accepts a non-aggression compact." % String(civ.name)
		"send_aid":
			var amount:=float(availability.amount)
			var delivered:=FoodSystem.issue_for_obligation(amount,"aid","Food aid • %s" % String(civ.name))
			if delivered<4.999: return {"error":"Food stores changed before aid could be dispatched."}
			civ["food_days"]=clampf(float(civ.food_days)+delivered/maxf(1.0,float(civ.population)),0.0,180.0)
			relation["opinion"]=clampf(opinion+0.14,-1.0,1.0); relation["border_tension"]=maxf(0.0,float(relation.border_tension)-0.10)
			message="%.1f Food reaches %s; their aggregate reserves and disposition improve." % [delivered,String(civ.name)]
		"contain":
			relation["stance"]="contain"; relation["treaty"]="none"; relation["trade"]=0.0; relation["opinion"]=clampf(opinion-0.12,-1.0,1.0); relation["border_tension"]=clampf(float(relation.border_tension)+0.15,0.0,1.0)
			message="The civilization adopts containment toward %s. Border tension rises and the security system must absorb it." % String(civ.name)
		"declare_war":
			if String(relation.get("war_goal","limited")) in ["none","defend"]:
				relation["war_goal"]="limited"
				relation["war_target_region_id"]=_default_war_target(civ,"limited")
			relation["stance"]="hostile"; relation["treaty"]="war"; relation["trade"]=0.0; relation["at_war"]=true; relation["opinion"]=clampf(opinion-0.42,-1.0,1.0); relation["border_tension"]=1.0
			relation["war_score"]=0.0; relation["conflict_turns"]=0; relation["war_started_day"]=int(GameState.elapsed_days); relation["last_war_result"]="ongoing"
			relation["war_id"]=_start_war("player",String(civ.id),String(relation.war_goal),String(relation.war_target_region_id),int(GameState.elapsed_days),"War declared by %s" % _player_civilization_name())
			var named_record_index:=_war_record_index(String(relation.war_id))
			var named_war:=String(war_history[named_record_index].name) if named_record_index>=0 else "Open war"
			message="%s begins with %s. Objective: %s. Battles, control, production, replacements, and exhaustion now determine the settlement." % [named_war,String(civ.name),String(WAR_GOAL_LABELS.get(String(relation.war_goal),"LIMITED WAR"))]
		"seek_peace":
			var occupation:=_player_occupation_status(civ)
			var objective:=war_objective_status(civ_id)
			var score:=float(relation.get("war_score",0.0))
			relation["at_war"]=false; relation["treaty"]="truce"; relation["stance"]="watchful"; relation["opinion"]=clampf(opinion+0.12,-1.0,1.0); relation["border_tension"]=0.30
			relation["truce_until_day"]=int(GameState.elapsed_days)+365
			relation["last_war_result"]="objective achieved" if bool(objective.get("complete",false)) else ("advantage" if score>10.0 else ("setback" if score<-10.0 else "stalemate"))
			_end_war(String(relation.get("war_id","")),int(GameState.elapsed_days),String(relation.last_war_result))
			relation["war_goal"]="limited"; relation["war_target_region_id"]=_default_war_target(civ,"limited"); relation["conflict_turns"]=0
			_remove_pending_player_incidents(civ_id)
			message="A one-year truce ends the war with %s; the current strategic control line remains in place%s. Result: %s." % [String(civ.name)," after occupation of all five urban regions" if bool(occupation.complete) else "",String(relation.last_war_result).to_upper()]
		_:
			return {"error":"Unknown diplomatic action."}
	civ["player_relation"]=relation
	civilizations[index]=civ
	var event:={"day":int(GameState.elapsed_days),"title":"Foreign policy enacted","description":message,"domain":"diplomacy","severity":"major" if normalized in ["declare_war","seek_peace"] else "notice"}
	_record_world_event(String(event.title),message,"diplomacy",int(GameState.elapsed_days))
	GameState.simulation_events.push_front(event)
	if GameState.simulation_events.size()>80: GameState.simulation_events.resize(80)
	_rebuild_competition()
	return {"ok":true,"action":normalized,"civilization":civ.duplicate(true),"message":message}

func consume_siege_relief_receipt(receipt_id:String,siege_id:String)->Dictionary:
	return ForeignDiplomacy.commitments.consume_receipt(receipt_id,siege_id)


func _round_casualties(result:Dictionary,side:String)->Dictionary:
	var totals:={"killed":0,"wounded":0,"scattered":0}
	for round_variant in result.get("rounds",[]):
		var breakdown:Dictionary=(round_variant as Dictionary).get("%s_casualties" % side,{})
		for field in totals: totals[field]=int(totals[field])+maxi(0,int(breakdown.get(field,0)))
	if int(totals.killed)==0: totals["killed"]=maxi(0,int((result.get(side,{}) as Dictionary).get("dead",0)))
	return totals


func _civilian_battle_effects(result:Dictionary,target_population:float)->Dictionary:
	var rounds:Array=result.get("rounds",[])
	if rounds.is_empty() or target_population<=1.0: return {"dead":0,"displaced":0}
	var military_dead:=int(_round_casualties(result,"attacker").killed)+int(_round_casualties(result,"defender").killed)
	var siege_factor:=1.45 if float(result.get("terrain_defense",1.0))>1.14 else 1.0
	var offensive_factor:=1.20 if String(result.get("campaign_mode","defensive"))=="offensive" else 0.75
	var estimated:=float(military_dead)*0.055*siege_factor*offensive_factor+target_population*0.000015*float(rounds.size())*siege_factor
	var dead:=mini(maxi(0,roundi(estimated)),maxi(0,roundi(target_population*0.012)))
	var displaced:=mini(maxi(0,roundi(float(dead)*4.0+target_population*0.00012*float(rounds.size())*offensive_factor)),maxi(0,roundi(target_population*0.08)))
	return {"dead":dead,"displaced":displaced}


func _apply_rival_civilian_deaths(civ:Dictionary,region_id:String,requested:int)->Dictionary:
	var region_index:=_region_index(civ,region_id)
	if region_index<0 or requested<=0: return {"civilization":civ,"dead":0}
	var regions:Array=(civ.get("strategic_regions",[]) as Array).duplicate(true)
	var region:Dictionary=regions[region_index]
	var actual:=mini(maxi(0,requested),mini(maxi(0,roundi(float(region.get("population",0.0)))),maxi(0,roundi(float(civ.get("population",1.0))-1.0))))
	if actual<=0: return {"civilization":civ,"dead":0}
	region["population"]=maxf(0.0,float(region.get("population",0.0))-float(actual))
	regions[region_index]=region
	civ["strategic_regions"]=regions
	civ["population"]=maxf(1.0,float(civ.get("population",1.0))-float(actual))
	var civilian_weights:={"children":1.05,"youth":0.78,"early_adults":0.92,"established_adults":1.0,"mature_adults":1.08,"elders":1.20}
	civ["cohorts"]=_scaled_cohorts(_remove_weighted_cohort_population(civ.get("cohorts",{}),float(actual),civilian_weights),float(civ.population))
	return {"civilization":civ,"dead":actual}


func _apply_rival_displacement(civ:Dictionary,region_id:String,requested:int)->Dictionary:
	var source_index:=_region_index(civ,region_id)
	if source_index<0 or requested<=0: return {"civilization":civ,"displaced":0}
	var regions:Array=(civ.get("strategic_regions",[]) as Array).duplicate(true)
	var source:Dictionary=regions[source_index]
	var actual:=mini(maxi(0,requested),maxi(0,roundi(float(source.get("population",0.0))*0.35)))
	var destinations:Array[int]=[]
	for index in regions.size():
		if index!=source_index and String((regions[index] as Dictionary).get("controller",String(civ.id)))==String(civ.id): destinations.append(index)
	if actual<=0 or destinations.is_empty(): return {"civilization":civ,"displaced":0}
	source["population"]=maxf(0.0,float(source.get("population",0.0))-float(actual))
	regions[source_index]=source
	var share:=float(actual)/float(destinations.size())
	for destination in destinations: regions[destination]["population"]=float(regions[destination].get("population",0.0))+share
	civ["strategic_regions"]=regions
	civ["displaced_population"]=maxf(0.0,float(civ.get("displaced_population",0.0))+float(actual))
	return {"civilization":civ,"displaced":actual}


func resolve_player_battle(civ_id:String,result:Dictionary)->Dictionary:
	var index:=_civilization_index(civ_id)
	if index<0: return {"error":"Unknown civilization."}
	var civ:Dictionary=civilizations[index]
	var home_side:=String(result.get("home_side","attacker"))
	var rival_side:="defender" if home_side=="attacker" else "attacker"
	var rival_result:Dictionary=result.get(rival_side,{})
	var home_result:Dictionary=result.get(home_side,{})
	var termination:Dictionary=result.get("termination",{})
	var dead:=maxi(0,int(rival_result.get("dead",0)))
	var rival_defeated:=String(termination.get("defeated",""))==String(rival_result.get("name",""))
	var prisoners:=maxi(0,int(termination.get("prisoners",0))) if rival_defeated else 0
	var population_before_losses:=float(civ.population)
	civ["population"]=maxf(1.0,float(civ.population)-float(dead))
	civ=_scale_strategic_region_populations(civ,float(civ.population)/maxf(1.0,population_before_losses))
	civ["military_population"]=maxf(0.0,float(civ.military_population)-float(dead+prisoners))
	var combat_weights:={"children":0.08,"youth":1.30,"early_adults":1.85,"established_adults":1.70,"mature_adults":1.05,"elders":0.18}
	civ["cohorts"]=_scaled_cohorts(_remove_weighted_cohort_population(civ.cohorts,float(dead),combat_weights),float(civ.population))
	var relation:Dictionary=_relation_with_strategy_defaults(civ.player_relation,civ)
	var player_won:=String(termination.get("captor",""))==String(home_result.get("name",MilitaryCampaign.home_army.get("name","")))
	var decisive:=String(termination.get("type","continued"))!="continued" and String(termination.get("captor",""))!=""
	var campaign_mode:=String(result.get("campaign_mode","defensive"))
	var field_encounter:=bool(result.get("field_encounter",false))
	var threat:Dictionary=result.get("threat",{})
	var is_raid:=String(threat.get("incident_kind","campaign"))=="raid"
	var target_region_id:=String(result.get("target_region_id",threat.get("target_region_id","")))
	var strategic_result:Dictionary={"decisive":decisive,"player_won":player_won,"campaign_mode":campaign_mode,"target_region_id":target_region_id}
	var home_dead:=maxi(0,int(home_result.get("dead",0)))
	if bool(relation.get("at_war",false)): relation=_ensure_relation_war(relation,"player",String(civ.id),int(GameState.elapsed_days),"Campaign battle")
	var target_population:=float(region_snapshot(civ_id,target_region_id).get("population",0.0)) if target_region_id!="" else float(GameState.population_total)
	var civilian_effects:={"dead":0,"displaced":0} if field_encounter else _civilian_battle_effects(result,target_population)
	var rival_civilian_dead:=0
	var rival_displaced:=0
	var player_civilian_dead:=0
	var player_displaced:=0
	if target_region_id!="":
		var civilian_result:=_apply_rival_civilian_deaths(civ,target_region_id,int(civilian_effects.dead))
		civ=civilian_result.civilization
		rival_civilian_dead=int(civilian_result.dead)
		var displacement_result:=_apply_rival_displacement(civ,target_region_id,int(civilian_effects.displaced))
		civ=displacement_result.civilization
		rival_displaced=int(displacement_result.displaced)
	elif not field_encounter:
		var civilian_registration:=GameState.register_population_deaths(int(civilian_effects.dead),"Civilian deaths in war")
		player_civilian_dead=int(civilian_registration.get("count",0))
		player_displaced=int(civilian_effects.displaced)
		GameState.simulation_metrics["displaced_population"]=maxf(0.0,float(GameState.simulation_metrics.get("displaced_population",0.0))+float(player_displaced))
	strategic_result["civilian_dead"]={"player":player_civilian_dead,"rival":rival_civilian_dead}
	strategic_result["displaced"]={"player":player_displaced,"rival":rival_displaced}
	relation["player_war_exhaustion"]=clampf(float(relation.get("player_war_exhaustion",0.0))+float(home_dead)/maxf(1.0,GameState.population_exact+float(home_dead))*5.0+(0.025 if decisive and not player_won else 0.0),0.0,1.0)
	relation["rival_war_exhaustion"]=clampf(float(relation.get("rival_war_exhaustion",0.0))+float(dead+prisoners)/maxf(1.0,population_before_losses)*5.0+(0.025 if decisive and player_won else 0.0),0.0,1.0)
	if decisive and player_won:
		civ["wars_lost"]=int(civ.wars_lost)+1
		if campaign_mode=="offensive" and target_region_id!="":
			var capture:=_capture_region(civ,target_region_id,home_result,rival_result)
			civ=capture.get("civilization",civ)
			strategic_result.merge(capture.get("outcome",{}),true)
			var captured_region:Dictionary=strategic_result.get("region",{})
			var role_score:={"frontier":14.0,"granary":17.0,"market":19.0,"works":22.0,"capital":32.0}
			relation["war_score"]=clampf(float(relation.get("war_score",0.0))+float(role_score.get(String(captured_region.get("role","frontier")),14.0)), -100.0,100.0)
		elif campaign_mode=="offensive" and not field_encounter:
			var transfer:=minf(0.025,maxf(0.0,float(civ.territory)-0.08))
			civ["territory"]=float(civ.territory)-transfer
			player_territory_balance+=transfer
		relation["opinion"]=clampf(float(relation.opinion)-0.08,-1.0,1.0)
	elif decisive:
		relation["war_score"]=clampf(float(relation.get("war_score",0.0))-18.0,-100.0,100.0)
		civ["wars_won"]=int(civ.wars_won)+1
		if campaign_mode=="defensive" and target_region_id!="":
			var restoration:=_restore_region_to_rival(civ,target_region_id)
			civ=restoration.get("civilization",civ)
			strategic_result.merge(restoration.get("outcome",{}),true)
		elif campaign_mode=="defensive" and not field_encounter:
			var transfer:=minf(0.018,maxf(0.0,_player_territory()-0.08))
			civ["territory"]=float(civ.territory)+transfer
			player_territory_balance-=transfer
		relation["border_tension"]=clampf(float(relation.border_tension)+0.08,0.0,1.0)
	if is_raid and decisive:
		relation["opinion"]=clampf(float(relation.get("opinion",0.0))-0.18,-1.0,1.0)
		relation["border_tension"]=clampf(float(relation.get("border_tension",0.0))+0.22,0.0,1.0)
		if player_won and campaign_mode=="offensive":
			var raid_strength:=maxi(1,int((result.get(home_side,{}) as Dictionary).get("remaining_troops",0)))
			var available_food:=maxf(0.0,float(civ.get("food_days",0.0))*float(civ.get("population",1.0)))
			var food_spoils:=minf(available_food*0.06,maxf(4.0,float(raid_strength)*0.85))
			civ["food_days"]=maxf(0.0,float(civ.get("food_days",0.0))-food_spoils/maxf(1.0,float(civ.get("population",1.0))))
			FoodSystem.receive_external_food(food_spoils)
			strategic_result["raid_spoils"]={"Food":food_spoils}
			_record_world_event("Raid succeeds","The raiding force withdraws from %s with %.1f Food; no territory is occupied." % [String(result.get("target_region_name","the target region")),food_spoils],"war",int(GameState.elapsed_days))
		elif campaign_mode=="offensive":
			_record_world_event("Raid repulsed","The raiding force is driven from %s without occupying ground." % String(result.get("target_region_name","the target region")),"war",int(GameState.elapsed_days))
	var home_breakdown:=_round_casualties(result,home_side)
	var rival_breakdown:=_round_casualties(result,rival_side)
	var territorial_change:Dictionary={}
	if bool(strategic_result.get("region_captured",false)) or bool(strategic_result.get("region_recaptured",false)) or bool(strategic_result.get("region_liberated",false)):
		var changed_region:Dictionary=strategic_result.get("region",{})
		territorial_change={"day":int(GameState.elapsed_days),"region_id":String(changed_region.get("id",target_region_id)),"region":String(changed_region.get("name",target_region_id)),"controller":String(changed_region.get("controller",""))}
	if String(relation.get("war_id",""))!="":
		_record_war_battle(String(relation.war_id),{"day":int(GameState.elapsed_days),"name":"Battle of %s" % String(result.get("target_region_name",target_region_id if target_region_id!="" else _player_civilization_name())).capitalize(),"location":String(result.get("target_region_name",target_region_id if target_region_id!="" else "home territory")),"outcome":"player victory" if player_won else ("rival victory" if decisive else "continued"),"losses":{"player":{"military_dead":int(home_breakdown.killed),"civilian_dead":player_civilian_dead,"wounded":int(home_breakdown.wounded),"captured":int(termination.get("prisoners",0)) if not player_won else 0,"displaced":player_displaced},String(civ.id):{"military_dead":int(rival_breakdown.killed),"civilian_dead":rival_civilian_dead,"wounded":int(rival_breakdown.wounded),"captured":prisoners,"displaced":rival_displaced}},"territorial_change":territorial_change})
	civ["player_relation"]=relation
	civilizations[index]=civ
	if target_region_id!="":
		city_intelligence.publish("player",city_intelligence.capture("player",target_region_id,.85,int(GameState.elapsed_days),"field campaign report","battle:"+target_region_id),int(GameState.elapsed_days))
	_rebuild_competition()
	world_changed.emit(competition_snapshot())
	return strategic_result


func _capture_region(civ:Dictionary,region_id:String,home_result:Dictionary,rival_result:Dictionary)->Dictionary:
	var location:=_region_location(region_id)
	if location.is_empty(): return {"civilization":civ,"outcome":{"error":"The campaign target no longer exists."}}
	var owner_index:=int(location.owner_index)
	var owner:Dictionary=civ if String(civilizations[owner_index].id)==String(civ.id) else civilizations[owner_index]
	var region_index:=int(location.region_index)
	var regions:Array=(owner.get("strategic_regions",[]) as Array).duplicate(true)
	var region:Dictionary=regions[region_index]
	if String(region.get("controller",String(civ.id)))=="player": return {"civilization":civ,"outcome":{"error":"The target region was already controlled."}}
	var transfer:=minf(float(region.get("territory_value",0.01)),maxf(0.0,float(civ.territory)-0.08))
	var battle_deaths:=maxi(0,int(home_result.get("dead",0)))+maxi(0,int(rival_result.get("dead",0)))
	var damage:=clampf(0.06+float(battle_deaths)/maxf(1.0,float(region.get("population",1.0)))*0.35,0.04,0.48)
	if String(owner.id)!=String(civ.id):
		# Defeating an occupier restores the region to its original aggregate polity.
		# Taking it for the player would silently start a second war with the people
		# whose city was just liberated.
		region["controller"]=String(owner.id)
		region["resistance"]=0.0
		region["integration"]=1.0
		region["occupation_turns"]=0
		region["damage"]=clampf(float(region.get("damage",0.0))+damage,0.0,1.0)
		region["last_control_change_day"]=int(GameState.elapsed_days)
		regions[region_index]=region
		owner["strategic_regions"]=regions
		owner["territory"]=float(owner.territory)+transfer
		civ["territory"]=maxf(0.08,float(civ.territory)-transfer)
		civilizations[owner_index]=owner
		var liberation_message:="%s was liberated from %s and returned to %s. No player occupation or population record was created." % [String(region.name),String(civ.name),String(owner.name)]
		_record_world_event("Strategic region liberated",liberation_message,"war",int(GameState.elapsed_days))
		return {"civilization":civ,"outcome":{"region_liberated":true,"region":region.duplicate(true),"original_civ_id":String(owner.id),"territory_transferred":0.0,"message":liberation_message}}
	var surviving:=maxi(0,int(home_result.get("remaining_troops",0)))
	var held:=region.duplicate(true)
	held.controller="player";held.resistance=clampf(.38+float(civ.cohesion)*.30+(.14 if String(region.get("role",""))=="capital" else 0.0),.25,.92)
	var hold_need:=ceili(occupation_requirement(owner,held))
	var effective_survivors:=surviving*clampf(float(home_result.get("supply_level",1)),0,1)*(.5+.45*clampf(float(home_result.get("readiness",1)),0,1))
	if effective_survivors<hold_need:
		var message:="Battle won, but %d surviving soldiers lack the supplied, ready strength to hold %s; about %d effective personnel are required. The city remains outside your control. Reinforce before another occupation attempt."%[surviving,String(region.name),hold_need]
		_record_world_event("Victory without occupation",message,"war",int(GameState.elapsed_days))
		return {"civilization":civ,"outcome":{"region_captured":false,"occupation_required":hold_need,"message":message}}
	region["controller"]="player"
	region["resistance"]=clampf(0.38+float(civ.cohesion)*0.30+(0.14 if String(region.get("role",""))=="capital" else 0.0),0.25,0.92)
	region["integration"]=0.0
	region["occupation_turns"]=0
	region["damage"]=clampf(float(region.get("damage",0.0))+damage,0.0,1.0)
	region["last_control_change_day"]=int(GameState.elapsed_days)
	regions[region_index]=region
	owner["strategic_regions"]=regions
	civ=owner
	civ["territory"]=float(civ.territory)-transfer
	player_territory_balance+=transfer
	var required:=occupation_requirement(civ,region)
	var message:="%s fell after a decisive campaign. %.2f territory and %s residents are now under occupation; approximately %s trained personnel are required to hold it." % [String(region.name),transfer,_compact_number(float(region.population)),_compact_number(required)]
	_record_world_event("Strategic region captured",message,"war",int(GameState.elapsed_days))
	GameState.simulation_events.push_front({"day":int(GameState.elapsed_days),"title":"%s captured" % String(region.name),"description":message,"domain":"security","severity":"major"})
	return {"civilization":civ,"outcome":{"region_captured":true,"region":region.duplicate(true),"territory_transferred":transfer,"occupation_required":required,"message":message}}


func _restore_region_to_rival(civ:Dictionary,region_id:String)->Dictionary:
	var region_index:=_region_index(civ,region_id)
	if region_index<0: return {"civilization":civ,"outcome":{"error":"The defended strategic region no longer exists."}}
	var regions:Array=(civ.get("strategic_regions",[]) as Array).duplicate(true)
	var region:Dictionary=regions[region_index]
	if String(region.get("controller",String(civ.id)))!="player": return {"civilization":civ,"outcome":{"region_recaptured":false}}
	var transfer:=float(region.get("territory_value",0.01))
	region["controller"]=String(civ.id)
	region["resistance"]=0.0
	region["integration"]=1.0
	region["occupation_turns"]=0
	region["damage"]=clampf(float(region.get("damage",0.0))+0.08,0.0,1.0)
	region["last_control_change_day"]=int(GameState.elapsed_days)
	regions[region_index]=region
	civ["strategic_regions"]=regions
	civ["territory"]=float(civ.territory)+transfer
	player_territory_balance-=transfer
	var message:="%s was recaptured by %s; its territorial value and strategic functions returned to rival control." % [String(region.name),String(civ.name)]
	_record_world_event("Occupied region recaptured",message,"war",int(GameState.elapsed_days))
	return {"civilization":civ,"outcome":{"region_recaptured":true,"region":region.duplicate(true),"territory_transferred":-transfer,"message":message}}


func abandon_occupied_region(civ_id:String,region_id:String)->Dictionary:
	var index:=_civilization_index(civ_id)
	if index<0: return {"error":"Unknown civilization."}
	var restoration:=_restore_region_to_rival(civilizations[index],region_id)
	var outcome:Dictionary=restoration.get("outcome",{})
	if not bool(outcome.get("region_recaptured",false)): return {"error":"The selected region is not under player occupation."}
	civilizations[index]=restoration.civilization
	_rebuild_competition()
	world_changed.emit(competition_snapshot())
	return outcome


func _compact_number(value:float)->String:
	if value>=1_000_000_000.0: return "%.2fB" % (value/1_000_000_000.0)
	if value>=1_000_000.0: return "%.2fM" % (value/1_000_000.0)
	if value>=1_000.0: return "%.1fK" % (value/1_000.0)
	return str(roundi(value))


func resolve_player_incident(civ_id:String,response:String,details:Dictionary={})->void:
	var index:=_civilization_index(civ_id)
	if index<0: return
	var civ:Dictionary=civilizations[index]
	var relation:Dictionary=_relation_with_strategy_defaults(civ.player_relation,civ)
	match response:
		"tribute":
			relation["war_score"]=clampf(float(relation.get("war_score",0.0))-8.0,-100.0,100.0)
			relation["player_war_exhaustion"]=clampf(float(relation.get("player_war_exhaustion",0.0))+0.035,0.0,1.0)
			relation["opinion"]=clampf(float(relation.opinion)+0.02,-1.0,1.0)
			var food_received:=maxf(0.0,float(details.get("food",0.0)))
			civ["food_days"]=clampf(float(civ.food_days)+food_received/maxf(1.0,float(civ.population)),0.0,180.0)
			civ["production"]=clampf(float(civ.production)+minf(0.002,food_received/maxf(1.0,float(civ.population))*0.002),0.0,1.0)
		"withdraw":
			relation["war_score"]=clampf(float(relation.get("war_score",0.0))-12.0,-100.0,100.0)
			relation["player_war_exhaustion"]=clampf(float(relation.get("player_war_exhaustion",0.0))+0.055,0.0,1.0)
			var transfer:=minf(0.008,maxf(0.0,_player_territory()-0.08))
			civ["territory"]=float(civ.territory)+transfer
			player_territory_balance-=transfer
			var resources:Dictionary=details.get("resources",{})
			var food_received:=maxf(0.0,float(resources.get("Food",0.0)))
			var material_received:=0.0
			for resource_name in resources:
				if String(resource_name)!="Food": material_received+=maxf(0.0,float(resources[resource_name]))
			civ["food_days"]=clampf(float(civ.food_days)+food_received/maxf(1.0,float(civ.population)),0.0,180.0)
			civ["production"]=clampf(float(civ.production)+minf(0.004,material_received/maxf(1.0,float(civ.population))*0.004),0.0,1.0)
			relation["border_tension"]=clampf(float(relation.border_tension)+0.04,0.0,1.0)
	civ["player_relation"]=relation
	civilizations[index]=civ
	_rebuild_competition()


func player_population_commitments()->Dictionary:
	initialize()
	var records:Array[Dictionary]=[]
	var by_function:Dictionary={"productive":0,"support":0,"mobilized":0,"dependent":0}
	var mobilization:Dictionary={"total":int(GameState.population_allocations.get("Defense",0)),"allocated_defense":int(GameState.population_allocations.get("Defense",0)),"excess_beyond_defense":0,"records":[],"bounded":true}
	var military_campaign:Node=null
	var tree:=Engine.get_main_loop() as SceneTree
	if tree and tree.root: military_campaign=tree.root.get_node_or_null("MilitaryCampaign")
	if military_campaign!=null and military_campaign.has_method("population_commitment_snapshot"):
		mobilization=military_campaign.population_commitment_snapshot()
	for mission_variant in scout_missions:
		var mission:Dictionary=mission_variant
		var scouts:=maxi(0,int(mission.get("personnel",0)))
		if scouts>0:
			by_function.productive=int(by_function.productive)+scouts
			records.append({"id":"scout_party_%d" % int(mission.get("mission_id",0)),"label":"SCOUT PARTY","kind":"scouting","personnel":scouts,"depart_day":int(mission.get("start_day",GameState.elapsed_days)),"return_day":int(mission.get("return_day",GameState.elapsed_days)),"source":"productive"})
	var missing_scouts:=_captured_player_scout_count()
	if missing_scouts>0:
		by_function.productive=int(by_function.productive)+missing_scouts
		records.append({"id":"missing_scouts","label":"SCOUTS CAPTURED OR MISSING","kind":"scouting","personnel":missing_scouts,"source":"productive"})
	if not diplomatic_mission.is_empty():
		var envoys:=maxi(0,int(diplomatic_mission.get("personnel",0)))
		if envoys>0:
			by_function.support=int(by_function.support)+envoys
			records.append({"id":"diplomatic_mission","label":"DIPLOMATIC MISSION","kind":"diplomacy","personnel":envoys,"depart_day":int(diplomatic_mission.get("depart_day",GameState.elapsed_days)),"return_day":int(diplomatic_mission.get("return_day",GameState.elapsed_days)),"source":"support"})
	if bool(GameState.settlement_convoy.get("active",false)):
		var convoy_population:=maxi(0,int(GameState.settlement_convoy.get("population",0)))
		var convoy_sources:Dictionary=GameState.settlement_convoy.get("population_sources",{})
		if convoy_sources.is_empty(): convoy_sources=GameState.proportional_population_commitment(convoy_population)
		for function_id in ["productive","support","mobilized","dependent"]:
			by_function[function_id]=int(by_function.get(function_id,0))+maxi(0,int(convoy_sources.get(function_id,0)))
		if convoy_population>0:
			records.append({"id":"settlement_convoy","label":"SETTLEMENT CONVOY","kind":"settlement_convoy","personnel":convoy_population,"depart_day":int(GameState.settlement_convoy.get("depart_day",GameState.elapsed_days)),"return_day":int(GameState.settlement_convoy.get("arrival_day",GameState.elapsed_days)),"source":"mixed","by_function":convoy_sources.duplicate(true)})
	var survivors:Dictionary=MilitaryCampaign.recovery.absent_group()
	if not survivors.is_empty():
		var sources:Dictionary=survivors.get("functions",{})
		for function_id in by_function:by_function[function_id]=int(by_function[function_id])+int(sources.get(function_id,0))
		records.append({"id":"siege_survivors","label":"SIEGE SURVIVORS","kind":"siege_recovery","personnel":int(survivors.people),"source":"mixed","by_function":sources.duplicate(true)})
	var total_absent:=0
	var working_absent:=0
	for function_id in ["productive","support","mobilized","dependent"]:
		var amount:=maxi(0,int(by_function.get(function_id,0)))
		total_absent+=amount
		if function_id!="dependent": working_absent+=amount
	return {
		"total_absent":total_absent,"working_absent":working_absent,"by_function":by_function,
		"records":records,"working_absence_ratio":clampf(float(working_absent)/maxf(1.0,float(GameState.able_population())),0.0,1.0),
		"mobilized_total":maxi(int(GameState.population_allocations.get("Defense",0)),int(mobilization.get("total",0))),"mobilization":mobilization,
		"bounded":true
	}


func player_population_function_profile()->Dictionary:
	return GameState.population_function_profile(player_population_commitments())


func mission_absent_personnel()->int:
	## Headcount physically away on civil missions (scouts, envoys, convoys).
	## Military field forces are accounted separately by the campaign layer.
	return maxi(0,int(player_population_commitments().get("total_absent",0)))


func player_effects()->Dictionary:
	initialize()
	var active_trade:=0
	var trade_volume:=0.0
	var war_count:=0
	var active_war_exhaustion:=0.0
	var hostile_pressure:=0.0
	var treaty_count:=0
	var occupied_regions:=0
	var occupied_population:=0.0
	var resistance_load:=0.0
	var integrated_market_bonus:=0.0
	var occupied_production_bonus:=0.0
	var occupation_relief_demand:=0.0
	var occupation_food_transfer:=0.0
	for civ in civilizations:
		var relation:Dictionary=civ.player_relation
		if String(relation.get("treaty","none"))=="trade" and not bool(relation.get("at_war",false)):
			active_trade+=1; trade_volume+=float(relation.get("trade",0.0))
		if String(relation.get("treaty","none"))=="non_aggression": treaty_count+=1
		if bool(relation.get("at_war",false)):
			war_count+=1
			active_war_exhaustion+=float(relation.get("player_war_exhaustion",0.0))
		hostile_pressure+=float(relation.get("border_tension",0.0))*(1.0 if bool(relation.get("at_war",false)) else 0.22)
		for region_variant in civ.get("strategic_regions",[]):
			var region:Dictionary=region_variant
			if String(region.get("controller",String(civ.id)))!="player": continue
			occupied_regions+=1
			var region_population:=float(region.get("population",0.0))
			var resistance:=float(region.get("resistance",0.0))
			var integration:=float(region.get("integration",0.0))
			var governance:=OCCUPATION_GOVERNANCE.state(region)
			var extraction:=float(OCCUPATION_GOVERNANCE.policy(region).extraction)
			var control:=occupation_control(String(civ.id),String(region.id))
			var function:=(integration*.7+extraction*.3)*(1.0-float(region.get("damage",0.0)))*(.4+.6*float(governance.welfare))*(1.0 if bool(control.get("controlled",false)) else 0.0)
			var damage:=float(region.get("damage",0.0))
			occupied_population+=region_population
			resistance_load+=region_population*resistance
			# Occupied civilians mostly provision themselves. Only disruption creates
			# a central relief obligation; an integrated granary can send a bounded
			# surplus back through the player's logistics network.
			occupation_relief_demand+=region_population*0.035*(resistance+damage+float(governance.inequality)*.25)*(1.0-integration*0.50)
			if String(region.get("role",""))=="granary": occupation_food_transfer+=region_population*0.025*function*(1.0-resistance)
			if String(region.get("role",""))=="market": integrated_market_bonus+=0.035*function
			if String(region.get("role",""))=="works": occupied_production_bonus+=0.045*function
	var community_effects:Dictionary=MilitaryCampaign.occupation_transfers.effects()
	var occupation_burden:=clampf(resistance_load/maxf(1.0,GameState.population_exact+occupied_population)+float(community_effects.grievance)*.4+float(community_effects.inequality)*.3,0.0,1.0)
	var war_exhaustion:=clampf(active_war_exhaustion/maxf(1.0,float(war_count)),0.0,1.0) if war_count>0 else 0.0
	var commitments:=player_population_commitments()
	var scout_personnel:=float(_captured_player_scout_count())
	for mission_variant in scout_missions: scout_personnel+=float((mission_variant as Dictionary).get("personnel",0.0))
	var scout_labor_absence:=clampf(scout_personnel/maxf(1.0,float(GameState.able_population())),0.0,0.45)
	var mobilization_excess:=maxi(0,int((commitments.mobilization as Dictionary).get("excess_beyond_defense",0)))
	var labor_unavailable:=maxi(0,int(commitments.working_absent))+mobilization_excess
	return {"active_trade_partners":active_trade,"trade_volume":trade_volume,"market_access_bonus":clampf(float(active_trade)*0.055+minf(0.08,trade_volume/maxf(1.0,GameState.population_exact)*0.08)+integrated_market_bonus,0.0,0.34),"knowledge_exchange":clampf(float(active_trade)*0.012,0.0,0.10),"treaty_count":treaty_count,"war_count":war_count,"war_exhaustion":war_exhaustion,"hostile_pressure":clampf(hostile_pressure/maxf(1.0,float(civilizations.size()))+occupation_burden*0.22+war_exhaustion*0.16,0.0,1.0),"security_support":clampf(float(treaty_count)*0.012,0.0,0.08),"occupied_regions":occupied_regions,"occupied_population":occupied_population,"occupation_burden":occupation_burden,"occupation_relief_demand":occupation_relief_demand,"occupation_food_transfer":occupation_food_transfer,"occupied_production_bonus":occupied_production_bonus,"scout_personnel":scout_personnel,"scout_labor_absence":scout_labor_absence,"population_commitments":commitments,"population_absent":int(commitments.total_absent),"mobilization_labor_displacement":mobilization_excess,"labor_unavailable":labor_unavailable,"labor_absence":clampf(float(labor_unavailable)/maxf(1.0,float(GameState.able_population())),0.0,1.0)}


func competition_snapshot()->Dictionary:
	initialize()
	var contenders:Array[Dictionary]=[]
	var player:=_player_profile()
	contenders.append(player)
	for civ in civilizations:
		var profile:=_public_profile(civ)
		profile["score"]=_score_values(profile)
		profile["score_breakdown"]=_score_breakdown(profile)
		contenders.append(profile)
	contenders.sort_custom(func(a:Dictionary,b:Dictionary)->bool: return float(a.score)>float(b.score))
	var player_rank:=1
	for index in contenders.size():
		contenders[index]["rank"]=index+1
		if String(contenders[index].id)=="player": player_rank=index+1
	var leader:Dictionary=contenders[0] if not contenders.is_empty() else player
	var domains:=_domain_leaders(contenders)
	for index in contenders.size():
		var profile:Dictionary=contenders[index]
		var domains_led:=_domains_led_by(String(profile.id),domains)
		var margin:=_lead_margin_for(String(profile.id),contenders)
		var requirements:=_victory_requirements(profile,int(profile.rank),domains_led,margin)
		profile["domains_led"]=domains_led
		profile["lead_margin"]=margin
		profile["victory_requirements"]=requirements
		profile["dominance_turns"]=int(contender_dominance_turns.get(String(profile.id),0))
		contenders[index]=profile
		if String(profile.id)=="player": player=profile
	leader=contenders[0] if not contenders.is_empty() else player
	var player_domains:=int(player.get("domains_led",0))
	var lead_margin:=float(player.get("lead_margin",0.0))
	var basics:Dictionary=(player.get("victory_requirements",{}) as Dictionary).get("sustainability",{})
	var basics_fraction:=float(basics.get("met_count",0))/maxf(1.0,float(basics.get("total_count",4)))
	var progress:=clampf(float(player_domains)/4.0*0.48+(1.0/float(player_rank))*0.19+clampf((lead_margin-0.75)/0.35,0.0,1.0)*0.13+basics_fraction*0.20,0.0,1.0)
	return {"day":int(GameState.elapsed_days),"player_rank":player_rank,"contender_count":contenders.size(),"leader":leader,"leaders":contenders,"domain_leaders":domains,"player_domains_led":player_domains,"lead_margin":lead_margin,"victory_progress":progress,"dominance_turns":dominance_turns,"collapse_turns":collapse_turns,"outcome":competition_outcome,"winner_id":competition_winner_id,"victory_rule":"After Year 20, any contender must meet the same sustainability floor, lead overall by 10%, and lead at least four strategic domains out of seven for twelve consecutive strategic turns.","defeat_rule":"Another contender meeting that rule first, or player systemic collapse for twelve strategic turns, is defeat."}


func strategic_knowledge_snapshot()->Dictionary:
	var contacted_count:=0
	for civ in civilizations:
		if int((civ.get("player_relation",{}) as Dictionary).get("contact_level",0))>=2: contacted_count+=1
	var adoption:Dictionary={}
	for discovery_id in ["tallies","standard_measures","census_rolls","statistical_inference"]:
		adoption[discovery_id]=clampf(float(GameState.discovery_adoption.get(discovery_id,0.0)),0.0,1.0) if discovery_id in GameState.known_discoveries else 0.0
	var stage:=0
	if float(adoption.tallies)>=0.20: stage=1
	if float(adoption.standard_measures)>=0.25: stage=2
	if float(adoption.census_rolls)>=0.30 and contacted_count>=2: stage=3
	if float(adoption.statistical_inference)>=0.35 and contacted_count>=4: stage=4
	var known_domains:Array[String]=[]
	if stage>=2: known_domains.assign(["population","production","logistics","resilience"])
	if stage>=3: known_domains.assign(SCORE_DOMAINS)
	var stage_title:=String([
		"NO COMPARATIVE FRAMEWORK",
		"QUANTITIES CAN BE RECORDED",
		"SEVERAL CAPACITIES CAN BE COMPARED",
		"A CIVILIZATIONAL FRAMEWORK HAS EMERGED",
		"THE BALANCE OF POWER CAN BE ESTIMATED"
	][stage])
	var summary:=String([
		"Your people know immediate conditions, but possess no general theory of civilizational power. No domains, score, rank, or global victory rule are known.",
		"Tallies preserve quantities, but they do not yet establish which capacities define power or how different societies should be compared.",
		"Shared measures reveal several recurring capacities. They are observations so far—not a complete list of domains and not a global ranking.",
		"Census records and repeated foreign contact support a seven-part model of civilizational power. Exact scores and victory thresholds remain unproven.",
		"Statistical comparison and broad contact now support estimated scores, known-world ranks, and the formal long-term victory conditions."
	][stage])
	var next_step:=String([
		"Repeated material tallies may make quantities comparable over time.",
		"Shared measures could make records from different places comparable.",
		"Census records and wider foreign contact may reveal a broader structure of power.",
		"Broader contact and statistical inference may turn the framework into a defensible comparison.",
		"No further scoring knowledge is currently hidden; unknown civilizations can still change every estimate."
	][stage])
	return {"stage":stage,"title":stage_title,"summary":summary,"next_step":next_step,"known_domains":known_domains,"framework_known":stage>=3,"total_domains":SCORE_DOMAINS.size() if stage>=3 else -1,"exact_scoring_known":stage>=4,"victory_structure_known":stage>=3,"victory_thresholds_known":stage>=4,"contacted_count":contacted_count,"adoption":adoption}


func known_competition_snapshot()->Dictionary:
	var full:=competition_snapshot()
	var strategic_knowledge:=strategic_knowledge_snapshot()
	var visible:Array[Dictionary]=[]
	for contender:Dictionary in full.leaders:
		if String(contender.id)=="player":
			var own:=contender.duplicate(true)
			for key in ["rank","known_rank","domains_led","lead_margin","victory_requirements","dominance_turns"]: own.erase(key)
			if not bool(strategic_knowledge.exact_scoring_known):
				own.erase("score"); own.erase("score_breakdown")
			visible.append(own)
		elif int(contender.get("player_relation",{}).get("contact_level",0))>=2:
			visible.append(_redact_known_foreign_profile(contender))
	# Knowing how to calculate a score does not supply other nations' census.
	# Alphabetical order must not reveal a hidden live ranking either.
	visible.sort_custom(func(a:Dictionary,b:Dictionary)->bool: return String(a.name)<String(b.name))
	var public_domains:Dictionary={}
	if bool(strategic_knowledge.framework_known):
		for domain in strategic_knowledge.known_domains: public_domains[String(domain)]=""
	return {"day":int(full.day),"player_rank":-1,"contender_count":visible.size(),"contacted_count":maxi(0,visible.size()-1),"leader":{},"leaders":visible,"domain_leaders":public_domains,"player_domains_led":-1,"victory_progress":-1.0,"dominance_turns":-1,"collapse_turns":collapse_turns,"outcome":competition_outcome,"winner_id":competition_winner_id if competition_outcome!="ongoing" else "","victory_rule":String(full.victory_rule) if bool(strategic_knowledge.victory_thresholds_known) else "No formal global victory condition has been established by your civilization.","defeat_rule":String(full.defeat_rule) if bool(strategic_knowledge.victory_thresholds_known) else "Distant paths to supremacy or collapse remain unknown.","global_rank_hidden":true,"strategic_knowledge":strategic_knowledge,"exploration":exploration_status()}


func _redact_known_foreign_profile(profile:Dictionary)->Dictionary:
	var visible:=profile.duplicate(true)
	var cities:Array[Dictionary]=city_intelligence.known_cities("player",String(profile.id))
	for key in ["population","controlled_population","occupied_population","foreign_controlled_population","cohorts","births_last_turn","deaths_last_turn","population_estimate_low","population_estimate_high","military_population","military_estimate_low","military_estimate_high","score","score_breakdown","rank","known_rank","domains_led","lead_margin","victory_requirements","dominance_turns","societal_identity","research_profile","progression_tiers","wars","trade_total","war_opponents"]: visible.erase(key)
	for key in ["health","cohesion","knowledge","production","logistics","institutions","ecology","military_readiness","command_readiness","food_days","territory","home_control","relative_military_power","military_replacement_coverage","world_reach"]: visible[key]=-1.0
	for key in ["military_era_tier","military_production_lines","training_cycles","home_regions_controlled","home_regions_total","diplomatic_partners","diplomatic_rivals"]: visible[key]=-1
	visible["training_focus"]="unknown"; visible["military_era"]="unknown"; visible["strategic_status"]="PARTIALLY OBSERVED"
	visible["founding_focus"]=String(profile.get("founding_focus","unknown")) if float(profile.get("intel_confidence",0))>=0.58 else "unknown"
	visible["rival_intent"]="Unconfirmed beyond dated reports"; visible["threat_level"]="UNCERTAIN"
	visible["strategic_regions"]=city_intelligence.public_regions(String(profile.id))
	visible["population_scope"]="observed cities only; not a national census"
	for city:Dictionary in cities:
		for field:String in ["population","garrison"]:
			var estimate:Dictionary=city.fields.get(field,{})
			if estimate.is_empty(): continue
			var prefix:="population" if field=="population" else "military"
			for bound:String in ["low","high"]:
				var key:=prefix+"_estimate_"+bound
				visible[key]=float(visible.get(key,0))+float(estimate[bound])
	var relation:Dictionary=visible.get("player_relation",{})
	for key in relation.keys():
		if String(key).begins_with("rival_player_") or key in ["rival_contact_level","rival_met_day"]: relation.erase(key)
	return visible


func _rebuild_competition(advance_outcome:bool=false,evaluation_day:int=-1)->void:
	var snapshot_data:=competition_snapshot() if not civilizations.is_empty() else {}
	if snapshot_data.is_empty(): return
	for contender in snapshot_data.leaders:
		if String(contender.id)=="player": continue
		var score_index:=_civilization_index(String(contender.id))
		if score_index>=0:
			civilizations[score_index]["score"]=float(contender.score)
			civilizations[score_index]["rank"]=int(contender.rank)
	if advance_outcome and competition_outcome=="ongoing":
		var outcome_day:=evaluation_day if evaluation_day>=0 else int(GameState.elapsed_days)
		for contender_variant in snapshot_data.leaders:
			var contender:Dictionary=contender_variant
			var requirements:Dictionary=contender.get("victory_requirements",{})
			var qualifying:=outcome_day>=20*365 and bool(requirements.get("currently_qualifies",false))
			var contender_id:=String(contender.id)
			contender_dominance_turns[contender_id]=int(contender_dominance_turns.get(contender_id,0))+1 if qualifying else 0
		dominance_turns=int(contender_dominance_turns.get("player",0))
		var effects:=player_effects()
		var collapsing:=GameState.population_health<0.12 and GameState.food_security<0.12 and float(GameState.simulation_metrics.get("legitimacy",0.62))<0.12 and float(effects.hostile_pressure)>0.35
		collapse_turns=collapse_turns+1 if collapsing and not MilitaryCampaign.recovery.has_active_occupation() and MilitaryCampaign.recovery.data.remnant.is_empty() else 0
		var winning_id:=""
		for contender_id in contender_dominance_turns:
			if int(contender_dominance_turns[contender_id])>=12: winning_id=String(contender_id); break
		if winning_id!="":
			competition_winner_id=winning_id
			competition_outcome="victory" if winning_id=="player" else "defeat"
		elif collapse_turns>=12:
			competition_winner_id="collapse"
			competition_outcome="defeat"


func _player_profile()->Dictionary:
	var effects:=player_effects()
	var military_count:=0.0
	if MilitaryCampaign!=null:
		# Untrained recruits contribute only partial strategic capacity; this keeps
		# the competitive military domain from being farmed by mobilizing a number
		# that has not yet become a field formation.
		military_count=float(MilitaryCampaign.home_army.get("troops",0))+float(MilitaryCampaign._queued_trainees())*0.65+float(MilitaryCampaign.aggregate_recruits)*0.35
	var territory:=_player_territory()
	var player_readiness:=clampf(float(MilitaryCampaign.home_army.get("readiness",GameState.simulation_metrics.get("security",0.38))),0.0,1.0) if MilitaryCampaign!=null else clampf(float(GameState.simulation_metrics.get("security",0.38)),0.0,1.0)
	var player_commander:Dictionary=MilitaryCampaign.home_army.get("commander",{}) if MilitaryCampaign!=null else {}
	var player_command_readiness:=clampf((float(player_commander.get("command",0.4))+float(player_commander.get("tactics",0.4))+float(player_commander.get("logistics",0.4))+float(player_commander.get("resolve",0.4)))/4.0,0.0,1.0)
	var player_military_tier:=int(MilitaryCampaign.military_development_snapshot().get("tier",0)) if MilitaryCampaign!=null and MilitaryCampaign.has_method("military_development_snapshot") else 0
	var profile:={"id":"player","name":_player_civilization_name(),"population":GameState.population_exact,"controlled_population":GameState.population_exact+float(effects.occupied_population),"knowledge":clampf(GameState.combined_intelligence,0.0,1.0),"production":clampf(float(GameState.simulation_metrics.get("material_capacity",0.12))+float(effects.occupied_production_bonus),0.0,1.0),"logistics":clampf(float(GameState.simulation_metrics.get("logistics",0.16)),0.0,1.0),"health":GameState.population_health,"cohesion":clampf(float(GameState.simulation_metrics.get("cohesion",0.58))-float(effects.occupation_burden)*0.12,0.0,1.0),"institutions":clampf(float(GameState.society_capacities.get("institutions",0.25))-float(effects.occupation_burden)*0.18,0.0,1.0),"territory":territory,"military_population":military_count,"military_readiness":player_readiness,"command_readiness":player_command_readiness,"military_era_tier":player_military_tier,"military_replacement_coverage":1.0-float(MilitaryCampaign._equipment_backlog_work())/maxf(1.0,float(MilitaryCampaign._equipment_backlog_work())+float(military_count)),"food_days":float(GameState.simulation_metrics.get("food_days",30.0)),"strategy":"PLAYER ORDERS","founding_focus":GameState.founding_focus,"foreign_effects":effects}
	var player_progression:Dictionary={}
	for domain in ProgressionSystem.domains(): player_progression[domain]=ProgressionSystem.domain_tier(domain)
	profile["progression_tiers"]=player_progression
	profile["world_reach"]=float(progression_reach_snapshot().combined)
	profile["score_breakdown"]=_score_breakdown(profile)
	profile["score"]=_score_values(profile)
	return profile


func _player_territory_base()->float:
	return maxf(0.12,float(GameState.settlement_plots.size())/24.0+float(GameState.settlement_nuclei.size())*0.35)


func _player_territory()->float:
	return maxf(0.08,_player_territory_base()+player_territory_balance)


func _public_profile(civ:Dictionary)->Dictionary:
	var control:=_region_control_effects(civ)
	var home_status:=_home_control_status(civ)
	var occupied_population:=0.0
	for region_variant in civ.get("strategic_regions",[]):
		var region:Dictionary=region_variant
		if String(region.get("controller",String(civ.id)))!="%s" % String(civ.id): occupied_population+=float(region.get("population",0.0))
	var foreign_controlled_population:=0.0
	for other_civ in civilizations:
		if String(other_civ.id)==String(civ.id): continue
		for region_variant in other_civ.get("strategic_regions",[]):
			var region:Dictionary=region_variant
			if String(region.get("controller",""))==String(civ.id): foreign_controlled_population+=float(region.get("population",0.0))
	var home_regions_controlled:=int(home_status.controlled)
	var strategic_status:="SOVEREIGN" if home_regions_controlled==STRATEGIC_REGIONS_PER_CIV else ("CAPITAL LOST" if not bool(home_status.capital_controlled) else "CONTESTED")
	var relation:=_relation_with_strategy_defaults(civ.player_relation,civ)
	var relative_power:=_military_power(civ)/maxf(1.0,_player_military_power())
	var network:=_diplomatic_network(civ)
	var intelligence:=clampf(float(relation.get("contact_intelligence",0.0)),0.0,1.0)
	var estimate_error:=lerpf(0.42,0.04,intelligence)
	var controlled_population:=maxf(1.0,float(civ.population)-occupied_population+foreign_controlled_population)
	var military_population:=float(civ.military_population)*float(control.home_control)
	var assessment_known:=intelligence>=0.32 or bool(relation.get("at_war",false))
	return {"id":String(civ.id),"name":String(civ.name),"population":float(civ.population),"controlled_population":controlled_population,"occupied_population":occupied_population,"foreign_controlled_population":foreign_controlled_population,"population_estimate_low":maxf(1.0,controlled_population*(1.0-estimate_error)),"population_estimate_high":controlled_population*(1.0+estimate_error),"cohorts":civ.cohorts.duplicate(true),"knowledge":float(civ.knowledge)*float(control.knowledge_factor),"production":float(civ.production)*float(control.production_factor),"logistics":float(civ.logistics)*float(control.logistics_factor),"health":float(civ.health),"cohesion":float(civ.cohesion),"institutions":float(civ.institutions)*float(control.institutions_factor),"territory":float(civ.territory),"military_population":military_population,"military_estimate_low":maxf(0.0,military_population*(1.0-estimate_error)),"military_estimate_high":military_population*(1.0+estimate_error),"military_readiness":float(civ.military_readiness),"command_readiness":float(civ.get("command_readiness",0.4)),"military_era_tier":int(civ.get("military_era_tier",0)),"military_era":String(civ.get("military_era","founding")),"military_production_lines":int(civ.get("military_production_lines",1)),"military_replacement_coverage":float(civ.get("military_replacement_coverage",0.5)),"training_focus":String(civ.get("training_focus","camp_drill")),"training_cycles":int(civ.get("training_cycles",0)),"founding_focus":String(civ.get("founding_focus","provision")),"food_days":float(civ.food_days),"strategy":String(civ.strategy),"score":float(civ.score),"rank":int(civ.rank),"player_relation":relation,"intel_confidence":intelligence,"strategic_regions":_public_regions(civ),"home_regions_controlled":home_regions_controlled,"home_regions_total":STRATEGIC_REGIONS_PER_CIV,"strategic_status":strategic_status,"home_control":float(control.home_control),"wars":_war_count(civ),"trade_total":float(civ.trade_total),"births_last_turn":float(civ.get("births_last_turn",0.0)),"deaths_last_turn":float(civ.get("deaths_last_turn",0.0)),"relative_military_power":relative_power,"rival_intent":_rival_intent(civ,relation,relative_power) if assessment_known else "Insufficient returned intelligence","threat_level":_threat_level(civ,relation,relative_power) if assessment_known else "UNCERTAIN","diplomatic_partners":int(network.partners) if intelligence>=0.48 else -1,"diplomatic_rivals":int(network.rivals) if intelligence>=0.48 else -1,"war_opponents":network.war_opponents if intelligence>=0.48 else [],"societal_identity":SOCIETAL_VALUES_MODEL.identity_snapshot(civ.get("societal_values",{})) if intelligence>=0.58 else {},"progression_tiers":(civ.get("progression_tiers",{}) as Dictionary).duplicate(true) if intelligence>=0.70 else {},"research_profile":_public_rival_research_profile(civ) if intelligence>=0.70 else {},"world_reach":float(civ.get("world_reach",0.0)) if intelligence>=0.70 else -1.0}


func _public_rival_research_profile(civ:Dictionary)->Dictionary:
	var profile:Dictionary=civ.get("discovery_profile",{})
	var result:Dictionary={"technologies":(profile.get("technologies",[]) as Array).duplicate(),"latest_technology":String(profile.get("latest_technology","")),"domains":{},"emphasis":{},"research_workforce":float(profile.get("research_workforce",0.0)),"research_capacity":float(profile.get("research_capacity",0.0)),"research_slots":int(profile.get("research_slots",0))}
	for domain in (profile.get("domains",{}) as Dictionary):
		var record:Dictionary=(profile.domains as Dictionary)[domain]
		result.domains[domain]={"count":int(record.get("count",0)),"maturity":int(record.get("maturity",0)),"breadth":int(record.get("breadth",0)),"specialty":String(record.get("specialty","")),"tradition":String(record.get("tradition",""))}
	for domain in (profile.get("emphasis",{}) as Dictionary): result.emphasis[domain]=float(profile.emphasis[domain])
	return result


func _public_regions(civ:Dictionary)->Array[Dictionary]:
	return city_intelligence.public_regions(String(civ.id))


func civilization_snapshot(civ_id:String)->Dictionary:
	initialize()
	for contender in competition_snapshot().leaders:
		if String(contender.id)==civ_id: return (contender as Dictionary).duplicate(true)
	return {}


func known_civilization_snapshot(civ_id:String)->Dictionary:
	var index:=_civilization_index(civ_id)
	if index<0 or int((civilizations[index].get("player_relation",{}) as Dictionary).get("contact_level",0))<2: return {}
	for contender in known_competition_snapshot().leaders:
		if String(contender.id)==civ_id: return (contender as Dictionary).duplicate(true)
	return {}


func _domain_leaders(contenders:Array[Dictionary])->Dictionary:
	var leaders:Dictionary={}
	for domain in SCORE_DOMAINS:
		var best_id:=""
		var best_value:=-INF
		for contender in contenders:
			var breakdown:Dictionary=contender.get("score_breakdown",_score_breakdown(contender))
			var value:=float(breakdown.get(domain,0.0))
			if value>best_value: best_value=value; best_id=String(contender.id)
		leaders[domain]=best_id
	return leaders


func _domains_led_by(contender_id:String,leaders:Dictionary)->int:
	var total:=0
	for domain in leaders:
		if String(leaders[domain])==contender_id: total+=1
	return total


func _lead_margin_for(contender_id:String,contenders:Array[Dictionary])->float:
	var own_score:=0.0
	var strongest_other:=0.0
	for contender in contenders:
		if String(contender.id)==contender_id: own_score=float(contender.score)
		else: strongest_other=maxf(strongest_other,float(contender.score))
	return own_score/maxf(0.001,strongest_other)


func _victory_requirements(profile:Dictionary,rank:int,domains_led:int,lead_margin:float)->Dictionary:
	var checks:Dictionary={
		"food":{"label":"Food reserve","value":float(profile.get("food_days",0.0)),"required":VICTORY_FOOD_DAYS,"unit":"days"},
		"health":{"label":"Health","value":float(profile.get("health",0.0)),"required":VICTORY_HEALTH,"unit":"ratio"},
		"cohesion":{"label":"Cohesion","value":float(profile.get("cohesion",0.0)),"required":VICTORY_COHESION,"unit":"ratio"},
		"institutions":{"label":"Institutions","value":float(profile.get("institutions",0.0)),"required":VICTORY_INSTITUTIONS,"unit":"ratio"}
	}
	var met:=0
	for key in checks:
		var check:Dictionary=checks[key]
		check["met"]=float(check.value)>=float(check.required)
		if bool(check.met): met+=1
		checks[key]=check
	var sustainable:=met==checks.size()
	return {"sustainability":{"checks":checks,"met_count":met,"total_count":checks.size(),"met":sustainable},"rank":{"value":rank,"required":1,"met":rank==1},"domains":{"value":domains_led,"required":4,"met":domains_led>=4},"lead_margin":{"value":lead_margin,"required":1.10,"met":lead_margin>=1.10},"currently_qualifies":sustainable and rank==1 and domains_led>=4 and lead_margin>=1.10}


func _score_for_civilization(civ:Dictionary)->float:
	var profile:=_public_profile(civ)
	return _score_values(profile)


func _score_values(profile:Dictionary)->float:
	var breakdown:=_score_breakdown(profile)
	var total:=0.0
	for domain in SCORE_DOMAINS: total+=float(breakdown.get(domain,0.0))
	return total/float(SCORE_DOMAINS.size())


func _score_breakdown(profile:Dictionary)->Dictionary:
	var controlled_population:=maxf(0.0,float(profile.get("controlled_population",profile.get("population",0.0))))
	var knowledge:=clampf(float(profile.get("knowledge",0.0)),0.0,1.0)
	var production:=clampf(float(profile.get("production",0.0)),0.0,1.0)
	var logistics:=clampf(float(profile.get("logistics",0.0)),0.0,1.0)
	var health:=clampf(float(profile.get("health",0.0)),0.0,1.0)
	var cohesion:=clampf(float(profile.get("cohesion",0.0)),0.0,1.0)
	var institutions:=clampf(float(profile.get("institutions",0.0)),0.0,1.0)
	var food_security:=clampf(float(profile.get("food_days",0.0))/90.0,0.0,1.0)
	var military_population:=maxf(0.0,float(profile.get("military_population",0.0)))
	var readiness:=clampf(float(profile.get("military_readiness",0.0)),0.0,1.0)
	var command_readiness:=clampf(float(profile.get("command_readiness",0.4)),0.0,1.0)
	var era_factor:=1.0+maxf(0.0,float(profile.get("military_era_tier",0)))*0.07
	var replacement_coverage:=clampf(float(profile.get("military_replacement_coverage",0.5)),0.0,1.0)
	var military_power:=military_population*(0.28+readiness*0.72)*(0.82+command_readiness*0.18)*(0.75+production*0.15+knowledge*0.10)*era_factor*(0.72+replacement_coverage*0.28)
	var resilience:=health*0.30+cohesion*0.25+institutions*0.20+food_security*0.25
	return {
		"population":clampf(log(1.0+controlled_population)/log(1000000001.0),0.0,1.0)*100.0,
		"knowledge":knowledge*100.0,
		"production":production*100.0,
		"logistics":logistics*100.0,
		"military":clampf(log(1.0+military_power)/log(100000001.0),0.0,1.0)*100.0,
		"resilience":resilience*100.0,
		"territory":clampf(sqrt(maxf(0.0,float(profile.get("territory",0.0)))/4.0),0.0,1.0)*100.0
	}


func _military_power(civ:Dictionary)->float:
	var era_factor:=1.0+float(civ.get("military_era_tier",0))*0.07
	var equipment_coverage:=clampf(float(civ.get("military_replacement_coverage",0.5)),0.0,1.0)
	return maxf(1.0,float(civ.military_population)*(0.28+float(civ.military_readiness)*0.72)*(0.82+float(civ.get("command_readiness",0.4))*0.18)*(0.75+float(civ.production)*0.15+float(civ.knowledge)*0.10)*era_factor*(0.72+equipment_coverage*0.28))


func _player_military_power()->float:
	var fielded:=float(MilitaryCampaign.home_army.get("troops",0)) if MilitaryCampaign!=null else 0.0
	var recruits:=float(MilitaryCampaign.aggregate_recruits) if MilitaryCampaign!=null else 0.0
	var trainees:=float(MilitaryCampaign._queued_trainees()) if MilitaryCampaign!=null else 0.0
	var readiness:=float(MilitaryCampaign.home_army.get("readiness",GameState.simulation_metrics.get("security",0.38))) if MilitaryCampaign!=null else float(GameState.simulation_metrics.get("security",0.38))
	var commander:Dictionary=MilitaryCampaign.home_army.get("commander",{}) if MilitaryCampaign!=null else {}
	var command_factor:=0.88+clampf(float(commander.get("command",0.4)),0.0,1.0)*0.12
	var era_tier:=int(MilitaryCampaign.military_development_snapshot().get("tier",0)) if MilitaryCampaign!=null and MilitaryCampaign.has_method("military_development_snapshot") else 0
	return maxf(1.0,(fielded+trainees*0.65+recruits*0.35)*(0.28+clampf(readiness,0.0,1.0)*0.72)*command_factor*(1.0+float(era_tier)*0.07))


func _war_count(civ:Dictionary)->int:
	var total:=0
	for relation in (civ.get("relations",{}) as Dictionary).values():
		if bool((relation as Dictionary).get("at_war",false)): total+=1
	if bool((civ.get("player_relation",{}) as Dictionary).get("at_war",false)): total+=1
	return total


func _friendly_relation_count(civ:Dictionary)->int:
	var total:=0
	for relation in (civ.get("relations",{}) as Dictionary).values():
		if float((relation as Dictionary).get("opinion",0.0))>0.18 and not bool((relation as Dictionary).get("at_war",false)): total+=1
	return total


func _diplomatic_network(civ:Dictionary) -> Dictionary:
	var partners:=0
	var rivals:=0
	var opponents:Array[String]=[]
	for other_id in (civ.get("relations",{}) as Dictionary):
		var relation:Dictionary=civ.relations[other_id]
		if bool(relation.get("at_war",false)):
			var other_index:=_civilization_index(String(other_id))
			opponents.append(String(civilizations[other_index].name) if other_index>=0 else String(other_id))
		elif String(relation.get("treaty","none")) in ["trade","non_aggression"] or float(relation.get("opinion",0.0))>=0.25:
			partners+=1
		elif float(relation.get("opinion",0.0))<=-0.22 or float(relation.get("border_tension",0.0))>=0.52:
			rivals+=1
	return {"partners":partners,"rivals":rivals,"war_opponents":opponents}


func _remove_pending_player_incidents(civ_id:String)->void:
	var retained:Array[Dictionary]=[]
	for incident in pending_player_incidents:
		if String(incident.get("source_civ_id",""))!=civ_id: retained.append(incident)
	pending_player_incidents=retained


func _set_pair_relation(first_index:int,second_index:int,relation:Dictionary)->void:
	var first:Dictionary=civilizations[first_index]
	var second:Dictionary=civilizations[second_index]
	(first.relations as Dictionary)[String(second.id)]=relation.duplicate(true)
	(second.relations as Dictionary)[String(first.id)]=relation.duplicate(true)
	civilizations[first_index]=first
	civilizations[second_index]=second


func _civilization_index(civ_id:String)->int:
	for index in civilizations.size():
		if String(civilizations[index].get("id",""))==civ_id: return index
	return -1


func _cohorts_for_population(population:float,age_bias:float=0.0)->Dictionary:
	var shares:={"children":0.30+age_bias,"youth":0.16,"early_adults":0.15,"established_adults":0.14,"mature_adults":0.17,"elders":0.08-age_bias}
	var result:Dictionary={}
	for cohort in AGE_COHORTS: result[cohort]=maxf(0.0,population*float(shares[cohort]))
	return result


func _scaled_cohorts(source:Dictionary,population:float)->Dictionary:
	var total:=0.0
	for cohort in AGE_COHORTS: total+=maxf(0.0,float(source.get(cohort,0.0)))
	if total<=0.0001: return _cohorts_for_population(population)
	var result:Dictionary={}
	for cohort in AGE_COHORTS: result[cohort]=maxf(0.0,float(source.get(cohort,0.0))*population/total)
	return result


func _working_age_population(cohorts:Dictionary)->float:
	return maxf(0.0,float(cohorts.get("youth",0.0)))+maxf(0.0,float(cohorts.get("early_adults",0.0)))+maxf(0.0,float(cohorts.get("established_adults",0.0)))+maxf(0.0,float(cohorts.get("mature_adults",0.0)))


func _advance_cohorts(source:Dictionary,births:float,deaths:float,hardship:float)->Dictionary:
	var original:=source.duplicate(true)
	var result:=source.duplicate(true)
	for transition in [["children","youth"],["youth","early_adults"],["early_adults","established_adults"],["established_adults","mature_adults"],["mature_adults","elders"]]:
		var from:=String(transition[0])
		var into:=String(transition[1])
		var moving:=maxf(0.0,float(original.get(from,0.0)))/float(COHORT_DURATION_TURNS[from])
		result[from]=maxf(0.0,float(result.get(from,0.0))-moving)
		result[into]=maxf(0.0,float(result.get(into,0.0))+moving)
	result["children"]=maxf(0.0,float(result.get("children",0.0))+maxf(0.0,births))
	var mortality_weights:={"children":1.05+hardship*1.25,"youth":0.45,"early_adults":0.42,"established_adults":0.58,"mature_adults":1.10,"elders":2.65+hardship*0.65}
	return _remove_weighted_cohort_population(result,deaths,mortality_weights)


func _remove_weighted_cohort_population(source:Dictionary,amount:float,weights:Dictionary)->Dictionary:
	var result:=source.duplicate(true)
	var remaining:=maxf(0.0,amount)
	for _pass in AGE_COHORTS.size()+1:
		if remaining<=0.000001: break
		var weighted_total:=0.0
		for cohort in AGE_COHORTS:
			weighted_total+=maxf(0.0,float(result.get(cohort,0.0)))*maxf(0.0,float(weights.get(cohort,1.0)))
		if weighted_total<=0.000001: break
		var pass_remaining:=remaining
		var removed_this_pass:=0.0
		for cohort in AGE_COHORTS:
			var available:=maxf(0.0,float(result.get(cohort,0.0)))
			var removed:=minf(available,pass_remaining*available*maxf(0.0,float(weights.get(cohort,1.0)))/weighted_total)
			result[cohort]=available-removed
			removed_this_pass+=removed
		remaining=maxf(0.0,remaining-removed_this_pass)
		if removed_this_pass<=0.000001: break
	return result


func _player_civilization_name()->String:
	if GameState.settlement_name.strip_edges()!="": return GameState.settlement_name.strip_edges().to_upper()
	return "PLAYER CIVILIZATION"


func _record_world_event(title:String,description:String,domain:String,day:int,metadata:Dictionary={})->void:
	var event:={"day":day,"title":title,"description":description,"domain":domain}
	event.merge(metadata,true)
	world_events.push_front(event)
	if world_events.size()>HISTORY_LIMIT: world_events.resize(HISTORY_LIMIT)
	diplomatic_event.emit(event.duplicate(true))


func export_state()->Dictionary:
	var exported_civilizations:=civilizations.duplicate(true)
	for index in exported_civilizations.size():
		exported_civilizations[index]["societal_values"]=SOCIETAL_VALUES_MODEL.serialize_state(exported_civilizations[index].get("societal_values",{}))
		# These fields are pure functions of world seed and position. Recomputing them
		# on load keeps the fixed civilization save class small even with a full
		# resource-potential vector for every off-screen society.
		exported_civilizations[index].erase("environment_profile")
		exported_civilizations[index].erase("resource_endowment")
		exported_civilizations[index].erase("world_position")
		var position:Variant=exported_civilizations[index].get("position",Vector2.ZERO)
		if position is Vector2: exported_civilizations[index]["position"]={"x":position.x,"y":position.y}
	var exported_formations:=foreign_formations.duplicate(true)
	for index in exported_formations.size():
		for point_key in ["point_a","point_b"]:
			var point:Variant=exported_formations[index].get(point_key,Vector2.ZERO)
			if point is Vector2: exported_formations[index][point_key]={"x":point.x,"y":point.y}
	return {"version":SAVE_VERSION,"world_seed":last_world_seed,"last_processed_day":last_processed_day,"last_turn_day":last_turn_day,"turn_index":turn_index,"dominance_turns":dominance_turns,"contender_dominance_turns":contender_dominance_turns.duplicate(true),"collapse_turns":collapse_turns,"competition_outcome":competition_outcome,"competition_winner_id":competition_winner_id,"player_territory_balance":player_territory_balance,"scout_missions":scout_missions.duplicate(true),"next_scout_mission_id":next_scout_mission_id,"nomad_sightings":nomad_sightings.duplicate(true),"next_nomad_sighting_id":next_nomad_sighting_id,"scout_reports":scout_reports.duplicate(true),"last_scout_outcome":last_scout_outcome.duplicate(true),"diplomatic_mission":diplomatic_mission.duplicate(true),"diplomatic_history":diplomatic_history.duplicate(true),"captured_player_scouts":captured_player_scouts.duplicate(true),"captured_foreign_scouts":captured_foreign_scouts.duplicate(true),"foreign_scout_reports_denied":foreign_scout_reports_denied,"revealed_areas":revealed_areas.duplicate(true),"fog_revision":fog_revision,"player_world_origin":{"x":player_world_origin.x,"y":player_world_origin.y},"city_intelligence":city_intelligence.records.duplicate(true),"rumor_leads":rumor_network.books.duplicate(true),"civilizations":exported_civilizations,"world_events":world_events.duplicate(true),"pending_player_incidents":pending_player_incidents.duplicate(true),"foreign_formations":exported_formations,"foreign_sightings":foreign_sightings.duplicate(true),"observation_revision":observation_revision,"last_observation_day":last_observation_day,"war_history":war_history.duplicate(true),"next_war_id":next_war_id}


func import_state(payload:Dictionary)->Dictionary:
	if not rumor_network.validate(payload.get("rumor_leads",{})): return {"error":"Invalid rumor records."}
	if not city_intelligence.validate(payload.get("city_intelligence",{})): return {"error":"Invalid city intelligence records."}
	var incoming:=payload.duplicate(true)
	var incoming_version:=int(incoming.get("version",-1))
	if incoming_version in [1,2,3,4]: incoming=_migrate_legacy_state(incoming)
	elif incoming_version==5: incoming=_migrate_v5_state(incoming)
	elif incoming_version==6: incoming=_migrate_v6_state(incoming)
	elif incoming_version==7: incoming=_migrate_v7_state(incoming)
	elif incoming_version==8: incoming=_migrate_v8_state(incoming)
	elif incoming_version==9: incoming=_migrate_v9_state(incoming)
	elif incoming_version!=SAVE_VERSION: return {"error":"Unsupported civilization save version."}
	if int(incoming.get("world_seed",GameState.world_seed))!=GameState.world_seed: return {"error":"Civilization save belongs to a different world."}
	var shape_error:=_payload_shape_error(incoming)
	if shape_error!="": return {"error":shape_error}
	for mission:Dictionary in incoming.get("scout_missions",[])+incoming.get("foreign_formations",[])+[incoming.get("diplomatic_mission",{})]:
		if not rumor_network.valid_carried(mission): return {"error":"Invalid carried rumors."}
		if not city_intelligence.valid_carried(mission): return {"error":"Invalid carried city observations."}
	var previous:=export_state()
	_apply_state(incoming)
	var errors:=validate_state()
	if not errors.is_empty():
		_apply_state(previous)
		return {"error":"Invalid civilization state.","details":errors}
	_rebuild_competition()
	if not incoming.has("city_intelligence"): city_intelligence.migrate()
	world_changed.emit(competition_snapshot())
	return {"ok":true,"version":SAVE_VERSION}


func _migrate_legacy_state(payload:Dictionary)->Dictionary:
	var migrated:=payload.duplicate(true)
	var incoming_civilizations:Array=migrated.get("civilizations",[])
	for index in incoming_civilizations.size():
		var civ:Dictionary=incoming_civilizations[index]
		if not civ.has("strategic_regions"):
			var rng:=RandomNumberGenerator.new()
			rng.seed=int(migrated.get("world_seed",GameState.world_seed))^(index+1)*982451653
			var prefix:=String(civ.get("name","RIVAL")).split(" ")[0]
			civ["strategic_regions"]=_create_strategic_regions(String(civ.get("id","civ_%02d" % (index+1))),prefix,float(civ.get("population",1.0)),float(civ.get("territory",0.65)),rng)
		civ["player_relation"]=_relation_with_strategy_defaults(civ.get("player_relation",{}),civ)
		incoming_civilizations[index]=civ
	migrated["civilizations"]=incoming_civilizations
	var streaks:Dictionary={"player":maxi(0,int(migrated.get("dominance_turns",0)))}
	for civ in incoming_civilizations: streaks[String((civ as Dictionary).get("id",""))]=0
	migrated["contender_dominance_turns"]=streaks
	migrated["competition_winner_id"]="player" if String(migrated.get("competition_outcome","ongoing"))=="victory" else ""
	migrated["scout_missions"]=[]
	migrated["next_scout_mission_id"]=1
	migrated["scout_reports"]=[]
	migrated["last_scout_outcome"]={}
	migrated["captured_player_scouts"]={}
	migrated["captured_foreign_scouts"]={}
	migrated["foreign_scout_reports_denied"]=0
	migrated["revealed_areas"]=[]
	migrated["fog_revision"]=0
	migrated["player_world_origin"]={"x":0.0,"y":0.0}
	migrated["foreign_formations"]=[]
	migrated["foreign_sightings"]=[]
	migrated["observation_revision"]=0
	migrated["last_observation_day"]=-1
	migrated["war_history"]=[]
	migrated["next_war_id"]=1
	migrated["version"]=SAVE_VERSION
	return migrated


func _migrate_v5_state(payload:Dictionary)->Dictionary:
	# Version 5 incorrectly bent three foreign expedition routes toward the
	# player's founding position. Rebuild only the bounded movement layer while
	# preserving the actual civilization simulation, diplomacy, and exploration.
	var migrated:=payload.duplicate(true)
	migrated["foreign_formations"]=[]
	migrated["foreign_sightings"]=[]
	migrated["observation_revision"]=maxi(0,int(migrated.get("observation_revision",0)))+1
	migrated["last_observation_day"]=-1
	migrated["war_history"]=[]
	migrated["next_war_id"]=1
	var is_day_one_state:=int(migrated.get("last_processed_day",0))<=1 and (migrated.get("scout_reports",[]) as Array).is_empty()
	var incoming_civilizations:Array=migrated.get("civilizations",[])
	for index in incoming_civilizations.size():
		var civ:Dictionary=incoming_civilizations[index]
		var relation:Dictionary=civ.get("player_relation",{})
		# A lookout sighting is not a diplomatic meeting. Clear v5's sighting-only
		# state, plus impossible Day 1 meetings created by the forced route.
		if int(relation.get("contact_level",0))==1 or (is_day_one_state and int(relation.get("met_day",-1))>=0):
			relation["contact_level"]=0
			relation["contact_intelligence"]=0.0
			relation["met_day"]=-1
		civ["player_relation"]=relation
		incoming_civilizations[index]=civ
	migrated["civilizations"]=incoming_civilizations
	migrated["version"]=SAVE_VERSION
	return migrated


func _migrate_v6_state(payload:Dictionary)->Dictionary:
	var migrated:=payload.duplicate(true)
	migrated["last_scout_outcome"]={}
	migrated["captured_player_scouts"]={}
	migrated["captured_foreign_scouts"]={}
	migrated["foreign_scout_reports_denied"]=0
	# V7 adds one fixed scout formation per contender. Rebuild only this bounded
	# movement layer; civilization, diplomacy, fog, and returned reports persist.
	migrated["foreign_formations"]=[]
	migrated["foreign_sightings"]=[]
	migrated["observation_revision"]=maxi(0,int(migrated.get("observation_revision",0)))+1
	migrated["last_observation_day"]=-1
	migrated["war_history"]=[]
	migrated["next_war_id"]=1
	var incoming_civilizations:Array=migrated.get("civilizations",[])
	for index in incoming_civilizations.size():
		var civ:Dictionary=incoming_civilizations[index]
		civ["player_relation"]=_relation_with_strategy_defaults(civ.get("player_relation",{}),civ)
		incoming_civilizations[index]=civ
	migrated["civilizations"]=incoming_civilizations
	migrated["version"]=SAVE_VERSION
	return migrated


func _migrate_v7_state(payload:Dictionary)->Dictionary:
	var migrated:=payload.duplicate(true)
	migrated["war_history"]=[]
	migrated["next_war_id"]=1
	var incoming_civilizations:Array=migrated.get("civilizations",[])
	for index in incoming_civilizations.size():
		var civ:Dictionary=incoming_civilizations[index]
		civ["player_relation"]=_relation_with_strategy_defaults(civ.get("player_relation",{}),civ)
		for other_id in (civ.get("relations",{}) as Dictionary):
			var relation:Dictionary=(civ.relations as Dictionary)[other_id]
			relation["war_id"]=""
			relation["front_stance"]="balanced"
			(civ.relations as Dictionary)[other_id]=relation
		incoming_civilizations[index]=civ
	migrated["civilizations"]=incoming_civilizations
	migrated["version"]=SAVE_VERSION
	return migrated


func _append_migrated_trail(records:Array,pending_points:Array,radius:float,source:String,day:int)->void:
	if pending_points.size()<2:
		if pending_points.size()==1:
			var lone:Dictionary=pending_points[0]
			records.append({"kind":"circle","x":float(lone.get("x",0.0)),"z":float(lone.get("z",0.0)),"radius":maxf(1.0,radius),"source":source,"day":day})
		return
	var bounded:Array=pending_points.slice(0,REVEALED_TRAIL_POINT_LIMIT)
	var first:Dictionary=bounded[0]
	records.append({"kind":"trail","x":float(first.get("x",0.0)),"z":float(first.get("z",0.0)),"radius":maxf(1.0,radius),"points":bounded.duplicate(true),"source":source,"day":day})


func _migrate_v8_state(payload:Dictionary)->Dictionary:
	var migrated:=payload.duplicate(true)
	var repaired:Array=[]
	var pending_points:Array=[]
	var pending_source:=""
	var pending_radius:=24.0
	var pending_day:=0
	for area_variant in migrated.get("revealed_areas",[]):
		if not area_variant is Dictionary: continue
		var area:Dictionary=area_variant
		var source:=String(area.get("source","returned chart"))
		# These thousands of circles are reconstructed below from the authoritative
		# returned polylines. Old consolidated circles are mathematically incapable
		# of preserving a route and are reduced to a small chart fragment.
		if source=="returned scout chart": continue
		if source=="consolidated chart":
			if not pending_points.is_empty():
				_append_migrated_trail(repaired,pending_points,pending_radius,pending_source,pending_day)
				pending_points=[]
			var fragment:=area.duplicate(true)
			fragment["kind"]="circle"
			fragment["radius"]=minf(72.0,maxf(1.0,float(fragment.get("radius",1.0))))
			fragment["source"]="recovered chart fragment"
			repaired.append(fragment)
			continue
		var can_group:=source in ["traveled ground","returned diplomatic route"] and String(area.get("kind","circle"))=="circle"
		if not can_group:
			if not pending_points.is_empty():
				_append_migrated_trail(repaired,pending_points,pending_radius,pending_source,pending_day)
				pending_points=[]
			var normalized:=area.duplicate(true)
			normalized["kind"]=String(normalized.get("kind","circle"))
			repaired.append(normalized)
			continue
		var point:={"x":float(area.get("x",0.0)),"z":float(area.get("z",0.0))}
		var begins_new:=pending_points.is_empty() or pending_source!=source
		if not begins_new:
			var previous:Dictionary=pending_points[-1]
			begins_new=Vector2(float(previous.x),float(previous.z)).distance_to(Vector2(float(point.x),float(point.z)))>maxf(120.0,float(area.get("radius",24.0))*4.0) or pending_points.size()>=REVEALED_TRAIL_POINT_LIMIT
		if begins_new and not pending_points.is_empty():
			_append_migrated_trail(repaired,pending_points,pending_radius,pending_source,pending_day)
			pending_points=[]
		pending_source=source
		pending_radius=maxf(1.0,float(area.get("radius",24.0)))
		pending_day=int(area.get("day",0))
		pending_points.append(point)
	if not pending_points.is_empty(): _append_migrated_trail(repaired,pending_points,pending_radius,pending_source,pending_day)
	for report_variant in migrated.get("scout_reports",[]):
		if not report_variant is Dictionary: continue
		var report:Dictionary=report_variant
		var route:Array=report.get("route",[])
		if route.size()<2: continue
		var first:Dictionary=route[0]
		repaired.append({"kind":"trail","x":float(first.get("x",0.0)),"z":float(first.get("z",0.0)),"radius":18.0,"points":route.duplicate(true),"source":"returned scout trail","day":int(report.get("day",0))})
	if repaired.size()>REVEAL_HISTORY_LIMIT: repaired=repaired.slice(repaired.size()-REVEAL_HISTORY_LIMIT)
	migrated["revealed_areas"]=repaired
	migrated["fog_revision"]=maxi(0,int(migrated.get("fog_revision",0)))+1
	migrated["version"]=SAVE_VERSION
	return migrated


func _migrate_v9_state(payload:Dictionary)->Dictionary:
	# V9 scout records repeated one immutable route forever. _apply_state detects
	# those records by the missing search sequence and schedules a fresh mission
	# from the civilization's current reach and physically earned evidence.
	var migrated:=payload.duplicate(true)
	migrated["version"]=SAVE_VERSION
	return migrated


func _payload_shape_error(payload:Dictionary)->String:
	for key in ["civilizations","world_events","pending_player_incidents","scout_reports","diplomatic_history","revealed_areas","foreign_formations","foreign_sightings","war_history"]:
		if not payload.get(key,[]) is Array: return "Civilization save field '%s' must be an array." % key
	for key in ["contender_dominance_turns","last_scout_outcome","diplomatic_mission","captured_player_scouts","captured_foreign_scouts","player_world_origin"]:
		if not payload.get(key,{}) is Dictionary: return "Civilization save field '%s' must be a dictionary." % key
	for entry in (payload.get("civilizations",[]) as Array):
		if not entry is Dictionary: return "Civilization save contains a non-dictionary polity record."
		for field in ["cohorts","allocations","relations","player_relation","progression_tiers","discovery_profile"]:
			if field in ["progression_tiers","discovery_profile"] and not entry.has(field): continue
			if not entry.get(field,{}) is Dictionary: return "Civilization save polity field '%s' must be a dictionary." % field
		if not entry.get("strategic_regions",[]) is Array: return "Civilization save polity field 'strategic_regions' must be an array."
		for region in (entry.get("strategic_regions",[]) as Array):
			if not region is Dictionary: return "Civilization save contains a malformed strategic region record."
		for relation in (entry.get("relations",{}) as Dictionary).values():
			if not relation is Dictionary: return "Civilization save contains a malformed relation record."
		var position:Variant=entry.get("position",null)
		if not position is Vector2 and not position is Dictionary and not position is Array: return "Civilization save contains a malformed world position."
	for entry in (payload.get("world_events",[]) as Array):
		if not entry is Dictionary: return "Civilization save contains a malformed world event."
	for entry in (payload.get("pending_player_incidents",[]) as Array):
		if not entry is Dictionary: return "Civilization save contains a malformed military incident."
	for entry in (payload.get("foreign_formations",[]) as Array):
		if not entry is Dictionary: return "Civilization save contains a malformed foreign formation."
		for point_key in ["point_a","point_b"]:
			var point:Variant=entry.get(point_key,null)
			if not point is Vector2 and not point is Dictionary and not point is Array: return "Civilization save contains a malformed foreign formation route."
	for entry in (payload.get("foreign_sightings",[]) as Array):
		if not entry is Dictionary: return "Civilization save contains a malformed foreign sighting."
	for entry in (payload.get("war_history",[]) as Array):
		if not entry is Dictionary: return "Civilization save contains a malformed war record."
		if not entry.get("participants",[]) is Array or not entry.get("casualties",{}) is Dictionary or not entry.get("battles",[]) is Array: return "Civilization save contains malformed war-ledger fields."
	return ""


func _apply_state(payload:Dictionary)->void:
	city_intelligence=preload("res://scripts/city_intelligence.gd").new(self)
	rumor_network=preload("res://scripts/rumor_network.gd").new(self)
	city_intelligence.records=payload.get("city_intelligence",{}).duplicate(true)
	rumor_network.books=payload.get("rumor_leads",{}).duplicate(true)
	last_world_seed=int(payload.get("world_seed",GameState.world_seed))
	last_processed_day=maxi(0,int(payload.get("last_processed_day",0)))
	last_turn_day=maxi(0,int(payload.get("last_turn_day",0)))
	turn_index=maxi(0,int(payload.get("turn_index",0)))
	dominance_turns=maxi(0,int(payload.get("dominance_turns",0)))
	contender_dominance_turns=(payload.get("contender_dominance_turns",{"player":dominance_turns}) as Dictionary).duplicate(true)
	collapse_turns=maxi(0,int(payload.get("collapse_turns",0)))
	competition_outcome=String(payload.get("competition_outcome","ongoing"))
	competition_winner_id=String(payload.get("competition_winner_id",""))
	player_territory_balance=float(payload.get("player_territory_balance",0.0))
	scout_missions.assign((payload.get("scout_missions",[]) as Array).duplicate(true))
	# Older saves carried one scout_mission dictionary; wrap it into the list.
	var legacy_mission:Dictionary=payload.get("scout_mission",{}) if payload.get("scout_mission",{}) is Dictionary else {}
	if scout_missions.is_empty() and not legacy_mission.is_empty():
		legacy_mission=legacy_mission.duplicate(true)
		if not legacy_mission.has("mission_id"): legacy_mission["mission_id"]=1
		scout_missions.append(legacy_mission)
	next_scout_mission_id=maxi(1,int(payload.get("next_scout_mission_id",scout_missions.size()+1)))
	nomad_sightings.assign((payload.get("nomad_sightings",[]) as Array).duplicate(true))
	next_nomad_sighting_id=maxi(1,int(payload.get("next_nomad_sighting_id",nomad_sightings.size()+1)))
	scout_reports.assign((payload.get("scout_reports",[]) as Array).duplicate(true))
	last_scout_outcome=(payload.get("last_scout_outcome",{}) as Dictionary).duplicate(true)
	# Retire illustrated landmarks in older saves while keeping real expedition outcomes.
	for record in scout_reports + scout_missions + [last_scout_outcome]:
		_strip_retired_landmarks(record)
	diplomatic_mission=(payload.get("diplomatic_mission",{}) as Dictionary).duplicate(true)
	if not diplomatic_mission.is_empty():
		# Same-version compatibility for missions saved before carried proposals
		# and explicit envoy provisioning were introduced.
		if not diplomatic_mission.has("purpose"): diplomatic_mission["purpose"]="goodwill"
		if not diplomatic_mission.has("purpose_label"): diplomatic_mission["purpose_label"]="GOODWILL MISSION"
		if not diplomatic_mission.has("provisions"): diplomatic_mission["provisions"]=maxf(0.1,float(diplomatic_mission.get("personnel",1))*maxf(1.0,float(diplomatic_mission.get("return_day",1))-float(diplomatic_mission.get("depart_day",0)))*0.55)
	diplomatic_history.assign((payload.get("diplomatic_history",[]) as Array).duplicate(true))
	captured_player_scouts=(payload.get("captured_player_scouts",{}) as Dictionary).duplicate(true)
	captured_foreign_scouts=(payload.get("captured_foreign_scouts",{}) as Dictionary).duplicate(true)
	foreign_scout_reports_denied=maxi(0,int(payload.get("foreign_scout_reports_denied",0)))
	revealed_areas.assign((payload.get("revealed_areas",[]) as Array).duplicate(true))
	fog_revision=maxi(0,int(payload.get("fog_revision",0)))
	var origin:Dictionary=payload.get("player_world_origin",{})
	player_world_origin=Vector2(float(origin.get("x",0.0)),float(origin.get("y",0.0)))
	var incoming_civilizations:Array=(payload.get("civilizations",[]) as Array).duplicate(true)
	for index in incoming_civilizations.size():
		if not (incoming_civilizations[index] as Dictionary).has("founding_focus"):
			incoming_civilizations[index]["founding_focus"]=String(GameState.FOUNDING_FOCUS_ORDER[(index+abs(last_world_seed))%GameState.FOUNDING_FOCUS_ORDER.size()])
		if not (incoming_civilizations[index] as Dictionary).has("settlement_count"): incoming_civilizations[index]["settlement_count"]=1
		if not (incoming_civilizations[index] as Dictionary).has("world_reach"): incoming_civilizations[index]["world_reach"]=0.0
		if not (incoming_civilizations[index] as Dictionary).has("progression_tiers"): incoming_civilizations[index]["progression_tiers"]=_initial_progression_tiers()
		if not (incoming_civilizations[index] as Dictionary).has("discovery_profile"):
			var imported:Dictionary=incoming_civilizations[index]
			incoming_civilizations[index]["discovery_profile"]=ProgressionSystem.initial_rival_discovery_profile(String(imported.get("id","civ_%02d" % (index+1))),String(imported.get("founding_focus","provision")),String(imported.get("strategy","sustenance")))
		if not (incoming_civilizations[index] as Dictionary).has("societal_values"):
			var imported_society:Dictionary=incoming_civilizations[index]
			incoming_civilizations[index]["societal_values"]=SOCIETAL_VALUES_MODEL.initial_state(String(imported_society.get("founding_focus","provision")),last_world_seed,String(imported_society.get("id","civ_%02d" % (index+1))))
		else:
			incoming_civilizations[index]["societal_values"]=SOCIETAL_VALUES_MODEL.deserialize_state(incoming_civilizations[index].get("societal_values",{}))
		var position:Variant=(incoming_civilizations[index] as Dictionary).get("position",null)
		if position is Dictionary:
			incoming_civilizations[index]["position"]=Vector2(float(position.get("x",0.0)),float(position.get("y",0.0)))
		elif position is Array and position.size()>=2:
			incoming_civilizations[index]["position"]=Vector2(float(position[0]),float(position[1]))
		var hydrated:Dictionary=incoming_civilizations[index]
		var hydrated_position:=_civilization_world_position(hydrated)
		hydrated["world_position"]=hydrated_position
		hydrated["environment_profile"]=PlanetEnvironment.profile_at(hydrated_position)
		hydrated["resource_endowment"]=(hydrated.environment_profile as Dictionary).get("resource_potentials",{})
		incoming_civilizations[index]=hydrated
	civilizations.assign(incoming_civilizations)
	world_events.assign((payload.get("world_events",[]) as Array).duplicate(true))
	world_events.assign(world_events.filter(func(event:Dictionary)->bool: return String(event.get("title",""))!="Landmark named"))
	pending_player_incidents.assign((payload.get("pending_player_incidents",[]) as Array).duplicate(true))
	foreign_formations.assign((payload.get("foreign_formations",[]) as Array).duplicate(true))
	if foreign_formations.is_empty(): _initialize_foreign_formations(last_world_seed)
	for formation_index in foreign_formations.size():
		var legacy_fixed_scout:=String(foreign_formations[formation_index].get("kind",""))=="scout" and not foreign_formations[formation_index].has("search_sequence")
		for point_key in ["point_a","point_b"]:
			var point:Variant=foreign_formations[formation_index].get(point_key,null)
			if point is Dictionary: foreign_formations[formation_index][point_key]=Vector2(float(point.get("x",0.0)),float(point.get("y",0.0)))
			elif point is Array and point.size()>=2: foreign_formations[formation_index][point_key]=Vector2(float(point[0]),float(point[1]))
		if String(foreign_formations[formation_index].get("kind",""))=="scout":
			foreign_formations[formation_index]["search_sequence"]=maxi(-1,int(foreign_formations[formation_index].get("search_sequence",foreign_formations[formation_index].get("last_report_cycle",0))))
			if legacy_fixed_scout:
				var scout_civ_index:=_civilization_index(String(foreign_formations[formation_index].get("civ_id","")))
				if scout_civ_index>=0:
					var disabled_until:=maxi(0,int(foreign_formations[formation_index].get("disabled_until_day",0)))
					foreign_formations[formation_index]=_schedule_foreign_scout_mission(foreign_formations[formation_index],civilizations[scout_civ_index],maxi(last_processed_day,disabled_until))
					foreign_formations[formation_index]["disabled_until_day"]=disabled_until
	foreign_sightings.assign((payload.get("foreign_sightings",[]) as Array).duplicate(true))
	_repair_missing_contact_provenance()
	observation_revision=maxi(0,int(payload.get("observation_revision",0)))
	last_observation_day=int(payload.get("last_observation_day",-1))
	war_history.assign((payload.get("war_history",[]) as Array).duplicate(true))
	next_war_id=maxi(1,int(payload.get("next_war_id",1)))


func validate_state()->Array[String]:
	var errors:Array[String]=[]
	if war_history.size()>WAR_HISTORY_LIMIT: errors.append("War history exceeds its fixed bound.")
	if next_war_id<1: errors.append("Next war ID must be positive.")
	var war_ids:Dictionary={}
	for record_variant in war_history:
		if not record_variant is Dictionary: errors.append("War history contains a malformed record."); continue
		var record:Dictionary=record_variant
		var war_id:=String(record.get("id",""))
		if war_id=="" or war_ids.has(war_id): errors.append("War IDs must be non-empty and unique.")
		war_ids[war_id]=true
		if String(record.get("status","")) not in ["active","ended"]: errors.append("War record has an invalid status.")
		if (record.get("participants",[]) as Array).size()!=2: errors.append("War record must contain exactly two aggregate belligerents.")
		if (record.get("battles",[]) as Array).size()>WAR_BATTLE_LIMIT: errors.append("War battle ledger exceeds its fixed bound.")
		for participant_losses in (record.get("casualties",{}) as Dictionary).values():
			if not participant_losses is Dictionary: errors.append("War casualty account is malformed."); continue
			for field in ["military_dead","civilian_dead","wounded","captured","displaced"]:
				if int(participant_losses.get(field,-1))<0: errors.append("War casualty totals cannot be negative.")
	if civilizations.is_empty() or civilizations.size()>MAX_RIVAL_CIVILIZATIONS: errors.append("World must contain between 1 and %d bounded rival civilization records." % MAX_RIVAL_CIVILIZATIONS)
	if last_processed_day<0 or last_turn_day<0 or last_turn_day>last_processed_day: errors.append("Civilization strategic clock is invalid.")
	if turn_index<0 or dominance_turns<0 or collapse_turns<0: errors.append("Civilization strategic counters cannot be negative.")
	if competition_outcome not in ["ongoing","victory","defeat"]: errors.append("Civilization competition outcome is invalid.")
	if competition_winner_id!="" and competition_winner_id not in ["player","collapse"] and not competition_winner_id.begins_with("civ_"): errors.append("Civilization competition winner is invalid.")
	if not is_finite(player_territory_balance): errors.append("Player territorial balance must be finite.")
	if not is_finite(player_world_origin.x) or not is_finite(player_world_origin.y): errors.append("Player world origin must be finite.")
	var ids:Dictionary={}
	for civ in civilizations:
		var civ_id:=String(civ.get("id",""))
		if civ_id=="" or ids.has(civ_id): errors.append("Civilization IDs must be non-empty and unique.")
		ids[civ_id]=true
		if float(civ.get("population",0.0))<1.0 or not is_finite(float(civ.get("population",0.0))): errors.append("Civilization population must be finite and positive.")
		for required in ["name","position","food_capacity","food_days","health","cohesion","knowledge","production","logistics","institutions","ecology","military_share","military_population","military_readiness","aggression","diplomacy","adaptability","founding_focus","strategy","allocations","relations","player_relation","territory","trade_total","strategic_regions","settlement_count","world_reach","progression_tiers","discovery_profile","societal_values"]:
			if not civ.has(required): errors.append("Civilization %s is missing required field %s." % [civ_id,required])
		for value_error in SOCIETAL_VALUES_MODEL.validate_state(civ.get("societal_values",{})): errors.append("Civilization %s: %s" % [civ_id,value_error])
		if not civ.get("position",null) is Vector2: errors.append("Civilization %s position must be a bounded world coordinate." % civ_id)
		for metric in ["health","cohesion","knowledge","production","logistics","institutions","ecology","military_share","military_readiness","aggression","diplomacy","adaptability"]:
			var value:=float(civ.get(metric,-1.0))
			if not is_finite(value) or value<0.0 or value>1.0: errors.append("Civilization %s metric %s must be finite and normalized." % [civ_id,metric])
		for amount_field in ["food_capacity","food_days","military_population","territory","trade_total"]:
			var amount:=float(civ.get(amount_field,-1.0))
			if not is_finite(amount) or amount<0.0: errors.append("Civilization %s field %s must be finite and nonnegative." % [civ_id,amount_field])
		if float(civ.get("military_population",0.0))>float(civ.get("population",0.0))+0.001: errors.append("Civilization military population exceeds its total population.")
		if String(civ.get("strategy","")) not in STRATEGIES: errors.append("Civilization strategy is unknown.")
		if String(civ.get("founding_focus","")) not in GameState.FOUNDING_FOCUS_ORDER: errors.append("Civilization founding focus is unknown.")
		if int(civ.get("settlement_count",0))<1 or int(civ.get("settlement_count",0))>256: errors.append("Civilization settlement network must remain a bounded aggregate count.")
		if not is_finite(float(civ.get("world_reach",-1.0))) or float(civ.get("world_reach",-1.0))<0.0 or float(civ.get("world_reach",-1.0))>1.0: errors.append("Civilization world reach must be normalized.")
		var progression_tiers:Dictionary=civ.get("progression_tiers",{})
		if progression_tiers.size()!=12: errors.append("Civilization progression must contain exactly twelve aggregate domains.")
		for progression_domain in _initial_progression_tiers():
			var progression_tier:=int(progression_tiers.get(progression_domain,-1))
			if progression_tier<0 or progression_tier>8: errors.append("Civilization progression tier is invalid for %s." % progression_domain)
		var discovery_profile:Dictionary=civ.get("discovery_profile",{})
		if (discovery_profile.get("domains",{}) as Dictionary).size()!=12: errors.append("Civilization discovery profile must contain twelve bounded domain records.")
		if (discovery_profile.get("momentum",{}) as Dictionary).size()!=12: errors.append("Civilization discovery momentum must contain twelve bounded values.")
		var allocations:Dictionary=civ.get("allocations",{})
		var allocation_total:=0.0
		for allocation in ["sustenance","growth","knowledge","production","military","diplomacy"]:
			var allocation_value:=float(allocations.get(allocation,-1.0))
			if not is_finite(allocation_value) or allocation_value<0.0 or allocation_value>1.0: errors.append("Civilization allocation %s is invalid." % allocation)
			allocation_total+=maxf(0.0,allocation_value)
		if absf(allocation_total-1.0)>0.0001: errors.append("Civilization strategic allocations must sum to one.")
		var cohorts:Dictionary=civ.get("cohorts",{})
		if cohorts.size()!=AGE_COHORTS.size(): errors.append("Civilization demographic state must use exactly six aggregate cohorts.")
		var cohort_total:=0.0
		for cohort in AGE_COHORTS:
			var cohort_value:=float(cohorts.get(cohort,-1.0))
			if not is_finite(cohort_value) or cohort_value<0.0: errors.append("Civilization cohort %s must be finite and nonnegative." % cohort)
			cohort_total+=maxf(0.0,cohort_value)
		if absf(cohort_total-float(civ.get("population",0.0)))>maxf(0.01,float(civ.get("population",0.0))*0.00001): errors.append("Civilization cohorts do not conserve population.")
		if (civ.get("relations",{}) as Dictionary).size()!=civilizations.size()-1: errors.append("Civilization relation graph is incomplete.")
		var regions:Array=civ.get("strategic_regions",[])
		if regions.size()!=STRATEGIC_REGIONS_PER_CIV: errors.append("Civilization %s must contain exactly %d bounded strategic regions." % [civ_id,STRATEGIC_REGIONS_PER_CIV])
		var region_ids:Dictionary={}
		var approaches:Dictionary={}
		var represented_population:=0.0
		for region_variant in regions:
			if not region_variant is Dictionary: errors.append("Civilization %s has a malformed strategic region." % civ_id); continue
			var region:Dictionary=region_variant
			errors.append_array(OCCUPATION_GOVERNANCE.validate(region))
			var region_id:=String(region.get("id",""))
			if region_id=="" or region_ids.has(region_id): errors.append("Strategic region IDs must be non-empty and unique within %s." % civ_id)
			region_ids[region_id]=true
			var role:=String(region.get("role",""))
			if role not in REGION_ROLES: errors.append("Strategic region %s has an invalid role." % region_id)
			var approach:=int(region.get("approach_index",-1))
			if approach<0 or approach>=STRATEGIC_REGIONS_PER_CIV or approaches.has(approach): errors.append("Strategic region approach order must be unique and bounded.")
			approaches[approach]=true
			var controller:=String(region.get("controller",""))
			if controller!="player" and not controller.begins_with("civ_"): errors.append("Strategic region %s has an invalid controller." % region_id)
			if String(region.get("original_controller",""))!=civ_id: errors.append("Strategic region %s has an invalid original controller." % region_id)
			for amount_field in ["population","population_share","territory_value","strategic_weight"]:
				var amount:=float(region.get(amount_field,-1.0))
				if not is_finite(amount) or amount<0.0: errors.append("Strategic region %s field %s must be finite and nonnegative." % [region_id,amount_field])
			for normalized_field in ["fortification","damage","resistance","integration","map_x","map_y"]:
				var normalized:=float(region.get(normalized_field,NAN))
				if not is_finite(normalized) or normalized<0.0 or normalized>1.0: errors.append("Strategic region %s field %s must be normalized." % [region_id,normalized_field])
			if int(region.get("occupation_turns",-1))<0 or int(region.get("last_control_change_day",-1))<0: errors.append("Strategic region occupation counters cannot be negative.")
			represented_population+=maxf(0.0,float(region.get("population",0.0)))
		if represented_population>float(civ.get("population",0.0))+maxf(0.01,float(civ.get("population",0.0))*0.00001): errors.append("Strategic regions cannot represent more people than their civilization contains.")
		if _contains_person_records(civ): errors.append("Civilization state contains forbidden individual-person records.")
	for civ in civilizations:
		var civ_id:=String(civ.get("id",""))
		var relations:Dictionary=civ.get("relations",{})
		for other_id in relations:
			if not ids.has(String(other_id)) or String(other_id)==civ_id: errors.append("Civilization relation graph references an invalid polity.")
			if not relations[other_id] is Dictionary: errors.append("Civilization relation record is malformed."); continue
			var relation:Dictionary=relations[other_id]
			_validate_relation(relation,errors,"inter-civilization")
			var other_index:=_civilization_index(String(other_id))
			if other_index>=0:
				var reverse:Dictionary=(civilizations[other_index].get("relations",{}) as Dictionary).get(civ_id,{})
				if relation!=reverse: errors.append("Civilization relation graph is asymmetric between %s and %s." % [civ_id,String(other_id)])
		var player_relation:Dictionary=civ.get("player_relation",{})
		_validate_relation(player_relation,errors,"player")
		for region_variant in civ.get("strategic_regions",[]):
			var controller:=String((region_variant as Dictionary).get("controller",""))
			if controller!="player" and not ids.has(controller): errors.append("Strategic region controller references an unknown civilization.")
	if world_events.size()>HISTORY_LIMIT: errors.append("Civilization history exceeds its fixed bound.")
	if pending_player_incidents.size()>INCIDENT_LIMIT: errors.append("Player incident queue exceeds its fixed bound.")
	if revealed_areas.size()>REVEAL_HISTORY_LIMIT: errors.append("Revealed map records exceed their fixed bound.")
	if scout_reports.size()>SCOUT_REPORT_LIMIT: errors.append("Scout reports exceed their fixed bound.")
	if diplomatic_history.size()>DIPLOMATIC_HISTORY_LIMIT: errors.append("Diplomatic mission history exceeds its fixed bound.")
	if captured_player_scouts.size()>CAPTURED_SCOUT_COHORT_LIMIT or captured_foreign_scouts.size()>CAPTURED_SCOUT_COHORT_LIMIT: errors.append("Captured scouts must remain bounded to one aggregate cohort per rival civilization.")
	if foreign_scout_reports_denied<0: errors.append("Denied foreign scout reports cannot be negative.")
	for cohort_map in [captured_player_scouts,captured_foreign_scouts]:
		for civ_id in (cohort_map as Dictionary):
			if not ids.has(String(civ_id)): errors.append("Captured scout cohort references an unknown civilization.")
			var cohort:Dictionary=(cohort_map as Dictionary)[civ_id]
			if int(cohort.get("count",-1))<0: errors.append("Captured scout cohort count cannot be negative.")
	for area_variant in revealed_areas:
		if not area_variant is Dictionary: errors.append("Revealed map record is malformed."); continue
		var area:Dictionary=area_variant
		for coordinate in ["x","z","radius"]:
			if not is_finite(float(area.get(coordinate,NAN))): errors.append("Revealed map record contains a non-finite coordinate.")
		if float(area.get("radius",0.0))<=0.0: errors.append("Revealed map radius must be positive.")
		var kind:=String(area.get("kind","circle"))
		if kind not in ["circle","trail"]: errors.append("Revealed map record has an invalid geometry kind.")
		if kind=="trail":
			var points:Variant=area.get("points",[])
			if not points is Array or points.size()<2 or points.size()>REVEALED_TRAIL_POINT_LIMIT:
				errors.append("Revealed trail must contain a bounded physical polyline.")
			elif points is Array:
				for point in points:
					if not point is Dictionary or not is_finite(float(point.get("x",NAN))) or not is_finite(float(point.get("z",NAN))): errors.append("Revealed trail contains an invalid point.")
	for mission_variant in scout_missions:
		var mission:Dictionary=mission_variant
		if int(mission.get("duration_days",0)) not in SCOUT_DURATIONS: errors.append("Scout mission duration is invalid.")
		if int(mission.get("return_day",-1))<=int(mission.get("start_day",-1)): errors.append("Scout mission return day must follow departure.")
		var route:Variant=mission.get("route",[])
		if not route is Array or route.size()<2 or route.size()>SCOUT_ROUTE_POINT_LIMIT: errors.append("Scout mission route must remain bounded.")
		elif route is Array:
			for point in route:
				if not point is Dictionary or not is_finite(float(point.get("x",NAN))) or not is_finite(float(point.get("z",NAN))): errors.append("Scout mission route contains an invalid point.")
			if String(mission.get("travel_mode","land"))=="land" and scout_land_authority.is_valid() and not _scout_route_is_land(route): errors.append("Land scout mission route crosses non-land terrain.")
		if String(mission.get("travel_mode","land"))!="land": errors.append("Scout travel mode is unavailable without an implemented maritime expedition capability.")
		for scout_trait in ["concealment","evasion"]:
			var scout_trait_value:=float(mission.get(scout_trait,NAN))
			if not is_finite(scout_trait_value) or scout_trait_value<0.0 or scout_trait_value>1.0: errors.append("Scout mission %s must be normalized." % scout_trait)
	if not diplomatic_mission.is_empty():
		if not ids.has(String(diplomatic_mission.get("civ_id",""))): errors.append("Diplomatic mission references an unknown civilization.")
		if diplomatic_mission.has("commitment_terms"):
			var commitment:Variant=diplomatic_mission.commitment_terms
			if not ForeignDiplomacy.commitments.valid_terms(commitment) or not ForeignDiplomacy.commitments.number(commitment.get("serial")) or float(commitment.get("serial",0))<1: errors.append("Diplomatic commitment terms are invalid.")
		if int(diplomatic_mission.get("arrival_day",-1))<=int(diplomatic_mission.get("depart_day",-1)): errors.append("Diplomatic mission arrival must follow departure.")
		if int(diplomatic_mission.get("return_day",-1))<=int(diplomatic_mission.get("arrival_day",-1)): errors.append("Diplomatic mission return must follow arrival.")
		var diplomatic_purpose:=String(diplomatic_mission.get("purpose","goodwill"))
		if diplomatic_purpose!="goodwill" and diplomatic_purpose not in CARRIED_DIPLOMATIC_ACTIONS: errors.append("Diplomatic mission purpose is invalid.")
		if not is_finite(float(diplomatic_mission.get("gift_amount",0.0))) or float(diplomatic_mission.get("gift_amount",0.0))<0.0: errors.append("Diplomatic mission gift cannot be negative or non-finite.")
		if diplomatic_purpose=="goodwill" and float(diplomatic_mission.get("gift_amount",0.0))<=0.0: errors.append("A goodwill mission must carry a physical gift.")
		if not is_finite(float(diplomatic_mission.get("provisions",0.0))) or float(diplomatic_mission.get("provisions",0.0))<=0.0: errors.append("Diplomatic mission must carry positive travel provisions.")
	if contender_dominance_turns.size()!=civilizations.size()+1: errors.append("Every contender must have exactly one victory-streak counter.")
	for contender_id in contender_dominance_turns:
		if int(contender_dominance_turns[contender_id])<0: errors.append("Contender victory streaks cannot be negative.")
	var incident_sources:Dictionary={}
	for incident in pending_player_incidents:
		var source_id:=String(incident.get("source_civ_id",""))
		if not ids.has(source_id): errors.append("Player incident references an unknown civilization.")
		if incident_sources.has(source_id): errors.append("Player incident queue contains duplicate source civilizations.")
		incident_sources[source_id]=true
		if int(incident.get("strength",0))<=0: errors.append("Player incident strength must be positive.")
		var target_region_id:=String(incident.get("target_region_id",""))
		if target_region_id!="":
			var source_index:=_civilization_index(source_id)
			if source_index<0 or _region_index(civilizations[source_index],target_region_id)<0: errors.append("Player incident references an unknown strategic region.")
	if foreign_formations.size()!=civilizations.size()*FOREIGN_FORMATIONS_PER_CIV: errors.append("Foreign movement must use exactly %d bounded aggregate formation records." % (civilizations.size()*FOREIGN_FORMATIONS_PER_CIV))
	var formation_ids:Dictionary={}
	for formation_variant in foreign_formations:
		if not formation_variant is Dictionary: errors.append("Foreign formation record is malformed."); continue
		var formation:Dictionary=formation_variant
		var formation_id:=String(formation.get("id","")); var civ_id:=String(formation.get("civ_id",""))
		if formation_id=="" or formation_ids.has(formation_id): errors.append("Foreign formation IDs must be non-empty and unique.")
		formation_ids[formation_id]=true
		if not ids.has(civ_id): errors.append("Foreign formation references an unknown civilization.")
		if String(formation.get("kind","")) not in ["patrol","expedition","scout"]: errors.append("Foreign formation has an invalid aggregate mission kind.")
		for point_key in ["point_a","point_b"]:
			var point:Variant=formation.get(point_key,null)
			if not point is Vector2 or not is_finite((point as Vector2).x) or not is_finite((point as Vector2).y): errors.append("Foreign formation route coordinates must be finite vectors.")
		var leg_days:=float(formation.get("leg_days",0.0)); var share:=float(formation.get("strength_share",-1.0)); var readiness:=float(formation.get("readiness",-1.0))
		if not is_finite(leg_days) or leg_days<=0.0: errors.append("Foreign formation travel duration must be finite and positive.")
		if not is_finite(share) or share<=0.0 or share>1.0: errors.append("Foreign formation strength share must be normalized and positive.")
		if not is_finite(readiness) or readiness<0.0 or readiness>1.0: errors.append("Foreign formation readiness must be normalized.")
		if String(formation.get("kind",""))=="scout":
			for trait_key in ["concealment","evasion"]:
				var trait_value:=float(formation.get(trait_key,NAN))
				if not is_finite(trait_value) or trait_value<0.0 or trait_value>1.0: errors.append("Foreign scout %s must be normalized." % trait_key)
			if int(formation.get("last_report_cycle",-1))<0 or int(formation.get("disabled_until_day",-1))<0 or int(formation.get("evaded_until_day",-1))<0: errors.append("Foreign scout mission counters cannot be negative.")
			if int(formation.get("search_sequence",-1))<0: errors.append("Foreign scout search sequence is invalid.")
	if foreign_sightings.size()>FOREIGN_SIGHTING_LIMIT: errors.append("Foreign sightings exceed their fixed history bound.")
	for sighting_variant in foreign_sightings:
		if not sighting_variant is Dictionary: errors.append("Foreign sighting record is malformed."); continue
		var sighting:Dictionary=sighting_variant
		if not formation_ids.has(String(sighting.get("formation_id",""))): errors.append("Foreign sighting references an unknown aggregate formation.")
		if not ids.has(String(sighting.get("civ_id",""))): errors.append("Foreign sighting references an unknown civilization.")
		var position:Variant=sighting.get("position",{})
		if not position is Dictionary or not is_finite(float(position.get("x",NAN))) or not is_finite(float(position.get("z",NAN))): errors.append("Foreign sighting position is malformed.")
	return errors


func _validate_relation(relation:Dictionary,errors:Array[String],label:String)->void:
	for metric in ["opinion","border_tension"]:
		var value:=float(relation.get(metric,NAN))
		if not is_finite(value) or (metric=="opinion" and (value<-1.0 or value>1.0)) or (metric=="border_tension" and (value<0.0 or value>1.0)): errors.append("%s relation %s is invalid." % [label,metric])
	var trade:=float(relation.get("trade",NAN))
	if not is_finite(trade) or trade<0.0: errors.append("%s relation trade must be finite and nonnegative." % label)
	var at_war:=bool(relation.get("at_war",false))
	if at_war and String(relation.get("treaty","none"))!="war": errors.append("%s relation at war must use the war treaty state." % label)
	if at_war and trade>0.000001: errors.append("%s relation cannot trade during active war." % label)
	if label=="player":
		if String(relation.get("war_goal","")) not in WAR_GOALS: errors.append("Player relation has an invalid war objective.")
		if String(relation.get("front_stance","balanced")) not in ["cautious","balanced","offensive"]: errors.append("Player relation has an invalid front stance.")
		var contact_level:=int(relation.get("contact_level",-1))
		var intelligence:=float(relation.get("contact_intelligence",NAN))
		var rival_contact_level:=int(relation.get("rival_contact_level",-1))
		var rival_intelligence:=float(relation.get("rival_player_intelligence",NAN))
		if contact_level<0 or contact_level>2: errors.append("Player relation contact level must be bounded.")
		if not is_finite(intelligence) or intelligence<0.0 or intelligence>1.0: errors.append("Player relation intelligence must be normalized.")
		if rival_contact_level<0 or rival_contact_level>2: errors.append("Rival knowledge of the player must use a bounded contact level.")
		if not is_finite(rival_intelligence) or rival_intelligence<0.0 or rival_intelligence>1.0: errors.append("Rival intelligence about the player must be normalized.")
		var trace_confidence:=float(relation.get("rival_player_trace_confidence",0.0))
		var trace_radius:=float(relation.get("rival_player_trace_radius_km",0.0))
		if not is_finite(trace_confidence) or trace_confidence<0.0 or trace_confidence>1.0: errors.append("Rival evidence confidence about the player must be normalized.")
		if not is_finite(trace_radius) or trace_radius<0.0: errors.append("Rival evidence uncertainty must be finite and nonnegative.")
		if trace_confidence>0.0:
			var trace_center:Variant=relation.get("rival_player_trace_center",{})
			if not trace_center is Dictionary or not is_finite(float(trace_center.get("x",NAN))) or not is_finite(float(trace_center.get("z",NAN))) or trace_radius<=0.0: errors.append("Rival evidence about the player must have a bounded uncertain location.")
		if contact_level<2 and (at_war or String(relation.get("treaty","none")) not in ["none",""]): errors.append("An unknown polity cannot have a player treaty or active war.")
		var war_score:=float(relation.get("war_score",NAN))
		if not is_finite(war_score) or war_score<-100.0 or war_score>100.0: errors.append("Player relation war score must remain between -100 and 100.")
		for exhaustion_key in ["player_war_exhaustion","rival_war_exhaustion"]:
			var exhaustion:=float(relation.get(exhaustion_key,NAN))
			if not is_finite(exhaustion) or exhaustion<0.0 or exhaustion>1.0: errors.append("Player relation %s must be normalized." % exhaustion_key)
		if int(relation.get("conflict_turns",-1))<0 or int(relation.get("truce_until_day",-1))<0 or int(relation.get("war_started_day",-2))<-1: errors.append("Player relation strategic-war counters are invalid.")


func _contains_person_records(value:Variant)->bool:
	var forbidden:=["person","people_records","citizen_registry","citizen_ids","soldier_ids","household_id","mother_id","father_id"]
	if value is Dictionary:
		for key in value:
			if String(key).to_lower() in forbidden: return true
			if _contains_person_records(value[key]): return true
	elif value is Array:
		for entry in value:
			if _contains_person_records(entry): return true
	return false

func _strip_retired_landmarks(record:Dictionary)->void:
	if record.has("discoveries"):
		record["discoveries"]=(record.discoveries as Array).filter(func(item:Dictionary)->bool: return String(item.get("kind",""))!="landmark")
	if record.has("windfalls"):
		record["windfalls"]=(record.windfalls as Array).filter(func(line:Variant)->bool: return not (String(line).begins_with("They name ") and "waymark" in String(line)))
	if record.has("journal"):
		record["journal"]=(record.journal as Array).filter(func(line:Variant)->bool: return not String(line).begins_with("They steered by "))
