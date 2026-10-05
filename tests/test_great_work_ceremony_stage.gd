extends GdUnitTestSuite
const Stage=preload("res://scripts/hud/great_work_ceremony_stage.gd")
const Presentation=preload("res://scripts/hud/court_presentation.gd")
const Ceremony=preload("res://scripts/hud/great_work_ceremony.gd")

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
	var record:={"id":"stone_ring","form":"ring","status":"complete","progress":1.0,"condition":1.0,"outcome":"success"}
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
	var scene:Control=auto_free(Stage.make({"id":"stone_ring","work_id":"stone_ring","status":"functioning","progress":1.0},{"key":"testwork","architect":{},"official":person,"attendees":[]}))
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
