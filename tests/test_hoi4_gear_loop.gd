extends GdUnitTestSuite
## HOI4's deployment loop, end to end: a band queued with no gear in store
## asks the workshops for it, the Quartermaster's lines make it, the band's
## gear bar fills from the stores, it finishes drill and deploys on its own.

const Deploy:=preload("res://scripts/hud/deployment_model.gd")
const Logistics:=preload("res://scripts/equipment_logistics.gd")
var _processing:Dictionary={}

func before_test()->void:
	if _processing.is_empty():
		for node:Node in [GameState,CivilizationSystem,MilitaryCampaign,ProgressionSystem]: _processing[node]=node.is_processing()
	WorldSimulation.clear()
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	GameState.reset_for_new_world(74017);GameState.civic_api_enabled=false
	DiscoverySystem.reset_for_new_world();FoodSystem.reset_for_new_world();MilitaryCampaign.reset_for_new_world();CivilizationSystem.reset_for_new_world()
	GovernmentPeopleSystem.reset_for_new_world()
	GameState.ensure_population_total(900);GameState.housing_capacity=1000
	GameState.settlement_site_committed=true;GameState.settlement_completed=["Hearth Circle"];SettlementModel.ensure_founded()
	GameState.select_founding_focus("provision")
	GameState.society_capacities["institutions"]=0.4
	GovernmentPeopleSystem._update_government_stage(false)
	GovernmentPeopleSystem.initialize()
	GameState.resource_stockpiles["Food"]=1000000.0
	GameState.food_stocks={"Preserved food":1000000.0}
	FoodSystem.receive_external_food(100000)
	for resource:String in ["Timber","Stone","Fiber Plants","Clay","Hides"]:GameState.resource_stockpiles[resource]=100000.0
	GameState.elapsed_days=20*365
	MilitaryCampaign.last_processed_day=int(GameState.elapsed_days)
	MilitaryCampaign.army_templates=[{"template_id":1,"name":"Levy band","entries":[{"unit":"levy","weapon":"improvised","count":10}]}]
	MilitaryCampaign.next_army_template_id=2
	MilitaryCampaign.military_inventory["improvised"]=0

func after_test()->void:
	GameState.elapsed_days=0
	MilitaryCampaign.reset_for_new_world()
	GovernmentPeopleSystem.reset_for_new_world()
	CivilizationSystem.reset_for_new_world()
	FoodSystem.reset_for_new_world()
	DiscoverySystem.reset_for_new_world()
	GameState.reset_for_new_world(74017)
	ProgressionSystem.reset_for_new_world()
	WorldSimulation.clear()
	for node:Node in _processing: node.set_process(bool(_processing[node]))

func _day()->void:
	GameState.elapsed_days+=1
	MilitaryCampaign.last_processed_day=int(GameState.elapsed_days)
	MilitaryCampaign._process_military_day()

func test_a_band_short_of_gear_gets_it_made_and_deploys_on_its_own()->void:
	var steward:Dictionary=WorldSimulation.government.officeholder("Quartermaster")
	if steward.is_empty():steward=WorldSimulation.government.officeholder("Steward")
	assert_dict(steward).override_failure_message("someone must run the workshops").is_not_empty()
	var line:Dictionary=MilitaryCampaign.recruit_deploy.add(1)
	var id:=int(line.id)
	var slot:=int(MilitaryCampaign.recruit_deploy.line(id).slots[0])
	assert_int(int(MilitaryCampaign.recruit_deploy.status(id,slot).equipment)).is_equal(0)
	# The shared reading says the band is short, and of what.
	assert_int(Logistics.deficit("improvised")).is_greater_equal(10)
	var band:Dictionary=Deploy.lines()[0].bands[0]
	assert_bool(bool(band.gear_short)).is_true()
	var deployed_day:=-1
	var first_gear_day:=-1
	var staff_line:=false
	var gear_filled:=false
	for day in 400:
		_day()
		for job:Dictionary in MilitaryCampaign.equipment_queue:
			if String(job.item)=="improvised" and bool(job.get("planner_managed",false)):staff_line=true
		if MilitaryCampaign.recruit_deploy.line(id).is_empty() or slot not in MilitaryCampaign.recruit_deploy.line(id).slots:
			if MilitaryCampaign.field_army_active_personnel()>0:deployed_day=day
			break
		var state:=MilitaryCampaign.recruit_deploy.status(id,slot)
		if first_gear_day<0 and int(state.equipment)>0:first_gear_day=day
		# The queue's gear bar reads the same reservation.
		var row:Dictionary=Deploy.lines()[0].bands[0]
		assert_int(int(row.gear)).is_equal(int(state.equipment))
		if int(row.gear)>=int(row.gear_target):gear_filled=true
	print("GEAR LOOP first gear day=",first_gear_day," deployed day=",deployed_day," lines=",MilitaryCampaign.equipment_queue.map(func(j:Dictionary)->String:return "%s target %s stock %s" % [j.item,j.get("target_stock",0),MilitaryCampaign.military_inventory.get(j.item,0)])," status=",MilitaryCampaign.workshop.data.status)
	assert_bool(staff_line).override_failure_message("the Quartermaster never ran a line for the gear").is_true()
	assert_bool(gear_filled).override_failure_message("the band's gear bar never filled").is_true()
	assert_int(first_gear_day).override_failure_message("the workshops never made the band's gear").is_greater_equal(0)
	assert_int(deployed_day).override_failure_message("the band never deployed").is_greater_equal(0)
	var army:Dictionary=MilitaryCampaign.field_armies[0]
	var issued:=0;var required:=0
	for formation:Dictionary in army.formations:issued+=int(formation.equipment);required+=int(formation.equipment_required)
	assert_int(issued).is_equal(required)
