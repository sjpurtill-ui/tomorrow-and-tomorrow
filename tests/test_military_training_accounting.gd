extends GdUnitTestSuite

func before_test()->void:
	GameState.reset_for_new_world(71042)
	GameState.ensure_population_total(10000)
	GameState.settlement_site_committed=true
	DiscoverySystem.reset_for_new_world()
	ProgressionSystem.reset_for_new_world()
	MilitaryCampaign.reset_for_new_world()
	CivilizationSystem.set_process(false)
	MilitaryCampaign.set_process(false)
	FoodSystem.reset_for_new_world()
	GameState.resource_stockpiles["Food"]=1000000.0

func after_test()->void:
	GameState.elapsed_days=0.0
	CivilizationSystem.set_process(true)
	MilitaryCampaign.set_process(true)

func _home(count:int)->void:
	MilitaryCampaign.home_army=MilitaryCampaign.simulator.create_formation_force("Test reserve",[{"id":1,"unit":"levy","weapon":"improvised","count":count,"equipment":count,"training":0.4,"experience":0.1}],0.8,0.7)
	MilitaryCampaign.home_army["supply_level"]=1.0

func test_deploy_leaves_22_in_reserve_but_preserves_122_total()->void:
	_home(122)
	MilitaryCampaign.army_templates=[{"template_id":1,"name":"Main army","entries":[{"unit":"levy","weapon":"improvised","count":100}]}]
	var preview:Dictionary=MilitaryCampaign.army_template_snapshot().templates[0]
	assert_int(int(preview.entries[0].ready)).is_equal(100)
	assert_int(int(preview.entries[0].home_available)).is_equal(122)
	var before:=MilitaryCampaign._mobilized_count()
	var result:=MilitaryCampaign.deploy_army_from_template(1)
	assert_bool(result.has("ok")).is_true()
	assert_int(int(result.army.troops)).is_equal(100)
	assert_int(int(MilitaryCampaign.home_army.troops)).is_equal(22)
	assert_int(MilitaryCampaign._mobilized_count()).is_equal(before)
	assert_str(String(result.message)).contains("100 soldiers")
	assert_str(String(result.message)).contains("22 remain")
	assert_int(int(result.army.formations[0].equipment)+int(MilitaryCampaign.home_army.formations[0].equipment)).is_equal(122)
	MilitaryCampaign.disband_field_army(int(result.army.army_id))
	assert_int(int(MilitaryCampaign.home_army.troops)).is_equal(122)

func test_prototype_queue_reports_accepted_count_and_keeps_remaining_recruits()->void:
	for id in ["seasonal_patterns","animal_taming","pack_animals","domesticated_mounts","bronze_weaponry"]: GameState.known_discoveries.append(id)
	MilitaryCampaign.aggregate_recruits=40
	MilitaryCampaign.army_templates=[{"template_id":1,"name":"Experimental riders","entries":[{"unit":"cavalry","weapon":"sword_shield","count":40}]}]
	var result:=MilitaryCampaign.queue_template_training(1)
	assert_int(int(result.get("queued",0))).is_equal(MilitaryCampaign.PROTOTYPE_COHORT_LIMIT)
	assert_int(MilitaryCampaign.aggregate_recruits+MilitaryCampaign._queued_trainees()).is_equal(40)
	var order:Dictionary=MilitaryCampaign.training_queue[0].duplicate(true)
	MilitaryCampaign._complete_training(order)
	MilitaryCampaign.training_queue.clear()
	assert_bool(bool(MilitaryCampaign.home_army.formations[0].prototype)).is_true()
	var deployed:=MilitaryCampaign.create_field_army(int(order.count))
	assert_bool(deployed.has("ok")).is_true()
	assert_bool(MilitaryCampaign.start_training("cavalry","sword_shield",8).has("error")).is_true()

func test_training_counts_are_capped_to_missing_build_places()->void:
	_home(15)
	MilitaryCampaign.training_queue=[{"unit":"levy","weapon":"improvised","count":50}]
	MilitaryCampaign.army_templates=[{"template_id":1,"entries":[{"unit":"levy","weapon":"improvised","count":20}]}]
	var preview:Dictionary=MilitaryCampaign.army_template_snapshot().templates[0]
	assert_int(int(preview.ready_total)).is_equal(15)
	assert_int(int(preview.in_training_total)).is_equal(5)

func test_personnel_ledger_partitions_every_service_pool()->void:
	_home(30)
	MilitaryCampaign.aggregate_recruits=4
	MilitaryCampaign.training_queue=[{"count":7}]
	MilitaryCampaign.training_injury_pool=3
	MilitaryCampaign.home_army["wounded_pool"]=2
	MilitaryCampaign.home_army["captured_pool"]=1
	MilitaryCampaign.field_armies=[{"troops":20,"scattered_pool":2}]
	MilitaryCampaign.occupation_forces=[{"troops":9,"wounded_pool":1}]
	var ledger:=MilitaryCampaign.personnel_ledger()
	var sum:=0
	for key in ["home","field","occupation","recruits","training","recovering","missing"]: sum+=int(ledger[key])
	assert_int(sum).is_equal(int(ledger.total))
	assert_int(sum).is_equal(79)

func test_exercises_include_assembled_home_armies_and_exclude_marching_armies()->void:
	_home(40)
	var deployed:=MilitaryCampaign.create_field_army(25)
	assert_bool(deployed.has("ok")).is_true()
	assert_int(MilitaryCampaign.exercise_personnel()).is_equal(40)
	var field_before:=float(MilitaryCampaign.field_armies[0].formations[0].training)
	assert_bool(MilitaryCampaign.start_training_program("reconnaissance_drill").has("ok")).is_true()
	MilitaryCampaign._process_training_program_day()
	assert_float(float(MilitaryCampaign.field_armies[0].formations[0].training)).is_greater(field_before)
	assert_int(int(MilitaryCampaign.training_program.participants)).is_equal(40)
	assert_int(MilitaryCampaign._mobilized_count()).is_equal(40)
	MilitaryCampaign.field_armies[0]["status"]="moving"
	field_before=float(MilitaryCampaign.field_armies[0].formations[0].training)
	MilitaryCampaign._process_training_program_day()
	assert_int(int(MilitaryCampaign.training_program.participants)).is_equal(15)
	assert_float(float(MilitaryCampaign.field_armies[0].formations[0].training)).is_equal(field_before)

func test_shared_skill_transfer_is_idempotent_and_works_for_all_archetypes()->void:
	_home(20)
	MilitaryCampaign.create_field_army(10)
	MilitaryCampaign.command_development["logistics"]=0.12
	MilitaryCampaign._synchronize_field_commander()
	var first:=float(MilitaryCampaign.field_armies[0].commander.logistics)
	for iteration in 20: MilitaryCampaign._synchronize_field_commander()
	assert_float(float(MilitaryCampaign.field_armies[0].commander.logistics)).is_equal(first)
	assert_float(float(MilitaryCampaign.field_armies[0].commander.training_development.logistics)).is_equal(0.12)
	var baseline:Dictionary={}
	for unit in MilitaryCampaign.UnitCatalog.ARCHETYPES: baseline[unit]=MilitaryCampaign._training_quality(String(unit))
	MilitaryCampaign.command_development["command"]=0.12
	MilitaryCampaign._synchronize_field_commander()
	for unit in MilitaryCampaign.UnitCatalog.ARCHETYPES:
		assert_float(MilitaryCampaign._training_quality(String(unit))).is_greater(float(baseline[unit]))
	assert_int(MilitaryCampaign.TRAINING_PROGRAMS.size()).is_equal(8)

func test_deployed_army_at_home_can_start_exercise_with_empty_reserve()->void:
	_home(20)
	MilitaryCampaign.create_field_army(20)
	assert_int(int(MilitaryCampaign.home_army.troops)).is_equal(0)
	assert_bool(MilitaryCampaign.start_training_program("rally_drill").has("ok")).is_true()

func test_advanced_exercises_still_require_knowledge()->void:
	_home(20)
	assert_bool(MilitaryCampaign.start_training_program("war_games").has("error")).is_true()
	assert_bool(MilitaryCampaign.start_training_program("staff_exercise").has("error")).is_true()
