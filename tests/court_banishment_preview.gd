extends "res://tests/court_custody_preview.gd"
## Actual offline order/menu receipts; five bounded private GPU stills.
const Executions:=preload("res://scripts/hud/court_executions.gd")

class RenderedPose extends SkeletonModifier3D:
	var body:Node3D
	func _process_modification_with_delta(_delta:float)->void:
		var skeleton:=get_skeleton()
		if skeleton==null or body==null:return
		var frames:Dictionary={}
		for name:String in ["foot.L","foot.R","hand.L","hand.R","index.L","index.R"]:
			var bone:=skeleton.find_bone(name)
			if bone>=0:frames[name]=skeleton.global_transform*skeleton.get_bone_global_pose(bone)
		body.set_meta("banishment_probe_pose",{"head":body.head_top(),"frames":frames})

func _ready()->void:
	if DisplayServer.get_name()=="headless" or not ProjectSettings.globalize_path("user://").contains("TomorrowPeopleGrownLandQA"):
		_fail("requires private GPU runner with QA userdata");get_tree().quit(2);return
	folder="res://artifacts/court-banishment/"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):folder=arg.trim_prefix("--out=")
	get_window().size=Vector2i(1280,720);get_window().content_scale_size=Vector2i(1280,720)
	HudTokens.set_color_mode("light")
	for mode:String in ["official","envoy","skip"]:evidence[mode]=await _exercise(mode)
	_write_evidence()
	print("COURT_BANISHMENT_PREVIEW PASS" if failures.is_empty() else "COURT_BANISHMENT_PREVIEW FAIL")
	get_tree().quit(0 if failures.is_empty() else 1)

func _exercise(mode:String)->Dictionary:
	var info:Dictionary=Fixture.new(self).base(false)
	for person:Dictionary in GovernmentPeopleSystem.people:person["born_day"]=int(person.get("born_day",0))+600*365
	GameState.elapsed_days=600*365
	GameState.known_discoveries.assign(["temple_high_steward","pictographic_records","plain_weaving"])
	Backdrop.tier_override=-1;Backdrop.Stages.stage_override="";Backdrop.Voice.knowledge_override.clear()
	var terrain:=TerrainDouble.new();add_child(terrain)
	var director:=Director.new();director.terrain=terrain;add_child(director);director.voice.force_offline=true
	var pid:=0;var known_id:="";var civ_id:=String(info.civ_id)
	var audience:Dictionary={}
	if mode=="official":
		pid=int(GovernmentPeopleSystem.officeholder("Marshal").get("person_id",0))
		GovernmentPeopleSystem._person_record(pid)["born_day"]=int(GameState.elapsed_days)-45*365
		audience=Hall.summon({"person_id":pid})
	elif mode=="envoy":audience=Hall.debug_force("news",civ_id)
	else:
		var known:Dictionary=Persons.create({"sex":"male","trade":"gatherer"})
		known.born_day=int(GameState.elapsed_days)-45*365;known_id=String(known.id)
		audience=Persons.summon_ref({"kind":"known","id":known_id},"")
	var id:=String(audience.get("id",""))
	if id.is_empty():_fail(mode+": no audience");director.queue_free();terrain.queue_free();return {}
	var modal:Control=director.open_audience(id)
	await _wait_scene(modal,id,1)
	modal.skip_reveal();modal.court_stage.settle();await get_tree().create_timer(0.4).timeout
	var stage:Control=modal.court_stage;var victim:Variant=stage.figure("main");var body:Node3D=victim.body3d
	if Executions.is_child(victim.person):_fail(mode+": fixture is not adult")
	if mode!="envoy" and int(victim.person.get("age",0))!=45:_fail(mode+": fixture age is not45")
	if String(stage.court_set.kind)!="chapter_03":_fail(mode+": expected chapter03")
	var identity:Dictionary=victim.person.duplicate(true)
	var cast_before:Dictionary={}
	for key:String in stage.cast_order:
		var f:Variant=stage.figure(key)
		if f==null or f.body3d==null:continue
		cast_before[key]={"nudge":f.nudge,"lift":f.lift}
		var observer:=RenderedPose.new();observer.name="BanishmentProbePose";observer.body=f.body3d;f.body3d.skeleton.add_child(observer)
	var result:Dictionary={}
	if mode=="official":
		modal.speech_input.text="Exile him.";modal._speak()
		var receipts:Array=modal.get("_custody_results")
		if not receipts.is_empty():result=receipts[-1].duplicate(true)
	elif mode=="envoy":result=modal.act_on_envoy("envoy_exile")
	else:result=modal.persons_choose({"action":"exile","params":{},"label":"Exile"})
	var population_after:=float(GameState.population_exact)
	var foreign_after:=float(ForeignDiplomacy.civilization(civ_id).get("population",0.0))
	print("BANISHMENT_ORDER mode=",mode," engine=",JSON.stringify(result))
	var started:=Time.get_ticks_usec();var next_sample:=0.0
	var scene_ref:Node;var terminal:Dictionary={};var support:Array=[]
	var phases:Dictionary={};var phase_started:Dictionary={};var framing:Dictionary={};var party_spacing:Dictionary={}
	var gesture:Dictionary={"samples":0,"minimum_alignment":1.0,"door_error_m":0.0}
	var bond_samples:=0;var blocked_samples:=0;var escort_samples:=0;var skipped:=false
	var room:Paths.Room=Paths.room_of(stage.court_set)
	while float(Time.get_ticks_usec()-started)/1000000.0<40.0:
		await get_tree().process_frame
		var seconds:=float(Time.get_ticks_usec()-started)/1000000.0
		if seconds<next_sample:continue
		next_sample=seconds+0.10;await RenderingServer.frame_post_draw
		var current:Node=stage.get("_custody")
		if not is_instance_valid(current):
			if not support.is_empty() or seconds>2.0:break
			continue
		if scene_ref==null:
			scene_ref=current
			current.finished.connect(func()->void:terminal.merge({"state":String(current.get_meta("custody_state","")),"escorted":bool(current.get_meta("escorted",false)),"fallback_reason":String(current.get_meta("fallback_reason","")),"elapsed_seconds":float(current.get_meta("elapsed",0.0))}))
		var state:=String(current.get_meta("custody_state",""))
		if state=="waiting_for_arrivals":continue
		if not phase_started.has(state):phase_started[state]=seconds
		phases[state]=true;support=(current.get_meta("support_keys",[]) as Array).duplicate()
		if String(current.get_meta("presentation",""))!="exile" or String(current.get_meta("victim",""))!="main":_fail(mode+": wrong presentation or target")
		if bool(body.get_meta("custody_bound",false)) or not body.find_children("CustodyBinding*","",true,false).is_empty():bond_samples+=1
		if state in ["escort","returning"]:
			var spacing:=_party_spacing(stage,support)
			if not spacing.is_empty():
				var prior:Dictionary=party_spacing.get(state,{"samples":0,"minimum_m":INF});prior.samples=int(prior.samples)+1
				if float(spacing.minimum_m)<float(prior.minimum_m):prior.merge(spacing,true)
				party_spacing[state]=prior
		if state=="escort":
			escort_samples+=1
			var movers:Array=["main"];movers.append_array(support)
			for key:String in movers:
				var f:Variant=stage.figure(key)
				if f==null or f.body3d==null or not f.body3d.is_visible_in_tree():continue
				var local:Vector3=stage.court_set.to_local(f.body3d.global_position)
				if not Paths.open_at(room,Vector2(local.x,local.z)):blocked_samples+=1
		var peak:bool=state=="door_gesture" and seconds-float(phase_started[state])>=0.55 and seconds-float(phase_started[state])<=0.95
		if peak:
			var actor_key:=String(current.get_meta("gesture_actor",""));var clip:=String(current.get_meta("gesture_clip",""))
			var actor:Variant=stage.figure(actor_key)
			var pose:Dictionary=actor.body3d.get_meta("banishment_probe_pose",{})
			var frames:Dictionary=pose.get("frames",{})
			var suffix:=".L" if clip=="point_l" else ".R"
			if frames.has("index"+suffix):
				var index:Transform3D=frames["index"+suffix]
				var door:Vector3=current.get_meta("gesture_target")
				var direction:Vector3=door-index.origin
				var alignment:=Vector2(index.basis.y.x,index.basis.y.z).normalized().dot(Vector2(direction.x,direction.z).normalized())
				gesture.samples=int(gesture.samples)+1;gesture.minimum_alignment=minf(float(gesture.minimum_alignment),alignment)
				gesture.door_error_m=maxf(float(gesture.door_error_m),door.distance_to(stage.court_set.door_points()[1]))
				gesture.actor=actor_key;gesture.clip=clip;gesture.target=str(door)
		if mode=="official":
			if state=="confront" and not pictures.has("confront"):framing.confront=_bounds(stage,support);_picture("confront")
			if peak and not pictures.has("door-gesture"):framing.gesture=_bounds(stage,support);_picture("door-gesture")
			if escort_samples>=12 and not pictures.has("escort"):framing.escort=_bounds(stage,support);_picture("escort")
		elif mode=="envoy" and escort_samples>=12 and not pictures.has("envoy-escort"):framing.escort=_bounds(stage,support);_picture("envoy-escort")
		if mode=="skip" and peak and not skipped:stage.skip_custody();skipped=true
	await _frames(4);await RenderingServer.frame_post_draw
	var restored:=true
	for key:String in support:
		var f:Variant=stage.figure(key)
		if f==null or not cast_before.has(key):restored=false;continue
		restored=restored and (f.nudge as Vector3).distance_to(cast_before[key].nudge)<0.001 and absf(float(f.lift)-float(cast_before[key].lift))<0.001
	var living:=false;var ledger_status:=""
	if mode=="official":
		var record:Dictionary=GovernmentPeopleSystem.person_snapshot(pid);ledger_status=String(record.get("status",""))
		living=not record.is_empty() and int(record.get("died_day",-1))<0 and ledger_status=="exiled"
		if int((result.get("target",{}) as Dictionary).get("person_id",0))!=pid or int(identity.get("person_id",0))!=pid:_fail(mode+": wrong official identity")
	elif mode=="envoy":
		ledger_status=String(result.get("envoy_state",""));living=ledger_status=="driven out" and String(result.get("harm",""))=="exile"
		if String((result.get("target",{}) as Dictionary).get("name",""))!=String(identity.get("name","")):_fail(mode+": wrong envoy identity")
	else:
		var record:=Persons.by_id(known_id);ledger_status=String(record.get("status",""))
		living=ledger_status=="exiled" and int(record.get("died_day",-1))<0
		if String(identity.get("known_id",""))!=known_id or not bool(result.get("ok",false)):_fail(mode+": wrong known person judgment")
	if mode!="skip" and (not bool(result.get("executed",false)) or String(result.get("verb",""))!="exile"):_fail(mode+": actual order did not adjudicate exile")
	var clean:bool=not stage.custody() and not is_instance_valid(scene_ref) and restored
	if not clean or body.is_visible_in_tree() or not bool(victim.leaving):_fail(mode+": departure/cleanup incomplete")
	if not living or stage.executing() or bool(modal.get("_executed")):_fail(mode+": presentation was not nonfatal")
	if float(GameState.population_exact)!=population_after or float(ForeignDiplomacy.civilization(civ_id).get("population",0.0))!=foreign_after:_fail(mode+": animation changed the post-judgment population ledger")
	if support.size()!=2 or bond_samples>0 or blocked_samples>0:_fail(mode+": escort party, free wrists, or path clearance failed")
	if int(gesture.samples)==0 or float(gesture.minimum_alignment)<0.85 or float(gesture.door_error_m)>0.001:_fail(mode+": rendered pointing finger did not indicate actual exit")
	for phase:String in party_spacing:
		if float(party_spacing[phase].minimum_m)<2.0*Paths.WALKER-0.001:_fail(mode+": walking party overlapped")
	for label:String in framing:
		if not bool(framing[label].fits):_fail(mode+": full gesture/group escaped frame")
	if mode!="skip" and (escort_samples==0 or not phases.has("turn") or not String(terminal.get("fallback_reason","")).is_empty()):_fail(mode+": natural sequence used fallback or missed turn/escort")
	if mode=="skip":
		if not skipped:_fail("skip: no interruption occurred")
		_picture("skip-cleanup")
	var report:Dictionary={"mode":mode,"actual_order":"Exile him." if mode=="official" else ("envoy_exile" if mode=="envoy" else "Persons exile"),"identity":identity,"engine_result":result,"ledger_status":ledger_status,"alive":living,"population_after_judgment":population_after,"population_after_animation":float(GameState.population_exact),"post_judgment_population_unchanged":float(GameState.population_exact)==population_after,"support_keys":support,"phases":phases.keys(),"gesture":gesture,"binding_samples":bond_samples,"escort_samples":escort_samples,"blocked_samples":blocked_samples,"party_spacing":party_spacing,"framing":framing,"terminal":terminal,"wall_seconds":float(Time.get_ticks_usec()-started)/1000000.0,"clean":clean,"guards_restored":restored,"skipped":skipped}
	print("BANISHMENT_AUDIT ",JSON.stringify(report))
	modal.queue_free();director.queue_free();terrain.queue_free();await _frames(4)
	return report

func _bounds(stage:Control,support:Array)->Dictionary:
	var camera:Camera3D=stage.camera;var view:Vector2=camera.get_viewport().get_visible_rect().size
	var allowed:=Rect2(Vector2(6,6),view-Vector2(12,12));var keys:Array=["main"];keys.append_array(support)
	var rows:Array=[];var fits:=true
	for key:String in keys:
		var f:Variant=stage.figure(key);var pose:Dictionary=f.body3d.get_meta("banishment_probe_pose",{})
		var frames:Dictionary=pose.get("frames",{});var points:Array[Vector3]=[]
		if pose.has("head"):points.append(Vector3(pose.head))
		for bone:String in ["foot.L","foot.R","hand.L","hand.R","index.L","index.R"]:
			if frames.has(bone):points.append((frames[bone] as Transform3D).origin)
		var inside:bool=points.size()==7;var projected:Array=[]
		for point:Vector3 in points:
			var pixel:Vector2=camera.unproject_position(point);projected.append(str(pixel))
			inside=inside and not camera.is_position_behind(point) and allowed.has_point(pixel)
		fits=fits and inside;rows.append({"key":key,"head_feet_hands_index":projected,"fits":inside})
	return {"fits":fits,"viewport":str(view),"margin_pixels":6,"figures":rows}
