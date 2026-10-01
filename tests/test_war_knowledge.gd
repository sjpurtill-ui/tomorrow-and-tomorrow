extends GdUnitTestSuite
## Nobody strikes a home we cannot find (war_loop.gd NEEDS_HOME).
##
## The player: "My army went out and raided Neyali when I DON'T EVEN KNOW
## WHERE IT IS!" Hask, left without word in a war, burned the stores of a
## people whose home nobody had found. Their stores and their chief are at
## that home: until it is found, whoever gives the word, the band follows the
## raiders' trail to look for it (war_track), and a found home goes on the
## map. A band that already struck a home before this rule knows the way.

const WAR:=preload("res://scripts/war_loop.gd")
const HallProbe:=preload("res://tests/audience_hall_probe.gd")

var probe:Node
var civ_id:=""
## The world's number of rival peoples before this suite set its own (restored
## after each test, or later suites generate worlds of the wrong size).
var opponents_before:=-1

func before_test()->void:
	if opponents_before<0:opponents_before=int(GameState.opponent_count)
	probe=auto_free(HallProbe.new())
	probe._base()
	GameState.opponent_count=4
	CivilizationSystem.reset_for_new_world()
	ForeignDiplomacy.reset_for_new_world(); GovernmentPeopleSystem.reset_for_new_world()
	probe._people(140)
	probe._refill()
	for civ in CivilizationSystem.civilizations:
		var relation:Dictionary=civ.player_relation
		relation.contact_level=2; relation.met_day=0
		relation.home_location_known=false; relation.home_position={}
		civ.population=150.0
		probe._stock_actor(String(civ.id),800,120)
		WorldSimulation.scoped(String(civ.id),func()->void:WorldSimulation.state.ensure_population_total(150))
	probe._fill_court()
	GameState.elapsed_days=10
	civ_id=String(CivilizationSystem.civilizations[0].id)

func after_test()->void:
	GameState.elapsed_days=0
	MilitaryCampaign.reset_for_new_world()
	GovernmentPeopleSystem.reset_for_new_world()
	ForeignDiplomacy.reset_for_new_world()
	# The rival peoples' own systems (probe._stock_actor) are freed here, not
	# left as orphans for the next suite.
	WorldSimulation.clear()
	GameState.opponent_count=opponents_before

func _op()->Dictionary:
	var f:Dictionary=WAR.front(civ_id)
	return (f.war as Dictionary).get("op",{}) if not (f.war as Dictionary).is_empty() else f.get("op",{})

func _bold_general()->void:
	var general:Dictionary=WAR._general()
	assert_bool(general.is_empty()).override_failure_message("the court has no war leader").is_false()
	for p in GovernmentPeopleSystem.people:
		if p is Dictionary and int((p as Dictionary).get("person_id",0))==int(general.get("person_id",-1)):(p as Dictionary)["courage"]=0.95

func test_an_order_to_burn_an_unfound_home_sends_trackers()->void:
	WAR.declare(civ_id,10,"a killed envoy")
	assert_bool(WAR.home_known(civ_id)).is_false()
	var said:=WAR.order(civ_id,"war_burn",false)
	assert_str(String(_op().get("objective",""))).is_equal("war_track")
	assert_int(int(_op().get("band",0))).is_between(WAR.TRACKERS_MIN,WAR.TRACKERS_MAX)
	assert_str(said).contains("Nobody here knows where")
	assert_str(said).contains("raiders' trail")
	# The stance stands: when the way is found, the war council sends the band
	# without being told again (war_council.gd).
	assert_str(said).contains("When the way is found, the war band goes")

func test_the_war_leader_acting_alone_never_strikes_an_unfound_home()->void:
	WAR.declare(civ_id,10,"a killed envoy")
	_bold_general()
	for i in 12:
		WAR.front(civ_id).war["op"]={}
		WAR.order(civ_id,"war_general",true)
		assert_str(String(_op().get("objective",""))).is_not_equal("war_burn")
		assert_str(String(_op().get("objective",""))).is_not_equal("war_chief")

func test_the_court_offers_to_find_their_home_until_it_is_found()->void:
	WAR.declare(civ_id,10,"a killed envoy")
	var audience:={"situation":{"war":{"civ_id":civ_id,"mode":"war","filed":10}}}
	var ids:Array=WAR.options(audience).map(func(o:Dictionary)->String:return String(o.get("id","")))
	assert_array(ids).contains(["war_track"])
	assert_array(ids).not_contains(["war_burn","war_chief"])
	WAR._find_home(civ_id,10,"a test","test")
	ids=WAR.options(audience).map(func(o:Dictionary)->String:return String(o.get("id","")))
	assert_array(ids).contains(["war_burn","war_chief"])
	assert_array(ids).not_contains(["war_track"])

func test_trackers_either_find_the_home_and_chart_it_or_come_back_without_it()->void:
	WAR.declare(civ_id,10,"a killed envoy")
	var found_once:=false
	var lost_once:=false
	for start in range(10,70):
		CivilizationSystem.civilizations[0].player_relation.home_location_known=false
		CivilizationSystem.civilizations[0].player_relation.home_position={}
		var op:={"objective":"war_track","start":start,"due":start+5,"band":4,"general_pid":int(WAR._general().get("person_id",0)),"general":"Hask","auto":true}
		WAR._resolve_op(civ_id,op,start+5)
		if WAR.home_known(civ_id):
			found_once=true
			var home:Dictionary=CivilizationSystem.civilizations[0].player_relation.home_position
			assert_bool(home.has("x") and home.has("z")).is_true()
		else: lost_once=true
		if found_once and lost_once: break
	assert_bool(found_once).override_failure_message("no tracking party ever found the home").is_true()
	# Every outcome is written down with the odds it was rolled at.
	var tracked:=(WAR.state().log as Array).filter(func(e:Dictionary)->bool:return String(e.get("kind",""))=="op_track")
	assert_bool(tracked.is_empty()).is_false()
	assert_bool((tracked[0] as Dictionary).has("chance")).is_true()

func test_a_band_that_already_struck_their_home_knows_the_way()->void:
	WAR.declare(civ_id,10,"a killed envoy")
	WAR._log(civ_id,"op_burn","Hask's band reached their stores by night and burned them.",{"won":true})
	assert_bool(WAR.home_known(civ_id)).is_false()
	GameState.elapsed_days=15
	WAR.daily(15)
	assert_bool(WAR.home_known(civ_id)).override_failure_message("the band that went there must know the way").is_true()

func test_a_known_home_can_be_struck()->void:
	WAR.declare(civ_id,10,"a killed envoy")
	WAR._find_home(civ_id,10,"a test","test")
	# A real band of our levy goes by the land road and raids their town
	# (war_council.gd); nothing of the old made-up band is out.
	CivilizationSystem.set_scout_geography_authority(func(_p:Vector2)->bool:return true)
	MilitaryCampaign.military_inventory["improvised"]=40
	MilitaryCampaign.raise_recruits(40)
	MilitaryCampaign.start_training("levy","improvised",40)
	MilitaryCampaign._complete_training(MilitaryCampaign.training_queue[0].duplicate(true))
	MilitaryCampaign.training_queue.clear()
	var said:=WAR.order(civ_id,"war_burn",false)
	CivilizationSystem.set_scout_geography_authority(Callable())
	var band:={}
	for a in MilitaryCampaign.field_armies:
		if String(((a as Dictionary).get("council",{}) as Dictionary).get("act",""))=="punish": band=a
	assert_dict(band).override_failure_message(said).is_not_empty()
	assert_bool(bool((band.city_operation as Dictionary).get("raid",false))).is_true()
	assert_str(String(_op().get("objective",""))).is_not_equal("war_burn")
