extends GdUnitTestSuite
## Great Works core: world uniqueness, races, stages, events, ceremonies,
## effects, upgrade chains and save compatibility, for player and AI alike.
const U=preload("res://scripts/undertaking_system.gd")
const C=preload("res://scripts/undertaking_catalog.gd")
const R=preload("res://scripts/undertaking_rewards.gd")
const E=preload("res://scripts/undertaking_effects.gd")
const GW=preload("res://scripts/great_works.gd")
const FoodScript=preload("res://scripts/food_system.gd")
const RIVAL:="rival"
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

func _record(target:Dictionary,id:String,fraction:float,status:String="building",passed:=true)->Dictionary:
	var work:float=C.get_definition(id).work
	var r:={"id":id,"status":status,"policy":"careful","progress":work*fraction,"quality":work*fraction,"condition":1.0,"strain":0,"stalled_days":0,"operating_days":0,"last_day":0,"started":0,"reason":"Test","legacy":"Unproven","gates":["design","stores","labor"] if passed else [],"decisions":[],"work_scale":1.0,"speed":1.0,"allure_scale":1.0}
	if not target.has("undertakings"):target.undertakings=[]
	target.undertakings.append(r)
	return r

func _rival(operation:Callable)->Variant:return WorldSimulation.scoped(RIVAL,operation)

func test_catalog_spans_eras_with_lore_decrees_and_valid_chains()->void:
	var eras:={}
	assert_int(C.all().size()).is_greater_equal(36)
	for d:Dictionary in C.all():
		eras[d.era]=int(eras.get(d.era,0))+1
		assert_str(String(d.lore)).is_not_empty();assert_str(String(d.decree.get("text",""))).is_not_empty()
		if not String(d.upgrade_from).is_empty():assert_dict(C.get_definition(String(d.upgrade_from))).is_not_empty()
	for era:String in C.ERAS:assert_int(int(eras.get(era,0))).is_greater_equal(4)
	assert_array(C.upgrades_of("ancestor_ring")).contains(["ring_temple"])
	assert_array(C.upgrades_of("ring_temple")).contains(["ring_cathedral"])

func test_world_uniqueness_across_owners()->void:
	var steps:=_record(city,"star_steps",1.0,"functioning");steps.claimed_day=10
	var claim:=U.claim_of("star_steps")
	assert_str(String(claim.owner)).is_equal("player")
	_rival(func()->void:
		assert_bool(U.possibilities(rival_city).map(func(d):return d.id).has("star_steps")).is_false()
		assert_bool(U.start(String(rival_city.id),"star_steps",flat,land).has("error")).is_true()
		# The same rules let the AI start an unclaimed work with its own architect.
		var result:=U.start(String(rival_city.id),"ancestor_ring",flat,land)
		assert_bool(result.has("ok")).is_true()
		var r:=U.find(rival_city,"ancestor_ring")
		assert_str(String(r.architect.id)).is_not_empty()
		assert_str(String(WorldSimulation.figures.by_id(String(r.architect.id)).role)).is_equal("Architect"))
	# The player's figures are untouched by the rival's commission.
	for p:Dictionary in HistoricalFigures.people:assert_str(String(p.role)).is_not_equal("Architect")
	var catalog:=GW.catalog()
	for entry:Dictionary in catalog:
		if entry.id=="star_steps":assert_str(String(entry.claimed_by)).is_equal("player")

func test_race_first_finisher_claims_and_loser_becomes_rival_monument()->void:
	var mine:=_record(city,"ancestor_ring",.9999)
	var theirs:Dictionary=_rival(func()->Dictionary:return _record(rival_city,"ancestor_ring",.9999))
	_rival(func()->void:U.advance_record(WorldSimulation.state,theirs,1,rival_city))
	assert_str(String(theirs.status)).is_equal("functioning")
	assert_int(int(theirs.claimed_day)).is_equal(1)
	U.advance_record(GameState,mine,1,city)
	assert_str(String(mine.status)).is_equal("rival")
	assert_str(U.display_name(mine)).is_equal("The Unfinished Ancestors' Ring")
	assert_str(String(U.claim_of("ancestor_ring").owner)).is_equal(RIVAL)
	# Rival monuments can be quarried for real materials...
	var stone:=float(GameState.resource_stockpiles.Stone)
	assert_bool(U.quarry(String(city.id),"ancestor_ring").has("ok")).is_true()
	assert_float(float(GameState.resource_stockpiles.Stone)-stone).is_equal_approx(240*.9999*.4,.01)
	assert_str(String(mine.status)).is_equal("quarried")
	# ...or repurposed as a lesser monument that never claims the work.
	var other:=_record(city,"stone_crown",.5)
	_rival(func()->void:var r:=_record(rival_city,"stone_crown",1.0,"functioning");r.claimed_day=2)
	U.advance_record(GameState,other,3,city)
	assert_str(String(other.status)).is_equal("rival")
	assert_bool(U.repurpose(String(city.id),"stone_crown").has("ok")).is_true()
	assert_bool(bool(other.lesser)).is_true()
	assert_str(String(U.claim_of("stone_crown").owner)).is_equal(RIVAL)
	assert_float(R.local_bonus(GameState,"craft")).is_equal(0.0)
	assert_float(E.deterrence("player")).is_equal(0.0)
	assert_float(E.deterrence(RIVAL)).is_greater(0.0)

func test_stage_gates_pose_decisions_with_real_consequences()->void:
	var r:=_record(city,"kiln_court",.26,"building",false)
	r.architect={"id":"x","name":"Ada Stone","vision":.8,"ego":.9,"talent":.8,"style":"soaring","mood":0}
	var progress:=float(r.progress)
	U.advance_record(GameState,r,40,city)
	assert_str(String(r.decision.key)).is_equal("design")
	U.advance_record(GameState,r,41,city)
	assert_float(float(r.progress)).is_equal(progress)
	assert_bool(U.decide(String(city.id),"kiln_court","grander").has("ok")).is_true()
	assert_float(U.total_work(r)).is_equal_approx(11000*1.25,.001)
	assert_float(float(r.allure_scale)).is_equal_approx(1.35,.0001)
	assert_bool(r.has("decision")).is_false()
	# Stores: pouring food in spends real rations and materials for real work.
	r.progress=U.total_work(r)*.46;r.quality=float(r.progress)
	GameState.food_stocks={FoodScript.STORED:20000.0,FoodScript.FRESH:0.0}
	U.advance_record(GameState,r,42,city)
	assert_str(String(r.decision.key)).is_equal("stores")
	var food_before:=float(GameState.food_stocks[FoodScript.STORED])
	var clay_before:=float(GameState.resource_stockpiles.Clay)
	progress=float(r.progress)
	assert_bool(U.decide(String(city.id),"kiln_court","pour").has("ok")).is_true()
	var eaten:=food_before-float(GameState.food_stocks[FoodScript.STORED])
	assert_float(eaten).is_greater(0.0)
	assert_float(float(r.progress)-progress).is_equal_approx(eaten*.5,.01)
	assert_float(clay_before-float(GameState.resource_stockpiles.Clay)).is_equal_approx((float(r.progress)-progress)*650/11000,.01)
	# Labor: a levy speeds work, records hardship and costs cohesion.
	r.progress=U.total_work(r)*.71;r.quality=float(r.progress)
	U.advance_record(GameState,r,43,city)
	assert_str(String(r.decision.key)).is_equal("labor")
	var cohesion:=float(GameState.simulation_metrics.cohesion)
	assert_bool(U.decide(String(city.id),"kiln_court","levy").has("ok")).is_true()
	assert_int(int(r.strain)).is_equal(90)
	assert_float(float(r.speed)).is_equal_approx(1.4,.0001)
	assert_float(float(GameState.simulation_metrics.cohesion)).is_equal_approx(cohesion-.05,.0001)
	# A disabled option cannot be forced.
	r.decision={"key":"labor","day":44,"prompt":"again"}
	GameState.food_stocks={};GameState.economy_stage="subsistence"
	assert_bool(U.decide(String(city.id),"kiln_court","paid").has("error")).is_true()
	# Refusing a proud architect's demand loses them.
	r.decision={"key":"demand","day":44,"prompt":"demand"}
	assert_bool(U.decide(String(city.id),"kiln_court","refuse").has("ok")).is_true()
	assert_str(String(r.architect.get("id",""))).is_not_equal("x")
	assert_bool(U.valid(GameState.player_settlements)).is_true()

func test_ai_answers_its_own_decisions_and_player_council_waits()->void:
	var theirs:Dictionary=_rival(func()->Dictionary:
		var r:=_record(rival_city,"kiln_court",.3,"building",false)
		U.advance_record(WorldSimulation.state,r,5,rival_city)
		return r)
	assert_str(String(theirs.decision.key)).is_equal("design")
	_rival(func()->void:WorldSimulation.state.elapsed_days=7;U.advance_all(7))
	assert_bool(theirs.has("decision")).is_false()
	assert_int(theirs.decisions.size()).is_equal(1)
	var mine:=_record(city,"measures_house",.3,"building",false)
	U.advance_record(GameState,mine,5,city)
	U.advance_all(7)
	assert_bool(mine.has("decision")).is_true()
	GameState.elapsed_days=5+U.PLAYER_DECISION_DAYS
	U.advance_all(5+U.PLAYER_DECISION_DAYS)
	assert_bool(mine.has("decision")).is_false()
	assert_bool(bool(mine.decisions[0].council)).is_true()

func _run_events(snapshot:Array)->Dictionary:
	GameState.player_settlements.assign(bytes_to_var(var_to_bytes(snapshot)))
	GameState.resource_stockpiles={"Stone":100000.0,"Timber":100000.0,"Clay":100000.0,"Fiber Plants":100000.0}
	GameState.simulation_metrics={"food_intake_ratio":1.0,"labor_efficiency":1.0,"cohesion":.7,"legitimacy":.6,"food_consumption":100.0}
	var r:Dictionary=GameState.player_settlements[0].undertakings[0]
	for day in range(1,2500):U.advance_record(GameState,r,day,GameState.player_settlements[0])
	return r

func test_construction_events_are_deterministic_bounded_and_named()->void:
	var r:=_record(city,"stone_crown",0.0)
	r.architect={"id":"figure_a","name":"Ada Stone","vision":.6,"ego":.3,"talent":.8,"style":"severe","mood":0}
	var snapshot:Array=bytes_to_var(var_to_bytes(GameState.player_settlements))
	var first:=_run_events(snapshot).duplicate(true)
	var second:=_run_events(snapshot)
	assert_array(second.events).is_equal(first.events)
	assert_float(float(second.progress)).is_equal(float(first.progress))
	var kinds:=0
	for event:Dictionary in first.events:
		if String(event.get("kind","")) in U.EVENT_KINDS:kinds+=1
	assert_int(kinds).is_greater(0)
	for count in first.get("stage_events",{}).values():assert_int(int(count)).is_less_equal(U.MAX_STAGE_EVENTS)

func test_ceremony_gifts_come_from_real_stores_and_conserve_goods()->void:
	CivilizationSystem.civilizations.append({"id":RIVAL,"name":"The Rival League","strategic_regions":[],"player_relation":{"opinion":.5,"contact_level":1,"at_war":false,"met_day":1}})
	_rival(func()->void:WorldSimulation.state.resource_stockpiles={"Stone":1000.0})
	var r:=_record(city,"ancestor_ring",.9999)
	r.architect={"id":"figure_a","name":"Ada Stone","vision":.6,"ego":.3,"talent":.8,"style":"severe","mood":0}
	U.advance_record(GameState,r,50,city)
	assert_str(String(r.status)).is_equal("functioning")
	var pending:=GW.pending_ceremonies()
	assert_int(pending.size()).is_equal(1)
	var guest:Dictionary=pending[0].attendees[0]
	assert_str(String(guest.civ_id)).is_equal(RIVAL)
	assert_str(String(guest.gift.resource)).is_equal("Stone")
	var gift:=float(guest.gift.amount)
	var total_before:=float(GameState.resource_stockpiles.Stone)+1000.0
	assert_bool(GW.dedicate(String(city.id),"ancestor_ring","  ").has("error")).is_true()
	var result:=GW.dedicate(String(city.id),"ancestor_ring","The Hearth Stones")
	assert_bool(result.has("ok")).is_true()
	var rival_stone:float=_rival(func()->float:return float(WorldSimulation.state.resource_stockpiles.Stone))
	assert_float(rival_stone).is_equal_approx(1000.0-gift,.0001)
	assert_float(float(GameState.resource_stockpiles.Stone)+rival_stone).is_equal_approx(total_before,.0001)
	assert_str(U.display_name(r)).is_equal("The Hearth Stones")
	assert_bool(r.heard_by.has(RIVAL)).is_true()
	assert_float(R.diplomatic_bonus(GameState,RIVAL,50)).is_greater(0.0)
	assert_array(GW.pending_ceremonies()).is_empty()
	var allure:=GW.allure_contribution()
	assert_float(float(allure.value)).is_greater(float(C.get_definition("ancestor_ring").allure))
	assert_bool(U.valid(GameState.player_settlements)).is_true()

func test_transformative_effects_are_real_and_bounded()->void:
	for id in ["stone_crown","returning_arch","assembly_dome"]:_record(city,id,1.0,"functioning")
	assert_float(E.deterrence("player")).is_equal(.25)
	for id in ["safe_passage","harbor_lamp","joining_water","grand_terminus","sky_harbor"]:_record(city,id,1.0,"functioning")
	assert_float(E.traffic_bonus("player")).is_equal(.40)
	assert_int(E.decree_options("player").size()).is_equal(8)
	# Covenant moves real food into a sealed reserve and back; none is created.
	var granary:=_record(city,"common_stores",1.0,"functioning")
	GameState.food_stocks={FoodScript.STORED:10000.0,FoodScript.FRESH:0.0}
	for day in range(1,60):E.advance_city(GameState,city,day,1)
	var sealed:=float(granary.covenant)
	assert_float(sealed).is_greater(0.0)
	assert_float(sealed).is_less_equal(6000.0)
	assert_float(float(GameState.food_stocks[FoodScript.STORED])+sealed).is_equal_approx(10000.0,.001)
	GameState.simulation_metrics.food_intake_ratio=.5
	E.advance_city(GameState,city,61,1)
	assert_float(float(granary.covenant)).is_less(sealed)
	assert_float(float(GameState.food_stocks[FoodScript.STORED])+float(granary.covenant)).is_equal_approx(10000.0,.001)
	# Long Song archives knowledge and restores a bounded amount each year.
	var song:=_record(city,"long_song",1.0,"functioning")
	GameState.known_discoveries=["tallies","cordage","basketry"]
	E.advance_city(GameState,city,30,1)
	GameState.known_discoveries=[]
	E.advance_city(GameState,city,60,1)
	assert_int(GameState.known_discoveries.size()).is_equal(1)
	E.advance_city(GameState,city,90,1)
	assert_int(GameState.known_discoveries.size()).is_equal(1)
	E.advance_city(GameState,city,390,1)
	assert_int(GameState.known_discoveries.size()).is_equal(2)
	assert_bool(E.valid_archive(song.archive)).is_true()
	# Watching Sky: warnings only for its holder, never beyond its horizon.
	assert_array(GW.forecast()).is_empty()
	_record(city,"star_steps",1.0,"functioning")
	for warning:Dictionary in GW.forecast():assert_int(int(warning.in_days)).is_less_equal(120)
	assert_array(GW.forecast(RIVAL)).is_empty()
	assert_bool(U.valid(GameState.player_settlements)).is_true()

func test_captured_work_effects_pass_to_the_occupier()->void:
	_record(city,"stone_crown",1.0,"functioning")
	assert_float(E.deterrence("player")).is_greater(0.0)
	city.occupied_by=RIVAL
	assert_float(E.deterrence("player")).is_equal(0.0)
	assert_float(E.deterrence(RIVAL)).is_greater(0.0)
	assert_str(String(U.claim_of("stone_crown").holder)).is_equal(RIVAL)
	assert_str(String(U.claim_of("stone_crown").owner)).is_equal("player")
	assert_float(float(GW.allure_contribution(RIVAL).value)).is_greater(0.0)
	city.occupied_by=""

func test_upgrade_in_place_keeps_name_history_and_claims()->void:
	var ring:=_record(city,"ancestor_ring",1.0,"functioning")
	ring.claimed_day=5;ring.custom_name="Old Stones";ring.site={"position":Vector2(1,1),"angle":0.0}
	ring.heard_by={RIVAL:{"day":5,"condition":1.0,"strain":0}}
	U.record_event(ring,5,"Completed and functioning")
	GameState.known_discoveries=["masonry_bond_patterns"]
	assert_bool(U.possibilities(city).map(func(d):return d.id).has("ring_temple")).is_true()
	assert_bool(U.start(String(city.id),"ring_temple").has("ok")).is_true()
	assert_str(String(ring.id)).is_equal("ring_temple")
	assert_str(U.display_name(ring)).is_equal("Old Stones")
	assert_str(String(ring.layers[0].id)).is_equal("ancestor_ring")
	assert_bool(ring.heard_by.has(RIVAL)).is_true()
	assert_vector(ring.site.position).is_equal(Vector2(1,1))
	var texts:Array=ring.events.map(func(e):return e.text)
	assert_bool(texts.has("Completed and functioning")).is_true()
	assert_str(String(U.claim_of("ancestor_ring").owner)).is_equal("player")
	# Abandoning the rebuilding reopens the older work.
	U.direct(String(city.id),"ring_temple","abandon")
	assert_str(String(ring.id)).is_equal("ancestor_ring")
	assert_str(String(ring.status)).is_equal("functioning")
	assert_bool(U.start(String(city.id),"ring_temple").has("ok")).is_true()
	ring.progress=U.total_work(ring)-.0001;ring.quality=float(ring.progress);ring.gates=["design","stores","labor"]
	U.advance_record(GameState,ring,500,city)
	assert_str(String(ring.status)).is_equal("functioning")
	assert_str(String(U.claim_of("ring_temple").owner)).is_equal("player")
	assert_str(String(U.claim_of("ancestor_ring").owner)).is_equal("player")
	assert_int(int(R.legacy(GameState).claimed)).is_equal(2)
	var saved:Array=bytes_to_var(var_to_bytes(GameState.player_settlements))
	assert_bool(U.valid(saved)).is_true()
	assert_str(String(saved[0].undertakings[0].layers[0].name)).is_equal("Old Stones")

func test_legacy_records_load_migrate_and_validate()->void:
	var legacy:={"id":"great_hall","status":"building","policy":"press","progress":6000.0,"quality":5000.0,"condition":1.0,"strain":3,"stalled_days":0,"operating_days":0,"last_day":10,"started":0,"reason":"Old save","legacy":"Old","events":[{"day":1,"text":"Foundations authorized"}]}
	city.undertakings=[legacy]
	var saved:Array=bytes_to_var(var_to_bytes(GameState.player_settlements))
	assert_bool(U.valid(saved)).is_true()
	U.advance_record(GameState,legacy,11,city)
	# Gates already passed by legacy progress are not re-posed.
	assert_array(legacy.gates).is_equal(["design","stores"])
	assert_bool(legacy.has("decision")).is_false()
	assert_float(float(legacy.progress)).is_greater(6000.0)
	saved=bytes_to_var(var_to_bytes(GameState.player_settlements))
	assert_bool(U.valid(saved)).is_true()
	saved[0].undertakings[0].work_scale=NAN
	assert_bool(U.valid(saved)).is_false()
	saved=bytes_to_var(var_to_bytes(GameState.player_settlements))
	saved[0].undertakings[0].decision={"key":"bribe","day":1}
	assert_bool(U.valid(saved)).is_false()
	saved=bytes_to_var(var_to_bytes(GameState.player_settlements))
	saved[0].undertakings[0].status="rival"
	assert_bool(U.valid(saved)).is_true()
	saved[0].undertakings[0].rivalry={"holder":5}
	assert_bool(U.valid(saved)).is_false()

func test_enshrine_requires_held_artifact_and_room()->void:
	var ring:=_record(city,"ancestor_ring",1.0,"functioning")
	GameState.society_exchange.collections["art_a"]={"id":"art_a","kind":"artifact","name":"Banded bead","rarity":2,"held_days":400.0,"study":1.0,"discovery_id":"x"}
	GameState.society_exchange.collections["art_b"]={"id":"art_b","kind":"artifact","name":"Calendar stone","rarity":3,"held_days":10.0,"study":1.0,"discovery_id":"y"}
	GameState.society_exchange.collections["art_c"]={"id":"art_c","kind":"artifact","name":"Flute","rarity":0,"held_days":10.0,"study":1.0,"discovery_id":"z"}
	var before:=float(GW.allure_contribution().value)
	assert_bool(GW.enshrine(String(city.id),"ancestor_ring","missing").has("error")).is_true()
	assert_bool(GW.enshrine(String(city.id),"ancestor_ring","art_a").has("ok")).is_true()
	assert_bool(GW.enshrine(String(city.id),"ancestor_ring","art_a").has("error")).is_true()
	assert_bool(GW.enshrine(String(city.id),"ancestor_ring","art_b").has("ok")).is_true()
	assert_bool(GW.enshrine(String(city.id),"ancestor_ring","art_c").has("error")).is_true()
	assert_float(float(GW.allure_contribution().value)).is_greater(before)
	assert_array(ring.enshrined).is_equal(["art_a","art_b"])
	_record(city,"rain_court",1.0,"functioning")
	assert_bool(GW.enshrine(String(city.id),"rain_court","art_c").has("error")).is_true()
	assert_bool(U.valid(GameState.player_settlements)).is_true()

func test_facade_world_status_and_decisions_are_owner_scoped()->void:
	_rival(func()->void:_record(rival_city,"kiln_court",.5))
	# Contact alone reveals nothing: only rivalry news (real observations) does.
	CivilizationSystem.civilizations.append({"id":RIVAL,"name":"The Rival League","strategic_regions":[],"player_relation":{"opinion":0.0,"contact_level":1,"at_war":false,"met_day":1}})
	for entry:Dictionary in GW.world_status():
		if entry.id=="kiln_court":
			assert_str(String(entry.status)).is_equal("unclaimed")
			assert_array(entry.known_sites).is_empty()
	for candidate:Dictionary in GW.candidates():assert_bool(candidate.has("rivals")).is_false()
	var mine:=_record(city,"measures_house",.3,"building",false)
	U.advance_record(GameState,mine,40,city)
	assert_int(GW.pending_decisions().size()).is_equal(1)
	assert_array(GW.pending_decisions(RIVAL)).is_empty()
	assert_bool(GW.decide(String(city.id),"measures_house","practical").has("ok")).is_true()
	assert_array(GW.rival_news_for("player")).is_not_null()
	assert_array(GW.recent_events(5)).is_not_empty()
