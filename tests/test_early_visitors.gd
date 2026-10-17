extends GdUnitTestSuite
const Hall=preload("res://scripts/audience_hall.gd")
const Early=preload("res://scripts/early_visitors.gd")
const Society=preload("res://scripts/society_exchange.gd")
const AI=preload("res://scripts/envoy_request_ai.gd")
const Voice=preload("res://scripts/audience_voice.gd")
const SEED=424242
var met:Array[String]=[]

func before_test()->void:
	WorldSimulation.clear()
	GameState.set_process(false); CivilizationSystem.set_process(false); MilitaryCampaign.set_process(false)
	GameState.reset_for_new_world(SEED); GameState.civic_api_enabled=false
	# Three peoples met are needed; the rival count is a new-game setting that
	# reset_for_new_world keeps, so another suite's choice must not shrink it.
	GameState.opponent_count=maxi(GameState.opponent_count,3)
	DiscoverySystem.reset_for_new_world(); FoodSystem.reset_for_new_world(); MilitaryCampaign.reset_for_new_world()
	CivilizationSystem.reset_for_new_world()
	ForeignDiplomacy.reset_for_new_world(); GovernmentPeopleSystem.reset_for_new_world()
	CivilizationSystem.player_world_origin=preload("res://scripts/civilization_start.gd").candidate(SEED,0)
	GameState.settlement_founded_at=Vector3(CivilizationSystem.player_world_origin.x,0,CivilizationSystem.player_world_origin.y)
	GameState.ensure_population_total(200); GameState.housing_capacity=260
	GameState.settlement_site_committed=true; GameState.settlement_founded_day=0; GameState.settlement_completed=["Hearth Circle"]; SettlementModel.ensure_founded()
	GameState.population_health=0.9; GameState.simulation_metrics.merge({"food_days":60.0,"food_intake_ratio":1.0,"security":0.6,"cohesion":0.7},true)
	GovernmentPeopleSystem.initialize()
	FoodSystem.receive_external_food(3000)
	for res in ["Timber","Stone","Clay","Fiber Plants"]: GameState.resource_stockpiles[res]=300.0
	met.clear()
	var civs:Array=CivilizationSystem.civilizations
	for index in 3:
		var civ:Dictionary=civs[index]
		civ.player_relation.contact_level=2; civ.player_relation.met_day=0; civ.player_relation.home_location_known=true
		# Neighbours whose country touches ours: shared ground and carried help
		# are theirs to ask (envoy_requests.gd plausible).
		civ["world_position"]=CivilizationSystem.player_world_origin+Vector2(30.0*float(index+1),0.0)
		met.append(String(civ.id))
	GameState.elapsed_days=400

	CivilizationSystem.set_scout_geography_authority(func(_p:Vector2)->bool:return true)
	for id in met:
		if not WorldSimulation.actors.has(id):WorldSimulation.create_actor(id,SEED+1,ForeignDiplomacy.civilization(id).world_position)
		WorldSimulation.scoped(id,func()->void:
			WorldSimulation.state.ensure_population_total(200)
			WorldSimulation.state.known_discoveries.assign(["clay_shaping"])
			WorldSimulation.state.discovery_adoption.clay_shaping=1.0
			WorldSimulation.state.resource_stockpiles.Food=2000.0
			WorldSimulation.state.food_stocks={"Preserved food":2000.0})
		var civ:=ForeignDiplomacy.civilization(id)
		civ.player_relation.encounter_position={"x":civ.world_position.x,"z":civ.world_position.y}
		civ.food_days=60.0;civ.health=0.8;civ.player_relation.opinion=0.3;civ.player_relation.border_tension=0.2
	GameState.known_discoveries.erase("clay_shaping")

func after_test()->void:
	WorldSimulation.clear()

func raise_visit(kind:String)->Dictionary:
	if kind=="families":ForeignDiplomacy.civilization(met[0]).food_days=10
	if kind=="captives":CivilizationSystem.captured_player_scouts[met[0]]={"count":3,"captured_day":380}
	var a:=Early.generate(met[0],{"type":"ambient","civ_id":met[0]},int(GameState.elapsed_days),kind)
	assert_bool(a.is_empty()).override_failure_message("no visit for "+kind).is_false()
	if not a.is_empty():Hall._enqueue(a,int(GameState.elapsed_days))
	return a

func test_cutoff_and_cooldown()->void:
	assert_bool(Early.active()).is_true()
	assert_int(Hall._gap()).is_equal(1460)
	Hall.state().last_arrival_day=400;Hall.state().next_any=1700
	for type in ["first_contact","famine"]:
		assert_bool(Hall._budget_allows({"type":type,"civ_id":met[0],"crisis":true},500)).is_false()
	assert_bool(Hall._budget_allows({"type":"peace_possible","civ_id":met[0],"crisis":true},500)).is_true()
	GameState.ensure_population_total(1000)
	assert_bool(Early.active()).is_false()
	assert_dict(Early.generate(met[0],{},600)).is_empty()

func test_each_new_visit_has_saved_facts_and_available_answers()->void:
	for kind in ["hunt","craft","lovers","traveller","families","captives","invitation"]:
		if kind=="invitation":ForeignDiplomacy.civilization(met[0]).food_days=60
		var a:=raise_visit(kind)
		if a.is_empty():continue
		assert_bool(Hall._valid_audience(a)).is_true()
		assert_bool(Hall.options(a.id).size()>=3).is_true()
		assert_bool(Hall.resolve(a.id,"decline").ok).is_true()
	assert_bool(Hall.validate_state(Hall.state())).is_true()

func test_inquiry_stays_open_and_cannot_reroll_after_reload()->void:
	var a:=raise_visit("hunt")
	var saved:Dictionary=JSON.parse_string(JSON.stringify(Hall.state()))
	var result:=Hall.resolve(a.id,"hear")
	assert_bool(result.keep_open).is_true();assert_str(a.status).is_equal("waiting")
	var finding:String=a.situation.visit.finding
	ForeignDiplomacy.audiences=saved
	assert_str(String(Hall.resolve(a.id,"hear").outcome)).is_equal(String(result.outcome))
	assert_str(Hall.find(a.id).situation.visit.finding).is_equal(finding)
	assert_bool(Hall.resolve(a.id,"hear").ok).is_false()
	assert_bool(JSON.stringify(Early.voice_facts(Hall.find(a.id))).contains("witness_roll")).is_false()

func test_migration_conserves_people_and_uses_real_food()->void:
	var a:=raise_visit("lovers")
	var source:=Society.owner_state(met[0])
	var total:float=GameState.population_exact+source.population_exact
	var children:float=source.population_cohorts.children
	var adults:=Early.available_adults(source)
	var food:=Hall.player_stock("Food")
	var theirs:=Hall.foreign_stock(met[0],"Food")
	var cost:float=a.situation.visit.food
	assert_bool(Hall.resolve(a.id,"reconcile").ok).is_true()
	assert_float(GameState.population_exact).is_equal(202.0)
	assert_float(source.population_cohorts.children).is_equal_approx(children,0.00001)
	assert_float(Early.available_adults(source)).is_equal_approx(adults-2,0.00001)
	assert_float(GameState.population_exact+source.population_exact).is_equal_approx(total,0.00001)
	assert_float(Hall.player_stock("Food")).is_equal_approx(food-cost*2,0.00001)
	assert_float(Hall.foreign_stock(met[0],"Food")).is_equal_approx(theirs+cost,0.00001)
	assert_bool(Society.valid(Society.data())).is_true()
	assert_bool(Hall.resolve(a.id,"reconcile").ok).is_false()
	assert_float(GameState.population_exact).is_equal(202.0)

func test_teaching_goes_to_study_collection_not_instant_unlock()->void:
	var a:=raise_visit("craft")
	assert_bool(Hall.resolve(a.id,"welcome").ok).is_true()
	assert_bool("clay_shaping" in GameState.known_discoveries).is_false()
	assert_bool(Society.data().collections.has("visitor:"+met[0]+":clay_shaping")).is_true()
	assert_bool(Society.valid(Society.data())).is_true()

func test_captives_are_not_added_to_population_and_stale_captives_cost_nothing()->void:
	var a:=raise_visit("captives")
	var population:float=GameState.population_exact
	assert_bool(Hall.resolve(a.id,"ransom").ok).is_true()
	assert_float(GameState.population_exact).is_equal(population)
	assert_int(int(CivilizationSystem.captured_player_scouts.get(met[0],{}).get("count",0))).is_equal(0)
	a=raise_visit("captives")
	CivilizationSystem.captured_player_scouts.erase(met[0])
	var food:=Hall.player_stock("Food")
	assert_bool(Hall.resolve(a.id,"ransom").ok).is_false()
	assert_float(Hall.player_stock("Food")).is_equal(food)

func test_invitation_returns_once_even_above_population_cutoff()->void:
	var a:=raise_visit("invitation")
	a.hidden.early.contest_roll=0.0
	assert_bool(Hall.resolve(a.id,"compete").ok).is_true()
	assert_float(preload("res://scripts/lent_hands.gd").away(401)).is_equal(2.0)
	assert_bool(Hall.validate_state(Hall.state())).is_true()
	GameState.ensure_population_total(1000)
	var food:=Hall.player_stock("Food")
	Early.daily(414)
	assert_float(Hall.player_stock("Food")).is_equal_approx(food+float(a.situation.visit.food),0.00001)
	assert_int(Early.jobs().size()).is_equal(0)
	var returned:=Hall.player_stock("Food")
	Early.daily(414)
	assert_float(Hall.player_stock("Food")).is_equal(returned)
	assert_float(preload("res://scripts/lent_hands.gd").away(414)).is_equal(0.0)

func test_returning_visitor_remembers_actual_decision()->void:
	var first:=raise_visit("hunt")
	Hall.resolve(first.id,"back")
	GameState.elapsed_days=900
	var again:=raise_visit("return")
	assert_str(again.speaker.name).is_equal(first.speaker.name)
	assert_str(again.situation.visit.previous_outcome).is_equal(first.outcome)
	GameState.ensure_population_total(1000)
	assert_bool(Hall.resolve(again.id,"remember").ok).is_true()
	assert_bool(first.return_used).is_true()
	assert_int(Hall.state().occasions.size()).is_equal(0)

func test_spoken_answers_only_choose_valid_options()->void:
	var a:=raise_visit("hunt")
	assert_str(Early.typed_choice(a,"share the catch").option).is_equal("share")
	for text in ["do not share the catch","if we can spare it, share the catch","should we share the catch?"]:
		assert_dict(Early.typed_choice(a,text)).is_empty()
	assert_str(AI.read_answer({"answer":"share","confidence":1.0},a).option).is_equal("share")
	assert_dict(AI.read_answer({"answer":"invented","confidence":1.0},a)).is_empty()
	var voice:=Voice.new()
	var scene:=voice.scene(a.id)
	var prompt:=voice.build_prompt(scene,"open",{})
	assert_str(prompt).contains("PERSONAL VISITOR FACTS")
	assert_str(prompt).not_contains("witness_roll")
	assert_str(voice._kind_words(scene)).contains("private visitor")
	var lines:=voice._offline_open(scene,Hall._rng("voice",400))
	assert_str(lines[0].text).is_equal(a.situation.visit.opening)
	voice.free()

func test_invalid_saved_visit_and_journey_rejected()->void:
	var a:=raise_visit("hunt")
	a.hidden.early.witness_roll=2.0
	assert_bool(Hall.validate_state(Hall.state())).is_false()
	assert_bool(Early.valid_jobs([{"audience":"a","civ":"b","name":"c","due":1,"chance":0.5,"roll":2,"prize":1}])).is_false()

func test_routine_generator_and_repeat_neighbour_use_personal_visits()->void:
	GameState.ensure_population_total(999)
	var occasion:={"key":"test-personal","type":"ambient","civ_id":met[0],"day":400,"expires":500,"data":{}}
	var a:=Hall._generate_foreign_occasion(occasion,400)
	assert_bool(Early.handles(a)).is_true()
	Hall._enqueue(a,400)
	Hall.resolve(a.id,"decline")
	assert_bool(Hall._speaker_allows(occasion,2000)).is_true()
	assert_bool(Hall._budget_allows(occasion,500)).is_false()
	assert_bool(Hall._business_mix(met[0],2000).has("early_visit")).is_true()
	GameState.ensure_population_total(1000)
	assert_bool(Hall._business_mix(met[0],2000).has("early_visit")).is_false()

func test_leaving_unanswered_is_not_a_diplomatic_insult()->void:
	var a:=raise_visit("hunt")
	var opinion:float=ForeignDiplomacy.civilization(met[0]).player_relation.opinion
	Hall._expire(500)
	assert_str(a.status).is_equal("expired")
	assert_float(float(ForeignDiplomacy.civilization(met[0]).player_relation.opinion)).is_equal(opinion)
	assert_int(Hall.state().occasions.size()).is_equal(0)

func test_guide_dispatches_real_scouts_and_blocks_duplicate_expedition()->void:
	var a:=raise_visit("traveller")
	var proposal:=CivilizationSystem.contact_investigation_proposal(met[0])
	assert_bool(proposal.get("ok",false)).override_failure_message(str(proposal)).is_true()
	if not proposal.get("ok",false):return
	var before:=CivilizationSystem.scout_missions.size()
	assert_bool(Hall.resolve(a.id,"explore").ok).is_true()
	assert_int(CivilizationSystem.scout_missions.size()).is_equal(before+1)
	assert_str(CivilizationSystem.scout_missions[-1].target_id).is_equal("contact:"+met[0])
	a=raise_visit("traveller")
	var food:=Hall.player_stock("Food")
	assert_bool(Hall.resolve(a.id,"explore").ok).is_false()
	assert_float(Hall.player_stock("Food")).is_equal(food)

func test_changed_knowledge_blocks_a_stale_craft_offer_before_migration()->void:
	var a:=raise_visit("craft")
	GameState.known_discoveries.append("clay_shaping")
	var food:=Hall.player_stock("Food")
	assert_bool(Hall.resolve(a.id,"welcome").ok).is_false()
	assert_float(GameState.population_exact).is_equal(200.0)
	assert_float(Hall.player_stock("Food")).is_equal(food)
