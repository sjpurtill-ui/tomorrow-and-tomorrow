extends GdUnitTestSuite

func before_test()->void:
	GameState.reset_for_new_world(4219)
	GameState.ensure_population_total(10000)
	MilitaryCampaign.reset_for_new_world()

func test_disability_is_a_subset_and_does_not_change_total_losses()->void:
	var sim:=CombatSimulator.new(); var rng:=RandomNumberGenerator.new(); rng.seed=981
	var loss:Dictionary=sim._casualty_breakdown(1000,rng,1.2)
	assert_int(int(loss.killed)+int(loss.wounded)+int(loss.scattered)).is_equal(1000)
	assert_int(int(loss.disabled)).is_greater(0)
	assert_int(int(loss.disabled)).is_less_equal(int(loss.wounded))
	assert_int(int(loss.severe_disability)).is_less_equal(int(loss.disabled))

func test_disabled_wounds_never_recover_into_full_strength()->void:
	var sim:=CombatSimulator.new()
	var force:=sim.create_formation_force("Veterans",[{"id":1,"unit":"line_infantry","weapon":"spear","count":100}],1,1)
	force["wounded_pool"]=20; force["disabled_pool"]=20; force["severe_disabled_pool"]=5
	for day in 50:
		var recovery:=sim.advance_preparation_day(force,{"logistics":1.0,"replacement_manpower":0})
		force=recovery.force
	assert_int(int(force.wounded_pool)).is_equal(20)
	assert_int(int(force.disabled_pool)).is_equal(20)
	assert_int(int(force.troops)).is_equal(100)

func test_demobilization_preserves_people_and_transfers_capacity_loss_once()->void:
	MilitaryCampaign.home_army={"troops":0,"formations":[],"wounded_pool":20,"disabled_pool":20,"severe_disabled_pool":5}
	var before:=GameState.population_total
	var result:=MilitaryCampaign.demobilize(20)
	assert_int(int(result.released)).is_equal(20)
	assert_int(GameState.population_total).is_equal(before)
	assert_int(PermanentInjuries.total(GameState.civilian_injuries)).is_equal(20)
	assert_int(int(MilitaryCampaign.home_army.wounded_pool)).is_equal(0)
	MilitaryCampaign.demobilize(20)
	assert_int(PermanentInjuries.total(GameState.civilian_injuries)).is_equal(20)

func test_effective_production_depends_on_job_demands_not_headcount_loss()->void:
	GameState.population_allocations={"Food":100,"Extraction":100,"Knowledge":100}
	GameState.civilian_injuries={"limited":50.0,"severe":50.0}
	assert_float(GameState.effective_workers("Food")).is_less(100)
	assert_float(GameState.effective_workers("Knowledge")).is_greater(GameState.effective_workers("Extraction"))
	assert_int(GameState.population_allocations.Food).is_equal(100)
	var impaired:Dictionary=FoodSystem._produce(GameState.effective_workers("Food"),1,1,false)
	var healthy:Dictionary=FoodSystem._produce(100,1,1,false)
	var a:=0.0; var b:=0.0
	for value in impaired.values(): a+=float(value)
	for value in healthy.values(): b+=float(value)
	assert_float(a).is_less(b)

func test_battle_totals_do_not_double_count_disabled_survivors()->void:
	var rounds:=[{"attacker_losses":100,"attacker_casualties":{"killed":20,"wounded":50,"disabled":10,"scattered":30}}]
	var summary:=BattleLossSummary.from_rounds(rounds,0,900)
	assert_int(int(summary.starting)).is_equal(1000)
	assert_int(int(summary.casualties)).is_equal(70)
	assert_int(int(summary.out_of_action)).is_equal(100)
	assert_int(int(summary.disabled)).is_equal(10)

func test_old_reports_never_fabricate_disability_counts()->void:
	var summary:=BattleLossSummary.from_rounds([{"defender_losses":4,"defender_casualties":{"killed":1,"wounded":3,"scattered":0}}],1,96)
	assert_bool(bool(summary.disability_recorded)).is_false()
	assert_int(int(summary.disabled)).is_equal(0)

func test_billion_scale_uses_the_same_two_injury_cohorts()->void:
	GameState.civilian_injuries={"limited":100000000.0,"severe":50000000.0}
	GameState.population_allocations={"Extraction":500000000,"Knowledge":500000000}
	assert_int(GameState.civilian_injuries.size()).is_equal(2)
	assert_float(GameState.effective_workers("Extraction")).is_between(0.0,500000000.0)
	assert_int(PermanentInjuries.total(GameState.civilian_injuries)).is_equal(150000000)

func test_returned_field_army_keeps_injury_subsets()->void:
	MilitaryCampaign.field_armies=[{"army_id":41,"status":"stationed","location_id":"player_home","troops":0,"formations":[],"wounded_pool":20,"disabled_pool":12,"severe_disabled_pool":4}]
	var result:=MilitaryCampaign.disband_field_army(41)
	assert_bool(result.get("ok",false)).is_true()
	assert_int(int(MilitaryCampaign.home_army.wounded_pool)).is_equal(20)
	assert_int(int(MilitaryCampaign.home_army.disabled_pool)).is_equal(12)
	MilitaryCampaign.demobilize(12)
	assert_int(PermanentInjuries.total(GameState.civilian_injuries)).is_equal(12)
	assert_int(int(MilitaryCampaign.home_army.wounded_pool)).is_equal(8)

func test_water_clipping_catches_crossing_triangles_with_vertices_outside()->void:
	var landscape:=BattleLandscape.new()
	var polygon:Array[Vector2]=[Vector2(-500,-500),Vector2(500,-500),Vector2(0,500)]
	for axis in 2:
		polygon=landscape._clip_water(polygon,axis,-160,-1)
		polygon=landscape._clip_water(polygon,axis,160,1)
	assert_int(polygon.size()).is_greater_equal(3)
	for point in polygon:
		assert_float(absf(point.x)).is_less_equal(160.001)
		assert_float(absf(point.y)).is_less_equal(160.001)
	landscape.free()
