extends GdUnitTestSuite
## Raising a levy at court (home_orders.gd): every part of the order is done.
## The user said "Raise an army of five levies and train them and arm them."
## and the court only put five spears in hand: the words named arming, and
## arming was read first and alone. Now:
## - new fighters called up are drilled at once and armed, whether or not the
##   words say so ("recruit 20 warriors" is a levy, not idle hands);
## - the weapons they lack are put in hand, and only those: what is in store
##   or already being made for nobody else is counted first;
## - words that only drill ("train the recruits") drill those waiting, and
##   with nobody waiting, those under arms at home go to camp drill;
## - arming alone ("arm the recruits", "make twenty spears") stays arming, and
##   look-alikes are not a levy ("levy a tax", "draft a law", "recruit a
##   scout", "raise the wall", a band's drill before a march, a question).
## Offline; never calls a real API.

const HomeOrders:=preload("res://scripts/home_orders.gd")
const CC:=preload("res://scripts/court_commands.gd")
const Fixtures:=preload("res://tests/court_eval/fixtures.gd")

const USER_LINE:="Raise an army of five levies and train them and arm them."


func before_test()->void:
	Fixtures.new(self).base(false)


func _weapon_jobs(item:String)->int:
	var n:=0
	for job in MilitaryCampaign.equipment_queue:
		if String((job as Dictionary).get("item",""))==item and not bool((job as Dictionary).get("persistent",false)):n+=int(job.get("count",0))
	return n


func test_the_users_words_are_a_whole_levy()->void:
	var reading:=HomeOrders.read(USER_LINE)
	assert_str(String(reading.get("kind",""))).is_equal("levy")
	assert_int(int(reading.count)).is_equal(5)
	assert_bool(bool(reading.recruit)).is_true()
	assert_bool(bool(reading.arm_said)).is_true()
	for said in ["recruit train and arm 5 levies","Recruit, train and arm five levies","Recruit 20 more warriors","Raise thirty new fighters","Call up fifteen more men to fight","levy twelve men for the band"]:
		var r:=HomeOrders.read(said)
		assert_str(String(r.get("kind",""))).override_failure_message("'%s' was not read as a levy: %s" % [said,str(r)]).is_equal("levy")
		assert_bool(bool(r.get("recruit",false))).override_failure_message("'%s' did not call anyone up" % said).is_true()
	var drill:=HomeOrders.read("Train the recruits")
	assert_str(String(drill.get("kind",""))).is_equal("levy")
	assert_bool(bool(drill.recruit)).is_false()
	var archers:=HomeOrders.read("Recruit ten archers")
	assert_str(String(archers.get("unit",""))).is_equal("archer")
	assert_str(String(archers.get("item",""))).is_equal("bow")


func test_arming_alone_stays_arming_and_look_alikes_are_not_a_levy()->void:
	assert_str(String(HomeOrders.read("Arm the recruits").get("kind",""))).is_equal("arm")
	assert_str(String(HomeOrders.read("Make twenty spears").get("kind",""))).is_equal("arm")
	for said in ["levy a tax on the harvest","draft a law against theft","recruit a scout for the western trail","raise the wall higher","let the band finish its drill first","how many recruits are waiting?","Attack Tsaren with twenty warriors"]:
		assert_str(String(HomeOrders.read(said).get("kind",""))).override_failure_message("'%s' was read as a levy" % said).is_not_equal("levy")


func test_a_levy_is_called_up_drilled_and_armed_with_only_what_is_missing()->void:
	var waiting_before:=MilitaryCampaign.aggregate_recruits
	var drills_before:=MilitaryCampaign.training_queue.size()
	var done:=HomeOrders.perform(HomeOrders.read(USER_LINE))
	assert_bool(bool(done.ok)).is_true()
	assert_int(int(done.raised)).is_equal(5)
	assert_int(int(done.drilling)).is_equal(5)
	# The five called up went straight into drill: nobody new is left waiting.
	assert_int(MilitaryCampaign.aggregate_recruits).is_equal(waiting_before)
	assert_int(MilitaryCampaign.training_queue.size()).is_equal(drills_before+1)
	var order:Dictionary=MilitaryCampaign.training_queue.back()
	assert_int(int(order.count)).is_equal(5)
	assert_str(String(order.unit)).is_equal("levy")
	# Their weapons: exactly what they lack is put in hand.
	var weapon:=String(order.weapon)
	var need:int=MilitaryCampaign._equipment_required_for("levy",5)
	assert_int(int(done.made)).is_equal(need)
	assert_int(_weapon_jobs(weapon)).is_equal(need)
	var says:=String(done.says)
	assert_str(says).contains("called up")
	assert_str(says).contains("drill")
	assert_str(says).contains("workshops will make")
	assert_str(String(done.outcome)).contains("begin drill")


func test_weapons_in_store_or_in_the_making_are_counted_first()->void:
	MilitaryCampaign.military_inventory["improvised"]=3
	MilitaryCampaign.military_inventory["spear"]=3
	var done:=HomeOrders.perform(HomeOrders.read("Recruit 5 levies"))
	var order:Dictionary=MilitaryCampaign.training_queue.back()
	var weapon:=String(order.weapon)
	var need:int=MilitaryCampaign._equipment_required_for("levy",5)
	assert_int(int(done.made)).is_equal(need-3)
	# A second levy counts the first one's claim on the store and the work.
	var jobs:=_weapon_jobs(weapon)
	var again:=HomeOrders.perform(HomeOrders.read("Recruit 2 levies"))
	assert_int(int(again.made)).is_equal(MilitaryCampaign._equipment_required_for("levy",2))
	assert_int(_weapon_jobs(weapon)).is_equal(jobs+int(again.made))
	# Enough in store: nothing is made.
	MilitaryCampaign.military_inventory[weapon]=int(MilitaryCampaign.military_inventory.get(weapon,0))+40
	var stocked:=HomeOrders.perform(HomeOrders.read("Recruit 4 levies"))
	assert_int(int(stocked.made)).is_equal(0)
	assert_str(String(stocked.says)).contains("for them")


func test_a_drill_order_drills_those_waiting()->void:
	MilitaryCampaign.raise_recruits(7)
	var waiting:=MilitaryCampaign.aggregate_recruits
	assert_int(waiting).is_equal(7)
	var done:=HomeOrders.perform(HomeOrders.read("Train the recruits"))
	assert_bool(bool(done.ok)).is_true()
	assert_int(int(done.raised)).is_equal(0)
	assert_int(int(done.drilling)).is_equal(waiting)
	assert_int(MilitaryCampaign.aggregate_recruits).is_equal(0)


func test_with_nobody_waiting_those_at_home_go_to_camp_drill()->void:
	Fixtures.new(self).train(8)
	MilitaryCampaign.aggregate_recruits=0
	MilitaryCampaign.training_program={}
	var done:=HomeOrders.perform(HomeOrders.read("Train the recruits"))
	assert_bool(bool(done.ok)).is_true()
	assert_bool((MilitaryCampaign.training_program as Dictionary).is_empty()).is_false()
	assert_str(String(done.says)).contains("camp drill")


func test_the_court_carries_out_the_whole_order()->void:
	var heard:=CC.classify(USER_LINE)
	assert_str(String(heard.get("verb",""))).is_equal("home")
	assert_str(String((heard.get("home",{}) as Dictionary).get("kind",""))).is_equal("levy")
	var routed:=CC.custom_order(USER_LINE,{})
	assert_str(String(routed.get("route",""))).is_equal("home")
	assert_str(String(routed.get("outcome",""))).contains("begin drill")


## The user's words: "Please dismiss 5 of our soldiers and return them to the
## workforce" stripped the war leader of his office, and the five stayed.
const DISMISS_LINE:="Please dismiss 5 of our soldiers and return them to the workforce"


func test_dismissing_soldiers_stands_them_down_and_never_demotes_anyone()->void:
	var reading:=HomeOrders.read(DISMISS_LINE)
	assert_str(String(reading.get("kind",""))).is_equal("stand_down")
	assert_int(int(reading.count)).is_equal(5)
	for said in ["send the recruits home","stand the levy down","disband all the recruits","let 3 warriors go home"]:
		assert_str(String(HomeOrders.read(said).get("kind",""))).override_failure_message("'%s' was not a stand-down" % said).is_equal("stand_down")
	# One person dismissed is still the court's business.
	assert_str(String(HomeOrders.read("Dismiss Tahu").get("kind",""))).is_not_equal("stand_down")
	assert_str(String(HomeOrders.read("release the prisoners").get("kind",""))).is_not_equal("stand_down")
	var heard:=CC.classify(DISMISS_LINE)
	assert_str(String(heard.get("verb",""))).is_equal("home")
	assert_str(String((heard.get("home",{}) as Dictionary).get("kind",""))).is_equal("stand_down")


func test_standing_down_sends_the_recruits_then_the_fighters_home()->void:
	Fixtures.new(self).train(8)
	MilitaryCampaign.raise_recruits(3)
	var home_before:=int(MilitaryCampaign.home_army.get("troops",0))
	var done:=HomeOrders.perform(HomeOrders.read(DISMISS_LINE))
	assert_bool(bool(done.ok)).is_true()
	assert_int(int(done.count)).is_equal(5)
	assert_int(MilitaryCampaign.aggregate_recruits).is_equal(0)
	assert_int(int(MilitaryCampaign.home_army.get("troops",0))).is_equal(home_before-2)
	assert_str(String(done.says)).contains("go home")
	# No number and no "all": the court asks how many, and nobody goes.
	var asked:=HomeOrders.perform(HomeOrders.read("send the soldiers home"))
	assert_bool(bool(asked.ok)).is_false()
	assert_str(String(asked.says)).contains("How many")
	assert_int(int(MilitaryCampaign.home_army.get("troops",0))).is_equal(home_before-2)
