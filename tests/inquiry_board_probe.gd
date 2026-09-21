extends Node
var failures:Array[String]=[]
func check(ok:bool,message:String)->void:
	if not ok:failures.append(message);push_error(message)
func _ready()->void:
	GameState.reset_for_new_world(991704)
	GovernmentPeopleSystem.reset_for_new_world()
	GameState.initialize_population_model()
	GameState.settlement_name="SeanTown";GameState.settlement_site_committed=true
	GameState.settlement_completed=["Hearth Circle"];GameState.settlement_founded_at=Vector3(12,0,-8)
	SettlementModel.ensure_founded();GovernmentPeopleSystem.initialize()
	GameState.select_founding_focus("provision")
	PeopleDirection.choose(String(PeopleDirection.AMBITIONS.keys()[0]))
	var city:=GameState.selected_player_settlement_id
	var history:=preload("res://scripts/strategic_history.gd")
	for day in range(0,730,30):history.record(GameState.strategic_history,day,{city:{"population":120+day/4,"food_days":40+sin(day*.02)*12,"water_days":5}})
	GameState.discovery_log=[{"id":"cordage","name":"Cordage","day":640,"causal_mechanism":"Twisted fibers carry loads that loose strands cannot."},{"id":"clay_shaping","name":"Clay shaping","day":300,"causal_mechanism":"Clay holds a useful form when worked and dried."}]
	for day in range(40,600,40):GameState.record_building_event({"day":day,"settlement_id":city,"kind":"Lean-to Shelters","event":"built","material_family":"Timber and plant fibers"})
	var terrain=load("res://local_terrain.tscn").instantiate();add_child(terrain)
	for i in 3:await get_tree().process_frame
	terrain._set_game_speed(0.0)
	if is_instance_valid(terrain.founding_focus_panel):terrain.founding_focus_panel.queue_free()
	terrain.founding_focus_panel=null
	var hud=terrain.hud
	for canvas in [Vector2i(1600,1000),Vector2i(1024,640)]:
		get_window().size=canvas;get_window().content_scale_size=canvas
		hud.open_dock("inquiry",0)
		for i in 8:await get_tree().process_frame
		check(hud.dock.get_global_rect().end.x<=canvas.x,"Research fits viewport")
		var panel=hud.dock.find_child("InquiryBoard",true,false)
		check(panel!=null,"Illustrated research is wired")
		if panel:
			check(panel.fields_grid.get_child_count()==12,"All twelve fields appear")
			var active_count:=0
			for field:Dictionary in panel.data.fields:active_count+=int(field.active)
			check(active_count==panel.data.investigations.size(),"Investigations counted in their actual fields")
			check(panel.get_combined_minimum_size().x<=panel.size.x,"Cards fit available width")
			var people:=GameState.population_total
			var known:=GameState.known_discoveries.duplicate()
			var field:Dictionary=panel.data.fields[0]
			var weight:=int(GameState.research_allocations.get(field.id,0))
			field.on_more.call()
			check(int(GameState.research_allocations[field.id])==weight+1,"More attention updates simulation")
			field.on_less.call()
			check(int(GameState.research_allocations[field.id])==weight,"Less attention restores weight")
			check(GameState.population_total==people and GameState.known_discoveries==known,"Attention invents no workers or discoveries")
		for i in 8:await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://artifacts/inquiry-board-"+str(canvas.x)+".png")
		var board=hud.dock.find_child("InquiryBoard",true,false)
		var ancestor:Node=board
		while ancestor!=null and not ancestor is ScrollContainer:ancestor=ancestor.get_parent()
		if ancestor is ScrollContainer:
			ancestor.scroll_vertical=1000
			for i in 4:await get_tree().process_frame
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("res://artifacts/inquiry-fields-"+str(canvas.x)+".png")
		board.data.on_tree.call()
		for i in 4:await get_tree().process_frame
		check(hud.has_meta("knowledge_atlas") and is_instance_valid(hud.get_meta("knowledge_atlas")),"Discovery tree opens")
		if hud.has_meta("knowledge_atlas") and is_instance_valid(hud.get_meta("knowledge_atlas")):hud.get_meta("knowledge_atlas").queue_free()
		for i in 2:await get_tree().process_frame
	var board=hud.dock.find_child("InquiryBoard",true,false)
	board.data.fields[0].on_open.call()
	for i in 3:await get_tree().process_frame
	check(hud.detail_dock.visible,"Field details open")
	var empty_data:Dictionary=board.data.duplicate();empty_data.investigations=[]
	var empty=preload("res://scripts/hud/inquiry_board.gd").new();add_child(empty);empty.setup(empty_data)
	check(empty.projects_grid.get_child_count()==1,"Empty research offers a workforce action")
	empty.queue_free()
	print("INQUIRY_BOARD_CHECKS: ",failures)
	get_tree().quit(0 if failures.is_empty() else 1)
