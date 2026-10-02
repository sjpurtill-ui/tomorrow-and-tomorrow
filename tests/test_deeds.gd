extends GdUnitTestSuite
## WHAT IS REMEMBERED (scripts/deeds.gd): the god's deeds are told for a
## generation, not a season.
##
## From the player's year-228 campaign: ten envoys killed and three towns
## taken over forty years, yet every year's annal said the people "speak of
## the god warmly and without fear", rival dread halved every 180 days (half a
## minute of play at the fastest speed), and the league of the fearful never
## formed. A settled feud also started again the next day over an older
## killing. These tests hold the long memory and the settlement to account.

const DEEDS:=preload("res://scripts/deeds.gd")
const DIVINE:=preload("res://scripts/divine_regard.gd")
const WAR:=preload("res://scripts/war_loop.gd")
const Hall:=preload("res://scripts/audience_hall.gd")
const HallProbe:=preload("res://tests/audience_hall_probe.gd")
const RIVALS:=preload("res://scripts/rival_rulers.gd")
const Lives:=preload("res://scripts/court_lives.gd")
const Standing:=preload("res://scripts/standing.gd")

var probe:Node
var civ_id:=""
var other_id:=""
var _opponents:=0

func before_test()->void:
	_opponents=GameState.opponent_count
	probe=auto_free(HallProbe.new())
	probe._base()
	GameState.opponent_count=4
	CivilizationSystem.reset_for_new_world()
	ForeignDiplomacy.reset_for_new_world(); GovernmentPeopleSystem.reset_for_new_world()
	probe._people(140)
	probe._refill()
	for civ in CivilizationSystem.civilizations:
		var relation:Dictionary=civ.player_relation
		relation.contact_level=2; relation.met_day=0; relation.opinion=-0.1; relation.border_tension=0.3
		for other in civ.relations: civ.relations[other].at_war=false
		probe._stock_actor(String(civ.id),800,120)
	probe._fill_court()
	GameState.elapsed_days=10
	civ_id=String(CivilizationSystem.civilizations[0].id)
	other_id=String(CivilizationSystem.civilizations[1].id)

func after_test()->void:
	GameState.elapsed_days=0
	if _opponents>0: GameState.opponent_count=_opponents
	MilitaryCampaign.reset_for_new_world()
	GovernmentPeopleSystem.reset_for_new_world()
	ForeignDiplomacy.reset_for_new_world()
	CivilizationSystem.reset_for_new_world()
	WorldSimulation.clear()

func _kill_envoy(id:String,who:String)->void:
	DIVINE.record_envoy_harm(id,Hall._civ_name(id),who,"kill",0.3)

func _at(day:int)->void:
	GameState.elapsed_days=day

# --------------------------------------------------------------------------

func test_a_killed_envoy_is_told_for_a_generation_not_a_season()->void:
	_kill_envoy(civ_id,"Solv Greyeyes")
	var told:=DEEDS.remembered(civ_id)
	assert_int(told.size()).is_equal(1)
	assert_str(String(told[0].words)).contains("Solv")
	_at(10+2*365)
	# The fresh dread is nearly gone after two years...
	assert_float(DIVINE.civ_dread(civ_id)).is_less(0.03)
	# ...but what is told of it still frightens them.
	assert_float(DEEDS.fear(civ_id)).is_greater(0.08)
	assert_float(float(Lives.rival_dread(civ_id))).is_greater(0.08)
	_at(10+25*365)
	assert_float(DEEDS.fear(civ_id)).is_between(0.04,0.06)

func test_ten_killings_over_forty_years_build_a_reputation()->void:
	var day:=10
	for i in 10:
		_at(day)
		_kill_envoy(civ_id,"Envoy%d Reed" % i)
		day+=4*365
	_at(day)
	# Enough for the league of the fearful (fear_league.JOIN_FEAR 0.45).
	assert_float(float(Lives.rival_dread(civ_id))).is_greater_equal(0.45)
	assert_float(DEEDS.resentment(civ_id)).is_greater(0.5)
	# The others heard of it: they fear us too, but bear no grudge for it.
	assert_float(DEEDS.fear(other_id)).is_between(0.1,0.4)
	assert_float(DEEDS.resentment(other_id)).is_equal(0.0)

func test_our_people_remember_a_god_who_kills_guests()->void:
	var before:Dictionary=DIVINE.people_regard(Hall._officials())
	var day:=10
	for i in 8:
		_at(day)
		_kill_envoy(civ_id,"Envoy%d Reed" % i)
		day+=3*365
	_at(day)
	var after:Dictionary=DIVINE.people_regard(Hall._officials())
	assert_float(float(after.told_dread)).is_greater(0.1)
	assert_float(float(after.dread)).is_greater(float(before.dread)+0.08)
	assert_float(float(after.love)).is_less(float(before.love))
	var home:=DEEDS.remembered("home")
	assert_bool(home.is_empty()).is_false()
	assert_str(String(home[0].words)).contains("guest")

func test_blessings_are_remembered_as_love()->void:
	var before:=float(DIVINE.people_regard(Hall._officials()).love)
	for i in 4:
		_at(10+i*200)
		DIVINE.record_people_act("bless_people")
	_at(10+5*365)
	var told:=DEEDS.home()
	assert_float(float(told.love)).is_greater(0.08)
	assert_float(float(told.dread)).is_equal(0.0)
	assert_float(float(DIVINE.people_regard(Hall._officials()).love)).is_greater_equal(before)

func test_the_dead_of_a_feud_are_one_told_deed_a_year()->void:
	DEEDS.blood(civ_id,4,false)
	DEEDS.blood(civ_id,6,false)
	DEEDS.blood(civ_id,6,true)
	var told:=DEEDS.remembered(civ_id,10)
	assert_int(told.size()).is_equal(2)
	var words:=PackedStringArray()
	for t in told: words.append(String(t.words))
	assert_str(", ".join(words)).contains("ten of theirs killed by our spears")
	assert_str(", ".join(words)).contains("raiders killed at our hearths")

func test_amends_ease_what_they_resent()->void:
	_kill_envoy(civ_id,"Hesk Reedweaver")
	var hurt:=DEEDS.resentment(civ_id)
	DEEDS.amends(civ_id,"the blood price that ended the feud")
	assert_float(DEEDS.resentment(civ_id)).is_less(hurt-0.05)

func test_a_settled_feud_is_not_started_again_by_an_older_killing()->void:
	RIVALS.character(civ_id)
	for i in 3:
		_at(10+i*40)
		RIVALS.grudge(civ_id,"the killing of their envoy Envoy%d" % i,1.0,"slain_envoy:%d" % i)
	_at(200)
	WAR.blood_feud(civ_id,200,"the killing of their envoy Envoy2","","envoy")
	assert_bool(WAR.feuding(civ_id)).is_true()
	WAR._end_feud(civ_id,400,"peace sought","They came to end it.")
	assert_bool(WAR.feuding(civ_id,400)).is_false()
	assert_int(int(RIVALS.envoy_wrongs(civ_id).count)).is_equal(0)
	# A year of their ruler's days: no new feud over the old killings.
	for day in range(400,765,5):
		_at(day)
		RIVALS.daily(day)
	assert_bool(WAR.feuding(civ_id,765)).is_false()
	assert_bool(WAR.keeps_peace(civ_id,765)).is_true()

func test_towns_taken_and_burned_are_told_once()->void:
	var civ:Dictionary=CivilizationSystem.civilizations[0]
	var regions:Array=civ.get("strategic_regions",[])
	if regions.size()<2:
		return
	(regions[0] as Dictionary)["controller"]="player"
	DEEDS.monthly(30)
	DEEDS.monthly(60)
	var told:=DEEDS.remembered(civ_id,10)
	var taken:=0
	for t in told:
		if String(t.kind)=="town_taken": taken+=1
	assert_int(taken).is_equal(1)

func test_the_memory_saves_and_is_checked()->void:
	_kill_envoy(civ_id,"Solv Greyeyes")
	DEEDS.blood(civ_id,5,false)
	var data:Dictionary=ForeignDiplomacy.audiences.deeds
	assert_bool(DEEDS.valid_state(data)).is_true()
	assert_bool(DEEDS.valid_state({"list":[{"day":"x","kind":"blood","civ":"a"}]})).is_false()
	assert_bool(DEEDS.valid_state({"list":"nope"})).is_false()
	# An older save has no memory: nothing is told, nothing breaks.
	ForeignDiplomacy.audiences.erase("deeds")
	assert_float(DEEDS.fear(civ_id)).is_equal(0.0)
	assert_array(DEEDS.remembered(civ_id)).is_empty()
