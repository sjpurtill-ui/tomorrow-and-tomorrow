extends "res://tests/audience_modal_probe.gd"
## Private GPU review through actual adjudication, never stage.beat().
## Two fresh adult chapter-03 fixtures: typed natural completion and an
## office order skipped after repeated contact. Only selected stills are saved.
const Fixture:=preload("res://tests/court_eval/fixtures.gd")
const Backdrop:=preload("res://scripts/hud/court_backdrop.gd")
const Executions:=preload("res://scripts/hud/court_executions.gd")

var pictures:Dictionary={}
var evidence:Dictionary={}
var folder:="res://artifacts/court-beating/"

func _ready()->void:
	if DisplayServer.get_name()=="headless":
		_fail("requires the private GPU runner");get_tree().quit(2);return
	if not ProjectSettings.globalize_path("user://").contains("TomorrowPeopleGrownLandQA"):
		_fail("requires isolated QA userdata");get_tree().quit(2);return
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):folder=arg.trim_prefix("--out=")
	get_window().size=Vector2i(1280,720)
	get_window().content_scale_size=Vector2i(1280,720)
	HudTokens.set_color_mode("light")
	for interrupted:bool in [false,true]:
		var mode:="skip" if interrupted else "natural"
		evidence[mode]=await _exercise(interrupted)
	_write_evidence()
	print("COURT_BEATING_PREVIEW PASS" if failures.is_empty() else "COURT_BEATING_PREVIEW FAIL")
	get_tree().quit(0 if failures.is_empty() else 1)

func _exercise(interrupted:bool)->Dictionary:
	var mode:="skip" if interrupted else "natural"
	Fixture.new(self).base(false)
	# The shared fixture creates its officials near year zero, then advances
	# its scenario clock to year95 without aging them. Keep those generated
	# adult ages when preparing this later visual chapter.
	var shift:=600*365
	for person:Dictionary in GovernmentPeopleSystem.people:
		person["born_day"]=int(person.get("born_day",0))+shift
	GameState.elapsed_days=600*365
	GameState.known_discoveries.assign(["temple_high_steward","pictographic_records","plain_weaving"])
	Backdrop.tier_override=-1;Backdrop.Stages.stage_override="";Backdrop.Voice.knowledge_override.clear()
	Executions.gore="full"
	var terrain:=TerrainDouble.new();add_child(terrain)
	var director:=Director.new();director.terrain=terrain;add_child(director)
	director.voice.force_offline=true
	var person:Dictionary=GovernmentPeopleSystem.officeholder("Marshal")
	var person_id:=int(person.get("person_id",0))
	if person_id<=0:
		_fail(mode+": no adult Marshal");director.queue_free();terrain.queue_free();return {}
	GovernmentPeopleSystem._person_record(person_id)["born_day"]=int(GameState.elapsed_days)-45*365
	person=GovernmentPeopleSystem.person_snapshot(person_id)
	var audience:Dictionary=Hall.summon({"person_id":person_id})
	var id:=String(audience.get("id",""))
	var modal:Control=director.open_audience(id)
	await _wait_scene(modal,id,1)
	modal.skip_reveal();modal.court_stage.settle()
	await get_tree().create_timer(0.5).timeout
	var stage:Control=modal.court_stage
	var victim:Variant=stage.figure("main")
	var population_before:=int(GameState.population_total)
	var cast_before:Dictionary={}
	for key:String in stage.cast_order:
		var figure:Variant=stage.figure(key)
		if figure!=null and figure.body3d!=null:
			cast_before[key]={"person_id":int(figure.person.get("person_id",0)),"position":figure.body3d.global_position,"nudge":figure.nudge,"lift":figure.lift,"visible":figure.body3d.visible}
	if int(victim.person.get("person_id",0))!=person_id:_fail(mode+": target figure does not match summoned adult")
	if int(victim.person.get("age",0))!=45:_fail(mode+": appearance did not use the prepared45-year-old adult")
	if String(stage.court_set.kind)!="chapter_03":_fail(mode+": expected normal ancient chapter03")
	var order:="Flog %s." % String(person.name) if interrupted else "Flog him."
	var engine_result:Dictionary={}
	print("BEATING_ORDER mode=",mode," person_id=",person_id," words=",order)
	if interrupted:engine_result=modal.office_order(order)
	else:
		modal.speech_input.text=order
		modal._speak()
		var results:Array=modal.get("_beating_results")
		if not results.is_empty():engine_result=results[-1].duplicate(true)
	var started:=Time.get_ticks_usec()
	var next_sample:=0.0
	var scene_ref:Node
	var modifiers:Array=[]
	var tweens:Array=[]
	var attacker_keys:Array=[]
	var per_attacker:Dictionary={}
	var maximum_impacts:=0
	var maximum_gap:=0.0
	var maximum_rendered_target_gap:=0.0
	var rendered_target_samples:=0
	var contact_samples:=0
	var maximum_blood:=0
	var saw_aftermath:=false
	var victim_visible_throughout:=true
	var skipped:=false
	var samples:Array=[]
	var framing:Dictionary={}
	var first_blood:Dictionary={}
	while float(Time.get_ticks_usec()-started)/1000000.0<28.0:
		await get_tree().process_frame
		var seconds:=float(Time.get_ticks_usec()-started)/1000000.0
		if seconds<next_sample:continue
		next_sample=seconds+0.10
		await RenderingServer.frame_post_draw
		var current:Node=stage.get_node_or_null("Beating")
		if current==null:
			if is_instance_valid(scene_ref) or not attacker_keys.is_empty():break
			if seconds>2.0:break
			continue
		scene_ref=current
		var state:=String(current.get_meta("beating_state",""))
		if state=="waiting_for_arrivals":continue
		attacker_keys=(current.get_meta("attackers",[]) as Array).duplicate()
		modifiers=(current.get("_modifiers") as Array).duplicate()
		tweens=(current.get("_tweens") as Array).duplicate()
		maximum_impacts=maxi(maximum_impacts,int(current.get_meta("impact_count",0)))
		maximum_gap=maxf(maximum_gap,float(current.get_meta("max_contact_gap",0.0)))
		saw_aftermath=saw_aftermath or state=="aftermath"
		victim_visible_throughout=victim_visible_throughout and bool(current.get_meta("victim_visible",false))
		if String(current.get("victim"))!="main":_fail(mode+": beating selected wrong cast target")
		for modifier:Node in modifiers:
			if not is_instance_valid(modifier) or bool(modifier.get("is_victim")):continue
			var index:=int(modifier.get("index"))
			per_attacker[str(index)]=maxi(int(per_attacker.get(str(index),0)),int(modifier.get("contacts")))
			if bool(modifier.get_meta("contact_phase",false)):
				contact_samples+=1
				maximum_gap=maxf(maximum_gap,float(modifier.get_meta("contact_gap",0.0)))
				var posed:Dictionary=victim.body3d.get_meta("beating_rendered_bone_frames",{})
				if posed.has("chest") and modifier.has_meta("fist_point"):
					var chest:Transform3D=posed.chest
					var attacker:Node3D=modifier.get("body")
					var radial:Vector3=attacker.global_position-chest.origin
					radial.y=0.0
					var target_point:Vector3=chest.origin+radial.normalized()*0.14+chest.basis.y.normalized()*0.08
					var fist_point:Vector3=modifier.get_meta("fist_point")
					maximum_rendered_target_gap=maxf(maximum_rendered_target_gap,fist_point.distance_to(target_point))
					rendered_target_samples+=1
		var blood:Node=stage.court_set.get_node_or_null("Blood")
		if blood!=null:maximum_blood=maxi(maximum_blood,int(blood.get("landed")))
		if maximum_blood>0 and first_blood.is_empty():first_blood=_blood_attachment_audit(victim.body3d)
		samples.append({"seconds":seconds,"state":state,"impacts":maximum_impacts,"blood":maximum_blood})
		if not interrupted:
			if maximum_impacts>=1 and not pictures.has("contact"):_store_picture("contact")
			if maximum_impacts>=7 and not pictures.has("repeated"):
				framing["repeated"]=_screen_bounds_audit(stage,attacker_keys)
				_store_picture("repeated")
			if state=="aftermath" and not pictures.has("aftermath"):
				framing["aftermath"]=_screen_bounds_audit(stage,attacker_keys)
				_store_picture("aftermath")
		elif maximum_impacts>=4 and not skipped:
			stage.skip_beating();skipped=true
	await _frames(4)
	await get_tree().create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	_store_picture("skip-restored" if interrupted else "end")
	var cleanup:bool=not stage.beating() and stage.get_node_or_null("Beating")==null and not is_instance_valid(scene_ref)
	var live_modifiers:=0
	for modifier in modifiers:
		if is_instance_valid(modifier):live_modifiers+=1
	var active_tweens:=0
	for tween in tweens:
		if is_instance_valid(tween) and tween.is_valid():active_tweens+=1
	var maximum_return_error:=0.0
	var restored:=true
	for key:String in attacker_keys:
		var figure:Variant=stage.figure(key)
		if figure==null or not cast_before.has(key):restored=false;continue
		maximum_return_error=maxf(maximum_return_error,figure.body3d.global_position.distance_to(cast_before[key].position))
		restored=restored and (figure.nudge as Vector3).distance_to(cast_before[key].nudge)<0.001 and absf(float(figure.lift)-float(cast_before[key].lift))<0.001
	var survivor:Dictionary=GovernmentPeopleSystem.person_snapshot(person_id)
	var alive:=not survivor.is_empty() and int(survivor.get("died_day",-1))<0
	var nonfatal:bool=alive and int(GameState.population_total)==population_before and not bool(engine_result.get("removed",false)) and not stage.executing() and not bool(modal.get("_executed"))
	if not bool(engine_result.get("executed",false)) or String(engine_result.get("verb",""))!="maim" or String(engine_result.get("harm",""))!="beat":_fail(mode+": actual order was not adjudicated as a nonfatal beating")
	if int((engine_result.get("target",{}) as Dictionary).get("person_id",0))!=person_id:_fail(mode+": adjudication targeted another person")
	if not nonfatal:_fail(mode+": victim did not remain alive in unchanged population")
	if not victim_visible_throughout:_fail(mode+": victim disappeared during the punishment")
	if attacker_keys.size()!=3 or per_attacker.size()!=3:_fail(mode+": fewer than three contacting attackers")
	if not interrupted:
		for count in per_attacker.values():
			if int(count)<2:_fail("natural: attacker did not make repeated contact")
		if maximum_impacts<9 or not saw_aftermath:_fail("natural: repeated full performance did not complete")
	if contact_samples==0 or maximum_gap>0.05:_fail(mode+": true rendered contact missing or gap exceeds5cm")
	if rendered_target_samples==0 or maximum_rendered_target_gap>0.05:_fail(mode+": fist misses victim's independently cached rendered chest by more than5cm")
	if maximum_blood<=0:_fail(mode+": full setting produced no blood")
	if not bool(first_blood.get("ready",false)) or float(first_blood.get("max_initial_gap_m",1.0))>0.05:_fail(mode+": first blood attachment was not aligned with the posed bone")
	if not interrupted:
		for label:String in ["repeated","aftermath"]:
			if not bool((framing.get(label,{}) as Dictionary).get("fits",false)):_fail("natural: "+label+" full figures do not fit the stage camera margin")
	if not cleanup or live_modifiers>0 or active_tweens>0 or not restored:_fail(mode+": stage, modifiers, tweens or cast state did not restore")
	if interrupted and not skipped:_fail("skip: never reached interruption point")
	var result:Dictionary={"order":order,"path":"office_order" if interrupted else "speech_input/_speak","reader":"offline","chapter":String(stage.court_set.kind),"person_id":person_id,"person_name":String(person.name),"person_age":GovernmentPeopleSystem.age_years(survivor),"engine_executed":bool(engine_result.get("executed",false)),"engine_verb":engine_result.get("verb"),"engine_harm":engine_result.get("harm"),"engine_target":engine_result.get("target"),"nonfatal":nonfatal,"attackers":attacker_keys,"impacts":maximum_impacts,"contacts_by_attacker":per_attacker,"contact_samples":contact_samples,"max_contact_gap_m":maximum_gap,"blood_splats":maximum_blood,"saw_aftermath":saw_aftermath,"skipped":skipped,"cleanup":cleanup,"live_modifiers":live_modifiers,"active_tweens":active_tweens,"cast_restored":restored,"max_attacker_return_error_m":maximum_return_error,"samples":samples}
	result["victim_visible_throughout"]=victim_visible_throughout
	result["framing"]=framing
	result["first_blood_attachments"]=first_blood
	result["appearance_age"]=int(victim.person.get("age",0))
	result["rendered_target_samples"]=rendered_target_samples
	result["max_gap_to_rendered_victim_m"]=maximum_rendered_target_gap
	print("BEATING_AUDIT ",JSON.stringify(result))
	modal.queue_free();director.queue_free();terrain.queue_free()
	await _frames(4)
	return result

func _screen_bounds_audit(stage:Control,attackers:Array)->Dictionary:
	var camera:Camera3D=stage.camera
	var view:Vector2=camera.get_viewport().get_visible_rect().size
	var allowed:=Rect2(Vector2(6.0,6.0),view-Vector2(12.0,12.0))
	var keys:Array=["main"]
	keys.append_array(attackers)
	var rows:Array=[]
	var all_fit:=true
	for key:String in keys:
		var figure:Variant=stage.figure(key)
		var body:Node3D=figure.body3d
		var pose:Dictionary=body.get_meta("beating_rendered_bounds",{})
		if not pose.has("head") or not pose.has("feet"):
			all_fit=false;rows.append({"key":key,"missing_rendered_pose":true});continue
		var points:Array[Vector3]=[Vector3(pose.head)]
		for foot:Vector3 in pose.feet:points.append(foot)
		var projected:Array=[]
		var bounds:=Rect2(camera.unproject_position(points[0]),Vector2.ZERO)
		var fits:=true
		for point:Vector3 in points:
			var pixel:Vector2=camera.unproject_position(point)
			projected.append(str(pixel));bounds=bounds.expand(pixel)
			fits=fits and not camera.is_position_behind(point) and allowed.has_point(pixel)
		all_fit=all_fit and fits
		rows.append({"key":key,"person_id":int(figure.person.get("person_id",0)),"head_and_feet_world":str(points),"projected_head_and_feet":projected,"bounds":str(bounds),"fits":fits})
	return {"viewport_size":str(view),"margin_pixels":6,"fits":all_fit,"figures":rows,"source":"post-animation modifier rendered head and feet metadata"}

func _blood_attachment_audit(body:Node3D)->Dictionary:
	var skeleton:Skeleton3D=body.get("skeleton")
	var frames:Dictionary=body.get_meta("beating_rendered_bone_frames",{})
	var rows:Array=[]
	var max_gap:=0.0
	for bone:String in ["chest","head"]:
		var holder:Node3D=skeleton.get_node_or_null("Blood_"+bone)
		if holder==null or not holder.has_meta("blood_initial_holder_gap"):continue
		var frame:Transform3D=frames.get(bone,Transform3D.IDENTITY)
		var gap:float=holder.global_position.distance_to(frame.origin) if frames.has(bone) else 1.0
		max_gap=maxf(max_gap,gap)
		rows.append({"bone":bone,"initial_bone_world":str(holder.get_meta("blood_initial_bone_world")),"initial_holder_gap_m":float(holder.get_meta("blood_initial_holder_gap")),"first_visible_holder_world":str(holder.global_position),"victim_rendered_bone_world":str(frame.origin),"first_visible_gap_to_rendered_bone_m":gap,"stickers":holder.get_child_count()})
	return {"ready":rows.size()==2,"max_initial_gap_m":max_gap,"holders":rows}

func _store_picture(label:String)->void:
	pictures[label]=get_viewport().get_texture().get_image()

func _write_evidence()->void:
	var path:=ProjectSettings.globalize_path(folder)
	DirAccess.make_dir_recursive_absolute(path)
	for label:String in pictures:
		var result:Error=(pictures[label] as Image).save_png(path.path_join(label+".png"))
		if result!=OK:_fail("could not encode "+label)
	evidence.merge({"scope":"Prepared later-court fixtures; actual engine adjudication and GPU performance, offline typed/menu-equivalent orders","keyframes":pictures.keys(),"buffered_before_encoding":true,"failures":failures,"passed":failures.is_empty()})
	var file:=FileAccess.open(path.path_join("audit.json"),FileAccess.WRITE)
	if file!=null:file.store_string(JSON.stringify(evidence,"\t"))
	else:_fail("could not write audit.json")
