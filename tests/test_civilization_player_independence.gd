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
