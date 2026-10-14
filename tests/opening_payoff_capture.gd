extends "res://tests/great_works_experience_probe.gd"
## Exercise the real opening, including every alternative and the final commitment.
func _ready()->void:
	if not OS.get_user_data_dir().ends_with("Tests"):
		push_error("Requires isolated test userdata");get_tree().quit(2);return
	_setup_world()
	var output:=ProjectSettings.globalize_path("res://artifacts/popup-audit/opening-payoff")
	DirAccess.make_dir_recursive_absolute(output)
	for mode in ["dark","light"]:
		HudTokens.set_color_mode(mode)
		for dimensions in [Vector2i(1600,900),Vector2i(1024,720)]:
			PeopleDirection.reset_for_new_world();GameState.elapsed_days=0;GameState.founding_focus=""
			get_window().size=dimensions;get_window().content_scale_size=dimensions
			var screen:Control=load("res://scripts/hud/fire_circle_opening.gd").new();add_child(screen);await _frames(12)
			var seen:Array=[]
			for button:Button in screen.ambition_buttons:
				if button.visible:seen.append(String(button.get_meta("ambition")))
				for fact in ["CoursePurpose","CourseGains","CourseCosts","CourseResearch"]:
					if (button.find_child(fact,true,false) as Label).text.is_empty():_fail("Opening omits "+fact)
			if seen.size()!=4:_fail("Opening shows more than four choices")
			await _shot(output+"/opening-%s-%d.png" % [mode,dimensions.x])
			screen.ambition_buttons[0].pressed.emit();await _frames(8)
			if screen.confirm.disabled or not get_viewport().get_visible_rect().encloses(screen.confirm.get_global_rect()):_fail("Opening confirmation inaccessible")
			await _shot(output+"/selected-%s-%d.png" % [mode,dimensions.x])
			screen.more_button.pressed.emit();await _frames(6)
			await _shot(output+"/alternatives-%s-%d.png" % [mode,dimensions.x])
			while true:
				var shown:=0
				for button:Button in screen.ambition_buttons:
					if button.visible:seen.append(String(button.get_meta("ambition")));shown+=1
				if shown>4:_fail("Alternative choices exceed four")
				if screen.more_next.disabled:break
				screen.more_next.pressed.emit();await _frames(3)
			if seen.size()!=PeopleDirection.AMBITIONS.size():_fail("Opening loses courses")
			screen.ambition_buttons[-1].pressed.emit()
			var chosen:=String(screen.selected_focus)
			screen.confirm.pressed.emit();await _frames(4)
			if PeopleDirection.ambition!=chosen:_fail("Opening chose a different course")
	print("OPENING_PAYOFF ",failures)
	get_tree().quit(0 if failures.is_empty() else 1)

func _shot(path:String)->void:
	if DisplayServer.get_name()=="headless":return
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(path)
