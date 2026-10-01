extends GdUnitTestSuite
## TRAITS WITH TRADE-OFFS AND GROWTH (office_levers.gd TRAIT_LEVERS,
## government_people_system.gd growth in office and age, historical_figures.gd
## temperament and growth): a trait helps one thing and costs another, in the
## numbers the engine applies; officials sharpen in office and dull in age;
## a general's temperament moves their skills while its label stays hidden.

const Levers:=preload("res://scripts/office_levers.gd")
const TEST_SEED:=517733


func before_test()->void:
	GameState.reset_for_new_world(TEST_SEED)
	GovernmentPeopleSystem.reset_for_new_world()
	GameState.initialize_population_model()
	GameState.settlement_name="Growth Hollow"
	GameState.settlement_site_committed=true
	GameState.settlement_completed=["Hearth Circle"]
	GameState.settlement_founded_at=Vector3(12.0,0.0,-8.0)
	SettlementModel.ensure_founded()
	GovernmentPeopleSystem.initialize()
	HistoricalFigures.reset_for_new_world()
	Levers.clear_cache()


func after_test()->void:
	HistoricalFigures.reset_for_new_world()


func test_every_trait_helps_one_thing_and_costs_another()->void:
	for trait_name:String in Levers.TRAIT_LEVERS:
		var deltas:Dictionary=Levers.TRAIT_LEVERS[trait_name]
		if deltas.is_empty(): continue   # Ambitious: grows faster (growth test)
		var helps:=false
		var costs:=false
		for lever_id:String in deltas:
			var better:=float(deltas[lever_id])<0.0 if lever_id in ["spoilage","forgetting","resistance"] else float(deltas[lever_id])>0.0
			if better: helps=true
			else: costs=true
		assert_bool(helps and costs).override_failure_message("%s: %s" % [trait_name,str(deltas)]).is_true()


func test_a_frugal_keeper_spoils_less_and_moves_orders_slower()->void:
	var plain:={"person_id":0,"skills":{"Provisioning":70,"Logistics":60,"Administration":50},"traits":[]}
	var frugal:={"person_id":0,"skills":{"Provisioning":70,"Logistics":60,"Administration":50},"traits":["Frugal"]}
	assert_float(Levers.person_lever(frugal,"Quartermaster")).is_equal_approx(Levers.person_lever(plain,"Quartermaster")-0.08,0.0001)
	var keeper:=Levers.ordinary_person().merged({"person_id":0,"traits":["Frugal"]},true)
	assert_float(Levers.person_order_pace(keeper,"Quartermaster")).is_equal_approx(Levers.person_order_pace(Levers.ordinary_person(),"Quartermaster")-0.04,0.0001)
	# Never past the lever's stated end.
	var best_frugal:={"person_id":0,"skills":{"Provisioning":99,"Logistics":99,"Administration":99},"traits":["Frugal","Skeptical"]}
	assert_float(Levers.person_lever(best_frugal,"Quartermaster")).is_equal_approx(0.80,0.0001)


func test_officials_sharpen_in_office_and_dull_with_age()->void:
	var gov:=GovernmentPeopleSystem
	var keeper:Dictionary=gov.people[1]
	keeper["office_key"]="Quartermaster"
	keeper["experience_months"]=11
	keeper["traits"]=["Patient","Humble"]
	keeper["death_age_years"]=200.0
	keeper["born_day"]=int(GameState.elapsed_days)-40*365
	var before:Dictionary=(keeper.skills as Dictionary).duplicate()
	var events:Array[Dictionary]=[]
	gov._process_lifespans(int(GameState.elapsed_days),events)
	assert_int(int(keeper.experience_months)).is_equal(12)
	assert_int(int(keeper.skills.Provisioning)).is_equal(mini(gov.SKILL_CAP,int(before.Provisioning)+1))
	assert_int(int(keeper.skills.Logistics)).is_equal(mini(gov.SKILL_CAP,int(before.Logistics)+1))
	assert_int(int(keeper.skills.Diplomacy)).is_equal(int(before.Diplomacy))
	# The ambitious grow half again as fast: two in their second year.
	keeper["traits"]=["Ambitious"]
	keeper["experience_months"]=23
	var mid:=int(keeper.skills.Provisioning)
	gov._process_lifespans(int(GameState.elapsed_days),events)
	assert_int(int(keeper.skills.Provisioning)).is_equal(mini(gov.SKILL_CAP,mid+2))
	# Past sixty, a point a year from every skill, counted from now on.
	var elder:Dictionary=gov.people[2]
	elder["born_day"]=int(GameState.elapsed_days)-63*365-10
	elder["death_age_years"]=200.0
	elder.erase("aged_years")
	var kept:Dictionary=(elder.skills as Dictionary).duplicate()
	gov._process_lifespans(int(GameState.elapsed_days),events)
	assert_dict(elder.skills as Dictionary).is_equal(kept)
	assert_int(int(elder.aged_years)).is_equal(3)
	elder["born_day"]=int(elder.born_day)-365
	gov._process_lifespans(int(GameState.elapsed_days),events)
	for key in kept: assert_int(int(elder.skills[key])).is_equal(maxi(gov.SKILL_FLOOR,int(kept[key])-1))


func test_a_generals_temperament_moves_their_skills_and_stays_unsaid()->void:
	HistoricalFigures.ensure()
	var general:Dictionary={}
	for p:Dictionary in HistoricalFigures.people:
		if String(p.role)=="General": general=p
	assert_bool(general.is_empty()).is_false()
	general["temperament"]="patient and exacting"
	general.erase("skills")
	var patient:Dictionary=HistoricalFigures.skills_of(general).duplicate()
	general["temperament"]="bold and impatient"
	general.erase("skills")
	var bold:Dictionary=HistoricalFigures.skills_of(general).duplicate()
	assert_float(float(bold.command)).is_greater_equal(float(patient.command))
	assert_float(float(bold.logistics)).is_less_equal(float(patient.logistics))
	var line:=preload("res://scripts/general_record.gd").lever_line(HistoricalFigures.commander_record(general,{}),String(general.name))
	assert_str(line).not_contains("bold")
	assert_str(line).not_contains("impatient")
