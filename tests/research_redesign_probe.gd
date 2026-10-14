extends Node
## Presentation-only fixture. It never loads or writes player saves.
var failures:Array[String]=[]
func check(ok:bool,words:String)->void:
	if not ok:failures.append(words);push_error(words)
func frames(count:int=8)->void:
	for i in count:await get_tree().process_frame
	await RenderingServer.frame_post_draw
func _ready()->void:
	# DisplayPreferences is created by the terrain and reads its configuration
	# during _ready, so set the palette only in this probe's isolated user data.
	if not "Test" in OS.get_user_data_dir():
		push_error("Research probe needs an isolated Test user directory");get_tree().quit(1);return
	var config:=ConfigFile.new();config.set_value("display","color_theme","dark" if "--dark" in OS.get_cmdline_user_args() else "light");config.save("user://display.cfg")
	GameState.reset_for_new_world(991704);GovernmentPeopleSystem.reset_for_new_world()
	GameState.civic_api_enabled=false;GameState.initialize_population_model()
	GameState.settlement_name="SeanTown";GameState.settlement_site_committed=true
	GameState.settlement_completed=["Hearth Circle"];GameState.settlement_founded_at=Vector3(12,0,-8)
	SettlementModel.ensure_founded();GovernmentPeopleSystem.initialize();GameState.select_founding_focus("provision")
	PeopleDirection.choose(String(PeopleDirection.AMBITIONS.keys()[0]))
	DiscoverySystem.reset_for_new_world();DiscoverySystem.initialize();GameState.elapsed_days=365*11
	for id in ["stone_sorting","clay_testing","counting_words","tallies","basketry","ember_tending","hearth_heat_retention"]:
		if not id in GameState.known_discoveries:GameState.known_discoveries.append(id)
	GameState.resource_deposits.append({"resource":"Clay","stage":"accessible"})
	GameState.resource_deposits.append({"resource":"Fiber Plants","stage":"accessible"})
	for domain in GameState.research_subcategory_allocations:
		for sub in (GameState.research_subcategory_allocations[domain] as Dictionary):GameState.research_subcategory_allocations[domain][sub]=0
	var lines:={"production::Material supply":"clay_shaping","production::Tool quality":"clay_shaping","demography::Fertility conditions":"mouths_against_store","nutrition::Daily supply":"fruit_pulp_screening","knowledge::Preserved knowledge":"moon_counting","health::Water & sanitation":"turbidity_judging"}
	GameState.active_investigations.clear()
	for channel:String in lines:
		var parts:=channel.split("::");GameState.research_subcategory_allocations[parts[0]][parts[1]]=1;GameState.active_investigations[channel]=lines[channel]
	DiscoverySystem._rebuild_research_domain_totals()
	GameState.discovery_progress.merge({"clay_shaping":0.46,"mouths_against_store":0.63,"fruit_pulp_screening":0.2,"moon_counting":0.08,"turbidity_judging":0.3},true)
	var terrain=load("res://local_terrain.tscn").instantiate();add_child(terrain)
	await frames(3);terrain._set_game_speed(0.0)
	if is_instance_valid(terrain.founding_focus_panel):terrain.founding_focus_panel.queue_free()
	terrain.founding_focus_panel=null
	var hud=terrain.hud
	var baseline:="--baseline" in OS.get_cmdline_user_args()
	var prefix:="baseline" if baseline else "redesign"
	if "--dark" in OS.get_cmdline_user_args():prefix+="-dark"
	for canvas in [Vector2i(1600,1000),Vector2i(1024,720)]:
		get_window().size=canvas;get_window().content_scale_size=canvas
		for index in [0,1,2]:
			hud.open_dock("inquiry",index,false);await frames()
			if baseline:
				if index==2:
					var provider=load("res://artifacts/research-baseline/dock_content_inquiry.gd").new(terrain,hud)
					hud.dock.present(provider,2)
				else:
					var old=hud.dock.find_child("InquiryBoard" if index==0 else "KnowledgeTree",true,false)
					var parent=old.get_parent();var data:Dictionary=old.data
					parent.remove_child(old);old.queue_free()
					var script:="inquiry_board" if index==0 else "knowledge_tree_board"
					var replacement=load("res://artifacts/research-baseline/"+script+".gd").new();parent.add_child(replacement);replacement.setup(data)
			await frames()
			check(hud.dock.get_global_rect().end.x<=canvas.x+1,"Dock fits "+str(canvas.x))
			get_viewport().get_texture().get_image().save_png("res://artifacts/research-%s-%d-tab%d.png" % [prefix,canvas.x,index])
			if not baseline:
				var board=hud.dock.find_child("InquiryBoard" if index==0 else "KnowledgeTree",true,false)
				check(board.get_combined_minimum_size().x<=board.size.x+1,"Research content fits "+str(canvas.x)+" tab "+str(index))
				if index==0:
					check(board.find_child("Fields",true,false).get_child_count()==12,"Twelve fields remain available")
					var field:Dictionary=board.data.fields[0];var weight:=int(GameState.research_allocations[field.id]);var people:=GameState.population_total;var known:=GameState.known_discoveries.duplicate()
					field.on_more.call();check(int(GameState.research_allocations[field.id])==weight+1,"Attention increase still works")
					field.on_less.call();check(int(GameState.research_allocations[field.id])==weight,"Attention decrease still works")
					check(GameState.population_total==people and GameState.known_discoveries==known,"Presentation preserves population and knowledge")
				elif index==1:
					var before:int=board.find_children("Pill_*","Button",true,false).size()
					for button:Button in board.find_children("*","Button",true,false):
						if button.text.begins_with("+") and "open to a team" in button.text:
							button.pressed.emit();await frames();check(board.find_children("Pill_*","Button",true,false).size()>before,"More questions expand inline");break
					var read:Control=board.find_child("DetailNotes",true,false)
					if read:
						for button:Button in board.find_children("*","Button",true,false):
							if button.text=="More about this question":button.pressed.emit();break
						check(read.visible,"Full question account can be read without hovering")
				elif index==2:
					board.data.on_toggle_unlearned.call();await frames()
					board=hud.dock.find_child("KnowledgeTree",true,false)
					check(board.archive_grid.get_child_count()==12,"All twelve archive fields are accessible")
					board.data.on_toggle_unlearned.call();await frames()
	# Every-discovery reading card: an existing finding in this isolated fixture.
	hud.close_dock();get_window().size=Vector2i(1280,900);get_window().content_scale_size=Vector2i(1280,900)
	var popup=preload("res://scripts/hud/discovery_popup.gd").announce(terrain,hud,[{"id":"basketry","day":3650}])
	await get_tree().create_timer(1.4).timeout;await frames()
	if popup:
		get_viewport().get_texture().get_image().save_png("res://artifacts/research-%s-discovery.png" % prefix)
		check(popup.panel.get_global_rect().end.x<=1280,"Discovery card fits")
		get_window().size=Vector2i(800,700);get_window().content_scale_size=Vector2i(800,700);await frames()
		get_viewport().get_texture().get_image().save_png("res://artifacts/research-%s-discovery-narrow.png" % prefix)
		check(popup.panel.get_global_rect().end.x<=get_viewport().get_visible_rect().size.x,"Narrow discovery card fits logical viewport")
	print("RESEARCH_REDESIGN_CHECKS ",prefix,": ",failures)
	get_tree().quit(0 if failures.is_empty() else 1)
