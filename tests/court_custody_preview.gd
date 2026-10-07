extends "res://tests/audience_modal_probe.gd"
## Bounded private GPU acceptance through actual Commands/Persons adjudication.
## Five stills in RAM; no live API, save writes, or stage.detain bypass.
const Fixture:=preload("res://tests/court_eval/fixtures.gd")
const Backdrop:=preload("res://scripts/hud/court_backdrop.gd")
const Persons:=preload("res://scripts/court_persons.gd")
const Paths:=preload("res://scripts/hud/court_paths.gd")
var pictures:Dictionary={}
var evidence:Dictionary={}
var folder:="res://artifacts/court-custody/"

func _ready()->void:
	if DisplayServer.get_name()=="headless" or not ProjectSettings.globalize_path("user://").contains("TomorrowPeopleGrownLandQA"):
		_fail("requires private GPU runner with QA userdata");get_tree().quit(2);return
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):folder=arg.trim_prefix("--out=")
	get_window().size=Vector2i(1280,720);get_window().content_scale_size=Vector2i(1280,720)
	HudTokens.set_color_mode("light")
	for mode:String in ["arrest","bind","skip"]:evidence[mode]=await _exercise(mode)
	_write_evidence()
	print("COURT_CUSTODY_PREVIEW PASS" if failures.is_empty() else "COURT_CUSTODY_PREVIEW FAIL")
	get_tree().quit(0 if failures.is_empty() else 1)

func _exercise(mode:String)->Dictionary:
	Fixture.new(self).base(false)
	for person:Dictionary in GovernmentPeopleSystem.people:person["born_day"]=int(person.get("born_day",0))+600*365
	GameState.elapsed_days=600*365
	GameState.known_discoveries.assign(["temple_high_steward","pictographic_records","plain_weaving"])
	Backdrop.tier_override=-1;Backdrop.Stages.stage_override="";Backdrop.Voice.knowledge_override.clear()
	var terrain:=TerrainDouble.new();add_child(terrain)
	var director:=Director.new();director.terrain=terrain;add_child(director);director.voice.force_offline=true
	var person_id:=0
	var known_id:=""
	var audience:Dictionary={}
	if mode=="arrest":
		var marshal:Dictionary=GovernmentPeopleSystem.officeholder("Marshal")
		person_id=int(marshal.get("person_id",0))
		GovernmentPeopleSystem._person_record(person_id)["born_day"]=int(GameState.elapsed_days)-45*365
		audience=Hall.summon({"person_id":person_id})
	else:
		var known:Dictionary=Persons.create({"sex":"male","trade":"gatherer"})
		known["born_day"]=int(GameState.elapsed_days)-45*365;known_id=String(known.id)
		audience=Persons.summon_ref({"kind":"known","id":known_id},"")
	var id:=String(audience.get("id",""))
	if id.is_empty():_fail(mode+": no adult audience");director.queue_free();terrain.queue_free();return {}
	var modal:Control=director.open_audience(id)
	await _wait_scene(modal,id,1)
	modal.skip_reveal();modal.court_stage.settle();await get_tree().create_timer(0.4).timeout
	var stage:Control=modal.court_stage
	var victim:Variant=stage.figure("main")
	var body:Node3D=victim.body3d
	if int(victim.person.get("age",0))!=45:_fail(mode+": actual cast is not prepared45-year-old adult")
	if String(stage.court_set.kind)!="chapter_03":_fail(mode+": expected actual later chapter03")
	if mode=="arrest" and int(victim.person.get("person_id",0))!=person_id:_fail(mode+": wrong official on stage")
	if mode!="arrest" and String(victim.person.get("known_id",""))!=known_id:_fail(mode+": wrong known person on stage")
	var population_before:=int(GameState.population_total)
	var cast_before:Dictionary={}
	for key:String in stage.cast_order:
		var f:Variant=stage.figure(key)
		if f!=null and f.body3d!=null:cast_before[key]={"nudge":f.nudge,"lift":f.lift,"position":f.body3d.global_position}
	var result:Dictionary={}
	if mode=="arrest":
		modal.speech_input.text="Arrest him.";modal._speak()
		var receipts:Array=modal.get("_custody_results")
		if not receipts.is_empty():result=receipts[-1].duplicate(true)
	else:
		result=Persons.perform(id,"bind",{});modal._after_persons(result)
	print("CUSTODY_ORDER mode=",mode," person_id=",person_id," known_id=",known_id," engine=",JSON.stringify(result))
	var started:=Time.get_ticks_usec()
	var next_sample:=0.0
	var scene_ref:Node
	var terminal:Dictionary={}
	var support:Array=[]
	var contacts:Dictionary={}
	var max_gap:=0.0
	var max_cord_gap:=0.0
	var cord_samples:=0
	var escort_samples:=0
	var blocked_samples:=0
	var party_spacing:Dictionary={}
	var phases:Dictionary={}
	var framing:Dictionary={}
	var skipped:=false
	var room:Paths.Room=Paths.room_of(stage.court_set)
	while float(Time.get_ticks_usec()-started)/1000000.0<(40.0 if mode=="arrest" else 28.0):
		await get_tree().process_frame
		var seconds:=float(Time.get_ticks_usec()-started)/1000000.0
		if seconds<next_sample:continue
		next_sample=seconds+0.10
		await RenderingServer.frame_post_draw
		var current:Node=stage.get("_custody")
		if not is_instance_valid(current):
			if not support.is_empty() or seconds>2.0:break
			continue
		if scene_ref==null:
			scene_ref=current
			current.finished.connect(func()->void:
				terminal.merge({"state":String(current.get_meta("custody_state","")),"escorted":bool(current.get_meta("escorted",false)),"depart":bool(current.get_meta("depart",false)),"fallback_reason":String(current.get_meta("fallback_reason",""))}))
		var state:=String(current.get_meta("custody_state",""))
		if state=="waiting_for_arrivals":continue
		phases[state]=true
		support=(current.get_meta("support_keys",[]) as Array).duplicate()
		if String(current.get_meta("victim","main"))!="main":_fail(mode+": custody targeted another cast member")
		var frames:Dictionary=body.get_meta("custody_rendered_bone_frames",{})
		for key:String in support:
			var guard:Variant=stage.figure(key)
			if guard==null or guard.body3d==null:continue
			var guard_body:Node3D=guard.body3d
			var modifier:Node=guard_body.skeleton.get_node_or_null("CustodyGrip")
			if modifier!=null and bool(modifier.get_meta("contact_phase",false)):
				var suffix:=".L" if int(modifier.get("index"))==0 else ".R"
				if frames.has("upper_arm"+suffix) and frames.has("forearm"+suffix) and modifier.has_meta("fist_point"):
					var upper:Transform3D=frames["upper_arm"+suffix]
					var lower:Transform3D=frames["forearm"+suffix]
					var anchor:Vector3=upper.origin.lerp(lower.origin,0.5)
					anchor+=(guard_body.global_position-anchor).normalized()*0.045
					var fist:Vector3=modifier.get_meta("fist_point")
					max_gap=maxf(max_gap,fist.distance_to(anchor));contacts[key]=int(contacts.get(key,0))+1
		var cord:Node3D=body.get_node_or_null("CustodyBinding")
		var cord_visible:bool=cord!=null and cord.is_visible_in_tree()
		if cord_visible and frames.has("hand.L") and frames.has("hand.R"):
			for side in 2:
				var wrist:Transform3D=frames["hand.L" if side==0 else "hand.R"]
				var loop:Node3D=cord.get_node("WristLoop%d" % side)
				max_cord_gap=maxf(max_cord_gap,loop.global_position.distance_to(wrist.origin))
			cord_samples+=1
		if state=="escort":
			escort_samples+=1
			var movers:Array=["main"];movers.append_array(support)
			for key:String in movers:
				var f:Variant=stage.figure(key)
				if f==null or f.body3d==null or not f.body3d.visible:continue
				var local:Vector3=stage.court_set.to_local(f.body3d.global_position)
				if not Paths.open_at(room,Vector2(local.x,local.z)):blocked_samples+=1
		if state in ["escort","returning"]:
			var spacing:=_party_spacing(stage,support)
			if not spacing.is_empty():
				var previous:Dictionary=party_spacing.get(state,{"samples":0,"minimum_m":INF})
				previous.samples=int(previous.samples)+1
				if float(spacing.minimum_m)<float(previous.minimum_m):
					previous.merge(spacing,true)
				party_spacing[state]=previous
		if mode=="arrest":
			if contacts.size()==2 and not pictures.has("grip"):
				framing["grip"]=_bounds(stage,support);_picture("grip")
			if cord_visible and not pictures.has("binding"):
				framing["binding"]=_bounds(stage,support);_picture("binding")
			if escort_samples>=5 and not pictures.has("escort"):
				framing["escort"]=_bounds(stage,support);_picture("escort")
		if mode=="skip" and cord_visible and contacts.size()==2 and not skipped:
			stage.skip_custody();skipped=true
	await _frames(4)
	await RenderingServer.frame_post_draw
	var helper_clean:bool=not stage.custody() and not is_instance_valid(scene_ref)
	var victim_visible:bool=body.is_visible_in_tree()
	var bound:bool=bool(body.get_meta("custody_bound",false))
	var restored:=true
	var return_error:=0.0
	for key:String in support:
		var f:Variant=stage.figure(key)
		if f==null or not cast_before.has(key):restored=false;continue
		restored=restored and (f.nudge as Vector3).distance_to(cast_before[key].nudge)<0.001 and absf(float(f.lift)-float(cast_before[key].lift))<0.001
		return_error=maxf(return_error,f.body3d.global_position.distance_to(cast_before[key].position))
		if f.body3d.skeleton.get_node_or_null("CustodyGrip")!=null:restored=false
	var living:=false
	if mode=="arrest":
		var survivor:Dictionary=GovernmentPeopleSystem.person_snapshot(person_id)
		living=not survivor.is_empty() and int(survivor.get("died_day",-1))<0
		if not bool(result.get("executed",false)) or String(result.get("verb",""))!="detain":_fail(mode+": typed order was not adjudicated as detention")
		if int((result.get("target",{}) as Dictionary).get("person_id",0))!=person_id:_fail(mode+": engine selected another person")
		if victim_visible or not bool(victim.leaving) or escort_samples==0:_fail(mode+": terminal arrest did not physically escort target out")
	else:
		living=String(Persons.by_id(known_id).get("status",""))=="living"
		if not bool(result.get("ok",false)) or String(result.get("action",""))!="bind":_fail(mode+": actual bind judgment failed")
		if not victim_visible or not bound or not bool(Persons.by_id(known_id).get("bound",false)):_fail(mode+": nonterminal binding did not remain visible and in ledger")
		if mode=="bind":_picture("held-visible")
	if support.size()!=2 or contacts.size()!=2 or max_gap>0.05:_fail(mode+": two rendered guard grips did not stay within5cm of victim anchors")
	if cord_samples==0 or max_cord_gap>0.05:_fail(mode+": visible cord did not follow rendered wrists")
	if blocked_samples>0:_fail(mode+": escort entered a blocked body-clearance floor cell")
	for phase:String in party_spacing:
		if float(party_spacing[phase].minimum_m)<2.0*Paths.WALKER-0.001:_fail(mode+": "+phase+" party centers violated two walking body radii")
	if not living or int(GameState.population_total)!=population_before or stage.executing() or bool(modal.get("_executed")):_fail(mode+": custody was not nonfatal")
	if not helper_clean or not restored:_fail(mode+": temporary helper/grips or guards did not restore")
	if mode!="skip" and not String(terminal.get("fallback_reason","")).is_empty():_fail(mode+": natural sequence used fallback finalization")
	for label:String in framing:
		if not bool(framing[label].fits):_fail(mode+": "+label+" full group escaped stage margin")
	var free_clean:=true
	if mode!="arrest":
		var freed:Dictionary=Persons.perform(id,"free",{});modal._after_persons(freed)
		await _frames(4);await RenderingServer.frame_post_draw
		free_clean=bool(freed.get("ok",false)) and not bool(Persons.by_id(known_id).get("bound",false)) and not bool(body.get_meta("custody_bound",false)) and body.get_node_or_null("CustodyBinding")==null and body.skeleton.get_node_or_null("CustodyBindingPose")==null
		if not free_clean:_fail(mode+": actual free order did not clear persistent bindings")
		if mode=="skip":_picture("skip-cleanup")
	if mode=="skip" and not skipped:_fail("skip: no interruption occurred")
	var report:Dictionary={"mode":mode,"order":"Arrest him." if mode=="arrest" else "Persons bind then free","path":"speech_input/_speak" if mode=="arrest" else "Persons.perform + modal._after_persons","reader":"offline","person_id":person_id,"known_id":known_id,"appearance_age":int(victim.person.get("age",0)),"engine_result":result,"support_keys":support,"grip_samples":contacts,"max_gap_to_rendered_victim_m":max_gap,"cord_samples":cord_samples,"max_cord_to_rendered_wrist_gap_m":max_cord_gap,"escort_samples":escort_samples,"blocked_body_clearance_samples":blocked_samples,"phases":phases.keys(),"terminal":terminal,"framing":framing,"victim_visible_after":victim_visible,"bound_after":bound,"living":living,"population_unchanged":int(GameState.population_total)==population_before,"helper_clean":helper_clean,"guards_restored":restored,"guard_return_error_m":return_error,"skipped":skipped,"free_cleans_binding":free_clean}
	report["party_spacing"]=party_spacing
	report["required_party_spacing_m"]=2.0*Paths.WALKER
	print("CUSTODY_AUDIT ",JSON.stringify(report))
	modal.queue_free();director.queue_free();terrain.queue_free();await _frames(4)
	return report

func _party_spacing(stage:Control,support:Array)->Dictionary:
	var keys:Array=["main"];keys.append_array(support)
	var positions:Dictionary={}
	for key:String in keys:
		var f:Variant=stage.figure(key)
		if f!=null and f.body3d!=null and f.body3d.is_visible_in_tree():
			var point:Vector3=stage.court_set.to_local(f.body3d.global_position)
			positions[key]=Vector2(point.x,point.z)
	var closest:Dictionary={}
	var visible_keys:Array=positions.keys()
	for first in visible_keys.size():
		for second in range(first+1,visible_keys.size()):
			var a:String=visible_keys[first];var b:String=visible_keys[second]
			var gap:float=(positions[a] as Vector2).distance_to(positions[b])
			if closest.is_empty() or gap<float(closest.minimum_m):closest={"minimum_m":gap,"pair":[a,b],"positions":[str(positions[a]),str(positions[b])]}
	return closest

func _bounds(stage:Control,support:Array)->Dictionary:
	var camera:Camera3D=stage.camera
	var view:Vector2=camera.get_viewport().get_visible_rect().size
	var allowed:=Rect2(Vector2(6,6),view-Vector2(12,12))
	var keys:Array=["main"];keys.append_array(support)
	var rows:Array=[]
	var fits:=true
	for key:String in keys:
		var f:Variant=stage.figure(key)
		var pose:Dictionary=f.body3d.get_meta("custody_rendered_bounds",{})
		# Guards no longer have a modifier during escort; their old world cache
		# belongs to the grip location. Read the current ordinary walk pose.
		var skeleton:Skeleton3D=f.body3d.skeleton
		if key!="main" and skeleton.get_node_or_null("CustodyGrip")==null:
			var feet:=PackedVector3Array()
			for bone_name:String in ["foot.L","foot.R"]:
				var bone:=skeleton.find_bone(bone_name)
				if bone>=0:feet.append(skeleton.to_global(skeleton.get_bone_global_pose(bone).origin))
			pose={"head":f.body3d.head_top(),"feet":feet}
		if not pose.has("head") or not pose.has("feet"):fits=false;rows.append({"key":key,"missing_pose":true});continue
		var points:Array[Vector3]=[Vector3(pose.head)]
		for foot:Vector3 in pose.feet:points.append(foot)
		var projected:Array=[]
		var inside:=true
		for point:Vector3 in points:
			var pixel:Vector2=camera.unproject_position(point)
			projected.append(str(pixel));inside=inside and not camera.is_position_behind(point) and allowed.has_point(pixel)
		fits=fits and inside;rows.append({"key":key,"head_and_feet":projected,"fits":inside})
	return {"fits":fits,"viewport":str(view),"margin_pixels":6,"figures":rows}

func _picture(label:String)->void:pictures[label]=get_viewport().get_texture().get_image()

func _write_evidence()->void:
	var path:=ProjectSettings.globalize_path(folder);DirAccess.make_dir_recursive_absolute(path)
	for label:String in pictures:
		if (pictures[label] as Image).save_png(path.path_join(label+".png"))!=OK:_fail("could not write "+label)
	evidence.merge({"scope":"Prepared adult chapter03 fixtures, actual offline engine orders and private GPU, no live API claim","keyframes":pictures.keys(),"failures":failures,"passed":failures.is_empty()})
	var file:=FileAccess.open(path.path_join("audit.json"),FileAccess.WRITE)
	if file!=null:file.store_string(JSON.stringify(evidence,"\t"))
	else:_fail("could not write audit")
