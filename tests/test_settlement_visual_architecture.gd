extends GdUnitTestSuite

const RENDERER:=preload("res://scripts/local_terrain.gd")
const VALUES:=preload("res://scripts/societal_values_model.gd")

var renderer:Node3D


func before_test()->void:
	GameState.reset_for_new_world(741991)
	renderer=auto_free(RENDERER.new())


func test_visual_signature_is_bounded_and_ignores_imperceptible_daily_drift()->void:
	var first:Dictionary={"axiality":0.500,"monumentality":0.500,"civic_space":0.500,"permeability":0.500,"defensive_depth":0.500,"terrain_conformity":0.500}
	var tiny_drift:=first.duplicate(true)
	tiny_drift.axiality=0.509
	var visible_drift:=first.duplicate(true)
	visible_drift.axiality=0.56
	assert_str(renderer._settlement_architecture_signature(first)).is_equal(renderer._settlement_architecture_signature(tiny_drift))
	assert_str(renderer._settlement_architecture_signature(first)).is_not_equal(renderer._settlement_architecture_signature(visible_drift))
	assert_int(renderer._settlement_architecture_signature(first).split(":").size()).is_equal(11)


func test_morphology_mesh_signature_ignores_invisible_drift_but_catches_visible_change()->void:
	GameState.settlement_plots=[{
		"id":1,"land_use":"residential_compound","form":"courtyard_compound","material_family":"earth",
		"roof_plan":"courtyard_flat","status":"active","fabric_generation":7,"storeys":2,
		"condition":0.801,"prosperity":0.501,"centroid":Vector2(0.20,-0.10)
	}]
	GameState.settlement_routes=[{
		"id":1,"kind":"desire_path","status":"active","hierarchy":"irregular_flat",
		"surface_tier":0,"points":PackedVector2Array([Vector2.ZERO,Vector2(0.2,-0.1)])
	}]
	GameState.morphology_revision=1
	var first:String=renderer._settlement_morphology_visual_signature()
	GameState.settlement_plots[0]["condition"]=0.809
	GameState.settlement_plots[0]["prosperity"]=0.509
	GameState.morphology_revision=2
	var invisible_drift:String=renderer._settlement_morphology_visual_signature()
	GameState.settlement_plots[0]["status"]="damaged"
	GameState.morphology_revision=3
	var visible_change:String=renderer._settlement_morphology_visual_signature()
	assert_str(first).is_equal(invisible_drift)
	assert_str(first).is_not_equal(visible_change)


func test_undirected_roof_alignment_uses_shortest_half_turn()->void:
	var aligned:float=float(renderer._lerp_undirected_angle(deg_to_rad(5.0),deg_to_rad(175.0),1.0))
	var difference:float=absf(wrapf(aligned-deg_to_rad(5.0),-PI*0.5,PI*0.5))
	assert_float(rad_to_deg(difference)).is_equal_approx(10.0,0.01)


func test_founding_values_produce_distinct_but_fixed_size_visual_grammars()->void:
	var inquiry:=VALUES.architecture_snapshot(VALUES.initial_state("inquiry",741991,"player"))
	var defense:=VALUES.architecture_snapshot(VALUES.initial_state("defense",741991,"player"))
	assert_int(inquiry.size()).is_equal(11)
	assert_int(defense.size()).is_equal(11)
	assert_str(renderer._settlement_architecture_signature(inquiry)).is_not_equal(renderer._settlement_architecture_signature(defense))
	assert_float(float(inquiry.permeability)).is_greater(float(defense.permeability))
	assert_float(float(defense.defensive_depth)).is_greater(float(inquiry.defensive_depth))


func test_visual_response_makes_lived_cultural_differences_legible_without_new_state()->void:
	var inquiry:=VALUES.architecture_snapshot(VALUES.initial_state("inquiry",741991,"player"))
	var defense:=VALUES.architecture_snapshot(VALUES.initial_state("defense",741991,"player"))
	var inquiry_visual:Dictionary=renderer._settlement_visual_architecture_profile(inquiry)
	var defense_visual:Dictionary=renderer._settlement_visual_architecture_profile(defense)
	assert_int(inquiry_visual.size()).is_equal(11)
	assert_float(float(inquiry_visual.permeability)-float(defense_visual.permeability)).is_greater(float(inquiry.permeability)-float(defense.permeability))
	assert_float(float(defense_visual.axiality)-float(inquiry_visual.axiality)).is_greater(float(defense.axiality)-float(inquiry.axiality))
	for value in inquiry_visual.values():
		assert_float(float(value)).is_between(0.0,1.0)


func test_each_founding_value_path_has_a_distinct_dominant_district_grammar()->void:
	var expected:Dictionary={
		"provision":"productive","generations":"lineage","inquiry":"inquiry",
		"industry":"industry","defense":"defense","exchange":"exchange"
	}
	var observed:Dictionary={}
	for focus in expected:
		var architecture:=VALUES.architecture_snapshot(VALUES.initial_state(focus,741991,"shared_culture_seed"))
		var family:String=renderer._settlement_dominant_architecture_family(architecture)
		observed[family]=true
		assert_str(family).is_equal(String(expected[focus]))
	assert_int(observed.size()).is_equal(6)


func test_cultural_signature_quota_preserves_mixed_city_fabric_and_excludes_water()->void:
	var inquiry:=VALUES.architecture_snapshot(VALUES.initial_state("inquiry",741991,"shared_culture_seed"))
	var signature_count:=0
	var mixed_count:=0
	for seed in 200:
		var family:String=renderer._settlement_architecture_district_family(inquiry,seed*7919,seed%3)
		if family=="mixed": mixed_count+=1
		else: signature_count+=1
	assert_int(signature_count).is_between(55,145)
	assert_int(mixed_count).is_between(55,145)
	for family in ["productive","lineage","inquiry","industry","exchange","defense"]:
		for tile in renderer._settlement_district_cultural_tile_options(false,family):
			assert_bool(int(tile) in [5,13,35,42,43]).is_false()
		for tile in renderer._settlement_district_cultural_tile_options(true,family):
			assert_int(int(tile)).is_not_equal(14)


func test_city_atlas_balancer_prevents_one_repeated_stamp_without_painting_water()->void:
	var architecture:=VALUES.architecture_snapshot(VALUES.initial_state("inquiry",741991,"shared_culture_seed"))
	for modern in [false,true]:
		var usage:Dictionary={}
		for index in 48:
			var seed:=741991+index*7919
			var land_use:=index%3
			var preferred:int=renderer._settlement_district_tile_index(modern,4,land_use,architecture,seed,false,{})
			var options:Array=renderer._settlement_district_balanced_tile_options(modern,4,land_use,architecture,seed,{})
			var selected:int=renderer._settlement_district_balanced_tile_index(preferred,options,usage,seed)
			usage[selected]=int(usage.get(selected,0))+1
		assert_int(usage.size()).is_greater_equal(16)
		var water_tiles:Array=[14,18] if modern else [5,13,35,42,43]
		for tile in usage:
			assert_bool(int(tile) in water_tiles).is_false()
			assert_int(int(usage[tile])).is_less_equal(3)


func test_six_value_paths_produce_six_bounded_road_grammars_without_more_geometry()->void:
	var signatures:Dictionary={}
	for focus in ["provision","generations","inquiry","industry","defense","exchange"]:
		var architecture:=VALUES.architecture_snapshot(VALUES.initial_state(focus,741991,"shared_culture_seed"))
		var grammar:Dictionary=renderer._settlement_district_road_grammar(architecture)
		var signature:="%d:%d:%d:%d:%d" % [roundi(float(grammar.reach)*1000.0),roundi(float(grammar.bend)*1000.0),roundi(float(grammar.mesh)*1000.0),roundi(float(grammar.keep_scale)*1000.0),roundi(float(grammar.width_scale)*1000.0)]
		signatures[signature]=true
		assert_float(float(grammar.keep_scale)).is_between(0.72,1.22)
		assert_float(float(grammar.width_scale)).is_between(0.76,1.26)
	assert_int(signatures.size()).is_equal(6)


func test_actual_founding_focus_changes_metropolitan_topology_not_only_tint()->void:
	GameState.settlement_name="Alder Reach"
	var profile:Dictionary=renderer._settlement_expansion_visual_profile({"classification":"metropolis","population":2400000})
	var no_plots:Array[Dictionary]=[]
	renderer.active_architecture_profile=VALUES.architecture_snapshot(VALUES.initial_state("inquiry",741991,"player"))
	var inquiry_layout:Dictionary=renderer._settlement_stage_visual_layout(profile,2400000,no_plots)
	renderer.active_architecture_profile=VALUES.architecture_snapshot(VALUES.initial_state("defense",741991,"player"))
	var defense_layout:Dictionary=renderer._settlement_stage_visual_layout(profile,2400000,no_plots)
	assert_array(inquiry_layout.cores).is_not_equal(defense_layout.cores)
	assert_array(inquiry_layout.corridor_angles).is_not_equal(defense_layout.corridor_angles)


func test_late_city_aerial_tone_inherits_real_construction_materials()->void:
	var architecture:Dictionary={"monumentality":0.5,"civic_space":0.5}
	var organic_plots:Array[Dictionary]=[
		{"material_family":"organic","area_ha":4.0,"status":"active"}
	]
	var stone_plots:Array[Dictionary]=[
		{"material_family":"stone","area_ha":4.0,"status":"active"}
	]
	var organic:Dictionary=renderer._settlement_stage_material_palette(organic_plots,5,architecture)
	var stone:Dictionary=renderer._settlement_stage_material_palette(stone_plots,5,architecture)
	assert_float(float(organic.organic_share)).is_equal_approx(1.0,0.001)
	assert_float(float(stone.stone_share)).is_equal_approx(1.0,0.001)
	assert_bool((organic.base as Color).is_equal_approx(stone.base as Color)).is_false()


func test_hundreds_of_aggregate_plots_still_commit_a_fixed_mesh_set()->void:
	GameState.societal_values=VALUES.initial_state("defense",741991,"player")
	var plots:Array[Dictionary]=[]
	for index in 256:
		var grid_x:=index%16
		var grid_z:=index/16
		var centroid:=Vector2((float(grid_x)-7.5)*0.018,(float(grid_z)-7.5)*0.018)
		var radius:=0.0072
		var polygon:=PackedVector2Array([
			centroid+Vector2(-radius,-radius*0.72),centroid+Vector2(radius*0.84,-radius),
			centroid+Vector2(radius,radius*0.68),centroid+Vector2(-radius*0.76,radius)
		])
		plots.append({
			"id":index+1,"seed":741991+index*97,"polygon":polygon,"centroid":centroid,
			"area_ha":0.08,"land_use":"residential_compound" if index%7 else "communal",
			"form":"courtyard_compound","material_family":"earth","material_mix":{"Clay":0.52,"Timber":0.24,"Fiber Plants":0.18},
			"roof_plan":"courtyard_flat","roof_coverage":0.42,"resident_count":26,"storeys":2,
			"condition":0.78,"prosperity":0.48,"status":"active","fabric_generation":7,"created_day":0
		})
	for lod in [0,1]:
		var parent:Node3D=auto_free(Node3D.new())
		renderer._create_plot_fabric(Vector3.ZERO,plots,lod,parent)
		assert_int(parent.get_child_count()).is_greater_equal(4)
		assert_int(parent.get_child_count()).is_less_equal(10)
		var roofs:=parent.get_node_or_null("PersistentRoofFabric") as MeshInstance3D
		assert_object(roofs).is_not_null()
		if roofs!=null:
			assert_int(roofs.mesh.get_surface_count()).is_greater(0)
		for child in parent.get_children(): assert_bool(child is MeshInstance3D).is_true()


func test_world_scale_border_renderer_culls_offscreen_settlements_and_hidden_lod()->void:
	var test_camera:Camera3D=auto_free(Camera3D.new())
	test_camera.size=100.0
	renderer.camera=test_camera
	renderer.camera_target=Vector3(500.0,0.0,-400.0)
	assert_bool(renderer._settlement_boundary_in_current_view({"position":Vector2(520.0,-390.0),"claim_radius_km":4.0})).is_true()
	assert_bool(renderer._settlement_boundary_in_current_view({"position":Vector2(1800.0,900.0),"claim_radius_km":4.0})).is_false()
	test_camera.size=3000.0
	assert_bool(renderer._settlement_boundary_in_current_view({"position":Vector2(500.0,-400.0),"claim_radius_km":4.0})).is_false()


func test_secondary_settlement_symbols_use_one_batch_and_bounded_labels()->void:
	var test_camera:Camera3D=auto_free(Camera3D.new())
	test_camera.size=50.0
	renderer.camera=test_camera
	var marker_root:Node3D=auto_free(Node3D.new())
	renderer.settlement_network_marker_root=marker_root
	var settlements:Array[Dictionary]=[]
	for index in 500:
		settlements.append({"id":"settlement_%d" % index,"name":"Settlement %d" % index,"classification":"town","population":500+index,"position":Vector2(float(index%25),float(index/25))})
	renderer._create_secondary_settlement_markers(settlements)
	assert_int(marker_root.get_child_count()).is_equal(25)
	assert_bool(marker_root.get_child(0) is MultiMeshInstance3D).is_true()
	var blips:=marker_root.get_child(0) as MultiMeshInstance3D
	assert_int(blips.multimesh.instance_count).is_equal(500)
	assert_bool(blips.multimesh.use_colors).is_true()


func test_expansion_stage_is_readable_by_text_weight_and_scale_not_color_alone()->void:
	var camp:Dictionary=renderer._settlement_expansion_visual_profile({"classification":"founding camp","population":40})
	var hamlet:Dictionary=renderer._settlement_expansion_visual_profile({"classification":"hamlet","population":180})
	var village:Dictionary=renderer._settlement_expansion_visual_profile({"classification":"village","population":1200})
	var town:Dictionary=renderer._settlement_expansion_visual_profile({"classification":"town","population":9000})
	var city:Dictionary=renderer._settlement_expansion_visual_profile({"classification":"city","population":120000})
	assert_array([camp.id,hamlet.id,village.id,town.id,city.id]).is_equal(["camp","hamlet","village","town","city"])
	assert_array([camp.label,hamlet.label,village.label,town.label,city.label]).is_equal(["FOUNDING CAMP","HAMLET","VILLAGE","TOWN","CITY"])
	assert_float(float(city.border_scale)).is_greater(float(camp.border_scale))
	assert_float(float(city.marker_scale)).is_greater(float(camp.marker_scale))
	assert_float(float(city.fill_alpha)).is_greater(float(camp.fill_alpha))
	assert_bool(Color(city.color)!=Color(camp.color)).is_true()


func test_expansion_grammar_continues_through_metropolis_and_megalopolis()->void:
	var city:Dictionary=renderer._settlement_expansion_visual_profile({"classification":"city","population":120000})
	var metropolis:Dictionary=renderer._settlement_expansion_visual_profile({"classification":"metropolis","population":2400000})
	var megalopolis:Dictionary=renderer._settlement_expansion_visual_profile({"classification":"megalopolis","population":24000000})
	assert_array([city.id,metropolis.id,megalopolis.id]).is_equal(["city","metropolis","megalopolis"])
	assert_array([city.label,metropolis.label,megalopolis.label]).is_equal(["CITY","METROPOLIS","MEGALOPOLIS"])
	assert_int(int(metropolis.core_count)).is_greater(int(city.core_count))
	assert_int(int(megalopolis.core_count)).is_greater(int(metropolis.core_count))
	assert_int(int(megalopolis.ring_count)).is_equal(3)
	assert_int(int(megalopolis.skyline_clusters)*int(megalopolis.masses_per_cluster)).is_less_equal(64)
	assert_float(renderer._settlement_stage_landscape_max_zoom(megalopolis)).is_greater(renderer._settlement_stage_landscape_max_zoom(metropolis))
	assert_float(renderer._settlement_stage_marker_zoom(megalopolis)).is_greater(renderer._settlement_stage_marker_zoom(city))


func test_beltways_require_a_real_engineered_network_and_never_become_orbits()->void:
	var layout:Dictionary={"ring_count":3}
	var one_upgraded_road:Array=[{"active":true,"surface_tier":6}]
	assert_int(renderer._settlement_supported_ring_count(layout,6,8,one_upgraded_road)).is_equal(0)
	var first_network:Array=[]
	for index in 3: first_network.append({"active":true,"surface_tier":4,"id":index})
	assert_int(renderer._settlement_supported_ring_count(layout,6,8,first_network)).is_equal(1)
	var mature_network:Array=[]
	for index in 9: mature_network.append({"active":true,"surface_tier":6,"id":index})
	assert_int(renderer._settlement_supported_ring_count(layout,6,8,mature_network)).is_equal(2)
	assert_int(renderer._settlement_supported_ring_count(layout,5,8,mature_network)).is_equal(1)


func test_population_alone_does_not_turn_a_classified_founding_camp_into_a_city_graphic()->void:
	var crowded_camp:Dictionary=renderer._settlement_expansion_visual_profile({"classification":"founding camp","population":100000})
	var unknown_legacy_record:Dictionary=renderer._settlement_expansion_visual_profile({"classification":"unknown","population":100000})
	assert_str(String(crowded_camp.id)).is_equal("camp")
	assert_str(String(unknown_legacy_record.id)).is_equal("city")


func test_city_visually_accumulates_the_next_stage_without_changing_its_label_early()->void:
	var young_city:Dictionary=renderer._settlement_expansion_visual_profile({"classification":"city","population":900000,"stage_progress":0.0})
	var nearly_metropolitan:Dictionary=renderer._settlement_expansion_visual_profile({"classification":"city","population":900000,"stage_progress":0.90})
	assert_str(String(nearly_metropolitan.id)).is_equal("city")
	assert_str(String(nearly_metropolitan.label)).is_equal("CITY")
	assert_int(int(nearly_metropolitan.core_count)).is_greater(int(young_city.core_count))
	assert_int(int(nearly_metropolitan.satellite_count)).is_greater(int(young_city.satellite_count))
	assert_float(float(nearly_metropolitan.border_scale)).is_greater(float(young_city.border_scale))


func test_new_urban_features_reveal_continuously_instead_of_popping_at_stage_thresholds()->void:
	var early:Array[float]=renderer._settlement_feature_reveals(1,4,0.10)
	var middle:Array[float]=renderer._settlement_feature_reveals(1,4,0.50)
	var late:Array[float]=renderer._settlement_feature_reveals(1,4,0.90)
	assert_float(early[0]).is_equal(1.0)
	assert_float(early[1]).is_between(0.0,1.0)
	assert_int(middle.size()).is_greater_equal(early.size())
	assert_int(late.size()).is_greater_equal(middle.size())
	assert_float(late[late.size()-1]).is_between(0.0,1.0)
	for reveal in late: assert_float(reveal).is_between(0.0,1.0)


func test_stage_layout_carries_bounded_reveal_weights_for_every_aggregate_feature()->void:
	GameState.settlement_name="Alder Reach"
	var profile:Dictionary=renderer._settlement_expansion_visual_profile({"classification":"city","population":900000,"stage_progress":0.44})
	var no_plots:Array[Dictionary]=[]
	var layout:Dictionary=renderer._settlement_stage_visual_layout(profile,900000,no_plots)
	assert_int(layout.core_reveals.size()).is_equal(layout.cores.size())
	assert_int(layout.satellite_reveals.size()).is_equal(layout.satellites.size())
	assert_int(layout.corridor_reveals.size()).is_equal(layout.corridor_angles.size())
	assert_int(layout.skyline_reveals.size()).is_equal(int(layout.skyline_clusters))
	assert_int(layout.mass_reveals.size()).is_equal(int(layout.masses_per_cluster))
	assert_int(layout.wedge_reveals.size()).is_equal(int(layout.green_wedges))
	assert_int(layout.district_reveals.size()).is_equal(int(layout.district_patches))


func test_visual_transition_waits_for_the_weakest_real_functional_gate()->void:
	var ready:Dictionary={"resident_population":900000,"service_population":1600000,"connectivity":0.54,"infrastructure":0.63,"specialization":0.44,"district_count":4}
	var disconnected:=ready.duplicate(true)
	disconnected.connectivity=0.12
	assert_float(renderer._settlement_visual_stage_progress(ready,"city")).is_greater(0.65)
	assert_float(renderer._settlement_visual_stage_progress(disconnected,"city")).is_equal(0.0)


func test_metropolitan_layout_is_deterministic_and_population_changes_extent_not_draw_budget()->void:
	GameState.settlement_name="Alder Reach"
	var profile:Dictionary=renderer._settlement_expansion_visual_profile({"classification":"megalopolis","population":24000000})
	var no_plots:Array[Dictionary]=[]
	var first:Dictionary=renderer._settlement_stage_visual_layout(profile,24000000,no_plots)
	var second:Dictionary=renderer._settlement_stage_visual_layout(profile,24000000,no_plots)
	var billion:Dictionary=renderer._settlement_stage_visual_layout(profile,1000000000,no_plots)
	assert_array(first.cores).is_equal(second.cores)
	assert_array(first.satellites).is_equal(second.satellites)
	assert_array(first.corridor_angles).is_equal(second.corridor_angles)
	assert_float(float(billion.radius)).is_greater(float(first.radius))
	assert_int(first.cores.size()).is_equal(8)
	assert_int(first.satellites.size()).is_equal(8)
	assert_int(int(first.skyline_clusters)*int(first.masses_per_cluster)).is_equal(64)


func test_later_urban_stages_add_to_the_same_civilization_grammar_without_reseeding_older_cores()->void:
	GameState.settlement_name="Alder Reach"
	var no_plots:Array[Dictionary]=[]
	var city_profile:Dictionary=renderer._settlement_expansion_visual_profile({"classification":"city","population":24000000})
	var metro_profile:Dictionary=renderer._settlement_expansion_visual_profile({"classification":"metropolis","population":24000000})
	var mega_profile:Dictionary=renderer._settlement_expansion_visual_profile({"classification":"megalopolis","population":24000000})
	var city_layout:Dictionary=renderer._settlement_stage_visual_layout(city_profile,24000000,no_plots)
	var metro_layout:Dictionary=renderer._settlement_stage_visual_layout(metro_profile,24000000,no_plots)
	var mega_layout:Dictionary=renderer._settlement_stage_visual_layout(mega_profile,24000000,no_plots)
	assert_array(city_layout.cores).is_equal((metro_layout.cores as Array).slice(0,city_layout.cores.size()))
	assert_array(metro_layout.cores).is_equal((mega_layout.cores as Array).slice(0,metro_layout.cores.size()))
	assert_array(city_layout.corridor_angles).is_equal((metro_layout.corridor_angles as Array).slice(0,city_layout.corridor_angles.size()))


func test_societal_architecture_changes_metropolitan_geometry_not_only_its_color()->void:
	GameState.settlement_name="Alder Reach"
	GameState.founding_focus="provision"
	var profile:Dictionary=renderer._settlement_expansion_visual_profile({"classification":"metropolis","population":2400000})
	var no_plots:Array[Dictionary]=[]
	renderer.active_architecture_profile={"axiality":0.96,"monumentality":0.82,"civic_space":0.30,"permeability":0.22,"defensive_depth":0.78,"terrain_conformity":0.16}
	var formal:Dictionary=renderer._settlement_stage_visual_layout(profile,2400000,no_plots)
	renderer.active_architecture_profile={"axiality":0.08,"monumentality":0.20,"civic_space":0.78,"permeability":0.88,"defensive_depth":0.18,"terrain_conformity":0.94}
	var organic:Dictionary=renderer._settlement_stage_visual_layout(profile,2400000,no_plots)
	assert_array(formal.cores).is_not_equal(organic.cores)
	assert_array(formal.corridor_angles).is_not_equal(organic.corridor_angles)


func test_metropolitan_rendering_uses_persistent_simulated_nuclei_before_visual_fallbacks()->void:
	GameState.settlement_nuclei=[
		{"id":1,"kind":"founding_hearth","position":Vector2.ZERO,"active":true},
		{"id":2,"kind":"market_crossing","position":Vector2(1.75,-0.60),"active":true},
		{"id":3,"kind":"satellite_quarter","position":Vector2(-2.20,1.10),"active":true}
	]
	var profile:Dictionary=renderer._settlement_expansion_visual_profile({"classification":"metropolis","population":2400000})
	var no_plots:Array[Dictionary]=[]
	var layout:Dictionary=renderer._settlement_stage_visual_layout(profile,2400000,no_plots)
	assert_bool(Vector2(layout.cores[0]).is_equal_approx(Vector2.ZERO)).is_true()
	assert_bool(Vector2(layout.cores[1]).is_equal_approx(Vector2(1.75,-0.60))).is_true()
	assert_bool(Vector2(layout.cores[2]).is_equal_approx(Vector2(-2.20,1.10))).is_true()


func test_strategic_civic_anchors_come_from_active_simulated_land_use_only()->void:
	var plots:Array[Dictionary]=[
		{"id":1,"land_use":"civic","status":"active","centroid":Vector2(0.20,0.10),"service_access":0.9,"prosperity":0.7,"area_ha":1.0},
		{"id":2,"land_use":"market","status":"ruin","centroid":Vector2(0.80,0.40),"service_access":1.0,"prosperity":0.8,"area_ha":1.0},
		{"id":3,"land_use":"workshop","status":"active","centroid":Vector2(-0.30,0.20),"service_access":0.7,"prosperity":0.6,"area_ha":1.0}
	]
	var civic:Array[Vector2]=renderer._settlement_stage_function_anchors(plots,["civic","market"],3)
	var productive:Array[Vector2]=renderer._settlement_stage_function_anchors(plots,["workshop"],3)
	assert_array(civic).is_equal([Vector2(0.20,0.10)])
	assert_array(productive).is_equal([Vector2(-0.30,0.20)])


func test_billion_person_megalopolis_commits_at_most_four_bounded_batched_surfaces()->void:
	GameState.societal_values=VALUES.initial_state("inquiry",741991,"player")
	renderer.footprint_population=1000000000
	var profile:Dictionary=renderer._settlement_expansion_visual_profile({"classification":"megalopolis","population":1000000000})
	var no_plots:Array[Dictionary]=[]
	var parent:Node3D=auto_free(Node3D.new())
	renderer._create_settlement_stage_landscape(Vector3.ZERO,profile,no_plots,1,parent)
	# The unified terrain-draped density field may eliminate an otherwise empty
	# open-space batch. The scaling contract is an upper bound, not an exact count.
	assert_int(parent.get_child_count()).is_between(2,4)
	var vertex_total:=0
	for child in parent.get_children():
		assert_bool(child is MeshInstance3D).is_true()
		var mesh:Mesh=(child as MeshInstance3D).mesh
		vertex_total+=mesh.surface_get_array_len(0)
	assert_int(vertex_total).is_less_equal(5000)


func test_fully_engineered_billion_person_megalopolis_stays_under_worst_case_vertex_cap()->void:
	GameState.societal_values=VALUES.initial_state("inquiry",741991,"player")
	ProgressionSystem.domain_levels["infrastructure"]=8
	ProgressionSystem.domain_levels["production"]=8
	GameState.settlement_routes=[{"active":true,"surface_tier":5,"points":PackedVector2Array([Vector2.ZERO,Vector2(1.0,0.0)])}]
	renderer.footprint_population=1000000000
	var profile:Dictionary=renderer._settlement_expansion_visual_profile({"classification":"megalopolis","population":1000000000})
	var no_plots:Array[Dictionary]=[]
	var parent:Node3D=auto_free(Node3D.new())
	renderer._create_settlement_stage_landscape(Vector3.ZERO,profile,no_plots,1,parent)
	assert_int(parent.get_child_count()).is_between(2,4)
	var vertex_total:=0
	for child in parent.get_children(): vertex_total+=((child as MeshInstance3D).mesh as Mesh).surface_get_array_len(0)
	assert_int(vertex_total).is_less_equal(7600)


func test_aggregate_damage_ratio_survives_zoom_without_unbounded_ruin_objects()->void:
	var intact:Array[Dictionary]=[{"area_ha":2.0,"status":"active","condition":1.0},{"area_ha":1.0,"status":"active","condition":0.9}]
	var neglected_but_inhabited:Array[Dictionary]=[{"area_ha":2.0,"status":"active","condition":0.22,"damage":{"neglect":0.94}}]
	var structurally_damaged:Array[Dictionary]=[{"area_ha":2.0,"status":"active","condition":0.82,"damage":{"structural":0.55}}]
	var damaged:Array[Dictionary]=[{"area_ha":2.0,"status":"ruin","condition":0.05},{"area_ha":1.0,"status":"damaged","condition":0.4}]
	assert_float(renderer._settlement_stage_damage_ratio(neglected_but_inhabited)).is_equal(0.0)
	assert_float(renderer._settlement_stage_damage_ratio(structurally_damaged)).is_greater(0.0)
	assert_float(renderer._settlement_stage_damage_ratio(damaged)).is_greater(renderer._settlement_stage_damage_ratio(intact))
	assert_float(renderer._settlement_stage_damage_ratio(damaged)).is_less_equal(1.0)


func test_defense_visual_signature_refreshes_on_meaningful_construction_or_siege_change_only()->void:
	var first:Dictionary={"stage":3,"integrity":0.811,"construction":{"active":true,"stage":4,"progress":0.211}}
	var tiny_drift:Dictionary={"stage":3,"integrity":0.819,"construction":{"active":true,"stage":4,"progress":0.219}}
	var visible_change:Dictionary={"stage":3,"integrity":0.74,"construction":{"active":true,"stage":4,"progress":0.31}}
	assert_str(renderer._settlement_defense_visual_signature(first)).is_equal(renderer._settlement_defense_visual_signature(tiny_drift))
	assert_str(renderer._settlement_defense_visual_signature(first)).is_not_equal(renderer._settlement_defense_visual_signature(visible_change))


func test_defense_construction_grows_and_siege_damage_breaks_the_same_bounded_geometry()->void:
	var profile:Dictionary=renderer._settlement_expansion_visual_profile({"classification":"city","population":120000})
	var no_plots:Array[Dictionary]=[]
	var layout:Dictionary=renderer._settlement_stage_visual_layout(profile,120000,no_plots)
	var flat_surface:=SurfaceTool.new()
	flat_surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var mass_surface:=SurfaceTool.new()
	mass_surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var early:Dictionary=renderer._append_settlement_defense_visuals(flat_surface,mass_surface,Vector3.ZERO,layout,120000,5,1.0,0.25,true)
	flat_surface=SurfaceTool.new()
	flat_surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	mass_surface=SurfaceTool.new()
	mass_surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var late:Dictionary=renderer._append_settlement_defense_visuals(flat_surface,mass_surface,Vector3.ZERO,layout,120000,5,1.0,0.80,true)
	flat_surface=SurfaceTool.new()
	flat_surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	mass_surface=SurfaceTool.new()
	mass_surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var breached:Dictionary=renderer._append_settlement_defense_visuals(flat_surface,mass_surface,Vector3.ZERO,layout,120000,5,0.28,1.0,false)
	assert_int(int(late.mass)).is_greater(int(early.mass))
	assert_int(int(late.mass)).is_greater(int(breached.mass))


func test_bastion_network_stays_at_or_below_the_four_surface_world_city_budget()->void:
	GameState.societal_values=VALUES.initial_state("defense",741991,"player")
	ProgressionSystem.domain_levels["infrastructure"]=8
	ProgressionSystem.domain_levels["production"]=8
	GameState.settlement_routes=[{"active":true,"surface_tier":5,"points":PackedVector2Array([Vector2.ZERO,Vector2(1.0,0.0)])}]
	renderer.footprint_population=1000000000
	var profile:Dictionary=renderer._settlement_expansion_visual_profile({"classification":"megalopolis","population":1000000000})
	var parent:Node3D=auto_free(Node3D.new())
	var defense:Dictionary={"stage":5,"integrity":1.0,"construction":{}}
	var no_plots:Array[Dictionary]=[]
	renderer._create_settlement_stage_landscape(Vector3.ZERO,profile,no_plots,1,parent,defense)
	assert_int(parent.get_child_count()).is_between(2,4)
	var vertex_total:=0
	for child in parent.get_children(): vertex_total+=((child as MeshInstance3D).mesh as Mesh).surface_get_array_len(0)
	assert_int(vertex_total).is_less_equal(9000)


func test_stage_aware_secondary_symbols_remain_one_batch()->void:
	var test_camera:Camera3D=auto_free(Camera3D.new())
	test_camera.size=80.0
	renderer.camera=test_camera
	var marker_root:Node3D=auto_free(Node3D.new())
	renderer.settlement_network_marker_root=marker_root
	var settlements:Array[Dictionary]=[
		{"name":"New Camp","classification":"founding camp","population":40,"position":Vector2.ZERO},
		{"name":"Large City","classification":"city","population":120000,"position":Vector2(8.0,0.0)}
	]
	renderer._create_secondary_settlement_markers(settlements)
	var blips:=marker_root.get_child(0) as MultiMeshInstance3D
	assert_int(blips.multimesh.instance_count).is_equal(2)
	assert_bool(blips.multimesh.use_colors).is_true()
	assert_int(marker_root.get_child_count()).is_equal(3)


func test_secondary_urban_extent_scales_with_population_and_stays_inside_the_claim()->void:
	var town:Dictionary={"classification":"town","population":9000}
	var metropolis:Dictionary={"classification":"metropolis","population":2400000}
	var bounded_metropolis:=metropolis.duplicate(true)
	bounded_metropolis["claim_radius_km"]=12.0
	assert_float(renderer._secondary_settlement_urban_radius(metropolis)).is_greater(renderer._secondary_settlement_urban_radius(town))
	assert_float(renderer._secondary_settlement_urban_radius(bounded_metropolis)).is_less_equal(12.0*0.82)


func test_entire_secondary_network_has_one_fixed_footprint_patch_budget()->void:
	var settlements:Array[Dictionary]=[]
	for index in 256:
		settlements.append({
			"id":"settlement_%d" % index,
			"classification":"megalopolis" if index%3==0 else ("city" if index%3==1 else "town"),
			"population":1000000000-index*1000
		})
	var allocations:PackedInt32Array=renderer._secondary_settlement_footprint_patch_allocations(settlements)
	var total:=0
	for allocation in allocations:
		assert_int(allocation).is_greater_equal(1)
		total+=allocation
	assert_int(total).is_equal(renderer.SECONDARY_SETTLEMENT_FOOTPRINT_PATCH_BUDGET)


func test_a_secondary_megalopolis_commits_one_batched_physical_surface()->void:
	var test_camera:Camera3D=auto_free(Camera3D.new())
	test_camera.size=400.0
	renderer.camera=test_camera
	renderer.settlement_network_marker_root=auto_free(Node3D.new())
	var settlements:Array[Dictionary]=[{
		"id":"secondary_world_city","name":"World City","classification":"megalopolis",
		"population":1000000000,"position":Vector2.ZERO,"claim_radius_km":420.0,
		"territory_drivers":{}
	}]
	renderer._create_secondary_settlement_footprints(settlements)
	assert_int(renderer.settlement_network_marker_root.get_child_count()).is_equal(1)
	var footprint:=renderer.settlement_network_marker_root.get_child(0) as MeshInstance3D
	assert_str(footprint.name).is_equal("SecondaryUrbanSystems")
	assert_int((footprint.mesh as Mesh).surface_get_array_len(0)).is_less_equal(512)


func test_controlled_ground_fill_uses_fixed_boundary_geometry()->void:
	var boundary:=PackedVector2Array()
	for index in 32: boundary.append(Vector2.from_angle(TAU*float(index)/32.0)*4.0)
	var surface:=SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	assert_int(renderer._append_settlement_claim_fill(surface,boundary,Color(0.8,0.7,0.4,0.05))).is_equal(32)
	var mesh:=surface.commit()
	assert_int(mesh.surface_get_array_len(0)).is_equal(96)


func test_controlled_ground_wash_disappears_during_close_inspection()->void:
	var test_camera:Camera3D=auto_free(Camera3D.new())
	renderer.camera=test_camera
	test_camera.size=1.0
	assert_float(renderer._settlement_claim_fill_alpha(0.07)).is_equal(0.0)
	test_camera.size=180.0
	assert_float(renderer._settlement_claim_fill_alpha(0.07)).is_greater(0.06)


func test_claim_tint_enters_gradually_and_updates_without_rebuilding_geometry()->void:
	var test_camera:Camera3D=auto_free(Camera3D.new())
	renderer.camera=test_camera
	var root:Node3D=auto_free(Node3D.new())
	renderer.settlement_border_root=root
	var wash:=MeshInstance3D.new()
	wash.name="ControlledGroundWash"
	var material:=StandardMaterial3D.new()
	wash.material_override=material
	root.add_child(wash)
	var previous:=0.0
	for zoom in [2.39,2.41,3.0,4.4,40.0,180.0]:
		test_camera.size=zoom
		renderer._update_settlement_claim_opacity()
		assert_object(wash.material_override).is_same(material)
		assert_float(material.albedo_color.a).is_greater_equal(previous)
		if zoom<2.42: assert_float(material.albedo_color.a).is_less(0.0001)
		previous=material.albedo_color.a
	assert_float(previous).is_equal_approx(1.0,0.00001)


func test_resource_labels_yield_to_settlement_identity_at_regional_zoom()->void:
	var test_camera:Camera3D=auto_free(Camera3D.new())
	test_camera.size=100.0
	renderer.camera=test_camera
	GameState.player_settlements=[{"id":"home","primary":true,"position":Vector2(20.0,-8.0)}]
	assert_bool(renderer._resource_label_conflicts_with_settlement(Vector3(22.0,0.0,-7.0))).is_true()
	assert_bool(renderer._resource_label_conflicts_with_settlement(Vector3(60.0,0.0,-7.0))).is_false()


func test_world_zoom_retains_one_explicit_home_orientation_cue()->void:
	GameState.settlement_name="Alder Reach"
	var text:String=renderer._settlement_map_label_text(3000.0)
	assert_str(text).is_equal("HOME  •  ALDER REACH")


func test_distant_urban_density_is_deterministic_and_strictly_bounded()->void:
	var first:Array[int]=[]
	var second:Array[int]=[]
	for index in 4096:
		var plot:Dictionary={"id":index+1,"status":"active","land_use":"residential_compound"}
		if renderer._settlement_plot_has_aggregate_density(plot,index,4096,2): first.append(index+1)
		if renderer._settlement_plot_has_aggregate_density(plot,index,4096,2): second.append(index+1)
	assert_array(first).is_equal(second)
	assert_int(first.size()).is_greater(120)
	assert_int(first.size()).is_less_equal(renderer.SETTLEMENT_AGGREGATE_DENSITY_BUDGET)


func test_persistent_density_tone_distinguishes_old_core_new_expansion_and_war_damage()->void:
	var old_core:Dictionary={"fabric_generation":10,"created_day":GameState.elapsed_days-365.0*150.0,"status":"active"}
	var new_edge:Dictionary={"fabric_generation":6,"created_day":GameState.elapsed_days-365.0,"status":"active"}
	var damaged_core:=old_core.duplicate(true)
	damaged_core["status"]="damaged"
	var old_color:Color=renderer._settlement_aggregate_density_color(old_core,2)
	var edge_color:Color=renderer._settlement_aggregate_density_color(new_edge,2)
	var damaged_color:Color=renderer._settlement_aggregate_density_color(damaged_core,2)
	assert_bool(old_color!=edge_color).is_true()
	assert_bool(damaged_color!=old_color).is_true()
	assert_float(damaged_color.get_luminance()).is_less(old_color.get_luminance())


func test_committing_a_site_retires_the_travel_ring_but_preserves_founding_camp_identity()->void:
	renderer.settler_map_ring=auto_free(MeshInstance3D.new())
	renderer.convoy_map_icon=auto_free(Node3D.new())
	renderer.convoy_map_label=auto_free(Label3D.new())
	renderer.convoy_detail_root=auto_free(Node3D.new())
	for node in [renderer.settler_map_ring,renderer.convoy_map_icon,renderer.convoy_map_label,renderer.convoy_detail_root]: node.visible=true
	renderer._retire_founding_expedition_visuals()
	assert_bool(renderer.settler_map_ring.visible).is_false()
	for node in [renderer.convoy_map_icon,renderer.convoy_map_label,renderer.convoy_detail_root]: assert_bool(node.visible).is_true()


func test_secondary_settlement_labels_thin_but_retain_three_world_scale_anchors()->void:
	var test_camera:Camera3D=auto_free(Camera3D.new())
	renderer.camera=test_camera
	test_camera.size=50.0
	assert_int(renderer._secondary_settlement_label_limit()).is_equal(24)
	test_camera.size=500.0
	assert_int(renderer._secondary_settlement_label_limit()).is_equal(16)
	test_camera.size=2000.0
	assert_int(renderer._secondary_settlement_label_limit()).is_equal(8)
	test_camera.size=3000.0
	assert_int(renderer._secondary_settlement_label_limit()).is_equal(3)


func test_world_scale_keeps_bounded_major_place_symbols_after_borders_cull()->void:
	var test_camera:Camera3D=auto_free(Camera3D.new())
	test_camera.size=12000.0
	renderer.camera=test_camera
	renderer.camera_target=Vector3.ZERO
	assert_bool(renderer._settlement_boundary_in_current_view({"position":Vector2(1000.0,0.0),"claim_radius_km":40.0})).is_false()
	assert_bool(renderer._settlement_marker_in_current_view({"position":Vector2(1000.0,0.0)})).is_true()
	var marker_root:Node3D=auto_free(Node3D.new())
	renderer.settlement_network_marker_root=marker_root
	var settlements:Array[Dictionary]=[]
	for index in 100:
		settlements.append({"name":"Place %d" % index,"classification":"city" if index<8 else "town","population":100000-index*300,"position":Vector2(float(index)*2.0,0.0)})
	renderer._create_secondary_settlement_markers(settlements)
	var blips:=marker_root.get_child(0) as MultiMeshInstance3D
	assert_int(blips.multimesh.instance_count).is_equal(64)
	assert_int(marker_root.get_child_count()).is_equal(4)


func test_intermediate_zoom_caps_expensive_plot_detail_without_dropping_ground_state()->void:
	var test_camera:Camera3D=auto_free(Camera3D.new())
	test_camera.size=10.0
	renderer.camera=test_camera
	var detailed:=0
	for index in 2048:
		if renderer._settlement_plot_has_detail({"id":index+1},index,2048,1): detailed+=1
	assert_int(detailed).is_greater(250)
	assert_int(detailed).is_less_equal(320)
	assert_int(renderer._settlement_detail_plot_budget(0)).is_equal(2048)
	assert_int(renderer._settlement_detail_plot_budget(2)).is_equal(0)


func test_close_metropolis_uses_one_strictly_bounded_district_clipmap()->void:
	renderer._configure_seamless_world()
	renderer._configure_shape()
	renderer._configure_noise()
	renderer._prepare_river_course()
	var center:Vector3=renderer._find_camp_position()
	var test_camera:Camera3D=auto_free(Camera3D.new())
	test_camera.size=1.5
	renderer.camera=test_camera
	renderer.camera_target=center
	var architecture:=VALUES.architecture_snapshot(VALUES.initial_state("industry",GameState.world_seed,"player"))
	var profile:Dictionary=renderer._settlement_expansion_visual_profile({"classification":"metropolis","population":5000000,"stage_progress":0.0})
	var no_plots:Array[Dictionary]=[]
	var layout:Dictionary=renderer._settlement_stage_visual_layout(profile,5000000,no_plots)
	var candidates:Array[Dictionary]=renderer._settlement_district_clipmap_candidates(center,layout,5,architecture)
	assert_int(candidates.size()).is_greater(0)
	assert_int(candidates.size()).is_less_equal(renderer.SETTLEMENT_DISTRICT_CLIPMAP_BUDGET)
	var uses:Dictionary={}
	var shapes:Dictionary={}
	for candidate in candidates: uses[int(candidate.get("land_use",0))]=true
	for candidate in candidates:
		if int(candidate.get("land_use",0))==0: shapes[int(candidate.get("shape_variant",0))]=true
	assert_int(uses.size()).is_greater_equal(1)
	assert_int(shapes.size()).is_greater_equal(6)


func test_town_and_city_absorb_one_stable_historical_core_without_extra_batches()->void:
	renderer._configure_seamless_world()
	renderer._configure_shape()
	renderer._configure_noise()
	renderer._prepare_river_course()
	var center:Vector3=renderer._find_camp_position()
	var test_camera:Camera3D=auto_free(Camera3D.new())
	test_camera.size=1.2
	renderer.camera=test_camera
	renderer.camera_target=center
	var architecture:=VALUES.architecture_snapshot(VALUES.initial_state("inquiry",GameState.world_seed,"player"))
	var inherited_tile:=-1
	var no_plots:Array[Dictionary]=[]
	for stage_record in [{"name":"town","population":5000,"stage":3},{"name":"city","population":500000,"stage":4}]:
		var profile:Dictionary=renderer._settlement_expansion_visual_profile({"classification":stage_record.name,"population":stage_record.population,"stage_progress":0.0})
		var layout:Dictionary=renderer._settlement_stage_visual_layout(profile,stage_record.population,no_plots)
		var candidates:Array[Dictionary]=renderer._settlement_district_clipmap_candidates(center,layout,stage_record.stage,architecture)
		var historical:Array[Dictionary]=[]
		for candidate in candidates:
			if bool(candidate.get("historic_core",false)): historical.append(candidate)
		assert_int(historical.size()).is_equal(1)
		assert_vector(Vector2(historical[0].point)).is_equal(Vector2(center.x,center.z))
		assert_int(int(historical[0].historic_tile)).is_between(48,63)
		assert_int(candidates.size()).is_less_equal(renderer.SETTLEMENT_DISTRICT_CLIPMAP_BUDGET)
		if inherited_tile>=0: assert_int(int(historical[0].historic_tile)).is_equal(inherited_tile)
		inherited_tile=int(historical[0].historic_tile)


func test_aggregate_neighborhood_condition_has_eight_ordered_states()->void:
	assert_int(renderer.SETTLEMENT_DISTRICT_CONDITIONS.size()).is_equal(8)
	assert_array(renderer.SETTLEMENT_DISTRICT_CONDITIONS).contains_exactly(["great","okay","fine","normal","bad","poor","damaged","destroyed"])
	var candidate:Dictionary={"seed":4128,"cell":Vector2i(3,5)}
	var strong:Dictionary={"health":1.0,"food":1.0,"cohesion":1.0,"material_capacity":1.0,"legitimacy":1.0}
	var collapsed:Dictionary={"health":0.0,"food":0.0,"cohesion":0.0,"material_capacity":0.0,"legitimacy":0.0}
	assert_int(renderer._settlement_district_condition(candidate,0.0,strong)).is_equal(0)
	assert_int(renderer._settlement_district_condition(candidate,0.0,collapsed)).is_equal(5)
	assert_int(renderer._settlement_district_condition(candidate,1.0,strong)).is_equal(7)


func test_poor_condition_stays_inhabited_while_damage_removes_structure()->void:
	var close_shader:String=renderer._settlement_district_atlas_material(null,4,false).shader.code
	assert_str(close_shader).contains("inherited_early_atlas_texture")
	assert_str(close_shader).contains("district_data.r*63.0")
	assert_str(close_shader).not_contains("condition==5.0 && sector_breakup")
	assert_str(close_shader).contains("condition==6.0 && sector_breakup")
	var terrain_source:String=FileAccess.get_file_as_string("res://scripts/local_terrain.gd")
	assert_str(terrain_source).contains("var condition_scale:=1.0")
	assert_str(terrain_source).not_contains("[1.02,1.01,1.0,0.99,0.97,0.94,0.90,0.88]")
	var strategic_shader:String=renderer._settlement_fabric_material(5,0.12).shader.code
	assert_str(strategic_shader).contains("if(condition<6.0) return 1.0;")
	assert_str(strategic_shader).contains("if(condition<7.0) return step(0.45,breakup);")
	assert_str(strategic_shader).not_contains("if(condition<6.0) return step")
	assert_str(strategic_shader).contains("final_damage_scar*district_visibility*0.22")
	assert_str(strategic_shader).contains("float condition_upkeep=1.12;")
	assert_str(strategic_shader).contains("if(district_condition>4.5) condition_upkeep=0.82;")


func test_neighborhood_atlas_family_follows_era_land_use_and_civic_practice()->void:
	var formal:Dictionary={"axiality":0.82,"civic_space":0.38,"defensive_depth":0.42}
	var civic:Dictionary={"axiality":0.44,"civic_space":0.82,"defensive_depth":0.36}
	assert_array(renderer._settlement_district_tile_options(true,4,2,formal)).contains_exactly([4,5])
	assert_array(renderer._settlement_district_tile_options(false,4,2,formal)).contains_exactly([4,9,10,14])
	assert_array(renderer._settlement_district_tile_options(true,4,0,formal)).is_not_equal(renderer._settlement_district_tile_options(true,4,0,civic))
	# Seed 641 falls outside the bounded cultural-signature quota and therefore checks
	# the ordinary era/material fallback independently of the new cultural routing.
	assert_int(renderer._settlement_district_tile_index(false,3,0,{},641,false,{"organic_share":0.7,"earth_share":0.2,"stone_share":0.1})).is_between(32,47)
	assert_int(renderer._settlement_district_tile_index(true,4,0,{},641,false,{})).is_between(16,31)
	assert_int(renderer._settlement_district_tile_index(false,0,0,{},41,false,{})).is_equal(0)
	assert_array(renderer._settlement_district_tile_options(false,1,0,{})).contains_exactly([0,2,8,9,11])
	assert_array(renderer._settlement_district_tile_options(false,2,0,{})).contains_exactly([2,8,9,11])
	assert_bool(renderer._settlement_district_tile_index(false,2,0,{},41,false,{}) in [1,6,7,14]).is_false()
	assert_bool(renderer._settlement_district_tile_index(false,2,0,{"permeability":0.20},41,false,{"earth_share":0.8,"organic_share":0.1,"stone_share":0.1}) in [5,8,11]).is_true()
	for false_fortification in [3,4,12]:
		assert_bool(false_fortification in renderer._settlement_district_tile_options(false,2,0,{})).is_false()
	assert_bool(renderer._settlement_district_tile_index(false,2,0,{},41,true,{}) in [1,7]).is_true()


func test_early_cultures_choose_distinct_dry_unfortified_settlement_plans()->void:
	var signatures:Dictionary={}
	var expected:Dictionary={"provision":[13],"generations":[11],"inquiry":[8],"industry":[2],"defense":[9],"exchange":[10]}
	for focus in ["provision","generations","inquiry","industry","defense","exchange"]:
		var architecture:=VALUES.architecture_snapshot(VALUES.initial_state(focus,741991,"shared_culture_seed"))
		var options:Array=renderer._settlement_district_tile_options(false,2,0,architecture)
		assert_array(options).contains_exactly(expected[focus])
		for tile in options:
			assert_bool(int(tile) in [1,3,4,6,7,12,14,15]).is_false()
		signatures[str(options)]=true
	assert_int(signatures.size()).is_equal(6)


func test_open_water_vernacular_plates_are_reserved_for_verified_waterfronts()->void:
	var open_water_tiles:Array[int]=[3,10,11]
	var inland_families:Array[Array]=[
		renderer._settlement_district_vernacular_tile_options(1,{},{}),
		renderer._settlement_district_vernacular_tile_options(2,{},{}),
		renderer._settlement_district_vernacular_tile_options(0,{"defensive_depth":0.8},{}),
		renderer._settlement_district_vernacular_tile_options(0,{"terrain_conformity":0.8},{}),
		renderer._settlement_district_vernacular_tile_options(0,{"axiality":0.8},{}),
		renderer._settlement_district_vernacular_tile_options(0,{"permeability":0.8},{}),
		renderer._settlement_district_vernacular_tile_options(0,{},
			{"organic_share":0.1,"earth_share":0.8,"stone_share":0.1}),
		renderer._settlement_district_vernacular_tile_options(0,{},
			{"organic_share":0.8,"earth_share":0.1,"stone_share":0.1}),
		renderer._settlement_district_vernacular_tile_options(0,{},
			{"organic_share":0.1,"earth_share":0.1,"stone_share":0.8})
	]
	for family in inland_families:
		for tile in open_water_tiles:
			assert_bool(tile in family).is_false()
	for seed in range(3):
		assert_int(renderer._settlement_district_tile_index(false,4,0,{},seed,true,{})).is_equal(32+open_water_tiles[seed])
	for seed in range(30):
		assert_bool(renderer._settlement_district_tile_index(false,4,0,{},seed,false,
			{"organic_share":0.8,"earth_share":0.1,"stone_share":0.1}) in [35,42,43]).is_false()


func test_every_inland_primary_pool_excludes_authored_water_scenes()->void:
	var practices:Array[Dictionary]=[
		{}, {"axiality":0.82}, {"civic_space":0.82}, {"defensive_depth":0.82}
	]
	for practice in practices:
		for land_use in [0,1,2]:
			var mature_pool:Array[int]=renderer._settlement_district_tile_options(false,4,land_use,practice)
			assert_bool(5 in mature_pool).is_false()
			assert_bool(13 in mature_pool).is_false()
			var modern_pool:Array[int]=renderer._settlement_district_tile_options(true,4,land_use,practice)
			assert_bool(14 in modern_pool).is_false()
	var shader_code:String=renderer._settlement_fabric_material(5,0.12).shader.code
	assert_str(shader_code).contains("return 16.0+floor(variant_roll*16.0);")
	assert_str(shader_code).contains("return 32.0+tile;")


func test_waterfront_district_requires_real_shore_and_maritime_capability()->void:
	renderer._configure_seamless_world()
	renderer._configure_shape()
	renderer._configure_noise()
	renderer._prepare_river_course()
	var candidate:Dictionary={
		"point":Vector2(0.80,0.0),"seed":19,"land_use":0,"condition":3,
		"cell_size":0.40,"angle":0.0,"radial_t":0.8
	}
	var coast:Dictionary={
		"maritime_visual_ready":true,"coast_direction":Vector2.RIGHT,
		"nearest_open_water_km":0.75
	}
	var candidates:Array[Dictionary]=[candidate]
	assert_int(renderer._settlement_waterfront_candidate_index(candidates,Vector3.ZERO,1.0,coast)).is_equal(0)
	var incapable:=coast.duplicate(true)
	incapable.maritime_visual_ready=false
	assert_int(renderer._settlement_waterfront_candidate_index(candidates,Vector3.ZERO,1.0,incapable)).is_equal(-1)
	incapable.shore_visual_ready=true
	# Early atlas plates stay dry because their baked water cannot follow the actual
	# generated shoreline. Coastal bonuses and shoreline accents are handled separately.
	assert_int(renderer._settlement_waterfront_candidate_index(candidates,Vector3.ZERO,1.0,incapable,true)).is_equal(-1)
	var inland:=coast.duplicate(true)
	inland.nearest_open_water_km=4.0
	assert_int(renderer._settlement_waterfront_candidate_index(candidates,Vector3.ZERO,1.0,inland)).is_equal(-1)


func test_capable_coastal_city_uses_one_deliberate_historical_waterfront_plate()->void:
	assert_int(renderer._settlement_district_tile_index(false,4,0,{},19,true)).is_equal(42)
	assert_int(renderer._settlement_district_tile_index(true,4,0,{},19,true)).is_equal(14)
	assert_bool(renderer._settlement_district_tile_index(false,4,0,{},19,false) in [35,42,43]).is_false()


func test_early_settlements_use_one_growing_aggregate_footprint()->void:
	renderer._configure_seamless_world()
	renderer._configure_shape()
	renderer._configure_noise()
	renderer._prepare_river_course()
	var center:Vector3=renderer._find_camp_position()
	var test_camera:Camera3D=auto_free(Camera3D.new())
	renderer.camera=test_camera
	renderer.camera_target=center
	var architecture:=VALUES.architecture_snapshot(VALUES.initial_state("industry",GameState.world_seed,"player"))
	for record in [
		{"classification":"founding camp","population":120,"stage":0,"zoom":0.12},
		{"classification":"hamlet","population":800,"stage":1,"zoom":0.20},
		{"classification":"village","population":5000,"stage":2,"zoom":0.36}
	]:
		test_camera.size=float(record.zoom)
		var profile:Dictionary=renderer._settlement_expansion_visual_profile(record)
		var no_plots:Array[Dictionary]=[]
		var layout:Dictionary=renderer._settlement_stage_visual_layout(profile,int(record.population),no_plots)
		var candidates:Array[Dictionary]=renderer._settlement_district_clipmap_candidates(center,layout,int(record.stage),architecture)
		assert_int(candidates.size()).is_equal(1)
		assert_float(Vector2(candidates[0].point).distance_to(Vector2(center.x,center.z))).is_less(0.00001)
		var candidate:Dictionary=candidates[0]
		var footprint_size:=maxf(float(candidate.cell_size)*0.90,float(layout.get("radius",0.0))*0.48)
		footprint_size=minf(footprint_size,float(candidate.cell_size)*2.0)
		var draped_mesh:ArrayMesh=renderer._settlement_district_draped_atlas_mesh(Vector2(candidate.point),float(candidate.angle),footprint_size)
		var arrays:Array=draped_mesh.surface_get_arrays(0)
		var vertices:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
		var indices:PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
		assert_int(vertices.size()).is_equal(289)
		assert_int(indices.size()).is_equal(1536)
		var minimum_height:=INF
		var maximum_height:=-INF
		for vertex in vertices:
			minimum_height=minf(minimum_height,vertex.y)
			maximum_height=maxf(maximum_height,vertex.y)
		assert_float(maximum_height-minimum_height).is_greater(0.0001)
	# Town-and-later grids retain the six-index shared neighborhood quad. Only the one
	# kilometre-scale early plan needs its own fixed terrain-following patch.
	var mature_mesh:ArrayMesh=renderer._settlement_district_atlas_mesh()
	assert_int(mature_mesh.surface_get_array_len(0)).is_equal(6)


func test_real_early_defense_survives_close_zoom_without_baked_atlas_walls()->void:
	GameState.societal_values=VALUES.initial_state("defense",741991,"player")
	renderer.footprint_population=1200
	var profile:Dictionary=renderer._settlement_expansion_visual_profile({"classification":"village","population":1200})
	var parent:Node3D=auto_free(Node3D.new())
	var no_plots:Array[Dictionary]=[]
	renderer._create_settlement_stage_landscape(Vector3.ZERO,profile,no_plots,0,parent,{"stage":2,"integrity":1.0,"construction":{}})
	assert_bool(parent.has_node("PersistentSettlementDefenseGround") or parent.has_node("PersistentSettlementDefenseMassing")).is_true()


func test_poor_upkeep_is_not_misreported_as_physical_destruction()->void:
	var candidate:Dictionary={"point":Vector2.ZERO,"cell_size":0.20}
	var poor_but_inhabited:Array[Dictionary]=[{
		"centroid":Vector2.ZERO,"status":"active","condition":0.12,
		"prosperity":0.08,"service_access":0.10,"maintenance_debt":0.90,
		"damage":{"neglect":0.95}
	}]
	var context:Dictionary=renderer._settlement_district_plot_context(candidate,Vector3.ZERO,poor_but_inhabited)
	assert_int(int(context.get("recorded_damage_state",-1))).is_equal(0)
	assert_float(float(context.get("physical_quality",1.0))).is_less(0.25)
	poor_but_inhabited[0].damage={"structural":0.42}
	context=renderer._settlement_district_plot_context(candidate,Vector3.ZERO,poor_but_inhabited)
	assert_int(int(context.get("recorded_damage_state",0))).is_equal(6)


func test_neighborhood_cells_remain_world_stable_while_zooming()->void:
	renderer._configure_seamless_world()
	renderer._configure_shape()
	renderer._configure_noise()
	renderer._prepare_river_course()
	var center:Vector3=renderer._find_camp_position()
	var test_camera:Camera3D=auto_free(Camera3D.new())
	renderer.camera=test_camera
	renderer.camera_target=center
	var architecture:=VALUES.architecture_snapshot(VALUES.initial_state("industry",GameState.world_seed,"player"))
	var profile:Dictionary=renderer._settlement_expansion_visual_profile({"classification":"city","population":500000,"stage_progress":0.0})
	var no_plots:Array[Dictionary]=[]
	var layout:Dictionary=renderer._settlement_stage_visual_layout(profile,500000,no_plots)
	test_camera.size=0.40
	var close_cells:Array[Dictionary]=renderer._settlement_district_clipmap_candidates(center,layout,4,architecture)
	test_camera.size=1.20
	var aerial_cells:Array[Dictionary]=renderer._settlement_district_clipmap_candidates(center,layout,4,architecture)
	assert_int(close_cells.size()).is_equal(aerial_cells.size())
	for index in close_cells.size():
		assert_str(str(close_cells[index].cell)).is_equal(str(aerial_cells[index].cell))


func test_neighborhood_condition_uses_bounded_physical_plot_evidence()->void:
	var candidate:Dictionary={"seed":4128,"cell":Vector2i(3,5),"point":Vector2(0.02,0.01),"cell_size":0.05}
	var healthy_plot:Array[Dictionary]=[{
		"id":1,"centroid":Vector2.ZERO,"condition":0.96,"prosperity":0.92,
		"service_access":0.90,"maintenance_debt":0.02,"status":"active"
	}]
	var ruined_plot:Array[Dictionary]=[{
		"id":2,"centroid":Vector2.ZERO,"condition":0.08,"prosperity":0.04,
		"service_access":0.06,"maintenance_debt":0.94,"status":"ruin"
	}]
	var healthy_context:Dictionary=renderer._settlement_district_plot_context(candidate,Vector3.ZERO,healthy_plot)
	var ruined_context:Dictionary=renderer._settlement_district_plot_context(candidate,Vector3.ZERO,ruined_plot)
	assert_float(float(healthy_context.physical_quality)).is_greater(float(ruined_context.physical_quality))
	assert_int(int(ruined_context.recorded_damage_state)).is_equal(7)
	assert_int(renderer._settlement_district_condition(candidate,0.0,ruined_context)).is_equal(7)


func test_grid_damage_stays_at_its_recorded_location_across_zoom_levels()->void:
	var plots:Array[Dictionary]=[
		{"id":1,"centroid":Vector2(-0.30,0.0),"condition":0.94,"prosperity":0.88,"service_access":0.86,"maintenance_debt":0.03,"status":"active"},
		{"id":2,"centroid":Vector2(0.30,0.0),"condition":0.06,"prosperity":0.04,"service_access":0.05,"maintenance_debt":0.95,"status":"ruin"}
	]
	var intact_grid:Dictionary={"seed":112,"cell":Vector2i(-3,0),"point":Vector2(-0.30,0.0),"cell_size":0.08}
	var destroyed_grid:Dictionary={"seed":113,"cell":Vector2i(3,0),"point":Vector2(0.30,0.0),"cell_size":0.08}
	var distant_grid:Dictionary={"seed":114,"cell":Vector2i(12,12),"point":Vector2(1.20,1.20),"cell_size":0.08}
	assert_int(renderer._settlement_district_spatial_condition(intact_grid,0.95,Vector3.ZERO,plots)).is_less(6)
	assert_int(renderer._settlement_district_spatial_condition(destroyed_grid,0.95,Vector3.ZERO,plots)).is_equal(7)
	# Even a high city-wide damage ratio cannot paint an unrelated distant cell as a
	# ruin when the aggregate plot ledger says the recorded destruction is elsewhere.
	assert_int(renderer._settlement_district_spatial_condition(distant_grid,0.95,Vector3.ZERO,plots)).is_less(6)
	# Real close and regional LODs use different cell IDs and cell sizes. Identical
	# geography must nevertheless resolve to the identical eight-state condition.
	var destroyed_close:=destroyed_grid.duplicate(true)
	destroyed_close.cell=Vector2i(1,0)
	destroyed_close.cell_size=0.20
	var destroyed_regional:=destroyed_grid.duplicate(true)
	destroyed_regional.cell=Vector2i(17,14)
	destroyed_regional.cell_size=0.544
	assert_int(renderer._settlement_district_spatial_condition(destroyed_close,0.95,Vector3.ZERO,plots)).is_equal(
		renderer._settlement_district_spatial_condition(destroyed_regional,0.95,Vector3.ZERO,plots)
	)
	var distant_close:=distant_grid.duplicate(true)
	distant_close.cell=Vector2i(6,6)
	distant_close.cell_size=0.20
	var distant_regional:=distant_grid.duplicate(true)
	distant_regional.cell=Vector2i(19,17)
	distant_regional.cell_size=0.544
	assert_int(renderer._settlement_district_spatial_condition(distant_close,0.95,Vector3.ZERO,plots)).is_equal(
		renderer._settlement_district_spatial_condition(distant_regional,0.95,Vector3.ZERO,plots)
	)


func test_google_earth_detail_lod_uses_one_crossover_without_a_blank_band()->void:
	var test_camera:Camera3D=auto_free(Camera3D.new())
	renderer.camera=test_camera
	for detail_size in [0.24,0.30,0.42,1.50,2.40,2.4005]:
		test_camera.size=detail_size
		assert_int(renderer._settlement_morphology_lod()).is_equal(0)
	test_camera.size=2.41
	assert_int(renderer._settlement_morphology_lod()).is_equal(1)


func test_float_tolerant_close_lod_keeps_its_aggregate_neighborhoods()->void:
	renderer._configure_seamless_world()
	renderer._configure_shape()
	renderer._configure_noise()
	renderer._prepare_river_course()
	var center:Vector3=renderer._find_camp_position()
	var test_camera:Camera3D=auto_free(Camera3D.new())
	test_camera.size=2.4005
	renderer.camera=test_camera
	renderer.camera_target=center
	var architecture:=VALUES.architecture_snapshot(VALUES.initial_state("industry",GameState.world_seed,"player"))
	var profile:Dictionary=renderer._settlement_expansion_visual_profile({"classification":"metropolis","population":5000000,"stage_progress":0.0})
	var no_plots:Array[Dictionary]=[]
	var layout:Dictionary=renderer._settlement_stage_visual_layout(profile,5000000,no_plots)
	assert_int(renderer._settlement_morphology_lod()).is_equal(0)
	assert_int(renderer._settlement_district_clipmap_candidates(center,layout,5,architecture).size()).is_greater(0)


func test_strategic_city_field_feathers_real_river_edges_without_coarse_triangle_holes()->void:
	renderer._configure_seamless_world()
	renderer._configure_shape()
	renderer._configure_noise()
	renderer._prepare_river_course()
	var camp:Vector3=renderer._find_camp_position()
	var river_z:=camp.z
	var river_center:=Vector3(renderer._world_river_x(river_z),0.0,river_z)
	var architecture:=VALUES.architecture_snapshot(VALUES.initial_state("industry",GameState.world_seed,"player"))
	var no_plots:Array[Dictionary]=[]
	var palette:Dictionary=renderer._settlement_stage_material_palette(no_plots,4,architecture)
	var cores:Array[Vector2]=[Vector2.ZERO]
	var satellites:Array[Vector2]=[]
	var surface:=SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var triangle_count:int=renderer._append_settlement_strategic_density_field(
		surface,river_center,1.2,cores,satellites,741991,palette,0.0,4,architecture,no_plots
	)
	var mesh:Mesh=surface.commit()
	assert_int(triangle_count).is_greater(0)
	assert_int(mesh.surface_get_array_len(0)).is_less_equal(30*30*6)
	var arrays:Array=mesh.surface_get_arrays(0)
	var vertices:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
	var colors:PackedColorArray=arrays[Mesh.ARRAY_COLOR]
	var mixed_shore_triangle:=false
	for index in range(0,colors.size(),3):
		var invalid_surface:=0
		var valid_surface:=0
		var invalid_surface_transparent:=0
		var valid_surface_visible:=0
		for corner in 3:
			var point:=Vector2(vertices[index+corner].x,vertices[index+corner].z)
			if renderer._settlement_stage_strategic_surface_at(point):
				valid_surface+=1
				if colors[index+corner].a>0.01: valid_surface_visible+=1
			else:
				invalid_surface+=1
				if colors[index+corner].a<=0.0001: invalid_surface_transparent+=1
		if invalid_surface>0 and valid_surface>0 and invalid_surface_transparent==invalid_surface and valid_surface_visible>0:
			mixed_shore_triangle=true
			break
	assert_bool(mixed_shore_triangle).is_true()


func test_territory_geography_sampling_invalidates_on_position_not_population_ticks()->void:
	GameState.player_settlements=[{"id":"home","position":Vector2(4.0,8.0),"population":120}]
	var initial:String=renderer._settlement_territory_sample_signature()
	GameState.player_settlements[0]["population"]=1_000_000_000
	assert_str(renderer._settlement_territory_sample_signature()).is_equal(initial)
	GameState.player_settlements[0]["position"]=Vector2(4.25,8.0)
	assert_str(renderer._settlement_territory_sample_signature()).is_not_equal(initial)


func test_billion_person_close_city_does_not_add_district_instances()->void:
	renderer._configure_seamless_world()
	renderer._configure_shape()
	renderer._configure_noise()
	renderer._prepare_river_course()
	var center:Vector3=renderer._find_camp_position()
	var test_camera:Camera3D=auto_free(Camera3D.new())
	test_camera.size=1.5
	renderer.camera=test_camera
	renderer.camera_target=center
	var architecture:=VALUES.architecture_snapshot(VALUES.initial_state("industry",GameState.world_seed,"player"))
	var modest_profile:Dictionary=renderer._settlement_expansion_visual_profile({"classification":"metropolis","population":5000000,"stage_progress":0.0})
	var immense_profile:Dictionary=renderer._settlement_expansion_visual_profile({"classification":"megalopolis","population":1000000000,"stage_progress":0.0})
	var no_plots:Array[Dictionary]=[]
	var modest_layout:Dictionary=renderer._settlement_stage_visual_layout(modest_profile,5000000,no_plots)
	var immense_layout:Dictionary=renderer._settlement_stage_visual_layout(immense_profile,1000000000,no_plots)
	var modest:Array[Dictionary]=renderer._settlement_district_clipmap_candidates(center,modest_layout,5,architecture)
	var immense:Array[Dictionary]=renderer._settlement_district_clipmap_candidates(center,immense_layout,6,architecture)
	assert_int(modest.size()).is_greater(0)
	assert_int(modest.size()).is_less_equal(renderer.SETTLEMENT_DISTRICT_CLIPMAP_BUDGET)
	assert_int(immense.size()).is_less_equal(modest.size())


func test_district_clipmap_retires_before_regional_zoom()->void:
	var test_camera:Camera3D=auto_free(Camera3D.new())
	test_camera.size=3.0
	renderer.camera=test_camera
	renderer.camera_target=Vector3.ZERO
	var layout:Dictionary={"radius":24.0,"axis":0.0,"cores":[Vector2.ZERO],"satellites":[],"corridor_angles":[]}
	var architecture:Dictionary={"axiality":0.5,"permeability":0.5,"civic_space":0.5,"terrain_conformity":0.5}
	assert_array(renderer._settlement_district_clipmap_candidates(Vector3.ZERO,layout,6,architecture)).is_empty()


func test_close_zoom_never_replaces_continuous_city_with_photo_tile_clipmap()->void:
	var terrain_source:=FileAccess.get_file_as_string("res://scripts/local_terrain.gd")
	assert_bool(terrain_source.contains("if lod==0: _create_settlement_district_clipmap")).is_false()
	assert_bool(terrain_source.contains("float aggregate_floor=fabric_kind==5 ? 0.78 : 0.16;")).is_true()


func test_roof_opacity_is_not_baked_at_the_old_camera_threshold()->void:
	var test_camera:Camera3D=auto_free(Camera3D.new())
	renderer.camera=test_camera
	var plots:Array[Dictionary]=[{
		"id":1,"seed":741991,"centroid":Vector2.ZERO,"area_ha":0.08,
		"polygon":PackedVector2Array([Vector2(-0.01,-0.01),Vector2(0.01,-0.01),Vector2(0.01,0.01),Vector2(-0.01,0.01)]),
		"land_use":"residential_compound","form":"courtyard_compound","material_family":"earth",
		"roof_plan":"courtyard_flat","roof_coverage":0.42,"resident_count":26,"storeys":2,
		"condition":0.78,"prosperity":0.48,"status":"active","fabric_generation":7,"created_day":0
	}]
	var original_colors:=PackedColorArray()
	for zoom in [0.41,0.43]:
		test_camera.size=zoom
		var parent:Node3D=auto_free(Node3D.new())
		renderer._create_plot_fabric(Vector3.ZERO,plots,0,parent)
		var roofs:=parent.get_node_or_null("PersistentRoofFabric") as MeshInstance3D
		assert_object(roofs).is_not_null()
		if roofs==null: return
		var colors:PackedColorArray=roofs.mesh.surface_get_arrays(0)[Mesh.ARRAY_COLOR]
		assert_int(colors.size()).is_greater(0)
		if original_colors.is_empty(): original_colors=colors
		else: assert_bool(original_colors==colors).is_true()
