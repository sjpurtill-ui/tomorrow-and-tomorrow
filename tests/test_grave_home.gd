extends GdUnitTestSuite
## Grave orders against the god's OWN people (scripts/grave_home.gd).
##
## The user's line, on the office order surface (court log, day 44277):
## "Kill all women in the village". It used to become a standing order with
## metric nudges and nobody died. Pinned here, on the court eval's own worlds
## (tests/court_eval/fixtures.gd: Seanstone of 900, Kishan the Headman):
## - whose people: our own at peace; "the village" with a town we hold that
##   nobody spoke of, or at war with none held, is asked; a town we hold just
##   spoken of stays its fate; laws stay laws;
## - the odds are stated and the rolls seeded: the same save, the same result;
## - the ledger balances: the people before, less the dead and the gone that
##   are reported, are the people after; the women counted fall by the women
##   killed and fled; the work, the houses and stores move as said;
## - bounded: a few hands do a few days' work, never everyone at once;
## - births fall with the women (the birth model reads the women left), and
##   their pregnancies are lost with them; an ordinary people's births are
##   untouched;
## - what lasts: the people's dread and love, the court, the Chronicle;
## - the voice is told the decided numbers and never asked for gore.

const Fixtures:=preload("res://tests/court_eval/fixtures.gd")
const Grave:=preload("res://scripts/grave_home.gd")
const CC:=preload("res://scripts/court_commands.gd")
const Hall:=preload("res://scripts/audience_hall.gd")
const DIVINE:=preload("res://scripts/divine_regard.gd")
const Chronicle:=preload("res://scripts/chronicle.gd")

const USERS_LINE:="Kill all women in the village"

var fx:Fixtures
var _processing:Dictionary={}

func before()->void:
	for node:Node in [GameState,CivilizationSystem,MilitaryCampaign,ProgressionSystem]: _processing[node]=node.is_processing()
	for key in ["OPENAI_API_KEY","LEVIATHAN_AI_API_KEY","LEVIATHAN_AI_ENDPOINT","LEVIATHAN_AI_MODEL","LEVIATHAN_AI_READER_MODEL"]: OS.unset_environment(key)
	fx=Fixtures.new(self)

func after()->void:
	CivilizationSystem.set_scout_geography_authority(Callable())
	GameState.elapsed_days=0
	MilitaryCampaign.reset_for_new_world()
	GovernmentPeopleSystem.reset_for_new_world()
	ForeignDiplomacy.reset_for_new_world()
	CivilizationSystem.reset_for_new_world()
	FoodSystem.reset_for_new_world()
	DiscoverySystem.reset_for_new_world()
	GameState.reset_for_new_world(74017)
	ProgressionSystem.reset_for_new_world()
	WorldSimulation.clear()
	for node:Node in _processing: node.set_process(bool(_processing[node]))
	preload("res://scripts/ai_mode.gd").reset_for_tests(preload("res://scripts/ai_mode.gd").SETTINGS_PATH)

func _world(name:String)->Dictionary:
	var w:=fx.use(name)
	assert_bool(w.has("error")).override_failure_message(str(w.get("error",""))).is_false()
	GameState.civic_api_enabled=false
	return w

func _audience(w:Dictionary,role:String="headman")->String:
	var id:=fx.audience_for(w,role)
	assert_str(id).is_not_empty()
	return id

func _female()->float:
	return float(GameState.population_cohorts.get("female",0.0))

# --------------------------------------------------------------------------
# Whose people
# --------------------------------------------------------------------------

func test_the_users_line_is_our_own_women_at_peace()->void:
	var w:=_world("home_peace")
	var id:=_audience(w)
	var audience:=Hall.find(id)
	for words in [USERS_LINE,"kill all women in the village","kil all women in the vilage"]:
		var r:=Grave.reading(words,audience,CC.roster(audience))
		assert_str(String(r.get("kind",""))).override_failure_message(words).is_equal("act")
		assert_str(String(r.get("how",""))).is_equal("kill")
		assert_array((r.groups as Array).map(func(g:Dictionary)->String: return String(g.id))).is_equal(["women"])
	var half:=Grave.reading("Kill half the farmers",audience,CC.roster(audience))
	assert_float(float(half.share)).is_equal(0.5)
	assert_str(String((half.groups[0] as Dictionary).get("role",""))).is_equal("Food")
	assert_str(String(Grave.reading("Burn our own village",audience,CC.roster(audience)).get("how",""))).is_equal("burn")
	assert_str(String(Grave.reading("Drive out the old",audience,CC.roster(audience)).get("how",""))).is_equal("drive")

func test_laws_people_and_other_peoples_are_never_read_as_this()->void:
	var w:=_world("home_peace")
	var id:=_audience(w)
	var audience:=Hall.find(id)
	var list:=CC.roster(audience)
	for words in ["Execute every thief","kill all thieves","Anyone who murders will be put to death","Kill every thief in the village","never kill a man who has surrendered",
		"Kill all the rebels","Kill Kavu","Kill him","Kill the men of Tsaren","Kill them all","Put the prisoners to death","Burn their stores","Burn the fields of the lazy",
		"don't kill the women","How many women are in the village?","Exile Kavu and his whole family"]:
		assert_dict(Grave.reading(words,audience,list)).override_failure_message(words).is_empty()

func test_the_village_is_asked_when_we_hold_a_town_nobody_spoke_of()->void:
	var w:=_world("tsaren_captured")
	var id:=_audience(w)
	var audience:=Hall.find(id)
	var list:=CC.roster(audience)
	var r:=Grave.reading("Kill all the women in the village",audience,list)
	assert_str(String(r.get("kind",""))).is_equal("ask")
	assert_str(String(r.get("question",""))).contains("Seanstone").contains("Tsaren")
	# No place in the words: the town we hold, as the war orders read it.
	assert_dict(Grave.reading("Kill all the women",audience,list)).is_empty()
	# "Our own" said outright: ours, whatever we hold.
	assert_str(String(Grave.reading("Kill all the women of our village",audience,list).get("kind",""))).is_equal("act")
	# Tsaren just spoken of: its people (the war orders), never ours.
	Hall.append_line(id,{"speaker":"You","role":"ruler","person_id":0,"civ_id":"","text":"How many people are left in Tsaren?","day":Hall._day(),"aside":false})
	assert_dict(Grave.reading("Kill all the women in the village",audience,list)).is_empty()

func test_the_question_is_answered_and_never_asked_twice()->void:
	var w:=_world("tsaren_captured")
	var id:=_audience(w)
	var before:=int(GameState.population_total)
	var asked:=CC.hear(id,"Kill all the women in the village",{"echoed":false})
	assert_str(String(asked.get("stage",""))).is_equal("grave_ask")
	assert_int(int(GameState.population_total)).is_equal(before)
	# The same unclear order again: said plainly, not asked again.
	var again:=CC.hear(id,"Kill all the women in the village",{})
	assert_str(String(again.get("stage",""))).is_equal("none")
	assert_str(String(again.get("outcome",""))).contains("Nothing is done until you say which village")
	# "Our own": the order on our own people (the one ordered may plead first).
	var ours:=CC.hear(id,"Our own, Seanstone",{})
	assert_str(String(ours.get("verb",""))).is_equal(Grave.VERB)
	assert_str(String(ours.get("stage",""))).is_not_equal("grave_ask")

# --------------------------------------------------------------------------
# The ledger, the odds, the bounds
# --------------------------------------------------------------------------

func _carry(id:String,words:String,insist:bool=true)->Dictionary:
	var audience:=Hall.find(id)
	var list:=CC.roster(audience)
	var r:=Grave.reading(words,audience,list)
	assert_str(String(r.get("kind",""))).override_failure_message(words).is_equal("act")
	return Grave.carry(id,audience,list,r,insist,{})

func test_killing_the_women_balances_the_ledger_and_says_its_numbers()->void:
	var w:=_world("home_peace")
	var id:=_audience(w)
	var pop:=int(GameState.population_total)
	var deaths:=int(GameState.lifetime_deaths)
	var gone:=int(GameState.lifetime_departures)
	var women:=float(GameState.population_exact-float(GameState.population_cohorts.children))*GameState.adult_female_share()
	var female:=_female()
	var fertile:=GameState.fertile_women()
	var pregnant:=GameState.estimated_active_pregnancies()
	var result:=_carry(id,USERS_LINE)
	print("GRAVE_HOME_TEST kill: ",result.get("stage","")," | ",result.get("outcome",""))
	var done:Dictionary=result.get("grave_home",{})
	if String(result.get("stage",""))!=Grave.VERB:
		# The one ordered refused even when the god insisted: nobody touched.
		assert_int(int(GameState.population_total)).is_equal(pop)
		return
	assert_bool(bool(done.get("ok",false))).is_true()
	var dead:=int(done.dead); var escaped:=int(done.escaped); var fled:=int(done.hands_fled); var kin:=int(done.kin_fled)
	# Before, less what is reported, is after.
	assert_int(pop-dead-escaped-fled-kin).is_equal(int(GameState.population_total))
	assert_int(int(GameState.lifetime_deaths)-deaths).is_equal(dead)
	assert_int(int(GameState.lifetime_departures)-gone).is_equal(escaped+fled+kin)
	assert_int(int(done.population_after)).is_equal(int(GameState.population_total))
	# The women counted fall by the women killed and fled (and their share of the rest who left).
	var share:=female/float(pop)
	assert_float(female-_female()).is_greater_equal(float(dead+escaped)-0.01)
	assert_float(female-_female()).is_less_equal(float(dead+escaped)+float(fled+kin)*share+1.0)
	assert_int(int(done.targets)).is_equal(floori(women+0.000001))
	# Bounded: the hands who would do it, five a day each, three days at most.
	assert_int(dead).is_less_equal(int(done.willing)*Grave.KILLS_PER_HAND*Grave.DAYS_MAX)
	assert_float(float(done.catch_odds)).is_between(0.35,0.92)
	assert_int(dead+escaped).is_equal(int(done.targets))
	# Births fall with the women; their pregnancies are lost with them.
	assert_float(GameState.fertile_women()).is_less(fertile)
	assert_float(GameState.fertile_women_factor()).is_less(1.0)
	assert_int(GameState.estimated_active_pregnancies()).is_less(pregnant)
	# Said with its numbers and how it was decided.
	var outcome:=String(result.outcome)
	for n in [dead,escaped]: assert_bool(CC._re("(?<![0-9])%d(?![0-9])|\\b%s\\b" % [n,preload("res://scripts/town_fate.gd")._count(n)]).search(outcome)!=null).override_failure_message("%d not in: %s" % [n,outcome]).is_true()
	assert_str(outcome).contains("chance").contains("women")
	# What lasts: the people's dread, love lost, standing, the Chronicle.
	var people:=DIVINE.people_regard(Hall._officials())
	assert_float(float(people.dread)).is_greater(0.2)
	var found:=false
	for e in (Chronicle.data().entries as Array):
		if String((e as Dictionary).get("key","")).begins_with("grave_home:kill"): found=true
	assert_bool(found).is_true()
	# The voice is told the numbers decided, and never asked for gore.
	var told:=CC.decided_words(result)
	assert_str(told).contains(String(result.outcome).substr(0,60)).contains("no gore")

func test_the_same_save_rolls_the_same()->void:
	var first:Dictionary
	for i in 2:
		var w:=_world("home_peace")
		var id:=_audience(w)
		var r:=_carry(id,"Kill half the farmers")
		var done:Dictionary=r.get("grave_home",{})
		var got:={"stage":String(r.stage),"dead":int(done.get("dead",0)),"escaped":int(done.get("escaped",0)),"kin":int(done.get("kin_fled",0)),"pop":int(GameState.population_total),"outcome":String(r.outcome)}
		if i==0: first=got
		else: assert_dict(got).is_equal(first)

func test_burning_our_own_village_takes_houses_and_stores()->void:
	var w:=_world("home_peace")
	var id:=_audience(w)
	var pop:=int(GameState.population_total)
	var houses:=int(GameState.housing_capacity)
	var food:=float(GameState.resource_stockpiles.get("Food",0.0))
	var result:=_carry(id,"Burn our own village")
	print("GRAVE_HOME_TEST burn: ",result.get("stage","")," | ",result.get("outcome",""))
	var done:Dictionary=result.get("grave_home",{})
	if String(result.get("stage",""))!=Grave.VERB: return
	assert_int(houses-int(GameState.housing_capacity)).is_equal(int(done.houses_lost))
	assert_float(food-float(GameState.resource_stockpiles.get("Food",0.0))).is_equal_approx(float(done.food_lost),1.0)
	assert_int(pop-int(done.dead)-int(done.kin_fled)-int(done.hands_fled)).is_equal(int(GameState.population_total))
	assert_float(float(done.burned_share)).is_between(0.3,0.85)
	assert_str(String(result.outcome)).contains("Seanstone")

func test_driving_out_the_old_kills_nobody()->void:
	var w:=_world("home_peace")
	var id:=_audience(w,"kavu")
	var pop:=int(GameState.population_total)
	var deaths:=int(GameState.lifetime_deaths)
	var elders:=float(GameState.population_cohorts.elders)
	var result:=_carry(id,"Drive out the old")
	print("GRAVE_HOME_TEST drive: ",result.get("stage","")," | ",result.get("outcome",""))
	var done:Dictionary=result.get("grave_home",{})
	if String(result.get("stage",""))!=Grave.VERB: return
	assert_int(int(GameState.lifetime_deaths)).is_equal(deaths)
	assert_int(pop-int(done.moved)-int(done.kin_fled)-int(done.hands_fled)).is_equal(int(GameState.population_total))
	assert_float(float(GameState.population_cohorts.elders)).is_less(elders)
	assert_int(int(done.moved)+int(done.hid)).is_equal(int(done.targets))

# --------------------------------------------------------------------------
# The birth model
# --------------------------------------------------------------------------

func test_births_read_the_women_left()->void:
	# An ordinary people: the factor is exactly 1, and newborns keep it so.
	_world("home_peace")
	assert_float(GameState.fertile_women_factor()).is_equal(1.0)
	var ctx:={"health":0.8,"food_security":0.9,"housing_ratio":0.9,"cohesion":0.6}
	var base_births:=0.0
	var snap:=fx.snapshot()
	for d in 120: base_births+=float(GameState.process_reproduction_day(ctx).get("births_count",0))
	assert_float(GameState.fertile_women_factor()).is_equal(1.0)
	fx.restore(snap)
	var fertile:=GameState.fertile_women()
	# Half the grown women killed: fewer conceptions, fewer births.
	var women:=floori((float(GameState.population_exact)-float(GameState.population_cohorts.children))*GameState.adult_female_share())
	GameState.register_directive_population_deaths(women/2,"test","half the women",{"age_cohorts":["youth","early_adults","established_adults","mature_adults","elders"],"sex":"female"})
	# The women among the grown fall to about two thirds of an ordinary
	# people's (the dead were grown too), and the mothers to about half.
	assert_float(GameState.fertile_women_factor()).is_between(0.6,0.72)
	assert_float(GameState.fertile_women()/fertile).is_between(0.45,0.55)
	GameState.lose_pregnancies(0.5)
	var after_births:=0.0
	for d in 120: after_births+=float(GameState.process_reproduction_day(ctx).get("births_count",0))
	assert_float(after_births).is_less(base_births)
	# Newborns come about half girls: the women's share climbs back.
	var share:=GameState.adult_female_share()
	assert_float(share).is_less(GameState.BIRTH_FEMALE_SHARE)
	# Men lost never raise the births.
	fx.restore(snap)
	GameState.register_directive_population_deaths(100,"test","men",{"age_cohorts":["youth","early_adults","established_adults","mature_adults","elders"],"sex":"male"})
	assert_float(GameState.fertile_women_factor()).is_equal(1.0)

func test_departures_of_women_keep_the_count_of_women()->void:
	_world("home_peace")
	var female:=_female()
	var male:=float(GameState.population_cohorts.get("male",0.0))
	var gone:=GameState.register_population_departures(30,"test",{"youth":1.0,"early_adults":1.0},"female")
	assert_int(int(gone.count)).is_equal(30)
	assert_float(female-_female()).is_equal_approx(30.0,0.001)
	assert_float(float(GameState.population_cohorts.male)).is_equal_approx(male,0.001)
