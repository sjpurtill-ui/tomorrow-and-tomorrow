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
