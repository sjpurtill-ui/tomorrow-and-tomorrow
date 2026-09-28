extends Control
## TEST CAPTURE (not the game): a march across varied ground on the war map.
## A fixture chart (a mountain wall with one pass, a wood, a river with a
## ford, a cart track) is painted underneath; the order goes through the real
## court engine, the army walks the terrain-weighed road (march_terrain.gd)
## for some days, and war_front_overlay.gd draws its arrow along that road.
## Run only through tools/run_isolated_gpu_probe.ps1 with
## -- --capture-dir=<absolute dir> [--days=N]. Quits by itself.

const Overlay:=preload("res://scripts/hud/war_front_overlay.gd")
const CC:=preload("res://scripts/court_commands.gd")
const Hall:=preload("res://scripts/audience_hall.gd")
const March:=preload("res://scripts/march_terrain.gd")
const Route:=preload("res://scripts/army_land_route.gd")

var directory:=""
var overlay:Control
var home:=Vector2.ZERO
var city:=Vector2.ZERO
var reply:=""
var doing:=""
var frames:=0
var view_centre:=Vector2.ZERO
var view_scale:=11.0
var days:=5
var road_points:=PackedVector2Array()

func _land(_p:Vector2)->bool: return true

## Local chart features (km from home).
func _ground(p:Vector2)->Dictionary:
	var u:=p-home
	if u.x>=-38.0 and u.x<=-30.0:
		if u.y>=30.0 and u.y<=36.0: return {"h":0.6,"slope":0.06,"wood":0.0,"wet":0.0}
		return {"h":2.5,"slope":0.55,"wood":0.0,"wet":0.0}
	if u.distance_to(Vector2(-15,12))<8.0: return {"h":0.3,"slope":0.0,"wood":0.9,"wet":0.0}
	return {"h":0.25,"slope":0.01,"wood":0.0,"wet":0.0}

func _crossing(a:Vector2,b:Vector2)->String:
	var ua:=a-home; var ub:=b-home
	if (ua.x+48.0)*(ub.x+48.0)>0.0 or is_equal_approx(ua.x,ub.x): return ""
	var z:=lerpf(ua.y,ub.y,(-48.0-ua.x)/(ub.x-ua.x))
	return "ford" if z>=18.0 and z<=22.0 else "deep"

func _ready()->void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-dir="): directory=argument.trim_prefix("--capture-dir=")
		if argument.begins_with("--days="): days=maxi(0,int(argument.trim_prefix("--days=")))
	if directory=="": directory=ProjectSettings.globalize_path("res://artifacts/march_terrain")
	DirAccess.make_dir_recursive_absolute(directory)
	_world()
	# The march order itself (the same MilitaryCampaign call a court or Army
	# screen order ends in): a host of 300 to Tsaren.
	CivilizationSystem.revealed_areas=[{"x":home.x,"z":home.y,"radius":300.0}]
	var made:Dictionary=MilitaryCampaign.create_field_army(300,"Host of Seanstone")
	if made.has("error"):
		printerr("MARCH TERRAIN CAPTURE FAIL: ",made.error); get_tree().quit(1); return
	var army_id:=int((made.army as Dictionary).army_id)
	var order:Dictionary=MilitaryCampaign.move_field_army_to_position(army_id,city.x,city.y,"Tsaren")
	reply=String(order.get("message",order.get("error","")))
	print("ORDER: ",reply)
	var index:=MilitaryCampaign._field_army_index(army_id)
	if index<0:
		printerr("MARCH TERRAIN CAPTURE FAIL: no army"); get_tree().quit(1); return
	var stated:=int(MilitaryCampaign.field_armies[index].arrival_day)-int(GameState.elapsed_days)
	var origin:=Vector2(float(MilitaryCampaign.field_armies[index].position.x),float(MilitaryCampaign.field_armies[index].position.z))
	road_points=PackedVector2Array([origin])
	for p in MilitaryCampaign.field_armies[index].march_route: road_points.append(Vector2(float(p.x),float(p.z)))
	for day in days:
		GameState.elapsed_days+=1; MilitaryCampaign._process_field_army_movement_day()
	var army:Dictionary=MilitaryCampaign.field_armies[index]
	var pos:=Vector2(float(army.position.x),float(army.position.z))
	var objective:=Vector2(float(army.destination_position.x),float(army.destination_position.z))
	var days_left:=int(army.arrival_day)-int(GameState.elapsed_days)
	print("MARCH TERRAIN: stated %d days at the order; after %d days %d left; road %.0f km (straight %.0f km)" % [stated,days,days_left,float(army.distance_total_km),home.distance_to(city)])
	var context:={"status":"moving","destination_name":String(army.destination_name),"destination_id":String(army.destination_id),"location_name":"","command_status":"","at_home":false,"delta":objective-pos,"days_left":days_left}
	var friendly:=[{"id":str(army_id),"army_id":army_id,"pos":pos,"strength":float(army.troops),"objective":objective,"offensive":true,"name":String(army.name),"road":Overlay._road_ahead(army,pos),"days_left":days_left,
		"era":0,"branch":"foot","general":String((army.get("commander",{}) as Dictionary).get("name","")),"selected":true,"condition":"intact","report_age":0,"doing_context":context}]
	doing=preload("res://scripts/hud/army_marks.gd").doing(context)
	print("MARK: ",String(army.name)," — ",doing)
	view_centre=home+Vector2(-30,16)
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
	GameState.elapsed_days=88*365+120
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
	March.reset_overrides()
	March.ground_override=Callable(self,"_ground")
	March.crossing_override=Callable(self,"_crossing")
	March.use_roads_override=true
	March.roads_override=[{"a":home,"b":home+Vector2(-28,32),"tier":1}]
	Route.clear_cache()
	MilitaryCampaign.raise_recruits(400)
	MilitaryCampaign.start_training("levy","improvised",400)
	MilitaryCampaign._complete_training(MilitaryCampaign.training_queue[0].duplicate(true))
	MilitaryCampaign.training_queue.clear()

func _to_screen(p:Vector2)->Vector2:
	return size*0.5+(p-view_centre)*view_scale

func _draw()->void:
	draw_rect(Rect2(Vector2.ZERO,size),Color("#b9ad86"))
	var font:=ThemeDB.fallback_font
	# The wood.
	draw_circle(_to_screen(home+Vector2(-15,12)),8.0*view_scale,Color("#6f7f52"))
	# The mountain wall and its pass.
	for band in [[-200.0,30.0],[36.0,200.0]]:
		var a:=_to_screen(home+Vector2(-38.0,float(band[0]))); var b:=_to_screen(home+Vector2(-30.0,float(band[1])))
		draw_rect(Rect2(a,b-a),Color("#8a8479"))
	draw_string(font,_to_screen(home+Vector2(-37.5,-6)),"mountains",HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("#2b2a26"))
	draw_string(font,_to_screen(home+Vector2(-37.5,33.5)),"pass",HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("#2b2a26"))
	# The river, deep but for its ford.
	draw_line(_to_screen(home+Vector2(-48,-200)),_to_screen(home+Vector2(-48,200)),Color("#5f7f8c"),5.0)
	draw_line(_to_screen(home+Vector2(-48,18)),_to_screen(home+Vector2(-48,22)),Color("#c9d8d4"),5.0)
	draw_string(font,_to_screen(home+Vector2(-47,20.5)),"ford",HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("#2b2a26"))
	# Our cart track.
	draw_line(_to_screen(home),_to_screen(home+Vector2(-28,32)),Color("#6b5433"),3.0)
	draw_string(font,_to_screen(home+Vector2(-12,20)),"cart track",HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("#2b2a26"))
	for place in [[home,"Seanstone"],[city,"Tsaren"]]:
		var at:=_to_screen(place[0])
		draw_circle(at,6,Color("#2b2a26"))
		draw_string(font,at+Vector2(10,-8),String(place[1]),HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color("#2b2a26"))
	draw_dashed_line(_to_screen(home),_to_screen(city),Color("#2b2a26",0.35),1.5,8.0)
	# The whole road the general chose, thin, under the overlay's arrow.
	for k in road_points.size()-1:
		draw_line(_to_screen(road_points[k]),_to_screen(road_points[k+1]),Color("#2b2a26",0.55),1.5)
	draw_string(font,Vector2(24,36),"TEST CAPTURE — not the game. Court order: \"Send our full forces into battle on Tsaren\", %d days later." % days,HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("#2b2a26"))
	draw_string(font,Vector2(24,size.y-58),reply.substr(0,190),HORIZONTAL_ALIGNMENT_LEFT,size.x-48,15,Color("#2b2a26"))
	draw_string(font,Vector2(24,size.y-32),"Mark: "+doing+"   (dashed: the straight line over the mountains; thin line: the general's road)",HORIZONTAL_ALIGNMENT_LEFT,size.x-48,15,Color("#2b2a26"))

func _process(_delta:float)->void:
	if overlay==null: return
	frames+=1
	if frames==6:
		var file:=directory.path_join("march_terrain_day_%d.png" % days)
		get_viewport().get_texture().get_image().save_png(file)
		print("MARCH TERRAIN CAPTURE PASS ",file)
		March.reset_overrides()
		get_tree().quit(0)
