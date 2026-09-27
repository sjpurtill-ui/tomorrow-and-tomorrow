extends GdUnitTestSuite
## The town's upkeep (upkeep_warnings.gd): the official who runs the town's
## work warns when its buildings wear out faster than they are mended, as a
## court matter the god summons (never unbidden), at real thresholds, without
## nagging; the offline answer moves people through the settlement's real
## focus; the god's typed words (online) choose the same answers or reach the
## live voice with the same facts; the recovery is told; the state saves.
## Never calls a real API.

const UW:=preload("res://scripts/upkeep_warnings.gd")
const Hall:=preload("res://scripts/audience_hall.gd")
const Chronicle:=preload("res://scripts/chronicle.gd")
const Years:=preload("res://scripts/chronicle_years.gd")
const Voice:=preload("res://scripts/audience_voice.gd")
const CV:=preload("res://scripts/character_voice.gd")
const SEED:=880088

var day:=400

func before_test()->void:
	WorldSimulation.clear()
	GameState.set_process(false); CivilizationSystem.set_process(false); MilitaryCampaign.set_process(false)
	GameState.reset_for_new_world(SEED); GameState.civic_api_enabled=false
	CivilizationSystem.reset_for_new_world()
	ForeignDiplomacy.reset_for_new_world(); GovernmentPeopleSystem.reset_for_new_world()
	GameState.ensure_population_total(150); GameState.housing_capacity=200
	GameState.settlement_site_committed=true; GameState.settlement_founded_day=0; GameState.settlement_completed=["Hearth Circle"]; SettlementModel.ensure_founded()
	GameState.population_health=0.9; GameState.simulation_metrics.merge({"food_days":60.0,"food_intake_ratio":1.0,"security":0.6,"cohesion":0.7},true)
	GovernmentPeopleSystem.initialize()
	day=400
	GameState.elapsed_days=day

func _town(condition:float,builders:int,paid:float=1.0)->void:
	var form:Dictionary=SettlementModel.city_form()
	form["condition"]=condition
	form["materials_paid"]=paid
	GameState.population_allocations["Construction"]=builders

func _month(months:int=1)->void:
	for i in months:
		day+=30
		GameState.elapsed_days=day
		UW.daily(day)

func _upkeep_matters()->Array:
	return (Hall.state().matters as Array).filter(func(m:Variant)->bool:return m is Dictionary and String(m.get("situation_type",""))=="upkeep")

func _told(stage:String)->int:
	var n:=0
	for entry in Chronicle.data().entries:
		if String((entry as Dictionary).get("key","")).begins_with("upkeep:%s:" % stage): n+=1
	return n

func _summon()->Dictionary:
	var person:=UW.holder()
	assert_bool(person.is_empty()).override_failure_message("no official to hold the matter").is_false()
	return Hall.summon({"person_id":int(person.person_id)})

func test_holder_is_the_town_leader_or_hearth_chief()->void:
	var person:=UW.holder()
	assert_bool(person.is_empty()).is_false()
	assert_bool(String(person.get("office_key","")) in ["settlement","Steward"]).override_failure_message(str(person.get("office_key",""))).is_true()

func test_thresholds_hysteresis_and_no_nagging()->void:
	# Sound and kept: nothing to say.
	_town(0.9,40)
	_month()
	assert_str(String(UW.state().stage)).is_equal("sound")
	assert_array(_upkeep_matters()).is_empty()
	# Still sound but wearing, and bad within the year: a heads-up.
	_town(0.62,0)
	_month()
	assert_str(String(UW.state().stage)).is_equal("slipping")
	assert_int(_upkeep_matters().size()).is_equal(1)
	assert_int(_told("slipping")).is_equal(1)
	# Nothing new within the season: no second notice, no renewed matter.
	var filed:=int(UW.state().last_filed)
	_town(0.60,0)
	_month()
	assert_int(int(UW.state().last_filed)).is_equal(filed)
	assert_int(_told("slipping")).is_equal(1)
	# Below 0.48 and still falling: news again.
	_town(0.44,0)
	_month()
	assert_str(String(UW.state().stage)).is_equal("failing")
	assert_int(_told("failing")).is_equal(1)
	assert_int(_upkeep_matters().size()).is_equal(1)
	filed=int(UW.state().last_filed)
	# Unresolved: renewed quietly at most once a season.
	for i in 2:
		_town(0.40-0.02*i,0)
		_month()
	assert_int(int(UW.state().last_filed)).is_equal(filed)
	_town(0.36,0)
	_month()
	assert_int(int(UW.state().last_filed)).is_equal(day)
	assert_int(_told("failing")).is_equal(1)
	# Wobbling around the line is not fresh news.
	_town(0.47,0)
	_month()
	_town(0.49,0)
	_month()
	assert_str(String(UW.state().stage)).is_equal("failing")
	assert_int(_told("failing")).is_equal(1)
	assert_int(_told("slipping")).is_equal(1)
	# At the floor: news once more.
	_town(0.05,0)
	_month()
	assert_str(String(UW.state().stage)).is_equal("floor")
	assert_int(_told("floor")).is_equal(1)
	# Builders at work lift it off the floor quietly; sound again is told.
	_town(0.30,60)
	_month()
	assert_str(String(UW.state().stage)).is_equal("failing")
	assert_int(_told("failing")).is_equal(1)
	_town(0.60,60)
	_month()
	assert_str(String(UW.state().stage)).is_equal("sound")
	assert_int(_told("sound")).is_equal(1)
	assert_array(_upkeep_matters()).is_empty()
	# The year's entry carries the news.
	var told:Array=(Chronicle.data().get("year_acc",{}) as Dictionary).get("upkeep",[])
	assert_bool(told.is_empty()).is_false()

func test_let_it_be_stops_the_asking_until_it_gets_worse()->void:
	_town(0.40,0)
	_month()
	var audience:=_summon()
	assert_str(String((audience.petition as Dictionary).topic)).is_equal("upkeep")
	assert_bool((audience.lines as Array).size()>=2).is_true()
	var result:=Hall.resolve(String(audience.id),"accept")
	assert_bool(bool(result.ok)).is_true()
	var filed:=int(UW.state().last_filed)
	for i in 6:
		_town(0.38-0.03*i,0)
		_month()
	assert_int(int(UW.state().last_filed)).is_equal(filed)
	assert_array(_upkeep_matters()).is_empty()
	_town(0.05,0)
	_month()
	assert_str(String(UW.state().stage)).is_equal("floor")
	assert_int(_upkeep_matters().size()).is_equal(1)

func test_offline_answer_moves_people_to_building_and_lifts_on_recovery()->void:
	_town(0.40,1)
	_month()
	var id:=UW.primary_settlement_id()
	GovernmentPeopleSystem.process_day(day)
	_town(0.40,1)
	var before:=GovernmentPeopleSystem.settlement_management(id)
	var before_share:=float((before.allocations as Dictionary).get("Construction",0.0))
	var before_pct:=float(GameState.population_allocation_percentages.get("Construction",0.0))
	var audience:=_summon()
	var said:=String(((audience.lines as Array).back() as Dictionary).get("text",""))
	# Plain facts: what is happening, how many build, how many are needed, what it costs.
	assert_str(said).contains("falling apart")
	assert_str(said).contains("them up")
	assert_str(said).contains("we need about")
	assert_str(said).contains("store pits")
	assert_bool(CV.permits(said,[])).override_failure_message("anachronism in: "+said).is_true()
	var ids:Array=Hall.options(String(audience.id)).map(func(o:Dictionary)->String:return String(o.id))
	assert_array(ids).contains(["more_builders","accept"])
	var result:=Hall.resolve(String(audience.id),"more_builders")
	assert_bool(bool(result.ok)).override_failure_message(str(result)).is_true()
	var after:=GovernmentPeopleSystem.settlement_management(id)
	assert_str(String(after.focus)).is_equal("shelter")
	assert_bool(bool(after.auto_manage)).is_false()
	assert_float(float((after.allocations as Dictionary).get("Construction",0.0))).is_greater(before_share)
	# GovernmentPeopleSystem's daily delegation carries it into the town's labour.
	GovernmentPeopleSystem.process_day(day+1)
	assert_float(float(GameState.population_allocation_percentages.get("Construction",0.0))).is_greater(before_pct)
	# No second order while the first stands.
	_town(0.35,1)
	_month(3)
	var again:=_summon()
	var open:=Hall.options(String(again.id)).filter(func(o:Dictionary)->bool:return String(o.id)=="more_builders")
	assert_bool(bool((open[0] as Dictionary).enabled)).is_false()
	Hall.resolve(String(again.id),"accept")
	# Sound again: the order is lifted and the leader chooses again.
	_town(0.62,60)
	_month()
	assert_str(String(UW.state().stage)).is_equal("sound")
	assert_bool(bool(GovernmentPeopleSystem.settlement_management(id).auto_manage)).is_true()
	var recovered:=""
	for entry in Chronicle.data().entries:
		if String((entry as Dictionary).get("key","")).begins_with("upkeep:sound:"): recovered=String(entry.text)
	assert_str(recovered).contains("sound again")
	assert_str(recovered).contains("gone back")

func test_online_words_choose_answers_and_the_live_voice_gets_the_facts()->void:
	_town(0.40,1)
	_month()
	var audience:=_summon()
	var id:=String(audience.id)
	assert_str(UW.typed_choice(id,"Put more people on the roofs.")).is_equal("more_builders")
	assert_str(UW.typed_choice(id,"Leave it. It can wait.")).is_equal("accept")
	assert_str(UW.typed_choice(id,"Why is this happening?")).is_equal("")
	# Anything else goes to the live voice, with the same facts (mocked transport).
	var sent:Array=[]
	var voice:Node=auto_free(Voice.new())
	add_child(voice)
	voice.config_override={"endpoint":"https://api.openai.com/v1/chat/completions","api_key":"test-key-not-real","model":"gpt-6-luna","structured_output":true}
	voice.send_hook=func(_id:String,payload:Dictionary,_attempt:int)->void:sent.append(payload)
	voice.player_speaks(id,"Why is this happening?")
	assert_int(sent.size()).is_equal(1)
	var prompt:=JSON.stringify(sent[0])
	assert_str(prompt).contains("falling apart")
	assert_str(prompt).contains("builders_to_mend")
	assert_str(prompt).contains("monthly_change")

func test_slipping_and_floor_words_are_plain_and_era_grounded()->void:
	for stage in ["slipping","failing","floor"]:
		for paid in [1.0,0.8,0.3]:
			_town(0.62 if stage=="slipping" else (0.4 if stage=="failing" else 0.05),2,paid)
			var text:=UW.spoken(UW.facts(),stage,false)
			assert_bool(CV.permits(text,[])).override_failure_message("anachronism in: "+text).is_true()
			assert_bool(text.contains("{")).is_false()
			if paid<0.5: assert_str(text).contains("hands alone will not do it")

func test_year_entry_line()->void:
	var out:Array=[]
	Years._upkeep({"upkeep":[{"stage":"failing","homes":"huts"},{"stage":"sound","homes":"huts"}]},out)
	assert_str(String(out[0].text)).is_equal("The huts fell into disrepair for want of builders, and were made sound again.")
	out.clear()
	Years._upkeep({"upkeep":[{"stage":"slipping","homes":"houses"},{"stage":"floor","homes":"houses"}]},out)
	assert_str(String(out[0].text)).is_equal("The houses were left nearly in ruins.")

func test_state_survives_a_save_round_trip()->void:
	_town(0.40,1)
	_month()
	var audience:=_summon()
	Hall.resolve(String(audience.id),"more_builders")
	UW.state().accepted="slipping"
	var saved:Variant=JSON.parse_string(JSON.stringify(ForeignDiplomacy.audiences))
	assert_bool(Hall.validate_state(saved)).is_true()
	ForeignDiplomacy.audiences=saved
	var s:=UW.state()
	assert_str(String(s.stage)).is_equal("failing")
	assert_str(String(s.accepted)).is_equal("slipping")
	assert_int(int(s.last_filed)).is_equal(day)
	assert_str(String((s.order as Dictionary).get("settlement_id",""))).is_equal(UW.primary_settlement_id())
	# A corrupted block is refused; an older save simply has none.
	var bad:Dictionary=(saved as Dictionary).duplicate(true)
	bad["upkeep"]={"stage":"exploded"}
	assert_bool(Hall.validate_state(bad)).is_false()
	var old:Dictionary=(saved as Dictionary).duplicate(true)
	old.erase("upkeep")
	assert_bool(Hall.validate_state(old)).is_true()
