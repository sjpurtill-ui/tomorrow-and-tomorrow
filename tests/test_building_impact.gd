extends GdUnitTestSuite
## Halls and shrines matter, and the Buildings page says what every building
## does (the user: "make halls and shrines matter ... EXPLAIN THE IMPACT OF
## THINGS"). Pins:
## - the Framed Hall raises legitimacy and cohesion and the stewards' reach,
##   scaled by the town's repair;
## - the Hearth Shrine and Shrine House raise cohesion and the people's love
##   of the god and ease their dread, and cost food in offerings; the Shrine
##   House acts only as far as its keepers are at work;
## - the Gathering Yard makes every deposit worked give more;
## - new homes hold more with the people's building knowledge;
## - every civic work explains itself in plain words with numbers, and the
##   Buildings page shows what the buildings and homes do.

const Civic:=preload("res://scripts/civic_building_effects.gd")
const Impact:=preload("res://scripts/building_impact.gd")
const Build:=preload("res://scripts/settlement_construction.gd")
const Dock:=preload("res://scripts/hud/content/dock_content_construction.gd")

var _processing:Dictionary={}


## The map the civic works list asks to choose a site with.
class StubTerrain extends Node:
	func _on_settlement_action_pressed()->void: pass


func before_test()->void:
	if _processing.is_empty():
		for node:Node in [GameState,CivilizationSystem,MilitaryCampaign]: _processing[node]=node.is_processing()
	WorldSimulation.clear()
	GameState.reset_for_new_world(8713)
	DiscoverySystem.reset_for_new_world()
	DiscoverySystem.initialize()
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	GameState.initialize_population_model()
	GameState.ensure_population_total(200)
	GameState.settlement_site_committed=true
	GameState.settlement_founded_at=Vector3.ZERO
	GameState.settlement_completed=["Hearth Circle","Lean-to Shelters","Storage Pits","Open Work Area"]
	GameState.city_form={"tier":1.0,"condition":1.0}
	GameState.population_allocations.merge({"Construction":20,"Logistics":10,"Crafting":10,"Administration":6,"Knowledge":4,"Extraction":10},true)


func after_test()->void:
	WorldSimulation.clear()
	for node:Node in _processing: node.set_process(bool(_processing[node]))


func test_the_hall_raises_legitimacy_cohesion_and_reach_by_the_towns_repair()->void:
	assert_float(Civic.effect("legitimacy")).is_equal(0.0)
	GameState.settlement_completed.append("Framed Hall")
	assert_float(Civic.effect("legitimacy")).is_equal_approx(0.035,0.0001)
	assert_float(Civic.effect("cohesion")).is_equal_approx(0.02,0.0001)
	assert_float(Civic.effect("admin_reach")).is_equal_approx(0.15,0.0001)
	# A town half in ruin: half the effect.
	GameState.city_form={"tier":1.0,"condition":0.5}
	assert_float(Civic.effect("legitimacy")).is_equal_approx(0.0175,0.0001)


func test_shrines_draw_the_people_together_and_to_the_god_at_a_cost_in_food()->void:
	GameState.settlement_completed.append_array(["Hearth Shrine","Shrine House"])
	GameState.ensure_population_total(200)
	# Four lore keepers for 200 people: two are needed, so fully tended.
	assert_float(Civic.keepers_ratio()).is_equal(1.0)
	assert_float(Civic.effect("cohesion")).is_equal_approx(0.045,0.0001)
	assert_float(Civic.effect("devotion")).is_equal_approx(0.12,0.0001)
	assert_float(Civic.effect("dread_eased")).is_equal_approx(0.05,0.0001)
	assert_float(Civic.effect("offerings")).is_equal_approx(0.013,0.0001)
	# No keepers: the Shrine House does nothing; the hearth shrine still acts.
	GameState.population_allocations["Knowledge"]=0
	assert_float(Civic.factor("Shrine House")).is_equal(0.0)
	assert_float(Civic.effect("devotion")).is_equal_approx(0.04,0.0001)
	# The offerings are food the people give up, in the day's demand.
	var demand:Dictionary=WorldSimulation.food.call("_calculate_demand",false)
	assert_float(float(demand.get("offerings",0.0))).is_greater(0.0)
	GameState.settlement_completed.erase("Hearth Shrine")
	GameState.settlement_completed.erase("Shrine House")
	var plain:Dictionary=WorldSimulation.food.call("_calculate_demand",false)
	assert_float(float(plain.get("offerings",0.0))).is_equal(0.0)


func test_the_yard_makes_every_deposit_give_more()->void:
	assert_float(Civic.effect("extraction")).is_equal(0.0)
	GameState.settlement_completed.append("Gathering Yard")
	assert_float(Civic.effect("extraction")).is_equal_approx(0.12,0.0001)
	var lines:Array=Impact.work("Gathering Yard").lines
	assert_str(String(lines[0].value)).is_equal("+12%")


func test_new_homes_hold_more_with_building_knowledge()->void:
	var plain:=Build.housing_batch_places()
	# Timber framing, known and put to use in a standing hall.
	GameState.known_discoveries.append("framed_construction")
	GameState.discovery_adoption["framed_construction"]=1.0
	GameState.settlement_completed.append("Framed Hall")
	DiscoverySystem.refresh_operating_effects()
	assert_float(Build.housing_output()).is_greater(0.0)
	assert_int(Build.housing_batch_places()).is_greater(plain)


func test_every_civic_work_explains_itself_plainly()->void:
	GameState.settlement_completed.append_array(["Framed Hall","Gathering Yard","Hearth Shrine","Shrine House","Public Stores"])
	var snake:=RegEx.create_from_string("[a-z]+_[a-z]+")
	for definition:Dictionary in Build._settlement_definitions():
		var told:=Impact.work(String(definition.name))
		assert_array(told.lines).override_failure_message("%s says nothing" % definition.name).is_not_empty()
		for line:Dictionary in told.lines:
			assert_str(String(line.value)).is_not_empty()
			assert_object(snake.search(String(line.words))).override_failure_message("%s: %s" % [definition.name,line.words]).is_null()
			assert_bool(String(line.tone) in ["good","bad","plain"]).is_true()


func test_homes_explain_births_deaths_and_crowding()->void:
	GameState.housing_capacity=180
	GameState.ensure_population_total(200)
	var h:=Impact.homes()
	var labels:Array=[]
	for line:Dictionary in h.lines: labels.append(String(line.label))
	for wanted in ["Work pace","Deaths from age and weakness","Births","Sickness breaking out","Fire","Room for newcomers"]:
		assert_array(labels).contains([wanted])
	# Over-full homes: sickness breaks out more often than in a roomy town.
	for line:Dictionary in h.lines:
		if String(line.label)=="Sickness breaking out": assert_str(String(line.tone)).is_equal("bad")


func test_the_buildings_page_shows_what_buildings_and_homes_do()->void:
	var terrain:=StubTerrain.new()
	var dock=Dock.new(terrain,null)
	var town:Dictionary=dock.tab(0)
	var kinds:Array=[]
	for block:Dictionary in town.blocks: kinds.append(String(block.get("type","")))
	assert_int(kinds.count("impact")).is_greater_equal(2)
	var summary:Dictionary={}
	for block:Dictionary in town.blocks:
		if String(block.get("heading","")).begins_with("What the buildings do"): summary=block
	assert_array(summary.get("lines",[])).is_not_empty()
	var civic:Dictionary=dock.tab(1)
	var queue:Dictionary=civic.blocks[0]
	for project:Dictionary in queue.projects:
		assert_array((project.impact as Dictionary).lines).is_not_empty()
	assert_str(String(dock.meta().title)).is_equal("Buildings")
	terrain.free()


## The page's figures are the engine's: if a rule changes, this fails
## rather than the page going on telling the old numbers.
func test_the_pages_numbers_match_the_food_rules()->void:
	var food=WorldSimulation.food
	GameState.ensure_population_total(200)
	GameState.settlement_completed.erase("Storage Pits")
	var without:float=float(food.call("_food_storage_capacity"))
	var rot_without:Array=food.call("_spoilage_rates",false)
	GameState.settlement_completed.append("Storage Pits")
	var with_pits:float=float(food.call("_food_storage_capacity"))
	var rot_with:Array=food.call("_spoilage_rates",false)
	assert_float(with_pits-without).is_equal_approx(float(GameState.population_exact)*Impact.PITS_RATIONS,0.5)
	assert_float(float(rot_with[0])/float(rot_without[0])).is_equal_approx(Impact.PITS_SPOILAGE,0.001)
