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
	assert_str(Orders.odds_words(9.0,true)).is_equal("more than 5 to 1 for us")
	assert_str(Orders.summary({"ready":true,"likely":"act","men":200,"odds":{"odds":1.5,"ours":true}})).contains("odds 3:2")
	assert_str(Orders.odds_short(2.0,false)).is_equal("1:2")
	assert_str(Orders.odds_short(1.05,true)).is_equal("even")

func test_the_arms_our_scouts_saw_set_the_odds_and_are_said()->void:
	var band:=_band(200)
	# Their pikes and bows against our spears, the same number of men.
	var theirs:=[{"unit":"pikeman","weapon":"pike","count":150,"authorized_count":150,"equipment":150,"equipment_required":150,"training":0.7},
		{"unit":"archer","weapon":"bow","count":50,"authorized_count":50,"equipment":50,"equipment_required":50,"training":0.7}]
	var as_us:=Orders.stated_odds(band,band.formations,200,200.0,0.0)
	var seen:=Orders.stated_odds(band,band.formations,200,200.0,0.0,theirs)
	assert_float(absf(float(seen.odds)-float(as_us.odds))+(0.0 if bool(seen.ours)==bool(as_us.ours) else 1.0)).is_greater(0.001)
	assert_str(Orders.arms_words(theirs)).is_equal("mostly pikes and some bows")
	assert_str(Orders.arms_words([{"weapon":"lance","count":5},{"weapon":"spear","count":80},{"weapon":"bow","count":15}])).is_equal("mostly spears, some bows and a few horses and lances")
	# Our own army, grouped as a rival's scouts would see it.
	MilitaryCampaign.home_army=band
	var grouped:=preload("res://scripts/civilization_strategy.gd").grouped_arms(MilitaryCampaign)
	assert_int(grouped.size()).is_equal(1)
	assert_int(int(grouped[0].count)).is_equal(200)
	# Nobody saw them lately: no arms, and the odds assume ours.
	assert_array(Orders._their_arms("nobody",200)).is_empty()

func test_a_raw_levy_is_not_told_it_is_favoured()->void:
	# 200 barely drilled against 120 counted: the garrison is reckoned drilled
	# as a garrison is, not as raw as we are.
	var sim=MilitaryCampaign.simulator
	var raw:=[{"id":1,"unit":"spearman","weapon":"spear","count":200,"authorized_count":200,"equipment":200,"equipment_required":200,"training":0.1}]
	var band:Dictionary=sim.create_formation_force("Band",raw,1.0,1.0)
	var odds:=Orders.stated_odds(band,band.formations,200,120.0,0.0)
	# Their better drill counts against us: less than the bare 200 to 120.
	assert_float(float(odds.raw)).is_less(200.0/120.0)
	var drilled:=_band(200)
	assert_float(float(Orders.stated_odds(drilled,drilled.formations,200,120.0,0.0).raw)).is_greater(float(odds.raw))
	# The raw figure is ours over theirs; the war leader objects below 0.8.
	var weak:=Orders.stated_odds(drilled,drilled.formations,200,600.0,0.0)
	assert_bool(preload("res://scripts/war_odds.gd").weaker(weak)).is_true()
	assert_bool(preload("res://scripts/war_odds.gd").weaker(Orders.stated_odds(drilled,drilled.formations,200,100.0,0.0))).is_false()
