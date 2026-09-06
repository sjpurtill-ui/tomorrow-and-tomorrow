extends "res://tests/focused_journey_probe.gd"

func _ready()->void:
	assert(OS.get_user_data_dir().ends_with("TomorrowAndTomorrow_DistrictHover_Test"))
	GameState.reset_for_new_world(551188);GameState.civic_api_enabled=false
	DiscoverySystem.reset_for_new_world();ProgressionSystem.reset_for_new_world();ResourceSystem.reset_for_new_world();FoodSystem.reset_for_new_world();ConsequenceEngine.reset_for_new_world();CivilizationSystem.reset_for_new_world()
	GameState.select_founding_focus("provision");PeopleDirection.choose(String(PeopleDirection.AMBITIONS.keys()[0]))
	GameState.settlement_site_committed=true;GameState.settlement_completed=["Hearth Circle"];SettlementModel.ensure_founded()
	terrain=preload("res://local_terrain.tscn").instantiate();add_child(terrain);terrain._set_game_speed(0)
	await frames();hud=terrain.hud
	get_window().size=Vector2i(1280,900)
	var point:Vector3=terrain.camera_target
	var report:Dictionary={"city_id":"hover_district","civ_id":"","name":"Ashen Foundry district","position":{"x":point.x,"z":point.z},"controller":"","observed_day":0,"reported_day":0,"quality":.6,"source":"local observation","reference":"lookouts","fields":{"population":{"low":800.0,"high":1200.0,"observed_day":0,"quality":.6,"source":"local observation","reference":"lookouts"}}}
	var other:=report.duplicate(true);other.city_id="other_district";other.name="Neighbor district";other.position.x+=.2
	CivilizationSystem.city_intelligence.records["player"]={"hover_district":report,"other_district":other}
	terrain.camera.size=.6;terrain._update_camera();await frames()
	var first:Node3D=terrain.contact_encounter_markers.hover_district
	var identity:=first.get_instance_id()
	var pointer:Vector2=terrain.camera.unproject_position(first.global_position+Vector3(0,terrain._height_at(point.x,point.z),0))
	var replacements:=0
	for step in 90:
		var motion:=InputEventMouseMotion.new();motion.position=pointer+Vector2(sin(step)*3,0);Input.parse_input_event(motion)
		if step%15==0:GameState.elapsed_days+=1
		await get_tree().process_frame
		var current:Node3D=terrain.contact_encounter_markers.hover_district
		if current.get_instance_id()!=identity:replacements+=1;identity=current.get_instance_id()
	await capture("district-hover")
	var before:=identity
	other.reported_day=9;other.source="returned scouts";other.fields.population.high=2400.0
	await frames()
	var unrelated_rebuilt:bool=terrain.contact_encounter_markers.hover_district.get_instance_id()!=before
	print("DISTRICT_HOVER_OBSERVATION aging_replacements=",replacements," unrelated_report_rebuilt=",unrelated_rebuilt)
	if not "--baseline" in OS.get_cmdline_user_args():
		assert(replacements==0,"Moving the pointer while reports age must retain district geometry")
		assert(not unrelated_rebuilt,"Another district's report must not rebuild this district")
		before=terrain.contact_encounter_markers.hover_district.get_instance_id()
		for offset in [-.05,.25,-.05]:
			move_camera(point,offset)
			await frames()
			assert(terrain.contact_encounter_markers.hover_district.get_instance_id()==before,"Camera movement and city distance order must not rebuild unchanged geometry")
		for day in range(10,20):
			report.observed_day=day;report.reported_day=day;report.fields.population.observed_day=day
			report.fields.population.low=700.0+day;report.fields.population.high=1400.0-day*2
			await frames()
			assert(terrain.contact_encounter_markers.hover_district.get_instance_id()==before,"Overlapping daily lookout estimates must not reshape buildings")
		report.fields.population.low=6000.0;report.fields.population.high=8000.0;await frames()
		assert(terrain.contact_encounter_markers.hover_district.get_instance_id()!=before,"Actual new population evidence must update geometry")
		CivilizationSystem.city_intelligence.records.player.erase("other_district");await frames()
		assert(not terrain.contact_encounter_markers.has("other_district"))
		terrain.camera.size=3.0;terrain._update_camera();await frames()
		assert(terrain.contact_encounter_markers.hover_district.find_children("*","MeshInstance3D",true,false).is_empty())
		terrain.camera.size=.6;terrain._update_camera();await frames()
		assert(terrain.contact_encounter_markers.hover_district.find_children("*","MeshInstance3D",true,false).size()==3)
		print("DISTRICT_HOVER_PASS pointer motion, dated reports, camera movement, independent updates, overlapping observations, new evidence, removal, zoom detail")
	get_tree().quit()

func move_camera(point:Vector3,offset:float)->void:
	terrain.camera_target=point+Vector3(offset,0,0);terrain._update_camera()
