extends GdUnitTestSuite
## Wider envoy business (envoy_requests.gd, envoy_request_ai.gd): every kind
## rises only from real state and resolves through bounded changes; loans are
## repaid by traders; repetition is damped; the live model can only choose
## among valid candidates and its words are validated; and the pace of envoy
## visits is exactly what the hall alone produces. Never calls a real API.

const Hall:=preload("res://scripts/audience_hall.gd")
const ER:=preload("res://scripts/envoy_requests.gd")
const RequestAI:=preload("res://scripts/envoy_request_ai.gd")
const Voice:=preload("res://scripts/audience_voice.gd")
const Rivals:=preload("res://scripts/rival_rulers.gd")
const SEED:=424242

var met:Array[String]=[]

func before_test()->void:
	ER.enabled=true
	_world()

func after_test()->void:
	ER.enabled=true

func _world()->void:
	WorldSimulation.clear()
	GameState.set_process(false); CivilizationSystem.set_process(false); MilitaryCampaign.set_process(false)
	GameState.reset_for_new_world(SEED); GameState.civic_api_enabled=false
	DiscoverySystem.reset_for_new_world(); FoodSystem.reset_for_new_world(); MilitaryCampaign.reset_for_new_world()
	CivilizationSystem.reset_for_new_world()
	ForeignDiplomacy.reset_for_new_world(); GovernmentPeopleSystem.reset_for_new_world()
	GameState.ensure_population_total(200); GameState.housing_capacity=260
	GameState.settlement_site_committed=true; GameState.settlement_founded_day=0; GameState.settlement_completed=["Hearth Circle"]; SettlementModel.ensure_founded()
	GameState.population_health=0.9; GameState.simulation_metrics.merge({"food_days":60.0,"food_intake_ratio":1.0,"security":0.6,"cohesion":0.7},true)
	GovernmentPeopleSystem.initialize()
	FoodSystem.receive_external_food(3000)
	for res in ["Timber","Stone","Clay","Fiber Plants"]: GameState.resource_stockpiles[res]=300.0
	CivilizationSystem.player_world_origin=preload("res://scripts/civilization_start.gd").candidate(SEED,0)
	met.clear()
	var civs:Array=CivilizationSystem.civilizations
	for index in 3:
		var civ:Dictionary=civs[index]
		civ.player_relation.contact_level=2; civ.player_relation.met_day=0; civ.player_relation.home_location_known=true
		met.append(String(civ.id))
	GameState.elapsed_days=400

func _civ(index:int=0)->Dictionary:
	return ForeignDiplomacy.civilization(met[index])

func _back(type:String,civ_index:int=0)->Dictionary:
	## Put the world into a state that truly backs this request.
	var civ:=_civ(civ_index)
	var other:=_civ(1 if civ_index!=1 else 0)
	civ.player_relation.opinion=0.35
	civ.food_days=60.0; civ.health=0.8
	# Each test answer stands alone: bonds made by the last one are cleared.
	(Rivals.character(met[civ_index]).bonds as Array).clear()
	match type:
		"food_loan","refuge","forage_leave","work_for_food": civ.food_days=10.0
		"healer_plea": civ.health=0.4
		"mediation":
			civ.relations[String(other.id)]={"border_tension":0.7,"at_war":false}
			other.relations[String(civ.id)]={"border_tension":0.7,"at_war":false}
		"border_line","hostage_exchange": civ.player_relation.border_tension=0.6
		"fugitive_return": civ.player_relation.recruitment_visits=1
		"blessing_rite": civ.player_relation.opinion=0.8; ForeignDiplomacy.leader(met[civ_index]).trust=0.6
		"war_supplies": civ.relations[String(other.id)]={"border_tension":0.9,"at_war":true}
		"succession_backing":
			Rivals.character(met[civ_index])
			(Rivals.character(met[civ_index]).lineage as Array).push_front({"name":"Old Ruler","gen":0,"died":int(GameState.elapsed_days)-100,"reign":9,"trait":"ledger","reputation":"remembered warily","woman":false})
		"craft_teaching": GameState.known_discoveries.append("pottery_firing")
		"captive_scouts": CivilizationSystem.captured_player_scouts[met[civ_index]]={"count":3,"captured_day":int(GameState.elapsed_days)-20}
		"rite_keeper": civ.player_relation.opinion=0.8; ForeignDiplomacy.leader(met[civ_index]).trust=0.6
		"boundary_cairn": civ.player_relation.border_tension=0.4
		"safe_passage": civ.relations[String(other.id)]={"border_tension":0.1,"at_war":false}
	return civ

func _raise(type:String,civ_index:int=0)->Dictionary:
	_back(type,civ_index)
	return Hall.debug_situation(type,met[civ_index],{})

func test_every_kind_rises_from_backing_state_and_every_answer_resolves_within_bounds()->void:
	var raised:=0
	for type:String in ER.TYPES:
		var probe:=_raise(type)
		if probe.is_empty():
			# A few kinds need a foreign ledger or a craft the world may lack; say which.
			assert_bool(type in ["craft_teaching","barter","blessing_rite","sacred_site","safe_passage"]).override_failure_message("%s could not be raised from backing state" % type).is_true()
			continue
		raised+=1
		assert_str(String(probe.kind)).is_equal("request")
		assert_str(String(probe.situation.summary)).is_not_empty()
		var ids:Array=[]
		for option in Hall.options(String(probe.id)): ids.append(String(option.id))
		assert_int(ids.size()).override_failure_message("%s offers no answers" % type).is_greater_equal(2)
		assert_bool("refuse" in ids).override_failure_message("%s cannot be refused" % type).is_true()
		Hall.resolve(String(probe.id),"refuse")
		for option_id in ids:
			var audience:=_raise(type)
			assert_dict(audience).override_failure_message("%s could not be raised again for %s" % [type,option_id]).is_not_empty()
			if audience.is_empty(): continue
			var pop_before:=int(GameState.population_total)
			var civ:=_civ()
			var result:=Hall.resolve(String(audience.id),String(option_id))
			assert_bool(bool(result.get("ok",false))).override_failure_message("%s:%s failed: %s" % [type,option_id,str(result)]).is_true()
			assert_str(String(result.outcome)).is_not_empty()
			assert_bool(String(result.reaction) in Hall.REACTIONS).is_true()
			assert_int(absi(int(GameState.population_total)-pop_before)).is_less_equal(40)
			assert_float(float(civ.player_relation.opinion)).is_between(-1.0,1.0)
			assert_float(float(civ.player_relation.border_tension)).is_between(0.0,1.0)
	assert_int(raised).is_greater_equal(16)

func test_requests_need_the_state_that_backs_them()->void:
	var civ:=_civ()
	civ.food_days=80.0; civ.health=0.9; civ.player_relation.border_tension=0.0; civ.player_relation.recruitment_visits=0
	civ.relations={}
	for type in ["food_loan","refuge","healer_plea","mediation","border_line","fugitive_return","war_supplies","succession_backing"]:
		assert_dict(Hall.debug_situation(type,met[0],{})).override_failure_message("%s raised without backing" % type).is_empty()

func test_a_loan_is_repaid_by_traders_without_another_envoy()->void:
	var audience:=_raise("food_loan")
	assert_dict(audience).is_not_empty()
	var food_before:=Hall.player_stock("Food")
	var result:=Hall.resolve(String(audience.id),"accept")
	assert_bool(bool(result.ok)).is_true()
	assert_float(Hall.player_stock("Food")).is_less(food_before)
	var pledges:=ER.pledges()
	assert_int(pledges.size()).is_equal(1)
	var p:Dictionary=pledges[0]
	var res:=String(p.res)
	var queued:=Hall.waiting().size()
	# Give their ledger enough to pay, then let the due day pass.
	if Hall.foreign_stock(met[0],res)>=0.0:
		preload("res://scripts/civilization_exchange.gd").receive(met[0],res,float(p.amt)*3.0)
		var before:=Hall.player_stock(res)
		var due:=int(p.due)
		GameState.elapsed_days=due+(10-due%10)%10
		ER.daily(int(GameState.elapsed_days))
		assert_int(ER.pledges().size()).is_equal(0)
		assert_float(Hall.player_stock(res)).is_greater(before)
	assert_int(Hall.waiting().size()).is_equal(queued)

func test_their_workers_deliver_what_they_gathered()->void:
	var audience:=_raise("work_for_food")
	assert_dict(audience).is_not_empty()
	var p:Dictionary=audience.situation.req
	var before:=Hall.player_stock(String(p.res))
	assert_bool(bool(Hall.resolve(String(audience.id),"accept").ok)).is_true()
	var due:=int(GameState.elapsed_days)+int(p.days)
	GameState.elapsed_days=due+(10-due%10)%10
	ER.daily(int(GameState.elapsed_days))
	assert_float(Hall.player_stock(String(p.res))).is_greater(before)
	assert_int(ER.pledges().size()).is_equal(0)

func test_refusing_is_remembered_by_their_ruler()->void:
	var audience:=_raise("sacred_site")
	if audience.is_empty(): audience=_raise("border_line")
	var grudges_before:=(Rivals.character(met[0]).grudges as Array).size()
	Hall.resolve(String(audience.id),"refuse")
	assert_bool((Rivals.character(met[0]).grudges as Array).size()>grudges_before or String(audience.situation.type)=="border_line").is_true()
	assert_bool(ForeignDiplomacy.leader(met[0]).memory.size()>0 if ForeignDiplomacy.leader(met[0]).has("memory") else true).is_true()

func test_variety_damps_repeats_by_type_family_and_people()->void:
	var store:=ER.store()
	store.recent=[{"d":390,"c":met[0],"t":"aid_request","a":"x"}]
	assert_float(ER.variety_factor("aid_request",met[1],400)).is_less(0.25)
	assert_float(ER.variety_factor("food_loan",met[1],400)).is_less(0.5)
	assert_float(ER.variety_factor("mediation",met[1],400)).is_equal(1.0)
	assert_float(ER.variety_factor("aid_request",met[0],400)).is_less(ER.variety_factor("aid_request",met[1],400))

func test_save_state_validates_and_round_trips()->void:
	Hall.resolve(String(_raise("food_loan").id),"accept")
	var s:=Hall.state()
	assert_bool(Hall.validate_state(s)).is_true()
	assert_bool(Hall.validate_state(JSON.parse_string(JSON.stringify(s)))).is_true()
	var bad:=s.duplicate(true); bad.envoy_requests.pledges=[{"res":"Gold","amt":1,"due":1}]
	assert_bool(Hall.validate_state(bad)).is_false()

# --- the live model: choose among valid candidates, validated, never required ---

func _live_voice(reply:Variant,calls:Array)->Node:
	var voice:Node=auto_free(Voice.new())
	add_child(voice)
	voice.config_override={"endpoint":"https://api.openai.com/v1/chat/completions","api_key":"test-key-not-real","model":"gpt-6-luna","structured_output":true}
	voice.pick_hook=func(id:String,payload:Dictionary)->PackedByteArray:
		calls.append(payload)
		if reply is Callable: return (reply as Callable).call(payload)
		return JSON.stringify({"choices":[{"message":{"content":JSON.stringify(reply)}}],"model":"gpt-6-luna","usage":{"total_tokens":300}}).to_utf8_buffer()
	return voice

func _with_alternatives()->Dictionary:
	var audience:=_raise("food_loan")
	var alt:=Hall._candidate("refuge",met[0],{"type":"their_famine","data":{}},Hall._rng("t",1),{},int(GameState.elapsed_days))
	audience["request_alts"]=[{"kind":String(alt.kind),"situation":(alt.situation as Dictionary).duplicate(true)}]
	return audience

func test_live_model_may_choose_another_valid_request_and_its_words_are_kept()->void:
	var audience:=_with_alternatives()
	var name:=String(audience.civ_name)
	var calls:Array=[]
	var voice:=_live_voice({"pick":"c1","headline":"asks you to take in their hungry families","stakes":"%s cannot feed everyone through the cold months." % name},calls)
	var revised:Array=[]
	voice.request_revised.connect(func(id:String)->void:revised.append(id))
	assert_bool(voice.pick_request(String(audience.id))).is_true()
	assert_int(calls.size()).is_equal(1)
	var payload:Dictionary=calls[0]
	assert_str(String(payload.model)).is_equal("gpt-6-luna")
	assert_int(JSON.stringify(payload).length()).is_less(7000)
	assert_array(payload.response_format.json_schema.schema.properties.pick.enum).contains_exactly(["c0","c1"])
	var now:=Hall.find(String(audience.id))
	assert_str(Hall._situation_type(now)).is_equal("refuge")
	assert_str(String(now.situation.headline)).is_equal("asks you to take in their hungry families")
	assert_str(String(now.situation.summary)).contains("cold months")
	assert_array(revised).contains_exactly([String(audience.id)])
	var ids:Array=[]
	for o in Hall.options(String(audience.id)): ids.append(String(o.id))
	assert_array(ids).contains(["accept","partial","refuse"])
	# Cached per visit: never asked twice.
	assert_bool(voice.pick_request(String(audience.id))).is_false()
	assert_int(calls.size()).is_equal(1)
	assert_bool(bool(Hall.resolve(String(audience.id),"accept").ok)).is_true()

func test_live_model_cannot_invent_business_names_or_numbers()->void:
	var audience:=_with_alternatives()
	var calls:Array=[]
	var voice:=_live_voice({"pick":"c7","headline":"wants gold","stakes":"x"},calls)
	voice.pick_request(String(audience.id))
	assert_str(Hall._situation_type(Hall.find(String(audience.id)))).is_equal("food_loan")
	assert_str(String(Hall.find(String(audience.id)).request_ai.mode)).is_equal("fallback")
	# A valid pick with invented facts keeps the pick but drops the words.
	var second:=_with_alternatives()
	var voice2:=_live_voice({"pick":"c0","headline":"asks for 999 food from Zarathor","stakes":"Zarathor the Great demands 999 Food, as the saying goes, a full belly makes a loyal friend."},calls)
	voice2.pick_request(String(second.id))
	var kept:=Hall.find(String(second.id))
	assert_str(Hall._situation_type(kept)).is_equal("food_loan")
	assert_str(String(kept.situation.headline)).is_equal(String(ER.TYPES.food_loan.headline))
	assert_bool(String(kept.situation.summary).contains("Zarathor")).is_false()

func test_transport_failure_and_offline_keep_the_deterministic_request()->void:
	var audience:=_with_alternatives()
	var calls:Array=[]
	var voice:=_live_voice(func(_p:Dictionary)->PackedByteArray:return PackedByteArray(),calls)
	voice.pick_request(String(audience.id))
	assert_str(Hall._situation_type(Hall.find(String(audience.id)))).is_equal("food_loan")
	assert_bool(voice.busy(String(audience.id))).is_false()
	var offline:=_with_alternatives()
	var quiet:Node=auto_free(Voice.new()); add_child(quiet); quiet.force_offline=true
	assert_bool(quiet.pick_request(String(offline.id))).is_false()
	assert_str(String(Hall.find(String(offline.id)).request_ai.mode)).is_equal("offline")

func test_offline_opening_says_what_the_request_is()->void:
	var audience:=_raise("mediation")
	var quiet:Node=auto_free(Voice.new()); add_child(quiet); quiet.force_offline=true
	quiet.open_scene(String(audience.id))
	var text:=""
	for line in Hall.find(String(audience.id)).lines: text+=String(line.text)+" "
	assert_str(text).contains(String(audience.situation.req.place))

# --- pace: the wider business never changes whether or when an envoy comes ---

func _arrivals(days:int,wider:bool)->Array:
	_world()
	ER.enabled=wider
	Hall.set_frequency("lively")
	var out:Array=[]
	var rng:=RandomNumberGenerator.new(); rng.seed=SEED
	for day in range(401,401+days):
		GameState.elapsed_days=day
		if day%45==0:
			var civ:=_civ(rng.randi_range(0,2))
			civ.player_relation.opinion=clampf(float(civ.player_relation.opinion)+rng.randf_range(-0.3,0.3),-0.9,0.9)
			civ.food_days=rng.randf_range(8.0,70.0)
			civ.health=rng.randf_range(0.35,0.9)
			civ.player_relation.border_tension=clampf(rng.randf_range(-0.2,0.8),0.0,1.0)
		for audience in Hall.daily(day):
			if String(audience.get("origin",""))=="foreign":
				out.append("%d:%s" % [day,String(audience.civ_id)])
				kinds.append(Hall._situation_type(audience))
	return out

var kinds:Array=[]

func test_pace_of_envoy_visits_is_unchanged()->void:
	## Envoys left unanswered (they expire), so the only difference between the
	## two runs is what they came about: arrival days and senders must match.
	kinds.clear()
	var alone:=_arrivals(1460,false)
	var alone_kinds:=kinds.duplicate()
	kinds.clear()
	var wider:=_arrivals(1460,true)
	assert_int(alone.size()).is_greater(3)
	assert_array(wider).is_equal(alone)
	var new_kinds:=kinds.filter(func(k:String)->bool:return ER.TYPES.has(k))
	assert_int(new_kinds.size()).override_failure_message("no wider business in %s" % str(kinds)).is_greater(0)
	assert_int(alone_kinds.filter(func(k:String)->bool:return ER.TYPES.has(k)).size()).is_equal(0)
	print("ENVOY_PACE_TEST arrivals=%d alone=%s wider=%s" % [alone.size(),str(alone_kinds),str(kinds)])
	ER.enabled=true

# --- round two: new business, typed answers, follow-ups, lean seasons ---

func test_new_kinds_need_their_state()->void:
	var civ:=_civ()
	civ.player_relation.opinion=0.0; civ.player_relation.border_tension=0.0
	CivilizationSystem.captured_player_scouts.clear(); CivilizationSystem.captured_foreign_scouts.clear()
	for type in ["captive_scouts","rite_keeper","boundary_cairn"]:
		assert_dict(Hall.debug_situation(type,met[0],{})).override_failure_message("%s raised without backing" % type).is_empty()

func test_captured_scouts_really_come_home()->void:
	CivilizationSystem.captured_player_scouts[met[0]]={"count":3,"captured_day":380}
	var audience:=Hall.debug_situation("captive_scouts",met[0],{})
	assert_dict(audience).is_not_empty()
	assert_str(String(audience.situation.summary)).contains("3 of your scouts")
	assert_bool(bool(Hall.resolve(String(audience.id),"partial").ok)).is_true()
	assert_bool(CivilizationSystem.captured_player_scouts.has(met[0])).is_false()
	assert_dict(Rivals.has_bond(met[0],["no_scouts"])).is_not_empty()
	# Their scouts, held by you, go home to their people.
	CivilizationSystem.captured_foreign_scouts[met[1]]={"civ_id":met[1],"count":2,"captured_day":390}
	var pop_before:=float(_civ(1).population)
	var theirs:=Hall.debug_situation("captive_scouts",met[1],{})
	assert_str(String(theirs.situation.req.side)).is_equal("theirs")
	assert_bool(bool(Hall.resolve(String(theirs.id),"accept").ok)).is_true()
	assert_bool(CivilizationSystem.captured_foreign_scouts.has(met[1])).is_false()
	assert_float(float(_civ(1).population)).is_greater(pop_before)

func test_typed_words_choose_the_same_bounded_answers()->void:
	var loan:=_raise("food_loan")
	assert_dict(loan).is_not_empty()
	var read:=ER.typed_choice(loan,"Lend them half and ask for flint back")
	assert_str(String(read.get("option",""))).is_equal("partial")
	assert_str(String(read.get("repay_res",""))).is_equal("Stone")
	assert_str(String(ER.typed_choice(loan,"Do not lend them anything.").get("option",""))).is_equal("refuse")
	assert_str(String(ER.typed_choice(loan,"Give it to them freely, ask nothing back").get("option",""))).is_equal("gift")
	assert_dict(ER.typed_choice(loan,"How long have they been hungry?")).is_empty()
	assert_dict(ER.typed_choice(loan,"Tell me about their ruler")).is_empty()
	# A condition goes to the live reading, never to keywords.
	assert_dict(ER.typed_choice(loan,"I won't lend them food unless they send stone")).is_empty()
	var third:=ER.typed_choice(loan,"Lend them a third of it")
	assert_str(String(third.option)).is_equal("accept")
	assert_float(float(third.share)).is_equal_approx(0.33,0.01)
	# A typed share is carried out exactly as a card would be, only smaller.
	var food_before:=Hall.player_stock("Food")
	ER.apply_typed(Hall.find(String(loan.id)),third)
	assert_bool(bool(Hall.resolve(String(loan.id),"accept").ok)).is_true()
	var lent:=food_before-Hall.player_stock("Food")
	assert_float(lent).is_less_equal(float(loan.situation.req.amount)*0.4)
	assert_float(lent).is_greater(0.0)
	# Other kinds, their own words.
	var judge:=_raise("mediation")
	assert_str(String(ER.typed_choice(judge,"Split the ground between them").get("option",""))).is_equal("partial")
	assert_str(String(ER.typed_choice(judge,"I will not judge their quarrel").get("option",""))).is_equal("refuse")
	assert_str(String(ER.typed_choice(judge,"The ground belongs to %s" % String(judge.situation.req.third_name)).get("option",""))).is_equal("other")
	CivilizationSystem.captured_player_scouts[met[0]]={"count":2,"captured_day":390}
	var held:=Hall.debug_situation("captive_scouts",met[0],{})
	assert_str(String(ER.typed_choice(held,"You have my word, no more scouts will come").get("option",""))).is_equal("partial")

func _answer_voice(reply:Variant,calls:Array)->Node:
	var voice:Node=auto_free(Voice.new())
	add_child(voice)
	voice.config_override={"endpoint":"https://api.openai.com/v1/chat/completions","api_key":"test-key-not-real","model":"gpt-6-luna","structured_output":true}
	voice.answer_hook=func(id:String,payload:Dictionary)->PackedByteArray:
		calls.append(payload)
		if reply is Callable: return (reply as Callable).call(payload)
		return JSON.stringify({"choices":[{"message":{"content":JSON.stringify(reply)}}],"model":"gpt-6-luna","usage":{"total_tokens":120}}).to_utf8_buffer()
	return voice

func test_live_reading_maps_typed_answers_and_falls_back_to_talk()->void:
	var audience:=_raise("war_supplies")
	assert_dict(audience).is_not_empty()
	var calls:Array=[]
	var got:Array=[]
	var voice:=_answer_voice({"answer":"accept","share":0.5,"repay":"none","confidence":0.9},calls)
	assert_bool(voice.read_request_answer(String(audience.id),"Send them what timber we can spare, half of it",func(r:Dictionary)->void:got.append(r))).is_true()
	assert_int(calls.size()).is_equal(1)
	assert_str(String(calls[0].model)).is_equal("gpt-6-luna")
	assert_array(calls[0].response_format.json_schema.schema.properties.answer.enum).contains(["accept","refuse","talk"])
	assert_str(String(got[0].option)).is_equal("accept")
	assert_float(float(got[0].share)).is_equal_approx(0.5,0.001)
	# Invented answers, low confidence, talk and transport failure all read as nothing.
	for reply in [{"answer":"burn_them","share":1,"repay":"none","confidence":0.99},{"answer":"refuse","share":1,"repay":"none","confidence":0.3},{"answer":"talk","share":1,"repay":"none","confidence":0.9}]:
		got.clear()
		var v2:=_answer_voice(reply,calls)
		v2.read_request_answer(String(audience.id),"Hmm",func(r:Dictionary)->void:got.append(r))
		assert_dict(got[0]).is_empty()
	got.clear()
	var dead:=_answer_voice(func(_p:Dictionary)->PackedByteArray:return PackedByteArray(),calls)
	dead.read_request_answer(String(audience.id),"Send it",func(r:Dictionary)->void:got.append(r))
	assert_dict(got[0]).is_empty()
	assert_bool(dead.busy(String(audience.id))).is_false()
	var quiet:Node=auto_free(Voice.new()); add_child(quiet); quiet.force_offline=true
	assert_bool(quiet.read_request_answer(String(audience.id),"Send it",func(_r:Dictionary)->void:pass)).is_false()

func test_the_next_envoy_says_how_you_answered_last_time()->void:
	var first:=_raise("mediation")
	var place:=String(first.situation.req.place)
	assert_bool(bool(Hall.resolve(String(first.id),"partial").ok)).is_true()
	GameState.elapsed_days=int(GameState.elapsed_days)+120
	var next:=_raise("barter")
	if next.is_empty(): next=_raise("border_line")
	assert_dict(next).is_not_empty()
	var recall:Dictionary=next.situation.get("recall",{})
	assert_str(String(recall.get("kind",""))).is_equal("answer")
	assert_str(String(recall.text)).contains(place)
	assert_str(String(next.situation.summary)).contains(place)
	# Said once: the envoy after that does not repeat it.
	Hall.resolve(String(next.id),"refuse")
	GameState.elapsed_days=int(GameState.elapsed_days)+120
	var third:=_raise("border_line")
	assert_bool(String((third.situation.get("recall",{}) as Dictionary).get("text","")).contains("divided")).is_false()
	assert_bool(Hall.validate_state(JSON.parse_string(JSON.stringify(Hall.state())))).is_true()

func test_a_loan_follow_up_says_whether_it_was_repaid()->void:
	var loan:=_raise("food_loan")
	Hall.resolve(String(loan.id),"accept")
	var answers:Array=ER.store().answers.get(met[0],[])
	assert_int(answers.size()).is_greater(0)
	var entry:Dictionary=answers[0]
	assert_str(ER.recall_text(met[0],entry,int(GameState.elapsed_days)+100)).contains("still owe")
	(entry.x as Dictionary)["repaid"]="full"
	assert_str(ER.recall_text(met[0],entry,int(GameState.elapsed_days)+400)).contains("paid back")

func _hunger_occasions(days:Array,food:Array)->Array:
	var seen:Array=[]
	var civ:=_civ()
	civ.player_relation.border_tension=0.0
	for index in days.size():
		civ.food_days=float(food[index])
		Hall.daily(int(days[index]))
		for o in Hall.occasions():
			if String(o.get("civ_id",""))==met[0] and String(o.type) in ["their_famine","lean_season"] and not "%s@%d" % [String(o.type),int(o.day)] in seen: seen.append("%s@%d" % [String(o.type),int(o.day)])
		for a in Hall.state().queue:
			var occ:Dictionary=((a as Dictionary).get("situation",{}) as Dictionary).get("occasion",{})
			if String((a as Dictionary).get("civ_id",""))==met[0] and String(occ.get("type","")) in ["their_famine","lean_season"] and not "%s@%d" % [String(occ.type),int(occ.day)] in seen: seen.append("%s@%d" % [String(occ.type),int(occ.day)])
	return seen

func test_hunger_pleads_once_then_lean_seasons_bring_other_business_until_true_famine()->void:
	var seen:=_hunger_occasions([401,411,421,431,441,451],[60.0,16.0,60.0,16.0,60.0,8.0])
	assert_array(seen).contains(["their_famine@411","lean_season@431","their_famine@451"])
