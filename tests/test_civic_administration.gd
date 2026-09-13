extends GdUnitTestSuite
const C=preload("res://scripts/civic_administration.gd")
func before_test()->void:
	WorldSimulation.clear()
	GameState.reset_for_new_world(1902)
	CivilizationSystem.reset_for_new_world()
	MilitaryCampaign.reset_for_new_world()
	DiscoverySystem.reset_for_new_world()
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

func test_clerical_reservation_reduces_other_administration_capacity()->void:
	GameState.population_allocations.Administration=10.0
	var raw:=GameState.effective_workers("Administration",false,false,true)
	var ordinary:=GameState.effective_workers("Administration")
	GovernmentPeopleSystem.administration_records.work=0.0
	C.credit_day(GovernmentPeopleSystem,20)
	var paid:=float(GovernmentPeopleSystem.administration_records.last_reserved_work)
	assert_float(ordinary).is_less(raw)
	assert_float(ordinary+paid).is_equal_approx(raw,.000001)
	GameState.resource_settlement_id="secondary"
	assert_float(GameState.effective_workers("Administration")).is_equal(raw)
	GameState.resource_settlement_id=""
func test_replacement_transfers_actual_pending_duty_after_paid_handover()->void:
	GameState.known_discoveries.append("public_office_handover")
	var site:Dictionary=GameState.player_settlements[0]
	var previous:=int(site.leader_person_id)
	var successor:=int(GovernmentPeopleSystem.people[1].person_id)
	var followup:={"state":"pending","leader_person_id":previous,"settlement_id":site.id,"due_day":1}
	GameState.sovereign_orders.append({"id":"custody_test","settlement_id":site.id,"implementation_followup":followup})
	GovernmentPeopleSystem.mark_central_appointment(successor,"Steward")
	assert_str(String(followup.handover_state)).is_equal("pending")
	C.process_handovers(GovernmentPeopleSystem)
	assert_bool(followup.has("custodian_person_id")).is_false()
	C.register_jurisdiction(GovernmentPeopleSystem,site.id,["work"])
	C.issue_mandate(GovernmentPeopleSystem,site.id,successor,["work"],30)
	var before:=float(GovernmentPeopleSystem.administration_records.work)
	C.process_handovers(GovernmentPeopleSystem)
	assert_int(int(followup.custodian_person_id)).is_equal(successor)
	assert_int(int(followup.leader_person_id)).is_equal(previous)
	assert_float(float(GovernmentPeopleSystem.administration_records.work)).is_equal(before-.5)
	assert_bool(C.can_review(GovernmentPeopleSystem,followup)).is_true()
	C.process_handovers(GovernmentPeopleSystem)
	assert_float(float(GovernmentPeopleSystem.administration_records.work)).is_equal(before-.5)

func test_petition_conversation_changes_work_and_requires_observed_resolution()->void:
	GameState.known_discoveries.append("petition_registers")
	var site:Dictionary=GameState.player_settlements[0]
	var person:=int(site.leader_person_id)
	GameState.housing_capacity=ceili(GameState.population_exact)
	GameState.water_metrics={"intake_ratio":.5}
	GameState.simulation_metrics["food_intake_ratio"]=1.0
	C.register_jurisdiction(GovernmentPeopleSystem,site.id,["water"])
	C.issue_mandate(GovernmentPeopleSystem,site.id,person,["water"],90)
	C.observe_petitions(GovernmentPeopleSystem)
	var petitions:Array=GovernmentPeopleSystem.administration_records.petitions
	assert_int(petitions.size()).is_equal(1)
	C.observe_petitions(GovernmentPeopleSystem)
	assert_int(petitions.size()).is_equal(1)
	var p:Dictionary=petitions[0]
	var leader:=GovernmentPeopleSystem.settlement_leader(site.id)
	var text:="address petition %d" % int(p.id)
	var order:=AdvisorSystem.begin_civic_directive(text,site.id,leader)
	var result:=AdvisorSystem.resolve_civic_directive(text,{},order,site.id,person)
	assert_bool(result.administrative_result.ok).is_true()
	assert_str(String(site.management_focus)).is_equal("water")
	assert_str(String(p.state)).is_equal("addressing")
	assert_bool(C.dispose_petition(GovernmentPeopleSystem,site.id,person,int(p.id),"resolve").has("error")).is_true()
	GameState.water_metrics.intake_ratio=1.0
	assert_bool(C.dispose_petition(GovernmentPeopleSystem,site.id,person,int(p.id),"resolve").get("ok",false)).is_true()
	assert_bool(C.valid(GovernmentPeopleSystem.administration_records)).is_true()
	var forged:=GovernmentPeopleSystem.administration_records.duplicate(true)
	forged.petitions[0].dispositions.back().observation.active=true
	assert_bool(C.valid(forged)).is_false()
func test_invalid_ledger_and_legacy_absence()->void:
	assert_bool(C.valid(C.empty_state())).is_true()
	var bad:=C.empty_state();bad.work=-1
	assert_bool(C.valid(bad)).is_false()
	bad=C.empty_state();bad.mandates={"foreign":{"settlement_id":"foreign","person_id":-2,"subjects":["water"],"issued_day":1,"expires_day":10}}
	assert_bool(C.valid(bad)).is_false()

func test_four_discoveries_keep_exact_foundations()->void:
	DiscoverySystem.initialize()
	var expected:={"jurisdiction_boundaries":["regional_maps","customary_law"],"official_mandate_registers":["professional_service","jurisdiction_boundaries"],"public_office_handover":["professional_service","formal_archives"],"petition_registers":["phonetic_notation","professional_service"]}
	var entries:=preload("res://scripts/civic_administration_knowledge.gd").entries()
	assert_int(entries.size()).is_equal(4)
	for entry:Dictionary in entries:
		assert_array(entry.requires_all).is_equal(expected[entry.id])
		assert_array(entry.requires_any).is_empty()
		for parent:String in entry.requires_all:
			assert_dict(DiscoverySystem.discovery_definition(parent)).is_not_empty()
func test_full_save_restores_civic_register_without_granting_new_authority()->void:
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	var site:Dictionary=GameState.player_settlements[0]
	var place:=String(site.id);var person:=int(site.leader_person_id)
	C.register_jurisdiction(GovernmentPeopleSystem,place,["water"])
	C.issue_mandate(GovernmentPeopleSystem,place,person,["water"],30)
	var before:=GovernmentPeopleSystem.administration_records.duplicate(true)
	var slot:="codex_civic_test_%d" % Time.get_ticks_usec()
	assert_bool(SaveSystem.save_game(slot).get("ok",false)).is_true()
	GovernmentPeopleSystem.administration_records=C.empty_state()
	var restored:=SaveSystem.load_game(slot)
	assert_bool(restored.get("ok",false)).override_failure_message(str(restored)).is_true()
	assert_dict(GovernmentPeopleSystem.administration_records).is_equal(before)
	assert_bool(C.authorized(GovernmentPeopleSystem,place,person,"water")).is_true()
	assert_bool(C.authorized(GovernmentPeopleSystem,place,person,"shelter")).is_false()
	DirAccess.remove_absolute(SaveSystem.slot_path(slot))
	GameState.set_process(true);CivilizationSystem.set_process(true);MilitaryCampaign.set_process(true)
