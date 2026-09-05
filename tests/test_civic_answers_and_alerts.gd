extends GdUnitTestSuite

const REQUEST:="I would like to honor our citizens with a massive bonfire in celebration of our 75th anniversary in 10 years."

func before_test()->void:
	GameState.reset_for_new_world(481902)
	GovernmentPeopleSystem.reset_for_new_world()
	PronouncementInterpreter.reset_for_new_world()
	ConsequenceEngine.reset_for_new_world()
	AdvisorSystem.reset_for_new_world()
	GameState.initialize_population_model()
	GameState.settlement_name="Dawngate"
	GameState.settlement_site_committed=true
	GameState.settlement_completed=["Hearth Circle"]
	SettlementModel.ensure_founded()
	GovernmentPeopleSystem.initialize()

func test_anniversary_request_gets_a_specific_answer_without_an_immediate_policy()->void:
	var city_id:=String(GameState.player_settlements[0].id)
	var leader:=GovernmentPeopleSystem.settlement_leader(city_id)
	var interpreted:=PronouncementInterpreter._local_interpretation(REQUEST)
	var order:=AdvisorSystem.begin_civic_directive(REQUEST,city_id,leader)
	var resolved:=AdvisorSystem.resolve_civic_directive(REQUEST,interpreted,order,city_id,int(leader.person_id))
	assert_str(String(resolved.status)).is_equal("proposal")
	assert_str(String(resolved.leader_reply)).contains("bonfire")
	assert_str(String(resolved.leader_reply)).contains("75th")
	assert_str(String(resolved.leader_reply)).contains("ten years")
	assert_bool("what you have not made clear" in String(resolved.leader_reply)).is_false()
	assert_array(ConsequenceEngine.active_policies()).is_empty()

func test_api_answer_survives_question_guard_without_executing_a_policy()->void:
	var response:={"summary":"An anniversary gathering","answer":"A bonfire could bring the town together. Keep its fuel separate from winter reserves.","policies":[],"unresolved":""}
	var result:=PronouncementInterpreter._validate(response,"What do you think about a bonfire for our anniversary?")
	assert_str(String(result.answer)).is_equal(String(response.answer))
	assert_array(result.policies).is_empty()
	var city_id:=String(GameState.player_settlements[0].id)
	var leader:=GovernmentPeopleSystem.settlement_leader(city_id)
	var question:="What do you think about a bonfire for our anniversary?"
	var order:=AdvisorSystem.begin_civic_directive(question,city_id,leader)
	var resolved:=AdvisorSystem.resolve_civic_directive(question,result,order,city_id,int(leader.person_id))
	assert_str(String(resolved.leader_reply)).contains(String(response.answer))
	assert_array(ConsequenceEngine.active_policies()).is_empty()

func test_future_start_is_not_confused_with_policy_duration()->void:
	assert_int(AdvisorSystem._civic_future_delay(REQUEST)).is_equal(3650)
	assert_int(AdvisorSystem._civic_future_delay("Ration food for ten days.")).is_equal(0)

func test_battle_reports_name_opponent_place_and_outcome()->void:
	var result:={"outcome":"defender_victory","home_side":"defender","target_region_name":"Dawngate","threat":{"source_name":"Reedbank Confederacy"},"defender":{"initial_troops":20,"remaining_troops":14,"morale":0.48}}
	var text:=MilitaryCampaign.battle_report_text(result)
	for required in ["Dawngate","Reedbank Confederacy","14 remaining","6 lost","defended"]: assert_str(text).contains(required)

func test_proposal_is_not_a_leader_refusal_or_an_order_underway()->void:
	var content:RefCounted=load("res://scripts/hud/content/dock_content_civilization.gd").new(null,null)
	assert_str(String(content._directive_state({"status":"proposal","leader_stance":"advises"}))).is_equal("PROPOSAL RECORDED")

func test_administrative_execution_is_never_grounded_as_repression()->void:
	for request in ["Execute on this.", "Execute the plan.", "Please execute our family support policy.", "The executive council should support families."]:
		var result:=PronouncementInterpreter._local_interpretation(request)
		for policy in result.get("policies",[]):
			assert_str(String(policy.id)).is_not_equal("mass_repression")
		var proposed:={"summary":"Implement", "unresolved":"", "policies":[{"id":"mass_repression","basis":"execute","confidence":1.0}]}
		assert_array(PronouncementInterpreter._validate(proposed,request).policies).is_empty()

func test_literal_execution_remains_grounded()->void:
	for request in ["Execute the sick.", "Execute prisoners.", "All men over 70 shall be executed."]:
		var result:=PronouncementInterpreter._local_interpretation(request)
		assert_array(result.policies).is_not_empty()
		assert_str(String(result.policies[0].id)).is_equal("mass_repression")

func test_birthrate_correction_escapes_pending_repression()->void:
	var city_id:=String(GameState.player_settlements[0].id)
	var leader:=GovernmentPeopleSystem.settlement_leader(city_id)
	var prior_text:="Execute the sick."
	var prior_order:=AdvisorSystem.begin_civic_directive(prior_text,city_id,leader)
	var prior:=AdvisorSystem.resolve_civic_directive(prior_text,PronouncementInterpreter._local_interpretation(prior_text),prior_order,city_id,int(leader.person_id))
	var correction:="No, please just increase birthrates? What are you talking about!? Lunatic!"
	var local:=PronouncementInterpreter._local_interpretation(correction)
	assert_array(local.policies).is_not_empty()
	assert_str(String(local.policies[0].id)).is_equal("family_support")
	var order:=AdvisorSystem.begin_civic_directive(correction,city_id,leader)
	var resolved:=AdvisorSystem.resolve_civic_directive(correction,local,order,city_id,int(leader.person_id))
	assert_str(String(prior.status)).is_equal("superseded")
	assert_bool(resolved.has("ethical_deliberation")).is_false()
	assert_bool("My final reading is: use lethal repression" in String(resolved.leader_reply)).is_false()
	for policy in resolved.parameters.interpretation.policies:
		assert_str(String(policy.id)).is_not_equal("mass_repression")

func test_rejection_without_a_replacement_closes_pending_order()->void:
	var city_id:=String(GameState.player_settlements[0].id)
	var leader:=GovernmentPeopleSystem.settlement_leader(city_id)
	var request:="Execute prisoners."
	var order:=AdvisorSystem.begin_civic_directive(request,city_id,leader)
	var prior:=AdvisorSystem.resolve_civic_directive(request,PronouncementInterpreter._local_interpretation(request),order,city_id,int(leader.person_id))
	var rejection:="No, that's not what I meant."
	var reply_order:=AdvisorSystem.begin_civic_directive(rejection,city_id,leader)
	var reply:=AdvisorSystem.resolve_civic_directive(rejection,PronouncementInterpreter._local_interpretation(rejection),reply_order,city_id,int(leader.person_id))
	assert_str(String(prior.status)).is_equal("superseded")
	assert_array(reply.parameters.interpretation.policies).is_empty()
	assert_dict(AdvisorSystem._pending_civic_context(city_id,int(leader.person_id))).is_empty()
