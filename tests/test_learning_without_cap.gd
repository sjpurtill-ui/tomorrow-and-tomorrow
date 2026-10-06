extends GdUnitTestSuite
## Learning without a cap (docs/PEOPLE_FIRST.md A): every learner counts, the
## questions worked at once grow without end, learners use goods, and a people
## that presses learning runs ahead of the calendar on its own age. The same
## rules for every people.
const R:=preload("res://scripts/research_600_catalog.gd")
const Society:=preload("res://scripts/society_model.gd")
const Impact:=preload("res://scripts/task_impact.gd")
const YEAR:=40

func before_test()->void:
	WorldSimulation.clear()
	GameState.reset_for_new_world(515151)
	GameState.initialize_population_model();GameState.ensure_population_total(400)
	GameState.synchronize_population_allocations()
	DiscoverySystem.reset_for_new_world();DiscoverySystem.initialize()
	GameState.elapsed_days=float(YEAR*365)
	var known:Array[String]=[]
	for entry:Dictionary in DiscoverySystem.technology_catalog:
		if DiscoverySystem.research_600_earliest_year(entry)<YEAR-4.0:known.append(String(entry.id))
	GameState.known_discoveries.assign(known)
	GameState.active_investigations.clear();GameState.research_targets.clear();GameState.discovery_progress.clear()
	preload("res://scripts/civilian_care.gd").data().staff_share=0.0
	GameState.resource_stockpiles[R.GOODS_KEY]=500.0
	DiscoverySystem.refresh_investigations()

func after_test()->void:
	WorldSimulation.clear()

## The older rule: twelve learners in full, then a tenfold more added 0.78 of twelve.
static func _knee(researchers:float)->float:
	return researchers if researchers<=12.0 else 12.0*(1.0+0.78*log(researchers/12.0)/log(10.0))

## A learner count and the people's allocation set to it.
func _learners(count:int)->float:
	GameState.population_allocations["Knowledge"]=count
	return float(GameState.effective_workers("Knowledge"))

# --- No knee ----------------------------------------------------------------------

func test_two_hundred_learners_do_about_twice_the_work_of_one_hundred()->void:
	var ratio:=R.team_capacity(200.0)/R.team_capacity(100.0)
	assert_float(ratio).override_failure_message("200 against 100: %.3f" % ratio).is_between(1.8,2.0)
	# The older knee gave 200 learners barely more than 100 (about 1.1 times).
	assert_float(_knee(200.0)/_knee(100.0)).is_less(1.15)
	# Every doubling adds about as much as the last, far past twelve.
	assert_float(R.team_capacity(24.0)/R.team_capacity(12.0)).is_greater(1.75)
	assert_float(R.team_capacity(2000.0)/R.team_capacity(1000.0)).is_greater(1.8)
	# Ten times the learners, about seven and a half times the work: never a cap.
	assert_float(R.team_capacity(1000.0)/R.team_capacity(100.0)).is_between(7.0,8.5)
	# A band's few learners each count in full, as they always did.
	assert_float(R.team_capacity(3.0)).is_equal_approx(3.0*R.LEARNER_PACE,0.0001)

func test_one_question_gets_a_little_less_from_each_more_person()->void:
	assert_float(R.team_strength(0.5)).is_equal_approx(0.5,0.0001)
	assert_float(R.team_strength(1.0)).is_equal_approx(1.0,0.0001)
	assert_float(R.team_strength(10.0)).is_equal_approx(pow(10.0,R.QUESTION_EXPONENT),0.0001)
	assert_float(R.team_strength(20.0)/R.team_strength(10.0)).is_between(1.75,1.85)
	assert_float(R.team_strength(1.0e6)).is_greater(R.team_strength(1.0e5)*6.0)

## The allocation is the budget: the work comes from the people at learning,
## never from the people's size.
func test_research_comes_from_the_people_at_learning_never_from_size_alone()->void:
	GameState.population_allocations["Knowledge"]=20
	var small:=DiscoverySystem.research_teams()
	var channel:=String(GameState.active_investigations.keys()[0])
	var home:=channel.split("::")
	var small_pace:=float(DiscoverySystem.research_capacity_for(home[0],home[1]).progress_multiplier)
	# Ten times the people, the same twenty at learning: the same work.
	GameState.ensure_population_total(4000)
	GameState.synchronize_population_allocations()
	GameState.population_allocations["Knowledge"]=20
	var big:=DiscoverySystem.research_teams()
	assert_float(float(big.on_lines)).is_equal_approx(float(small.on_lines),0.0001)
	assert_float(float(big.work)).is_equal_approx(float(small.work),0.0001)
	assert_float(float(DiscoverySystem.research_capacity_for(home[0],home[1]).progress_multiplier)).is_less_equal(small_pace*1.0001)
	# Nobody at learning: no research at all, however many people.
	GameState.population_allocations["Knowledge"]=0
	assert_float(float(DiscoverySystem.research_teams().work)).is_equal(0.0)
	assert_float(float(DiscoverySystem.research_capacity_for(home[0],home[1]).progress_multiplier)).is_equal(0.0)
	# A big people that moves many hands to learning learns much faster.
	GameState.population_allocations["Knowledge"]=400
	assert_float(float(DiscoverySystem.research_teams().work)).is_greater(float(small.work)*10.0)

# --- Questions at once ----------------------------------------------------------------

func test_teams_grow_past_twenty_four_at_large_populations()->void:
	assert_int(R.team_count(2.5)).is_equal(4)
	assert_int(R.team_count(250000.0)).is_equal(24)
	assert_int(R.team_count(2.5e6)).is_equal(28)
	assert_int(R.team_count(1.0e12)).is_greater(40)
	# A great people with its learners on the lines fields more than 24 teams.
	GameState.ensure_population_total(4_000_000)
	GameState.synchronize_population_allocations()
	GameState.population_allocation_percentages["Knowledge"]=20.0
	GameState.synchronize_population_allocations()
	var teams:=DiscoverySystem.research_teams()
	assert_float(float(teams.on_lines)).is_greater(250000.0)
	assert_int(int(teams.count)).is_greater(24)

# --- Goods -------------------------------------------------------------------------------

func test_learners_take_their_goods_and_a_shortage_halves_learning_at_most()->void:
	assert_float(R.goods_factor(0.0)).is_equal_approx(0.5,0.0001)
	assert_float(R.goods_factor(1.0)).is_equal_approx(1.0,0.0001)
	assert_float(R.goods_factor(0.5)).is_equal_approx(0.75,0.0001)
	# Learning ahead of the age is dear: LEAD_GOODS_YEARS ahead, twice the goods.
	assert_float(R.goods_need(10.0,1.0,R.LEAD_GOODS_YEARS)).is_equal_approx(2.0*R.goods_need(10.0),0.0001)
	assert_float(R.goods_need(10.0,1.0,R.LEAD_GOODS_YEARS*3.0)).is_equal_approx(4.0*R.goods_need(10.0),0.0001)
	var learners:=float(GameState.effective_workers("Knowledge"))
	assert_float(learners).is_greater(0.0)
	# One goods-unit keeps a learner twenty days; the day's goods leave the stores.
	assert_float(R.goods_need(learners)).is_equal_approx(learners/20.0,0.0001)
	var before:=float(GameState.resource_stockpiles[R.GOODS_KEY])
	GameState.elapsed_days+=1.0
	DiscoverySystem.process_day({})
	assert_float(before-float(GameState.resource_stockpiles[R.GOODS_KEY])).is_equal_approx(learners/20.0,0.0001)
	assert_float(DiscoverySystem.learning_goods_cover()).is_equal_approx(1.0,0.0001)
	# A team on a question whose age has come (teams take the quickest
	# question, which may stand a little ahead of its age).
	var channel:=String(GameState.active_investigations.keys()[0])
	for desk:Variant in GameState.active_investigations:
		if DiscoverySystem.age_bucket(DiscoverySystem.discovery_definition(String(GameState.active_investigations[desk])))==0:channel=String(desk);break
	var home:=channel.split("::")
	var full:=float(DiscoverySystem.research_capacity_for(home[0],home[1]).progress_multiplier)
	# Empty stores: the learners work at half pace, never less.
	GameState.resource_stockpiles[R.GOODS_KEY]=0.0
	GameState.elapsed_days+=1.0
	DiscoverySystem.process_day({})
	assert_float(DiscoverySystem.learning_goods_cover()).is_equal(0.0)
	var empty:=float(DiscoverySystem.research_capacity_for(home[0],home[1]).progress_multiplier)
	assert_float(empty/full).is_equal_approx(0.5,0.01)
	assert_str(DiscoverySystem._investigation_bottleneck(DiscoverySystem.discovery_definition(String(GameState.active_investigations.get(channel,""))),1,1.0,1.0,0.5,{"team_people":100.0,"support_multiplier":1.0})).starts_with("LEARNING GOODS")
	# Half the goods: three quarters of the pace.
	GameState.resource_stockpiles[R.GOODS_KEY]=learners/40.0
	GameState.elapsed_days+=1.0
	DiscoverySystem.process_day({})
	assert_float(DiscoverySystem.learning_goods_cover()).is_equal_approx(0.5,0.0001)
	assert_float(float(GameState.resource_stockpiles[R.GOODS_KEY])).is_equal_approx(0.0,0.0001)

# --- The people's own age ----------------------------------------------------------------

func test_a_people_far_ahead_still_progresses_at_its_own_age()->void:
	var calendar:=float(GameState.elapsed_days)/365.0
	var ahead:={"id":"own_age_test","name":"Ahead","dynamic":"culture","subcategory":"Social cohesion","earliest_year":calendar+40.0,"signals":[]}
	# Against the calendar it is forty years ahead: nine times the work.
	assert_float(DiscoverySystem.research_early_factor(ahead,calendar)).is_greater(8.0)
	# A people whose learning runs fifty years ahead takes it up as work of its age.
	DiscoverySystem.learning_lead=50.0
	assert_float(DiscoverySystem.learning_year()).is_equal_approx(calendar+50.0,0.001)
	assert_float(DiscoverySystem.research_years_ahead(ahead)).is_equal(0.0)
	assert_float(DiscoverySystem.research_early_factor(ahead)).is_equal(1.0)
	assert_int(DiscoverySystem.age_bucket(ahead)).is_equal(0)
	# Its scholarship goes with it: no extra price for the lead itself.
	var bronze:=DiscoverySystem.discovery_definition("copper_smelting")
	GameState.scholarship_level=calendar
	assert_float(DiscoverySystem.era_cost_multiplier(bronze)).is_equal(1.0)
	# And its research still moves day by day.
	var progress_before:=GameState.discovery_progress.duplicate()
	for day in 30:
		GameState.elapsed_days+=1.0
		DiscoverySystem.process_day({})
	var moved:=false
	for id:Variant in GameState.discovery_progress:
		if float(GameState.discovery_progress[id])>float(progress_before.get(id,0.0)):moved=true
	assert_bool(moved or GameState.discovery_log.size()>0).is_true()

func test_what_a_people_knows_pays_off_to_the_age_its_knowledge_reached()->void:
	var model=DiscoverySystem.society_model
	var calendar:=float(GameState.elapsed_days)/365.0
	# Everything up to year 200 is known: the frontier stands far past the calendar.
	var known:Array[String]=[]
	for entry:Dictionary in DiscoverySystem.technology_catalog:
		if DiscoverySystem.research_600_earliest_year(entry)<200.0:known.append(String(entry.id))
	GameState.known_discoveries.assign(known)
	DiscoverySystem.learning_lead=0.0
	model._rebuild_effect_totals(DiscoverySystem.catalog)
	assert_float(float(model.ceiling_era)).is_equal_approx(calendar,0.01)
	# With its learning a hundred years ahead, the payoffs follow it.
	DiscoverySystem.learning_lead=100.0
	model._rebuild_effect_totals(DiscoverySystem.catalog)
	assert_float(float(model.ceiling_era)).is_greater(calendar+90.0)
	# Still held to what its knowledge reached, never past it.
	DiscoverySystem.learning_lead=1000.0
	model._rebuild_effect_totals(DiscoverySystem.catalog)
	assert_float(float(model.ceiling_era)).is_less(300.0)

func test_pressing_learning_runs_ahead_and_easing_off_lets_the_calendar_catch_up()->void:
	var able:=float(GameState.able_population())
	var sustainable:=DiscoverySystem.sustainable_learning_share()
	assert_float(sustainable).is_greater(0.0)
	# At the share the age can spare, the lead holds still.
	assert_float(R.lead_rate(sustainable,sustainable)).is_equal_approx(0.0,0.0001)
	# Twice that share: LEAD_YEARS_PER_DOUBLING years a year; four times, twice that.
	assert_float(R.lead_rate(sustainable*2.0,sustainable)).is_equal_approx(R.LEAD_YEARS_PER_DOUBLING,0.0001)
	assert_float(R.lead_rate(sustainable*4.0,sustainable)).is_equal_approx(R.LEAD_YEARS_PER_DOUBLING*2.0,0.0001)
	assert_float(R.lead_rate(0.0,sustainable)).is_equal_approx(-R.LEAD_YEARS_PER_DOUBLING*R.LEAD_FALL_DOUBLINGS,0.0001)
	# A people with a third of its able at learning gains on the calendar day by day.
	GameState.population_allocations["Knowledge"]=roundi(able/3.0)
	DiscoverySystem.learning_lead=0.0
	for day in 60:
		GameState.elapsed_days+=1.0
		DiscoverySystem.process_day({})
	var gained:=float(DiscoverySystem.learning_lead)
	assert_float(gained).is_greater(0.01)
	assert_float(DiscoverySystem.learning_year()).is_equal_approx(float(GameState.elapsed_days)/365.0+gained,0.0001)
	# Nobody learning: the calendar catches up, never passing below it.
	GameState.population_allocations["Knowledge"]=0
	for day in 400:
		GameState.elapsed_days+=1.0
		DiscoverySystem.process_day({})
	assert_float(float(DiscoverySystem.learning_lead)).is_equal(0.0)

func test_an_older_save_loads_at_the_calendar_with_no_jump()->void:
	# A save from before the lead holds no field for it: the system keeps 0.
	var saved:=SaveSystem._capture_reflected(DiscoverySystem,SaveSystem.REFLECT_SKIP.get("DiscoverySystem",[]))
	assert_bool(saved.has("learning_lead")).is_true()
	saved.erase("learning_lead")
	DiscoverySystem.learning_lead=0.0
	SaveSystem._apply_reflected(DiscoverySystem,saved)
	assert_float(DiscoverySystem.learning_lead).is_equal(0.0)
	assert_float(DiscoverySystem.learning_year()).is_equal_approx(float(GameState.elapsed_days)/365.0,0.0001)
	# The day's goods record is never saved.
	assert_bool(saved.has("_learning_day")).is_false()
	# A saved lead comes back as it was.
	DiscoverySystem.learning_lead=12.5
	var again:=SaveSystem._capture_reflected(DiscoverySystem,SaveSystem.REFLECT_SKIP.get("DiscoverySystem",[]))
	DiscoverySystem.learning_lead=0.0
	SaveSystem._apply_reflected(DiscoverySystem,again)
	assert_float(DiscoverySystem.learning_lead).is_equal(12.5)

# --- What one more learner does -----------------------------------------------------------

func test_the_learning_row_says_what_one_more_learner_adds_in_the_engines_numbers()->void:
	GameState.elapsed_days+=1.0
	DiscoverySystem.process_day({})
	var effect:=DiscoverySystem.role_effect("Knowledge",1.0)
	var learners:=float(effect.learners)
	assert_float(learners).is_greater(0.0)
	assert_float(float(effect.work_more)).is_greater(float(effect.work))
	assert_float(float(effect.pace_gain)).is_greater(0.0)
	assert_float(float(effect.goods_a_day)).is_equal_approx(learners/20.0,0.0001)
	assert_float(float(effect.goods_a_day_more)).is_equal_approx((learners+1.0)/20.0,0.0001)
	assert_float(float(effect.goods_factor)).is_equal_approx(1.0,0.0001)
	assert_float(float(effect.lead_rate_more)).is_greater(float(effect.lead_rate))
	assert_float(float(effect.sustainable_share)).is_equal_approx(DiscoverySystem.sustainable_learning_share(),0.0001)
	var ten:=DiscoverySystem.role_effect("Knowledge",10.0)
	assert_float(float(ten.pace_gain)).is_greater(float(effect.pace_gain)*5.0)
	assert_dict(DiscoverySystem.role_effect("Food")).is_empty()
	# The People view's rows read the same numbers.
	var said:=Impact.of("Knowledge")
	var labels:Array=[]
	for line:Dictionary in said.lines:labels.append(String(line.label))
	assert_array(labels).contains(["One more learner","Goods for the learners","Ahead of the calendar"])
	for line:Dictionary in said.lines:
		assert_bool(String(line.value).contains("%")).is_false()
		assert_bool(String(line.words).contains("%")).is_false()

# --- Every people -------------------------------------------------------------------------

func test_a_computer_people_learns_by_the_same_rules_in_its_own_scope()->void:
	WorldSimulation.create_actor("scholars",4242)
	var player_lead:=float(DiscoverySystem.learning_lead)
	WorldSimulation.scoped("scholars",func()->void:
		var state:=WorldSimulation.state
		state.resource_stockpiles[R.GOODS_KEY]=200.0
		state.population_allocations["Knowledge"]=roundi(float(state.able_population())/3.0)
		var learners:=float(state.effective_workers("Knowledge"))
		var before:=float(state.resource_stockpiles[R.GOODS_KEY])
		for day in 30:
			state.elapsed_days+=1.0
			WorldSimulation.discovery.process_day({})
		# Its own goods, its own lead.
		# (a little more as its lead grows: learning ahead of the age is dearer)
		assert_float(before-float(state.resource_stockpiles[R.GOODS_KEY])).is_between(learners*30.0/20.0,learners*30.0/20.0*1.01)
		assert_float(float(WorldSimulation.discovery.learning_lead)).is_greater(0.0)
		var teams:=WorldSimulation.discovery.research_teams()
		assert_float(float(teams.work)).is_equal_approx(R.team_capacity(float(teams.on_lines)),0.0001)
	)
	assert_float(float(DiscoverySystem.learning_lead)).is_equal(player_lead)

# --- Goods: makers, towns, steps ----------------------------------------------------------

const Goods:=preload("res://scripts/civilian_goods.gd")

## A settled place whose makers have raw materials for a long while.
func _makers_ready(state:Variant)->void:
	state.settlement_site_committed=true
	state.convoy_traveling=false
	for item:String in Goods.BASKET:state.resource_stockpiles[item]=5000.0
	state.population_allocations["Crafting"]=40

func test_makers_make_good_what_the_learners_take_and_the_report_shows_it()->void:
	_makers_ready(GameState)
	GameState.population_allocations["Crafting"]=150
	GameState.population_allocations["Knowledge"]=60
	var learners:=float(GameState.effective_workers("Knowledge"))
	GameState.resource_stockpiles[R.GOODS_KEY]=Goods.target()*1.2+learners/20.0
	for step in 5:
		GameState.elapsed_days+=1.0
		DiscoverySystem.process_day({})
		# The learners took a day's goods before the makers' day...
		assert_float(DiscoverySystem.learning_goods_cover()).is_equal_approx(1.0,0.0001)
		var report:=Goods.advance()
		var day_need:=R.goods_need(learners,1.0,DiscoverySystem.learning_lead)
		assert_float(float(report.learners)).is_equal_approx(day_need,0.001)
		# ...and the makers stock what households want and the learners' next day.
		assert_float(Goods.stock()).is_greater_equal(Goods.target()*1.2+day_need-Goods.target()*0.01)
	# The goods screen nets the learners' take out of the day's change.
	var card:Dictionary=preload("res://scripts/hud/content/dock_content_production.gd")._household_card()
	assert_float(float(card.learners)).is_equal_approx(R.goods_need(learners,1.0,DiscoverySystem.learning_lead),0.001)
	var story:=preload("res://scripts/hud/production_queue.gd").household_story(card)
	assert_str(String(story.pace)).contains("the learners take")

func test_a_ten_day_step_keeps_its_learners_in_goods()->void:
	WorldSimulation.create_actor("tenday",9191)
	WorldSimulation.actors.tenday["span"]=10
	WorldSimulation.scoped("tenday",func()->void:
		var state:=WorldSimulation.state
		assert_int(WorldSimulation.span).is_equal(10)
		_makers_ready(state)
		state.population_allocations["Knowledge"]=roundi(float(state.able_population())/4.0)
		state.resource_stockpiles[R.GOODS_KEY]=Goods.target()*1.2
		var covers:Array=[]
		for step in 6:
			state.elapsed_days+=10.0
			WorldSimulation.discovery.process_day({})
			covers.append(WorldSimulation.discovery.learning_goods_cover())
			Goods.advance()
		# After the first step the makers keep a whole step's goods for them.
		for index in range(1,covers.size()):assert_float(float(covers[index])).override_failure_message(str(covers)).is_greater(0.99)
	)

func test_learners_draw_from_the_towns_when_the_home_stores_are_short()->void:
	GameState.player_settlements.assign([{"id":"home","name":"Home","primary":true,"position":Vector2.ZERO,"population_share":0.5,"founded_day":0},
		{"id":"dawngate","name":"Dawngate","primary":false,"position":Vector2(10,0),"population_share":0.25,"founded_day":0},
		{"id":"riverbend","name":"Riverbend","primary":false,"position":Vector2(0,10),"population_share":0.25,"founded_day":0}])
	SettlementModel.with_city_resources("dawngate",func()->void:GameState.resource_stockpiles[R.GOODS_KEY]=30.0)
	SettlementModel.with_city_resources("riverbend",func()->void:GameState.resource_stockpiles[R.GOODS_KEY]=10.0)
	var learners:=float(GameState.effective_workers("Knowledge"))
	var need:=learners/20.0
	GameState.resource_stockpiles[R.GOODS_KEY]=need*0.25
	# The realm's goods, not only the capital's.
	assert_float(R.goods_held()).is_equal_approx(need*0.25+40.0,0.0001)
	GameState.elapsed_days+=1.0
	DiscoverySystem.process_day({})
	assert_float(DiscoverySystem.learning_goods_cover()).is_equal_approx(1.0,0.0001)
	assert_float(float(GameState.resource_stockpiles[R.GOODS_KEY])).is_equal_approx(0.0,0.0001)
	# The rest from the towns, three to one as they hold.
	var short:=need*0.75
	assert_float(float(SettlementModel.with_city_resources("dawngate",func()->float:return float(GameState.resource_stockpiles[R.GOODS_KEY])))).is_equal_approx(30.0-short*0.75,0.0001)
	assert_float(float(SettlementModel.with_city_resources("riverbend",func()->float:return float(GameState.resource_stockpiles[R.GOODS_KEY])))).is_equal_approx(10.0-short*0.25,0.0001)
	# Each town's makers are told what the learners took there.
	var told:Dictionary=SettlementModel.with_city_resources("dawngate",func()->Dictionary:return R.learners_goods())
	assert_float(float(told.taken)).is_equal_approx(short*0.75,0.0001)
	assert_float(float(told.wanted)).is_equal_approx(short*0.75,0.0001)
	assert_float(float(R.learners_goods().wanted)).is_equal_approx(need,0.0001)
	# With every store empty, learning goes at half pace.
	SettlementModel.with_city_resources("dawngate",func()->void:GameState.resource_stockpiles[R.GOODS_KEY]=0.0)
	SettlementModel.with_city_resources("riverbend",func()->void:GameState.resource_stockpiles[R.GOODS_KEY]=0.0)
	GameState.elapsed_days+=1.0
	DiscoverySystem.process_day({})
	assert_float(DiscoverySystem.learning_goods_cover()).is_equal(0.0)

func test_no_lead_without_research_lines_followed()->void:
	GameState.population_allocations["Knowledge"]=roundi(float(GameState.able_population())/3.0)
	for line:Variant in GameState.research_subcategory_allocations:
		var subs:Dictionary=GameState.research_subcategory_allocations[line]
		for sub:Variant in subs:subs[sub]=0
	DiscoverySystem._rebuild_research_domain_totals()
	assert_float(float(DiscoverySystem.research_teams().on_lines)).is_equal(0.0)
	DiscoverySystem.learning_lead=0.0
	for day in 60:
		GameState.elapsed_days+=1.0
		DiscoverySystem.process_day({})
	# Many learners, but no learning done: no lead.
	assert_float(float(DiscoverySystem.learning_lead)).is_equal(0.0)

func test_what_the_economy_can_spare_reads_its_real_age_never_the_lead()->void:
	var model=DiscoverySystem.society_model
	var known:Array[String]=[]
	for entry:Dictionary in DiscoverySystem.technology_catalog:
		if DiscoverySystem.research_600_earliest_year(entry)<300.0:known.append(String(entry.id))
	GameState.known_discoveries.assign(known)
	GameState.population_allocations["Knowledge"]=roundi(float(GameState.able_population())/3.0)
	DiscoverySystem.learning_lead=0.0
	model._rebuild_effect_totals(DiscoverySystem.catalog)
	var excess:=float(model.specialist_excess)
	var spare:=DiscoverySystem.sustainable_learning_share()
	var artifacts:=preload("res://scripts/artifact_collection.gd").era_bonus_cap()
	assert_float(excess).is_greater(0.0)
	# A lead of two centuries moves the payoffs, never what the economy can spare.
	DiscoverySystem.learning_lead=200.0
	model._rebuild_effect_totals(DiscoverySystem.catalog)
	assert_float(float(model.ceiling_era)).is_greater(float(model.economy_era())+100.0)
	assert_float(float(model.economy_era())).is_equal_approx(float(GameState.elapsed_days)/365.0,0.01)
	assert_float(float(model.specialist_excess)).is_equal_approx(excess,0.000001)
	assert_float(DiscoverySystem.sustainable_learning_share()).is_equal_approx(spare,0.000001)
	# The lead itself is paid for: the extra learners' upkeep grows with it.
	assert_float(float(model.specialist_burden)).is_equal_approx(1.0+200.0/R.LEAD_UPKEEP_YEARS,0.000001)
	assert_float(preload("res://scripts/artifact_collection.gd").era_bonus_cap()).is_equal_approx(artifacts,0.000001)
	# Foundations to start now are read from the people's own age.
	var source:=FileAccess.get_file_as_string("res://scripts/research_foundations.gd")
	assert_str(source).contains("discovery.learning_year()")

func test_a_lead_is_paid_for_in_the_extra_learners_upkeep()->void:
	var model=DiscoverySystem.society_model
	GameState.population_allocations["Knowledge"]=roundi(float(GameState.able_population())/3.0)
	DiscoverySystem.learning_lead=0.0
	model._rebuild_effect_totals(DiscoverySystem.catalog)
	var births:=float(model.effect("conception_support"))
	var work:=float(model.effect("labor_demand"))
	assert_float(float(model.specialist_burden)).is_equal(1.0)
	DiscoverySystem.learning_lead=R.LEAD_UPKEEP_YEARS*0.5
	model._rebuild_effect_totals(DiscoverySystem.catalog)
	assert_float(float(model.specialist_burden)).is_equal_approx(1.5,0.000001)
	assert_float(float(model.effect("conception_support"))).is_less(births)
	assert_float(float(model.effect("labor_demand"))).is_greater_equal(work)

# --- The first ways come at a village's pace (2026-10-02 recalibration) -------------

## A young people learns slowly: through its first FOUNDING_HOLD_YEARS years
## every question asks FOUNDING_WORK times the work, whatever the question's
## age, back to the usual work by FOUNDING_FADE_YEARS. Per learner the engine
## had not changed (a fresh village with 3 learners: 110 ways by year 16 on
## main, 106 before the overhaul), but a balanced village learned some 76 ways
## in 16 years; now about 45.
func test_the_first_ways_come_at_a_village_pace()->void:
	assert_float(R.founding_work(0.0)).is_equal_approx(R.FOUNDING_WORK,0.0001)
	assert_float(R.founding_work(R.FOUNDING_HOLD_YEARS)).is_equal_approx(R.FOUNDING_WORK,0.0001)
	assert_float(R.founding_work((R.FOUNDING_HOLD_YEARS+R.FOUNDING_FADE_YEARS)*0.5)).is_equal_approx((R.FOUNDING_WORK+1.0)*0.5,0.0001)
	assert_float(R.founding_work(R.FOUNDING_FADE_YEARS)).is_equal(1.0)
	assert_float(R.founding_work(300.0)).is_equal(1.0)
	assert_float(R.FOUNDING_WORK).is_greater(1.4)
	# The questions' own pace is the one it always was.
	assert_float(R.pace_for(0.0)).is_equal_approx(7.0,0.0001)
	assert_float(R.pace_for(200.0)).is_equal_approx(2.4,0.0001)
	# It reads the people's own age: a young people pays it on a question of
	# any age, a people a generation old on none, though it lag far behind.
	var old_question:={"id":"founding_test_old","name":"Old","dynamic":"culture","subcategory":"Social cohesion","earliest_year":0.0,"signals":[]}
	DiscoverySystem.learning_lead=0.0
	GameState.elapsed_days=5.0*365.0
	var young:=float(DiscoverySystem.research_difficulty(old_question,GameState.world_seed))
	GameState.elapsed_days=float(int(R.FOUNDING_FADE_YEARS)*365+365)
	var grown:=float(DiscoverySystem.research_difficulty(old_question,GameState.world_seed))
	assert_float(young/grown).is_equal_approx(R.FOUNDING_WORK,0.01)
	# The share the age can spare stays 4 in 100 at the founding: a lead never
	# makes learning cheaper for the people who press it.
	assert_float(Society._rise(Society.SUSTAINABLE_SPECIALISTS,0.0)).is_equal_approx(0.04,0.0001)
	assert_float(R.LEAD_YEARS_PER_DOUBLING).is_equal_approx(0.06,0.0001)
	# More learners still give more work: no cap.
	assert_float(R.team_capacity(8.0)).is_greater(R.team_capacity(2.0)*3.5)

## The research pages say a young people learns slowly, with the engine's own
## number at the people's own age, beside each question's clock; nothing once
## it learns at the usual pace.
func test_the_research_pages_say_a_young_people_learns_slowly()->void:
	DiscoverySystem.learning_lead=0.0
	GameState.elapsed_days=5.0*365.0
	assert_str(DiscoverySystem.founding_words()).is_equal("A young people learns slowly: every question takes 2.2 times the work until year 15, easing to normal by year 30.")
	# Easing: the number now.
	GameState.elapsed_days=22.5*365.0
	var easing:=DiscoverySystem.founding_words()
	assert_str(easing).starts_with("A young people learns slowly: every question takes %s times the work now" % ("%.1f" % R.founding_work(22.5)))
	assert_str(easing).ends_with("easing to normal by year 30.")
	# Back to the usual pace: nothing said.
	GameState.elapsed_days=31.0*365.0
	assert_str(DiscoverySystem.founding_words()).is_empty()
	# On the cards: each question's record carries it and its tip says it.
	GameState.elapsed_days=5.0*365.0
	DiscoverySystem.refresh_investigations()
	var records:=DiscoverySystem.active_investigation_records()
	assert_int(records.size()).is_greater(0)
	for record:Dictionary in records:
		assert_str(String(record.founding_note)).is_equal(DiscoverySystem.founding_words())
	var words:Dictionary=preload("res://scripts/hud/inquiry_board.gd")._card_words(records[0])
	assert_str(String(words.tooltip)).contains("A young people learns slowly")
	var grown:Dictionary=records[0].duplicate(true)
	grown["founding_note"]=""
	assert_str(String(preload("res://scripts/hud/inquiry_board.gd")._card_words(grown).tooltip)).not_contains("young people")
