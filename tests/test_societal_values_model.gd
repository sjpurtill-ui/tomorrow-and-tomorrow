extends GdUnitTestSuite

const MODEL:=preload("res://scripts/societal_values_model.gd")


func test_founding_focus_seeds_values_without_creating_an_ideology_label()->void:
	var inquiry:=MODEL.initial_state("inquiry",77,"player")
	var defense:=MODEL.initial_state("defense",77,"player")
	assert_int((inquiry.lived as Dictionary).size()).is_equal(10)
	assert_float(float(inquiry.lived.experimentation)).is_greater(float(defense.lived.experimentation))
	assert_float(float(defense.lived.centralization)).is_greater(float(inquiry.lived.centralization))
	assert_bool(String(inquiry.identity.name).contains("ORDER") or String(inquiry.identity.name).contains("SOCIETY") or String(inquiry.identity.name).contains("STATE") or String(inquiry.identity.name).contains("COMMONWEALTH")).is_true()
	assert_array(MODEL.validate_state(inquiry)).is_empty()


func test_discovery_unlocks_an_institutional_form_but_does_not_snap_lived_values()->void:
	var state:=MODEL.initial_state("generations",91,"player")
	var before:Dictionary=state.lived.duplicate(true)
	state=MODEL.advance(state,["household_councils"],{"household_councils":0.64},{"food":0.8,"health":0.8,"security":0.6,"ecology":0.8,"knowledge":0.3,"trade":0.0,"war_pressure":0.0,"inequality":0.3,"adaptability":0.5},30)
	assert_bool((state.institutions as Dictionary).has("household_councils")).is_true()
	assert_float(float(state.institutions.household_councils.adoption)).is_equal_approx(0.64,0.0001)
	var recorded_adoption:=false
	for event_variant in state.history:
		var event:Dictionary=event_variant
		if String(event.get("type",""))=="institution_adopted":
			recorded_adoption=true
			break
	assert_bool(recorded_adoption).is_true()
	assert_float(absf(float(state.lived.collective_obligation)-float(before.collective_obligation))).is_less(0.02)
	assert_array(MODEL.validate_state(state)).is_empty()


func test_material_history_and_adopted_forms_create_slow_value_divergence()->void:
	var open_society:=MODEL.initial_state("exchange",113,"open")
	var besieged_society:=MODEL.initial_state("defense",113,"besieged")
	var discoveries:Array=["household_councils","census_rolls","public_levies","specialized_courts"]
	var adoption:Dictionary={"household_councils":0.8,"census_rolls":0.7,"public_levies":0.6,"specialized_courts":0.5}
	for year in 20:
		open_society=MODEL.advance(open_society,discoveries,adoption,{"food":0.85,"health":0.82,"security":0.78,"ecology":0.78,"knowledge":0.72,"trade":0.85,"war_pressure":0.0,"inequality":0.28,"adaptability":0.72},(year+1)*365)
		besieged_society=MODEL.advance(besieged_society,discoveries,adoption,{"food":0.38,"health":0.48,"security":0.24,"ecology":0.52,"knowledge":0.30,"trade":0.0,"war_pressure":0.92,"inequality":0.62,"adaptability":0.38},(year+1)*365)
	assert_float(float(open_society.lived.openness)).is_greater(float(besieged_society.lived.openness))
	assert_float(float(besieged_society.lived.centralization)).is_greater(float(open_society.lived.centralization))
	assert_bool(String(open_society.identity.name)!=String(besieged_society.identity.name) or String(open_society.identity.summary)!=String(besieged_society.identity.summary)).is_true()


func test_rivals_use_the_same_fixed_size_organizational_model()->void:
	var civ:Dictionary={"discovery_profile":{"domains":{"institutions":{"count":9,"adoption":0.76}}}}
	var organizations:=MODEL.organizational_discoveries_for_rival(civ)
	var state:=MODEL.initial_state("industry",44,"rival")
	state=MODEL.advance(state,organizations.known,organizations.adoption,{"food":0.7,"health":0.7,"security":0.5,"ecology":0.5,"knowledge":0.6,"trade":0.3,"war_pressure":0.0,"inequality":0.4,"adaptability":0.6},3650)
	assert_int((organizations.known as Array).size()).is_equal(9)
	assert_int((state.institutions as Dictionary).size()).is_equal(9)
	assert_int((state.lived as Dictionary).size()).is_equal(10)
	assert_int(JSON.stringify(state).length()).is_less(12000)
	assert_array(MODEL.validate_state(state)).is_empty()


func test_mature_institutional_inquiry_opens_a_named_organizational_possibility()->void:
	var source_id:="inquiry_institutions_legitimacy_recorded_cases_06"
	var possibilities:=MODEL.organizational_possibilities(
		[source_id],{source_id:0.68}
	)
	assert_array(possibilities.known).contains(["constitutional_order"])
	assert_str(String(possibilities.sources.constitutional_order)).is_equal(source_id)
	assert_float(float(possibilities.adoption.constitutional_order)).is_equal_approx(0.68,0.0001)
	var state:=MODEL.advance(
		MODEL.initial_state("inquiry",112,"constitutional"),[source_id],{source_id:0.68},
		{"food":0.8,"health":0.8,"security":0.6,"ecology":0.7,"knowledge":0.8,"trade":0.4,"war_pressure":0.0,"inequality":0.3,"adaptability":0.8},3650
	)
	assert_bool((state.institutions as Dictionary).has("constitutional_order")).is_true()
	assert_str(String(state.institutions.constitutional_order.source_discovery)).is_equal(source_id)
	assert_array(MODEL.validate_state(state)).is_empty()


func test_vague_institutional_question_does_not_unlock_a_form_before_concrete_maturity()->void:
	var immature_id:="inquiry_institutions_state_capacity_institutional_trial_08"
	var mature_id:="inquiry_institutions_state_capacity_institutional_trial_09"
	var immature:=MODEL.organizational_possibilities([immature_id],{immature_id:0.9})
	var mature:=MODEL.organizational_possibilities([mature_id],{mature_id:0.4})
	assert_bool("mass_public_systems" in immature.known).is_false()
	assert_bool("mass_public_systems" in mature.known).is_true()


func test_same_discovered_possibility_takes_different_forms_under_different_values()->void:
	var source_id:="inquiry_institutions_institutional_flexibility_regional_comparison_11"
	var open_seed:=MODEL.initial_state("inquiry",991,"open_form")
	open_seed.lived.hierarchy=0.12
	open_seed.lived.centralization=0.18
	open_seed.lived.experimentation=0.94
	open_seed.lived.pluralism=0.92
	open_seed.lived.openness=0.88
	var command_seed:=MODEL.initial_state("defense",991,"command_form")
	command_seed.lived.hierarchy=0.92
	command_seed.lived.collective_obligation=0.90
	command_seed.lived.centralization=0.94
	command_seed.lived.experimentation=0.70
	command_seed.lived.pluralism=0.10
	var open_state:=MODEL.advance(MODEL.normalize_state(open_seed),[source_id],{source_id:0.7},{},3650)
	var command_state:=MODEL.advance(MODEL.normalize_state(command_seed),[source_id],{source_id:0.7},{"war_pressure":1.0},3650)
	assert_str(String(open_state.institutions.adaptive_governance.form)).is_not_equal(String(command_state.institutions.adaptive_governance.form))
	assert_int((open_state.institutions as Dictionary).size()).is_less_equal(MODEL.INSTITUTIONS.size()+MODEL.EMERGENT_INSTITUTIONS.size())


func test_mature_rivals_unlock_the_same_bounded_modern_organizational_families()->void:
	var civ:Dictionary={"discovery_profile":{"domains":{"institutions":{"count":150,"maturity":12,"adoption":0.74}}}}
	var organizations:=MODEL.organizational_discoveries_for_rival(civ)
	assert_array(organizations.known).contains(["territorial_administration","constitutional_order","mass_public_systems","adaptive_governance"])
	var state:=MODEL.advance(MODEL.initial_state("industry",512,"modern_rival"),organizations.known,organizations.adoption,{},36_500)
	assert_int((state.institutions as Dictionary).size()).is_equal(13)
	assert_int(JSON.stringify(MODEL.serialize_state(state)).length()).is_less(8_000)
	assert_array(MODEL.validate_state(state)).is_empty()


func test_architecture_is_derived_from_values_without_per_building_state()->void:
	var inquiry:=MODEL.architecture_snapshot(MODEL.initial_state("inquiry",8,"a"))
	var defense:=MODEL.architecture_snapshot(MODEL.initial_state("defense",8,"b"))
	assert_int(inquiry.size()).is_equal(6)
	assert_float(float(defense.axiality)).is_greater(float(inquiry.axiality))
	assert_float(float(inquiry.permeability)).is_greater(float(defense.permeability))


func test_compact_save_round_trip_rebuilds_derived_identity_and_institutions()->void:
	var state:=MODEL.initial_state("inquiry",707,"round_trip")
	state=MODEL.advance(state,["household_councils","census_rolls"],{"household_councils":0.72,"census_rolls":0.44},{"food":0.8,"health":0.75,"security":0.6,"ecology":0.72,"knowledge":0.7,"trade":0.5,"war_pressure":0.0,"inequality":0.25,"adaptability":0.7},365)
	var packed:Dictionary=MODEL.serialize_state(state)
	var json:=JSON.stringify(packed)
	var restored:=MODEL.deserialize_state(JSON.parse_string(json))
	assert_int(json.length()).is_less(2_500)
	assert_str(String(restored.identity.name)).is_equal(String(state.identity.name))
	assert_str(String(restored.institutions.household_councils.form)).is_equal(String(state.institutions.household_councils.form))
	assert_float(float(restored.lived.experimentation)).is_equal_approx(float(state.lived.experimentation),0.0001)
	assert_array(MODEL.validate_state(restored)).is_empty()
