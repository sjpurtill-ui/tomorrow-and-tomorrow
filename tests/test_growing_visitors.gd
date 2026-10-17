extends GdUnitTestSuite
const Hall=preload("res://scripts/audience_hall.gd")
const Early=preload("res://scripts/early_visitors.gd")
const Society=preload("res://scripts/society_exchange.gd")
const AI=preload("res://scripts/envoy_request_ai.gd")
const Voice=preload("res://scripts/audience_voice.gd")
const Growing=preload("res://scripts/growing_visitors.gd")
const Access=preload("res://scripts/resource_access.gd")
const Pacts=preload("res://scripts/trade_pacts.gd")
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
	GameState.ensure_population_total(2000); GameState.housing_capacity=2600
	GameState.settlement_site_committed=true; GameState.settlement_founded_day=0; GameState.settlement_completed=["Hearth Circle"]; SettlementModel.ensure_founded()
	GameState.water_metrics.intake_ratio=1.0
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
			WorldSimulation.state.ensure_population_total(2000)
			WorldSimulation.state.known_discoveries.assign(["clay_shaping"])
			WorldSimulation.state.discovery_adoption.clay_shaping=1.0
			WorldSimulation.state.resource_stockpiles.Food=100000.0
			WorldSimulation.state.food_stocks={"Preserved food":100000.0})
		var civ:=ForeignDiplomacy.civilization(id)
		civ.player_relation.encounter_position={"x":civ.world_position.x,"z":civ.world_position.y}
		civ.food_days=60.0;civ.health=0.8;civ.player_relation.opinion=0.3;civ.player_relation.border_tension=0.2
	GameState.known_discoveries.erase("clay_shaping")

func after_test()->void:
	WorldSimulation.clear()


func visit(kind:String,civ:String="")->Dictionary:
	var a:=Growing.generate(civ,{},int(GameState.elapsed_days),kind)
	assert_bool(a.is_empty()).override_failure_message("Missing visit: "+kind).is_false()
	if not a.is_empty():Hall._enqueue(a,int(GameState.elapsed_days))
	return a

func quarry()->Dictionary:
	var d:=ResourceSystem._deposit("Stone",GameState.settlement_founded_at+Vector3(24,0,0),1.0,100.0,1)
	d.stage="accessible"
	Society.owner_state(met[0]).resource_deposits.append(d)
	return d

func test_population_gates_and_pacing()->void:
	assert_bool(Growing.active()).is_true()
	assert_int(Hall._gap()).is_equal(1095)
	GameState.ensure_population_total(5000)
	assert_int(Hall._gap()).is_equal(365)
	GameState.ensure_population_total(10000)
	assert_bool(Growing.active()).is_false()
	GameState.ensure_population_total(999)
	assert_bool(Growing.active()).is_false()
	assert_array(Growing.eligible(met[0])).is_empty()

func test_no_invented_pressure_or_deposit()->void:
	assert_array(Growing.eligible(met[0])).is_empty()
	assert_array(Growing.eligible("")).is_empty()
	quarry()
	assert_array(Growing.eligible(met[0])).contains(["quarry"])

func test_food_is_a_real_scheduled_exchange()->void:
	GameState.simulation_metrics.food_days=12
	var a:=visit("food",met[0])
	if a.is_empty():return
	assert_bool(Hall._valid_audience(a)).is_true()
	var before:=Hall.player_stock("Food")
	var wood:=Hall.player_stock("Timber")
	assert_bool(Hall.resolve(a.id,"trade").ok).is_true()
	assert_float(Hall.player_stock("Food")).is_equal(before)
	var p:Dictionary=Pacts.pacts(met[0])[0]
	GameState.elapsed_days=int(p.due)
	Pacts.daily(int(GameState.elapsed_days))
	assert_float(Hall.player_stock("Food")).is_greater(before)
	assert_float(Hall.player_stock("Timber")).is_less(wood)
	assert_bool(Hall.resolve(a.id,"trade").ok).is_false()

func test_quarry_reserves_workers_depletes_source_and_delays_delivery()->void:
	var d:=quarry()
	var a:=visit("quarry",met[0])
	if a.is_empty():return
	assert_bool(Hall._valid_audience(a)).is_true()
	assert_bool(Hall.resolve(a.id,"access").ok).is_true()
	var c:Dictionary=Access.contracts()[0]
	var before:=Hall.player_stock("Stone")
	var host_before:=Hall.foreign_stock(met[0],"Stone")
	GameState.elapsed_days+=1
	var remaining:=Access.work(40,40,{"tools":0.5})
	assert_vector(remaining).is_equal(Vector2(30,30))
	assert_float(float(d.remaining)).is_equal(100.0)
	GameState.elapsed_days+=int(c.travel)+1
	Access.work(40,40,{"tools":0.5})
	assert_float(float(d.remaining)).is_less(100)
	assert_float(Hall.player_stock("Stone")).is_equal(before)
	assert_float(Hall.foreign_stock(met[0],"Stone")).is_greater(host_before)
	var extracted:=float(c.extracted)
	Access.work(40,40,{"tools":0.5})
	assert_float(float(c.extracted)).is_equal(extracted)
	GameState.elapsed_days+=int(c.travel)
	Access.daily(int(GameState.elapsed_days))
	assert_float(Hall.player_stock("Stone")-before).is_equal_approx(extracted*0.75,0.001)
	assert_float(float(d.remaining)+float(c.paid)+float(c.delivered)).is_equal_approx(100,0.001)
	assert_bool(Hall.validate_state(JSON.parse_string(JSON.stringify(Hall.state())))).is_true()

func test_war_revokes_access_and_releases_workers()->void:
	quarry()
	var a:=visit("quarry",met[0]);if a.is_empty():return
	Hall.resolve(a.id,"access")
	ForeignDiplomacy.civilization(met[0]).player_relation.at_war=true
	GameState.elapsed_days+=1
	assert_vector(Access.work(40,40,{})).is_equal(Vector2(40,40))
	assert_str(Access.contracts()[0].status).is_equal("ended")

func test_households_use_reception_capacity_and_conserve_population()->void:
	var source:=Society.owner_state(met[0])
	source.simulation_metrics.food_days=5
	var a:=visit("households",met[0]);if a.is_empty():return
	assert_bool(Hall._valid_audience(a)).is_true()
	var total:=float(GameState.population_exact+source.population_exact)
	var before:=Hall.player_stock("Food")
	var result:=Hall.resolve(a.id,"admit")
	assert_bool(result.ok).override_failure_message(String(result.outcome)).is_true()
	assert_float(float(GameState.population_exact+source.population_exact)).is_equal_approx(total,0.001)
	assert_float(before-Hall.player_stock("Food")).is_equal(float(a.situation.visit.people))
	assert_bool(Hall.resolve(a.id,"admit").ok).is_false()

func test_changed_capacity_blocks_admission_without_spending()->void:
	Society.owner_state(met[0]).simulation_metrics.food_days=5
	var a:=visit("households",met[0]);if a.is_empty():return
	GameState.housing_capacity=100
	var before:=Hall.player_stock("Food")
	assert_bool(Hall.resolve(a.id,"admit").ok).is_false()
	assert_float(Hall.player_stock("Food")).is_equal(before)

func test_release_uses_defense_allocation_without_creating_people()->void:
	GameState.simulation_metrics.food_days=10
	preload("res://scripts/watch_military.gd").move(50)
	var a:=visit("army");if a.is_empty():return
	var total:=GameState.population_exact
	var defense:=int(GameState.population_allocations.Defense)
	assert_bool(Hall.resolve(a.id,"release").ok).is_true()
	Growing.daily(int(GameState.elapsed_days)+1)
	assert_int(int(GameState.population_allocations.Defense)).is_less(defense)
	assert_float(GameState.population_exact).is_equal(total)
	assert_bool(Growing.valid_jobs(Growing.jobs())).is_true()

func test_relocation_preserves_national_cohorts_and_leaves_buildings()->void:
	var source:Dictionary=GameState.player_settlements[0]
	GameState.simulation_metrics.food_days=10
	var target:Dictionary=source.duplicate(true)
	target.id="settlement_test";target.primary=false;target.population_share=0.2;target.position+=Vector2(24,0)
	target.local_state={"housing_capacity":700,"simulation_metrics":{"food_days":60},"water_metrics":{"intake_ratio":1.0}}
	GameState.player_settlements.append(target)
	var a:=visit("relocate");if a.is_empty():return
	var national:=GameState.population_exact
	var cohorts:=GameState.population_cohorts.duplicate(true)
	var old_source:=SettlementModel._settlement_population(source)
	var old_target:=SettlementModel._settlement_population(target)
	var buildings:=GameState.settlement_completed.duplicate()
	assert_bool(Hall.resolve(a.id,"move").ok).is_true()
	assert_float(SettlementModel._settlement_population(target)).is_equal(old_target)
	GameState.elapsed_days+=int(a.situation.visit.days)
	Growing.daily(int(GameState.elapsed_days))
	assert_float(SettlementModel._settlement_population(target)).is_equal(old_target+int(a.situation.visit.people))
	assert_float(SettlementModel._settlement_population(source)).is_equal(old_source-int(a.situation.visit.people))
	assert_float(GameState.population_exact).is_equal(national)
	assert_dict(GameState.population_cohorts).is_equal(cohorts)
	assert_array(GameState.settlement_completed).is_equal(buildings)

func test_voice_and_typed_choice_only_offer_executable_decisions()->void:
	quarry()
	var a:=visit("quarry",met[0]);if a.is_empty():return
	assert_bool(Hall.resolve(a.id,"hear").keep_open).is_true()
	assert_dict(Growing.typed_choice(a,"do not accept the quarry terms")).is_empty()
	assert_str(String(Growing.typed_choice(a,"Accept the quarry terms").option)).is_equal("access")
	var voice:=Voice.new()
	voice.force_offline=true
	var scene:=voice.scene(String(a.id))
	assert_str(String(scene.sit_type)).is_equal("growing_visit")
	var lines:Array=voice._offline_open(scene,Hall._rng("test",400))
	assert_str(String(lines[0].text)).is_equal(String(a.situation.visit.opening))
	voice.free()

func test_supplier_visit_changes_general_objective_and_keeps_pact()->void:
	GameState.simulation_metrics.food_days=12
	var terms:=Growing.food_terms(met[0])
	assert_bool(terms.is_empty()).is_false()
	var sealed:=Pacts.seal(met[0],terms)
	preload("res://scripts/war_loop.gd").front(met[0]).stance="punish"
	var a:=visit("suppliers")
	if a.is_empty():return
	assert_bool(Hall._valid_audience(a)).is_true()
	assert_bool(Hall.resolve(a.id,"recall").ok).is_true()
	assert_str(preload("res://scripts/war_council.gd").stance_of(met[0])).is_equal("leave")
	assert_str(String(sealed.pact.status)).is_equal("active")

func test_saved_access_and_delegations_reject_corruption()->void:
	quarry()
	var a:=visit("quarry",met[0]);if a.is_empty():return
	Hall.resolve(a.id,"access")
	var saved:Dictionary=JSON.parse_string(JSON.stringify(Hall.state()))
	assert_bool(Hall.validate_state(saved)).is_true()
	saved.resource_access[0].royalty=2.0
	assert_bool(Hall.validate_state(saved)).is_false()

func test_expiry_and_manual_end_stop_mining_but_deliver_existing_cargo()->void:
	quarry()
	var a:=visit("quarry",met[0]);if a.is_empty():return
	Hall.resolve(a.id,"access")
	var c:Dictionary=Access.contracts()[0]
	GameState.elapsed_days+=int(c.travel)+1
	Access.work(40,40,{})
	assert_float(float(c.extracted)).is_greater(0.0)
	Access.stop(String(c.id))
	GameState.elapsed_days+=int(c.travel)
	assert_vector(Access.work(40,40,{})).is_equal(Vector2(40,40))
	assert_float(float(c.delivered)).is_equal_approx(float(c.extracted)*0.75,0.001)
	assert_str(String(Access.card(String(c.id)).state)).is_equal("done")

func test_domestic_visit_spends_budget_and_waits_after_decline()->void:
	GameState.simulation_metrics.food_days=10
	preload("res://scripts/watch_military.gd").move(50)
	var a:=visit("army");if a.is_empty():return
	assert_bool(preload("res://scripts/envoy_requests.gd").answerable(a)).is_true()
	assert_str(String(AI.read_answer({"answer":"release","confidence":1.0},a).option)).is_equal("release")
	assert_int(int(Hall.state().last_arrival_day)).is_equal(400)
	assert_bool(Hall._budget_allows({},401)).is_false()
	Hall.resolve(a.id,"decline")
	assert_array(Growing.jobs()).is_empty()

func test_resource_access_control_ends_actual_contract()->void:
	quarry()
	var a:=visit("quarry",met[0]);if a.is_empty():return
	Hall.resolve(a.id,"access")
	var panel:=preload("res://scripts/hud/court_council_panel.gd").new()
	add_child(panel)
	var buttons:=panel.access_box.find_children("*","Button",true,false)
	assert_int(buttons.size()).is_equal(1)
	if not buttons.is_empty():buttons[0].pressed.emit()
	assert_str(String(Access.contracts()[0].status)).is_equal("ended")
	await get_tree().process_frame
	remove_child(panel);panel.free()

func test_foreign_work_shares_one_world_reserve_and_cannot_run_twice()->void:
	var d:=quarry()
	d.world_key="test_shared_quarry"
	WorldSimulation.geography_stock[d.world_key]={"remaining":100.0,"initial_amount":100.0}
	WorldSimulation.enabled=true
	var a:=visit("quarry",met[0]);if a.is_empty():return
	Hall.resolve(a.id,"access")
	var c:Dictionary=Access.contracts()[0]
	GameState.elapsed_days+=int(c.travel)+1
	Access.work(40,40,{})
	var remaining:=float(WorldSimulation.geography_stock[d.world_key].remaining)
	assert_float(remaining).is_less(100.0)
	assert_float(remaining+float(c.extracted)).is_equal_approx(100.0,0.001)
	Access.work(40,40,{})
	assert_float(float(WorldSimulation.geography_stock[d.world_key].remaining)).is_equal(remaining)

func test_new_military_objective_cancels_pending_release()->void:
	Growing.add_job({"id":"recall_test","type":"release","people":20,"released":0,"fronts":[met[0]],"status":"active","reason":"Waiting","start":400})
	preload("res://scripts/war_loop.gd").front(met[0]).stance="punish"
	var before:=int(GameState.population_allocations.Defense)
	Growing.daily(401)
	assert_int(int(GameState.population_allocations.Defense)).is_equal(before)
	assert_str(String(Growing.jobs()[0].status)).is_equal("ended")

func test_pending_visit_survives_population_cutoff()->void:
	quarry()
	var a:=visit("quarry",met[0]);if a.is_empty():return
	GameState.ensure_population_total(10000)
	assert_bool(Growing.active()).is_false()
	assert_bool(Hall.resolve(a.id,"access").ok).is_true()
	var saved:Dictionary=JSON.parse_string(JSON.stringify(Hall.state()))
	assert_bool(Hall.validate_state(saved)).is_true()
	ForeignDiplomacy.audiences=saved
	GameState.elapsed_days+=5
	Access.work(40,40,{})
	assert_float(float(Access.contracts()[0].extracted)).is_greater(0.0)
