extends GdUnitTestSuite
## Conceived wonders: identity-driven concepts, unique names, feasibility,
## risk and reward by ambition, follies, layering, no world claims, legacy
## saves (no victory: history only), and the retained stages/decisions/events/ceremony/effects.
const U=preload("res://scripts/undertaking_system.gd")
const C=preload("res://scripts/undertaking_catalog.gd")
const R=preload("res://scripts/undertaking_rewards.gd")
const E=preload("res://scripts/undertaking_effects.gd")
const W=preload("res://scripts/wonder_concept.gd")
const GW=preload("res://scripts/great_works.gd")
const FoodScript=preload("res://scripts/food_system.gd")
const RIVAL:="rival"
const KNOWN:=["masonry_bond_patterns","joinery","clay_shaping","public_stores","seed_selection","seasonal_patterns","drainage","festival_calendar","tallies","voussoir_arch_assembly"]
var city:Dictionary
var rival_city:Dictionary
var flat:=func(_p:Vector2)->float:return 0.0
var land:=func(_p:Vector2)->bool:return true

func before_test()->void:
	WorldSimulation.clear();GameState.reset_for_new_world(921);SettlementModel.reset_for_new_world();MilitaryCampaign.reset_for_new_world();CivilizationSystem.reset_for_new_world()
	HistoricalFigures.reset_for_new_world()
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	_found(GameState,"Hometown")
	city=GameState.player_settlements[0]
	WorldSimulation.create_actor(RIVAL,921)
	WorldSimulation.actors[RIVAL].identity={"name":"The Rival League"}
	WorldSimulation.scoped(RIVAL,func()->void:
		_found(WorldSimulation.state,"Rivalton")
		rival_city=WorldSimulation.state.player_settlements[0])
func after_test()->void:
	WorldSimulation.clear();GameState.set_process(true);CivilizationSystem.set_process(true);MilitaryCampaign.set_process(true)

func _found(state:Node,name:String)->void:
	state.settlement_name=name;state.settlement_site_committed=true;state.settlement_completed.assign(["Hearth Circle"])
	WorldSimulation.settlements.ensure_founded()
	state.population_allocations={"Construction":20,"Crafting":10,"Food":20}
	state.resource_stockpiles={"Stone":100000.0,"Timber":100000.0,"Clay":100000.0,"Fiber Plants":100000.0}
	state.simulation_metrics={"food_intake_ratio":1.0,"labor_efficiency":1.0,"cohesion":.7,"legitimacy":.6,"food_consumption":100.0}
	state.water_metrics={"intake_ratio":1.0}
	state.population_total=3000;state.population_exact=3000.0
	state.known_discoveries.assign(KNOWN)

func _values(state:Node,lived:Dictionary)->void:
	var model:Dictionary=state.societal_values
	for axis in lived:model.lived[axis]=float(lived[axis])

func _record(target:Dictionary,id:String,fraction:float,status:String="building",passed:=true)->Dictionary:
	var work:float=C.get_definition(id).work
	var r:={"id":id,"status":status,"policy":"careful","progress":work*fraction,"quality":work*fraction,"condition":1.0,"strain":0,"stalled_days":0,"operating_days":0,"last_day":0,"started":0,"reason":"Test","legacy":"Unproven","gates":["design","stores","labor"] if passed else [],"decisions":[],"work_scale":1.0,"speed":1.0,"allure_scale":1.0}
	if id.begins_with("wonder:"):r.custom_name="Test Work "+id.get_slice(":",6);r.shift=0.0;r.feasibility=.6
	if not target.has("undertakings"):target.undertakings=[]
	target.undertakings.append(r)
	return r
func _id(form:String,purpose:String,ambition:String,material:String="stone",tier:int=1,token:String="a1b2c3")->String:
	return W.make_id(form,purpose,ambition,material,tier,token)
func _rival(operation:Callable)->Variant:return WorldSimulation.scoped(RIVAL,operation)

func test_concepts_reflect_identity_and_are_deterministic()->void:
	_values(GameState,{"hierarchy":.95,"centralization":.9,"experimentation":.1,"openness":.1,"collective_obligation":.2})
	_rival(func()->void:_values(WorldSimulation.state,{"hierarchy":.05,"openness":.95,"pluralism":.95,"experimentation":.9,"collective_obligation":.9}))
	var mine:=GW.conceive("player")
	assert_int(mine.size()).is_between(1,3)
	assert_array(GW.conceive("player").map(func(c):return c.name)).is_equal(mine.map(func(c):return c.name))
	var theirs:=GW.conceive(RIVAL)
	assert_array(theirs.map(func(c):return c.purpose)).is_not_equal(mine.map(func(c):return c.purpose))
	for concept:Dictionary in mine+theirs:
		assert_dict(C.get_definition(String(concept.id))).is_not_empty()
		assert_str(String(concept.name)).is_not_empty();assert_str(String(concept.lore)).is_not_empty();assert_str(String(concept.motive)).is_not_empty()
		assert_bool(W.form_available(String(concept.shape),KNOWN)).is_true()
	# A proud, hierarchical people leans toward awe and triumph; an open one toward welcome.
	var proud:=W.purpose_weights("player");var open:=W.purpose_weights(RIVAL)
	assert_float(float(proud.awe_rivals)).is_greater(float(open.awe_rivals))
	assert_float(float(open.welcome_strangers)).is_greater(float(proud.welcome_strangers))
	# Triggers steer the motive: a famine asks for bread before glory.
	var famine:=GW.conceive("player",{"kind":"famine"})
	assert_bool(famine.any(func(c):return c.purpose=="feed_people")).is_true()
	# Knowledge gates the forms: without masonry or joinery there are no towers.
	GameState.known_discoveries.assign([])
	for concept:Dictionary in GW.conceive("player",{"kind":"envy","form":"tower"}):assert_str(String(concept.shape)).is_not_equal("tower")

func test_names_are_unique_and_in_tradition()->void:
	var committed:={}
	for day in range(0,40):
		GameState.elapsed_days=day*97
		var batch:={}
		for concept:Dictionary in GW.conceive("player",{"kind":["famine","war","victory","death","plenty"][day%5]}):
			# Never a name already carried by a work, never twice in one offer.
			assert_bool(W.used_names().has(String(concept.name))).is_false()
			assert_bool(batch.has(String(concept.name))).is_false()
			batch[String(concept.name)]=true
			var result:=U.commission(String(city.id),concept,"modest",flat,land)
			if result.has("ok"):
				assert_bool(committed.has(String(result.name))).is_false()
				committed[String(result.name)]=true
				var r:=U.find(city,String(result.id))
				r.status="functioning";r.progress=U.total_work(r)
	assert_int(committed.size()).is_greater(30)
	# Names already carried by works are never offered again.
	var used:=W.used_names()
	assert_int(used.size()).is_greater(10)
	for concept:Dictionary in GW.conceive("player",{"kind":"famine"}):assert_bool(used.has(String(concept.name))).is_false()
	assert_str(W.tradition("player")).is_not_empty()

func test_feasibility_responds_to_conditions_and_ambition()->void:
	var concept:=W.retarget(GW.conceive("player",{"purpose":"awe_rivals","form":"tower"})[0],"grand")
	var calm:=GW.assess(concept)
	var bold:=GW.assess(W.retarget(concept,"audacious"))
	var small:=GW.assess(W.retarget(concept,"modest"))
	assert_float(float(small.score)).is_greater(float(calm.score))
	assert_float(float(calm.score)).is_greater(float(bold.score))
	assert_str(String(calm.spoken)).is_not_empty()
	assert_bool(String(calm.spoken).contains("%")).is_false()
	assert_array(calm.factors).is_not_empty()
	GameState.simulation_metrics.cohesion=.15;GameState.simulation_metrics.legitimacy=.2;GameState.simulation_metrics.food_intake_ratio=.5
	GameState.population_allocations={"Construction":2,"Crafting":0}
	var troubled:=GW.assess(concept)
	assert_float(float(troubled.score)).is_less(float(calm.score)-.15)
	assert_str(String(troubled.spoken)).is_not_equal(String(calm.spoken))

func test_audacious_fails_more_and_pays_more_over_seeded_trials()->void:
	var stats:={}
	for ambition:String in W.AMBITIONS:
		var score:=float(GW.assess(W.retarget(GW.conceive("player",{"purpose":"awe_rivals","form":"mound"})[0],ambition)).score)
		var collapses:=0;var pay:=0.0
		for i in 1000:
			var outcome:=W.resolve(score,ambition,W.unit_roll("trial/%s/%d" % [ambition,i]))
			if outcome=="collapse":collapses+=1
			pay+=W.pay(ambition,outcome)
		stats[ambition]={"collapse":collapses,"pay":pay}
	assert_int(int(stats.audacious.collapse)).is_greater(int(stats.grand.collapse))
	assert_int(int(stats.grand.collapse)).is_greater(int(stats.modest.collapse))
	assert_float(float(stats.audacious.pay)).is_greater(float(stats.modest.pay))
	# The live completion path draws from the same odds, deterministically.
	var outcomes:={}
	for i in 40:
		var r:=_record(city,_id("mound","awe_rivals","audacious","stone",1,"t%d" % i),.99999)
		U.advance_record(GameState,r,10+i,city)
		outcomes[String(r.outcome)]=int(outcomes.get(String(r.outcome),0))+1
	assert_int(outcomes.size()).is_greater(1)

func test_collapse_is_a_named_folly_with_real_losses()->void:
	var r:=_record(city,_id("tower","defy_gods","audacious"),.99999)
	var cohesion:=float(GameState.simulation_metrics.cohesion);var legitimacy:=float(GameState.simulation_metrics.legitimacy)
	var people:=float(GameState.population_exact)
	var stone:=float(GameState.resource_stockpiles.Stone)
	U.apply_outcome(GameState,r,city,50,"collapse")
	assert_str(String(r.status)).is_equal("ruined")
	assert_str(String(r.outcome)).is_equal("collapse")
	assert_str(String(r.ruin_lore)).contains("Test Work")
	assert_float(float(GameState.simulation_metrics.cohesion)).is_less(cohesion)
	assert_float(float(GameState.simulation_metrics.legitimacy)).is_less(legitimacy)
	assert_float(float(GameState.population_exact)).is_less(people)
	assert_bool(R.rewarding(r)).is_false()
	assert_dict(r.scar).is_not_empty()
	assert_float(float(GW.allure_contribution().value)).is_equal(0.0)
	assert_int(int(R.history(GameState).follies)).is_equal(1)
	# Its ruins can still be quarried for real stone.
	assert_bool(U.quarry(String(city.id),String(r.id)).has("ok")).is_true()
	assert_float(float(GameState.resource_stockpiles.Stone)).is_greater(stone)
	assert_bool(U.valid(GameState.player_settlements)).is_true()

func test_payoff_follows_purpose_ambition_and_outcome()->void:
	var bold:=_record(city,_id("granary","feed_people","audacious","timber",1,"g1"),.99999)
	U.apply_outcome(GameState,bold,city,60,"success")
	assert_float(float(bold.rewards.food_capacity)).is_equal_approx(9000*2.5,.01)
	assert_str(E.family(bold)).is_equal("covenant")
	assert_float(R.local_bonus(GameState,"food_capacity")).is_equal_approx(9000*2.5*float(bold.condition),.1)
	var small:=_record(city,_id("granary","feed_people","modest","timber",1,"g2"),.99999)
	U.apply_outcome(GameState,small,city,61,"flawed")
	assert_float(float(small.rewards.food_capacity)).is_equal_approx(9000*.25,.01)
	assert_float(E.covenant_cap(bold)).is_greater(E.covenant_cap(small))
	# Effects stay bounded however many works a people raises.
	for i in 6:
		var awe:=_record(city,_id("colossus","awe_rivals","audacious","stone",1,"c%d" % i),1.0,"functioning")
		U.apply_outcome(GameState,awe,{},62,"triumph")
	assert_float(E.deterrence("player")).is_equal(.25)
	for i in 6:
		var guide:=_record(city,_id("gate","welcome_strangers","audacious","stone",2,"w%d" % i),1.0,"functioning")
		U.apply_outcome(GameState,guide,{},63,"triumph")
	assert_float(E.traffic_bonus("player")).is_equal(.40)
	assert_float(R.local_bonus(GameState,"attraction")).is_less_equal(.20)
	# Civic works steady cohesion only slowly and never past the ceiling.
	var hall:=_record(city,_id("ring","bind_tribes","grand","stone",1,"b1"),1.0,"functioning")
	U.apply_outcome(GameState,hall,{},64,"success")
	GameState.simulation_metrics.cohesion=.5
	for day in range(100,130):E.advance_city(GameState,city,day,1)
	assert_float(float(GameState.simulation_metrics.cohesion)).is_between(.5,.5+30*E.CIVIC_DAILY*3)
	assert_bool(U.valid(GameState.player_settlements)).is_true()

func test_unlimited_works_and_no_world_claims()->void:
	var id:=_id("tower","watch_heavens","grand","stone",1,"same")
	var mine:=_record(city,id,.99999)
	var theirs:Dictionary=_rival(func()->Dictionary:return _record(rival_city,id,.99999))
	U.apply_outcome(GameState,mine,city,5,"success")
	_rival(func()->void:U.apply_outcome(WorldSimulation.state,theirs,rival_city,4,"success"))
	assert_str(String(mine.status)).is_equal("functioning")
	assert_str(String(theirs.status)).is_equal("functioning")
	assert_dict(U.claims()).is_empty()
	assert_dict(GW.claims()).is_empty()
	# One settlement may raise work after work.
	for i in 20:
		var concept:=GW.conceive("player",{"kind":"plenty","purpose":"give_thanks"})[0]
		GameState.elapsed_days=1000+i
		concept=W.retarget(concept,"modest")
		var result:=GW.commission(String(city.id),concept,"modest","player",flat,land)
		assert_bool(result.has("ok")).is_true()
		U.find(city,String(result.id)).status="functioning"
	assert_int(GW.works().size()).is_greater_equal(21)

func test_commission_ai_parity_and_layering_keeps_history()->void:
	var theirs:Dictionary=_rival(func()->Dictionary:
		var concept:=W.conceive(RIVAL)[0]
		return U.commission(String(rival_city.id),concept,"grand",flat,land))
	assert_bool(theirs.has("ok")).is_true()
	var record:Dictionary=_rival(func()->Dictionary:return U.find(rival_city,String(theirs.id)))
	assert_str(String(WorldSimulation.actors[RIVAL].systems.HistoricalFigures.by_id(String(record.architect.id)).role)).is_equal("Architect")
	assert_float(float(record.feasibility)).is_greater(0.0)
	# Layer a new conception on a standing work: the site and its history remain.
	var base:=_record(city,_id("ring","honor_dead","modest","stone",1,"base"),1.0,"functioning")
	base.custom_name="Old Stones";base.site={"position":Vector2(1,1),"angle":0.0};base.outcome="success"
	U.record_event(base,5,"Completed and functioning")
	var concept:=GW.conceive("player",{"kind":"expand","city_id":String(city.id),"work_id":String(base.id)})[0]
	var result:=GW.commission(String(city.id),concept,"grand")
	assert_bool(result.has("ok")).is_true()
	assert_str(String(base.id)).is_equal(String(result.id))
	assert_str(String(base.layers[0].name)).is_equal("Old Stones")
	assert_vector(base.site.position).is_equal(Vector2(1,1))
	assert_bool(base.events.map(func(e):return e.text).has("Completed and functioning")).is_true()
	U.direct(String(city.id),String(base.id),"abandon")
	assert_str(U.display_name(base)).is_equal("Old Stones")
	assert_str(String(base.status)).is_equal("functioning")
	assert_bool(U.valid(GameState.player_settlements)).is_true()

func test_words_map_onto_the_grammar()->void:
	var concept:=GW.concept_from_words("Raise the tallest tower in the world to honor our dead ancestors")
	assert_str(String(concept.shape)).is_equal("tower")
	assert_str(String(concept.purpose)).is_equal("honor_dead")
	assert_str(String(concept.ambition)).is_equal("audacious")
	var humble:=GW.concept_from_words("a small garden to give thanks for the harvest")
	assert_str(String(humble.ambition)).is_equal("modest")
	assert_str(String(humble.purpose)).is_equal("give_thanks")
	var mapped:=GW.concept_from_mapping({"form":"archive","purpose":"remember_knowledge","ambition":"nonsense"},"x")
	assert_str(String(mapped.shape)).is_equal("archive")
	assert_bool(String(mapped.ambition) in W.AMBITIONS).is_true()
	# Optional model mapping exists only when the player enabled the AI connection,
	# and its prompt confines the model to the grammar.
	var request:=GW.mapping_request("anything")
	if not request.is_empty():assert_str(String(request.messages[0].content)).contains("observatory")

func test_stage_decisions_shift_the_odds_with_real_consequences()->void:
	var r:=_record(city,_id("hall","bind_tribes","grand","timber",1,"h1"),.26,"building",false)
	r.architect={"id":"x","name":"Ada Stone","vision":.8,"ego":.9,"talent":.8,"style":"soaring","mood":0}
	U.advance_record(GameState,r,40,city)
	assert_str(String(r.decision.key)).is_equal("design")
	var before:=float(U.assess_record(r,"player").score)
	assert_bool(U.decide(String(city.id),String(r.id),"grander").has("ok")).is_true()
	assert_float(float(U.assess_record(r,"player").score)).is_less(before)
	assert_float(float(r.allure_scale)).is_equal_approx(1.35,.0001)
	r.progress=U.total_work(r)*.46;r.quality=float(r.progress)
	GameState.food_stocks={FoodScript.STORED:20000.0,FoodScript.FRESH:0.0}
	U.advance_record(GameState,r,42,city)
	assert_str(String(r.decision.key)).is_equal("stores")
	var food_before:=float(GameState.food_stocks[FoodScript.STORED])
	var progress:=float(r.progress)
	assert_bool(U.decide(String(city.id),String(r.id),"pour").has("ok")).is_true()
	var eaten:=food_before-float(GameState.food_stocks[FoodScript.STORED])
	assert_float(eaten).is_greater(0.0)
	assert_float(float(r.progress)-progress).is_equal_approx(eaten*.5,.01)
	r.progress=U.total_work(r)*.71;r.quality=float(r.progress)
	U.advance_record(GameState,r,43,city)
	var cohesion:=float(GameState.simulation_metrics.cohesion)
	assert_bool(U.decide(String(city.id),String(r.id),"levy").has("ok")).is_true()
	assert_int(int(r.strain)).is_equal(90)
	assert_float(float(GameState.simulation_metrics.cohesion)).is_equal_approx(cohesion-.05,.0001)
	r.decision={"key":"demand","day":44,"prompt":"demand"}
	assert_bool(U.decide(String(city.id),String(r.id),"refuse").has("ok")).is_true()
	assert_str(String(r.architect.get("id",""))).is_not_equal("x")
	assert_bool(U.valid(GameState.player_settlements)).is_true()

func test_ai_answers_its_own_decisions_and_player_council_waits()->void:
	var id:=_id("hall","bind_tribes","grand","timber",1,"ai1")
	var theirs:Dictionary=_rival(func()->Dictionary:
		var r:=_record(rival_city,id,.3,"building",false)
		U.advance_record(WorldSimulation.state,r,5,rival_city)
		return r)
	assert_str(String(theirs.decision.key)).is_equal("design")
	_rival(func()->void:WorldSimulation.state.elapsed_days=7;U.advance_all(7))
	assert_bool(theirs.has("decision")).is_false()
	var mine:=_record(city,id,.3,"building",false)
	U.advance_record(GameState,mine,5,city)
	U.advance_all(7)
	assert_bool(mine.has("decision")).is_true()
	GameState.elapsed_days=5+U.PLAYER_DECISION_DAYS
	U.advance_all(5+U.PLAYER_DECISION_DAYS)
	assert_bool(mine.has("decision")).is_false()
	assert_bool(bool(mine.decisions[0].council)).is_true()

var _people:Array=[]
func _run_events(snapshot:Array)->Dictionary:
	# Accidents remove real people; restore the same population for each run.
	if _people.is_empty():_people=[GameState.population_exact,GameState.population_total,GameState.population_cohorts.duplicate(true),GameState.civilian_injuries.duplicate(true)]
	GameState.population_exact=_people[0];GameState.population_total=_people[1];GameState.population_cohorts=_people[2].duplicate(true);GameState.civilian_injuries=_people[3].duplicate(true)
	GameState.player_settlements.assign(bytes_to_var(var_to_bytes(snapshot)))
	GameState.resource_stockpiles={"Stone":100000.0,"Timber":100000.0,"Clay":100000.0,"Fiber Plants":100000.0}
	GameState.simulation_metrics={"food_intake_ratio":1.0,"labor_efficiency":1.0,"cohesion":.7,"legitimacy":.6,"food_consumption":100.0}
	GameState.population_allocations={"Construction":20,"Crafting":10,"Food":20}
	var r:Dictionary=GameState.player_settlements[0].undertakings[0]
	for day in range(1,2500):U.advance_record(GameState,r,day,GameState.player_settlements[0])
	return r

func test_construction_events_are_deterministic_and_bounded()->void:
	var r:=_record(city,_id("colossus","awe_rivals","grand","stone",1,"ev"),0.0)
	r.architect={"id":"figure_a","name":"Ada Stone","vision":.6,"ego":.3,"talent":.8,"style":"severe","mood":0}
	var snapshot:Array=bytes_to_var(var_to_bytes(GameState.player_settlements))
	var first:=_run_events(snapshot).duplicate(true)
	var second:=_run_events(snapshot)
	assert_array(second.events).is_equal(first.events)
	assert_float(float(second.shift)).is_equal(float(first.shift))
	var kinds:=0
	for event:Dictionary in first.events:
		if String(event.get("kind","")) in U.EVENT_KINDS:kinds+=1
	assert_int(kinds).is_greater(0)
	for count in first.get("stage_events",{}).values():assert_int(int(count)).is_less_equal(U.MAX_STAGE_EVENTS)
	assert_float(absf(float(first.shift))).is_less_equal(.4)

func test_ceremony_gifts_come_from_real_stores_and_conserve_goods()->void:
	CivilizationSystem.civilizations.append({"id":RIVAL,"name":"The Rival League","strategic_regions":[],"player_relation":{"opinion":.5,"contact_level":1,"at_war":false,"met_day":1}})
	_rival(func()->void:WorldSimulation.state.resource_stockpiles={"Stone":1000.0})
	var r:=_record(city,_id("ring","honor_dead","grand","stone",1,"cer"),.99999)
	U.apply_outcome(GameState,r,city,50,"success")
	var pending:=GW.pending_ceremonies()
	assert_int(pending.size()).is_equal(1)
	var guest:Dictionary=pending[0].attendees[0]
	assert_str(String(guest.gift.resource)).is_equal("Stone")
	var gift:=float(guest.gift.amount)
	var total_before:=float(GameState.resource_stockpiles.Stone)+1000.0
	assert_bool(GW.dedicate(String(city.id),String(r.id),"The Hearth Stones").has("ok")).is_true()
	var rival_stone:float=_rival(func()->float:return float(WorldSimulation.state.resource_stockpiles.Stone))
	assert_float(rival_stone).is_equal_approx(1000.0-gift,.0001)
	assert_float(float(GameState.resource_stockpiles.Stone)+rival_stone).is_equal_approx(total_before,.0001)
	assert_bool(r.heard_by.has(RIVAL)).is_true()
	assert_float(R.diplomatic_bonus(GameState,RIVAL,50)).is_greater(0.0)
	assert_float(float(GW.allure_contribution().value)).is_greater(0.0)

func test_legacy_records_load_migrate_and_complete()->void:
	var legacy:={"id":"great_hall","status":"building","policy":"press","progress":6000.0,"quality":5000.0,"condition":1.0,"strain":3,"stalled_days":0,"operating_days":0,"last_day":10,"started":0,"reason":"Old save","legacy":"Old","events":[{"day":1,"text":"Foundations authorized"}],"claimed_day":3}
	var ring:={"id":"ancestor_ring","status":"functioning","policy":"careful","progress":4000.0,"quality":4000.0,"condition":1.0,"strain":0,"stalled_days":0,"operating_days":400,"last_day":10,"started":0,"reason":"Old","legacy":"Old"}
	city.undertakings=[legacy,ring]
	var saved:Array=bytes_to_var(var_to_bytes(GameState.player_settlements))
	assert_bool(U.valid(saved)).is_true()
	U.advance_record(GameState,legacy,11,city)
	assert_array(legacy.gates).is_equal(["design","stores"])
	assert_float(float(legacy.progress)).is_greater(6000.0)
	assert_float(R.diplomatic_bonus(GameState,"x",11)).is_equal(0.0)
	assert_str(E.family({"id":"star_steps"})).is_equal("watching_sky")
	assert_bool(R.rewarding(ring)).is_true()
	legacy.progress=U.total_work(legacy)-.0001;legacy.quality=legacy.progress;legacy.gates=["design","stores","labor"]
	U.advance_record(GameState,legacy,12,city)
	assert_str(String(legacy.status)).is_equal("functioning")
	assert_bool(legacy.has("outcome")).is_false()
	saved=bytes_to_var(var_to_bytes(GameState.player_settlements))
	assert_bool(U.valid(saved)).is_true()
	saved[0].undertakings[0].outcome="glorious"
	assert_bool(U.valid(saved)).is_false()
	saved=bytes_to_var(var_to_bytes(GameState.player_settlements))
	saved[0].undertakings[0].rivalry={"holder":5}
	assert_bool(U.valid(saved)).is_false()
	saved=bytes_to_var(var_to_bytes(GameState.player_settlements))
	saved[0].undertakings[0].id="wonder:tower:nonsense:grand:stone:1:x"
	assert_bool(U.valid(saved)).is_false()

func test_enshrine_allure_and_captured_effects()->void:
	var r:=_record(city,_id("hall","remember_knowledge","audacious","timber",1,"en"),.99999)
	U.apply_outcome(GameState,r,{},20,"success")
	GameState.society_exchange.collections["art_a"]={"id":"art_a","kind":"artifact","name":"Banded bead","rarity":2,"held_days":400.0,"study":1.0,"discovery_id":"x"}
	var before:=float(GW.allure_contribution().value)
	assert_bool(GW.enshrine(String(city.id),String(r.id),"missing").has("error")).is_true()
	assert_bool(GW.enshrine(String(city.id),String(r.id),"art_a").has("ok")).is_true()
	assert_float(float(GW.allure_contribution().value)).is_greater(before)
	var awe:=_record(city,_id("colossus","awe_rivals","grand","stone",1,"cap"),.99999)
	U.apply_outcome(GameState,awe,{},21,"success")
	assert_float(E.deterrence("player")).is_greater(0.0)
	city.occupied_by=RIVAL
	assert_float(E.deterrence("player")).is_equal(0.0)
	assert_float(E.deterrence(RIVAL)).is_greater(0.0)
	city.occupied_by=""

func test_facade_is_owner_scoped()->void:
	var mine:=_record(city,_id("hall","bind_tribes","grand","timber",1,"fa"),.3,"building",false)
	U.advance_record(GameState,mine,40,city)
	assert_int(GW.pending_decisions().size()).is_equal(1)
	assert_array(GW.pending_decisions(RIVAL)).is_empty()
	assert_bool(GW.decide(String(city.id),String(mine.id),"practical").has("ok")).is_true()
	assert_array(GW.recent_events(5)).is_not_empty()
	assert_array(GW.known_foreign_works()).is_not_null()
	assert_int(GW.works().size()).is_equal(1)
	assert_int(GW.works(RIVAL).size()).is_equal(0)
	var site:=GW.site(String(city.id),String(mine.id))
	assert_str(String(site.display_name)).is_equal(U.display_name(mine))
	assert_dict(site.assessment).is_not_empty()

func test_famine_survived_raises_one_pitch_with_cooldown_and_save_roundtrip()->void:
	GameState.elapsed_days=4000
	GameState.simulation_metrics.food_days=90.0
	GameState.demographic_ledger.assign([{"kind":"death","cause":"Hunger","count":40,"day":3700}])
	U.advance_all(4000)
	# Pending state persists and validates before the hall reads it.
	var saved:Array=bytes_to_var(var_to_bytes(GameState.player_settlements))
	assert_bool(U.valid(saved)).is_true()
	assert_str(String(saved[0].great_works_pitch.pending.trigger.kind)).is_equal("famine")
	var proposals:=GW.pending_proposals()
	assert_int(proposals.size()).is_equal(1)
	assert_str(String(proposals[0].trigger.kind)).is_equal("famine")
	assert_int(proposals[0].concepts.size()).is_between(1,3)
	assert_str(String(proposals[0].concepts[0].purpose)).is_equal("feed_people")
	assert_bool(proposals[0].proposer is Dictionary).is_true()
	# Reading consumes it; the same pitch is never raised twice.
	assert_array(GW.pending_proposals()).is_empty()
	# Cooldown: even overflowing stores do not raise another pitch within 3 years.
	GameState.simulation_metrics.food_days=400.0
	for day in [4001,4200,4000+365*2]:
		GameState.elapsed_days=day;U.advance_all(day)
		assert_array(GW.pending_proposals()).is_empty()
	# Never while hungry, and never while already building.
	GameState.elapsed_days=4000+365*7;GameState.simulation_metrics.food_intake_ratio=.5
	U.advance_all(4000+365*7)
	assert_array(GW.pending_proposals()).is_empty()
	GameState.simulation_metrics.food_intake_ratio=1.0
	var building:=_record(city,_id("ring","honor_dead","modest","stone",1,"busy"),.2)
	U.advance_all(4000+365*7+1)
	assert_array(GW.pending_proposals()).is_empty()
	building.status="functioning";building.progress=U.total_work(building)
	U.advance_all(4000+365*7+2)
	var later:=GW.pending_proposals()
	assert_int(later.size()).is_equal(1)
	assert_str(String(later[0].trigger.kind)).is_equal("plenty")
	saved=bytes_to_var(var_to_bytes(GameState.player_settlements))
	assert_bool(U.valid(saved)).is_true()
	saved[0].great_works_pitch.seen={"bribe":1}
	assert_bool(U.valid(saved)).is_false()
