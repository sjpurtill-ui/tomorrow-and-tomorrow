extends GdUnitTestSuite
const View=preload("res://scripts/hud/reported_city_view.gd")
const Foreign=preload("res://scripts/foreign_settlement_visual.gd")
const Grounds=preload("res://scripts/settlement_grounds.gd")
const Dossier=preload("res://scripts/hud/city_dossier.gd")
const Dock=preload("res://scripts/hud/content/dock_detail_foreign_city.gd")

class MapFixture extends Node3D:
	var camera:Camera3D
	var camera_target:=Vector3(90,2,40)
	var camera_yaw:=.23
	var camera_pitch:=-1.1
	var zoom_target_size:=7.0
	var camera_updates:=0
	var sampled:Array[Vector2]=[]
	func _init()->void:
		camera=Camera3D.new();camera.size=8.0;add_child(camera)
	func _height_at(x:float,z:float)->float:
		sampled.append(Vector2(x,z));return .4+x*.0001+z*.00003
	func _update_camera()->void:camera_updates+=1
	func _update_scale_lod()->void:camera_updates+=1

func before_test()->void:
	WorldSimulation.clear()
	GameState.reset_for_new_world(861302)
	MilitaryCampaign.reset_for_new_world();ForeignDiplomacy.reset_for_new_world()
	Grounds.clear()

func _field(low:float,high:float)->Dictionary:
	return {"low":low,"high":high,"observed_low":low,"observed_high":high,"observed_day":100,"reported_day":110,"quality":.8,"source":"our returning scout","reference":"visit:1"}

func _report()->Dictionary:
	return {"city_id":"reported-town","civ_id":"reported-people","name":"Reedbank","position":{"x":14034.0,"z":-752.0},
		"controller":"reported-people","observed_day":100,"reported_day":110,"quality":.8,"source":"our returning scout","reference":"visit:1",
		"fields":{"population":_field(180,220),"fortification":_field(.2,.4),"damage":_field(.0,.1)}}

func _view(report:Dictionary,map:Node=null)->Control:
	var widget:Control=auto_free(View.new());add_child(widget)
	widget.setup({"report":report,"terrain":map,"fresh_status":"Aging","fresh_age":"about a year ago","caption":"Held by the Reed People"})
	return widget

func _geometry(widget:Control)->Array:
	var result:Array=[]
	var model:Node3D=widget.get("model")
	for child:Node in model.get_children():
		if child is MultiMeshInstance3D and String(child.name).begins_with("ForeignHouses_"):
			result.append([String(child.name),child.multimesh.instance_count,child.get_meta("source_transforms",[])])
	return result

func _texts(node:Node)->String:
	var values:Array[String]=[]
	if node is Label:values.append(node.text)
	if node is Button:values.append(node.text)
	for child:Node in node.get_children():values.append(_texts(child))
	return "\n".join(values)

func test_portrait_uses_frozen_observed_bounds_instead_of_aging_projection()->void:
	var report:=_report();var bytes:=var_to_bytes(report)
	var first:=_view(report)
	var aged:=report.duplicate(true)
	aged.fields.population.low=0.0;aged.fields.population.high=8000.0
	aged.fields.fortification.low=0.0;aged.fields.fortification.high=1.0
	aged["age_days"]=1200;aged["freshness"]="stale"
	var second:=_view(aged)
	assert_array(_geometry(second)).is_equal(_geometry(first))
	assert_int(Foreign.display_population(second.get("frozen_report"))).is_equal(200)
	assert_array(var_to_bytes(report)).is_equal(bytes)
	assert_float(float(aged.fields.population.high)).is_equal(8000.0)

func test_hidden_rival_changes_cannot_restyle_or_resize_an_existing_report()->void:
	CivilizationSystem.reset_for_new_world();CivilizationSystem.initialize()
	var civ:Dictionary=CivilizationSystem.civilizations[0]
	var report:=_report();report.civ_id=String(civ.id);report.city_id=String(civ.strategic_regions[0].id)
	var first:=_view(report)
	var before:=_geometry(first)
	civ.population=float(civ.population)*15.0
	civ.strategic_regions[0].population=90000000.0
	civ.strategic_regions[0].damage=1.0;civ.strategic_regions[0].fortification=1.0
	civ["knowledge"]=.99;civ["production"]=.99
	var second:=_view(report)
	assert_array(_geometry(second)).is_equal(before)
	assert_dict(second.get("frozen_report")).is_equal(first.get("frozen_report"))

func _observed_state()->PackedByteArray:
	return var_to_bytes([GameState.population_total,GameState.elapsed_days,GameState.settlement_plots,GameState.settlement_routes,
		GameState.settlement_completed,GameState.resource_stockpiles,GameState.settlement_portrait_history,
		CivilizationSystem.city_intelligence.records if CivilizationSystem.city_intelligence!=null else {},
		Grounds.signature,Grounds.slot_keys,Grounds.slot_signatures,Grounds.slot_reports,Grounds._requests])

func test_private_portrait_does_not_touch_map_camera_ledgers_ground_or_home_album()->void:
	var map:MapFixture=auto_free(MapFixture.new());add_child(map)
	GameState.settlement_portrait_history={"home":{"views":[{"day":20,"span":.2,"reason":"First recorded view"}]}}
	Grounds.request("existing-town",{"buildings":[]},[],[],Vector3(1,0,3))
	var before:=_observed_state()
	var camera_state:=[map.camera.transform,map.camera.size,map.camera_target,map.camera_yaw,map.camera_pitch,map.zoom_target_size]
	var report:=_report();var evidence:=var_to_bytes(report)
	var widget:=_view(report,map)
	var view:SubViewport=widget.get("view")
	assert_bool(view.own_world_3d).is_true()
	assert_object(view.world_3d).is_not_same(map.get_viewport().world_3d)
	assert_array(_observed_state()).is_equal(before)
	assert_array(var_to_bytes(report)).is_equal(evidence)
	assert_int(map.camera_updates).is_zero()
	assert_array([map.camera.transform,map.camera.size,map.camera_target,map.camera_yaw,map.camera_pitch,map.zoom_target_size]).is_equal(camera_state)
	assert_int(map.sampled.size()).is_equal(View.GRID_SIZE*View.GRID_SIZE+1)
	for point:Vector2 in map.sampled:assert_float(point.distance_to(Vector2(14034,-752))).is_less(2.0)
	widget.hide();widget.call("_visibility_changed")
	assert_array(_observed_state()).is_equal(before)
	assert_bool(map.has_meta("village_portrait")).is_false()

func test_unknown_evidence_stays_unknown_and_geometry_is_bounded_without_people()->void:
	var report:=_report();report.fields={}
	var unknown:=_view(report)
	assert_dict((unknown.get("frozen_report") as Dictionary).fields).is_empty()
	assert_int(Foreign.display_population(unknown.get("frozen_report"))).is_equal(-1)
	var large:=_report();large.fields.population=_field(90000000,90000000)
	var widget:=_view(large)
	assert_int(int(widget.stats().building_count)).is_between(1,Foreign.MAX_BUILDINGS)
	var model:Node3D=widget.get("model")
	for node:Node in model.find_children("*","",true,false):
		assert_bool(node is AnimationPlayer or node is Skeleton3D).is_false()
		var source:Script=node.get_script()
		if source!=null:
			assert_str(source.resource_path).not_contains("court_figure")
			assert_str(source.resource_path).not_contains("living_map")
	assert_int(int(widget.stats().model_builds)).is_equal(1)

func test_view_renders_on_demand_and_stops_when_hidden()->void:
	var widget:=_view(_report())
	await get_tree().process_frame
	await get_tree().process_frame
	var view:SubViewport=widget.get("view")
	assert_int(view.render_target_update_mode).is_not_equal(SubViewport.UPDATE_ALWAYS)
	var drawn:=int(widget.stats().viewport_updates)
	assert_int(drawn).is_greater(0)
	await get_tree().process_frame
	assert_int(int(widget.stats().viewport_updates)).is_equal(drawn)
	widget.hide();widget.call("_visibility_changed")
	assert_int(view.render_target_update_mode).is_equal(SubViewport.UPDATE_DISABLED)
	widget.call("_request_render")
	await get_tree().process_frame
	assert_int(int(widget.stats().viewport_updates)).is_equal(drawn)
	assert_int(int(widget.stats().model_builds)).is_equal(1)

func test_real_report_adapter_keeps_metrics_provenance_and_unknown_rows()->void:
	CivilizationSystem.reset_for_new_world();CivilizationSystem.initialize()
	var civ:Dictionary=CivilizationSystem.civilizations[0]
	var report:=_report();report.civ_id=String(civ.id);report.controller=String(civ.id);report.city_id=String(civ.strategic_regions[0].id)
	CivilizationSystem.city_intelligence.publish("player",report,110)
	GameState.elapsed_days=600
	var dock:=Dock.new(null,null,String(report.city_id))
	var blocks:Array=dock.tab(0).blocks
	var selected:Dictionary={}
	for block:Dictionary in blocks:
		if String(block.get("type",""))=="city_dossier":selected=block;break
	assert_dict(selected).is_not_empty()
	if selected.is_empty():return
	assert_dict(selected.get("report",{})).is_not_empty()
	assert_str(String(selected.source)).is_equal("our returning scout")
	assert_str(String(selected.account)).contains("between 180 and 220 people")
	var population:Dictionary={};var garrison:Dictionary={}
	for item:Dictionary in selected.items:
		if item.key=="population":population=item
		if item.key=="garrison":garrison=item
	assert_float(float(population.field.observed_low)).is_equal(180.0)
	assert_float(float(population.field.observed_high)).is_equal(220.0)
	assert_dict(garrison.field).is_empty()
	var dossier:Control=auto_free(Dossier.new());add_child(dossier);dossier.setup(selected)
	assert_int(dossier.find_children("ReportedCityView","",true,false).size()).is_equal(1)
	assert_str(_texts(dossier)).contains("Not yet seen:")
	# Hovering metric rows must remain safe after replacing the old Sketch node.
	for row:Node in dossier.find_children("*","PanelContainer",true,false):
		row.emit_signal("mouse_entered");row.emit_signal("mouse_exited")

func test_dated_dossier_update_keeps_portrait_and_refreshes_rows_until_new_evidence()->void:
	var report:=_report()
	var block:Dictionary={"report":report,"fresh_status":"Aging","fresh_age":"about a year ago",
		"caption":"Held by the Reed People","source":"our returning scout","account":"The original account.",
		"items":[{"key":"population","name":"Population","value":"180–220","field":report.fields.population,"own":100.0}]}
	# A real dossier lives in a panel with a fixed width. An unsized standalone
	# VBox instead follows the longest label, legitimately resizing its portrait.
	var dossier:Control=auto_free(Dossier.new());dossier.size=Vector2(900,1100)
	add_child(dossier);dossier.setup(block)
	for frame in 4:await get_tree().process_frame
	var portrait:Control=dossier.get("portrait")
	var model:Node3D=portrait.get("model")
	var view:SubViewport=portrait.get("view")
	var old_rows:Node=dossier.get("report_body")
	var stats:Dictionary=portrait.stats()
	var portrait_size:Vector2=(portrait.get("picture") as TextureRect).size
	var viewport_size:Vector2i=view.size
	assert_float(portrait_size.x).is_equal(900.0)
	await get_tree().process_frame
	assert_int(int(portrait.stats().viewport_updates)).is_equal(int(stats.viewport_updates))
	var updated:=block.duplicate(true)
	updated.fresh_status="Stale";updated.fresh_age="about two years ago"
	updated.source="our second returning scout";updated.account="The refreshed account."
	updated.caption="Held by the River People"
	updated.report.name="Reedbank, as later reported";updated.report.source=updated.source
	updated.report.controller="river-people"
	updated.report.fields.population.low=0.0;updated.report.fields.population.high=8000.0
	updated.items[0].value="A wider planning range"
	assert_bool(dossier.update_block(updated)).is_true()
	assert_object(dossier.get("portrait")).is_same(portrait)
	assert_object(portrait.get("model")).is_same(model)
	assert_object(portrait.get("view")).is_same(view)
	assert_object(dossier.get("report_body")).is_not_same(old_rows)
	assert_str(_texts(dossier)).contains("The refreshed account.").contains("A wider planning range").contains("Stale")
	assert_str(_texts(dossier)).not_contains("The original account.")
	assert_str(String(portrait.get("frozen_report").name)).is_equal("Reedbank, as later reported")
	assert_int(Foreign.display_population(portrait.get("frozen_report"))).is_equal(200)
	for frame in 3:await get_tree().process_frame
	assert_vector((portrait.get("picture") as TextureRect).size).is_equal(portrait_size)
	assert_vector(view.size).is_equal(viewport_size)
	assert_int(int(portrait.stats().model_builds)).is_equal(int(stats.model_builds))
	assert_int(int(portrait.stats().viewport_updates)).is_equal(int(stats.viewport_updates))
	var retained_rows:Node=dossier.get("report_body")
	var new_evidence:=updated.duplicate(true)
	new_evidence.report.fields.population.observed_high=400.0
	assert_bool(dossier.update_block(new_evidence)).is_false()
	assert_object(dossier.get("portrait")).is_same(portrait)
	assert_object(dossier.get("report_body")).is_same(retained_rows)
	assert_int(Foreign.display_population(portrait.get("frozen_report"))).is_equal(200)

func test_framing_buttons_reuse_model_and_ground_and_whole_town_fits_buildings()->void:
	var map:MapFixture=auto_free(MapFixture.new());add_child(map)
	var report:=_report();report.fields.population=_field(8000,8000)
	var widget:Control=auto_free(View.new());widget.size=Vector2(900,650);add_child(widget)
	widget.setup({"report":report,"terrain":map})
	for frame in 4:await get_tree().process_frame
	var center:Button=widget.get_node("ReportFraming/TownCenter")
	var whole:Button=widget.get_node("ReportFraming/WholeTown")
	var model:Node3D=widget.get("model")
	var camera:Camera3D=widget.get("camera")
	var view:SubViewport=widget.get("view")
	var stats:Dictionary=widget.stats()
	var center_span:=camera.size
	var center_transform:=camera.transform
	assert_bool(widget.get("whole_town")).is_false()
	# Repeated clicks while the selected mode is unchanged do no work.
	center.emit_signal("pressed");center.emit_signal("pressed")
	await get_tree().process_frame
	assert_int(int(widget.stats().viewport_updates)).is_equal(int(stats.viewport_updates))
	whole.emit_signal("pressed");whole.emit_signal("pressed")
	await get_tree().process_frame
	assert_bool(widget.get("whole_town")).is_true()
	assert_float(camera.size).is_greater(center_span)
	assert_float(center_span/camera.size).is_equal_approx(.35,.00001)
	assert_vector(camera.position).is_equal(center_transform.origin)
	assert_int(int(widget.stats().viewport_updates)).is_equal(int(stats.viewport_updates)+1)
	# Check every actual building corner against the orthographic image, not
	# an implementation-only zoom flag or the looser shared world-axis box.
	var half_height:=camera.size*.5
	var half_width:=half_height*float(view.size.x)/float(view.size.y)
	var greatest_x:=0.0;var greatest_y:=0.0;var corners:=0
	var inverse:=camera.transform.affine_inverse()
	for child:Node in model.get_children():
		if not child is MultiMeshInstance3D or not String(child.name).begins_with("ForeignHouses_"):continue
		var bounds:AABB=child.multimesh.mesh.get_aabb()
		for placed:Transform3D in child.get_meta("source_transforms",[]):
			for index in 8:
				var point:Vector3=inverse*(placed*bounds.get_endpoint(index))
				greatest_x=maxf(greatest_x,absf(point.x));greatest_y=maxf(greatest_y,absf(point.y));corners+=1
	assert_int(corners).is_greater(0)
	assert_float(greatest_x).is_less(half_width)
	assert_float(greatest_y).is_less(half_height)
	center.emit_signal("pressed");center.emit_signal("pressed")
	await get_tree().process_frame
	assert_bool(widget.get("whole_town")).is_false()
	assert_float(camera.size).is_equal_approx(center_span,.000001)
	assert_int(int(widget.stats().viewport_updates)).is_equal(int(stats.viewport_updates)+2)
	assert_object(widget.get("model")).is_same(model)
	assert_int(int(widget.stats().model_builds)).is_equal(int(stats.model_builds))
	assert_int(int(widget.stats().height_samples)).is_equal(int(stats.height_samples))
	assert_int(map.sampled.size()).is_equal(int(stats.height_samples))
	for frame in 2:await get_tree().process_frame
	assert_int(int(widget.stats().viewport_updates)).is_equal(int(stats.viewport_updates)+2)
