extends GdUnitTestSuite
const Chart=preload("res://scripts/scout_chart_index.gd")
const World=preload("res://scripts/civilization_system.gd")
const Candidates=preload("res://scripts/research_candidate_index.gd")
func reference_contains(world:Node,point:Vector2)->bool:
	for area in world.revealed_areas:
		if world._revealed_record_contains(area,point):return true
	return false
func test_cached_chart_matches_exact_geometry_and_rebuilds_on_growth()->void:
	var world:Node=auto_free(World.new())
	world._add_revealed_area(Vector2(-128,0),4,"test")
	world._add_revealed_trail([{"x":-100.0,"z":-100.0},{"x":8000.0,"z":8000.0}],18,"test",1)
	world._add_revealed_trail([{"x":0.0,"z":0.0},{"x":128.0,"z":0.0}],4,"traveled ground",1)
	var rng:=RandomNumberGenerator.new();rng.seed=909
	for i in 300:
		var point:=Vector2(rng.randf_range(-150,300),rng.randf_range(-150,300))
		assert_bool(world._position_is_revealed(point)).is_equal(reference_contains(world,point))
	for point in [Vector2(-132,0),Vector2(-132.0001,0),Vector2(64,4),Vector2(64,4.0001),Vector2(128,0),Vector2(1000,1000)]:
		assert_bool(world._position_is_revealed(point)).is_equal(reference_contains(world,point))
	var prior=world._revealed_chart_index
	world._append_revealed_travel(Vector2(128,0),Vector2(200,0))
	assert_bool(world._position_is_revealed(Vector2(190,0))).is_true()
	assert_bool(is_same(prior,world._revealed_chart_index)).is_false()
	world.revealed_areas.clear()
	assert_bool(world._position_is_revealed(Vector2(190,0))).is_false()
func test_chart_buckets_have_bounded_fanout_and_exact_fallback()->void:
	var index:=Chart.new([])
	index.bucket_references=Chart.MAX_BUCKET_REFERENCES
	index.add_segment(Vector2(-256,0),Vector2(256,0),8)
	assert_dict(index.buckets).is_empty()
	assert_bool(index.contains(Vector2(0,8))).is_true()
	assert_bool(index.contains(Vector2(0,8.001))).is_false()
func test_chart_is_not_saved_and_import_clears_same_revision_cache()->void:
	var world:Node=auto_free(World.new());world.reset_for_new_world()
	world.revealed_areas.clear();world._add_revealed_area(Vector2.ZERO,5,"test")
	assert_bool(world._position_is_revealed(Vector2.ZERO)).is_true()
	var payload:Dictionary=world.export_state()
	payload.revealed_areas[0].x=1000.0
	assert_bool(world.import_state(payload).get("ok",false)).is_true()
	assert_bool(world._position_is_revealed(Vector2.ZERO)).is_false()
	assert_bool(world._position_is_revealed(Vector2(1000,0))).is_true()
	assert_bool(SaveSystem._capture_reflected(world,[]).has("_revealed_chart_index")).is_false()
func test_candidate_pool_preserves_order_and_handles_learning_forgetting_and_replacement()->void:
	var index:=Candidates.new()
	var definitions:Array=[{"id":"a"},{"id":"b"},{"id":"c"}]
	var known:Array=["a"]
	assert_array(index.candidates("one",definitions,known)).contains_exactly([definitions[1],definitions[2]])
	known.append("b")
	assert_array(index.candidates("one",definitions,known)).contains_exactly([definitions[2]])
	known[0]="c" # Same size, different knowledge must invalidate.
	assert_array(index.candidates("one",definitions,known)).contains_exactly([definitions[0]])
	known.clear()
	assert_array(index.candidates("one",definitions,known)).contains_exactly(definitions)
	assert_array(index.candidates("one",[{"id":"replacement"}],known)).contains_exactly([{"id":"replacement"}])
func test_research_selection_matches_full_catalog_scan_across_knowledge_states()->void:
	WorldSimulation.clear();WorldSimulation.create_actor("candidate_test",318)
	WorldSimulation.scoped("candidate_test",func()->void:
		var discovery=WorldSimulation.discovery
		var state=WorldSimulation.state
		var all:Array=[]
		for entry in discovery.technology_catalog:all.append(String(entry.id))
		for fraction in [0.0,0.5,1.0]:
			state.known_discoveries.assign(all.slice(0,int(all.size()*fraction)))
			var known:=preload("res://scripts/technology_requirements.gd").index_known(state.known_discoveries)
			for channel in discovery.catalog_by_channel:
				var best:Dictionary={};var score:=-INF
				for entry in discovery.catalog_by_channel[channel]:
					if not discovery._discovery_is_eligible(entry,100000,known):continue
					var value:float=discovery._candidate_score(entry)
					if String(state.research_targets.get(channel,""))==String(entry.id):value+=100000.0
					if value>score:score=value;best=entry
				assert_dict(discovery._best_candidate_for_channel(channel,100000)).is_equal(best)
				assert_bool(discovery._channel_has_candidate(channel,100000)).is_equal(not best.is_empty())
	)
	WorldSimulation.clear()
