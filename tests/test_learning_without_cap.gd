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
	for population:float in [4000.0,40000.0,400000.0]:
		var ratio:=R.team_capacity(200.0,population)/R.team_capacity(100.0,population)
		assert_float(ratio).override_failure_message("200 against 100 in %d: %.3f" % [int(population),ratio]).is_between(1.8,2.0)
	# The older knee gave 200 learners barely more than 100 (about 1.1 times).
	assert_float(_knee(200.0)/_knee(100.0)).is_less(1.15)
	# Every doubling adds about as much as the last, far past twelve.
	var small:=R.team_capacity(24.0)/R.team_capacity(12.0)
	var large:=R.team_capacity(2000.0)/R.team_capacity(1000.0)
	assert_float(small).is_greater(1.75)
	assert_float(large).is_greater(1.8)
	# Ten times the learners, about seven and a half times the work: never a cap.
	assert_float(R.team_capacity(1000.0,4000.0)/R.team_capacity(100.0,4000.0)).is_between(7.0,8.5)

func test_one_question_gets_a_little_less_from_each_more_person()->void:
	assert_float(R.team_strength(0.5)).is_equal_approx(0.5,0.0001)
	assert_float(R.team_strength(1.0)).is_equal_approx(1.0,0.0001)
	assert_float(R.team_strength(10.0)).is_equal_approx(pow(10.0,R.QUESTION_EXPONENT),0.0001)
	assert_float(R.team_strength(20.0)/R.team_strength(10.0)).is_between(1.75,1.85)
	assert_float(R.team_strength(1.0e6)).is_greater(R.team_strength(1.0e5)*6.0)

func test_a_people_at_the_normal_share_keeps_the_pace_its_questions_were_measured_against()->void:
	for population:float in [120.0,1000.0,4000.0,50000.0,1.0e6]:
		var normal:=population*R.NORMAL_RESEARCH_SHARE
		assert_float(R.team_capacity(normal,population)).override_failure_message("normal share of %d" % int(population)).is_equal_approx(_knee(normal),0.0001)
	# A band's learners each count in full, as they always did.
	assert_float(R.team_capacity(3.0,120.0)).is_equal_approx(3.0,0.0001)
	# Fewer learners than the normal share do less: learning is a choice.
	assert_float(R.team_capacity(25.0,4000.0)).is_less(_knee(25.0)*0.6)

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
	var learners:=float(GameState.effective_workers("Knowledge"))
	assert_float(learners).is_greater(0.0)
	# One goods-unit keeps a learner twenty days; the day's goods leave the stores.
	assert_float(R.goods_need(learners)).is_equal_approx(learners/20.0,0.0001)
	var before:=float(GameState.resource_stockpiles[R.GOODS_KEY])
	GameState.elapsed_days+=1.0
	DiscoverySystem.process_day({})
	assert_float(before-float(GameState.resource_stockpiles[R.GOODS_KEY])).is_equal_approx(learners/20.0,0.0001)
	assert_float(DiscoverySystem.learning_goods_cover()).is_equal_approx(1.0,0.0001)
	var channel:=String(GameState.active_investigations.keys()[0])
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
	assert_float(gained).is_greater(0.05)
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
		assert_float(before-float(state.resource_stockpiles[R.GOODS_KEY])).is_equal_approx(learners*30.0/20.0,0.01)
		assert_float(float(WorldSimulation.discovery.learning_lead)).is_greater(0.0)
		var teams:=WorldSimulation.discovery.research_teams()
		assert_float(float(teams.work)).is_equal_approx(R.team_capacity(float(teams.on_lines),float(state.population_exact)),0.0001)
	)
	assert_float(float(DiscoverySystem.learning_lead)).is_equal(player_lead)
