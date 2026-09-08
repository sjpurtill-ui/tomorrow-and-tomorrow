extends GdUnitTestSuite
const Roster=preload("res://scripts/hud/military_roster_screen.gd")
const Staff=preload("res://scripts/military_training_staff.gd")
var op:RefCounted

func before_test()->void:
	GameState.set_process(false);MilitaryCampaign.set_process(false);CivilizationSystem.set_process(false)
	GameState.reset_for_new_world(424242);SettlementModel.reset_for_new_world();MilitaryCampaign.reset_for_new_world();FoodSystem.reset_for_new_world()
	GameState.initialize_population_model();GameState.ensure_population_total(2000)
	GameState.settlement_completed=["Hearth Circle"];SettlementModel.ensure_founded()
	GameState.resource_stockpiles["Food"]=1000000.0
	GameState.food_stocks={"Preserved food":1000000.0}
	for resource:String in ["Timber","Stone","Iron Ore","Fiber Plants","Copper Ore","Graphite","Bitumen"]:GameState.resource_stockpiles[resource]=1000000.0
	MilitaryCampaign.military_consumables.fuel=100000
	op=MilitaryCampaign.joint_operations
	op.geography.land_query=func(point:Vector2)->bool:return point.y>=0

func after_test()->void:
	GameState.elapsed_days=0;GameState.set_process(true);MilitaryCampaign.set_process(true);CivilizationSystem.set_process(true)

func _home()->void:
	MilitaryCampaign.home_army=MilitaryCampaign.simulator.create_formation_force("Reserve",[{"id":1,"unit":"levy","weapon":"improvised","count":100,"equipment":100,"training":.25,"experience":.1},{"id":2,"unit":"levy","weapon":"improvised","count":20,"equipment":20,"training":.9,"experience":.6}],.8,.7)
	MilitaryCampaign.home_army.supply_level=1.0

func _army_day(day:int)->void:
	GameState.elapsed_days=day;MilitaryCampaign.last_processed_day=day
	MilitaryCampaign._process_training_program_day()

func _craft(domain:String)->Dictionary:
	var type_id:="war_canoe" if domain=="navy" else "observation_balloon"
	var definition:Dictionary=op.C.UNITS[type_id]
	GameState.known_discoveries.append(String(definition.gate));GameState.discovery_adoption[definition.gate]=1.0
	GameState.player_settlements[0].position=Vector2(0,1)
	var built:Dictionary=op.build_base(String(GameState.player_settlements[0].id),domain)
	assert_bool(built.has("ok")).override_failure_message(str(built)).is_true()
	var base:Dictionary=op.state.bases.back();base.construction_work=30
	MilitaryCampaign.military_inventory[definition.equipment]=2
	var commissioned:Dictionary=op.commission(int(base.id),type_id,2)
	assert_bool(commissioned.has("ok")).override_failure_message(str(commissioned)).is_true()
	return op.force(int(commissioned.id))

func test_policies_are_separate_and_repeated_orders_do_not_buy_progress()->void:
	_home()
	var staff=MilitaryCampaign.training_staff
	staff.set_policy("navy","intensive");staff.set_policy("army","maintain")
	assert_str(staff.policy("navy").id).is_equal("intensive");assert_str(staff.policy("air").id).is_equal("regular")
	var food:=FoodSystem.total_stored();var skill:=float(MilitaryCampaign.home_army.formations[0].training)
	for _repeat in 30:
		staff.set_policy("army","maintain");MilitaryCampaign.start_training_program("camp_drill")
	assert_float(float(MilitaryCampaign.training_program.progress_days)).is_equal(0.0)
	assert_float(float(MilitaryCampaign.home_army.formations[0].training)).is_equal(skill)
	assert_float(FoodSystem.total_stored()).is_equal(food)

func test_staff_train_weaker_units_automatically_with_long_courses_and_paid_rations()->void:
	_home();var food:=FoodSystem.total_stored()
	_army_day(1)
	assert_int(int(MilitaryCampaign.training_program.participants)).is_equal(30)
	assert_float(float(MilitaryCampaign.home_army.formations[0].training)).is_greater(.25)
	assert_float(float(MilitaryCampaign.home_army.formations[1].training)).is_equal(.9)
	for day in range(2,31):_army_day(day)
	assert_float(float(MilitaryCampaign.training_program.duration_days)).is_equal(84.0)
	assert_int(MilitaryCampaign.training_program_cycles).is_equal(0)
	assert_float(food-FoodSystem.total_stored()).is_greater(100.0)
	var progress:=float(MilitaryCampaign.training_program.progress_days)
	_army_day(30)
	assert_float(float(MilitaryCampaign.training_program.progress_days)).is_equal(progress)

func test_food_reserve_and_threats_suspend_training_without_free_gains()->void:
	_home();GameState.resource_stockpiles.Food=0;GameState.food_stocks={"Preserved food":100.0}
	_army_day(1)
	assert_dict(MilitaryCampaign.training_program).is_empty()
	assert_float(FoodSystem.total_stored()).is_equal(100.0)
	GameState.food_stocks={"Preserved food":1000000.0};MilitaryCampaign.active_threat={"id":"incoming"}
	_army_day(2)
	assert_dict(MilitaryCampaign.training_program).is_empty()
	assert_int(int(MilitaryCampaign.home_army.formations[0].training_attending)).is_equal(0)

func test_target_stops_training_and_suspend_preserves_course_progress()->void:
	_home();_army_day(1)
	var progress:=float(MilitaryCampaign.training_program.progress_days)
	MilitaryCampaign.training_staff.set_policy("army","suspended");_army_day(2)
	assert_float(float(MilitaryCampaign.training_program.progress_days)).is_equal(progress)
	MilitaryCampaign.training_staff.set_policy("army","regular")
	for formation:Dictionary in MilitaryCampaign.home_army.formations:formation.training=.75
	_army_day(3)
	assert_int(int(MilitaryCampaign.training_program.participants)).is_equal(0)
	assert_float(float(MilitaryCampaign.training_program.progress_days)).is_equal(progress)

func test_initial_instruction_is_longer_and_paid()->void:
	MilitaryCampaign.aggregate_recruits=2;MilitaryCampaign.military_inventory.improvised=2
	var order:=MilitaryCampaign.start_training("levy","improvised",2)
	assert_float(float(order.required_days)).is_greater_equal(45.0)
	var food:=FoodSystem.total_stored();MilitaryCampaign._process_training_day()
	assert_float(FoodSystem.total_stored()).is_less(food)
	var progress:=float(MilitaryCampaign.training_queue[0].progress_days)
	MilitaryCampaign.training_staff.set_policy("army","suspended");MilitaryCampaign._process_training_day()
	assert_float(float(MilitaryCampaign.training_queue[0].progress_days)).is_equal(progress)

func test_policy_and_paid_progress_survive_save_load_without_repeat_rewards()->void:
	_home();_army_day(1);MilitaryCampaign.training_staff.set_policy("air","intensive")
	var saved:=MilitaryCampaign.export_state();var food:=FoodSystem.total_stored()
	var progress:=float(MilitaryCampaign.training_program.progress_days)
	var result:=MilitaryCampaign.import_state(saved)
	assert_bool(result.has("ok")).override_failure_message(str(result)).is_true()
	assert_str(MilitaryCampaign.training_staff.policy("air").id).is_equal("intensive")
	_army_day(1)
	assert_float(float(MilitaryCampaign.training_program.progress_days)).is_equal(progress)
	assert_float(FoodSystem.total_stored()).is_equal(food)

func test_old_training_save_preserves_completion_fraction_once()->void:
	MilitaryCampaign.aggregate_recruits=1;MilitaryCampaign.start_training("levy","improvised",1)
	MilitaryCampaign.training_queue[0].required_days=10.0;MilitaryCampaign.training_queue[0].progress_days=5.0
	var saved:=MilitaryCampaign.export_state();saved.erase("training_timing_version");saved.erase("training_strategy")
	assert_bool(MilitaryCampaign.import_state(saved).has("ok")).is_true()
	assert_float(float(MilitaryCampaign.training_queue[0].required_days)).is_equal(45.0)
	assert_float(float(MilitaryCampaign.training_queue[0].progress_days)).is_equal(22.5)
	var migrated:=MilitaryCampaign.export_state();MilitaryCampaign.import_state(migrated)
	assert_float(float(MilitaryCampaign.training_queue[0].progress_days)).is_equal(22.5)

func test_navy_and_air_crews_train_automatically_and_pay_materials()->void:
	for domain:String in ["navy","air"]:
		var unit:=_craft(domain);var base:Dictionary=op.base(int(unit.base_id))
		var timber:=float(GameState.resource_stockpiles.Timber);var food:=FoodSystem.total_stored()
		assert_bool(MilitaryCampaign.training_staff.service_training(unit,base,1)).is_true()
		assert_float(float(unit.training)).is_greater(0.0).is_less(.02)
		assert_float(float(GameState.resource_stockpiles.Timber)).is_less(timber)
		assert_float(FoodSystem.total_stored()).is_less(food)
		var progress:=float(unit.training)
		MilitaryCampaign.training_staff.service_training(unit,base,1)
		assert_float(float(unit.training)).is_equal(progress)

func test_service_shortages_pause_without_partial_spending_and_recover_automatically()->void:
	var unit:=_craft("air");var base:Dictionary=op.base(int(unit.base_id))
	GameState.resource_stockpiles.Timber=0
	var food:=FoodSystem.total_stored()
	MilitaryCampaign.training_staff.service_training(unit,base,1)
	assert_float(float(unit.training)).is_equal(0.0);assert_float(FoodSystem.total_stored()).is_equal(food)
	assert_str(String(unit.training_status)).contains("Timber")
	GameState.resource_stockpiles.Timber=1000
	MilitaryCampaign.training_staff.service_training(unit,base,2)
	assert_float(float(unit.training)).is_greater(0.0)

func test_service_training_recovers_low_condition_instead_of_deadlocking()->void:
	var unit:=_craft("air");unit.condition=.75;var base:Dictionary=op.base(int(unit.base_id))
	MilitaryCampaign.training_staff.service_training(unit,base,1)
	assert_float(float(unit.condition)).is_greater(.75)
	assert_float(float(unit.training)).is_equal(0.0)
	for day in range(2,8):MilitaryCampaign.training_staff.service_training(unit,base,day)
	assert_float(float(unit.training)).is_greater(0.0)
	unit.training=1.0;unit.condition=.75;unit.repairing=false
	MilitaryCampaign.training_staff.service_training(unit,base,8)
	assert_bool(bool(unit.repairing)).is_true()

func test_rival_training_uses_shared_duration_cost_and_target()->void:
	var civ:Dictionary={"id":"training_test","population":400.0,"military_population":120.0,"military_readiness":.25,"military_proficiency":.25,"command_readiness":.5,"food_days":100.0,"logistics":.7,"institutions":.7,"production":.5,"military_stockpile":1000.0,"strategy":"sustenance","player_relation":{"at_war":false},"discovery_profile":{"technologies":[]}}
	var after:=CivilizationSystem._advance_rival_military_training(civ,{"military":.2},0)
	var maximum_gain:float=MilitaryCampaign.TRAINING_PROGRAMS.camp_drill.training_gain/84.0*30*.25*1.2
	assert_float(float(after.military_proficiency)-.25).is_between(0.0,maximum_gain)
	assert_float(float(after.food_days)).is_less(100.0)
	assert_int(int(after.get("training_cycles",0))).is_equal(0)
	civ.food_days=1.0;var before:=float(civ.military_proficiency)
	CivilizationSystem._advance_rival_military_training(civ,{"military":.2},0)
	assert_float(float(civ.military_proficiency)).is_equal(before)

func test_large_roster_and_policy_controls_update_without_training_buttons()->void:
	_home()
	var screen:CanvasLayer=auto_free(Roster.new());add_child(screen)
	assert_int(screen._rows().size()).is_equal(2)
	assert_int(screen.bindings.size()).is_equal(2)
	screen.training_view=true;screen._build_body()
	assert_int(screen.policy_buttons.size()).is_equal(4)
	screen.policy_buttons.intensive.pressed.emit()
	assert_str(MilitaryCampaign.training_staff.policy("army").id).is_equal("intensive")
	assert_bool(screen.policy_buttons.intensive.button_pressed).is_true()
	assert_bool(screen.policy_buttons.regular.button_pressed).is_false()

func test_suspended_training_has_no_fictitious_completion_date()->void:
	var unit:=_craft("air")
	MilitaryCampaign.training_staff.set_policy("air","suspended")
	var readiness:Dictionary=op.readiness(int(unit.id))
	assert_int(int(readiness.training_days)).is_equal(-1)
	assert_str(str(readiness.blockers)).contains("suspended")
	MilitaryCampaign.aggregate_recruits=1;MilitaryCampaign.start_training("levy","improvised",1)
	MilitaryCampaign.training_staff.set_policy("army","suspended")
	var progress:Dictionary=MilitaryCampaign.training_progress_snapshot().values()[0]
	assert_int(int(progress.estimated_days)).is_equal(-1)
	assert_str(String(progress.reason)).contains("suspended")

func test_staff_report_keeps_field_formations_dated_and_does_not_expose_live_changes()->void:
	_home()
	MilitaryCampaign.create_field_army(50)
	var army:Dictionary=MilitaryCampaign.field_armies[0]
	army.status="moving";army.location_id="field"
	army.last_report=MilitaryCampaign._army_report_snapshot(army)
	var reported_count:=int(army.last_report.formations[0].count)
	army.formations[0].count=1
	var screen:CanvasLayer=auto_free(Roster.new());add_child(screen)
	var reported:Array=screen._rows().filter(func(row:Dictionary)->bool:return "report" in String(row.location))
	assert_int(int(reported[0].count)).is_equal(reported_count)

func test_roster_policy_layout_fits_the_game_and_map_click_closes_it()->void:
	_home()
	var screen:CanvasLayer=Roster.new();add_child(screen)
	screen.training_view=true;screen._build_body()
	await get_tree().process_frame
	assert_float(screen.body.get_combined_minimum_size().x).is_less_equal(screen.panel.size.x-36.0)
	var click:=InputEventMouseButton.new();click.button_index=MOUSE_BUTTON_LEFT;click.pressed=true;click.position=Vector2.ZERO
	screen._input(click)
	assert_bool(screen.is_queued_for_deletion()).is_true()
	await get_tree().process_frame
