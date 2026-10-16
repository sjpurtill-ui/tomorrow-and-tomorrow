extends GdUnitTestSuite
## Actual production provider. Opening/refreshing is observational; only the
## preserved explicit callbacks may change work, names or navigation.
const Provider=preload("res://scripts/hud/content/dock_content_settlement.gd")
const Fixture=preload("res://tests/test_home_lives_model.gd")
const Preview=preload("res://scripts/hud/workforce_preview.gd")
var fixture:Node
var hud:TestHud
var terrain:TestTerrain

class TestHud extends Control:
	signal section_requested(section:String,sub:int)
	var opened:Array=[]
	var refreshed:=0
	func _init()->void:section_requested.connect(func(section:String,sub:int)->void:opened.append([section,sub]))
	func request_immediate_dock_refresh()->void:refreshed+=1
	func open_detail(_provider:RefCounted,_sub:int)->void:pass

class TestTerrain extends Node:
	var renamed_id:=""
	func _open_settlement_naming_panel(id:String)->void:renamed_id=id
	func _settlement_display_name()->String:return "First hearth"
	func _discovery_context()->Dictionary:
		# The real geography reader expires old field observations. The view
		# must guard that write, while retaining the actual construction offer.
		GameState.active_field_observation_signals(int(GameState.elapsed_days))
		return {"origin":Vector3.ZERO,"water_conveyance_sources":[]}

func before()->void:
	fixture=Fixture.new();add_child(fixture);fixture.before()

func after()->void:
	fixture.after();fixture.free()

func before_test()->void:
	fixture.before_test()
	SettlementModel.ensure_founded()
	GovernmentPeopleSystem.initialize()
	GameState.field_observation_signals={"expired":{"strength":0.5,"until_day":1}}
	hud=TestHud.new();add_child(hud)
	terrain=TestTerrain.new();add_child(terrain)

func after_test()->void:
	hud.queue_free();terrain.queue_free()
	await get_tree().process_frame

func test_meta_tab_and_signature_do_not_reconcile_government_or_mutate_old_defaults()->void:
	GameState.ensure_population_total(2400)
	GameState.selected_player_settlement_id=""
	GameState.city_form={}
	GameState.built_fabric={};GameState.fabric_realm={}
	GameState.known_discoveries.append("latrine_siting");GameState.discovery_adoption["latrine_siting"]=0.5
	for person:Dictionary in GovernmentPeopleSystem.people:
		person.erase("early_art_index");person.erase("early_art_profile")
	var before:=Preview._capture_systems()
	var provider:=Provider.new(terrain,hud)
	var start:=Time.get_ticks_usec()
	provider.meta();provider.signature()
	var page:=provider.tab(0)
	provider.signature()
	print("HOME_LIVES_PROVIDER_MS ",(Time.get_ticks_usec()-start)/1000.0)
	assert_bool(page.blocks[0].lives.ok).is_true()
	assert_array(fixture._changed_fields(before,Preview._capture_systems())).is_empty()
	assert_str(GameState.selected_player_settlement_id).is_equal("")
	assert_array(page.blocks[0].groups).is_empty()

func test_same_day_research_values_standing_and_food_edits_invalidate_signature()->void:
	var provider:=Provider.new(terrain,hud)
	var before:=provider.signature()
	GameState.discovery_progress["question"]=0.00001
	assert_array(provider.signature()).is_not_equal(before);before=provider.signature()
	GameState.societal_values.lived["openness"]=0.51234
	assert_array(provider.signature()).is_not_equal(before);before=provider.signature()
	GameState.simulation_metrics["standing_awe"]=0.51234
	assert_array(provider.signature()).is_not_equal(before);before=provider.signature()
	GameState.food_stocks["Stored food"]+=0.1
	assert_array(provider.signature()).is_not_equal(before)

func test_manual_warning_and_uninitialized_direction_remain_read_only()->void:
	PeopleDirection.automatic_work=false
	PeopleDirection.cultural_memory={}
	GameState.population_cohorts.erase("working_age")
	GameState.pregnancy_cohorts={}
	var provider:=Provider.new(terrain,hud)
	var before:=Preview._capture_systems()
	assert_bool(provider.tab(0).blocks[0].lives.ok).is_true()
	assert_array(fixture._changed_fields(before,Preview._capture_systems())).is_empty()
	PeopleDirection.initialized=false
	before=Preview._capture_systems()
	provider.meta();provider.signature();provider.tab(0)
	assert_array(fixture._changed_fields(before,Preview._capture_systems())).is_empty()

func test_secondary_scope_and_existing_navigation_actions_are_preserved()->void:
	fixture._two_towns()
	GameState.selected_player_settlement_id="second"
	var provider:=Provider.new(terrain,hud)
	var before:=Preview._capture_systems()
	var block:Dictionary=provider.tab(0).blocks[0]
	assert_int(int(block.lives.population.current)).is_equal(30)
	assert_int(int(block.lives.scope.national_population)).is_equal(120)
	assert_array(fixture._changed_fields(before,Preview._capture_systems())).is_empty()
	block.on_food.call();block.on_works.call();block.on_research.call();block.on_culture.call();block.on_rename.call()
	assert_array(hud.opened).is_equal([["economy",0],["construction",0],["inquiry",0],["civ",0]])
	assert_str(terrain.renamed_id).is_equal("second")
	assert_bool(block.on_population.is_valid()).is_true()
	assert_bool(block.on_leader.is_valid()).is_true()
	assert_bool(block.compare_care.is_valid()).is_true()

func test_works_offer_remains_a_real_explicit_command_and_reading_does_not_build()->void:
	GameState.known_discoveries.append("latrine_siting");GameState.discovery_adoption["latrine_siting"]=0.5
	GameState.resource_stockpiles["Stone"]=20.0
	var provider:=Provider.new(terrain,hud)
	var before:=Preview._capture_systems()
	var block:Dictionary=provider.tab(0).blocks[0]
	assert_array(fixture._changed_fields(before,Preview._capture_systems())).is_empty()
	var offers:Array=block.works.offers
	assert_array(offers).has_size(1)
	assert_bool(offers[0].on_press.is_valid()).is_true()
	assert_array(GameState.water_waste_works.works).is_empty()
	offers[0].on_press.call()
	assert_array(GameState.water_waste_works.works).has_size(1)
	assert_float(float(GameState.resource_stockpiles.Stone)).is_equal(16.0)
