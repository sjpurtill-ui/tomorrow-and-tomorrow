extends GdUnitTestSuite
## Raising soldiers gets them armed without the player touching Production: the
## workshop officer opens or tops up a line, waiting soldiers shape their own
## simple gear, short materials raise gathering, and both screens say so.
const Production=preload("res://scripts/persistent_production.gd")
const Plain=preload("res://scripts/hud/production_plain.gd")
const Story=preload("res://scripts/hud/military_force_story.gd")

func before_test()->void:
	GameState.reset_for_new_world(7511);MilitaryCampaign.reset_for_new_world()
	# Workshop line capacity follows the domain tiers; start them from the new world.
	ProgressionSystem.reset_for_new_world()
	GameState.resource_stockpiles["Timber"]=100.0
	GameState.population_health=1.0
	GameState.simulation_metrics["labor_efficiency"]=1.0
	GameState.settlement_plots.clear()
	# A poor workshop, as in the reported campaign: craftspeople alone make
	# about one club a month.
	GameState.settlement_plots.append({"land_use":"workshop","worker_capacity":100,"condition":.05,"status":"active","damage":{}})
	GovernmentPeopleSystem.reset_for_new_world()
	GameState.initialize_population_model()
	GameState.population_allocations.Crafting=5
	GameState.population_allocations.Logistics=6
	GameState.population_allocations.Defense=0
	GameState.settlement_name="Arming Town"
	GameState.settlement_site_committed=true
	GameState.settlement_completed=["Hearth Circle"]
	GameState.settlement_founded_at=Vector3(12,0,-8)
	SettlementModel.ensure_founded()
	GovernmentPeopleSystem.initialize()
	MilitaryCampaign.army_templates=[]
	MilitaryCampaign.home_army=MilitaryCampaign.simulator.create_formation_force("Reserve",[],.8,.7)
	MilitaryCampaign.military_inventory["improvised"]=0

## The reported levy: 20 recruits drilling with 17 sets reserved... here none yet.
func _levy(reserved:int=0)->void:
	MilitaryCampaign.training_queue=[{"id":5,"mode":"new","unit":"levy","weapon":"improvised","count":20,"initial_count":20,"progress_days":5.0,"required_days":7.0,"deployment_line":1,"deployment_slot":1,"entry_index":0,"target_count":20,"reserved_equipment":reserved}]

func _days_to_make(count:int,limit:int)->int:
	for day:int in range(1,limit+1):
		GameState.elapsed_days=day
		MilitaryCampaign.workshop.advance(day)
		MilitaryCampaign._process_equipment_production_day()
		if int(MilitaryCampaign.military_inventory.improvised)>=count:return day
	return -1

func test_quartermaster_is_appointed_for_these_cases()->void:
	assert_bool(GovernmentPeopleSystem.officeholder("Quartermaster").is_empty() and GovernmentPeopleSystem.officeholder("Steward").is_empty()).is_false()

func test_raising_soldiers_with_no_manual_production_arms_them_within_days()->void:
	_levy()
	assert_array(MilitaryCampaign.equipment_queue).is_empty()
	var days:=_days_to_make(20,10)
	# Twenty clubs are a day or two of the recruits' own work, not years.
	assert_int(days).is_between(1,3)
	var job:Dictionary=MilitaryCampaign.equipment_queue[0]
	assert_bool(bool(job.planner_managed)).is_true()
	assert_float(float(GameState.resource_stockpiles.Timber)).is_equal_approx(100.0-20*.35,.001)

func test_waiting_soldiers_add_work_only_for_simple_gear_they_lack()->void:
	_levy(17)
	MilitaryCampaign.workshop.advance(1)
	var job:Dictionary=MilitaryCampaign.equipment_queue[0]
	assert_float(MilitaryCampaign.workshop.muster_hands_work(job)).is_equal_approx(3*.25,.0001)
	assert_float(float(job.allocation)).is_equal(2.0)
	MilitaryCampaign.military_inventory.improvised=3
	assert_float(MilitaryCampaign.workshop.muster_hands_work(job)).is_equal(0.0)
	MilitaryCampaign.training_queue[0].reserved_equipment=20
	MilitaryCampaign.workshop.advance(2)
	assert_float(float(job.allocation)).is_equal(1.0)

func test_player_owned_line_does_not_block_equipping()->void:
	var started:=MilitaryCampaign.start_production_line("improvised",5)
	var job:Dictionary=MilitaryCampaign.equipment_queue[0]
	MilitaryCampaign.configure_production_line(int(started.job_id),5,false)
	assert_bool(bool(job.get("planner_managed",false))).is_false()
	_levy()
	MilitaryCampaign.workshop.advance(1)
	# The officer raises only the too-low target; the line stays the player's.
	assert_int(int(job.target_stock)).is_equal(20)
	assert_bool(bool(job.get("planner_managed",false))).is_false()
	assert_str(String(MilitaryCampaign.workshop.data.status)).contains("raised your simple levy weapons order from 5 to 20")
	var plan:Dictionary=MilitaryCampaign.workshop.line_plan(int(job.id))
	assert_str(String(plan.officer)).is_equal("Your workshop")
	assert_int(int(plan.raised_from)).is_equal(5)
	assert_int(_days_to_make(20,10)).is_between(1,3)

func test_player_pause_is_respected_and_said_plainly()->void:
	var started:=MilitaryCampaign.start_production_line("improvised",5)
	MilitaryCampaign.configure_production_line(int(started.job_id),5,true)
	_levy()
	MilitaryCampaign.workshop.advance(1)
	var job:Dictionary=MilitaryCampaign.equipment_queue[0]
	assert_bool(bool(job.paused)).is_true()
	assert_int(int(job.target_stock)).is_equal(5)
	assert_str(String(MilitaryCampaign.workshop.data.status)).contains("paused on your order while 20 soldiers wait")
	assert_dict(MilitaryCampaign.workshop.gear_plan("improvised")).is_empty()

func test_material_shortage_asks_for_gatherers_and_says_so()->void:
	_levy()
	GameState.resource_stockpiles.Timber=2.0
	var request:Dictionary=MilitaryCampaign.workshop.extraction_request()
	assert_float(float(request.weight)).is_greater(0.0)
	assert_array(request.materials).contains(["Timber"])
	var asked:float=GovernmentPeopleSystem._allocations_for_focus("balanced",{}).Extraction
	MilitaryCampaign.workshop.advance(1)
	assert_str(String(MilitaryCampaign.workshop.data.status)).contains("Short of timber (7 needed, 2 in store)")
	assert_str(String(MilitaryCampaign.workshop.data.status)).contains("asked the settlement leaders for more hands")
	GameState.resource_stockpiles.Timber=100.0
	assert_dict(MilitaryCampaign.workshop.extraction_request()).is_empty()
	assert_float(asked).is_greater(float(GovernmentPeopleSystem._allocations_for_focus("balanced",{}).Extraction))

func test_production_screen_says_what_the_quartermaster_is_making()->void:
	_levy()
	MilitaryCampaign.workshop.advance(1)
	var line:Dictionary=MilitaryCampaign.production_lines_snapshot().lines[0]
	var plan:Dictionary=MilitaryCampaign.workshop.line_plan(int(line.id))
	assert_int(int(plan.count)).is_equal(20)
	line["staff_plan"]=plan
	var story:=Plain.line_story(line,{})
	var text:=Plain.plan_text(line,story,MilitaryCampaign.workshop.owner(),Production.product_name("improvised"))
	assert_str(text).is_equal("The %s is making 20 simple levy weapons for the new recruits (within a day)." % String(MilitaryCampaign.workshop._office()))
	assert_str(text).not_contains("year")

func test_forces_screen_says_who_is_making_the_weapons_and_how_long()->void:
	_levy(17)
	MilitaryCampaign.workshop.advance(1)
	var plan:Dictionary=MilitaryCampaign.workshop.gear_plan("improvised")
	assert_bool(bool(plan.covered)).is_true()
	assert_str(String(plan.maker)).is_equal("the "+String(MilitaryCampaign.workshop._office()))
	assert_float(float(plan.days)).is_less(3.0)
	var supply:=Story.supply_for(MilitaryCampaign,"improvised")
	var row:={"kind":"line","place":"reserve","name":"LEVY BAND","count":20,"authorized":20,"gear":17,"gear_required":20,"skill":0.0,"experience":0.0,"condition":1.0,"progress":.5,"in_training":true}
	var ctx:={"service":"army","stage":"hearth","free_adults":0,"policy":{"id":"regular","label":"Regular","intake":1.0},"food_for_drill":true,"supply":supply,"line":{"paused":false,"auto_deploy":true},"days_left":-1,"stalled":"","captain":{},"defense_target":0}
	var story:=Story.describe(row,ctx)
	var office:=String(MilitaryCampaign.workshop._office())
	assert_str(String(story.arms_brief)).is_equal("3 still waiting for weapons; the %s is making them, %s." % [office,Story.about_days(float(plan.days))])
