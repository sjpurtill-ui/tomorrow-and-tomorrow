extends GdUnitTestSuite
const Model=preload("res://scripts/hud/population_readings.gd")
const Archive=preload("res://scripts/hud/death_archive.gd")
func test_reconciliation_uses_same_dated_window_and_keeps_other_change_honest()->void:
	var state:={"elapsed_days":100,"population_total":110,"strategic_history":{"scopes":{"civilization":{"monthly":[{"day":30,"population":100}],"annual":[]}}},"vital_statistics_tracking_start_day":0,"vital_statistics_history":[{"day":30,"births":40,"deaths":10},{"day":31,"births":12,"deaths":4},{"day":101,"births":100,"deaths":0}]}
	var before:=state.duplicate(true);var data:=Model.balance(state)
	assert_bool(data.vitals_known).is_true();assert_int(data.births).is_equal(12);assert_int(data.deaths).is_equal(4);assert_int(data.other).is_equal(2)
	assert_int(data.before+data.births-data.deaths+data.other).is_equal(data.current)
	assert_dict(state).is_equal(before)
	state.vital_statistics_tracking_start_day=50
	data=Model.balance(state);assert_bool(data.known).is_true();assert_bool(data.vitals_known).is_false();assert_bool(data.has("other")).is_false()
	state.strategic_history={};assert_bool(Model.balance(state).known).is_false()
func test_archive_is_bounded_searchable_and_restores_only_selected_account()->void:
	var records:Array=[]
	for i in 60:records.append({"id":str(i),"day":i,"kind":"death","count":1,"cause":"illness","title":"Person %d" % i,"description":"Account %d" % i,"location":"Town"})
	var board:Control=auto_free(Archive.new());add_child(board);board.setup({"records":records})
	assert_int(board.choices.get_child_count()).is_equal(7)
	assert_int(board.detail.get_child_count()).is_equal(3)
	assert_str(board.detail.get_child(0).text).is_equal("Person 59")
	board.search.text="Person 17";board.search.text_changed.emit(board.search.text)
	assert_int(board.choices.get_child_count()).is_equal(1);assert_str(board.detail.get_child(0).text).is_equal("Person 17")
	var saved:Dictionary=board.view_state();board.search.text="no match";board._refresh();board.restore_view_state(saved)
	assert_str(board.detail.get_child(0).text).is_equal("Person 17")
func test_cohorts_read_existing_model_without_normalizing_or_creating_people()->void:
	WorldSimulation.clear();GameState.reset_for_new_world(919)
	GameState.population_cohorts={}
	assert_array(Model.cohorts(GameState)).is_empty()
	GameState.population_cohorts={"children":10.2,"youth":8.3,"early_adults":7.0,"established_adults":6.0,"mature_adults":5.0,"elders":4.0}
	var before:Dictionary=GameState.population_cohorts.duplicate()
	var rows:=Model.cohorts(GameState)
	assert_int(rows.size()).is_equal(6);assert_str(rows[0].value).is_equal("10.2")
	assert_dict(GameState.population_cohorts).is_equal(before)
	WorldSimulation.clear()
