extends Node

const TERRAIN_SCENE:=preload("res://local_terrain.tscn")
const PRESENTATION:=preload("res://scripts/warfare_map_presentation.gd")
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
		var label:=marker.get_node("ArmyLabel") as Label3D
		var arrow:=marker.get_node("HeadingChevron") as MeshInstance3D
		var arrow_arrays:=arrow.mesh.surface_get_arrays(0)
		_expect((arrow_arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()==24,"direction arrow exceeds triangular prism vertex budget")
		var arrow_normals:PackedVector3Array=arrow_arrays[Mesh.ARRAY_NORMAL]
		_expect(arrow_normals[0].y>0.99 and arrow_normals[3].y< -0.99,"direction arrow cap winding is inverted: %s / %s" % [arrow_normals[0],arrow_normals[3]])
		for direction in [Vector2.RIGHT,Vector2.LEFT,Vector2.UP,Vector2.DOWN]:
			var moving_army:=army.duplicate(true)
			moving_army.status="moving"
			moving_army.position={"x":0.0,"z":0.0}
			moving_army.destination_position={"x":direction.x,"z":direction.y}
			terrain._apply_warfare_formation_view(marker,PRESENTATION.player_marker(moving_army,320.0,true))
			var tip_direction:=arrow.basis*Vector3.FORWARD
			_expect(tip_direction.dot(Vector3(direction.x,0,direction.y))>0.999,"moving arrow points away from its destination")
		terrain._apply_warfare_formation_view(marker,PRESENTATION.player_marker(army,320.0,true))
		_expect("YOU" in label.text and "8.0K" in label.text and "FORMING" in label.text,"player marker omits owner, aggregate strength, or readiness")
		terrain._apply_warfare_formation_view(marker,PRESENTATION.player_marker(army,320.0,true))
		_expect((marker.get_node("SelectedRing") as MeshInstance3D).visible,"selected army has no distinct selection halo")
		_expect(label.global_transform.basis.get_scale().is_equal_approx(Vector3.ONE),"army label inherits the regional marker scale")
		_expect(_render_element_count(marker)<=16,"one aggregate player icon exceeds the fixed render-element budget")
		_expect(marker.get_node_or_null("RoleGlyphPrimary")!=null and marker.get_node_or_null("RoleGlyphFourth")!=null,"aggregate icon is missing its reusable silhouette parts")
		_expect((marker.get_node("StrengthLabel") as Label3D).text=="8.0K","army icon has no explicit compact soldier count")
		_expect(marker.get_node_or_null("CommandSpine")==null,"counter retains a bar obscuring the centered weapon")
		_expect(marker.get_node_or_null("RoleInfantryA")==null and marker.get_node_or_null("RoleArmoredHull")==null,"aggregate counter still retains dormant role-specific branches")
		for historical_unit in ["levy","line_infantry","skirmisher","cavalry","siege_engineer","field_artillery","rifle_infantry","machine_gun_company","motorized_infantry","armored_formation","modern_artillery"]:
			terrain._configure_warfare_role_glyph(marker,"infantry",historical_unit)
			_expect(String(marker.get_meta("formation_icon",""))==historical_unit,"%s has no distinct military icon mapping" % historical_unit)
			var visible_icon_parts:=0
			for glyph_name in ["RoleGlyphPrimary","RoleGlyphSecondary","RoleGlyphTertiary","RoleGlyphFourth"]:
				if (marker.get_node(glyph_name) as MeshInstance3D).visible: visible_icon_parts+=1
			_expect(visible_icon_parts>=1,"%s icon has no visible silhouette" % historical_unit)
		var damaged_army:=army.duplicate(true)
		damaged_army["readiness"]=0.18
		damaged_army["wounded_pool"]=8000
		damaged_army["formations"]=[{"unit":"modern_artillery","count":8000,"equipment_condition":0.30}]
		terrain._apply_warfare_formation_view(marker,PRESENTATION.player_marker(damaged_army,320.0,true))
		var damage_scars:=marker.get_node("DamageScars") as MultiMeshInstance3D
		_expect(damage_scars.multimesh.visible_instance_count>=2,"severe formation damage has no bounded scar cue")
		_expect((marker.get_node("ReadinessPip") as MeshInstance3D).scale.z<0.45,"broken readiness does not visibly shorten the edge readiness tab")
		_expect((marker.get_node("RoleGlyphPrimary") as MeshInstance3D).visible,"composition role disappears when damage/readiness changes")
		terrain._apply_warfare_formation_view(marker,PRESENTATION.player_marker(army,320.0,true))
	if marker:
		for icon_unit in ["line_infantry","cavalry","siege_engineer","field_artillery","motorized_infantry","armored_formation"]:
			var icon_army:=army.duplicate(true)
			icon_army.formations=[{"unit":icon_unit,"count":8000}]
			var icon_view:=PRESENTATION.player_marker(icon_army,320.0,true)
			terrain._apply_warfare_formation_view(marker,icon_view)
			var primary:=marker.get_node("RoleGlyphPrimary") as MeshInstance3D
			var positions:Dictionary={}
			for part_name in ["RoleGlyphPrimary","RoleGlyphSecondary","RoleGlyphTertiary","RoleGlyphFourth"]:
				var part:=marker.get_node(part_name) as MeshInstance3D
				positions[part_name]=part.position
				var expected:Vector3=Vector3(part.get_meta("glyph_base_position"))-Vector3(primary.get_meta("glyph_base_position"))
				_expect((part.position-primary.position).is_equal_approx(expected),"%s lost authored offsets for %s" % [icon_unit,part_name])
			terrain._apply_warfare_formation_view(marker,icon_view)
			for part_name in positions:
				_expect((marker.get_node(part_name) as Node3D).position.is_equal_approx(positions[part_name]),"%s icon drifts on repeated updates" % icon_unit)
			icon_army.readiness=0.1
			terrain._apply_warfare_formation_view(marker,PRESENTATION.player_marker(icon_army,320.0,true))
			for part_name in positions:
				var part:=marker.get_node(part_name) as Node3D
				var expected:Vector3=Vector3(positions[part_name])-Vector3(positions["RoleGlyphPrimary"])
				_expect((part.position-primary.position).is_equal_approx(expected),"broken readiness collapses %s silhouette" % icon_unit)
	var foreign_counter:Node3D=terrain._create_warfare_formation_marker("ForeignBudgetProbe",false)
	terrain.add_child(foreign_counter)
	var foreign_view:Dictionary=PRESENTATION.foreign_marker({"id":"foreign_probe","civilization":"Cedar League","identified":true,"hostile":true,"strength_estimate_low":900,"strength_estimate_high":1500,"readiness_estimate_low":0.42,"readiness_estimate_high":0.66,"formation_role":"armored","formation_era":3,"damage_estimate":0.36,"position":{"x":origin.x+8.0,"z":origin.z+8.0}},320.0)
	terrain._apply_warfare_formation_view(foreign_counter,foreign_view)
	for counter in [marker,foreign_counter]:
		for part in counter.get_children():
			if part is Label3D:
				_expect(part.render_priority==32,"counter label is not above map-symbol materials")
			elif part is GeometryInstance3D:
				var material:=part.material_override as StandardMaterial3D
				_expect(material!=null,"counter part lacks an explicit material")
				if material:
					_expect(material.transparency==BaseMaterial3D.TRANSPARENCY_ALPHA,"opaque counter part can be overdrawn by transparent roofs")
					_expect(material.render_priority>=17 and material.render_priority<=26,"counter part escaped its above-roof priority band")
		var plate_name:String="ArmyPlate" if counter==marker else "ObservationPlate"
		var plate_material:Material=counter.get_node(plate_name).material_override
		_expect(counter.get_node("CounterBorder").material_override.render_priority<plate_material.render_priority,"counter border covers its plate")
		_expect(counter.get_node("RoleGlyphPrimary").material_override.render_priority>plate_material.render_priority,"counter plate covers its weapon")
	_expect(_render_element_count(foreign_counter)<=17,"one observed foreign icon exceeds the fixed render-element budget")
	_expect((foreign_counter.get_node("RoleGlyphSecondary") as MeshInstance3D).visible,"identified foreign composition does not reach the aggregate role glyph")
	foreign_counter.queue_free()
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
	var front:={"id":"front_probe","war_name":"War of North Crossing","opponent":"Cedar League","target_region_id":"probe_objective","target":"North Crossing","objective":"Take North Crossing","progress":0.36,"field_personnel":8000,"inbound_personnel":0,"occupation_personnel":0,"readiness":0.62,"supply":0.58}
	var destination:={"position":{"x":origin.x,"z":origin.z}}
	terrain._refresh_warfare_front_markers([PRESENTATION.front_marker(front,destination,320.0,true)])
	var front_marker:Node3D=terrain.warfare_front_markers.get("front_probe",null)
	_expect(front_marker!=null and front_marker.visible,"active engagement/front marker is absent at regional scale")
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
		_expect(grounded_front!=null and grounded_front.visible,"local front disappeared during ground-clearance update")
		if grounded_front:
			var lift:float=grounded_front.position.y-terrain._height_at(grounded_front.position.x,grounded_front.position.z)
			_expect(absf(lift-PRESENTATION.marker_ground_clearance(zoom))<0.00001,"front does not use zoom-aware ground clearance")
	terrain.camera.size=12_000.0
	terrain._refresh_player_field_army_markers()
	marker=terrain.player_field_army_markers.get("1",null)
	_expect(marker!=null and not marker.visible,"world scale still renders individual army detail")
	terrain._refresh_warfare_front_markers([PRESENTATION.front_marker(front,destination,12_000.0,true)])
	front_marker=terrain.warfare_front_markers.get("front_probe",null)
	_expect(front_marker!=null and front_marker.visible,"world scale lost aggregate strategic war state")
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
	_expect(stacked_labels==1,"co-located regional armies did not collapse to one aggregate label")
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
		var compact_label:=grounded_counter.get_node("StrengthLabel") as Label3D
		var view:=PRESENTATION.player_marker(reported_army,1.0,true)
		view["show_label"]=true
		var saved_label_position:=detail_label.position
		var pill:Control=terrain.hud.time_pill
		detail_label.global_position=terrain.camera.project_position(pill.get_global_rect().get_center(),2.0)
		terrain._apply_warfare_formation_view(grounded_counter,view)
		_expect(not detail_label.visible and compact_label.visible,"HUD-obscured army label loses its compact strength fallback")
		detail_label.global_position=terrain.camera.project_position(get_viewport().get_visible_rect().get_center(),2.0)
		terrain._apply_warfare_formation_view(grounded_counter,view)
		_expect(detail_label.visible and not compact_label.visible,"clear army label does not return after leaving HUD obstruction")
		detail_label.position=saved_label_position
		var saved_yaw:float=terrain.camera_yaw
		for yaw in [0.0,1.2,2.6]:
			terrain.camera_yaw=yaw
			terrain._update_camera()
			terrain._apply_warfare_formation_view(grounded_counter,view)
			var counter_screen:Vector2=terrain.camera.unproject_position(grounded_counter.global_position)
			var count_screen:Vector2=terrain.camera.unproject_position(compact_label.global_position)
			_expect(count_screen.y>counter_screen.y,"troop count stops sitting below counter after camera rotation")
		terrain.camera_yaw=saved_yaw
		terrain._update_camera()
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
