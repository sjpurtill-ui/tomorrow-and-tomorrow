extends GdUnitTestSuite
## WHAT A BAND DESIGN DOES (hud/deployment_model.template_stats): the engine's
## own numbers on each template card, like HOI4's division designer without
## the width puzzle; and a line's later bands join the band it raised before
## while that band is at home.

const Model:=preload("res://scripts/hud/deployment_model.gd")

func before_test()->void:
	WorldSimulation.clear();GameState.reset_for_new_world(808);MilitaryCampaign.reset_for_new_world()
	GameState.settlement_site_committed=true;GameState.settlement_founded_at=Vector3.ZERO
	MilitaryCampaign.home_army=MilitaryCampaign._empty_home_army()

func after_test()->void:
	WorldSimulation.clear()

func test_a_design_states_strength_march_supply_and_training()->void:
	var spears:=Model.template_stats(MilitaryCampaign,[{"unit":"spearman","weapon":"spear","count":100}])
	var tanks:=Model.template_stats(MilitaryCampaign,[{"unit":"armored_formation","weapon":"armored_vehicle","count":100}])
	assert_float(float(tanks.strength)).is_greater(float(spears.strength)*3.0)
	assert_float(float(spears.loads_man)).is_between(1.0,1.3)
	assert_float(float(tanks.loads_man)).is_greater(20.0)
	assert_float(float(tanks.hard)).is_greater(0.9)
	assert_float(float(spears.hard)).is_equal(0.0)
	assert_float(float(spears.days)).is_greater(0.0)
	assert_float(float(spears.reinforce_days)).is_less(float(spears.days))
	var said:Array=Model.stats_words(tanks)
	assert_str(String(said[0])).contains("Strength")
	assert_str(String(said[1])).contains("loads a man a day")

func test_machines_are_named_on_the_card()->void:
	var frames:=Model.template_stats(MilitaryCampaign,[{"unit":"combat_frame_cohort","weapon":"combat_frame","count":10}])
	assert_int(int(frames.machines)).is_equal(80)
	assert_str(String(Model.stats_words(frames)[1])).contains("Machines: 80")

func test_an_empty_design_says_nothing()->void:
	assert_dict(Model.template_stats(MilitaryCampaign,[])).is_empty()
	assert_str(String(Model.stats_words({})[0])).is_empty()
