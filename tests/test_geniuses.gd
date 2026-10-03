extends GdUnitTestSuite
## GIFTED CHILDREN (scripts/geniuses.gd): born at a stated, seeded rate that
## grows with the square root of a people's births; noticed as children on
## odds that rise with carers and learners (unnoticed, ordinary); grown, they
## make each person on their work count for more (once, on their own work,
## gone at their death); a gifted master builder brings a great work; every
## people by the same rules; and the records save, an older save starting
## with none.

const G:=preload("res://scripts/geniuses.gd")
const U:=preload("res://scripts/undertaking_system.gd")
const W:=preload("res://scripts/wonder_concept.gd")
const SaveSystemScript:=preload("res://scripts/save_system.gd")
const RIVAL:="rival_gifts"
const KNOWN:=["masonry_bond_patterns","joinery","clay_shaping","public_stores","seed_selection","seasonal_patterns","drainage","festival_calendar","tallies","voussoir_arch_assembly"]

var _processing:Dictionary={}

func before()->void:
	for node:Node in [GameState,CivilizationSystem,MilitaryCampaign]:_processing[node]=node.is_processing()

func after()->void:
	WorldSimulation.clear()
	HistoricalFigures.reset_for_new_world()
	MilitaryCampaign.reset_for_new_world();CivilizationSystem.reset_for_new_world();SettlementModel.reset_for_new_world()
	GameState.reset_for_new_world(74017)
	for node:Node in _processing:node.set_process(bool(_processing[node]))

func before_test()->void:
	WorldSimulation.clear()
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	GameState.reset_for_new_world(60211)
	SettlementModel.reset_for_new_world();MilitaryCampaign.reset_for_new_world();CivilizationSystem.reset_for_new_world()
	HistoricalFigures.reset_for_new_world()
	_found(GameState,"Reedford")
	HistoricalFigures.ensure()

func after_test()->void:
	WorldSimulation.clear()

func _found(state:Node,name:String)->void:
	state.settlement_name=name;state.settlement_site_committed=true;state.settlement_completed.assign(["Hearth Circle"])
	state.initialize_population_model()
	state.ensure_population_total(300)
	WorldSimulation.settlements.ensure_founded()
	state.population_allocations={"Food":80,"Survey":10,"Extraction":10,"Construction":20,"Crafting":10,"Logistics":10,"Knowledge":10,"Administration":8,"Defense":8}
	state.resource_stockpiles={"Stone":100000.0,"Timber":100000.0,"Clay":100000.0,"Fiber Plants":100000.0}
	state.simulation_metrics={"food_intake_ratio":1.0,"labor_efficiency":1.0,"cohesion":.7,"legitimacy":.6,"food_consumption":100.0}
	state.water_metrics={"intake_ratio":1.0}
	state.known_discoveries.assign(KNOWN)
	state.elapsed_days=40*365

## A gifted child of `layer`, born `age_days` ago, put straight on the roll.
func _child(figures:Node,layer:String,age_days:int,gift:float=0.5,noticed:bool=false)->Dictionary:
	figures.genius_serial=int(figures.genius_serial)+1
	var day:=int(WorldSimulation.state.elapsed_days)
	var g:={"id":"gift_%d" % int(figures.genius_serial),"serial":int(figures.genius_serial),"layer":layer,"gift":gift,"born":day-age_days,"female":true,
		"home":"","notice_day":day-age_days+7*365,"status":"child","noticed":day-age_days+7*365 if noticed else -1,"name":"Tala Test%d" % int(figures.genius_serial) if noticed else "","figure_id":"","last_roll":day}
	(figures.geniuses as Array).append(g)
	return g

## A gifted grown of `layer`, through the engine's own coming of age.
func _grown(figures:Node,layer:String,gift:float=0.5)->Dictionary:
	var g:=_child(figures,layer,16*365,gift,true)
	G._children(figures,WorldSimulation.state,int(WorldSimulation.state.elapsed_days))
	return figures.by_id(String(g.figure_id))

# --------------------------------------------------------------------------
# Born: the stated rate, seeded, growing with the square root of births
# --------------------------------------------------------------------------

func test_the_rate_is_stated_seeded_and_sublinear()->void:
	# Among 12 births a year (a people of some 300): one born about every 12
	# years, and with ordinary care (half noticed) one seen a generation.
	assert_float(1.0/G.expected_per_year(12.0)).is_between(11.0,13.0)
	assert_float(1.0/(G.expected_per_year(12.0)*0.5)).is_between(20.0,28.0)
	# A hundred times the births make ten times the gifted, not a hundred.
	assert_float(G.expected_per_year(1200.0)/G.expected_per_year(12.0)).is_equal_approx(10.0,0.001)
	var small:=_born_over(12,1200)
	var large:=_born_over(1200,120)
	# Seeded: the same world counts the same again.
	assert_int(_born_over(12,1200)).is_equal(small)
	# Each about 100 expected (Poisson: within three spreads).
	assert_int(small).is_between(70,130)
	assert_int(large).is_between(70,130)

## Gifted births over `years` at `births` a year, the yearly roll as the game runs it.
func _born_over(births:int,years:int)->int:
	var figures:=HistoricalFigures
	figures.genius_tally={};figures.geniuses.clear()
	figures.genius_since=0;figures.genius_births_seen=0
	GameState.lifetime_births=0
	for year in range(1,years+1):
		GameState.lifetime_births+=births
		G._year(figures,GameState,year*365)
		figures.geniuses.clear()
	return int(figures.genius_tally.get("born",0))

func test_each_gift_has_one_of_the_nine_works_a_name_and_a_home()->void:
	var figures:=HistoricalFigures
	figures.genius_since=int(GameState.elapsed_days)-365;figures.genius_births_seen=0
	GameState.lifetime_births=40000
	G._year(figures,GameState,int(GameState.elapsed_days))
	assert_int(figures.geniuses.size()).is_greater(0)
	var town:=String(GameState.player_settlements[0].id)
	for g:Dictionary in figures.geniuses:
		assert_bool(String(g.layer) in G.LAYERS).is_true()
		assert_str(String(g.home)).is_equal(town)
		assert_int(int(g.notice_day)-int(g.born)).is_between(6*365,10*365)
	# The work the people do most is a little likelier, never certain.
	var weights:=G.layer_weights(GameState)
	assert_float(float(weights.Food)).is_greater(float(weights.Defense))
	assert_float(float(weights.Food)).is_less_equal(2.0)

func test_an_older_save_starts_with_none()->void:
	# A save from before gifted children: thousands already born, none counted.
	var figures:=HistoricalFigures
	figures.genius_since=-1
	GameState.lifetime_births=5000
	var day:=int(GameState.elapsed_days)
	G.advance(figures,day)
	assert_int(figures.geniuses.size()).is_equal(0)
	assert_int(int(figures.genius_births_seen)).is_equal(5000)
	# A year on, only that year's births count.
	GameState.lifetime_births=5012
	G.advance(figures,day+365)
	assert_int(int(figures.genius_tally.get("born",0))).is_less_equal(2)

# --------------------------------------------------------------------------
# Noticed: carers and learners raise the odds; the unnoticed grow up ordinary
# --------------------------------------------------------------------------

func test_notice_odds_rise_with_carers_and_learners()->void:
	var people:=float(GameState.population_exact)
	GameState.population_allocations.Administration=0;GameState.population_allocations.Knowledge=0
	var none:=float(G.notice_parts(GameState).chance)
	assert_float(none).is_equal_approx(G.NOTICE_BASE,0.0001)
	GameState.population_allocations.Administration=roundi(people*G.CARER_SHARE)
	var cared:=float(G.notice_parts(GameState).chance)
	GameState.population_allocations.Knowledge=roundi(people*G.TEACHER_SHARE)
	var both:=float(G.notice_parts(GameState).chance)
	assert_float(cared).is_greater(none)
	assert_float(both).is_greater(cared)
	assert_float(both).is_equal_approx(G.NOTICE_CEILING,0.0001)
	# The rolls follow the stated odds: many children, about that share seen.
	assert_float(_noticed_share(0,0)).is_between(0.10,0.32)
	assert_float(_noticed_share(roundi(people*G.CARER_SHARE),roundi(people*G.TEACHER_SHARE))).is_between(0.80,0.98)

func _noticed_share(carers:int,learners:int)->float:
	var figures:=HistoricalFigures
	GameState.population_allocations.Administration=carers;GameState.population_allocations.Knowledge=learners
	figures.genius_tally={}
	for i in 120:
		figures.geniuses.clear()
		_child(figures,"Knowledge",7*365)
		G._children(figures,GameState,int(GameState.elapsed_days))
	return float(figures.genius_tally.get("noticed",0))/120.0

func test_the_unnoticed_grow_up_ordinary()->void:
	var figures:=HistoricalFigures
	GameState.population_allocations.Administration=0;GameState.population_allocations.Knowledge=0
	var missed:Dictionary={}
	for i in 40:
		var g:=_child(figures,"Construction",7*365)
		G._children(figures,GameState,int(GameState.elapsed_days))
		if not figures.geniuses.has(g):missed=g;break
	assert_dict(missed).is_not_empty()
	# Its roll was at or above the stated odds; nothing is kept of it.
	assert_float(float(missed.notice_roll)).is_greater_equal(G.NOTICE_BASE)
	assert_str(String(missed.name)).is_empty()
	assert_int(int(figures.genius_tally.get("missed",0))).is_greater(0)
	# Years on, nobody comes of age from it and building gains nothing.
	G._children(figures,GameState,int(GameState.elapsed_days)+10*365)
	G.refresh(figures,GameState)
	for p:Dictionary in figures.people:assert_bool(p.has("genius")).is_false()
	assert_float(G.bonus(GameState,"Construction")).is_equal(0.0)

func test_a_noticed_child_is_told_plainly_once()->void:
	var figures:=HistoricalFigures
	GameState.population_allocations.Administration=200;GameState.population_allocations.Knowledge=200
	var g:={}
	for i in 20:
		g=_child(figures,"Food",7*365)
		G._children(figures,GameState,int(GameState.elapsed_days))
		if int(g.noticed)>=0:break
	assert_int(int(g.noticed)).is_greater_equal(0)
	assert_str(String(g.name)).is_not_empty()
	var told:=preload("res://scripts/chronicle.gd").entries("whisper",50).filter(func(e:Dictionary)->bool:return String(e.get("key",""))=="genius:"+String(g.id))
	assert_int(told.size()).is_equal(1)
	var text:=String(told[0].text)
	assert_str(text).contains(String(g.name)).contains("getting food").contains("in 100 more").contains("Reedford")
	assert_str(text).not_contains("%")

# --------------------------------------------------------------------------
# Grown: once, on their own work, gone at their death
# --------------------------------------------------------------------------

func test_the_grown_lift_their_own_work_once_and_not_after_death()->void:
	var figures:=HistoricalFigures
	figures.genius_bonus={}
	var base_build:=float(GameState.effective_workers("Construction"))
	var base_food:=float(GameState.effective_workers("Food"))
	var p:=_grown(figures,"Construction",1.0)
	assert_dict(p).is_not_empty()
	assert_str(String(p.role)).is_equal("Architect")
	# 20 builders: all within reach, so the full strength 0.25 (gift 1).
	var expected:=G.STRENGTH_BASE+G.STRENGTH_SPAN
	assert_float(G.bonus(GameState,"Construction")).is_equal_approx(expected,0.0001)
	assert_float(float(GameState.effective_workers("Construction"))).is_equal_approx(base_build*(1.0+expected),0.001)
	# Once: another day's refresh does not stack it.
	G.refresh(figures,GameState);G.refresh(figures,GameState)
	assert_float(float(GameState.effective_workers("Construction"))).is_equal_approx(base_build*(1.0+expected),0.001)
	# Only their own work.
	assert_float(float(GameState.effective_workers("Food"))).is_equal_approx(base_food,0.0001)
	# Patronage: a fifth more.
	figures.support(String(p.id))
	G.refresh(figures,GameState)
	assert_float(G.bonus(GameState,"Construction")).is_equal_approx(expected*G.PATRON,0.0001)
	# Dead, it is gone.
	figures.record_death(String(p.id),int(GameState.elapsed_days),"illness")
	G.refresh(figures,GameState)
	assert_float(G.bonus(GameState,"Construction")).is_equal(0.0)
	assert_float(float(GameState.effective_workers("Construction"))).is_equal_approx(base_build,0.0001)

func test_reach_thins_a_gift_over_a_great_crowd()->void:
	var figures:=HistoricalFigures
	var p:=_grown(figures,"Food",0.0)
	GameState.population_allocations.Food=200
	G.refresh(figures,GameState)
	assert_float(G.bonus(GameState,"Food")).is_equal_approx(G.STRENGTH_BASE,0.0001)
	# Eight times the reach: half as much to each.
	GameState.population_allocations.Food=1600
	G.refresh(figures,GameState)
	assert_float(G.bonus(GameState,"Food")).is_equal_approx(G.STRENGTH_BASE*0.5,0.0001)
	# Two gifted in one work combine, never past the cap.
	_grown(figures,"Food",1.0)
	GameState.population_allocations.Food=100
	G.refresh(figures,GameState)
	var both:=1.0-(1.0-G.STRENGTH_BASE)*(1.0-G.STRENGTH_BASE-G.STRENGTH_SPAN)
	assert_float(G.bonus(GameState,"Food")).is_equal_approx(both,0.0001)
	assert_float(G.bonus(GameState,"Food")).is_less_equal(G.LAYER_CAP)
	assert_str(G.row_words("Food")).contains("Gifted").contains(String(p.name).get_slice(" ",0))

func test_a_gifted_war_leader_leads_better_and_is_sent_first()->void:
	var figures:=HistoricalFigures
	var base:={"command":.5,"tactics":.5,"logistics":.5,"resolve":.5}
	var p:=_grown(figures,"Defense",1.0)
	assert_str(String(p.role)).is_equal("General")
	# Nothing reads the watch's effective workers: no claim is made there.
	assert_float(G.bonus(GameState,"Defense")).is_equal(0.0)
	var lift:=G.command_bonus(p)
	assert_float(lift).is_equal_approx((G.STRENGTH_BASE+G.STRENGTH_SPAN)*G.COMMAND_SHARE,0.0001)
	var with_gift:=figures.general_skill(p,"command",base)
	p.genius.layer="Food"
	var without:=figures.general_skill(p,"command",base)
	p.genius.layer="Defense"
	assert_float(with_gift-without).is_equal_approx(lift,0.0001)
	var led:=figures.commander(base,"army_gifted")
	assert_str(String(led.get("figure_id",""))).is_equal(String(p.id))

func test_a_child_who_dies_takes_the_gift_and_the_people_are_told()->void:
	var figures:=HistoricalFigures
	var g:=_child(figures,"Knowledge",8*365,0.5,true)
	g.last_roll=int(g.born)
	# A world where every child dies: the life table is the people's own.
	var hard:={"condition":40.0,"hazard":0.9,"care":{},"base":GameState.BASELINE_HAZARD_BY_AGE}
	assert_float(G.annual_death_chance(hard,8)).is_equal_approx(0.98,0.0001)
	var kind:={"condition":1.0,"hazard":0.0,"care":{},"base":GameState.BASELINE_HAZARD_BY_AGE}
	assert_float(G.annual_death_chance(kind,8)).is_equal_approx(0.004,0.0001)
	GameState.population_health=0.0;GameState.food_security=0.0
	GameState.exceptional_hazard_smoothed=0.9
	G._mortality(figures,GameState,int(GameState.elapsed_days))
	assert_bool(figures.geniuses.has(g)).is_false()
	assert_int(int(figures.genius_tally.get("lost_young",0))).is_equal(1)
	var told:=preload("res://scripts/chronicle.gd").entries("whisper",50).filter(func(e:Dictionary)->bool:return String(e.get("key",""))=="genius-lost:"+String(g.id))
	assert_int(told.size()).is_equal(1)

# --------------------------------------------------------------------------
# A gifted master builder brings a great work
# --------------------------------------------------------------------------

func test_a_gifted_master_builder_brings_and_leads_a_great_work()->void:
	var figures:=HistoricalFigures
	var p:=_grown(figures,"Construction",1.0)
	var day:=int(GameState.elapsed_days)
	# The pitch: theirs, brought by them, asked once.
	U.detect_pitch(GameState,day)
	var pending:Dictionary=U.pitch_state(GameState).get("pending",{})
	assert_str(String((pending.get("trigger",{}) as Dictionary).get("kind",""))).is_equal("genius")
	assert_str(String((pending.get("proposer",{}) as Dictionary).get("figure_id",""))).is_equal(String(p.id))
	assert_dict(G.architect_trigger(figures,day)).is_empty()
	assert_bool(U.valid(GameState.player_settlements)).is_true()
	U.pitch_state(GameState).erase("pending")
	# A computer ruler would still be moved by them until a work is begun.
	assert_str(String(G.architect_trigger(figures,day,false).get("kind",""))).is_equal("genius")
	# The work: they are its master builder, and its odds are better for it.
	var city:Dictionary=GameState.player_settlements[0]
	var concept:Dictionary=W.conceive("player",{"kind":"genius","day":day})[0]
	var plain:=W.assess(concept,"player",{"architect":{"talent":.95,"name":"Someone"}})
	var gifted:=W.assess(concept,"player",{"architect":{"talent":.95,"name":String(p.name),"genius":G.strength(p)}})
	assert_float(float(gifted.score)).is_greater(float(plain.score))
	assert_bool((gifted.factors as Array).any(func(f:Dictionary)->bool:return String(f.name)=="Gift")).is_true()
	var flat:=func(_p:Vector2)->float:return 0.0
	var land:=func(_p:Vector2)->bool:return true
	var made:=U.commission(String(city.id),concept,"modest",flat,land)
	assert_bool(made.has("ok")).override_failure_message(str(made)).is_true()
	var record:=U.find(city,String(made.id))
	assert_str(String(record.architect.id)).is_equal(String(p.id))
	assert_float(float(record.architect.genius)).is_greater(0.0)
	assert_int(int(p.genius.led)).is_equal(day)
	assert_dict(G.architect_trigger(figures,day,false)).is_empty()
	assert_bool(U.valid(GameState.player_settlements)).is_true()

# --------------------------------------------------------------------------
# Every people by the same rules
# --------------------------------------------------------------------------

func test_a_computer_people_has_its_own_gifted_by_the_same_rules()->void:
	WorldSimulation.create_actor(RIVAL,60211)
	WorldSimulation.actors[RIVAL].identity={"name":"The Esurai"}
	var rival_state:Node=WorldSimulation.actors[RIVAL].systems.GameState
	var player_build:=float(GameState.effective_workers("Construction"))
	var made:Dictionary=WorldSimulation.scoped(RIVAL,func()->Dictionary:
		_found(WorldSimulation.state,"Esuri")
		var figures:=WorldSimulation.figures
		figures.ensure()
		var before:=float(WorldSimulation.state.effective_workers("Construction"))
		var p:=_grown(figures,"Construction",1.0)
		var after:=float(WorldSimulation.state.effective_workers("Construction"))
		var trigger:=preload("res://scripts/civilization_controller.gd").conception_trigger(RIVAL,{"personality":{"openness":.6,"discipline":.5,"empathy":.5,"assertiveness":.5,"risk_tolerance":.6},"hungry":false})
		return {"p":p,"before":before,"after":after,"trigger":trigger,"figures":figures})
	var p:Dictionary=made.p
	assert_dict(p).is_not_empty()
	assert_float(float(made.after)).is_equal_approx(float(made.before)*(1.0+G.STRENGTH_BASE+G.STRENGTH_SPAN),0.001)
	# Read from outside its scope, the same.
	assert_float(G.bonus(rival_state,"Construction")).is_equal_approx(G.STRENGTH_BASE+G.STRENGTH_SPAN,0.0001)
	# Their gifted grown move their ruler to raise a work.
	assert_str(String((made.trigger as Dictionary).get("kind",""))).is_equal("genius")
	# Ours are untouched, and nothing is told of a people we have not met.
	assert_float(G.bonus(GameState,"Construction")).is_equal(0.0)
	assert_float(float(GameState.effective_workers("Construction"))).is_equal_approx(player_build,0.0001)
	assert_bool(HistoricalFigures.by_id(String(p.id)).has("genius")).is_false()
	var told:=preload("res://scripts/chronicle.gd").entries("whisper",50).filter(func(e:Dictionary)->bool:return String(e.get("key","")).begins_with("genius"))
	assert_int(told.size()).is_equal(0)

# --------------------------------------------------------------------------
# Saved, and loaded
# --------------------------------------------------------------------------

func test_the_gifted_save_and_load()->void:
	var figures:=HistoricalFigures
	var p:=_grown(figures,"Crafting",0.7)
	_child(figures,"Logistics",3*365,0.4)
	var noticed:=_child(figures,"Survey",9*365,0.2,true)
	figures.genius_since=int(GameState.elapsed_days);figures.genius_births_seen=777
	G.refresh(figures,GameState)
	var bonus:=G.bonus(GameState,"Crafting")
	assert_float(bonus).is_greater(0.0)
	# The figures' curated state (saved with the military's) and the reflected fields.
	var curated:=figures.export_state()
	var reflected:=SaveSystemScript._capture_reflected(figures,[])
	for key in ["geniuses","genius_bonus","genius_serial","genius_since","genius_births_seen","genius_tally"]:assert_bool(reflected.has(key)).is_true()
	figures.reset_for_new_world()
	figures.seed_value=GameState.world_seed
	SaveSystemScript._apply_reflected(figures,reflected)
	var loaded:=figures.import_state(curated)
	assert_bool(loaded.has("ok")).override_failure_message(str(loaded)).is_true()
	assert_int(figures.geniuses.size()).is_equal(3)
	assert_int(int(figures.genius_births_seen)).is_equal(777)
	assert_float(G.bonus(GameState,"Crafting")).is_equal_approx(bonus,0.0001)
	var back:=figures.by_id(String(p.id))
	assert_str(String(back.role)).is_equal("Maker")
	assert_float(float(back.genius.gift)).is_equal_approx(0.7,0.0001)
	# A noticed child's name stays reserved.
	assert_bool(figures.used.has(String(noticed.name))).is_true()
	# A damaged gifted record is refused.
	var bad:=curated.duplicate(true)
	for q:Dictionary in bad.people:
		if q.has("genius"):q.genius.layer="Dancing"
	assert_bool(figures.import_state(bad).has("error")).is_true()
	# An older figures save (no gifted at all) loads as before.
	var older:=curated.duplicate(true)
	older.people=(older.people as Array).filter(func(q:Dictionary)->bool:return not q.has("genius"))
	assert_bool(figures.import_state(older).has("ok")).is_true()
