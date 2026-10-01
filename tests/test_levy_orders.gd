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
const Hall:=preload("res://scripts/audience_hall.gd")

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


## Founding one town (realm_orders.gd found_town): the settlers set out.
## Tests have no mapped rivers, so the site is given through the seam.
func test_founding_a_town_sends_settlers_out()->void:
	var Realm:=load("res://scripts/realm_orders.gd")
	CivilizationSystem._add_revealed_area(Vector2.ZERO,45.0,"scout report")
	var reading:Dictionary=Realm.read("Found a new town by the river")
	assert_str(String(reading.get("kind",""))).is_equal("found_town")
	assert_bool(bool(reading.river)).is_true()
	Realm.site_override=func()->Vector2: return Vector2(12.0,5.0)
	var done:Dictionary=Realm.perform(reading)
	Realm.site_override=Callable()
	assert_bool(bool(done.ok)).override_failure_message(str(done)).is_true()
	assert_bool((GameState.settlement_convoy as Dictionary).is_empty()).is_false()
	assert_str(String(done.says)).contains("settlers set out")


# --------------------------------------------------------------------------
# "I called on my court for 10 levies, they said they were training. Nothing."
# The words were not read as a call-up; with nobody waiting the court fell to
# the drill at home, and a drill nobody could attend (every soldier already at
# the staff's target) had stood "under way" for 24 years. The people had cut
# down every stand of trees they knew, so no levy could be armed, and the
# court promised 45 days of drill that were really 9 months.
# --------------------------------------------------------------------------

func test_asking_for_levies_in_any_words_calls_them_up()->void:
	for said in ["I need 10 levies","Give me 10 levies","Raise a levy of 10 men","I want 10 more levies","10 levies","Prepare 10 levies","Get me ten levies"]:
		var r:=HomeOrders.read(said)
		assert_str(String(r.get("kind",""))).override_failure_message("'%s' was not read as a levy: %s" % [said,str(r)]).is_equal("levy")
		assert_bool(bool(r.get("recruit",false))).override_failure_message("'%s' did not call anyone up" % said).is_true()
		assert_int(int(r.count)).is_equal(10)
	# Look-alikes: a statement, a tax, the fighters we have.
	for said in ["I have 10 levies","Raise a levy on grain"]:
		assert_str(String(HomeOrders.read(said).get("kind",""))).override_failure_message("'%s' was read as a levy" % said).is_not_equal("levy")
	for said in ["Train the 7 levies","Train the recruits"]:
		var r:=HomeOrders.read(said)
		assert_bool(bool(r.get("recruit",false)) or bool(r.get("fill",false))).override_failure_message("'%s' called people up" % said).is_false()
	var called:=HomeOrders.perform(HomeOrders.read("I need 10 levies"))
	assert_int(int(called.raised)).is_equal(10)
	assert_int(int(called.drilling)).is_equal(10)


func test_train_ten_levies_drills_those_waiting_and_calls_up_the_rest()->void:
	MilitaryCampaign.raise_recruits(3)
	var done:=HomeOrders.perform(HomeOrders.read("Train 10 levies"))
	assert_bool(bool(done.ok)).is_true()
	assert_int(int(done.raised)).is_equal(7)
	assert_int(int(done.drilling)).is_equal(10)
	assert_int(MilitaryCampaign.aggregate_recruits).is_equal(0)
	assert_str(String(done.says)).contains("with the 3 already waiting that makes the 10 you asked for")


## The days said are the drill's real pace: the instructors' pace for all in
## drill with their weapons in hand, and a quarter of it for a spear levy
## whose spears cannot be made.
func test_the_court_says_how_long_the_drill_really_takes()->void:
	# Their weapons in store: the armed pace from the first day.
	for item in ["spear","improvised"]:MilitaryCampaign.military_inventory[item]=40
	var armed:=HomeOrders.perform(HomeOrders.read("Recruit 4 levies"))
	var order:Dictionary=MilitaryCampaign.training_queue.back()
	var pace:=HomeOrders._drill_pace(MilitaryCampaign,String(order.weapon),1.0)
	assert_float(pace).is_greater(0.0)
	assert_str(String(armed.says)).contains("about %d days before they are fit to fight." % ceili(float(order.required_days)/pace))
	# No spears, and none can be made: the slower drill, said plainly.
	MilitaryCampaign.training_queue.clear();MilitaryCampaign.equipment_queue.clear()
	GameState.resource_stockpiles["Timber"]=0.0;GameState.resource_stockpiles["Stone"]=0.0
	MilitaryCampaign.military_inventory["spear"]=0
	var bare:=HomeOrders.perform(HomeOrders.read("Recruit 4 spearmen"))
	var says:=String(bare.says)
	assert_str(String(MilitaryCampaign.training_queue.back().weapon)).is_equal("spear")
	assert_str(says).contains("without spears they drill at a quarter the pace")


## No wood to arm them: every stand of trees cut down, said with how far the
## carriers look for new woods and how many would look farther.
func test_no_wood_is_said_plainly_with_what_would_bring_it()->void:
	for deposit in GameState.resource_deposits:
		if String((deposit as Dictionary).get("resource",""))=="Timber":deposit["remaining"]=0.1;deposit["initial_amount"]=800.0
	GameState.resource_deposits.append({"id":"cut_wood","resource":"Timber","stage":"developed","remaining":0.2,"initial_amount":900.0,"position":Vector3(2.0,0.0,1.0),"quality":0.8})
	GameState.resource_stockpiles["Timber"]=0.0
	MilitaryCampaign.military_inventory["spear"]=0;MilitaryCampaign.military_inventory["improvised"]=0
	var wood:Dictionary=WorldSimulation.resources.woodland_outlook()
	assert_int(int(wood.stands_working)).is_equal(0)
	assert_float(float(wood.reach_km)).is_equal(3.0*float(WorldSimulation.resources.surface_search_rings()))
	var done:=HomeOrders.perform(HomeOrders.read("Recruit 6 levies"))
	assert_str(String(done.says)).contains("We have no wood for them: every stand of trees we know is cut down")
	assert_str(String(done.says)).contains("our carriers look for new woods no farther than %d km" % roundi(float(wood.reach_km)))
	# The carriers who would look one ring farther: one more ring for every 6 at work.
	if int(wood.carriers_for_next)>0:
		GameState.population_allocations["Logistics"]=int(wood.carriers_for_next)
		assert_int(WorldSimulation.resources.surface_search_rings()).is_greater(roundi(float(wood.reach_km)/3.0))


func _home_formations(training:float,equipped:bool)->void:
	Fixtures.new(self).train(8)
	for formation:Dictionary in MilitaryCampaign.home_army.get("formations",[]):
		formation["training"]=training;formation["personnel_condition"]=1.0
		formation["equipment_required"]=int(formation.get("count",1))
		formation["equipment"]=int(formation.get("count",1)) if equipped else 0


## A drill nobody can attend waits, its progress kept, while soldiers may soon
## need it; after STALLED_DRILL_DAYS standing still it lapses, and the staff
## begin a fresh one when anyone needs drilling. One the ruler suspended waits
## for as long as the ruler likes.
func test_a_drill_nobody_can_attend_does_not_stand_open_for_ever()->void:
	_home_formations(0.9,true)
	MilitaryCampaign.training_program={}
	assert_bool(MilitaryCampaign.start_training_program("signal_drill").has("error")).is_false()
	var start_day:=int(GameState.elapsed_days)
	assert_bool(MilitaryCampaign.training_staff.prepare_army_day()).is_false()
	assert_bool((MilitaryCampaign.training_program as Dictionary).is_empty()).is_false()
	assert_str(String(MilitaryCampaign.training_staff.data.status.army)).starts_with("Every soldier at home already meets the training target")
	GameState.elapsed_days=start_day+MilitaryCampaign.training_staff.STALLED_DRILL_DAYS-1
	MilitaryCampaign.training_staff.prepare_army_day()
	assert_bool((MilitaryCampaign.training_program as Dictionary).is_empty()).is_false()
	GameState.elapsed_days=start_day+MilitaryCampaign.training_staff.STALLED_DRILL_DAYS
	MilitaryCampaign.training_staff.prepare_army_day()
	assert_bool((MilitaryCampaign.training_program as Dictionary).is_empty()).is_true()
	# Suspended by the ruler: it waits, however long.
	_home_formations(0.3,true)
	MilitaryCampaign.training_program={}
	assert_bool(MilitaryCampaign.start_training_program("camp_drill").has("error")).is_false()
	MilitaryCampaign.training_staff.set_policy("army","suspended")
	for step in 3:
		GameState.elapsed_days+=MilitaryCampaign.training_staff.STALLED_DRILL_DAYS
		MilitaryCampaign.training_staff.prepare_army_day()
	assert_bool((MilitaryCampaign.training_program as Dictionary).is_empty()).is_false()
	MilitaryCampaign.training_staff.set_policy("army","regular")


func test_the_court_never_says_a_stalled_drill_is_under_way()->void:
	Fixtures.new(self).train(8)
	MilitaryCampaign.aggregate_recruits=0
	MilitaryCampaign.training_program={"id":"signal_drill","label":"SIGNALS & COORDINATION","scope":"army","participants":0,"paused_reason":"No training rotation: units meet the target, need equipment, or are recovering.","progress_days":38.0,"duration_days":96.0}
	var done:=HomeOrders.perform(HomeOrders.read("Train the recruits"))
	assert_str(String(done.says)).contains("stands still")
	assert_str(String(done.says)).not_contains("already at their drill")


# --------------------------------------------------------------------------
# "I asked for 20 soldiers and NOTHING happened" (year 183). The player typed
# "raise 20 soldiers" in court. Many plain ways of asking for soldiers were
# never read as a levy: "I want 20 soldiers" and "give me 20 warriors" became
# a vague standing order, "give me 20 fighters" a march with nowhere to go,
# and "train 20 soldiers" said to a town overseer went to the town council,
# who answered "I'll train twenty folk" while nobody was called up. Every one
# now calls up, drills and arms, or says in numbers why it cannot.
# --------------------------------------------------------------------------

const PLAYER_SOLDIERS:="raise 20 soldiers"
const SOLDIER_ASKS:=["raise 20 soldiers","Raise 20 soldiers","I want 20 soldiers","Give me 20 soldiers","Recruit 20 soldiers","20 more soldiers","I need 20 soldiers",
	"I want 20 warriors","Give me 20 warriors","Raise 20 warriors","I need 20 warriors","I want 20 fighters","Give me 20 fighters","I need 20 fighters",
	"I want 20 men","Give me 20 men","Raise 20 men","Recruit 20 men","20 more men","I need 20 men","Get me 20 soldiers","We need 20 soldiers",
	"I want an army of 20","Make 20 soldiers","Build an army of 20 soldiers","Create 20 soldiers","I want twenty soldiers","20 soldiers"]
const SOLDIER_DRILLS:=["Train 20 soldiers","Train 20 warriors","Train 20 fighters","Train 20 men"]


func _in_drill()->int:
	var n:=0
	for order:Dictionary in MilitaryCampaign.training_queue:n+=int(order.get("count",0))
	return n


func test_the_players_words_raise_twenty_soldiers()->void:
	var reading:=HomeOrders.read(PLAYER_SOLDIERS)
	assert_str(String(reading.get("kind",""))).is_equal("levy")
	assert_int(int(reading.count)).is_equal(20)
	assert_bool(bool(reading.recruit)).is_true()
	var before:=_in_drill()
	var done:=HomeOrders.perform(reading)
	assert_bool(bool(done.ok)).is_true()
	assert_int(int(done.raised)).is_equal(20)
	assert_int(_in_drill()-before).is_equal(20)
	assert_str(String(done.says)).starts_with("20 are called up")


func test_asking_for_soldiers_in_any_words_calls_them_up()->void:
	for said:String in SOLDIER_ASKS:
		var r:=HomeOrders.read(said)
		assert_str(String(r.get("kind",""))).override_failure_message("'%s' was not read as a levy: %s" % [said,str(r)]).is_equal("levy")
		assert_bool(bool(r.get("recruit",false))).override_failure_message("'%s' did not call anyone up: %s" % [said,str(r)]).is_true()
		assert_int(int(r.count)).override_failure_message("'%s' lost its number" % said).is_equal(20)
	for said:String in SOLDIER_DRILLS:
		var r:=HomeOrders.read(said)
		assert_str(String(r.get("kind",""))).override_failure_message("'%s' was not read as a levy: %s" % [said,str(r)]).is_equal("levy")
		assert_bool(bool(r.get("fill",false))).override_failure_message("'%s' would not call up the rest: %s" % [said,str(r)]).is_true()
	# Look-alikes: soldiers we have, sent, lost or counted; men for other work;
	# a march; a question.
	for said:String in ["Send 20 soldiers to the ford","We lost 20 soldiers","I have 20 soldiers","I need 20 men on the fields","Give 20 soldiers to the war leader","Train the 20 soldiers","How many soldiers do we have?","Give me 20 soldiers to attack Tsaren","Put 20 men on building"]:
		var r:=HomeOrders.read(said)
		assert_bool(String(r.get("kind",""))=="levy" and (bool(r.get("recruit",false)) or bool(r.get("fill",false)))).override_failure_message("'%s' called people up: %s" % [said,str(r)]).is_false()


func test_train_twenty_soldiers_drills_twenty()->void:
	var before:=_in_drill()
	var done:=HomeOrders.perform(HomeOrders.read("Train 20 soldiers"))
	assert_bool(bool(done.ok)).is_true()
	assert_int(_in_drill()-before).is_equal(20)


## Whoever the god speaks to in court, the levy is carried out by the same
## mechanic: the war leader, the headman, a town's overseer (who once sent it
## to the town council as a lesson to teach).
func test_the_court_raises_them_whoever_hears_it()->void:
	for entry:Dictionary in Hall.summonable():
		MilitaryCampaign.training_queue.clear();MilitaryCampaign.aggregate_recruits=0
		var audience:=Hall.summon(entry.target as Dictionary)
		if audience.is_empty():continue
		for said:String in [PLAYER_SOLDIERS,"I want 20 soldiers","Train 20 soldiers"]:
			MilitaryCampaign.training_queue.clear();MilitaryCampaign.aggregate_recruits=0
			var heard:=CC.hear(String(audience.id),said,{})
			assert_bool(bool(heard.get("handled",false))).override_failure_message("'%s' to %s was not heard as an order" % [said,String(entry.name)]).is_true()
			assert_int(_in_drill()).override_failure_message("'%s' to %s raised nobody: %s" % [said,String(entry.name),String(heard.get("outcome",""))]).is_equal(20)
			assert_str(String(heard.get("outcome",""))).override_failure_message("'%s' to %s became a standing order" % [said,String(entry.name)]).not_contains("standing order")


## With nobody free, the court says so with the engine's own count.
func test_nobody_free_is_said_with_the_numbers()->void:
	var adults:=MilitaryCampaign.recruitment_capacity()
	MilitaryCampaign.raise_recruits(adults)
	MilitaryCampaign.start_training("levy","improvised",MilitaryCampaign.aggregate_recruits)
	var done:=HomeOrders.perform(HomeOrders.read(PLAYER_SOLDIERS))
	assert_bool(bool(done.ok)).is_false()
	assert_str(String(done.says)).contains("0 of the 20 you asked for")
	assert_str(String(done.says)).contains("Of our %d able adults at home" % adults)
	assert_str(String(done.outcome)).starts_with("Nothing is set in motion")


## The days the court says are the engine's own (levy_forecast.gd). In year
## 183 the court said the drill took 468 days (as if no spear would ever be
## made) and that the spears could not be made, though the workshops made all
## 20 within 9 days and the drill ended in about 120. Here the engine's own
## daily workshop and drill steps run until the levy is fit to fight: the day
## the last weapon is in hand and the day the drill ends must be the days the
## court said.
const WEAPONS_SAID:="All (\\d+) are in hand in about (\\d+) days?"
const DRILL_SAID:="about (\\d+) days? before they are fit to fight"

func _said(says:String,pattern:String,group:int)->int:
	var m:=RegEx.create_from_string(pattern).search(says)
	return int(m.get_string(group)) if m!=null else -1

## The engine's own days for the levy `training_id`: each day the town's own
## deliveries (the deposits' delivered_today), then the workshops and the
## drill exactly as the military day runs them. {weapons_day, drill_day}.
func _run_days(training_id:int,weapon:String,need:int,limit:int=400,trade:bool=false)->Dictionary:
	var out:={"weapons_day":-1,"drill_day":-1}
	if int(MilitaryCampaign.military_inventory.get(weapon,0))>=need:out.weapons_day=0
	for day in range(1,limit+1):
		GameState.elapsed_days+=1
		for deposit in GameState.resource_deposits:
			var m:=String((deposit as Dictionary).get("resource",""))
			GameState.resource_stockpiles[m]=float(GameState.resource_stockpiles.get(m,0.0))+float((deposit as Dictionary).get("delivered_today",0.0))
		# Our other towns' deliveries, by the engine's own city trade.
		if trade:SettlementModel.process_city_trade()
		MilitaryCampaign._process_equipment_production_day()
		MilitaryCampaign._process_training_day()
		if int(out.weapons_day)<0 and int(MilitaryCampaign.military_inventory.get(weapon,0))>=need:out.weapons_day=day
		var drilling:=false
		for order:Dictionary in MilitaryCampaign.training_queue:
			if int(order.get("id",-1))==training_id:drilling=true
		if not drilling:
			out.drill_day=day
			return out
	return out

func _levy_world(timber:float)->void:
	MilitaryCampaign.equipment_queue.clear()
	MilitaryCampaign.training_queue.clear();MilitaryCampaign.aggregate_recruits=0
	for item in ["spear","improvised"]:MilitaryCampaign.military_inventory[item]=0
	GameState.resource_stockpiles["Timber"]=timber
	for deposit in GameState.resource_deposits:(deposit as Dictionary)["delivered_today"]=0.0

## Wood enough: the workshops make the weapons in a batch, and the court's days
## are the days the engine takes.
func test_the_courts_days_are_the_engines_days_when_the_workshops_make_them()->void:
	_levy_world(300.0)
	var done:=HomeOrders.perform(HomeOrders.read(PLAYER_SOLDIERS))
	assert_bool(bool(done.ok)).is_true()
	var says:=String(done.says)
	assert_str(says).not_contains("cannot make")
	var order:Dictionary=MilitaryCampaign.training_queue.back()
	var weapon:=String(order.weapon)
	var need:int=MilitaryCampaign._equipment_required_for(String(order.unit),int(order.count))
	var weapons_said:=_said(says,WEAPONS_SAID,2)
	var drill_said:=_said(says,DRILL_SAID,1)
	assert_int(weapons_said).override_failure_message("no day for the weapons in: "+says).is_greater(0)
	assert_int(drill_said).override_failure_message("no drill days in: "+says).is_greater(0)
	assert_int(int(done.weapons_day)).is_equal(weapons_said)
	assert_int(int(done.drill_days)).is_equal(drill_said)
	var real:=_run_days(int(order.id),weapon,need)
	assert_int(int(real.weapons_day)).override_failure_message("the court said %d days for the %s, the engine took %d" % [weapons_said,weapon,int(real.weapons_day)]).is_equal(weapons_said)
	assert_int(int(real.drill_day)).override_failure_message("the court said %d days of drill, the engine took %d" % [drill_said,int(real.drill_day)]).is_equal(drill_said)

## Too little wood for all of them at once, as in year 183: a workshop line
## makes them as the wood comes in, at the rate the engine makes them, never
## "cannot be made"; and the drill counts the weapons as they come.
func test_short_of_wood_the_line_makes_them_at_the_engines_rate()->void:
	_levy_world(3.0)
	var stand:Dictionary={}
	for deposit in GameState.resource_deposits:
		if String((deposit as Dictionary).get("resource",""))=="Timber":stand=deposit;break
	if stand.is_empty():
		stand={"id":"test_stand","resource":"Timber","stage":"developed","remaining":500.0,"initial_amount":800.0,"position":Vector3(2.0,0.0,1.0),"quality":0.8,"shipments":[],"stock_at_source":0.0}
		GameState.resource_deposits.append(stand)
	# Our own cutters bring in one load of wood a day.
	stand["delivered_today"]=1.0
	var done:=HomeOrders.perform(HomeOrders.read(PLAYER_SOLDIERS))
	assert_bool(bool(done.ok)).is_true()
	var says:=String(done.says)
	assert_str(says).not_contains("cannot make")
	assert_str(says).contains("a workshop line is set to make them")
	assert_str(says).contains("It makes them as the timber comes in")
	assert_str(says).contains("slower at first until their")
	var order:Dictionary=MilitaryCampaign.training_queue.back()
	var weapon:=String(order.weapon)
	var need:int=MilitaryCampaign._equipment_required_for(String(order.unit),int(order.count))
	var weapons_said:=_said(says,WEAPONS_SAID,2)
	var drill_said:=_said(says,DRILL_SAID,1)
	assert_int(weapons_said).override_failure_message("no day for the weapons in: "+says).is_greater(1)
	var per:=float((MilitaryCampaign._equipment_recipe(weapon).materials as Dictionary).get("Timber",1.0))
	assert_str(says).contains("the store holds timber for %d of them now" % floori(3.0/per+0.000001))
	var real:=_run_days(int(order.id),weapon,need)
	assert_int(int(real.weapons_day)).override_failure_message("the court said %d days for the %s, the engine took %d" % [weapons_said,weapon,int(real.weapons_day)]).is_equal(weapons_said)
	assert_int(int(real.drill_day)).override_failure_message("the court said %d days of drill, the engine took %d" % [drill_said,int(real.drill_day)]).is_equal(drill_said)
	# Counting the weapons as they come: no shorter than the armed pace, far
	# shorter than a drill that never gets them.
	var full:=HomeOrders._drill_pace(MilitaryCampaign,weapon,1.0)
	var bare:=HomeOrders._drill_pace(MilitaryCampaign,weapon,0.0)
	assert_int(drill_said).is_greater_equal(ceili(float(order.required_days)/full))
	assert_int(drill_said).is_less(ceili(float(order.required_days)/bare))

## The order's card says the same days as the court, from the same forecast.
func test_the_card_says_the_courts_days()->void:
	_levy_world(300.0)
	var done:=HomeOrders.perform(HomeOrders.read(PLAYER_SOLDIERS))
	var card:=preload("res://scripts/order_probes.gd").read({"kind":"levy","refs":{"training_id":int(done.training_id),"asked":20,"raised":20}})
	assert_str(String(card.line)).contains("fit in about %d days" % int(done.drill_days))


## Short of wood with another town that has plenty, as in year 183 (Sean
## Springs held 2 timber, Dawngate 393): our other town sends wood when the
## store runs short, the line makes the weapons as it comes, and the court's
## days are the days the engine takes, its own city trade included.
func test_short_of_wood_our_other_towns_send_it_at_the_engines_pace()->void:
	_levy_world(3.0)
	var home:Vector2=CivilizationSystem.player_world_origin
	var there:=home+Vector2(24.0,0.0)
	GameState.player_settlements.append({"id":"dawngate","name":"Dawngate","primary":false,"position":there,"population_share":0.25,"founded_day":0})
	CivilizationSystem.record_player_travel(there)
	SettlementModel.with_city_resources("dawngate",func()->void:GameState.resource_stockpiles["Timber"]=300.0)
	GameState.society_capacities["logistics"]=0.8
	GameState.society_capacities["institutions"]=0.8
	GameState.last_city_trade_day=int(GameState.elapsed_days)
	var done:=HomeOrders.perform(HomeOrders.read(PLAYER_SOLDIERS))
	assert_bool(bool(done.ok)).is_true()
	var says:=String(done.says)
	assert_str(says).not_contains("cannot make")
	assert_str(says).contains("our other towns send more when it runs short")
	var order:Dictionary=MilitaryCampaign.training_queue.back()
	var weapon:=String(order.weapon)
	var need:int=MilitaryCampaign._equipment_required_for(String(order.unit),int(order.count))
	var weapons_said:=_said(says,WEAPONS_SAID,2)
	var drill_said:=_said(says,DRILL_SAID,1)
	assert_int(weapons_said).override_failure_message("no day for the weapons in: "+says).is_greater(1)
	var real:=_run_days(int(order.id),weapon,need,400,true)
	assert_int(int(real.weapons_day)).override_failure_message("the court said %d days for the %s, the engine took %d: %s" % [weapons_said,weapon,int(real.weapons_day),says]).is_equal(weapons_said)
	assert_int(int(real.drill_day)).override_failure_message("the court said %d days of drill, the engine took %d" % [drill_said,int(real.drill_day)]).is_equal(drill_said)
