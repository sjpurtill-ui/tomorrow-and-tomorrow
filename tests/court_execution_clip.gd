extends "res://tests/audience_modal_probe.gd"
## An execution at court, end to end, for review: the real Court modal and
## engine; the god gives the order from the "Put to death" menu; the engine
## decides; the hall shows it done (court_executions.gd, the director's
## scene, court_exec_stage.gd).
##   --only=club|behead|dogs|...   the method the god asks for
##   --tier=0|1                    the fire circle (0) or the longhouse (1)
##   --typed-dogs                  submit "Feed him to the dogs." in the speech box
##   --without-resident-dog        use the actual ancient chapter without ambient dogs
##   --output=res://artifacts/...  optional frame/audit destination
## For the review reel the people here are given bronze (the axe) so the
## three-swing beheading can play in either hall. Windowed on a private
## desktop with Godot's movie writer (--write-movie <dir>/f.png --fixed-fps
## 12). Presentation only: the engine decides who dies.

const Backdrop:=preload("res://scripts/hud/court_backdrop.gd")
const Executions:=preload("res://scripts/hud/court_executions.gd")
const Acting:=preload("res://scripts/hud/court_acting.gd")

var only:="club"
var tier:=0
var frame_dir:=""
var frame_index:=0
var review_stage:Control
var saw_execution:=false
var seen_things:Dictionary={}
var checked_marks:Dictionary={}
var bad_marks:Dictionary={}
var typed_dogs:=false
var without_resident_dog:=false
var output_override:=""
var buffered_frames:Array[Image]=[]
var dog_keyframes:Dictionary={}
var dog_pack:Array=[]
var peak_pack:=0
var peak_contacts:=0
var contact_samples:=0
var max_contact_gap:=0.0
var dog_aftermath:=false
var helper_ref:Node
var initial_animals:=0
var dog_audit:Dictionary={}

func _ready()->void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--only="):only=arg.trim_prefix("--only=")
		if arg.begins_with("--tier="):tier=int(arg.trim_prefix("--tier="))
		if arg=="--capture-frames":frame_dir="res://reports/court_execution_review/"
		if arg=="--typed-dogs":typed_dogs=true;only="dogs"
		if arg=="--without-resident-dog":without_resident_dog=true
		if arg.begins_with("--output="):output_override=arg.trim_prefix("--output=")
	if typed_dogs:only="dogs"
	capture=DisplayServer.get_name()!="headless"
	if not frame_dir.is_empty():
		frame_dir=ProjectSettings.globalize_path(output_override if not output_override.is_empty() else frame_dir+"%s-tier%d/" % [only,tier])
		if not frame_dir.ends_with("/"):frame_dir+="/"
		DirAccess.make_dir_recursive_absolute(frame_dir)
	Backdrop.tier_override=tier
	_setup_world()
	if without_resident_dog:
		Backdrop.tier_override=-1;Backdrop.Stages.stage_override=""
		Backdrop.Voice.knowledge_override.clear()
		GameState.known_discoveries.assign(["temple_high_steward","pictographic_records","plain_weaving"])
		GameState.elapsed_days=600*365
	if only=="behead" and not GameState.known_discoveries.has("bronze_alloying"):GameState.known_discoveries.append("bronze_alloying")
	var terrain:=TerrainDouble.new();terrain.name="TerrainDouble";add_child(terrain)
	var director:=Director.new();director.terrain=terrain;add_child(director)
	if "force_offline" in director.voice:director.voice.force_offline=true
	await _frames(2)
	if capture:
		get_window().size=Vector2i(1536,864);get_window().content_scale_size=Vector2i(1536,864)
		await _frames(3)
	HudTokens.set_color_mode("light")
	await _execute(director)
	_write_dog_capture()
	print("COURT_EXECUTION_CLIP PASS" if failures.is_empty() else "COURT_EXECUTION_CLIP FAIL")
	get_tree().quit(0 if failures.is_empty() else 1)

func _wait(seconds:float)->void:
	var deadline:=Time.get_ticks_msec()+int(seconds*1000.0)
	while Time.get_ticks_msec()<deadline:
		await get_tree().create_timer(0.25).timeout
		if is_instance_valid(review_stage):
			var current:Node=review_stage.get_node_or_null("Execution")
			if current!=null:
				saw_execution=true
				for key in current._things:seen_things[key]=true
				_check_plan_marks(current)
				if only=="dogs":_observe_dogs(current)
			if not frame_dir.is_empty() and capture:
				await RenderingServer.frame_post_draw
				if typed_dogs or without_resident_dog:
					buffered_frames.append(get_viewport().get_texture().get_image())
					var state:=String(current.get_meta("dog_attack_state","")) if is_instance_valid(current) else ""
					var label:="contact" if peak_contacts==3 and state=="tug" else state
					if not label.is_empty() and not dog_keyframes.has(label):dog_keyframes[label]=frame_index
					if bool(review_stage.exec_done) and saw_execution:dog_keyframes["end"]=frame_index
				else:review_stage.view3d.get_texture().get_image().save_png(frame_dir+"frame_%04d.png" % frame_index)
				frame_index+=1

func _observe_dogs(current:Node)->void:
	var pack:Array=current.get("_pack")
	peak_pack=maxi(peak_pack,pack.size())
	if not pack.is_empty():dog_pack=pack.duplicate()
	var helper:Node=current.get_node_or_null("DogAttack")
	if helper==null:return
	helper_ref=helper
	peak_contacts=maxi(peak_contacts,int(helper.get_meta("contact_count",0)))
	var state:=String(helper.get_meta("attack_state",""))
	dog_aftermath=dog_aftermath or state=="aftermath"
	for dog:Node3D in pack:
		if not is_instance_valid(dog) or state!="tug" or not bool(dog.get_meta("execution_contact",false)):continue
		var gap:=float(dog.get_meta("execution_contact_gap",-1.0))
		if gap>=0.0:
			contact_samples+=1;max_contact_gap=maxf(max_contact_gap,gap)

func _write_dog_capture()->void:
	if frame_dir.is_empty():return
	for index in buffered_frames.size():buffered_frames[index].save_png(frame_dir+"frame_%04d.png" % index)
	for label:String in dog_keyframes:buffered_frames[int(dog_keyframes[label])].save_png(frame_dir+label+".png")
	if typed_dogs or without_resident_dog:
		dog_audit.merge({"frames":frame_index,"keyframes":dog_keyframes,"buffered_before_encoding":true,"failures":failures,"passed":failures.is_empty()})
		var file:=FileAccess.open(frame_dir+"audit.json",FileAccess.WRITE)
		if file!=null:file.store_string(JSON.stringify(dog_audit,"\t"))

func _check_plan_marks(current:Node)->void:
	# A split alone is not proof of staging: a failed route can leave the
	# executioner swinging several metres away while the victim still splits.
	for role:String in current._plan.get("roles",{}):
		if role=="victim":continue
		var key:=String(current._plan_keys.get(role,""))
		var body:Node3D=current.call("_body",key)
		if body==null:continue
		var actor=Acting.of(body)
		if actor==null or actor._a==null:continue
		if not String(actor._a.clip).begins_with("exec_") or float(actor._a.t)<1.6:continue
		var expected:Vector3=current.call("_plan_at",current._plan.roles[role].at)
		var error:=Vector2(body.global_position.x-expected.x,body.global_position.z-expected.z).length()
		checked_marks[role]=true
		if error>0.25 and not bad_marks.has(role):
			bad_marks[role]=error
			_fail("%s performs %.2f m away from its authored mark" % [role,error])

func _execute(director:Node)->void:
	var audience:=Hall.debug_force("petition")
	if audience.is_empty():_fail("no petition");return
	var id:=String(audience.id)
	var modal:Control=director.open_audience(id)
	await _wait_scene(modal,id,1)
	review_stage=modal.court_stage
	initial_animals=review_stage.court_set.animals.size()
	if without_resident_dog:
		if String(review_stage.court_set.kind)!="chapter_03":_fail("expected actual chapter_03, got "+String(review_stage.court_set.kind))
		if review_stage.court_set.animal("dog")!=null:_fail("later court unexpectedly has a resident dog")
		print("DOG FIXTURE chapter=",review_stage.court_set.kind," presentation=",review_stage.facts.presentation.period," resident_dog=",review_stage.court_set.animal("dog")!=null)
	print("MARK opened")
	await _wait(4.0)
	# This diagnostic reviews the full scene without changing saved preferences.
	Executions.gore="full"
	var name:=String((Hall.find(id).get("speaker",{}) as Dictionary).get("name",""))
	var order:="Put %s to death %s." % [name,String(Executions.ORDER_WORDS.get(only,"before the court"))]
	if typed_dogs:order="Feed him to the dogs."
	print("MARK order ",order)
	var result:Dictionary={}
	if typed_dogs:
		modal.speech_input.text=order
		modal._speak()
		await _wait(0.5)
		result=modal.resolved_result
	else:result=modal.office_order(order)
	print("ORDER executed=",result.get("executed",false)," removed=",result.get("removed",false)," verb=",result.get("verb",""))
	if typed_dogs and not bool(result.get("removed",false)):_fail("typed order did not remove its target through engine adjudication")
	if not typed_dogs and not bool(result.get("removed",false)):
		await _wait(2.0)
		result=modal.office_order("I said it: "+order)
		print("ORDER again executed=",result.get("executed",false)," removed=",result.get("removed",false))
	await _wait(2.0)
	print("EXEC method=",modal.court_stage.exec_method if is_instance_valid(modal.court_stage) else "")
	if (typed_dogs or without_resident_dog) and String(review_stage.exec_method)!=only:_fail("requested %s but actual method was %s" % [only,review_stage.exec_method])
	await _wait(16.5)
	# Entering cast members can delay the first beat. Wait for the actual end,
	# then record recovery as well, instead of truncating a longer arrival.
	var finish_deadline:=Time.get_ticks_msec()+30000
	while not bool(review_stage.exec_done) and Time.get_ticks_msec()<finish_deadline:
		await _wait(0.25)
	await _wait(3.0)
	print("MARK end")
	print("EXEC REVIEW saw_execution=",saw_execution," done=",review_stage.exec_done," things=",seen_things.keys())
	if not saw_execution:_fail("the order never started an execution")
	if not bool(review_stage.exec_done):_fail("the execution never finished")
	if only in ["club","behead"] and not seen_things.has("head:main"):_fail("the execution never reached its impact")
	if only in ["club","behead"] and not checked_marks.has("executioner"):_fail("the executioner's authored performance was not observed")
	if only=="club" and not checked_marks.has("cook"):_fail("the cook's authored performance was not observed")
	if only=="dogs" and (typed_dogs or without_resident_dog):
		var surviving_pack:=0
		for dog in dog_pack:
			if is_instance_valid(dog):surviving_pack+=1
		var clean:=review_stage.get_node_or_null("Execution")==null and not is_instance_valid(helper_ref)
		if without_resident_dog:clean=clean and surviving_pack==0 and review_stage.court_set.animals.size()==initial_animals
		if peak_pack!=3 or peak_contacts!=3:_fail("three-dog pack/contact was not observed")
		if contact_samples==0 or max_contact_gap>0.06:_fail("dog contact missing or farther than 6 cm")
		if not dog_aftermath:_fail("dog aftermath was not observed")
		if not clean:_fail("dog execution did not clean up")
		dog_audit={"order":order,"path":"speech_input/_speak" if typed_dogs else "office_order","reader":"offline","chapter":String(review_stage.court_set.kind),"without_resident_dog":without_resident_dog,"engine_executed":bool(result.get("executed",false)),"engine_removed":bool(result.get("removed",false)),"requested_method":only,"actual_method":String(review_stage.exec_method),"peak_pack":peak_pack,"peak_contacts":peak_contacts,"contact_samples":contact_samples,"max_contact_gap_m":max_contact_gap,"saw_aftermath":dog_aftermath,"cleanup":clean,"surviving_pack":surviving_pack,"done":bool(review_stage.exec_done)}
		print("DOG ORDER AUDIT ",JSON.stringify(dog_audit))
	if not frame_dir.is_empty():print("COURT_EXECUTION_REVIEW wrote ",frame_index," frames to ",frame_dir)
