extends "res://tests/modern_war_capture.gd"
var failures:Array[String]=[]
func check(ok:bool,why:String)->void:
	if not ok:failures.append(why);push_error(why)
func run()->void:
	if not OS.get_user_data_dir().ends_with("Tests"):get_tree().quit(2);return
	output="res://artifacts/popup-modern-c/war-choices-density"
	var fixture:=HallProbe.new();fixture._base()
	GameState.opponent_count=13;CivilizationSystem.reset_for_new_world()
	fixture._people(1400);fixture._refill();fixture._next_door()
	GovernmentPeopleSystem.reset_for_new_world();GovernmentPeopleSystem.initialize()
	GameState.elapsed_days=130
	for index in CivilizationSystem.civilizations.size():
		var civ:Dictionary=CivilizationSystem.civilizations[index]
		civ.player_relation.contact_level=2;civ.player_relation.met_day=0
		preload("res://scripts/war_loop.gd").blood_feud(String(civ.id),10,"a border raid")
		preload("res://scripts/war_loop.gd").front(String(civ.id)).merge({"their_dead":index+3,"our_dead":index+1,"pending":{}},true)
	var intel=CivilizationSystem.city_intelligence
	for civ:Dictionary in CivilizationSystem.civilizations:
		var city_id:String=intel.primary_id(String(civ.id))
		intel.publish("player",intel.capture("player",city_id,0.9,130,"Returned scouts","fixture"),130)
	preload("res://scripts/enemy_strength.gd").forget()
	HistoricalFigures.reset_for_new_world();HistoricalFigures.ensure()
	for person:Dictionary in HistoricalFigures.people:person.status="dead"
	var generals:Array=[]
	for index in 12:
		var person:Dictionary=HistoricalFigures._create("General",20)
		check(not person.is_empty(),"Fixture general created")
		generals.append(person)
	var base:Dictionary=MilitaryCampaign._acting_field_commander(false)
	MilitaryCampaign.home_army=MilitaryCampaign.simulator.create_formation_force("The watch",[{"id":0,"unit":"levy","weapon":"improvised","count":48,"equipment":48,"training":0.6}],0.7,0.8)
	MilitaryCampaign.home_army["commander"]=HistoricalFigures.commander_record(generals[0],base)
	for index in range(1,generals.size()):
		var people:=10+index*2
		var band:Dictionary=MilitaryCampaign.simulator.create_formation_force("Band %d" % index,[{"id":index,"unit":"spearman","weapon":"spear","count":people,"authorized_count":people,"equipment":people,"equipment_required":people,"training":0.6}],0.7,0.8)
		band.merge({"army_id":index,"status":"stationed","location_name":"River watch","position":{"x":0.0,"z":0.0},"supply_level":0.86,"commander":HistoricalFigures.commander_record(generals[index],base)},true)
		band["council"]={"civ":String(CivilizationSystem.civilizations[index].id),"kind":"war_guard"}
		MilitaryCampaign.field_armies.append(band)
	var ops:=preload("res://scripts/covert_ops.gd").state()
	for index in 7:ops.learned.append({"fact":"A returned scout account %d" % index,"civ_id":String(CivilizationSystem.civilizations[0].id),"civ_name":String(CivilizationSystem.civilizations[0].name),"day":130-index*30})
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	for canvas_size in [Vector2i(1600,900),Vector2i(1024,720)]:
		for mode in ["dark","light"]:
			T.set_color_mode(mode)
			var viewport:=SubViewport.new();viewport.size=canvas_size;viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;add_child(viewport)
			var background:=ColorRect.new();background.color=T.PAPER_SUNK;background.size=Vector2(canvas_size);viewport.add_child(background)
			var screen:=Roster.new();screen.page="war";viewport.add_child(screen);screen.panel.theme=T.control_theme();await settle()
			var board:Control
			for child in screen.body.get_children():
				if child.get_script()==Board:board=child
			check(board!=null,"Actual War board")
			for task in ["fronts","leaders"]:
				board.show_tab(task);await settle()
				var reader:Control=board.front_reader if task=="fronts" else board.leader_reader
				check(board.tabs_row.visible,"Tabs available at every width")
				check(reader.records.size()>10,"Crowded fixture")
				check(reader.choices.get_child_count()==4,"Bounded four-choice index")
				check(reader.reader.get_child_count()==1,"One full selected card")
				check(Rect2(Vector2.ZERO,Vector2(canvas_size)).encloses(screen.panel.get_global_rect()),"War outer panel fits")
				await shot(viewport,"%s-%s-%d" % [task,mode,canvas_size.x])
				if canvas_size.x<1520:
					check(not reader.index.visible and reader.pick.visible,"Narrow selected reader first")
					reader.pick.pressed.emit();await settle()
					check(reader.index.visible and not reader.reader.visible,"Narrow chooser replaces card")
					check(Rect2(Vector2.ZERO,Vector2(canvas_size)-Vector2(0,28)).encloses(reader.next.get_global_rect()),"Complete narrow chooser pager above fold")
					await shot(viewport,"%s-choose-%s-%d" % [task,mode,canvas_size.x])
				reader.next.pressed.emit();await settle()
				check(reader.page==1,"Can reach next four records")
				var last:Dictionary=reader.records.back()
				reader.search.text=String(last.title);reader.search.text_changed.emit(reader.search.text);await settle()
				check(reader.matches().size()==1,"Late record remains searchable")
				reader.choices.get_child(0).pressed.emit();await settle()
				check(reader.selected_id==String(last.id),"Choice opens the matching full card")
				board.refresh(true);await settle()
				check(reader.selected_id==String(last.id) and reader.query==String(last.title),"Refresh keeps selected identity and query")
				await shot(viewport,"%s-selected-%s-%d" % [task,mode,canvas_size.x])
				if task=="fronts":
					for control_name in ["Stance_leave","Stance_defend","Stance_punish","Stance_take","Stance_peace","LedBy"]:
						var control:=reader.reader.find_child(control_name,true,false) as Control
						check(control!=null,"Existing front action "+control_name)
						if control!=null:check(Rect2(Vector2.ZERO,Vector2(canvas_size)).encloses(control.get_global_rect()),"Front action above fold "+control_name)
				else:
					var name_general:=board.find_child("NameGeneral",true,false) as Control
					check(Rect2(Vector2.ZERO,Vector2(canvas_size)).encloses(name_general.get_global_rect()),"Name general above fold")
			board.show_tab("army");await settle()
			await shot(viewport,"army-%s-%d" % [mode,canvas_size.x])
			check(board.find_child("Legend",true,false).get_child_count()<=8,"Army legend bounded by allocation types")
			check(board.find_child("Part_fronts",true,false)!=null,"Many fronts grouped in Army overview")
			check(board.border_box.get_parent()==board.army_section,"Border belongs to Army at every width")
			board.show_tab("fronts");await settle()
			check(not board.army_pane.visible and board.fronts_section.visible and not board.leaders_section.visible,"One selected task uses board")
			check(not board.front_reader.query.is_empty(),"Task switching preserves search")
			board.show_tab("leaders");board._toggle_covert();await settle()
			check(not board.panes.visible and board.covert_back.visible,"Intelligence remains a full task")
			check(board.covert.record_entries.get_child_count()==3,"Intelligence digest preserved")
			board._toggle_covert();await settle()
			check(board.tab=="leaders" and not board.leader_reader.query.is_empty(),"Intelligence Back retains selected commander")
			screen.queue_free();viewport.queue_free();await get_tree().process_frame
	fixture.free();WorldSimulation.clear()
	print("WAR_CHOICES_DENSITY ","PASS" if failures.is_empty() else "FAIL "+str(failures));get_tree().quit(0 if failures.is_empty() else 1)
func shot(viewport:SubViewport,file:String)->void:
	if DisplayServer.get_name()=="headless":return
	viewport.get_texture().get_image().save_png(output.path_join(file+".png"));print("SHOT ",file)
