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
	# Contact begins with armies drawn up. Fight one genuine exchange in each
	# existing engagement before claiming that the subsequent worms are fighting.
	for id in MilitaryCampaign.own_engagements.keys():
		_check(MilitaryCampaign.focus_engagement(String(id)),"Real contact engagement can be focused")
		MilitaryCampaign.fight_engagement_day("hold")
	CivilizationSystem._process_local_observation(int(GameState.elapsed_days),true)
	focus=_point(MilitaryCampaign.field_armies[0])
	if "--crowded-only" in OS.get_cmdline_user_args():
		await _shot("crowded_small","1152 × 720 · multiple sectors and simultaneous contacts",120.0,center,Vector2i(1152,720))
		await _finish();return
	await _shot("contact_local","Real contact · normal battle registry, no injected battle marks",38.0,focus)
	await _motion_proof()
	if "--contact-only" in OS.get_cmdline_user_args():await _finish();return
	await _shot("contact_close","Close combat · both armies work against the crossing",16.0,focus)
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
	var overlap_pairs:=0
	var counters:Array=overlay.get("counter_rects")
	if key in ["perimeter","crowded_small"]:_check(counters.size()==16,"All sixteen army cards remain present in "+key)
	for i in counters.size():
		for j in range(i+1,counters.size()):
			if (counters[i] as Rect2).intersection(counters[j]).get_area()>1.0:overlap_pairs+=1
	_check(overlap_pairs==0,"Army cards remain separately readable in "+key)
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		_check(get_viewport().get_texture().get_image().save_png(directory.path_join(key+".png"))==OK,"Saved "+key)
	captures.append({"key":key,"fronts":(chart.fronts as Array).size(),"battles":(chart.battles as Array).size(),"band":overlay.call("_band"),"viewport":str(viewport),"reduced_motion":Motion.reduced(),"palette":T.color_mode,"spatial_crossings":crossings,"counter_count":counters.size(),"counter_overlap_pairs":overlap_pairs})
	print("BORDER_COLLECTION_PLATE ",key," fronts=",(chart.fronts as Array).size()," battles=",(chart.battles as Array).size()," band=",overlay.call("_band"))

func _heat_metrics() -> Dictionary:
	var out:={"ours":{"fronts":0,"deployed":0,"mobile":0,"peak":0.0,"hot_runs":0},"theirs":{"fronts":0,"deployed":0,"mobile":0,"peak":0.0,"hot_runs":0},"battles":[]}
	for line:Dictionary in overlay.scene.get("fronts",[]):
		var side:String="ours" if bool(line.get("ours",true)) else "theirs"
		out[side].fronts+=1
		out[side]["deployed" if bool(line.get("deployed",false)) else "mobile"]+=1
		for heat:float in line.get("heat",PackedFloat32Array()):out[side].peak=maxf(float(out[side].peak),heat)
	for battle:Dictionary in overlay.collect().get("battles",[]):
		out.battles.append({"id":battle.get("id",""),"status":battle.get("status",""),"age_days":battle.get("age_days",-1)})
	for run:Dictionary in overlay.get("hot_cache"):
		var side:String="ours" if (run.get("ink",Overlay.THEIRS) as Color).is_equal_approx(Overlay.OURS) else "theirs"
		out[side].hot_runs+=1
	return out

func _worm_regions(side:String,image:Image) -> Array[Rect2i]:
	# Scope pixel comparisons to each side's actual hot ribbon neighbourhood,
	# rather than accepting motion anywhere in the map or its HUD as evidence.
	var regions:Array[Rect2i]=[]
	var factor:Vector2=Vector2(image.get_size())/overlay.get_viewport_rect().size
	var bounds:=Rect2i(Vector2i.ZERO,image.get_size())
	for run:Dictionary in overlay.get("hot_cache"):
		var own:bool=(run.get("ink",Overlay.THEIRS) as Color).is_equal_approx(Overlay.OURS)
		if own!=(side=="ours"):continue
		var points:PackedVector2Array=run.points
		for i in range(1,points.size()):
			var rect:=Rect2(points[i-1]*factor,Vector2.ZERO).expand(points[i]*factor).grow(22.0*factor.x)
			regions.append(Rect2i(rect).intersection(bounds))
	return regions

static func _changed_pixels(a:Image,b:Image,regions:Array[Rect2i]) -> int:
	var counted:Dictionary={}
	var changed:=0
	for region:Rect2i in regions:
		for y in range(region.position.y,region.end.y):
			for x in range(region.position.x,region.end.x):
				var key:=y*a.get_width()+x
				if counted.has(key):continue
				counted[key]=true
				var before:=a.get_pixel(x,y);var after:=b.get_pixel(x,y)
				if not before.is_equal_approx(after):changed+=1
	return changed

func _pulse_image() -> Image:
	(overlay.get("pulse_layer") as Control).queue_redraw()
	await _frames(3)
	await RenderingServer.frame_post_draw
	return get_viewport().get_texture().get_image()

func _ribbon_only_image() -> Image:
	# Controlled rendering diagnostic only: suppress each decorative battle
	# pulse while retaining the unmodified production scene and hot ribbons.
	# A pulsing ring or wash can otherwise change pixels over a static worm.
	var caption_before:=caption.text
	caption.text="TEST · Controlled ribbon diagnostic · decorative ring and wash suppressed\nProduction scene and hot geometry unchanged · cosmetic pulse flags restored after this frame"
	await _frames(3)
	var entries:Array=overlay.get("battle_cache")
	var previous:Array=[]
	var scene_before:=hash(overlay.scene)
	var heat_before:=hash(overlay.get("hot_cache"))
	for entry:Dictionary in entries:
		previous.append(bool(entry.get("live",false)));entry.live=false
	var result:Image=await _pulse_image()
	for i in entries.size():entries[i].live=previous[i]
	caption.text=caption_before
	_check(hash(overlay.scene)==scene_before and hash(overlay.get("hot_cache"))==heat_before,"Controlled pulse suppression preserves scene and fighting geometry")
	return result

func _motion_proof() -> void:
	# Let geometry finish approaching its target before comparing pixels. All
	# simulation nodes remain frozen: only the production overlay process runs.
	for _i in 80:overlay.call("_process",0.1)
	await _frames(4)
	var metrics:=_heat_metrics()
	for side in ["ours","theirs"]:
		_check(float(metrics[side].peak)>0.06,"Real contact heats the "+side+" formation")
		_check(int(metrics[side].hot_runs)>0,"Real contact draws a "+side+" fighting ribbon")
	if DisplayServer.get_name()=="headless":
		captures.append({"key":"contact_motion","heat":metrics,"pixels":"GPU required"});return
	caption.text="TEST · Same real contact, two animation phases · no campaign tick\nAuthored army exercise · production collection on copied terrain"
	terrain.call("_set_game_speed",1)
	overlay.call("_process",0.25)
	var first:Image=await _pulse_image()
	var clock_a:=float(overlay.anim_clock)
	_check(first.save_png(directory.path_join("contact_a.png"))==OK,"Saved timed contact A")
	var ribbon_a:Image=await _ribbon_only_image()
	_check(ribbon_a.save_png(directory.path_join("worm_only_a.png"))==OK,"Saved controlled ribbon A")
	overlay.call("_process",0.73)
	var second:Image=await _pulse_image()
	_check(second.save_png(directory.path_join("contact_b.png"))==OK,"Saved timed contact B")
	var ribbon_b:Image=await _ribbon_only_image()
	_check(ribbon_b.save_png(directory.path_join("worm_only_b.png"))==OK,"Saved controlled ribbon B")
	var changes:={}
	for side in ["ours","theirs"]:
		changes[side]=_changed_pixels(ribbon_a,ribbon_b,_worm_regions(side,ribbon_b))
		_check(int(changes[side])>8,"Real "+side+" fighting ribbon changes pixels with time")
	terrain.call("_set_game_speed",0)
	var stopped:=float(overlay.anim_clock)
	var paused_a:Image=await _ribbon_only_image()
	for _i in 6:overlay.call("_process",0.25)
	var paused_b:Image=await _ribbon_only_image()
	_check(is_equal_approx(stopped,float(overlay.anim_clock)),"Paused production clock stays fixed")
	var paused_changes:={}
	for side in ["ours","theirs"]:
		paused_changes[side]=_changed_pixels(paused_a,paused_b,_worm_regions(side,paused_b))
		_check(int(paused_changes[side])==0,"Paused "+side+" fighting ribbon is pixel-stable")
	_set_motion(true)
	terrain.call("_set_game_speed",1)
	# Force a chart rebuild after the actual setting changes, matching the
	# redraw that resizing and normal camera movement can cause in play.
	overlay.queue_redraw();await _frames(3)
	var reduced_a:Image=await _ribbon_only_image()
	overlay.call("_process",0.73)
	var reduced_b:Image=await _ribbon_only_image()
	var reduced_changes:={}
	for side in ["ours","theirs"]:
		reduced_changes[side]=_changed_pixels(reduced_a,reduced_b,_worm_regions(side,reduced_b))
		_check(int(reduced_changes[side])==0,"Reduced-motion "+side+" fighting ribbon is pixel-stable")
	_set_motion(false);terrain.call("_set_game_speed",0)
	captures.append({"key":"contact_motion","heat":metrics,"clock_a":clock_a,"clock_b":stopped,"comparison":"Controlled decorative pulse suppression: battle_cache live flags false only for worm_only images and comparisons, restored immediately; scene and hot geometry untouched","changed_pixels":changes,"paused_changed_pixels":paused_changes,"reduced_changed_pixels":reduced_changes})
	print("BORDER_CONTACT_MOTION ",JSON.stringify(captures[-1]))
