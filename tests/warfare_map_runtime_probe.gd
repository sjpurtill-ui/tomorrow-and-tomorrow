extends Node

const TERRAIN_SCENE:=preload("res://local_terrain.tscn")
const PRESENTATION:=preload("res://scripts/warfare_map_presentation.gd")
const ARMY_MARKS:=preload("res://scripts/hud/army_marks.gd")
var failures:Array[String]=[]


func _ready()->void:
	GameState.reset_for_new_world(830177)
	DiscoverySystem.reset_for_new_world()
	ResourceSystem.reset_for_new_world()
	FoodSystem.reset_for_new_world()
	CivilizationSystem.reset_for_new_world()
	MilitaryCampaign.reset_for_new_world()
	GameState.select_founding_focus("security")
	var terrain:=TERRAIN_SCENE.instantiate()
	add_child(terrain)
	await get_tree().process_frame
	await get_tree().process_frame
	var origin:Vector3=terrain.world_start_position
	var army:=_army(1,origin)
	MilitaryCampaign.field_armies.clear(); MilitaryCampaign.field_armies.append(army)
	terrain.camera.size=320.0
	terrain._refresh_player_field_army_markers()
	_expect(terrain.player_field_army_markers.size()==1,"one aggregate army did not create exactly one marker")
	var marker:Node3D=terrain.player_field_army_markers.get("1",null)
	_expect(marker!=null and marker.visible,"regional player army marker is absent")
	if marker:
		# The world keeps only where the force stands (and its ground up close):
		# its mark, card and selection are inked by the war chart.
		for part in marker.get_children():
			_expect(not (part is MeshInstance3D or part is MultiMeshInstance3D),"a 3D counter plate or glyph survives on the map: %s" % part.name)
		var label:=marker.get_node("ArmyLabel") as Label3D
		_expect(not label.visible,"a world-space army label shows above the close view")
		_expect("about 8,000" in label.text and not "8.0K" in label.text and not "READY" in label.text,"army label is not plain words: %s" % label.text)
		_expect(label.global_transform.basis.get_scale().is_equal_approx(Vector3.ONE),"army label inherits the regional marker scale")
		_expect(_render_element_count(marker)<=4,"one aggregate army keeps more than a position and a label in the world")
	var chart:Control=terrain.get_node_or_null("WarMapMarks/WarFrontOverlay")
	_expect(chart!=null,"the war chart that draws the force marks is missing")
	if chart:
		terrain.camera_target=origin
		terrain._update_camera()
		chart.set_scene(chart.compose(chart.collect()),true)
		chart.queue_redraw()
		await get_tree().process_frame
		await get_tree().process_frame
		var at:Vector2=chart.mark_screen_position("ours","1")
		_expect(at.is_finite(),"the war chart drew no mark for the army")
		if at.is_finite():
			var drawn:Dictionary=(chart.drawn_marks as Array)[0]
			_expect(is_equal_approx(float(drawn.size),ARMY_MARKS.size_px("regional",String(drawn.kind))),"the army mark is not sized for its zoom band")
			terrain._clear_army_selection()
			_expect(terrain._select_field_army_from_screen(at) and terrain.selected_army_id==1,"clicking the army mark does not select the army")
	army["status"]="moving"
	army["destination_id"]="probe_objective"
	army["destination_name"]="North Crossing"
	army["destination_position"]={"x":origin.x+12.0,"z":origin.z+6.0}
	army["distance_total_km"]=13.4
	army["distance_remaining_km"]=9.2
	army["arrival_day"]=18
	MilitaryCampaign.field_armies[0]=army
	terrain._refresh_player_field_army_markers()
	_expect(terrain.player_field_army_paths.size()==1,"moving army has no bounded movement path")
	var path:Node3D=terrain.player_field_army_paths.get("1",null)
	_expect(path!=null and path.visible and path.get_node_or_null("MovementPath")!=null and path.get_node_or_null("MovementObjective")!=null,"movement path omits route or objective")
	if path:
		var objective_label:=path.get_node("MovementObjective/ObjectiveLabel") as Label3D
		_expect(objective_label.global_transform.basis.get_scale().is_equal_approx(Vector3.ONE),"movement objective label inherits the objective marker scale")
	var previous_path_id:=0
	for zoom in [8.0,20.0,40.0,320.0]:
		terrain.camera.size=zoom
		terrain._refresh_player_field_army_markers()
		var scaled_path:Node3D=terrain.player_field_army_paths.get("1")
		var path_id:=scaled_path.get_instance_id()
		_expect(path_id!=previous_path_id,"army path retains a different zoom's width")
		previous_path_id=path_id
		_expect(is_equal_approx(float(scaled_path.get_meta("route_scale")),PRESENTATION.marker_scale(zoom)),"army path scale exceeds its presentation scale")
		var objective:Node3D=scaled_path.get_node("MovementObjective")
		var lift:float=objective.position.y-terrain._close_surface_height_at(objective.position.x,objective.position.z)
		_expect(absf(lift-PRESENTATION.marker_ground_clearance(zoom))<0.00001,"army objective floats above its intended ground point")
		if DisplayServer.get_name()!="headless":
			var arrows:MultiMeshInstance3D=scaled_path.get_node("MarchChevrons")
			_expect(is_equal_approx(arrows.multimesh.get_instance_transform(0).basis.get_scale().x,clampf(PRESENTATION.marker_scale(zoom)*0.86,0.0005,5.4)),"march arrows retain an oversized minimum")
		terrain._refresh_player_field_army_markers()
		_expect(terrain.player_field_army_paths.get("1").get_instance_id()==path_id,"stationary army path rebuilds every frame")
	terrain.camera.size=320.0
	var front:={"id":"front_probe","war_name":"War of North Crossing","opponent":"Cedar League","target_region_id":"probe_objective","target":"North Crossing","objective":"Take North Crossing","progress":0.36,"field_personnel":8000,"inbound_personnel":0,"occupation_personnel":0,"readiness":0.62,"supply":0.58}
	var planned_route:Array=[{"x":origin.x,"z":origin.z},{"x":origin.x,"z":origin.z-0.02}]
	var scout_mission:Dictionary={"mission_id":"scale_probe","ordered_heading":"north","return_day":100000,"route":planned_route.duplicate(true)}
	CivilizationSystem.scout_missions.assign([scout_mission])
	var previous_scout_id:=0
	for zoom in [0.035,0.8,20.0,40.0,320.0]:
		terrain.camera.size=zoom
		terrain._refresh_player_scout_route_markers()
		var scout_marker:Node3D=terrain.player_scout_route_markers.get("scale_probe")
		_expect(scout_marker!=null,"planned scout corridor disappears during zoom")
		if scout_marker:
			var current_id:=scout_marker.get_instance_id()
			_expect(current_id!=previous_scout_id,"scout route retains geometry from a different zoom")
			previous_scout_id=current_id
			var profile:Dictionary=terrain._scout_route_visual_profile(zoom)
			_expect(is_equal_approx(float(scout_marker.get_meta("route_width")),float(profile.width)),"actual scout refresh uses wrong-band width")
			_expect(float(profile.width)/zoom<0.0024,"scout corridor covers excessive screen width")
			_expect(int(scout_marker.get_meta("tick_count",0))<=3,"scout route carries more than three direction ticks")
			_expect(not scout_marker.get_node("ScoutOrderLabel").visible,"scout route details should appear on hover, not as a permanent label")
			var hover:Control=scout_marker.find_child("ScoutRouteOverlay",true,false)
			_expect(hover!=null and "due day" in hover.caption,"scout corridor lost its hover account")
			terrain._refresh_player_scout_route_markers()
			_expect(terrain.player_scout_route_markers.get("scale_probe").get_instance_id()==current_id,"stationary zoom rebuilds the scout route every frame")
	_expect(scout_mission.route==planned_route,"visual refresh changed the ordered route")
	CivilizationSystem.scout_missions.clear()
	terrain._refresh_player_scout_route_markers()
	terrain.camera.size=320.0
	for direction in [Vector2.UP,Vector2.RIGHT,Vector2.DOWN,Vector2.LEFT]:
		var target:Vector3=origin+Vector3(direction.x,0,direction.y)*20.0
		var route:Array=[{"x":origin.x,"z":origin.z},{"x":target.x,"z":target.z}]
		var army_route:Node3D=terrain._create_player_field_army_path({"id":"direction_probe","scale":0.32},origin,target,"local")
		var scout_route:Node3D=terrain._create_player_scout_route_marker({"mission_id":"direction_probe"},route,"local")
		terrain.add_child(army_route)
		terrain.add_child(scout_route)
		for route_node in [army_route,scout_route]:
			for part in route_node.get_children():
				if part is GeometryInstance3D and not part is Label3D:
					var material:Material=part.material_override
					# Scout chart ink is a blended ShaderMaterial (scout_chart_ink.gdshader).
					_expect(material is ShaderMaterial or (material as StandardMaterial3D).transparency==BaseMaterial3D.TRANSPARENCY_ALPHA,"route part can be overdrawn by transparent drapes")
					_expect(material.render_priority>4 and material.render_priority<17,"route escaped its below-counter layer band")
		_expect(army_route.get_node("MarchChevrons").material_override.render_priority>army_route.get_node("MovementPath").material_override.render_priority,"army line covers its arrowheads")
		if scout_route.has_node("ScoutDirectionTicks"): _expect(scout_route.get_node("ScoutDirectionTicks").material_override.render_priority>scout_route.get_node("ScoutCorridor").material_override.render_priority,"scout corridor covers its direction ticks")
		var objective:Node3D=army_route.get_node("MovementObjective")
		_expect(objective.get_node("ObjectiveArrow").material_override.render_priority>objective.get_node("ObjectiveRing").material_override.render_priority,"objective ring covers its pointer")
		for arrows:MultiMeshInstance3D in [army_route.get_node("MarchChevrons")]:
			var vertices:PackedVector3Array=arrows.multimesh.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
			_expect(vertices.size()==24,"route direction marker is not a triangular prism")
			_expect(arrows.multimesh.instance_count==5,"local route exceeded its fixed five arrow budget")
			# The dummy renderer returns identity for MultiMesh transforms. Verify
			# stored directions in the hidden graphical run, not against dummy data.
			if DisplayServer.get_name()!="headless":
				var tip:Vector3=arrows.multimesh.get_instance_transform(0).basis*vertices[1]
				_expect(Vector2(tip.x,tip.z).normalized().dot(direction)>0.999,"%s route arrow points against %s" % [arrows.name,direction])
		army_route.free()
		scout_route.free()
	var destination:={"position":{"x":origin.x,"z":origin.z}}
	terrain._refresh_warfare_front_markers([PRESENTATION.front_marker(front,destination,320.0,true)])
	var front_marker:Node3D=terrain.warfare_front_markers.get("front_probe",null)
	_expect(front_marker!=null and not front_marker.visible,"the old 3D front token must stay hidden; war_map_overlay draws wars")
	if front_marker:
		for wing_name in ["AttackerWing","DefenderWing"]:
			var wing:=front_marker.get_node(wing_name) as MeshInstance3D
			_expect((wing.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()==24,"battle wing is not an explicit triangular arrow")
			var direction:=wing.basis*Vector3.RIGHT
			_expect(direction.x>0.99 if wing_name=="AttackerWing" else direction.x< -0.99,"battle arrows do not point toward contact")
		terrain._configure_warfare_overlay_layers(front_marker)
		for part in front_marker.get_children():
			if part is Label3D:
				_expect(part.render_priority==32,"front label is not above its counter")
			elif part is GeometryInstance3D:
				var material:=part.material_override as StandardMaterial3D
				_expect(material.transparency==BaseMaterial3D.TRANSPARENCY_ALPHA,"front part can be overwritten by roof drapes")
				_expect(material.render_priority>=17 and material.render_priority<=26,"front layer configuration drifts on repeat")
		_expect(front_marker.get_node("FrontPlate").material_override.render_priority<front_marker.get_node("FrontCore").material_override.render_priority,"front plate covers the battle core")
		_expect("BATTLE IN PROGRESS" in (front_marker.get_node("FrontLabel") as Label3D).text,"front marker does not distinguish an active local engagement")
		_expect((front_marker.get_node("FrontLabel") as Label3D).global_transform.basis.get_scale().is_equal_approx(Vector3.ONE),"front label inherits the regional front scale")
	# A fixed 0.20km lift detached fronts from their real ground near local zoom.
	for zoom in [8.0,20.0,320.0]:
		terrain.camera.size=zoom
		terrain._refresh_warfare_front_markers([PRESENTATION.front_marker(front,destination,zoom,true)])
		var grounded_front:Node3D=terrain.warfare_front_markers.get("front_probe",null)
		_expect(grounded_front!=null and not grounded_front.visible,"the old 3D front token must stay hidden; war_map_overlay draws wars")
		if grounded_front:
			var lift:float=grounded_front.position.y-terrain._height_at(grounded_front.position.x,grounded_front.position.z)
			_expect(absf(lift-PRESENTATION.marker_ground_clearance(zoom))<0.00001,"front does not use zoom-aware ground clearance")
	terrain.camera.size=12_000.0
	terrain._refresh_player_field_army_markers()
	marker=terrain.player_field_army_markers.get("1",null)
	_expect(marker!=null and not marker.visible,"world scale still renders individual army detail")
	terrain._refresh_warfare_front_markers([PRESENTATION.front_marker(front,destination,12_000.0,true)])
	front_marker=terrain.warfare_front_markers.get("front_probe",null)
	_expect(front_marker!=null and not front_marker.visible,"the old 3D front token must stay hidden; war_map_overlay draws wars")
	if front_marker:
		_expect("WAR OF NORTH CROSSING" in (front_marker.get_node("FrontLabel") as Label3D).text,"world front marker omits the named war")
	MilitaryCampaign.field_armies.clear()
	for army_id in 24: MilitaryCampaign.field_armies.append(_army(army_id+1,origin))
	terrain.camera.size=320.0
	terrain._refresh_player_field_army_markers()
	_expect(terrain.player_field_army_markers.size()==PRESENTATION.MAX_PLAYER_MARKERS,"renderer exceeded the fixed player-army marker budget")
	var stacked_labels:=0
	for stacked_marker_variant in terrain.player_field_army_markers.values():
		var stacked_marker:=stacked_marker_variant as Node3D
		if stacked_marker and (stacked_marker.get_node("ArmyLabel") as Label3D).visible: stacked_labels+=1
	# Regionally the war chart letters the stack as one card; no world labels.
	_expect(stacked_labels==0,"co-located regional armies still carry world-space labels")
	terrain.camera.size=7.99
	terrain._refresh_player_field_army_markers()
	for close_marker_variant in terrain.player_field_army_markers.values():
		var close_marker:=close_marker_variant as Node3D
		_expect(close_marker.visible,"army icon disappears at close zoom")
		_expect(close_marker.scale.x<0.20,"close-zoom army icon retains an oversized minimum scale")
	for figures:Node3D in terrain.close_army_figures.values():
		_expect(figures.get_node_or_null("Strength")==null,"close figures duplicate the counter's soldier label")
	# The counter and figures must consume the same last-known report. The real
	# army has travelled away; neither zooming nor its ground mesh may expose it.
	var reported_army:=_army(71,origin+Vector3(0.5,0,0))
	reported_army["status"]="moving"
	reported_army["location_id"]="away"
	reported_army["last_report"]={"day":0,"position":{"x":origin.x,"z":origin.z},"status":"stationed","troops":600,"supply_level":0.8}
	MilitaryCampaign.field_armies.assign([reported_army])
	terrain.camera_target=origin
	terrain.camera.size=1.0
	terrain.game_speed=0.0
	_expect(not bool(MilitaryCampaign.field_armies_snapshot().get("live_reports",true)),"report fixture unexpectedly has live military signals")
	terrain._refresh_player_field_army_markers()
	var reported_figures:Node3D=terrain.close_army_figures.get("71",null)
	var grounded_counter:Node3D=terrain.player_field_army_markers.get("71",null)
	if grounded_counter:
		var lift:float=grounded_counter.position.y-terrain._height_at(grounded_counter.position.x,grounded_counter.position.z)
		_expect(lift>0.0 and lift<0.002,"close army counter is floating metres above its formation")
	_expect(reported_figures!=null,"reported army lost its close formation")
	if reported_figures:
		_expect(is_equal_approx(reported_figures.position.x,origin.x) and is_equal_approx(reported_figures.position.z,origin.z),"close figures expose live coordinates instead of the runner report")
		_expect(reported_figures.represented_troops==600,"close figures ignore reported strength")
		_expect(reported_figures.clip=="idle","a stationary report animates as a live moving army")
	_expect(MilitaryCampaign.field_armies[0].position.x==origin.x+0.5,"visual report handling mutated the real army")
	if grounded_counter and terrain.hud:
		terrain._update_camera()
		var detail_label:=grounded_counter.get_node("ArmyLabel") as Label3D
		var view:=PRESENTATION.player_marker(reported_army,1.0,true)
		view["show_label"]=true
		var saved_label_position:=detail_label.position
		var pill:Control=terrain.hud.time_pill
		detail_label.global_position=terrain.camera.project_position(pill.get_global_rect().get_center(),2.0)
		terrain._apply_warfare_formation_view(grounded_counter,view)
		detail_label.global_position=terrain.camera.project_position(pill.get_global_rect().get_center(),2.0)
		_expect(not detail_label.visible or not terrain._warfare_label_has_clear_space(detail_label),"HUD-obscured army label stays drawn over the HUD")
		detail_label.position=saved_label_position
		_expect(not "LAST REPORT" in detail_label.text and not "DAYS OLD" in detail_label.text,"close army label carries report jargon: %s" % detail_label.text)
	if not failures.is_empty():
		for failure in failures: push_error(failure)
		get_tree().quit(1)
		return
	print("WARFARE_MAP_RUNTIME_PROBE PASS markers=%d paths=%d fronts=%d" % [terrain.player_field_army_markers.size(),terrain.player_field_army_paths.size(),terrain.warfare_front_markers.size()])
	get_tree().quit(0)


func _army(army_id:int,origin:Vector3)->Dictionary:
	return {"army_id":army_id,"name":"%d Field Army" % army_id,"troops":8_000,"readiness":0.62,"supply_level":0.74,"status":"stationed","location_id":"player_home","location_name":"HOME","position":{"x":origin.x,"z":origin.z},"destination_id":"","destination_position":{},"distance_remaining_km":0.0,"arrival_day":-1,"formations":[]}


func _expect(condition:bool,message:String)->void:
	if not condition: failures.append(message)


func _render_element_count(root:Node)->int:
	var total:=1 if root is GeometryInstance3D else 0
	for child in root.get_children(): total+=_render_element_count(child)
	return total
