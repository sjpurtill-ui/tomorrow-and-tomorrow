extends GdUnitTestSuite
const Eras=preload("res://scripts/technology_eras.gd")

func before_test()->void:
	WorldSimulation.clear()
	GameState.reset_for_new_world(314159);DiscoverySystem.reset_for_new_world();DiscoverySystem.initialize()
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)

func after_test()->void:
	GameState.elapsed_days=0
	WorldSimulation.clear()
	GameState.set_process(true);CivilizationSystem.set_process(true);MilitaryCampaign.set_process(true)

func test_every_catalog_discovery_has_a_dated_period()->void:
	var missing:Array[String]=[]
	for entry:Dictionary in DiscoverySystem.technology_catalog:
		# 600-year design discoveries are dated by their design year instead.
		if not Eras.HISTORICAL_YEAR.has(String(entry.id)) and not preload("res://scripts/research_600_catalog.gd").has(String(entry.id)):missing.append(String(entry.id))
	assert_array(missing).is_empty()

func test_pacing_curve_matches_campaign_targets()->void:
	assert_float(Eras.game_year_for(-8000)).is_equal(0.0)
	assert_float(Eras.game_year_for(-3000)).is_equal_approx(300.0,0.01)
	assert_float(Eras.game_year_for(1800)).is_equal_approx(2400.0,0.01)
	assert_float(Eras.game_year_for(2100)).is_equal(3000.0)

func test_no_discovery_is_dated_before_its_required_foundations()->void:
	var violations:Array[String]=[]
	for entry:Dictionary in DiscoverySystem.technology_catalog:
		var era:=DiscoverySystem.discovery_era(String(entry.id))
		for parent in entry.get("requires_all",[]):
			if DiscoverySystem.discovery_era(String(parent))>era+0.01:violations.append("%s<%s" % [entry.id,parent])
	assert_array(violations).is_empty()

func test_inquiry_far_beyond_scholarship_is_prohibitively_slow()->void:
	GameState.scholarship_level=150.0
	var bronze:=DiscoverySystem.discovery_definition("copper_smelting")
	var induction:=DiscoverySystem.discovery_definition("electromagnetic_induction")
	assert_float(DiscoverySystem.era_cost_multiplier(bronze)).is_equal(1.0)
	assert_float(DiscoverySystem.era_cost_multiplier(induction)).is_greater(1000000.0)
	assert_float(DiscoverySystem.research_difficulty(induction,314159)).is_greater(DiscoverySystem.research_difficulty(induction,314159,2400.0)*1000.0)
	# The same question is ordinary work once scholarship has matured.
	assert_float(DiscoverySystem.era_cost_multiplier(induction,2400.0)).is_equal(1.0)

func test_lines_prefer_questions_of_their_age()->void:
	GameState.scholarship_level=150.0
	var bronze:=DiscoverySystem.discovery_definition("copper_smelting")
	var induction:=DiscoverySystem.discovery_definition("electromagnetic_induction")
	var penalty:=DiscoverySystem._candidate_score(induction)-DiscoverySystem._candidate_score(bronze)
	assert_float(penalty).is_less(-150.0)

func test_scholarship_advances_with_research_program_not_grants()->void:
	GameState.scholarship_level=0.0
	var known_before:=GameState.known_discoveries.duplicate()
	var staffed:=DiscoverySystem.scholarship_rate()
	assert_float(staffed).is_between(0.3,1.35)
	GameState.population_allocations["Knowledge"]=0
	GameState.population_allocation_percentages["Knowledge"]=0.0
	assert_float(DiscoverySystem.scholarship_rate()).is_less_equal(staffed)
	assert_array(GameState.known_discoveries).is_equal(known_before)

func test_older_saves_start_from_known_breadth_never_past_elapsed_time()->void:
	GameState.scholarship_level=-1.0
	GameState.elapsed_days=365*40
	GameState.known_discoveries.append_array(["electromagnetic_induction","electrochemical_cells","relay_logic"])
	var level:=DiscoverySystem.scholarship_level()
	assert_float(level).is_less_equal(40.0)
	assert_float(GameState.scholarship_level).is_equal(level)
