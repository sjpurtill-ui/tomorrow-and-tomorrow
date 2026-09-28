extends GdUnitTestSuite
## Small changes are said in the unit that shows them, never "+0.0".
##
## The player: "when i discover things life expectancy is affected by 0.0 all
## the time." A new practice spreads over years, so the month it arrives adds
## days or weeks of life; one decimal of a year printed "+0.0 years". The same
## rounding printed tiny discovery effects as "+0.0%".

const EraWords:=preload("res://scripts/hud/era_words.gd")
const Discovery:=preload("res://scripts/discovery_system.gd")

var known_before:Array[String]=[]

func before_test()->void:
	known_before=GameState.known_discoveries.duplicate()

func after_test()->void:
	GameState.known_discoveries.clear();GameState.known_discoveries.append_array(known_before)

func test_a_small_change_in_life_is_days_weeks_or_months()->void:
	assert_str(EraWords.life_change(0.0)).is_equal("less than a day")
	assert_str(EraWords.life_change(0.001)).is_equal("less than a day")
	assert_str(EraWords.life_change(0.01)).is_equal("+4 days")
	assert_str(EraWords.life_change(1.2/365.25)).is_equal("+1 day")
	assert_str(EraWords.life_change(0.05)).is_equal("+3 weeks")
	assert_str(EraWords.life_change(-0.1)).is_equal("-5 weeks")
	assert_str(EraWords.life_change(0.25)).is_equal("+3 months")
	assert_str(EraWords.life_change(-0.5)).is_equal("-6 months")
	for delta in [0.0,0.004,0.02,0.07,0.3,-0.02]:
		assert_str(EraWords.life_change(delta)).override_failure_message("%s reads %s" % [delta,EraWords.life_change(delta)]).not_contains("0.0")

func test_years_are_said_in_the_age_s_own_words()->void:
	GameState.known_discoveries.clear()
	assert_str(EraWords.life_change(3.0)).is_equal("+3 winters")
	GameState.known_discoveries.append("printing_process")
	assert_str(EraWords.life_change(3.0)).is_equal("+3.0 years")
	assert_str(EraWords.life_change(-2.5)).is_equal("-2.5 years")

func test_a_tiny_discovery_effect_is_never_plus_zero_percent()->void:
	assert_str(Discovery.effect_percent(0.012)).is_equal("+1.2%")
	assert_str(Discovery.effect_percent(-0.004)).is_equal("-0.4%")
	assert_str(Discovery.effect_percent(0.0003)).is_equal("+0.03%")
	assert_str(Discovery.effect_percent(-0.0002)).is_equal("-0.02%")
	assert_str(Discovery.effect_percent(0.00001)).is_equal("+<0.01%")
	var text:=DiscoverySystem._effect_summary({"health_protection":0.0003,"food_output":0.012})
	assert_str(text).not_contains("+0.0%")
	assert_str(text).contains("+0.03%")
