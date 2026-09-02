extends Node3D

const RENDERER:=preload("res://scripts/local_terrain.gd")
const PRESENTATION:=preload("res://scripts/warfare_map_presentation.gd")


func _ready()->void:
	call_deferred("_render_audit")


func _argument(prefix:String,fallback:String)->String:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with(prefix): return argument.trim_prefix(prefix)
	return fallback


func _role_formations(role:String)->Array:
	return {
		"mobile":[{"unit":"motorized_infantry","count":12500}],
		"artillery":[{"unit":"rifle_infantry","count":9000},{"unit":"modern_artillery","count":3500}],
		"armored":[{"unit":"motorized_infantry","count":6500},{"unit":"armored_formation","count":6000}],
		"infantry":[{"unit":"line_infantry","count":12500}]
	}.get(role,[{"unit":"line_infantry","count":12500}])


func _add_urban_audit_ground(audit_zoom:float,condition:String)->void:
	if condition=="open": return
	var conditions:=["great","okay","fine","normal","bad","poor","damaged","destroyed"]
	var condition_index:=conditions.find(condition)
	if condition_index<0: condition_index=3
	var cell:=audit_zoom*0.082
	var retain:float=float([1.0,1.0,0.98,0.95,0.90,0.82,0.54,0.27][condition_index])
	# One batched field is enough to challenge counter readability with dense urban
	# texture. Poor ground remains fully inhabited; only damaged/destroyed states open
	# real holes, mirroring the production settlement condition grammar.
	var blocks:=MultiMeshInstance3D.new()
	blocks.name="UrbanConditionField"
	var block_mesh:=BoxMesh.new(); block_mesh.size=Vector3(cell*0.62,0.08,cell*0.54)
	var block_multimesh:=MultiMesh.new(); block_multimesh.transform_format=MultiMesh.TRANSFORM_3D; block_multimesh.mesh=block_mesh; block_multimesh.instance_count=117
	var visible:=0
	for row in 9:
		for column in 13:
			var survival:=float((row*43+column*71+row*column*11)%101)/100.0
			if survival>retain: continue
			var x:=(float(column)-6.0)*cell
			var z:=(float(row)-4.0)*cell
			var jitter_x:=sin(float(row*17+column*29))*cell*0.11
			var jitter_z:=cos(float(row*31-column*13))*cell*0.09
			var damage_scale:=1.0
			if condition_index>=6: damage_scale=0.48+survival*0.42
			var basis:=Basis(Vector3.UP,(-0.08 if (row+column)%3==0 else 0.05)).scaled(Vector3(0.80+float((row+column)%4)*0.09,1.0,damage_scale))
			block_multimesh.set_instance_transform(visible,Transform3D(basis,Vector3(x+jitter_x,0.05,z+jitter_z)))
			visible+=1
	block_multimesh.visible_instance_count=visible
	blocks.multimesh=block_multimesh
	var block_material:=StandardMaterial3D.new()
	var urban_tones:=["#918b72","#89836b","#807a64","#746f5d","#675f52","#574f46","#493f3b","#332d2c"]
	block_material.albedo_color=Color(urban_tones[condition_index]); block_material.roughness=1.0
	blocks.material_override=block_material
	add_child(blocks)
	var roads:=MultiMeshInstance3D.new()
	roads.name="UrbanRoadField"
	var road_mesh:=BoxMesh.new(); road_mesh.size=Vector3(cell*12.8,0.025,cell*0.16)
	var road_multimesh:=MultiMesh.new(); road_multimesh.transform_format=MultiMesh.TRANSFORM_3D; road_multimesh.mesh=road_mesh; road_multimesh.instance_count=9; road_multimesh.visible_instance_count=9
	for road_index in 9:
		var road_basis:=Basis.IDENTITY.scaled(Vector3(1.0,1.0,0.55 if condition_index>=6 and road_index%3==0 else 1.0))
		road_multimesh.set_instance_transform(road_index,Transform3D(road_basis,Vector3(0.0,0.018,(float(road_index)-4.0)*cell)))
	roads.multimesh=road_multimesh
	var road_material:=StandardMaterial3D.new(); road_material.albedo_color=Color("#262a28" if condition_index<6 else "#302827"); road_material.roughness=1.0; roads.material_override=road_material
	add_child(roads)


func _render_audit()->void:
	var renderer:=RENDERER.new()
	renderer._configure_seamless_world()
	renderer._configure_shape()
	renderer._configure_noise()
	renderer._prepare_river_course()
	var audit_zoom:=maxf(8.0,float(_argument("--zoom=","58.0")))
	var audit_band:=PRESENTATION.scale_band(audit_zoom)
	var camera:=Camera3D.new()
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	camera.size=audit_zoom
	camera.position=Vector3(audit_zoom*0.035,audit_zoom*1.25,audit_zoom*0.15)
	add_child(camera)
	camera.look_at(Vector3.ZERO,Vector3.UP)
	camera.current=true
	var ground:=MeshInstance3D.new()
	var ground_mesh:=PlaneMesh.new(); ground_mesh.size=Vector2(audit_zoom*1.31,audit_zoom*0.93); ground.mesh=ground_mesh
	var ground_material:=StandardMaterial3D.new(); ground_material.albedo_color=Color("#263126"); ground_material.roughness=1.0; ground.material_override=ground_material
	add_child(ground)
	var background_path:=_argument("--background=","").strip_edges()
	if background_path!="":
		var background_image:=Image.load_from_file(ProjectSettings.globalize_path(background_path))
		if background_image:
			ground_material.albedo_color=Color.WHITE
			ground_material.albedo_texture=ImageTexture.create_from_image(background_image)
	var urban_condition:=_argument("--urban=","open").strip_edges().to_lower()
	if urban_condition not in ["open","great","okay","fine","normal","bad","poor","damaged","destroyed"]: urban_condition="normal"
	if urban_condition!="open":
		ground_material.albedo_color=Color("#31352f" if urban_condition not in ["damaged","destroyed"] else "#252727")
		_add_urban_audit_ground(audit_zoom,urban_condition)

	var selected_role:=_argument("--role=","armored").strip_edges().to_lower()
	if selected_role not in ["infantry","mobile","artillery","armored"]: selected_role="infantry"
	var selected_readiness:=clampf(float(_argument("--readiness=","0.78")),0.0,1.25)
	var selected_damage:=clampf(float(_argument("--damage=","0.0")),0.0,0.95)
	var contested:=_argument("--contested=","0")=="1"
	var occupation:=_argument("--occupation=","0")=="1"
	var wounded_for_damage:=roundi(12500.0*selected_damage/maxf(0.05,1.0-selected_damage))
	var selected_army:Dictionary=PRESENTATION.player_marker({"army_id":1,"name":"First Field Army","troops":12500,"formations":_role_formations(selected_role),"readiness":selected_readiness,"wounded_pool":wounded_for_damage,"supply_level":0.64,"status":"moving","location_name":"Alder Reach","destination_name":"North Road","destination_position":{"x":audit_zoom*0.14,"z":-audit_zoom*0.14},"distance_remaining_km":36.0,"arrival_day":84,"position":{"x":-audit_zoom*0.31,"z":-audit_zoom*0.14}},audit_zoom,true)
	var selected_marker:Node3D=renderer._create_warfare_formation_marker("SelectedArmy",true); selected_marker.position=Vector3(-audit_zoom*0.31,0.1,-audit_zoom*0.14); renderer._apply_warfare_formation_view(selected_marker,selected_army); selected_marker.visible=bool(selected_army.visible); add_child(selected_marker)
	var selected_path:Node3D=renderer._create_player_field_army_path(selected_army,Vector3(-audit_zoom*0.31,0.0,-audit_zoom*0.14),Vector3(audit_zoom*0.14,0.0,-audit_zoom*0.14),audit_band); add_child(selected_path)
	var supplied_army:Dictionary=PRESENTATION.player_marker({"army_id":2,"name":"Second Field Army","troops":7200,"formations":[{"unit":"line_infantry","count":7200}],"readiness":0.48,"supply_level":0.22,"status":"stationed","location_name":"South March","position":{"x":-audit_zoom*0.22,"z":audit_zoom*0.22}},audit_zoom,false)
	var supplied_marker:Node3D=renderer._create_warfare_formation_marker("SuppliedArmy",true); supplied_marker.position=Vector3(-audit_zoom*0.22,0.1,audit_zoom*0.22); renderer._apply_warfare_formation_view(supplied_marker,supplied_army); supplied_marker.visible=bool(supplied_army.visible); add_child(supplied_marker)
	var foreign_view:Dictionary=PRESENTATION.foreign_marker({"id":"cedar_host","label":"CEDAR HOST","civilization":"Cedar League","identified":true,"hostile":true,"carries_report":false,"strength_estimate_low":9000,"strength_estimate_high":14000,"readiness_estimate_low":0.42,"readiness_estimate_high":0.66,"formation_role":"artillery","formation_era":2,"damage_estimate":0.36,"distance_km":18.0,"position":{"x":audit_zoom*0.29,"z":audit_zoom*0.20}},audit_zoom)
	var foreign_marker:Node3D=renderer._create_warfare_formation_marker("ForeignArmy",false); foreign_marker.position=Vector3(audit_zoom*0.29,0.1,audit_zoom*0.20); renderer._apply_warfare_formation_view(foreign_marker,foreign_view); foreign_marker.visible=bool(foreign_view.visible); add_child(foreign_marker)
	if contested:
		selected_path.visible=false
		selected_army.position={"x":0.0,"z":0.0}; foreign_view.position={"x":0.0,"z":0.0}
		var player_views:Array[Dictionary]=[selected_army]; var foreign_views:Array[Dictionary]=[foreign_view]
		PRESENTATION._apply_cross_faction_counter_lanes(player_views,foreign_views,audit_zoom)
		var player_offset:Dictionary=player_views[0].display_offset; var foreign_offset:Dictionary=foreign_views[0].display_offset
		selected_marker.position=Vector3(float(player_offset.get("x",0.0)),0.1,float(player_offset.get("z",0.0)))
		foreign_marker.position=Vector3(float(foreign_offset.get("x",0.0)),0.1,float(foreign_offset.get("z",0.0)))
		renderer._apply_warfare_formation_view(selected_marker,player_views[0])
		renderer._apply_warfare_formation_view(foreign_marker,foreign_views[0])
	var front_view:Dictionary=PRESENTATION.front_marker({"id":"front","war_name":"War of the North Road","opponent":"Cedar League","target_region_id":"north","target":"North Road","objective":"Take North Road","progress":0.43,"field_personnel":22000,"occupation_personnel":6800 if occupation else 0,"readiness":0.61,"supply":0.72},{"position":{"x":audit_zoom*0.29,"z":-audit_zoom*0.19}},audit_zoom,not occupation)
	var front_marker:Node3D=renderer._create_warfare_front_marker("front"); front_marker.position=Vector3(audit_zoom*0.29,0.1,-audit_zoom*0.19); front_marker.scale=Vector3.ONE*float(front_view.scale); add_child(front_marker)
	var front_color:=Color(String(front_view.color)); renderer._set_warfare_part_color(front_marker.get_node("FrontCore"),front_color)
	var front_plate_color:=Color("#202526").lerp(front_color.darkened(0.35),0.34); front_plate_color.a=0.92; renderer._set_warfare_part_color(front_marker.get_node("FrontPlate"),front_plate_color)
	renderer._set_warfare_part_color(front_marker.get_node("ContactLine"),front_color.lightened(0.25))
	renderer._set_warfare_part_color(front_marker.get_node("AttackerWing"),Color(String(front_view.attacker_color)).lightened(0.10))
	renderer._set_warfare_part_color(front_marker.get_node("DefenderWing"),Color(String(front_view.defender_color)).lightened(0.06))
	var progress:=float(front_view.progress); var progress_bar:=front_marker.get_node("ObjectiveProgress") as MeshInstance3D; progress_bar.scale=Vector3(progress,1.0,1.0); progress_bar.position.x=-2.45+2.45*progress; renderer._set_warfare_part_color(progress_bar,front_color.lightened(0.24))
	var front_label:=front_marker.get_node("FrontLabel") as Label3D; front_label.text=String(front_view.label); front_label.modulate=front_color.lightened(0.24); front_label.scale=Vector3.ONE/maxf(0.001,float(front_view.scale)); front_label.visible=bool(front_view.show_label)

	var environment:=WorldEnvironment.new(); var resource:=Environment.new(); resource.background_mode=Environment.BG_COLOR; resource.background_color=Color("#0c1212"); resource.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR; resource.ambient_light_color=Color("#d7d2c1"); resource.ambient_light_energy=0.88; environment.environment=resource; add_child(environment)
	var sun:=DirectionalLight3D.new(); sun.rotation_degrees=Vector3(-58.0,-34.0,0.0); sun.light_energy=0.92; sun.shadow_enabled=true; add_child(sun)
	await get_tree().process_frame
	await get_tree().process_frame
	RenderingServer.force_sync(); RenderingServer.force_draw(true,0.0)
	var image:=get_viewport().get_texture().get_image()
	if image: image.save_png(_argument("--output=","user://warfare_visual_audit.png"))
	# The harness creates temporary meshes/materials outside the production scene.
	# Release them before exit so a successful visual audit does not report false
	# ObjectDB/resource leaks.
	for child in get_children(): child.queue_free()
	await get_tree().process_frame
	renderer.free()
	await get_tree().process_frame
	get_tree().quit()
