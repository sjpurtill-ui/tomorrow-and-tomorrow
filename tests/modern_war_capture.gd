extends Node
## Presentation evidence from a deterministic test world. No campaign save or AI.
const HallProbe=preload("res://tests/audience_hall_probe.gd")
const Roster=preload("res://scripts/hud/military_roster_screen.gd")
const Board=preload("res://scripts/hud/war_board.gd")
const T=preload("res://scripts/hud/hud_tokens.gd")
var output:="res://artifacts/popup-audit"
func _ready()->void:call_deferred("run")
func settle()->void:
	for frame in 8:
		await get_tree().process_frame
		RenderingServer.force_draw(false)
func run()->void:
	for node in [GameState,MilitaryCampaign,CivilizationSystem]:node.set_process(false)
	var fixture:=HallProbe.new();fixture._base();fixture._people(140);fixture._refill();fixture._next_door()
	GovernmentPeopleSystem.reset_for_new_world();GovernmentPeopleSystem.initialize()
	for civ in CivilizationSystem.civilizations:civ.player_relation.contact_level=2;civ.player_relation.met_day=0
	GameState.elapsed_days=10
	var ops:=preload("res://scripts/covert_ops.gd").state()
	for index in 18:
		ops.learned.append({"fact":"Anmacha have food for sixty days" if index%2==0 else "Eten have learned to preserve the winter harvest","civ_id":String(CivilizationSystem.civilizations[index%2].id),"civ_name":"Anmacha" if index%2==0 else "Eten","day":10-index*30})
	var civ_id:=String(CivilizationSystem.civilizations[0].id)
	preload("res://scripts/war_loop.gd").blood_feud(civ_id,10,"a border raid")
	preload("res://scripts/war_loop.gd").front(civ_id).merge({"their_dead":3,"our_dead":1,"pending":{}},true)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	for canvas_size in [Vector2i(1600,1000),Vector2i(1024,720)]:
		for mode in ["dark","light"]:
			T.set_color_mode(mode)
			var viewport:=SubViewport.new();viewport.size=canvas_size;viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;add_child(viewport)
			var background:=ColorRect.new();background.color=T.PAPER_SUNK;background.size=Vector2(canvas_size);viewport.add_child(background)
			var screen:=Roster.new();screen.page="war"
			viewport.add_child(screen);screen.panel.theme=T.control_theme();await settle()
			var board:Control
			for child in screen.body.get_children():
				if child.get_script()==Board:board=child
			assert(board!=null)
			for page in ["army","fronts","leaders"]:
				board.show_tab(page);await settle()
				if not Rect2(Vector2.ZERO,Vector2(canvas_size)).encloses(screen.panel.get_global_rect()):
					print("WAR_BOUNDS ",canvas_size," ",mode," ",page," ",screen.panel.get_global_rect()," minimum ",screen.panel.get_combined_minimum_size())
					_dump_wide(screen.panel,float(canvas_size.x))
					viewport.get_texture().get_image().save_png(output.path_join("war-bounds-failure.png"))
					get_tree().quit(1);return
				viewport.get_texture().get_image().save_png(output.path_join("modern-war-%s-%s-%d.png" % [page,mode,canvas_size.x]))
			board._toggle_covert();await settle()
			assert(not board.panes.visible and board.covert_back.visible)
			assert(board.covert.record_entries.get_child_count()==3)
			viewport.get_texture().get_image().save_png(output.path_join("intelligence-latest-%s-%d.png" % [mode,canvas_size.x]))
			board.covert.find_child("BrowseRecords",true,false).pressed.emit();await settle()
			assert(board.covert.record_entries.get_child_count()==6)
			board.covert.record_next.pressed.emit();await settle()
			assert(board.covert.record_page==1)
			viewport.get_texture().get_image().save_png(output.path_join("intelligence-archive-%s-%d.png" % [mode,canvas_size.x]))
			var search:LineEdit=board.covert.find_child("RecordSearch",true,false)
			search.text="winter";search.text_changed.emit(search.text);await settle()
			assert(board.covert.record_page==0)
			assert("9 matching" in board.covert.record_count.text)
			board._toggle_covert();await settle();board._toggle_covert();await settle()
			assert(board.covert.record_query=="winter")
			screen.queue_free();viewport.queue_free();await get_tree().process_frame
	fixture.free();WorldSimulation.clear()
	print("MODERN_WAR_CAPTURE PASS")
	get_tree().quit(0)

func _dump_wide(node:Node,width:float)->void:
	if node is Control and node.is_visible_in_tree() and node.get_combined_minimum_size().x>400:
		print("WAR_MIN ",node.get_path()," ",node.get_combined_minimum_size()," size ",node.size)
	for child in node.get_children():_dump_wide(child,width)
