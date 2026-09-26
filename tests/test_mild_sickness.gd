extends GdUnitTestSuite
## Mild sicknesses are folded into the year's entry (crisis_system.gd,
## chronicle_annals.gd, chronicle_years.gd):
## - at onset a sickness is grave (a court crisis, as before) or mild (met by
##   the people's own custom: no matter at court, no onset, middle or end card);
## - a mild sickness still makes people ill, costs work, and its deaths are
##   real, counted and named;
## - one that turns grave by its turn comes to court then;
## - the year's entry tells mild sicknesses in one plain line, counted across
##   the year, and never as "a year without sickness";
## - mild sicknesses do not count toward crisis callbacks;
## - a crisis saved before this change carries on as before.
## Offline; never calls a real API.

const Crisis:=preload("res://scripts/crisis_system.gd")
const Chronicle:=preload("res://scripts/chronicle.gd")
const Annals:=preload("res://scripts/chronicle_annals.gd")
const Years:=preload("res://scripts/chronicle_years.gd")
const Hall:=preload("res://scripts/audience_hall.gd")
const SEED:=424242

var _saved_people:Array=[]

func before_test()->void:
	WorldSimulation.clear()
	GameState.set_process(false); CivilizationSystem.set_process(false); MilitaryCampaign.set_process(false)
	GameState.reset_for_new_world(SEED); GameState.civic_api_enabled=false
	ForeignDiplomacy.reset_for_new_world(); GovernmentPeopleSystem.reset_for_new_world()
	GameState.ensure_population_total(110)
	GameState.settlement_founded_day=0
	GameState.elapsed_days=400
	GameState.chronicle={}
	Chronicle.pending_cards.clear()
	Crisis.onsets_enabled=false
	_saved_people=GovernmentPeopleSystem.people.duplicate(true)

func after_test()->void:
	GovernmentPeopleSystem.people=_saved_people
	Crisis.onsets_enabled=true

func _x()->Dictionary:
	var x:=Crisis.inputs(int(GameState.elapsed_days))
	x["pop"]=float(GameState.population_total)
	return x

func _open(v:float)->Dictionary:
	Crisis._open_sickness(int(GameState.elapsed_days),_x(),"sickness",v,"",false)
	return Crisis._active_of("sickness")

func _run_to(c:Dictionary,to_day:int)->void:
	for day in range(int(GameState.elapsed_days)+1,to_day+1):
		GameState.elapsed_days=day
		if (Crisis.state().active as Dictionary).has(String(c.id)): Crisis._advance(c,day,_x())

func _cards_of(c:Dictionary)->Array:
	return (GameState.chronicle.get("entries",[]) as Array).filter(func(e:Dictionary)->bool:return String(e.get("key","")).begins_with("crisis:%s:" % String(c.id)))

func _logged(kind:String,c:Dictionary)->bool:
	return (Crisis.state().log as Array).any(func(e:Dictionary)->bool:return String(e.get("kind",""))==kind and String(e.get("crisis",""))==String(c.id))

func _crisis_matters()->Array:
	return (Hall.state().matters as Array).filter(func(m:Variant)->bool:return m is Dictionary and String((m as Dictionary).get("situation_type",""))=="crisis")


func test_grave_is_measured_by_expected_deaths_share_and_spread()->void:
	# A typical fever of a band of 112 (the measured campaign): mild.
	assert_bool(Crisis.is_grave(112.0,0.0023)).is_false()
	assert_bool(Crisis.is_grave(112.0,0.0028)).is_false()
	# A death more likely than one in three, and 3 in 1000 expected dead: grave.
	assert_bool(Crisis.is_grave(112.0,0.0031)).is_true()
	assert_bool(Crisis.is_grave(112.0,0.0063)).is_true()
	# A large people: expected deaths alone do not make a fever grave.
	assert_bool(Crisis.is_grave(1000.0,0.0025)).is_false()
	assert_bool(Crisis.is_grave(1000.0,0.004)).is_true()
	# A tenth or more falling ill is grave at any size.
	assert_bool(Crisis.is_grave(40.0,0.014)).is_true()


func test_a_mild_sickness_is_met_by_custom_without_the_court()->void:
	var c:=_open(0.001)
	assert_bool(c.is_empty()).is_false()
	assert_bool(bool(c.get("quiet",false))).is_true()
	assert_str(String(c.matter)).is_equal("")
	assert_bool(_crisis_matters().is_empty()).is_true()
	assert_str(String(c.choice)).is_equal("tend")
	assert_bool(_logged("mild",c)).is_true()
	assert_bool(_logged("onset",c)).is_false()
	assert_int(int((Crisis.stats().get("sickness",{}) as Dictionary).get("mild",0))).is_equal(1)
	# People are ill, and the season's work is lighter while they are down.
	assert_int(int(c.sick)).is_greater_equal(3)
	var labour:=0.0
	for mod in GameState.active_modifiers:
		if String(mod.get("crisis",""))==String(c.id): labour+=float((mod.effects as Dictionary).get("labor_multiplier",0.0))
	assert_float(labour).is_less(0.0)
	# No card at onset, middle or end.
	_run_to(c,int(c.end_day)+2)
	assert_str(String(c.phase)).is_equal("done")
	assert_array(_cards_of(c)).is_empty()
	assert_bool(_crisis_matters().is_empty()).is_true()
	assert_int(Chronicle.pending_cards.size()).is_equal(0)
	assert_bool(_logged("mild_end",c)).is_true()
	assert_bool((Crisis.state().history as Array).is_empty()).is_true()
	assert_int(Crisis.mild_log().size()).is_equal(1)


func test_the_custom_of_keeping_the_sick_apart_is_followed()->void:
	(Crisis.state().flags as Dictionary)["apart_custom"]=true
	var c:=_open(0.001)
	assert_bool(bool(c.get("quiet",false))).is_true()
	assert_str(String(c.choice)).is_equal("apart")
	assert_float(float(c.mult)).is_equal_approx(0.4,0.0001)


func test_a_grave_sickness_still_comes_to_court()->void:
	var c:=_open(0.3)
	assert_bool(bool(c.get("quiet",false))).is_false()
	assert_bool(_logged("onset",c)).is_true()
	var onset:=_cards_of(c).filter(func(e:Dictionary)->bool:return String(e.key).ends_with(":onset"))
	assert_array(onset).is_not_empty()
	assert_str(String(c.choice)).is_equal("")


func test_mild_deaths_are_real_counted_and_told_in_the_year()->void:
	var pop0:=GameState.population_total
	var c:=_open(0.001)
	assert_bool(bool(c.get("quiet",false))).is_true()
	# Stand in for a harder course: expected deaths about two, never two by the turn.
	c.m=0.002; c.mult=8.0
	_run_to(c,int(c.end_day)+2)
	var dead:=int(c.deaths)
	assert_bool(bool(c.get("quiet",false))).is_true()
	assert_int(dead).is_greater_equal(1)
	assert_int(GameState.population_total).is_equal(pop0-dead)
	assert_int(int((Crisis.stats().get("sickness",{}) as Dictionary).get("deaths",0))).is_equal(dead)
	assert_array(_cards_of(c)).is_empty()
	var mild:Array=(GameState.chronicle.get("year_acc",{}) as Dictionary).get("mild",[])
	assert_int(mild.size()).is_equal(1)
	assert_int(int(mild[0].deaths)).is_equal(dead)
	assert_array(mild[0].dead).is_not_empty()
	var line:=Years.mild_line(mild,{"seed":1,"recent":{},"used":[]})
	assert_str(line).contains(String(mild[0].dead[0]).get_slice(",",0))
	assert_str(line).contains("died of it")
	# Mild sicknesses are not crisis callbacks.
	assert_array(Annals.crisis_log(GameState.chronicle)).is_empty()


func test_a_mild_sickness_that_turns_grave_comes_to_court_at_its_turn()->void:
	var c:=_open(0.001)
	assert_bool(bool(c.get("quiet",false))).is_true()
	c.m=0.002; c.mult=40.0   # deaths mount: three or more by the turn
	_run_to(c,int(c.mid_day)+1)
	assert_bool(bool(c.get("quiet",false))).is_false()
	assert_bool(c.has("escalated")).is_true()
	assert_int(int(c.deaths)).is_greater_equal(Crisis.ESCALATE_DEATHS)
	assert_bool(_logged("onset",c)).is_true()
	var cards:=_cards_of(c)
	assert_array(cards).is_not_empty()
	assert_str(String(cards[0].title)).contains("Sickness Spreads")
	assert_int(int((Crisis.stats().get("sickness",{}) as Dictionary).get("escalated",0))).is_equal(1)
	# From here it is a court crisis: a second decision, an end, a history.
	assert_str(String(c.get("matter_phase","mid"))).is_equal("mid")
	_run_to(c,int(c.end_day)+2)
	assert_bool(_cards_of(c).any(func(e:Dictionary)->bool:return String(e.key).ends_with(":end"))).is_true()
	assert_bool((Crisis.state().history as Array).any(func(h:Dictionary)->bool:return String(h.id)==String(c.id))).is_true()
	assert_bool(Crisis.mild_log().is_empty()).is_true()


func test_one_mild_sickness_is_one_plain_line()->void:
	var f:={"kind":"cough","where":"at the east fire","season":"autumn","part":"late","sick":9,"days":42,"deaths":1,"dead":["Ashti, an old woman"]}
	var seen:={}
	for seed in 6:
		var line:=Years.mild_line([f],{"seed":seed,"recent":{},"used":[]})
		seen[line]=true
		assert_str(line.to_lower()).contains("cough")
		assert_str(line).contains("east fire")
		assert_str(line).contains("late autumn")
		assert_str(line).contains("nine")
		assert_str(line).contains("Ashti, an old woman, died of it")
		assert_str(line).contains("six weeks")
	assert_int(seen.size()).is_greater(1)
	var none:=f.duplicate(); none.deaths=0; none.dead=[]
	assert_str(Years.mild_line([none],{"seed":1,"recent":{},"used":[]})).contains("no one died")


func test_several_mild_sicknesses_are_counted_across_the_year()->void:
	var year:=[{"kind":"cough","where":"at the east fire","season":"winter","part":"early","sick":8,"days":50,"deaths":0,"dead":[]},
		{"kind":"flux","where":"at the fires by the water","season":"summer","part":"","sick":7,"days":45,"deaths":1,"dead":["Tesk, a small boy"]},
		{"kind":"fever","where":"among the old ones' hearths","season":"autumn","part":"late","sick":9,"days":60,"deaths":0,"dead":[]}]
	var line:=Years.mild_line(year,{"seed":3,"recent":{},"used":[]})
	assert_str(line.to_lower()).contains("three")
	assert_str(line).contains("24")
	assert_str(line).contains("the flux at the fires by the water in the summer")
	assert_str(line).contains("Tesk, a small boy")


func test_a_year_with_only_mild_sicknesses_is_not_called_free_of_sickness()->void:
	var a:={"year":10,"pop0":0,"crises":[],"deaths":[],"heads":[],"learned":[],"scouts":{"n":0},"aims":[],"works":[],"contacts":[],"wars":[],
		"mild":[{"kind":"cough","where":"at the east fire","season":"winter","part":"","sick":8,"days":40,"deaths":0,"dead":[]}]}
	var annals:=[{"y":8,"crises":0,"deaths":0},{"y":9,"crises":0,"deaths":0}]
	var text:=" ".join(Years.entry(Years.items(a,annals,{"seed":2,"era":"tally","recent":{},"used":[],"regard":"","divine":[],"pop":0,"change":{}})).lines)
	assert_str(text.to_lower()).contains("cough")
	assert_str(text.to_lower()).not_contains("no sickness")
	assert_str(text.to_lower()).not_contains("without sickness")
	assert_bool(Years.troubled({"crises":0,"mild":1})).is_true()
	assert_bool(Years.troubled({"crises":0})).is_false()


func test_the_year_entry_carries_the_folded_line()->void:
	GameState.elapsed_days=10
	Chronicle.ingest_day({"discoveries":[],"progression":[]})
	GameState.elapsed_days=400
	var c:=_open(0.001)
	_run_to(c,int(c.end_day)+2)
	GameState.elapsed_days=float((int(GameState.elapsed_days)/365+1)*365+1)
	Chronicle.ingest_day({"discoveries":[],"progression":[]})
	var annal:={}
	for e in GameState.chronicle.get("entries",[]):
		if String(e.get("key","")).begins_with("annal:"): annal=e
	assert_bool(annal.is_empty()).is_false()
	var fact:Dictionary=Crisis.mild_log()[0]
	assert_str(String(annal.text)).contains(Years._round_where(String(fact.where)))
	assert_str(String(annal.text)).contains(Years.num(int(fact.sick)))
	var memory:Array=(GameState.chronicle.annals as Array).filter(func(m:Dictionary)->bool:return int(m.get("mild",0))>0)
	assert_int(memory.size()).is_equal(1)
	assert_int(int(memory[0].get("crises",0))).is_equal(0)


func test_a_crisis_saved_before_the_change_carries_on()->void:
	var c:=_open(0.3)
	# An older save's crisis has neither of the new keys.
	c.erase("quiet"); c.erase("hunger0")
	_run_to(c,int(c.end_day)+2)
	if String(c.phase)=="remember": _run_to(c,int(GameState.elapsed_days)+Crisis.MID_DECIDE_DAYS+2)
	assert_str(String(c.phase)).is_equal("done")
	assert_bool(_cards_of(c).any(func(e:Dictionary)->bool:return String(e.key).ends_with(":end"))).is_true()
	var saved:=(Crisis.state() as Dictionary).duplicate(true)
	saved.erase("mild_log")
	assert_bool(Crisis.valid_state(saved)).is_true()
	assert_bool(Crisis.valid_state(Crisis.state())).is_true()
