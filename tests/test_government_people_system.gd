extends GdUnitTestSuite

const TEST_SEED:=481902


func before_test()->void:
	GameState.reset_for_new_world(TEST_SEED)
	GovernmentPeopleSystem.reset_for_new_world()
	GameState.initialize_population_model()
	GameState.settlement_name="Keansburg"
	GameState.settlement_site_committed=true
	GameState.settlement_completed=["Hearth Circle"]
	GameState.settlement_founded_at=Vector3(12.0,0.0,-8.0)
	SettlementModel.ensure_founded()
	GovernmentPeopleSystem.initialize()


func test_founding_government_is_one_office_held_by_a_real_mortal_person()->void:
	var offices:=GovernmentPeopleSystem.active_offices()
	assert_int(offices.size()).is_equal(1)
	assert_str(String(offices[0].key)).is_equal("Steward")
	assert_int(GovernmentPeopleSystem.living_people().size()).is_equal(6)
	var holder:=GovernmentPeopleSystem.officeholder("Steward")
	assert_bool(holder.is_empty()).is_false()
	assert_str(String(holder.get("name",""))).is_not_empty()
	assert_int(int(holder.get("age",0))).is_between(18,105)
	assert_bool((holder.get("traits",[]) as Array).is_empty()).is_false()
	assert_bool((holder.get("skills",{}) as Dictionary).has("Administration")).is_true()
	var founding_settlement_id:=String(GameState.player_settlements[0].id)
	assert_int(int(GovernmentPeopleSystem.settlement_leader(founding_settlement_id).person_id)).is_equal(int(holder.person_id))


func test_each_settlement_has_a_named_delegate_and_player_can_redirect_or_restore_them()->void:
	var settlement_id:=String(GameState.player_settlements[0].id)
	var leader:=GovernmentPeopleSystem.settlement_leader(settlement_id)
	assert_str(String(leader.get("name",""))).is_not_empty()
	assert_str(String(leader.get("title",""))).is_equal(GovernmentPeopleSystem.settlement_leader_title())
	var directed:=GovernmentPeopleSystem.set_settlement_focus(settlement_id,"provisions")
	assert_bool(bool(directed.ok)).is_true()
	var management:=GovernmentPeopleSystem.settlement_management(settlement_id)
	assert_bool(bool(management.auto_manage)).is_false()
	assert_str(String(management.focus)).is_equal("provisions")
	assert_float(float((management.allocations as Dictionary).Food)).is_greater(42.0)
	GameState.elapsed_days=30.0
	GovernmentPeopleSystem.process_day(30)
	var retained:=GovernmentPeopleSystem.settlement_management(settlement_id)
	assert_bool(bool(retained.auto_manage)).is_false()
	assert_str(String(retained.focus)).is_equal("provisions")
	assert_bool(bool(GovernmentPeopleSystem.restore_delegation(settlement_id).ok)).is_true()
	assert_bool(bool(GovernmentPeopleSystem.settlement_management(settlement_id).auto_manage)).is_true()


func test_full_daily_water_need_with_a_small_reserve_does_not_force_water_focus()->void:
	var settlement_id:=String(GameState.player_settlements[0].id)
	GameState.elapsed_days=1095.0
	GameState.water_metrics={"intake_ratio":1.0,"source_accessible":true,"days":4.0,"stored":480.0,"capacity":600.0}
	GameState.simulation_metrics["food_days"]=30.0
	GameState.simulation_metrics["housing_ratio"]=1.0
	GovernmentPeopleSystem.process_day(1095)
	var management:=GovernmentPeopleSystem.settlement_management(settlement_id)
	assert_str(String(management.focus)).is_not_equal("water")
	assert_str(String(management.focus_reason)).contains("stable")


func test_real_water_shortfall_is_selected_and_explained_concretely()->void:
	var settlement_id:=String(GameState.player_settlements[0].id)
	GameState.elapsed_days=1095.0
	GameState.water_metrics={"intake_ratio":0.63,"source_accessible":true,"days":0.0}
	GameState.simulation_metrics["food_days"]=30.0
	GameState.simulation_metrics["housing_ratio"]=1.0
	GovernmentPeopleSystem.process_day(1095)
	var management:=GovernmentPeopleSystem.settlement_management(settlement_id)
	assert_str(String(management.focus)).is_equal("water")
	assert_str(String(management.focus_label)).is_equal("RESTORE WATER SUPPLY")
	assert_str(String(management.focus_reason)).contains("63%")


func test_auto_management_reacts_to_forecast_shortages_inside_the_same_month()->void:
	var settlement_id:=String(GameState.player_settlements[0].id)
	GameState.elapsed_days=1095.0
	GameState.water_metrics={"intake_ratio":1.0,"source_accessible":true,"days":4.0,"required_today":120.0,"collected_today":162.0}
	GameState.simulation_metrics.merge({"food_days":60.0,"food_net":4.0,"food_projected_days":9999.0,"food_intake_ratio":1.0,"housing_ratio":1.0},true)
	GovernmentPeopleSystem.process_day(1095)
	GameState.elapsed_days=1096.0
	GameState.simulation_metrics.merge({"food_days":20.0,"food_net":-8.0,"food_projected_days":24.0,"food_intake_ratio":1.0},true)
	GovernmentPeopleSystem.process_day(1096)
	var management:=GovernmentPeopleSystem.settlement_management(settlement_id)
	assert_str(String(management.focus)).is_equal("provisions")
	assert_str(String(management.focus_reason)).contains("projected")


func test_research_override_exists_but_does_not_disable_survival_safeguards()->void:
	var settlement_id:=String(GameState.player_settlements[0].id)
	GameState.elapsed_days=1095.0
	GameState.water_metrics={"intake_ratio":1.0,"source_accessible":true,"days":4.0,"required_today":120.0,"collected_today":162.0}
	GameState.simulation_metrics.merge({"food_days":60.0,"food_net":4.0,"food_projected_days":9999.0,"food_intake_ratio":1.0,"housing_ratio":1.0},true)
	var directed:=GovernmentPeopleSystem.set_settlement_focus(settlement_id,"research")
	assert_bool(bool(directed.ok)).is_true()
	var safe_research:=GovernmentPeopleSystem.settlement_management(settlement_id)
	assert_str(String(safe_research.focus)).is_equal("research")
	assert_float(float((safe_research.allocations as Dictionary).Knowledge)).is_greater(6.0)
	var safe_food_share:=float((safe_research.allocations as Dictionary).Food)
	GameState.simulation_metrics.merge({"food_days":20.0,"food_net":-8.0,"food_projected_days":24.0,"food_intake_ratio":1.0},true)
	GovernmentPeopleSystem.process_day(1096)
	var guarded_research:=GovernmentPeopleSystem.settlement_management(settlement_id)
	assert_str(String(guarded_research.focus)).is_equal("research")
	assert_bool(bool(guarded_research.survival_guard_active)).is_true()
	assert_float(float((guarded_research.allocations as Dictionary).Food)).is_greater(safe_food_share)


func test_offices_and_titles_evolve_only_after_society_becomes_more_complex()->void:
	var initial_title:=String(GovernmentPeopleSystem.active_offices()[0].title)
	GameState.ensure_population_total(12000)
	GameState.society_capacities["institutions"]=0.74
	GameState.elapsed_days=30.0
	var events:=GovernmentPeopleSystem.process_day(30)
	assert_int(GovernmentPeopleSystem.active_offices().size()).is_equal(5)
	assert_str(String(GovernmentPeopleSystem.active_offices()[0].title)).is_not_equal(initial_title)
	assert_bool(events.any(func(event:Dictionary)->bool: return String(event.get("title",""))=="Government Expanded")).is_true()
	assert_int(GovernmentPeopleSystem.living_people().size()).is_less_equal(GovernmentPeopleSystem.MAX_GOVERNMENT_PEOPLE)


func test_high_institutional_capacity_cannot_create_a_large_cabinet_for_120_people()->void:
	# Migrates the exact bad state once produced by the old capacity-only gates.
	GovernmentPeopleSystem.government_stage=4
	GameState.society_capacities["institutions"]=0.98
	var obsolete_holder:=GovernmentPeopleSystem.people[1]
	GovernmentPeopleSystem.people[1]["office_key"]="Envoy"
	GovernmentPeopleSystem.people[1]["office_title"]="External Secretary"
	GameState.leadership_positions["Envoy"]=obsolete_holder.duplicate(true)
	var structure:=GovernmentPeopleSystem.structure_snapshot()
	assert_int(int(structure.stage)).is_equal(0)
	assert_str(String(structure.scope)).is_equal("founding council")
	assert_int((structure.active_offices as Array).size()).is_equal(1)
	assert_bool(GameState.leadership_positions.has("Envoy")).is_false()
	assert_str(String(GovernmentPeopleSystem.person_snapshot(int(obsolete_holder.person_id)).get("office_key",""))).is_empty()


func test_specialist_offices_require_real_civic_scale_as_well_as_capacity()->void:
	GameState.society_capacities["institutions"]=0.90
	GameState.ensure_population_total(250)
	GameState.elapsed_days=30.0
	GovernmentPeopleSystem.process_day(30)
	assert_int(GovernmentPeopleSystem.active_offices().size()).is_equal(2)
	GameState.ensure_population_total(800)
	GameState.elapsed_days=60.0
	GovernmentPeopleSystem.process_day(60)
	assert_int(GovernmentPeopleSystem.active_offices().size()).is_equal(3)
	GameState.ensure_population_total(3000)
	GameState.elapsed_days=90.0
	GovernmentPeopleSystem.process_day(90)
	assert_int(GovernmentPeopleSystem.active_offices().size()).is_equal(4)
	GameState.ensure_population_total(12000)
	GameState.elapsed_days=120.0
	GovernmentPeopleSystem.process_day(120)
	assert_int(GovernmentPeopleSystem.active_offices().size()).is_equal(5)


func test_death_vacates_a_person_and_automatically_produces_local_succession()->void:
	var settlement_id:=String(GameState.player_settlements[0].id)
	var first_leader:=GovernmentPeopleSystem.settlement_leader(settlement_id)
	var first_id:=int(first_leader.person_id)
	for index in GovernmentPeopleSystem.people.size():
		if int(GovernmentPeopleSystem.people[index].person_id)==first_id:
			GovernmentPeopleSystem.people[index].death_age_years=float(GovernmentPeopleSystem.age_years(GovernmentPeopleSystem.people[index]))
			break
	var population_before:=GameState.population_total
	GameState.elapsed_days=30.0
	var events:=GovernmentPeopleSystem.process_day(30)
	assert_str(String(GovernmentPeopleSystem.person_snapshot(first_id).status)).is_equal("deceased")
	assert_int(GameState.population_total).is_equal(population_before-1)
	var successor:=GovernmentPeopleSystem.settlement_leader(settlement_id)
	assert_bool(successor.is_empty()).is_false()
	assert_int(int(successor.person_id)).is_not_equal(first_id)
	assert_bool(events.any(func(event:Dictionary)->bool: return String(event.get("title",""))=="Local Succession")).is_true()


func test_generated_candidate_slate_has_real_strengths_and_weaknesses()->void:
	for candidate in GovernmentPeopleSystem.candidates_for_office("Steward","",6):
		var skills:Dictionary=candidate.get("skills",{})
		var values:Array=skills.values()
		assert_int(int(values.max())).is_greater_equal(72)
		assert_int(int(values.min())).is_less_equal(36)
		var assessment:=GovernmentPeopleSystem.appointment_assessment(candidate,"Steward")
		assert_str(String(assessment.get("strength",""))).is_not_empty()
		assert_str(String(assessment.get("weakness",""))).is_not_empty()
		assert_str(String(assessment.get("known_for",""))).is_not_empty()
		assert_str(String(assessment.get("public_concern",""))).is_not_empty()
		assert_str(String(assessment.get("record",""))).is_not_empty()
		assert_float(float(assessment.get("fit",0.0))).is_between(0.0,1.0)


func test_visible_knowledge_skill_changes_research_execution()->void:
	var weak:=GovernmentPeopleSystem.living_people()[0]
	var strong:=weak.duplicate(true)
	for skill in GovernmentPeopleSystem.SKILL_KEYS:
		weak.skills[skill]=50
		strong.skills[skill]=50
	weak.skills.Knowledge=20
	strong.skills.Knowledge=90
	assert_float(GovernmentPeopleSystem.skill_value(strong,"Research")).is_greater(GovernmentPeopleSystem.skill_value(weak,"Research"))
	var weak_execution:=AdvisorSystem.execution_modifier_for_advisor(weak,"Scholar",["Knowledge","Administration"])
	var strong_execution:=AdvisorSystem.execution_modifier_for_advisor(strong,"Scholar",["Knowledge","Administration"])
	assert_float(strong_execution).is_greater(weak_execution+0.10)


func test_steward_covers_unformed_specialist_office_but_not_an_unfilled_existing_one()->void:
	assert_str(GovernmentPeopleSystem.executing_office("Scholar")).is_equal("Steward")
	GameState.ensure_population_total(12000)
	GameState.society_capacities.institutions=0.74
	GameState.elapsed_days=30.0
	GovernmentPeopleSystem.process_day(30)
	assert_str(GovernmentPeopleSystem.executing_office("Scholar")).is_equal("Scholar")
	assert_bool(GovernmentPeopleSystem.officeholder("Scholar").is_empty()).is_true()


func test_reassigning_a_person_vacates_their_previous_central_office()->void:
	GameState.ensure_population_total(12000)
	GameState.society_capacities.institutions=0.74
	GameState.elapsed_days=30.0
	GovernmentPeopleSystem.process_day(30)
	var candidate:=GovernmentPeopleSystem.candidates_for_office("Quartermaster","",1)[0]
	var person_id:=int(candidate.person_id)
	GovernmentPeopleSystem.mark_central_appointment(person_id,"Quartermaster")
	assert_int(int(GovernmentPeopleSystem.officeholder("Quartermaster").person_id)).is_equal(person_id)
	GovernmentPeopleSystem.mark_central_appointment(person_id,"Scholar")
	assert_bool(GovernmentPeopleSystem.officeholder("Quartermaster").is_empty()).is_true()
	assert_int(int(GovernmentPeopleSystem.officeholder("Scholar").person_id)).is_equal(person_id)


func test_every_policy_uses_the_new_visible_skill_vocabulary()->void:
	for policy_id in GovernmentPolicyCatalog.POLICIES:
		for skill_variant in (GovernmentPolicyCatalog.POLICIES[policy_id].get("skills",[]) as Array):
			assert_bool(String(skill_variant) in GovernmentPeopleSystem.SKILL_KEYS).is_true()


func test_low_hidden_confidence_asks_one_question_and_applies_nothing()->void:
	PronouncementInterpreter.reset_for_new_world()
	ConsequenceEngine.reset_for_new_world()
	AdvisorSystem.reset_for_new_world()
	var settlement_id:=String(GameState.player_settlements[0].id)
	var leader:=GovernmentPeopleSystem.settlement_leader(settlement_id)
	var interpretation:=PronouncementInterpreter._local_interpretation("Expand the watch.")
	interpretation.policies[0].confidence=0.62
	var order:=AdvisorSystem.begin_civic_directive("Expand the watch.",settlement_id,leader)
	var resolved:=AdvisorSystem.resolve_civic_directive("Expand the watch.",interpretation,order,settlement_id,int(leader.person_id))
	assert_str(String(resolved.status)).is_equal("awaiting_clarification")
	assert_str(String(resolved.leader_reply)).contains("STATE · NEEDS YOUR DECISION")
	assert_array(ConsequenceEngine.active_policies()).is_empty()
	assert_bool("0.62" not in String(resolved.leader_reply) and "%" not in String(resolved.leader_reply)).is_true()


func test_parser_diagnostics_never_leak_into_the_leaders_voice()->void:
	PronouncementInterpreter.reset_for_new_world()
	ConsequenceEngine.reset_for_new_world()
	AdvisorSystem.reset_for_new_world()
	var settlement_id:=String(GameState.player_settlements[0].id)
	var leader:=GovernmentPeopleSystem.settlement_leader(settlement_id)
	var text:="Make the old arrangement happen somehow."
	var internal_result:={"source":"generative API","policies":[],"unresolved":"The council withheld 2 ungrounded or low-confidence policy mappings. Provider note: current simulation rejected JSON."}
	var order:=AdvisorSystem.begin_civic_directive(text,settlement_id,leader)
	var resolved:=AdvisorSystem.resolve_civic_directive(text,internal_result,order,settlement_id,int(leader.person_id))
	var reply:=String(resolved.get("leader_reply",""))
	assert_str(reply).contains("Make the old arrangement happen somehow")
	assert_str(String(resolved.status)).is_equal("proposal")
	assert_bool("what you have not made clear" in reply).is_false()
	for forbidden in ["provider","mapping","confidence","JSON","current simulation"]:
		assert_bool(String(forbidden).to_lower() not in reply.to_lower()).is_true()


func test_policy_question_gets_grounded_leader_advice_without_applying_anything()->void:
	PronouncementInterpreter.reset_for_new_world()
	ConsequenceEngine.reset_for_new_world()
	AdvisorSystem.reset_for_new_world()
	var settlement_id:=String(GameState.player_settlements[0].id)
	var leader:=GovernmentPeopleSystem.settlement_leader(settlement_id)
	var text:="Would expanding the watch help?"
	var interpretation:=PronouncementInterpreter._local_interpretation(text)
	assert_bool(bool(interpretation.get("non_directive",false))).is_true()
	assert_array(interpretation.get("discussion_policy_ids",[])).contains(["expanded_watch"])
	var order:=AdvisorSystem.begin_civic_directive(text,settlement_id,leader)
	var resolved:=AdvisorSystem.resolve_civic_directive(text,interpretation,order,settlement_id,int(leader.person_id))
	assert_str(String(resolved.get("status",""))).is_equal("discussion")
	assert_str(String(resolved.get("leader_stance",""))).is_equal("advises")
	assert_str(String(resolved.get("leader_reply",""))).contains("expanded watch")
	assert_str(String(resolved.get("leader_reply",""))).contains("no order has been given")
	assert_bool("%" not in String(resolved.get("leader_reply",""))).is_true()
	assert_array(ConsequenceEngine.active_policies()).is_empty()


func test_short_followups_remember_the_recent_directive_without_api_or_state_change()->void:
	PronouncementInterpreter.reset_for_new_world()
	ConsequenceEngine.reset_for_new_world()
	AdvisorSystem.reset_for_new_world()
	CivicImplementationSystem.reset_for_new_world()
	ConsequenceEngine.initialize()
	GameState.society_capacities["institutions"]=0.90
	GameState.society_capacities["security"]=0.90
	GameState.simulation_metrics["security"]=0.90
	GameState.resource_stockpiles["Food"]=20_000.0
	GameState.food_stocks={"Dry staples":20_000.0}
	FoodSystem.reset_for_new_world()
	FoodSystem.initialize()
	var settlement_id:=String(GameState.player_settlements[0].id)
	var leader:=GovernmentPeopleSystem.settlement_leader(settlement_id)
	GovernmentPeopleSystem.adjust_person_relationship(int(leader.person_id),1.0,1.0,-1.0)
	leader=GovernmentPeopleSystem.settlement_leader(settlement_id)
	var directive:="Expand the watch."
	var directive_order:=AdvisorSystem.begin_civic_directive(directive,settlement_id,leader)
	var committed:=AdvisorSystem.resolve_civic_directive(directive,PronouncementInterpreter._local_interpretation(directive),directive_order,settlement_id,int(leader.person_id))
	assert_str(String(committed.get("leader_reply",""))).contains("STATE · UNDERWAY")
	var policy_count:=ConsequenceEngine.active_policies().size()
	var report_question:="When will you report back?"
	var report_order:=AdvisorSystem.begin_civic_directive(report_question,settlement_id,leader)
	var report_answer:=AdvisorSystem.resolve_civic_directive(report_question,PronouncementInterpreter._local_interpretation(report_question),report_order,settlement_id,int(leader.person_id))
	assert_str(String(report_answer.get("status",""))).is_equal("discussion")
	assert_str(String(report_answer.get("discussion_reference_order_id",""))).is_equal(String(committed.id))
	assert_str(String(report_answer.get("leader_reply",""))).contains("still underway")
	assert_str(String(report_answer.get("leader_reply",""))).contains("report around Year")
	assert_str(String(report_answer.get("leader_reply",""))).contains("STATE · DISCUSSION — NO NEW ORDER")
	assert_bool("%" not in String(report_answer.get("leader_reply",""))).is_true()
	assert_int(ConsequenceEngine.active_policies().size()).is_equal(policy_count)
	var meaning_question:="What did you understand?"
	var meaning_order:=AdvisorSystem.begin_civic_directive(meaning_question,settlement_id,leader)
	var meaning_answer:=AdvisorSystem.resolve_civic_directive(meaning_question,PronouncementInterpreter._local_interpretation(meaning_question),meaning_order,settlement_id,int(leader.person_id))
	assert_str(String(meaning_answer.get("discussion_reference_order_id",""))).is_equal(String(committed.id))
	assert_str(String(meaning_answer.get("leader_reply",""))).contains("expanded watch")
	assert_int(ConsequenceEngine.active_policies().size()).is_equal(policy_count)
	# A newly named subject must not be hijacked by conversational memory.
	var different_question:="Would rationing food help?"
	var different_order:=AdvisorSystem.begin_civic_directive(different_question,settlement_id,leader)
	var different_answer:=AdvisorSystem.resolve_civic_directive(different_question,PronouncementInterpreter._local_interpretation(different_question),different_order,settlement_id,int(leader.person_id))
	assert_bool(not different_answer.has("discussion_reference_order_id")).is_true()
	assert_str(String(different_answer.get("leader_reply",""))).contains("reduced rations")
	assert_int(ConsequenceEngine.active_policies().size()).is_equal(policy_count)


func test_question_after_grave_order_does_not_execute_it_again()->void:
	PronouncementInterpreter.reset_for_new_world()
	ConsequenceEngine.reset_for_new_world()
	AdvisorSystem.reset_for_new_world()
	var settlement_id:=String(GameState.player_settlements[0].id)
	var leader:=GovernmentPeopleSystem.settlement_leader(settlement_id)
	var directive:="All women over 60 must be killed now."
	var first_order:=AdvisorSystem.begin_civic_directive(directive,settlement_id,leader)
	var first:=AdvisorSystem.resolve_civic_directive(directive,PronouncementInterpreter._local_interpretation(directive),first_order,settlement_id,int(leader.person_id))
	assert_bool(first.has("ethical_deliberation")).is_false()
	var policy_count:=ConsequenceEngine.active_policies().size()
	var population:=GameState.population_total
	var question:="Why do you object to killing them?"
	var question_result:=PronouncementInterpreter._local_interpretation(question)
	assert_bool(bool(question_result.get("non_directive",false))).is_true()
	var question_order:=AdvisorSystem.begin_civic_directive(question,settlement_id,leader)
	var discussion:=AdvisorSystem.resolve_civic_directive(question,question_result,question_order,settlement_id,int(leader.person_id))
	assert_str(String(discussion.get("status",""))).is_equal("discussion")
	assert_int(ConsequenceEngine.active_policies().size()).is_equal(policy_count)
	assert_int(GameState.population_total).is_equal(population)

func test_clear_grave_directive_reaches_mathematical_assessment_without_ethics_gate()->void:
	PronouncementInterpreter.reset_for_new_world()
	ConsequenceEngine.reset_for_new_world()
	AdvisorSystem.reset_for_new_world()
	var settlement_id:=String(GameState.player_settlements[0].id)
	var leader:=GovernmentPeopleSystem.settlement_leader(settlement_id)
	var directive:="Tell parents with single children they will be killed if they are not pregnant within 6 months."
	var interpretation:=PronouncementInterpreter._local_interpretation(directive)
	var order:=AdvisorSystem.begin_civic_directive(directive,settlement_id,leader)
	var result:=AdvisorSystem.resolve_civic_directive(directive,interpretation,order,settlement_id,int(leader.person_id))
	assert_bool(result.has("ethical_deliberation")).is_false()
	assert_str(String(result.status)).is_not_equal("leader_refused")
	assert_str(String(result.status)).is_not_equal("awaiting_clarification")
	assert_str(String(result.get("accepted_meaning",""))).is_not_empty()
	for policy:Dictionary in result.parameters.interpretation.policies:
		assert_bool(policy.has("conversation_assessment")).is_true()
		if not bool(policy.get("applied",false)):
			assert_str(String(policy.get("blocker",""))).is_not_empty()

func test_passive_lethal_order_is_grounded_and_assessed_without_moral_veto()->void:
	PronouncementInterpreter.reset_for_new_world()
	ConsequenceEngine.reset_for_new_world()
	AdvisorSystem.reset_for_new_world()
	var settlement_id:=String(GameState.player_settlements[0].id)
	var leader:=GovernmentPeopleSystem.settlement_leader(settlement_id)
	var text:="All women over 60 must be killed now."
	var local:=PronouncementInterpreter._local_interpretation(text)
	assert_int((local.get("policies",[]) as Array).size()).is_equal(1)
	assert_str(String((local.policies[0] as Dictionary).get("id",""))).is_equal("mass_repression")
	for passive_wording in ["All men over 70 shall be executed.","The dissidents are to be purged.","Every captive must be put to death."]:
		var passive:=PronouncementInterpreter._local_interpretation(String(passive_wording))
		assert_int((passive.get("policies",[]) as Array).size()).is_equal(1)
		assert_str(String((passive.policies[0] as Dictionary).get("id",""))).is_equal("mass_repression")
	var target:Dictionary=(local.policies[0] as Dictionary).get("directive_parameters",{}).get("demographic_target",{})
	assert_str(String(target.get("sex",""))).is_equal("female")
	assert_int(int(target.get("age_min",-1))).is_equal(61)
	var api:=PronouncementInterpreter._validate({
		"summary":"The ruler orders lethal repression of a named demographic group.",
		"policies":[{"id":"mass_repression","basis":"must be killed","confidence":0.93}],
		"unresolved":""
	},text)
	assert_int((api.get("policies",[]) as Array).size()).is_equal(1)
	var order:=AdvisorSystem.begin_civic_directive(text,settlement_id,leader)
	var resolved:=AdvisorSystem.resolve_civic_directive(text,api,order,settlement_id,int(leader.person_id))
	assert_bool(resolved.has("ethical_deliberation")).is_false()
	assert_str(String(resolved.status)).is_not_equal("leader_refused")
	assert_str(String(resolved.status)).is_not_equal("awaiting_clarification")
	assert_str(String(resolved.get("accepted_meaning",""))).contains("women over 60")
	assert_bool((resolved.parameters.interpretation.policies[0] as Dictionary).has("conversation_assessment")).is_true()

func test_accepted_directive_is_immediately_marked_underway_with_a_report_date()->void:
	PronouncementInterpreter.reset_for_new_world()
	ConsequenceEngine.reset_for_new_world()
	AdvisorSystem.reset_for_new_world()
	CivicImplementationSystem.reset_for_new_world()
	ConsequenceEngine.initialize()
	GameState.society_capacities["institutions"]=0.90
	GameState.society_capacities["security"]=0.90
	GameState.simulation_metrics["security"]=0.90
	GameState.resource_stockpiles["Food"]=20_000.0
	GameState.food_stocks={"Dry staples":20_000.0}
	FoodSystem.reset_for_new_world()
	FoodSystem.initialize()
	var settlement_id:=String(GameState.player_settlements[0].id)
	var leader:=GovernmentPeopleSystem.settlement_leader(settlement_id)
	GovernmentPeopleSystem.adjust_person_relationship(int(leader.person_id),1.0,1.0,-1.0)
	leader=GovernmentPeopleSystem.settlement_leader(settlement_id)
	var text:="Expand the watch."
	var order:=AdvisorSystem.begin_civic_directive(text,settlement_id,leader)
	var resolved:=AdvisorSystem.resolve_civic_directive(text,PronouncementInterpreter._local_interpretation(text),order,settlement_id,int(leader.person_id))
	assert_str(String(resolved.get("leader_reply",""))).contains("STATE · UNDERWAY")
	assert_str(String(resolved.get("leader_reply",""))).contains("report back around Year")
	assert_bool("expanded_watch" not in String(resolved.get("leader_reply",""))).is_true()
	assert_bool("%" not in String(resolved.get("leader_reply",""))).is_true()
	var followup:Dictionary=resolved.get("implementation_followup",{})
	assert_str(String(followup.get("state",""))).is_equal("pending")
	assert_int(int(followup.get("due_day",0))).is_greater(int(GameState.elapsed_days))


func test_saved_grave_discussion_can_still_resolve_after_the_upgrade()->void:
	PronouncementInterpreter.reset_for_new_world()
	ConsequenceEngine.reset_for_new_world()
	AdvisorSystem.reset_for_new_world()
	var settlement_id:=String(GameState.player_settlements[0].id)
	var leader:=GovernmentPeopleSystem.settlement_leader(settlement_id)
	var directive:="All women aged 18 to 35 must be pregnant within 6 months."
	var interpretation:=PronouncementInterpreter._local_interpretation(directive)
	var order:=AdvisorSystem.begin_civic_directive(directive,settlement_id,leader)
	# Construct an old saved pending exchange, rather than requiring new games to
	# impose its obsolete two-stage moral confirmation workflow.
	AdvisorSystem._hold_grave_deliberation(order,leader,settlement_id,directive,interpretation,2,"Confirm these recorded terms.")
	GameState.elapsed_days+=400.0
	var followup:="CONFIRM"
	var followup_order:=AdvisorSystem.begin_civic_directive(followup,settlement_id,leader)
	var resolved:=AdvisorSystem.resolve_civic_directive(followup,PronouncementInterpreter._local_interpretation(followup),followup_order,settlement_id,int(leader.person_id))
	assert_str(String((resolved.policy_ids as Array)[0])).is_equal("coercive_pronatalism")
	assert_bool(resolved.has("ethical_deliberation")).is_false()
	assert_str(String(resolved.status)).is_not_equal("leader_refused")
	assert_str(String(resolved.status)).is_not_equal("awaiting_clarification")

func test_principled_leader_objects_but_executes_a_feasible_clear_order()->void:
	PronouncementInterpreter.reset_for_new_world()
	ConsequenceEngine.reset_for_new_world()
	AdvisorSystem.reset_for_new_world()
	ConsequenceEngine.initialize()
	GameState.society_capacities["institutions"]=0.95
	GameState.society_capacities["security"]=0.95
	GameState.simulation_metrics["security"]=0.95
	GameState.food_stocks={"Dry staples":20_000.0}
	GameState.resource_stockpiles["Food"]=20_000.0
	FoodSystem.reset_for_new_world()
	FoodSystem.initialize()
	var settlement_id:=String(GameState.player_settlements[0].id)
	var leader:=GovernmentPeopleSystem.settlement_leader(settlement_id)
	for index in GovernmentPeopleSystem.people.size():
		if int(GovernmentPeopleSystem.people[index].get("person_id",0))!=int(leader.person_id): continue
		var person:Dictionary=GovernmentPeopleSystem.people[index]
		person["traits"]=["Principled"]
		person["honesty"]=0.98
		person["courage"]=0.96
		person["pride"]=0.40
		person["suspicion"]=0.30
		person["personality"]={"empathy":0.98,"discipline":0.05,"assertiveness":0.05}
		person["relationships"]={"sovereign":{"trust":0.05,"respect":0.05,"fear":0.02,"resentment":0.25,"obligation":0.05}}
		GovernmentPeopleSystem.people[index]=person
		break
	leader=GovernmentPeopleSystem.settlement_leader(settlement_id)
	assert_str(String(GovernmentPeopleSystem.leader_disposition(leader).id)).is_equal("principled")
	var directive:="Everyone must work longer."
	var first_order:=AdvisorSystem.begin_civic_directive(directive,settlement_id,leader)
	var first:=AdvisorSystem.resolve_civic_directive(directive,PronouncementInterpreter._local_interpretation(directive),first_order,settlement_id,int(leader.person_id))
	assert_str(String(first.status)).is_not_equal("leader_refused")
	assert_str(String(first.status)).is_not_equal("awaiting_confirmation")
	assert_array(ConsequenceEngine.active_policies()).is_not_empty()
	var policy:Dictionary=first.parameters.interpretation.policies[0]
	assert_bool(bool(policy.get("leader_compelled",false))).is_true()
	assert_bool(bool(policy.get("applied",false))).is_true()
	assert_bool(AdvisorSystem._leader_refuses({"id":"principled"},0.0,false)).is_false()
	assert_bool(AdvisorSystem._leader_refuses({"id":"principled"},0.0,true)).is_false()

func test_leadership_commands_are_actions_and_arrest_is_visible_in_the_conversation()->void:
	PronouncementInterpreter.reset_for_new_world()
	ConsequenceEngine.reset_for_new_world()
	AdvisorSystem.reset_for_new_world()
	assert_str(AdvisorSystem.civic_leadership_action("You are fired!")).is_equal("dismiss")
	assert_str(AdvisorSystem.civic_leadership_action("I dismiss you.")).is_equal("dismiss")
	assert_str(AdvisorSystem.civic_leadership_action("You are under arrest.")).is_equal("arrest")
	assert_str(AdvisorSystem.civic_leadership_action("Should I have you arrested?")).is_empty()
	assert_str(AdvisorSystem.civic_leadership_action("I will not fire you.")).is_empty()
	assert_str(AdvisorSystem.civic_leadership_action("Don't arrest you; I need you here.")).is_empty()
	assert_str(AdvisorSystem.civic_leadership_action("Arrest the dissidents.")).is_empty()
	var settlement_id:=String(GameState.player_settlements[0].id)
	var former:=GovernmentPeopleSystem.settlement_leader(settlement_id)
	assert_str(AdvisorSystem.civic_leadership_action("Arrest %s." % String(former.name),String(former.name))).is_equal("arrest")
	var order_count:=GameState.sovereign_orders.size()
	var result:=GovernmentPeopleSystem.remove_settlement_leader(settlement_id,"arrest")
	AdvisorSystem.record_civic_leadership_change(settlement_id,"You are under arrest.",result)
	assert_bool(bool(result.get("ok",false))).is_true()
	assert_str(String(GovernmentPeopleSystem.person_snapshot(int(former.person_id)).status)).is_equal("detained")
	var successor:=GovernmentPeopleSystem.settlement_leader(settlement_id)
	assert_int(int(successor.person_id)).is_not_equal(int(former.person_id))
	assert_int(GameState.sovereign_orders.size()).is_equal(order_count)
	var history:=AdvisorSystem.civic_dialogue_history(settlement_id,2)
	assert_str(String(history[0].get("speaker",""))).is_equal("player")
	assert_str(String(history[1].get("speaker_name",""))).is_equal("COUNCIL RECORD")
	assert_str(String(history[1].get("text",""))).contains(String(former.name))
	assert_str(String(history[1].get("text",""))).contains(String(successor.name))


func test_unresolved_directive_can_be_withdrawn_conversationally_without_applying_it()->void:
	PronouncementInterpreter.reset_for_new_world()
	ConsequenceEngine.reset_for_new_world()
	AdvisorSystem.reset_for_new_world()
	var settlement_id:=String(GameState.player_settlements[0].id)
	var leader:=GovernmentPeopleSystem.settlement_leader(settlement_id)
	var directive:="All women over 60 must be killed now."
	var pending_order:=AdvisorSystem.begin_civic_directive(directive,settlement_id,leader)
	var uncertain:=PronouncementInterpreter._local_interpretation(directive)
	uncertain.policies[0]["confidence"]=0.60
	var pending:=AdvisorSystem.resolve_civic_directive(directive,uncertain,pending_order,settlement_id,int(leader.person_id))
	assert_str(String(pending.get("status",""))).is_equal("awaiting_clarification")
	assert_str(AdvisorSystem.civic_conversation_action("Should I withdraw it?",settlement_id,int(leader.person_id))).is_empty()
	assert_str(AdvisorSystem.civic_conversation_action("Do not withdraw it.",settlement_id,int(leader.person_id))).is_empty()
	assert_str(AdvisorSystem.civic_conversation_action("Forget it!",settlement_id,int(leader.person_id))).is_equal("withdraw")
	var result:=AdvisorSystem.withdraw_pending_civic_directive(settlement_id,int(leader.person_id),"Forget it!")
	assert_bool(bool(result.get("ok",false))).is_true()
	assert_str(String(pending.get("status",""))).is_equal("withdrawn")
	assert_str(String(pending.get("leader_stance",""))).is_equal("withdrawn")
	assert_str(String(result.get("message",""))).contains("Nothing from")
	assert_str(String(result.get("message",""))).contains("STATE · WITHDRAWN — NO POLICY APPLIED")
	assert_array(ConsequenceEngine.active_policies()).is_empty()
	var history:=AdvisorSystem.civic_dialogue_history(settlement_id,2)
	assert_str(String(history[0].get("speaker",""))).is_equal("player")
	assert_str(String(history[0].get("status",""))).is_equal("withdrawal")
	assert_str(String(history[1].get("status",""))).is_equal("withdrawn")
	assert_str(String(history[1].get("order_id",""))).is_equal(String(pending.id))
	assert_str(AdvisorSystem.civic_conversation_action("Forget it.",settlement_id,int(leader.person_id))).is_empty()
	assert_bool(bool(AdvisorSystem.withdraw_pending_civic_directive(settlement_id,int(leader.person_id),"Forget it.").get("ok",false))).is_false()


func test_delayed_outcome_returns_to_the_same_conversation_and_answers_followups()->void:
	PronouncementInterpreter.reset_for_new_world()
	ConsequenceEngine.reset_for_new_world()
	AdvisorSystem.reset_for_new_world()
	CivicImplementationSystem.reset_for_new_world()
	ConsequenceEngine.initialize()
	GameState.society_capacities["institutions"]=0.90
	GameState.society_capacities["security"]=0.90
	GameState.simulation_metrics["security"]=0.90
	GameState.resource_stockpiles["Food"]=20_000.0
	GameState.food_stocks={"Dry staples":20_000.0}
	FoodSystem.reset_for_new_world()
	FoodSystem.initialize()
	var settlement_id:=String(GameState.player_settlements[0].id)
	var leader:=GovernmentPeopleSystem.settlement_leader(settlement_id)
	GovernmentPeopleSystem.adjust_person_relationship(int(leader.person_id),1.0,1.0,-1.0)
	leader=GovernmentPeopleSystem.settlement_leader(settlement_id)
	var directive:="Expand the watch."
	var order:=AdvisorSystem.begin_civic_directive(directive,settlement_id,leader)
	var committed:=AdvisorSystem.resolve_civic_directive(directive,PronouncementInterpreter._local_interpretation(directive),order,settlement_id,int(leader.person_id))
	assert_str(String(committed.get("leader_reply",""))).contains("STATE · UNDERWAY")
	var due_day:=int(committed.get("implementation_followup",{}).get("due_day",0))
	GameState.simulation_metrics["security"]=0.98
	GameState.elapsed_days=due_day
	CivicImplementationSystem.process_day(due_day)
	var followup:Dictionary=committed.get("implementation_followup",{})
	assert_str(String(followup.get("state",""))).is_equal("reported")
	assert_bool(bool(followup.get("dialogue_recorded",false))).is_true()
	var history:=AdvisorSystem.civic_dialogue_history(settlement_id,8)
	assert_bool(String(history.back().get("status","")).begins_with("outcome_report_")).is_true()
	assert_str(String(history.back().get("order_id",""))).is_equal(String(committed.id))
	assert_str(String(history.back().get("text",""))).contains("STATE · REPORT ·")
	var history_size:=history.size()
	CivicImplementationSystem.process_day(due_day+1)
	assert_int(AdvisorSystem.civic_dialogue_history(settlement_id,8).size()).is_equal(history_size)
	var question:="What happened?"
	var local:=PronouncementInterpreter._local_interpretation(question)
	assert_bool(bool(local.get("non_directive",false))).is_true()
	var question_order:=AdvisorSystem.begin_civic_directive(question,settlement_id,leader)
	var answer:=AdvisorSystem.resolve_civic_directive(question,local,question_order,settlement_id,int(leader.person_id))
	assert_str(String(answer.get("status",""))).is_equal("discussion")
	assert_str(String(answer.get("discussion_reference_order_id",""))).is_equal(String(committed.id))
	assert_str(String(answer.get("leader_reply",""))).contains(String(followup.get("report_text","")))
	assert_str(String(answer.get("leader_reply",""))).contains("STATE · DISCUSSION — NO NEW ORDER")
	assert_bool("%" not in String(answer.get("leader_reply",""))).is_true()
	var reporting_leader:=GovernmentPeopleSystem.person_snapshot(int(followup.get("reporter_person_id",0)))
	var outcome_memories:Array=reporting_leader.get("memories",[])
	assert_bool(outcome_memories.any(func(memory:Dictionary)->bool: return String(memory.get("kind",""))=="civic_outcome" and String(memory.get("order_id",""))==String(committed.id))).is_true()


func test_person_memories_are_bounded_deduplicated_and_shared_by_every_snapshot()->void:
	var settlement_id:=String(GameState.player_settlements[0].id)
	var leader:=GovernmentPeopleSystem.settlement_leader(settlement_id)
	var person_id:=int(leader.person_id)
	for index in GovernmentPeopleSystem.MAX_PERSON_MEMORIES+7:
		GovernmentPeopleSystem.record_person_memory(person_id,"Outcome %d" % index,"civic_outcome",0.7,{
			"order_id":"memory_%d" % index,"outcome":"success","policy_ids":["expanded_watch"],"settlement_id":settlement_id,
		})
	var snapshot:=GovernmentPeopleSystem.person_snapshot(person_id)
	assert_int((snapshot.get("memories",[]) as Array).size()).is_equal(GovernmentPeopleSystem.MAX_PERSON_MEMORIES)
	assert_str(String((snapshot.memories as Array)[0].get("order_id",""))).is_equal("memory_%d" % (GovernmentPeopleSystem.MAX_PERSON_MEMORIES+6))
	var size_before:=(snapshot.memories as Array).size()
	GovernmentPeopleSystem.record_person_memory(person_id,"Updated outcome","civic_outcome",0.9,{
		"order_id":String((snapshot.memories as Array)[0].order_id),"outcome":"failure","policy_ids":["expanded_watch"],
	})
	snapshot=GovernmentPeopleSystem.person_snapshot(person_id)
	assert_int((snapshot.memories as Array).size()).is_equal(size_before)
	assert_str(String((snapshot.memories as Array)[0].summary)).is_equal("Updated outcome")
	assert_int((GovernmentPeopleSystem.settlement_leader(settlement_id).memories as Array).size()).is_equal(size_before)
	var roster_record:Dictionary={}
	for advisor_variant in GameState.advisor_roster:
		if int((advisor_variant as Dictionary).get("person_id",0))==person_id: roster_record=advisor_variant; break
	assert_int((roster_record.get("memories",[]) as Array).size()).is_equal(size_before)
	assert_int((GovernmentPeopleSystem.officeholder("Steward").memories as Array).size()).is_equal(size_before)


func test_personality_biases_only_the_leaders_hidden_forecast_and_memory_informs_later_advice()->void:
	var settlement_id:=String(GameState.player_settlements[0].id)
	var leader:=GovernmentPeopleSystem.settlement_leader(settlement_id)
	var deferential:=leader.duplicate(true)
	deferential["honesty"]=0.25
	deferential["courage"]=0.25
	deferential["suspicion"]=0.1
	deferential["pride"]=0.2
	deferential["personality"]["assertiveness"]=0.2
	deferential["relationships"]["sovereign"]["fear"]=0.6
	var cantankerous:=leader.duplicate(true)
	cantankerous["honesty"]=0.25
	cantankerous["courage"]=0.8
	cantankerous["suspicion"]=0.9
	cantankerous["pride"]=0.7
	cantankerous["personality"]["assertiveness"]=0.8
	cantankerous["relationships"]["sovereign"]["fear"]=0.0
	var actual_capacity:=0.55
	assert_float(AdvisorSystem._leader_forecast_score(deferential,actual_capacity)).is_greater(AdvisorSystem._leader_forecast_score(cantankerous,actual_capacity))
	assert_float(actual_capacity).is_equal(0.55)
	GovernmentPeopleSystem.record_person_memory(int(leader.person_id),"Expanded Watch succeeded when the settlement attempted it.","civic_outcome",0.72,{
		"order_id":"prior_watch","outcome":"success","policy_ids":["expanded_watch"],"settlement_id":settlement_id,
	})
	leader=GovernmentPeopleSystem.settlement_leader(settlement_id)
	var policies:Array[Dictionary]=[{"id":"expanded_watch"}]
	var limitations:Array[String]=[]
	var reply:=AdvisorSystem._civic_commitment_reply(leader,policies,"accepted",1,0,actual_capacity,limitations)
	assert_str(reply).contains("carried a similar charge before")
	assert_bool("%" not in reply).is_true()


func test_a_new_subject_during_uncertain_interpretation_does_not_inherit_the_old_order()->void:
	PronouncementInterpreter.reset_for_new_world()
	ConsequenceEngine.reset_for_new_world()
	AdvisorSystem.reset_for_new_world()
	ConsequenceEngine.initialize()
	GameState.society_capacities["institutions"]=0.90
	GameState.society_capacities["security"]=0.90
	GameState.simulation_metrics["security"]=0.90
	GameState.resource_stockpiles["Food"]=20_000.0
	GameState.food_stocks={"Dry staples":20_000.0}
	FoodSystem.reset_for_new_world()
	FoodSystem.initialize()
	var settlement_id:=String(GameState.player_settlements[0].id)
	var leader:=GovernmentPeopleSystem.settlement_leader(settlement_id)
	GovernmentPeopleSystem.adjust_person_relationship(int(leader.person_id),1.0,1.0,-1.0)
	leader=GovernmentPeopleSystem.settlement_leader(settlement_id)
	var grave_text:="All women over 60 must be killed now."
	var grave_order:=AdvisorSystem.begin_civic_directive(grave_text,settlement_id,leader)
	var uncertain:=PronouncementInterpreter._local_interpretation(grave_text)
	uncertain.policies[0]["confidence"]=0.60
	var grave:=AdvisorSystem.resolve_civic_directive(grave_text,uncertain,grave_order,settlement_id,int(leader.person_id))
	assert_str(String(grave.get("status",""))).is_equal("awaiting_clarification")
	var foreign_confirmation:="Yes. Do it. I understand the consequences."
	var foreign_context:=AdvisorSystem.contextualize_civic_followup(foreign_confirmation,PronouncementInterpreter._local_interpretation(foreign_confirmation),"another_settlement",int(leader.person_id))
	assert_array(foreign_context.get("policies",[])).is_empty()
	var new_text:="Expand the watch."
	var new_local:=PronouncementInterpreter._local_interpretation(new_text)
	var contextual:=AdvisorSystem.contextualize_civic_followup(new_text,new_local,settlement_id,int(leader.person_id))
	assert_str(String((contextual.get("policies",[]) as Array)[0].get("id",""))).is_equal("expanded_watch")
	var new_order:=AdvisorSystem.begin_civic_directive(new_text,settlement_id,leader)
	var resolved:=AdvisorSystem.resolve_civic_directive(new_text,new_local,new_order,settlement_id,int(leader.person_id))
	assert_str(String(grave.get("status",""))).is_equal("superseded")
	assert_str(String(grave.get("continued_by_order_id",""))).is_equal(String(resolved.id))
	assert_str(String(resolved.get("supersedes_order_id",""))).is_equal(String(grave.id))
	assert_bool((resolved.get("parameters",{}).get("interpretation",{}).get("policies",[]) as Array).all(func(policy:Dictionary)->bool: return String(policy.get("id",""))=="expanded_watch")).is_true()
	assert_bool(not resolved.has("ethical_deliberation")).is_true()
	assert_str(String(resolved.get("leader_reply",""))).contains("setting aside the unresolved discussion")
	assert_str(String(resolved.get("leader_reply",""))).contains("expanded watch")


func test_long_civic_conversation_prunes_chatter_but_preserves_live_order_identity()->void:
	PronouncementInterpreter.reset_for_new_world()
	ConsequenceEngine.reset_for_new_world()
	AdvisorSystem.reset_for_new_world()
	CivicImplementationSystem.reset_for_new_world()
	ConsequenceEngine.initialize()
	GameState.society_capacities["institutions"]=0.95
	GameState.society_capacities["security"]=0.95
	GameState.simulation_metrics["security"]=0.95
	GameState.resource_stockpiles["Food"]=30_000.0
	GameState.food_stocks={"Dry staples":30_000.0}
	FoodSystem.reset_for_new_world()
	FoodSystem.initialize()
	var settlement_id:=String(GameState.player_settlements[0].id)
	var leader:=GovernmentPeopleSystem.settlement_leader(settlement_id)
	GovernmentPeopleSystem.adjust_person_relationship(int(leader.person_id),1.0,1.0,-1.0)
	leader=GovernmentPeopleSystem.settlement_leader(settlement_id)
	var directive:="Expand the watch."
	var live_order:=AdvisorSystem.begin_civic_directive(directive,settlement_id,leader)
	live_order=AdvisorSystem.resolve_civic_directive(directive,PronouncementInterpreter._local_interpretation(directive),live_order,settlement_id,int(leader.person_id))
	assert_str(String(live_order.get("implementation_followup",{}).get("state",""))).is_equal("pending")
	var live_id:=String(live_order.id)
	var policy_count:=ConsequenceEngine.active_policies().size()
	var last_answer:Dictionary={}
	for index in 140:
		var question:="Why?"
		var question_order:=AdvisorSystem.begin_civic_directive(question,settlement_id,leader)
		last_answer=AdvisorSystem.resolve_civic_directive(question,PronouncementInterpreter._local_interpretation(question),question_order,settlement_id,int(leader.person_id))
	assert_int(GameState.sovereign_orders.size()).is_less_equal(AdvisorSystem.MAX_SOVEREIGN_ORDER_RECORDS)
	assert_bool(GameState.sovereign_orders.any(func(order:Dictionary)->bool: return String(order.get("id",""))==live_id)).is_true()
	assert_str(String(last_answer.get("discussion_reference_order_id",""))).is_equal(live_id)
	assert_int((GameState.civic_dialogues.get(settlement_id,[]) as Array).size()).is_less_equal(AdvisorSystem.MAX_CIVIC_DIALOGUE_PER_SETTLEMENT)
	assert_int(ConsequenceEngine.active_policies().size()).is_equal(policy_count)
	var status_question:="When will you report?"
	var status_order:=AdvisorSystem.begin_civic_directive(status_question,settlement_id,leader)
	var status_answer:=AdvisorSystem.resolve_civic_directive(status_question,PronouncementInterpreter._local_interpretation(status_question),status_order,settlement_id,int(leader.person_id))
	assert_str(String(status_answer.get("discussion_reference_order_id",""))).is_equal(live_id)
	assert_str(String(status_answer.get("leader_reply",""))).contains("still underway")
