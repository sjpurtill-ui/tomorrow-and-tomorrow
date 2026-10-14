extends "res://tests/own_town_capture.gd"
const Figures:=preload("res://scripts/historical_figures_screen.gd")
const Notices:=preload("res://scripts/hud/notification_stack.gd")
const NoticeModel:=preload("res://scripts/hud/notification_model.gd")
var failures:Array[String]=[]
func check(ok:bool,why:String)->void:
	if not ok:failures.append(why);push_error(why)
func _ready()->void:
	if not OS.get_user_data_dir().ends_with("Tests"):get_tree().quit(2);return
	var stage:=CanvasLayer.new();add_child(stage)
	_world("early");HistoricalFigures.reset_for_new_world();HistoricalFigures.ensure()
	var person:Dictionary=HistoricalFigures.people[0]
	person.events=[]
	for index in 55:person.events.append({"day":index*30,"text":"Recorded work %d: taught the riverbank makers to strengthen their tools. The household workshops now preserve that method, and the whole account is kept with this person's deeds." % index})
	for mode in ["dark","light"]:
		T.set_color_mode(mode)
		for dimensions in [Vector2i(1600,900),Vector2i(1024,720)]:
			get_window().size=dimensions;get_window().content_scale_size=dimensions;await _frames(3)
			var figures:=Figures.new();stage.add_child(figures);await _frames(5)
			check(figures.deeds_choices.get_child_count()==3,"Three recent deeds")
			check(Rect2(Vector2.ZERO,Vector2(dimensions)).encloses(figures.patron.get_global_rect()),"Support action remains visible")
			await _shot("figures-%s-%d" % [mode,dimensions.x])
			figures.deeds_toggle.pressed.emit();await _frames(3)
			check(figures.deeds_choices.get_child_count()==6,"Six archived deeds")
			await _shot("figures-archive-%s-%d" % [mode,dimensions.x])
			figures.deeds_search.text="Recorded work 0:";figures.deeds_search.text_changed.emit(figures.deeds_search.text);await _frames(3)
			check(figures.deeds_choices.get_child_count()==1,"Oldest matching deed remains searchable")
			await _shot("figures-search-%s-%d" % [mode,dimensions.x])
			figures.queue_free();await _frames(3)
			var background:=ColorRect.new();background.color=T.PAPER;background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);stage.add_child(background)
			var hud:=CaptureHud.new();hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);stage.add_child(hud)
			NoticeModel.reset()
			for index in 65:NoticeModel.remember(NoticeModel.normalize({"group":"fixture:%d" % index,"category":"building","title":"The riverbank workshop %d is complete" % index,"text":"The makers have brought tools and twelve baskets of timber.","day":index*20,"action":{"kind":"section","section":"construction","sub":0}}))
			var notices:=Notices.ensure(self,hud);notices._intake();notices.toggle_log();await _frames(5)
			check(notices.log_list.get_child_count()==3,"Three recent notices")
			await _shot("notices-%s-%d" % [mode,dimensions.x])
			notices.log_browse.pressed.emit();await _frames(4)
			check(notices.log_list.get_child_count()==6,"Six archived notices")
			print("NOTICE_RECT ",mode," ",dimensions," ",notices.log_panel.get_global_rect())
			check(Rect2(Vector2.ZERO,Vector2(dimensions)).encloses(notices.log_panel.get_global_rect()),"Notice log fits viewport")
			await _shot("notice-archive-%s-%d" % [mode,dimensions.x])
			notices.log_search.text="workshop 0 ";notices.log_search.text_changed.emit(notices.log_search.text);await _frames(3)
			await _shot("notice-search-%s-%d" % [mode,dimensions.x])
			hud.queue_free();background.queue_free();await _frames(3)
	print("FIGURE_NOTICE_DENSITY ","PASS" if failures.is_empty() else "FAIL "+str(failures));get_tree().quit(0 if failures.is_empty() else 1)
func _frames(n:int)->void:
	for i in n:await get_tree().process_frame
func _shot(name:String)->void:
	if DisplayServer.get_name()=="headless":return
	await RenderingServer.frame_post_draw
	var dir:=ProjectSettings.globalize_path("res://artifacts/popup-modern-c/figure-notice-density")
	DirAccess.make_dir_recursive_absolute(dir)
	get_viewport().get_texture().get_image().save_png(dir.path_join(name+".png"));print("SHOT ",name)
