extends "res://tests/border_defense_capture.gd"
## Authored staff-era exercise on copied terrain. Troops/development/enemy
## stations are fixture setup; council allocation, marches, observations,
## contact battles, reports and collect -> compose -> draw are production.
const Council := preload("res://scripts/war_council.gd")
const War := preload("res://scripts/war_loop.gd")
const Forts := preload("res://scripts/fort_border.gd")
const Route := preload("res://scripts/army_land_route.gd")
var rival := ""
var focus := Vector2.ZERO
var crossings := 0

func _run() -> void:
	if not await _prepare():return
	scope="TEST authored staff-era armies and enemy stations on copied terrain; real council, movement, reports, observations, contact battle and unmodified overlay collection"
	capital_label.hide()
	caption.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	caption.custom_minimum_size=Vector2(760,0)
	caption.add_theme_font_size_override("font_size",14)
	(caption.get_parent() as Control).custom_minimum_size=Vector2(790,48)
	if not _interior():
		_check(false,"Dry interior found for the authored perimeter");await _finish();return
	_author_campaign()
	var result:Dictionary=Council.order(rival,"defend")
	_check(MilitaryCampaign.field_armies.size()==8,"Council creates eight real stations: "+str(result))
	if MilitaryCampaign.field_armies.size()!=8:day=int(GameState.elapsed_days);await _finish();return
	for _i in 8:
		GameState.elapsed_days+=1
		MilitaryCampaign._process_field_army_movement_day()
		MilitaryCampaign._process_army_runners_day()
	for bearing in 32:
		var direction:=Vector2.from_angle(TAU*float(bearing)/32.0)
		var contact:=Defense.first_contact(center+direction*35.0,center,MilitaryCampaign.field_armies,{"troops":500})
		if not contact.is_empty():crossings+=1
	_check(crossings==32,"All 32 perimeter approaches meet real deployed armies")
	_add_rivals()
	CivilizationSystem._process_local_observation(int(GameState.elapsed_days),true)
	day=int(GameState.elapsed_days)
	await _shot("perimeter","Eight council stations · normal army reports and observations",145.0,center)
	# Order two actual stationed bands forward. The ordinary swept movement
	# must discover contact and reserve both existing battle engagements.
	for index in 2:
		var army:Dictionary=MilitaryCampaign.field_armies[index]
		var position:=_point(army)
		var direction:=(position-center).normalized()
		var goal:=position+direction*4.0
		MilitaryCampaign.move_field_army_to_position(int(army.army_id),goal.x,goal.y,"Fixture advance through the held line")
	GameState.elapsed_days+=1;MilitaryCampaign._process_field_army_movement_day()
	MilitaryCampaign._process_army_runners_day()
	CivilizationSystem._process_local_observation(int(GameState.elapsed_days),true)
	day=int(GameState.elapsed_days)
	var collected:Dictionary=overlay.collect()
	_check((collected.battles as Array).size()>=2,"Two real contacts reach the normal battle collector")
	focus=_point(MilitaryCampaign.field_armies[0])
	await _shot("contact_local","Real contact · normal battle registry, no injected battle marks",38.0,focus)
	await _shot("crowded_small","1152 × 720 · multiple sectors and simultaneous contacts",120.0,center,Vector2i(1152,720))
	await _shot("continental","Automatic continental band · same armies and battles",900.0,center,Vector2i(1152,720))
	T.set_color_mode("dark")
	await _shot("night","Night palette · same contact, real map collection",38.0,focus,Vector2i(1152,720))
	_set_motion(true)
	await _shot("reduced","Reduced motion · readable held ground and contact",38.0,focus,Vector2i(1152,720))
	# Exercise the actual process path, without advancing any campaign day.
	terrain.call("_set_game_speed",0)
	var paused_clock:=float(overlay.anim_clock)
	overlay.call("_process",0.5)
	_check(is_equal_approx(float(overlay.anim_clock),paused_clock),"Pause freezes the overlay animation clock")
	_set_motion(false)
	terrain.call("_set_game_speed",1)
	overlay.call("_process",0.5)
	_check(float(overlay.anim_clock)>paused_clock,"Resume advances the actual overlay animation clock")
	terrain.call("_set_game_speed",0)
	T.set_color_mode("light")
	await _shot("resumed","Resume restores motion · campaign remains frozen for this capture",38.0,focus,Vector2i(1152,720))
	await _finish()

func _interior() -> bool:
	var original:Vector2=CivilizationSystem.player_world_origin
	for ring in range(8,25,2):
		for bearing in 8:
			var candidate:=original+Vector2.from_angle(TAU*float(bearing)/8.0)*float(ring)*8.0
			var dry:=CivilizationSystem._scout_land_at(candidate)
			for angle in 48:
				for radius in [10.0,20.0,32.0]:
					if not CivilizationSystem._scout_land_at(candidate+Vector2.from_angle(TAU*float(angle)/48.0)*radius):dry=false;break
				if not dry:break
			if dry:center=candidate;return true
	return false

func _set_motion(reduced:bool) -> void:
	# Window resizes reapply this real preference, so changing only the
	# renderer's static Motion flag would silently lose the setting.
	var preferences:Node=terrain.get("display_preferences")
	preferences.set("reduce_motion",reduced);preferences.call("apply")
	_check(Motion.reduced()==reduced,"Display preference reaches effective motion mode")

static func _point(force:Dictionary) -> Vector2:
	return Defense.point(force.get("position",{}))

func _author_campaign() -> void:
	WorldSimulation.clear();MilitaryCampaign.reset_for_new_world()
	GameState.ensure_population_total(400000)
	GameState.resource_stockpiles["Food"]=10000000.0;GameState.food_stocks={"Preserved food":10000000.0}
	GameState.border_forts={"forts":[],"border_share":0.0,"next_id":1,"seeded":true}
	CivilizationSystem.player_world_origin=center
	GameState.settlement_founded_at=Vector3(center.x,0,center.y)
	for city:Dictionary in GameState.player_settlements:
		if bool(city.get("primary",false)):city.position=center;city.claim_radius_km=2.0
	CivilizationSystem._add_revealed_area(center,100.0,"TEST perimeter survey")
	Route.clear_cache()
	for discovery in ["formation_drill","military_staffs","radio_telegraphy"]:
		if not discovery in GameState.known_discoveries:GameState.known_discoveries.append(discovery)
		GameState.discovery_adoption[discovery]=1.0
	# Development is authored setup, so live signal-era reports are legitimate.
	for domain in ["security","production","logistics","institutions"]:ProgressionSystem.domain_levels[domain]=5
	MilitaryCampaign.home_army=MilitaryCampaign.simulator.create_formation_force("TEST trained reserve",[{"id":1,"unit":"levy","weapon":"improvised","count":200000,"equipment":200000,"training":0.8}],0.9,0.9)
	MilitaryCampaign.home_army.provision_ratio=1.0;MilitaryCampaign.home_army.supply_level=1.0
	CivilizationSystem.foreign_formations.clear();CivilizationSystem.foreign_sightings.clear();CivilizationSystem.formation_memory.clear()
	var civ:Dictionary=CivilizationSystem.civilizations[0]
	rival=String(civ.id);civ.name="Fixture Esurai";civ.military_population=200000.0
	civ.player_relation.at_war=false;civ.player_relation.treaty="none";civ.player_relation.contact_level=2;civ.player_relation.home_location_known=true
	War.blood_feud(rival,int(GameState.elapsed_days),"TEST border exercise")
	CivilizationSystem.record_player_hostile_order(rival,"","TEST declared field exercise")
	terrain.set_process(false);terrain.set_physics_process(false)
	_set_motion(false)
	overlay.band_override="";overlay.extra_inputs={}

func _add_rivals() -> void:
	var stations:Array=[]
	for index in MilitaryCampaign.field_armies.size():
		var army:Dictionary=MilitaryCampaign.field_armies[index]
		var at:=_point(army)
		var offset:=(at-center).normalized()*1.6
		var points:Array=[]
		for point:Vector2 in Defense.coverage(army):points.append(_pack(point+offset))
		stations.append({"at":at+offset,"points":points,"troops":int(army.troops)})
	var today:=int(GameState.elapsed_days)
	var land:Callable=CivilizationSystem.scout_land_authority
	WorldSimulation.context_provider=func(_at:Vector2)->Dictionary:return {"environment_profile":PlanetEnvironment.profile_at(Vector2.ZERO),"surface_water_distance_km":0.1,"surface_water_recognized":true}
	WorldSimulation.create_actor(rival,hash(rival)&0x7fffffff,center+Vector2(50,0))
	WorldSimulation.actors[rival].controller="manual"
	WorldSimulation.actors[rival].systems.CivilizationSystem.scout_land_authority=land
	_check(bool(WorldSimulation.submit(rival,{"kind":"found"}).get("ok",false)),"Owned rival settlement founded")
	WorldSimulation.scoped(rival,func()->void:
		WorldSimulation.state.ensure_population_total(400000);WorldSimulation.state.elapsed_days=today
		WorldSimulation.state.settlement_completed=["Hearth Circle"];WorldSimulation.settlements.ensure_founded()
		WorldSimulation.state.resource_stockpiles["Food"]=10000000.0
		WorldSimulation.state.known_discoveries.append_array(["formation_drill","military_staffs","radio_telegraphy"])
		var mc=WorldSimulation.military
		mc.home_army=mc.simulator.create_formation_force("TEST opposing reserve",[{"id":1,"unit":"levy","weapon":"improvised","count":200000,"equipment":200000,"training":0.8}],0.9,0.9)
		for station:Dictionary in stations:
			var made:Dictionary=mc.create_field_army(int(station.troops))
			_check(made.has("ok"),"Real rival field army created")
			if not made.has("ok"):continue
			var force:Dictionary=mc.field_armies[mc._field_army_index(int(made.army.army_id))]
			force.position=_pack(station.at);force.status="stationed";force.location_id="field_position";force.provision_ratio=1.0;force.supply_level=1.0
			force.border_sector={"owner":rival,"civ_id":"player","anchor":_pack(station.at),"points":station.points,"assigned_troops":station.troops,"organization":8.0,"day":today}
	)
	WorldSimulation.enabled=true;WorldSimulation.refresh_projections();WorldSimulation.refresh_views()
	CivilizationSystem.record_player_hostile_order(rival,"","TEST declared field exercise")

func _shot(key:String,words:String,zoom:float,at:Vector2,viewport:=Vector2i(1600,900)) -> void:
	caption.text="TEST · "+words+"\nAuthored army exercise · production collection on copied terrain"
	get_window().size=viewport;get_window().content_scale_size=viewport
	terrain.camera_target=Vector3(at.x,terrain.call("_height_at",at.x,at.y),at.y)
	terrain.camera.size=zoom;terrain.call("_update_camera");await _settle()
	# Normal update path collects, composes and retargets; no scene override.
	overlay.collect_elapsed=99.0
	for _i in 12:overlay.call("_process",0.1)
	overlay.queue_redraw();await _frames(4)
	(overlay.get("pulse_layer") as Control).queue_redraw();await _frames(2)
	var chart:Dictionary=overlay.scene
	_check(Motion.reduced()==(key=="reduced"),"Effective motion mode survives resize in "+key)
	_check((chart.fronts as Array).size()>=8,"Collected sectors remain present in "+key)
	_check(overlay.band_override=="","Automatic scale band in "+key)
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		_check(get_viewport().get_texture().get_image().save_png(directory.path_join(key+".png"))==OK,"Saved "+key)
	captures.append({"key":key,"fronts":(chart.fronts as Array).size(),"battles":(chart.battles as Array).size(),"band":overlay.call("_band"),"viewport":str(viewport),"reduced_motion":Motion.reduced(),"palette":T.color_mode,"spatial_crossings":crossings})
	print("BORDER_COLLECTION_PLATE ",key," fronts=",(chart.fronts as Array).size()," battles=",(chart.battles as Array).size()," band=",overlay.call("_band"))
