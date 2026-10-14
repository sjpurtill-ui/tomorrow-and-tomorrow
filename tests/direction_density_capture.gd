extends "res://tests/great_works_experience_probe.gd"
## Exercises every course and a long memory through the production UI.
func _ready()->void:
	if not OS.get_user_data_dir().ends_with("Tests"):
		push_error("Requires isolated test userdata");get_tree().quit(2);return
	_setup_world();PeopleDirection.reset_for_new_world()
	var keys:=PeopleDirection.AMBITIONS.keys()
	for index in 14:
		GameState.elapsed_days=index*PeopleDirection.CENTURY_DAYS
		PeopleDirection.choose(String(keys[index%keys.size()]))
	GameState.elapsed_days=14*PeopleDirection.CENTURY_DAYS
	var out:=ProjectSettings.globalize_path("res://artifacts/popup-audit/direction-density")
	DirAccess.make_dir_recursive_absolute(out)
	for mode in ["dark","light"]:
		HudTokens.set_color_mode(mode)
		for dimensions in [Vector2i(1600,900),Vector2i(1024,720)]:
			get_window().size=dimensions;get_window().content_scale_size=dimensions
			var screen:Control=load("res://scripts/people_direction_screen.gd").new();add_child(screen);await _frames(10)
			var visible:Array=screen.ambition_buttons.filter(func(button:Button)->bool:return button.visible)
			if visible.size()!=4:_fail("Expected four course choices with visible payoffs")
			for button:Button in visible:
				if not get_viewport().get_visible_rect().encloses(button.get_global_rect()):_fail("Course outside viewport")
			await _shot(out+"/courses-%s-%d.png" % [mode,dimensions.x])
			(screen.find_child("NextCourses",true,false) as Button).pressed.emit()
			(screen.find_child("NextCourses",true,false) as Button).pressed.emit()
			(screen.find_child("NextCourses",true,false) as Button).pressed.emit()
			var last:Button=screen.ambition_buttons[-1];last.pressed.emit();await _frames(5)
			if screen.selected_focus!=String(last.get_meta("ambition")):_fail("Last course unreachable")
			var confirm:Button=screen.pages[0].get_node("ConfirmFocus")
			if confirm.disabled or not get_viewport().get_visible_rect().encloses(confirm.get_global_rect()):_fail("Course confirmation inaccessible")
			await _shot(out+"/selected-%s-%d.png" % [mode,dimensions.x])
			screen._show_page(1);await _frames(8)
			if screen.find_child("ChoiceHistory",true,false).get_child_count()!=3:_fail("Recent memory must show three choices")
			await _shot(out+"/character-%s-%d.png" % [mode,dimensions.x])
			(screen.find_child("BrowseChoices",true,false) as Button).pressed.emit();await _frames(8)
			if screen.find_child("ChoiceHistory",true,false).get_child_count()!=6:_fail("Memory archive must show six choices")
			screen.queue_free();await _frames(4)
	var final_screen:Control=load("res://scripts/people_direction_screen.gd").new();add_child(final_screen);await _frames(5)
	final_screen.ambition_buttons[1].pressed.emit()
	var chosen:=String(final_screen.selected_focus)
	(final_screen.pages[0].get_node("ConfirmFocus") as Button).pressed.emit();await _frames(4)
	if PeopleDirection.ambition!=chosen:_fail("Confirm did not apply the selected course")
	print("DIRECTION_DENSITY ",failures)
	get_tree().quit(0 if failures.is_empty() else 1)

func _shot(path:String)->void:
	if DisplayServer.get_name()=="headless":return
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(path)
