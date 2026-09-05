extends GdUnitTestSuite

func before_test()->void:
	GameState.reset_for_new_world(424242)
	SettlementModel.reset_for_new_world()
	GovernmentPeopleSystem.reset_for_new_world()
	AdvisorSystem.reset_for_new_world()
	PronouncementInterpreter.reset_for_new_world()
	ConsequenceEngine.reset_for_new_world()
	CivilizationSystem.reset_for_new_world(); CivilizationSystem.initialize()
	ForeignDiplomacy.reset_for_new_world()
	GameState.civic_api_enabled=false
	GameState.initialize_population_model()
	GameState.settlement_site_committed=true; GameState.settlement_completed=["Hearth Circle"]
	SettlementModel.ensure_founded(); GovernmentPeopleSystem.initialize()
	FoodSystem.reset_for_new_world(); FoodSystem.initialize(); FoodSystem.receive_external_food(1000)
	GameState.resource_stockpiles.Timber=100

func _foreign()->String:
	var civ:Dictionary=CivilizationSystem.civilizations[0]
	civ.player_relation.contact_level=2
	civ.player_relation.home_location_known=true
	civ.player_relation.home_position={"x":CivilizationSystem.player_world_origin.x+1,"z":CivilizationSystem.player_world_origin.y}
	return String(civ.id)

func _return_envoys()->void:
	GameState.elapsed_days=int(CivilizationSystem.diplomatic_mission.return_day)
	CivilizationSystem._process_diplomatic_mission(int(GameState.elapsed_days))

func test_audience_requires_real_envoys_and_does_not_purchase_an_accord()->void:
	var id:=_foreign()
	assert_bool(ForeignDialogue.access(id).ok).is_false()
	assert_bool(ForeignDialogue.ask(id,"What do you want?")).is_false()
	assert_bool(ForeignDiplomacy.send_audience(id).get("ok",false)).is_true()
	assert_bool(ForeignDialogue.access(id).ok).is_false()
	assert_bool(ForeignDiplomacy.resolve(id).has("error")).is_true()
	assert_float(float(GameState.resource_stockpiles.Timber)).is_equal(100.0)
	_return_envoys()
	assert_bool(ForeignDialogue.access(id).ok).is_true()
	assert_dict(ForeignDiplomacy.leader(id).accord).is_empty()
	assert_dict(CivilizationSystem.diplomatic_mission).is_empty()

func test_foreign_failure_keeps_context_draft_and_allows_revision_and_withdrawal()->void:
	var id:=_foreign(); ForeignDiplomacy.send_audience(id); _return_envoys()
	assert_bool(ForeignDialogue.accept(id,{"reply":"We could exchange teachers.","accord":"exchange","tone":"equals","generous":false})).is_true()
	var before:int=ForeignDialogue.thread(id).messages.size()
	assert_bool(ForeignDialogue.ask(id,"Why should we contribute more?")).is_true()
	assert_bool(ForeignDialogue.thread(id).retryable).is_true()
	assert_int(ForeignDialogue.thread(id).messages.size()).is_equal(before+1)
	assert_str(ForeignDialogue.thread(id).draft.accord).is_equal("exchange")
	ForeignDialogue.retry(id)
	assert_int(ForeignDialogue.thread(id).messages.size()).is_equal(before+1)
	assert_bool(ForeignDialogue.accept(id,{"reply":"We need safe routes more than teachers.","accord":"routes","tone":"honor","generous":true})).is_true()
	assert_str(ForeignDialogue.thread(id).draft.accord).is_equal("routes")
	assert_bool(ForeignDialogue.ask(id,"withdraw the proposal")).is_true()
	assert_dict(ForeignDialogue.thread(id).draft).is_empty()
	assert_bool(ForeignDialogue.ask(id,"Then what concerns you at the border?")).is_true()
	assert_dict(CivilizationSystem.diplomatic_mission).is_empty()
	assert_float(float(GameState.resource_stockpiles.Timber)).is_equal(100.0)

func test_foreign_transcript_and_draft_survive_save_without_private_world_data()->void:
	var id:=_foreign(); ForeignDiplomacy.send_audience(id); _return_envoys()
	ForeignDialogue.ask(id,"Let us discuss shared waystations.")
	ForeignDialogue.accept(id,{"reply":"Shared waystations may suit us.","accord":"routes","tone":"equals","generous":false})
	var saved:=ForeignDiplomacy.export_state()
	assert_bool(ForeignDiplomacy.import_state(JSON.parse_string(JSON.stringify(saved))).get("ok",false)).is_true()
	assert_str(ForeignDialogue.thread(id).draft.accord).is_equal("routes")
	assert_int(ForeignDialogue.thread(id).messages.size()).is_equal(2)
	var context:=ForeignDialogue.known_context(id)
	assert_bool(context.has("population") or context.has("strength") or context.has("home_position") or context.has("resources")).is_false()
	assert_bool(context.returned_reports.size()>0).is_true()
	saved=ForeignDiplomacy.export_state()
	var invalid:=saved.duplicate(true); invalid.dialogue[id].messages[0].role="system"
	assert_bool(ForeignDiplomacy.import_state(invalid).has("error")).is_true()
	assert_dict(ForeignDiplomacy.export_state()).is_equal(saved)

func test_civic_failure_cannot_execute_and_retry_keeps_original_words()->void:
	var city_id:=String(GameState.player_settlements[0].id)
	var leader:=GovernmentPeopleSystem.settlement_leader(city_id)
	var text:="Expand the watch."
	var local:=PronouncementInterpreter._local_interpretation(text)
	var failed:=PronouncementInterpreter._conversation_service_failure(local)
	assert_array(failed.policies).is_empty()
	var order:=AdvisorSystem.begin_civic_directive(text,city_id,leader)
	AdvisorSystem.resolve_civic_directive(text,failed,order,city_id,int(leader.person_id))
	assert_array(ConsequenceEngine.active_policies()).is_empty()
	assert_str(AdvisorSystem.civic_retry_text("retry",city_id)).is_equal(text)
	assert_int(AdvisorSystem.civic_dialogue_history(city_id).size()).is_equal(2)

func test_clarification_can_change_duration_without_losing_the_pending_policy()->void:
	var city_id:=String(GameState.player_settlements[0].id)
	var leader:=GovernmentPeopleSystem.settlement_leader(city_id)
	var original:="Expand the watch for ninety days."
	var result:=PronouncementInterpreter._local_interpretation(original)
	result.policies[0].confidence=0.6
	var order:=AdvisorSystem.begin_civic_directive(original,city_id,leader)
	AdvisorSystem.resolve_civic_directive(original,result,order,city_id,int(leader.person_id))
	assert_str(order.status).is_equal("awaiting_clarification")
	var revised:=AdvisorSystem.contextualize_civic_followup("No, for thirty days instead.",PronouncementInterpreter._local_interpretation("No, for thirty days instead."),city_id,int(leader.person_id))
	assert_int(revised.policies.size()).is_equal(1)
	assert_float(float(revised.policies[0].days)).is_equal(30.0)
	assert_str(revised.policies[0].id).is_equal("expanded_watch")
	var question:=AdvisorSystem.contextualize_civic_followup("Why?",PronouncementInterpreter._local_interpretation("Why?"),city_id,int(leader.person_id))
	assert_array(question.policies).is_empty()

func test_civic_model_context_retains_full_exchange_and_decisions()->void:
	var history:Array=[]
	for i in 24: history.append({"speaker":"player" if i%2==0 else "leader","text":"turn %d " % i + "x".repeat(900),"status":"discussion"})
	var context:=PronouncementInterpreter._sanitize_public_context({"conversation":history,"decisions":[{"request":"Expand the watch","status":"active","outcome":"Started for 30 days."}]})
	assert_int(context.conversation.size()).is_equal(24)
	assert_int(String(context.conversation[0].text).length()).is_greater(400)
	assert_str(context.decisions[0].outcome).is_equal("Started for 30 days.")

func test_desired_policy_in_discussion_does_not_become_an_order()->void:
	for text in ["I want better shelters, but keep enough timber for winter fuel. What tradeoff should we consider before I give an order?","Can we discuss expanding the watch without committing anyone yet?"]:
		var result:=PronouncementInterpreter._local_interpretation(text)
		assert_bool(result.get("non_directive",false)).is_true()
		assert_array(result.policies).is_empty()

func test_editor_reload_preserves_older_in_memory_foreign_messages()->void:
	var id:=_foreign()
	ForeignDialogue.threads[id]={"messages":[{"role":"assistant","content":JSON.stringify({"reply":"We can keep discussing."})}],"reply":"We can keep discussing.","draft":{}}
	var migrated:=ForeignDialogue.thread(id)
	assert_str(migrated.messages[0].content).is_equal("We can keep discussing.")
	assert_int(int(migrated.messages[0].day)).is_equal(-1)
	assert_bool(ForeignDialogue.validate_state(ForeignDialogue.export_state())).is_true()
