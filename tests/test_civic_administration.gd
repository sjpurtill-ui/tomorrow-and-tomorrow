extends GdUnitTestSuite
const C=preload("res://scripts/civic_administration.gd")
func before_test()->void:
	WorldSimulation.clear()
	GameState.reset_for_new_world(1902)
	GovernmentPeopleSystem.reset_for_new_world()
	GameState.initialize_population_model()
	GameState.settlement_site_committed=true
	GameState.settlement_completed=["Hearth Circle"]
	SettlementModel.ensure_founded()
	GovernmentPeopleSystem.initialize()
	GameState.known_discoveries.append_array(["jurisdiction_boundaries","official_mandate_registers"])
	GovernmentPeopleSystem.administration_records.work=10.0
func after_test()->void:WorldSimulation.clear()
func test_mandate_checks_actual_appointment_scope_and_expiry()->void:
	var site:Dictionary=GameState.player_settlements[0]
	var person:=int(site.leader_person_id)
	assert_bool(C.register_jurisdiction(GovernmentPeopleSystem,site.id,["water","shelter"]).get("ok",false)).is_true()
	assert_bool(C.issue_mandate(GovernmentPeopleSystem,site.id,person,["water"],10).get("ok",false)).is_true()
	assert_bool(C.authorized(GovernmentPeopleSystem,site.id,person,"water")).is_true()
	assert_bool(C.authorized(GovernmentPeopleSystem,site.id,person,"shelter")).is_false()
	assert_bool(C.authorized(GovernmentPeopleSystem,site.id,person+100,"water")).is_false()
	site.occupied_by="neighbor"
	assert_bool(C.authorized(GovernmentPeopleSystem,site.id,person,"water")).is_false()
	site.erase("occupied_by")
	GameState.elapsed_days+=10
	assert_bool(C.authorized(GovernmentPeopleSystem,site.id,person,"water")).is_false()
func test_rejected_scope_does_not_charge_and_revised_scope_revokes_power()->void:
	var site:Dictionary=GameState.player_settlements[0]
	var person:=int(site.leader_person_id)
	C.register_jurisdiction(GovernmentPeopleSystem,site.id,["water","shelter"])
	var before:=float(GovernmentPeopleSystem.administration_records.work)
	assert_bool(C.issue_mandate(GovernmentPeopleSystem,site.id,person,["disputes"],10).has("error")).is_true()
	assert_float(float(GovernmentPeopleSystem.administration_records.work)).is_equal(before)
	C.issue_mandate(GovernmentPeopleSystem,site.id,person,["water"],10)
	C.register_jurisdiction(GovernmentPeopleSystem,site.id,["shelter"])
	assert_bool(C.authorized(GovernmentPeopleSystem,site.id,person,"water")).is_false()
func test_clerical_work_is_bounded_and_cannot_be_credited_twice_today()->void:
	GovernmentPeopleSystem.administration_records.work=0.0
	GameState.population_allocations.Administration=10.0
	C.credit_day(GovernmentPeopleSystem,100)
	var before:=float(GovernmentPeopleSystem.administration_records.work)
	C.credit_day(GovernmentPeopleSystem,100)
	assert_float(float(GovernmentPeopleSystem.administration_records.work)).is_equal(before)
	C.credit_day(GovernmentPeopleSystem,10000)
	assert_float(float(GovernmentPeopleSystem.administration_records.work)).is_less_equal(before*2.0)
