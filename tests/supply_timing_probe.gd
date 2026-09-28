extends Node
## TEST PROBE (not the game): supply field timing on a real grounded world.
## Headless: <godot> --headless --path . res://tests/supply_timing_probe.tscn
## Prints SUPPLY_TIMING {json} and quits. Never saves.
##   spec: cost of SupplyState.spec() cached and in full, per engine call;
##   build: a full 96x96 build with ground sampling and a rebuild with the
##          ground cached (on the main thread, for timing only), and a worker
##          build's wall time;
##   march: geo_key changes while a band marches 300 km out and back
##          (with and without revealing land round it each day);
##   day: main-thread cost of a day's rations with five bands out.
const Supply:=preload("res://scripts/supply_state.gd")
const March:=preload("res://scripts/march_terrain.gd")
var terrain:Node
var _out:={}

func _ready()->void:
	get_tree().create_timer(240.0).timeout.connect(func(): print("SUPPLY_TIMING TIMEOUT"); get_tree().quit(3))
	GameState.reset_for_new_world(74017);GameState.civic_api_enabled=false
	DiscoverySystem.reset_for_new_world();ProgressionSystem.reset_for_new_world();ResourceSystem.reset_for_new_world();FoodSystem.reset_for_new_world();ConsequenceEngine.reset_for_new_world();CivilizationSystem.reset_for_new_world();MilitaryCampaign.reset_for_new_world()
	GameState.select_founding_focus("provision")
	GameState.settlement_site_committed=true;GameState.settlement_completed=["Hearth Circle"];SettlementModel.ensure_founded()
	GameState.settlement_name="Seanstone"
	_say("reset done")
	terrain=preload("res://local_terrain.tscn").instantiate();add_child(terrain);terrain._set_game_speed(0)
	_say("terrain added")
	for f in 8: await get_tree().process_frame
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	var out:=_out
	var home:Vector2=CivilizationSystem.player_world_origin
	Supply.reset()
	# The largest lattice: known land wide enough for 96 nodes a side.
	var radius:=560.0
	var s:={}
	while radius<900.0:
		_know(home,radius)
		s=Supply.spec()
		if int(s.get("nx",0))>=96: break
		radius+=8.0
	_say("lattice found")
	out["lattice"]={"n":int(s.get("nx",0)),"cell_km":float(s.get("cell",0.0)),"known_radius_km":radius,"async":bool(s.get("async",false))}
	# (1) spec(): cached, and in full.
	var t0:=Time.get_ticks_usec()
	for k in 500: Supply.spec()
	out["spec_cached_us"]=float(Time.get_ticks_usec()-t0)/500.0
	t0=Time.get_ticks_usec()
	for k in 20:
		Supply._spec_sig=-1
		Supply.spec()
	out["spec_full_us"]=float(Time.get_ticks_usec()-t0)/20.0
	_say("spec timed")
	# (2) builds, timed on the main thread (the game never builds here).
	s=Supply.spec()
	t0=Time.get_ticks_usec()
	var full:=Supply.build(s,{},[false])
	_say("full build")
	out["build_full_ms"]=float(Time.get_ticks_usec()-t0)/1000.0
	out["build_full_sampling_ms"]=float(full.get("sample_ms",0.0))
	t0=Time.get_ticks_usec()
	var again:=Supply.build(s,full.ground,[false])
	out["rebuild_cached_ground_ms"]=float(Time.get_ticks_usec()-t0)/1000.0
	_say("rebuild")
	# The worst case asked for: a 96x96 lattice at the same cell.
	var s96:=s.duplicate()
	s96["nx"]=96; s96["ny"]=96; s96["geo_key"]=hash([int(s.geo_key),96]); s96["key"]=hash([int(s.key),96])
	t0=Time.get_ticks_usec()
	var big:=Supply.build(s96,{},[false])
	out["build_96_full_ms"]=float(Time.get_ticks_usec()-t0)/1000.0
	out["build_96_sampling_ms"]=float(big.get("sample_ms",0.0))
	t0=Time.get_ticks_usec()
	Supply.build(s96,big.ground,[false])
	out["rebuild_96_cached_ground_ms"]=float(Time.get_ticks_usec()-t0)/1000.0
	# The fused sampler's ground against the marching ground at some nodes.
	var worst:={"h":0.0,"wood":0.0,"t":0.0,"rain":0.0,"wet":0.0}
	var n:=int(full.nx)*int(full.ny)
	for i in range(0,n,n/60):
		var p:=Supply.node_pos(full,i)
		var g:=March.ground_at(p)
		if g.is_empty(): continue
		for key in worst:
			var mine:=float((full.ground[key] as PackedFloat32Array)[i])
			worst[key]=maxf(float(worst[key]),absf(mine-float(g.get(key,0.0))))
	out["ground_vs_march_max_diff"]=worst
	_say("ground compared")
	# A worker build's wall time, and the main thread's cost meanwhile.
	Supply.reset(); _know(home,radius)
	var main_us:=0
	t0=Time.get_ticks_usec()
	var k0:=Time.get_ticks_usec(); Supply.field(); main_us+=Time.get_ticks_usec()-k0
	var job_ms:=0.0
	while not Supply.current():
		await get_tree().process_frame
		if Supply._job!=null: job_ms=maxf(job_ms,Supply._job.ms)
		k0=Time.get_ticks_usec(); Supply.prefetch(); main_us+=Time.get_ticks_usec()-k0
		if Time.get_ticks_usec()-t0>60000000: break
	out["worker_build_wall_ms"]=float(Time.get_ticks_usec()-t0)/1000.0
	out["worker_build_ms"]=float(Supply._field.get("ms",0.0))
	out["main_thread_us_while_building"]=main_us
	_say("worker build")
	# (3) a band marching 300 km out and back, 20 km a day.
	for reveal in [false,true]:
		Supply.reset(); _know(home,120.0)
		MilitaryCampaign.field_armies.assign([_band(7,home)])
		var keys:={}; var geo:={}
		var last_geo:=0; var changes:=0
		var builds:=Supply.async_builds
		for day in 31:
			var km:=float(day if day<=15 else 30-day)*20.0
			var at:=home+Vector2(km,km*0.2)
			MilitaryCampaign.field_armies[0].position={"x":at.x,"z":at.y}
			if reveal:
				CivilizationSystem.revealed_areas.append({"kind":"circle","x":at.x,"z":at.y,"radius":30.0,"day":day})
				CivilizationSystem.fog_revision+=1
			GameState.elapsed_days+=1
			var sp:=Supply.spec()
			if int(sp.geo_key)!=last_geo: changes+=1; last_geo=int(sp.geo_key)
			keys[int(sp.key)]=true
			Supply.haul_for(MilitaryCampaign.field_armies[0])
			for f in 2: await get_tree().process_frame
		out["march_reveal" if reveal else "march"]={"geo_key_changes":changes-1,"keys":keys.size(),"worker_builds":Supply.async_builds-builds}
	_say("march")
	# (4) the main thread's cost of a day's rations with five bands out.
	Supply.reset(); _know(home,300.0)
	var bands:Array[Dictionary]=[]
	for k in 5: bands.append(_band(10+k,home+Vector2.from_angle(float(k)*1.2)*float(40+k*50)))
	MilitaryCampaign.field_armies.assign(bands)
	Supply.field()
	while not Supply.current():
		await get_tree().process_frame
		Supply.prefetch()
	var day_us:=0
	for day in 20:
		GameState.elapsed_days+=1
		var d0:=Time.get_ticks_usec()
		var credit:Dictionary=MilitaryCampaign.draw_delivered_field_rations(60.0)
		var accessible:=(60.0-float(credit.total))*MilitaryCampaign.field_provision_delivery_ratio(60.0,credit)
		MilitaryCampaign.record_daily_provisions(60.0,accessible,credit)
		day_us+=Time.get_ticks_usec()-d0
	out["rations_day_us_5_bands"]=float(day_us)/20.0
	var d1:=Time.get_ticks_usec()
	for k in 20: Supply.forces()
	out["forces_report_us"]=float(Time.get_ticks_usec()-d1)/20.0
	Supply.shutdown()
	print("SUPPLY_TIMING ",JSON.stringify(out))
	get_tree().quit(0)

func _say(what:String)->void:
	print("SUPPLY_TIMING_STEP %s at %.1fs %s" % [what,float(Time.get_ticks_msec())/1000.0,JSON.stringify(_out)])

func _know(home:Vector2,radius:float)->void:
	CivilizationSystem.revealed_areas.assign([{"kind":"circle","x":home.x,"z":home.y,"radius":radius,"day":0}])
	CivilizationSystem.fog_revision+=1

func _band(id:int,at:Vector2)->Dictionary:
	return {"army_id":id,"name":"LEVY BAND %d" % id,"troops":60,"status":"stationed","location_id":"field","position":{"x":at.x,"z":at.y},
		"formations":[],"supply_level":1.0,"commander":{"name":"Rovik Ashdown","logistics":0.4}}
