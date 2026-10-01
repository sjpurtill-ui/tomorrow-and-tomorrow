extends GdUnitTestSuite
## OFFICE LEVERS (scripts/office_levers.gd): each office's holder moves one
## thing the engine applies every day, by a stated amount, and the screens
## and the court's reports say so in numbers. An ordinary holder (every skill
## 47) moves nothing; the best and worst holders reach the stated ends; the
## lever reaches the people in full below 500 and through the clerks above;
## the Headman stands in, at half, for the offices not yet open.

const Levers:=preload("res://scripts/office_levers.gd")
const HomeOrders:=preload("res://scripts/home_orders.gd")
const DivineRegard:=preload("res://scripts/divine_regard.gd")
const TEST_SEED:=731205


func before_test()->void:
	GameState.reset_for_new_world(TEST_SEED)
	GovernmentPeopleSystem.reset_for_new_world()
	GameState.initialize_population_model()
	GameState.settlement_name="Lever Ford"
	GameState.settlement_site_committed=true
	GameState.settlement_completed=["Hearth Circle"]
	GameState.settlement_founded_at=Vector3(12.0,0.0,-8.0)
	SettlementModel.ensure_founded()
	GovernmentPeopleSystem.initialize()
	Levers.clear_cache()


func after_test()->void:
	MilitaryCampaign.equipment_queue.clear()
	GameState.active_modifiers.clear()
	Levers.clear_cache()


static func _person(id:int,skills:Dictionary,traits:Array=[])->Dictionary:
	var full:={}
	for skill in GovernmentPeopleSystem.SKILL_KEYS: full[skill]=47
	for skill in skills: full[skill]=skills[skill]
	return {"person_id":id,"name":"Test%d Person" % id,"skills":full,"traits":traits,"status":"active",
		"personality":{"openness":0.5,"discipline":0.5,"empathy":0.5,"assertiveness":0.5,"risk_tolerance":0.5},
		"relationships":{"sovereign":{"trust":0.5,"respect":0.5,"fear":0.0,"resentment":0.0,"obligation":0.4}},"experience_months":0}


func _seat(office:String,person:Dictionary)->void:
	GameState.leadership_positions[office]=person


func test_unlock_ranks_agree_with_the_government()->void:
	for definition:Dictionary in GovernmentPeopleSystem.OFFICE_DEFINITIONS:
		assert_int(int(Levers.UNLOCK[String(definition.key)])).override_failure_message(String(definition.key)).is_equal(int(definition.unlock))


func test_an_ordinary_holder_moves_nothing_and_the_ends_are_the_stated_ones()->void:
	var ordinary:=Levers.ordinary_person()
	for office:String in Levers.LEVERS:
		var spec:Dictionary=Levers.LEVERS[office]
		var neutral:=1.0 if String(spec.kind)=="mul" else 0.0
		assert_float(Levers.person_lever(ordinary,office)).override_failure_message(office).is_equal_approx(neutral,0.0001)
		var best:={}; var worst:={}
		for skill in spec.skills: best[skill]=95; worst[skill]=5
		assert_float(Levers.person_lever(_person(1,best),office)).override_failure_message(office).is_equal_approx(float(spec.best),0.0001)
		assert_float(Levers.person_lever(_person(2,worst),office)).override_failure_message(office).is_equal_approx(float(spec.worst),0.0001)
	# A realistic keeper (Provisioning 85, the rest ordinary) lands about three
	# quarters of the way to the best end: inside the stated range.
	var keeper:=Levers.person_lever(_person(3,{"Provisioning":85}),"Quartermaster")
	assert_float(keeper).is_between(0.80,0.90)


func test_the_keeper_of_stores_changes_what_rots_by_the_lever()->void:
	GovernmentPeopleSystem.government_stage=1
	_seat("Quartermaster",Levers.ordinary_person().merged({"person_id":901,"name":"Plain Keeper"},true))
	var plain:Array=FoodSystem._spoilage_rates(false)
	var great:=_person(902,{"Provisioning":90,"Logistics":70})
	_seat("Quartermaster",great)
	var lever:=Levers.value("Quartermaster")
	assert_float(lever).is_less(0.88)
	var kept:Array=FoodSystem._spoilage_rates(false)
	assert_float(float(kept[0])/float(plain[0])).is_equal_approx(lever,0.0001)
	assert_float(float(kept[1])/float(plain[1])).is_equal_approx(lever,0.0001)


func test_the_headman_stands_in_at_half_for_an_office_not_yet_open()->void:
	GovernmentPeopleSystem.government_stage=0
	var headman:=_person(903,{"Provisioning":95,"Logistics":95,"Administration":95})
	_seat("Steward",headman)
	GameState.leadership_positions.erase("Quartermaster")
	var who:=Levers.holder_of("Quartermaster")
	assert_bool(bool(who.acting)).is_true()
	var raw:=Levers.person_lever(headman,"Quartermaster")
	assert_float(Levers.value("Quartermaster")).is_equal_approx(1.0+(raw-1.0)*Levers.STAND_IN_SHARE,0.0001)
	# The lore keeper too; but the priests, judges and treasury do not exist yet.
	assert_float(Levers.value("HighPriest")).is_equal(0.0)
	assert_float(Levers.value("Justice")).is_equal(1.0)


func test_reach_is_full_for_a_band_and_set_by_the_clerks_for_a_realm()->void:
	GameState.population_exact=120.0
	assert_float(Levers.reach()).is_equal(1.0)
	GameState.population_exact=50_000.0
	GameState.elapsed_days=10.0
	GameState.population_allocations["Administration"]=10.0
	GameState.society_capacities["institutions"]=0.2
	Levers.clear_cache()
	var thin:=Levers.reach()
	assert_float(thin).is_equal_approx(Levers.MIN_REACH,0.0001)
	# The same keeper reaches the people only through the clerks.
	GovernmentPeopleSystem.government_stage=1
	var great:=_person(904,{"Provisioning":95,"Logistics":95,"Administration":95})
	_seat("Quartermaster",great)
	assert_float(Levers.value("Quartermaster")).is_equal_approx(1.0+(Levers.person_lever(great,"Quartermaster")-1.0)*thin,0.0001)
	GameState.population_allocations["Administration"]=1800.0
	GameState.society_capacities["institutions"]=0.9
	GameState.elapsed_days=11.0
	assert_float(Levers.reach()).is_greater(0.9)


func test_execution_weighs_competence_more_but_an_ordinary_official_is_unchanged()->void:
	var ordinary:=Levers.ordinary_person()
	var institutions:=clampf(float(GameState.society_capacities.get("institutions",0.5)),0.0,1.0)
	var burden:=float(ConsequenceEngine.administrative_load())
	var task:=GovernmentPeopleSystem.competency(ordinary,["Provisioning"])
	var fit:=GovernmentPeopleSystem.office_competency(ordinary,"Quartermaster")
	var competence:=task*0.70+fit*0.30
	var structural:=0.0
	if DiscoverySystem.society_model!=null: structural=DiscoverySystem.society_model.doctrine_execution_strength("")*0.22
	var before:=clampf(0.36+competence*0.46+0.5*0.055+0.5*0.035+institutions*0.16+structural-burden*0.42,0.35,1.12)
	var now:=float(AdvisorSystem.execution_modifier_for_advisor(ordinary,"Quartermaster",["Provisioning"]))
	assert_float(now).is_equal_approx(before,0.01)
	var great:=_person(905,{"Provisioning":92,"Logistics":80})
	var great_now:=float(AdvisorSystem.execution_modifier_for_advisor(great,"Quartermaster",["Provisioning"]))
	var great_task:=GovernmentPeopleSystem.competency(great,["Provisioning"])
	var great_fit:=GovernmentPeopleSystem.office_competency(great,"Quartermaster")
	var great_before:=clampf(0.36+(great_task*0.70+great_fit*0.30)*0.46+0.5*0.055+0.5*0.035+institutions*0.16+structural-burden*0.42,0.35,1.12)
	assert_float(great_now).is_greater(great_before)


func test_the_card_reads_the_holder_an_ordinary_one_and_the_best_free_candidate()->void:
	GovernmentPeopleSystem.government_stage=1
	var keeper:=_person(906,{"Provisioning":82})
	_seat("Quartermaster",keeper)
	var card:=Levers.card("Quartermaster")
	assert_str(String(card.text)).contains("of what would rot")
	assert_str(String(card.text)).contains("an ordinary ")
	assert_str(String(card.text)).contains(" 0%")
	# The best free candidate is one of the cast, with a number of their own.
	var best:Dictionary=card.best
	assert_bool(best.is_empty()).is_false()
	assert_str(String(card.text)).contains(String(best.name).get_slice(" ",0)+" would ")
	assert_str(String(card.tip)).contains("x1.15 to x0.80")


func test_a_ration_ordered_through_the_keeper_saves_more_under_a_good_one_and_says_so()->void:
	GovernmentPeopleSystem.government_stage=1
	var keeper:=_person(907,{"Provisioning":93,"Logistics":85,"Administration":80})
	_seat("Quartermaster",keeper)
	var done:=HomeOrders.perform(HomeOrders.read("Ration the food"))
	assert_bool(bool(done.get("ok",false))).override_failure_message(str(done)).is_true()
	var pace:=float((done.get("holder",{}) as Dictionary).get("pace",1.0))
	assert_float(pace).is_greater(1.05)
	var ration:Dictionary={}
	for mod in GameState.active_modifiers:
		if String((mod as Dictionary).get("id","")).begins_with("court_ration"): ration=mod
	assert_float(float((ration.effects as Dictionary).food_demand)).is_equal_approx(-0.75*pace,0.0001)
	assert_str(String(done.outcome)).contains("Test907")
	assert_str(String(done.outcome)).contains("in 100 less is eaten")


func test_a_workshop_job_an_order_put_in_hand_goes_at_the_keepers_pace()->void:
	GovernmentPeopleSystem.government_stage=1
	_seat("Quartermaster",_person(908,{"Provisioning":95,"Logistics":95,"Administration":90}))
	var from:=int(MilitaryCampaign.next_equipment_job_id)
	MilitaryCampaign.equipment_queue.append({"id":from,"job_type":"transport","item":"transport_cart","count":2,"completed":0,"progress_days":0.0,"work_per_item":10.0,"required_days":20.0})
	MilitaryCampaign.next_equipment_job_id=from+1
	var done:=Levers.with_holder({"ok":true,"kind":"carts","count":2,"says":"","outcome":"2 carts put in hand."},from)
	var pace:=float(done.holder.pace)
	assert_float(pace).is_greater(1.05)
	var job:Dictionary=MilitaryCampaign.equipment_queue[0]
	assert_float(float(job.required_days)).is_equal_approx(20.0/pace,0.0001)
	assert_str(String(done.outcome)).contains("faster than an ordinary")
	# Paced once only.
	Levers.with_holder({"ok":true,"kind":"carts","count":2,"says":"","outcome":""},from)
	assert_float(float((MilitaryCampaign.equipment_queue[0] as Dictionary).required_days)).is_equal_approx(20.0/pace,0.0001)


func test_the_arbiter_eases_the_resistance_orders_meet()->void:
	GameState.leadership_positions.erase("Justice")
	var plain:Dictionary=ConsequenceEngine.directive_assessment("care_rotation",0.18,120)
	var judge:=_person(909,{"Administration":92,"Knowledge":80})
	_seat("Justice",judge)
	var lever:=Levers.value("Justice")
	assert_float(lever).is_less(0.85)
	var eased:Dictionary=ConsequenceEngine.directive_assessment("care_rotation",0.18,120)
	assert_float(float(eased.resistance)).is_equal_approx(float(plain.resistance)*lever,0.0001)


func test_the_priest_raises_the_peoples_love()->void:
	GameState.leadership_positions.erase("HighPriest")
	var plain:=float(DivineRegard.people_regard([]).love)
	_seat("HighPriest",_person(910,{"Diplomacy":90,"Knowledge":80}))
	var lever:=Levers.value("HighPriest")
	assert_float(lever).is_greater(0.03)
	var loved:=float(DivineRegard.people_regard([]).love)
	assert_float(loved-plain).is_equal_approx(lever,0.0001)


func test_the_messenger_wins_favour_with_another_ruler()->void:
	GovernmentPeopleSystem.government_stage=4
	_seat("Envoy",_person(911,{"Diplomacy":93,"Logistics":70}))
	var sway:=Levers.value("Envoy")
	assert_float(sway).is_greater(0.06)
	var card:=Levers.card("Envoy")
	assert_str(String(card.text)).contains("points more favour")


func test_each_lever_is_wired_into_its_engine_hook()->void:
	# The hooks the engine reads every day (see the table in office_levers.gd).
	var hooks:={"res://scripts/consequence_engine.gd":['OfficeLevers.labour()','OfficeLevers.value("Justice")'],
		"res://scripts/food_system.gd":['value("Quartermaster")'],"res://scripts/society_model.gd":['value("Scholar")'],
		"res://scripts/civilization_system.gd":['value("ChiefScout")','value("Envoy")'],"res://scripts/foreign_diplomacy.gd":['value("Envoy")'],
		"res://scripts/divine_regard.gd":['value("HighPriest")'],"res://scripts/economy_system.gd":['value("Treasurer")'],
		"res://scripts/home_orders.gd":["with_holder("]}
	for path:String in hooks:
		var source:=FileAccess.get_file_as_string(path)
		for needle:String in hooks[path]: assert_str(source).override_failure_message("%s lacks %s" % [path,needle]).contains(needle)


func test_the_war_leaders_card_reads_the_home_band()->void:
	GovernmentPeopleSystem.government_stage=2
	var strong:=_person(912,{"Defense":92,"Logistics":70,"Knowledge":60})
	_seat("Marshal",strong)
	var card:=Levers.marshal_card()
	assert_bool(card.is_empty()).is_false()
	assert_str(String(card.text)).contains("The home band fights")
	assert_float(float(card.holder)).is_greater(0.0)
	# The same reading as the war leader the army takes.
	var commander:Dictionary=MilitaryCampaign._marshal_commander()
	var mine:=Levers.marshal_command(strong)
	assert_float(float(mine.command)).is_equal_approx(float(commander.command)-float(MilitaryCampaign.command_development.get("command",0.0)),0.0001)


func test_the_research_atlas_names_the_leaders_own_skills_and_the_pace()->void:
	var holder:=GovernmentPeopleSystem.officeholder("Steward")
	var line:String=preload("res://scripts/hud/research_atlas.gd")._leader_line({"office":"Steward","requested_office":"Steward","person_id":int(holder.person_id),"vacant":false,"skills":["Administration","Construction"]})
	assert_str(line).contains("administration %d" % roundi(GovernmentPeopleSystem.skill_value(holder,"Administration")))
	assert_str(line).contains("than under an ordinary leader")
