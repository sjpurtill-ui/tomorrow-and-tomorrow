extends GdUnitTestSuite
func before_test()->void:
	GameState.reset_for_new_world(61044)
	GameState.ensure_population_total(1000)
	GameState.settlement_site_committed=true
	CivilizationSystem.scout_missions.clear();CivilizationSystem.diplomatic_mission.clear()
	MilitaryCampaign.reset_for_new_world()
	MilitaryCampaign.home_army=MilitaryCampaign.simulator.create_formation_force("Home",[],.9,.8)
	MilitaryCampaign.army_templates=[{"template_id":1,"name":"Levy","entries":[{"unit":"levy","weapon":"improvised","count":10}]}]
	MilitaryCampaign.military_inventory.improvised=100
	FoodSystem.reset_for_new_world();FoodSystem.receive_external_food(100000)
func test_draft_has_no_discovery_percentage_cap_and_displaces_labor()->void:
	var adults:=roundi(float(GameState.population_cohorts.working_age))
	var food_workers:=GameState.effective_workers("Food")
	var raised:=MilitaryCampaign.raise_recruits(adults)
	assert_int(int(raised.raised)).is_equal(adults)
	assert_int(int(MilitaryCampaign.raise_recruits(100).raised)).is_equal(0)
	assert_int(int(MilitaryCampaign.population_commitment_snapshot().excess_beyond_defense)).is_greater(0)
	assert_int(GameState.population_total).is_equal(1000)
	assert_float(GameState.effective_workers("Food")).is_equal(0.0)
	assert_float(GameState.effective_workers("Crafting")).is_equal(0.0)
	MilitaryCampaign.demobilize(adults)
	assert_float(GameState.effective_workers("Food")).is_equal(food_workers)
	assert_int(MilitaryCampaign._mobilized_count()).is_equal(0)
func test_away_scouts_cannot_be_drafted_twice()->void:
	var baseline:=MilitaryCampaign.recruitment_capacity()
	CivilizationSystem.scout_missions.append({"mission_id":12,"personnel":20})
	assert_int(MilitaryCampaign.recruitment_capacity()).is_equal(baseline-20)
func test_template_can_plan_beyond_current_population()->void:
	assert_bool(MilitaryCampaign.adjust_template_entry(1,"levy","improvised",100000).has("ok")).is_true()
	assert_int(int(MilitaryCampaign.army_templates[0].entries[0].count)).is_equal(100010)
func test_shortages_do_not_block_enrollment_or_create_equipment()->void:
	MilitaryCampaign.military_inventory.improvised=0
	GameState.food_stocks={"Preserved food":0.0};GameState.resource_stockpiles.Food=0
	var result:=MilitaryCampaign.recruit_deploy.add(1)
	assert_bool(result.has("ok")).is_true()
	assert_int(MilitaryCampaign._queued_trainees()).is_equal(10)
	MilitaryCampaign._process_training_day()
	assert_float(float(MilitaryCampaign.training_queue[0].progress_days)).is_equal(0.0)
	assert_int(int(MilitaryCampaign.military_inventory.improvised)).is_equal(0)
func test_parallel_batches_do_not_duplicate_shared_reserve()->void:
	var result:=MilitaryCampaign.recruit_deploy.add(1,2,2)
	var item:=MilitaryCampaign.recruit_deploy.line(int(result.id))
	assert_int(item.slots.size()).is_equal(2)
	assert_int(MilitaryCampaign._queued_trainees()).is_equal(20)
	MilitaryCampaign.recruit_deploy.prepare()
	assert_int(MilitaryCampaign._queued_trainees()).is_equal(20)
	assert_int(int(MilitaryCampaign.military_inventory.improvised)).is_equal(80)
func test_cancel_releases_people_and_returns_reserved_equipment()->void:
	var result:=MilitaryCampaign.recruit_deploy.add(1,2,2)
	MilitaryCampaign.recruit_deploy.cancel(int(result.id))
	assert_int(MilitaryCampaign._mobilized_count()).is_equal(0)
	assert_int(int(MilitaryCampaign.military_inventory.improvised)).is_equal(100)
	assert_int(GameState.population_total).is_equal(1000)
func test_early_deployment_transfers_exact_people_and_reduces_skill()->void:
	var result:=MilitaryCampaign.recruit_deploy.add(1)
	var item:=MilitaryCampaign.recruit_deploy.line(int(result.id));var slot:=int(item.slots[0])
	assert_bool(MilitaryCampaign.recruit_deploy.deploy(int(result.id),slot,true).has("error")).is_true()
	for order:Dictionary in MilitaryCampaign.training_queue:order.progress_days=float(order.required_days)*.2
	var mobilized:=MilitaryCampaign._mobilized_count()
	assert_bool(MilitaryCampaign.recruit_deploy.deploy(int(result.id),slot,true).has("ok")).is_true()
	assert_int(MilitaryCampaign._mobilized_count()).is_equal(mobilized)
	assert_int(MilitaryCampaign.field_army_active_personnel()).is_equal(10)
	assert_int(int(MilitaryCampaign.home_army.troops)).is_equal(0)
	assert_float(float(MilitaryCampaign.field_armies[0].formations[0].training)).is_less(.4)
func test_repeat_waits_for_actual_people_and_refills_after_deployment()->void:
	var result:=MilitaryCampaign.recruit_deploy.add(1,1,1,true)
	for order:Dictionary in MilitaryCampaign.training_queue:order.progress_days=order.required_days
	MilitaryCampaign.recruit_deploy.deploy_ready()
	assert_int(MilitaryCampaign.field_army_active_personnel()).is_equal(10)
	MilitaryCampaign.recruit_deploy.prepare()
	assert_int(MilitaryCampaign._queued_trainees()).is_equal(10)
	assert_int(MilitaryCampaign._mobilized_count()).is_equal(20)
func test_priority_allocates_scarce_equipment_and_full_training_is_equipment_limited()->void:
	MilitaryCampaign.military_inventory.improvised=0
	var first:=MilitaryCampaign.recruit_deploy.add(1)
	var second:=MilitaryCampaign.recruit_deploy.add(1)
	MilitaryCampaign.recruit_deploy.configure(int(second.id),"priority",2)
	MilitaryCampaign.military_inventory.improvised=10
	MilitaryCampaign.recruit_deploy.prepare()
	assert_int(int(MilitaryCampaign.training_queue[0].reserved_equipment)).is_equal(0)
	assert_int(int(MilitaryCampaign.training_queue[1].reserved_equipment)).is_equal(10)
	MilitaryCampaign._process_training_day()
	assert_float(float(MilitaryCampaign.training_queue[0].progress_days)).is_equal(0.0)
	assert_float(float(MilitaryCampaign.training_queue[1].progress_days)).is_greater(0)
	assert_int(int(first.id)).is_not_equal(int(second.id))
func test_orders_and_reservations_survive_save_roundtrip()->void:
	MilitaryCampaign.recruit_deploy.add(1,2,2,true)
	var payload:Dictionary=bytes_to_var(var_to_bytes(MilitaryCampaign.export_state()))
	var restored:=MilitaryCampaign.import_state(payload)
	assert_bool(restored.has("ok")).override_failure_message(str(restored)).is_true()
	assert_int(MilitaryCampaign.recruit_deploy.data.lines.size()).is_equal(1)
	assert_int(MilitaryCampaign._queued_trainees()).is_equal(20)
	MilitaryCampaign.recruit_deploy.prepare()
	assert_int(MilitaryCampaign._queued_trainees()).is_equal(20)
func test_board_instantiates_with_live_progress_controls()->void:
	MilitaryCampaign.recruit_deploy.add(1)
	var board=auto_free(preload("res://scripts/hud/recruit_deploy_board.gd").new())
	add_child(board)
	board.setup({"edit_template":func(_id:int):pass})
	board.update_values()
	assert_int(board.live.size()).is_equal(2)

func test_large_parallel_request_keeps_unfilled_orders_aggregate()->void:
	MilitaryCampaign.recruit_deploy.add(1,1000000,1)
	var item:Dictionary=MilitaryCampaign.recruit_deploy.data.lines[0]
	assert_int(item.slots.size()).is_less_equal(100)
	assert_int(int(item.remaining)+item.slots.size()).is_equal(1000000)
	assert_int(MilitaryCampaign._mobilized_count()).is_less_equal(MilitaryCampaign.recruitment_capacity())
func test_assigning_to_existing_home_army_preserves_its_people()->void:
	var first:=MilitaryCampaign.recruit_deploy.add(1)
	for order:Dictionary in MilitaryCampaign.training_queue:order.progress_days=order.required_days
	MilitaryCampaign.recruit_deploy.deploy_ready()
	var id:=int(MilitaryCampaign.field_armies[0].army_id)
	var second:=MilitaryCampaign.recruit_deploy.add(1)
	MilitaryCampaign.recruit_deploy.configure(int(second.id),"target_army",id)
	for order:Dictionary in MilitaryCampaign.training_queue:order.progress_days=order.required_days
	MilitaryCampaign.recruit_deploy.deploy_ready()
	assert_int(MilitaryCampaign.field_armies.size()).is_equal(1)
	assert_int(int(MilitaryCampaign.field_armies[0].troops)).is_equal(20)
	assert_int(MilitaryCampaign._mobilized_count()).is_equal(20)
	assert_int(int(first.id)).is_not_equal(int(second.id))

func test_paused_line_does_not_spend_instruction_rations()->void:
	var result:=MilitaryCampaign.recruit_deploy.add(1)
	MilitaryCampaign.recruit_deploy.configure(int(result.id),"paused",true)
	var food:=FoodSystem.total_stored()
	MilitaryCampaign._process_training_day()
	assert_float(FoodSystem.total_stored()).is_equal(food)
	assert_float(float(MilitaryCampaign.training_queue[0].progress_days)).is_equal(0.0)
func test_actual_instruction_finishes_and_auto_deploys_without_clicks()->void:
	MilitaryCampaign.recruit_deploy.add(1)
	for day in 300:
		MilitaryCampaign.recruit_deploy.prepare()
		MilitaryCampaign._process_training_day()
		MilitaryCampaign.recruit_deploy.deploy_ready()
		if MilitaryCampaign.field_army_active_personnel()>0:break
	assert_int(MilitaryCampaign.field_army_active_personnel()).is_greater(0)
	assert_int(MilitaryCampaign._mobilized_count()).is_less_equal(12)
	assert_int(GameState.population_total).is_equal(1000)
func test_local_worker_calculation_uses_national_mobilization_share()->void:
	var fraction:=GameState.civilian_workforce_fraction()
	assert_float(fraction).is_equal(1.0)
	MilitaryCampaign.raise_recruits(MilitaryCampaign.recruitment_capacity())
	GameState.player_settlements=[{"id":"home","primary":true,"population_share":1.0}]
	var workers:float=WorldSimulation.settlements.with_local_population(func():return GameState.effective_workers("Food"))
	assert_float(workers).is_equal(0.0)

func test_invalid_saved_line_is_rejected_without_replacing_current_forces()->void:
	MilitaryCampaign.recruit_deploy.add(1)
	var saved:=MilitaryCampaign.export_state()
	saved.recruit_deploy.lines[0].id=0
	assert_bool(MilitaryCampaign.import_state(saved).has("error")).is_true()
	assert_int(int(MilitaryCampaign.recruit_deploy.data.lines[0].id)).is_equal(1)
	assert_int(MilitaryCampaign._queued_trainees()).is_equal(10)
