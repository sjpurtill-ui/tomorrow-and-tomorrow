extends GdUnitTestSuite
## WHAT A PEOPLE DOES ABOUT US (scripts/world_answer.gd): the feud's endings.
##
## In the player's year-228 campaign the Kezari lost seven envoys and a town
## to the god and answered the same way thirty times: a raid of two dozen, a
## parley, quiet, a raid. Here a frightened, outmatched people bows and pays
## every harvest until its fear or our strength fails; a resentful people that
## is not outmatched arms for a season and comes with every spear.

const ANSWER:=preload("res://scripts/world_answer.gd")
const DEEDS:=preload("res://scripts/deeds.gd")
const DIVINE:=preload("res://scripts/divine_regard.gd")
const WAR:=preload("res://scripts/war_loop.gd")
const Hall:=preload("res://scripts/audience_hall.gd")
const HallProbe:=preload("res://tests/audience_hall_probe.gd")
const RIVALS:=preload("res://scripts/rival_rulers.gd")
const Stances:=preload("res://scripts/trade_stances.gd")

var probe:Node
var civ_id:=""
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
	Hall.envoys_only=false

func after_test()->void:
	Hall.envoys_only=false
	GameState.elapsed_days=0
	if _opponents>0: GameState.opponent_count=_opponents
	MilitaryCampaign.reset_for_new_world()
	GovernmentPeopleSystem.reset_for_new_world()
	ForeignDiplomacy.reset_for_new_world()
	CivilizationSystem.reset_for_new_world()
	WorldSimulation.clear()

func _civ(id:String)->Dictionary:
	for civ in CivilizationSystem.civilizations:
		if String(civ.id)==id: return civ
	return {}

func _set_pop(civ:Dictionary,n:float)->void:
	var before:=maxf(1.0,float(civ.get("population",n)))
	civ["population"]=n
	civ["cohorts"]=CivilizationSystem._scaled_cohorts(civ.get("cohorts",{}),n)
	CivilizationSystem._scale_strategic_region_populations(civ,n/before)
	civ["military_population"]=minf(float(civ.get("military_population",0.0)),n*0.1)

## Years of killed envoys: they fear us and resent us.
func _terrorise(id:String,killings:int)->void:
	for i in killings:
		GameState.elapsed_days=10+i*200
		DIVINE.record_envoy_harm(id,Hall._civ_name(id),"Envoy%d Reed" % i,"kill",0.3)
		# As the court's killing does (court_commands.gd): their ruler's grudge.
		RIVALS.character(id)
		RIVALS.grudge(id,"the killing of their envoy Envoy%d" % i,1.0,"slain_envoy:%d" % i)
	GameState.elapsed_days=10+killings*200

func _occasion(type:String,id:String)->Dictionary:
	for o in Hall.state().occasions:
		if o is Dictionary and String((o as Dictionary).get("type",""))==type and String((o as Dictionary).get("civ_id",""))==id: return o
	return {}

func _chronicle_titles()->String:
	var out:=PackedStringArray()
	for e in (GameState.chronicle.get("entries",[]) as Array): out.append(String((e as Dictionary).get("title","")))
	return " | ".join(out)

# --------------------------------------------------------------------------

func test_nobody_bows_or_marches_without_cause()->void:
	var o:=ANSWER.odds(civ_id)
	assert_float(float(o.bow)).is_equal(0.0)
	assert_float(float(o.all_in)).is_equal(0.0)

func test_a_frightened_outmatched_people_would_bow_a_resentful_equal_would_march()->void:
	_terrorise(civ_id,8)
	_set_pop(_civ(civ_id),40.0)
	var weak:=ANSWER.odds(civ_id)
	assert_float(float(weak.bow)).is_greater(0.0)
	assert_str(String(weak.why_bow)).contains("fear us")
	_set_pop(_civ(civ_id),400.0)
	var r:=ANSWER.reading(civ_id)
	# Nobody marches on a town they cannot find.
	r["knows_way"]=false
	assert_float(float(ANSWER.odds(civ_id,r).all_in)).is_equal(0.0)
	r["knows_way"]=true
	var strong:=ANSWER.odds(civ_id,r)
	assert_float(float(strong.bow)).is_less(float(weak.bow))
	assert_float(float(strong.all_in)).is_greater(0.0)
	assert_str(String(strong.why_all_in)).contains("resent us")

func test_they_come_to_bow_and_become_tributaries()->void:
	_terrorise(civ_id,8)
	_set_pop(_civ(civ_id),40.0)
	var day:=int(GameState.elapsed_days)
	ANSWER._offer_submission(civ_id,day,ANSWER.odds(civ_id))
	var occasion:=_occasion("submission",civ_id)
	assert_bool(occasion.is_empty()).is_false()
	var audience:Dictionary=Hall._generate_for(occasion,day)
	assert_bool(audience.is_empty()).is_false()
	assert_str(String(Hall._situation_type(audience))).is_equal("submission")
	var ids:=PackedStringArray()
	for option in ANSWER.options(audience): ids.append(String(option.id))
	assert_array(Array(ids)).contains_exactly(["accept","more","refuse"])
	var result:=ANSWER.resolve(audience,"accept")
	assert_str(String(result.get("outcome",""))).contains("bows to the god")
	assert_bool(ANSWER.is_tributary(civ_id)).is_true()
	assert_bool(WAR.keeps_peace(civ_id,day+10)).is_true()
	var t:=ANSWER.tributary(civ_id)
	assert_str(String(t.hostage)).contains("son of")
	# The tribute is the economy's own: one agreement in the trade ledger,
	# collected each season like any people's tribute.
	var agreement:=Stances.tribute(civ_id,"player")
	assert_bool(agreement.is_empty()).is_false()
	assert_float(float(agreement.value)).is_equal_approx(float(t.value),0.11)
	assert_str(_chronicle_titles()).contains("Bows to the God")

func test_tribute_comes_each_harvest_until_they_no_longer_fear_us()->void:
	_terrorise(civ_id,8)
	_set_pop(_civ(civ_id),40.0)
	var day:=int(GameState.elapsed_days)
	ANSWER._bind(civ_id,day,30.0,"Tam, son of Ilak","")
	GameState.elapsed_days=day+365
	ANSWER.monthly(day+365)
	assert_int(int(ANSWER.tributary(civ_id).get("years",0))).is_equal(1)
	# The agreement is kept ahead while the bond holds.
	assert_int(int(Stances.tribute(civ_id,"player").until)).is_greater(day+2*365)
	assert_str(_chronicle_titles()).contains("Keeps Faith")
	# A generation and more on, the fear is gone: they withhold it.
	DIVINE.store().events.clear()
	ForeignDiplomacy.audiences.erase("deeds")
	DIVINE.store().civ_dread.clear()
	GameState.elapsed_days=day+2*365
	ANSWER.monthly(day+2*365)
	assert_bool(ANSWER.is_tributary(civ_id)).is_false()
	assert_bool(Stances.tribute(civ_id,"player").is_empty()).is_true()
	assert_str(_chronicle_titles()).contains("Withholds Its Tribute")

func test_asking_twice_as_much_is_a_stated_gamble()->void:
	_terrorise(civ_id,8)
	_set_pop(_civ(civ_id),40.0)
	var chance:=ANSWER.more_odds(civ_id)
	assert_float(chance).is_between(0.1,0.9)
	var day:=int(GameState.elapsed_days)
	ANSWER._offer_submission(civ_id,day,ANSWER.odds(civ_id))
	var audience:Dictionary=Hall._generate_for(_occasion("submission",civ_id),day)
	var more:Dictionary={}
	for option in ANSWER.options(audience):
		if String(option.id)=="more": more=option
	assert_str(String(more.sub)).contains("%d in 100" % roundi(chance*100.0))
	var result:=ANSWER.resolve(audience,"more")
	var bound:=ANSWER.is_tributary(civ_id)
	assert_str(String(result.outcome)).contains("%d in 100" % roundi(chance*100.0))
	if not bound: assert_str(String(result.outcome)).contains("shamed")

func test_a_resentful_people_arms_then_marches_with_its_league()->void:
	var day:=int(GameState.elapsed_days)
	ANSWER._begin_arming(civ_id,day,{"why_all_in":"they resent us"})
	var arm:=ANSWER.arming(civ_id)
	assert_bool(arm.is_empty()).is_false()
	assert_int(int(arm.march)).is_between(day+ANSWER.ARMING_MIN,day+ANSWER.ARMING_MAX)
	assert_str(_chronicle_titles()).contains("Sharpens Every Spear")
	# Their own planner reads the season of arming as war: more spears raised.
	var plan:Dictionary=WorldSimulation.scoped(civ_id,func()->Dictionary: return (load("res://scripts/civilization_controller.gd") as GDScript).call("current_plan",civ_id))
	assert_bool(bool(plan.get("at_war",false))).is_true()
	GameState.elapsed_days=int(arm.march)
	ANSWER.monthly(int(arm.march))
	assert_bool(ANSWER.arming(civ_id).is_empty()).is_true()

func test_kin_and_tributaries_are_left_out_of_the_reckoning()->void:
	_terrorise(civ_id,8)
	_set_pop(_civ(civ_id),40.0)
	ANSWER._bind(civ_id,int(GameState.elapsed_days),20.0,"","")
	for m in 24: ANSWER.monthly(int(GameState.elapsed_days)+m*30)
	assert_bool(_occasion("submission",civ_id).is_empty()).is_true()
	assert_bool(ANSWER.arming(civ_id).is_empty()).is_true()

func test_the_answers_save_and_are_checked()->void:
	_terrorise(civ_id,8)
	_set_pop(_civ(civ_id),40.0)
	ANSWER._bind(civ_id,int(GameState.elapsed_days),20.0,"Tam, son of Ilak","")
	ANSWER._begin_arming(String(CivilizationSystem.civilizations[1].id),int(GameState.elapsed_days),{})
	assert_bool(ANSWER.valid_state(ForeignDiplomacy.audiences.answers)).is_true()
	assert_bool(bool(Hall.validate_state(Hall.state()))).is_true()
	assert_bool(ANSWER.valid_state({"tributaries":{"x":{"since":"a"}}})).is_false()
	ForeignDiplomacy.audiences.erase("answers")
	assert_bool(ANSWER.is_tributary(civ_id)).is_false()

const PERSONS:=preload("res://scripts/court_persons.gd")

func _bound_with_hostage()->Dictionary:
	_terrorise(civ_id,8)
	_set_pop(_civ(civ_id),40.0)
	ANSWER._bind(civ_id,int(GameState.elapsed_days),20.0,"Tam, son of Ilak","")
	return PERSONS.by_id(String(ANSWER.tributary(civ_id).get("hostage_id","")))

func test_the_hostage_lives_among_us_and_the_court_knows_him()->void:
	var p:=_bound_with_hostage()
	assert_bool(p.is_empty()).is_false()
	assert_str(String(p.name)).is_equal("Tam, son of Ilak")
	assert_str(String(p.hostage_of)).is_equal(civ_id)
	assert_str(PERSONS.title_of(p)).contains("hostage of the")
	# "Bring me Tam": the court knows whom you mean.
	var ref:=PERSONS.resolve_name("Tam")
	assert_str(String(ref.get("id",""))).is_equal(String(p.id))

func test_putting_the_hostage_to_death_breaks_the_bond_and_brings_blood()->void:
	var p:=_bound_with_hostage()
	var people_before:=int(GameState.population_total)
	var told:=ANSWER.hostage_judged(p,"execute")
	assert_str(told).contains("put to death")
	assert_bool(ANSWER.is_tributary(civ_id)).is_false()
	assert_bool(Stances.tribute(civ_id,"player").is_empty()).is_true()
	assert_bool(WAR.feuding(civ_id)).is_true()
	var words:=PackedStringArray()
	for t in DEEDS.remembered(civ_id,6): words.append(String(t.words))
	assert_str(", ".join(words)).contains("the killing of Tam")
	# He was none of ours: our count is unchanged.
	assert_int(int(GameState.population_total)).is_equal(people_before)

func test_sending_the_hostage_home_is_a_mercy_they_remember()->void:
	var p:=_bound_with_hostage()
	var hurt:=DEEDS.resentment(civ_id)
	var told:=ANSWER.hostage_judged(p,"free")
	assert_str(told).contains("sent home")
	assert_float(DEEDS.resentment(civ_id)).is_less(hurt)
	assert_bool(ANSWER.is_tributary(civ_id)).is_true()
	assert_str(String(ANSWER.tributary(civ_id).hostage)).is_equal("")

## A people organised for war does not raid with everything: it declares war.
func test_a_people_organised_for_war_declares_war_when_it_comes()->void:
	GameState.ensure_population_total(2400); GameState.housing_capacity=3200
	_set_pop(_civ(civ_id),3000.0)
	var day:=int(GameState.elapsed_days)
	ANSWER._begin_arming(civ_id,day,{"why_all_in":"they resent us"})
	var march:=int(ANSWER.arming(civ_id).march)
	GameState.elapsed_days=march
	ANSWER.monthly(march)
	assert_bool(bool(_civ(civ_id).player_relation.get("at_war",false))).is_true()
	assert_str(_chronicle_titles()).contains("War With")
