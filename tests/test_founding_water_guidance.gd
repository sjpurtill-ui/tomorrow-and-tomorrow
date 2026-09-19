extends GdUnitTestSuite

const Advice:=preload("res://scripts/founding_site_advice.gd")
const Guide:=preload("res://scripts/hud/founding_site_guide.gd")
const Renderer:=preload("res://scripts/local_terrain.gd")

class Map extends "res://scripts/local_terrain.gd":
	var water_x:=0.0
	var charted_to:=100.0
	var blocked_route:=false
	var opened_site:=Vector3.INF
	var water_queries:=0
	func _ready()->void:pass
	func _process(_delta:float)->void:pass
	func _height_at(_x:float,_z:float)->float:return 1.0
	func _settlement_surface_assessment(point:Vector3)->Dictionary:
		return {"valid":absf(point.x-water_x)>.25,"reason":"RIVER CHANNEL"}
	func _world_position_is_revealed(point:Vector3)->bool:return point.x<=charted_to
	func _founding_water_sources(point:Vector3)->Array[Dictionary]:
		water_queries+=1
		return [{"position":Vector3(water_x,1,point.z),"distance_km":absf(point.x-water_x),"kind":"River"}]
	func _analyze_convoy_route(origin:Vector3,point:Vector3)->Dictionary:
		return {"valid":not blocked_route,"distance_km":origin.distance_to(point),"terrain_modifier":1.0}
	func _open_founding_site_guide(point:Vector3,_later:bool=false)->void:opened_site=point
	func _settlement_model()->Node:return SettlementModel

class CommitMap extends Map:
	func _retire_founding_expedition_visuals()->void:pass
	func _update_resource_proximity()->void:pass
	func _refresh_settlement_footprint(_force:=false)->void:pass
	func _update_settlement_progress_text()->void:pass
	func _issue_travel_council_report(_stage:String,_progress:float,_reason:="")->void:pass
	func _open_people_panel()->void:pass
	func _update_time_interface()->void:pass
	func _open_settlement_naming_panel(_settlement_id:String="")->void:pass

var world:Map

func before_test()->void:
	GameState.reset_for_new_world(741991)
	CivilizationSystem.reset_for_new_world()
	SettlementModel.reset_for_new_world()
	world=auto_free(Map.new())

func test_nearby_known_water_is_recommended_and_matches_collection_model()->void:
	var site:=world._founding_site_advice(Vector3(.6,1,0),true)
	assert_bool(site.valid).is_true()
	assert_bool(site.recommended).is_true()
	assert_float(site.household_ratio).is_equal(ResourceSystem._household_surface_water_access_ratio(.6))
	assert_str(site.source_text).contains("0.6 km W")

func test_six_kilometer_access_is_a_labor_warning_not_a_safe_site()->void:
	var site:=world._founding_site_advice(Vector3(6,1,0),true)
	assert_bool(site.valid).is_true()
	assert_bool(site.recommended).is_false()
	assert_str(site.title).is_equal("LONG WATER CARRY")
	assert_str(site.reason).contains("38%")
	assert_float(site.household_ratio).is_equal_approx(.38,.00001)
	assert_bool(world._founding_site_advice(Vector3(6.001,1,0),true).valid).is_false()

func test_hidden_water_does_not_leak_into_advice_or_recommendations()->void:
	world.water_x=4;world.charted_to=3.5
	var site:=world._founding_site_advice(Vector3(3,1,0),true)
	assert_bool(site.valid).is_false()
	assert_bool(site.has("source_position")).is_false()
	assert_bool(site.has("source_text")).is_false()
	assert_array(world._founding_advisor().suggestions(Vector3(3,1,0))).is_empty()
	world.charted_to=4
	CivilizationSystem.fog_revision+=1
	assert_bool(world._founding_site_advice(Vector3(3,1,0)).recommended).is_true()

func test_uncharted_ground_is_unknown_without_querying_hidden_geography()->void:
	world.charted_to=0
	var site:=world._founding_site_advice(Vector3(1,1,0),true)
	assert_str(site.title).is_equal("WATER SUPPLY UNKNOWN")
	assert_int(world.water_queries).is_equal(0)

func test_recommendations_are_known_dry_near_water_and_reachable()->void:
	world.charted_to=4
	var sites:Array=world._founding_advisor().suggestions(Vector3(4,1,0))
	assert_int(sites.size()).is_between(1,3)
	for site:Dictionary in sites:
		assert_bool(world._world_position_is_revealed(site.position)).is_true()
		assert_bool(world._world_position_is_revealed(site.source_position)).is_true()
		assert_bool(world._settlement_surface_assessment(site.position).valid).is_true()
		assert_float(site.distance_km).is_less_equal(1.0)
	world.blocked_route=true
	assert_array(world._founding_advisor().suggestions(Vector3(4,1,0))).is_empty()

func test_found_button_opens_review_without_committing_or_spending()->void:
	world.settler_marker=auto_free(Area3D.new());world.settler_marker.position=Vector3(.5,1,0)
	var stores:=GameState.resource_stockpiles.duplicate(true)
	world._on_settlement_action_pressed()
	assert_vector(world.opened_site).is_equal(world.settler_marker.position)
	assert_bool(GameState.settlement_site_committed).is_false()
	assert_dict(GameState.resource_stockpiles).is_equal(stores)

func test_first_foundation_rechecks_exact_position_and_refuses_dry_site_without_water()->void:
	# Same cached display cell straddles the collection limit; commitment must
	# sample the real destination, not a previously green/amber hover cell.
	assert_bool(world._founding_site_advice(Vector3(5.999,1,0)).valid).is_true()
	world.settler_marker=auto_free(Area3D.new());world.settler_marker.position=Vector3(6.001,1,0)
	world.travel_status_label=auto_free(Label.new())
	var stores:=GameState.resource_stockpiles.duplicate(true)
	world._start_settlement_here()
	assert_bool(GameState.settlement_site_committed).is_false()
	assert_str(world.travel_status_label.text).contains("No known fresh water")
	assert_dict(GameState.resource_stockpiles).is_equal(stores)

func test_later_city_preview_quote_and_final_send_all_refuse_unconfirmed_water()->void:
	var position:=Vector3(10,1,0)
	world.settlement_convoy_instruction_label=auto_free(Label.new())
	assert_bool(world._settlement_convoy_site_assessment(position).valid).is_false()
	world._begin_settlement_convoy(position)
	assert_object(world.settlement_convoy_confirm_panel).is_null()
	world._open_settlement_convoy_confirmation(position,{},{"ok":true})
	assert_object(world.settlement_convoy_confirm_panel).is_null()
	world.settlement_convoy_pending_destination=position
	world.settlement_convoy_pending_quote={"ok":true,"duration_days":1.0}
	world.settlement_convoy_confirm_status=auto_free(Label.new())
	world.settlement_convoy_confirm_button=auto_free(Button.new())
	var stores:=GameState.resource_stockpiles.duplicate(true)
	world._confirm_settlement_convoy()
	assert_bool(world.settlement_convoy_confirm_button.disabled).is_true()
	assert_dict(GameState.resource_stockpiles).is_equal(stores)
	assert_bool(bool(GameState.settlement_convoy.get("active",false))).is_false()

func test_read_only_advice_does_not_create_water_or_advance_time()->void:
	var stores:=GameState.resource_stockpiles.duplicate(true)
	var days:=GameState.elapsed_days
	world._founding_site_advice(Vector3(.5,1,0))
	world._founding_advisor().suggestions(Vector3(4,1,0))
	assert_dict(GameState.resource_stockpiles).is_equal(stores)
	assert_float(GameState.elapsed_days).is_equal(days)

func test_usable_first_site_commits_the_actual_convoy_location()->void:
	var map:CommitMap=auto_free(CommitMap.new())
	map.settler_marker=auto_free(Area3D.new());map.settler_marker.position=Vector3(.5,1,0)
	map.travel_active=true;GameState.convoy_traveling=true
	map._start_settlement_here()
	await await_idle_frame()
	assert_bool(GameState.settlement_site_committed).is_true()
	assert_bool(map.travel_active).is_false()
	assert_bool(GameState.convoy_traveling).is_false()
	assert_vector(GameState.settlement_founded_at).is_equal(map.settler_marker.position)

func test_later_city_quote_keeps_water_warning_and_send_button_visible()->void:
	GameState.initialize_population_model();GameState.ensure_population_total(1000)
	GameState.settlement_site_committed=true;GameState.settlement_completed=["Hearth Circle"]
	GameState.settlement_founded_at=Vector3(-10,1,0)
	SettlementModel.ensure_founded()
	var viewport:SubViewport=auto_free(SubViewport.new());viewport.size=Vector2i(1024,640);add_child(viewport)
	var map:CommitMap=auto_free(CommitMap.new());viewport.add_child(map)
	map.interface_layer=CanvasLayer.new();map.add_child(map.interface_layer)
	CivilizationSystem.city_intelligence.records={"player":{"neighbor":_neighbor_report()}}
	var point:=Vector3(5,1,0)
	var assessment:Dictionary=map._settlement_convoy_site_assessment(point,true)
	assert_bool(assessment.valid).is_true()
	assert_bool(assessment.recommended).is_false()
	map._open_settlement_convoy_confirmation(point,{"distance_km":15},{"ok":true,"suggested_name":"Waterford","population":60,"duration_days":2,"food":300,"materials":{"Timber":40}})
	await await_idle_frame();await await_idle_frame()
	assert_bool(map.settlement_convoy_confirm_button.disabled).is_false()
	assert_str(map.settlement_convoy_confirm_status.text).contains("water-hauling")
	assert_str(map.settlement_convoy_confirm_status.text).contains("resentment")
	assert_float(map.settlement_convoy_confirm_button.get_global_rect().end.y).is_less_equal(624.0)
	assert_float(map.settlement_convoy_confirm_status.get_global_rect().end.y).is_less_equal(map.settlement_convoy_confirm_button.get_global_rect().position.y)
	assert_float(map.settlement_convoy_confirm_button.get_global_rect().end.x).is_less_equal(1008.0)
	map._dismiss_settlement_convoy_confirmation()

func _neighbor_report()->Dictionary:
	return {"city_id":"neighbor","civ_id":"neighbor_civ","controller":"neighbor_civ","name":"Riverbank","position":{"x":0.0,"z":0.0},"observed_day":0,"reported_day":0,"fields":{}}

func test_water_rich_site_can_still_be_a_border_provocation_and_is_not_recommended()->void:
	CivilizationSystem.city_intelligence.records={"player":{"neighbor":_neighbor_report()}}
	var site:=world._founding_site_advice(Vector3(.5,1,0),true)
	assert_bool(site.valid).is_true()
	assert_bool(site.water_recommended).is_true()
	assert_bool(site.recommended).is_false()
	assert_str(site.neighbors.title).contains("SEVERE")
	assert_array(world._founding_advisor().suggestions(Vector3(.5,1,0))).is_empty()

func test_actual_seeded_hydrology_and_suggestions_agree_with_daily_water_access()->void:
	var actual:Node3D=auto_free(Renderer.new())
	actual._configure_shape();actual._configure_noise();actual._prepare_river_course()
	CivilizationSystem.revealed_areas=[{"x":0.0,"z":0.0,"radius":100.0}]
	var x:float=actual._world_river_x(0.0)+.6
	var position:=Vector3(x,actual._height_at(x,0),0)
	var site:Dictionary=actual._founding_site_advice(position,true)
	assert_bool(site.recommended).is_true()
	assert_bool(actual._world_position_is_revealed(site.source_position)).is_true()
	var expected:float=actual._river_distance_at(x,0)
	assert_float(site.distance_km).is_equal_approx(expected,.001)
	var candidates:Array=actual._founding_advisor().suggestions(position)
	assert_array(candidates).is_not_empty()
	for candidate:Dictionary in candidates:
		var target:Vector3=candidate.position
		assert_bool(actual._settlement_surface_assessment(target).valid).is_true()
		assert_float(actual._river_distance_at(target.x,target.z)).is_less_equal(1.0)

func test_review_fits_small_canvas_and_map_click_closes_without_moving()->void:
	var viewport:SubViewport=auto_free(SubViewport.new());viewport.size=Vector2i(1024,640);add_child(viewport)
	var map:Map=auto_free(Map.new());viewport.add_child(map)
	map.settler_marker=Area3D.new();map.settler_marker.position=Vector3(6,1,0);map.add_child(map.settler_marker)
	var guide:Control=auto_free(Guide.new());viewport.add_child(guide);map.founding_site_guide=guide
	guide.setup(map,map.settler_marker.position,false)
	map._apply_modal_screen_contract(guide)
	await await_idle_frame();await await_idle_frame()
	assert_bool(guide.panel.has_meta("viewport_fit_hosted")).is_false()
	assert_bool(guide.heading.is_visible_in_tree()).is_true()
	assert_float(guide.panel.get_global_rect().end.x).is_less_equal(1024.0)
	assert_float(guide.panel.get_global_rect().end.y).is_less_equal(584.0)
	assert_float(guide.action.get_global_rect().end.y).is_less_equal(guide.panel.get_global_rect().end.y)
	assert_bool(guide.action.disabled).is_false()
	assert_str(guide.action.text).contains("WATER HAULING")
	CivilizationSystem.city_intelligence.records={"player":{"neighbor":_neighbor_report()}}
	CivilizationSystem.fog_revision+=1
	guide.update_site(Vector3(.5,1,0));guide._search()
	await await_idle_frame();await await_idle_frame()
	assert_str(guide.action.text).contains("PROVOKE NEIGHBOR")
	assert_float(guide.panel.get_global_rect().end.y).is_less_equal(584.0)
	assert_bool(map._dismiss_map_panels()).is_true()
	assert_bool(GameState.settlement_site_committed).is_false()
	assert_bool(map.travel_active).is_false()

func test_site_review_is_visual_and_only_lists_reported_nearby_resources()->void:
	GameState.resource_deposits=[
		{"id":"stone-near","resource":"Stone","stage":"recognized","position":Vector3(2,0,0),"quality":.8,"remaining":40.0,"initial_amount":40.0,"blockers":[],"access":0.0},
		{"id":"hidden-copper","resource":"Copper Ore","stage":"unknown","position":Vector3(1,0,0),"quality":1.0,"remaining":40.0,"initial_amount":40.0,"blockers":[],"access":0.0},
		{"id":"clay-far","resource":"Clay","stage":"surveyed","position":Vector3(25,0,0),"quality":1.0,"remaining":40.0,"initial_amount":40.0,"blockers":[],"access":0.0}
	]
	var viewport:SubViewport=auto_free(SubViewport.new());viewport.size=Vector2i(1024,640);add_child(viewport)
	var map:Map=auto_free(Map.new());viewport.add_child(map)
	var guide:Control=auto_free(Guide.new());viewport.add_child(guide);guide.setup(map,Vector3(.5,1,0),false)
	await await_idle_frame();await await_idle_frame()
	assert_str(guide.heading.text).is_equal("WATER NEARBY")
	assert_str(guide.meter_label.text).is_equal("100%")
	assert_str(guide.neighbor_label.text).is_equal("None reported within 30 km")
	assert_int(guide.resource_cards.size()).is_equal(1)
	assert_str(guide.resource_cards[0].resource).is_equal("Stone")
	assert_str(_visible_text(guide)).not_contains("Households can cover basic drinking needs")
	assert_str(_visible_text(guide)).not_contains("unlocated cities remain unknown")

func _visible_text(node:Node)->String:
	var result:=""
	if node is Label and node.is_visible_in_tree():result+=node.text+"\n"
	for child:Node in node.get_children():result+=_visible_text(child)
	return result

class CoastMap extends Map:
	func _height_at(x:float,_z:float)->float:return -1.0 if x<0 else 1.0
	func _world_river_x(_z:float)->float:return INF
	func _local_drainage_distance_at(_x:float,_z:float)->float:return .4
	func _local_drainage_channel_x(_index:int,_z:float)->float:return -.2
	func _founding_water_sources(point:Vector3)->Array[Dictionary]:return _surface_water_sources(point,6.0)

func test_submerged_drainage_is_not_drinking_water_in_either_daily_math_or_site_review()->void:
	var coast:CoastMap=auto_free(CoastMap.new())
	# Course sentinel avoids generating unrelated seeded tributaries in this isolated coast.
	coast.world_tributary_courses=[[]]
	var position:=Vector3(.4,1,0)
	assert_bool(is_inf(coast._river_distance_at(position.x,position.z))).is_true()
	var site:=coast._founding_site_advice(position,true)
	assert_bool(site.valid).is_false()
	assert_str(site.source_text).contains("Open water nearby")
	assert_str(site.reason).contains("not a confirmed drinking source")
	coast.charted_to=-1
	assert_str(coast._founding_site_advice(position,true).title).is_equal("WATER SUPPLY UNKNOWN")

func test_compact_review_keeps_close_and_action_visible_on_resize()->void:
	var viewport:SubViewport=auto_free(SubViewport.new());viewport.size=Vector2i(1024,640);add_child(viewport)
	var map:Map=auto_free(Map.new());viewport.add_child(map)
	map.settler_marker=Area3D.new();map.settler_marker.position=Vector3(6,1,0);map.add_child(map.settler_marker)
	var guide:Control=auto_free(Guide.new());viewport.add_child(guide)
	guide.setup(map,map.settler_marker.position,false)
	for canvas:Vector2i in [Vector2i(1024,640),Vector2i(1280,720),Vector2i(1024,640)]:
		viewport.size=canvas;guide._layout()
		await await_idle_frame();await await_idle_frame()
		assert_float(guide.panel.get_global_rect().end.y).is_less_equal(float(canvas.y)-80)
		assert_float(guide.action.get_global_rect().end.y).is_less_equal(guide.panel.get_global_rect().end.y)
		assert_float(guide.action.get_global_rect().position.y).is_greater_equal(guide.scroll.get_global_rect().end.y)
		assert_bool(guide.action.disabled).is_false()
