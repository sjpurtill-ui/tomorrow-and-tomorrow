extends GdUnitTestSuite
const Details:=preload("res://scripts/settlement_yard_details.gd")
const Meshes:=preload("res://scripts/settlement_yard_meshes.gd")
const Ground:=preload("res://scripts/early_settlement_ground.gd")
const Town:=preload("res://scripts/organic_town_visual.gd")
const KNOWLEDGE:=["clay_shaping","food_drying","seed_reserves","fish_weirs_and_traps"]

func before_test()->void:GameState.reset_for_new_world(910178)

func _box(at:Vector2,half:Vector2)->PackedVector2Array:
	return PackedVector2Array([at+Vector2(-half.x,-half.y),at+Vector2(half.x,-half.y),at+half,at+Vector2(-half.x,half.y)])

func _source(count:int=1,identity:String="root",origin:Vector2=Vector2.ZERO)->Dictionary:
	var buildings:Array[Dictionary]=[];var plots:Array[Dictionary]=[]
	for index in count:
		var at:=Vector2(float(index%8)*.028,float(index/8)*.028)
		var plot:={"id":index+1,"seed":91+index,"centroid":at,"polygon":_box(at,Vector2.ONE*.012),"land_use":"residential_compound","status":"active","resident_count":5,"form":"timber_household","material_family":"timber"}
		plots.append(plot)
		buildings.append({"id":"%d:0" % (index+1),"plot_id":index+1,"plot":plot,"position":at,"footprint":_box(at,Vector2(.002,.003)),"angle":0.0,"radius":.0037})
	plots.append({"id":999,"centroid":Vector2(-.02,0),"polygon":_box(Vector2(-.02,0),Vector2.ONE*.006),"land_use":"field","status":"active"})
	return {"id":identity,"origin":origin,"plan":{"buildings":buildings,"replaced":{}},"plots":plots,"routes":[],"knowledge":KNOWLEDGE.duplicate()}

func _flat(_point:Vector2)->float:return .08
func _dry(_point:Vector2)->bool:return true
func _seen(_point:Vector2)->bool:return true
func _never(_point:Vector2)->bool:return false
func _sources(source:Dictionary)->Array[Dictionary]:return [source]
func _water(point:Vector2)->bool:return point.x<-.018
func _yards()->Node3D:
	var node:Node3D=auto_free(Details.new());node.configure(_flat,_dry,_seen,_water);return node
func _draw(node:Node3D,sources:Array[Dictionary],revision:int=1,view:Vector2=Vector2.ZERO)->void:
	node.request(sources,revision);node.set_view(view,.1)
	for step in 40:
		node.process_jobs(1000000,4)
		if int(node.stats().pending)==0:break
func _kinds(node:Node3D)->Array[String]:
	var kinds:Array[String]=[]
	for row:Dictionary in node.displayed:
		if String(row.kind) not in kinds:kinds.append(row.kind)
	kinds.sort();return kinds
func _positions(node:Node3D)->Dictionary:
	var result:Dictionary={}
	for row:Dictionary in node.displayed:result[String(row.house_id)+"/"+String(row.kind)]=row.transform
	return result

func test_one_global_budget_and_five_batches_bound_many_sources_without_people()->void:
	var sources:Array[Dictionary]=[_source(64,"root",Vector2(-.10,-.10)),_source(64,"neighbor",Vector2(.14,-.10))]
	var before:=var_to_bytes(sources);var node:=_yards()
	_draw(node,sources)
	assert_int(int(node.stats().houses)).is_equal(Details.MAX_HOUSES)
	assert_int(node.displayed.size()).is_greater(0)
	assert_int(node.displayed.size()).is_less_equal(Details.MAX_PROPS)
	assert_int(node.get_child_count()).is_less_equal(5)
	var homes:Dictionary={}
	for row:Dictionary in node.displayed:homes[row.house_id]=int(homes.get(row.house_id,0))+1
	for count:int in homes.values():assert_int(count).is_less_equal(3)
	for child:Node in node.get_children():
		assert_bool(child is MultiMeshInstance3D).is_true()
		assert_bool(String(child.name).begins_with("Yard_")).is_true()
		assert_int(child.get_child_count()).is_zero()
	assert_array(var_to_bytes(sources)).is_equal(before)

func test_yard_footprints_avoid_houses_parcel_edges_routes_and_each_other()->void:
	var source:=_source(8)
	source.routes=[{"id":1,"kind":"camp_path","width_m":1.2,"points":PackedVector2Array([Vector2(-.01,.0045),Vector2(.21,.0045)])}]
	var node:=_yards();_draw(node,[source],1,Vector2(.08,0))
	assert_int(node.displayed.size()).is_greater(0)
	var envelopes:=Geometry2D.offset_polyline(source.routes[0].points,Town.route_half_width(source.routes[0]))
	for index in node.displayed.size():
		var row:Dictionary=node.displayed[index]
		for house:Dictionary in source.plan.buildings:
			assert_array(Geometry2D.intersect_polygons(row.footprint,house.footprint)).is_empty()
			if String(row.house_id)=="root/"+String(house.id):assert_array(Geometry2D.clip_polygons(row.footprint,house.plot.polygon)).is_empty()
		for road:PackedVector2Array in envelopes:assert_array(Geometry2D.intersect_polygons(row.footprint,road)).is_empty()
		for earlier in index:assert_array(Geometry2D.intersect_polygons(row.footprint,node.displayed[earlier].footprint)).is_empty()
		var mesh_bounds:=Meshes.bounds(row.kind)
		assert_float(row.transform.origin.y+mesh_bounds.position.y*.001).is_equal_approx(.08002,.000001)

func test_water_fog_and_steep_ground_skip_instead_of_stacking_a_fallback()->void:
	var node:=_yards();var source:=_source()
	node.configure(_flat,_never,_seen,_water);_draw(node,[source])
	assert_array(node.displayed).is_empty()
	node.configure(_flat,_dry,_never,_water);_draw(node,[source],2)
	assert_array(node.displayed).is_empty()
	node.configure(func(point:Vector2)->float:return point.x*20.0,_dry,_seen,_water);_draw(node,[source],3)
	assert_array(node.displayed).is_empty()
	# A dry cliff rejected for building is not evidence of fishing water.
	node.configure(_flat,_dry,_seen);_draw(node,[source],4)
	assert_array(_kinds(node)).not_contains(["fishing_net"])

func test_only_occupied_completed_homes_have_yards_and_removal_is_immediate()->void:
	var source:=_source(5)
	source.plan.buildings[0].plot.status="under_construction"
	source.plan.buildings[1].plot.status="vacant"
	source.plan.buildings[2].plot.status="ruin"
	source.plan.buildings[3].plot.resident_count=0
	var node:=_yards();_draw(node,[source],1,Vector2(.10,0))
	assert_int(node.displayed.size()).is_greater(0)
	for row:Dictionary in node.displayed:assert_str(row.house_id).is_equal("root/5:0")
	source.plan.buildings[4].plot.status="ruin"
	node.request(_sources(source),2)
	assert_array(node.displayed).is_empty()
	for child:MultiMeshInstance3D in node.get_children():assert_int(child.multimesh.visible_instance_count).is_zero()

func test_grain_and_nets_require_actual_craft_and_local_context_without_inventory_reads()->void:
	var source:=_source(16,"coast",Vector2(-.015,-.08))
	var node:=_yards();_draw(node,[source],1,Vector2(.035,0))
	assert_array(_kinds(node)).contains(["woodpile","pots","drying_rack","stored_grain","fishing_net"])
	source.knowledge=[];_draw(node,[source],2,Vector2(.035,0))
	assert_array(_kinds(node)).is_equal(["woodpile"])
	source.knowledge=KNOWLEDGE.duplicate();source.plots.pop_back()
	node.configure(_flat,_dry,_seen,_never);_draw(node,[source],3,Vector2(.035,0))
	assert_array(_kinds(node)).not_contains(["stored_grain","fishing_net"])

func test_idle_frames_and_pan_revisit_reuse_positions_nodes_and_no_placement_work()->void:
	var source:=_source(12);var node:=_yards();_draw(node,[source],1,Vector2(.08,0))
	var first:=_positions(node);var builds:int=node.placement_builds;var updates:int=node.batch_updates
	var nodes:Array=[]
	for child:Node in node.get_children():nodes.append(child.get_instance_id())
	for frame in 120:
		node.request(_sources(source),1);node.set_view(Vector2(.08,0),.1);node.process_jobs()
	assert_int(node.placement_builds).is_equal(builds);assert_int(node.batch_updates).is_equal(updates)
	node.set_view(Vector2(3,3),.1);node.process_jobs(1000000,4)
	assert_array(node.displayed).is_empty()
	node.set_view(Vector2(.08,0),.1);node.process_jobs(1000000,4)
	assert_dict(_positions(node)).is_equal(first)
	assert_int(node.placement_builds).is_equal(builds)
	var returned:Array=[]
	for child:Node in node.get_children():returned.append(child.get_instance_id())
	assert_array(returned).is_equal(nodes)

func test_view_gate_and_cooperative_work_have_explicit_hard_limits()->void:
	var node:=_yards();node.request(_sources(_source(64,"root",Vector2(-.10,-.10))),1)
	node.set_view(Vector2.ZERO,.301);node.process_jobs(1000000,4)
	assert_bool(node.visible).is_false();assert_int(node.placement_builds).is_zero()
	node.set_view(Vector2.ZERO,.30);node.process_jobs(1000000,4)
	assert_bool(node.visible).is_true();assert_int(node.placement_builds).is_equal(4)
	assert_int(int(node.stats().pending)).is_equal(28)
	node.set_view(Vector2.ZERO,1.0);node.process_jobs(1000000,4)
	assert_bool(node.visible).is_false();assert_int(node.placement_builds).is_equal(4)

func test_old_household_and_service_layer_never_duplicates_five_yard_kinds()->void:
	GameState.known_discoveries.assign(KNOWLEDGE)
	var source:=_source(4)
	source.plots.append({"id":900,"seed":7,"form":"open_hearth_yard","status":"active","centroid":Vector2(-.02,-.02)})
	source.plots.append({"id":901,"seed":8,"form":"guarded_cache","status":"active","centroid":Vector2(-.02,.02)})
	var plots:Array[Dictionary]=[];plots.assign(source.plots)
	var parent:Node3D=auto_free(Node3D.new())
	Ground.render(source.plan,plots,[],Vector3.ZERO,func(_x:float,_z:float)->float:return .08,_dry,parent,false)
	for kind:String in Meshes.KINDS:assert_array(parent.find_children("Prop_"+kind,"",true,false)).is_empty()
	assert_array(parent.find_children("Prop_bench","",true,false)).is_not_empty()
	var country:Node3D=auto_free(preload("res://scripts/settlement_country_visual.gd").new())
	var far_parent:Node3D=auto_free(Node3D.new())
	for kind:String in Meshes.KINDS:country._add_prop(far_parent,kind,Vector2.ZERO,0.0)
	assert_int(far_parent.get_child_count()).is_zero()

func test_admitted_country_homes_need_explicit_occupancy_without_inventing_residents()->void:
	var source:=_source(3,"country_seed")
	for house:Dictionary in source.plan.buildings:house.plot.resident_count=0
	var node:=_yards();_draw(node,[source])
	assert_array(node.displayed).is_empty()
	source.representative_occupied=true
	source.plan.buildings[1].plot.status="under_construction"
	source.plan.buildings[2].plot.status="ruin"
	var before:=var_to_bytes(source)
	_draw(node,[source],2)
	assert_int(node.displayed.size()).is_greater(0)
	for row:Dictionary in node.displayed:assert_str(row.house_id).is_equal("country_seed/1:0")
	assert_array(var_to_bytes(source)).is_equal(before)

func test_planetary_origin_preserves_submetre_placement_and_polygon_clearance()->void:
	var source:=_source(8)
	source.routes=[{"id":1,"kind":"camp_path","width_m":1.2,"points":PackedVector2Array([Vector2(-.01,.0045),Vector2(.21,.0045)])}]
	var near:=_yards();near.configure(_flat,_dry,_seen,_never);_draw(near,[source])
	assert_int(near.displayed.size()).is_greater(0)
	var actual:=source.duplicate(true);actual.origin=Vector2(14034,-9260)
	var far:=_yards();far.configure(_flat,_dry,_seen,_never);_draw(far,[actual],1,actual.origin)
	assert_int(far.displayed.size()).is_equal(near.displayed.size())
	assert_dict(_positions(far)).is_equal(_positions(near))
	assert_object(far.position).is_equal(Vector3(14034,0,-9260))
	for index in near.displayed.size():
		assert_array(far.displayed[index].local_footprint).is_equal(near.displayed[index].local_footprint)

func test_live_source_occupancy_overrides_cached_plan_and_removed_plots()->void:
	var source:=_source(2)
	# A retained renderer snapshot deliberately keeps its old active residents.
	source.plan=source.plan.duplicate(true)
	source.plots[0].resident_count=0
	source.plots[1].status="vacant"
	var node:=_yards();_draw(node,[source])
	assert_array(node.displayed).is_empty()
	source.plots[0].resident_count=5
	_draw(node,[source],2)
	assert_int(node.displayed.size()).is_greater(0)
	for row:Dictionary in node.displayed:assert_str(row.house_id).is_equal("root/1:0")
	source.plots.remove_at(0)
	_draw(node,[source],3)
	assert_array(node.displayed).is_empty()
