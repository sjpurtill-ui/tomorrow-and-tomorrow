extends GdUnitTestSuite
const Roster=preload("res://scripts/hud/military_roster_screen.gd")
const Art=preload("res://scripts/hud/military_roster_visuals.gd")
func before_test()->void:
	GameState.reset_for_new_world(424242);MilitaryCampaign.reset_for_new_world();CivilizationSystem.reset_for_new_world()
	GameState.initialize_population_model();GameState.ensure_population_total(1000)
	MilitaryCampaign.home_army=MilitaryCampaign.simulator.create_formation_force("Reserve",[{"id":1,"unit":"levy","weapon":"improvised","count":3,"equipment":0,"training":.4,"experience":0},{"id":2,"unit":"cavalry","weapon":"lance","count":12,"equipment":12,"training":.8,"experience":.6}],.8,.7)

func test_roster_has_service_artwork_actual_counts_and_distinct_portraits_without_spending()->void:
	var stores:=GameState.resource_stockpiles.duplicate(true);var time:=GameState.elapsed_days
	var screen:CanvasLayer=auto_free(Roster.new());add_child(screen)
	# The army's Forces page is HOI4's overview: one row for the levy at home,
	# its numbers on bars, the reasons in the tooltips.
	var board:VBoxContainer=screen.forces_board
	assert_int(board.live.size()).is_equal(1)
	assert_str(board.chips.men.value.text).is_equal("15")
	assert_str(board.chips.men.word.text).is_equal("warriors")
	assert_str(board.chips.gear.value.text).is_equal("80%")
	assert_str(board.chips.gear.chip.tooltip_text).contains("Short 3 Simple levy weapons")
	var row:Dictionary=board.live[0]
	assert_str(row.men.text).is_equal("15/15")
	assert_str(row.men_cell.tooltip_text).is_equal("15 men, every place filled.")
	assert_str(String(row.meters[0].text)).is_equal("12/15")
	assert_str(String(row.meters[0].tooltip_text)).contains("Short 3 Simple levy weapons")
	assert_object(row.face.texture).is_not_null()
	assert_str(Art.illustration_path("levy")).ends_with("levy-v1.png")
	assert_str(Art.illustration_path("armored_formation")).ends_with("armor-v1.png")
	assert_str(Art.illustration_path("war_elephant")).ends_with("war_elephant-v1.png")
	assert_bool(screen.portraits.find_children("*","SubViewport",true,false).is_empty()).is_true()
	assert_str(Art.role_symbol("armored_formation","army")).is_equal("armor")
	for service:String in ["army","navy","air"]:assert_object(Art.artwork(service)).is_not_null()
	assert_dict(GameState.resource_stockpiles).is_equal(stores);assert_float(GameState.elapsed_days).is_equal(time)

func test_live_updates_keep_card_and_expanded_detail_and_attention_filter_is_current()->void:
	var screen:CanvasLayer=auto_free(Roster.new());add_child(screen)
	var board:VBoxContainer=screen.forces_board
	var card:Control=board.live[0].panel
	MilitaryCampaign.home_army.formations[0].training=.65
	board._process(.6)
	# The same row, its drill read again in place.
	assert_object(board.live[0].panel).is_same(card)
	assert_str(board.live[0].drill.text).is_equal("77%")
	board.set_filter("short");assert_int(board.live.size()).is_equal(1)
	MilitaryCampaign.home_army.formations[0].equipment=3
	board._process(.6);assert_int(board.live.size()).is_equal(0)
	# The filter stays chosen when the page is built again.
	screen._build_body();assert_str(screen.forces_board.filter).is_equal("short")

func test_switching_service_and_policy_never_changes_another_service()->void:
	# Services are offered only once the people can field them: boats and flight.
	GameState.known_discoveries.append_array(["river_craft","powered_flight"])
	var screen:CanvasLayer=auto_free(Roster.new());add_child(screen)
	assert_bool(screen.service_buttons.has("navy") and screen.service_buttons.has("air")).is_true()
	screen.training_view=true;screen._build_body()
	screen.policy_buttons.intensive.pressed.emit()
	screen.service_buttons.navy.pressed.emit()
	assert_str(screen.service).is_equal("navy")
	assert_bool(screen.policy_buttons.regular.button_pressed).is_true()
	assert_str(MilitaryCampaign.training_staff.policy("army").id).is_equal("intensive")
	screen.policy_buttons.maintain.pressed.emit()
	assert_str(MilitaryCampaign.training_staff.policy("air").id).is_equal("regular")
	assert_str(MilitaryCampaign.training_staff.policy("navy").id).is_equal("maintain")

func test_roster_and_policy_wrap_at_small_sizes_and_keep_close_and_navigation_reachable()->void:
	var view:SubViewport=auto_free(SubViewport.new());view.size=Vector2i(1024,640);add_child(view)
	var screen:CanvasLayer=auto_free(Roster.new());view.add_child(screen)
	for size:Vector2i in [Vector2i(800,600),Vector2i(1024,640),Vector2i(1280,720),Vector2i(1600,900)]:
		view.size=size;screen._layout()
		for policy:bool in [false,true]:
			screen.training_view=policy;screen._build_body()
			await await_idle_frame();await await_idle_frame()
			assert_bool(Rect2(Vector2.ZERO,Vector2(size)).encloses(screen.panel.get_global_rect())).is_true()
			assert_bool(screen.panel.get_global_rect().encloses(screen.close_button.get_global_rect())).is_true()
			assert_bool(screen.panel.get_global_rect().encloses(screen.management_button.get_global_rect())).is_true()
			assert_float(screen.body.get_combined_minimum_size().x).is_less_equal(screen.scroll.size.x)
			if policy:assert_int(screen.policy_grid.columns).is_equal(4 if screen.panel.size.x>=920 else 2)

func test_unknown_field_report_uses_no_model_or_invented_readiness()->void:
	MilitaryCampaign.create_field_army(2)
	var army:Dictionary=MilitaryCampaign.field_armies[0];army.status="moving";army.location_id="field";army.last_report={}
	var screen:CanvasLayer=auto_free(Roster.new());add_child(screen)
	var board:VBoxContainer=screen.forces_board
	var unknown:Dictionary={}
	for control:Dictionary in board.live:
		if String(control.id)=="army:%d" % int(army.army_id):unknown=control
	# No report yet: no numbers are guessed, and the totals leave them out.
	assert_bool(bool(unknown.row.unknown)).is_true()
	assert_str(unknown.men.text).is_equal("—")
	assert_str(unknown.men_cell.tooltip_text).contains("Not known until a runner reports")
	assert_str(unknown.where.text).is_equal("No report yet")
	for meter:Control in unknown.meters:assert_bool(meter.visible).is_false()
	assert_bool((unknown.drill_cell as Control).visible).is_false()
	assert_str(board.chips.men.chip.tooltip_text).contains("Not counted: 1 away with no report yet")

func test_compact_rows_and_small_army_panel_leave_the_map_visible()->void:
	var view:SubViewport=auto_free(SubViewport.new());view.size=Vector2i(1440,900);add_child(view)
	var screen:CanvasLayer=auto_free(Roster.new());view.add_child(screen)
	for frame in 8:await await_idle_frame()
	# One compact row per army, as HOI4 lists them: one force leaves most of
	# the map in view.
	var board:VBoxContainer=screen.forces_board
	assert_float(board.live[0].panel.size.y).is_less_equal(80)
	assert_float(screen.panel.size.y).is_less_equal(560)
	for type_id:String in Art.manifest():
		assert_bool(ResourceLoader.exists(Art.illustration_path(type_id))).override_failure_message(type_id).is_true()
	var click:=InputEventMouseButton.new();click.button_index=MOUSE_BUTTON_LEFT;click.pressed=true
	board.live[0].panel._gui_input(click)
	assert_str(board.selected_id).is_equal("home")

func test_fragmented_levies_share_force_but_never_combine_separate_armies()->void:
	var formations:Array=[]
	for index in 100:
		formations.append({"id":index+1,"unit":"levy","weapon":"improvised","count":1,"authorized_count":1,"equipment":0,"equipment_required":1,"training":.4,"personnel_condition":.8})
	MilitaryCampaign.home_army.formations=formations;MilitaryCampaign.home_army.troops=100
	MilitaryCampaign.occupation_forces=[{"civ_id":"enemy","region_id":"a","region_name":"Northbank","troops":4,"formations":formations.slice(0,4)},{"civ_id":"enemy","region_id":"b","region_name":"Southbank","troops":2,"formations":formations.slice(4,6)}]
	var screen:CanvasLayer=auto_free(Roster.new());add_child(screen)
	var rows:Array=screen.forces_board.rows
	assert_int(rows.size()).is_equal(3)
	assert_int(int(rows[0].men)).is_equal(100)
	assert_int(int(rows[0].kinds[0].count)).is_equal(100)
	assert_str(screen.forces_board.live[0].who.tooltip_text).contains("Made up of 100 levy")
	assert_str(String(rows[1].title)).contains("Northbank")
	assert_int(int(rows[1].men)).is_equal(4)
	assert_int(int(rows[2].men)).is_equal(2)
	assert_int(MilitaryCampaign.home_army.formations.size()).is_equal(100)

func test_recruitment_lines_are_not_split_into_individual_trainees()->void:
	MilitaryCampaign.home_army.formations=[];MilitaryCampaign.home_army.troops=0
	MilitaryCampaign.training_queue=[{"id":1,"unit":"levy","count":1,"deployment_line":2},{"id":2,"unit":"levy","count":3,"deployment_line":2},{"id":3,"unit":"levy","count":5,"deployment_line":3}]
	var screen:CanvasLayer=auto_free(Roster.new());add_child(screen)
	# Recruits in drill are one number on the strip (their lines are in
	# Recruit & deploy), never a row per recruit.
	assert_int(screen.forces_board.rows.size()).is_equal(0)
	assert_str(screen.forces_board.chips.training.value.text).is_equal("9")
