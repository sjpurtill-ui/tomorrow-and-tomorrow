extends "res://tests/audience_modal_probe.gd"
## Isolated visual diagnostic, never the player game. Uses real stage/figure code.
## Run only through tools/run_isolated_gpu_probe.ps1, with Dummy audio.

const Stage:=preload("res://scripts/hud/court_stage.gd")
const Presentation:=preload("res://scripts/hud/court_presentation.gd")
const Directing:=preload("res://scripts/hud/court_director.gd")
const Voice:=preload("res://scripts/character_voice.gd")
const Stages:=preload("res://scripts/civic_stages.gd")
const PERIODS:=[
	["early",[]],
	["ancient",["temple_high_steward","pictographic_records"]],
	["medieval",["fitted_tailoring","royal_chancery_office","printing_process","paper_making","petition_registers"]],
	["early_modern",["secretaries_of_state","privy_council_minutes"]],
	["industrial",["single_minister_departments","appointed_department_prefects"]],
	["modern",["national_income_accounts","labor_ministry"]],
]

func _ready()->void:
	capture=DisplayServer.get_name()!="headless"
	out_dir=ProjectSettings.globalize_path("res://reports/court_eras/")
	if capture:DirAccess.make_dir_recursive_absolute(out_dir)
	_setup_world()
	get_window().size=Vector2i(1536,864);get_window().content_scale_size=Vector2i(1536,864)
	Stage.acting=Stage.Acting.service();Stage.director=Directing.new()
	for row in PERIODS:
		Voice.knowledge_override={"player":row[1]}
		var profile:=Presentation.for_owner()
		if String(profile.period)!=String(row[0]):_fail("wrong period "+str(row));continue
		var stage:=Stage.new()
		stage.facts={"presentation":profile,"presentations":{"player":profile},"era":3,"layout":"home"}
		stage.use_set(String(profile.stage_id),{"tier":3 if profile.period!="early" else 0,"rustic_props":profile.rustic_props,"dogs":profile.court_animals,"herds":false,"fowl":false})
		add_child(stage);stage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		for i in 6:
			var key:="main" if i==0 else "official%d" % i
			var person:={"name":["Hena","Tamsa","Keren","Orun","Nera","Bram"][i],"person_id":100+i,"sex":"female" if i%2==0 else "male","age":[34,36,20,22,65,68][i],"office_title":"Councillor"}
			stage.add_figure(key,person,"main" if i==0 else "court",person.name,person.office_title)
		await _frames(4)
		stage.settle();stage.frame_cast(0.0)
		await _frames(12)
		for key in stage.cast_order:
			var body:Node3D=stage.figure(key).body3d
			if body==null or String(body.look.get("outfit",""))!=String(profile.outfit):_fail("wardrobe missing: "+str(row[0])+"/"+key)
		await _capture_stage(stage,String(row[0])+"-standing")
		stage.arrive(["main"])
		await get_tree().create_timer(1.4).timeout
		await _capture_stage(stage,String(row[0])+"-walking")
		await get_tree().create_timer(6.0).timeout
		if not stage._pending_greetings.is_empty():_fail("arrival greeting not consumed: "+str(row[0]))
		stage.conclude(0.0,"bow","pleased")
		await get_tree().create_timer(0.5).timeout
		await _capture_stage(stage,String(row[0])+"-departure")
		stage.settle();stage.queue_free();await _frames(4)
	Voice.knowledge_override.clear();Stages.stage_override=""
	print("COURT_ERA_CAPTURE PASS" if failures.is_empty() else "COURT_ERA_CAPTURE FAIL: "+str(failures))
	get_tree().quit(0 if failures.is_empty() else 1)

func _capture_stage(stage:Control,label:String)->void:
	if not capture:return
	await RenderingServer.frame_post_draw
	stage.view3d.get_texture().get_image().save_png(out_dir+label+".png")
