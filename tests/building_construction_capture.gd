extends "res://tests/people_grown_land_capture.gd"
## Prepared plot specimens on real saved terrain, never campaign-history claims.
## --construction-capture --save=<read-only copy> [--frames=120]
## Baseline renderer files are separately frozen from the recorded Git base.
const Early:=preload("res://scripts/early_settlement_visual.gd")
const Keys:=preload("res://scripts/settlement_visual_keys.gd")
const Country:=preload("res://scripts/settlement_country_visual.gd")
const Patches:=preload("res://scripts/settlement_patch_renderer.gd")
var failures:Array[String]=[]
var images:Dictionary={}
var output:="res://artifacts/building-construction"
var specimens:Array[Dictionary]=[]
var roads:Array[Dictionary]=[]
var specimen_plan:Dictionary={}
var origin:=Vector3.ZERO
var title:Label
var label_layer:CanvasLayer

func _check(ok:bool,message:String)->void:
	if not ok:failures.append(message);push_error(message)

func _run()->void:
	if "--construction-capture" not in OS.get_cmdline_user_args() or DisplayServer.get_name()=="headless" or not ProjectSettings.globalize_path("user://").contains("TomorrowPeopleGrownLandQA"):
		get_tree().quit(2);return
	output=_arg("out",output);DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	var baseline_path:="res://artifacts/building-construction/baseline/"
	if not FileAccess.file_exists(baseline_path+"early_settlement_visual.gd"):
		_check(false,"Frozen renderer baseline is missing");get_tree().quit(2);return
	var old_early:Script=load(baseline_path+"early_settlement_visual.gd")
	var old_country:Script=load(baseline_path+"settlement_country_visual.gd")
	var source:=_arg("save","res://artifacts/wall-scale/current.save")
	var saves:=Snapshot.new();saves.source=source;add_child(saves)
	var loaded:Dictionary=saves.load_game("copy")
	if loaded.has("error"):_check(false,str(loaded));get_tree().quit(2);return
	GameState.civic_api_enabled=false
	for node in get_tree().root.get_children():
		if node!=self:node.set_process(false);node.set_physics_process(false)
	terrain=load("res://local_terrain.tscn").instantiate();add_child(terrain);terrain._set_game_speed(0)
	print("CONSTRUCTION_CAPTURE_SOURCE_LOADED")
	origin=GameState.settlement_founded_at
	get_window().size=Vector2i(1600,900);get_window().content_scale_size=Vector2i(1600,900)
	var deadline:=Time.get_ticks_msec()+90000
	while not terrain.macro_render.ready() and Time.get_ticks_msec()<deadline:await get_tree().process_frame
	terrain.set_camera_distance_level(0);terrain.zoom_target_size=-1.0;terrain.zoom_preset_active=false
	_set_camera(.16,origin)
	await _settle()
	# Freeze the settled background queue during like-for-like geometry timing.
	# Full live map-loop timing is recorded separately after the panel comparison.
	terrain.set_process(false)
	for layer:CanvasLayer in get_tree().root.find_children("*","CanvasLayer",true,false):layer.visible=false
	# Hide normal settlement drawing only while the explicitly labelled specimen
	# is reviewed at the same cleared core; the final context image restores it.
	var hidden:Array[Node3D]=[]
	for field:String in ["settlement_visual_root","settlement_land_use_root","settlement_network_fabric_root","settlement_border_root","settlement_network_marker_root","country_land"]:
		var node:Node3D=terrain.get(field)
		if is_instance_valid(node) and node.visible:hidden.append(node);node.visible=false
	_prepare_specimens()
	label_layer=CanvasLayer.new();label_layer.layer=100;add_child(label_layer)
	title=Label.new();title.position=Vector2(22,14);title.add_theme_font_size_override("font_size",20)
	title.add_theme_color_override("font_color",Color("f5ead4"));title.add_theme_color_override("font_shadow_color",Color.BLACK)
	title.add_theme_constant_override("shadow_offset_x",2);title.add_theme_constant_override("shadow_offset_y",2);label_layer.add_child(title)
	var specimen_hash:=hash(var_to_bytes(specimens))
	report={"scope":"Prepared early/later construction specimens on genuine saved terrain, not historical campaign checkpoints","timing_scope":"Identical frozen map background for renderer comparisons; separate live settled map loop sample","source":source,"source_sha256":FileAccess.get_sha256(source),"baseline_commit":"670a4fee","fixture_hash":specimen_hash,"plot_count":specimens.size(),"population":GameState.population_total,"day":GameState.elapsed_days,"origin":str(origin),"comparisons":[],"failures":failures}
	var rid:=get_viewport().get_viewport_rid();RenderingServer.viewport_set_measure_render_time(rid,true)
	for entry:String in ["root","expansion"]:
		for version:String in ["before","after"]:
			var parent:=Node3D.new();parent.name="ConstructionSpecimen";terrain.add_child(parent)
			var start:=Time.get_ticks_usec()
			var renderer:Node3D
			if entry=="root":
				if version=="before":old_early.call("render",specimen_plan,origin,_height,parent)
				else:Early.render(specimen_plan,origin,_height,parent)
			else:
				renderer=old_country.new() if version=="before" else Country.new();terrain.add_child(renderer)
				renderer.configure(func(point:Vector2)->float:return _height(point.x,point.y),_world_land)
				var record:Dictionary={"id":"construction-review","kind":"cluster","group":"homesteads","position":Vector2(origin.x,origin.z),"settlement_plots":specimens.duplicate(true),"settlement_routes":roads.duplicate(true),"track_from":Vector2(origin.x,origin.z)}
				renderer._build_patch(parent,record,{"style":{},"road_tier":0})
			var build_usec:=Time.get_ticks_usec()-start
			title.text="TEST SPECIMEN | %s %s | saved terrain | four recorded stages + complete\nTop row: timber household. Bottom row: masonry courtyard. Work: 10%% / 35%% / 60%% / 85%% / active." % [version,entry]
			for frame in 120:await get_tree().process_frame
			var timed:Dictionary=await _measure_frames(int(_arg("frames","120")))
			await RenderingServer.frame_post_draw
			images[version+"_"+entry]=get_viewport().get_texture().get_image()
			var audit:=_geometry(parent)
			report.comparisons.append({"version":version,"entry":entry,"build_usec":build_usec,"timing":timed,"geometry":audit})
			if version=="after":
				_check((audit.get("stages",[]) as Array).size()==4,entry+": all4 construction stages must render")
				_check(int(audit.instances)>0,entry+": production mesh instances missing")
			print("CONSTRUCTION_CAPTURE ",version," ",entry," ",JSON.stringify(timed)," geometry=",JSON.stringify(audit))
			parent.queue_free()
			if renderer!=null:renderer.queue_free()
			for frame in 4:await get_tree().process_frame
	report["reuse"]=await _retention_check()
	_check(hash(var_to_bytes(specimens))==specimen_hash,"Renderer mutated prepared plot specimen")
	for node:Node3D in hidden:
		if is_instance_valid(node):node.visible=true
	terrain.set_process(true)
	_set_camera(.75,origin);await _settle()
	title.text="TEST REVIEW | Actual loaded settlement context | %d people | no population or campaign-time edits" % GameState.population_total
	for frame in 120:await get_tree().process_frame
	report["map_people"]=_map_people_audit()
	report["settled_map_timing"]=await _measure_frames(int(_arg("frames","120")))
	await RenderingServer.frame_post_draw;images["in_map_context"]=get_viewport().get_texture().get_image()
	# Encoding happens only after every measurement window has ended.
	for key:String in images:(images[key] as Image).save_png(ProjectSettings.globalize_path(output.path_join(key+".png")))
	report["failures"]=failures;report["passed"]=failures.is_empty()
	_write(output.path_join("capture-audit.json"),report)
	print("CONSTRUCTION_CAPTURE_DONE ","PASS" if failures.is_empty() else "FAIL")
	get_tree().quit(0 if failures.is_empty() else 1)

func _world_land(point:Vector2)->bool:return terrain._settlement_stage_land_at(point)
func _local_land(point:Vector2)->bool:return _world_land(Vector2(origin.x,origin.z)+point)
func _height(x:float,z:float)->float:return terrain._close_surface_height_at(x,z)

func _settle()->void:
	var deadline:=Time.get_ticks_msec()+35000
	var frames:=0
	while frames<90 or terrain.terrain_patch_job!=null or int(terrain.settlement_patch_stats().get("pending",0))>0:
		await get_tree().process_frame;frames+=1
		if Time.get_ticks_msec()>deadline:break
	_check(terrain.terrain_patch_job==null,"Terrain job did not settle")

func _prepare_specimens()->void:
	for row in 2:
		for column in 5:
			var center:=Vector2((column-2)*.038,(row-.5)*.07)
			var polygon:=PackedVector2Array([Vector2(-.017,-.025),Vector2(.017,-.025),Vector2(.017,.025),Vector2(-.017,.025)])
			for index in polygon.size():polygon[index]+=center
			var plot:Dictionary={"id":row*5+column+1,"seed":91,"centroid":center,"polygon":polygon,"frontage_route_id":row+1,"area_ha":.17,"roof_coverage":.1,"resident_count":5,"material_family":"organic" if row==0 else "earth","land_use":"residential_compound","form":"timber_household" if row==0 else "compact_courtyard_row","roof_plan":"timber_ridge" if row==0 else "courtyard_flat","status":"active" if column==4 else "under_construction","construction_progress":1.0 if column==4 else .1+column*.25,"condition":.9,"storeys":1}
			plot["fabric_generation"]=0 if row==0 else 6
			specimens.append(plot)
		roads.append({"id":row+1,"kind":"camp_path","width_m":.6,"points":PackedVector2Array([Vector2(-.1,(row-.5)*.07-.022),Vector2(.1,(row-.5)*.07-.022)])})
	specimen_plan=Early.layout(specimens,roads,_local_land)
	var represented:Dictionary={}
	for building:Dictionary in specimen_plan.get("buildings",[]):represented[int(building.plot_id)]=true
	for plot:Dictionary in specimens:_check(represented.has(int(plot.id)),"Real land/layout omitted specimen plot%d (%s)" % [plot.id,plot.form])

func _measure_frames(count:int)->Dictionary:
	var wall:Array[float]=[];var process:Array[float]=[];var cpu:Array[float]=[];var gpu:Array[float]=[];var draws:Array[float]=[]
	var rid:=get_viewport().get_viewport_rid();var last:=Time.get_ticks_usec()
	for frame in count:
		await get_tree().process_frame
		var now:=Time.get_ticks_usec();wall.append(float(now-last)/1000.0);last=now
		process.append(Performance.get_monitor(Performance.TIME_PROCESS)*1000.0)
		cpu.append(RenderingServer.viewport_get_measured_render_time_cpu(rid));gpu.append(RenderingServer.viewport_get_measured_render_time_gpu(rid))
		draws.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	return {"frames":count,"wall_ms":_distribution(wall),"process_ms":_distribution(process),"render_cpu_ms":_distribution(cpu),"render_gpu_ms":_distribution(gpu),"gpu_timer_supported":gpu.max()>0.0,"draw_calls":_distribution(draws),"encoding_during_measurement":false}

func _distribution(values:Array[float])->Dictionary:
	var sorted:=values.duplicate();sorted.sort();var sum:=0.0
	for value:float in values:sum+=value
	return {"mean":sum/maxi(1,values.size()),"p50":sorted[sorted.size()/2],"p95":sorted[mini(sorted.size()-1,floori(sorted.size()*.95))],"max":sorted[-1]}

func _geometry(parent:Node)->Dictionary:
	var stages:Array=[];var instances:=0;var batches:=0;var vertices:=0
	for node:MultiMeshInstance3D in parent.find_children("*","MultiMeshInstance3D",true,false):
		batches+=1;instances+=node.multimesh.instance_count
		if node.has_meta("construction_stage") and int(node.get_meta("construction_stage")) not in stages:stages.append(int(node.get_meta("construction_stage")))
		var mesh:Mesh=node.multimesh.mesh
		for surface in mesh.get_surface_count():
			var arrays:Array=mesh.surface_get_arrays(surface)
			if arrays.size()>Mesh.ARRAY_VERTEX and arrays[Mesh.ARRAY_VERTEX]!=null:vertices+=(arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()*node.multimesh.instance_count
	stages.sort()
	return {"stages":stages,"batches":batches,"instances":instances,"submitted_vertices":vertices}

func _draw_retained(parent:Node3D,plan:Dictionary)->void:Early.render(plan,origin,_height,parent)

func _retention_check()->Dictionary:
	var plot:Dictionary=specimens[0].duplicate(true);plot.construction_progress=.27
	var plots:Array[Dictionary]=[plot];var plan:=Early.layout(plots,roads,_local_land)
	var holder:=Node3D.new();terrain.add_child(holder);holder.visible=false
	var patches:=Patches.new(holder)
	var entries:Array[Dictionary]=[{"key":"review","signature":Keys.appearance(plot),"build":_draw_retained.bind(plan)}]
	patches.request(entries);patches.process(100000,1)
	var first_id:int=patches.installed.review.node.get_instance_id();var first_builds:=patches.builds
	var start:=Time.get_ticks_usec()
	for value:float in [.28,.32,.38,.44,.49]:
		plot.construction_progress=value;entries[0].signature=Keys.appearance(plot)
		entries[0].build=_draw_retained.bind(Keys.refresh_plan(plan,plots));patches.request(entries);patches.process(4000,1)
	var same_stage_usec:=Time.get_ticks_usec()-start
	_check(patches.builds==first_builds and patches.installed.review.node.get_instance_id()==first_id,"Within-stage progress rebuilt retained geometry")
	plot.construction_progress=.5;entries[0].signature=Keys.appearance(plot);entries[0].build=_draw_retained.bind(Keys.refresh_plan(plan,plots))
	patches.request(entries);patches.process(100000,1)
	_check(patches.builds==first_builds+1,"Threshold progress did not rebuild exactly one patch")
	var result:Dictionary={"initial_builds":first_builds,"within_stage_builds":first_builds,"within_stage_request_usec":same_stage_usec,"within_stage_requests":5,"after_threshold_builds":patches.builds,"node_changed_at_threshold":patches.installed.review.node.get_instance_id()!=first_id,"stats":patches.stats()}
	holder.queue_free();await get_tree().process_frame
	return result
