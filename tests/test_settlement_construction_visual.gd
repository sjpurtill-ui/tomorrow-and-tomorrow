extends GdUnitTestSuite
const State:=preload("res://scripts/settlement_construction_state.gd")
const Meshes:=preload("res://scripts/settlement_construction_mesh.gd")
const Early:=preload("res://scripts/early_settlement_visual.gd")
const Keys:=preload("res://scripts/settlement_visual_keys.gd")
const Patches:=preload("res://scripts/settlement_patch_renderer.gd")
const Country:=preload("res://scripts/settlement_country_visual.gd")
const Fabric:=preload("res://scripts/settlement_fabric_operations.gd")
class Terrain extends "res://scripts/local_terrain.gd":
	var vegetation_builds:=0
	var requests:=0
	func _ready()->void:pass
	func _process(_delta:float)->void:pass
	func _settlement_model()->Node:return SettlementModel
	func _height_at(_x:float,_z:float)->float:return .05
	func _close_surface_height_at(_x:float,_z:float)->float:return .05
	func _settlement_stage_land_at(_point:Vector2)->bool:return true
	func _prime_organic_town_plan(_center:Vector3)->bool:return false
	func _paint_settlement_grounds(_center:Vector3)->void:pass
	func _rebuild_close_vegetation(_center:Vector3)->void:vegetation_builds+=1
	func _request_settlement_visual_patches(_center:Vector3,_plots:Array[Dictionary],_routes:Array[Dictionary],_lod:int,_profile:Dictionary,_defense:Dictionary)->void:requests+=1

func before_test()->void:GameState.reset_for_new_world(910148)

func _plot(form:="timber_household",family:="organic",roof:="timber_ridge")->Dictionary:
	return {"id":1,"seed":91,"centroid":Vector2.ZERO,"polygon":PackedVector2Array([Vector2(-.02,-.02),Vector2(.02,-.02),Vector2(.02,.02),Vector2(-.02,.02)]),"frontage_route_id":1,"area_ha":.16,"roof_coverage":.3,"resident_count":12,"material_family":family,"land_use":"residential_compound","form":form,"roof_plan":roof,"status":"active","condition":.9,"storeys":1}

func _plots(plot:Dictionary)->Array[Dictionary]:return [plot]
func _routes()->Array[Dictionary]:return [{"id":1,"kind":"camp_path","width_m":.6,"points":PackedVector2Array([Vector2(-.025,0),Vector2(.025,0)])}]
func _dry(_point:Vector2)->bool:return true
func _height(_x:float,_z:float)->float:return .05
func _plan(plot:Dictionary)->Dictionary:return Early.layout(_plots(plot),_routes(),_dry)
func _draw(plan:Dictionary)->Node3D:
	var root:Node3D=auto_free(Node3D.new());Early.render(plan,Vector3.ZERO,_height,root);return root
func _transforms(root:Node)->Array:
	var values:Array=[]
	for child in root.get_children():
		if child.has_meta("source_transforms"):values.append_array(child.get_meta("source_transforms"))
		elif child is MultiMeshInstance3D and String(child.name).begins_with("SettlementArchitecture_"):
			for index in child.multimesh.instance_count:values.append(child.multimesh.get_instance_transform(index))
	# Completed kits group by variant; construction groups by source+milestone.
	# Compare physical identity independently of those harmless draw-batch orders.
	values.sort_custom(func(a:Transform3D,b:Transform3D)->bool:return a.origin.z<b.origin.z if a.origin.x==b.origin.x else a.origin.x<b.origin.x)
	return values
func _render_patch(parent:Node3D,plan:Dictionary)->void:Early.render(plan,Vector3.ZERO,_height,parent)

func _begin_retrofit(plot:Dictionary)->void:
	var known:Array=["timber_lateral_bracing"]
	for entry:Dictionary in preload("res://scripts/settlement_fabric_knowledge.gd").entries():
		if String(entry.id)!="timber_lateral_bracing":continue
		known.append_array(entry.requires_all)
		for group:Array in entry.requires_any:known.append(group[0])
	var result:=Fabric.start(plot,"timber_lateral_bracing",{"Timber Brace Sets":1.0},known,{"timber_lateral_bracing":1.0},100)
	assert_bool(bool(result.get("ok",false))).is_true()

func test_only_recorded_new_build_progress_selects_milestones_without_mutating_plot()->void:
	var plot:=_plot();plot.status="under_construction"
	for row:Array in [[0.0,0],[.249,0],[.25,1],[.499,1],[.5,2],[.749,2],[.75,3],[1.0,3]]:
		plot.construction_progress=row[0];var before:=var_to_bytes(plot)
		assert_int(int(State.state(plot).stage)).is_equal(int(row[1]))
		assert_str(String(State.state(plot).mode)).is_equal("new")
		assert_array(var_to_bytes(plot)).is_equal(before)
	plot.status="active";plot.construction_progress=.1
	assert_str(String(State.state(plot).mode)).is_empty()
	assert_int(int(State.state(plot).stage)).is_equal(4)

func test_real_paid_retrofit_work_is_read_only_and_inspection_does_not_grant_completion()->void:
	var plot:=_plot();_begin_retrofit(plot)
	if not plot.has("fabric_job"):return
	assert_str(String(State.state(plot).mode)).is_equal("retrofit")
	assert_int(int(State.state(plot).stage)).is_equal(0)
	Fabric.advance(plot,1.0,101)
	var before:=var_to_bytes(plot)
	assert_int(int(State.state(plot).stage)).is_equal(0)
	assert_array(var_to_bytes(plot)).is_equal(before)
	Fabric.advance(plot,100.0,102)
	assert_str(String(plot.fabric_job.state)).is_equal("awaiting_inspection")
	assert_str(String(State.state(plot).mode)).is_equal("retrofit")
	assert_int(int(State.state(plot).stage)).is_equal(0)
	assert_dict(plot.get("fabric_components",{})).is_empty()
	plot.erase("fabric_job")
	assert_str(String(State.state(plot).mode)).is_empty()

func test_fractional_work_keeps_patch_node_and_mesh_until_a_stage_boundary()->void:
	var plot:=_plot("portable_shelter_cluster","organic","ridge_light_shelter")
	plot.status="under_construction";plot.construction_progress=.27
	var plan:=_plan(plot);assert_int(plan.buildings.size()).is_greater(0)
	var parent:Node3D=auto_free(Node3D.new());var patches:=Patches.new(parent)
	var entries:Array[Dictionary]=[{"key":"home","signature":Keys.appearance(plot),"build":_render_patch.bind(plan)}]
	patches.request(entries);patches.process(100000,8)
	var original:Node3D=patches.installed.home.node
	var batch:MultiMeshInstance3D=original.find_children("Construction_*","MultiMeshInstance3D",true,false)[0]
	var mesh:Mesh=batch.multimesh.mesh
	var placement:=Keys.placement(_plots(plot),_routes())
	for progress:float in [.28,.32,.38,.44,.49]:
		plot.construction_progress=progress;entries[0].signature=Keys.appearance(plot)
		patches.request(entries);patches.process(100000,8)
		assert_int(patches.builds).is_equal(1)
		assert_int(patches.installed.home.node.get_instance_id()).is_equal(original.get_instance_id())
		assert_int(batch.multimesh.mesh.get_instance_id()).is_equal(mesh.get_instance_id())
		assert_int(Keys.placement(_plots(plot),_routes())).is_equal(placement)
	plot.construction_progress=.5;entries[0].signature=Keys.appearance(plot)
	entries[0].build=_render_patch.bind(Keys.refresh_plan(plan,_plots(plot)))
	patches.request(entries)
	assert_int(patches.installed.home.node.get_instance_id()).is_equal(original.get_instance_id())
	patches.process(100000,8)
	assert_int(patches.builds).is_equal(2)
	assert_int(patches.installed.home.node.get_instance_id()).is_not_equal(original.get_instance_id())
	var walls:MultiMeshInstance3D=patches.installed.home.node.find_children("Construction_*","MultiMeshInstance3D",true,false)[0]
	assert_int(int(walls.get_meta("construction_stage"))).is_equal(2)

func test_early_town_and_late_builds_keep_final_placement_through_completion()->void:
	for spec:Array in [["portable_shelter_cluster","organic","ridge_light_shelter"],["timber_household","organic","timber_ridge"],["compact_courtyard_row","earth","courtyard_flat"]]:
		var plot:=_plot(spec[0],spec[1],spec[2]);plot.status="under_construction";plot.construction_progress=.1
		if spec[0]=="compact_courtyard_row":plot.fabric_generation=6
		var plan:=_plan(plot);assert_int(plan.buildings.size()).is_greater(0)
		if plan.buildings.is_empty():continue
		Early.remember_layout(plan,_plots(plot))
		var sites:=var_to_bytes(plot.visual_building_sites)
		var foundation:=_draw(plan);var first:=_transforms(foundation)
		assert_array(first).is_not_empty()
		for progress:float in [.3,.55,.8]:
			plot.construction_progress=progress
			var current:=_draw(Keys.refresh_plan(plan,_plots(plot)))
			assert_array(_transforms(current)).is_equal(first)
		plot.status="active";plot.construction_progress=1.0
		var complete:=_draw(Keys.refresh_plan(plan,_plots(plot)))
		assert_array(_transforms(complete)).is_equal(first)
		assert_array(var_to_bytes(plot.visual_building_sites)).is_equal(sites)
		assert_int(complete.find_children("Construction_*","MultiMeshInstance3D",true,false).size()).is_zero()

func test_root_and_country_seed_use_identical_under_construction_meshes_and_transforms()->void:
	var plot:=_plot();plot.status="under_construction";plot.construction_progress=.35
	var seed:={"id":"construction_seed","kind":"cluster","group":"homesteads","position":Vector2.ZERO,"settlement_plots":_plots(plot),"settlement_routes":_routes(),"track_from":Vector2.ZERO}
	var before:=var_to_bytes(seed)
	var country:Node3D=auto_free(Country.new());country.configure(func(_point:Vector2)->float:return .05,_dry)
	var drawn:Node3D=auto_free(Node3D.new());country._build_patch(drawn,seed,{"style":{},"road_tier":0})
	var expected:=_draw(_plan(plot))
	assert_int(drawn.find_children("Construction_*","MultiMeshInstance3D",true,false).size()).is_greater(0)
	assert_array(_transforms(drawn)).is_equal(_transforms(expected))
	var actual:MultiMeshInstance3D=drawn.find_children("Construction_*","MultiMeshInstance3D",true,false)[0]
	var source:MultiMeshInstance3D=expected.find_children("Construction_*","MultiMeshInstance3D",true,false)[0]
	assert_int(actual.multimesh.mesh.get_instance_id()).is_equal(source.multimesh.mesh.get_instance_id())
	assert_array(var_to_bytes(seed)).is_equal(before)

func test_retrofit_keeps_complete_house_and_adds_only_bounded_scaffold_overlay()->void:
	var plot:=_plot("portable_shelter_cluster","organic","ridge_light_shelter")
	var plan:=_plan(plot);var complete:=_draw(plan)
	var homes:Array=complete.find_children("EarlySettlement_*","MultiMeshInstance3D",true,false)
	assert_int(homes.size()).is_equal(1)
	_begin_retrofit(plot)
	if not plot.has("fabric_job"):return
	var before:=var_to_bytes(plot)
	var working:=_draw(Keys.refresh_plan(plan,_plots(plot)))
	var held:Array=working.find_children("EarlySettlement_*","MultiMeshInstance3D",true,false)
	assert_int(held.size()).is_equal(1)
	assert_int(held[0].multimesh.mesh.get_instance_id()).is_equal(homes[0].multimesh.mesh.get_instance_id())
	assert_array(held[0].get_meta("source_transforms")).is_equal(homes[0].get_meta("source_transforms"))
	assert_int(working.find_children("Construction_*","MultiMeshInstance3D",true,false).size()).is_equal(1)
	assert_array(var_to_bytes(plot)).is_equal(before)
	var key:=Keys.appearance(plot);Fabric.advance(plot,.1,101)
	assert_int(Keys.appearance(plot)).is_equal(key)
	Fabric.advance(plot,1.0,102)
	assert_int(Keys.appearance(plot)).is_equal(key)
	plot.erase("fabric_job")
	assert_int(Keys.appearance(plot)).is_not_equal(key)

func test_damage_and_land_clipping_cannot_be_bypassed_by_scaffolding()->void:
	var plot:=_plot();plot.status="under_construction";plot.construction_progress=.4
	var hidden:=Early.layout(_plots(plot),_routes(),func(_point:Vector2)->bool:return false)
	assert_int(hidden.buildings.size()).is_zero()
	var plan:=_plan(plot);plot.damage={"structural":.9}
	var parent:=_draw(Keys.refresh_plan(plan,_plots(plot)))
	assert_int(parent.find_children("Construction_*","MultiMeshInstance3D",true,false).size()).is_zero()
	plot.status="ruin";plot.damage={}
	parent=_draw(Keys.refresh_plan(plan,_plots(plot)))
	assert_int(parent.find_children("Construction_*","MultiMeshInstance3D",true,false).size()).is_zero()

func test_four_milestones_batch_roofs_without_per_house_nodes()->void:
	var plots:Array[Dictionary]=[]
	var routes:Array[Dictionary]=[]
	for stage in 4:
		var plot:=_plot("portable_shelter_cluster","organic","ridge_light_shelter")
		plot.id=stage+1;plot.seed=91+stage;plot.status="under_construction";plot.construction_progress=float(stage)*.25
		var offset:=Vector2(stage*.06,0);plot.centroid=offset
		for index in plot.polygon.size():plot.polygon[index]+=offset
		plot.frontage_route_id=stage+1
		routes.append({"id":stage+1,"kind":"camp_path","width_m":.6,"points":PackedVector2Array([offset+Vector2(-.025,0),offset+Vector2(.025,0)])})
		plots.append(plot)
	var plan:=Early.layout(plots,routes,_dry);var root:=_draw(plan)
	var batches:Array=root.find_children("Construction_*","MultiMeshInstance3D",true,false)
	assert_int(batches.size()).is_equal(4)
	var count:=0
	for node:MultiMeshInstance3D in batches:count+=node.multimesh.instance_count
	assert_int(count).is_equal(plan.buildings.size())
	assert_int(root.get_child_count()).is_less_equal(8)

func test_daily_construction_signature_changes_only_at_milestones_and_is_city_scoped()->void:
	var plot:=_plot();plot.status="under_construction";plot.construction_progress=.27
	GameState.settlement_plots=_plots(plot);GameState.elapsed_days=11
	var terrain:Terrain=auto_free(Terrain.new())
	var first:=terrain._settlement_construction_visual_signature()
	var token:=terrain._settlement_patch_state_token()
	var morphology:=terrain._settlement_morphology_visual_signature()
	var placement:=Keys.placement(GameState.settlement_plots,[])
	for fraction:float in [.29,.34,.41,.49]:
		GameState.elapsed_days+=1;plot.construction_progress=fraction
		assert_int(terrain._settlement_construction_visual_signature()).is_equal(first)
		assert_int(terrain._settlement_patch_state_token()).is_equal(token)
	GameState.elapsed_days+=1;plot.construction_progress=.5
	assert_int(terrain._settlement_construction_visual_signature()).is_not_equal(first)
	assert_int(terrain._settlement_patch_state_token()).is_not_equal(token)
	assert_str(terrain._settlement_morphology_visual_signature()).is_equal(morphology)
	assert_int(Keys.placement(GameState.settlement_plots,[])).is_equal(placement)
	GameState.resource_settlement_id="test_secondary";plot.construction_progress=.27
	assert_int(terrain._settlement_construction_visual_signature()).is_equal(first)
	assert_int(terrain.cached_construction_visual_signatures.size()).is_equal(2)

func test_root_refresh_observes_milestone_without_rebuilding_vegetation()->void:
	var plot:=_plot();plot.status="under_construction";plot.construction_progress=.27
	GameState.initialize_population_model();GameState.settlement_completed=["Hearth Circle"]
	GameState.settlement_plots=_plots(plot);GameState.settlement_routes=_routes();GameState.elapsed_days=11
	SettlementModel.ensure_founded()
	var terrain:Terrain=auto_free(Terrain.new())
	terrain.camera=Camera3D.new();terrain.camera.size=.5;terrain.add_child(terrain.camera)
	terrain.settler_marker=Area3D.new();terrain.add_child(terrain.settler_marker)
	terrain.settlement_blip=MeshInstance3D.new();terrain.add_child(terrain.settlement_blip)
	terrain._refresh_settlement_footprint()
	assert_int(terrain.requests).is_equal(1)
	var vegetation:=terrain.vegetation_builds
	GameState.elapsed_days+=1;plot.construction_progress=.42
	terrain._refresh_settlement_footprint()
	assert_int(terrain.requests).is_equal(1)
	GameState.elapsed_days+=1;plot.construction_progress=.5
	terrain._refresh_settlement_footprint()
	assert_int(terrain.requests).is_equal(2)
	assert_int(terrain.vegetation_builds).is_equal(vegetation)
	assert_int(terrain.settlement_layout_builds).is_zero()

func _fallback(terrain:Terrain,plot:Dictionary)->Dictionary:
	var roof:=SurfaceTool.new();roof.begin(Mesh.PRIMITIVE_TRIANGLES)
	var walls:=SurfaceTool.new();walls.begin(Mesh.PRIMITIVE_TRIANGLES)
	var counts:Dictionary=terrain._append_satellite_roof_fabric(roof,walls,plot,Vector3.ZERO,0,true)
	var roof_arrays:=roof.commit_to_arrays();var wall_arrays:=walls.commit_to_arrays()
	return {"counts":counts,"roofs":roof_arrays[Mesh.ARRAY_VERTEX] if not roof_arrays.is_empty() and roof_arrays[Mesh.ARRAY_VERTEX] is PackedVector3Array else PackedVector3Array(),"walls":wall_arrays[Mesh.ARRAY_VERTEX] if not wall_arrays.is_empty() and wall_arrays[Mesh.ARRAY_VERTEX] is PackedVector3Array else PackedVector3Array()}

func test_fallback_work_keeps_final_mass_placement_and_roof_is_added_only_at_last_stage()->void:
	var plot:=_plot();plot.id=preload("res://scripts/organic_town_visual.gd").MAX_PLOTS+1
	GameState.settlement_plots=_plots(plot);GameState.settlement_routes=_routes()
	var terrain:Terrain=auto_free(Terrain.new());var final:=_fallback(terrain,plot)
	assert_int(final.counts.roofs).is_greater(0)
	assert_array(final.walls).is_not_empty()
	plot.status="under_construction"
	var foundation:Dictionary={}
	for stage in 4:
		plot.construction_progress=float(stage)*.25
		var current:=_fallback(terrain,plot)
		if stage<3:
			assert_int(current.counts.roofs).is_zero()
			assert_array(current.roofs).is_empty()
			assert_int(current.counts.walls).is_greater(0)
		else:
			assert_array(current.roofs).is_equal(final.roofs)
			assert_array(current.walls).is_equal(final.walls)
		if stage==0:foundation=current
		if stage==1:assert_int(current.walls.size()).is_greater(foundation.walls.size())
		if stage==2:assert_array(current.walls).is_equal(final.walls)
	plot.construction_progress=.3
	var held:=_fallback(terrain,plot);plot.construction_progress=.49
	assert_array(_fallback(terrain,plot).walls).is_equal(held.walls)
