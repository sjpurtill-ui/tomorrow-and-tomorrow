extends Node
## TEST capture only, never a player launch: the real map and HUD with a
## staged war, for the HOI4-style army screens (recruit queue, army bar,
## army command with a route preview). Run it through
## tools/run_isolated_gpu_probe.ps1 at 1600x900. Arguments after "--":
##   --era=early|late        1-2 bands at the hearth, or several armies later
##   --shot=map|recruit|training|command|route|plan|arrow|front
##     (front: a front line drawn and ordered, three days on, panel closed)
##   --out=res://artifacts/hoi4-armies/<name>.png
## Works on the code before and after the HOI4 rework (new hooks are
## looked up with has_method), so the same fixture gives before and after.
const Orders:=preload("res://scripts/army_orders.gd")
var terrain:Node
var city_id:=""
var towns:Array[String]=[]

func _ready()->void:
	get_window().title="TEST — HOI4 armies capture"
	call_deferred("_run")

func _arg(name:String,fallback:String="")->String:
	for a:String in OS.get_cmdline_user_args():
		if a.begins_with("--%s=" % name):return a.get_slice("=",1)
		if a=="--"+name:return "true"
	return fallback

func _settle(frames:int=6)->void:
	for _frame in frames:
		await get_tree().process_frame
		RenderingServer.force_draw(false)

func _run()->void:
	var era:=_arg("era","early")
	var shot:=_arg("shot","map")
	GameState.reset_for_new_world(991704);MilitaryCampaign.reset_for_new_world()
	GameState.initialize_population_model();GameState.ensure_population_total(160 if era=="early" else int(_arg("pop","420")))
	GameState.housing_capacity=GameState.population_total+200
	GameState.settlement_name="Seanstone";GameState.settlement_site_committed=true
	GameState.settlement_completed=["Hearth Circle"];GameState.settlement_founded_at=Vector3(12,0,-8)
	SettlementModel.ensure_founded();GovernmentPeopleSystem.initialize()
	GameState.select_founding_focus("provision");PeopleDirection.choose(String(PeopleDirection.AMBITIONS.keys()[0]))
	GameState.elapsed_days=(3 if era=="early" else int(_arg("years","12")))*365+40
	if era=="late":
		GameState.known_discoveries.append_array(["pictographic_records","phonetic_notation","formal_archives","hafted_weapons","bow_craft","shield_wall","formation_drill","domesticated_mounts","bronze_weaponry"])
	GameState.resource_stockpiles["Food"]=100000.0
	print("HOI4_CAPTURE stage: terrain")
	terrain=load("res://local_terrain.tscn").instantiate()
	# The command screens look for the map as the running scene.
	get_tree().root.add_child(terrain);get_tree().current_scene=terrain
	for _i in 4:await get_tree().process_frame
	terrain._set_game_speed(0.0)
	if is_instance_valid(terrain.founding_focus_panel):terrain.founding_focus_panel.queue_free()
	terrain.founding_focus_panel=null
	for singleton:Node in [GameState,MilitaryCampaign,CivilizationSystem]:singleton.set_process(false)
	print("HOI4_CAPTURE stage: world")
	_stage_world(era)
	print("HOI4_CAPTURE stage: forces")
	_stage_forces(era)
	_close_unbidden_scenes()
	print("HOI4_CAPTURE stage: camera")
	var home:Vector2=CivilizationSystem.player_world_origin
	terrain.camera_target=Vector3(home.x-8.0,terrain._height_at(home.x,home.y),home.y+4.0)
	terrain.camera.size=62.0 if era=="early" else 150.0
	terrain._update_camera();terrain._update_scale_lod()
	await _settle(4)
	while terrain.terrain_patch_job!=null:
		terrain._advance_terrain_patch()
		await get_tree().process_frame
	terrain._update_world_streaming()
	await _settle(4)
	_close_unbidden_scenes()
	print("HOI4_CAPTURE stage: screens")
	match shot:
		"recruit":MilitaryCampaign.open_roster("army",false,"recruitment")
		"training":MilitaryCampaign.open_roster("army",true,"training")
		"command","route","plan","arrow","front":await _open_command(shot)
		"map":
			if terrain.hud and terrain.hud.has_method("select_army") and not MilitaryCampaign.field_armies.is_empty():terrain.hud.select_army(int(MilitaryCampaign.field_armies[0].army_id))
	await _settle(10)
	var output:=_arg("out","res://artifacts/hoi4-armies/%s-%s.png" % [era,shot])
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output.get_base_dir()))
	await RenderingServer.frame_post_draw
	var error:=get_viewport().get_texture().get_image().save_png(output)
	print("HOI4_ARMIES_CAPTURE ","PASS" if error==OK else "FAIL"," ",output)
	get_tree().quit(0 if error==OK else 1)

## Moves the camera so these ground points sit in the open map left of the
## command panel (the panel covers the right third of the screen).
func _frame(panel:Variant,points:Array)->void:
	var centre:=Vector2.ZERO
	for p:Vector2 in points:centre+=p/float(points.size())
	var view:=get_viewport().get_visible_rect().size
	var goal:=Vector2((96.0+(view.x-470.0))*0.5 if panel!=null else view.x*0.5,view.y*0.42)
	for _pass in 3:
		var here:Vector2=terrain.camera.unproject_position(Vector3(centre.x,terrain._height_at(centre.x,centre.y),centre.y))
		var east:Vector2=terrain.camera.unproject_position(Vector3(centre.x+1.0,terrain._height_at(centre.x,centre.y),centre.y))-here
		var south:Vector2=terrain.camera.unproject_position(Vector3(centre.x,terrain._height_at(centre.x,centre.y),centre.y+1.0))-here
		var shift:=here-goal
		var det:=east.x*south.y-east.y*south.x
		if absf(det)<0.0001:break
		var a:=(shift.x*south.y-shift.y*south.x)/det
		var b:=(east.x*shift.y-east.y*shift.x)/det
		terrain.camera_target+=Vector3(a,0.0,b)
		terrain._update_camera()
	await _settle(2)
	while terrain.terrain_patch_job!=null:
		terrain._advance_terrain_patch()
		await get_tree().process_frame
	await _settle(2)

func _close_unbidden_scenes()->void:
	## An envoy or court scene the staged contact may raise is not part of
	## this capture.
	var director:Node=preload("res://scripts/audience_director.gd").court_node()
	if director!=null and is_instance_valid(director.get("modal")):director.modal.queue_free()

func _land_near(home:Vector2,heading:Vector2,km:float)->Vector2:
	for step in 24:
		var angle:=heading.angle()+(float(step/2)*0.26)*(1.0 if step%2==0 else -1.0)
		var at:=home+Vector2.from_angle(angle)*km
		if CivilizationSystem._scout_land_at(at):return at
	return home+heading.normalized()*km

func _stage_world(era:String)->void:
	var home:Vector2=CivilizationSystem.player_world_origin
	CivilizationSystem.revealed_areas=[{"x":home.x,"z":home.y,"radius":260.0}]
	var civ:Dictionary=CivilizationSystem.civilizations[0]
	civ["name"]="Tsaren"
	var relation:Dictionary=civ.player_relation
	relation.at_war=true;relation.contact_level=2;relation.home_location_known=true
	var regions:Array=civ.strategic_regions
	var spots:=[[Vector2(-1,0.4),26.0,"Tsaren"],[Vector2(-0.6,-1),48.0,"Orvel"],[Vector2(0.2,1),64.0,"Kesh"]]
	for i in mini(regions.size(),spots.size() if era=="late" else 1):
		var region:Dictionary=regions[i]
		region["name"]=String(spots[i][2])
		var id:=String(region.id)
		towns.append(id)
		CivilizationSystem.city_intelligence.publish("player",CivilizationSystem.city_intelligence.capture("player",id,.8,int(GameState.elapsed_days),"scout report","test"),int(GameState.elapsed_days))
		var at:=_land_near(home,spots[i][0],float(spots[i][1]))
		CivilizationSystem.city_intelligence.records.player[id]["position"]={"x":at.x,"z":at.y}
		CivilizationSystem.city_intelligence.records.player[id].fields["garrison"]={"low":18.0,"high":24.0,"observed_day":int(GameState.elapsed_days),"reported_day":int(GameState.elapsed_days)}
	city_id=towns[0]

func _train(unit:String,weapon:String,count:int,training:float=0.7)->void:
	MilitaryCampaign.military_inventory[weapon]=int(MilitaryCampaign.military_inventory.get(weapon,0))+count
	MilitaryCampaign.raise_recruits(count);MilitaryCampaign.start_training(unit,weapon,count)
	var order:Dictionary=MilitaryCampaign.training_queue[-1].duplicate(true)
	MilitaryCampaign.training_queue.pop_back()
	MilitaryCampaign._complete_training(order)
	for formation:Dictionary in MilitaryCampaign.home_army.get("formations",[]):formation["training"]=training

func _march(army_id:int,verb:String,target:Dictionary,days:int)->void:
	Orders.give(army_id,verb,target,true)
	for _day in days:
		GameState.elapsed_days+=1;MilitaryCampaign._process_field_army_movement_day()

func _stage_forces(era:String)->void:
	MilitaryCampaign.army_templates=[{"template_id":1,"name":"Levy band","entries":[{"unit":"levy","weapon":"improvised","count":20}]}]
	if era=="late":
		MilitaryCampaign.army_templates.append({"template_id":2,"name":"Spear host","entries":[{"unit":"levy","weapon":"improvised","count":60},{"unit":"skirmisher","weapon":"improvised","count":20}]})
	MilitaryCampaign.next_army_template_id=MilitaryCampaign.army_templates.size()+1
	var place:={"type":"place","place":Orders.place(city_id)}
	if era=="early":
		_train("levy","improvised",46)
		var first:Dictionary=MilitaryCampaign.create_field_army(24,"Levy band 1")
		MilitaryCampaign.create_field_army(20,"Levy band 2")
		_march(int(first.army.army_id),"attack",place,1)
		MilitaryCampaign.military_inventory["improvised"]=12
		MilitaryCampaign.recruit_deploy.add(1,2,1,false)
		for order:Dictionary in MilitaryCampaign.training_queue:order.progress_days=float(order.required_days)*0.35
	else:
		_train("levy","improvised",200,0.75)
		var names:=["First host","Second host","River band","Hill band","Watch band"]
		var sizes:=[62,44,30,24,20]
		var ids:Array[int]=[]
		for i in names.size():
			var made:Dictionary=MilitaryCampaign.create_field_army(sizes[i],names[i])
			if made.has("army"):ids.append(int(made.army.army_id))
		if ids.size()>=5:
			_march(ids[0],"attack",place,2)
			_march(ids[1],"goto",{"type":"spot","x":CivilizationSystem.player_world_origin.x+18.0,"z":CivilizationSystem.player_world_origin.y-20.0},3)
			if towns.size()>1:_march(ids[2],"raid",{"type":"place","place":Orders.place(towns[1])},2)
			var hungry:Dictionary=MilitaryCampaign.field_armies[MilitaryCampaign._field_army_index(ids[3])]
			hungry["hungry_days"]=6.0;hungry["provision_ratio"]=0.4;hungry["supply_level"]=0.35
			var worn:Dictionary=MilitaryCampaign.field_armies[MilitaryCampaign._field_army_index(ids[4])]
			worn["morale"]=0.2
			var command:RefCounted=MilitaryCampaign.command_hierarchy
			command.sync()
			var grouped:Array=[]
			for entry:Dictionary in command.data.nodes.values():
				if entry.service=="army" and int(entry.force_id) in [ids[3],ids[4]]:grouped.append(String(entry.id))
			if grouped.size()==2:command.organize(grouped,4,"Hill army")
		MilitaryCampaign.military_inventory["improvised"]=40
		MilitaryCampaign.recruit_deploy.add(2,3,1,false)
		MilitaryCampaign.recruit_deploy.add(1,2,1,true)
		for order:Dictionary in MilitaryCampaign.training_queue:order.progress_days=float(order.required_days)*0.55
	MilitaryCampaign.command_hierarchy.sync()

func _open_command(shot:String)->void:
	# The band still at home: free for a new order.
	var army_id:=0
	for army:Dictionary in MilitaryCampaign.field_armies:
		if Orders.at_home(army):army_id=int(army.army_id)
	if terrain.hud and terrain.hud.has_method("select_army"):terrain.hud.select_army(army_id)
	MilitaryCampaign.joint_operations.open_hierarchy("army")
	var panel:CanvasLayer=MilitaryCampaign.joint_operations.screen
	await _settle(3)
	if panel==null:return
	var home:Vector2=CivilizationSystem.player_world_origin
	if shot in ["plan","front"] and panel.has_method("begin_plan"):
		# A drawn front line near home: before the order, or three days on.
		panel.choose_force(army_id)
		panel.begin_plan("front")
		var line:=[home+Vector2(10,-16),home+Vector2(15,-4),home+Vector2(13,10)]
		for p in line:panel.plan_point(p)
		panel.finish_plan()
		await _frame(panel,line+[home])
		if shot=="front":
			panel._give(false)
			print("HOI4_CAPTURE front order: ",String(panel.last_answer.get("says","")))
			for _day in 3:
				GameState.elapsed_days+=1
				MilitaryCampaign.command_hierarchy.advance(int(GameState.elapsed_days))
				MilitaryCampaign._process_field_army_movement_day()
			panel.queue_free()
			if terrain.hud and terrain.hud.has_method("select_army"):terrain.hud.select_army(army_id)
			await _frame(null,line+[home])
		return
	if shot=="arrow" and panel.has_method("begin_plan"):
		panel.choose_force(army_id)
		panel.begin_plan("arrow")
		var town:=Orders._v2(Orders.place(city_id).position)
		panel.plan_point(town)
		return
	if panel.has_method("choose_force"):
		panel.choose_force(army_id);panel.choose_verb("attack")
		if shot=="route" and panel.has_method("hover_target"):
			var town:=Orders._v2(Orders.place(city_id).position)
			await _frame(panel,[home,town])
			panel.hover_target(panel.map.world_to_screen(town))
		else:
			panel.choose_place(city_id)
