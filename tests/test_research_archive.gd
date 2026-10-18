extends GdUnitTestSuite
const Board:=preload("res://scripts/hud/knowledge_tree_board.gd")
const Views:=preload("res://scripts/hud/view_state.gd")

func _block(selected:Array)->Dictionary:
	var findings:Array=[]
	for index in 60:findings.append({"label":"Finding %d" % index,"value":"three years ago","tip":"Full effect account %d" % index})
	return {"archive":true,"summary":"60 known of 100","selected":"labor","on_select":func(id:String)->void:selected.append(id),"archive_fields":[
		{"id":"labor","name":"Work & tools","known":60,"count":"60 of 80","summary":"Working efficiency +12%","sections":[{"heading":"What it adds now","items":[{"label":"Working efficiency","value":"+12%","tone":"good","tip":"The complete explanation"}]},{"heading":"Findings · newest first","items":findings}]},
		{"id":"health","name":"Health & care","known":0,"count":"0 of 20","summary":"No measured benefit yet","sections":[]}]}

func test_selected_account_keeps_every_finding_and_its_full_explanation()->void:
	var chosen:Array=[]
	var board:Control=auto_free(Board.new());add_child(board);board.size=Vector2(1060,700);board.setup(_block(chosen))
	for i in 4:await get_tree().process_frame
	var facts:Array=board.archive_results.get_children()
	assert_int(facts.size()).is_equal(3)
	board.archive_browse=true;board.select_archive("labor",false)
	assert_int(board.archive_results.get_child_count()).is_equal(6)
	board.archive_page=9;board._render_findings()
	assert_str((board.archive_results.get_child(5) as Label).tooltip_text).is_equal("Full effect account 59")
	board.archive_query="Finding 59";board.archive_page=0;board._render_findings()
	assert_int(board.archive_results.get_child_count()).is_equal(1)
	board.select_archive("health")
	assert_array(chosen).contains_exactly(["health"])
	var state:Dictionary=board.view_state()
	board.select_archive("labor",false);board.restore_view_state(state)
	assert_str(board.archive_selected).is_equal("health")
	assert_array(chosen).contains_exactly(["health"])

func test_narrow_reader_uses_same_selection_without_a_second_page()->void:
	var board:Control=auto_free(Board.new());add_child(board);board.size=Vector2(420,700);board.setup(_block([]))
	for i in 4:await get_tree().process_frame
	assert_bool(board.archive_picker.visible).is_true()
	assert_bool(board.archive_list.visible).is_false()
	assert_int(board.archive_picker.item_count).is_equal(2)
	board.archive_picker.item_selected.emit(1)
	assert_str(board.archive_selected).is_equal("health")
	assert_float(board.get_combined_minimum_size().x).is_less_equal(421.0)

func test_explore_search_and_pages_reach_every_question_without_a_long_list()->void:
	var rows:Array=[]
	for index in 60:rows.append({"id":"q%d" % index,"name":"Question %d" % index,"status":"AVAILABLE","subcategory":"Test line"})
	var selected:Array=[]
	var board:Control=auto_free(Board.new());add_child(board);board.size=Vector2(1060,700);board.setup({"domain":"labor","fields":[],"rows":rows,"chosen":{},"on_select":func(id:String)->void:selected.append(id)})
	for i in 4:await get_tree().process_frame
	assert_int(board.question_grid.get_child_count()).is_equal(6)
	for choice:Control in board.question_grid.get_children():assert_float(choice.size.y).is_less(180.0)
	board.question_page=9;board._render_questions()
	var last:Button=board.find_child("Pill_q59",true,false);assert_object(last).is_not_null();last.pressed.emit()
	assert_array(selected).contains_exactly(["q59"])
	board.question_query="Question 37";board.question_page=0;board._render_questions()
	assert_int(board.question_grid.get_child_count()).is_equal(1)

func test_archive_can_shrink_after_opening_wide()->void:
	var board:Control=auto_free(Board.new());add_child(board);board.size=Vector2(1060,700);board.setup(_block([]))
	for i in 4:await get_tree().process_frame
	board.size.x=420
	for i in 6:await get_tree().process_frame
	assert_bool(board.archive_picker.visible).is_true()
	assert_bool(board.archive_list.visible).is_false()
	assert_float(board.get_combined_minimum_size().x).is_less_equal(421.0)

func test_global_totals_open_before_archive_and_keep_navigation_state()->void:
	var block:=_block([])
	block.totals=[{"id":"health_protection","label":"Protection from sickness","unlocked":.12,"current":.03}]
	block.recent=[{"id":"a","label":"First","day":3,"effect":"Protection +2 pp"},{"id":"b","label":"Second","day":2,"effect":"Water +3 pp"},{"id":"c","label":"Third","day":1,"effect":"Work +1 pp"},{"id":"d","label":"Old","day":0,"effect":"Work +1 pp"}]
	var board:Control=auto_free(Board.new());add_child(board);board.size=Vector2(1060,700);board.setup(block)
	for i in 4:await get_tree().process_frame
	assert_bool(board.overview.visible).is_true();assert_bool(board.archive_body.visible).is_false()
	assert_int(board.overview_totals.get_child_count()).is_equal(1)
	assert_int(board.find_child("LatestThree",true,false).get_child_count()).is_equal(4)
	board.archive_toggle.pressed.emit()
	assert_bool(board.archive_body.visible).is_true();assert_bool(board.overview.visible).is_false()
	var state:Dictionary=board.view_state();board._show_archive(false);board.restore_view_state(state)
	assert_bool(board.archive_open).is_true()
	board._show_archive(false);board.size.x=420
	for i in 5:await get_tree().process_frame
	assert_int(board.overview_totals.columns).is_equal(1)
	assert_float(board.get_combined_minimum_size().x).is_less_equal(421.)

func test_provider_aggregates_known_effects_and_last_three_across_fields()->void:
	WorldSimulation.clear();GameState.reset_for_new_world(908)
	GameState.known_discoveries=["clean_water","wound_cleaning","shared_childcare","birth_attendants"]
	GameState.discovery_log=[]
	var expected:Dictionary={}
	for i in GameState.known_discoveries.size():
		var id:String=GameState.known_discoveries[i]
		GameState.discovery_log.append({"id":id,"day":i+1})
		for key:String in DiscoverySystem.discovery_definition(id).get("effects",{}):expected[key]=float(expected.get(key,0))+float(DiscoverySystem.discovery_definition(id).effects[key])
	DiscoverySystem.refresh_operating_effects()
	var provider=preload("res://scripts/hud/content/dock_content_inquiry.gd").new(null,null)
	var data:Dictionary=provider.tab(2).blocks[0]
	assert_int(data.recent.size()).is_equal(3);assert_str(data.recent[0].id).is_equal("birth_attendants")
	for row:Dictionary in data.totals:assert_float(row.unlocked).is_equal_approx(float(expected[row.id]),.00001)
	WorldSimulation.clear()
