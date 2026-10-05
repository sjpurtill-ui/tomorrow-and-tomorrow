extends GdUnitTestSuite
const Stage=preload("res://scripts/hud/great_work_ceremony_stage.gd")
const Presentation=preload("res://scripts/hud/court_presentation.gd")
const Ceremony=preload("res://scripts/hud/great_work_ceremony.gd")
const Bridge=preload("res://scripts/great_works_audience.gd")
const AudienceVoice=preload("res://scripts/audience_voice.gd")
const Concept=preload("res://scripts/wonder_concept.gd")

class DedicationFacade extends RefCounted:
	var allowed:=false
	var calls:=0
	func site(_city:String,_work:String)->Dictionary:
		return {"id":"ancestor_ring","status":"functioning","fraction":1.0,"condition":1.0,"ceremony":{"allure":0.0}}
	func allure_contribution(_owner:String)->Dictionary:return {"value":0.0}
	func renown(_owner:String)->Dictionary:return {"share":0.0,"points":0.0}
	func dedicate(_city:String,_work:String,title:String)->Dictionary:
		calls+=1
		return {"ok":true,"message":title+" was dedicated.","gifts":[]} if allowed else {"error":"No dedication is waiting for this work."}

func test_ritual_uses_actual_capabilities_across_the_whole_history()->void:
	for year in [0,500,1000,1500,2000,2500,3000]:
		var early:=Stage.ritual_spec([],Presentation.from_knowledge([]))
		assert_str(early.mode).is_equal("offering")
	var medieval:=Stage.ritual_spec(["fitted_tailoring"],{"period":"medieval","outfit":"medieval"})
	assert_str(medieval.mode).is_equal("unveiling")
	var industrial:=Stage.ritual_spec(["rotative_steam_engine"],{"period":"industrial","outfit":"formal"})
	assert_str(industrial.mode).is_equal("ribbon")
	var modern:=Stage.ritual_spec(["electrical_generators"],{"period":"modern","outfit":"business"})
	assert_str(modern.mode).is_equal("ribbon")
	for practice in ["solid_state_lighting","electric_street_lighting","filament_lamp_works"]:
		assert_str(Stage.ritual_spec([practice],{"period":"modern","outfit":"business"}).mode).is_equal("illumination")
	assert_str(Stage.ritual_spec(["solid_state_lighting"],Presentation.from_knowledge([])).mode).is_equal("offering")

func test_cast_is_bounded_and_drawn_only_from_supplied_people()->void:
	var context:={"key":"testwork","architect":{},"official":{},"attendees":[]}
	assert_array(Stage.cast_for(context)).is_empty()
	context.official={"person_id":22,"name":"Recorded steward"}
	context.architect={"name":"Recorded builder","id":"unlisted_saved_builder"}
	for index in 12:context.attendees.append({"civ_id":"ceremony_test_%d" % index,"name":"Recorded people %d" % index})
	var before:=context.duplicate(true)
	var cast:=Stage.cast_for(context)
	assert_int(cast.size()).is_equal(6)
	assert_str(cast[0].person.name).is_equal("Recorded builder")
	assert_int(cast[1].person.person_id).is_equal(22)
	assert_str(cast[2].civ_id).is_equal("ceremony_test_0")
	assert_dict(context).is_equal(before)
	assert_array(Stage.cast_for(context)).contains_exactly(cast)

func test_scene_is_retained_and_idle_or_hidden_viewport_stops()->void:
	var record:={"id":"ancestor_ring","status":"functioning","fraction":1.0,"condition":1.0,"outcome":"success"}
	var before:=record.duplicate(true)
	var scene:Control=auto_free(Stage.make(record,{"key":"testwork","architect":{},"official":{},"attendees":[]}))
	scene.size=Vector2(720,340);add_child(scene)
	for frame in 2:await get_tree().process_frame
	var diagnostics:Dictionary=scene.diagnostics()
	assert_int(diagnostics.build_count).is_equal(1)
	scene.settle()
	assert_bool(scene.diagnostics().viewport_active).is_false()
	scene.dedication()
	assert_bool(scene.diagnostics().committed).is_true()
	scene.dedication();scene.settle()
	assert_int(scene.diagnostics().model_node_id).is_equal(diagnostics.model_node_id)
	assert_int(scene.diagnostics().build_count).is_equal(1)
	scene.hide()
	assert_int(scene.view.render_target_update_mode).is_equal(SubViewport.UPDATE_DISABLED)
	assert_dict(record).is_equal(before)

func test_recorded_official_uses_the_shared_court_body_and_speaking_path()->void:
	var person:={"name":"Tovan","person_id":123,"sex":"male","age":40}
	var scene:Control=auto_free(Stage.make({"id":"ancestor_ring","status":"functioning","fraction":1.0},{"key":"testwork","architect":{},"official":person,"attendees":[]}))
	scene.size=Vector2(720,340);add_child(scene)
	for frame in 2:await get_tree().process_frame
	assert_int(scene.diagnostics().body_count).is_equal(1)
	assert_int(scene.diagnostics().mesh_count).is_greater(0)
	scene.speak({"role":"official","speaker":"Tovan","text":"The work stands."},false)
	assert_str(scene.diagnostics().camera_shot).is_equal("speaker")
	scene.settle();scene.show_work()
	assert_str(scene.diagnostics().camera_shot).is_equal("work")
	scene.settle()
	assert_bool(scene.diagnostics().viewport_active).is_false()

func test_named_envoy_speech_focuses_its_recorded_body_after_settling()->void:
	var tower:=Concept.make_id("tower","bind_tribes","modest","concrete",5,"focus_test")
	for work:String in ["ancestor_ring",tower]:
		for guests in [2,4]:
			var context:={"key":work,"title":"The Recorded Work","city_name":"Ashford","outcome":"success","architect":{"id":"focus_builder","name":"Recorded builder","age":40,"sex":"male"},"official":{"person_id":23,"name":"Recorded keeper","age":40,"sex":"male"},"attendees":[]}
			for index in guests:context.attendees.append({"civ_id":"focus_guest_%d" % index,"name":"Recorded people %d" % index})
			var voice:Node=auto_free(AudienceVoice.new())
			var lines:Array=voice.ceremony_named_offline(context,"The Witness Work")
			assert_int(lines.size()).is_equal(2)
			var envoy:Dictionary=lines.back()
			assert_str(envoy.role).is_equal("envoy")
			assert_str(envoy.civ_id).is_equal("focus_guest_0")
			var scene:Control=Stage.make({"id":work,"status":"functioning","fraction":1.0},context)
			scene.size=Vector2(760,360);add_child(scene)
			await get_tree().process_frame
			assert_int(scene.diagnostics().body_count).is_equal(guests+2)
			scene.settle();scene.dedication()
			for animate in [false,true]:
				for line:Dictionary in lines:scene.speak(line,animate)
				scene.settle()
				var body:Node3D=scene.bodies.envoy_0
				assert_str(body.get_meta("ceremony_person").name).is_equal(envoy.speaker)
				var expected:=body.position+Vector3(4.4,2.8,7.8)
				var face:Vector2=scene.lens.unproject_position(body.position+Vector3(0,1.5,0))
				print("NAMED_ENVOY_FOCUS work=",work," cast=",guests+2," animated=",animate," camera_error=",scene.lens.position.distance_to(expected)," face=",face)
				assert_float(scene.lens.position.distance_to(expected)).is_less(.001)
				assert_float(absf(face.x-float(scene.view.size.x)*.5)).is_less(20.0)
				assert_bool(scene.diagnostics().viewport_active).is_false()
			scene.queue_free();await get_tree().process_frame

func test_dead_architect_is_credited_in_record_but_not_cast()->void:
	var saved:=HistoricalFigures.people.duplicate(true)
	HistoricalFigures.people.append({"id":"ceremony_dead_architect","name":"Recorded builder","status":"dead","death_day":8})
	var context:={"key":"work","architect":{"id":"ceremony_dead_architect","name":"Recorded builder"},"official":{},"attendees":[]}
	assert_array(Stage.cast_for(context)).is_empty()
	assert_str(context.architect.name).is_equal("Recorded builder")
	HistoricalFigures.people.assign(saved)

func test_compact_modal_keeps_name_and_close_inside_the_view()->void:
	var viewport:SubViewport=auto_free(SubViewport.new());viewport.size=Vector2i(1138,640);add_child(viewport)
	var modal:Control=auto_free(Ceremony.new())
	modal.ceremony={"work_id":"missing_fixture_record","city_id":"none","city_name":"Ashford","title":"The Work of the Recorded People","attendees":[],"name_suggestions":["The Work of the Recorded People"]}
	viewport.add_child(modal)
	# Exercise the live opening path: no external/manual fit after wrapping.
	for frame in 20:await get_tree().process_frame
	var bounds:=Rect2(Vector2.ZERO,Vector2(1138,640))
	print("CEREMONY_FIT stage=",modal.stage.get_global_rect()," min=",modal.stage.get_combined_minimum_size()," close=",(modal.find_child("CloseCeremonyTop",true,false) as Control).get_global_rect()," name=",modal.dedicate_button.get_global_rect()," plate=",modal.plate.get_global_rect())
	assert_bool(bounds.encloses(modal.stage.get_global_rect())).is_true()
	assert_bool(bounds.encloses(modal.dedicate_button.get_global_rect())).is_true()
	assert_bool(bounds.encloses((modal.find_child("CloseCeremonyTop",true,false) as Control).get_global_rect())).is_true()
	assert_float(modal.plate.size.x).is_greater(600.0)
	modal.skip_reveal()
	assert_bool(modal.plate.diagnostics().committed).is_false()

func test_narrow_stage_wraps_long_captions_within_its_frame()->void:
	var viewport:SubViewport=auto_free(SubViewport.new());viewport.size=Vector2i(360,360);add_child(viewport)
	var scene:Control=Stage.make({"id":"ancestor_ring","status":"functioning","fraction":1.0},{"key":"caption","architect":{},"official":{},"attendees":[]},300)
	scene.size=Vector2(340,320);scene.position=Vector2(10,10);viewport.add_child(scene)
	for frame in 20:await get_tree().process_frame
	var frame:Control=scene.get_node("CeremonyCaption")
	for line in ["The dedication beacon is kindled before the lighthouse. The open-way mark recalls the work's purpose of welcoming strangers.","The miniature sluice lifts to mark the dedication. The wave-mark recalls the work's purpose of taming water.","The beam comes level beside the common measuring rod. The tool-mark recalls the work's purpose of showing mastery."]:
		scene.speak({"text":line},false)
		for settled in 4:await get_tree().process_frame
		assert_bool(scene.get_global_rect().encloses(frame.get_global_rect())).is_true()
		assert_bool(frame.get_global_rect().encloses(scene._caption.get_global_rect())).is_true()
		assert_int(scene._caption.get_line_count()).is_greater(1)
	scene.queue_free();await get_tree().process_frame

func test_rite_description_changes_only_when_dedication_succeeds()->void:
	var saved_facade:Object=Bridge.facade_override
	var facade:=DedicationFacade.new();Bridge.facade_override=facade
	var viewport:SubViewport=auto_free(SubViewport.new());viewport.size=Vector2i(1138,640);add_child(viewport)
	var modal:Control=Ceremony.new()
	modal.ceremony={"work_id":"ancestor_ring","city_id":"caption_fixture","title":"The Recorded Ring","attendees":[],"name_suggestions":["The Recorded Ring"]}
	viewport.add_child(modal)
	await get_tree().process_frame
	modal.skip_reveal()
	var description:Label=modal.find_child("RitualDescription",true,false)
	var waiting:String=modal.ritual_profile.before+" "+modal.ritual_profile.purpose_caption
	var completed:String=modal.ritual_profile.after+" "+modal.ritual_profile.purpose_caption
	assert_str(description.text).is_equal(waiting)
	assert_bool(modal.dedicate_with("A Name").has("error")).is_true()
	assert_str(description.text).is_equal(waiting)
	assert_bool(modal.voice_ctx.ritual.dedicated).is_false()
	assert_bool(modal.plate.diagnostics().committed).is_false()
	assert_bool(modal.naming_box.visible).is_true()
	facade.allowed=true
	assert_bool(modal.dedicate_with("The Witness Ring").has("ok")).is_true()
	assert_str(description.text).is_equal(completed)
	assert_bool(modal.voice_ctx.ritual.dedicated).is_true()
	assert_bool(modal.plate.diagnostics().committed).is_true()
	assert_str(modal.title_label.text).is_equal("The Witness Ring")
	assert_bool(modal.result_box.visible).is_true()
	assert_bool(modal.naming_box.visible).is_false()
	modal.dedicate_with("Another Name")
	assert_int(facade.calls).is_equal(2)
	assert_str(description.text).is_equal(completed)
	assert_str(modal.title_label.text).is_equal("The Witness Ring")
	modal.close();await get_tree().process_frame
	Bridge.facade_override=saved_facade
