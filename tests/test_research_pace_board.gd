extends GdUnitTestSuite
## The Research board's header: how fast the people learn against a typical
## people of their age, the single biggest limiter in plain words, and every
## input as an icon with the engine's numbers.
const Board:=preload("res://scripts/hud/inquiry_board.gd")
const Inquiry:=preload("res://scripts/hud/content/dock_content_inquiry.gd")
const R:=preload("res://scripts/research_600_catalog.gd")

func _pace(extra:Dictionary={})->Dictionary:
	var pace:={"learners":70.0,"heads":72.0,"able":400.0,"teams":10,"on_lines":70.0,"work":50.0,"typical":16.0,"typical_work":14.6,"sustainable":0.04,"ratio":50.0/14.6,
		"goods_need":4.2,"goods_cover":1.0,"goods_factor":1.0,"goods_held":2300.0,"goods_per_learner":0.06,"lead":13.0,"lead_rate":0.12,"year":142.0,
		"founding":1.0,"founding_words":"","support":1.6,"education":0.8,"food_security":0.9,"pay":1.12,"gifted":[],"gifted_lift":0.0,"abroad":0,"taught":[],
		"craft":1.04,"studying":false,"questions":10,"proofs":4.2,"work_factor":1.0,"offices":1.0,"earliest":0.0,"furthest":0.0,"thin":0,"lacking":[]}
	pace.merge(extra,true)
	return pace

func test_the_header_states_the_pace_against_a_typical_people()->void:
	var words:=Board.pace_words(_pace())
	assert_str(String(words.value)).is_equal("3.4 times")
	assert_str(String(words.words)).contains("typical people our age").contains("70 learners").contains("about 16")
	assert_str(String(words.proofs)).contains("about 4.2 questions proven a year")
	assert_str(String(words.limiter)).starts_with("Nothing holds the learning back much")
	var kinds:Array=(words.chips as Array).map(func(c:Dictionary)->String:return String(c.kind))
	assert_array(kinds).contains_exactly(["learners","goods","lead","support","pay","gifted","teachers","craft"])

func test_short_goods_show_in_red_and_name_the_limit()->void:
	var words:=Board.pace_words(_pace({"goods_cover":0.6,"goods_factor":R.goods_factor(0.6)}))
	var goods:Dictionary=(words.chips as Array).filter(func(c:Dictionary)->bool:return c.kind=="goods")[0]
	assert_str(String(goods.tone)).is_equal("bad")
	assert_str(String(goods.value)).is_equal("4.2 goods a day")
	assert_str(String(goods.label)).is_equal("only 2.5 given, 1.7 short")
	assert_str(String(words.limiter)).starts_with("Short of goods").contains("60 in 100").contains("80 in 100")
	assert_str(String(Board.limiter(_pace({"goods_cover":0.6,"goods_factor":R.goods_factor(0.6)})).kind)).is_equal("goods")

func test_the_biggest_limiter_wins()->void:
	# Working far ahead costs more than a small goods shortfall.
	var ahead:=Board.limiter(_pace({"work_factor":15.0,"earliest":50.0,"furthest":95.0,"goods_cover":0.9,"goods_factor":R.goods_factor(0.9)}))
	assert_str(String(ahead.kind)).is_equal("ahead")
	assert_str(String(ahead.text)).contains("50 to 95 years early").contains("15 times")
	var young:=Board.limiter(_pace({"founding":2.2,"founding_words":"A young people learns slowly: every question takes 2.2 times the work until year 15, easing to normal by year 30."}))
	assert_str(String(young.kind)).is_equal("young")
	var few:=Board.limiter(_pace({"work":5.0,"ratio":5.0/14.6}))
	assert_str(String(few.kind)).is_equal("few")
	assert_str(String(Board.limiter(_pace({"learners":0.0})).kind)).is_equal("none")
	assert_str(String(Board.limiter(_pace({"studying":true})).kind)).is_equal("artifacts")

func test_waiting_lines_name_what_they_lack()->void:
	assert_array(Inquiry.materials_lacking(["Knowledge of Stone","Copper Ore: surveyed access or 2.0 in stores","A population of at least 300"])).contains_exactly(["Stone","Copper Ore"])
	var lane:={"slots":[],"field":{"share":0.1},"waiting":[
		{"line":"Tool quality","kind":"gate","lacks":["Stone"],"reason":"Needs knowledge of Stone (next: Ground Stone Axes)"},
		{"line":"Material supply","kind":"ahead","years":68.0,"reason":"Its next question is 68 years ahead."}]}
	var words:=Board._waiting_words(lane)
	assert_str(String(words.text)).is_equal("Tool quality lacks stone · Material supply: next question 68 years ahead")
	assert_bool(bool(words.lacking)).is_true()
	assert_str(String(words.tip)).contains("Needs knowledge of Stone")

func test_the_engine_reading_feeds_the_header()->void:
	GameState.reset_for_new_world(991704)
	GameState.initialize_population_model();GameState.ensure_population_total(400)
	GameState.synchronize_population_allocations()
	DiscoverySystem.reset_for_new_world();DiscoverySystem.initialize()
	GameState.elapsed_days=float(365*11)
	var records:=DiscoverySystem.active_investigation_records()
	var pace:=Inquiry.learning_pace(records)
	var effect:=DiscoverySystem.role_effect("Knowledge",1.0)
	assert_float(float(pace.learners)).is_equal_approx(float(effect.learners),0.0001)
	assert_float(float(pace.goods_need)).is_equal_approx(float(effect.goods_a_day),0.0001)
	assert_float(float(pace.founding)).is_equal_approx(R.founding_work(DiscoverySystem.learning_year()),0.0001)
	assert_int(int(pace.questions)).is_equal(records.size())
	var words:=Board.pace_words(pace)
	assert_str(String(words.limiter)).is_not_empty()
	# Young at year 11: the founding work is named.
	assert_array((words.chips as Array).map(func(c:Dictionary)->String:return String(c.kind))).contains(["young"])
	for chip:Dictionary in words.chips:assert_str(String(chip.tip)).is_not_empty()
	# Each staffed line without a question says why it waits.
	var waiting:=Inquiry.waiting_lines()
	for channel:String in waiting:
		assert_str(String(waiting[channel].reason)).is_not_empty()
		assert_str(String(waiting[channel].kind)).is_not_empty()
