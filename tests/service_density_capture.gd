extends "res://tests/great_works_experience_probe.gd"
## Late-service UI only: many forces and reports, all existing actions retained.
const Roster=preload("res://scripts/hud/military_roster_screen.gd")
func _ready()->void:
	if not OS.get_user_data_dir().ends_with("Tests"):
		push_error("Requires isolated test userdata");get_tree().quit(2);return
	var fixture:=preload("res://tests/audience_hall_probe.gd").new()
	fixture._base();fixture._people(5000);fixture._refill();fixture._next_door()
	for singleton in [GameState,MilitaryCampaign,CivilizationSystem]:singleton.set_process(false)
	for material in ["Food","Timber","Stone","Iron Ore"]:GameState.resource_stockpiles[material]=100000.0
	var service_fixture:=preload("res://tests/military_visual_roster_probe.gd").new()
	service_fixture.add_service_force("navy");service_fixture.add_service_force("air")
	var operations=MilitaryCampaign.joint_operations
	for domain in ["navy","air"]:
		var seed_force:Dictionary=operations.state.forces.filter(func(force:Dictionary)->bool:return String(force.domain)==domain)[0]
		for index in 18:
			var force:=seed_force.duplicate(true);force.id=100+index+(100 if domain=="air" else 0);force.name=("Coastal guard " if domain=="navy" else "Northern watch ")+str(index+1);force.condition=.5+index*.02;operations.state.forces.append(force)
		for index in 37:operations.state.events.append({"day":700-index,"domain":domain,"text":"%s report %d: crews returned from patrol. The named force requires repairs before its next mission." % [domain,index+1]})
	var output:=ProjectSettings.globalize_path("res://artifacts/popup-audit/service-density")
	DirAccess.make_dir_recursive_absolute(output)
	for mode in ["dark","light"]:
		HudTokens.set_color_mode(mode)
		for dimensions in [Vector2i(1600,900),Vector2i(1024,720)]:
			get_window().size=dimensions;get_window().content_scale_size=dimensions
			for domain in ["navy","air"]:
				var screen:=Roster.new();screen.service=domain;add_child(screen);screen.panel.theme=HudTokens.control_theme();await _frames(10)
				if screen.service_choices.size()!=4 or screen.bindings.size()!=1:_fail("Force overview must show four choices and one profile")
				for choice:Button in screen.service_choices.values():
					if not get_viewport().get_visible_rect().encloses(choice.get_global_rect()):_fail("Force choice outside viewport")
				if not get_viewport().get_visible_rect().encloses(screen.bindings[0].action.get_global_rect()):_fail("Selected force action outside viewport")
				await _shot(output+"/%s-forces-%s-%d.png" % [domain,mode,dimensions.x])
				(screen.find_child("NextServiceForces",true,false) as Button).pressed.emit();await _frames(5)
				if screen.service_page!=1:_fail("Force page did not advance")
				var search:LineEdit=screen.find_child("FindServiceForce",true,false);search.text="guard 18" if domain=="navy" else "watch 18";search.text_submitted.emit(search.text);await _frames(5)
				if screen.service_choices.size()!=1 or screen.bindings.size()!=1:_fail("Cannot find the last force")
				var last_id:=String(screen.bindings[0].row.id)
				operations.force(int(last_id.get_slice(":",1))).condition=.91
				screen._process(1.0)
				if screen.bindings.size()!=1:_fail("Live refresh lost selected profile")
				elif not is_equal_approx(float(screen.bindings[0].row.condition),.91):_fail("Live refresh updated a different force")
				screen.service_query="";screen._show_page("support");await _frames(6)
				if screen.page!="forces" or screen.service_choices.size()!=4 or screen.bindings.size()!=1:_fail("Readiness should open the selected force")
				elif not String(screen.bindings[0].readiness.text).contains("condition"):_fail("Readiness missing from selected force")
				await _shot(output+"/%s-readiness-%s-%d.png" % [domain,mode,dimensions.x])
				screen._show_page("training");await _frames(6)
				await _shot(output+"/%s-training-%s-%d.png" % [domain,mode,dimensions.x])
				screen.queue_free();await _frames(3)
				var command=load("res://scripts/hud/%s_command_panel.gd" % ("naval" if domain=="navy" else "air")).new();add_child(command);await _frames(8)
				command.pages.current_tab=3;await _frames(4)
				if command.report_rows.get_child_count()!=3:_fail("Service digest must show three reports")
				await _shot(output+"/%s-reports-%s-%d.png" % [domain,mode,dimensions.x])
				command.report_browse.pressed.emit();await _frames(3)
				if command.report_rows.get_child_count()!=6:_fail("Report archive must show six choices")
				command.report_search.text=domain+" report 37";command.report_search.text_changed.emit(command.report_search.text);await _frames(4)
				if not command.reports.text.contains("report 37"):_fail("Old service report is unreachable")
				await _shot(output+"/%s-archive-%s-%d.png" % [domain,mode,dimensions.x])
				command.queue_free();await _frames(3)
	fixture.free();service_fixture.free();WorldSimulation.clear()
	print("SERVICE_DENSITY ",failures)
	get_tree().quit(0 if failures.is_empty() else 1)

func _shot(path:String)->void:
	if DisplayServer.get_name()=="headless":return
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(path)
