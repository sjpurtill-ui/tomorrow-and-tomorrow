extends GdUnitTestSuite
## THE RULER MAKES EVERY PROPOSAL. Officials report, answer and carry out;
## they bring no plans of their own: no ambitions or first tasks, no
## suggested decree on a report, no aims, no wonder pitches, no council
## recommendations. The god sets a generation's aim by word in the court.

const Hall:=preload("res://scripts/audience_hall.gd")
const Aims:=preload("res://scripts/legacy_aims.gd")
const HomeOrders:=preload("res://scripts/home_orders.gd")

var _processing:Dictionary={}

func before()->void:
	for node:Node in [GameState,CivilizationSystem,MilitaryCampaign,ProgressionSystem]:_processing[node]=node.is_processing()

func after()->void:
	GameState.elapsed_days=0
	MilitaryCampaign.reset_for_new_world()
	GovernmentPeopleSystem.reset_for_new_world()
	CivilizationSystem.reset_for_new_world()
	GameState.reset_for_new_world(74017)
	PeopleDirection.reset_for_new_world()
	WorldSimulation.clear()
	for node:Node in _processing:node.set_process(bool(_processing[node]))

func _people()->void:
	WorldSimulation.clear()
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	GameState.reset_for_new_world(716203)
	GovernmentPeopleSystem.reset_for_new_world()
	CivilizationSystem.reset_for_new_world()
	PeopleDirection.reset_for_new_world()
	GameState.initialize_population_model()
	GameState.ensure_population_total(300)
	GameState.settlement_site_committed=true
	GameState.settlement_completed=["Hearth Circle"]
	SettlementModel.ensure_founded()
	GovernmentPeopleSystem.initialize()
	PeopleDirection.ensure()

func test_officials_raise_no_plans_of_their_own()->void:
	for kind:String in ["ambition","appointment","promise_followup"]:
		assert_bool(kind in Hall.COURT_OCCASIONS).is_false()

func test_a_report_carries_no_suggested_decree_and_offers_none()->void:
	_people()
	GameState.simulation_metrics["food_days"]=4.0
	var audience:Dictionary=Hall.debug_situation("crisis_petition")
	if audience.is_empty():return
	assert_str(String((audience.get("petition",{}) as Dictionary).get("suggested_decree",""))).is_empty()
	var ids:=[]
	for option:Dictionary in Hall.options(String(audience.get("id",""))):ids.append(String(option.id))
	assert_bool("decree" in ids).is_false()
	assert_bool("promise" in ids).is_false()
	assert_bool("heard" in ids).is_true()

func test_old_proposals_are_cleared_from_the_court()->void:
	_people()
	var s:Dictionary=Hall.state()
	(s.matters as Array).append({"id":"matter_x","key":"x","situation_type":"ambition","holder_key":"person:1"})
	(s.occasions as Array).append({"key":"ambition:1:5","type":"ambition","person_id":1,"day":5})
	(s.occasions as Array).append({"key":"grievance:1:1:5","type":"grievance","person_id":1,"day":5})
	Hall._drop_officials_proposals()
	assert_int((s.matters as Array).size()).is_equal(0)
	assert_int((s.occasions as Array).size()).is_equal(1)

func test_the_council_recommends_nothing()->void:
	_people()
	var item:Dictionary=WorldSimulation.advisors.generate_consequence_item({"domain":"food","description":"Food is short.","severity":"critical"})
	assert_dict(item).is_empty()
	assert_array(WorldSimulation.advisors.council_decision_items()).is_empty()

func test_the_god_sets_an_aim_by_word()->void:
	_people()
	assert_dict(HomeOrders.aim_reading("Our aim for this generation is to grow")).is_not_empty()
	assert_dict(HomeOrders.aim_reading("Set the people an aim: to be feared by our neighbours")).is_not_empty()
	assert_dict(HomeOrders.aim_reading("What is our aim?")).is_empty()
	assert_dict(HomeOrders.aim_reading("Send gatherers to find food")).is_empty()
	var said:Dictionary=Aims.court_order("Our aim for this generation is to grow")
	assert_bool(bool(said.ok)).is_true()
	assert_bool(Aims.has_active()).is_true()
	assert_str(String((Aims.active() as Dictionary).chosen_by)).is_equal("god")
	# A new word sets the old aim down and takes up the new one.
	var again:Dictionary=Aims.court_order("Our aim is to learn the working of stone")
	assert_bool(bool(again.ok)).is_true()
	assert_str(String(again.says)).contains("is set aside")

func test_no_aim_is_proposed_or_taken_up_without_the_god()->void:
	_people()
	for day in range(1,2000,10):
		GameState.elapsed_days=float(day)
		Aims.daily(day)
	assert_bool(Aims.has_active()).is_false()
	assert_str(String(Aims.state().matter_id)).is_empty()
