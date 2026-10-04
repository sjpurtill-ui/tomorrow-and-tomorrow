extends "res://tests/audience_modal_probe.gd"
## Private-desktop diagnostic of the real room/actor renderer at all boundaries.

const Stage:=preload("res://scripts/hud/court_stage.gd")
const CourtSet:=preload("res://scripts/hud/court_set_3d.gd")
const Chapters:=preload("res://scripts/hud/court_chapters.gd")
const Presentation:=preload("res://scripts/hud/court_presentation.gd")
const Voice:=preload("res://scripts/character_voice.gd")
const Directing:=preload("res://scripts/hud/court_director.gd")
const ADDITIONS:=[[],["central_hall_houses","plain_weaving"],
	["lime_plastered_floors","temple_high_steward","pictographic_records"],
	["dressed_stone_masonry"],["columned_stone_temple"],
	["vaulted_masonry_roofs","parchment_record_preparation"],
	["clerestory_halls","bookbinding_assemblies","paper_making","glazed_windows"],
	["plank_walled_timber_halls","fitted_tailoring","royal_chancery_office"],
	["great_hall_of_justice"],["chancery_enrolment_rolls","belfry_town_halls"],
	["secretaries_of_state","privy_council_minutes","screw_press_printing"],
	["sash_windows","cabinet_first_minister"],
	["ministry_office_block","single_minister_departments","appointed_department_prefects"],
	["typewriter","radiator_central_heating"],
	["national_income_accounts","labor_ministry","telephone_circuits","electric_street_lighting","fluorescent_lighting","reinforced_concrete"],
	["desk_computers","flat_panel_displays","refrigerated_air_conditioning"]]

func _ready()->void:
	capture=DisplayServer.get_name()!="headless"
	out_dir=ProjectSettings.globalize_path("res://reports/court_chapters/")
	if capture:DirAccess.make_dir_recursive_absolute(out_dir)
	_setup_world()
	get_window().size=Vector2i(1536,864);get_window().content_scale_size=Vector2i(1536,864)
	Stage.acting=Stage.Acting.service();Stage.director=Directing.new()
	CourtSet.quality="low"
	var known:Array=[]
	for index in 16:
		known.append_array(ADDITIONS[index])
		GameState.elapsed_days=float(index*200)*365.0
		Voice.knowledge_override={"player":known.duplicate()}
		var chapter:=Chapters.for_owner()
		if int(chapter.design)!=index:_fail("wrong chapter "+str(chapter))
		var profile:=Presentation.for_owner()
		var stage:=Stage.new()
		stage.facts={"chapter":chapter,"presentation":profile,"presentations":{"player":profile},"layout":"home"}
		var set_facts:=CourtSet.facts_from_game()
		set_facts.merge({"rustic_props":profile.rustic_props,"dogs":false,"herds":false,"fowl":false,"season":"winter" if index%2==0 else "summer"},true)
		stage.use_set(String(profile.stage_id),set_facts)
		add_child(stage);stage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		if String(stage.court_set.kind)!=String(chapter.set_kind):_fail("missing room "+str(chapter.set_kind))
		for i in 7:
			var key:="main" if i==0 else "official%d" % i
			var person:={"name":["Hena","Tamsa","Keren","Orun","Nera","Bram","Lea"][i],"person_id":100+i,"sex":"female" if i%2==0 else "male","age":[34,36,20,22,65,68,44][i],"office_title":"Councillor"}
			stage.add_figure(key,person,"main" if i==0 else "court",person.name,person.office_title)
		await _frames(4)
		stage.settle();stage.frame_cast(0.0)
		await _frames(20)
		if not stage.court_set.has_hearth():
			if stage.court_set.fire_light!=null or stage.court_set.shimmer!=null:_fail("phantom hearth in "+str(chapter.set_kind))
		if stage.court_set.indoors() and (stage.court_set.snowfall!=null or not stage.court_set.breaths.is_empty()):_fail("indoor winter particles in "+str(chapter.set_kind))
		await _capture_stage(stage,"%02d-year-%04d-audience" % [index,index*200])
		# A room overview for evaluating architecture alongside the actual framing.
		stage.camera.position=Vector3(8.5,7.4,13.5)
		stage.camera.look_at(Vector3(0,1,-1),Vector3.UP)
		stage.camera.fov=54
		await _frames(3)
		await _capture_stage(stage,"%02d-year-%04d-room" % [index,index*200])
		if index in [7,9,12,15]:
			stage.frame_cast(0.0);stage.arrive(["main"])
			await get_tree().create_timer(0.8).timeout
			await _capture_stage(stage,"%02d-arrival" % index)
		stage.settle();stage.queue_free();await _frames(3)
	Voice.knowledge_override.clear();CourtSet.quality="auto"
	print("COURT_CHAPTER_CAPTURE PASS 16" if failures.is_empty() else "COURT_CHAPTER_CAPTURE FAIL: "+str(failures))
	get_tree().quit(0 if failures.is_empty() else 1)

func _capture_stage(stage:Control,label:String)->void:
	if not capture:return
	await RenderingServer.frame_post_draw
	stage.view3d.get_texture().get_image().save_png(out_dir+label+".png")
