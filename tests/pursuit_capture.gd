extends Control
## TEST CAPTURE (not the game): the war chart round Tsaren with part of its
## garrison out after the men who fled. The user's sequence goes through the
## real court engine ("Kill all the men of Tsaren", "Yeah, go ahead and chase
## them"), the detachment walks a day, and war_front_overlay.gd draws the
## garrison card on the town and the detachment as its own band.
## --mode=before redraws what the user saw from the same world: the full
## count on a garrison card at the world's own site for the region (which our
## chart does not show there) and our band at the town "reported 14 days ago".
## Run only through tools/run_isolated_gpu_probe.ps1 with
## -- --capture-dir=<absolute dir> [--mode=before|after]. Quits by itself.

const Overlay:=preload("res://scripts/hud/war_front_overlay.gd")
const CC:=preload("res://scripts/court_commands.gd")
const Hall:=preload("res://scripts/audience_hall.gd")
const Pursuit:=preload("res://scripts/pursuit.gd")
const Marks:=preload("res://scripts/hud/army_marks.gd")

var directory:=""
var mode:="after"
var overlay:Control
var home:=Vector2.ZERO
var city:=Vector2.ZERO
var site:=Vector2.ZERO
var stonefield:=Vector2.ZERO
var lines:=PackedStringArray()
var frames:=0
var view_centre:=Vector2.ZERO
var view_scale:=14.0

func _land(_p:Vector2)->bool:
	return true

func _ready()->void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	get_tree().create_timer(60.0).timeout.connect(func():get_tree().quit(3))
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-dir="): directory=argument.trim_prefix("--capture-dir=")
		if argument.begins_with("--mode="): mode=argument.trim_prefix("--mode=")
	if directory=="": directory=ProjectSettings.globalize_path("res://artifacts/pursuit")
	DirAccess.make_dir_recursive_absolute(directory)
	var band:=_world()
	var audience:=Hall.summon({"figure_id":String((band.commander as Dictionary).get("figure_id",""))})
	var id:=String(audience.id)
	var kill:=CC.hear(id,"Kill all the men of Tsaren")
	var chase:=CC.hear(id,"Yeah, go ahead and chase them")
	lines.append("Kill: "+String(kill.get("actor_says","")))
	lines.append("Chase: "+String(chase.get("actor_says","")))
	GameState.elapsed_days+=1; MilitaryCampaign._process_field_army_movement_day()
	var friendly:Array=[]
	var garrisons:Array=[]
	var today:=int(GameState.elapsed_days)
	var rovik:Dictionary=MilitaryCampaign.field_armies[MilitaryCampaign._field_army_index(int(band.army_id))]
	var rovik_pos:=Vector2(float(rovik.position.x),float(rovik.position.z))
	if mode=="before":
		var whole:=int(MilitaryCampaign.occupation_force_for_region(String(CivilizationSystem.civilizations[0].id),String(rovik.location_id)).get("troops",0))+Pursuit.away_from(String(rovik.location_id))
		garrisons=[{"region_id":"x","pos":site,"troops":whole,"town":"Tsaren","general":"Rovik Longstride","fate_note":"15 killed"}]
		friendly=[_band(rovik,rovik_pos,{"status":"stationed","location_name":"Tsaren","home_km":rovik_pos.distance_to(home)},14,"")]
	else:
		garrisons=Overlay._garrison_inputs()
		friendly=[_band(rovik,rovik_pos,{"status":"stationed","location_name":"Tsaren","home_km":rovik_pos.distance_to(home)},0,"")]
		for a in MilitaryCampaign.field_armies:
			if (a as Dictionary).get("pursuit") is Dictionary:
				var at:=Vector2(float(a.position.x),float(a.position.z))
				friendly.append(_band(a,at,{"status":String(a.status),"pursuit":Pursuit.doing_words(a)},0,"Tsaren"))
				lines.append("Detachment: %d, %s" % [int(a.troops),Pursuit.doing_words(a)])
	lines.append("Town badge: %s" % String(preload("res://scripts/map_ownership.gd").status({"city_id":String(rovik.location_id)}).note))
	for l in lines: print("PURSUIT CAPTURE ",l)
	view_centre=city+Vector2(0,-6)
	overlay=Overlay.new(); add_child(overlay)
	overlay.project=func(p:Vector2)->Vector2: return size*0.5+(p-view_centre)*view_scale
	overlay.band_override="local"
	overlay.set_scene(Overlay.compose({"mode":"host","stage":"hearth","home":home,"today":today,"friendly":friendly,"enemy":[],"raids":[],"engagements":[],"garrisons":garrisons}),true)
	queue_redraw()

func _band(army:Dictionary,pos:Vector2,context:Dictionary,age:int,detached:String)->Dictionary:
	return {"id":str(army.army_id),"army_id":int(army.army_id),"pos":pos,"strength":float(army.troops),"objective":Vector2.INF,"offensive":false,"name":String(army.name),
		"era":0,"branch":"foot","general":String((army.get("commander",{}) as Dictionary).get("name","")),"selected":false,"condition":"worn" if detached=="" else "intact",
		"report_age":age,"doing_context":context,"detachment_of":detached}

func _world()->Dictionary:
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
	civ["name"]="Esurai"
	civ.player_relation.at_war=true; civ.player_relation.contact_level=2
	var ri:=CivilizationSystem._frontline_region_index(civ)
	var region:Dictionary=civ.strategic_regions[ri]
	region["name"]="Tsaren"; region["population"]=90.0
	var city_id:=String(region.id)
	CivilizationSystem.city_intelligence.publish("player",CivilizationSystem.city_intelligence.capture("player",city_id,.8,int(GameState.elapsed_days),"scout report","capture"),int(GameState.elapsed_days))
	home=CivilizationSystem.player_world_origin
	city=home+Vector2(-20.0,8.0)
	CivilizationSystem.city_intelligence.records.player[city_id]["position"]={"x":city.x,"z":city.y}
	site=Pursuit._v2(CivilizationSystem.city_intelligence.site(city_id).get("position",{}))
	# The world's site lies north of the town our chart shows, as in the user's game.
	if not site.is_finite() or site.distance_to(city)>40.0 or site.distance_to(city)<5.0:
		site=city+Vector2(3.0,-22.0)
	CivilizationSystem.set_scout_geography_authority(Callable(self,"_land"))
	MilitaryCampaign.military_inventory["improvised"]=int(MilitaryCampaign.military_inventory.get("improvised",0))+18
	MilitaryCampaign.raise_recruits(18)
	MilitaryCampaign.start_training("levy","improvised",18)
	MilitaryCampaign._complete_training(MilitaryCampaign.training_queue[0].duplicate(true))
	MilitaryCampaign.training_queue.clear()
	MilitaryCampaign.create_field_army(18,"LEVY BAND 1")
	var army:Dictionary=MilitaryCampaign.field_armies[0]
	army["supply_level"]=1.0; army["readiness"]=1.0
	army["position"]={"x":city.x+0.6,"z":city.y+0.4}
	army["location_id"]=city_id; army["location_name"]="Tsaren"; army["status"]="stationed"
	civ.strategic_regions[ri]["controller"]="player"
	var factor:=maxf(.05,1.0*(.5+.5*clampf(.9,.15,1.0)))
	MilitaryCampaign.establish_occupation_force(String(civ.id),civ.strategic_regions[ri],floorf(17.0*factor),int(army.army_id))
	var to:=Pursuit.refuge(String(civ.id),city_id)
	civ.strategic_regions[CivilizationSystem._region_index(civ,String(to.region_id))]["name"]="Stonefield"
	stonefield=Pursuit._v2(to.position)
	return MilitaryCampaign.field_armies[MilitaryCampaign._field_army_index(int(army.army_id))]

func _to_screen(p:Vector2)->Vector2:
	return size*0.5+(p-view_centre)*view_scale

func _draw()->void:
	draw_rect(Rect2(Vector2.ZERO,size),Color("#c9bd96"))
	var font:=ThemeDB.fallback_font
	for place in [[city,"Tsaren (on our chart)"],[home,"Seanstone"]]:
		var at:=_to_screen(place[0])
		draw_circle(at,7,Color("#2b2a26"))
		draw_string(font,at+Vector2(10,20),String(place[1]),HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("#2b2a26"))
	if stonefield.is_finite():
		var dir:=(stonefield-city).normalized()
		var edge:=_to_screen(city)+dir*380.0
		draw_line(_to_screen(city),edge,Color("#2b2a26",0.35),1.5,true)
		draw_string(font,edge+Vector2(6,0),"to Stonefield",HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("#2b2a26"))
	draw_string(font,Vector2(24,34),"TEST CAPTURE — not the game. %s: Tsaren, a day after \"Yeah, go ahead and chase them\"." % mode.to_upper(),HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("#2b2a26"))
	var y:=size.y-24.0*lines.size()-10.0
	for l in lines:
		draw_string(font,Vector2(24,y),l.substr(0,200),HORIZONTAL_ALIGNMENT_LEFT,size.x-48,14,Color("#2b2a26")); y+=24.0

func _process(_delta:float)->void:
	if overlay==null: return
	frames+=1
	if frames==6:
		var file:=directory.path_join("pursuit_%s.png" % mode)
		get_viewport().get_texture().get_image().save_png(file)
		print("PURSUIT CAPTURE PASS ",file)
		get_tree().quit(0)
