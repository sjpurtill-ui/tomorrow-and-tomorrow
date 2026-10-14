extends "res://tests/great_works_experience_probe.gd"
## Prepared large catalogue, production Atlas, isolated captures only.
func _ready()->void:
	if not OS.get_user_data_dir().ends_with("Tests"):
		push_error("Requires isolated test userdata");get_tree().quit(2);return
	_setup_world();city.undertakings=[]
	for index in 14:
		_add_work("ring" if index%2==0 else "tower","honor_dead","modest","density%d" % index,.32,"River Work %02d" % index)
	terrain=TerrainDouble.new();add_child(terrain)
	director=Director.new();director.terrain=terrain;add_child(director);director.voice.force_offline=true
	var out:=ProjectSettings.globalize_path("res://artifacts/popup-audit/great-works-density")
	DirAccess.make_dir_recursive_absolute(out)
	for mode in ["dark","light"]:
		HudTokens.set_color_mode(mode)
		for dimensions in [Vector2i(1600,900),Vector2i(1024,720)]:
			get_window().size=dimensions;get_window().content_scale_size=dimensions
			var atlas:Control=Atlas.open(self,terrain,director)
			await _frames(15)
			if not get_viewport().get_visible_rect().encloses(atlas.panel.get_global_rect()):_fail("Atlas outside viewport")
			if atlas.list_box.get_child_count()!=6:_fail("Expected six works")
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(out+"/works-%s-%d.png" % [mode,dimensions.x])
			var model:Control=atlas.model_view
			var search:=atlas.find_child("FindWork",true,false) as LineEdit
			search.text="Work 13";search.text_changed.emit(search.text)
			if atlas.list_box.get_child_count()!=1 or atlas.model_view!=model:_fail("Search lost retained model or the final work")
			var press:=InputEventAction.new();press.action="ui_accept";press.pressed=true;atlas.list_box.get_child(0).gui_input.emit(press)
			await _frames(10)
			if not String(atlas.selected_key).contains("density13"):_fail("Work selection failed")
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(out+"/selected-%s-%d.png" % [mode,dimensions.x])
			atlas.close();await _frames(4)
	print("GREAT_WORKS_DENSITY ",failures)
	get_tree().quit(0 if failures.is_empty() else 1)
