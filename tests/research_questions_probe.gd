extends Node
## GPU capture of the Research dock's "Where we look" tab at year 11 with six
## lines of study at work. Clay Vessels is held by two lines at once: its own
## line (Material supply) and Tool quality, which took it up as foundation work
## for the craft field. The sim reaches this state when a borrowed question's
## own line frees up and picks it. Run through tools/run_isolated_gpu_probe.ps1;
## captures land in res://artifacts/ (not committed).
var failures:Array[String]=[]
func check(ok:bool,message:String)->void:
	if not ok:failures.append(message);push_error(message)
func frames(count:int=6)->void:
	for i in count:await get_tree().process_frame
	await RenderingServer.frame_post_draw
func capture(name:String)->void:
	await frames(4)
	get_viewport().get_texture().get_image().save_png("res://artifacts/%s.png" % name)
	print("CAPTURE ",name)
func _ready()->void:
	GameState.reset_for_new_world(991704)
	GovernmentPeopleSystem.reset_for_new_world()
	GameState.initialize_population_model()
	GameState.settlement_name="SeanTown";GameState.settlement_site_committed=true
	GameState.settlement_completed=["Hearth Circle"];GameState.settlement_founded_at=Vector3(12,0,-8)
	SettlementModel.ensure_founded();GovernmentPeopleSystem.initialize()
	GameState.select_founding_focus("provision")
	PeopleDirection.choose(String(PeopleDirection.AMBITIONS.keys()[0]))
	DiscoverySystem.reset_for_new_world();DiscoverySystem.initialize()
	var day:=365*11
	GameState.elapsed_days=float(day)
	for id in ["stone_sorting","clay_testing","counting_words","tallies","basketry","ember_tending","hearth_heat_retention"]:
		if not id in GameState.known_discoveries:GameState.known_discoveries.append(id)
	GameState.resource_deposits.append({"resource":"Clay","stage":"accessible"})
	GameState.resource_deposits.append({"resource":"Fiber Plants","stage":"accessible"})
	for domain in GameState.research_subcategory_allocations:
		for sub in (GameState.research_subcategory_allocations[domain] as Dictionary):GameState.research_subcategory_allocations[domain][sub]=0
	var lines:={"production::Material supply":"clay_shaping","production::Tool quality":"clay_shaping",
		"demography::Fertility conditions":"mouths_against_store","nutrition::Daily supply":"fruit_pulp_screening",
		"knowledge::Preserved knowledge":"moon_counting","health::Water & sanitation":"turbidity_judging"}
	GameState.active_investigations.clear()
	for channel:String in lines:
		var parts:=channel.split("::")
		GameState.research_subcategory_allocations[parts[0]][parts[1]]=1
		GameState.active_investigations[channel]=lines[channel]
	DiscoverySystem._rebuild_research_domain_totals()
	check("clay_shaping" in DiscoverySystem._research_600_foundation_ids("production",day),"Clay Vessels is craft foundation work, so Tool quality may hold it")
	for id in ["clay_shaping","mouths_against_store","fruit_pulp_screening","moon_counting","turbidity_judging"]:
		check(DiscoverySystem._discovery_is_eligible(DiscoverySystem.discovery_definition(id),day),id+" is open at year 11")
	GameState.discovery_progress.merge({"clay_shaping":0.46,"mouths_against_store":0.63,"fruit_pulp_screening":0.2,"moon_counting":0.08,"turbidity_judging":0.3},true)
	var terrain=load("res://local_terrain.tscn").instantiate();add_child(terrain)
	for i in 3:await get_tree().process_frame
	terrain._set_game_speed(0.0)
	if is_instance_valid(terrain.founding_focus_panel):terrain.founding_focus_panel.queue_free()
	terrain.founding_focus_panel=null
	var hud=terrain.hud
	for canvas in [Vector2i(1600,1000),Vector2i(1024,720)]:
		get_window().size=canvas;get_window().content_scale_size=canvas
		hud.open_dock("inquiry",0)
		await frames(8)
		var board=hud.dock.find_child("InquiryBoard",true,false)
		check(board!=null,"The Where we look tab shows the inquiry board")
		if board==null:continue
		var ids:Array[String]=[]
		for record:Dictionary in board.data.investigations:ids.append(String(record.get("id","")))
		print("QUESTIONS %d: %s" % [canvas.x,ids])
		var seen:Dictionary={}
		for id in ids:
			check(not seen.has(id),"%s is listed once, not once per line (%d)" % [id,canvas.x]);seen[id]=true
		var cards:Array=board.find_children("Question_*","",true,false)
		check(cards.size()==ids.size(),"One card per question (%d cards, %d questions)" % [cards.size(),ids.size()])
		for card:Control in cards:
			var label:Label=card.find_child("FieldLabel",true,false)
			check(label!=null and not label.text.strip_edges().is_empty(),"%s has a field label" % card.name)
			if label:
				var font:=label.get_theme_font("font");var needed:=font.get_string_size(label.text,HORIZONTAL_ALIGNMENT_LEFT,-1,label.get_theme_font_size("font_size")).x
				check(label.size.x+1.0>=needed,"%s field label shows whole (%.0f of %.0f px)" % [card.name,label.size.x,needed])
			var content:=card.get_combined_minimum_size().y
			check(card.size.y<=content+1.0,"%s is as tall as its content (%.0f px, content %.0f px)" % [card.name,card.size.y,content])
		var ancestor:Node=board
		while ancestor!=null and not ancestor is ScrollContainer:ancestor=ancestor.get_parent()
		if ancestor is ScrollContainer:
			var view:=(ancestor as ScrollContainer).get_global_rect()
			check(board.get_global_rect().end.x<=view.end.x+1.0,"Board fits the dock (%d: board ends %.0f, dock %.0f)" % [canvas.x,board.get_global_rect().end.x,view.end.x])
		await capture("research-questions-%d" % canvas.x)
		if ancestor is ScrollContainer:
			var scroll:=ancestor as ScrollContainer
			var section:Control=board.find_child("BeingLearned",true,false)
			if section==null:section=board.get("projects_grid")
			if section:
				var top:=section.global_position.y-scroll.global_position.y
				scroll.scroll_vertical=int(maxf(0.0,top-16.0))
				await capture("research-questions-%d-cards" % canvas.x)
				scroll.scroll_vertical=int(maxf(0.0,top+section.size.y-scroll.size.y+24.0))
				await capture("research-questions-%d-cards-end" % canvas.x)
	print("RESEARCH_QUESTIONS_CHECKS: ",failures)
	get_tree().quit(0 if failures.is_empty() else 1)
