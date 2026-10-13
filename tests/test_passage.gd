extends GdUnitTestSuite
## THE WAY BETWEEN TWO PEOPLES (passage.gd): one rule for everyone a people
## sends to another. A land road lets all through; with none they go in the
## sender's own boats at the crossing's odds, and over a sea too wide for
## those boats nobody is sent: no envoy to our hall or from it, no eyes either
## way, no raiders, no tribute, no sickness, no households.
## Quick: three simulated peoples and ours at day 0, ways set by hand.

const Passage:=preload("res://scripts/passage.gd")
const Ledger:=preload("res://scripts/trade_ledger.gd")
const Stances:=preload("res://scripts/trade_stances.gd")
const Covert:=preload("res://scripts/covert_ops.gd")
const War:=preload("res://scripts/war_loop.gd")
const Hall:=preload("res://scripts/audience_hall.gd")
const Crisis:=preload("res://scripts/crisis_system.gd")

var ids:Array=[]

func before_test()->void:
	OS.set_environment("OPENAI_API_KEY","")
	WorldSimulation.clear()
	GameState.reset_for_new_world(31337)
	MilitaryCampaign.reset_for_new_world()
	ForeignDiplomacy.reset_for_new_world()
	CivilizationSystem.reset_for_new_world()
	CivilizationSystem.civilizations.assign(CivilizationSystem.civilizations.slice(0,3))
	CivilizationSystem.scout_land_authority=func(_at:Vector2)->bool:return true
	WorldSimulation.context_provider=func(_origin:Vector2)->Dictionary:return {"environment_profile":PlanetEnvironment.profile_at(Vector2.ZERO),"surface_water_distance_km":.1,"surface_water_recognized":true}
	WorldSimulation.start_world()
	ids=[]
	for c:Dictionary in CivilizationSystem.civilizations: ids.append(String(c.id))
	GameState.settlement_site_committed=true; GameState.settlement_completed=["Hearth Circle"]
	FoodSystem.reset_for_new_world(); FoodSystem.initialize()
	CivilizationSystem.player_world_origin=Vector2.ZERO
	for i in ids.size():
		var c:Dictionary=CivilizationSystem.civilizations[i]
		c["world_position"]=Vector2(150.0*float(i+1),0.0)
		c["alive"]=true
		var rel:Dictionary=c.player_relation
		rel["contact_level"]=2; rel["home_location_known"]=true; rel["opinion"]=0.1
		rel["home_position"]={"x":150.0*float(i+1),"z":0.0}
	for id:String in ids:
		WorldSimulation.scoped(id,func()->void:
			for v:Dictionary in WorldSimulation.world.civilizations: (v.player_relation as Dictionary)["contact_level"]=2)
	Ledger._discover_pairs(10)
	Ledger.survey_ways(100)

func after_test()->void:
	WorldSimulation.clear()
	WorldSimulation.context_provider=Callable()
	CivilizationSystem.scout_land_authority=Callable()
	ForeignDiplomacy.reset_for_new_world()

func _way(a:String,b:String,kind:String,open:float=0.0,coast:float=0.0)->void:
	var p:=Ledger.pair(a,b)
	var from:=Ledger.position(String(p.a)); var to:=Ledger.position(String(p.b))
	p["way"]={"k":kind,"o":open,"c":coast,"fx":from.x,"fy":from.y,"tx":to.x,"ty":to.y}

func _boats(owner:String,endurance:float)->void:
	Ledger._refresh_report(owner,int(GameState.elapsed_days))
	(Ledger.state().reports[owner] as Dictionary)["end"]=endurance

## We become an island: 600 km of open water and 50 in sight of a coast to
## every people, with boats of the given endurance on each side.
func _island(ours:float,theirs:float)->void:
	for id:String in ids: _way("player",id,"sea",600.0,50.0)
	for id:String in ids: _boats(id,theirs)
	_boats("player",ours)

func test_by_land_everyone_arrives_and_by_sea_only_the_senders_boats_count()->void:
	var a:=String(ids[0])
	assert_str(String(Passage.between("player",a).kind)).is_equal("land")
	assert_float(Passage.share("player",a)).is_equal(1.0)
	assert_str(Passage.words("player",a)).is_empty()
	# Our boats are good, theirs are poor: we reach them, they do not reach us.
	_island(1400.0,300.0)
	var ours:=pow(0.5,610.0/1400.0)
	assert_float(Passage.share("player",a)).is_equal_approx(ours,0.001)
	assert_bool(Passage.open("player",a)).is_true()
	assert_float(Passage.share(a,"player")).is_equal(0.0)
	assert_bool(Passage.open(a,"player")).is_false()
	assert_str(Passage.words("player",a)).contains("650 km of water").contains("%d in 100" % roundi(ours*100.0))
	assert_str(Passage.words(a,"player")).contains("nobody crosses")
	# The god's people is "human" in another people's world: the same way.
	assert_bool(Passage.open(a,"human")).is_false()
	# Who came through is rolled once and never again; about the share arrive.
	assert_bool(Passage.arrives("player",a,"x",5)).is_equal(Passage.arrives("player",a,"x",5))
	var came:=0
	for day in 400:
		if Passage.arrives("player",a,"party",day): came+=1
	assert_int(came).is_between(roundi(400.0*ours)-40,roundi(400.0*ours)+40)
	for day in 50: assert_bool(Passage.arrives(a,"player","party",day)).is_false()
	# No boats fit for the sea at all: nobody.
	_boats("player",0.0)
	assert_bool(Passage.open("player",a)).is_false()

func test_a_way_round_by_land_through_peoples_who_know_each_other_is_a_land_road()->void:
	var a:=String(ids[0]); var b:=String(ids[1])
	_way(a,b,"sea",900.0,0.0)
	_boats(a,200.0); _boats(b,200.0)
	# Both have a land road to us, so they reach each other round by land.
	assert_str(String(Ledger.way(a,b).kind)).is_equal("sea")
	assert_str(String(Passage.between(a,b).kind)).is_equal("land")
	assert_bool(Passage.open(a,b)).is_true()

func test_no_envoy_comes_to_our_hall_over_a_sea_their_boats_cannot_cross()->void:
	var a:=String(ids[0])
	var occasion:={"type":"debug","key":"t","civ_id":a,"day":10,"data":{"text":"a test"}}
	# By land the hall hears them (whatever business the world backs).
	var before:=int(Hall.state().serial)
	_island(1400.0,300.0)
	for n in 20:
		Hall.state()["serial"]=before+n
		assert_dict(Hall._generate_foreign_occasion(occasion.duplicate(true),10+n)).is_empty()

func test_no_eyes_go_either_way_and_eyes_already_there_are_cut_off()->void:
	var a:=String(ids[0])
	# By land an eye of ours sets out.
	var op:Dictionary=Covert.launch("plant",a,"","trader",{})
	assert_bool(op.has("error")).override_failure_message(str(op)).is_false()
	op["stage"]="in_place"; op["settled_day"]=0
	assert_int(int(Covert.network(a).eyes)).is_equal(1)
	# The sea shuts both ways.
	_island(300.0,300.0)
	var refused:Dictionary=Covert.launch("watch",a,"","trader",{})
	assert_str(String(refused.get("error",""))).contains("Nobody can be sent among").contains("650 km of water")
	var theirs:Dictionary=WorldSimulation.scoped(a,func()->Dictionary:return Covert.launch("plant","human","","trader",{}))
	assert_bool(theirs.has("error")).is_true()
	# The eye we had among them can send no word: counted gone.
	Covert._cut_off(33)
	assert_int(int(Covert.network(a).eyes)).is_equal(0)
	assert_str(String(op.stage)).is_equal("done")
	assert_bool(GameState.simulation_events.any(func(e:Dictionary)->bool:return String(e.get("title",""))=="OUR EYES ARE CUT OFF")).is_true()

func test_our_envoys_are_refused_over_a_shut_sea_and_told_the_odds_over_an_open_one()->void:
	var a:=String(ids[0])
	GameState.resource_stockpiles.Food=90000.0; GameState.food_stocks={"Preserved food":90000.0}
	_island(300.0,300.0)
	var shut:Dictionary=CivilizationSystem.diplomatic_mission_quote(a,"Food","goodwill")
	assert_str(String(shut.get("error",""))).contains("No envoy can reach them").contains("650 km of water")
	_island(1400.0,300.0)
	var open:Dictionary=CivilizationSystem.diplomatic_mission_quote(a,"Food","goodwill")
	if not open.has("error"):
		assert_float(float(open.passage_share)).is_equal_approx(pow(0.5,610.0/1400.0),0.001)
		assert_str(String(open.passage_words)).contains("come through")
	else:
		# Whatever else stops it, it is not the sea.
		assert_str(String(open.error)).not_contains("No envoy can reach them")

func test_no_war_feud_raid_tribute_or_sickness_crosses_a_shut_sea()->void:
	var a:=String(ids[0]); var b:=String(ids[1])
	assert_bool(War.sea_shut(a)).is_false()
	assert_int(Crisis._contacts().size()).is_equal(ids.size())
	_island(300.0,300.0)
	assert_bool(War.over_sea(a)).is_true()
	assert_bool(War.sea_shut(a)).is_true()
	assert_bool(War.near_us(a)).is_false()
	assert_bool(War.near_us(a,true)).is_false()
	assert_float(War.proximity(a)).is_equal(0.0)
	assert_bool(War.declare(a,20,"a test")).is_false()
	# No stance but free trade, and no tribute, toll or raid on the traders.
	assert_bool(Ledger.sea_shut("player",a)).is_true()
	var said:Dictionary=Stances.set_stance("player",a,"tribute","",40.0)
	assert_bool(bool(said.ok)).is_false()
	assert_str(String(said.said)).contains("No trader crosses")
	# No neighbour for sickness, begging, robbing or sending families away.
	assert_int(Crisis._contacts().size()).is_equal(0)
	# Peoples with a land road between them are untouched.
	assert_bool(War.sea_shut_between(a,b)).is_false()
	# Boats that cross open war again, but nobody walks it.
	_island(1400.0,1400.0)
	assert_bool(War.sea_shut(a)).is_false()
	assert_bool(War.near_us(a,true)).is_false()
	assert_int(Crisis._contacts().size()).is_equal(ids.size())
