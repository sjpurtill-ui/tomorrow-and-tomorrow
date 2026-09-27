extends Control
## TEST CAPTURE (not the game): the war map a few days after the court order
## "Send our full forces into battle on Tsaren". A fixture chart with the
## user's geometry (Seanstone on the coast, Tsaren south-west across a bay)
## is painted underneath; the order goes through the real court engine
## (court_commands.hear -> court_war_orders), the army marches on the real
## land road for four days, and war_front_overlay.gd draws it.
## Run only through tools/run_isolated_gpu_probe.ps1 with
## -- --capture-dir=<absolute dir>. Quits by itself.

const Overlay:=preload("res://scripts/hud/war_front_overlay.gd")
const CC:=preload("res://scripts/court_commands.gd")
const Hall:=preload("res://scripts/audience_hall.gd")

var directory:=""
var overlay:Control
var home:=Vector2.ZERO
var city:=Vector2.ZERO
var reply:=""
var doing:=""
var frames:=0
var view_centre:=Vector2.ZERO
var view_scale:=9.0
var days:=4

func _land(p:Vector2)->bool:
	return p.distance_to((home+city)*0.5)>home.distance_to(city)*0.3

func _ready()->void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-dir="): directory=argument.trim_prefix("--capture-dir=")
		if argument.begins_with("--days="): days=maxi(0,int(argument.trim_prefix("--days=")))
	if directory=="": directory=ProjectSettings.globalize_path("res://artifacts/court_war_orders")
	DirAccess.make_dir_recursive_absolute(directory)
	_world()
	var marshal:=GovernmentPeopleSystem.officeholder("Marshal")
	var target:={"person_id":int(marshal.get("person_id",0))} if not marshal.is_empty() else {"person_id":int((Hall._officials()[0] as Dictionary).person_id)}
	var audience:=Hall.summon(target)
	var r:=CC.hear(String(audience.id),"Send our full forces into battle on Tsaren")
	reply=String(r.get("outcome",""))
	print("COURT REPLY: ",reply)
	var army_id:=int((r.get("objective",{}) as Dictionary).get("army_id",0))
	for day in days:
		GameState.elapsed_days+=1; MilitaryCampaign._process_field_army_movement_day()
	var index:=MilitaryCampaign._field_army_index(army_id)
	if index<0:
		printerr("COURT WAR CAPTURE FAIL: no army"); get_tree().quit(1); return
	var army:Dictionary=MilitaryCampaign.field_armies[index]
	var pos:=Vector2(float(army.position.x),float(army.position.z))
	var objective:=Vector2(float(army.destination_position.x),float(army.destination_position.z))
	var days_left:=int(army.arrival_day)-int(GameState.elapsed_days)
	var context:={"status":"moving","destination_name":String(army.destination_name),"destination_id":String(army.destination_id),"location_name":"","command_status":"","at_home":false,"delta":objective-pos,"days_left":days_left}
	var friendly:=[{"id":str(army_id),"army_id":army_id,"pos":pos,"strength":float(army.troops),"objective":objective,"offensive":true,"name":String(army.name),"road":Overlay._road_ahead(army,pos),"days_left":days_left,
		"era":0,"branch":"foot","general":String((army.get("commander",{}) as Dictionary).get("name","")),"selected":true,"condition":"intact","report_age":0,"doing_context":context}]
	doing=preload("res://scripts/hud/army_marks.gd").doing(context)
	print("MARK: ",String(army.name)," — ",doing)
	view_centre=(home+city)*0.5
	overlay=Overlay.new(); add_child(overlay)
	overlay.project=func(p:Vector2)->Vector2: return size*0.5+(p-view_centre)*view_scale
	overlay.band_override="regional"
	overlay.set_scene(Overlay.compose({"mode":"host","stage":"reckoned","home":home,"today":int(GameState.elapsed_days),"friendly":friendly,"enemy":[],"raids":[],"engagements":[]}),true)
	queue_redraw()

func _world()->void:
	WorldSimulation.clear()
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	GameState.reset_for_new_world(74017);GameState.civic_api_enabled=false
	DiscoverySystem.reset_for_new_world();FoodSystem.reset_for_new_world();MilitaryCampaign.reset_for_new_world();CivilizationSystem.reset_for_new_world()
	ForeignDiplomacy.reset_for_new_world();ForeignDiplomacy.ensure();GovernmentPeopleSystem.reset_for_new_world()
	GameState.ensure_population_total(900);GameState.housing_capacity=1000
	GameState.settlement_site_committed=true;GameState.settlement_completed=["Hearth Circle"];SettlementModel.ensure_founded()
	GameState.select_founding_focus("provision");GameState.settlement_name="Seanstone"
	GameState.society_capacities["institutions"]=0.4
	GovernmentPeopleSystem._update_government_stage(false);GovernmentPeopleSystem.initialize()
	GameState.resource_stockpiles["Food"]=1000000.0
	GameState.elapsed_days=88*365
	var civ:Dictionary=CivilizationSystem.civilizations[0]
	civ["name"]="Tsaren"
	var region:Dictionary=civ.strategic_regions[CivilizationSystem._frontline_region_index(civ)]
	region["name"]="Tsaren"
	var city_id:=String(region.id)
	CivilizationSystem.city_intelligence.publish("player",CivilizationSystem.city_intelligence.capture("player",city_id,.8,int(GameState.elapsed_days),"scout report","capture"),int(GameState.elapsed_days))
	home=CivilizationSystem.player_world_origin
	city=home+Vector2(-60.0,24.0)
	var rec:Dictionary=CivilizationSystem.city_intelligence.records.player[city_id]
	rec["position"]={"x":city.x,"z":city.y}
	rec.fields["garrison"]={"low":40.0,"high":40.0,"observed_day":int(GameState.elapsed_days),"reported_day":int(GameState.elapsed_days)}
	CivilizationSystem.set_scout_geography_authority(Callable(self,"_land"))
	MilitaryCampaign.raise_recruits(400)
	MilitaryCampaign.start_training("levy","improvised",400)
	MilitaryCampaign._complete_training(MilitaryCampaign.training_queue[0].duplicate(true))
	MilitaryCampaign.training_queue.clear()

func _to_screen(p:Vector2)->Vector2:
	return size*0.5+(p-view_centre)*view_scale

func _draw()->void:
	draw_rect(Rect2(Vector2.ZERO,size),Color("#b9ad86"))
	var bay:=(home+city)*0.5
	draw_circle(_to_screen(bay),home.distance_to(city)*0.3*view_scale,Color("#6f8f98"))
	draw_arc(_to_screen(bay),home.distance_to(city)*0.3*view_scale,0,TAU,96,Color("#3b3a33"),2.0,true)
	var font:=ThemeDB.fallback_font
	for place in [[home,"Seanstone"],[city,"Tsaren"]]:
		var at:=_to_screen(place[0])
		draw_circle(at,6,Color("#2b2a26"))
		draw_string(font,at+Vector2(10,-8),String(place[1]),HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color("#2b2a26"))
	draw_dashed_line(_to_screen(home),_to_screen(city),Color("#2b2a26",0.35),1.5,8.0)
	draw_string(font,Vector2(24,36),"TEST CAPTURE — not the game. Court order: \"Send our full forces into battle on Tsaren\", %d days later." % days,HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("#2b2a26"))
	draw_string(font,Vector2(24,size.y-58),reply.substr(0,170),HORIZONTAL_ALIGNMENT_LEFT,size.x-48,15,Color("#2b2a26"))
	draw_string(font,Vector2(24,size.y-32),"Mark: "+doing+"   (dashed line: the straight line across the bay, which the march no longer needs)",HORIZONTAL_ALIGNMENT_LEFT,size.x-48,15,Color("#2b2a26"))

func _process(_delta:float)->void:
	if overlay==null: return
	frames+=1
	if frames==6:
		var file:=directory.path_join("court_war_march_day_%d.png" % days)
		get_viewport().get_texture().get_image().save_png(file)
		print("COURT WAR CAPTURE PASS ",file)
		get_tree().quit(0)
