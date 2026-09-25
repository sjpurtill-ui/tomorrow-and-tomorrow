extends GdUnitTestSuite
const Overview=preload("res://scripts/hud/civilization_overview_model.gd")
const Content=preload("res://scripts/hud/content/dock_content_overview.gd")
class TestHud extends Control:
	signal section_requested(section:String,sub:int)

func before_test()->void:
	WorldSimulation.clear()
	GameState.reset_for_new_world(772241)
	ResourceSystem.reset_for_new_world();FoodSystem.reset_for_new_world();SettlementModel.reset_for_new_world()
	GameState.initialize_population_model()
	GameState.settlement_completed=["Hearth Circle"]
	GameState.settlement_site_committed=true;GameState.settlement_name="Capital"
	SettlementModel.ensure_founded()
	GameState.player_settlements.append({"id":"second","name":"Second City","primary":false,"position":Vector2(10,0),"population_share":.25,"founded_day":0})
	GameState.housing_capacity=1000
	GameState.resource_stockpiles.Timber=7.0
	GameState.simulation_metrics.food_days=100.0;GameState.simulation_metrics.food_intake_ratio=1.0
	GameState.water_metrics={"days":10.0,"intake_ratio":1.0}
	SettlementModel.with_city_resources("second",func()->void:
		GameState.resource_stockpiles.Timber=3.0
		GameState.housing_capacity=0
		GameState.simulation_metrics.food_days=1.0;GameState.simulation_metrics.food_intake_ratio=.5
		GameState.water_metrics={"days":1.0,"intake_ratio":.7})

func test_overview_exposes_secondary_shortages_without_pooling_shelter()->void:
	var result:=Overview.snapshot()
	assert_int(result.cities.size()).is_equal(2)
	assert_int(result.population).is_equal(GameState.population_total)
	assert_int(result.attention).is_equal(1)
	assert_float(float(result.food_min)).is_equal(1.0)
	assert_str(String(result.cities[0].id)).is_equal("second")
	assert_int(result.sheltered).is_equal(roundi(SettlementModel.primary_population_exact()))
	assert_int(result.places).is_equal(1000)
	assert_float(float(result.materials.Timber)).is_equal(10.0)

func test_reading_overview_preserves_selected_city_and_live_state()->void:
	SettlementModel.select_settlement("second")
	var population:=GameState.population_exact
	var metrics:=GameState.simulation_metrics.duplicate(true)
	var stocks:=GameState.resource_stockpiles.duplicate(true)
	Overview.snapshot()
	assert_str(GameState.selected_player_settlement_id).is_equal("second")
	assert_float(GameState.population_exact).is_equal(population)
	assert_dict(GameState.simulation_metrics).is_equal(metrics)
	assert_dict(GameState.resource_stockpiles).is_equal(stocks)

func test_content_reads_city_changes_without_reopening_and_links_every_city()->void:
	var content:=Content.new(null,null)
	var first:Dictionary=content.tab(0)
	var people:Dictionary=first.blocks[0]
	assert_str(String(people.type)).is_equal("people")
	assert_int(people.hearths.size()).is_equal(2)
	assert_bool(people.hearths[0].on_click is Callable).is_true()
	SettlementModel.with_city_resources("second",func()->void:
		GameState.housing_capacity=1000
		GameState.simulation_metrics.food_days=20.0;GameState.simulation_metrics.food_intake_ratio=1.0
		GameState.water_metrics={"days":3.0,"intake_ratio":1.0})
	var next:Dictionary=content.tab(0).blocks[0]
	# The People view: stores of food are the second of six vitals.
	assert_str(String(next.vitals[1].value)).is_equal("20 days")
	assert_int((next.vitals as Array).size()).is_equal(6)
	assert_str(String(next.hearths[0].status)).is_equal("Basic needs met")
	assert_str(String(next.hearths[0].needs)).contains("roofs for all")

func test_the_people_screen_shows_named_faces_a_voice_and_work()->void:
	GameState.hearth_season["born"]=2
	var block:Dictionary=Content.new(null,null).tab(0).blocks[0]
	var roles:Array=(block.faces as Array).map(func(f:Dictionary)->String:return String(f.role))
	assert_array(roles).contains(["newborn","oldest","provider","maker","grievance"])
	for face:Dictionary in block.faces:
		assert_str(String(face.name)).is_not_empty()
		if bool(face.alive) and String(face.role)!="newborn":assert_str(String(face.summon.known_id)).is_not_empty()
	var babe:Dictionary=(block.faces as Array).filter(func(f:Dictionary)->bool:return f.role=="newborn")[0]
	assert_int(int(babe.age)).is_equal(0)
	# The same people come back on the next read: they are remembered.
	var again:Dictionary=Content.new(null,null).tab(0).blocks[0]
	assert_str(String(again.faces[1].id)).is_equal(String(block.faces[1].id))
	var voice:Dictionary=block.scene.voice
	assert_str(String(voice.line)).is_not_empty()
	assert_str(String(voice.face.name)).is_not_empty()
	assert_str(String(block.scene.headline)).contains("souls at the Capital fires")
	assert_str(String(block.scene.register)).is_equal("TOLD AT THE FIRE")
	assert_int((block.labor.tasks as Array).size()).is_greater(3)
	for task:Dictionary in block.labor.tasks:assert_int(int(task.count)).is_greater(0)
	for word in ["GDP","‰","per mille","%"]:assert_str(String(block.scene.headline)).not_contains(word)

func test_city_navigation_and_overview_layout()->void:
	var hud:=TestHud.new();add_child(hud)
	var opened:Array=[]
	hud.connect("section_requested",func(section:String,sub:int)->void:opened.assign([section,sub]))
	var content:=Content.new(null,hud)
	content.open_city("second")
	assert_str(GameState.selected_player_settlement_id).is_equal("second")
	assert_array(opened).is_equal(["settlement",0])
	var panel=preload("res://scripts/hud/dock_panel.gd").new();add_child(panel)
	for width:int in [1200,700]:
		panel.size=Vector2(width,900);panel.present(content,0)
		for frame in 6:await get_tree().process_frame
		assert_float(panel.size.x).is_less_equal(float(width))
		assert_int(panel.body.get_child_count()).is_greater(0)
		var screen:Node=panel.body.find_child("PeopleScreen",true,false)
		assert_object(screen).is_not_null()
		assert_int((screen.get("columns") as GridContainer).columns).is_equal(2 if width>=1200 else 1)
	panel.queue_free();hud.queue_free();await get_tree().process_frame

func test_unsettled_overview_keeps_actual_carried_stores()->void:
	GameState.player_settlements.clear();GameState.settlement_site_committed=false
	var result:=Overview.snapshot()
	assert_int(result.cities.size()).is_equal(0)
	assert_float(float(result.materials.Timber)).is_equal(7.0)
	assert_float(float(result.food_min)).is_equal(100.0)


