extends GdUnitTestSuite
const F=preload("res://scripts/major_families.gd")
const Orders=preload("res://scripts/court_family_orders.gd")
const Manual=preload("res://scripts/manual_work.gd")
const Society=preload("res://scripts/society_exchange.gd")
const Modal=preload("res://scripts/hud/audience_modal.gd")
const Purse=preload("res://scripts/realm_purse.gd")

func before_test()->void:
	WorldSimulation.clear()
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	GameState.reset_for_new_world(424242);GameState.civic_api_enabled=false
	DiscoverySystem.reset_for_new_world();FoodSystem.reset_for_new_world();MilitaryCampaign.reset_for_new_world();CivilizationSystem.reset_for_new_world()
	ForeignDiplomacy.reset_for_new_world();GovernmentPeopleSystem.reset_for_new_world();PeopleDirection.reset_for_new_world();SettlementModel.reset_for_new_world()
	GameState.ensure_population_total(10000);GameState.housing_capacity=20000
	GameState.settlement_site_committed=true;GameState.settlement_completed=["Hearth Circle"];SettlementModel.ensure_founded()
	GameState.water_metrics.intake_ratio=1.0;GameState.simulation_metrics.food_days=60.0
	GameState.food_stocks={"Preserved food":1000000.0};GameState.resource_stockpiles.Food=1000000.0
	GovernmentPeopleSystem.initialize()
	GameState.elapsed_days=30
	F.ensure()

func after_test()->void:
	WorldSimulation.clear()

func months(count:int)->void:
	for i in count:
		GameState.elapsed_days+=30
		F.tick(int(GameState.elapsed_days))

func mature(population:int,stage:int)->void:
	GameState.ensure_population_total(population)
	for f:Dictionary in F.data().families:f.stage=stage

func test_thresholds_and_all_trades()->void:
	assert_int(F.data().families.size()).is_equal(9)
	for pair:Array in [[9999,0],[10000,1],[99999,1],[100000,2],[500000,3],[5000000,4],[20000000,5]]:
		assert_int(F.ceiling(int(pair[0]))).is_equal(int(pair[1]))
	assert_bool(Society.valid(GameState.society_exchange)).is_true()
	var ids:Array=[]
	for f:Dictionary in F.data().families:
		assert_bool(ids.has(f.head)).is_false();ids.append(f.head)
		assert_str(GovernmentPeopleSystem.person_snapshot(int(f.head)).status).is_equal("active")

func test_no_families_before_10000()->void:
	GameState.society_exchange.erase("major_families");GameState.ensure_population_total(9999)
	F.ensure();F.tick(60)
	assert_bool(F.data().is_empty()).is_true()
	assert_bool(F.decide("favor","Food").ok).is_false()

func test_organization_takes_time_and_favor_accelerates()->void:
	GameState.ensure_population_total(100000)
	F.decide("favor","Knowledge")
	months(4)
	assert_int(F.family("Knowledge").stage).is_equal(2)
	assert_int(F.family("Food").stage).is_equal(1)
	months(2)
	assert_int(F.family("Food").stage).is_equal(2)
	months(40)
	assert_int(F.stage()).is_equal(2)

func test_all_five_stages_keep_identity()->void:
	var name:=String(F.family("Knowledge").name)
	GameState.ensure_population_total(20000000)
	months(80)
	assert_int(F.stage()).is_equal(5)
	assert_str(F.family("Knowledge").name).is_equal(name)
	assert_int(F.data().parties.size()).is_greater(0)
	assert_bool(F.data().parties[String(F.family("Knowledge").party)].full).is_true()
	assert_bool(F.valid(F.data())).is_true()

func test_succession_preserves_institution()->void:
	var f:=F.family("Food");var name:=String(f.name);var old:=int(f.head)
	GovernmentPeopleSystem._person_record(old).status="deceased"
	months(1)
	assert_int(f.head).is_not_equal(old)
	assert_str(f.name).is_equal(name)
	assert_int(f.successions).is_equal(1)

func test_bonuses_leave_automatic_allocation_and_heads_unchanged()->void:
	var before:=GovernmentPeopleSystem._allocations_for_focus("balanced",{},true)
	var allocations:Dictionary=GameState.population_allocations.duplicate(true)
	var workers:=GameState.workers_at("Knowledge")
	F.decide("favor","Knowledge")
	var after:=GovernmentPeopleSystem._allocations_for_focus("balanced",{},true)
	assert_dict(after).is_equal(before)
	assert_dict(GameState.population_allocations).is_equal(allocations)
	assert_float(GameState.workers_at("Knowledge")).is_equal(workers)
	assert_float(F.factor("Knowledge")).is_greater(1.0)
	assert_float(F.factor("Administration")).is_less(1.0)

func test_manual_split_is_not_overwritten()->void:
	Manual.set_manual(true)
	var split:Dictionary=PeopleDirection.work_baseline.duplicate(true)
	var allocations:Dictionary=GameState.population_allocations.duplicate(true)
	F.decide("favor","Defense")
	assert_float(F.factor("Defense")).is_greater(1.0)
	assert_dict(PeopleDirection.work_baseline).is_equal(split)
	assert_dict(GameState.population_allocations).is_equal(allocations)
	assert_str(F.brief()).contains("unchanged")

func test_contest_is_seeded_and_survives_roundtrip()->void:
	mature(100000,2);F.decide("favor","Knowledge")
	var snapshot:=F.data().duplicate(true)
	F._contest(F.data(),390)
	var roll:Dictionary=F.data().roll.duplicate(true)
	GameState.society_exchange.major_families=snapshot
	F._contest(F.data(),390)
	assert_dict(F.data().roll).is_equal(roll)
	var restored:Dictionary=JSON.parse_string(JSON.stringify(F.data()))
	assert_bool(F.valid(restored)).is_true()
	GameState.society_exchange.major_families=restored
	var old:=F.data().duplicate(true)
	F.brief();F.bonuses();F.ensure()
	assert_dict(F.data()).is_equal(old)

func test_opposition_changes_real_program_with_conserved_budget()->void:
	mature(500000,3);F.decide("favor","Knowledge")
	F.data().challenger="Defense"
	assert_float(F.factor("Knowledge")).is_equal_approx(1.039,0.001)
	assert_float(F.factor("Defense")).is_equal(1.0)

func test_political_coalitions_broaden_program()->void:
	mature(5000000,4);F._organize(F.data(),30)
	F.decide("favor","Knowledge")
	assert_bool(F.program("Knowledge").weights.has("Survey")).is_true()
	assert_int(F.data().parties[String(F.family("Knowledge").party)].members.size()).is_greater(1)
	assert_str(F.data().parties[String(F.family("Knowledge").party)].founder).is_not_empty()

func test_full_parties_choose_leaders_outside_founding_houses()->void:
	mature(20000000,5);F._organize(F.data(),30)
	var person:=GovernmentPeopleSystem.admit_person({"name":"New public scholar"})
	var record:=GovernmentPeopleSystem._person_record(int(person.person_id))
	record.skills.Knowledge=1000;record.pride=.1;record.personality.openness=.9
	F._organize(F.data(),390)
	assert_int(F.data().parties[String(F.family("Knowledge").party)].head).is_equal(int(person.person_id))
	assert_bool(F.data().parties[String(F.family("Knowledge").party)].full).is_true()
	assert_str(F.data().parties[String(F.family("Knowledge").party)].founder).is_not_empty()

func test_spending_and_trade_use_existing_ledgers()->void:
	F.decide("fund","Knowledge")
	assert_bool(Purse.line_on("scholars")).is_true()
	assert_bool(Purse.line_on("army")).is_true()
	var result:=F.decide("trade","Logistics")
	assert_bool(result.ok).is_true()
	assert_str(preload("res://scripts/enterprise.gd").stance()).is_equal("open")

func test_population_collapse_suspends_but_remembers()->void:
	F.decide("favor","Knowledge")
	var name:=String(F.family("Knowledge").name)
	GameState.ensure_population_total(9000)
	assert_bool(F.bonuses().is_empty()).is_true()
	assert_str(F.family("Knowledge").name).is_equal(name)
	assert_bool(F.decide("entrust","Defense").ok).is_false()

func test_validation_rejects_corruption_accepts_old_saves()->void:
	assert_bool(F.valid({})).is_true()
	var broken:=F.data().duplicate(true);broken.families[0].standing=NAN
	assert_bool(F.valid(broken)).is_false()
	broken=F.data().duplicate(true);broken.families.append(broken.families[0].duplicate(true))
	assert_bool(F.valid(broken)).is_false()
	GameState.society_exchange.erase("major_families")
	assert_bool(Society.valid(GameState.society_exchange)).is_true()

func test_commands_are_exact_and_do_not_execute_questions()->void:
	var name:=String(F.family("Knowledge").name)
	assert_str(Orders.read("Favor "+name).id).is_equal("Knowledge")
	for words:String in ["Should I favor "+name+"?","Do not favor "+name,"If we favor "+name,"They say favor "+name,"Favor "+name+" if we can"]:
		assert_bool(Orders.read(words).is_empty()).is_true()

func test_panel_buttons_and_new_court_default()->void:
	var modal:=Modal.new();add_child(modal)
	await get_tree().process_frame
	assert_object(modal.find_child("FamilyCourt",true,false)).is_not_null()
	assert_object(modal.find_child("CourtSceneArea",true,false)).is_null()
	var favor:=modal.find_child("FavorFood",true,false) as Button
	assert_object(favor).is_not_null()
	if favor!=null:favor.pressed.emit()
	await get_tree().process_frame
	assert_str(F.data().favored).is_equal("Food")
	assert_str(preload("res://scripts/order_tracker.gd").orders()[0].state).is_equal("done")
	modal.queue_free()
	await get_tree().process_frame

func test_conquest_needs_scale_followers_and_success()->void:
	var person:={"person_id":41,"pride":.8,"personality":{"assertiveness":.9,"risk_tolerance":.9,"openness":.7}}
	for c:Dictionary in [{"population":120,"defenders":8,"victories":2},{"population":100000,"defenders":99,"victories":2},{"population":100000,"defenders":100,"victories":0}]:
		assert_str(F.Character.make(person,"Defense",c).outlook).is_equal("security")
	var profile:=F.Character.make(person,"Defense",{"population":100000,"defenders":100,"victories":2})
	assert_str(profile.outlook).is_equal("conquest")

func test_small_hearth_has_personal_wants_not_political_titles()->void:
	var profile:=F.Character.make({"person_id":1,"personality":{}},"Defense",{"population":120})
	assert_str(profile.want).contains("this fire")
	assert_str(F.Character.speech(profile,1)).not_contains("institutions")
	assert_str(profile.outlook).is_equal("security")

func test_wit_is_optional_stable_and_suppressed_in_hardship()->void:
	var profile:Dictionary=F.family("Knowledge").character.duplicate(true);profile.humor="dry"
	assert_str(F.Character.speech(profile,0)).contains("wrong")
	assert_str(F.Character.speech(profile,0,true)).not_contains("wrong")
	assert_str(F.Character.speech(profile,1)).not_contains("wrong")
	assert_str(F.Character.speech(profile,0)).is_equal(F.Character.speech(profile,0))

func test_values_change_slowly_and_work_preferences_exclude_family_pressure()->void:
	var baseline:Dictionary=F.work_values()
	var allocations:Dictionary=GameState.population_allocations.duplicate(true)
	F.decide("favor","Knowledge")
	GameState.simulation_metrics.knowledge=.9
	months(12)
	assert_float(GameState.societal_values.official.experimentation).is_greater(float(baseline.official.experimentation))
	assert_float(F.work_values().lived.experimentation).is_equal_approx(float(baseline.lived.experimentation),.00001)
	assert_dict(GameState.population_allocations).is_equal(allocations)
	var memory:Dictionary=F.data().culture.duplicate(true)
	F.decide("neutral","")
	assert_dict(F.data().culture).is_equal(memory)
	assert_bool(F.bonuses().is_empty()).is_true()

func test_production_bonus_changes_speed_not_factory_hands()->void:
	var production=preload("res://scripts/persistent_production.gd")
	var before:Dictionary=production.workforce()
	F.decide("favor","Defense")
	var after:Dictionary=production.workforce()
	assert_float(after.workers).is_equal(float(before.workers))
	assert_float(after.condition_factor).is_greater(float(before.condition_factor))

func test_research_bonus_is_applied_to_real_progress()->void:
	var discovery:Dictionary=DiscoverySystem.discovery_definition("clay_shaping")
	var before:=DiscoverySystem.daily_progress(discovery,1.0,1.0,1.0)
	F.decide("favor","Knowledge")
	var after:=DiscoverySystem.daily_progress(discovery,1.0,1.0,1.0)
	assert_float(after).is_equal_approx(before*F.factor("Knowledge"),.00000001)
	assert_float(after).is_greater(before)

func test_family_dialogue_uses_motive_in_both_voice_paths()->void:
	var hall=preload("res://scripts/audience_hall.gd")
	var a:Dictionary=hall.summon({"person_id":int(F.family("Knowledge").head)})
	assert_bool(a.is_empty()).is_false()
	var voice:=preload("res://scripts/audience_voice.gd").new()
	var scene:=voice.scene(String(a.id))
	var lines:Array=voice._offline_open(scene,hall._rng("family-test",30))
	assert_bool(lines.is_empty()).is_false()
	assert_str(String(lines[0].text)).contains("result")
	assert_str(voice.build_prompt(scene,"open",{})).contains(String(F.family("Knowledge").character.want))
	assert_str(voice.court_answer(scene,scene.envoy,"What do you want?")).contains(String(F.family("Knowledge").character.want))
	voice.free()

func test_victory_gate_reads_actual_home_side()->void:
	MilitaryCampaign.battle_history.assign([
		{"home_side":"defender","defender":{"name":"Our guard"},"winner":"Our guard"},
		{"home_side":"attacker","attacker":{"name":"Our army"},"winner":"Their guard"},
		{"home_side":"attacker","attacker":{"name":"Our army"},"winner":"Our army"}])
	assert_int(F.Character.context().victories).is_equal(2)

func test_old_and_new_save_roundtrip_keeps_families_people_and_values()->void:
	var slot:="__family_test_%d_%d" % [OS.get_process_id(),Time.get_ticks_usec()]
	F.decide("favor","Knowledge");months(4)
	var expected:=F.data().duplicate(true)
	var saved:=SaveSystem.save_game(slot)
	assert_bool(saved.get("ok",false)).is_true()
	GameState.society_exchange.erase("major_families")
	var loaded:=SaveSystem.load_game(slot)
	assert_bool(loaded.get("ok",false)).is_true()
	assert_dict(F.data()).is_equal(expected)
	DirAccess.remove_absolute(SaveSystem.slot_path(slot))

func test_family_pressure_is_scoped_to_its_civilization()->void:
	F.decide("favor","Knowledge")
	var player:=F.data().duplicate(true)
	var id:=String(CivilizationSystem.civilizations[0].id)
	WorldSimulation.create_actor(id,424243,Vector2(40,40))
	WorldSimulation.scoped(id,func()->void:
		WorldSimulation.state.ensure_population_total(10000)
		WorldSimulation.government.initialize();F.ensure()
		assert_str(F.data().favored).is_equal("")
		F.decide("favor","Defense")
		assert_str(F.data().favored).is_equal("Defense"))
	assert_dict(F.data()).is_equal(player)

func test_cultural_inheritance_affects_values_after_patronage_ends()->void:
	F.data().culture.experimentation=.85
	var old:=float(GameState.societal_values.lived.experimentation)
	F._advance_values(F.data())
	assert_float(GameState.societal_values.lived.experimentation).is_greater(old)

func test_unfavored_and_corrupt_culture_do_not_change_state()->void:
	var before:Dictionary=GameState.societal_values.duplicate(true)
	F._advance_values(F.data())
	assert_dict(GameState.societal_values).is_equal(before)
	var bad:=F.data().duplicate(true);bad.culture.experimentation=NAN
	assert_bool(F.valid(bad)).is_false()

func test_family_appears_only_when_its_trade_exists()->void:
	GameState.society_exchange.erase("major_families")
	var existing:=int(GameState.population_allocations.Knowledge)
	GameState.population_allocations.Knowledge=0
	GameState.population_allocations.Food+=existing
	F.ensure()
	assert_bool(F.family("Knowledge").is_empty()).is_true()
	GameState.population_allocations.Food-=existing
	GameState.population_allocations.Knowledge=existing
	months(1)
	assert_bool(F.family("Knowledge").is_empty()).is_false()

func test_party_leaders_are_distinct_and_do_not_have_to_be_founders()->void:
	mature(20000000,5)
	F._organize(F.data(),30);F._organize(F.data(),390)
	var leaders:Array=[]
	for party:Dictionary in F.data().parties.values():
		if party.members.is_empty():continue
		assert_bool(leaders.has(party.head)).is_false()
		leaders.append(party.head)

func test_repeated_concessions_do_not_farm_loyalty()->void:
	assert_bool(F.decide("fund","Knowledge").ok).is_true()
	var loyalty:=float(F.family("Knowledge").loyalty)
	assert_bool(F.decide("fund","Knowledge").ok).is_false()
	assert_float(F.family("Knowledge").loyalty).is_equal(loyalty)
	assert_bool(F.decide("trade","Logistics").ok).is_true()
	loyalty=float(F.family("Logistics").loyalty)
	assert_bool(F.decide("trade","Logistics").ok).is_false()
	assert_float(F.family("Logistics").loyalty).is_equal(loyalty)

func test_small_court_does_not_know_future_unlocks_or_hijack_household_questions()->void:
	GameState.society_exchange.erase("major_families")
	GameState.ensure_population_total(120)
	var facts:=preload("res://scripts/court_facts.gd").sheet(["stores"])
	assert_str(String(facts.families)).not_contains("10,000")
	assert_str(String(facts.families)).contains("households")
	var answer:=preload("res://scripts/court_answers.gd").answer(facts,"How many families are held captive?")
	assert_str(answer).is_not_equal(String(facts.families))

func test_court_has_no_parallel_office_screen_or_appointment_dossier()->void:
	var modal:=Modal.new();add_child(modal)
	await get_tree().process_frame
	assert_object(modal.find_child("CourtTabofficials",true,false)).is_null()
	modal.domestic_page="officials";modal.show_court()
	assert_object(modal.find_child("FamilyCourt",true,false)).is_not_null()
	var head:=int(F.family("Knowledge").head)
	assert_str(F.court_title(head)).contains(String(F.family("Knowledge").name))
	assert_str(preload("res://scripts/person_posts.gd").of({"person_id":head}).title).contains(String(F.family("Knowledge").name))
	var rows:=F.court_rows(head)
	assert_bool(rows.any(func(row:Array)->bool:return row[0]=="Wants")).is_true()
	assert_bool(rows.any(func(row:Array)->bool:return row[0] in ["Office","Could hold it","Empty offices"])).is_false()
	var audience:=preload("res://scripts/audience_hall.gd").summon({"person_id":head})
	assert_str(String(audience.get("speaker",{}).get("title",""))).contains(String(F.family("Knowledge").name))
	modal.queue_free();await get_tree().process_frame

func test_small_households_do_not_show_old_office_management()->void:
	GameState.society_exchange.erase("major_families")
	GameState.ensure_population_total(120)
	var modal:=Modal.new();add_child(modal)
	await get_tree().process_frame
	assert_object(modal.find_child("CourtTabofficials",true,false)).is_null()
	assert_object(modal.find_child("CourtTabpeople",true,false)).is_null()
	assert_object(modal.find_child("RosterList",true,false)).is_not_null()
	for entry:Dictionary in preload("res://scripts/hud/court_roster.gd").domestic_people():
		if int(entry.get("target",{}).get("person_id",0))>0:
			assert_str(String(entry.title).to_lower()).not_contains("steward").not_contains("minister")
	modal.queue_free();await get_tree().process_frame
