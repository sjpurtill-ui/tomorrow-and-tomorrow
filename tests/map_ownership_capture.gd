extends Node
## Isolated chart capture of who holds which town: our home and our own town,
## a town we have just taken, a rival capital and towns of two other peoples.
## Run only through tools/run_isolated_gpu_probe.ps1:
##   res://tests/map_ownership_capture.tscn -- --zoom=2|3 --out=<png path>
## The capture plays the real capture path (the rival's town falls, our band
## leaves a garrison), then draws the map's own marks and city cards over a
## plain chart ground. It never writes a save and quits by itself.
class Map extends "res://scripts/local_terrain.gd":
	func _ready()->void:pass
	func _process(_delta:float)->void:pass
	func _height_at(_x:float,_z:float)->float:return 0.0
	func _close_surface_height_at(_x:float,_z:float)->float:return 0.0

var map:Node3D

func _ready()->void:
	# Never outlive a failed setup.
	get_tree().create_timer(60.0).timeout.connect(func():get_tree().quit(3))
	var zoom:=2;var out:=""
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--zoom="):zoom=int(argument.trim_prefix("--zoom="))
		elif argument.begins_with("--out="):out=argument.trim_prefix("--out=")
	GameState.reset_for_new_world(424242)
	CivilizationSystem.reset_for_new_world();CivilizationSystem.initialize()
	MilitaryCampaign.reset_for_new_world()
	GameState.elapsed_days=400.0
	MilitaryCampaign.last_processed_day=400
	var civs:Array=CivilizationSystem.civilizations
	for civ:Dictionary in civs:civ.player_relation.contact_level=2
	var intel=CivilizationSystem.city_intelligence
	# A people with a chief town and a second town (the one that falls), and
	# three other peoples' towns, all set close together so one view shows them.
	var by_civ:Dictionary={}
	for site:Dictionary in intel.sites(false):
		if not by_civ.has(site.civ_id):by_civ[site.civ_id]=[]
		by_civ[site.civ_id].append(site)
	var owner_id:=""
	for civ_id in by_civ:
		if (by_civ[civ_id] as Array).size()>=2:owner_id=String(civ_id);break
	var chosen:Array=[]
	var capital_id:=intel.primary_id(owner_id)
	for site:Dictionary in by_civ[owner_id]:
		if String(site.city_id)==capital_id:chosen.push_front(site)
	for site:Dictionary in by_civ[owner_id]:
		if String(site.city_id)!=capital_id:chosen.append(site);break
	for civ_id in by_civ:
		if String(civ_id)!=owner_id and chosen.size()<5:chosen.append(by_civ[civ_id][0])
	var centre:Vector2=intel.vector(chosen[0].position)
	var spread:=26.0 if zoom<=2 else 300.0
	var offsets:=[Vector2(0.0,0.0),Vector2(0.9,-0.55),Vector2(-0.95,0.2),Vector2(0.15,0.85),Vector2(1.05,0.5)]
	for index in chosen.size():
		var observation:Dictionary=intel.capture("player",String(chosen[index].city_id),.85,390,"Scout report","capture")
		var at:Vector2=centre+(offsets[index] as Vector2)*spread
		observation.position={"x":at.x,"z":at.y}
		# The last of them was seen burned out.
		if index==4:observation.fields["damage"]={"low":.7,"high":.85,"observed_day":390,"quality":.85,"source":"Scout report","reference":"capture"}
		intel.publish("player",observation,392)
	# Our home and a second town of ours, as the map letters them.
	map=Map.new();add_child(map)
	map.camera=Camera3D.new();map.add_child(map.camera)
	map.camera.projection=Camera3D.PROJECTION_PERSPECTIVE
	var environment:=WorldEnvironment.new();environment.environment=Environment.new()
	environment.environment.background_mode=Environment.BG_COLOR;environment.environment.background_color=Color("#a9a27c")
	add_child(environment)
	for own:Array in [["Seanstone",Vector2(-0.35,-0.95),true],["Elmmeadow",Vector2(-1.2,-0.55),false]]:
		var at:Vector2=centre+(own[1] as Vector2)*spread
		var label:=Label3D.new();label.text=map._city_map_label(String(own[0]),240 if bool(own[2]) else 60)
		label.set_meta("city_civilization_id","player");label.set_meta("city_map_id","own_"+String(own[0]))
		label.set_meta("city_map_anchor",Vector3(at.x,0,at.y));label.fixed_size=true;label.position=Vector3(at.x,0,at.y)
		map.add_child(label);map._update_city_flag(label)
		var glyph:=MeshInstance3D.new();glyph.mesh=QuadMesh.new();glyph.material_override=map._map_glyph_material(false,26.0 if bool(own[2]) else 20.0,bool(own[2]))
		glyph.set_instance_shader_parameter("glyph_index",2.0 if bool(own[2]) else 1.0)
		if bool(own[2]):glyph.set_instance_shader_parameter("home_ring_radius",0.44)
		glyph.position=Vector3(at.x,0,at.y);map.add_child(glyph)
	# The rival's second town falls to our band, which leaves a guard behind:
	# the same calls the general's campaign makes (general_campaign._secure_home).
	var owner_index:=CivilizationSystem._civilization_index(owner_id)
	var taken:Dictionary=CivilizationSystem.region_snapshot(owner_id,String(chosen[1].city_id))
	var fell:Dictionary=CivilizationSystem._capture_region(CivilizationSystem.civilizations[owner_index],String(taken.id),{"remaining_troops":400,"supply_level":1.0,"readiness":1.0,"dead":3},{"dead":9})
	CivilizationSystem.civilizations[owner_index]=fell.get("civilization",CivilizationSystem.civilizations[owner_index])
	MilitaryCampaign.occupation_forces.append({"civ_id":owner_id,"region_id":String(taken.id),"region_name":String(taken.name),"troops":17,"committed_day":400,"formations":[]})
	# And our siege lies round the third.
	MilitaryCampaign.active_siege={"active":true,"mode":"offensive","region_id":String(chosen[2].city_id),"days":5}
	map.camera_target=Vector3(centre.x,0,centre.y)
	map.set_camera_distance_level(zoom);map.camera.size=map.zoom_target_size;map._update_camera()
	for pass_index in 3:
		map._refresh_contact_encounter_markers()
		map._normalize_aerial_labels()
	# The marks are drawn; the siege itself is not simulated here.
	MilitaryCampaign.active_siege={}
	await get_tree().process_frame
	if is_instance_valid(map.city_labels):
		map.city_labels.refresh()
		# At the regional view, open the taken town's card as a hover would;
		# the chart view shows every mark and name tag at rest.
		for card:Dictionary in map.city_labels.cards:
			if String(card.id)==String(taken.id) and zoom<=2:map.city_labels.pinned_id=String(card.id)
		map.city_labels.queue_redraw()
	# The chart key as map help shows it, over the lower left of the view.
	var layer:=CanvasLayer.new();add_child(layer)
	var help:=PanelContainer.new();help.position=Vector2(100,560);help.size=Vector2(390,96)
	var style:=StyleBoxFlat.new();style.bg_color=Color("#1c2624ee");style.border_color=Color("#7ca39d");style.set_border_width_all(1);style.set_content_margin_all(10)
	help.add_theme_stylebox_override("panel",style);layer.add_child(help)
	var root:=VBoxContainer.new();help.add_child(root)
	var body:=Label.new();body.text="Left-click a town for its report. Right-click land to send people.";body.add_theme_font_size_override("font_size",11);body.add_theme_color_override("font_color",Color("#c5cbc5"));root.add_child(body)
	var anchor:=Control.new();anchor.position=Vector2(100,860)
	preload("res://scripts/hud/map_legend.gd").attach(help,anchor,true)
	for frame in 30:await get_tree().process_frame
	RenderingServer.force_draw(true,0.0)
	await get_tree().process_frame
	if out!="" and DisplayServer.get_name()!="headless":
		var image:=get_viewport().get_texture().get_image()
		if image:image.save_png(out)
	for c:Dictionary in intel.known_cities("player","",false):
		var glyph:Node=map.contact_encounter_markers[c.city_id].get_node_or_null("RegionalCityGlyph")
		print("CITY ",c.name," ",c.controller," status=",preload("res://scripts/map_ownership.gd").status(c).kind," glyph=",glyph.get_meta("glyph",-1) if glyph else -2," forces=",MilitaryCampaign.occupation_forces.size())
	print("MAP_OWNERSHIP_CAPTURE zoom=",zoom," taken=",String(taken.name)," -> ",out)
	get_tree().quit(0)
