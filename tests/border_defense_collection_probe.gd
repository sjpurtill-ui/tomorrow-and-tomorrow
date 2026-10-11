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
var encirclement := false
var inland := Vector2.RIGHT
var attacking_ids:Array[int]=[]
var expected_actors := 0
var fort_shape:Dictionary={}
var removed_scout_paths := 0

func _fixture_loaded() -> void:
	# The authored army exercise relocates the home and replaces its armies.
	# Old scout trajectories and orders refer to that discarded setup. Clear
	# fixture data before terrain layers mount; never hide a rendered layer.
	if not "--retain-scout-charts" in OS.get_cmdline_user_args():
		removed_scout_paths=CivilizationSystem.scout_missions.size()+CivilizationSystem.scout_reports.size()
		CivilizationSystem.scout_missions.clear();CivilizationSystem.scout_reports.clear()
	GameState.order_tracker={"next_id":1,"orders":[]}

func _run() -> void:
	if not await _prepare():return
	encirclement="--encirclement" in OS.get_cmdline_user_args()
	scope="TEST authored neighboring-country conflict on copied terrain; actual fort outline, council deployment, marches, observed enemy sectors, combat and production map collection" if not encirclement else "TEST encirclement stress case: eight friendly and eight enemy armies through production collection"
	scope+="; unrelated copied scout paths (%d) and order references cleared before terrain initialization" % removed_scout_paths
	if "--retain-scout-charts" in OS.get_cmdline_user_args():scope+="; copied scout archive retained to test ordinary chart clutter"
	capital_label.hide()
	caption.autowrap_mode=TextServer.AUTOWRAP_OFF
	caption.custom_minimum_size=Vector2.ZERO
	caption.add_theme_font_size_override("font_size",11)
	var badge:=caption.get_parent() as Control
	badge.custom_minimum_size=Vector2.ZERO
	badge.position=Vector2(930,610)
	var paper:=caption.get_parent().get_theme_stylebox("panel") as StyleBoxFlat
	paper.content_margin_left=8;paper.content_margin_right=8;paper.content_margin_top=4;paper.content_margin_bottom=4
	if not (_interior() if encirclement else _coastal_site()):
		_check(false,"Suitable real terrain found for the authored border");await _finish();return
	_author_campaign()
	var result:Dictionary=Council.order(rival,"defend")
	_check(MilitaryCampaign.field_armies.size()>=4,"Council deploys real land stations: "+str(result))
	if MilitaryCampaign.field_armies.size()<4:day=int(GameState.elapsed_days);await _finish();return
	for _i in 12:
		GameState.elapsed_days+=1
		MilitaryCampaign._process_field_army_movement_day()
		MilitaryCampaign._process_army_runners_day()
	for bearing in 32:
		var direction:=Vector2.from_angle(TAU*float(bearing)/32.0)
		var contact:=Defense.first_contact(center+direction*35.0,center,MilitaryCampaign.field_armies,{"troops":500})
		if not contact.is_empty():crossings+=1
	if encirclement:_check(crossings==32,"All 32 perimeter approaches meet real deployed armies")
	_add_rivals()
	CivilizationSystem._process_local_observation(int(GameState.elapsed_days),true)
	day=int(GameState.elapsed_days)
	await _shot("perimeter","Encirclement stress" if encirclement else "Neighboring border",145.0 if encirclement else 155.0,center+inland*12.0,Vector2i(1152,720))
	# Order two actual stationed bands forward. The ordinary swept movement
	# must discover contact and reserve both existing battle engagements.
	for army_id in attacking_ids.slice(0,2 if encirclement else 1):
		var army:Dictionary=MilitaryCampaign.field_armies[MilitaryCampaign._field_army_index(army_id)]
		var position:=_point(army)
		var direction:=(position-center).normalized()
		var goal:=position+direction*4.0
		MilitaryCampaign.move_field_army_to_position(int(army.army_id),goal.x,goal.y,"Advance across the border")
	GameState.elapsed_days+=1;MilitaryCampaign._process_field_army_movement_day()
	MilitaryCampaign._process_army_runners_day()
	CivilizationSystem._process_local_observation(int(GameState.elapsed_days),true)
	day=int(GameState.elapsed_days)
	var collected:Dictionary=overlay.collect()
	_check((collected.battles as Array).size()>=(2 if encirclement else 1),"Real contact reaches the normal battle collector")
	# Contact begins with armies drawn up. Fight one genuine exchange in each
	# existing engagement before claiming that the subsequent worms are fighting.
	for id in MilitaryCampaign.own_engagements.keys():
		_check(MilitaryCampaign.focus_engagement(String(id)),"Real contact engagement can be focused")
		MilitaryCampaign.fight_engagement_day("hold")
	CivilizationSystem._process_local_observation(int(GameState.elapsed_days),true)
	focus=_point(MilitaryCampaign.field_armies[MilitaryCampaign._field_army_index(attacking_ids[0])])
	if "--crowded-only" in OS.get_cmdline_user_args():
		await _shot("crowded_small","1152 × 720 · multiple sectors and simultaneous contacts",120.0,center,Vector2i(1152,720))
		await _finish();return
	await _shot("contact_local","Border fighting",38.0,focus,Vector2i(1152,720))
	await _motion_proof()
	if "--contact-only" in OS.get_cmdline_user_args():await _finish();return
	await _shot("contact_close","At the crossing",16.0,focus,Vector2i(1152,720))
	await _focused_battle()
	await _shot("crowded_small","Encirclement stress" if encirclement else "Border overview",145.0 if encirclement else 155.0,center+inland*12.0,Vector2i(1152,720))
	await _selected_army()
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

func _coastal_site() -> bool:
	var original:Vector2=CivilizationSystem.player_world_origin
	# Choose actual coastline with a dry inland approach, never paint water
	# or invent a terrain mask. Council's normal land clipping owns the coast.
	for ring in range(4,25,2):
		for bearing in 12:
			var candidate:=original+Vector2.from_angle(TAU*float(bearing)/12.0)*float(ring)*8.0
			if not CivilizationSystem._scout_land_at(candidate):continue
			for coast in 8:
				var shore:=Vector2.from_angle(TAU*float(coast)/8.0)
				if CivilizationSystem._scout_land_at(candidate+shore*26.0):continue
				var dry:=true
				for a in 8:
					if not CivilizationSystem._scout_land_at(candidate+Vector2.from_angle(TAU*a/8.0)*9.0):dry=false;break
				for angle in [-0.8,-0.4,0.0,0.4,0.8]:
					for radius in [18.0,32.0,46.0,60.0,78.0]:
						if not CivilizationSystem._scout_land_at(candidate-shore.rotated(angle)*radius):dry=false;break
				if dry:center=candidate;inland=-shore;return true
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
	ForeignDiplomacy.audiences.erase("war");ForeignDiplomacy.audiences.erase("council")
	CivilizationSystem.war_history.clear()
	GameState.ensure_population_total(400000 if encirclement else 120000)
	GameState.resource_stockpiles["Food"]=10000000.0;GameState.food_stocks={"Preserved food":10000000.0}
	GameState.border_forts={"forts":[],"border_share":0.0,"next_id":1,"seeded":true}
	CivilizationSystem.player_world_origin=center
	GameState.settlement_founded_at=Vector3(center.x,0,center.y)
	for city:Dictionary in GameState.player_settlements:
		if bool(city.get("primary",false)):city.position=center;city.claim_radius_km=2.0
	if not encirclement:
		for offset in [Vector2(18,-10),Vector2(27,8),Vector2(7,20)]:
			var at:Vector2=center+inland*offset.x+inland.orthogonal()*offset.y
			GameState.border_forts.forts.append({"id":int(GameState.border_forts.next_id),"kind":"watch_camp","x":at.x,"z":at.y,"status":"standing","progress":600.0,"condition":1.0,"since":int(GameState.elapsed_days)-100,"name":"Border watch"})
			GameState.border_forts.next_id+=1
	fort_shape=Forts.outline()
	if not encirclement:_check(float(fort_shape.reach)>Forts.home_km()+5.0,"Real standing forts make an irregular border")
	# These copied orders reference armies erased by fixture setup. Reset
	# the fixture ledger and notify its normal UI, never hide the order panel.
	GameState.order_tracker={"next_id":1,"orders":[]}
	preload("res://scripts/order_tracker.gd").hub().changed.emit()
	terrain.call("_clear_army_selection")
	overlay.close_tip();overlay.close_note()
	CivilizationSystem._add_revealed_area(center,100.0,"TEST perimeter survey")
	Route.clear_cache()
	for discovery in ["formation_drill","military_staffs","radio_telegraphy"]:
		if not discovery in GameState.known_discoveries:GameState.known_discoveries.append(discovery)
		GameState.discovery_adoption[discovery]=1.0
	# Development is authored setup, so live signal-era reports are legitimate.
	for domain in ["security","production","logistics","institutions"]:ProgressionSystem.domain_levels[domain]=5
	var trained:=200000 if encirclement else 40000
	MilitaryCampaign.home_army=MilitaryCampaign.simulator.create_formation_force("TEST trained reserve",[{"id":1,"unit":"levy","weapon":"improvised","count":trained,"equipment":trained,"training":0.8}],0.9,0.9)
	MilitaryCampaign.home_army.provision_ratio=1.0;MilitaryCampaign.home_army.supply_level=1.0
	CivilizationSystem.foreign_formations.clear();CivilizationSystem.foreign_sightings.clear();CivilizationSystem.formation_memory.clear()
	var civ:Dictionary=CivilizationSystem.civilizations[0]
	rival=String(civ.id);civ.military_population=float(trained)
	var neighboring_home:=center+inland*(50.0 if encirclement else 78.0)
	civ.world_position=neighboring_home
	civ.position=Vector2(neighboring_home.x/CivilizationSystem.CIVILIZATION_WORLD_RADIUS_X_KM,neighboring_home.y/CivilizationSystem.CIVILIZATION_WORLD_RADIUS_Z_KM)
	civ.player_relation.home_position=_pack(neighboring_home)
	civ.player_relation.war_started_day=-1;civ.player_relation.war_id=""
	civ.player_relation.at_war=false;civ.player_relation.treaty="none";civ.player_relation.contact_level=2;civ.player_relation.home_location_known=true
	var capital:Dictionary=civ.strategic_regions[CivilizationSystem._frontline_region_index(civ)]
	capital.position=neighboring_home;capital.role="capital"
	civ.strategic_regions=[capital]
	CivilizationSystem.city_intelligence.records["player"]={}
	var today:=int(GameState.elapsed_days)
	CivilizationSystem.city_intelligence.publish("player",CivilizationSystem.city_intelligence.capture("player",String(capital.id),0.9,today,"scout report","authored neighboring country"),today)
	_check(Defense.point(Council.known_towns(rival)[0].position).distance_to(neighboring_home)<0.1,"Council knows the actual neighboring capital")
	War.blood_feud(rival,int(GameState.elapsed_days),"TEST border exercise")
	CivilizationSystem.record_player_hostile_order(rival,"","TEST declared field exercise")
	terrain.set_process(false);terrain.set_physics_process(false)
	_set_motion(false)
	overlay.band_override="";overlay.extra_inputs={}

func _add_rivals() -> void:
	var stations:Array=[]
	var candidates:Array=MilitaryCampaign.field_armies.duplicate()
	if not encirclement:candidates.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return (_point(a)-center).dot(inland)>(_point(b)-center).dot(inland))
	for army:Dictionary in candidates:
		if not encirclement and stations.size()>=2:break
		var at:=_point(army)
		var offset:=(at-center).normalized()*1.6
		var points:Array=[]
		for point:Vector2 in Defense.coverage(army):points.append(_pack(point+offset))
		if points.size()<2:continue
		stations.append({"at":at+offset,"points":points,"troops":int(army.troops)})
		attacking_ids.append(int(army.army_id))
	expected_actors=MilitaryCampaign.field_armies.size()+stations.size()
	_check(stations.size()==(8 if encirclement else 2),"Rival deployments are restricted to the intended frontier")
	var today:=int(GameState.elapsed_days)
	var land:Callable=CivilizationSystem.scout_land_authority
	WorldSimulation.context_provider=func(_at:Vector2)->Dictionary:return {"environment_profile":PlanetEnvironment.profile_at(Vector2.ZERO),"surface_water_distance_km":0.1,"surface_water_recognized":true}
	WorldSimulation.create_actor(rival,hash(rival)&0x7fffffff,center+inland*(50.0 if encirclement else 78.0))
	WorldSimulation.actors[rival].controller="manual"
	WorldSimulation.actors[rival].systems.CivilizationSystem.scout_land_authority=land
	_check(bool(WorldSimulation.submit(rival,{"kind":"found"}).get("ok",false)),"Owned rival settlement founded")
	WorldSimulation.scoped(rival,func()->void:
		WorldSimulation.state.ensure_population_total(400000 if encirclement else 120000);WorldSimulation.state.elapsed_days=today
		WorldSimulation.state.settlement_completed=["Hearth Circle"];WorldSimulation.settlements.ensure_founded()
		WorldSimulation.state.resource_stockpiles["Food"]=10000000.0
		WorldSimulation.state.known_discoveries.append_array(["formation_drill","military_staffs","radio_telegraphy"])
		var mc=WorldSimulation.military
		var trained:=200000 if encirclement else 40000
		mc.home_army=mc.simulator.create_formation_force("TEST opposing reserve",[{"id":1,"unit":"levy","weapon":"improvised","count":trained,"equipment":trained,"training":0.8}],0.9,0.9)
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
	_label("TEST · "+words)
	Input.warp_mouse(Vector2(12,12));overlay.close_tip();overlay.close_note()
	get_window().size=viewport;get_window().content_scale_size=viewport
	_label(words)
	terrain.camera_target=Vector3(at.x,terrain.call("_height_at",at.x,at.y),at.y)
	terrain.camera.size=zoom;terrain.call("_update_camera");await _settle()
	# Normal update path collects, composes and retargets; no scene override.
	overlay.collect_elapsed=99.0
	for _i in 12:overlay.call("_process",0.1)
	overlay.queue_redraw();await _frames(4)
	(overlay.get("pulse_layer") as Control).queue_redraw();await _frames(2)
	var chart:Dictionary=overlay.scene
	_check(Motion.reduced()==(key=="reduced"),"Effective motion mode survives resize in "+key)
	_check((chart.fronts as Array).size()>=4,"Collected sectors remain present in "+key)
	_check(overlay.band_override=="","Automatic scale band in "+key)
	var overlap_pairs:=0
	var counters:Array=overlay.get("counter_rects")
	var represented:Dictionary={}
	for hit:Dictionary in overlay.get("hits"):
		if String(hit.get("kind",""))=="army":represented["ours:"+str(hit.get("army_id",0))]=true
		elif String(hit.get("kind",""))=="sighting":represented["theirs:"+str(hit.get("enemy_id",""))]=true
		for member in hit.get("members",[]):represented[String(member)]=true
	var actual_count:=(overlay.collect().get("friendly",[]) as Array).size()+(overlay.collect().get("enemy",[]) as Array).size()
	_check(actual_count==expected_actors,"Every authored actor remains in production collection in "+key)
	if key in ["perimeter","crowded_small"]:
		for mark:Dictionary in chart.get("marks",[]):
			if int(mark.get("army_id",0))>0 or String(mark.get("enemy_id",""))!="":_check(represented.has(String(mark.id)),"Map signal remains hittable for "+String(mark.id)+" in "+key)
	for i in counters.size():
		for j in range(i+1,counters.size()):
			if (counters[i] as Rect2).intersection(counters[j]).get_area()>1.0:overlap_pairs+=1
	_check(overlap_pairs==0,"Army cards remain separately readable in "+key)
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		_check(get_viewport().get_texture().get_image().save_png(directory.path_join(key+".png"))==OK,"Saved "+key)
	captures.append({"key":key,"description":words,"fronts":(chart.fronts as Array).size(),"battles":(chart.battles as Array).size(),"band":overlay.call("_band"),"viewport":str(viewport),"reduced_motion":Motion.reduced(),"palette":T.color_mode,"spatial_crossings":crossings,"actors":actual_count,"hit_identities":represented.keys(),"counter_count":counters.size(),"counter_overlap_pairs":overlap_pairs})
	print("BORDER_COLLECTION_PLATE ",key," fronts=",(chart.fronts as Array).size()," battles=",(chart.battles as Array).size()," band=",overlay.call("_band"))

func _label(_words:String) -> void:
	caption.text="TEST · Encirclement" if encirclement else "TEST · Authored conflict"
	var badge:=caption.get_parent() as Control
	badge.reset_size()
	badge.position=Vector2(get_window().content_scale_size)-badge.size-Vector2(24,82)

func _focused_battle() -> void:
	var picked:Dictionary={}
	for hit:Dictionary in overlay.get("hits"):
		if String(hit.get("kind",""))=="battle":picked=hit;break
	_check(not picked.is_empty(),"A real battle has a focusable map signal")
	if picked.is_empty():return
	var at:Vector2=picked.centre
	Input.warp_mouse(at);await _frames(3)
	overlay.call("_hover",at);await _frames(3)
	var tip:Control=overlay.get("tip")
	_check(is_instance_valid(tip) and tip.visible,"Battle focus reveals actual details")
	_label("TEST · Focused battle")
	await _frames(2)
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		_check(get_viewport().get_texture().get_image().save_png(directory.path_join("focused_battle.png"))==OK,"Saved focused battle")
	captures.append({"key":"focused_battle","battle_id":picked.battle.get("id",""),"detail_visible":is_instance_valid(tip) and tip.visible})
	overlay.close_tip();Input.warp_mouse(Vector2(12,12))

func _selected_army() -> void:
	var bar:Control=(terrain.get("hud") as Control).get("army_bar")
	bar.call("refresh")
	var group:Dictionary={}
	for card:Dictionary in bar.get("cards"):
		if String(card.get("kind",""))=="group" and (card.get("member_cards",[]) as Array).size()>(group.get("member_cards",[]) as Array).size():group=card
	_check(not group.is_empty(),"Real general has a selectable army group")
	if group.is_empty():return
	bar.call("select_card",group);await _frames(3)
	var last:Dictionary=(group.member_cards as Array)[-1]
	bar.call("select_card",last);await _frames(3)
	_check(int(terrain.selected_army_id)==int(last.army_id),"Last army member can be selected through the actual bar")
	await _shot("selected_army","Selected army",120.0,center+inland*12.0,Vector2i(1152,720))
	var strip:Control=bar.get("member_scroll")
	if is_instance_valid(strip):_check(Rect2(Vector2.ZERO,bar.get_viewport_rect().size).encloses(strip.get_global_rect()),"Selected army member strip stays inside the small viewport")
	terrain.call("_clear_army_selection");bar.call("refresh")
	if bool(bar.call("expanded")):bar.call("toggle_disclosure")

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
	_label("TEST · Ribbon-only diagnostic")
	await _frames(3)
	var entries:Array=overlay.get("battle_cache")
	var previous:Array=[]
	var scene_before:=hash(overlay.scene)
	var heat_before:=hash(overlay.get("hot_cache"))
	for entry:Dictionary in entries:
		previous.append(bool(entry.get("live",false)));entry.live=false
	var result:Image=await _pulse_image()
	for i in entries.size():entries[i].live=previous[i]
	_label(caption_before)
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
	_label("TEST · Combat motion")
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
