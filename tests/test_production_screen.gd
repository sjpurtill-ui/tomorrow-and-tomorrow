extends GdUnitTestSuite
## Production screen: plain-language line readings and the controls in words.
const Plain=preload("res://scripts/hud/production_plain.gd")
const Queue=preload("res://scripts/hud/production_queue.gd")
const Provider=preload("res://scripts/hud/content/dock_content_production.gd")

static func starved_line()->Dictionary:
	# 0.02 a day, 25 wanted, 5 timber for 0.3 each: labor-slow and timber-short.
	return {"id":1,"item":"improvised","persistent":true,"state":"Working","paused":false,"planner_managed":false,
		"output_per_day":0.02,"forecast_output_per_day":0.02,"stock":0,"target_stock":25,"progress_days":0.0,"work_per_item":0.25,
		"efficiency":0.2,"share":1.0,"allocation":1.0,
		"materials_status":[{"resource":"Timber","name":"Timber","stored":5.0,"per_item":0.3,"per_day":0.006}]}

static func healthy_line()->Dictionary:
	return {"id":2,"item":"spear","persistent":true,"state":"Working","paused":false,"planner_managed":true,
		"output_per_day":3.0,"forecast_output_per_day":2.0,"stock":18,"target_stock":20,"progress_days":0.0,"work_per_item":0.55,
		"efficiency":0.9,"share":0.5,"allocation":2.0,
		"materials_status":[{"resource":"Timber","name":"Timber","stored":80.0,"per_item":0.5,"per_day":1.5}]}

const CONTEXT:={"line_count":1,"labor_share":0.35,"workforce":{"workers":4.0,"workplace_condition":1.0,"health":1.0,"logistics":1.0}}

func before_test()->void:
	WorldSimulation.clear()
	GameState.reset_for_new_world(4242)
	MilitaryCampaign.reset_for_new_world()
func after_test()->void:WorldSimulation.clear()

func test_starved_line_reads_rate_eta_and_bottleneck_in_plain_words()->void:
	var story:=Plain.line_story(starved_line(),CONTEXT)
	assert_str(String(story.pace)).is_equal("About 1 every 50 days")
	assert_str(String(story.eta)).is_equal("About 3½ years at this pace")
	assert_str(String(story.short)).is_equal("Short of timber")
	assert_str(String(story.tone)).is_equal("bad")
	assert_str(String(story.held)).is_equal("Short of timber: the 5 in store covers about 16 of the 25 still wanted.")
	assert_str(String(story.also)).contains("still learning this work (20% of full skill)")
	assert_str(String(story.materials[0].text)).is_equal("Timber: 0.3 for each one, 5 in store — enough for about 16 more")
	assert_bool(bool(story.materials[0].short)).is_true()
	assert_str(String(story.progress_text)).is_equal("0 of 25 in store")

func test_healthy_line_is_on_pace()->void:
	var story:=Plain.line_story(healthy_line(),CONTEXT)
	assert_str(String(story.pace)).is_equal("About 3 a day")
	assert_str(String(story.eta)).is_equal("Within a day at this pace")
	assert_str(String(story.held)).is_equal("Nothing. On pace.")
	assert_str(String(story.materials[0].text)).is_equal("Timber: needs about 1.5 a day, 80 in store — about 55 days left")

func test_blocked_and_paused_lines()->void:
	var line:=starved_line();line.state="Missing Timber";line.materials_status[0].stored=0.0
	var story:=Plain.line_story(line,CONTEXT)
	assert_str(String(story.pace)).is_equal("Nothing is being made right now")
	assert_str(String(story.held)).is_equal("Out of timber. Nothing can be made until more comes in.")
	assert_str(String(story.eta)).is_equal("Stalled until the problem below is fixed")
	line=healthy_line();line.paused=true;line.state="Paused"
	story=Plain.line_story(line,CONTEXT)
	assert_str(String(story.pace)).is_equal("Paused")
	assert_str(String(story.short)).is_equal("Paused")

func test_words_for_time_numbers_targets_and_blockers()->void:
	assert_str(Plain.span_text(50)).is_equal("50 days")
	assert_str(Plain.span_text(120)).is_equal("4 months")
	assert_str(Plain.span_text(365*2.2)).is_equal("2 years")
	assert_str(Plain.number(5.08)).is_equal("5")
	assert_str(Plain.number(0.35)).is_equal("0.35")
	assert_str(Plain.number(2.5)).is_equal("2.5")
	assert_int(Plain.step_target(25,1)).is_equal(30)
	assert_int(Plain.step_target(25,-1)).is_equal(20)
	assert_int(Plain.step_target(7,1)).is_equal(10)
	assert_int(Plain.step_target(1,-1)).is_equal(0)
	assert_str(Plain.priority_name(4.0)).is_equal("Urgent")
	assert_str(Plain.priority_name(0.5)).is_equal("Low")
	assert_str(Plain.blocker_text("Build an operational naval base for this production branch first.")).is_equal("Needs a naval base first")
	assert_str(Plain.blocker_text("Timber: 5.08 in stores; 40.00 needed for one item.")).is_equal("Needs 40 timber, 5 in store")
	assert_str(Plain.repair_text("Staff waiting for workshop capacity; repairs remain on the upkeep list")).is_equal("waiting for free workshop space")

func test_header_says_who_runs_the_workshops()->void:
	var owner:="Mahun of the High Camp · Quartermaster"
	var mine:=starved_line();mine.name="Simple levy weapons"
	var head:=Plain.header(owner,true,[mine])
	assert_str(String(head.text)).is_equal("Mahun of the High Camp, your Quartermaster, runs the workshops except Simple levy weapons, which you took over.")
	assert_str(String(head.action)).is_equal("Hand back to Mahun of the High Camp")
	head=Plain.header(owner,true,[healthy_line()])
	assert_str(String(head.text)).is_equal("Mahun of the High Camp, your Quartermaster, runs the workshops.")
	assert_str(String(head.kind)).is_equal("take_over")
	head=Plain.header(owner,false,[])
	assert_str(String(head.text)).starts_with("You run the workshops.")
	assert_str(String(head.kind)).is_equal("hand_back")

func test_screen_has_one_readout_and_worded_controls()->void:
	var actions:Array=[]
	var panel:Control=auto_free(Queue.new());add_child(panel)
	panel.setup({"mode":"military","owner":"Mahun of the High Camp · Quartermaster","managed":true,"status":"","capacity":2,"context":CONTEXT,
		"lines":[starved_line(),healthy_line()],"stores":[{"resource":"Timber","name":"Timber","amount":5.0}],
		"recipes":[{"item":"navy_hull","name":"War canoes","group":"Ships and aircraft","needs":"Each needs 40 timber","blocker":"Needs a naval base first","running":false}],
		"on_action":func(id,action,value):actions.append([id,action,value]),"on_detail":func(_id):pass,"on_header":func(_k):pass,"on_start":func(_i):pass,
		"on_add":func():pass,"on_manage":func():pass,"on_history":func():pass})
	var text:=""
	for label:Label in panel.find_children("*","Label",true,false):
		text+=label.text+"\n"
		assert_int(label.get_theme_font_size("font_size")).is_greater_equal(12)
	for banned:String in ["LEADER MANAGED","/ lines","⌒","0.02 / day","Ready to order when needed","KNOWN WORKSHOP RECIPES"]:
		assert_str(text).not_contains(banned)
	assert_str(text).contains("runs the workshops except Simple levy weapons")
	assert_str(text).contains("About 1 every 50 days")
	assert_str(text).contains("Needs a naval base first")
	var card:Node=panel.find_child("Line1",true,false)
	assert_int(card.find_children("*","ProgressBar",true,false).size()).is_equal(1)
	for button:Button in panel.find_children("*","Button",true,false):
		assert_str(button.tooltip_text).is_not_empty()
		assert_str(button.text).is_not_equal("M")
	var names:Array[String]=[]
	for button:Button in card.find_children("*","Button",true,false):names.append(button.text)
	for expected:String in ["Pause","−","+","Low","Normal","High","Urgent","More ▾"]:assert_array(names).contains([expected])
	(card.find_child("TargetUp",true,false) as Button).pressed.emit()
	(card.find_child("PriorityHigh",true,false) as Button).pressed.emit()
	assert_array(actions).contains_exactly([[1,"target",30.0],[1,"priority",2.0]])
	var start:Button=panel.find_child("Recipe_navy_hull",true,false).find_child("StartButton",true,false)
	assert_bool(start.disabled).is_true()

func test_provider_screen_drives_existing_production_actions()->void:
	GameState.reset_for_new_world(7511);MilitaryCampaign.reset_for_new_world();GovernmentPeopleSystem.reset_for_new_world();SettlementModel.reset_for_new_world()
	GameState.initialize_population_model()
	GameState.resource_stockpiles.Timber=100.0
	GameState.population_allocations.Crafting=100;GameState.population_allocations.Logistics=100
	GameState.population_health=1.0;GameState.simulation_metrics.labor_efficiency=1.0
	GameState.settlement_plots=[{"land_use":"workshop","worker_capacity":100,"condition":1.0,"status":"active","damage":{}}]
	GameState.settlement_name="Workshop Town";GameState.settlement_site_committed=true;GameState.settlement_completed=["Hearth Circle"]
	GameState.settlement_founded_at=Vector3(12,0,-8)
	SettlementModel.ensure_founded();GovernmentPeopleSystem.initialize()
	var provider=Provider.new(null,null)
	provider._start("improvised")
	assert_int(MilitaryCampaign.equipment_queue.size()).is_equal(1)
	var job:Dictionary=MilitaryCampaign.equipment_queue[0]
	assert_int(int(job.target_stock)).is_equal(Provider.START_TARGET)
	var block:Dictionary=provider.tab(2).blocks[0]
	assert_str(String(block.type)).is_equal("production_queue")
	assert_int((block.lines as Array).size()).is_equal(1)
	var levy:Array=(block.recipes as Array).filter(func(recipe:Dictionary)->bool:return recipe.item=="improvised")
	assert_bool(bool(levy[0].running)).is_true()
	assert_str(String(levy[0].group)).is_equal("Weapons and gear")
	provider._action(int(job.id),"target",15)
	assert_int(int(MilitaryCampaign.equipment_queue[0].target_stock)).is_equal(15)
	provider._action(int(job.id),"priority",4.0)
	assert_float(float(MilitaryCampaign.equipment_queue[0].allocation)).is_equal(4.0)
	provider._header_action("take_over")
	assert_bool(bool(MilitaryCampaign.workshop.data.enabled)).is_false()
	provider._header_action("hand_back")
	assert_bool(bool(MilitaryCampaign.workshop.data.enabled)).is_true()
	assert_bool(bool(MilitaryCampaign.equipment_queue[0].planner_managed)).is_true()
	assert_str(String(provider.tab(1).blocks[0].mode)).is_equal("civilian")
	assert_bool(provider.tab(1).blocks[0].has("lines")).is_false()

func test_staff_plan_is_said_plainly_when_present()->void:
	var line:=starved_line();line.planner_managed=true
	line.staff_plan={"count":22,"reason":"for the new levy"}
	var story:=Plain.line_story(line,CONTEXT)
	var text:=Plain.plan_text(line,story,"Mahun of the High Camp · Quartermaster","Simple levy weapons")
	assert_str(text).is_equal("The Quartermaster is making 22 simple levy weapons for the new levy (about 3 years; short of timber).")
	assert_str(Plain.plan_text(starved_line(),story,"","Spears")).is_empty()
	var panel:Control=auto_free(Queue.new());add_child(panel)
	panel.setup({"mode":"military","owner":"Mahun of the High Camp · Quartermaster","managed":true,"capacity":1,"context":CONTEXT,"lines":[line]})
	assert_str((panel.find_child("StaffPlan",true,false) as Label).text).is_equal(text)
	assert_str((panel.find_child("Runner",true,false) as Label).text).is_equal("· Mahun of the High Camp runs this line")
