extends GdUnitTestSuite
func before_test()->void:
	GameState.reset_for_new_world(74017);MilitaryCampaign.reset_for_new_world()
	GameState.ensure_population_total(400);GameState.initialize_population_model()
	GameState.population_health=.97;GameState.food_security=.98;GameState.housing_capacity=500
	GameState.population_allocations.Defense=6
	MilitaryCampaign.home_army=MilitaryCampaign.simulator.create_formation_force("Home",[],.99,.5)
	MilitaryCampaign.home_army.service_strain=1.0;MilitaryCampaign.home_army.supply_level=.70
	for i in 6:MilitaryCampaign.home_army.formations.append({"id":i+1,"unit":"levy","weapon":"improvised","count":1,"authorized_count":1,"training":.39,"personnel_condition":.05,"equipment":0,"equipment_required":1,"ammunition":0,"ammunition_required":0})
	MilitaryCampaign.home_army.troops=6;MilitaryCampaign.next_formation_id=7
	MilitaryCampaign.army_templates=[{"template_id":1,"name":"Eight","entries":[{"unit":"levy","weapon":"improvised","count":8}]}]
func test_refresh_does_not_damage_people_or_change_population()->void:
	MilitaryCampaign.home_army.formations[0].personnel_condition=.8
	for i in 100:MilitaryCampaign._refresh_readiness()
	assert_float(float(MilitaryCampaign.home_army.formations[0].personnel_condition)).is_equal(.8)
	assert_int(MilitaryCampaign._mobilized_count()).is_equal(6)
func test_six_home_zero_training_two_unfilled_wait_without_partial_intake()->void:
	var entry:Dictionary=MilitaryCampaign.army_template_snapshot().templates[0].entries[0]
	assert_int(int(entry.ready)).is_equal(6);assert_int(int(entry.in_training)).is_equal(0);assert_int(int(entry.unfilled)).is_equal(2)
	var result:=MilitaryCampaign.queue_template_training(1)
	assert_int(int(result.get("queued",0))).is_equal(0)
	assert_int(MilitaryCampaign._mobilized_count()).is_equal(6)
	assert_array(MilitaryCampaign.training_queue).is_empty()
	assert_bool(MilitaryCampaign.army_templates[0].recruitment_requested).is_true()
func test_unfilled_order_survives_capacity_block_then_fills_without_second_click()->void:
	GameState.ensure_population_total(210)
	MilitaryCampaign.queue_template_training(1)
	assert_bool(MilitaryCampaign.army_templates[0].recruitment_requested).is_true()
	var payload:Dictionary=MilitaryCampaign.export_state()
	assert_bool(bool(payload.army_templates[0].recruitment_requested)).is_true()
	GameState.ensure_population_total(400)
	GameState.population_allocations.Defense=20
	MilitaryCampaign.military_inventory.improvised=8
	FoodSystem.initialize();FoodSystem.receive_external_food(10000)
	MilitaryCampaign._process_requested_templates()
	assert_int(MilitaryCampaign._matching_home_count("levy","improvised")+MilitaryCampaign._matching_training_count("levy","improvised")).is_equal(8)
func test_groups_preserve_six_soldiers_and_equipment_without_merging_cohort_state()->void:
	var groups:=MilitaryCampaign.grouped_home_formations()
	assert_int(groups.size()).is_equal(1);assert_int(int(groups[0].count)).is_equal(6)
	assert_int(int(groups[0].equipment_required)).is_equal(6)
	assert_int(MilitaryCampaign.home_army.formations.size()).is_equal(6)
func test_moderate_supplied_home_duty_recovers_strain_and_condition()->void:
	MilitaryCampaign.home_army.service_strain=.4
	var before:=MilitaryCampaign._force_personnel_condition(MilitaryCampaign.home_army)
	for day in 30:
		MilitaryCampaign._process_service_strain_day()
		MilitaryCampaign.record_daily_provisions(6,6)
		MilitaryCampaign._refresh_readiness()
	assert_float(float(MilitaryCampaign.home_army.service_strain)).is_less(.4)
	assert_float(MilitaryCampaign._force_personnel_condition(MilitaryCampaign.home_army)).is_greater(before)
	assert_int(int(MilitaryCampaign.home_army.troops)).is_equal(6)

func test_full_intake_reserves_equipment_and_cancel_returns_it()->void:
	GameState.population_allocations.Defense=20
	MilitaryCampaign.military_inventory.improvised=8
	FoodSystem.initialize();FoodSystem.receive_external_food(10000)
	var before:=GameState.population_total
	assert_int(int(MilitaryCampaign.queue_template_training(1).get("queued",0))).is_equal(8)
	assert_int(int(MilitaryCampaign.military_inventory.improvised)).is_equal(0)
	assert_int(int(MilitaryCampaign.training_queue[0].reserved_equipment)).is_equal(8)
	MilitaryCampaign.cancel_training(int(MilitaryCampaign.training_queue[0].id))
	assert_int(int(MilitaryCampaign.military_inventory.improvised)).is_equal(8)
	assert_int(GameState.population_total).is_equal(before)
	assert_int(MilitaryCampaign._mobilized_count()).is_equal(8)

func test_full_batch_completes_together_with_reserved_equipment_and_no_people_created()->void:
	GameState.population_allocations.Defense=20
	MilitaryCampaign.military_inventory.improvised=8
	FoodSystem.initialize();FoodSystem.receive_external_food(10000)
	var before:=GameState.population_total
	MilitaryCampaign.queue_template_training(1)
	assert_int(int(MilitaryCampaign.home_army.troops)).is_equal(0)
	assert_int(MilitaryCampaign._queued_trainees()).is_equal(8)
	var payload:Dictionary=JSON.parse_string(JSON.stringify(MilitaryCampaign.export_state()))
	assert_bool(MilitaryCampaign.import_state(payload).has("ok")).is_true()
	for day in 100:
		if MilitaryCampaign.training_queue.is_empty():break
		MilitaryCampaign._process_training_day()
	assert_array(MilitaryCampaign.training_queue).is_empty()
	assert_int(int(MilitaryCampaign.home_army.troops)).is_equal(8)
	assert_int(GameState.population_total).is_equal(before)
	assert_int(int(MilitaryCampaign.home_army.formations[0].equipment)).is_equal(8)
	assert_int(MilitaryCampaign._mobilized_count()).is_equal(8)

func test_batch_holds_finished_members_and_cancels_all_members()->void:
	MilitaryCampaign.training_queue=[
		{"id":101,"build_batch":1,"unit":"levy","weapon":"improvised","count":3,"progress_days":10.0,"required_days":10.0,"reserved_equipment":3},
		{"id":102,"build_batch":1,"unit":"levy","weapon":"improvised","count":5,"progress_days":2.0,"required_days":20.0,"reserved_equipment":5}]
	MilitaryCampaign.military_inventory.improvised=0
	MilitaryCampaign._complete_ready_build_batches()
	assert_int(MilitaryCampaign.training_queue.size()).is_equal(2)
	assert_int(int(MilitaryCampaign.home_army.troops)).is_equal(6)
	assert_int(int(MilitaryCampaign.cancel_training(101).returned)).is_equal(8)
	assert_array(MilitaryCampaign.training_queue).is_empty()
	assert_int(int(MilitaryCampaign.military_inventory.improvised)).is_equal(8)
