extends GdUnitTestSuite

func before_test()->void:
	GameState.reset_for_new_world(90173)
	PeopleDirection.reset_for_new_world()
	CivilizationSystem.reset_for_new_world()
	GovernmentPeopleSystem.reset_for_new_world()

func test_player_choice_is_required_at_exact_century_and_can_be_renewed()->void:
	assert_bool(PeopleDirection.needs_century_choice()).is_true()
	assert_float(PeopleDirection.research_multiplier("security")).is_equal(1.0)
	assert_bool(PeopleDirection.choose("military").get("ok",false)).is_true()
	assert_float(PeopleDirection.research_multiplier("security")).is_equal(1.25)
	GameState.elapsed_days=36499
	assert_bool(PeopleDirection.needs_century_choice()).is_false()
	assert_bool(PeopleDirection.choose("inquiry").has("error")).is_true()
	GameState.elapsed_days=36500
	assert_bool(PeopleDirection.needs_century_choice()).is_true()
	assert_str(PeopleDirection.ambition).is_equal("military")
	assert_float(PeopleDirection.research_multiplier("security")).is_equal(1.0)
	assert_bool(PeopleDirection.choose("military").get("ok",false)).is_true()
	assert_int(PeopleDirection.chosen_century).is_equal(1)
	assert_bool(PeopleDirection.needs_century_choice()).is_false()

func test_skipped_centuries_do_not_autoselect_or_grow_history()->void:
	PeopleDirection.choose("makers")
	PeopleDirection.advance(36500)
	var values:=GameState.societal_values.duplicate(true)
	GameState.elapsed_days=36500*100
	PeopleDirection.advance(int(GameState.elapsed_days))
	assert_bool(PeopleDirection.needs_century_choice()).is_true()
	assert_int(PeopleDirection.history.size()).is_equal(1)
	assert_dict(GameState.societal_values).is_equal(values)
	assert_bool(PeopleDirection.choose("wellbeing").get("ok",false)).is_true()
	assert_int(PeopleDirection.history.size()).is_equal(2)

func test_legacy_save_preserves_its_direction_for_current_century()->void:
	PeopleDirection.choose("inquiry")
	var legacy:=PeopleDirection.export_state()
	legacy.version=1; legacy.erase("chosen_century")
	GameState.elapsed_days=90000
	assert_bool(PeopleDirection.import_state(legacy).get("ok",false)).is_true()
	assert_int(PeopleDirection.chosen_century).is_equal(2)
	assert_str(PeopleDirection.ambition).is_equal("inquiry")
	assert_bool(PeopleDirection.needs_century_choice()).is_false()
	var saved:=PeopleDirection.export_state()
	assert_bool(PeopleDirection.import_state(JSON.parse_string(JSON.stringify(saved))).get("ok",false)).is_true()
	GameState.elapsed_days=109500
	assert_bool(PeopleDirection.needs_century_choice()).is_true()
	assert_bool(PeopleDirection.import_state(saved).get("ok",false)).is_true()
	assert_bool(PeopleDirection.needs_century_choice()).is_true()

func test_invalid_century_is_rejected_without_mutation()->void:
	PeopleDirection.choose("horizons")
	var invalid:=PeopleDirection.export_state()
	invalid.chosen_century=999
	assert_bool(PeopleDirection.import_state(invalid).has("error")).is_true()
	assert_int(PeopleDirection.chosen_century).is_equal(0)
	assert_str(PeopleDirection.ambition).is_equal("horizons")

func test_eight_real_focuses_have_existing_value_axes()->void:
	assert_int(PeopleDirection.AMBITIONS.size()).is_equal(8)
	for focus in PeopleDirection.AMBITIONS.values():
		assert_bool(focus.axis in PeopleDirection.VALUES.VALUE_ORDER).is_true()
		assert_int(focus.domains.size()).is_equal(2)

func test_advice_only_uses_filled_current_offices_and_cannot_choose()->void:
	GameState.initialize_population_model()
	GameState.settlement_site_committed=true
	GameState.settlement_completed=["Hearth Circle"]
	SettlementModel.ensure_founded()
	GovernmentPeopleSystem.initialize()
	var first:=PeopleDirection.advisor_recommendations()
	assert_int(first.size()).is_equal(1)
	if first.is_empty(): return
	assert_str(String(first[0].name)).is_equal(String(GovernmentPeopleSystem.officeholder("Steward").name))
	assert_str(PeopleDirection.ambition).is_empty()
	assert_bool(PeopleDirection.needs_century_choice()).is_true()

func test_unknown_civilizations_cannot_change_recommendations()->void:
	GameState.settlement_site_committed=true
	GameState.settlement_completed=["Hearth Circle"]
	SettlementModel.ensure_founded()
	GovernmentPeopleSystem.initialize()
	var before:=PeopleDirection.advisor_recommendations()
	assert_int(before.size()).is_greater(0)
	for index in CivilizationSystem.civilizations.size():
		CivilizationSystem.civilizations[index].name="SECRET EMPIRE %d" % index
		CivilizationSystem.civilizations[index].military_population=1000000000
		CivilizationSystem.civilizations[index]["aggression"]=1.0
	var after:=PeopleDirection.advisor_recommendations()
	assert_array(after).is_equal(before)
	assert_str(JSON.stringify(after)).not_contains("SECRET")

func test_known_war_and_trade_change_role_specific_advice()->void:
	var known:Array=[{"name":"Known Neighbors","at_war":true,"trade":false}]
	var marshal:=PeopleDirection._recommendation("Marshal",known)
	assert_str(marshal.focus).is_equal("military")
	assert_str(marshal.reason).contains("Known Neighbors")
	var scholar:=PeopleDirection._recommendation("Scholar",known)
	assert_str(scholar.focus).is_equal("inquiry")
	var envoy:=PeopleDirection._recommendation("Envoy",[{"name":"Known Traders","at_war":false,"trade":true}])
	assert_str(envoy.focus).is_equal("commerce")
	assert_str(envoy.reason).contains("Known Traders")

func test_advice_roster_expands_with_real_government_offices()->void:
	GameState.ensure_population_total(10000)
	GameState.society_capacities["institutions"]=0.8
	GameState.settlement_site_committed=true
	GameState.settlement_completed=["Hearth Circle"]
	SettlementModel.ensure_founded()
	GovernmentPeopleSystem.initialize()
	var advice:=PeopleDirection.advisor_recommendations()
	assert_int(advice.size()).is_equal(1) # Vacant specialist offices do not invent advisors.
	for office in GovernmentPeopleSystem.active_offices():
		if String(office.key)=="Steward": continue
		var candidates:=GovernmentPeopleSystem.candidates_for_office(String(office.key),"",96).filter(func(person:Dictionary)->bool: return String(person.get("office_key",""))=="")
		assert_bool(candidates.is_empty()).is_false()
		if candidates.is_empty(): return
		var holder:=GovernmentPeopleSystem.mark_central_appointment(int(candidates[0].person_id),String(office.key))
		GameState.leadership_positions[String(office.key)]=holder
	advice=PeopleDirection.advisor_recommendations()
	assert_int(advice.size()).is_equal(5)
	for entry in advice:
		assert_int(int(entry.person_id)).is_greater(0)
	assert_str(PeopleDirection.ambition).is_empty()
