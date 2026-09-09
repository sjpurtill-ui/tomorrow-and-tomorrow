extends GdUnitTestSuite
func test_registering_player_home_never_relocates_rivals_or_their_forces()->void:
	GameState.reset_for_new_world(112358)
	CivilizationSystem.reset_for_new_world()
	CivilizationSystem.set_scout_geography_authority(func(_p:Vector2)->bool:return true)
	var homes:Array=[]
	for civ:Dictionary in CivilizationSystem.civilizations:homes.append(CivilizationSystem._civilization_world_position(civ))
	var formations:=CivilizationSystem.foreign_formations.duplicate(true)
	for origin in [Vector2.ZERO,Vector2(700,320),Vector2(-1800,2300)]:
		CivilizationSystem.register_player_origin(origin)
		for i in homes.size():assert_vector(CivilizationSystem._civilization_world_position(CivilizationSystem.civilizations[i])).is_equal(homes[i])
	assert_array(CivilizationSystem.foreign_formations).is_equal(formations)
func test_foreign_leaders_share_civic_personality_axes_and_prioritize_survival()->void:
	var model=preload("res://scripts/leader_personality.gd")
	var p:=model.foreign(123,"civ_01")
	assert_dict(p).is_equal(model.foreign(123,"civ_01"))
	assert_int(p.size()).is_equal(5)
	for value in p.values():assert_float(float(value)).is_between(.12,.92)
	assert_str(model.agenda({"food_days":3,"population":120,"food_capacity":80},p)[0].strategy).is_equal("sustenance")
	assert_str(model.agenda({"food_days":80,"population":120,"food_capacity":200,"player_relation":{"at_war":true}},p)[0].strategy).is_equal("fortification")

func test_new_civilizations_start_with_one_settlement_and_the_player_population()->void:
	GameState.reset_for_new_world(424242);GameState.initialize_population_model()
	CivilizationSystem.reset_for_new_world()
	var sites:=CivilizationSystem.city_intelligence.sites(false)
	assert_int(sites.size()).is_equal(CivilizationSystem.civilizations.size())
	for civ:Dictionary in CivilizationSystem.civilizations:
		assert_int(int(civ.population)).is_equal(GameState.population_total)
		var founded:=0;var accounted:=0.0
		for region:Dictionary in civ.strategic_regions:
			accounted+=float(region.population)
			if bool(region.settlement_founded):founded+=1
			else:assert_float(float(region.population)).is_equal(0.0)
		assert_int(founded).is_equal(1)
		assert_float(accounted).is_equal(float(civ.population))
		for age:String in CivilizationSystem.AGE_COHORTS:assert_float(float(civ.cohorts[age])).is_equal(float(GameState.population_cohorts[age]))
	assert_array(CivilizationSystem.validate_state()).is_empty()

func test_more_people_cannot_create_unfunded_cities()->void:
	GameState.reset_for_new_world(424242);CivilizationSystem.reset_for_new_world()
	var civ:Dictionary=CivilizationSystem.civilizations[0].duplicate(true)
	civ.population=12000000;civ.production=.9;civ.institutions=.9
	var result:=ProgressionSystem.advance_rival(civ)
	assert_int(int(result.settlement_count)).is_equal(1)
