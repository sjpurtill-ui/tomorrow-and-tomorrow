extends GdUnitTestSuite
const ART=preload("res://scripts/settlement_place_art.gd")
const VISUAL=preload("res://scripts/settlement_country_visual.gd")

func _record(kind:String="coast",status:String="living",trend:int=0)->Dictionary:
	return {"id":"place:shore-1","kind":"cluster","group":"homesteads","position":Vector2(1,1),"track_from":Vector2.ZERO,"road_tier":1,
		"place":{"id":"shore-1","name":"Reedhaven","position":Vector2(1,1),"kind":kind,"status":status,"trend":trend,"flooded":false,
			"facing":Vector2.RIGHT,"open_water":0.65,"people":240,"day":20000,"left_day":20000},
		"settlement_growth":{"seed":4177,"parcels":12,"templates":[{"form":"timber_household","roof_plan":"timber_ridge","material_family":"organic","storeys":1}],"obstacles":[]}}

func _visual():
	var visual=auto_free(VISUAL.new())
	visual.configure(func(_at:Vector2)->float:return 0.0,func(at:Vector2)->bool:return at.x<1.3)
	visual.water_at=func(at:Vector2)->bool:return at.x>=1.3
	return visual

func _draw(visual,record:Dictionary)->Node3D:
	var node:Node3D=auto_free(Node3D.new())
	visual._build_patch(node,record,{"style":{},"road_tier":1})
	return node

func _details(kind:String,land:Callable)->Dictionary:
	var record:=_record(kind)
	return ART.details({"origin":record.position,"place":record.place,"plots":[],"plan":{"buildings":[]}},land,func(at:Vector2)->bool:return not bool(land.call(at)))

func _flush(visual)->void:
	var guard:=0
	while not visual.retained.pending.is_empty() and guard<200:
		visual.process_jobs(100000,8);guard+=1
	assert_int(visual.retained.pending.size()).is_equal(0)

func _roof_sites(visual,id:String)->Dictionary:
	var out:Dictionary={}
	for building:Dictionary in visual._seed_layouts[id].plan.buildings:
		out[building.id]=[building.position,building.angle,building.footprint,building.variant]
	return out

func test_coast_details_find_true_bank_and_high_open_water_salt()->void:
	var detail:=_details("coast",func(point:Vector2)->bool:return point.x<1.3)
	assert_bool(detail.shore_found).is_true()
	assert_float(float(detail.bank.x)).is_between(1.299,1.301)
	assert_int(detail.props.size()).is_equal(3)
	assert_str(detail.props[0].kind).is_equal("dugout")
	assert_str(detail.props[2].kind).is_equal("drying_rack")
	assert_int(detail.fields.size()).is_equal(2)
	for entry:Dictionary in detail.props:assert_float(float(entry.position.x)).is_less(1.3)
	assert_str(detail.lines[0].kind).is_equal("shore_access")

func test_lake_jetty_needs_physical_water_and_other_places_have_distinct_ground()->void:
	var dry:=_details("lake",func(_point:Vector2)->bool:return true)
	assert_bool(dry.shore_found).is_false()
	assert_int(dry.props.size()).is_equal(5)
	var lake:=_details("lake",func(point:Vector2)->bool:return point.x<1.3)
	assert_int(lake.props.size()).is_equal(6)
	assert_str(lake.props[-1].kind).is_equal("jetty")
	var river:=_details("river",func(_point:Vector2)->bool:return true)
	assert_str(river.lines[0].kind).is_equal("bank_track")
	assert_str(river.lines[1].kind).is_equal("crossing_track")
	var inland:=_details("inland",func(_point:Vector2)->bool:return true)
	assert_int(inland.fields.size()).is_equal(2)
	assert_str(inland.fields[0].kind).is_equal("field_plot")

func test_dry_cliff_and_unknown_river_bearing_never_create_false_water_features()->void:
	var bank:=ART.shore(Vector2.ZERO,Vector2.RIGHT,func(at:Vector2)->bool:return at.x<0.2,func(_at:Vector2)->bool:return false)
	assert_bool(bank.found).is_false()
	var record:=_record("river");record.place.facing=Vector2.ZERO
	var detail:=ART.details({"origin":record.position,"place":record.place,"plots":[]},func(_at:Vector2)->bool:return true)
	assert_array(detail.lines).is_empty()
	assert_array(detail.props).is_empty()

func test_named_place_uses_unchanged_root_plan_and_smaller_ink_name()->void:
	var visual=_visual();var record:=_record()
	var before:=var_to_bytes(record)
	var drawn:=_draw(visual,record)
	assert_array(var_to_bytes(record)).is_equal(before)
	assert_int(drawn.get_meta("country_home_count")).is_greater(0)
	assert_str(drawn.get_meta("country_place_name")).is_equal("Reedhaven")
	var label:=drawn.get_node("PlaceChartName") as Label3D
	assert_str(label.text).is_equal("Reedhaven")
	assert_int(label.font_size).is_less(12)
	assert_bool(label.font!=null).is_true()
	assert_bool(drawn.get_meta("place_detail_kinds").has("dugout")).is_true()
	assert_int(drawn.get_meta("place_detail_positions").size()).is_less_equal(ART.MAX_DETAILS)

func test_growth_and_flood_overlays_leave_all_established_roofs_stationary()->void:
	var visual=_visual();var record:=_record()
	var calm:=_draw(visual,record)
	var positions:Array=calm.get_meta("country_home_positions")
	var steps:int=visual.seed_layout_steps
	record.place.trend=1;record.place.flooded=true
	var flood:=_draw(visual,record)
	assert_array(flood.get_meta("country_home_positions")).is_equal(positions)
	assert_int(visual.seed_layout_steps).is_equal(steps)
	assert_bool(flood.get_meta("place_detail_kinds").has("frame")).is_true()
	assert_bool(flood.get_meta("place_detail_kinds").has("flood_wash")).is_true()
	var detail:Dictionary=ART.details({"origin":record.position,"place":record.place,"plots":[]},func(_point:Vector2)->bool:return true)
	for entry:Dictionary in detail.washes:
		if entry.kind=="flood_wash":assert_float(float(entry.position.x)).is_greater(1.0)

func test_shrinking_houses_lose_some_roofs_without_mutating_cached_sites()->void:
	var visual=_visual();var record:=_record()
	var alive:=_draw(visual,record)
	var prior:=_roof_sites(visual,record.id)
	record.place.trend=-1
	var shrinking:=_draw(visual,record)
	assert_int(shrinking.get_meta("place_damaged_roofs")).is_between(1,3)
	assert_int(shrinking.get_meta("country_home_count")).is_less(alive.get_meta("country_home_count"))
	assert_dict(_roof_sites(visual,record.id)).is_equal(prior)
	assert_int(shrinking.get_meta("country_seed_plan").buildings.size()).is_equal(shrinking.get_meta("country_home_count"))
	record.place.trend=0
	var recovered:=_draw(visual,record)
	assert_array(recovered.get_meta("country_home_positions")).is_equal(alive.get_meta("country_home_positions"))

func test_ruin_has_no_occupied_roofs_and_fades_with_years_since_leaving()->void:
	var visual=_visual();var record:=_record()
	var living:=_draw(visual,record)
	record.place.status="ruin";record.place.people=0
	var ruin:=_draw(visual,record)
	assert_int(ruin.get_meta("country_home_count")).is_equal(0)
	assert_int(ruin.get_meta("place_damaged_roofs")).is_equal(living.get_meta("country_home_count"))
	assert_bool(ruin.get_meta("place_detail_kinds").has("overgrowth")).is_true()
	assert_bool(ruin.get_meta("place_detail_kinds").has("dugout")).is_false()
	record.place.day+=365*60
	var old:=_draw(visual,record)
	assert_float(old.get_meta("country_place_fade")).is_less(ruin.get_meta("country_place_fade"))
	assert_array(old.get_meta("country_home_positions")).is_empty()

func test_track_work_is_bounded_and_incremental_with_dry_coast_detour()->void:
	var track:=ART.begin_track(Vector2.ZERO,Vector2(160,0),{"facing":Vector2.UP})
	assert_bool(ART.advance_track(track,func(_at:Vector2)->bool:return true)).is_false()
	assert_int(track.points.size()).is_equal(2)
	while not ART.advance_track(track,func(_at:Vector2)->bool:return true):pass
	assert_int(track.points.size()).is_equal(ART.MAX_TRACK_POINTS)
	assert_vector(track.points[-1]).is_equal(Vector2(160,0))
	var points:=ART.track_points(Vector2.ZERO,Vector2(1,0),{"facing":Vector2.UP},func(at:Vector2)->bool:return not (at.x>0.3 and at.x<0.7 and absf(at.y)<0.05))
	var bent:=false
	for point:Vector2 in points:
		if absf(point.y)>=0.05:bent=true
	assert_bool(bent).is_true()

func test_replacement_keeps_old_patch_while_track_and_roofs_prepare()->void:
	var visual=_visual();var record:=_record()
	var entries:Array[Dictionary]=[{"key":"homesteads:place:shore-1","signature":1,"build":visual._build_patch.bind(record,{"style":{},"road_tier":1})}]
	visual.retained.request(entries);_flush(visual)
	var previous:Node3D=visual.retained.installed[entries[0].key].node
	var prior_id:=previous.get_instance_id()
	record.place.flooded=true
	entries[0].signature=2;visual.retained.request(entries)
	visual.process_jobs(1,1);visual.process_jobs(1,1)
	assert_int(visual.retained.installed[entries[0].key].node.get_instance_id()).is_equal(prior_id)
	_flush(visual)
	assert_int(visual.retained.installed[entries[0].key].node.get_instance_id()).is_not_equal(prior_id)
	assert_bool(visual.retained.installed[entries[0].key].node.get_meta("country_place_flooded")).is_true()

func test_discarded_named_place_is_never_resurrected_as_established_fallback()->void:
	var visual=_visual();var record:=_record()
	var snapshot:={"owner":"player","origin":Vector2.ZERO,"population":0.0,"seed":4,"founded":true,"deposits":[]}
	visual._seed_identity=["player",4,Vector2.ZERO]
	visual.plan={"homesteads":[record]}
	var entries:Array[Dictionary]=[{"key":"homesteads:place:shore-1","signature":1,"build":visual._build_patch.bind(record,{"style":{},"road_tier":1})}]
	visual.retained.request(entries);_flush(visual)
	visual.request(snapshot)
	assert_bool(visual._established_seeds.has(record.id)).is_false()
	assert_bool(visual._seed_layouts.has(record.id)).is_false()
	assert_bool(visual._growth_states.has(record.id)).is_false()
	assert_bool(visual.retained.desired.has(entries[0].key)).is_false()

func test_far_farms_do_not_consume_retained_neighbourhood_slots()->void:
	var visual=_visual()
	var snapshot:={"owner":"player","origin":Vector2.ZERO,"population":50000.0,"seed":157,"founded":true,
		"core_km":9.0,"worked_km":60.0,"realm_km":60.0,"dense_radius_km":0.2,"deposits":[]}
	visual.request(snapshot)
	var active:=0
	for record:Dictionary in visual.plan.homesteads:
		if record.has("settlement_growth"):active+=1
	assert_int(visual.plan.homesteads.size()).is_greater(24)
	assert_int(active).is_less(24)
	var old:=_record();old.erase("place");old.id="seed:player:157:23";old.offset=old.position;old.distance_km=old.position.length()
	visual._established_seeds[old.id]=old
	snapshot.population=40000.0
	visual.request(snapshot)
	assert_bool(visual.retained.desired.has("homesteads:"+String(old.id))).is_true()
