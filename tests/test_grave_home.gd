extends GdUnitTestSuite
## Grave orders against the god's OWN people (scripts/grave_home.gd).
##
## The user's line, on the office order surface (court log, day 44277):
## "Kill all women in the village". It used to become a standing order with
## metric nudges and nobody died. Pinned here, on the court eval's own worlds
## (tests/court_eval/fixtures.gd: Seanstone of 900, Kishan the Headman):
## - what the words fall on: people named as the act's own object, never a
##   goat, trees, the dead or wolves; driving out is out of the realm, never
##   out of the hall; laws stay laws;
## - whose people: our own at peace; "the village" with a town we hold that
##   nobody spoke of, or at war, is asked once; only a short, clear answer
##   settles it, any other words drop it and are heard as themselves;
## - the odds are stated and the rolls seeded: the same save, the same result;
## - the ledger balances by age and sex: before, less the dead and the gone
##   reported, is after; "the women and the old" counts the old women once;
##   the work follows the farmers killed; the hands who flee are men of home;
## - births read the women of child-bearing age only: girls and old women
##   killed never cut today's births, and only the pregnancies of the mothers
##   killed or gone are lost;
## - what lasts: the people's dread, the court's true memory, the Chronicle;
## - the voice is told the decided numbers and never asked for gore.

const Fixtures:=preload("res://tests/court_eval/fixtures.gd")
const Grave:=preload("res://scripts/grave_home.gd")
const CC:=preload("res://scripts/court_commands.gd")
const Hall:=preload("res://scripts/audience_hall.gd")
const DIVINE:=preload("res://scripts/divine_regard.gd")
const Chronicle:=preload("res://scripts/chronicle.gd")

const USERS_LINE:="Kill all women in the village"
const GROWN:=["youth","early_adults","established_adults","mature_adults","elders"]
const EVERY_AGE:=["children","youth","early_adults","established_adults","mature_adults","elders"]

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

func _ids(r:Dictionary)->Array:
	return (r.get("groups",[]) as Array).map(func(g:Dictionary)->String: return String(g.id))

# --------------------------------------------------------------------------
# What the words fall on, and whose people
# --------------------------------------------------------------------------

func test_the_users_line_is_our_own_women_at_peace()->void:
	var w:=_world("home_peace")
	var id:=_audience(w)
	var audience:=Hall.find(id)
	var list:=CC.roster(audience)
	for words in [USERS_LINE,"kill all women in the village","kil all women in the vilage"]:
		var r:=Grave.reading(words,audience,list)
		assert_str(String(r.get("kind",""))).override_failure_message(words).is_equal("act")
		assert_str(String(r.get("how",""))).is_equal("kill")
		assert_array(_ids(r)).is_equal(["women"])
	var half:=Grave.reading("Kill half the farmers",audience,list)
	assert_float(float(half.share)).is_equal(0.5)
	assert_str(String((half.groups[0] as Dictionary).get("role",""))).is_equal("Food")
	assert_int(int(Grave.reading("Kill 20 of the women",audience,list).get("count",0))).is_equal(20)
	assert_array(_ids(Grave.reading("Kill the women and the old",audience,list))).is_equal(["women","elders"])
	assert_str(String(Grave.reading("Burn our own village",audience,list).get("how",""))).is_equal("burn")
	assert_str(String(Grave.reading("burn our village to the ground",audience,list).get("how",""))).is_equal("burn")
	assert_str(String(Grave.reading("Put the women of our village to death",audience,list).get("how",""))).is_equal("kill")
	for words in ["Drive the old out of the realm","drive out the old from our lands","banish the elders","banish the elders from Seanstone","Drive the women out of the realm","exile the old people into the wilderness","exile the old people, never to return","Kishan, banish the elders","I order you to banish the elders"]:
		assert_str(String(Grave.reading(words,audience,list).get("how",""))).override_failure_message(words).is_equal("drive")

func test_things_rooms_laws_and_other_peoples_are_never_read_as_this()->void:
	var w:=_world("home_peace")
	var id:=_audience(w)
	var audience:=Hall.find(id)
	var list:=CC.roster(audience)
	for words in [
		# No people for the act's object (the review's lines).
		"Cut down the trees around our village","Kill the sick goat in the village","get rid of the rats in our houses","kill the old dog at home",
		"rid the village of wolves","Burn the dead in the village","Drive the wolves out of our village","kill the village","Kill the women's goats",
		"burn the farmers' fields","kill the sick",
		# Moving people about, not out of the realm.
		"throw the men out of the hall","turn the men out to the fields","chase the boys off the walls","send the children away to fetch water",
		"banish the women from the hall",
		# Laws, one person, other peoples, words held back, questions.
		"Execute every thief","kill all thieves","Anyone who murders will be put to death","Kill every thief in the village","never kill a man who has surrendered",
		"Kill all the rebels","Kill Kavu","Kill him","Kill the men of Tsaren","Kill them all","Put the prisoners to death","Burn their stores","Burn the fields of the lazy",
		"don't kill the women","How many women are in the village?","Exile Kavu and his whole family","kill one woman",
		# Sentences that forbid, doubt, report or suppose it (second review).
		"We must not kill the children","It would be wrong to kill the women","The elders say we should burn our village","Do you think we should kill the old",
		"If the harvest fails, kill the old","kill the women if they resist","Kill the women when the enemy comes",
		# The object is the verb's own clause, and the verb opens the order.
		"Kill two goats and feed the children","Have the butcher feed the women","The men kill deer and the women cook","Kill time until the men return",
		"Drive out the wolves and protect the children",
		# Moving people within the realm; a part of the village burned.
		"Send the women and children away from the village","Send the hunters out into the forest","Send the herders out to the hills","Drive out the old",
		"drive the old people out of the village","Burn the huts of the sick","burn the houses","burn some houses",
		# Seanstone named only as where others are taken: not our people.
		"kill all the men of tsaren bring the women and children back to seanstone"]:
		assert_dict(Grave.reading(words,audience,list)).override_failure_message(words).is_empty()
	# People narrowed: never the whole group; the court asks whom exactly.
	for words in ["Kill the men who refused to fight","kill the men who deserted","kill the sick women","kill the wounded men"]:
		assert_str(String(Grave.reading(words,audience,list).get("kind",""))).override_failure_message(words).is_equal("whom")

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

func test_only_a_clear_answer_settles_the_question()->void:
	var w:=_world("tsaren_captured")
	var id:=_audience(w)
	var info:Dictionary=w.info
	var tsaren_women:=int(preload("res://scripts/town_ledger.gd").counts(String(info.civ_id),String(info.tsaren_id)).get("killed_women",0))
	var pop:=int(GameState.population_total)
	var asked:=CC.hear(id,"Kill all the women in the village",{"echoed":false})
	assert_str(String(asked.get("stage",""))).is_equal("grave_ask")
	# The same unclear order again: said plainly, not asked again.
	var again:=CC.hear(id,"Kill all the women in the village",{})
	assert_str(String(again.get("outcome",""))).contains("Nothing is done until you say which village")
	var audience:=Hall.find(id)
	# Words that are no answer: the question is dropped, nothing is done.
	for words in ["Bring us bread","how many live in our village","the last harvest was poor"]:
		assert_dict(Grave.answer_choice(audience,words)).override_failure_message(words).is_empty()
	CC.hear(id,"Bring us bread",{})
	assert_int(int(GameState.population_total)).is_equal(pop)
	assert_dict(Grave._pending(Hall.find(id))).is_empty()
	CC.hear(id,"the last harvest was poor",{})
	assert_int(int(preload("res://scripts/town_ledger.gd").counts(String(info.civ_id),String(info.tsaren_id)).get("killed_women",0))).is_equal(tsaren_women)
	assert_int(int(GameState.population_total)).is_equal(pop)
	# Clear answers.
	CC.hear(id,"Kill all the women in the village",{})
	audience=Hall.find(id)
	for pair in [["Our own, Seanstone","own"],["ours","own"],["Seanstone","own"],["Tsaren","town"],["the second one","town"],["no","no"],["neither","no"]]:
		assert_str(String(Grave.answer_choice(audience,String(pair[0])).get("pick",""))).override_failure_message(String(pair[0])).is_equal(String(pair[1]))
	# A new order while it is open is that order: the men of our village, never the women.
	var women:=GameState.women_in(GROWN)
	var men_order:=CC.hear(id,"Kill all the men of our village",{})
	assert_str(String(men_order.get("stage",""))).is_equal("grave_readback")
	assert_str(String(men_order.get("actor_says",""))).contains("men of Seanstone killed")
	assert_float(GameState.women_in(GROWN)).is_equal_approx(women,0.001)
	assert_array(_ids(Grave._pending(Hall.find(id)).get("reading",{}) as Dictionary)).is_equal(["men"])

func test_a_town_lost_before_the_answer_is_asked_again()->void:
	var w:=_world("tsaren_captured")
	var id:=_audience(w)
	var info:Dictionary=w.info
	CC.hear(id,"Kill all the women in the village",{"echoed":false})
	MilitaryCampaign.remove_occupation_force(String(info.civ_id),String(info.tsaren_id))
	var pop:=int(GameState.population_total)
	var r:=CC.hear(id,"Tsaren",{})
	assert_str(String(r.get("stage",""))).is_equal("grave_ask")
	assert_str(String(r.get("actor_says",""))).contains("no longer in our hands").contains("Seanstone").not_contains(" of ,")
	assert_int(int(GameState.population_total)).is_equal(pop)

# --------------------------------------------------------------------------
# The ledger, the odds, the bounds
# --------------------------------------------------------------------------

func _carry(id:String,words:String,insist:bool=true)->Dictionary:
	var audience:=Hall.find(id)
	var list:=CC.roster(audience)
	var r:=Grave.reading(words,audience,list)
	assert_str(String(r.get("kind",""))).override_failure_message(words).is_equal("act")
	return Grave.carry(id,audience,list,r,insist,{},"",true)

# --------------------------------------------------------------------------
# The read-back: carried out only on the god's yes in the very next line
# --------------------------------------------------------------------------

func _elders()->float:
	return float(GameState.population_cohorts.elders)

func test_the_order_alone_is_read_back_and_changes_nothing()->void:
	var w:=_world("home_peace")
	var id:=_audience(w,"kavu")
	var pop:=int(GameState.population_total)
	var r:=CC.hear(id,"Drive the old out of the realm",{})
	assert_str(String(r.get("stage",""))).is_equal("grave_readback")
	assert_str(String(r.get("actor_says",""))).contains("You would have the").contains("old people of Seanstone driven out of the realm?")
	assert_int(int(GameState.population_total)).is_equal(pop)
	assert_str(String(Grave._pending(Hall.find(id)).get("ask",""))).is_equal("readback")
	# The very next line, a plain yes: carried out.
	var elders:=_elders()
	var done:=CC.hear(id,"yes",{})
	assert_str(String(done.get("stage",""))).is_equal(Grave.VERB)
	assert_float(_elders()).is_less(elders)
	assert_dict(Grave._pending(Hall.find(id))).is_empty()

func test_any_other_line_drops_the_read_back()->void:
	for between in ["Bring us bread","How much food is in the stores?","the harvest was poor","Kill all the children"]:
		var w:=_world("home_peace")
		var id:=_audience(w,"kavu")
		CC.hear(id,"Drive the old out of the realm",{})
		var elders:=_elders()
		CC.hear(id,between,{})
		if between.begins_with("Kill"):
			# A new grave order is read back itself; the old one is gone.
			assert_array(_ids(Grave._pending(Hall.find(id)).get("reading",{}) as Dictionary)).is_equal(["children"])
			continue
		var after:=CC.hear(id,"yes",{})
		assert_str(String(after.get("stage",""))).override_failure_message(between).is_not_equal(Grave.VERB)
		assert_float(_elders()).override_failure_message(between).is_equal(elders)

func test_a_yes_elsewhere_or_after_a_reload_does_nothing()->void:
	var w:=_world("home_peace")
	var id:=_audience(w,"kavu")
	CC.hear(id,"Drive the old out of the realm",{})
	var elders:=_elders()
	# In another audience: nothing (there is nothing open there).
	var other:=_audience(w,"headman")
	assert_str(other).is_not_equal(id)
	CC.hear(other,"yes",{})
	assert_float(_elders()).is_equal(elders)
	# After a load the read-back's line is not known: dropped, never acted on.
	Grave._marks.clear()
	CC.hear(id,"yes",{})
	assert_float(_elders()).is_equal(elders)
	assert_dict(Grave._pending(Hall.find(id))).is_empty()

func test_a_plea_waits_only_for_the_very_next_line()->void:
	var w:=_world("home_peace")
	var id:=_audience(w)
	var pop:=int(GameState.population_total)
	CC.hear(id,USERS_LINE,{})
	var plea:=CC.hear(id,"yes",{})
	assert_str(String(plea.get("stage",""))).is_equal("grave_hesitate")
	CC.hear(id,"Bring us bread",{})
	CC.hear(id,"do it",{})
	assert_int(int(GameState.population_total)).is_equal(pop)
	# Asked again, then "do it" in the very next line: carried out.
	CC.hear(id,USERS_LINE,{})
	CC.hear(id,"yes",{})
	var done:=CC.hear(id,"do it",{})
	if String(done.get("stage",""))==Grave.VERB: assert_int(int(GameState.population_total)).is_less(pop)

func test_a_town_lost_before_the_yes_is_never_struck_in_its_name()->void:
	var w:=_world("home_towns")
	var id:=_audience(w)
	var r:=CC.hear(id,"Kill all the women of Reedmouth",{})
	assert_str(String(r.get("stage",""))).is_equal("grave_readback")
	var pop:=int(GameState.population_total)
	for i in range(GameState.player_settlements.size()-1,-1,-1):
		if String((GameState.player_settlements[i] as Dictionary).get("name",""))=="Reedmouth": GameState.player_settlements.remove_at(i)
	var after:=CC.hear(id,"yes",{})
	assert_str(String(after.get("outcome",""))).contains("no longer one of our towns")
	assert_int(int(GameState.population_total)).is_equal(pop)

func test_arrivals_of_known_sex_are_counted_so()->void:
	_world("home_peace")
	var women:=GameState.women_in(EVERY_AGE)
	var pop:=float(GameState.population_exact)
	GameState.register_population_arrivals(40,"test",{"youth":1.0,"early_adults":1.0},1.0)
	assert_float(GameState.women_in(EVERY_AGE)-women).is_equal_approx(40.0,0.01)
	GameState.register_population_arrivals(20,"test",{"early_adults":1.0},0.0)
	assert_float(GameState.women_in(EVERY_AGE)-women).is_equal_approx(40.0,0.01)
	assert_float(float(GameState.population_exact)-pop).is_equal_approx(60.0,0.01)

func test_killing_the_women_balances_the_ledger_and_says_its_numbers()->void:
	var w:=_world("home_peace")
	var id:=_audience(w)
	# Home's own count, as a day of play leaves it (the births read it).
	SettlementModel.with_local_population(func()->void: pass,true)
	var pop:=int(GameState.population_total)
	var deaths:=int(GameState.lifetime_deaths)
	var gone:=int(GameState.lifetime_departures)
	var women:=GameState.women_in(GROWN)
	var girls:=GameState.women_in(["children"])*1.0
	var fertile:=GameState.fertile_women()
	var pregnant:=float(GameState.pregnancy_cohorts.first_trimester)+float(GameState.pregnancy_cohorts.second_trimester)+float(GameState.pregnancy_cohorts.third_trimester)
	var result:=_carry(id,USERS_LINE)
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
	# The grown women fall by the women killed and fled (and their share of
	# the kin who left); the hands who fled are men; no girl was named.
	assert_float(women-GameState.women_in(GROWN)).is_greater_equal(float(dead+escaped)-0.01)
	assert_float(women-GameState.women_in(GROWN)).is_less_equal(float(dead+escaped+kin)+0.01)
	assert_float(GameState.women_in(["children"])).is_greater_equal(girls*(1.0-float(kin)/float(pop-dead-escaped-fled))-1.0)
	# Whole women of each age (a part of one in each age is never struck).
	assert_int(int(done.targets)).is_between(floori(women)-5,floori(women))
	# Bounded: the hands who would do it, five a day each, three days at most.
	assert_int(dead).is_less_equal(int(done.willing)*Grave.KILLS_PER_HAND*Grave.DAYS_MAX)
	assert_float(float(done.catch_odds)).is_between(0.35,0.92)
	assert_int(dead+escaped+int(done.hid)).is_equal(int(done.targets))
	# Births fall with the mothers; only the pregnancies of the mothers gone go.
	var fertile_after:=GameState.fertile_women()
	assert_float(fertile_after).is_less(fertile)
	var pregnant_after:=float(GameState.pregnancy_cohorts.first_trimester)+float(GameState.pregnancy_cohorts.second_trimester)+float(GameState.pregnancy_cohorts.third_trimester)
	assert_float(pregnant_after/pregnant).is_equal_approx(fertile_after/fertile,0.001)
	# ... and so does home's own count, which the daily births read.
	var local_fertile:float=SettlementModel.with_local_population(func()->float: return GameState.fertile_women_factor())
	assert_float(local_fertile).is_less(1.0)
	# Said with its numbers and how it was decided.
	var outcome:=String(result.outcome)
	for n in [dead,escaped]: assert_bool(CC._re("(?<![0-9])%d(?![0-9])|\\b%s\\b" % [n,preload("res://scripts/town_fate.gd")._count(n)]).search(outcome)!=null).override_failure_message("%d not in: %s" % [n,outcome]).is_true()
	assert_str(outcome).contains("chance").contains("women")
	# What lasts: the people's dread, the Chronicle, a true memory at court.
	var people:=DIVINE.people_regard(Hall._officials())
	assert_float(float(people.dread)).is_greater(0.2)
	var found:=false
	for e in (Chronicle.data().entries as Array):
		if String((e as Dictionary).get("key","")).begins_with("grave_home:kill"): found=true
	assert_bool(found).is_true()
	var true_memory:=false
	for p:Dictionary in Hall._officials():
		for m in (GovernmentPeopleSystem.person_snapshot(int(p.person_id)).get("memories",[]) as Array):
			if not "women of Seanstone" in str(m): continue
			assert_str(str(m)).not_contains("in the hall")
			if "killed: %d dead" % dead in str(m): true_memory=true
	assert_bool(true_memory).is_true()
	# The voice is told the numbers decided, and never asked for gore.
	var told:=CC.decided_words(result)
	assert_str(told).contains(String(result.outcome).substr(0,60)).contains("no gore")

func test_the_women_and_the_old_are_counted_once()->void:
	var w:=_world("home_peace")
	var id:=_audience(w,"kavu")
	var audience:=Hall.find(id)
	var r:=Grave.reading("Kill the women and the old",audience,CC.roster(audience))
	var named:=0
	for c in GROWN: named+=floori(GameState.women_in([c])+0.000001)
	named+=floori(float(GameState.population_cohorts.elders)-GameState.women_in(["elders"])+0.000001)
	assert_int(Grave.group_count(r.groups as Array)).is_equal(named)
	var result:=Grave.carry(id,audience,CC.roster(audience),r,true,{},"",true)
	if String(result.get("stage",""))!=Grave.VERB: return
	var done:Dictionary=result.grave_home
	assert_int(int(done.dead)+int(done.escaped)+int(done.hid)).is_equal(int(done.targets))
	assert_int(int(done.targets)).is_less_equal(named)

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

func test_the_farmers_killed_are_gone_from_the_fields()->void:
	var w:=_world("home_peace")
	var id:=_audience(w,"suri")
	var farmers:=int(GameState.population_allocations.Food)
	var result:=_carry(id,"Kill all the farmers")
	if String(result.get("stage",""))!=Grave.VERB: return
	var done:Dictionary=result.grave_home
	var lost:=int(done.dead)+int(done.escaped)
	assert_int(lost).is_greater(0)
	# The work the ledger shows the same day: the farmers less those killed or
	# fled, and at most their share of the others who left.
	var now:=int(GameState.population_allocations.Food)
	assert_int(now).is_less_equal(farmers-lost+1)
	assert_int(now).is_greater_equal(farmers-lost-int(done.kin_fled)-int(done.hands_fled)-2)

func test_burning_our_own_village_takes_houses_and_stores()->void:
	var w:=_world("home_peace")
	var id:=_audience(w)
	var pop:=int(GameState.population_total)
	var houses:=int(GameState.housing_capacity)
	var food:=float(GameState.resource_stockpiles.get("Food",0.0))
	var result:=_carry(id,"Burn our own village")
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
	var result:=_carry(id,"Drive the old out of the realm")
	var done:Dictionary=result.get("grave_home",{})
	if String(result.get("stage",""))!=Grave.VERB: return
	assert_int(int(GameState.lifetime_deaths)).is_equal(deaths)
	assert_int(pop-int(done.moved)-int(done.kin_fled)-int(done.hands_fled)).is_equal(int(GameState.population_total))
	assert_float(float(GameState.population_cohorts.elders)).is_less(elders)
	assert_int(int(done.moved)+int(done.hid)).is_equal(int(done.targets))

func test_the_hands_who_flee_are_men_of_home()->void:
	_world("home_peace")
	var women:=GameState.women_in(EVERY_AGE)
	var pop:=float(GameState.population_exact)
	var gone:=Grave._hands_flee({"who":"watch"},5)
	assert_int(gone).is_equal(5)
	assert_float(GameState.women_in(EVERY_AGE)).is_equal_approx(women,0.001)
	assert_float(float(GameState.population_exact)).is_equal_approx(pop-5.0,0.001)

# --------------------------------------------------------------------------
# The birth model
# --------------------------------------------------------------------------

func _births(days:int)->float:
	var ctx:={"health":0.8,"food_security":0.9,"housing_ratio":0.9,"cohesion":0.6}
	var n:=0.0
	for d in days: n+=float(GameState.process_reproduction_day(ctx).get("births_count",0))
	return n

func test_births_read_the_women_of_child_bearing_age()->void:
	# An ordinary people keeps no women by age, and its births are untouched.
	_world("home_peace")
	assert_bool(GameState.has_female_cohorts()).is_false()
	assert_float(GameState.fertile_women_factor()).is_equal(1.0)
	var snap:=fx.snapshot()
	var base_births:=_births(400)
	fx.restore(snap)
	var fertile:=GameState.fertile_women()
	# Half the grown women killed: half the mothers, fewer births.
	var women:=floori(GameState.women_in(GROWN))
	GameState.register_directive_population_deaths(women/2,"test","half the women",{"age_cohorts":GROWN,"sex":"female"})
	assert_float(GameState.fertile_women()/fertile).is_between(0.45,0.55)
	assert_float(_births(400)).is_less(base_births)
	# Girls killed, or old women: today's mothers are the same (the girls are
	# missed as mothers years from now, as they would have grown up).
	for cell in [{"cohort":"children","sex":"female","count":100},{"cohort":"elders","sex":"female","count":30}]:
		fx.restore(snap)
		var died:=GameState.register_population_deaths_by_cell([cell],"test","test")
		assert_int(int(died.count)).is_equal(int(cell.count))
		assert_float(GameState.fertile_women()).override_failure_message(str(cell)).is_equal_approx(fertile,0.0001)
		assert_float(_births(400)).override_failure_message(str(cell)).is_greater_equal(base_births*0.97)
	# Men lost never lower the mothers.
	fx.restore(snap)
	GameState.register_directive_population_deaths(100,"test","men",{"age_cohorts":GROWN,"sex":"male"})
	assert_float(GameState.fertile_women()).is_equal_approx(fertile,0.0001)
	# Ordinary deaths after a cull keep each age's women as they are (no drift).
	fx.restore(snap)
	GameState.register_directive_population_deaths(women/2,"test","half the women",{"age_cohorts":GROWN,"sex":"female"})
	var ratio:=GameState.women_in(["early_adults"])/float(GameState.population_cohorts.early_adults)
	GameState.register_population_deaths(60,"Hunger")
	assert_float(GameState.women_in(["early_adults"])/float(GameState.population_cohorts.early_adults)).is_equal_approx(ratio,0.0001)
	# The realm's totals are read from the women by age.
	var total:=0.0
	for c in EVERY_AGE: total+=GameState.women_in([c])
	assert_float(float(GameState.population_cohorts.female)).is_equal_approx(total,0.001)

func test_departures_of_women_keep_the_count_of_women()->void:
	_world("home_peace")
	var female:=GameState.women_in(EVERY_AGE)
	var men:=float(GameState.population_exact)-female
	var gone:=GameState.register_population_departures(30,"test",{"children":0.0,"youth":1.0,"early_adults":1.0,"established_adults":0.0,"mature_adults":0.0,"elders":0.0},"female")
	assert_int(int(gone.count)).is_equal(30)
	assert_float(female-GameState.women_in(EVERY_AGE)).is_equal_approx(30.0,0.001)
	assert_float(float(GameState.population_exact)-GameState.women_in(EVERY_AGE)).is_equal_approx(men,0.001)

func test_a_town_of_ours_named_is_its_own_people_only()->void:
	var w:=_world("home_towns")
	var id:=_audience(w)
	var audience:=Hall.find(id)
	var r:=Grave.reading("Kill all the women of Reedmouth",audience,CC.roster(audience))
	assert_str(String(r.get("kind",""))).is_equal("act")
	assert_str(String(r.get("home",""))).is_equal("Reedmouth")
	assert_str(String(r.get("settlement_id",""))).is_not_empty()
	var home_before:=SettlementModel.primary_population_exact()
	var pop:=int(GameState.population_total)
	var women:=GameState.women_in(GROWN)
	var result:=Grave.carry(id,audience,CC.roster(audience),r,true,{},"",true)
	if String(result.get("stage",""))!=Grave.VERB: return
	var done:Dictionary=result.get("grave_home",{})
	assert_str(String(result.outcome)).contains("Reedmouth")
	# Reedmouth's people, not home's: home keeps its count less the hands who fled.
	assert_float(absf(SettlementModel.primary_population_exact()-home_before)).is_less_equal(float(int(done.hands_fled))+1.0)
	assert_int(pop-int(done.dead)-int(done.escaped)-int(done.hands_fled)-int(done.kin_fled)).is_equal(int(GameState.population_total))
	# The realm's women, read back from the towns: never counted twice.
	var lost:=float(int(done.dead)+int(done.escaped))
	assert_float(GameState.women_in(GROWN)).is_less_equal(women-lost+1.0)
	assert_float(GameState.women_in(GROWN)).is_greater_equal(women-lost-float(done.kin_fled)-1.0)
