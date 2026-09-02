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

	var selected_role:=_argument("--role=","armored").strip_edges().to_lower()
	if selected_role not in ["infantry","mobile","artillery","armored"]: selected_role="infantry"
	var selected_army:Dictionary=PRESENTATION.player_marker({"army_id":1,"name":"First Field Army","troops":12500,"formations":_role_formations(selected_role),"readiness":0.78,"supply_level":0.64,"status":"moving","location_name":"Alder Reach","destination_name":"North Road","destination_position":{"x":audit_zoom*0.14,"z":-audit_zoom*0.14},"distance_remaining_km":36.0,"arrival_day":84,"position":{"x":-audit_zoom*0.31,"z":-audit_zoom*0.14}},audit_zoom,true)
	var selected_marker:Node3D=renderer._create_warfare_formation_marker("SelectedArmy",true); selected_marker.position=Vector3(-audit_zoom*0.31,0.1,-audit_zoom*0.14); renderer._apply_warfare_formation_view(selected_marker,selected_army); selected_marker.visible=bool(selected_army.visible); add_child(selected_marker)
	var selected_path:Node3D=renderer._create_player_field_army_path(selected_army,Vector3(-audit_zoom*0.31,0.0,-audit_zoom*0.14),Vector3(audit_zoom*0.14,0.0,-audit_zoom*0.14),audit_band); add_child(selected_path)
	var supplied_army:Dictionary=PRESENTATION.player_marker({"army_id":2,"name":"Second Field Army","troops":7200,"formations":[{"unit":"line_infantry","count":7200}],"readiness":0.48,"supply_level":0.22,"status":"stationed","location_name":"South March","position":{"x":-audit_zoom*0.22,"z":audit_zoom*0.22}},audit_zoom,false)
	var supplied_marker:Node3D=renderer._create_warfare_formation_marker("SuppliedArmy",true); supplied_marker.position=Vector3(-audit_zoom*0.22,0.1,audit_zoom*0.22); renderer._apply_warfare_formation_view(supplied_marker,supplied_army); supplied_marker.visible=bool(supplied_army.visible); add_child(supplied_marker)
	var foreign_view:Dictionary=PRESENTATION.foreign_marker({"id":"cedar_host","label":"CEDAR HOST","civilization":"Cedar League","identified":true,"hostile":true,"carries_report":false,"strength_estimate_low":9000,"strength_estimate_high":14000,"readiness_estimate_low":0.42,"readiness_estimate_high":0.66,"distance_km":18.0,"position":{"x":audit_zoom*0.29,"z":audit_zoom*0.20}},audit_zoom)
	var foreign_marker:Node3D=renderer._create_warfare_formation_marker("ForeignArmy",false); foreign_marker.position=Vector3(audit_zoom*0.29,0.1,audit_zoom*0.20); renderer._apply_warfare_formation_view(foreign_marker,foreign_view); foreign_marker.visible=bool(foreign_view.visible); add_child(foreign_marker)
	var front_view:Dictionary=PRESENTATION.front_marker({"id":"front","war_name":"War of the North Road","opponent":"Cedar League","target_region_id":"north","target":"North Road","objective":"Take North Road","progress":0.43,"field_personnel":22000,"readiness":0.61,"supply":0.72},{"position":{"x":audit_zoom*0.29,"z":-audit_zoom*0.19}},audit_zoom,true)
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
	get_tree().quit()
