extends GdUnitTestSuite
## Standing (docs/STANDING_DESIGN.md): our strengths read from real state, each
## met people's view of us, the dangers Envy and Contempt, and their
## consequences: raids weigh fighting strength (warriors count), envy draws
## raiders, contempt brings demands, awe gifts; our warbands menace newcomers.

const Standing:=preload("res://scripts/standing.gd")
const War:=preload("res://scripts/war_loop.gd")
const Lives:=preload("res://scripts/court_lives.gd")

func before_test()->void:
	OS.set_environment("OPENAI_API_KEY","")
	GameState.reset_for_new_world(515151)
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
	GameState.elapsed_days=400.0
	Standing.forget()

func after_test()->void:
	Standing.forget()
	GameState.elapsed_days=0

func _met(population:float=120.0,warriors:float=6.0,readiness:float=0.55)->String:
	var civ:Dictionary=CivilizationSystem.civilizations[0]
	civ.player_relation.contact_level=2
	civ.player_relation.opinion=0.0
	civ.player_relation.border_tension=0.2
	civ.population=population
	civ.military_population=warriors
	civ.military_readiness=readiness
	ForeignDiplomacy.leader(String(civ.id))
	return String(civ.id)

func _rich(food_days:float)->void:
	GameState.simulation_metrics["food_days"]=food_days
	GameState.resource_stockpiles["Timber"]=600.0
	GameState.resource_stockpiles["Stone"]=600.0

func _arm(troops:int,readiness:float)->void:
	MilitaryCampaign.home_army["troops"]=troops
	MilitaryCampaign.home_army["readiness"]=readiness
	# The month's reading the daily systems use (ConsequenceEngine takes it monthly).
	Standing.record_monthly()

func test_strengths_are_read_from_state_with_reasons()->void:
	var our:=Standing.strengths()
	for id:String in ["might","genius","persuasion","cunning","wealth","splendor","order","endurance","reach"]:
		assert_bool(our.has(id)).override_failure_message(id).is_true()
		assert_float(float(our[id].value)).override_failure_message(id).is_between(0.0,1.0)
		assert_str(String(our[id].why)).override_failure_message(id).is_not_empty()

func test_warriors_count_in_fighting_strength_and_the_raid_ratio()->void:
	var id:=_met()
	_arm(0,0.3)
	var unarmed:=War.ratio(id)
	_arm(12,0.8)
	var armed:=War.ratio(id)
	assert_float(armed).is_less(unarmed*0.8)
	assert_float(Standing.strengths().might.value).is_greater(0.5)

func test_rich_and_unguarded_is_envied_and_held_in_contempt()->void:
	var id:=_met(160.0,10.0,0.7)
	_rich(120.0)
	_arm(0,0.3)
	var weak:=Standing.view_of(id)
	assert_bool(bool(weak.known)).is_true()
	assert_float(float(weak.envy)).is_greater(Standing.ENVY_RAID_FLOOR)
	assert_float(float(weak.contempt)).is_greater(Standing.CONTEMPT_FLOOR)
	_arm(14,0.85)
	var guarded:=Standing.view_of(id)
	assert_float(float(guarded.awe)).is_greater(float(weak.awe))
	assert_float(float(guarded.envy)).is_less(float(weak.envy))
	assert_float(float(guarded.contempt)).is_less(float(weak.contempt))
	# Might menaces: the same people find us less alluring when we bristle.
	assert_float(float(guarded.allure)).is_less_equal(float(weak.allure))

func test_views_move_the_envoys_business()->void:
	var id:=_met(160.0,10.0,0.7)
	_rich(120.0)
	_arm(0,0.3)
	var demands_weak:=Lives.standing_weight("tribute_demand",id)
	_arm(14,0.85)
	var demands_strong:=Lives.standing_weight("tribute_demand",id)
	assert_float(demands_weak).is_greater(demands_strong)
	assert_float(Lives.standing_weight("gift_goods",id)).is_greater_equal(1.0)

func test_a_people_never_met_holds_no_view()->void:
	var civ:Dictionary=CivilizationSystem.civilizations[0]
	civ.player_relation.contact_level=0
	var v:=Standing.view_of(String(civ.id))
	assert_bool(bool(v.known)).is_false()
	assert_float(float(v.envy)).is_equal(0.0)

func test_pride_is_ordinary_for_a_plain_village_and_menace_costs_allure()->void:
	_arm(0,0.3)
	assert_float(float(Standing.pride().value)).is_between(0.45,0.6)
	var calm:=Standing.attraction_shift()
	_arm(14,0.85)
	assert_float(Standing.attraction_shift()).is_less(calm)

func test_the_standing_page_says_what_we_are_and_how_each_people_sees_us()->void:
	var id:=_met(160.0,10.0,0.7)
	_rich(120.0)
	_arm(0,0.3)
	var page=preload("res://scripts/hud/content/dock_content_civilization.gd").new(null,null)
	var blocks:Array=page.tab(2).blocks
	assert_str(String(blocks[0].heading)).is_equal("What we are")
	assert_int((blocks[0].items as Array).size()).is_equal(9)
	var theirs:Dictionary={}
	for block:Dictionary in blocks:
		if String(block.get("heading","")).begins_with("How ") and String(block.get("heading","")).ends_with(" see us"):theirs=block
	assert_bool(theirs.is_empty()).is_false()
	var names:Array=[]
	for item:Dictionary in theirs.items:names.append(String(item.name).get_slice(":",0))
	assert_array(names).contains(["Allure","Awe","Fear","Respect","Trust","Resentment","Danger"])
	assert_str(String(blocks[-1].heading)).is_equal("Our own people")
	assert_bool(id!="").is_true()
