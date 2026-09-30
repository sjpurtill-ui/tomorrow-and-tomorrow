extends GdUnitTestSuite
## THE WAR LEADER'S STATED ODDS (army_orders.stated_odds): before an attack
## the preview gives the odds by the combat engine's own reading: our band as
## it stands against the men counted there, assumed armed as we are, behind
## the walls our scouts saw. The assumption is said in the words.

const Orders:=preload("res://scripts/army_orders.gd")

func before_test()->void:
	WorldSimulation.clear();GameState.reset_for_new_world(7070);MilitaryCampaign.reset_for_new_world()
	MilitaryCampaign.home_army=MilitaryCampaign._empty_home_army()

func after_test()->void:
	WorldSimulation.clear()

func _band(men:int,morale:float=1.0)->Dictionary:
	var sim=MilitaryCampaign.simulator
	var formations:=[{"id":1,"unit":"spearman","weapon":"spear","count":men,"authorized_count":men,"equipment":men,"equipment_required":men,"training":0.8}]
	var force:Dictionary=sim.create_formation_force("Band",formations,morale,1.0)
	return force

func test_numbers_walls_and_heart_set_the_odds()->void:
	var band:=_band(200)
	var even:=Orders.stated_odds(band,band.formations,200,200.0,0.0)
	assert_str(Orders.odds_words(float(even.odds),bool(even.ours))).is_equal("about even")
	var strong:=Orders.stated_odds(band,band.formations,200,80.0,0.0)
	assert_bool(bool(strong.ours)).is_true()
	assert_float(float(strong.odds)).is_greater(2.0)
	var weak:=Orders.stated_odds(band,band.formations,200,500.0,0.0)
	assert_bool(bool(weak.ours)).is_false()
	assert_str(Orders.odds_words(float(weak.odds),false)).contains("against us")
	# Walls count for them; a shaken band counts for less.
	var walled:=Orders.stated_odds(band,band.formations,200,150.0,1.0)
	var open:=Orders.stated_odds(band,band.formations,200,150.0,0.0)
	assert_float(float(walled.odds)).is_less(float(open.odds))
	var shaken:=_band(200,0.4)
	var tired:=Orders.stated_odds(shaken,shaken.formations,200,150.0,0.0)
	assert_float(float(tired.odds)).is_less(float(open.odds))

func test_the_words_are_plain_fractions()->void:
	assert_str(Orders.odds_words(1.5,true)).is_equal("about 3 to 2 for us")
	assert_str(Orders.odds_words(2.0,false)).is_equal("about 2 to 1 against us")
	assert_str(Orders.odds_words(9.0,true)).is_equal("about more than 5 to 1 for us")
	assert_str(Orders.summary({"ready":true,"likely":"act","men":200,"odds":{"odds":1.5,"ours":true}})).contains("odds 3:2")
	assert_str(Orders.odds_short(2.0,false)).is_equal("1:2")
	assert_str(Orders.odds_short(1.05,true)).is_equal("even")
