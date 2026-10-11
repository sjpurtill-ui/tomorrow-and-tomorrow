extends GdUnitTestSuite
## Rival rulers send expeditions by sea under our own rules (expedition.gd
## leaders_decide), and a meeting made in one people's world is known to the
## people met (civilization_system.gd _meeting_is_mutual).

const Expedition:=preload("res://scripts/expedition.gd")
const COAST_BOATS:=["river_craft","hide_covered_boats","plank_extended_dugouts","sail_panel_cutting","sail_seaming","wayfinding_stars"]
var rival:=""

## The rival's home country x -40..600, 400 km of open sea, a far land beyond x 1000.
static func _two_lands()->Callable:
	return func(point:Vector2)->bool:return (point.x>=-40.0 and point.x<=600.0 and absf(point.y)<300.0) or (point.x>1000.0 and point.x<3000.0 and absf(point.y)<900.0)

func before_test()->void:
	OS.set_environment("OPENAI_API_KEY","")
	WorldSimulation.clear()
	GameState.reset_for_new_world(616161)
	SettlementModel.reset_for_new_world()
	GovernmentPeopleSystem.reset_for_new_world()
	ConsequenceEngine.reset_for_new_world()
	CivilizationSystem.reset_for_new_world(); CivilizationSystem.initialize()
	ForeignDiplomacy.reset_for_new_world()
	MilitaryCampaign.reset_for_new_world()
	GameState.civic_api_enabled=false
	GameState.initialize_population_model()
	GameState.settlement_site_committed=true; GameState.settlement_completed=["Hearth Circle"]
	SettlementModel.ensure_founded(); GovernmentPeopleSystem.initialize()
	WorldSimulation.context_provider=func(_o:Vector2)->Dictionary:return {"environment_profile":PlanetEnvironment.profile_at(Vector2.ZERO),"surface_water_distance_km":0.3,"surface_water_recognized":true}
	rival=String(CivilizationSystem.civilizations[0].id)
	WorldSimulation.create_actor(rival,616161,Vector2.ZERO)
	WorldSimulation.actors[rival].controller="manual"
	WorldSimulation.enabled=true

func after_test()->void:
	WorldSimulation.enabled=false
	WorldSimulation.clear()

func test_a_meeting_made_by_their_party_is_known_to_us_and_told()->void:
	GameState.simulation_events=[]
	var ours:Dictionary=CivilizationSystem.civilizations[0]
	assert_int(int((ours.player_relation as Dictionary).get("contact_level",0))).is_less(2)
	WorldSimulation.scoped(rival,func()->void:
		WorldSimulation.world._meeting_is_mutual({"id":"human","name":"the people over the sea"},4000,Vector2(120,40),"an expedition",true))
	var relation:Dictionary=CivilizationSystem.civilizations[0].player_relation
	assert_int(int(relation.contact_level)).is_equal(2)
	assert_int(int(relation.rival_contact_level)).is_equal(2)
	assert_str(String(relation.contact_source)).is_equal("their_party_came")
	assert_float(float(relation.encounter_position.x)).is_equal(120.0)
	var told:=GameState.simulation_events.filter(func(e:Dictionary)->bool:return String(e.get("title","")).begins_with("First contact"))
	assert_int(told.size()).is_equal(1)
	assert_str(String(told[0].description)).contains("from over the sea")
	# Once met, a second meeting says nothing new.
	WorldSimulation.scoped(rival,func()->void:
		WorldSimulation.world._meeting_is_mutual({"id":"human","name":"x"},4100,Vector2(0,0),"a scouting party",false))
	assert_int(GameState.simulation_events.filter(func(e:Dictionary)->bool:return String(e.get("title","")).begins_with("First contact")).size()).is_equal(1)

func test_a_ruler_with_nothing_left_to_chart_sends_an_expedition_by_sea()->void:
	var outcome:Dictionary=WorldSimulation.scoped(rival,func()->Dictionary:
		var world:Node=WorldSimulation.world
		var state:Node=WorldSimulation.state
		world.set_scout_geography_authority(_two_lands())
		state.settlement_site_committed=true
		state.ensure_population_total(3000)
		state.resource_stockpiles.Food=90000.0;state.food_stocks={"Preserved food":90000.0}
		for id:String in COAST_BOATS:
			if not id in state.known_discoveries:state.known_discoveries.append(id)
			state.discovery_adoption[id]=1.0
		var staff:Dictionary=world.scouting_staff.data
		staff.share=0.05
		# Scouts still finding new ground: no expedition.
		var idle:Dictionary=Expedition.leaders_decide({})
		staff["fruitless"]=2
		var tries:Array=[]
		for attempt in 8:
			staff["expedition_next_day"]=0
			var result:Dictionary=Expedition.leaders_decide({})
			tries.append(result)
			if bool(result.get("sent",false)):break
		# Not again within the half year, nor while one is away.
		var again:Dictionary=Expedition.leaders_decide({})
		return {"idle":idle,"tries":tries,"again":again,"away":Expedition.away(world).size(),"mission":world.scout_missions[-1] if not world.scout_missions.is_empty() else {}})
	assert_bool((outcome.idle as Dictionary).is_empty()).is_true()
	assert_int(int(outcome.away)).override_failure_message(str(outcome.tries)).is_equal(1)
	assert_bool((outcome.again as Dictionary).is_empty()).is_true()
	var mission:Dictionary=outcome.mission
	assert_str(String(mission.travel_mode)).is_equal("sea")
	assert_float(float(mission.expedition.chance)).is_greater_equal(Expedition.LEADERS_LEAST_CHANCE)
	# Theirs, not ours.
	assert_array(CivilizationSystem.scout_missions).is_empty()

func test_word_from_over_the_sea_is_a_rumour_with_a_place_and_never_a_meeting()->void:
	# No boats fit for the sea: nothing is heard.
	GameState.simulation_events=[]
	for month in 60:assert_array(Expedition.hearsay_over_the_sea(CivilizationSystem,month*30+posmod(absi(hash("player:sea_hearsay")),30))).is_empty()
	for id:String in COAST_BOATS:
		if not id in GameState.known_discoveries:GameState.known_discoveries.append(id)
		GameState.discovery_adoption[id]=1.0
	assert_float(Expedition.endurance_km(true)).is_greater(250.0)
	var heard:Array=[]
	var day:=0
	for month in 2400:
		day=month*30+posmod(absi(hash("player:sea_hearsay")),30)
		heard=Expedition.hearsay_over_the_sea(CivilizationSystem,day)
		if not heard.is_empty():break
	assert_array(heard).override_failure_message("nothing heard in 200 years").is_not_empty()
	var leads:Array=CivilizationSystem.rumor_network.list_leads("player",day)
	var lead:Dictionary=leads.filter(func(l:Dictionary)->bool:return String(l.subject)==String(heard[0]))[0]
	assert_str(String(lead.name)).is_equal("a people over the sea")
	assert_float(float(lead.radius)).is_between(150.0,1500.0)
	for civ:Dictionary in CivilizationSystem.civilizations:
		if String(civ.id)==String(heard[0]):assert_int(int((civ.player_relation as Dictionary).get("contact_level",0))).is_equal(0)
	assert_str(String(GameState.simulation_events[0].title)).is_equal("WORD FROM OVER THE SEA")
	# Any other day of the month: nothing.
	assert_array(Expedition.hearsay_over_the_sea(CivilizationSystem,day+1)).is_empty()
