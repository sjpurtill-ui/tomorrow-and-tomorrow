extends GdUnitTestSuite
func before_test()->void:
	GameState.reset_for_new_world(112358)
	CivilizationSystem.reset_for_new_world()
func test_projection_bounds_summary_without_capping_actual_production()->void:
	GameState.simulation_metrics={"material_capacity":1.03,"food_days":35.0}
	var summary:Dictionary=CivilizationSystem.civilizations[0].duplicate(true)
	WorldSimulation.project(summary)
	assert_float(float(summary.production)).is_equal(1.0)
	assert_float(float(summary.food_days)).is_equal(35.0)
	assert_float(float(GameState.simulation_metrics.material_capacity)).is_equal(1.03)
func test_existing_shared_summary_overflow_loads()->void:
	var payload:=CivilizationSystem.export_state()
	payload.civilizations[0]["shared_rules"]=true
	payload.civilizations[0]["production"]=1.03
	assert_bool(CivilizationSystem.import_state(payload).has("error")).is_false()
	assert_float(float(CivilizationSystem.civilizations[0].production)).is_equal(1.0)
func test_negative_summary_remains_invalid()->void:
	var payload:=CivilizationSystem.export_state()
	payload.civilizations[0]["shared_rules"]=true
	payload.civilizations[0]["production"]=-0.1
	assert_bool(CivilizationSystem.import_state(payload).has("error")).is_true()

func test_collapsed_shared_population_summary_reopens_without_rewriting_input()->void:
	var payload:=CivilizationSystem.export_state()
	var population:=float(payload.civilizations[0].population)
	payload.civilizations[0]["shared_rules"]=true
	payload.civilizations[0].military_population=population*10
	payload.civilizations[0].military_share=10.0
	assert_bool(CivilizationSystem.import_state(payload).has("error")).is_false()
	assert_float(float(CivilizationSystem.civilizations[0].military_population)).is_equal(population)
	assert_float(float(payload.civilizations[0].military_share)).is_equal(10.0)
func test_new_military_projection_is_bounded_without_deleting_commitments()->void:
	MilitaryCampaign.reset_for_new_world()
	MilitaryCampaign.aggregate_recruits=10
	GameState.ensure_population_total(1)
	var summary:Dictionary=CivilizationSystem.civilizations[0].duplicate(true)
	WorldSimulation.project(summary)
	assert_float(float(summary.military_population)).is_less_equal(GameState.population_exact)
	assert_float(float(summary.military_share)).is_less_equal(1.0)
	assert_int(MilitaryCampaign.aggregate_recruits).is_equal(10)
	MilitaryCampaign.reset_for_new_world()

func test_prepared_foreign_formation_uses_the_same_readiness_range_as_combat()->void:
	var payload:=CivilizationSystem.export_state()
	payload.foreign_formations[0].readiness=1.25
	assert_bool(CivilizationSystem.import_state(payload).has("error")).is_false()
	assert_float(float(CivilizationSystem.foreign_formations[0].readiness)).is_equal(1.25)
func test_out_of_range_foreign_readiness_is_still_rejected()->void:
	for value in [-.1,1.5001,INF,NAN]:
		var payload:=CivilizationSystem.export_state()
		payload.foreign_formations[0].readiness=value
		assert_bool(CivilizationSystem.import_state(payload).has("error")).is_true()

func test_prepared_army_projects_normalized_summary_without_losing_readiness()->void:
	MilitaryCampaign.reset_for_new_world()
	MilitaryCampaign.home_army.readiness=1.25
	var summary:Dictionary=CivilizationSystem.civilizations[0].duplicate(true)
	WorldSimulation.project(summary)
	assert_float(float(summary.military_readiness)).is_equal(1.0)
	assert_float(float(MilitaryCampaign.home_army.readiness)).is_equal(1.25)
	MilitaryCampaign.reset_for_new_world()
func test_existing_shared_readiness_overflow_loads()->void:
	var payload:=CivilizationSystem.export_state()
	payload.civilizations[0]["shared_rules"]=true
	payload.civilizations[0].military_readiness=1.25
	assert_bool(CivilizationSystem.import_state(payload).has("error")).is_false()
	assert_float(float(CivilizationSystem.civilizations[0].military_readiness)).is_equal(1.0)
	assert_float(float(payload.civilizations[0].military_readiness)).is_equal(1.25)
