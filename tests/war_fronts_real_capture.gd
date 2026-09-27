extends Node
## TEST CAPTURE (not the game): war on the REAL map. Loads the real terrain
## scene, resumes the private copy of a mature quicksave (the run must use a
## test-only override.cfg that points user:// at a private directory), puts a
## war on that real ground near the real home and its nearest known foreign
## town, and captures the real renderer (terrain, city cards, great works,
## borders, army counters, HUD) at the zoom bands the fronts use.
##
## Run only through tools/run_isolated_gpu_probe.ps1 with user arguments
##   --resume-saved --capture-dir=<absolute dir> --capture-stage=before|after
## Optional: --inspect (print what the save holds and quit), --alderford (the
## authored Alderford war instead of the fixture). Quits by itself.
##
## The fixture's own armies are real MilitaryCampaign field armies (so their
## counters render); the enemy side is supplied as dated sightings through
## the overlay's test hook `extra_inputs` (after) or its injected scene
## (before, round-one code), because foreign formations are simulated and
## cannot be placed by hand without faking the observation model.

const TERRAIN_SCENE:=preload("res://local_terrain.tscn")
const Overlay:=preload("res://scripts/hud/war_front_overlay.gd")

var terrain:Node
var directory:=""
var stage:="after"
var inspect:=false
var alderford:=false
var overlay:Control
var fixture:Dictionary={}
var home:=Vector2.ZERO
var target:=Vector2.ZERO
var target_name:=""


func _ready()->void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-dir="): directory=argument.trim_prefix("--capture-dir=")
		elif argument.begins_with("--capture-stage="): stage=argument.trim_prefix("--capture-stage=")
		elif argument=="--inspect": inspect=true
		elif argument=="--alderford": alderford=true
	if directory=="": directory=ProjectSettings.globalize_path("res://artifacts/war_fronts_real")
	DirAccess.make_dir_recursive_absolute(directory)
	print("REAL CAPTURE user dir: ",OS.get_user_data_dir())
	terrain=TERRAIN_SCENE.instantiate()
	add_child(terrain)
	_run.call_deferred()


func _frames(count:int)->void:
	for _i in count: await get_tree().process_frame


func _settle()->void:
	for _pass in 3:
		var guard:=0
		while terrain.get("terrain_patch_job")!=null and guard<600:
			terrain._advance_terrain_patch(); guard+=1
			await get_tree().process_frame
		terrain._update_world_streaming()
		await get_tree().process_frame
	terrain._update_scale_lod()
	await _frames(6)


func _run()->void:
	await _frames(20)
	if terrain.has_method("_set_game_speed"): terrain._set_game_speed(0)
	_summary()
	if inspect:
		get_tree().quit(0); return
	overlay=terrain.find_child("WarFrontOverlay",true,false) as Control
	if overlay==null and terrain.has_method("_ensure_war_map_overlay"):
		terrain._ensure_war_map_overlay(); overlay=terrain.find_child("WarFrontOverlay",true,false) as Control
	if alderford: await _alderford()
	else: await _fixture_war()
	print("REAL CAPTURE PASS stage=%s dir=%s" % [stage,directory])
	# Let the terrain's background bakes finish before the scene is freed.
	var render:Variant=terrain.get("macro_render")
	var deadline:=Time.get_ticks_msec()+10000
	while render!=null and render.has_method("ready") and not render.ready() and Time.get_ticks_msec()<deadline: await get_tree().process_frame
	get_tree().quit(0)


func _summary()->void:
	var at_war:=0
	for civ:Dictionary in CivilizationSystem.civilizations:
		if bool((civ.get("player_relation",{}) as Dictionary).get("at_war",false)): at_war+=1
	var obs:Dictionary=CivilizationSystem.local_observation_snapshot()
	var op:Variant=MilitaryCampaign.get("joint_operations")
	print("REAL CAPTURE SAVE day=%d settlement=%s stage=%s known=%d at_war=%d field_armies=%d visible=%d recent=%d cities_known=%d joint_forces=%d campaign=%s" % [
		int(GameState.elapsed_days),GameState.settlement_name,preload("res://scripts/hud/era_words.gd").stage(),GameState.known_discoveries.size(),at_war,MilitaryCampaign.field_armies.size(),
		(obs.get("visible",[]) as Array).size(),(obs.get("recent",[]) as Array).size(),CivilizationSystem.city_intelligence.known_cities().size(),
		(op.state.forces as Array).size() if op!=null else -1,str(GeneralCampaign.active)])


static func _v2(position:Variant)->Vector2:
	if position is Dictionary: return Vector2(float(position.get("x",0.0)),float(position.get("z",0.0)))
	if position is Vector3: return Vector2(position.x,position.z)
	return Vector2(position)


# --- The fixture war on the real map --------------------------------------------

func _army(id:int,at:Vector2,troops:int,objective:Vector2)->Dictionary:
	var today:=int(GameState.elapsed_days)
	var position:={"x":at.x,"z":at.y}
	var army:={"army_id":id,"name":"%s Host" % ["First","Second","Third","Fourth","Fifth","Sixth"][(id-900)%6],"troops":troops,"readiness":0.7,"supply_level":0.8,"morale":0.72,
		"status":"moving" if objective.is_finite() else "stationed","location_id":"field_position","location_name":"Commanded ground","position":position,
		"destination_id":"" if objective.is_finite() else "","destination_position":{"x":objective.x,"z":objective.y} if objective.is_finite() else {},"distance_remaining_km":at.distance_to(objective) if objective.is_finite() else 0.0,
		"arrival_day":-1,"formations":[{"id":1,"unit":"line_infantry","count":troops,"training":0.6,"personnel_condition":1.0}],"commander":{"name":["Field staff","Arno Kell","Field staff","Hena Vall","Field staff"][(id-900)%5],"command":0.6,"tactics":0.6,"logistics":0.6,"resolve":0.6}}
	# One runner is three days behind, so its card says so.
	army["last_report"]={"position":position.duplicate(),"troops":troops,"status":army.status,"day":today-(3 if id==903 else 0)}
	return army


func _fixture_war()->void:
	var today:=int(GameState.elapsed_days)
	home=CivilizationSystem.player_world_origin
	target=home+Vector2(70,18)
	target_name="their town"
	var best:=INF
	for city:Dictionary in CivilizationSystem.city_intelligence.known_cities():
		if String(city.get("civ_id",""))=="player": continue
		var at:=_v2(city.get("position",{}))
		var d:=at.distance_to(home)
		if d>8.0 and d<best: best=d; target=at; target_name=String(city.get("name","their town"))
	var axis:=(target-home).normalized()
	var across:=axis.orthogonal()
	var span:=home.distance_to(target)
	var line:=home+axis*span*0.55
	print("REAL CAPTURE fixture home=%s target=%s (%s) span=%.1f km" % [home,target,target_name,span])
	var spread:=clampf(span*0.18,3.0,40.0)
	var armies:Array=[]
	var ids:=[900,901,902,903,904]
	var offsets:=[-1.0,-0.5,0.0,0.5,1.0]
	for k in ids.size():
		var at:Vector2=line-axis*spread*0.35+across*spread*float(offsets[k])
		var objective:=Vector2.INF
		if k==2: objective=target
		elif k==0: objective=line+axis*spread*0.8+across*spread*-1.2
		armies.append(_army(ids[k],at,[6000,30000,24000,8000,5000][k],objective))
	# Real armies so the real counters draw. Kept in the private copy only.
	for army in armies: MilitaryCampaign.field_armies.append(army)
	# Round three: one force selected, so its gold ring and card show.
	if stage!="before": terrain.selected_army_id=903
	# Two of them are corps; group them under one army-group headquarters.
	var command:Variant=MilitaryCampaign.get("command_hierarchy")
	if command!=null:
		command.sync()
		var corps:Array=[]
		for record:Dictionary in command.data.nodes.values():
			if int(record.get("force_id",-1)) in [901,902]: corps.append(String(record.id))
		print("REAL CAPTURE army group: ",command.organize(corps,8,"Northern Group"))
	var enemy:Array=[]
	var ages:=[0,1,3,28,34,0]
	for k in 6:
		var at:Vector2=line+axis*spread*0.4+across*spread*(float(k)/5.0*2.2-1.1)
		enemy.append({"id":"fx%d" % k,"pos":at,"strength":[7000.0,12000.0,9000.0,6000.0,5000.0,8000.0][k],"age_days":ages[k],"moving":k==1,"heading":-(axis.angle()+PI*0.5)+PI,"seen_day":today-int(ages[k])})
	var clash_at:=line+axis*spread*0.02
	fixture={"enemy":enemy,
		"engagements":[{"pos":clash_at,"axis":axis,"ours":"hammer_and_anvil","theirs":"shield_wall","rounds":3,"phase_ours":"strike","phase_theirs":"hold","event":""},
			{"pos":line+across*spread*0.95,"axis":axis,"ours":"feigned_retreat","theirs":"head_on","rounds":2,"phase_ours":"yield","phase_theirs":"hold","event":""}],
		"sieges":[{"pos":target,"pressure":0.55,"works":"circumvallation","ours":true,"days":24}],
		# The save is still at the hearth; this fixture shows a staffed war.
		"mode":"theatre","stage":"reckoned","zones":_fixture_zones(line,axis,across,spread),
		# A rival fleet squeezing our own harbour, felt at home.
		"harbours":[{"pos":home,"level":0.35,"held":true,"text":"Our harbour blockaded 40 days: sea trade 28% down"}]}
	fixture["lanes"]=_fixture_lanes(fixture.zones)
	await _plates([["regional",clampf(spread*5.0,90.0,700.0),line],["regional-wide",clampf(span*1.25,90.0,700.0),line],["local",clampf(span*0.5,30.0,80.0),clash_at],["continental",clampf(span*6.0,900.0,5000.0),line]])
	await _extras(["local",clampf(span*0.5,30.0,80.0),line])
	await _cost()
	if stage!="before": await _era_plates(clampf(span*0.5,30.0,80.0),line)


## Round three: the same ground in two other ages. Early: small war bands
## (spear tallies) in the raid age. Late: rifles and armour (staff boxes).
func _era_plates(zoom:float,line:Vector2)->void:
	if overlay==null or not ("extra_inputs" in overlay): return
	var bands:=[40,180,60,120,25]
	var k:=0
	for army in MilitaryCampaign.field_armies:
		if int(army.get("army_id",0)) in [900,901,902,903,904]:
			army.troops=bands[k]; army.last_report.troops=bands[k]; army.formations=[{"id":1,"unit":"levy","count":bands[k]}]; k+=1
	var early:=fixture.duplicate(true)
	early.stage="hearth"; early.mode="raid"; early.zones=[]; early.lanes=[]; early.harbours=[]; early.sieges=[]; early.engagements=[]
	for e in early.enemy: e.strength=float(e.strength)/60.0
	fixture=early
	await _plates([["local",zoom,line]],"mature_early")
	var units:=["rifle_infantry","armored_formation","motorized_infantry","modern_artillery","rifle_infantry"]
	var sizes:=[6000,30000,24000,8000,5000]
	k=0
	for army in MilitaryCampaign.field_armies:
		if int(army.get("army_id",0)) in [900,901,902,903,904]:
			army.troops=sizes[k]; army.last_report.troops=sizes[k]; army.formations=[{"id":1,"unit":units[k],"count":sizes[k]}]; k+=1
	var late:=early.duplicate(true)
	late.stage="reckoned"; late.mode="theatre"
	for e in late.enemy: e.strength=float(e.strength)*60.0; e["era"]=3; e["branch"]="armour" if int(e.strength)>=9000 else "foot"
	fixture=late
	await _plates([["local",zoom,line],["regional",clampf(zoom*2.5,90.0,700.0),line]],"mature_modern")


## An air zone over the front, and a fleet zone on the nearest real water.
func _fixture_zones(line:Vector2,axis:Vector2,across:Vector2,spread:float)->Array:
	var zones:Array=[]
	var air:=PackedVector2Array()
	for k in 6: air.append(line+Vector2.from_angle(TAU*float(k)/6.0).rotated(axis.angle())*Vector2(spread*1.1,spread*0.7))
	zones.append({"domain":"air","vertices":air,"control":0.7,"mission":"interception","tactic":"directed_interception","base":home,"port":Vector2.INF,"contacts":[{"pos":line+axis*spread*0.6,"age":1}],"name":"First Air Group"})
	var water:=Vector2.INF
	for ring in range(1,40):
		for k in 24:
			var at:=home+Vector2.from_angle(TAU*float(k)/24.0)*float(ring)*4.0
			if not CivilizationSystem._scout_land_at(at): water=at; break
		if water.is_finite(): break
	if water.is_finite():
		var sea:=PackedVector2Array()
		for k in 7: sea.append(water+Vector2.from_angle(TAU*float(k)/7.0)*spread*0.8)
		var port:=target if target.distance_to(water)<spread*1.6 else Vector2.INF
		var lane:=PackedVector2Array([water+Vector2(-spread*0.5,spread*0.2),water+Vector2(spread*0.6,-spread*0.1),water+Vector2(spread*1.6,-spread*0.9)])
		zones.append({"lane":lane})
		zones.append({"domain":"navy","vertices":sea,"control":0.62,"mission":"patrol","tactic":"close_blockade" if port.is_finite() else "line_of_battle","base":home,"port":port,"contacts":[{"pos":water+Vector2(spread*0.3,0),"age":2}],"name":"Home Fleet"})
		print("REAL CAPTURE water at %s (%.1f km from home)" % [water,water.distance_to(home)])
	return zones


## Split the fixture's convoy lane out of the zone list.
func _fixture_lanes(zones:Array)->Array:
	var lanes:Array=[]
	for z in zones.duplicate():
		if z.has("lane"):
			lanes.append({"points":z.lane,"domain":"navy","escorted":true,"raided":true,"status":"outbound","invasion":false,"name":"Grain convoy"})
			zones.erase(z)
	return lanes


func _alderford()->void:
	GeneralCampaign.terrain=terrain
	var started:Dictionary=GeneralCampaign.start_scenario()
	print("REAL CAPTURE alderford start: ",started)
	if is_instance_valid(GeneralCampaign.screen): GeneralCampaign.screen.hide()
	var army:Dictionary=GeneralCampaign.army()
	var rival:Dictionary=(GeneralCampaign.state.get("rivals",[]) as Array)[0] if not (GeneralCampaign.state.get("rivals",[]) as Array).is_empty() else {}
	if not army.is_empty() and not rival.is_empty():
		var there:Vector2=GeneralCampaign.world_position(rival.home)
		var start:=Vector2(GeneralCampaign.state.origin)
		var at:=start.lerp(there,0.45)
		army.position={"x":at.x,"z":at.y}; army.status="moving"; army.destination_position={"x":there.x,"z":there.y}; army.destination_id=""
		army["last_report"]={"position":army.position.duplicate(),"troops":int(army.get("troops",240)),"status":"moving","day":int(GameState.elapsed_days)}
		GeneralCampaign.state.mission={"action":"attack","target":String(rival.id)}
		home=start; target=there
	fixture={}
	await _plates([["local",40.0,home.lerp(target,0.5)]],"alderford")


# --- Plates ---------------------------------------------------------------------

## Steady-state cost with the camera still, and while the front eases.
func _cost()->void:
	if overlay==null or not ("extra_inputs" in overlay): return
	await get_tree().create_timer(4.0).timeout
	var redraws:=int(overlay.redraws)
	await _frames(120)
	print("REAL CAPTURE cost still: redraws over 120 frames=%d draw_us=%d compose_us=%d captions=%d dropped=%d" % [int(overlay.redraws)-redraws,int(overlay.last_draw_usec),int(overlay.last_compose_usec),(overlay.placed_captions as Array).size(),int(overlay.dropped_captions)])
	var pushed:Dictionary=overlay.extra_inputs.duplicate(true)
	for e in pushed.enemy: e.pos=(e.pos as Vector2)-(target-home).normalized()*home.distance_to(target)*0.05
	overlay.set("extra_inputs",pushed); overlay.set("collect_elapsed",99.0)
	redraws=int(overlay.redraws)
	var worst:=0
	for _k in 120:
		await get_tree().process_frame
		worst=maxi(worst,int(overlay.last_draw_usec))
	print("REAL CAPTURE cost easing: redraws over 120 frames=%d worst_draw_us=%d settling=%s" % [int(overlay.redraws)-redraws,worst,str(overlay.settling)])


func _save(name:String)->void:
	RenderingServer.force_draw(true,0.0)
	get_viewport().get_texture().get_image().save_png(directory.path_join(name))
	print("REAL CAPTURE plate=",name)


## After: a note opened by clicking the front, and the front easing as their
## hosts are pushed back (three frames a third of a second apart).
func _extras(view:Array)->void:
	if overlay==null or not ("extra_inputs" in overlay) or fixture.is_empty(): return
	terrain.camera_target=Vector3(view[2].x,terrain._height_at(view[2].x,view[2].y),view[2].y)
	terrain.camera.size=float(view[1]); terrain._update_camera()
	await _settle()
	var live:Dictionary=overlay.collect()
	overlay.set("inputs_signature",hash(live)); overlay.set_scene(Overlay.compose(live),true)
	await _frames(4)
	var fronts:Array=overlay.scene.get("fronts",[])
	if not fronts.is_empty():
		var pts:PackedVector2Array=fronts[0].points
		var at:Vector2=overlay._screen(pts[pts.size()/2])
		overlay.open_note(overlay.hit_at(at) if not overlay.hit_at(at).is_empty() else {"kind":"front","armies":fronts[0].get("armies",[])},at)
		await _frames(4)
		_save("mature_%s_note_%s.png" % [view[0],stage])
		overlay.close_note()
	# Their hosts fall back two fifths of the span: the line follows over days.
	var pushed:=fixture.duplicate(true)
	var axis:=(target-home).normalized()
	for e in pushed.enemy: e.pos=(e.pos as Vector2)+axis*home.distance_to(target)*0.08
	overlay.set("extra_inputs",pushed)
	overlay.set("collect_elapsed",99.0)
	for k in 3:
		await get_tree().create_timer(0.35).timeout
		_save("mature_%s_motion%d_%s.png" % [view[0],k,stage])


func _plates(views:Array,prefix:String="mature")->void:
	var has_hook:=overlay!=null and "extra_inputs" in overlay
	if overlay!=null and has_hook: overlay.set("extra_inputs",fixture)
	for view in views:
		var band:String=view[0]
		terrain.camera_target=Vector3(view[2].x,terrain._height_at(view[2].x,view[2].y),view[2].y)
		terrain.camera.size=float(view[1])
		terrain._update_camera()
		terrain._refresh_player_field_army_markers()
		await _settle()
		if overlay!=null:
			if has_hook:
				# Snap to the settled drawing (the easing is shown separately).
				var live:Dictionary=overlay.collect()
				overlay.set("inputs_signature",hash(live)); overlay.set("collect_elapsed",0.0)
				overlay.set_scene(Overlay.compose(live),true)
			else:
				# Round-one code: the same real inputs plus the same fixture,
				# composed by its own static compose().
				var inputs:Dictionary=overlay.collect()
				overlay.set("inputs_signature",hash(inputs)); overlay.set("collect_elapsed",0.0)
				for key in fixture: inputs[key]=(inputs.get(key,[]) as Array)+(fixture[key] as Array) if fixture[key] is Array else fixture[key]
				overlay.set_scene(Overlay.compose(inputs),true)
		await _frames(8)
		var start:=Time.get_ticks_usec()
		RenderingServer.force_draw(true,0.0)
		var frame_ms:=float(Time.get_ticks_usec()-start)/1000.0
		var image:=get_viewport().get_texture().get_image()
		var path:=directory.path_join("%s_%s_%s.png" % [prefix,band,stage])
		image.save_png(path)
		var scene:Dictionary=overlay.get("scene") if overlay!=null else {}
		print("REAL CAPTURE plate=%s band=%s camera=%.0f km mode=%s fronts=%d clashes=%d compose_us=%d frame_ms=%.1f redraws=%d" % [path.get_file(),band,float(view[1]),String(scene.get("mode","")),
			(scene.get("fronts",[]) as Array).size(),(scene.get("clashes",[]) as Array).size(),int(overlay.get("last_compose_usec")) if overlay!=null else -1,frame_ms,int(overlay.get("redraws")) if overlay!=null else -1])

