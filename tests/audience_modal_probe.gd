extends Node
## Audience Hall UI probe. Headless: builds every kind through the director,
## plays the offline scene, speaks, resolves, defers. Windowed (via
## tools/run_isolated_gpu_probe.ps1) it also writes review captures to
## res://reports/audience/.
##   <godot> --headless --path <worktree> res://tests/audience_modal_probe.tscn

const Hall:=preload("res://scripts/audience_hall.gd")
const Director:=preload("res://scripts/audience_director.gd")

class TerrainDouble extends Node:
	## Stands in for local_terrain: only the surfaces the modal/director touch.
	var game_speed:=1.0
	var capture_render_active:=false
	var decrees:Array[String]=[]
	func _set_game_speed(speed:float)->void:game_speed=speed
	func issue_civic_directive_text(text:String)->void:decrees.append(text)
	func _blocking_modal_or_report_open()->bool:return false

var failures:Array[String]=[]
var capture:=false
var out_dir:=""

func _ready()->void:
	capture=DisplayServer.get_name()!="headless"
	for argument in OS.get_cmdline_user_args():
		if argument=="--no-capture":capture=false
	out_dir=ProjectSettings.globalize_path("res://reports/audience/")
	if capture:DirAccess.make_dir_recursive_absolute(out_dir)
	_setup_world()
	var terrain:=TerrainDouble.new();terrain.name="TerrainDouble";add_child(terrain)
	var director:=Director.new();director.terrain=terrain;add_child(director)
	# Never reach the network from a probe, whatever the user's AI settings.
	if "force_offline" in director.voice:director.voice.force_offline=true
	await _frames(2)
	if capture:
		get_window().size=Vector2i(1920,1080);get_window().content_scale_size=Vector2i(1920,1080)
		await _frames(2)
	for mode in (["dark","light"] if capture else ["light"]):
		HudTokens.set_color_mode(mode)
		await _exercise_kind(director,terrain,"threat",mode)
		await _exercise_kind(director,terrain,"gift",mode)
		await _exercise_kind(director,terrain,"petition",mode)
		await _exercise_kind(director,terrain,"report",mode)
		if mode=="light" or capture:
			await _exercise_kind(director,terrain,"request",mode)
			await _exercise_kind(director,terrain,"news",mode)
	await _exercise_defer(director,terrain)
	if failures.is_empty():
		print("AUDIENCE_MODAL PASS")
		get_tree().quit(0)
	else:
		for failure in failures:printerr("AUDIENCE_MODAL FAIL: ",failure)
		get_tree().quit(1)

const SEED:=313131

func _civ(id:String,civ_name:String,population:int,food_days:float,strategy:String,aggression:float,opinion:float,tension:float,position:Vector2)->Dictionary:
	return {"id":id,"name":civ_name,"alive":true,"population":population,"food_days":food_days,"strategy":strategy,"aggression":aggression,"world_position":position,"position":position,"strategic_regions":[],"relations":{},
		"player_relation":{"opinion":opinion,"border_tension":tension,"at_war":false,"treaty":"none","stance":"watchful","contact_level":2,"contact_intelligence":0.1,"met_day":0,"home_location_known":true,"home_position":{"x":position.x,"z":position.y}}}

func _stock_actor(id:String,food:float,stock:float)->void:
	WorldSimulation.create_actor(id,SEED,Vector2(30,0));WorldSimulation.actors[id].controller="manual"
	WorldSimulation.scoped(id,func()->void:
		WorldSimulation.state.ensure_population_total(180);WorldSimulation.state.settlement_site_committed=true
		WorldSimulation.food.receive_external_food(food)
		for resource in ["Timber","Stone","Clay","Fiber Plants"]:WorldSimulation.state.resource_stockpiles[resource]=stock)

func _setup_world()->void:
	## Mirrors tests/audience_hall_probe.gd: three contacted peoples with real ledgers.
	WorldSimulation.clear()
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	GameState.reset_for_new_world(SEED);GameState.civic_api_enabled=false
	DiscoverySystem.reset_for_new_world();FoodSystem.reset_for_new_world();MilitaryCampaign.reset_for_new_world();CivilizationSystem.reset_for_new_world()
	ForeignDiplomacy.reset_for_new_world();GovernmentPeopleSystem.reset_for_new_world()
	GameState.ensure_population_total(200);GameState.housing_capacity=260
	GameState.settlement_site_committed=true;GameState.settlement_completed=["Hearth Circle"];SettlementModel.ensure_founded()
	GameState.select_founding_focus("provision")
	GameState.population_health=0.9;GameState.simulation_metrics.merge({"food_days":60.0,"food_intake_ratio":1.0,"security":0.6,"cohesion":0.7},true)
	GovernmentPeopleSystem.initialize()
	FoodSystem.receive_external_food(4000)
	for resource in ["Timber","Stone","Clay","Fiber Plants"]:GameState.resource_stockpiles[resource]=300.0
	_stock_actor("rival_a",3000,400);_stock_actor("rival_b",2000,250);_stock_actor("rival_c",800,80)
	CivilizationSystem.civilizations.clear()
	CivilizationSystem.civilizations.append(_civ("rival_a","Kel Adun",260,70,"commerce",0.2,0.35,0.1,Vector2(30,0)))
	CivilizationSystem.civilizations.append(_civ("rival_b","Varrow",420,18,"fortification",0.8,-0.3,0.65,Vector2(0,30)))
	CivilizationSystem.civilizations.append(_civ("rival_c","Isle of Mora",150,9,"expansion",0.4,0.0,0.3,Vector2(-30,0)))
	GameState.elapsed_days=1

func _frames(count:int)->void:
	for i in count:await get_tree().process_frame

func _fail(text:String)->void:
	failures.append(text);printerr("AUDIENCE_MODAL FAIL: ",text)

func _wait_scene(modal:Control,id:String,minimum:int,limit:float=8.0)->void:
	var waited:=0.0
	while waited<limit:
		var lines:Array=Hall.find(id).get("lines",[])
		if lines.size()>=minimum and not modal.voice.busy(id):break
		await get_tree().process_frame;waited+=get_process_delta_time()
	modal.skip_reveal()
	await _frames(3)

func _exercise_kind(director:Node,terrain:TerrainDouble,kind:String,mode:String)->void:
	var audience:=Hall.debug_force(kind)
	if audience.is_empty():_fail("debug_force(%s) produced no audience" % kind);return
	var id:=String(audience.id)
	var modal:Control=director.open_audience(id)
	if modal==null:_fail("%s modal did not open" % kind);return
	await _frames(2)
	if terrain.game_speed!=0.0:_fail("%s modal did not pause the simulation" % kind)
	var herald:=modal.find_child("HeraldTitle",true,false) as Label
	if herald==null or herald.text.is_empty():_fail("%s herald missing" % kind)
	await _wait_scene(modal,id,1)
	var lines:Array=Hall.find(id).get("lines",[])
	if lines.is_empty():_fail("%s opening produced no lines" % kind)
	if modal.transcript.get_child_count()<lines.size():_fail("%s transcript rendered %d of %d lines" % [kind,modal.transcript.get_child_count(),lines.size()])
	var options:=Hall.options(id)
	if options.is_empty():_fail("%s has no options" % kind)
	if modal.options_row.get_child_count()!=options.size():_fail("%s rendered %d of %d option cards" % [kind,modal.options_row.get_child_count(),options.size()])
	if not get_viewport().get_visible_rect().encloses(modal.card.get_global_rect()):_fail("%s card escapes the viewport %s" % [kind,modal.card.get_global_rect()])
	if not get_viewport().get_visible_rect().encloses(modal.card.get_global_rect()):_dump(modal.card,0)
	if modal.card.size.y>modal.DESIGN_SIZE.y+1.0:_fail("%s card grew past its design height: %s" % [kind,modal.card.size])
	# The ruler speaks freely.
	var before:=lines.size()
	modal.speech_input.text={"petition":"Tell me plainly what you need.","report":"Would they fight us, if it came to it?","gift":"And what does your ruler hope this buys?"}.get(kind,"What does your master truly want from us?")
	modal._speak()
	await _wait_scene(modal,id,before+2)
	lines=Hall.find(id).get("lines",[])
	var ruler_spoke:=false
	for index in range(before,lines.size()):
		if String(lines[index].get("role",""))=="ruler":ruler_spoke=true
	if not ruler_spoke:_fail("%s ruler line missing after speech" % kind)
	if lines.size()<before+2:_fail("%s nobody answered the ruler (%d→%d lines)" % [kind,before,lines.size()])
	if capture and kind in ["threat","petition","request","news","report"]:
		await _capture("%s-%s-scene" % [kind,mode])
	# Choose: petitions issue their decree; others take the first enabled option.
	var chosen:=""
	for option in options:
		if kind=="petition" and String(option.id)=="decree" and bool(option.enabled):chosen="decree"
	if chosen=="":
		for option in options:
			if bool(option.enabled):chosen=String(option.id);break
	var decrees_before:=terrain.decrees.size()
	var result:Dictionary=modal.choose(chosen)
	if not bool(result.get("ok",false)):_fail("%s resolve(%s) failed: %s" % [kind,chosen,result])
	if kind=="petition" and chosen=="decree" and terrain.decrees.size()!=decrees_before+1:_fail("petition decree was not routed to the civic pipeline")
	if String(Hall.find(id).get("status",""))!="resolved":_fail("%s not resolved" % kind)
	var receipt:=modal.find_child("ReceiptText",true,false) as Label
	if receipt==null or receipt.text.is_empty():_fail("%s outcome receipt missing" % kind)
	await _frames(2)
	if modal.card.size.y>modal.DESIGN_SIZE.y+1.0:_fail("%s resolved card grew past its design height: %s" % [kind,modal.card.size])
	await _wait_scene(modal,id,Hall.find(id).get("lines",[]).size()+1,6.0)
	if capture and kind in ["gift","threat","request"]:
		await _capture("%s-%s-resolved" % [kind,mode])
	var dismiss:=modal.find_child("Dismiss",true,false) as Button
	if dismiss==null:_fail("%s dismiss button missing" % kind)
	else:dismiss.pressed.emit()
	await _frames(2)
	if is_instance_valid(modal):_fail("%s modal did not close" % kind)
	if terrain.game_speed==0.0:_fail("%s modal did not release the pause" % kind)
	print("AUDIENCE_MODAL kind=%s mode=%s lines=%d option=%s outcome=%s" % [kind,mode,Hall.find(id).get("lines",[]).size(),chosen,String(result.get("outcome",""))])

func _exercise_defer(director:Node,terrain:TerrainDouble)->void:
	HudTokens.set_color_mode("light")
	var first:=Hall.debug_force("news")
	var second:=Hall.debug_force("petition")
	if first.is_empty() or second.is_empty():_fail("defer setup failed");return
	var modal:Control=director.open_audience(String(first.id))
	await _frames(3)
	if not modal.next_button.visible:_fail("queue indicator hidden with %d waiting" % Hall.waiting().size())
	modal.summon_check.button_pressed=false
	if bool(Hall.state().summon_immediately):_fail("summon checkbox not bound to state")
	modal.summon_check.button_pressed=true
	modal.receive_next()
	await _frames(2)
	if modal.audience_id!=String(second.id):_fail("receive next did not advance")
	modal.make_them_wait()
	await _frames(2)
	if is_instance_valid(modal):_fail("make them wait did not close")
	if String(Hall.find(String(second.id)).status)!="waiting":_fail("deferred audience no longer waits")
	director._refresh_badge()
	await _frames(2)
	if not director.badge.visible:_fail("antechamber badge hidden with audiences waiting")
	if capture:await _capture("antechamber-badge-light")
	director.open_next()
	await _frames(2)
	if not is_instance_valid(director.modal):_fail("badge did not reopen the hall")
	else:
		director.modal.make_them_wait();await _frames(2)
	print("AUDIENCE_MODAL defer/queue/badge ok waiting=%d" % Hall.waiting().size())

func _capture(label:String)->void:
	await _frames(4)
	await RenderingServer.frame_post_draw
	var path:=out_dir+"audience-"+label+".png"
	get_viewport().get_texture().get_image().save_png(path)
	print("AUDIENCE_MODAL capture ",path)

func _dump(node:Node,depth:int)->void:
	if depth>9:return
	if node is Control and (node as Control).get_combined_minimum_size().y>600:
		print("  ".repeat(depth),node.name," ",node.get_class()," min=",(node as Control).get_combined_minimum_size())
		for child in node.get_children():_dump(child,depth+1)
