extends GdUnitTestSuite
const P=preload("res://scripts/research_supply_planner.gd")
const C=preload("res://scripts/civilization_controller.gd")
const S=preload("res://scripts/civilization_strategy.gd")
func before_test()->void:
	WorldSimulation.clear();WorldSimulation.create_actor("supply_ruler",91420)
func after_test()->void:WorldSimulation.clear()
func source(stage:String="surveyed",stock:float=0)->Dictionary:
	var item:=WorldSimulation.resources._deposit("Stone",Vector3(1,0,1),.8,1000,0)
	item.stage=stage;item.access=.8
	WorldSimulation.state.resource_deposits.clear();WorldSimulation.state.resource_deposits.append(item)
	WorldSimulation.state.resource_stockpiles.Stone=stock
	WorldSimulation.state.population_allocations.Extraction=5
	# Year 10: joinery, stone's processing method, is open by then.
	WorldSimulation.state.elapsed_days=3650
	return item
func test_stone_shortage_points_to_its_open_processing_method_without_unlocking_it()->void:
	# The founding kit now includes cordage, joinery's only foundation, so a
	# stone shortage points straight at joinery once its age has come.
	WorldSimulation.scoped("supply_ruler",func()->void:
		source()
		assert_dict(P.frontier("joinery")).is_equal({"joinery":0})
		var order:=P.recommendation()
		assert_str(String(order.id)).is_equal("joinery")
		assert_str(String(order.resource)).is_equal("Stone")
		assert_bool("joinery" in WorldSimulation.state.known_discoveries).is_false()
		# Before its age the planner suggests nothing it could not start.
		WorldSimulation.state.elapsed_days=0
		assert_dict(P.recommendation()).is_empty()
	)
func test_hidden_unsurveyed_exhausted_or_supplied_sources_do_not_drive_research()->void:
	WorldSimulation.scoped("supply_ruler",func()->void:
		for stage:String in ["unknown","recognized","accessible","developed"]:
			source(stage);assert_dict(P.recommendation()).is_empty()
		source("surveyed",20);assert_dict(P.recommendation()).is_empty()
		var item:=source();item.remaining=0;assert_dict(P.recommendation()).is_empty()
		source();WorldSimulation.state.population_allocations.Extraction=0;assert_dict(P.recommendation()).is_empty()
	)
func test_learned_foundation_moves_frontier_forward_and_still_respects_material_basis()->void:
	WorldSimulation.scoped("supply_ruler",func()->void:
		# Without cordage the frontier is cordage, one step before joinery.
		source();WorldSimulation.state.known_discoveries.erase("cordage")
		var before:=P.frontier("joinery")
		assert_bool(before.has("joinery")).is_false()
		assert_int(int(before.get("cordage",-1))).is_equal(1)
		WorldSimulation.state.known_discoveries.append("cordage")
		assert_bool(P.frontier("joinery").has("joinery")).is_true()
		WorldSimulation.state.known_discoveries.append("joinery")
		assert_dict(P.frontier("joinery")).is_empty()
	)
func test_controller_redirects_one_existing_point_and_selects_actual_investigation()->void:
	var player_before:=GameState.research_allocations.duplicate(true)
	WorldSimulation.scoped("supply_ruler",func()->void:
		source()
		var known_before:int=WorldSimulation.state.known_discoveries.size()
		var weights:Dictionary={}
		for domain:String in S.DOMAINS:
			weights[domain]=.1
			WorldSimulation.submit("supply_ruler",{"kind":"research_emphasis","domain":domain,"weight":0})
		weights.security=100
		WorldSimulation.submit("supply_ruler",{"kind":"research_emphasis","domain":"security","weight":3})
		C.research_orders("supply_ruler",{"research_weights":weights,"goals":[{"title":"Defend"}]})
		# Emphasis is shares in the player's own steps; it buys no research.
		var total:=0
		for value in WorldSimulation.state.research_allocations.values():
			total+=int(value);assert_int(int(value)).is_between(0,12)
		assert_int(total).is_less_equal(preload("res://scripts/research_600_catalog.gd").ATTENTION_STEPS)
		assert_int(int(WorldSimulation.state.research_allocations.infrastructure)).is_greater(0)
		assert_bool("joinery" in WorldSimulation.state.active_investigations.values()).is_true()
		assert_int(WorldSimulation.state.known_discoveries.size()).is_equal(known_before)
		assert_float(float(WorldSimulation.state.resource_stockpiles.Stone)).is_equal(0.0)
	)
	assert_dict(GameState.research_allocations).is_equal(player_before)
func test_target_command_cannot_invent_emphasis()->void:
	WorldSimulation.scoped("supply_ruler",func()->void:
		source();WorldSimulation.submit("supply_ruler",{"kind":"research_emphasis","domain":"production","weight":0})
		assert_bool(WorldSimulation.submit("supply_ruler",{"kind":"research_target","id":"stone_sorting"}).has("error")).is_true()
		assert_int(int(WorldSimulation.state.research_allocations.production)).is_equal(0)
	)
func test_a_real_shortage_moves_attention_and_never_adds_any()->void:
	WorldSimulation.scoped("supply_ruler",func()->void:
		source();var weights:Dictionary={}
		for domain:String in S.DOMAINS:
			weights[domain]=1.0
			WorldSimulation.submit("supply_ruler",{"kind":"research_emphasis","domain":domain,"weight":0})
		weights.infrastructure=0.0
		C.research_orders("supply_ruler",{"research_weights":weights,"goals":[{"title":"Recover supplies"}]})
		# The ruler weighs infrastructure not at all; the shortage takes one step
		# from its largest field for joinery rather than adding one.
		var total:=0
		for value in WorldSimulation.state.research_allocations.values():total+=int(value)
		assert_int(total).is_equal(preload("res://scripts/research_600_catalog.gd").ATTENTION_STEPS)
		assert_int(int(WorldSimulation.state.research_allocations.infrastructure)).is_equal(1)
		assert_bool("joinery" in WorldSimulation.state.active_investigations.values()).is_true()
	)
func test_optional_cycle_terminates_and_keeps_a_grounded_alternative()->void:
	WorldSimulation.scoped("supply_ruler",func()->void:
		source()
		var a:Dictionary=WorldSimulation.discovery.discovery_definition("joinery").duplicate(true)
		a.id="probe_a";a.requires_all=[];a.requires_any=[];a.requires=[]
		a.learning_routes=[{"id":"cyclic","requires_all":["probe_b"]},{"id":"grounded","requires_all":["stone_sorting"]}]
		var b:Dictionary=a.duplicate(true);b.id="probe_b";b.learning_routes=[{"id":"back","requires_all":["probe_a"]}]
		WorldSimulation.discovery.catalog_by_id.probe_a=a;WorldSimulation.discovery.catalog_by_id.probe_b=b
		assert_bool(P.frontier("probe_a").has("stone_sorting")).is_true()
	)
