extends "res://tests/audience_modal_probe.gd"
## Actual court navigation surfaces, with offline fixture state and no save.
func _ready()->void:
	capture=true;out_dir=ProjectSettings.globalize_path("res://artifacts/popup-audit/court-details/")
	DirAccess.make_dir_recursive_absolute(out_dir)
	_setup_world()
	var terrain:=TerrainDouble.new();add_child(terrain)
	var director:=Director.new();director.terrain=terrain;add_child(director);director.voice.force_offline=true
	for dimensions in [Vector2i(1600,900),Vector2i(1024,720)]:
		get_window().size=dimensions;get_window().content_scale_size=dimensions
		var modal:Control=director.open_court();await _frames(12)
		assert(get_viewport().get_visible_rect().encloses(modal.card.get_global_rect()))
		await _capture("resting-%d" % dimensions.x)
		var officials:Array=Hall._officials()
		if not officials.is_empty():
			modal.focus({"person_id":int(officials[0].person_id)});await _frames(12);modal.skip_reveal();await _frames(4)
			await _capture("official-%d" % dimensions.x)
			for button:Button in modal.find_children("*","Button",true,false):
				if button.is_visible_in_tree() and "What you know" in button.text:
					button.button_pressed=true;await _frames(4);await _capture("dossier-%d" % dimensions.x);break
			modal.show_history_at(-1);await _frames(4);await _capture("earlier-%d" % dimensions.x)
		modal._close();await _frames(4)
	print("MODERN_COURT_DETAILS PASS")
	get_tree().quit(0)
