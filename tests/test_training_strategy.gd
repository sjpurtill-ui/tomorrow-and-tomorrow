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

func test_service_repair_spell_finishes_before_initial_or_qualified_training_resumes()->void:
	for domain:String in ["navy","air"]:
		var unit:=_craft(domain)
		for initial:bool in [true,false]:
			unit.training=0.0 if initial else 1.0;unit.proficiency=.25;unit.condition=.75;unit.repairing=false
			var first_day:=int(op.state.last_day)+1
			var food:=FoodSystem.total_stored()
			for day in range(first_day,first_day+6):
				var costs:Dictionary=op.repair_costs(unit)
				var timber:=float(GameState.resource_stockpiles.Timber)
				var proficiency:=float(unit.proficiency)
				op.advance(day)
				assert_float(float(unit.training)).is_equal(0.0 if initial else 1.0)
				assert_float(float(unit.proficiency)).is_equal(proficiency)
				assert_int(int(unit.training_attending)).is_equal(0)
				assert_float(FoodSystem.total_stored()).is_equal(food)
				assert_float(float(GameState.resource_stockpiles.Timber)).is_equal_approx(timber-float(costs.Timber),.00001)
				assert_str(String(unit.status)).contains("Repairing")
			assert_float(float(unit.condition)).is_greater_equal(.98)
			assert_bool(bool(unit.repairing)).is_false()
			op.advance(first_day+6)
			assert_int(int(unit.training_attending)).is_greater(0)
			assert_float(FoodSystem.total_stored()).is_less(food)
			if initial:assert_float(float(unit.training)).is_greater(0.0)
			else:assert_float(float(unit.proficiency)).is_greater(.25)
		# Avoid charging this service's later rotations during the next fixture.
		MilitaryCampaign.training_staff.set_policy(domain,"suspended")

func test_suspended_instruction_still_repairs_and_shortages_recover_without_orders()->void:
	var unit:=_craft("air");unit.condition=.90;unit.repairing=true
	MilitaryCampaign.training_staff.set_policy("air","suspended")
	GameState.resource_stockpiles.Timber=0.0
	var food:=FoodSystem.total_stored();var fiber:=float(GameState.resource_stockpiles["Fiber Plants"])
	op.advance(1)
	assert_float(float(unit.condition)).is_equal(.90)
	assert_float(float(GameState.resource_stockpiles["Fiber Plants"])).is_equal(fiber)
	assert_str(String(unit.training_status)).contains("Repairs waiting for").contains("Timber")
	GameState.resource_stockpiles.Timber=1000.0
	for day in range(2,6):op.advance(day)
	assert_float(float(unit.condition)).is_greater_equal(.98)
	assert_bool(bool(unit.repairing)).is_false()
	assert_float(float(unit.training)).is_equal(0.0)
	assert_float(FoodSystem.total_stored()).is_equal(food)
	assert_str(String(unit.training_status)).contains("suspended")
	MilitaryCampaign.training_staff.set_policy("air","regular");op.advance(6)
	assert_float(float(unit.training)).is_greater(0.0)

func test_same_day_reentry_preserves_paid_attendance_and_status_even_at_graduation()->void:
	var unit:=_craft("air");var base:Dictionary=op.base(int(unit.base_id))
	unit.training=.999
	MilitaryCampaign.training_staff.set_policy("air","intensive")
	for day in [1,2]:
		MilitaryCampaign.training_staff.service_training(unit,base,day)
		var after:=unit.duplicate(true)
		var report:Dictionary=MilitaryCampaign.training_staff.snapshot("air")
		var food:=FoodSystem.total_stored()
		for _repeat in 5:MilitaryCampaign.training_staff.service_training(unit,base,day)
		assert_dict(unit).is_equal(after)
		assert_dict(MilitaryCampaign.training_staff.snapshot("air")).is_equal(report)
		assert_float(FoodSystem.total_stored()).is_equal(food)
		assert_int(int(unit.training_attending)).is_greater(0)

func test_rival_crew_training_cannot_overwrite_player_staff_reports_or_spending()->void:
	var unit:=_craft("navy");var base:Dictionary=op.base(int(unit.base_id))
	MilitaryCampaign.training_staff.service_training(unit,base,1)
	var report:Dictionary=MilitaryCampaign.training_staff.snapshot("navy")
	var other:=unit.duplicate(true);other.owner="staff_report_test";other.training=0.0
	var civ:Dictionary={"id":other.owner,"population":2000.0,"food_days":1.0,"military_stockpile":10000.0,"strategy":"sustenance","player_relation":{"at_war":false}}
	CivilizationSystem.civilizations.append(civ)
	MilitaryCampaign.training_staff.service_training(other,base,2)
	assert_str(String(other.training_status)).contains("suspended")
	assert_dict(MilitaryCampaign.training_staff.snapshot("navy")).is_equal(report)
	civ.food_days=100.0;civ.military_stockpile=0.0
	MilitaryCampaign.training_staff.service_training(other,base,3)
	assert_str(String(other.training_status)).contains("unavailable")
	assert_dict(MilitaryCampaign.training_staff.snapshot("navy")).is_equal(report)
	civ.military_stockpile=10000.0
	MilitaryCampaign.training_staff.service_training(other,base,4)
	assert_float(float(other.training)).is_greater(0.0)
	assert_dict(MilitaryCampaign.training_staff.snapshot("navy")).is_equal(report)
	CivilizationSystem.civilizations.erase(civ)

func test_initial_intensive_staff_report_describes_instruction_not_overfull_rotations()->void:
	var unit:=_craft("air")
	MilitaryCampaign.training_staff.set_policy("air","intensive");op.advance(1)
	assert_int(int(unit.training_attending)).is_equal(op.crew(unit))
	assert_str(String(unit.training_status)).contains("Staff instruction").contains("days at current policy")
	assert_int(int(MilitaryCampaign.training_staff.snapshot("air").attending)).is_equal(op.crew(unit))

func test_roster_keeps_operational_activity_and_repair_shortages_visible()->void:
	var unit:=_craft("navy");unit.training=1.0;unit.condition=.90;unit.repairing=true
	GameState.resource_stockpiles.Timber=0.0
	op.advance(1)
	var screen:CanvasLayer=auto_free(Roster.new());screen.service="navy";add_child(screen)
	assert_str(String(screen._rows()[0].activity)).contains("Repairs waiting for").contains("Timber")
	unit.condition=1.0;unit.repairing=false
	var destination:Vector2=op.point(op.base(int(unit.base_id)))+Vector2(1000,-100)
	assert_bool(op.set_route(unit,destination).has("error")).is_false()
	op.advance(2)
	assert_str(String(screen._rows()[0].activity)).is_equal("Under way")
	assert_str(String(screen._rows()[0].training_note)).contains("return to home base")

func _additional_service_force(original:Dictionary)->Dictionary:
	var type_id:String=original.units.keys()[0]
	MilitaryCampaign.military_inventory[op.C.UNITS[type_id].equipment]=2
	var created:Dictionary=op.commission(int(original.base_id),type_id,2)
	assert_bool(created.has("ok")).override_failure_message(str(created)).is_true()
	return op.force(int(created.id))

func test_service_overview_counts_every_owned_force_and_is_independent_of_processing_order()->void:
	var training:=_craft("navy")
	var ready:=_additional_service_force(training);ready.training=1.0;ready.proficiency=.9
	var assigned:=_additional_service_force(training);assigned.training=1.0
	assert_bool(op.set_route(assigned,op.point(op.base(int(training.base_id)))+Vector2(1000,-100)).has("error")).is_false()
	var repairing:=_additional_service_force(training);repairing.training=1.0;repairing.condition=.6;repairing.repairing=true
	var stranded:=_additional_service_force(training);stranded.base_id=999
	_craft("air")
	var rival:=training.duplicate(true);rival.id=op._id();rival.owner="unrelated_rival";op.state.forces.append(rival)
	op.advance(1)
	var overview:Dictionary=MilitaryCampaign.training_staff.snapshot("navy")
	assert_dict(overview.groups).is_equal({"training":1,"assigned":1,"target":1,"paused":2})
	assert_int(int(overview.forces)).is_equal(5)
	assert_int(int(overview.attending)).is_equal(op.crew(training))
	assert_int(int(overview.personnel)).is_equal(op.crew(training)*5)
	assert_str(String(overview.status)).contains("5 task forces").contains("Home base unavailable").contains("Repairing")
	var before:Dictionary=op.export_state()
	MilitaryCampaign.training_staff.snapshot("navy")
	assert_dict(op.export_state()).is_equal(before)
	op.state.forces.reverse()
	assert_dict(MilitaryCampaign.training_staff.snapshot("navy")).is_equal(overview)

func test_reaching_target_stops_the_rotation_and_clears_the_old_exercise_report()->void:
	var unit:=_craft("air");unit.training=1.0;unit.proficiency=.54999
	MilitaryCampaign.training_staff.set_policy("air","maintain")
	op.advance(1)
	assert_int(int(MilitaryCampaign.training_staff.snapshot("air").groups.training)).is_equal(1)
	var food:=FoodSystem.total_stored()
	op.advance(2)
	var overview:Dictionary=MilitaryCampaign.training_staff.snapshot("air")
	assert_int(int(overview.groups.training)).is_equal(0)
	assert_int(int(overview.groups.target)).is_equal(1)
	assert_int(int(overview.attending)).is_equal(0)
	assert_str(String(unit.training_status)).is_equal("Training target met")
	assert_float(FoodSystem.total_stored()).is_equal(food)

func test_base_failure_or_missing_equipment_clears_yesterdays_training_indicators()->void:
	for domain in ["navy","air"]:
		var unit:=_craft(domain);var base:Dictionary=op.base(int(unit.base_id))
		var first_day:=int(op.state.last_day)+1
		op.advance(first_day)
		assert_int(int(unit.training_attending)).is_greater(0)
		base.condition=0.0;op.advance(first_day+1)
		assert_int(int(unit.training_attending)).is_equal(0)
		assert_str(String(unit.training_status)).contains("Home base unavailable")
		assert_int(int(MilitaryCampaign.training_staff.snapshot(domain).groups.paused)).is_equal(1)
		base.condition=1.0;op.advance(first_day+2)
		assert_int(int(unit.training_attending)).is_greater(0)
		unit.auto_replace=false
		for type_id in unit.units:unit.units[type_id]=0
		op.advance(first_day+3)
		assert_int(int(unit.training_attending)).is_equal(0)
		assert_str(String(unit.training_status)).contains("replacement equipment and crew")
		assert_int(int(MilitaryCampaign.training_staff.snapshot(domain).groups.training)).is_equal(0)

func test_empty_service_has_no_stale_report_and_policy_changes_do_not_fabricate_training()->void:
	MilitaryCampaign.training_staff.data.status.navy="Staff exercises · 50% of crews rotating"
	var empty:Dictionary=MilitaryCampaign.training_staff.snapshot("navy")
	assert_str(String(empty.status)).contains("No task forces commissioned")
	assert_dict(empty.groups).is_equal({"training":0,"assigned":0,"target":0,"paused":0})
	var unit:=_craft("navy")
	MilitaryCampaign.training_staff.set_policy("navy","intensive")
	var waiting:Dictionary=MilitaryCampaign.training_staff.snapshot("navy")
	assert_int(int(waiting.groups.paused)).is_equal(1)
	assert_int(int(waiting.attending)).is_equal(0)
	assert_float(float(unit.training)).is_equal(0.0)
	assert_str(String(waiting.status)).contains("next staff review")

func test_visual_training_indicators_update_in_place_and_fit_the_policy_panel()->void:
	var unit:=_craft("air");unit.training=1.0;unit.proficiency=.9
	op.advance(1)
	var screen:CanvasLayer=auto_free(Roster.new());screen.service="air";screen.training_view=true;add_child(screen)
	await get_tree().process_frame
	assert_int(screen.service_indicators.size()).is_equal(4)
	assert_str(String(screen.service_indicators.target.value.text)).is_equal("1")
	var indicator:Label=screen.service_indicators.target.value
	MilitaryCampaign.training_staff.set_policy("air","suspended");op.advance(2);screen._update_policy()
	assert_object(screen.service_indicators.target.value).is_same(indicator)
	assert_str(String(screen.service_indicators.target.value.text)).is_equal("0")
	assert_str(String(screen.service_indicators.paused.value.text)).is_equal("1")
	assert_str(String(screen.service_indicators.paused.card.tooltip_text)).contains("suspended")
	assert_float(screen.body.get_combined_minimum_size().x).is_less_equal(screen.panel.size.x-36.0)
