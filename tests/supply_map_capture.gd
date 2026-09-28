extends Node
## TEST CAPTURE (not the game): the supply map on the real terrain.
## Run only through tools/run_isolated_gpu_probe.ps1, e.g.
##   res://tests/supply_map_capture.tscn -- --scene=early|late --zoom=region|continent --out=<png> [--tip]
## early: the first years, porters only, one band of 30 out on a foray.
## late: carts and a made road, three bands out, a town we hold with its
##   garrison, and a band besieging a town beyond it.
## Turns the map on with the toolbar's own Supply button, waits for the
## supply field and the day's paint, and saves one PNG. Never saves a game;
## quits by itself.
const Supply:=preload("res://scripts/supply_state.gd")
const SupplyMap:=preload("res://scripts/hud/supply_map.gd")
const March:=preload("res://scripts/march_terrain.gd")
const Route:=preload("res://scripts/army_land_route.gd")

var terrain:Node
var scene:="early"
var zoom:="region"
var out:=""
var tip:=false
var home:=Vector2.ZERO
var look_at:=Vector2.ZERO

func _ready()->void:
	get_tree().create_timer(170.0).timeout.connect(func(): print("SUPPLY_MAP_CAPTURE TIMEOUT"); get_tree().quit(3))
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--scene="): scene=arg.trim_prefix("--scene=")
		elif arg.begins_with("--zoom="): zoom=arg.trim_prefix("--zoom=")
		elif arg.begins_with("--out="): out=arg.trim_prefix("--out=")
		elif arg=="--tip": tip=true
	GameState.reset_for_new_world(74017);GameState.civic_api_enabled=false
	DiscoverySystem.reset_for_new_world();ProgressionSystem.reset_for_new_world();ResourceSystem.reset_for_new_world();FoodSystem.reset_for_new_world();ConsequenceEngine.reset_for_new_world();CivilizationSystem.reset_for_new_world();MilitaryCampaign.reset_for_new_world()
	GameState.select_founding_focus("provision")
	GameState.settlement_site_committed=true;GameState.settlement_completed=["Hearth Circle"];SettlementModel.ensure_founded()
	GameState.settlement_name="Seanstone"
	terrain=preload("res://local_terrain.tscn").instantiate();add_child(terrain);terrain._set_game_speed(0)
	for f in 8: await get_tree().process_frame
	if is_instance_valid(terrain.get("founding_focus_panel")): terrain.founding_focus_panel.queue_free(); terrain.founding_focus_panel=null
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	home=CivilizationSystem.player_world_origin
	Supply.reset()
	if scene=="late": _stage_late()
	else: _stage_early()
	# The field for the day's rations, then the day's rations themselves.
	var waited:=0
	while not Supply.current() and waited<600:
		Supply.prefetch(); await get_tree().process_frame; waited+=1
	_ration_day()
	# The toolbar's own button turns the map on.
	var button:Button=terrain.hud.find_child("ToolbarSupply",true,false)
	print("SUPPLY BUTTON ",button!=null)
	if button!=null: button.button_pressed=true
	else: SupplyMap.ensure(terrain).set_enabled(true)
	var map:Node=SupplyMap.find(terrain)
	# The view.
	var level:=2 if zoom=="region" else 3
	terrain.set_camera_distance_level(level)
	terrain.camera.size=float(terrain.zoom_target_size)
	terrain.zoom_target_size=-1.0
	terrain.zoom_preset_active=false
	terrain._set_camera_target(Vector3(look_at.x,terrain._height_at(look_at.x,look_at.y),look_at.y))
	terrain._update_camera()
	terrain._update_scale_lod()
	for f in 3: await get_tree().process_frame
	for stream_pass in 2:
		var guard:=0
		while terrain.get("terrain_patch_job")!=null and guard<2000:
			terrain._advance_terrain_patch(); await get_tree().process_frame; guard+=1
		terrain._update_world_streaming()
	terrain._update_scale_lod()
	waited=0
	while (int(map.get("paints"))<1 or map.get("_job")!=null) and waited<900:
		await get_tree().process_frame; waited+=1
	for f in 20: await get_tree().process_frame
	if tip:
		var chart:Control=map.get("chart")
		var marks:Array=chart.get("marks")
		for mark:Dictionary in marks:
			if String(mark.id).begins_with("army:"):
				var at:Vector2=chart.call("_screen",mark.pos,float(mark.h))
				(map.get("key_card") as Control).call("show_tip",chart.call("_force_tip",mark.report),at+Vector2(0,-24))
				break
	for f in 6: await get_tree().process_frame
	RenderingServer.force_sync()
	RenderingServer.force_draw(true,0.0)
	await get_tree().process_frame
	var summary:=[]
	for r:Dictionary in Supply.forces(): summary.append("%s %s: %s" % [String(r.force_kind),String(r.get("name","")),String(r.words)])
	print("SUPPLY_MAP_CAPTURE scene=",scene," zoom=",zoom," paints=",map.get("paints")," paint_ms=",map.get("paint_ms")," field_ms=",Supply._field.get("ms",0.0)," cell_km=",Supply._field.get("cell",0.0))
	for line in summary: print("  ",line)
	if out!="" and DisplayServer.get_name()!="headless":
		var image:=get_viewport().get_texture().get_image()
		if image: image.save_png(out)
	print("SUPPLY_MAP_CAPTURE PASS ",out)
	Supply.shutdown()
	get_tree().quit(0)

## A point on land near the one asked for (the land authority's own test).
func _land_near(want:Vector2)->Vector2:
	for ring in 12:
		for k in 16:
			var p:=want+Vector2.from_angle(TAU*float(k)/16.0)*float(ring)*6.0
			if terrain._scout_land_at(p): return p
	return want

func _know(radius:float)->void:
	CivilizationSystem.revealed_areas.assign([{"kind":"circle","x":home.x,"z":home.y,"radius":radius,"day":0}])
	CivilizationSystem.fog_revision+=1

func _reveal(at:Vector2,radius:float)->void:
	CivilizationSystem.revealed_areas.append({"kind":"circle","x":at.x,"z":at.y,"radius":radius,"day":int(GameState.elapsed_days)})
	CivilizationSystem.fog_revision+=1

## The warm half of the year for home's hemisphere: the season wave's height.
func _summer()->void:
	var hemisphere:=-1.0 if home.y>0.0 else 1.0
	var warmest:=0; var high:=-INF
	for d in range(0,365,5):
		var w:=sin(float(d)/365.0*TAU)*hemisphere
		if w>high: high=w; warmest=d
	GameState.elapsed_days=365*6+warmest

func _band(id:int,at:Vector2,troops:int,name:String,leader:String)->Dictionary:
	return {"army_id":id,"name":name,"troops":troops,"status":"stationed","location_id":"field","position":{"x":at.x,"z":at.y},
		"formations":[{"unit":"levy","count":troops}],"supply_level":0.8,"readiness":0.8,"commander":{"name":leader,"logistics":0.45},"hungry_days":0.0}

func _stage_early()->void:
	_summer()
	GameState.ensure_population_total(160);GameState.housing_capacity=200
	GameState.population_allocations.Logistics=5
	MilitaryCampaign.home_army=MilitaryCampaign._empty_home_army()
	MilitaryCampaign.home_army.troops=20
	var out_at:=_land_near(home+Vector2.from_angle(0.6)*78.0)
	_know(120.0); _reveal(out_at,40.0)
	MilitaryCampaign.field_armies.assign([_band(7,out_at,30,"Rovik's band","Rovik Ashdown")])
	look_at=home.lerp(out_at,0.45) if zoom=="region" else home

func _stage_late()->void:
	_summer()
	GameState.elapsed_days+=365*40
	GameState.ensure_population_total(2600);GameState.housing_capacity=3000
	GameState.population_allocations.Logistics=60
	GameState.resource_stockpiles["Transport Carts"]=40.0
	MilitaryCampaign.home_army=MilitaryCampaign._empty_home_army()
	MilitaryCampaign.home_army.troops=120
	_know(520.0)
	# A town of theirs we took, and one beyond it we lay siege to.
	var civ:Dictionary=CivilizationSystem.civilizations[0]
	civ["name"]="Esurai"
	var regions:Array=civ.strategic_regions
	var held_region:Dictionary=regions[CivilizationSystem._frontline_region_index(civ)]
	held_region["name"]="Tsaren"
	var town:=_land_near(home+Vector2.from_angle(-0.4)*120.0)
	var day:=int(GameState.elapsed_days)
	CivilizationSystem.city_intelligence.publish("player",CivilizationSystem.city_intelligence.capture("player",String(held_region.id),.8,day,"field campaign report","capture"),day)
	CivilizationSystem.city_intelligence.records.player[String(held_region.id)]["position"]={"x":town.x,"z":town.y}
	held_region["controller"]="player"; held_region["resistance"]=0.35
	MilitaryCampaign.occupation_forces.assign([{"civ_id":String(civ.id),"region_id":String(held_region.id),"region_name":"Tsaren","troops":40,"formations":[{"unit":"levy","count":40}],"supply_level":0.9,"commander":{"name":"Suri Vell"}}])
	_reveal(town,60.0)
	# Our roads: a made road to Tsaren, a cart track north.
	March.use_roads_override=true
	var north:=_land_near(home+Vector2.from_angle(1.9)*110.0)
	March.roads_override=[{"a":home,"b":town,"tier":2},{"a":home,"b":north,"tier":1}]
	var siege_at:=_land_near(town+Vector2.from_angle(-0.25)*70.0)
	var near:=_land_near(home+Vector2.from_angle(1.9)*60.0)
	var far:=_land_near(home+Vector2.from_angle(3.0)*330.0)
	_reveal(siege_at,50.0); _reveal(far,60.0)
	MilitaryCampaign.field_armies.assign([
		_band(7,siege_at,420,"Host of Seanstone","Rovik Ashdown"),
		_band(8,near,160,"Northern levy","Kavu Tern"),
		_band(9,far,260,"Western raiders","Oda Marr")])
	# The town beyond, under siege (the record military_campaign keeps).
	var target_region:Dictionary=regions[(CivilizationSystem._frontline_region_index(civ)+1)%regions.size()]
	target_region["name"]="Kelvra"
	CivilizationSystem.city_intelligence.publish("player",CivilizationSystem.city_intelligence.capture("player",String(target_region.id),.7,day,"field campaign report","siege"),day)
	var target:=_land_near(siege_at+Vector2.from_angle(-0.25)*6.0)
	CivilizationSystem.city_intelligence.records.player[String(target_region.id)]["position"]={"x":target.x,"z":target.y}
	MilitaryCampaign.active_siege={"id":"siege_capture","active":true,"mode":"offensive","attacker_id":"player","defender_id":String(civ.id),"start_day":day-12,"last_day":day,"days":12,
		"target_position":{"x":target.x,"z":target.y},"region_id":String(target_region.id),"army_id":7,
		"threat":{"target_region_name":"Kelvra","target_region_id":String(target_region.id),"source_name":"Esurai","campaign_mode":"offensive"},
		"pressure":0.3,"fatigue":0.1,"blockade":0.4,"hardship":0.2,"starving_days":0,"relief":[]}
	look_at=town.lerp(siege_at,0.35) if zoom=="region" else home

## A day's rations for everyone out (food_system's call), full stores.
func _ration_day()->void:
	var need:=0.0
	for a in MilitaryCampaign.field_armies: need+=float(a.troops)
	for g in MilitaryCampaign.occupation_forces: need+=float(g.troops)
	need+=float(MilitaryCampaign.home_army.troops)
	var credit:Dictionary=MilitaryCampaign.draw_delivered_field_rations(need)
	var accessible:=(need-float(credit.total))*MilitaryCampaign.field_provision_delivery_ratio(need,credit)
	MilitaryCampaign.record_daily_provisions(need,accessible,credit)
