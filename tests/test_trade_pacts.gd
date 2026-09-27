extends GdUnitTestSuite
## Standing exchanges (trade_pacts.gd) and the envoy talk that concludes into
## them (foreign_dialogue.gd): the model's structured terms are validated and
## clamped, agreeing words lead to a seal, a ruler cannot defer forever, sealed
## exchanges run for years through real stores with honest shortfalls, and
## everything survives a save. The live model is always mocked.

const Pacts:=preload("res://scripts/trade_pacts.gd")
const Hall:=preload("res://scripts/audience_hall.gd")
const Rivals:=preload("res://scripts/rival_rulers.gd")

## The brief from the reported conversation.
const BRIEF:="Offer Temba ten timber for one hundred rations of food each year, for ten years, each food payment made when its timber portion is delivered."
## What the envoy carried: we give 100 Food a year, they give 10 Timber.
const CARRIED:={"player_gives":"Food","player_amount":100,"foreign_gives":"Timber","foreign_amount":10,"cadence":"year","portions":10,"when_ready":true,"carry_debt":false}
const TEMBA_DEFERS:="Ten timber for one hundred rations when a portion is ready, with no debt carried forward. I will take that arrangement to my council. This is still a proposal, not a binding agreement."

func before_test()->void:
	OS.set_environment("OPENAI_API_KEY","")
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
	FoodSystem.reset_for_new_world(); FoodSystem.initialize(); FoodSystem.receive_external_food(3000)
	GameState.resource_stockpiles.Timber=100.0
	GameState.resource_stockpiles.Stone=200.0

func _foreign()->String:
	var civ:Dictionary=CivilizationSystem.civilizations[0]
	civ.player_relation.contact_level=2
	civ.player_relation.home_location_known=true
	civ.player_relation.home_position={"x":CivilizationSystem.player_world_origin.x+1,"z":CivilizationSystem.player_world_origin.y}
	civ.player_relation.opinion=0.2
	civ.population=180; civ.food_days=60.0
	return String(civ.id)

func _return_envoys()->void:
	GameState.elapsed_days=int(CivilizationSystem.diplomatic_mission.return_day)
	CivilizationSystem._process_diplomatic_mission(int(GameState.elapsed_days))

func _meet()->String:
	var id:=_foreign(); ForeignDiplomacy.send_audience(id); _return_envoys()
	return id

func _reply(text:String,exchange:Dictionary,envoy_terms:Dictionary=CARRIED)->Dictionary:
	return {"envoy_words":"My ruler would send you a hundred rations of food a year for ten timber, each payment when the timber comes, for ten years.","reply":text,
		"accord":"","tone":"equals","generous":false,"reaction":"unchanged","commitment":{},"envoy_terms":envoy_terms.duplicate(),"exchange":exchange.duplicate()}

func _round(id:String,reply:Dictionary)->void:
	## One envoy round trip with a mocked answer.
	assert_bool(ForeignDialogue.ask(id,BRIEF)).is_true()
	ForeignDialogue.thread(id).staged_result=reply
	ForeignDialogue.thread(id).retryable=false
	_return_envoys()

func _terms(give_res:String,give:int,get_res:String,got:int,cadence:String="year",portions:int=5,when_ready:bool=false,debt:bool=false)->Dictionary:
	return {"give_res":give_res,"give_amt":give,"get_res":get_res,"get_amt":got,"cadence":cadence,"portions":portions,"when_ready":when_ready,"carry_debt":debt}

# --------------------------------------------------------------------------

func test_model_terms_are_validated_and_clamped()->void:
	var id:=_foreign()
	var terms:=Pacts.from_model(CARRIED)
	assert_str(String(terms.give_res)).is_equal("Food")
	assert_int(int(terms.give_amt)).is_equal(100)
	assert_str(String(terms.get_res)).is_equal("Timber")
	assert_bool(Pacts.valid_terms(terms)).is_true()
	# Malformed shapes are not terms.
	var same:=CARRIED.duplicate(); same.foreign_gives="Food"
	assert_dict(Pacts.from_model(same)).is_empty()
	var missing:=CARRIED.duplicate(); missing.erase("cadence")
	assert_dict(Pacts.from_model(missing)).is_empty()
	var bogus:=CARRIED.duplicate(); bogus.player_gives="Gold"
	assert_dict(Pacts.from_model(bogus)).is_empty()
	# Too many portions are clamped to ten years.
	var long:=CARRIED.duplicate(); long.portions=80
	assert_int(int(Pacts.from_model(long).portions)).is_equal(10)
	# Numbers said in words or digits.
	var said:=Pacts.numbers_in(BRIEF)
	assert_bool(10 in said and 100 in said).is_true()
	assert_bool(120 in Pacts.numbers_in("one hundred and twenty loads")).is_true()
	assert_bool(1500 in Pacts.numbers_in("1,500 rations")).is_true()
	assert_bool(Pacts.grounded(terms,BRIEF)).is_true()
	assert_bool(Pacts.grounded(Pacts.from_model(long),"we spoke of seven and twelve")).is_false()
	# Their promise is bounded by what they hold and by the era's porters.
	var huge:=_terms("Food",100,"Timber",5000)
	var fitted:=Pacts.fit(id,huge)
	assert_int(int(fitted.terms.get_amt)).is_less_equal(Pacts.cap("Timber"))
	assert_int(int(fitted.terms.get_amt)).is_equal(Pacts.their_limit(id,"Timber"))
	assert_array(fitted.notes).is_not_empty()
	var heavy:=_terms("Stone",9000,"Food",10)
	assert_int(int(Pacts.fit(id,heavy).terms.give_amt)).is_equal(Pacts.cap("Stone"))
	# The live schema offers the exchange and the carried terms; once a decision
	# is owed, "consult" is no longer an answer the model may give.
	var schema:Dictionary=ForeignDialogue.response_format(id).json_schema.schema
	assert_bool("exchange" in schema.required and "envoy_terms" in schema.required).is_true()
	var stances:Array=schema.properties.exchange.anyOf[1].properties.stance.enum
	assert_bool("consult" in stances and "accept" in stances).is_true()
	ForeignDialogue.thread(id).must_decide=true
	stances=ForeignDialogue.response_format(id).json_schema.schema.properties.exchange.anyOf[1].properties.stance.enum
	assert_bool("consult" in stances).is_false()
	ForeignDialogue.thread(id).must_decide=false
	# A reply whose exchange is not an object is rejected outright.
	var broken:=_reply("Yes.",{}); broken.exchange="accept"
	assert_bool(ForeignDialogue._valid_response(broken,false)).is_false()

func test_invented_or_unkeepable_acceptances_do_not_stand()->void:
	var id:=_meet()
	# Numbers nobody said are dropped: no exchange draft.
	var invented:=_reply("Agreed.",{"player_gives":"Food","player_amount":37,"foreign_gives":"Timber","foreign_amount":9,"cadence":"year","portions":3,"when_ready":false,"carry_debt":false,"stance":"accept"},{})
	assert_str(ForeignDialogue.exchange_problem(id,invented)).contains("invent")
	assert_bool(ForeignDialogue.accept(id,invented)).is_true()
	assert_bool((ForeignDialogue.thread(id).draft as Dictionary).has("exchange")).is_false()
	# Accepting far more than their people hold is not an acceptance.
	var greedy_terms:={"player_gives":"Food","player_amount":10,"foreign_gives":"Timber","foreign_amount":900,"cadence":"year","portions":3,"when_ready":false,"carry_debt":false}
	var greedy:=_reply("Nine hundred timber a year for ten food. Agreed.",greedy_terms.merged({"stance":"accept"}),greedy_terms)
	greedy.envoy_words="We asked for nine hundred timber a year and offered ten food."
	assert_str(ForeignDialogue.exchange_problem(id,greedy)).is_not_empty()
	assert_bool(ForeignDialogue.accept(id,greedy)).is_true()
	var draft:Dictionary=ForeignDialogue.thread(id).draft
	assert_bool(String(draft.get("stance","")) in ["counter","refuse"]).is_true()
	if String(draft.stance)=="counter":assert_int(int(draft.exchange.get_amt)).is_less_equal(Pacts.their_limit(id,"Timber"))
	assert_str(String(ForeignDialogue.thread(id).reply)).not_contains("Agreed")

func test_reported_conversation_converges_and_seals()->void:
	var id:=_meet()
	# Round one: the old answer, word for word in substance. Terms carried,
	# no decision: that is a deferral to their council, dated.
	_round(id,_reply(TEMBA_DEFERS,{}))
	var t:=ForeignDialogue.thread(id)
	assert_str(String(t.draft.stance)).is_equal("consult")
	assert_bool(Pacts.same_terms(t.council.terms,Pacts.from_model(CARRIED))).is_true()
	assert_bool(ForeignDialogue.sealable(id)).is_false()
	# Round two: the next envoy must bring a decision. The council has decided
	# and a second "I will take it to my council" is not allowed to stand.
	assert_bool(ForeignDialogue.ask(id,BRIEF)).is_true()
	assert_bool(bool(t.must_decide)).is_true()
	assert_str(String(t.council.decision.decision)).is_equal("accept")
	var context:=ForeignDialogue.known_context(id)
	assert_bool(bool(context.standing_exchange.decision_required)).is_true()
	assert_str(String(context.standing_exchange.council_answer.decision)).is_equal("accept")
	var again:=_reply(TEMBA_DEFERS,CARRIED.merged({"stance":"consult"}))
	assert_str(ForeignDialogue.exchange_problem(id,again)).contains("council has already decided")
	t.staged_result=again; t.retryable=false
	_return_envoys()
	assert_str(String(t.draft.stance)).is_equal("accept")
	assert_str(String(t.reply)).contains("I agree")
	assert_str(String(t.reply)).not_contains("council")
	assert_bool(ForeignDialogue.sealable(id)).is_true()
	# Sealing binds both peoples to the exact terms carried.
	var sealed:=ForeignDialogue.seal(id)
	assert_bool(sealed.get("ok",false)).is_true()
	assert_bool(Pacts.same_terms(sealed.pact.terms,Pacts.from_model(CARRIED))).is_true()
	assert_dict(t.draft).is_empty()
	assert_str(String((t.messages as Array).back().content)).starts_with("Sealed:")
	assert_int(Pacts.pacts(id).size()).is_equal(1)

func test_a_live_acceptance_of_the_carried_terms_seals_in_one_round()->void:
	var id:=_meet()
	_round(id,_reply("A hundred rations a year for ten timber, each paid when the timber arrives, for ten years. I agree to that.",CARRIED.merged({"stance":"accept"})))
	assert_str(String(ForeignDialogue.thread(id).draft.stance)).is_equal("accept")
	assert_bool(ForeignDialogue.seal(id).get("ok",false)).is_true()

func test_loop_guard_forces_a_decision_when_a_position_repeats()->void:
	var id:=_meet()
	var deferral:=_reply("Let me think on ten timber for one hundred rations.",CARRIED.merged({"stance":"consult"}))
	deferral.envoy_terms={}
	ForeignDialogue.thread(id).topic=Pacts.from_model(CARRIED)
	assert_bool(ForeignDialogue.accept(id,deferral.duplicate(true))).is_true()
	assert_str(String(ForeignDialogue.thread(id).draft.stance)).is_equal("consult")
	# The same position again, without any council sitting in between.
	ForeignDialogue.thread(id).council={}
	assert_bool(ForeignDialogue.accept(id,deferral.duplicate(true))).is_true()
	var stance:=String(ForeignDialogue.thread(id).draft.stance)
	assert_bool(stance in ["accept","counter","refuse"]).override_failure_message("still deferring: "+stance).is_true()
	# A counter repeated word for word becomes their last offer, still sealable.
	var counter_terms:={"player_gives":"Food","player_amount":100,"foreign_gives":"Timber","foreign_amount":8,"cadence":"year","portions":10,"when_ready":true,"carry_debt":false}
	var counter:=_reply("Eight timber, not ten, for the hundred rations.",counter_terms.merged({"stance":"counter"}),{})
	ForeignDialogue.accept(id,counter.duplicate(true))
	ForeignDialogue.accept(id,counter.duplicate(true))
	assert_bool(bool(ForeignDialogue.thread(id).draft.final)).is_true()
	assert_bool(ForeignDialogue.sealable(id)).is_true()

func test_the_ruler_decides_from_real_need_and_temper()->void:
	var id:=_foreign()
	var fair:=Pacts.from_model(CARRIED)
	assert_str(String(Pacts.appraise(id,fair).decision)).is_equal("accept")
	# Thirty Food a year for forty Timber is a poor trade for them: a counter with numbers.
	var poor:=_terms("Food",30,"Timber",40)
	var answer:=Pacts.appraise(id,poor)
	assert_str(String(answer.decision)).is_equal("counter")
	assert_float(Pacts.ratio(id,answer.terms)).is_greater_equal(Pacts.ratio(id,poor))
	# Absurd terms are refused with a reason.
	var absurd:=_terms("Food",1,"Timber",40)
	var refusal:=Pacts.appraise(id,absurd)
	assert_str(String(refusal.decision)).is_equal("refuse")
	assert_str(String(refusal.reason)).is_not_empty()
	# At war, nothing.
	ForeignDiplomacy.civilization(id).player_relation.at_war=true
	assert_str(String(Pacts.appraise(id,fair).decision)).is_equal("refuse")
	assert_str(Pacts.seal_blocker(id,fair)).is_not_empty()

func test_execution_over_years_with_deliveries_shortages_and_endings()->void:
	var id:=_foreign()
	var start:=400
	GameState.elapsed_days=start
	var food0:=Pacts.player_stock("Food"); var timber0:=Pacts.player_stock("Timber")
	var kept:=Pacts.seal(id,_terms("Food",100,"Timber",10,"year",4,true,false),30)
	assert_bool(kept.get("ok",false)).is_true()
	var pact:Dictionary=kept.pact
	var trust0:=float(ForeignDiplomacy.leader(id).trust)
	for day in range(start+10,start+365*4+200,10):
		GameState.elapsed_days=day; Pacts.daily(day)
	assert_str(String(pact.status)).is_equal("completed")
	assert_int(int(pact.done)).is_equal(4)
	assert_float(Pacts.player_stock("Timber")-timber0).is_equal_approx(40.0,0.5)
	assert_float(food0-Pacts.player_stock("Food")).is_greater_equal(399.0)
	assert_float(float(ForeignDiplomacy.leader(id).trust)).is_greater(trust0)
	var outcomes:=[]
	for entry:Dictionary in pact.log: outcomes.append(String(entry.o))
	assert_bool("completed" in outcomes and "delivered" in outcomes).is_true()
	# A seasonal exchange you cannot keep: skipped portions, then they end it.
	var day0:=int(GameState.elapsed_days)
	var broken:=Pacts.seal(id,_terms("Stone",20,"Food",60,"season",8,false,false),20).pact as Dictionary
	GameState.resource_stockpiles.Stone=0.0
	var trust1:=float(ForeignDiplomacy.leader(id).trust)
	for day in range(day0+10,day0+91*4,10):
		GameState.elapsed_days=day; Pacts.daily(day)
	assert_str(String(broken.status)).is_equal("cancelled")
	assert_int(int(broken.miss_p)).is_equal(Pacts.MISSES_TO_LAPSE)
	assert_float(float(ForeignDiplomacy.leader(id).trust)).is_less(trust1)
	assert_bool(String(broken.log[1].o) in ["skipped","partial"]).is_true()
	assert_str(String(broken.log[1].n)).contains("could not spare the Stone")
	assert_bool(Rivals.grudge_weight(id)>0.0).is_true()
	# A partial portion with debt carried: what was short is owed next time.
	day0=int(GameState.elapsed_days)
	GameState.resource_stockpiles.Stone=25.0
	var owed:=Pacts.seal(id,_terms("Stone",20,"Food",30,"year",3,false,true),10).pact as Dictionary
	GameState.resource_stockpiles.Stone=10.0
	for day in range(day0+10,day0+30,10):
		GameState.elapsed_days=day; Pacts.daily(day)
	assert_str(String(owed.log[0].o)).is_equal("partial")
	assert_float(float(owed.owe_p)).is_greater(0.0)
	# You end it while they keep their side: a broken word.
	var trust2:=float(ForeignDiplomacy.leader(id).trust)
	assert_bool(Pacts.cancel(String(owed.id)).get("ok",false)).is_true()
	assert_str(String(owed.status)).is_equal("cancelled")
	assert_float(float(ForeignDiplomacy.leader(id).trust)).is_less(trust2)
	# War suspends an exchange instead of running it.
	day0=int(GameState.elapsed_days)
	GameState.resource_stockpiles.Stone=200.0
	var paused:=Pacts.seal(id,_terms("Stone",10,"Food",20,"year",2),10).pact as Dictionary
	ForeignDiplomacy.civilization(id).player_relation.at_war=true
	for day in range(day0+10,day0+60,10):
		GameState.elapsed_days=day; Pacts.daily(day)
	assert_int(int(paused.done)).is_equal(0)
	assert_bool(bool(paused.get("suspended",false))).is_true()

func test_exchanges_and_talk_survive_a_save()->void:
	var id:=_meet()
	_round(id,_reply(TEMBA_DEFERS,{}))
	Pacts.seal(id,_terms("Food",60,"Timber",6,"season",4,true,true),20)
	var saved:=ForeignDiplomacy.export_state()
	var json:Variant=JSON.parse_string(JSON.stringify(saved))
	assert_bool(ForeignDiplomacy.import_state(json).get("ok",false)).is_true()
	assert_int(Pacts.pacts(id).size()).is_equal(1)
	assert_str(String(ForeignDialogue.thread(id).draft.stance)).is_equal("consult")
	assert_bool(Pacts.valid_terms(ForeignDialogue.thread(id).council.terms)).is_true()
	# The restored exchange still runs.
	var pact:Dictionary=Pacts.pacts(id)[0]
	var day0:=int(GameState.elapsed_days)
	for day in range(day0+1,day0+60):
		GameState.elapsed_days=day; Pacts.daily(day)
	assert_int(int(pact.done)).is_equal(1)
	# Corrupt exchange state is refused and the loaded state kept.
	var bad:=ForeignDiplomacy.export_state()
	var good:=bad.duplicate(true)
	bad.audiences.trade_pacts.pacts[0].terms.give_res="Gold"
	assert_bool(ForeignDiplomacy.import_state(bad).has("error")).is_true()
	var bad_thread:=good.duplicate(true)
	bad_thread.dialogue[id].topic={"give_res":"Food"}
	assert_bool(ForeignDiplomacy.import_state(bad_thread).has("error")).is_true()
	# Older saves without any of this load.
	var legacy:=good.duplicate(true)
	legacy.audiences.erase("trade_pacts")
	for key in ["topic","council","positions","must_decide"]: legacy.dialogue[id].erase(key)
	legacy.dialogue[id].draft={}
	assert_bool(ForeignDiplomacy.import_state(legacy).get("ok",false)).is_true()

func test_offline_choices_reach_the_same_core()->void:
	var id:=_meet()
	var choices:=ForeignDialogue.offline_choices(id)
	var trade:Array=choices.filter(func(c:Dictionary)->bool:return String(c.id).begins_with("trade:"))
	assert_array(trade).is_not_empty()
	for choice:Dictionary in trade:
		assert_bool(Pacts.valid_terms(choice.terms)).is_true()
		assert_float(float(choice.terms.give_amt)).is_less_equal(Pacts.player_stock(String(choice.terms.give_res))*0.5)
		assert_int(int(choice.terms.get_amt)).is_less_equal(Pacts.their_limit(id,String(choice.terms.get_res)))
	assert_bool(ForeignDialogue.ask_offline(id,String(trade[0].id))).is_true()
	_return_envoys()
	var t:=ForeignDialogue.thread(id)
	assert_bool(t.draft.has("exchange")).is_true()
	var stance:=String(t.draft.stance)
	if stance=="consult":
		var answer:Array=ForeignDialogue.offline_choices(id).filter(func(c:Dictionary)->bool:return String(c.id)=="trade:answer")
		assert_array(answer).is_not_empty()
		assert_bool(ForeignDialogue.ask_offline(id,"trade:answer")).is_true()
		_return_envoys()
		stance=String(t.draft.stance)
	assert_bool(stance in ["accept","counter","refuse"]).override_failure_message("offline still deferring: "+stance).is_true()
	assert_str(String((t.messages as Array).back().content)).is_not_empty()
	if stance!="refuse":assert_bool(ForeignDialogue.seal(id).get("ok",false)).is_true()

func test_council_of_nations_shows_the_exchange_as_a_tie()->void:
	var first:=preload("res://tests/commitment_ui_probe.gd").build_fixture()
	var sealed:=Pacts.seal(first,_terms("Food",100,"Timber",10,"year",10,true,false),20)
	assert_bool(sealed.get("ok",false)).is_true()
	var screen:Control=auto_free(preload("res://scripts/commitment_screen.gd").new())
	screen.set("civ_id",first)
	add_child(screen)
	await await_idle_frame()
	var card:Node=screen.peoples_box.get_child(0)
	var chips:=""
	for label in card.find_children("*","Label",true,false): chips+=(label as Label).text+"\n"
	assert_str(chips).contains("Trade: 100 Food for 10 Timber a year")
	var row:Node=screen.find_child("Exchange_"+String(sealed.pact.id),true,false)
	assert_object(row).is_not_null()
	var text:=""
	for label in row.find_children("*","Label",true,false): text+=(label as Label).text+"\n"
	assert_str(text).contains("Portion 1 of 10 due Year ")
	assert_str(text).contains("Sealed:")
	var end:=screen.find_child("EndExchange_"+String(sealed.pact.id),true,false) as Button
	assert_object(end).is_not_null()
	end.pressed.emit()
	assert_str(String(Pacts.find(String(sealed.pact.id)).status)).is_equal("cancelled")

func test_court_shows_the_terms_and_seals_them()->void:
	var id:=_meet()
	_round(id,_reply("A hundred rations a year for ten timber, each paid when the timber arrives, for ten years. I agree to that.",CARRIED.merged({"stance":"accept"})))
	var modal:Control=auto_free(preload("res://scripts/hud/audience_modal.gd").new())
	add_child(modal)
	await await_idle_frame()
	assert_bool(modal.show_foreign(id)).is_true()
	await await_idle_frame()
	var panel:=modal.find_child("ExchangeTerms",true,false) as Control
	assert_object(panel).is_not_null()
	assert_bool(panel.visible).is_true()
	assert_str((modal.find_child("ExchangeWords",true,false) as Label).text).contains("You give 100 Food and they give 10 Timber each year, for 10 years")
	assert_str((modal.find_child("ExchangeKicker",true,false) as Label).text).contains("AGREES")
	var seal:=modal.find_child("SealExchange",true,false) as Button
	assert_bool(seal.visible and not seal.disabled).is_true()
	assert_str(seal.text).is_equal("Seal this agreement")
	# Chat lines carry the Chronicle's calendar words, not raw day counts.
	var heads:=""
	for label in modal.transcript.find_children("*","Label",true,false): heads+=(label as Label).text+"\n"
	assert_str(heads).contains("Year ")
	assert_str(heads).not_contains("day ")
	seal.pressed.emit()
	await await_idle_frame()
	assert_int(Pacts.pacts(id).size()).is_equal(1)
	assert_bool(panel.visible).is_false()
	modal.queue_free()
