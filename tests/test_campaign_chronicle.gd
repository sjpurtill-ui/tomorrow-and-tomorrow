extends GdUnitTestSuite
const Chronicle=preload("res://scripts/campaign_chronicle.gd")
func test_sparse_centuries_do_not_fabricate_observed_prosperity()->void:
	var model=Chronicle.new()
	model.observe(0,{"healthy":true,"population":200})
	model.observe(1000*365,{"healthy":true,"population":300})
	assert_int(model.data.healthy_days).is_equal(30)
	assert_bool(model.snapshot(1000*365).review_available).is_false()
func test_distress_recovers_and_legacy_stays_available_without_terminal_race()->void:
	var model=Chronicle.new()
	model.observe(0,{"population":200})
	model.observe(30,{"population":100,"crisis":true})
	model.observe(60,{"population":110,"healthy":true})
	assert_int(model.data.recoveries).is_equal(1)
	assert_bool(model.reckon(1000*365).has("error")).is_true()
	assert_bool(model.reckon(2500*365).has("ok")).is_true()
	model.observe(3001*365,{"population":500,"institutions":true})
	assert_int(model.data.latest.population).is_equal(500)
func test_millennial_history_is_bounded_but_developments_persist()->void:
	var model=Chronicle.new()
	for century in 40:
		model.observe(century*36500,{"population":200+century,"settlement":true,"learning":century>2,"institutions":century>8})
	assert_int(model.data.chapters.size()).is_less_equal(40)
	assert_int(model.data.milestones.size()).is_equal(3)
	var restored=Chronicle.new();restored.restore(JSON.parse_string(JSON.stringify(model.data)))
	assert_dict(JSON.parse_string(JSON.stringify(restored.snapshot(4000*365)))).is_equal(JSON.parse_string(JSON.stringify(model.snapshot(4000*365))))
