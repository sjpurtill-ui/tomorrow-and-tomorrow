extends GdUnitTestSuite
## CADENCE OF THE WORLD'S ANSWERS (world_answer.gd), over forty years.
##
## The player's rule: before a recurring feature ships, play years of it and
## read how often it fires and whether it repeats. This is the logic of it
## alone (no terrain, no battles): a world shaped like the year-228 campaign
## (one people whose envoys the god kept killing, one that resents us without
## fearing us, two we never wronged), the god accepting every people that
## comes to bow, forty years of months. It prints the years' answers (the
## transcript in the test log) and holds the cadence to account.

const ANSWER:=preload("res://scripts/world_answer.gd")
const DEEDS:=preload("res://scripts/deeds.gd")
const DIVINE:=preload("res://scripts/divine_regard.gd")
const Hall:=preload("res://scripts/audience_hall.gd")
const HallProbe:=preload("res://tests/audience_hall_probe.gd")
const RIVALS:=preload("res://scripts/rival_rulers.gd")

var probe:Node
var _opponents:=0

func before_test()->void:
	_opponents=GameState.opponent_count
	probe=auto_free(HallProbe.new())
	probe._base()
	GameState.opponent_count=4
	CivilizationSystem.reset_for_new_world()
	ForeignDiplomacy.reset_for_new_world(); GovernmentPeopleSystem.reset_for_new_world()
	probe._people(400)
	probe._refill()
	for civ in CivilizationSystem.civilizations:
		var relation:Dictionary=civ.player_relation
		relation.contact_level=2; relation.met_day=0; relation.opinion=-0.1; relation.border_tension=0.3
		for other in civ.relations: civ.relations[other].at_war=false
		probe._stock_actor(String(civ.id),2000,300)
	probe._fill_court()
	GameState.elapsed_days=10
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

func _civ(index:int)->Dictionary:
	return CivilizationSystem.civilizations[index]

func _set_pop(civ:Dictionary,n:float)->void:
	var before:=maxf(1.0,float(civ.get("population",n)))
	civ["population"]=n
	civ["cohorts"]=CivilizationSystem._scaled_cohorts(civ.get("cohorts",{}),n)
	CivilizationSystem._scale_strategic_region_populations(civ,n/before)
	civ["military_population"]=minf(float(civ.get("military_population",0.0)),n*0.1)

func _occasions(type:String)->Array:
	var out:Array=[]
	for o in Hall.state().occasions:
		if o is Dictionary and String((o as Dictionary).get("type",""))==type: out.append(o)
	return out

## Forty years of months; the god takes every people that comes to bow, and
## (when wrong_every_years > 0) wrongs the resentful people anew that often.
## Returns {civ_id: [{day, kind}]} and prints the transcript.
func _run(resentful:String,wrong_every_years:int)->Dictionary:
	var start:=int(GameState.elapsed_days)
	var events:={}
	var log:=PackedStringArray()
	var was_arming:={}; var was_bound:={}
	for month in 40*12:
		var day:=start+month*30
		GameState.elapsed_days=day
		if wrong_every_years>0 and month>0 and month%(wrong_every_years*12)==0:
			DIVINE.record_envoy_harm(resentful,Hall._civ_name(resentful),"Envoy%d Stone" % month,"kill",0.3)
		ANSWER.monthly(day)
		for occasion in _occasions("submission"):
			Hall.state().occasions.erase(occasion)
			var audience:Dictionary=Hall._generate_for(occasion,day)
			if not audience.is_empty(): ANSWER.resolve(audience,"accept")
		for civ in CivilizationSystem.civilizations:
			var id:=String(civ.id)
			var arming:=not ANSWER.arming(id).is_empty()
			var bound:=ANSWER.is_tributary(id)
			for pair in [["arming",arming,was_arming],["bow",bound,was_bound]]:
				if bool(pair[1]) and not bool((pair[2] as Dictionary).get(id,false)):
					(events.get_or_add(id,[]) as Array).append({"day":day,"kind":String(pair[0])})
					log.append("year %d: %s %s" % [floori(float(day-start)/365.0),Hall._civ_name(id),"arms against us" if String(pair[0])=="arming" else "bows"])
				(pair[2] as Dictionary)[id]=bool(pair[1])
	print("WORLD_ANSWER_CADENCE\n"+"\n".join(log))
	return events

func _setup()->Array:
	var feared:=String(_civ(0).id)
	var resentful:=String(_civ(1).id)
	_set_pop(_civ(0),90.0)
	_set_pop(_civ(1),420.0)
	# The god kept killing the first people's envoys; the second holds old grudges.
	for i in 7:
		GameState.elapsed_days=10+i*120
		DIVINE.record_envoy_harm(feared,Hall._civ_name(feared),"Envoy%d Reed" % i,"kill",0.3)
		RIVALS.character(feared); RIVALS.grudge(feared,"the killing of their envoy Envoy%d" % i,1.0,"slain_envoy:%d" % i)
	RIVALS.character(resentful)
	for i in 3: RIVALS.grudge(resentful,"an old wrong %d" % i,1.0,"old:%d" % i)
	return [feared,resentful,[String(_civ(2).id),String(_civ(3).id)]]

func test_forty_years_of_answers_end_feuds_without_repeating()->void:
	var who:=_setup()
	var feared:=String(who[0]); var resentful:=String(who[1]); var untouched:Array=who[2]
	var start:=int(GameState.elapsed_days)
	var events:=_run(resentful,0)
	# Peoples we never wronged never answer.
	for id in untouched: assert_bool(events.has(id)).override_failure_message("%s answered though never wronged" % id).is_false()
	# The people we kept wronging bows within ten years.
	assert_bool(events.has(feared)).is_true()
	assert_str(String((events[feared] as Array)[0].kind)).is_equal("bow")
	assert_int(int((events[feared] as Array)[0].day)-start).is_less(10*365)
	# The resentful people comes with everything once over old grudges, and
	# never again without a new wrong.
	var armed:=(events.get(resentful,[]) as Array).filter(func(x:Dictionary)->bool: return String(x.kind)=="arming")
	assert_int(armed.size()).is_equal(1)

func test_a_people_wronged_again_and_again_comes_again_but_not_every_season()->void:
	var who:=_setup()
	var resentful:=String(who[1])
	var events:=_run(resentful,6)
	var armed:Array=(events.get(resentful,[]) as Array).filter(func(x:Dictionary)->bool: return String(x.kind)=="arming").map(func(x:Dictionary)->int: return int(x.day))
	assert_int(armed.size()).is_greater(1)
	for i in range(1,armed.size()): assert_int(int(armed[i])-int(armed[i-1])).is_greater_equal(ANSWER.ALL_IN_GAP)
